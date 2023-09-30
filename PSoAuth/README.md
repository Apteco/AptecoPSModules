
# General approach

This description needs reworking as a local webserver is supported now!

This oAuth process does work if you are allowed to use Apps for receiving the code instead of a public https website.
The process guids you to the login page of the service you want to receiver an authentication token for. After this it
will be redirected to an app url that this module created beforehand like `myNewApp:\\putinherewhateveryouwant`.
After receiving the code at this app, it will be exchanged with an oAuth token. Sometimes you also get a refresh token.
Both is saved in a local json file, encrypted, if you want to.
This module also supports you in creating a scheduled task in Windows for refreshing. But you have to setup the schedule afterwards.
Sometimes tokens are only for 1 hour, sometimes for 30 days.

Be aware, that you can close your browser window when the whole process is done.

```Powershell

# First install this module
Install-Module PSOAuth -verbose

# Install dependencies for this module
Install-PSOAuth

# Move to the directory where you want everything to be saved
# The logfile will be created in this directory

# Create a token
Request-OAuthApp -SaveSeparateTokenFile
Request-OAuthLocalhost

# Do an api call to refresh the token
# ...

# Refresh the token 
Request-TokenRefresh -SettingsFile "xyz"
```

- This uses the response type `code` and grant=basic
- The second call uses grant_type = "authorization_code"

- Create automated task for refresh
- Create specific functions to ask for token ttl and so forth -> or maybe use aptecopsframework with prebuilt integrations for that

# CleverReach

## Request initial access


Parameter|Value|Explanation
-|-|-
ClientId|ssCNo32SNf|Default and certified CleverReach App for Apteco
ClientSecret||Please ask Apteco
AuthUrl|https://rest.cleverreach.com/oauth/authorize.php
TokenUrl|https://rest.cleverreach.com/oauth/token.php
Protocol|apttoken|The app that will be called to gather the code/token
Scope||This can be left empty

```Powershell
Request-OAuthApp
```

or

```Powershell
$oauthParam = [Hashtable]@{
    "ClientId" = "ssCNo32SNf"
    "ClientSecret" = ""     # ask for this at Apteco, if you don't have your own app
    "AuthUrl" = "https://rest.cleverreach.com/oauth/authorize.php"
    "TokenUrl" = "https://rest.cleverreach.com/oauth/token.php"
    "SaveSeparateTokenFile" = $true
}
Request-OAuthLocalhost @oauthParam
```


## Refresh your access

Request your token with an api call
At moment CleverReach tokens have a ttl of 30 days

```PowerShell
# TEST THIS CODE

# Read settings file
$settings = Get-Content -Path ".\settings.json" -Encoding utf8 -Raw | ConvertFrom-Json -Depth 99

# Build your header
$header = @{
    "Authorization" = "Bearer $( $settings.accesstoken )"
}

# Exchange token
$validateParameters = [Hashtable]@{
    Uri = "https://rest.cleverreach.com/v3/debug/exchange.json"
    Method = "Get"
    Headers = $header
    Verbose = $true
    ContentType = "application/json"
}
$newToken = Invoke-RestMethod @validateParameters

# Log
Write-Verbose -message "Got new token valid for $( $newToken.expires_in ) seconds and scope '$( $newToken.scope )'" -Verbose

# Exchange file
Request-TokenRefresh -SettingsFile $settingsFile -NewAccessToken $newToken.access_token
```


You can save this as a script, if it helps. And create a scheduled task for it.


# Salesforce


## Create an connected app

Create a connected app beforehand

## Request initial access

POST https://login.salesforce.com/services/oauth2/token


Parameter|Value|Explanation
-|-|-
ClientId||ClientID of your Salesforce Connected App
ClientSecret||ClientSecret of your Salesforce Connected App
AuthUrl|https://login.salesforce.com/services/oauth2/authorize
TokenUrl|https://login.salesforce.com/services/oauth2/token
Protocol|sftoken|The app that will be called to gather the code/token
Scope||This can be left empty

## Refresh access

At moment Salesforce tokens have a ttl of 1 hour, so you better create a task for refreshment

Please have a look at the path to your json file, and replace your client_id and client_secret

```PowerShell

# Read settings file
$settingsFile = ".\settings.json"
$settings = Get-Content -Path $settingsFile -Encoding utf8 -Raw | ConvertFrom-Json -Depth 99

# Exchange token
$validateParameters = [Hashtable]@{
    Method = "POST"
    Uri = "https://login.salesforce.com/services/oauth2/token"
    Body = [Hashtable]@{
        "client_id" = "3MVG9I5UQ_0k_hTkyC7dvZDoWszDfra.IGCBVnxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        "client_secret" = "1DBF58393544Exxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        "grant_type" = "refresh_token"
        "refresh_token" = $settings.refreshtoken
    }
    Verbose = $true
}
$newToken = Invoke-RestMethod @validateParameters

# Log
Write-Log -message "Got new token valid for $( $newToken.expires_in ) seconds and scope '$( $newToken.scope )'"

# Exchange file
Request-TokenRefresh -SettingsFile $settingsFile -NewAccessToken $newToken.access_token
```

If you have encrypted your tokens, use `( Get-SecuretoPlaintext $settings.refreshtoken )` instead of `$settings.refreshtoken`


# Microsoft Dynamics Sales 365 (DataVerse)

## Create an Azure App

Create your app through the Azure Portal following these instructions: https://learn.microsoft.com/en-us/power-apps/developer/data-platform/walkthrough-register-app-azure-active-directory#create-an-application-registration


## Request initial access


Parameter|Value|Explanation
-|-|-
ClientId||Please use your `Application ID (Client)` of your created app
ClientSecret||Please use your `Secret ID`, not the Secret itself, of your created app
AuthUrl|https://login.microsoftonline.com/{tenantID}/oauth2/v2.0/authorize|Please replace your `{tenantID}` before using it
TokenUrl|https://login.microsoftonline.com/{tenantID}/oauth2/v2.0/token|Please replace your `{tenantID}` before using it
RedirectURL|http://localhost:43902|This is the url for redirection, please take this from your app
Scope|https://{orgID}.crm.dynamics.com/user_impersonation offline_access|Please replace your `{orgID}` from your dynamics URL












# Supported/Tested Solutions

- CleverReach
- Hubspot Private App
- Salesforce SalesCloud Connected App
- Microsoft Azure App










# OLD - see what is useful



Since CleverReach changed the expiry date of the tokens from three years to 30 days, we have implemented a way of automatic token creation and exchange.

There are two ways of using it:
1. On the app server in a specific place called by a Windows Scheduled Task in a regular rhythm
1. During the Data Build called as a preload or postload action where the file will be automatically deployed to the app server

# Prerequisites

Open the script `cleverreach__00__create_settings.ps1` and have a look at the following parts

If you want to receive notifications about a refreshed or failed token, put this to `$true` or `$false`

```PowerShell
    "sendMailOnCheck" = $true
    "sendMailOnSuccess" = $true
    "sendMailOnFailure" = $true
```

Change the default receiver email address for receiving those notifications

```PowerShell
    "notificationReceiver" = "admin@example.com"
```

If the notifications should be send, make sure to configure the mail settings

```PowerShell
    "mail" = @{
        smptServer = "smtp.example.com"
        port = 587
        from = "admin@example.com"
        username = "admin@example.com"
        password = $smtpPassEncrypted
    }
```

Then you execute that settings creation script. It does not need administrator rights.

NOTE: The script will ask you about the path to store the token. It needs to be accessible to the app server or needs to be put in the system folder so Designer can put the file into the deployment


# Method 1 - Regular Task (Default)

* Change the script as described above
* Execute the script `cleverreach__00__create_settings.ps1` first and you will be asked a few things and your smtp password - if you don't want to use the email notifications just leave it blank or enter some random string
* This will save a `settings.json` file and a token file like `cr.token` in the same folder (as default setting)
* The script will ask you to create a scheduled task automatically that will check and exchange (if needed) the token on a daily schedule. It should look like here in the screenshots<br/><br/>![grafik](https://user-images.githubusercontent.com/14135678/102686228-8257ae80-41e6-11eb-81c0-ff27a4cf45bb.png)<br/><br/>![grafik](https://user-images.githubusercontent.com/14135678/102686233-8c79ad00-41e6-11eb-9e73-825127985a39.png)<br/><br/>![grafik](https://user-images.githubusercontent.com/14135678/102686241-99969c00-41e6-11eb-814e-720cc5d100e0.png)

# Method 2 - Designer Action

* Change the script as described above
* Execute the script `cleverreach__00__create_settings.ps1` first and you will be asked a few things and your smtp password - if you don't want to use the email notifications just leave it blank or enter some random string
* This will save a `settings.json` file and a token file like `cr.token` in the same folder (as default setting). But for this method please make sure to change the path to the system folder like `D:\Apteco\Build\Holidays\cr.token` so it will be automatically deployed to the server
* In Designer create a preload or postload action like this:<br/><br/>![grafik](https://user-images.githubusercontent.com/14135678/102684853-68b16980-41dc-11eb-9e77-e26e1ded749a.png)
* The log is configured to send the log entries to a separate text file AND the Designer log (you can see an example here that the token exchange failed):<br/><br/>![grafik](https://user-images.githubusercontent.com/14135678/102686210-550b0080-41e6-11eb-935b-3f3a3651ba62.png)



# Configure PeopleStage to read token

## Channel Editor

Add the new parameter `Access Token Path` and change it to the local path where the token is saved

![grafik](https://user-images.githubusercontent.com/14135678/104179067-93719500-540b-11eb-92db-f3b8d8cdd9ec.png)

This setting is now possible from Orbit Campaign Channel Editor, too (2021-10-27).

## Response Gatherer

Add the new parameter `ACCESSTOKENPATH` and change it to the local path where the token is saved

![grafik](https://user-images.githubusercontent.com/14135678/104179240-d3387c80-540b-11eb-9ab4-f963fac445e0.png)


# Troubleshooting

```
Send-MailMessage : Das Remotezertifikat ist laut Validierungsverfahren ungültig
The remote certificate is invalid according to the validation procedure.
```

When generating the settings.json file, set `deactivateServerCertificateValidation` to `$true` (Default `$false`)

```
Unable to relay recipient in non-accepted domain
```

Check your mailserver, looks like the (external) recipient is not allowed by the current settings