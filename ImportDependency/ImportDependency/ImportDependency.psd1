
@{

# Script module or binary module file associated with this manifest.
RootModule = 'ImportDependency.psm1'

# Version number of this module.
ModuleVersion = '0.4.20'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'bae79f8a-e164-41a4-96fe-ab9c302a1b65'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2026 Apteco GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Apteco PS Modules - PowerShell import dependencies

Module to import dependencies from the PowerShell Gallery and NuGet.

Please make sure to have the Modules WriteLog and PowerShellGet (>= 2.2.4) installed.
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
    #"MergePSCustomObject"
)

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @(
      "System.IO.Compression.FileSystem"
)

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
    "Import-Dependency"
    "Get-PSEnvironment"
    "Get-TemporaryPath"
    "Get-PythonPath"
    "Get-PwshPath"
    "Get-LocalPackage"
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
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/ImportDependency'

        # A URL to an icon representing this module.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # ReleaseNotes of this module -- kept short (PowerShell Gallery caps this field at 10600
        # characters). Full history: see CHANGELOG.md in this module's repo folder.
        ReleaseNotes = '
Full changelog: https://github.com/Apteco/AptecoPSModules/blob/main/ImportDependency/CHANGELOG.md

0.4.20 Fixed ARM64 misdetection: when RuntimeInformation.ProcessArchitecture and the CIM fallback both
       come back empty (seen in Windows Sandbox), the last-resort Is64BitOperatingSystem check only sees
       32 vs 64-bit, not ARM64 vs x64, so ARM64 got misclassified as x64 and DuckDB loaded the wrong
       runtime folder (ERROR_BAD_EXE_FORMAT). That fallback now checks PROCESSOR_ARCHITECTURE first
0.4.19 Widened 0.4.18''s kernel32 LoadLibrary retry from 3x500ms (~2s) to 10 attempts with backoff capped
       at 3s (~18s worst case) -- 3 retries was too short to ride out a transient lock on a freshly
       extracted native DLL
0.4.18 Fixed the kernel32 LoadLibrary fallback (for native runtime DLLs) discarding its return handle and
       always logging "possibly loaded" even on failure. The handle is now actually checked, with retries
       before giving up
0.4.17 Fixed Import-Dependency aborting its entire load loop (silently leaving every later package
       unloaded) when a single-version package''s /ref or /lib only contains NuGet''s "_._" empty-TFM
       placeholder convention (a runtime-only package with no managed assembly for any TFM, e.g.
       SQLitePCLRaw.lib.e_sqlite3). Both call sites in Import-Dependency are now wrapped in try/catch,
       same as Select-CompatiblePackage already was
0.4.16 Added a new function Select-CompatiblePackage to select the best matching version of a package
       for the current runtime and framework, and updated Import-Dependency to use it. This allows
       Import-Dependency to load the correct DuckDB.NET build for Windows PowerShell 5.1 (netstandard2.0)
       vs PowerShell Core (Windows and Linux)
0.4.15 Fixed Get-LocalPackage returning the .nupkg FILE itself as Path for packages found via the zip
       branch (Source="zip"), instead of the folder containing it, which silently caused
       Import-Dependency to report 0 for every load/fail counter even though packages were valid
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
