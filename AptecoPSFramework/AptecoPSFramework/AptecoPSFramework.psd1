
@{

# Script module or binary module file associated with this manifest.
RootModule = 'AptecoPSFramework.psm1'

# Version number of this module.
ModuleVersion = '0.1.4'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'ada4a156-dea2-4821-9c8b-e7ef33a7fa46'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2023 Apteco GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Apteco PS Modules - Framework

This module allows Apteco, partners and customers to develop their own integrations.
This framework brings lots of useful features with it like
- Logging + Send information to Orbit UI
- Standardised settings management saved in json files
- Update upward compatibility when there are new features and setting possibilites
- Errorhandling and causing stop of campaigns on problems
- Installation of dependencies
- Developer mode to quickly create own integrations
- Secure encryption of tokens and credentials
- Possibility to develop cmdlets that can be executed directly in PowerShell e.g. to start clean up jobs or download specific data from an integration...
- Easy boilerplate, documentation on GitHub and Demo-Channel to start quickly
- Easy updates via PowerShellGallery
- Easy integration of proxies, custom headers, REST handling
- Using secure oAuth for connected apps like Microsoft Dynamics, Salesforce SalesCloud and CleverReach
- Much more to follow...

Your help is appreciated. Just contact me.
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
# Using our own dependency module later for more scripts/modules/packages
RequiredModules = @(
    #"WriteLog"
    #"SqlServer"
    #"EncryptCredential"
    #"ConvertUnixTimestamp"
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
    "Add-PluginFolder"
    "Export-Settings"
    "Get-Debug"
    "Get-Plugin"
    "Get-PluginFolders"
    "Get-Plugins"
    "Get-ProcessIdentifier"
    "Get-Settings"
    "Import-Plugin"
    "Import-Settings"
    "Install-AptecoPSFramework"
    "Register-Plugins"
    "Set-DebugMode"
    "Set-ExecutionDirectory"
    "Set-ProcessIdentifier"
    "Set-Settings"
    "Install-Plugin"
) #'*'

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

        # 'Tags' wurde auf das Modul angewendet und unterstützt die Modulermittlung in Onlinekatalogen.
        Tags = @("PSEdition_Desktop", "Windows", "Apteco")

        # Eine URL zur Lizenz für dieses Modul.
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'

        # Eine URL zur Hauptwebsite für dieses Projekt.
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/dev/AptecoPSFramework'

        # Eine URL zu einem Symbol, das das Modul darstellt.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # release channel
        #Prerelease = 'alpha3'

        # 'ReleaseNotes' des Moduls
        ReleaseNotes = '
0.1.4 Changed the uploadsize from 2 to 80 for Hubspot
      Fix for loading properties of objects other than contacts in Hubspot
0.1.3 Changed Microsoft Dynamics Dataverse Integration to pagesize of 4500 instead of 3 for testing
      Removed -MergeArrays flag when merging settings in module and plugin -> now the arrays from the settings file are the important ones
      Adding hubspot to load CRM data with properties and search/filter, sync all of your data now!
      Hubspot list upload is now implemented through a list chooser in Orbit/PeopleStage and with use of the email address
      Changed the behaviour at Import-Settings, which looks now automatically for settings.json, otherwise you have to refer to it
0.1.2 New hashtable variable "variableCache" for plugins to share data/variables between functions
      Fix of saving oauth settings file path in the settings.json file
      Read-Only Support for Microsoft Dynamics DataVerse Web API
0.1.1 New version jump with more dependencies that have been implemented now: Install-Dependencies and Import-Dependencies, make sure to install those scripts before updating
      Fix for http calls so generic problematic are not repeating infinite
      Loading assemblies as dependencies, too
      Add a function/cmdlet to install plugins dependencies
      Adding more CleverReach api functions around token handling
      Support of PSOAuth for Salesforce SalesCloud and Microsoft Dynamics Dataverse, improved token refreshment for CleverReach
      Added enforced secret encryption for CleverReach, Salesforce and Microsoft
      Added automatic try of token refresh, if there is a http401 error
0.0.20 Exchanged the module/script path handling for the module itself and the boilerplate
       Improved the installation of dependencies with a new script
       Fix of $null when loading details of new attributes
0.0.19 Added script support for boilerplates
0.0.18 Added a new setting for CleverReach to put response log information into a separate logfile
       Added more documentation for CleverReach response download
0.0.17 Fixing a problem when CleverReach invokes a http502 invalid gateway error -> Repeat the call a few times
       Fixing a problem in CleverReach when creating new attributes we get now less information back, so we are loading details of new created attributes
       Adding functionality to repeat REST calls, when specific problems occur
0.0.16 Added String values for Preheaders that are nulled when they are used
0.0.15 Fixing a problem with WriteLog module
0.0.14 Fixing a problem with the preview read of the input file when it has more than 100 rows
0.0.13 Fixing a problem with newly created lists/groups without any attributes for CleverReach
       Preventing a problem with empty upserts for CleverReach
0.0.12 Fixing a problem when there is no preheader html already present in CleverReach
0.0.11 Fixing updating the settings.json file after an module update
0.0.10 Enrolling fix for changed function name
       Changed the Tag removal to wait until finished
0.0.9 Support for waiting until the mailing is released for CleverReach
      Fixed a query for global deactivated receivers
      Fixed a request for group stats to be at the end of the broadcast for CleverReach
      Changed a setting for global receiver deactivations
      Query group stats by runtime filters instead of cached stats
      Added more documentation and FAQs about this integration
      Changed the preheader behaviour for CleverReach (now dependent on a variable)
0.0.8 Preheader Support for CleverReach, just needs a "Preheader" variable
      Fixed a visual problem after the mailing was sent. Needed the "eddytor" for this
0.0.7 Removing not needed zip files
      Fixing a problem with the pluginsfolder in the settings
      Complete rewriting of the settings part for joining PSCustomObjects and Hashtables
0.0.6 Added tags support for uploading data and preview
      Fixed a bug in the CleverReach Preview regarding new attributes
0.0.5 Added CleverReach Email Preview
0.0.4 Changed URLs
      Many improvements and fixes for the CleverReach plugin
      Boilerplate fixes for loading psmodulepath environment variable
0.0.3 Automatically load new plugin folders and save them in the settings
      Support response gathering for CleverReach Plugin
0.0.2 Small fixes after testing
0.0.1 Initial release of Apteco PS module through psgallery
'

    } # Ende der PSData-Hashtabelle

} # Ende der PrivateData-Hashtabelle

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}