#-----------------------------------------------
# NOTES
#-----------------------------------------------

<#

Inspired by Tutorial of RamblingCookieMonster in
http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
and
https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psm1

#>


#-----------------------------------------------
# IMPORT IMPORTDEPENDENCY MODULE
#-----------------------------------------------

If ( ( Get-Module -Name ImportDependency ).Count -ge 1 ) {
    Write-Verbose "Module ImportDependency is already imported"
} else {
    Write-Verbose "Importing module ImportDependency"
    Import-Module -Name ImportDependency
}


#-----------------------------------------------
# LOAD DEPENDENCIES
#-----------------------------------------------

. ( Join-Path -Path $PSScriptRoot -ChildPath "/bin/dependencies.ps1" )

If ( $Script:psModules.Count -gt 0 ) {
    Import-Dependency -Module $Script:psModules
}


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -Recurse -ErrorAction SilentlyContinue )

@( $Public + $Private ) | ForEach-Object {
    $import = $_
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
    }
}


#-----------------------------------------------
# LOAD DEFAULT SETTINGS
#-----------------------------------------------

$defaultSettingsFile = Join-Path -Path $PSScriptRoot -ChildPath "/Settings/defaultsettings.ps1"
$Script:settings = . $defaultSettingsFile


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

New-Variable -Name endpoints      -Value $null -Scope Script -Force  # Cached Orbit API endpoint catalog
New-Variable -Name credential     -Value $null -Scope Script -Force  # Credential set via Connect-AptecoOrbit
New-Variable -Name sessionId      -Value $null -Scope Script -Force  # Current Orbit session id
New-Variable -Name sessionToken   -Value $null -Scope Script -Force  # Current Orbit access token (encrypted at rest if settings.encryptToken)
New-Variable -Name sessionExpires -Value $null -Scope Script -Force  # Expiry of the current session


#-----------------------------------------------
# EXPORT PUBLIC FUNCTIONS
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename
