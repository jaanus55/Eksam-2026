#requires -Version 5.1
#requires -Modules ActiveDirectory

<#
.SYNOPSIS
Koostab Active Directory kontode raporti:
1) kontod, mis pole kunagi domeeni loginud;
2) keelatud kontod;
3) lukustatud kontod.
#>

[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path $PSScriptRoot "AD_Raport")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runFolder = Join-Path $OutputFolder $timestamp
New-Item -ItemType Directory -Path $runFolder -Force | Out-Null

$allUsers = Get-ADUser -Filter * -Properties `
    LastLogonDate, Enabled, WhenCreated, DistinguishedName

$neverLoggedOn = $allUsers |
    Where-Object { $null -eq $_.LastLogonDate } |
    Sort-Object SamAccountName |
    Select-Object Name, SamAccountName, Enabled, WhenCreated, DistinguishedName

$disabledUsers = $allUsers |
    Where-Object { $_.Enabled -eq $false } |
    Sort-Object SamAccountName |
    Select-Object Name, SamAccountName, LastLogonDate, WhenCreated, DistinguishedName

$lockedUsers = Search-ADAccount -LockedOut -UsersOnly |
    Get-ADUser -Properties LastLogonDate, Enabled, WhenCreated, DistinguishedName |
    Sort-Object SamAccountName |
    Select-Object Name, SamAccountName, Enabled, LastLogonDate, WhenCreated, DistinguishedName

$neverPath = Join-Path $runFolder "AD_Kunagi_Logimata.csv"
$disabledPath = Join-Path $runFolder "AD_Keelatud_Kontod.csv"
$lockedPath = Join-Path $runFolder "AD_Lukustatud_Kontod.csv"
$summaryPath = Join-Path $runFolder "AD_Kokkuvote.csv"
$textPath = Join-Path $runFolder "AD_Kokkuvote.txt"

$neverLoggedOn | Export-Csv -LiteralPath $neverPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
$disabledUsers | Export-Csv -LiteralPath $disabledPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
$lockedUsers | Export-Csv -LiteralPath $lockedPath -Delimiter ";" -NoTypeInformation -Encoding UTF8

$summary = [pscustomobject]@{
    RaportiAeg          = Get-Date
    KoikKasutajakontod  = @($allUsers).Count
    KunagiLogimata      = @($neverLoggedOn).Count
    KeelatudKontod      = @($disabledUsers).Count
    LukustatudKontod    = @($lockedUsers).Count
}

$summary | Export-Csv -LiteralPath $summaryPath -Delimiter ";" -NoTypeInformation -Encoding UTF8

@(
    "ACTIVE DIRECTORY KONTODE RAPORT"
    "Raporti aeg: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
    ""
    "Kõik kasutajakontod: $(@($allUsers).Count)"
    "Kunagi domeeni logimata: $(@($neverLoggedOn).Count)"
    "Keelatud kontod: $(@($disabledUsers).Count)"
    "Lukustatud kontod: $(@($lockedUsers).Count)"
    ""
    "Detailfailid:"
    $neverPath
    $disabledPath
    $lockedPath
) | Set-Content -LiteralPath $textPath -Encoding UTF8

Write-Host ""
Write-Host "AD raport valmis: $runFolder" -ForegroundColor Cyan
$summary | Format-List
