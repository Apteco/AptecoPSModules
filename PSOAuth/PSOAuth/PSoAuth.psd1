
@{

# Die diesem Manifest zugeordnete Skript- oder Binärmoduldatei.
RootModule = 'PSOAuth.psm1'

# Die Versionsnummer dieses Moduls
ModuleVersion = '0.1.5'

# Unterstützte PSEditions
# CompatiblePSEditions = @()

# ID zur eindeutigen Kennzeichnung dieses Moduls
GUID = '36746cd0-0a75-4e34-a2cc-e9f736ed8cd8'

# Autor dieses Moduls
Author = 'florian.von.bracht@apteco.de'

# Unternehmen oder Hersteller dieses Moduls
CompanyName = 'Apteco GmbH'

# Urheberrechtserklärung für dieses Modul
Copyright = '(c) 2026 Apteco GmbH. All rights reserved.'

# Beschreibung der von diesem Modul bereitgestellten Funktionen
Description = 'Apteco PS Modules - PowerShell oAuth

Support of oAuth v2 in PowerShell! This module allows the oAuth flow to create your first api token for Microsoft Dynamics, Salesforce, CleverReach and much more...
We support redirect urls to local urls `http://localhost:54321` and app urls (handled via registry) `apttoken://localhost`. The local url is instantly starting up a
basic webserver on the port you have defined. This module can be used for debugging or server2server communication. Here you can see the two methods than can be used:

'

# Die für dieses Modul mindestens erforderliche Version des Windows PowerShell-Moduls
PowerShellVersion = '5.1'

# Der Name des für dieses Modul erforderlichen Windows PowerShell-Hosts
# PowerShellHostName = ''

# Die für dieses Modul mindestens erforderliche Version des Windows PowerShell-Hosts
# PowerShellHostVersion = ''

# Die für dieses Modul mindestens erforderliche Microsoft .NET Framework-Version. Diese erforderliche Komponente ist nur für die PowerShell Desktop-Edition gültig.
# DotNetFrameworkVersion = ''

# Die für dieses Modul mindestens erforderliche Version der CLR (Common Language Runtime). Diese erforderliche Komponente ist nur für die PowerShell Desktop-Edition gültig.
# CLRVersion = ''

# Die für dieses Modul erforderliche Prozessorarchitektur ("Keine", "X86", "Amd64").
# ProcessorArchitecture = ''

# Die Module, die vor dem Importieren dieses Moduls in die globale Umgebung geladen werden müssen
RequiredModules = @(
    #"Install-Dependencies"
)

# Die Assemblys, die vor dem Importieren dieses Moduls geladen werden müssen
# RequiredAssemblies = @()

# Die Skriptdateien (PS1-Dateien), die vor dem Importieren dieses Moduls in der Umgebung des Aufrufers ausgeführt werden.
# ScriptsToProcess = @()

# Die Typdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# TypesToProcess = @()

# Die Formatdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# FormatsToProcess = @()

# Die Module, die als geschachtelte Module des in "RootModule/ModuleToProcess" angegebenen Moduls importiert werden sollen.
# NestedModules = @()

# Aus diesem Modul zu exportierende Funktionen. Um optimale Leistung zu erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht. Verwenden Sie ein leeres Array, wenn keine zu exportierenden Funktionen vorhanden sind.
FunctionsToExport = @(
    "Request-OAuthApp"
    "Request-OAuthLocalhost"
    "Request-TokenRefresh"
)

# Aus diesem Modul zu exportierende Cmdlets. Um optimale Leistung zu erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht. Verwenden Sie ein leeres Array, wenn keine zu exportierenden Cmdlets vorhanden sind.
CmdletsToExport = @() #'*'

# Die aus diesem Modul zu exportierenden Variablen
VariablesToExport = @() #'*'

# Aus diesem Modul zu exportierende Aliase. Um optimale Leistung zu erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht. Verwenden Sie ein leeres Array, wenn keine zu exportierenden Aliase vorhanden sind.
AliasesToExport = @() #'*'

# Aus diesem Modul zu exportierende DSC-Ressourcen
# DscResourcesToExport = @()

# Liste aller Module in diesem Modulpaket
# ModuleList = @()

# Liste aller Dateien in diesem Modulpaket
# FileList = @()

# Die privaten Daten, die an das in "RootModule/ModuleToProcess" angegebene Modul übergeben werden sollen. Diese können auch eine PSData-Hashtabelle mit zusätzlichen von PowerShell verwendeten Modulmetadaten enthalten.
PrivateData = @{

    PSData = @{

        # 'Tags' wurde auf das Modul angewendet und unterstützt die Modulermittlung in Onlinekatalogen.
        Tags = @("PSEdition_Desktop", "PSEdition_Core", "Windows", "Apteco")

        # Eine URL zur Lizenz für dieses Modul.
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'

        # Eine URL zur Hauptwebsite für dieses Projekt.
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/PSOAuth'

        # Eine URL zu einem Symbol, das das Modul darstellt.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # 'ReleaseNotes' des Moduls
        ReleaseNotes = '
0.1.5 Replacing Import-Dependencies with a new module ImportDependency to handle dependencies better
0.1.4 Enhancing some spellings
0.1.3 Added a switch when setting the logfile if it should be overridden or not
0.1.2 Fixed temporary module and script path loading
0.1.1 Fixed a $null comparison order
0.1.0 Bumping version to 0.1.0
      Fix: Preventing null or empty tokens
0.0.8 Bumped the copyright year to 2024
0.0.7 Fix for wrong cmdlet name ConvertToJson to ConvertTo-JSON
0.0.6 Support of scope and state payload for oAuth v2 flow
0.0.5 New Switch flag to save the payload of the second call
      More documentation for the app and localhost functions
      New PSCustomObject that can be saved in the settings json file, so it can be used for token refreshment
0.0.4 Fix for setting the logfile in the main modules process -> this could interrupt when launched from .net in a non-writeable folder like System32
0.0.3 Fix for using a wrong variable in re-saving the token
      Added description for this module
0.0.2 Allow custom payload to be saved in the settings json file
      Fix of saving the boolean switch parameter SaveSeparateTokenFile
0.0.1 Initial release of PSOAuth supporting app and localhost methods
'

    } # Ende der PSData-Hashtabelle

} # Ende der PrivateData-Hashtabelle

# HelpInfo-URI dieses Moduls
# HelpInfoURI = ''

# Standardpräfix für Befehle, die aus diesem Modul exportiert werden. Das Standardpräfix kann mit "Import-Module -Prefix" überschrieben werden.
# DefaultCommandPrefix = ''

}

