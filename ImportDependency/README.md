# Apteco PS Modules - PowerShell dependency import

Execute commands like

```PowerShell
Import-Dependency -Module "WriteLog" -LoadWholePackageFolder -Verbose
```

or

```Powershell
Import-Dependency -Module "WriteLog" -LocalPackage "System.Data.SQLite", "Npgsql" -Verbose
```

The last way is more efficient, but could cause more problems, when important dependencies are missing. Best way is to install all needed dependencies with my other script like

```PowerShell
Import-Dependency-Module "WriteLog" -LocalPackage "System.Data.SQLite", "Npgsql" -Verbose
```

And then work out (e.g. with moving folders) which packages are not needed or are needed

This script is automatically searching for a `.\lib` subfolder in your current directory.

It will also automatically create a log file in the current folder named `dependencies_import.log`

If you want to see more output in your console, just add the `-Verbose` flag to your command.


# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

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
$pkg = Find-Module -Repository "PSGallery" -Name "ImportDependency" -IncludeDependencies
$pkg | Where-Object { $_.Type -eq "Module" } | Install-Module -Verbose -Scope AllUsers
$pkg | Where-Object { $_.Type -eq "Script" } | Install-Script -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule "ImportDependency"
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

On Linux you would use `Set-Location "$( $env:Home )/Downloads"` or create the `.\Downloads` directory.

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
$pkg = Find-Script -Repository "LocalRepo" -Name "ImportDependency" -IncludeDependencies
$pkg | Where-Object { $_.Type -eq "Module" } | Install-Module -Verbose -Scope AllUsers
$pkg | Where-Object { $_.Type -eq "Script" } | Install-Script -Verbose -Scope AllUsers
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name "ImportDependency"
```

# Examples

## How to use e.g. for installing MailKit into a local folder

```PowerShell
install-script install-dependencies -force
install-module Import-Dependency -force

cd c:\temp
Install-Dependencies -LocalPackage MailKit -verbose
Import-Dependency -LoadWholePackageFolder -LocalPackageFolder "./lib" -verbose
```

## Check the current PowerShell environment

Use this to get a good overview of the current environment. This is useful information for loading dependencies or to operate on different operating systems etc.

```PowerShell
Get-PSEnvironment

Name                           Value
----                           -----
PSVersion                      5.1.26100.6584
PSEdition                      Desktop
OS                             Windows
IsCore                         False
Architecture                   ARM64
CurrentRuntime                 net4.0
Is64BitOS                      True
Is64BitProcess                 True
ExecutingUser                  FLOPRO11\flo
IsElevated                     False
RuntimePreference              win-arm64, win-arm, win-x64, win-x86
FrameworkPreference            net48, net47, net462, net461, net45, net40, netstandard2.0, netstandard1.5, netstandard1....
PackageManagement              1.4.8.1
PowerShellGet                  2.2.5
VcRedist                       @{installed=True; is64bit=True; versions=System.Collections.Hashtable}
BackgroundCheckCompleted       True
InstalledModules               {@{Name=PackageManagement; Version=1.4.8.1; Type=Module; Description=PackageManagement (a...
InstalledGlobalPackages        {Microsoft.PackageManagement.Packaging.SoftwareIdentity, Microsoft.PackageManagement.Pack...
LocalPackageCheckCompleted     True
InstalledLocalPackages
```

If you need a faster execution of the command, just skip some checks

```PowerShell
Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck

Name                           Value
----                           -----
PSVersion                      5.1.26100.6584
PSEdition                      Desktop
OS                             Windows
IsCore                         False
Architecture                   ARM64
CurrentRuntime                 net4.0
Is64BitOS                      True
Is64BitProcess                 True
ExecutingUser                  FLOPRO11\flo
IsElevated                     False
RuntimePreference              win-arm64, win-arm, win-x64, win-x86
FrameworkPreference            net48, net47, net462, net461, net45, net40, netstandard2.0, netstandard1.5, netstandard1....
PackageManagement              1.4.8.1
PowerShellGet                  2.2.5
VcRedist                       @{installed=True; is64bit=True; versions=System.Collections.Hashtable}
BackgroundCheckCompleted       False
InstalledModules
InstalledGlobalPackages
LocalPackageCheckCompleted     False
InstalledLocalPackages
```

If you have saved some nuget packages to a local folder, you can find and examine them navigating to the parent folder of the packages
and then execute the command similar to this

```PowerShell
$ps = Get-PSEnvironment -LocalPackageFolder ".\lib"
$ps.InstalledLocalPackages

Name                           Version          Source                           ProviderName
----                           -------          ------                           ------------
System.Runtime.CompilerServ... 6.1.2            C:\Users\flo\Downloads\testpa... NuGet
System.Threading.Channels      7.0.0            C:\Users\flo\Downloads\testpa... NuGet
System.Threading.Tasks.Exte... 4.6.3            C:\Users\flo\Downloads\testpa... NuGet
```

# Contribution

You are free to use this code, put in some changes and use a pull request to feedback improvements :-)

