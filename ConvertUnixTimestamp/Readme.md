
# Apteco PS Modules - PowerShell unix timestamp conversion

Execute commands like

```PowerShell
Get-Unixtime
Get-Unixtime -InMilliseconds
Get-Unixtime -InMilliseconds -Timestamp ( Get-Date ).AddDays(-2)
```

to get a unix timestamp like

```PowerShell
Get-Unixtime
1667389515

Get-Unixtime -InMilliseconds
1667389529073
```

or do something like

```PowerShell
ConvertFrom-UnixTime -Unixtime 1591775090
ConvertFrom-UnixTime -Unixtime 1591775090 -ConvertToLocalTimezone
ConvertFrom-UnixTime -Unixtime 1591775146091 -InMilliseconds
( ConvertFrom-UnixTime -Unixtime $lastSession.timestamp ).ToString("yyyy-MM-ddTHH:mm:ssK")
```

and get back a [DateTime] object which you can format and store like you want.

# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "ConvertUnixTimestamp" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule ConvertUnixTimestamp
```

If you want to find more [Apteco scripts in PSGallery](https://www.powershellgallery.com/packages?q=Tags%3A%22Apteco%22), please search with

```PowerShell
Find-Module -Repository "PSGallery" -Tag "Apteco"
```

### Installation via local Repository

If your machine does not have an online connection you can use another machine to save the script from PSGallery website as a local file via your browser. You should have download a file with an `.nupkg` extension. Please don't forget to download all dependencies, too. You could simply unzip the file(s) and put the script somewhere you need it OR do it in an updatable manner and create a local repository if you don't have it already with

```PowerShell
Set-Location "$( $env:USERPROFILE )\Downloads"
New-Item -Name "PSRepo" -ItemType Directory
Register-PSRepository -Name "LocalRepo" -SourceLocation "$( $env:USERPROFILE )\Downloads\PSRepo"
Get-PSRepository
```

On Linux you would use `Set-Location "$( $env:Home )/Downloads"` or create the `.\Downloads` directory.

Then put your downloaded `.nupkg` file into the new created `PSRepo` folder and you should see the module via 

```PowerShell
Find-Module -Repository LocalRepo
```

Then install the script like 

```PowerShell
Find-Module -Repository LocalRepo -Name ConvertUnixTimestamp -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name ConvertUnixTimestamp
```

## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location ConvertUnixTimestamp
Import-Module .\ConvertUnixTimestamp
```
