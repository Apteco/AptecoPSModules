
################################################
#
# INPUT
#
################################################

# Param(
#     [hashtable] $params
# )


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false


#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

# if ( $debug -eq $true ) {

#     $params = [hashtable]@{
#         Password = 'ko'
#         Username = 'ko'
#         #scriptPath = 'C:\faststats\Scripts\cleverreach'
#         settingsFile = '.\settings.json'
#         #mode='taggingOnly'
#     }

# }


################################################
#
# NOTES
#
################################################

<#

bla bla

#>


################################################
#
# SCRIPT ROOT
#
################################################
<#
if ( $debug -eq $true ) {

    if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
        $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    }

    $params.scriptPath = $scriptPath

}

# Some local settings
$dir = $params.scriptPath
Set-Location $dir
#>

#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

$modulePath = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
    #C:\Program Files\PowerShell\Modules
    #c:\program files\powershell\7\Modules
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("windir") )\system32\WindowsPowerShell\v1.0\Modules"
)
$Env:PSModulePath = ( $modulePath | Sort-Object -unique ) -join ";"
# Using $env:PSModulePath for only temporary override


#-----------------------------------------------
# ADD SCRIPT PATH, IF NOT PRESENT
#-----------------------------------------------

#$envVariables = [System.Environment]::GetEnvironmentVariables()
$scriptPath = @( [System.Environment]::GetEnvironmentVariable("Path") -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Scripts"
)
$Env:Path = ( $scriptPath | Sort-Object -unique ) -join ";"
# Using $env:Path for only temporary override


################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# IMPORT MODULE
#-----------------------------------------------

Import-Module "AptecoPSFramework" -Verbose
#Set-ExecutionDirectory -Path $dir


#-----------------------------------------------
# ADD MORE PLUGINS
#-----------------------------------------------

#Add-PluginFolder "D:\Scripts\CleverReach\Plugins"


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

# Set-DebugMode -DebugMode $debug


#-----------------------------------------------
# SETTINGS
#-----------------------------------------------

# Set the settings
<#
$settings = Get-settings
$settings.logfile = ".\file.log"
Set-Settings -PSCustom $settings
#>
Import-Settings -Path ".\settings.json"


################################################
#
# PROGRAM
#
################################################

# TODO [x] check if we need to make a try catch here -> not needed, if we use a combination like

<#
            $msg = "Temporary count of $( $mssqlResult ) is less than $( $rowsCount ) in the original export. Please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

#>


#-----------------------------------------------
# GET MESSAGES
#-----------------------------------------------


# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    $return = Get-Response

    # Return the values, if succeeded
    $return

} catch {

    throw $_.Exception
    Exit 1

}




