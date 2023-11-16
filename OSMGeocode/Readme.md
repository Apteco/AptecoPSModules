
# Introduction

This module is intended to show the value of external data and make "appetite" on more data that is out there.

# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

The installation needs to be done on the "Apteco APP Server", so the "Apteco Service" can talk to this module.

## PSGallery

This is the easier option if your machine is allowed to talk to the internet. If not, look at the next option, because you can also build a local repository that can be used for installation and updates.

Let us check if you have the needed prerequisites

```PowerShell
# Check your executionpolicy: https:/go.microsoft.com/fwlink/?LinkID=135170
Get-ExecutionPolicy

# Either set it to Bypass to generally allow scripts for current user
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
# or
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Make sure to have PowerShellGet >= 1.6.0
Get-InstalledModule -Name PowerShellGet -MinimumVersion 1.6.0
```


### Installation via Install-Module

For installation execute this for all users scope (or with a users scope, but this needs to be the exact user that executes the "Apteco Service").

It is recommended, to use at minimum the module `PowerShellGet` with version `1.6.0` to avoid problems with loading prerelease versions. To check this, run

```PowerShell
Get-InstalledModule -Name PowerShellGet -MinimumVersion 1.6.0
```

If you have no result, then execute

```PowerShell
install-module powershellget -Verbose -AllowClobber -force
```

to update that module. Now proceed with installing apteco modules:

```PowerShell
# Execute this with elevated rights or with the user you need to execute it with, e.g. the apteco service user
install-script install-dependencies, import-dependencies
install-module writelog
Install-Dependencies -module OSMGeocode
```

You can check the installed module with

```PowerShell
Get-InstalledModule OSMGeocode
```

If you want to find more [Apteco scripts in PSGallery](https://www.powershellgallery.com/packages?q=Tags%3A%22Apteco%22), please search with

```PowerShell
Find-Module -Repository "PSGallery" -Tag "Apteco"
```

To update the module, just execute the `Install-Module` command again with `-Force` like

```PowerShell
Find-Module -Repository "PSGallery" -Name "OSMGeocode" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers -Force
```


# Install it



# Getting started with the Framework


```PowerShell
Import-Module OSMGeocode -Verbose
```

If you get error messages during the import, that is normal, because there are modules missing yet. They need to be installed with `Install-AptecoOSMGeocode`

```PowerShell
Install-OSMGeocode -Verbose
```


You can get and set other query parameters via 

```PowerShell
$g = Get-AllowedQueryParameter # default is: street, city, postalcode, countrycodes
$g += "wow"
Set-AllowedQueryParameter $g
```


## Quickstart examples

### Geocode a single address

```PowerShell
$addr = [PSCustomObject]@{
    "street" = "Schaumainkai 87"
    "city" = "Frankfurt"
    "postalcode" = 60589
    "countrycodes" = "de"
}

Invoke-OSM -Address $addr -Email "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -verbose
# OR
$addr | Invoke-OSM -Email "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -verbose
```

### Geocode multiple addresses

```PowerShell
$addresses = @(
    [PSCustomObject]@{
        "street" = "Schaumainkai 87"
        "city" = "Frankfurt"
        "postalcode" = 60589
        "countrycodes" = "de"
    }
    [PSCustomObject]@{
        "street" = "Kaiserstrasse 35"
        "city" = "Frankfurt"
        #"postalcode" = 60589
        "countrycodes" = "de"
    }
)

$addresses = Import-csv ".\test.csv" -Encoding UTF8 -Delimiter "`t"
#$addresses | Invoke-OSM -Email "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -verbose
$addresses | Invoke-OSM -Email "florian.von.bracht@apteco.de" -AddressDetails -ExtraTags -AddMetaData -ReturnOnlyFirstPosition -ResultsLanguage "de" | Out-GridView
```


### Working with hashes to identify known addresses

```PowerShell

#-----------------------------------------------
# PREPARE THE DATABASE AND FILL HASH CACHE
#-----------------------------------------------

# Open a new database
Open-SQLiteConnection -DataSource ".\addresses.sqlite"

# Create a table for inserting the data
Invoke-SqlUpdate -Query "CREATE TABLE IF NOT EXISTS addresses (inputHash TEXT, inputObject TEXT, results TEXT, total INT, updatedAt DATE DEFAULT (datetime('now','localtime')))" | Out-Null

# The original output uses inputHash, inputObject, results, total
#$insertQuery = "INSERT INTO addresses (inputHash, inputObject, results, total) VALUES (@inputHash, @inputObject, @results, @total)"

# This does not need to be done for the first run, it is used for exclusions on subsequent runs
Invoke-SqlQuery -Query "Select inputHash from addresses" -Stream | ForEach-Object { Add-ToHashCache $_.inputHash }


#-----------------------------------------------
# PREPARE THE INPUT DATA
#-----------------------------------------------

$c = Get-Content -Path '.\ac_adressen.csv' -Encoding UTF8 -TotalCount 10 | ConvertFrom-Csv -Delimiter ","

# Map your columns from the original data to the needed parameters
# The original parameters can be requested via Get-AllowedQueryParameter
$mapping = @(
    @{name="id";expression={ $_.FID }}
    @{name="street";expression={ $_.adresse }}
    @{name="city";expression={ "Aachen" }}
    @{name="postalcode";expression={ $_.plz }}
    @{name="countrycodes";expression={ "de" }}
)


#-----------------------------------------------
# GEOCODE YOUR DATA
#-----------------------------------------------

# Use the addresses | transform the data | geocode data | save it into a database
# The input variable could also be replace with the definition of $c to allow better streaming
$c | select-object $mapping | Invoke-OSM -Email "florian.von.bracht@apteco.de" -ResultsLanguage "de" -AddressDetails -ExtraTags -NameDetails -ReturnOnlyFirstPosition -AddMetaData -AddToHashCache -ExcludeKnownHashes -CombineIdAndHash -Verbose | Add-RowsToSql -TableName addresses -FormatObjectAsJson -Verbose


#-----------------------------------------------
# CLOSE THE CONNECTION
#-----------------------------------------------

Close-SqlConnection
```

## Adding a hash column to a csv

This is kind of intense and needs around 206 seconds for 45k objects/records:

```PowerShell
$mapping = @(
    @{name="id";expression={ $_.FID }}
    @{name="street";expression={ $_.adresse }}
    @{name="city";expression={ "Aachen" }}
    @{name="postalcode";expression={ $_.plz }}
    @{name="countrycodes";expression={ "de" }}
)
$c = import-csv -Path .\ac.csv -Delimiter "," -Encoding UTF8 | select $mapping | Add-HashColumn -HashColumnName hash
```

## Working with IDs rather than hashes

When you later join your geocoded addresses and locations via ID rather than a hash value (which needs some time to calculate)
you should follow these strategy

1. Load a smaller set that you think could have changed. Like addresses that have a changedate in the last two days. Overlapping with previous runs is allowed.
1. Fill your known hash values from your database.
1. Include a property/field in your input objects with the name `id` and geocode your addresses and don't forget to use the `-CombineIdAndHash` flag.
1. Voila! Now you have all IDs and can use that field to join the data. Please be aware that if an address has changed, the ID can be multiple times in your database. So you need a window function to select the most recent record or the one with the highest ROWID per ID or similar.

For the example above in sqlite you could use this query to get the newest address per id:

```SQL
SELECT *
FROM (
	SELECT *
		, row_number() OVER (
			PARTITION BY id ORDER BY updatedAt DESC
			) rownum
	FROM (
		SELECT json_extract(inputObject, '$.id') "id"
			, *
		FROM addresses
		) a1
	)
WHERE rownum = 1
```

or a bit more advanced

```SQL
SELECT *
FROM (
	SELECT json_extract(inputObject, '$.id') AS "ID"
		, total
		, updatedAt
		, json_extract(results, '$.address.road') || ' ' || json_extract(results, '$.address.house_number') "Straße"
		, json_extract(results, '$.address.postcode') "Plz-5"
		, json_extract(results, '$.address.village') "Dorf"
		, json_extract(results, '$.address.suburb') "Stadtteil"
		, json_extract(results, '$.address.town') "Ort"
		, json_extract(results, '$.address.county') "Landkreis"
		, json_extract(results, '$.address.state') "Bundesland"
		, json_extract(results, '$.address.country') "Land"
		, json_extract(results, '$.address.country_code') "ISO-Code"
		, json_extract(results, '$.lat') "Breitengrad Lat"
		, json_extract(results, '$.lon') "Längengrad Lon"
		, json_extract(results, '$.licence') "OSM-Lizenz"
		, json_extract(results, '$.osm_type') "OSM-Typ"
		, json_extract(results, '$.osm_id') "OSM-ID"
		, json_extract(results, '$.type') "Typ"
		, json_extract(results, '$.category') "Kategorie"
		, json_extract(results, '$.name') "Name"
		, json_extract(results, '$.extratags.contact:phone') "Telefon 1"
		, json_extract(results, '$.extratags.phone') "Telefon 2"
		, row_number() OVER (
			PARTITION BY json_extract(inputObject, '$.id') ORDER BY updatedAt DESC
			) rownum
	FROM addresses
	)
WHERE rownum = 1
	AND Straße IS NOT NULL
	--limit 10
```

# TODO

- [x] needs more explanations on parameter
