
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

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -ErrorAction SilentlyContinue -Recurse )

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
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# Define the variables
New-Variable -Name timestamp -Value $null -Scope Script -Force      # Start time of this module
New-Variable -Name moduleRoot -Value $null -Scope Script -Force     # Current location root of this module
New-Variable -Name defaultStorefile -Value $null -Scope Script -Force  # Default path for all settings
New-Variable -Name store -Value $null -Scope Script -Force        # Default json storage template
New-Variable -Name Debug -Value $null -Scope Script -Force        # debug variable to test things on
New-Variable -Name localLibFolder -Value $null -Scope Script -Force        # app folder for settings of this module
New-Variable -Name libFolderLoadedIndicator -Value $null -Scope Script -Force        # app folder for settings of this module


# Set the variables now
$Script:timestamp = [datetime]::Now
$Script:moduleRoot = $PSScriptRoot.ToString()
$Script:libFolderLoadedIndicator = $false

# Default json storage template
$Script:store = [PSCustomObject]@{
    "lastChange" = [datetime]::Now.ToString("yyyyMMddHHmmss")
    "channels" = [Array]@()
    "additionalHeaders" = [PSCustomObject]@{}
    "groups" = [Array]@()
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

# Default folders and files
$localAppData = [Environment]::GetFolderPath("LocalApplicationData")
$localTargetFolder = "$( $localAppData )/AptecoPSModules/PSNotify"
$Script:defaultStorefile = "$( $localTargetFolder )/store.json"
$Script:localLibFolder = "$( $localTargetFolder )/lib"

# Check if the modules path is valid and if so and the folder does not exist, create it
If ( (Test-Path -Path $localTargetFolder -IsValid) -eq $true ) {
    If ( (Test-Path -Path $localTargetFolder) -eq $false ) {
        New-Item -Path $localTargetFolder -ItemType Directory
    }
}

# Check if the lib path is valid and if so and the folder does not exist, create it
If ( (Test-Path -Path $localLibFolder -IsValid) -eq $true ) {
    If ( (Test-Path -Path $localLibFolder) -eq $false ) {
        New-Item -Path $localLibFolder -ItemType Directory
    }
}

# Setting it to null for now
#$Script:keyfile = $null

# If the file exists, read it, otherwise create it
If ( (Test-Path -Path $defaultStorefile) -eq $true ) {
    Get-Store
} Else {
    Set-Store
}

# Some verbose information
$resolvedStorefile = Resolve-Path -Path $defaultStorefile
Write-Verbose -Message "Default path for keyfile:$( $resolvedStorefile.Path )"


#-----------------------------------------------
# HANDLE STORE
#-----------------------------------------------



#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename
#Export-ModuleMember -Function $Private.Basename


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# ...