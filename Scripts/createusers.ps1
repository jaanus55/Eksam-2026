Import-Module ActiveDirectory

$csvPath = "C:\Scripts\kasutajad.csv"

# Default password for newly created users
$password = ConvertTo-SecureString "Passw0rd!" -AsPlainText -Force

# Base OU
$baseOU = "OU=Kasutajad,DC=salm,DC=local"

$users = Import-Csv -Path $csvPath -Encoding UTF8

foreach ($user in $users) {

    $fullName = $user.Nimi.Trim()
    $department = $user.Osakond.Trim()

    # Create department OU if it does not already exist
    $departmentOU = "OU=$department,$baseOU"

    $existingOU = Get-ADOrganizationalUnit `
        -Filter "Name -eq '$department'" `
        -SearchBase $baseOU `
        -ErrorAction SilentlyContinue

    if (-not $existingOU) {
        New-ADOrganizationalUnit `
            -Name $department `
            -Path $baseOU `
            -ProtectedFromAccidentalDeletion $false

        Write-Host "Created OU: $department"
    }

    # Split full name
    $nameParts = $fullName -split " "

    $firstName = $nameParts[0]
    $lastName = $nameParts[-1]

    # Create username firstname.lastname
    $username = "$firstName.$lastName".ToLower()

    # Replace Estonian characters
    $username = $username `
        -replace "ä","a" `
        -replace "ö","o" `
        -replace "ü","u" `
        -replace "õ","o" `
        -replace "š","s" `
        -replace "ž","z"

    # Remove unwanted characters
    $username = $username -replace "[^a-z0-9.-]", ""

    # Handle duplicate usernames
    $originalUsername = $username
    $number = 2

    while (Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue) {
        $username = "$originalUsername$number"
        $number++
    }

    New-ADUser `
        -Name $fullName `
        -GivenName $firstName `
        -Surname $lastName `
        -SamAccountName $username `
        -UserPrincipalName "$username@salm.local" `
        -Department $department `
        -Path $departmentOU `
        -AccountPassword $password `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    Write-Host "Created user: $fullName  ->  $username"
}

Write-Host ""
Write-Host "Finished creating users."