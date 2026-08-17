#requires -Version 5.1
#requires -Modules DhcpServer

<#
.SYNOPSIS
Koostab DHCP IPv4 raporti:
1) DHCP Server teenuse olek;
2) aktiivsed skoobid;
3) failover-olek;
4) kasutuses olevad IP-aadressid ja MAC-aadressid;
5) reserveeringud;
6) vabad IP-aadressid.
#>

[CmdletBinding()]
param(
    [string]$DhcpServer = "DC1",
    [string]$OutputFolder = (Join-Path $PSScriptRoot "DHCP_Raport")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module DhcpServer

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runFolder = Join-Path $OutputFolder $timestamp
New-Item -ItemType Directory -Path $runFolder -Force | Out-Null

function Convert-IpToText {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value.PSObject.Properties.Name -contains "IPAddressToString") {
        return $Value.IPAddressToString
    }

    if ($Value.PSObject.Properties.Name -contains "IPAddress") {
        $inner = $Value.IPAddress
        if ($inner -and ($inner.PSObject.Properties.Name -contains "IPAddressToString")) {
            return $inner.IPAddressToString
        }
        return [string]$inner
    }

    return [string]$Value
}

# Teenuse olek
try {
    $service = Get-CimInstance `
        -ClassName Win32_Service `
        -ComputerName $DhcpServer `
        -Filter "Name='DHCPServer'" `
        -ErrorAction Stop

    $serviceReport = [pscustomobject]@{
        Server      = $DhcpServer
        ServiceName = $service.Name
        DisplayName = $service.DisplayName
        State       = $service.State
        StartMode   = $service.StartMode
        RaportiAeg  = Get-Date
    }
}
catch {
    # Kui CIM on tulemüüriga piiratud, proovitakse DHCP teenuse vastamist.
    Get-DhcpServerv4Statistics -ComputerName $DhcpServer -ErrorAction Stop | Out-Null

    $serviceReport = [pscustomobject]@{
        Server      = $DhcpServer
        ServiceName = "DHCPServer"
        DisplayName = "DHCP Server"
        State       = "Vastab DHCP-halduspäringule"
        StartMode   = "CIM kaudu tuvastamata"
        RaportiAeg  = Get-Date
    }
}

$serviceReport |
    Export-Csv -LiteralPath (Join-Path $runFolder "DHCP_Teenuse_Olek.csv") `
    -Delimiter ";" -NoTypeInformation -Encoding UTF8

# Skoobid
$allScopes = @(Get-DhcpServerv4Scope -ComputerName $DhcpServer)
$activeScopes = @($allScopes | Where-Object { $_.State -eq "Active" })

$scopeReport = $activeScopes | ForEach-Object {
    [pscustomobject]@{
        Server        = $DhcpServer
        ScopeId       = Convert-IpToText $_.ScopeId
        Name          = $_.Name
        State         = $_.State
        StartRange    = Convert-IpToText $_.StartRange
        EndRange      = Convert-IpToText $_.EndRange
        SubnetMask    = Convert-IpToText $_.SubnetMask
        LeaseDuration = $_.LeaseDuration
    }
}

$scopeReport |
    Export-Csv -LiteralPath (Join-Path $runFolder "DHCP_Aktiivsed_Skoobid.csv") `
    -Delimiter ";" -NoTypeInformation -Encoding UTF8

# Failover
$failoverReport = @()
try {
    $failoverReport = @(Get-DhcpServerv4Failover -ComputerName $DhcpServer -ErrorAction Stop |
        Select-Object Name, PartnerServer, Mode, LoadBalancePercent, ServerRole,
            ReservePercent, MaxClientLeadTime, State, ScopeId)
}
catch {
    $failoverReport = @([pscustomobject]@{
        Name               = "Failover puudub või päring ebaõnnestus"
        PartnerServer      = ""
        Mode               = ""
        LoadBalancePercent = ""
        ServerRole         = ""
        ReservePercent     = ""
        MaxClientLeadTime  = ""
        State              = $_.Exception.Message
        ScopeId            = ""
    })
}

$failoverReport |
    Export-Csv -LiteralPath (Join-Path $runFolder "DHCP_Failover.csv") `
    -Delimiter ";" -NoTypeInformation -Encoding UTF8

# Aktiivsed rendid ehk hetkel kasutuses olevad IP-d
$usedAddresses = foreach ($scope in $activeScopes) {
    $scopeId = $scope.ScopeId

    Get-DhcpServerv4Lease `
        -ComputerName $DhcpServer `
        -ScopeId $scopeId `
        -ErrorAction Stop |
    ForEach-Object {
        [pscustomobject]@{
            Server          = $DhcpServer
            ScopeId         = Convert-IpToText $scopeId
            IPAddress       = Convert-IpToText $_.IPAddress
            MAC_ClientId    = $_.ClientId
            HostName        = $_.HostName
            AddressState    = $_.AddressState
            LeaseExpiryTime = $_.LeaseExpiryTime
        }
    }
}

$usedAddresses |
    Export-Csv -LiteralPath (Join-Path $runFolder "DHCP_Kasutuses_IP_ja_MAC.csv") `
    -Delimiter ";" -NoTypeInformation -Encoding UTF8

# Staatilised rendid ehk reserveeringud
$reservations = foreach ($scope in $activeScopes) {
    $scopeId = $scope.ScopeId

    Get-DhcpServerv4Reservation `
        -ComputerName $DhcpServer `
        -ScopeId $scopeId `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        [pscustomobject]@{
            Server       = $DhcpServer
            ScopeId      = Convert-IpToText $scopeId
            IPAddress    = Convert-IpToText $_.IPAddress
            MAC_ClientId = $_.ClientId
            Name         = $_.Name
            Description  = $_.Description
            Type         = $_.Type
        }
    }
}

$reservations |
    Export-Csv -LiteralPath (Join-Path $runFolder "DHCP_Reserveeringud.csv") `
    -Delimiter ";" -NoTypeInformation -Encoding UTF8

# Vabad IP-aadressid
$freeAddresses = foreach ($scope in $activeScopes) {
    $scopeId = $scope.ScopeId
    $statistics = Get-DhcpServerv4ScopeStatistics `
        -ComputerName $DhcpServer `
        -ScopeId $scopeId `
        -ErrorAction Stop

    $freeCount = 0
    if ($statistics.PSObject.Properties.Name -contains "Free") {
        $freeCount = [int]$statistics.Free
    }
    elseif ($statistics.PSObject.Properties.Name -contains "AddressesFree") {
        $freeCount = [int]$statistics.AddressesFree
    }

    if ($freeCount -gt 0) {
        $addresses = Get-DhcpServerv4FreeIPAddress `
            -ComputerName $DhcpServer `
            -ScopeId $scopeId `
            -NumAddress $freeCount `
            -ErrorAction Stop

        foreach ($address in @($addresses)) {
            [pscustomobject]@{
                Server    = $DhcpServer
                ScopeId   = Convert-IpToText $scopeId
                IPAddress = Convert-IpToText $address
            }
        }
    }
}

$freeAddresses |
    Export-Csv -LiteralPath (Join-Path $runFolder "DHCP_Vabad_IP.csv") `
    -Delimiter ";" -NoTypeInformation -Encoding UTF8

$summary = [pscustomobject]@{
    Server              = $DhcpServer
    RaportiAeg          = Get-Date
    TeenuseOlek         = $serviceReport.State
    AktiivseidSkoope    = @($activeScopes).Count
    AktiivseidRente     = @($usedAddresses).Count
    Reserveeringuid     = @($reservations).Count
    VabuIPAadresse      = @($freeAddresses).Count
    FailoverSeoseid     = @($failoverReport).Count
}

$summary |
    Export-Csv -LiteralPath (Join-Path $runFolder "DHCP_Kokkuvote.csv") `
    -Delimiter ";" -NoTypeInformation -Encoding UTF8

@(
    "DHCP RAPORT"
    "Server: $DhcpServer"
    "Raporti aeg: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
    ""
    "Teenuse olek: $($serviceReport.State)"
    "Aktiivseid skoope: $(@($activeScopes).Count)"
    "Aktiivseid rente: $(@($usedAddresses).Count)"
    "Reserveeringuid: $(@($reservations).Count)"
    "Vabu IP-aadresse: $(@($freeAddresses).Count)"
    ""
    "Raportikaust: $runFolder"
) | Set-Content -LiteralPath (Join-Path $runFolder "DHCP_Kokkuvote.txt") -Encoding UTF8

Write-Host ""
Write-Host "DHCP raport valmis: $runFolder" -ForegroundColor Cyan
$summary | Format-List
