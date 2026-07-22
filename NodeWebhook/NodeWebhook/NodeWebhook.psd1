
@{

RootModule        = 'NodeWebhook.psm1'
ModuleVersion     = '0.0.2'
GUID              = 'cb1e6ffe-efe3-4ce9-97cb-ab4696b0c938'
Author            = 'florian.von.bracht@apteco.de'
CompanyName       = 'Apteco GmbH'
Copyright         = '(c) 2026 Apteco GmbH. All rights reserved.'
PowerShellVersion = '5.1'

Description = 'Apteco PS Modules - Node.js Webhook Receiver

A Fastify-based Node.js webhook receiver with a SQLite queue and a SQL Server worker.
Use Copy-NodeWebhook to deploy the application files to a target directory,
then run setup.ps1 to install pm2, configure IIS ARR, and register the autostart task.

Requires Node.js >= 22.5.0 and npm on the target machine.
'

FunctionsToExport = @(
    'Copy-NodeWebhook'
)

CmdletsToExport   = @()
VariablesToExport  = @()
AliasesToExport    = @()

PrivateData = @{
    PSData = @{
        Tags       = @('powershell', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Apteco', 'Webhook', 'Node', 'nodejs')
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/NodeWebhook'
        IconUri    = 'https://www.apteco.de/sites/default/files/favicon_3.ico'
        ReleaseNotes = '
0.0.2 Allowing larger payloads to receive
0.0.1 Initial release
'
    }
}

}
