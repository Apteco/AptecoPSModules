# setup_notify.ps1 — einmalig ausführen
$ErrorActionPreference = 'Stop'

$workDir     = 'C:\FastStats\Scripts\node_webhook'
$keyFile     = Join-Path $workDir 'config\notify.key'
$secretsFile = Join-Path $workDir 'config\notify_secrets.json'

Import-Module EncryptCredential

# Config-Ordner sicherstellen
$cfgDir = Split-Path $keyFile -Parent
if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }

# Keyfile erzeugen (nur wenn noch nicht vorhanden — sonst werden alte Secrets unlesbar!)
if (-not (Test-Path $keyFile)) {
    New-Keyfile -Path $keyFile        # PRÜFEN: Parametername (-Path / -File)
    Write-Host "Keyfile erstellt: $keyFile" -ForegroundColor Green
} else {
    Write-Host "Keyfile existiert bereits — wird wiederverwendet." -ForegroundColor Yellow
}

Import-Keyfile -Path $keyFile         # PRÜFEN: Parametername

# Teams-Webhook-URL interaktiv abfragen und verschlüsseln
$teamsUri = Read-Host 'Teams-Webhook-URL eingeben'
$encrypted = Convert-PlaintextToSecure -String $teamsUri   # PRÜFEN: Parametername (-String)

# In Config schreiben
@{ TeamsWebhook = $encrypted } | ConvertTo-Json | Set-Content -Path $secretsFile -Encoding UTF8
Write-Host "Webhook verschluesselt gespeichert: $secretsFile" -ForegroundColor Green

Write-Host "`nNicht vergessen: Berechtigungen einschraenken (siehe icacls-Befehl)." -ForegroundColor Cyan