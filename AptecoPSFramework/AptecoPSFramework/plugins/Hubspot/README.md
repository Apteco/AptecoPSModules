https://developers.hubspot.com/docs/api/working-with-oauth

https://developers.hubspot.com/docs/api/oauth/tokens


Token information, replace [token]
curl --request GET --url https://api.hubapi.com/oauth/v1/access-tokens/[token]

For Hubspot it is important to differentiate between private apps, which don't support oAuth, but just plain access tokens
and the apps in the public marketplace which support oauth.

Currently the access token has no expiration so it will be refreshed when the access token expired and a call is done




# Quickstart with oAuth and public app

Please ask apteco to go through this process

```PowerShell
# Import module
Import-Module aptecopsframework -Verbose

# Load plugins
#Add-PluginFolder -Folder "D:\Scripts\AptecoPSFramework_Plugins"
#Register-Plugins

# Choose plugin and install it
$plugin = get-plugins | where-object { $_.name -like "*Hubspot*" }
Install-Plugin -Guid $plugin.guid
Import-Plugin -Guid $plugin.guid

# Get settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\file.log"

# Set the settings
Set-Settings -PSCustom $settings

# Create a token for hubspot and save the path to it
$tokenFile = ".\hs.token"
$tokenSettings = ".\hs_token_settings.json"
Request-Token -SettingsFile $tokenSettings -TokenFile $tokenFile -UseStateToPreventCSRFAttacks

# Save the settings into a file
$settingsFile = ".\settings.json"
Export-Settings -Path $settingsFile
```

# Quickstart with private app

```PowerShell
# Import module
Import-Module aptecopsframework -Verbose

# Load plugins
#Add-PluginFolder -Folder "D:\Scripts\AptecoPSFramework_Plugins"
#Register-Plugins

# Choose plugin and install it
$plugin = get-plugins | where-object { $_.name -like "*Hubspot*" }
Install-Plugin -Guid $plugin.guid
Import-Plugin -Guid $plugin.guid

# Get settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\file.log"

# Set the settings
Set-Settings -PSCustom $settings

# Save a token for hubspot and save the path to it
Save-PrivateAppToken -TokenFile ".\hs.token"

# Save the settings into a file
Export-Settings -Path ".\settings.json"
```