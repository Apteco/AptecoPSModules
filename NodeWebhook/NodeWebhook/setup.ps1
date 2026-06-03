#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Webhook Receiver — Setup & Dienst-Verwaltung via pm2

.DESCRIPTION
    Installiert Node.js-Abhängigkeiten, richtet pm2 als Windows-Dienst ein,
    erstellt den IIS-Unterordner "webhook" und konfiguriert ARR/URL Rewrite.
    PM2_HOME wird auf das App-Verzeichnis gesetzt damit alle pm2-Daten
    zusammen mit dem Projekt liegen.
    Autostart via Scheduled Task (AtStartup) — zuverlässiger als Registry-Login-Hook.

.PARAMETER Action
    setup       — Erstinstallation (npm install, pm2, IIS webhook-Ordner einrichten)
    start       — Receiver + Worker starten
    stop        — Receiver + Worker stoppen
    restart     — Beide Prozesse neu starten
    status      — Aktuellen Status anzeigen
    logs        — Live-Logs anzeigen (Ctrl+C zum Beenden)
    uninstall   — pm2-Dienst und alle Prozesse entfernen

.PARAMETER IisSiteName
    Name der IIS-Website in der der webhook-Unterordner erstellt wird.
    Default: "Default Web Site"

.PARAMETER IisWebRoot
    Physischer Pfad der IIS-Website.
    Default: C:\inetpub\wwwroot

.PARAMETER AutostartUser
    Windows-Account unter dem der pm2-Autostart-Task läuft.
    Muss SQL Server Zugriff haben wenn Windows Auth verwendet wird.
    Default: aktuell eingeloggter User

.EXAMPLE
    .\setup.ps1 -Action setup
    .\setup.ps1 -Action setup -AutostartUser "DOMAIN\SvcAccount"
    .\setup.ps1 -Action setup -IisSiteName "MeineSeite" -IisWebRoot "D:\wwwroot"
	pm2 save   # aktuellen Stand als Dump speichern
	.\setup.ps1 -Action setup -AutostartUser "aptservice"
    .\setup.ps1 -Action start
    .\setup.ps1 -Action status
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('setup', 'start', 'stop', 'restart', 'status', 'logs', 'uninstall')]
    [string] $Action,

    [string] $IisSiteName    = 'Default Web Site',
    [string] $IisWebRoot     = 'C:\inetpub\wwwroot',
    [string] $AutostartUser  = $env:USERNAME
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
$AppDir       = $PSScriptRoot
$ReceiverName = 'webhook-receiver'
$WorkerName   = 'webhook-worker'
$NodeExe      = 'node'
$Pm2Exe       = 'pm2'
$WebhookDir   = Join-Path $IisWebRoot 'webhook'
$Pm2Home      = Join-Path $AppDir '.pm2'
$TaskName     = 'PM2-Autostart-WebhookReceiver'
$TaskPath     = '\Apteco\'

# PM2_HOME für die aktuelle Session setzen
$env:PM2_HOME = $Pm2Home

# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------
function Write-Step([string]$msg) {
    Write-Host "`n▶ $msg" -ForegroundColor Cyan
}

function Write-Ok([string]$msg) {
    Write-Host "  ✓ $msg" -ForegroundColor Green
}

function Write-Warn([string]$msg) {
    Write-Host "  ! $msg" -ForegroundColor Yellow
}

function Assert-Command([string]$cmd) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "Befehl '$cmd' nicht gefunden. Bitte installieren und PATH prüfen."
    }
}

function Invoke-Pm2([string[]]$pmArgs) {
    & $Pm2Exe @pmArgs
    if ($LASTEXITCODE -ne 0) {
        throw "pm2 beendete mit Exit-Code $LASTEXITCODE"
    }
}

# ------------------------------------------------------------
# PM2_HOME dauerhaft als Systemvariable setzen
# ------------------------------------------------------------
function Set-Pm2HomeEnv {
    Write-Step "PM2_HOME als Systemvariable setzen"
    $current = [System.Environment]::GetEnvironmentVariable('PM2_HOME', 'Machine')
    if ($current -ne $Pm2Home) {
        [System.Environment]::SetEnvironmentVariable('PM2_HOME', $Pm2Home, 'Machine')
        Write-Ok "PM2_HOME = $Pm2Home"
    } else {
        Write-Ok "PM2_HOME bereits korrekt: $Pm2Home"
    }
}

# ------------------------------------------------------------
# Autostart via Scheduled Task (AtStartup + pm2 resurrect)
# Zuverlässiger als pm2-windows-startup (Registry/Login-Hook),
# da der Task auch ohne interaktiven Login beim Systemstart läuft.
# ------------------------------------------------------------
function Install-AutostartTask {
    Write-Step "Autostart Scheduled Task einrichten (Account: $AutostartUser)"

    # Task-Ordner anlegen
    $scheduler = New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    $rootFolder = $scheduler.GetFolder('\')
    try   { $rootFolder.GetFolder('Apteco') | Out-Null }
    catch { $rootFolder.CreateFolder('Apteco') | Out-Null }

    $pm2Path = (Get-Command $Pm2Exe -ErrorAction Stop).Source

    # Aktion: pm2 resurrect — lädt gespeicherten Prozess-Dump
    $action = New-ScheduledTaskAction `
        -Execute          $pm2Path `
        -Argument         'resurrect' `
        -WorkingDirectory $AppDir

    # Trigger: beim Systemstart
    $trigger = New-ScheduledTaskTrigger -AtStartup

    # Einstellungen
    $settings = New-ScheduledTaskSettingsSet `
        -ExecutionTimeLimit  (New-TimeSpan -Minutes 2) `
        -RestartCount        3 `
        -RestartInterval     (New-TimeSpan -Minutes 1) `
        -MultipleInstances   IgnoreNew `
        -StartWhenAvailable

    # Passwort abfragen
    $cred = Get-Credential -UserName $AutostartUser `
        -Message "Passwort für Scheduled Task Account '$AutostartUser'"

    $principal = New-ScheduledTaskPrincipal `
        -UserId    $AutostartUser `
        -LogonType Password `
        -RunLevel  Highest

    Register-ScheduledTask `
        -TaskName    $TaskName `
        -TaskPath    $TaskPath `
        -Action      $action `
        -Trigger     $trigger `
        -Settings    $settings `
        -Principal   $principal `
        -Password    $cred.GetNetworkCredential().Password `
        -Force | Out-Null

    Write-Ok "Task '$TaskPath$TaskName' registriert"
    Write-Ok "Läuft als: $AutostartUser"
    Write-Ok "Trigger:   AtStartup → pm2 resurrect"
    Write-Warn "Hinweis: Account muss SQL Server Zugriff haben wenn Windows Auth aktiv ist."
}

function Remove-AutostartTask {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false -ErrorAction Stop
        Write-Ok "Autostart Task '$TaskName' entfernt"
    } catch {
        Write-Warn "Task nicht gefunden oder Fehler beim Entfernen: $_"
    }
}

# ------------------------------------------------------------
# IIS webhook-Verzeichnis und web.config einrichten
# ------------------------------------------------------------
function Install-IisWebhook {
    Write-Step 'IIS: WebAdministration Modul laden'
    Import-Module WebAdministration -ErrorAction Stop
    Write-Ok 'WebAdministration geladen'

    Write-Step "IIS: Unterverzeichnis '$WebhookDir' anlegen"
    if (-not (Test-Path $WebhookDir)) {
        New-Item -ItemType Directory -Path $WebhookDir | Out-Null
        Write-Ok "Verzeichnis erstellt: $WebhookDir"
    } else {
        Write-Ok "Verzeichnis existiert bereits: $WebhookDir"
    }

    Write-Step 'IIS: web.config in webhook-Verzeichnis kopieren'
    $srcConfig = Join-Path $AppDir 'web.config'
    $dstConfig = Join-Path $WebhookDir 'web.config'
    Copy-Item -Path $srcConfig -Destination $dstConfig -Force
    Write-Ok "web.config kopiert nach $dstConfig"

    Write-Step "IIS: Virtual Directory 'webhook' unter '$IisSiteName' einrichten"
    $vdPath = "IIS:\Sites\$IisSiteName\webhook"
    if (-not (Test-Path $vdPath)) {
        New-WebVirtualDirectory -Site $IisSiteName -Name 'webhook' -PhysicalPath $WebhookDir | Out-Null
        Write-Ok "Virtual Directory 'webhook' erstellt"
    } else {
        Write-Ok "Virtual Directory 'webhook' existiert bereits"
    }

    Write-Step 'IIS: HTTP_X_FORWARDED_FOR als allowed Server Variable registrieren'
    $filterPath = 'system.webServer/rewrite/allowedServerVariables'
    $existing = Get-WebConfigurationProperty `
        -PSPath 'MACHINE/WEBROOT/APPHOST' `
        -Filter $filterPath `
        -Name '.' `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.name -eq 'HTTP_X_FORWARDED_FOR' }

    if (-not $existing) {
        Add-WebConfigurationProperty `
            -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter $filterPath `
            -Name '.' `
            -Value @{ name = 'HTTP_X_FORWARDED_FOR' }
        Write-Ok 'HTTP_X_FORWARDED_FOR registriert'
    } else {
        Write-Ok 'HTTP_X_FORWARDED_FOR bereits registriert'
    }
}

# ------------------------------------------------------------
# Actions
# ------------------------------------------------------------
switch ($Action) {

    'setup' {
        # --- Node.js Version prüfen ---
        Write-Step 'Voraussetzungen prüfen'
        Assert-Command $NodeExe
        $nodeVersion = & $NodeExe --version
        $verMatch = $nodeVersion -match 'v(\d+)\.(\d+)'
        if ($verMatch) {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -lt 22 -or ($major -eq 22 -and $minor -lt 5)) {
                throw "Node.js $nodeVersion zu alt. Bitte Node.js 22.5 oder neuer installieren (https://nodejs.org)."
            }
        }
        Write-Ok "Node.js $nodeVersion"

        # --- PM2_HOME dauerhaft setzen ---
        Set-Pm2HomeEnv

        # --- npm install ---
        Write-Step 'npm install'
        Push-Location $AppDir
        npm install --omit=dev
        if ($LASTEXITCODE -ne 0) { throw 'npm install fehlgeschlagen' }
        Write-Ok 'Abhängigkeiten installiert'
        Pop-Location

        # --- .env prüfen ---
        Write-Step '.env prüfen'
        $envPath = Join-Path $AppDir '.env'
        if (-not (Test-Path $envPath)) {
            Copy-Item (Join-Path $AppDir '.env.example') $envPath
            Write-Warn '.env aus .env.example erstellt — bitte Werte eintragen!'
        } else {
            Write-Ok '.env vorhanden'
        }

        # --- pm2 installieren ---
        Write-Step 'pm2 global installieren'
        $pm2Version = & npm list -g pm2 --depth=0 2>$null
        if ($pm2Version -notmatch 'pm2@') {
            npm install -g pm2
            if ($LASTEXITCODE -ne 0) { throw 'pm2 Installation fehlgeschlagen' }
            Write-Ok 'pm2 installiert'
        } else {
            Write-Ok "pm2 bereits vorhanden ($($pm2Version.Trim()))"
        }

        # --- IIS einrichten ---
        Install-IisWebhook

        # --- pm2 Prozesse registrieren ---
        Write-Step 'Prozesse in pm2 registrieren'
        Push-Location $AppDir

        $receiverScript = Join-Path $AppDir 'src\server.js'
        $workerScript   = Join-Path $AppDir 'src\worker.js'

        # Alte Einträge entfernen falls vorhanden
        & $Pm2Exe delete $ReceiverName 2>$null
        & $Pm2Exe delete $WorkerName   2>$null

        Invoke-Pm2 @('start', $receiverScript,
            '--name', $ReceiverName,
            '--interpreter', $NodeExe
        )
        Invoke-Pm2 @('start', $workerScript,
            '--name', $WorkerName,
            '--interpreter', $NodeExe
        )

        # Dump speichern (wird von "pm2 resurrect" beim Autostart geladen)
        Invoke-Pm2 @('save')
        Write-Ok 'pm2 Prozess-Dump gespeichert'

        Pop-Location

        # --- Autostart Scheduled Task einrichten ---
        Install-AutostartTask

        Write-Host ''
        Write-Ok 'Setup abgeschlossen!'
        Write-Host ''
        Write-Host '  Nächste Schritte:' -ForegroundColor White
        Write-Host "  1. .env anpassen:       notepad $AppDir\.env" -ForegroundColor White
        Write-Host "  2. endpoints.yaml:      notepad $AppDir\endpoints.yaml" -ForegroundColor White
        Write-Host '  3. Neu starten:         .\setup.ps1 -Action restart' -ForegroundColor White
        Write-Host "  4. pm2-Daten liegen in: $Pm2Home" -ForegroundColor White
        Write-Host "  5. Autostart Task:      $TaskPath$TaskName" -ForegroundColor White
    }

    'start' {
        Write-Step "Starte $ReceiverName und $WorkerName"
        Push-Location $AppDir
        Invoke-Pm2 @('start', $ReceiverName)
        Invoke-Pm2 @('start', $WorkerName)
        Invoke-Pm2 @('save')
        Pop-Location
        Write-Ok 'Gestartet'
        & $Pm2Exe list
    }

    'stop' {
        Write-Step "Stoppe $ReceiverName und $WorkerName"
        Invoke-Pm2 @('stop', $ReceiverName)
        Invoke-Pm2 @('stop', $WorkerName)
        Invoke-Pm2 @('save')
        Write-Ok 'Gestoppt'
    }

    'restart' {
        Write-Step "Starte neu: $ReceiverName und $WorkerName"
        Invoke-Pm2 @('restart', $ReceiverName)
        Invoke-Pm2 @('restart', $WorkerName)
        Write-Ok 'Neustart abgeschlossen'
        & $Pm2Exe list
    }

    'status' {
        Write-Step 'pm2 Prozessliste'
        & $Pm2Exe list
        Write-Step 'Autostart Task Status'
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop
            $info = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath
            Write-Host "  Task State:    $($task.State)" -ForegroundColor White
            Write-Host "  Letzter Run:   $($info.LastRunTime)" -ForegroundColor White
            Write-Host "  Letztes Ergebnis: 0x$($info.LastTaskResult.ToString('X'))" -ForegroundColor White
            Write-Host "  Nächster Run:  $($info.NextRunTime)" -ForegroundColor White
        } catch {
            Write-Warn "Autostart Task nicht gefunden — setup ausführen?"
        }
        Write-Step 'Queue-Statistik (HTTP)'
        try {
            $port = 3000
            $envFile = Join-Path $AppDir '.env'
            if (Test-Path $envFile) {
                $portLine = Select-String -Path $envFile -Pattern '^PORT=(\d+)'
                if ($portLine) { $port = [int]$portLine.Matches[0].Groups[1].Value }
            }
            $stats = Invoke-RestMethod "http://127.0.0.1:$port/admin/queue-stats" -TimeoutSec 3
            $stats.stats | ConvertTo-Json -Depth 3
        } catch {
            Write-Warn "Queue-Stats nicht erreichbar (Receiver läuft?): $_"
        }
    }

    'logs' {
        Write-Step "Live-Logs ($ReceiverName + $WorkerName) — Ctrl+C zum Beenden"
        & $Pm2Exe logs $ReceiverName $WorkerName --lines 50
    }

    'uninstall' {
        Write-Step 'pm2 Prozesse entfernen'
        & $Pm2Exe delete $ReceiverName 2>$null
        & $Pm2Exe delete $WorkerName   2>$null
        & $Pm2Exe save --force 2>$null

        Write-Step 'Autostart Task entfernen'
        Remove-AutostartTask

        Write-Step 'PM2_HOME Systemvariable entfernen'
        [System.Environment]::SetEnvironmentVariable('PM2_HOME', $null, 'Machine')
        Write-Ok 'PM2_HOME entfernt'

        Write-Step 'IIS Virtual Directory entfernen'
        try {
            Import-Module WebAdministration -ErrorAction Stop
            $vdPath = "IIS:\Sites\$IisSiteName\webhook"
            if (Test-Path $vdPath) {
                Remove-Item $vdPath -Recurse -Force
                Write-Ok "Virtual Directory 'webhook' entfernt"
            } else {
                Write-Ok "Virtual Directory 'webhook' nicht gefunden — übersprungen"
            }
        } catch {
            Write-Warn "IIS-Cleanup fehlgeschlagen: $_"
        }

        Write-Ok 'Deinstallation abgeschlossen'
        Write-Warn "Node-Module, .env, .pm2-Ordner und DB bleiben erhalten."
        Write-Warn "Manuell löschen falls gewünscht: $AppDir\.pm2"
    }
}