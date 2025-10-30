
@{

# Script module or binary module file associated with this manifest.
RootModule = 'ImportDependency.psm1'

# Version number of this module.
ModuleVersion = '0.3.11'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'bae79f8a-e164-41a4-96fe-ab9c302a1b65'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2025 Apteco GmbH. All rights reserved.'

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
    "Import-Dependency"
    "Get-PSEnvironment"
    "Get-TemporaryPath"
    "Get-PythonPath"
    "Get-PwshPath"
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

        # ReleaseNotes of this module
        ReleaseNotes = '
0.3.11 Fixed a problem with $psedition variable that is already existing and read-only
0.3.10 Added a hint when PowerShellGet is not installed in PowerShell Core
       Fixed a problem with $null logfiles in Import-Dependency
0.3.9 Fix for vcredist, when there is only one version installed
0.3.8 Added more default information about PSCore, if installed (but also when not currently used)
      Fixed getting pwsh path on Windows and Linux
      Fixed loading of module and script path
0.3.7 Returning absolute logfile path rather than a relative one
0.3.6 Adding a function Get-TemporaryPath to get a temporary path on Windows and Linux
      Adding two functions to get pwsh and python path
0.3.5 Adding Linux functionality for current executing user and if it is sudo/elevated
0.3.4 Added more switches to get faster execution of Get-PSEnvironment
      Added a synopsys to Get-PSEnvironment
      Changed the approach to load the versions of PowerShellGet and PackageManagement
      Loading the OS directly at the start of module import to determine if PATH needs to be extended
0.3.3 Fixed a problem when VCRedist is not installed at all
0.3.2 Added functionality to load global and local packages into Get-PSEnvironment
0.3.1 Added check of vcredist, powershellget and packagemanagement version
0.3.0 Re-publication as module rather than a script
      Support for PowerShell Core for Windows and Linux, possibly MacOS
      Support for Windows ARM64 architecture
      Added function Get-PSEnvironment to get information about the current PowerShell environment
0.2.0 Added support for loading runtimes with Windows ARM64 architecture
0.1.4 Removed to not load WriteLog module as it is already required here
      Changed Get-LogfileOverride to new parameter KeepLogfile as WriteLog is loaded
        in this script and Get-LogfileOverride will always be the default value
0.1.3 Change the last message to VERBOSE instead of INFO
0.1.2 Fixed temporary module and script path loading
0.1.1 Improved the missing module load
0.1.0 Improving documentation, adding PATH variables, missing modules will not throw an error anymore
0.0.8 Added a parameter switch to suppress warnings to host
0.0.7 Added a note in the log that a runtime was only possibly loaded
0.0.6 Checking 64bit of OS and process
      Output last error when using Kernel32
      Adding runtime errors to log instead of console
0.0.5 Make sure Get-Package is from PackageManagement and NOT VS
0.0.4 Make sure to reuse a log, if already set
0.0.3 Minor Improvements
      Status information at the end
      Differentiation between .net core and windows/desktop priorities
0.0.2 Fixed a problem with out commented input parameters
0.0.1 Initial release of this script
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

