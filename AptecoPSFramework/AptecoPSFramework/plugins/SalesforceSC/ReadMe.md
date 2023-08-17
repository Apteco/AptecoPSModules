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