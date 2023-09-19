
################################################
#
# SCRIPT ROOT
#
################################################

# if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
#     $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# } else {
#     $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
# }

# Set-Location -Path $scriptPath

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
# MODULES
#
################################################

Import-Module "AptecoPSFramework" -Verbose # TODO change later to plain module name
Import-Module "EncryptCredential" # Add this so you can encrypt your credentials, but start this window with your PeopleStage executing server user
# TODO Is this step still needed?
#Set-ExecutionDirectory -Path "."


################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# ADD MORE PLUGINS
#-----------------------------------------------

#Add-PluginFolder "D:\Scripts\CleverReach\Plugins"
#Register-Plugins   # Not needed later on since 0.0.3

#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = @(, (get-plugins | Select-Object guid, name, version, lastUpdate, stage, category, type, path | Out-GridView -PassThru ))

If ($plugin.count -gt 1) {
    Write-Host "Sorry, you have chosen more than 1 plugin"
    exit 1
} elseif ( $plugin.count -eq 0 ) {
    Write-Host "Sorry, you have chosen less than 1 plugin"
    exit 1
}


#-----------------------------------------------
# LOAD THE PLUGIN
#-----------------------------------------------

Import-Plugin -guid $plugin.guid


#-----------------------------------------------
# LOAD THE SETTINGS (GLOBAL + PLUGIN)
#-----------------------------------------------

$settings = Get-settings
#$settings.pluginGuid = $plugin.guid


################################################
#
# CHANGE PARAMETERS
#
################################################

# logfile
$settings.logfile = ".\file.log"


# Override settings
#$settings."pageSize" = 5

# TODO need to remove this later to connecting the api through an APP


#-----------------------------------------------
# SETTINGS FOR 'GENERATE'
#-----------------------------------------------

# $settings.token.tokenUsage = "generate"
# $settings.login.accesstoken = $token
# $settings.login.refreshtoken = $token


#-----------------------------------------------
# SETTINGS FOR 'CONSUME'
#-----------------------------------------------

# $settings.token.tokenUsage = "consume"

# # Define as absolute path
# #$tokenfile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\cr.token") # Or resolve the relative path into absolute
# $tokenfile = "D:\Scripts\CleverReach\check-token214112\cr.token"
# $settings.token.tokenFilePath = $tokenfile


################################################
#
# SET AND EXPORT SETTINGS
#
################################################

Set-Settings -PSCustom $settings
Export-Settings -Path ".\settings.json"
