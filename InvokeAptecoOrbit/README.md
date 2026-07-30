# Apteco PS Modules - Apteco Orbit API client

Authenticate against an Apteco Orbit API instance, call any of its endpoints, and download
paginated data without hand-rolling the paging loop yourself.

```PowerShell
Connect-AptecoOrbit -BaseUrl "https://partner.apteco.io/OrbitAPI/" -DataView "Demo" -Credential (Get-Credential)

# Call a single endpoint by its key, as listed in the Orbit API's own About/Endpoints catalog
Invoke-AptecoOrbit -Key "GetPeopleStageSystem" -QueryParameters @{ systemName = "Demo" }

# Download every page of a paginated list endpoint
Get-AptecoOrbitPagedData -Key "GetElementStatusForDescendants" -PathParameters @{ systemName = "Demo"; elementId = 42 } -QueryParameters @{ filter = "Type eq 'Campaign'" }

# Or use the ready-made campaign download, which also adds a folder breadcrumb per campaign
Get-AptecoOrbitCampaigns -System "Demo"

# Export a FastStats audience and download the resulting file (async export + poll + download)
Export-AptecoOrbitAudience -System "Demo" -AudienceId 246 -WorkbookItemId "<workbook-item-guid>" -OutFile "C:\Temp\export.csv"
```

The session/access token is cached to disk (encrypted at rest via
[EncryptCredential](https://github.com/Apteco/AptecoPSModules/tree/main/EncryptCredential) by
default) and reused until it expires, so repeated script runs do not need to log in every time.

Both the `SIMPLE` (default) and `SALTED` login types are supported - pass `-LoginType SALTED` to `Connect-AptecoOrbit` if your instance requires it.

## Known limitations

* This module has not yet been exercised against a live Orbit instance; please report any
  endpoint/response shape mismatches.
