# Apteco PS Modules - PowerShell dependency import

Execute commands like

```PowerShell
Import-Dependencies.ps1 -Module "WriteLog" -LoadWholePackageFolder -Verbose
```

or

```Powershell
Import-Dependencies.ps1 -Module "WriteLog" -LocalPackage "System.Data.SQLite", "Npgsql" -Verbose
```

The last way is more efficient, but could cause more problems, when important dependencies are missing. Best way is to install all needed dependencies with my other script like

```PowerShell
Install-Dependencies -Module "WriteLog" -LocalPackage "System.Data.SQLite", "Npgsql" -Verbose
```

And then work out (e.g. with moving folders) which packages are not needed or are needed

This script is automatically searching for a `.\lib` subfolder in your current directory.

It will also automatically create a log file in the current folder named `dependencies_import.log`

If you want to see more output in your console, just add the `-Verbose` flag to your command.


# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Script

Before you proceed, it is needed to update your PowerShellGet or PATH variable to find script. You can see this in this snippet how it can work
```PowerShell
PS C:\Users\WDAGUtilityAccount> install-module writelog
NuGet provider is required to continue                                                                                  
PowerShellGet requires NuGet provider version '2.8.5.201' or newer to interact with NuGet-based repositories. The NuGet  provider must be available in 'C:\Program Files\PackageManagement\ProviderAssemblies' or 'C:\Users\WDAGUtilityAccount\AppData\Local\PackageManagement\ProviderAssemblies'. You can also install the NuGet provider by running 'Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force'. Do you want PowerShellGet   to install and import the NuGet provider now?
[Y] Yes  [N] No  [S] Suspend  [?] Help (default is "Y"): Y

Untrusted repository
You are installing the modules from an untrusted repository. If you trust this repository, change its
InstallationPolicy value by running the Set-PSRepository cmdlet. Are you sure you want to install the modules from
'PSGallery'?
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "N"): Y
PS C:\Users\WDAGUtilityAccount> install-script install-dependencies

PATH Environment Variable Change
Your system has not been configured with a default script installation path yet, which means you can only run a script
by specifying the full path to the script file. This action places the script into the folder 'C:\Program
Files\WindowsPowerShell\Scripts', and adds that folder to your PATH environment variable. Do you want to add the script
 installation path 'C:\Program Files\WindowsPowerShell\Scripts' to the PATH environment variable?
[Y] Yes  [N] No  [S] Suspend  [?] Help (default is "Y"): Y

Untrusted repository
You are installing the scripts from an untrusted repository. If you trust this repository, change its
InstallationPolicy value by running the Set-PSRepository cmdlet. Are you sure you want to install the scripts from
'PSGallery'?
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "N"): Y
PS C:\Users\WDAGUtilityAccount>
```

For installation execute this for all users scope

```PowerShell
$pkg = Find-Module -Repository "PSGallery" -Name "Import-Dependencies" -IncludeDependencies
$pkg | Where-Object { $_.Type -eq "Module" } | Install-Module -Verbose -Scope AllUsers
$pkg | Where-Object { $_.Type -eq "Script" } | Install-Script -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledScript "Import-Dependencies"
```

If you want to find more [Apteco scripts in PSGallery](https://www.powershellgallery.com/packages?q=Tags%3A%22Apteco%22), please search with

```PowerShell
Find-Module -Repository "PSGallery" -Tag "Apteco"
Find-Script -Repository "PSGallery" -Tag "Apteco"
```

### Installation via local Repository

If your machine does not have an online connection you can use another machine to save the script from PSGallery website as a local file via your browser. You should have download a file with an `.nupkg` extension. Please don't forget to download all dependencies, too. You could simply unzip the file(s) and put the script somewhere you need it OR do it in an updatable manner and create a local repository if you don't have it already with

```PowerShell
Set-Location "$( $env:USERPROFILE )\Downloads"
New-Item -Name "PSRepo" -ItemType Directory
Register-PSRepository -Name "LocalRepo" -SourceLocation "$( $env:USERPROFILE )\Downloads\PSRepo"
Get-PSRepository
```

To trust a local repository, use

```PowerShell
Set-PSRepository -Name "LocalRepo"  -InstallationPolicy Trusted
```

To remove the trust, just put it back to `Untrusted`

```PowerShell
Set-PSRepository -Name "LocalRepo"  -InstallationPolicy Untrusted
```

Then put your downloaded `.nupkg` file into the new created `PSRepo` folder and you should see the module via 

```PowerShell
Find-Module -Repository "LocalRepo"
```

Then install the script like 

```PowerShell
$pkg = Find-Script -Repository "LocalRepo" -Name "Import-Dependencies" -IncludeDependencies
$pkg | Where-Object { $_.Type -eq "Module" } | Install-Module -Verbose -Scope AllUsers
$pkg | Where-Object { $_.Type -eq "Script" } | Install-Script -Verbose -Scope AllUsers
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Script -Name "Import-Dependencies"
```

# Examples

## How to use e.g. for installing MailKit into a local folder

```PowerShell
install-script install-dependencies, import-dependencies -force
cd c:\temp
Install-Dependencies -LocalPackage MailKit -verbose
Import-Dependencies -LoadWholePackageFolder -LocalPackageFolder "./lib" -verbose
```

# Contribution

You are free to use this code, put in some changes and use a pull request to feedback improvements :-)

# TODO 


- [ ] Show a wrapper to use it with an psd file
