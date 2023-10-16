This plugin is used for reading data from Microsoft Dynamics

More information about setting up your App in a Microsoft account can be found in the PSOAuth module.

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
$plugin = get-plugins | Where-Object { $_.name -like "*Dynamics*" }

# Install the plugin before loading it (installing dependencies)
Install-Plugin -Guid $plugin.guid

# Import the plugin
import-plugin -Guid $plugin.guid

# Get settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\file.log"
$settings.base = "https://orgabcdefg.crm11.dynamics.com"

# Set the settings
Set-Settings -PSCustom $settings

# Create a token for cleverreach and save the path to it
# The client secret will be asked for when executing the cmdlet
$tokenFile = ".\dyn365.token"
$tokenSettings = ".\dyn365_token_settings.json"
$orgId = "d9792e43-ac09-46e5-bbde-4056c3b6792a" # German: Verzeichnis-ID (Mandant)
Request-Token -ClientId "4f6cf54a-96cc-4e71-8a6a-0f018b439e6f" -RedirectUrl "http://localhost:43902/" -SettingsFile $tokenSettings -TokenFile $tokenFile -CrmUrl $settings.base -OrgId $orgId -UseStateToPreventCSRFAttacks

# Please check the redirect url, if it has trailing / in the azure portal

# You are getting asked for a secret (not the secret ID), just paste it interactively
# The secret should look like: DxBMv~MP2krXQ-xvavDVnseXmtuJN6UzEb0u-XUH

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
get-command -module "*Dynamics*"

# Then you can use commands like these
Get-WhoAmI
Get-Account

#-----------------------------------------------

# To manually refresh your token later, just execute

Save-NewToken

```

Use `Request-Token` to use the auth flow to obtain a new token, use `Save-NewToken` to use your refresh token and obtain a new one and save it

The refresh token should have a longer expiration duration, so doing a `Save-NewToken` before doing more, should help