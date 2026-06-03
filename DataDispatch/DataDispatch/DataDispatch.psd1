
@{

RootModule        = 'DataDispatch.psm1'
ModuleVersion     = '0.0.1'
GUID              = 'bad0a73c-d4d7-4651-891e-28bd94beed4e'
Author            = 'florian.von.bracht@apteco.de'
CompanyName       = 'Apteco GmbH'
Copyright         = '(c) 2026 Apteco GmbH. All rights reserved.'
PowerShellVersion = '5.1'

Description = 'Apteco PS Modules - Webhook Data Dispatcher

Reads processed webhook events from SQL Server (dbo.WebhookEvents) and distributes
them to configurable targets: SQL Server tables, stored procedures, CSV, JSON, DuckDB.
Runs as a Windows Scheduled Task every N minutes.

Use Copy-DataDispatch to deploy the dispatcher files to a target directory,
then edit .env and endpoints/*.yaml before running setup-task.ps1 -Action install.

Requires PowerShell modules: WriteLog, SimplySql, powershell-yaml.
'

FunctionsToExport = @(
    'Copy-DataDispatch'
)

CmdletsToExport   = @()
VariablesToExport  = @()
AliasesToExport    = @()

PrivateData = @{
    PSData = @{
        Tags       = @('powershell', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Apteco', 'Webhook', 'Dispatcher', 'SQLServer')
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/DataDispatch'
        IconUri    = 'https://www.apteco.de/sites/default/files/favicon_3.ico'
        ReleaseNotes = '
0.0.1 Initial release
'
    }
}

}
