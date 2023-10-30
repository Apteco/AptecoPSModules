
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
Install-Dependencies -module Apteco.OSMGeocode
```

You can check the installed module with

```PowerShell
Get-InstalledModule Apteco.OSMGeocode
```

If you want to find more [Apteco scripts in PSGallery](https://www.powershellgallery.com/packages?q=Tags%3A%22Apteco%22), please search with

```PowerShell
Find-Module -Repository "PSGallery" -Tag "Apteco"
```

To update the module, just execute the `Install-Module` command again with `-Force` like

```PowerShell
Find-Module -Repository "PSGallery" -Name "Apteco.OSMGeocode" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers -Force
```


# Install it



# Getting started with the Framework


```PowerShell
Import-Module Apteco.OSMGeocode -Verbose
```

If you get error messages during the import, that is normal, because there are modules missing yet. They need to be installed with `Install-AptecoOSMGeocode`

```PowerShell
Install-AptecoOSMGeocode -Verbose
```
