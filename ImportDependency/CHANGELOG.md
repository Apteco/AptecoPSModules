# Changelog

All notable changes to the `ImportDependency` module. The `.psd1`'s `ReleaseNotes` only keeps the
most recent entries (PowerShell Gallery caps that field at 10600 characters) — this file is the
full history.

## 0.4.20
Fixed ARM64 misdetection: when `RuntimeInformation.ProcessArchitecture` and the CIM fallback both
come back empty (seen in Windows Sandbox), the last-resort `Is64BitOperatingSystem` check only sees
32 vs 64-bit, not ARM64 vs x64, so ARM64 got misclassified as x64 and DuckDB loaded the wrong
runtime folder (`ERROR_BAD_EXE_FORMAT`). That fallback now checks `PROCESSOR_ARCHITECTURE` first.

## 0.4.19
Widened 0.4.18's kernel32 `LoadLibrary` retry from 3x500ms (~2s) to 10 attempts with backoff capped
at 3s (~18s worst case) — 3 retries was too short to ride out a transient lock on a freshly
extracted native DLL.

## 0.4.18
Fixed the kernel32 `LoadLibrary` fallback (for native runtime DLLs) discarding its return handle and
always logging "possibly loaded" even on failure. The handle is now actually checked, with retries
before giving up.

## 0.4.17
Fixed `Import-Dependency` aborting its entire load loop (silently leaving every later package
unloaded) when a single-version package's `/ref` or `/lib` only contains NuGet's `_._` empty-TFM
placeholder convention (a runtime-only package with no managed assembly for any TFM, e.g.
`SQLitePCLRaw.lib.e_sqlite3`). `Get-BestReferencePath`/`Get-BestFrameworkPath` throw in that case,
and `-ErrorAction SilentlyContinue` does not suppress a throw — only `Select-CompatiblePackage`'s
own call was try/catch-protected, so this only showed up for packages with exactly one installed
version, which skip `Select-CompatiblePackage`'s multi-version filtering entirely. Both call sites
in `Import-Dependency` are now wrapped in try/catch, same as `Select-CompatiblePackage` already was.

## 0.4.16
Added a new function `Select-CompatiblePackage` to select the best matching version of a package
for the current runtime and framework, and updated `Import-Dependency` to use it. This allows
`Import-Dependency` to load the correct DuckDB.NET build for Windows PowerShell 5.1 (netstandard2.0)
vs PowerShell Core (Windows and Linux).

## 0.4.15
Fixed `Get-LocalPackage` returning the `.nupkg` FILE itself as `Path` for packages found via the zip
branch (`Source="zip"`), instead of the folder containing it. `Install-Package -Destination` extracts
`lib`/`ref`/`runtimes` as siblings of the `.nupkg` it keeps, but `Import-Dependency`'s loader does
`Get-Item -Path $pkg.Path` and then `Test-Path "<Path>/lib"` — which is always false (silently, no
error) when `Path` is a file. This caused `Import-Dependency` to report 0 for every load/fail counter
even though packages were found and their files were completely valid, e.g. Npgsql/DuckDB.NET.

## 0.4.14
Fixed `InstalledModules`/`InstalledGlobalPackages` only ever being scanned once, at module import
time. `Update-BackgroundJob` only received results from jobs already in flight and never started
new ones, so every `Get-PSEnvironment` call after the first silently returned the same stale
snapshot — newly installed modules/packages only showed up after `Import-Module -Force`. The job
start logic is now in `Start-EnvironmentBackgroundJob`, which `Update-BackgroundJob` calls again
whenever no jobs are currently running, so it genuinely re-scans on every non-skipped call.

## 0.4.13
Fixed the same staleness problem for PackageManagement/PowerShellGet: `Get-PSEnvironment` was
returning the version cached from module import time instead of the current one, causing repeated
unnecessary "outdated, updating now" attempts even after PackageManagement/PowerShellGet had already
been updated mid-session. New `Get-LatestModuleVersion` is now checked live on every
`Get-PSEnvironment` call.

## 0.4.12
Fixed `Get-PSEnvironment` returning a stale VcRedist status cached from module import time. It is
now always re-checked live, so installs/removals done after import (e.g. via `InstallDependency`'s
`Install-VcRedist`) show up immediately on the next `Get-PSEnvironment` call.

## 0.4.11
- Adding some more verbose output to help with debugging.
- Fixed module import failing with "Access is denied" in locked-down environments like Windows
  Sandbox, where the `Get-CimInstance` fallback for architecture detection is blocked. Now falls
  back further to `Is64BitOperatingSystem`, which does not need WMI/CIM access.

## 0.4.10
- Fixed a problem when getting the python path on Windows.
- Fixed a problem with PowerShell Core where a path was tried to be loaded, even when pwsh is not
  installed.

## 0.4.9
Added a check to remove inaccessible paths from `PSModulePath` to avoid errors when loading modules.

## 0.4.8
- Added all execution policies to `Get-PSEnvironment`.
- Fixed a problem with checking elevation on Linux and MacOS.

## 0.4.7
Suppressing runtime loading message.

## 0.4.6
Added pwsh/Linux compatibility to load native Linux/macOS assemblies from the runtimes folder.

## 0.4.5
Fixed a problem with loading native assemblies from runtimes folders.

## 0.4.4
- Added an internal switch for `-verbose` output.
- Fixed a problem with loading local packages when using the wrong path.

## 0.4.3
- Fixed a problem with loading local packages when using Id rather than Name.
- Changed the way how to load the frameworks preferences in packages.

## 0.4.2
Changed the way on how to load modules.

## 0.4.1
Fixed a typo in `Import-Dependency` after tests with Ubuntu.

## 0.4.0
- Adding verbose output when import-module.
- Changing the way how we load module and package metadata for better performance.
- Cosmetic changes on code.
- Determination if pwsh is 64 bit is now a background job.
- Added a new function to load packages from specific folders without `Get-Package`.

## 0.3.15
- Fixed a problem with PowerShell Core and indefinite running of `Get-Package`.
- Added execution policy for machine to `Get-PSEnvironment`.
- Added net471 and netcoreapp2.0 to framework preferences.
- Added `win` to runtime preferences with loading logic.
- Removed old comments and code.

## 0.3.14
Fixing a missing return value from 0.3.13.

## 0.3.13
Using `Get-Module -ListAvailable` rather than `Get-InstalledModule` to avoid problems with
PowerShellGet and PSCore.

## 0.3.12
Fixed a bug with choosing the wrong runtime folder when loading packages with native DLLs.

## 0.3.11
Fixed a problem with the `$psedition` variable that is already existing and read-only.

## 0.3.10
- Added a hint when PowerShellGet is not installed in PowerShell Core.
- Fixed a problem with `$null` logfiles in `Import-Dependency`.

## 0.3.9
Fix for vcredist, when there is only one version installed.

## 0.3.8
- Added more default information about PSCore, if installed (but also when not currently used).
- Fixed getting pwsh path on Windows and Linux.
- Fixed loading of module and script path.

## 0.3.7
Returning absolute logfile path rather than a relative one.

## 0.3.6
- Adding a function `Get-TemporaryPath` to get a temporary path on Windows and Linux.
- Adding two functions to get pwsh and python path.

## 0.3.5
Adding Linux functionality for current executing user and if it is sudo/elevated.

## 0.3.4
- Added more switches to get faster execution of `Get-PSEnvironment`.
- Added a synopsis to `Get-PSEnvironment`.
- Changed the approach to load the versions of PowerShellGet and PackageManagement.
- Loading the OS directly at the start of module import to determine if PATH needs to be extended.

## 0.3.3
Fixed a problem when VCRedist is not installed at all.

## 0.3.2
Added functionality to load global and local packages into `Get-PSEnvironment`.

## 0.3.1
Added check of vcredist, PowerShellGet and PackageManagement version.

## 0.3.0
- Re-publication as module rather than a script.
- Support for PowerShell Core for Windows and Linux, possibly MacOS.
- Support for Windows ARM64 architecture.
- Added function `Get-PSEnvironment` to get information about the current PowerShell environment.

## 0.2.0
Added support for loading runtimes with Windows ARM64 architecture.

## 0.1.4
- Removed to not load WriteLog module as it is already required here.
- Changed `Get-LogfileOverride` to new parameter `KeepLogfile` as WriteLog is loaded in this script
  and `Get-LogfileOverride` will always be the default value.

## 0.1.3
Change the last message to VERBOSE instead of INFO.

## 0.1.2
Fixed temporary module and script path loading.

## 0.1.1
Improved the missing module load.

## 0.1.0
Improving documentation, adding PATH variables, missing modules will not throw an error anymore.

## 0.0.8
Added a parameter switch to suppress warnings to host.

## 0.0.7
Added a note in the log that a runtime was only possibly loaded.

## 0.0.6
- Checking 64bit of OS and process.
- Output last error when using Kernel32.
- Adding runtime errors to log instead of console.

## 0.0.5
Make sure `Get-Package` is from PackageManagement and NOT VS.

## 0.0.4
Make sure to reuse a log, if already set.

## 0.0.3
- Minor improvements.
- Status information at the end.
- Differentiation between .NET Core and Windows/Desktop priorities.

## 0.0.2
Fixed a problem with out-commented input parameters.

## 0.0.1
Initial release of this script.
