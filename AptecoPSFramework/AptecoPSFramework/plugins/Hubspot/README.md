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

# Example for loading Hubspot data and properties into a SQLITE

```PowerShell


try {

    #-----------------------------------------------
    # PREPARATION
    #-----------------------------------------------

    # Load module, settings and plugin
    Set-Location -Path "D:\Apteco\Build\Hubspot\preload\HubspotExtract_v2" #"D:\Scripts\AptecoPSFramework_HubspotLoadData"
    Import-Module AptecoPSFramework, SimplySql, WriteLog
    Import-Settings "D:\Scripts\AptecoPSFramework_HubspotLoadData\settings.json"

    # Hubspot settings
    $objectsToLoad = [array]@( "companies" , "contacts", "deals", "notes", "meetings", "tasks", "calls" )

    # Database settings
    $dbname = "D:\Apteco\Build\Hubspot\data\hubspot_v2.sqlite"
    $backupDb = "$( $dbname ).$( [datetime]::Now.toString("yyyyMMddHHmmss") )"

    # Other settings
    Set-Logfile ".\hubspot.log"

    # Current time
    $startTime = [DateTime]::Now


    #-----------------------------------------------
    # CHECK DATABASE
    #-----------------------------------------------

    # Rename existing database
    If ( ( Test-Path -Path $dbname ) -eq $true ) {
        Move-Item -Path $dbname -Destination $backupDb
    }

    # Make connection to a new database
    Open-SQLiteConnection -DataSource $dbname

    # Create table and define query
    Invoke-SqlUpdate -Query "CREATE TABLE items (object TEXT, id INTEGER, properties TEXT, createdAt TEXT, updatedAt TEXT, archived TEXT, associations TEXT)" | Out-Null
    $insertQuery = "INSERT INTO items (object, id, properties, createdAt, updatedAt, archived, associations) VALUES (@object, @id, @properties, @createdAt, @updatedAt, @archived, @associations)"


    #-----------------------------------------------
    # LOAD HUBSPOT DATA AND LOAD INTO NEW DATABASE
    #-----------------------------------------------

    [int]$recordsInsertedTotal = 0
    Write-Log "Loading and inserting data"
    $objectsToLoad | ForEach-Object {
        
        # Use the current object and reset the counter
        $object = $_
        [int]$recordsInserted = 0
        
        Start-Transaction

        # Load data from Hubspot
        Get-CRMData -Object $object -LoadAllProperties -AddWrapper -LoadAllRecords -Associations companies, contacts | ForEach-Object {
            $params = [Hashtable]@{
                "id" = $_.id
                "object" = $object
                "properties" = Convertto-json -InputObject $_.properties -Depth 99
                "createdAt" = $_.createdAt
                "updatedAt" = $_.updatedAt
                "archived" = $_.archived
                "associations" = Convertto-json -InputObject $_.associations -Depth 99
            }
            $recordsInserted += Invoke-SqlUpdate -Query $insertQuery -Parameters $params #| Out-Null
        }

        If ( $recordsInserted -gt 0 ) {
            Complete-Transaction
        }

        $recordsInsertedTotal += $recordsInserted

        Write-Log "  $( $object ): $( $recordsInserted )"

    }

    Write-Log "Inserted $( $recordsInsertedTotal ) in total"

    <#
    # Load main data from Hubspot
    $companies = Get-CRMData -Object companies -LoadAllProperties -AddWrapper -limit 10 #-LoadAllRecords
    $contacts = Get-CRMData -Object contacts -LoadAllProperties -AddWrapper -Associations companies -limit 10 #-LoadAllRecords
    $deals = Get-CRMData -Object deals -LoadAllProperties -AddWrapper -Associations companies, contacts -limit 10

    # Load engagement data
    $notes = Get-CRMData -Object notes -LoadAllProperties -AddWrapper -Associations companies, contacts -limit 10
    $meetings = Get-CRMData -Object meetings -LoadAllProperties -AddWrapper -Associations companies, contacts -limit 10
    $tasks = Get-CRMData -Object tasks -LoadAllProperties -AddWrapper -Associations companies, contacts -limit 10
    $calls = Get-CRMData -Object calls -LoadAllProperties -AddWrapper -Associations companies, contacts -limit 10
    #$communications = Get-CRMData -Object communications -LoadAllProperties -AddWrapper -Associations companies, contacts -limit 10
    #$emails = Get-CRMData -Object emails -LoadAllProperties -AddWrapper -Associations companies, contacts -limit 10
    #>


    #-----------------------------------------------
    # LOAD PROPERTIES
    #-----------------------------------------------

    # Create table and define query
    Invoke-SqlUpdate -Query "CREATE TABLE properties (object TEXT, updatedAt TEXT, createdAt TEXT, name TEXT, label TEXT, type TEXT, fieldType TEXT, description TEXT, groupName TEXT, options TEXT, displayOrder INTEGER, calculated TEXT, externalOptions TEXT, hasUniqueValue TEXT, hidden TEXT, hubspotDefined TEXT, showCurrencySymbol TEXT, modificationMetadata TEXT, formField TEXT, calculationFormula TEXT)" | Out-Null
    $insertQuery = "INSERT INTO properties (object, updatedAt, createdAt, name, label, type, fieldType, description, groupName, options, displayOrder, calculated, externalOptions, hasUniqueValue, hidden, hubspotDefined, showCurrencySymbol, modificationMetadata, formField, calculationFormula) VALUES (@object, @updatedAt, @createdAt, @name, @label, @type, @fieldType, @description, @groupName, @options, @displayOrder, @calculated, @externalOptions, @hasUniqueValue, @hidden, @hubspotDefined, @showCurrencySymbol, @modificationMetadata, @formField, @calculationFormula)"

    [int]$recordsInsertedTotal = 0
    Write-Log "Loading and inserting properties"
    $objectsToLoad | ForEach-Object {
        
        # Use the current object and reset the counter
        $object = $_
        [int]$recordsInserted = 0
        
        Start-Transaction

        # Load data from Hubspot
        Get-Property -Object $object | ForEach-Object {
            $params = [Hashtable]@{
                "object" = $object
                "updatedAt" = $_.updatedAt
                "createdAt" = $_.createdAt
                "name" = $_.name
                "label" = $_.label
                "type" = $_.type
                "fieldType" = $_.fieldType
                "description" = $_.description
                "groupName" = $_.groupName
                "options" = Convertto-json -InputObject $_.options -Depth 99
                "displayOrder" = $_.displayOrder
                "calculated" = $_.calculated
                "externalOptions" = $_.externalOptions
                "hasUniqueValue" = $_.hasUniqueValue
                "hidden" = $_.hidden
                "hubspotDefined" = $_.hubspotDefined
                "showCurrencySymbol" = $_.showCurrencySymbol
                "modificationMetadata" = Convertto-json -InputObject $_.modificationMetadata -Depth 99
                "formField" = $_.formField
                "calculationFormula" = $_.calculationFormula
            }
            $recordsInserted += Invoke-SqlUpdate -Query $insertQuery -Parameters $params #| Out-Null
        }

        If ( $recordsInserted -gt 0 ) {
            Complete-Transaction
        } else {
            Stop-Transaction
        }

        $recordsInsertedTotal += $recordsInserted

        Write-Log "  $( $object ): $( $recordsInserted )"

    }


    #-----------------------------------------------
    # CHECK AND CLOSE CONNECTION
    #-----------------------------------------------

    $itemsCount = Invoke-SqlScalar -Query "SELECT count(*) FROM items"
    $propertiesCount = Invoke-SqlScalar -Query "SELECT count(*) FROM properties"

    Write-Log "Confirmed $( $itemsCount ) items"
    Write-Log "Confirmed $( $propertiesCount ) properties"


    #-----------------------------------------------
    # MEASURE
    #-----------------------------------------------

    $ts = New-TimeSpan -Start $startTime -End ( [DateTime]::Now )

    Write-Log "Needed $( $ts.TotalSeconds ) in total" -severity INFO


    #-----------------------------------------------
    # REMOVE DATABASE
    #-----------------------------------------------

    # Rename existing database
    If ( ( Test-Path -Path $backupDb ) -eq $true ) {
        Remove-Item -Path $backupDb
    }


    #-----------------------------------------------
    # GENERATE QUERIES TO USE
    #-----------------------------------------------

    #Invoke-SqlQuery -Query "SELECT id, createdAt, updatedAt FROM items where item = 'contacts' limit 10" | Out-GridView


    $objectsToLoad | ForEach-Object {
        
        # Use the current object and reset the counter
        $object = $_

        $objectProperties = Invoke-SqlQuery -Query "SELECT name, label FROM properties where object = '$( $object )'" #| Out-GridView

        $propsList = [System.Collections.ArrayList]@()
        $objectProperties | ForEach-Object {
            [void]$propsList.add("  json_extract(i.properties, '$.$( $_.name )') ""$( $_.label.replace('"','').replace("'",'') )""")
        }

        # General query for the object/table
        $queryString = [System.Text.StringBuilder]::new()        
        [void]$queryString.Append( "SELECT" )
        [void]$queryString.AppendLine( "  id, createdAt, updatedAt, archived," )
        [void]$queryString.AppendLine( "$(( $propsList -join ", `r`n" ))" )
        [void]$queryString.AppendLine( "FROM items i where object = '$( $object )'" )
        $queryString.toString() | Set-Content ".\query_$( $object ).sql" -Encoding UTF8 -force

        # Lookup queries
        $queryLookups = @"
            SELECT p.name
            , json_extract(j.value, '$.value') code
            , json_extract(j.value, '$.label') description
        FROM properties p
            , json_each(p.options) j
        WHERE p.OBJECT = '$( $object )'
            AND p.fieldType = 'select'
            AND json_extract(j.value, '$.value') IS NOT NULL
            AND json_extract(j.value, '$.value') != ''
            AND json_extract(j.value, '$.hidden') = 0
            AND p.name IS NOT NULL
        ORDER BY name
            , json_extract(j.value, '$.displayOrder')
"@

        $objectLookups = Invoke-SqlQuery -Query $queryLookups

        $objectLookups | group name | ForEach-Object {
            $name = $_.name
            $queryLookups -replace ("p.name IS NOT NULL", "p.name = '$( $name )'") | Set-Content ".\lookup_$( $object )_$( $name ).sql" -Encoding UTF8 -force
        }


    }

} catch {

    Write-Log $_.Exception -severity ERROR
    throw $_.Exception

} finally {

    #-----------------------------------------------
    # CLOSE THE CONNECTION
    #-----------------------------------------------

    Close-SqlConnection

}



```