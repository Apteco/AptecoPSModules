
# Apteco PS Modules - PowerShell security encryption module

Execute commands like

```PowerShell
"Hello World" | Convert-PlaintextToSecure
```

to get a string like

```
76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=
```

This string can be decrypted by calling

```PowerShell
"76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=" | Convert-SecureToPlaintext
```

and get back

```
Hello World
```


You better save the strings into variables ;-)

This module is used to double encrypt sensitive data like credentials, tokens etc. They cannot be stolen pretty easily as it uses SecureStrings.

At the first encryption or when calling `Export-Keyfile` a new random keyfile will be generated for salting with AES.
The key ist saved per default in your users profile, but can be exported into any other folder and use it from there.
Be aware that the encrypted strings are only valid for the executing machine as it uses SecureStrings that cannot be
copied over to other machines.

You can use `Import-Keyfile` to use a keyfile that has been exported before.

# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "EncryptCredential" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule EncryptCredential
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
Find-Module -Repository LocalRepo -Name EncryptCredential -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name EncryptCredential
```

## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location EncryptCredential
Import-Module .\EncryptCredential
```

