Data is available under these terms: https://www.openstreetmap.org/copyright

Encoding should also be UTF8 for input file

```PowerShell
Install-Module InvokeGeocoding
Import-Module InvokeGeocoding -verbose
Install-InvokeGeocoding -verbose
```

```PowerShell
$settings = get-settings
$settings.logfile = ".\geocoding.log"
$settings.sqliteDB = ".\db.sqlite"
Set-Settings $settings
Export-Settings ".\settings.json"
```

Now open the settings.json and especially change your mapping. 

```PowerShell
Import-Module InvokeGeocoding -verbose
Import-Settings ".\settings.json"
$params = [hashtable]@{
    Path = '.\test.csv'
    settingsfile = ".\settings.json"
}
Invoke-Geocoding $params
```


```
```

# TODO 

[ ] replace the private/string with "ConvertStrings" module when published
[ ] put settings creation and loading in separate modules
[ ] put the download/load of local packages into a separate module/script