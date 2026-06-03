#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Scheduled Task für den Webhook Dispatcher einrichten oder entfernen.

.PARAMETER Action
    install   — Task anlegen (überschreibt bestehenden)
    uninstall — Task entfernen
    run       — Task einmalig sofort ausführen
    status    — Task-Status anzeigen

.PARAMETER IntervalMinutes
    Ausführungsintervall in Minuten. Default: 5

.PARAMETER RunAsUser
    Windows-Account unter dem der Task läuft.
    Default: SYSTEM (für Windows Auth zu SQL Server ggf. Domänen-Account nötig)

.EXAMPLE
    .\setup-task.ps1 -Action install
    .\setup-task.ps1 -Action install -IntervalMinutes 10 -RunAsUser "DOMAIN\SvcAccount"
    .\setup-task.ps1 -Action status
    .\setup-task.ps1 -Action uninstall
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('install', 'uninstall', 'run', 'status')]
    [string] $Action,

    [int]    $IntervalMinutes = 5,
    [string] $RunAsUser       = 'SYSTEM'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskName    = 'WebhookDispatcher'
$TaskPath    = '\Apteco\'
$ScriptDir   = $PSScriptRoot
$PwshExe     = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source ?? 'pwsh'
$DispatchScript = Join-Path $ScriptDir 'dispatch.ps1'

function Write-Step([string]$msg) { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }

switch ($Action) {

    'install' {
        Write-Step "Scheduled Task '$TaskName' einrichten"

        # Task-Ordner anlegen
        $scheduler = New-Object -ComObject Schedule.Service
        $scheduler.Connect()
        $rootFolder = $scheduler.GetFolder('\')
        try { $rootFolder.GetFolder('Apteco') | Out-Null }
        catch { $rootFolder.CreateFolder('Apteco') | Out-Null }

        # Aktion: pwsh -NonInteractive -File dispatch.ps1
        $action = New-ScheduledTaskAction `
            -Execute    $PwshExe `
            -Argument   "-NonInteractive -NoProfile -File `"$DispatchScript`"" `
            -WorkingDirectory $ScriptDir

        # Trigger: alle N Minuten, dauerhaft
        $trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -Once -At (Get-Date)

        # Einstellungen
        $settings = New-ScheduledTaskSettingsSet `
            -ExecutionTimeLimit     (New-TimeSpan -Hours 1) `
            -MultipleInstances      IgnoreNew `
            -RunOnlyIfNetworkAvailable `
            -StartWhenAvailable

        # Principal (Ausführungs-Account)
        if ($RunAsUser -eq 'SYSTEM') {
            $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        } else {
            $principal = New-ScheduledTaskPrincipal -UserId $RunAsUser -LogonType Password -RunLevel Highest
        }

        $taskDef = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

        # Passwort abfragen falls Domänen-Account
        if ($RunAsUser -ne 'SYSTEM') {
            $cred     = Get-Credential -UserName $RunAsUser -Message "Passwort für Scheduled Task Account"
            Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath `
                -InputObject $taskDef -User $RunAsUser -Password $cred.GetNetworkCredential().Password -Force | Out-Null
        } else {
            Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath `
                -InputObject $taskDef -Force | Out-Null
        }

        Write-Ok "Task '$TaskPath$TaskName' registriert"
        Write-Ok "Intervall: alle $IntervalMinutes Minuten"
        Write-Ok "Account:   $RunAsUser"
        Write-Warn "Hinweis: Bei Windows Auth zu SQL Server muss der Task-Account SQL Server Zugriff haben."
    }

    'uninstall' {
        Write-Step "Scheduled Task '$TaskName' entfernen"
        try {
            Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
            Write-Ok "Task entfernt"
        } catch {
            Write-Warn "Task nicht gefunden oder Fehler: $_"
        }
    }

    'run' {
        Write-Step "Task einmalig sofort ausführen"
        Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        Write-Ok "Task gestartet — Logs: $(Join-Path $ScriptDir 'logs')"
    }

    'status' {
        Write-Step "Task-Status"
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            $info = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath
            Write-Host "  Status:        $($task.State)" -ForegroundColor White
            Write-Host "  Letzter Run:   $($info.LastRunTime)" -ForegroundColor White
            Write-Host "  Letztes Ergebnis: $($info.LastTaskResult)" -ForegroundColor White
            Write-Host "  Nächster Run:  $($info.NextRunTime)" -ForegroundColor White
        } catch {
            Write-Warn "Task '$TaskName' nicht gefunden. Bitte zuerst: .\setup-task.ps1 -Action install"
        }
    }
}
