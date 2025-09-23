#
# Modulmanifest für das Modul "PSNotify"
#
# Generiert von: florian.von.bracht@apteco.de
#
# Generiert am: 23.08.2023
#

@{

# Die diesem Manifest zugeordnete Skript- oder Binärmoduldatei.
RootModule = 'PSNotify.psm1'

# Die Versionsnummer dieses Moduls
ModuleVersion = '0.0.10'

# Unterstützte PSEditions
# CompatiblePSEditions = @()

# ID zur eindeutigen Kennzeichnung dieses Moduls
GUID = 'fded63d1-caad-4cf3-973a-08426e9f86d9'

# Autor dieses Moduls
Author = 'florian.von.bracht@apteco.de'

# Unternehmen oder Hersteller dieses Moduls
CompanyName = 'Apteco GmbH'

# Urheberrechtserklärung für dieses Modul
Copyright = '(c) 2025 Apteco GmbH. All rights reserved.'

# Beschreibung der von diesem Modul bereitgestellten Funktionen
Description = 'Apteco PS Modules - PowerShell Notify

This module allows you to trigger messages via email, Telegram, Slack and Teams. You can use
the channels separated from each other or combined as a group, when you want to inform via
multiple different channels.

Have a look at the GitHub repository for more information: https://github.com/Apteco/AptecoPSModules/tree/main/PSNotify

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
    'EncryptCredential'
    'ExtendFunction'
    #'Install-Dependencies'
    #'Import-Dependencies'
)

# Die Assemblys, die vor dem Importieren dieses Moduls geladen werden müssen
# RequiredAssemblies = @()

# Die Skriptdateien (PS1-Dateien), die vor dem Importieren dieses Moduls in der Umgebung des Aufrufers ausgeführt werden.
ScriptsToProcess = @(
    #'Install-Dependencies'
    #'Import-Dependencies'
)

# Die Typdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# TypesToProcess = @()

# Die Formatdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# FormatsToProcess = @()

# Die Module, die als geschachtelte Module des in "RootModule/ModuleToProcess" angegebenen Moduls importiert werden sollen.
# NestedModules = @()

# Aus diesem Modul zu exportierende Funktionen. Um optimale Leistung zu erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht. Verwenden Sie ein leeres Array, wenn keine zu exportierenden Funktionen vorhanden sind.
FunctionsToExport = @(

    # Telegram
    'Add-TelegramChannel'
    'Get-TelegramChannel'
    'Remove-TelegramChannel'
    'Add-TelegramTarget'
    'Remove-TelegramTarget'
    'Send-TelegramNotification'
    'Get-TelegramMe'
    'Get-TelegramUpdates'

    # Email
    'Add-EmailChannel'
    'Get-EmailChannel'
    'Remove-EmailChannel'
    'Add-EmailTarget'
    'Remove-EmailTarget'
    'Install-Mailkit'
    'Send-MailNotification'

    # Slack
    'Add-SlackChannel'
    'Get-SlackChannel'
    'Remove-SlackChannel'
    'Add-SlackTarget'
    'Remove-SlackTarget'
    'Get-SlackConversations'
    'Send-SlackNotification'

    # Teams
    'Add-TeamsChannel'
    'Get-TeamsChannel'
    'Remove-TeamsChannel'
    'Send-TeamsNotification'

    # Group
    'Add-NotificationGroup'
    'Add-NotificationGroupTarget'
    'Get-NotificationGroups'
    'Send-GroupNotification'

    # General
    'Get-NotificationChannels'
    'Get-NotificationTargets'

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
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/PSNotify'

        # Eine URL zu einem Symbol, das das Modul darstellt.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # 'ReleaseNotes' des Moduls
        ReleaseNotes = '
0.0.10 Updated copyright to 2025
0.0.9 Fixed the order of $null comparisons
0.0.8 Bumped the copyright year to 2024
0.0.7 Improved the Get-TelegramUpdates function to allow input parameter like offset, limit and timeout
0.0.6 Get Telegram updates
0.0.5 Some fixed for Teams Updates
0.0.4 More wrong named functions fixed
0.0.3 Adding milliseconds to backup store file name
      Fixed a bug where "null" was put into the channels
      Fixed wrong named functions
0.0.2 Fixed wrong nameing of Send-TeamsUpdate to Send-TeamsNotification
      Fixed a small $null bug when creating the first channel
0.0.1 Initial release of PSNotify module through psgallery
'

    } # Ende der PSData-Hashtabelle

} # Ende der PrivateData-Hashtabelle

# HelpInfo-URI dieses Moduls
# HelpInfoURI = ''

# Standardpräfix für Befehle, die aus diesem Modul exportiert werden. Das Standardpräfix kann mit "Import-Module -Prefix" überschrieben werden.
# DefaultCommandPrefix = ''

}

