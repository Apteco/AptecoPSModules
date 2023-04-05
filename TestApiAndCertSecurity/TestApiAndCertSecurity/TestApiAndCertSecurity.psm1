
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
# ENUMS
#-----------------------------------------------

# ...


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach {
    $import = $_
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# ...