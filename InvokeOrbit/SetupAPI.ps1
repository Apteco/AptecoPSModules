
#-----------------------------------------------
# TEST
#-----------------------------------------------

"Hello world"


#-----------------------------------------------
# LOAD THIS MODULE
#-----------------------------------------------

Set-Location -Path "C:\Users\Florian\Documents\GitHub\AptecoPSModules\InvokeOrbit"
import-module .\InvokeOrbit -Verbose

Set-ExecutionDirectory -Path "C:\Users\Florian\Documents\GitHub\AptecoPSModules\InvokeOrbit"


#-----------------------------------------------
# CREATE OR IMPORT SETTINGS
#-----------------------------------------------

# Create this settings once
$settings = Get-Settings

$settings.logfile = "C:\Users\Florian\Documents\GitHub\AptecoPSModules\InvokeOrbit\test.log"

import-module EncryptCredential
$pass = Read-Host -AsSecureString "Please enter the password for your api user"
$passEncrypted = Convert-PlaintextToSecure -String ((New-Object System.Management.Automation.PSCredential ('dummy', $pass) ).GetNetworkCredential().Password) 
$settings.login.pass = $passEncrypted

Set-Settings -PSCustom $settings
Export-Settings -Path ".\settings.json"