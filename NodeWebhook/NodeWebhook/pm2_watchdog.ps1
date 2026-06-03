# pm2_watchdog.ps1
$ErrorActionPreference = 'Stop'

# ── Konfiguration ──────────────────────────────────────────────
$workDir       = 'C:\FastStats\Scripts\node_webhook'
$logFile       = Join-Path $workDir 'logs\watchdog.log'
$pm2Home       = Join-Path $workDir '.pm2'
$nodeExe       = 'C:\Program Files\nodejs\node.exe'
$pm2Bin        = 'C:\Program Files\nodejs\node_modules\pm2\bin\pm2'   # ggf. anpassen
$ecosystemFile = Join-Path $workDir 'ecosystem.config.js'
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
    return (& $nodeExe $pm2Bin @Arguments 2>&1) -join "`n"
}

function Get-Pm2Procs {
    $raw = Invoke-Pm2 @('jlist')
    $i = $raw.IndexOf('[')
    if ($i -lt 0) { return $null }            # Daemon nicht erreichbar
    try { return ($raw.Substring($i) | ConvertFrom-Json -AsHashtable) }
    catch { return $null }
}

function Start-Pm2Apps {
    # startet alle Apps deterministisch aus der ecosystem-Datei
    Write-Log -Message "Starte Apps aus $ecosystemFile." -Severity WARNING
    Invoke-Pm2 @('start', $ecosystemFile) | Out-Null
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
        if (-not $didStart) {
            Write-Log -Message "$name fehlt in PM2 — starte aus ecosystem." -Severity WARNING
            Start-Pm2Apps
            $didStart = $true
            $procs = Get-Pm2Procs
        }
    }
    elseif ($p.pm2_env.status -ne 'online') {
        $problems += "$name ist $($p.pm2_env.status)"
        Write-Log -Message "$name ist '$($p.pm2_env.status)' — restart." -Severity WARNING
        Invoke-Pm2 @('restart', $name) | Out-Null
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
}