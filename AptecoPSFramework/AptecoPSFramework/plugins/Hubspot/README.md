https://developers.hubspot.com/docs/api/working-with-oauth

https://developers.hubspot.com/docs/api/oauth/tokens


Token information, replace [token]
curl --request GET --url https://api.hubapi.com/oauth/v1/access-tokens/[token]

For Hubspot it is important to differentiate between private apps, which don't support oAuth, but just plain access tokens
and the apps in the public marketplace which support oauth.

Currently the access token has no expiration so it will be refreshed when the access token expired and a call is done


This implementation works well with all v3 CRM-APIs

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

# Quickstart with private app and token

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



```PowerShell
# Get properties of contacts
get-property -Object contacts | Out-GridView

# This returns all properties automatically
get-crmdata -Object contacts -LoadAllProperties

# This returns only selected properties - Hubspot always delivers hs_object_id, lastmodifieddate and createdate with it
get-crmdata -Object contacts -Properties anrede, email -limit 3

anrede createdate               email                            hs_object_id lastmodifieddate
------ ----------               -----                            ------------ ----------------
Herr   2020-06-18T06:40:47.992Z ex.ample@example.com             41101        2023-10-19T14:39:15.495Z
       2019-03-14T16:17:54.478Z abcdef.ddfasdf@ggg.de            108802       2023-08-07T09:50:06.778Z
       2019-03-14T16:17:54.507Z lkdhsa.aslsie@abc.de             108804       2023-08-07T09:50:09.493Z

# To get the wrapped data (like it is sent from hubspot) just add the flag -AddWrapper, shwon as a list
get-crmdata -Object contacts -Properties anrede, email -limit 3 -AddWrapper | fl

id         : 41101
properties : @{anrede=Herr; createdate=2020-06-18T06:40:47.992Z; email=ex.ample@example.com; hs_object_id=41101; lastmodifieddate=2023-10-19T14:39:15.495Z}
createdAt  : 2020-06-18T06:40:47.992Z
updatedAt  : 2023-10-19T14:39:15.495Z
archived   : False

id         : 108802
properties : @{anrede=; createdate=2019-03-14T16:17:54.478Z; email=abcdef.ddfasdf@ggg.de; hs_object_id=108802; lastmodifieddate=2023-08-07T09:50:06.778Z}
createdAt  : 2019-03-14T16:17:54.478Z
updatedAt  : 2023-08-07T09:50:06.778Z
archived   : False

id         : 108804
properties : @{anrede=; createdate=2019-03-14T16:17:54.507Z; email=lkdhsa.aslsie@abc.de; hs_object_id=108804; lastmodifieddate=2023-08-07T09:50:09.493Z}
createdAt  : 2019-03-14T16:17:54.507Z
updatedAt  : 2023-08-07T09:50:09.493Z
archived   : False


# To get the associations with the record, just add the -associations parameter like here, shown as json to show the nesting
get-crmdata -Object contacts -Properties anrede, email -limit 3 -addwrapper -Associations Companies, Contacts -verbose | ConvertTo-Json -Depth 99
VERBOSE: GET
https://api.hubapi.com/crm/v3/objects/contacts?archived=False&properties=anrede,email&limit=3&associations=Companies,Co
ntacts with 0-byte payload
VERBOSE: received -1-byte response of content type application/json;charset=utf-8
[
    {
        "id":  "41101",
        "properties":  {
                           "anrede":  "Herr",
                           "createdate":  "2020-06-18T06:40:47.992Z",
                           "email":  "ex.ample@example.com",
                           "hs_object_id":  "41101",
                           "lastmodifieddate":  "2023-10-19T14:39:15.495Z"
                       },
        "createdAt":  "2020-06-18T06:40:47.992Z",
        "updatedAt":  "2023-10-19T14:39:15.495Z",
        "archived":  false,
        "associations":  {
                             "companies":  {
                                               "results":  [
                                                               {
                                                                   "id":  "7981616015",
                                                                   "type":  "contact_to_company"
                                                               },
                                                               {
                                                                   "id":  "7981616015",
                                                                   "type":  "contact_to_company_unlabeled"
                                                               }
                                                           ]
                                           }
                         }
    },
    ...

# To load just active records ids (to sort out the deleted ones without receiving a delete webhook)
( get-crmdata -Object contacts -LoadAllRecords -AddWrapper -verbose ).id


# To filter/search for data, define a filter first and then use it
# This is a basic use of the filter which does not allow multiple filtergroups at the moment
# If you need multiple filter groups, just let us know or create a pull request
# Good source for possible filters is here: https://developers.hubspot.com/docs/api/crm/contacts and search for "search"
# These properties will automatically returned, when using filters: https://developers.hubspot.com/docs/api/crm/search
$filter = [Array](
    [Ordered]@{
        "propertyName"="hubspotscore"
        "operator"="GTE"
        "value"="0"
    }
)
get-crmdata -Object contacts -Limit 10 -verbose -Filter $filter -Sort hubspotscore -properties email, firstname, lastname

# Or to load all records for that filter (hubspot only allows 100 records per request, and only 4 searches per second so it can take a while)
$c = get-crmdata -Object contacts -verbose -Filter $filter -Sort hubspotscore -properties email, firstname, lastname -LoadAllRecords
$c | out-gridview



# Load all lists
Get-List -LoadAllLists

# Search for a list
Get-List -Query "Free"

# Add a member to a list (this needs to be the ILS-List-ID)
# You get a status in the result in recordIdsAdded and recordIdsMissing
# Already existing members on that list are not listed in the result
Add-ListMember -ListId 355 -AddMemberships 463451

# Add multiple members to a list
Add-ListMember -ListId 355 -AddMemberships 463451, 456

# Get ListMember
Get-ListMember -ListId 355

# Remove ListMember
Remove-ListMember -ListId 355 -AddMemberships 463451

```

