
################################################
#
# SCRIPT ROOT
#
################################################

if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
} else {
    $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

Set-Location -Path $scriptPath


################################################
#
# MODULES
#
################################################

Import-Module "D:\Scripts\PSModules\InvokeCleverReach" -Verbose # TODO change later to plain module name
Set-ExecutionDirectory -Path "."


################################################
#
# SETTINGS
#
################################################

$settings = Get-settings
$settings.logfile = ".\file.log"


################################################
#
# CHANGE PARAMETERS
#
################################################

# Override settings
$settings."pageSize" = 5

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

$settings.token.tokenUsage = "consume"
$settings.token.tokenFilePath = "D:\Scripts\CleverReach\check-token214112\cr.token"


################################################
#
# SET AND EXPORT SETTINGS
#
################################################

Set-Settings -PSCustom $settings
Export-Settings -Path ".\settings.json"
