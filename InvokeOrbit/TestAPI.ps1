

#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false


#-----------------------------------------------
# DIRECTORY
#-----------------------------------------------


$dir = "C:\Users\Florian\Documents\GitHub\AptecoPSModules\InvokeOrbit"

Set-Location -Path $dir
import-module .\InvokeOrbit -Verbose
Set-ExecutionDirectory -Path $dir


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


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode $debug