
@{

# Script module or binary module file associated with this manifest.
RootModule = 'InstallDependency.psm1'

# Version number of this module.
ModuleVersion = '0.3.12'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '0e50fec8-0b5d-4cca-88c0-20d7de4d4242'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2026 Apteco GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Apteco PS Modules - PowerShell install dependencies

Module to install dependencies from PowerShell Gallery and NuGet.

Downloads and installs the latest versions of some modules and packages (saved in current folder or machine folder) from the PowerShell Gallery and NuGet.
'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
    "WriteLog"
    "ImportDependency"
)

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    "Install-Dependency"
    "Install-NuGetPackage"
    "Install-VcRedist"
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @() #'*'

# Variables to export from this module
VariablesToExport = @() #'*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @() #'*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('powershell', "PSEdition_Desktop", "PSEdition_Core", "Windows", 'Linux', "Apteco")

        # A URL to the license for this module.
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/InstallDependency'

        # A URL to an icon representing this module.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # ReleaseNotes of this module
        ReleaseNotes = '
0.3.12 Re-import PackageManagement/PowerShellGet in-session right after updating them, since Import-Module -Force
       merely stacks the new version alongside the old one still loaded in-process and cmdlets kept resolving
       to the stale binaries until the whole PowerShell session was restarted.
       Fix with -AllowClobber when installing local packages
0.3.11 Added a pinned version support to keep the same version of a package installed for all environments.
       This is needed for DuckDB.NET to keep the same version for Windows PowerShell 5.1 (netstandard2.0)
       and PowerShell Core (Windows and Linux)
0.3.10 Found the real cause behind the 0.3.9 "Cannot install local packages!" abort: $pack (the list of
       packages to install) was not forced into an array, so a single match collapsed to a scalar
       object. Windows PowerShell 5.1 (Desktop) has no .Count on scalars (unlike PS 6+), so
       $pack.Count was $null, and Write-Progress''s $i/$pack.Count division threw "Attempted to divide
       by zero", aborting the whole install loop before the .nupkg cleanup was ever reached. $pack is
       now always wrapped in @() so .Count is well-defined regardless of match count or PS edition
0.3.9 Fixed the 0.3.8 .nupkg cleanup being able to abort the entire local/global package install loop:
      Install-Package -Destination can still hold a lock on the freshly written .nupkg for a moment
      (observed on Windows PowerShell 5.1''s legacy PackageManagement NuGet provider), so an immediate
      open/delete could fail with a sharing violation, which was unhandled and aborted the rest of the
      run with an unhelpful "Cannot install local packages!" warning. The cleanup now retries a few
      times with a short delay and never lets a single package''s cleanup failure abort the others, and
      the outer warning now includes the actual exception message
0.3.8 Initial release of the InstallDependency modul to replace Install-Dependencies script
      Fixed the 0.4.6 cleanup deleting the .nupkg outright, which removed the package''s only remaining
      metadata source (no .nuspec, no .nupkg left) -- Get-LocalPackage could no longer discover it at
      all, so Import-Dependency silently stopped finding/loading it. Now extracts just the tiny .nuspec
      out of the .nupkg before removing it, so the package stays discoverable via Get-LocalPackage''s
      fast nuspec path without needing to keep the full .nupkg around
0.3.7 Added -KeepPackage switch (default: off, matching Install-NuGetPackage) that removes the raw .nupkg
      files Install-Package -Destination leaves behind as siblings of the extracted lib/ref/runtimes
      folders in LocalPackageFolder after a successful install. Only ever touches LocalPackageFolder,
      never the global/machine package cache
0.3.6 Fixed -LocalPackage/-GlobalPackage being typed [String[]], which silently coerced any
      PSCustomObject (e.g. @{name="Npgsql"; version="8.0.7"}) passed for version pinning into its
      string representation before the function body ever ran -- so version pinning never actually
      worked, for any version. Changed to [Object[]] so PSCustomObject entries pass through intact.
      This bug predates the module (inherited from the original Install-Dependencies script)
0.3.5 Fixed Install-Package failing with "multiple packages matched ''PackageManagement''" (NuGet.org
      coincidentally hosts a same-named package) by specifying -ProviderName when updating PackageManagement/
      PowerShellGet, and wrapped both updates in try/catch so a failure there cannot abort the whole run
0.3.4 Suppressed the return values of Install-Package/Install-Module/Update-Module/Register-PSRepository/
      Set-PSRepository/Register-PackageSource/Set-PackageSource, which were being written to the pipeline
      unsuppressed and dumped as full PackageManagement/PowerShellGet objects to the console/caller
0.3.3 Fixed module import failing with "Cannot index into a null array" when pwsh (PowerShell Core) is not
      installed (e.g. Windows Sandbox) -> the pwsh version was read before checking whether pwsh was found at all
0.3.2 Fixed module import failing with "Access is denied" in locked-down environments like Windows Sandbox,
      where the Get-CimInstance fallback for architecture detection is blocked. Now falls back further to
      Is64BitOperatingSystem, which does not need WMI/CIM access
0.3.1 Added Install-VcRedist to check for and install the Visual C++ Redistributable (x64), moved here from
      AptecoPSFramework''s own installation script so any consumer can reuse it
0.3.0 Removed -Script support (PowerShellGet scripts are deprecated in favor of modules). Install-Dependency now
      reuses Get-PSEnvironment (from ImportDependency) for already-installed modules and local/global NuGet
      packages instead of querying Get-InstalledModule/Get-Package itself, and local/global packages are now
      skipped when already installed at a current version, matching how modules already behaved
0.2.0 Migration of Install-Dependencies script to Install-Dependency module
'
        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

