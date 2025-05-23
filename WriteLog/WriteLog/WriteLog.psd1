
@{

# Die diesem Manifest zugeordnete Skript- oder Binärmoduldatei.
RootModule = 'WriteLog.psm1'

# Die Versionsnummer dieses Moduls
ModuleVersion = '0.9.14'

# Unterstützte PSEditions
# CompatiblePSEditions = @()

# ID zur eindeutigen Kennzeichnung dieses Moduls
GUID = '36746cd0-0a75-4e34-a2cc-e9f736ed8cd8'

# Autor dieses Moduls
Author = 'florian.von.bracht@apteco.de'

# Unternehmen oder Hersteller dieses Moduls
CompanyName = 'Apteco GmbH'

# Urheberrechtserklärung für dieses Modul
Copyright = '(c) 2025 Apteco GmbH. All rights reserved.'

# Beschreibung der von diesem Modul bereitgestellten Funktionen
Description = 'Apteco PS Modules - PowerShell logging script

Execute commands like

Write-Log -message "Hello World"
Write-Log -message "Hello World" -severity ([LogSeverity]::ERROR)
"Hello World" | Write-Log

The logfile getting written looks like

20210217134552	a6f3eda5-1b50-4841-861e-010174784e8c	INFO	Hello World
20210217134617	a6f3eda5-1b50-4841-861e-010174784e8c	ERROR	Hello World

separated by tabs.

Make sure, the variables $logfile and $processId are present before calling this. Otherwise they will be created automatically and you are notified about the location and the current process id
The variables could be filled like

$logfile = ".\test.log"
$processId = [guid]::NewGuid()

The process id is good for parallel calls/processes so you know they belong together
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
# RequiredModules = @()

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
    "Write-Log"
    "Get-Logfile"
    "Set-Logfile"
    "Get-ProcessId"
    "Set-ProcessId"
    "Resize-Logfile"
    "Get-LogfileOverride"
    "Get-ProcessIdOverride"
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
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/WriteLog'

        # Eine URL zu einem Symbol, das das Modul darstellt.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # 'ReleaseNotes' des Moduls
        ReleaseNotes = '
0.9.14 If message is null, it will throw an error. Invalid path for logfile will throw an error, too
0.9.13 Added a switch when setting the logfile if it should be overridden or not
0.9.12 Fixing a few return values, outputting verbose instead of returning values in set functions
0.9.11 Fixed missing public function declarations
0.9.10 Added two functions to find out if default logfile and processid have been overriden
       Now setting the filename and processid earlier
0.9.9 Removed dependency of New-TemporaryFile
      Removed the hints to logfile path and process id. This will be automatically set and can be overridden
0.9.8 Fixing a problem with accidental removed dashes
0.9.7 Changed formatting and resolved some hints from PSScriptAnalyzer
0.9.6 Changed warning output to verbose information
0.9.5 Changing Write-Output to Write-Information an tag the streams instead for Default and Info
0.9.4 Removed dependencies on variables and added getter/setter functions instead
0.9.3 Adding a function to clean a logfile (keep only latest n rows)
      Conversion of script to module
0.9.2 Updated description and removed the return value because it can cause problems in c# calling the script
0.9.1 Initial release of logging module through psgallery
'

    } # Ende der PSData-Hashtabelle

} # Ende der PrivateData-Hashtabelle

}

