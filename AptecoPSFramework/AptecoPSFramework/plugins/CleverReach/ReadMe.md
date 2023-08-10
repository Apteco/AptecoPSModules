
# CleverReach Plugin


Create your channel like it is described in the output of the `Install-AptecoPSFramework` command. In the channel settings integration parameter you have the following modes

Mode|Upload Data|Tag Receivers|Copy Mailing|Trigger Broadcast|Setup
-|-|-|-|-|-
Upload and Broadcast|x|x|x|x|Upload and Broadcast
Prepare|x|x|x||Upload and Broadcast<br/>Integration parameter `mode=prepare`
Tagging|x|x|||Retrieve Existing List Names=True<br/>`mode=taggingOnly`
Upload only|x|x|||Upload only


## Modes

### Upload and Broadcast

The whole process from uploading data up to the automatic trigger of a copied mailing.

During the process the module will create new local attributes to the new/existing list, upsert data to it, give the receivers a new tag, create a filter/segment, copy a mailing and schedule it a few seconds later.

To create a new list, just enter a name you would like:

![grafik](https://github.com/Apteco/AptecoPSModules/assets/14135678/1fcca69f-1df5-485c-a74e-ee189197f1fa)

To use an existing list, just open the dropdown and optionally filter it and choose a list:

![grafik](https://github.com/Apteco/AptecoPSModules/assets/14135678/b4177f8c-deee-4f47-b4e1-5b8175bdaf4e)

With this mode and the prepare mode you are able to use the preview functionalities. So you can interactively enter data and get a rendered personalised email preview back from CleverReach. It looks like this:



https://github.com/Apteco/AptecoPSModules/assets/14135678/0321edc1-43d3-4af4-a813-e64160cba92a

Added support for tagging for all modes. It works in upload and preview and works like in this video:


https://github.com/Apteco/AptecoPSModules/assets/14135678/6e3dcab8-1fcb-48d3-9628-b83ca7c00579




### Prepare

The whole process from uploading data up to the preparation of a copied mailing. The difference to the broadcast is the not scheduled mailing. Response data will still be able to be mapped as all IDs are already created and saved for matching.

Set to "Upload and Broadcast"
Integration parameters like `settingsFile=D:\Scripts\CleverReach\PSCleverReachModule\settings.json;mode=prepare`

The mechanism for lists is the same as in "Upload and Broadcast"

### Tagging

Upload your data and tag your receivers with a specific tag you can choose of. Please make sure you dont setup Upload Only, otherwise the MessageName/Tagname will not be transferred by PeopleStage.

The mechanism for lists is the same as in "Upload and Broadcast"

### Upload Only

Please be aware, that you still need to choose a mailing template, but that does not have an effect for the upload.

The mechanism for lists is the same as in "Upload and Broadcast"

## Commands

Besides the default commands for PeopleStage functionalities you have additional command you can use straight away after you have imported the module with

```PowerShell
Import-Module "AptecoPSFramework" -Verbose
Import-Settings -Path "D:\Scripts\CleverReach\PSCleverReachModule\settings.json"
```

There are commands available for

```PowerShell
Get-LocalDeactivated
Get-ReceiversWithTag
Get-Tags
Get-Blocklist
Get-Bounces
Get-GlobalDeactivated
Get-CRGroups
Get-GroupSegments
Get-GroupStats
Get-GroupStatsByRuntime
Remove-TagsAtReceivers
```

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

You can save variables and values into the variable `$Script:pluginDebug` and output it with `Get-PluginDebug`.

If you don't have this function, you can just put this file in your `Public` folder and it will be dot sourced the next time:

```PowerShell
function Get-PluginDebug {

    [CmdletBinding()]
    param ()
    
    process {

        $Script:pluginDebug

    }

}
```



# CleverReach Settings

Please review [DefaultSettings.ps1](AptecoPSFramework/settings/defaultssettings.ps1) in the modules folder AND [the plugins folder](AptecoPSFramework/plugins/settings/defaultssettings.ps1) for more information. Some of the settings are explained here in detail.

* [ ] Add more explanations


Path|Setting|Default|Explanation
-|-|-|-
/|base|https://rest.cleverreach.com/v3/|The default API address for CleverReach
/|contentType|application/json; charset=utf-8|Default content type that will be used for API requests
/|pageSize|500|If paging is used to read information, this is the default pagesize that will be used automatically
/|mailinglimit|999|No of mailings that will be loaded
/|additionalHeaders||additional headers that should automatically be included in the API requests
/|additionalParameters||additional parameters for the Invoke-RestMethod e.g. proxy parameters
/|logAPIrequests|true|Output GET and POST requests in the console window
/token/|tokenUsage|consume|`consume` or `generate`, depending on the mode you are wishing
/token/|tokenFilePath||path for the file containing the token that should be consumed or generated
/upload/|countRowsInputFile|true|Automatically count the number of rows in the input file. This uses streaming and does not parse anything, so it is extremly fast.
/upload/|validateReceivers|true|Uses a CleverReach API call to validate receivers. It removes blacklisted, not active and not in the list contained emails addresses.
/upload/|excludeNotValidReceivers|false|If this is set to true, only active email addresses of the specific list will be used. This does only have an effect when using existing lists. So new contacts will not be uploaded, only existing ones in CleverReach will be used instead.
/upload/|excludeBounces|true|Exclude bounces from upload
/upload/|excludeGlobalDeactivated|false|Exclude deactivated (unsubscribed) receivers from any list (groupid=0)
/upload/|excludeLocalDeactivated|true|Exclude deactivated  (unsubscribed) receivers for the chosen list
/upload/|uploadSize|300|Max no of rows per batch upload call, max of 1000
/upload/|tagSource|Apteco|Default tag source that will be used like `Apteco.a1qhvh3_20230607201732`
/upload/|useTagForUploadOnly|true|adds a tag to receivers, even if no email gets prepared or send out
/upload/|reservedFields|["tags"]|field names that should not be used in uploads
/upload/|loadRuntimeStatistics|true|Loads total, active, inactive, bounced receivers of the group after upserting the data. This loads all receivers on the list, so can need a while and cause many api calls
/broadcast/|defaultReleaseOffset|120|Seconds offset that will added to the current time when broadcasting a mailing
/broadcast/|addPreheaderAfterBody|true|Adding a default preheader after the `<body>`
/broadcast/|preheaderFieldname|AptecoPreheader|The variable/field name that will trigger a preheader insertion/replacement.
/broadcast/|removeNativePreheader|true|Sometimes CleverReach already inserts a preheader into the template. This command removes the native CleverReach Preheader
/broadcast/|defaultContentType|html/text|We cannot read the content type of the mailing, so we are setting it here. Could be "html", "text" or "html/text"
/broadcast/|defaultEditor|eddytor|We cannot read the used editor from the template so we are setting it through this entry. Could be "eddytor", "wizard", "freeform", "advanced", "plaintext"
/broadcast/|defaultOpenTracking|true|We cannot read from the template if the open tracking is active or not. So it will be set through this setting.
/broadcast/|defaultClickTracking|true|We cannot read from the template if the link/click tracking is active or not. So it will be set through this setting.
/broadcast/|defaultLinkTrackingUrl||Could something be like "27.wayne.cleverreach.com"
/broadcast/|defaultLinkTrackingType||Could be "google", "intelliad", "crconnect"
/broadcast/|defaultGoogleCampaignName||Something like "My Campaign" for tracking reports in Google Analytics
/broadcast/|waitUntilFinished|false|PS or Orbit are waiting until mailing is confirmed to be sent off
/broadcast/|maxWaitForFinishedAfterOffset|120|Wait for another 120 seconds (or more or less) until it is confirmed of send off 


# Response Gathering



This plugin has a functionality builtin to load responses with a command.

## Configuration

There are three important requisites:

1. Install the `FastStats Email Response Gatherer` from Apteco on the same machine
1. Create a configuration xml file when executing the configurator at `C:\Program Files\Apteco\FastStats Email Response Gatherer x64\EmailResponseConfig.exe`. Please fill out and then save the file where you like it:
  - Connection String: Your email response database connection string, usually something like `Data Source=localhost;Initial Catalog=RS_Handel;User Id=serviceuser;Password=password123;`
  - Bulk Insert Folder: A folder that is temporarily needed for inserting the data. This path needs to be accessible by the SQL-Server as if the SQL-Server would enter this path
  - PeoplStage connection string: Your PeopleStage database connection string, usually something like `Data Source=localhost;Initial Catalog=PS_Handel;User Id=serviceuser;Password=password123;`
  - Broadcaster: `PowerShell`
  - Username: Could be any dummy value
  - Password: Could be any dummy value
  - Broadcast Parameters: Please have a look at the following table and check each parameter, especially `FTPURL` which points to your folder where you are saving your response files:

Parameter|Value
-|-
CLICKDATECOLUMNNAME|timestamp
CLICKURLCOLUMNNAME|link
DELIVERYDATECOLUMNNAME|timestamp
EMAILCOLUMNNAME|email
EVENTTRIGGEREDDATECOLUMNNAME|timestamp
TYPECOLUMNNAME|MessageType
URNCOLUMNNAME|urn
DATEFORMAT|UnixTimeStamp
RemoveFiles|true
MESSAGENAMECOLUMNNAME|mailingName
FILEPATTERN|responses_*
FTPURL|File://D:\Scripts\CleverReach\PSCleverReachModule\r
DELIMITER|TAB
ENCLOSER|DOUBLEQUOTE
SENDIDCOLUMNNAME|mailingId

3. Check your settings json file
  - So please check your settings json file that you have configured this section. Is it important you have checked at minimum the following settings:
    - fergePath: The path to your response gatherer, usually something like `C:\Program Files\Apteco\FastStats Email Response Gatherer x64\EmailResponseGatherer64.exe`
    - fergeConfigurationXml The path to your xml file that you have created in the previous step

## Gather Responses

Just execute these commands which can also be used for a scheduled task. Please change to the directory where you wish to save the response files to.

```PowerShell
Set-Path -Path "D:\Scripts\CleverReach\PSCleverReachModule\r"
Import-Module "AptecoPSFramework" -Verbose
Import-Settings -Path "D:\Scripts\CleverReach\PSCleverReachModule\settings.json"
Get-Response
```

As per default, FERGE should be automatically triggered after downloading and parsing the response data.

# Automatic Token Refreshment

Still needs to be implemented here. In the meantime have a look here: https://github.com/Apteco/HelperScripts/tree/master/scripts/cleverreach/check-token

# FAQ

## Cleaning

cleanup of tags
cleanup of segments
cleanup of lists

## Usage of multiple settings files

It is supported to have as many settings json files as you wish. Just enter a different filename when you do `Export-Settings -Path ".\settings_new.json` and put the absolute file name into your channel editor integration parameters.

## Remove multiple tags at once

It is easy to combine multiple commands like

```PowerShell
Get-Tags | where { $_.origin -eq "Apteco" } | % { Remove-TagsAtReceivers -Source $_.origin -Tag $_.tag }
```
This command gets all tags, filters it by the first part of the tag and removes this tag from all receivers

## Listing of all segments

This can be easily done with

```PowerShell
$segments = Get-Groups | % { Get-GroupSegments -GroupId $_.id }
$segments
```

## Support of Preheader

Yes, this plugin allows the support of Preheaders. This is not possible to gather from CleverReach API at the moment, so we are using regular expressions to cut out existing preheaders and set a personalised one, which can also use Variables. The removal and replacement only takes place, if you define a preheader variable in Apteco with the Name `AptecoPreheader`. So you see Apteco on the left hand side and my inbox on the right hand side:

![grafik](https://github.com/Apteco/AptecoPSModules/assets/14135678/ce9a3038-cc8d-4e4e-a8a6-1b374af9a988)

The email on the right hand side with preheader also shows an example above how it looks like without a defined preheader variable.

This behaviour is dependent on the broadcast settings named `addPreheaderAfterBody` and `removeNativePreheader`

The preheader html is defined as

```HTML
<div style="display:none;font-size:1px;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;mso-hide:all;">{APTECOPREHEADER}&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;</div>
```

## Deactivated / Unsubscribed receivers

The settings `upload.excludeGlobalDeactivated` (default: `false`) and `upload.excludeLocalDeactivated` (default: `true`) are controlling this behaviour.

If `excludeGlobalDeactivated` is set to `true` and if there is a receiver deactivated on one list and is active on another list, it will be in the result as deactivated.

There is also a setting in CleverReach that puts a deactivation/unsubscription automatically on a Blocklist. This setting causes that those contacts are automatically excluded from uploads in Apteco but also automatically excluded in CleverReach. So it is a double safety net.

## Difference to C# Implementation

There is another already integrated implementation available that uses an older approach where receivers are getting activated and deactivated before the upload when working on existing lists. New lists will be filled with only active receivers. If you already use this implementation, there are two differences:

1. URN field: In the Channel Editor you define the URN field as a parameter. This is not supported yet. So you need to add your URN to the additional variables and give it the label you wish to (like CustomerID).
1. Communication Key: Beforehand, the communication key was always created in CleverReach with an underscore in the name and the description like `COMMUNICATION_KEY`. Now spaces are allowed and lead to an error in PeopleStage and Orbit that shows: `Error[9001]: Failed to sync attributes`. In the detailed log file you also see an HTTP409 Conflict, because the communication key should be created but is already there. Since version `0.0.9` this module will automatically look for a not existing communication key and `communication key` and `communication_key`, so the parallel use of the existing integration and this framework is possible on the same list (but possibly different impacts as the existing integration deactivates receivers).

# TODO

- [x] get lists
- [x] get mailings
- [ ] migrate "refresh token with scheduled task" to here
- [x] setup boilerplate (copy files of a subfolder to somewhere else and hints, that this folder needs to be accessed by a e.g. service and hints to the paths for get-messages etc.)
- [ ] cleanup job of lists and tags -> cmdlets already implemented
- [ ] put token in a separate file (or give the option for it to use multiple settings). Or maybe have a "main" settings file and give an option to export the token and in the other settings file use that one like PeopleStage, too
* [x] check the validations about bounces
* [x] implement and test tags in a field, especially for preview
* [ ] Try an overlay in preview to edit mailing
* [ ] Try to use regex to identify used variables in mailing html and show in preview
* [ ] Umlaute in filenames in debug mode
* [ ] debug mode not set in the plugin itself

# Test

- [ ] additionalParameters and additionalHeaders
- [x] exception for api call
- [x] dependencies
- [x] Differentiate between new lists and existing lists
- [x] test reserverd fields, tags
- [x] check the processid
- [ ] manually expire a token and test the stacktrace
- [ ] test on multiple table levels and their dependency with URN
