#requires -Version 5.1
#requires -Modules ActiveDirectory

<#
.SYNOPSIS
Impordib kasutajad failist kasutajad.csv ja loob CSV-s määratud OU-struktuuri.

CSV veerud:
Eesnimi;Perenimi;Kasutajanimi;Parool;OU;Osakond

OU näide:
Kasutajad/Personal
#>

[CmdletBinding()]
param(
    [string]$CsvPath = (Join-Path $PSScriptRoot "kasutajad.csv")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV-faili ei leitud: $CsvPath"
}

$domain = Get-ADDomain
$domainDN = $domain.DistinguishedName
$dnsRoot = $domain.DNSRoot

function Get-CsvDelimiter {
    param([string]$Path)

    $firstLine = Get-Content -LiteralPath $Path -TotalCount 1
    if ($firstLine -match ";") {
        return ";"
    }
    return ","
}

function Ensure-OUPath {
    param(
        [Parameter(Mandatory)]
        [string]$OUPath,

        [Parameter(Mandatory)]
        [string]$DomainDN
    )

    if ([string]::IsNullOrWhiteSpace($OUPath)) {
        return $DomainDN
    }

    $parts = $OUPath -split "[/\\]" |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $currentDN = $DomainDN

    foreach ($part in $parts) {
        $safeName = $part.Replace("'", "''")

        $ou = Get-ADOrganizationalUnit `
            -Filter "Name -eq '$safeName'" `
            -SearchBase $currentDN `
            -SearchScope OneLevel `
            -ErrorAction SilentlyContinue

        if (-not $ou) {
            $ou = New-ADOrganizationalUnit `
                -Name $part `
                -Path $currentDN `
                -ProtectedFromAccidentalDeletion $true `
                -PassThru

            Write-Host "Loodi OU: $($ou.DistinguishedName)" -ForegroundColor Green
        }

        $currentDN = $ou.DistinguishedName
    }

    return $currentDN
}

$delimiter = Get-CsvDelimiter -Path $CsvPath
$users = Import-Csv -LiteralPath $CsvPath -Delimiter $delimiter -Encoding UTF8

if (-not $users) {
    throw "CSV-failis pole kasutajaid."
}

$results = foreach ($row in $users) {
    try {
        $firstName = [string]$row.Eesnimi
        $lastName = [string]$row.Perenimi
        $sam = ([string]$row.Kasutajanimi).Trim()
        $plainPassword = [string]$row.Parool
        $ouPath = [string]$row.OU
        $department = [string]$row.Osakond

        if ([string]::IsNullOrWhiteSpace($firstName) -or
            [string]::IsNullOrWhiteSpace($lastName) -or
            [string]::IsNullOrWhiteSpace($sam) -or
            [string]::IsNullOrWhiteSpace($plainPassword) -or
            [string]::IsNullOrWhiteSpace($ouPath)) {

            throw "Puudub kohustuslik väärtus. Vajalikud veerud: Eesnimi, Perenimi, Kasutajanimi, Parool ja OU."
        }

        $safeSam = $sam.Replace("'", "''")
        $existing = Get-ADUser -Filter "SamAccountName -eq '$safeSam'" -ErrorAction SilentlyContinue

        if ($existing) {
            Write-Warning "Kasutaja $sam on juba olemas. Jäeti vahele."

            [pscustomobject]@{
                Kasutajanimi = $sam
                Tulemus      = "Jäeti vahele"
                Selgitus     = "Kasutaja on juba olemas"
            }
            continue
        }

        $targetOUDN = Ensure-OUPath -OUPath $ouPath -DomainDN $domainDN
        $displayName = "$firstName $lastName"
        $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force

        $newUserParams = @{
            Name                  = $displayName
            GivenName             = $firstName
            Surname               = $lastName
            DisplayName           = $displayName
            SamAccountName        = $sam
            UserPrincipalName     = "$sam@$dnsRoot"
            Path                  = $targetOUDN
            AccountPassword       = $securePassword
            Enabled               = $true
            ChangePasswordAtLogon = $true
        }

        if (-not [string]::IsNullOrWhiteSpace($department)) {
            $newUserParams.Department = $department
        }

        New-ADUser @newUserParams

        Write-Host "Loodi kasutaja: $sam ($displayName)" -ForegroundColor Green

        [pscustomobject]@{
            Kasutajanimi = $sam
            Tulemus      = "Loodud"
            Selgitus     = $targetOUDN
        }
    }
    catch {
        Write-Warning "Kasutaja import ebaõnnestus: $($_.Exception.Message)"

        [pscustomobject]@{
            Kasutajanimi = [string]$row.Kasutajanimi
            Tulemus      = "Viga"
            Selgitus     = $_.Exception.Message
        }
    }
}

$logPath = Join-Path $PSScriptRoot ("AD_import_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$results | Export-Csv -LiteralPath $logPath -Delimiter ";" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Import lõpetatud. Logifail: $logPath" -ForegroundColor Cyan
