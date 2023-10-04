
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

# Default folders and files
$localAppData = [Environment]::GetFolderPath("LocalApplicationData")
$localTargetFolder = Join-Path -Path $localAppData -ChildPath "/AptecoPSModules" #"$( $localAppData )/AptecoPSModules"
$Script:defaultKeyfile = Join-Path -Path $localTargetFolder -ChildPath "/key.aes" #"$( $localTargetFolder )/key.aes"

# Check if the path is valid and if so and the folder does not exist, create it
If ( (Test-Path -Path $localTargetFolder -IsValid) -eq $true ) {
    If ( (Test-Path -Path $localTargetFolder) -eq $false ) {
        New-Item -Path $localTargetFolder -ItemType Directory
    }
}

# Some verbose information
Write-Verbose -Message "Default path for keyfile:$( $defaultKeyfile )" #-Verbose
Write-Verbose -Message "If you want to use another path, use 'Export-Keyfile -Path' to save it." #-Verbose
Write-Verbose -Message "Use 'Import-Keyfile -Path' for loading that file" #-Verbose

# Setting it to null for now
$Script:keyfile = $null


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# ...