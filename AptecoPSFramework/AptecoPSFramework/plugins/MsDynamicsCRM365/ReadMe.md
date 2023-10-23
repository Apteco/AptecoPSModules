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

# Usage

To list all table

```PowerShell
Get-Table
```

Or get more details

```PowerShell
Get-TableDetail -TableName accounts, contacts | Out-GridView
```

Or search for tables containing `contacts`

```PowerShell
Get-Table | where { $_.name -like "*contact*" }
```

List Contacts and Accounts

List any table, limited by 3 records

```PowerShell
get-record -TableName contacts -top 3 | Out-GridView
```

Get a specific record by id and resolve guids

```PowerShell
get-record -TableName contacts -id "cdcfa450-cb0c-ea11-a813-000d3a1b1223" -ResolveLookups
```

Filter contacts by gender and give back 3 records

```PowerShell
get-record -TableName "contacts" -verbose -filter "gendercode eq 1" -top 3
```

Filter contacts by gender and modifiedon date

```PowerShell
# tipp: use this format to create the right date time format
# [datetime]::UtcNow.toString("yyyy-MM-ddTHH:mm:ssZ")
# or just
# [DateTime]::UtcNow.ToString('u')
get-record -TableName "contacts" -verbose -filter "gendercode eq 1 and modifiedon gt 2023-09-13T00:00:00Z"
```

More about filters can be found here: https://learn.microsoft.com/de-de/power-apps/developer/data-platform/webapi/query-data-web-api





Only return `contactid` and `fullname`

```PowerShell
get-record -TableName "contacts" -verbose -select contactid,fullname
```


Count all records in contacts table

```PowerShell
get-record -TableName contacts -count
```

or filter and count
```PowerShell
get-record -TableName "contacts" -verbose -filter "gendercode eq 1 and modifiedon gt 2023-09-13T00:00:00Z" -count
```

This command will always show you the first page of data (which is 5000 records by default), if you want to load all pages, use the `-paging` flag like

```PowerShell
get-record -TableName contacts -select fullname,lastname -verbose -paging
```


Some objects support delta tracking, which is really a nice way to load changes instead of timestamps, so doing this at the first step

```PowerShell
# Find out which tables support deltatracking
Get-Record -TableName EntityDefinitions -filter "ChangeTrackingEnabled eq true and IsCustomEntity eq false" -select LogicalName

# At the first call, define your recordset
# This will create a deltatracking.json file in your current directory which saves the deltalink for the next call
Get-Record -TableName contacts -Select fullname, lastname -DeltaTracking -Paging

# This call will look for a deltatracking.json file in your current directory and will reuse that link and save the new one
Get-Record -TableName contacts -LoadDelta

```

For example here you can see the results of new/updated records (first object) and a deleted objects (second object):

```PowerShell
$e = Get-Record -TableName contacts -LoadDelta
$e | convertto-json
[
    {
        "@odata.etag":  "W/\"5105446\"",
        "fullname":  "Christoph Braun",
        "lastname":  "Braun",
        "contactid":  "075de5a8-56d0-ea11-a812-000d3a1bbd52"
    },
    {
        "@odata.context":  "https://orgbdda5a9d.crm11.dynamics.com/api/data/v9.2/$metadata#contacts/$deletedEntity",
        "id":  "2dd54287-c371-ee11-8179-6045bdc1ef70",
        "reason":  "deleted"
    }
]

# So to differentiate this command is helpful
# Load deletes
$e | where { $_."@odata.context" -like "*deletedEntity" } | select id, reason

id                                   reason
--                                   ------
2dd54287-c371-ee11-8179-6045bdc1ef70 deleted

# Load new/updated
$e | where { $_."@odata.context" -notlike "*deletedEntity" }
```

Good explanations on delta tracking: https://bengribaudo.com/blog/2021/05/06/5704/dataverse-web-api-tip-deltas-tracking-changes






To retrieve picklist values per table, this is a good choice. Just replace `contact` with the table you need:

```PowerShell
get-record -TableName "EntityDefinitions(LogicalName='contact')/Attributes/Microsoft.Dynamics.CRM.PicklistAttributeMetadata" -select LogicalName,OptionSet -expand 'GlobalOptionSet($select=Options)'
```

You get a table for that:

```PowerShell
PS C:\Users\Florian\Downloads\20231016\ms> $p

LogicalName                  MetadataId                           GlobalOptionSet
-----------                  ----------                           ---------------
accountrolecode              ef5e9b87-e4e4-4f7b-bbae-5115f968bbfb @{MetadataId=a3b48905-7d78-47d1-bb56-da3cbd0975ca; Options=System.Object[]}
address1_addresstypecode     81c142ea-db05-48cd-9387-175b4246794d @{MetadataId=8b6e9a56-6a18-4b17-9f5d-cfdbd46d9e0b; Options=System.Object[]}
address1_freighttermscode    24858aea-93fd-4dfd-a51d-d289b0135a39 @{MetadataId=919726a2-8436-44ef-8c66-6117c442b862; Options=System.Object[]}
address1_shippingmethodcode  05e0cbb6-bb5b-4d8f-ace9-7cfc1f2a04ee @{MetadataId=b01576e7-514c-45d5-a264-e4fbfd53f615; Options=System.Object[]}
address2_addresstypecode     dbcf375a-eb4d-4891-9f04-3ea869779d57 @{MetadataId=c4714e0b-7573-4f51-8cb7-46fc321a5089; Options=System.Object[]}
address2_freighttermscode    0eb29dd1-3dd2-49e5-b8ea-8b2485477207 @{MetadataId=dc2aabc1-4efa-4667-b474-1aad1b4cf244; Options=System.Object[]}
address2_shippingmethodcode  c335ab4e-5383-4bb6-b8b5-f33ac2348e9e @{MetadataId=60d225d8-b4ab-4e5a-9d18-3dd946e1a413; Options=System.Object[]}
address3_addresstypecode     0f366b5b-f2e9-4378-bc84-6d796b2c29f4 @{MetadataId=97534134-54f6-42fa-914b-2f1531cddfdc; Options=System.Object[]}
address3_freighttermscode    0b045097-c546-41b5-9d01-1352fd3f6b85 @{MetadataId=2a18f883-f938-432f-b27f-e23e507bdf08; Options=System.Object[]}
address3_shippingmethodcode  5449c9d1-d7f7-42a8-8033-60dc1b239595 @{MetadataId=147717a9-2dff-4bc5-9f9e-de99ae7c1c86; Options=System.Object[]}
customersizecode             bffd7570-2899-492b-97d8-a45208eb2114 @{MetadataId=97a8f6fc-e23a-4279-99c0-df748136e38b; Options=System.Object[]}
customertypecode             cd0cefe1-b185-4795-a05c-3f27c205f21e @{MetadataId=ee3ff3c1-739e-4dc6-a452-c85f3d52814e; Options=System.Object[]}
educationcode                1f1a7b51-b139-453a-a1cb-e2899494e1a3 @{MetadataId=96b15669-cfc3-42f9-aa6a-8f0595182c30; Options=System.Object[]}
familystatuscode             18d22cd0-f923-4d46-97e2-9decc997d285 @{MetadataId=2da4a488-81c9-419d-ad1c-fb0d33a1e0ef; Options=System.Object[]}
gendercode                   a81e86c9-e2e1-4c1e-81ab-8913eedaab47 @{MetadataId=cb7f9ccb-21b2-45b5-acf5-0a62344d0860; Options=System.Object[]}
haschildrencode              37861c8f-246f-4534-a91e-6f27aeee1243 @{MetadataId=ced703d8-357b-4e56-94ec-1a045156036f; Options=System.Object[]}
leadsourcecode               853b2009-216c-4c0e-9abc-dfd285210a82 @{MetadataId=e9e66ceb-7c14-4c03-a182-b2013d38797c; Options=System.Object[]}
msdyn_decisioninfluencetag   3689c54e-3790-47ef-a00a-d0b225b06a56 @{MetadataId=878145e5-914f-ee11-be6f-00224842b21c; Options=System.Object[]}
msdyn_orgchangestatus        780a7299-1b22-4e1a-907d-d1cc2af21724 @{MetadataId=838145e5-914f-ee11-be6f-00224842b21c; Options=System.Object[]}
mspp_userpreferredlcid       cfc9bc75-f6ad-426e-92c3-7453e7f37fb3 @{MetadataId=c50ef413-89cc-4442-b44a-8d5c4484375e; Options=System.Object[]}
paymenttermscode             384614ff-b79c-4009-9bec-7dedf8c7b99c @{MetadataId=7154ab7b-7c99-4712-9d8c-7eaaae4f6f78; Options=System.Object[]}
preferredappointmentdaycode  42741f7e-dc25-4857-84d6-b4ecab8d9e2e @{MetadataId=51769958-f7a4-41b4-a3ea-0992249c6b17; Options=System.Object[]}
preferredappointmenttimecode 89802cd9-fe13-4612-8cac-e3593d3da38b @{MetadataId=5b1d1539-a020-4a16-8f31-c57fce454b53; Options=System.Object[]}
preferredcontactmethodcode   3423a9b1-891b-44cb-a9b9-28d5a4ffb628 @{MetadataId=4b838079-0334-49b3-9f72-0434392dab2c; Options=System.Object[]}
shippingmethodcode           ff7d514a-d8ac-41b5-931c-c344aac35849 @{MetadataId=334b102e-4481-41a5-9b27-8e39ecd9e496; Options=System.Object[]}
territorycode                aa3e1fe6-cd5c-424b-b54c-7b17474c47bf @{MetadataId=e3d3f048-333e-4b83-9d87-609f4ee093f3; Options=System.Object[]}
```

And in the GlobalOptionSet there are nested the picklist choices you need:

Here is just an example for `gendercode`

```PowerShell
PS C:\Users\Florian\Downloads\20231016\ms> ( $p | where { $_.logicalname -eq "gendercode" } ) | convertto-json -Depth 99
{
    "LogicalName":  "gendercode",
    "MetadataId":  "a81e86c9-e2e1-4c1e-81ab-8913eedaab47",
    "GlobalOptionSet":  {
                            "MetadataId":  "cb7f9ccb-21b2-45b5-acf5-0a62344d0860",
                            "Options":  [
                                            {
                                                "Value":  1,
                                                "Color":  null,
                                                "IsManaged":  true,
                                                "ExternalValue":  null,
                                                "ParentValues":  [

                                                                 ],
                                                "Tag":  null,
                                                "MetadataId":  null,
                                                "HasChanged":  null,
                                                "Label":  {
                                                              "LocalizedLabels":  [
                                                                                      {
                                                                                          "Label":  "Männlich",
                                                                                          "LanguageCode":  1031,
                                                                                          "IsManaged":  true,
                                                                                          "MetadataId":  "96a9c7f4-2241-db11-898a-0007e9e17ebd",
                                                                                          "HasChanged":  null
                                                                                      }
                                                                                  ],
                                                              "UserLocalizedLabel":  {
                                                                                         "Label":  "Männlich",
                                                                                         "LanguageCode":  1031,
                                                                                         "IsManaged":  true,
                                                                                         "MetadataId":  "96a9c7f4-2241-db11-898a-0007e9e17ebd",
                                                                                         "HasChanged":  null
                                                                                     }
                                                          },
                                                "Description":  {
                                                                    "LocalizedLabels":  [

                                                                                        ],
                                                                    "UserLocalizedLabel":  null
                                                                }
                                            },
                                            {
                                                "Value":  2,
                                                "Color":  null,
                                                "IsManaged":  true,
                                                "ExternalValue":  null,
                                                "ParentValues":  [

                                                                 ],
                                                "Tag":  null,
                                                "MetadataId":  null,
                                                "HasChanged":  null,
                                                "Label":  {
                                                              "LocalizedLabels":  [
                                                                                      {
                                                                                          "Label":  "Weiblich",
                                                                                          "LanguageCode":  1031,
                                                                                          "IsManaged":  true,
                                                                                          "MetadataId":  "98a9c7f4-2241-db11-898a-0007e9e17ebd",
                                                                                          "HasChanged":  null
                                                                                      }
                                                                                  ],
                                                              "UserLocalizedLabel":  {
                                                                                         "Label":  "Weiblich",
                                                                                         "LanguageCode":  1031,
                                                                                         "IsManaged":  true,
                                                                                         "MetadataId":  "98a9c7f4-2241-db11-898a-0007e9e17ebd",
                                                                                         "HasChanged":  null
                                                                                     }
                                                          },
                                                "Description":  {
                                                                    "LocalizedLabels":  [

                                                                                        ],
                                                                    "UserLocalizedLabel":  null
                                                                }
                                            }
                                        ]
                        }
}
```

When you are happing with just attribute, the picklist code like 1,2,.. and the localised description, you can just use

```PowerShell
Get-PicklistOptions -LogicalName account | Sort-Object -Property Attribute, Code | Format-Table
```

to get a table like

```PowerShell
Get-PicklistOptions -LogicalName account | Sort-Object -Property Attribute, Code | ft

AUSFÜHRLICH: GET https://orgbdabcedf.crm11.dynamics.com:443/api/data/v9.2/EntityDefinitions(LogicalName='account')/Attributes/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?%24expand=GlobalOptionSet(%24select%3dOptions)&%24select=LogicalName%2cOptionSet

Attribute                    Code Description
---------                    ---- -----------
accountcategorycode             1 Bevorzugter Kunde
accountcategorycode             2 Standard
accountclassificationcode       1 Standardwert
accountratingcode               1 Standardwert
address1_addresstypecode        1 Rechnungsadresse
address1_addresstypecode        2 Lieferadresse
address1_addresstypecode        3 Primär
address1_addresstypecode        4 Sonstiges
address1_freighttermscode       1 Frei an Bord
address1_freighttermscode       3 Kosten und Fracht
address1_freighttermscode      21 Abholung
address1_shippingmethodcode     2 DHL
address1_shippingmethodcode     3 FedEx
address1_shippingmethodcode     4 UPS
address1_shippingmethodcode     5 Postal Mail
address1_shippingmethodcode     7 Selbstabholer
address1_shippingmethodcode    13 Deutsche Post
address1_shippingmethodcode    14 DPD
address2_addresstypecode        1 Standardwert
address2_freighttermscode       1 Standardwert
address2_shippingmethodcode     1 Standardwert
businesstypecode                1 Standardwert
customersizecode                1 Standardwert
customertypecode                1 Mitbewerber
customertypecode                2 Berater
customertypecode                3 Kunde
customertypecode                4 Investor
customertypecode                5 Partner
customertypecode                6 Schlüsselperson
customertypecode                7 Presse
customertypecode                8 Interessent
customertypecode                9 Wiederverkäufer
customertypecode               10 Lieferant
customertypecode               11 Hersteller
customertypecode               12 Sonstiges
industrycode                   33 Großhandel
industrycode                   44 Chemische Industrie
industrycode                   47 Services
industrycode                   53 Baugewerbe
industrycode                   60 Verarbeitendes Gewerbe
industrycode                   72 Einzelhandel
industrycode                   73 Herstellung technischer Geräte und Anlagen
industrycode                   74 IT-Industrie
industrycode                   75 Metallindustrie, Maschinen- und Fahrzeugbau
industrycode                   76 Nahrungs- und Genussmittel
industrycode                   77 Ver- und Entsorgung
ownershipcode                   1 Öffentlich
ownershipcode                   2 Privat
ownershipcode                   3 Niederlassung
ownershipcode                   4 Sonstiges
paymenttermscode                2 10 Tage 2%, 30 Tage netto
paymenttermscode                5 7 Tage netto
paymenttermscode                7 14 Tage netto
paymenttermscode                8 21 Tage netto
preferredappointmentdaycode     0 Sonntag
preferredappointmentdaycode     1 Montag
preferredappointmentdaycode     2 Dienstag
preferredappointmentdaycode     3 Mittwoch
preferredappointmentdaycode     4 Donnerstag
preferredappointmentdaycode     5 Freitag
preferredappointmentdaycode     6 Samstag
preferredappointmenttimecode    1 Morgens
preferredappointmenttimecode    2 Nachmittags
preferredappointmenttimecode    3 Abends
preferredcontactmethodcode      1 Beliebig
preferredcontactmethodcode      2 E-Mail
preferredcontactmethodcode      3 Telefon
preferredcontactmethodcode      4 Fax
preferredcontactmethodcode      5 Post
shippingmethodcode              1 Standardwert
territorycode                   1 Standardwert
```