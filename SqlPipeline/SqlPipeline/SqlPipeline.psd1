
@{

# Die diesem Manifest zugeordnete Skript- oder Binärmoduldatei.
RootModule = 'SqlPipeline.psm1'

# Die Versionsnummer dieses Moduls
ModuleVersion = '0.3.9'

# Unterstützte PSEditions
# CompatiblePSEditions = @()

# ID zur eindeutigen Kennzeichnung dieses Moduls
GUID = 'c497508b-29a6-4b0e-b53c-aa093d860d0f'

# Autor dieses Moduls
Author = 'florian.von.bracht@apteco.de'

# Unternehmen oder Hersteller dieses Moduls
CompanyName = 'Apteco GmbH'

# Urheberrechtserklärung für dieses Modul
Copyright = '(c) 2026 Apteco GmbH. All rights reserved.'

# Beschreibung der von diesem Modul bereitgestellten Funktionen
Description = 'Apteco PS Modules - Wrapper for SimplySQL
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
    #"SimplySQL"
    "ImportDependency"
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

    # SimplySQL
    "Add-RowsToSql"

    # DuckDB
    "Add-RowsToDuckDB"
    "Invoke-IncrementalLoad"
    "New-DuckDBConnection"
    "Initialize-SQLPipeline"
    "Close-SqlPipeline"
    "Get-LastLoadTimeStamp"
    "Get-DuckDBData"
    "Invoke-DuckDBQuery"
    "Set-LoadMetadata"
    "Export-DuckDBToParquet"
    "Show-DuckDBConnection"

    # General
    "Install-SqlPipeline"

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
        Tags = @('powershell', "PSEdition_Desktop", "PSEdition_Core", "Windows", 'Linux', "Apteco")

        # Eine URL zur Lizenz für dieses Modul.
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'

        # Eine URL zur Hauptwebsite für dieses Projekt.
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/SqlPipeline'

        # Eine URL zu einem Symbol, das das Modul darstellt.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # 'ReleaseNotes' des Moduls
        ReleaseNotes = '
0.3.9 Performance improvement for appending rows with complex datatypes (e.g. arrays, objects) by only checking the first row for complex columns and then directly serializing values without checking every time
0.3.8 Fixed the encryption for DuckDB connections
0.3.7 DuckDB: multi-row type inference & appender fixes with numeric and boolean types
0.3.6 Adding functionality to count updates and inserts when executing the MERGE
0.3.5 Added function to show open DuckDB connections: Show-DuckDBConnection
0.3.4 Fixing package installation with PowerShell 5.1 because Expand-Archive only supports *.zip files
0.3.3 Extending Install-SqlPipeline to install DuckDB.net 1.4.4 when using PowerShell 5.1 (latest supported version), pwsh is supporting all latest versions
      Fixing to not cancel the module import if SimplySQL does not match the current processor architecture
      Fixing returned values for last loaded timestamp, duckdb columns, existing table, Get-DuckDB data in general
      Fixing datatype matching for DuckDB, as there is not Int32
      Fixing the fallback of a closed connection to existing in-memory connection
0.3.2 Renaming Close-DuckDBConnection to Close-SqlPipeline to not clash with Close-DuckDBConnection of AptecoPSFramework (which is used for direct DuckDB connections outside of SqlPipeline)
0.3.1 Skipping comparison with complex datatypes with -SimpleTypesOnly for better import performance
      Adding a csv importer to export big files first into a temporary file and directly import them via DuckDB into a staging table
      Added quotations around column names for duckdb support
0.3.0 Added DuckDB.net support through Add-RowsToDuckDB and more
      Added verbose output when importing module
      Better usage of ImportDependency to recognize if local package dependencies are already loaded
      Added local package installation for DuckDB.net (not needed for Add-RowsToSql, only for Add-RowsToDuckDB): Install-SqlPipeline
      Added function to export DuckDB tables to Parquet: Export-DuckDBToParquet
0.2.1 Changing the way to look for existing tables
0.2.0 Support of Linux
0.1.5 Fixing case sensitive path for private and public functions
0.1.4 Prefixing SimplySql commands
      Integration of ImportDependency module
0.1.3 Removing unnecessary Code
0.1.2 Throwing an exception now, when no transaction is used and the input is not valid
0.1.1 Fixed temporary module and script path loading
0.1.0 Improved the check for existing tables and columns. In this case the table will not be dropped the the SimplySQL update.
0.0.7 Bumped the copyright year to 2024
0.0.6 Fix of trimming when datatype is boolean or something else than String
0.0.5 Automatically trim values now, but there is a parameter to deactivate this behaviour
0.0.4 Adding support for Object[] and ArrayList to be converted into JSON, too
0.0.3 Fix for table existing check and prevent using more columns than needed (the leaded to overwriting columns that have default values like changedate)
0.0.2 Small fix for tables that are already existing, but empty
0.0.1 Initial release of SqlPipeline
'

    } # Ende der PSData-Hashtabelle

} # Ende der PrivateData-Hashtabelle

# HelpInfo-URI dieses Moduls
# HelpInfoURI = ''

# Standardpräfix für Befehle, die aus diesem Modul exportiert werden. Das Standardpräfix kann mit "Import-Module -Prefix" überschrieben werden.
# DefaultCommandPrefix = ''

}

