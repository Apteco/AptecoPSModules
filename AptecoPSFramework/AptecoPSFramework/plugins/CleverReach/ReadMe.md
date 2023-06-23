
# CleverReach Plugin


Create your channel like it is described in the output of the `Install-AptecoPSFramework` command. In the channel settings integration parameter you have the following modes

Mode|Upload Data|Tag Receivers|Copy Mailing|Trigger Broadcast|Setup
-|-|-|-|-|-
Upload and Broadcast|x|x|x|x|Upload and Broadcast<br/>abc
Prepare|x|x|x||Upload and Broadcast<br/>Integration parameter `mode=prepare`
Tagging|x|x|||Append To List = True<br/>Retrieve Existing List Names=True<br/>mode=taggingOnly
Upload only|x||||Upload only


## Modes

### Upload and Broadcast

The whole process from uploading data up to the automatic trigger of a copied mailing.

During the process the module will create new local attributes to the new/existing list, upsert data to it, give the receivers a new tag, create a filter/segment, copy a mailing and schedule it a few seconds later.

### Prepare

The whole process from uploading data up to the preparation of a copied mailing. The difference to the broadcast is the not scheduled mailing. Response data will still be able to be mapped as all IDs are already created and saved for matching.

Set to "Upload and Broadcast"
Integration parameters like `scriptPath=D:\Scripts\CleverReach\PSCleverReachModule;settingsFile=.\settings.json;mode=prepare`

### Tagging

Upload your data and tag your receivers with a specific tag you can choose of. Please make sure you dont setup Upload Only, otherwise the MessageName will not be transferred by PeopleStage.


### Upload Only

Please be aware, that you still need to choose a mailing template, but that does not have an effect for the upload.


## Debugging

```PowerShell
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSModules\InvokeCleverReach\InvokeCleverReach"
```

To change the source code and debug it, start always a new powershell session because modules cannot be overloaded. Do it like if you want to use other credentials

```PowerShell
$cred = Get-Credential
start-process powershell.exe -WorkingDirectory "C:\faststats\scripts\cleverreach" -Credential ($cred)
```

To use the same user, just do it like

```PowerShell
start-process powershell.exe -WorkingDirectory "C:\faststats\scripts\cleverreach"
```

# CleverReach Settings

Please review [DefaultSettings.ps1](AptecoPSFramework/settings/defaultssettings.ps1) in the modules folder AND [the plugins folder](AptecoPSFramework/plugins/settings/defaultssettings.ps1) for more information. Some of the settings are explained here in detail.

* [ ] Add more explanations


Path|Setting|Default|Explanation
-|-|-|-
/|base|https://rest.cleverreach.com/v3/|The default API address for CleverReach
/|pageSize|500|If paging is used to read information, this is the default pagesize that will be used automatically
/upload/|countRowsInputFile|true|Automatically count the number of rows in the input file. This uses streaming and does not parse anything, so it is extremly fast.
/upload/|validateReceivers|true|Uses a CleverReach API call to validate receivers. It removes blacklisted, not active and not in the list contained emails addresses.
/upload/|excludeNotValidReceivers|false|If this is set to true, only active email addresses of the specific list will be used. This does only have an effect when using existing lists. So new contacts will not be uploaded, only existing ones in CleverReach will be used instead.

# Response Gathering

# Automatic Token Refreshment

# FAQ

## Cleaning

cleanup of tags
cleanup of segments
cleanup of lists

## Usage of multiple settings files

test reserverd fields
check the processid
manually expire a token and test the stacktrace




# TODO

- [x] get lists
- [x] get mailings
- [ ] migrate "refresh token with scheduled task" to here
- [x] setup boilerplate (copy files of a subfolder to somewhere else and hints, that this folder needs to be accessed by a e.g. service and hints to the paths for get-messages etc.)
- [ ] cleanup job of lists and tags
- [ ] put token in a separate file (or give the option for it to use multiple settings). Or maybe have a "main" settings file and give an option to export the token and in the other settings file use that one like PeopleStage, too
* [ ] check the validations about bounces

# Test

- [ ] additionalParameters and additionalHeaders
- [ ] exception for api call
- [ ] dependencies
- [ ] Differentiate between new lists and existing lists
