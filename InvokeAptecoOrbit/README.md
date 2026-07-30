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
```

The session/access token is cached to disk (encrypted at rest via
[EncryptCredential](https://github.com/Apteco/AptecoPSModules/tree/main/EncryptCredential) by
default) and reused until it expires, so repeated script runs do not need to log in every time.

## Known limitations

* Only the `SIMPLE` login type is currently implemented. The Orbit API also offers a `SALTED`
  login (a multi-step, salted-hash exchange) - it is not implemented, since the exact hash
  algorithm/salting order a given instance expects was never verified end-to-end. Calling
  `Connect-AptecoOrbit` with that login type throws a clear error instead of guessing.
* This module has not yet been exercised against a live Orbit instance; please report any
  endpoint/response shape mismatches.
