# pm2_watchdog.ps1
$ErrorActionPreference = 'Stop'

# ── Konfiguration ──────────────────────────────────────────────
$workDir       = 'C:\FastStats\Scripts\node_webhook'
$logFile       = Join-Path $workDir 'logs\watchdog.log'
$pm2Home       = Join-Path $workDir '.pm2'
$nodeExe       = 'C:\Program Files\nodejs\node.exe'
$pm2Bin        = 'C:\Program Files\nodejs\node_modules\pm2\bin\pm2'   # ggf. anpassen
$ecosystemFile = Join-Path $workDir 'ecosystem.config.cjs'
$expectedApps  = @('webhook-receiver','webhook-worker')

# ── Vorbereitung ───────────────────────────────────────────────
$env:PM2_HOME = $pm2Home

Import-Module WriteLog
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
Set-Logfile -Path $logFile

# ── PM2-Helfer ─────────────────────────────────────────────────
function Invoke-Pm2 {
    param([string[]]$Arguments)
    # Stdout und Stderr getrennt erfassen damit Fehler nicht verschluckt werden
    $output = & $nodeExe $pm2Bin @Arguments 2>&1
    $text   = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    return @{
        Text     = $text
        ExitCode = $LASTEXITCODE
    }
}

function Get-Pm2Procs {
    $result = Invoke-Pm2 @('jlist')
    $raw = $result.Text
    $i = $raw.IndexOf('[')
    if ($i -lt 0) { return $null }            # Daemon nicht erreichbar
    try { return ($raw.Substring($i) | ConvertFrom-Json -AsHashtable) }
    catch {
        Write-Log -Message "Get-Pm2Procs: JSON-Parse fehlgeschlagen. Raw-Output: $raw" -Severity ERROR
        return $null
    }
}

function Test-EcosystemFile {
    # Prüft VOR dem Start, ob die ecosystem-Datei syntaktisch ladbar ist
    # und ob die referenzierten script-Pfade tatsächlich existieren.
    if (-not (Test-Path $ecosystemFile)) {
        Write-Log -Message "Ecosystem-Datei nicht gefunden: $ecosystemFile" -Severity ERROR
        return $false
    }

    $nodeCheck = & $nodeExe -e "try { const cfg = require('$($ecosystemFile.Replace('\','\\'))'); console.log(JSON.stringify(cfg.apps.map(a => ({name:a.name, script:a.script})))); } catch(e) { console.error('PARSE_ERROR:' + e.message); process.exit(1); }" 2>&1
    $nodeExitCode = $LASTEXITCODE

    if ($nodeExitCode -ne 0 -or $nodeCheck -match '^PARSE_ERROR:') {
        Write-Log -Message "Ecosystem-Datei kann nicht geladen werden: $nodeCheck" -Severity ERROR
        return $false
    }

    try {
        $apps = $nodeCheck | ConvertFrom-Json
        $allOk = $true
        foreach ($app in $apps) {
            if (-not (Test-Path $app.script)) {
                Write-Log -Message "Script-Pfad existiert nicht für App '$($app.name)': $($app.script)" -Severity ERROR
                $allOk = $false
            }
        }
        return $allOk
    } catch {
        Write-Log -Message "Konnte App-Liste aus ecosystem.config.js nicht parsen: $_" -Severity ERROR
        return $false
    }
}

function Start-Pm2Apps {
    param(
        [string]$OnlyApp = $null   # Falls gesetzt: nur DIESE eine App (re)starten,
                                   # nicht die komplette ecosystem-Datei.
                                   # Wichtig, damit eine kurzzeitig "fehlende" App
                                   # nicht versehentlich einen Neustart der bereits
                                   # gesunden Apps auslöst (kann laufende DB-Connections
                                   # / vorbereitete SQLite-Statements invalidieren).
    )

    if (-not (Test-EcosystemFile)) {
        Write-Log -Message "Ecosystem-Datei-Validierung fehlgeschlagen — Start wird trotzdem versucht, Ergebnis wird geprüft." -Severity ERROR
    }

    if ($OnlyApp) {
        Write-Log -Message "Starte gezielt NUR '$OnlyApp' aus $ecosystemFile (andere Apps bleiben unberührt)." -Severity WARNING
        $result = Invoke-Pm2 @('start', $ecosystemFile, '--only', $OnlyApp)
    } else {
        Write-Log -Message "Starte ALLE Apps aus $ecosystemFile (Daemon war nicht erreichbar)." -Severity WARNING
        $result = Invoke-Pm2 @('start', $ecosystemFile)
    }

    if ($result.ExitCode -ne 0) {
        Write-Log -Message "pm2 start fehlgeschlagen (ExitCode=$($result.ExitCode)). Output: $($result.Text)" -Severity ERROR
    } else {
        Write-Log -Message "pm2 start Output: $($result.Text)" -Severity INFO
    }
    Start-Sleep -Seconds 3
}

# ── 1. Daemon-Check (z.B. nach Reboot) ─────────────────────────
$procs = Get-Pm2Procs
$didStart = $false

if ($null -eq $procs) {
    Write-Log -Message 'PM2-Daemon nicht erreichbar — starte Apps neu.' -Severity WARNING
    Start-Pm2Apps
    $didStart = $true
    $procs = Get-Pm2Procs
}

# ── 2. App-Status prüfen ───────────────────────────────────────
$problems = @()

foreach ($name in $expectedApps) {
    $p = $procs | Where-Object { $_.name -eq $name }

    if (-not $p) {
        $problems += "$name fehlt"
        Write-Log -Message "$name fehlt in PM2 — starte gezielt nur diese App." -Severity WARNING
        Start-Pm2Apps -OnlyApp $name
        $procs = Get-Pm2Procs
    }
    elseif ($p.pm2_env.status -ne 'online') {
        $problems += "$name ist $($p.pm2_env.status)"
        Write-Log -Message "$name ist '$($p.pm2_env.status)' — restart." -Severity WARNING
        $restartResult = Invoke-Pm2 @('restart', $name)
        if ($restartResult.ExitCode -ne 0) {
            Write-Log -Message "pm2 restart $name fehlgeschlagen: $($restartResult.Text)" -Severity ERROR
        }
    }
}

# ── 3. Ergebnis loggen ─────────────────────────────────────────
if ($problems.Count -eq 0 -and -not $didStart) {
    Write-Log -Message "OK — alle Apps online: $($expectedApps -join ', ')." -Severity VERBOSE
} else {
    Start-Sleep -Seconds 2
    $final = Get-Pm2Procs
    $states = foreach ($name in $expectedApps) {
        $p = $final | Where-Object { $_.name -eq $name }
        if ($p) { "$name=$($p.pm2_env.status)" } else { "$name=fehlt" }
    }
    Write-Log -Message "Nach Reparatur: $($states -join ', ')." -Severity INFO

    # Wenn nach allen Reparaturversuchen immer noch Apps fehlen,
    # nochmal explizit die letzten pm2-Logs der App ausgeben (falls vorhanden)
    foreach ($name in $expectedApps) {
        $p = $final | Where-Object { $_.name -eq $name }
        if (-not $p) {
            $logsResult = Invoke-Pm2 @('logs', $name, '--lines', '20', '--nostream')
            Write-Log -Message "Letzte pm2-Logs für '$name' (falls vorhanden): $($logsResult.Text)" -Severity ERROR
        }
    }
}