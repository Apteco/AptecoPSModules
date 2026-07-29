@{

# Script module or binary module file associated with this manifest.
RootModule = 'EncryptCredential.psm1'

# Version number of this module.
ModuleVersion = '0.4.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '43de2802-b61c-431a-a098-d6b0ce85f572'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2026 Apteco GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Apteco PS Modules - PowerShell security encryption module

Execute commands like

"Hello World" | Convert-PlaintextToSecure

to get a string like

76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=

This string can be decrypted by calling

"76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=" | Convert-SecureToPlaintext

and get back

Hello World

You better save the strings into variables ;-)

This module is used to double encrypt sensitive data like credentials, tokens etc.

Encryption happens in two layers: AES-256 with a random keyfile plus a machine-bound layer
(DPAPI on Windows, machine-id derived keys on Linux/macOS). So even if an attacker steals the
encrypted string AND the keyfile, it cannot be decrypted on another machine. With
-Scope User the string is additionally bound to the current user account.

At the first encryption a new random keyfile will be generated automatically.
The key is saved per default in your users profile, but can be exported into any other folder
via Export-Keyfile and loaded from there via Import-Keyfile.

Strings encrypted with older versions of this module stay decryptable (legacy format is
detected automatically).

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
# RequiredModules = @()

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
    "Convert-PlaintextToSecure"
    "Convert-SecureToPlaintext"
    "Export-Keyfile"
    "Import-Keyfile"
    "New-Keyfile"
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
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/EncryptCredential'

        # A URL to an icon representing this module.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # ReleaseNotes of this module
        ReleaseNotes = "
0.4.0 Encrypted strings are now really bound to the machine they were created on:
      a second encryption layer via DPAPI (Windows) or machine-id derived keys with
      AES + HMAC integrity protection (Linux/macOS) wraps the existing keyfile encryption.
      So a stolen ciphertext plus keyfile is useless on another machine.
      New -Scope parameter on Convert-PlaintextToSecure:
      'Machine' (default), 'User' (additionally bound to the current account) and
      'Portable' (old single-layer behaviour for moving ciphertexts between machines).
      Decryption stays downwards compatible - strings from older versions are detected
      and decrypted with the keyfile only.
      Export-Keyfile now re-applies restrictive file permissions to the exported copy
      and no longer switches to the new path if the copy failed.
      Import-Keyfile now validates that the file is a usable 16/24/32 byte AES key.
      Added a Pester test suite.
0.3.3 Fixed Convert-PlaintextToSecure calling New-Keyfile (the public, confirmation-gated wrapper with no -Path/-ByteLength params)
      instead of the private New-KeyfileRaw when auto-creating a missing keyfile. This threw a parameter binding error
      on any machine without an existing keyfile yet, e.g. fresh CI runners.
0.3.2 Fixed a bug where the module would not properly handle cases where the keyfile did not exist. Using New-Keyfile now instead of Create-Keyfile
0.3.1 Fixed returning an exception, when decryption failed instead of writing
      an error and returning an empty string
0.3.0 Reworked the module with Claude AI to be more secure and robust, now using another way to create
      a keyfile for salting. The old encryption method is still supported, so all
      previously encrypted strings will stay valid UNTIL you call New-Keyfile. After that,
      please re-encrypt all your credentials.
      Added ACL and linux file permission handling for the keyfile.
      Dispose the used AES object after encryption/decryption for better security.
      Changed internal functions verbs for more consistency
      Updated the copyright year to 2026
0.2.0 Tested successfully Linux support
0.1.2 Updated copyright to 2025
0.1.1 Bumped the copyright year to 2024
0.1.0 Making this module more mature with only explicit functions to export
      Removing not needed verbose output, use -verbose to see it again
      Fixed the path joining
0.0.2 Fixed a bug regarding output if a keyfile does not exist
0.0.1 Initial release through PSGallery
"

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

