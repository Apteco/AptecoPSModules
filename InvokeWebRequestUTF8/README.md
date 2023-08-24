
# Apteco Customs - PowerShell WebRequest UTF8

Helpful function for APIs, that return UTF8 encoded content, but PowerShell does not recognize it as UTF8 encoded.

So it reads the content and converts it from the `[Console]::OutputEncoding.HeaderName` to UTF8.


# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "InvokeWebRequestUTF8" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule InvokeWebRequestUTF8
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

Then put your downloaded `.nupkg` file into the new created `PSRepo` folder and you should see the module via 

```PowerShell
Find-Module -Repository LocalRepo
```

Then install the script like 

```PowerShell
Find-Module -Repository LocalRepo -Name InvokeWebRequestUTF8 -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name InvokeWebRequestUTF8
```



## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location InvokeWebRequestUTF8
Import-Module .\InvokeWebRequestUTF8
```

# Example

This module is using the ExtendFunction module and is mirroring the original `Invoke-WebRequest` so you have the exact same parameters, only the command changes to something like

```PowerShell
Invoke-WebRequest -UseBasicParsing -Uri "https://api.chucknorris.io/jokes/random" -Method "GET"
```

If you are using this command on a console or restricted environment, please don't forget to use `-UseBasicParsing` as you already know. This shouldn't be an issue on pwsh or linux.
