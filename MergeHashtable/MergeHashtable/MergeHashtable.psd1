﻿#
# Module manifest for module 'MergeHashtable'
#
# Generated by: florian.von.bracht@apteco.de
#
# Generated on: 18.08.2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'MergeHashtable.psm1'

# Version number of this module.
ModuleVersion = '0.0.4'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'a870656a-f285-40ba-9ecb-5df64000387e'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2024 Apteco GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Apteco PS Modules - PowerShell merge Hashtable

This module merges two hashtables into one. It is able to handle nested structures like hashtables, arrays and PSCustomObjects. Please see the examples below.

Just use

```PowerShell
$left = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [hashtable]@{
        "Street" = "Kaiserstraße 35"
    }
    "tags" = [Array]@("nice","company")
    "product" = [PSCustomObject]@{
        "name" = "Orbit"
        "owner" = "Apteco Ltd."
    }
}

$right = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [hashtable]@{
        "Street" = "Schaumainkai 87"
        "Postcode" = 60596
    }
    "tags" = [Array]@("wow")
    "product" = [PSCustomObject]@{
        "sprint" = 106
    }
}


Merge-Hashtable -Left $left -right $right -AddKeysFromRight -MergeArrays -MergePSCustomObjects -MergeHashtables

```

to merge two nested hashtables into one where the "right" will overwrite existing values from "left".

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
    "Merge-Hashtable"
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
        Tags = @("PSEdition_Desktop", "PSEdition_Core", "Windows", "Apteco")

        # A URL to the license for this module.
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/MergeHashtable'

        # A URL to an icon representing this module.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # ReleaseNotes of this module
        ReleaseNotes = '
0.0.4 Bumped the copyright year to 2024
0.0.3 Remove dependency for MergePSCustomObject module and add dynamically a message, when it will be needed
0.0.2 Add dependency for MergePSCustomObject module
0.0.1 Initial release of merge hashtable module through psgallery
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

