
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


# Available hashing algorithms, referring to https://learn.microsoft.com/de-de/dotnet/api/system.security.cryptography.hashalgorithm.create?view=net-7.0
# and System.Security.Cryptography
# The numeric values are just dummy values
<#
Enum HashName {
    SHA1        = 10
    MD5         = 20
    SHA256      = 30
    SHA384      = 40
    SHA512      = 50
    HMACSHA256  = 60
}
#>


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach-Object {
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

$Script:rnd = [Random]::new()


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# ...