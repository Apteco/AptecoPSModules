
# Apteco PS Modules - PowerShell dependency installation

`InstallDependency` is the module successor of the standalone [`Install-Dependencies`](../Install-Dependencies) script. It downloads and installs the latest versions of modules and NuGet packages from PowerShell Gallery and NuGet, and it can save NuGet packages locally instead of installing them into a global machine path.

Execute commands like

```PowerShell
Install-Dependency -Module "WriteLog" -LocalPackage "System.Data.SQLite", "Npgsql" -Verbose
```

Then the modules/packages will be installed on your machine:
- Modules will be installed with `AllUsers` scope when you run elevated, otherwise `CurrentUser`
- Global packages will be installed in `%LOCALAPPDATA%\PackageManagement\NuGet\Packages` (requires an elevated/administrator session)
- Local packages will be installed in the current folder. It will create a `.\lib` folder (configurable via `-LocalPackageFolder`) and puts all packages in there

Sources for the modules are PowerShellGallery and for packages it is NuGet. But you can also use other or local repositories. You only have to choose one repository when executing this command, if more than one is registered.

Before doing any of that, it calls `Get-PSEnvironment` (from the [`ImportDependency`](../ImportDependency) module) once to find out what's already installed. Anything already present at a current version is skipped; only what's missing or outdated is installed or updated.

Before installing modules/packages, it will automatically scan for dependencies and will install them too, unless `-ExcludeDependencies` is used.

When you don't have suitable repositories available, it will ask you to create them.

It will also automatically create a log file in the current folder named `dependencies_install.log` (via the [`WriteLog`](../WriteLog) module), unless a logfile override is already active in your session and `-KeepLogfile` is used.

If you want to see more output in your console, just add the `-Verbose` flag to your command.

# Requirements

This module depends on two other Apteco PS Modules, which are installed automatically as dependencies from PSGallery:

- [`WriteLog`](../WriteLog) — used for all logging output
- [`ImportDependency`](../ImportDependency) — used for `Get-PSEnvironment` (OS/elevation/architecture detection, and discovery of already-installed modules and local/global NuGet packages)

# Installation

You can just download the whole repository here and pick this module, or you can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "InstallDependency" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule InstallDependency
```

If you want to find more [Apteco scripts in PSGallery](https://www.powershellgallery.com/packages?q=Tags%3A%22Apteco%22), please search with

```PowerShell
Find-Module -Repository "PSGallery" -Tag "Apteco"
```

### Installation via local Repository

If your machine does not have an online connection you can use another machine to save the module from the PSGallery website as a local file via your browser. You should download a file with an `.nupkg` extension. Please don't forget to download all dependencies too. You could simply unzip the file(s) and put the module somewhere you need it OR do it in an updatable manner and create a local repository if you don't have it already with

```PowerShell
Set-Location "$( $env:USERPROFILE )\Downloads"
New-Item -Name "PSRepo" -ItemType Directory
Register-PSRepository -Name "LocalRepo" -SourceLocation "$( $env:USERPROFILE )\Downloads\PSRepo"
Get-PSRepository
```

On Linux you would use `Set-Location "$( $env:Home )/Downloads"` or create the `.\Downloads` directory.

To trust a local repository, use

```PowerShell
Set-PSRepository -Name LocalRepo -InstallationPolicy Trusted
```

To remove the trust, just put it back to `Untrusted`

```PowerShell
Set-PSRepository -Name LocalRepo -InstallationPolicy Untrusted
```

Then put your downloaded `.nupkg` file into the newly created `PSRepo` folder and you should see the module via

```PowerShell
Find-Module -Repository LocalRepo
```

Then install the module like

```PowerShell
Find-Module -Repository LocalRepo -Name InstallDependency -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the module anymore, just remove it with

```PowerShell
Uninstall-Module -Name InstallDependency
```

## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location InstallDependency
Import-Module .\InstallDependency
```

# Functions

## Install-Dependency

The main function. Installs modules and NuGet packages.

```PowerShell
Install-Dependency -Module "WriteLog" -LocalPackage "SQLitePCLRaw.core", "Npgsql" -Verbose
```

Packages can be defined either as a raw string array, or as a `pscustomobject` with a specific version number

```PowerShell
$packages = [Array]@(
    [PSCustomObject]@{
        name = "Npgsql"
        version = "4.1.12"
    }
)
Install-Dependency -Module "WriteLog" -LocalPackage $packages -Verbose
```

### Parameters

Parameter|Explanation
-|-
`Module`|Array of modules to install on the local machine via PowerShellGallery
`GlobalPackage`|Array of NuGet packages to install globally on the local machine (needs elevated/administrator rights)
`LocalPackage`|Array of NuGet packages to install in a subfolder of the current folder. Can be changed with `LocalPackageFolder`
`LocalPackageFolder`|Folder name of the local package folder. Default is `lib`
`ExcludeDependencies`|By default, dependencies are installed for every module/package. This can be deactivated with this switch
`SuppressWarnings`|Log warnings, but don't write them to the host
`KeepLogfile`|Keep an already active logfile override rather than switching to `.\dependencies_install.log` for the duration of this call

> PowerShellGet *scripts* (`Install-Script`/`Find-Script`) are intentionally not supported — use modules instead.

### Example: DuckDB.NET across Windows PowerShell and pwsh, in one shared lib folder

`DuckDB.NET.Bindings.Full`/`DuckDB.NET.Data.Full` dropped their `netstandard2.0` build after version `1.4.4` — later versions only ship `net8.0`/`net10.0` builds, which Windows PowerShell 5.1 (running on .NET Framework) cannot load at all. So if a script needs to run under both Windows PowerShell and pwsh, `1.4.4` is the newest version Windows PowerShell can use, while pwsh can take the newest version available.

You do not need two separate `lib` folders for this. Install both into the same one — `Install-Dependency` (with the fix described in this module's changelog) keeps distinct pinned versions of the same package Id side by side rather than treating a newer version as already covering an older pinned request, and [`ImportDependency`](../ImportDependency)'s loader (`Select-CompatiblePackage`) picks the one whose target-framework folder matches whichever PowerShell edition is actually running, so only one of them is ever loaded into the process:

```PowerShell
$packages = [Array]@(
    # Windows PowerShell 5.1 pin: the last version with a netstandard2.0 build, plus the two BCL
    # polyfills its netstandard2.0 dependency group declares
    [PSCustomObject]@{ name = "DuckDB.NET.Bindings.Full"; version = "1.4.4" }
    [PSCustomObject]@{ name = "DuckDB.NET.Data.Full";     version = "1.4.4" }
    [PSCustomObject]@{ name = "System.Memory";            version = "4.6.0" }
    [PSCustomObject]@{ name = "System.Runtime.CompilerServices.Unsafe"; version = "6.0.0" }

    # pwsh: no pin needed, always take the newest build directly
    "DuckDB.NET.Bindings.Full"
    "DuckDB.NET.Data.Full"
)

Install-Dependency -LocalPackage $packages -ExcludeDependencies -Verbose
```

> Pin `System.Runtime.CompilerServices.Unsafe` to exactly `6.0.0`, not a later one. Its NuGet package version and the `AssemblyVersion` embedded in its DLL drift apart across releases: `6.1.0`'s `net462` build embeds `AssemblyVersion 6.0.1.0`, while its `netstandard2.0` build embeds `6.0.0.0`. Windows PowerShell's target-framework preference tries `net462` before `netstandard2.0`, so `6.1.0` loads the wrong identity there and `DuckDB.NET.Bindings 1.4.4` (built against `6.0.0.0`) fails at first use with a `FileNotFoundException`. `6.0.0` has no `net462` build at all, so every build it does ship reports `6.0.0.0` consistently, regardless of which one gets picked.

Run this same command from either Windows PowerShell or pwsh — it installs the same six packages either way, since installing has nothing to do with which one actually gets loaded later. Then, from **Windows PowerShell 5.1**:

```PowerShell
Import-Module ImportDependency
Import-Dependency -LoadWholePackageFolder
# DuckDB.NET.Bindings/Data 1.4.4 (netstandard2.0) get loaded; 1.5.x+ is skipped as incompatible
[DuckDB.NET.Data.DuckDBConnection]::new("Data Source=:memory:")
```

And from **pwsh**:

```PowerShell
Import-Module ImportDependency
Import-Dependency -LoadWholePackageFolder
# The newest DuckDB.NET.Bindings/Data (net8.0/net10.0) get loaded; 1.4.4 is skipped in favour of it
[DuckDB.NET.Data.DuckDBConnection]::new("Data Source=:memory:")
```

## Install-NuGetPackage

Downloads and extracts a single NuGet package directly from `nuget.org` without going through `Install-Package`/`Find-Package`. Useful when you just need the raw package contents (e.g. `lib/` DLLs) without registering a NuGet repository.

```PowerShell
Install-NuGetPackage -PackageId "Npgsql" -Version "4.1.12" -OutputDir "./lib"
```

If `-Version` is omitted, the latest available version is resolved automatically. By default the downloaded `.nupkg` file is removed after extraction; use `-KeepPackage` to keep it.

## Install-VcRedist

Checks whether the Visual C++ Redistributable (x64) is installed (needed by DuckDB and other native NuGet packages) and installs it if missing. Downloads the newest x64 `vc_redist.exe` from Microsoft's official permalink and installs it quietly.

```PowerShell
Install-VcRedist -Verbose
```

By default this asks for confirmation before installing. For unattended/automated installs, skip the prompt with `-Force`:

```PowerShell
Install-VcRedist -Force
```

Returns `$true` if vcredist x64 is installed by the end of the call (whether it already was, or was just installed), `$false` otherwise. Does nothing (and returns `$true`) on non-Windows.

# How could this module be wrapped into other modules

This is dependent on the module [`ImportDependency`](../ImportDependency) and a `./bin/dependencies.ps1` file which contains multiple arrays. This file looks like this

```PowerShell
$psModules = @(
    "WriteLog"
    "EncryptCredential"
    "ConvertUnixTimestamp"
    "ConvertStrings"
)

# Define either a simple string or provide a pscustomobject with a specific version number
$psPackages = @(
    <#
    [PSCustomObject]@{
        name = "Npgsql"
        version = "4.1.12"
    }
    #>
)
```

To wrap these arrays into an installation function, you could do it like this, but please rename the function. Please be aware that the module root is saved into a variable `$Script:moduleRoot` in the main module's `.psm1` file like `$Script:moduleRoot = $PSScriptRoot.ToString()`

```PowerShell
function Install-xyz {
    [CmdletBinding()]
    param (

    )

    process {

        # Check if InstallDependency is present
        If ( @( Get-InstalledModule | Where-Object { $_.Name -eq "InstallDependency" } ).Count -lt 1 ) {
            throw "Missing dependency, execute: 'Install-Module InstallDependency'"
        }

        # Load dependencies as variables
        . ( Join-Path -Path $Script:moduleRoot -ChildPath "/bin/dependencies.ps1" )

        # Call the function to install dependencies
        Install-Dependency -Module $psModules -LocalPackage $psPackages

    }

}
```

# Migrating from the Install-Dependencies script

The previous [`Install-Dependencies`](../Install-Dependencies) script is superseded by this module. The main differences:

- `Install-Dependencies` (script, `Install-Script`) → `Install-Dependency` (module function, `Install-Module`)
- The `-Script` parameter has been removed entirely — PowerShellGet scripts are deprecated in favor of modules, which are better integrated with the rest of this ecosystem
- The install scope (`AllUsers`/`CurrentUser`) is now derived automatically from whether the current session is elevated, instead of the `-InstallScriptAndModuleForCurrentUser` switch
- Logging, OS/elevation detection, and already-installed modules/local/global packages are now discovered via a single upfront `Get-PSEnvironment` call (from the shared [`ImportDependency`](../ImportDependency) module) instead of being re-queried separately throughout the function via `Get-InstalledModule`/`Get-Package`
- Local/global NuGet packages that are already installed at a current version are now skipped, matching how modules already behaved (previously packages were always re-searched and reinstalled)

# Contribution

You are free to use this code, put in some changes and use a pull request to feedback improvements :-)
