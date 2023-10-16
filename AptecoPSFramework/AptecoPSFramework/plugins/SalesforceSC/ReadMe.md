This plugin is used for adding Leads and Contacts to CampaignMembers 

```PowerShell

# Instantiate
Import-Module AptecoPSFramework
Import-Settings .\sfsettings.json

# Get objects and filter them
Get-SFSCObject -verbose | where-object { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru

# Get objects metadata
Get-SFSCObjectMeta -Object "Account" -verbose | fl

# Get objects fields
$fields = Get-SFSCObjectField -Object "Account" -Verbose
$fields | select-object name, label, type, length, defaultValue, picklistValues | Out-GridView

# Get data of an object (builds a soql query internally)
Get-SFSCObjectData -Object "Account" -Fields "Id", "Name" -Limit 10 -Verbose

# Invoke an SOQL query
Invoke-SFSCQuery -Query "Select Id, Name from Account limit 10" #-Bulk #-IncludeAttributes

# Count an object via SOQL query
Invoke-SFSCQuery -Query "Select count() from Account" -verbose -ReturnCount


```


# Quickstart

```PowerShell
# Check your executionpolicy: https:/go.microsoft.com/fwlink/?LinkID=135170
Get-ExecutionPolicy

# Either set it to Bypass to generally allow scripts for current user
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
# or
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Make sure to have PowerShellGet >= 1.6.0
Get-InstalledModule -Name PowerShellGet -MinimumVersion 1.6.0

# Install PowerShellGet with a current version
Install-Module -Name PowerShellGet -force -verbose

# Execute this with elevated rights or with the user you need to execute it with, e.g. the apteco service user
install-script install-dependencies, import-dependencies
install-module writelog
Install-Dependencies -module aptecopsframework


# Import Module and install more dependencies
Import-Module aptecopsframework
Install-AptecoPSFramework -Verbose

#-----------------------------------------------

# Please open another PowerShell window to enforce a reload of that module, recommended with elevated rights, if the plugin has dependencies
Import-Module aptecopsframework -Verbose

# Choose a plugin
$plugin = get-plugins | Where-Object { $_.name -like "*Salesforce*" }

# Install the plugin before loading it (installing dependencies)
Install-Plugin -Guid $plugin.guid

# Import the plugin
import-plugin -Guid $plugin.guid

# Get settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\file.log"
$tokenFile = ".\sf.token"
$tokenSettings = ".\sf_token_settings.json"

# Set the settings
Set-Settings -PSCustom $settings

# Create a token for cleverreach and save the path to it
# The client secret will be asked for when executing the cmdlet
# NOTE: Please exchange [CLIENTID] with your client ID and redirect url here
Request-Token -ClientId "[CLIENTID]" -RedirectUrl "http://localhost:54321/" -SettingsFile $tokenSettings -TokenFile $tokenFile -UseStateToPreventCSRFAttacks

# You are getting asked for a secret, just paste it interactively
# The secret should look like: GQF26T1CR9FSWSJ4CH52ESCDDCJ4X132H91PP3WTFVGCGFQ22SGUQA0P6DH6U

# Save the settings into a file
$settingsFile = ".\settings.json"
Export-Settings -Path $settingsFile

# Register a task for automatic token refreshment
Register-TokenRefreshTask -SettingsFile $settingsFile

#-----------------------------------------------

# Please open another PowerShell window to enforce a reload of that module, recommended with elevated rights, if the plugin has dependencies

# Import the module and the settings file, which contains the plugin settings, too
Import-Module aptecopsframework -Verbose
Import-Settings -Path ".\settings.json"

# List all commands of this plugin
get-command -module "*Salesforce*"

#-----------------------------------------------

# To manually refresh your token later, just execute

Save-NewToken

```