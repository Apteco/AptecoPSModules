# NodeWebhook

Node.js webhook receiver with Fastify 5, a SQLite queue, and a SQL Server worker.
Deployed and managed via a PowerShell module.

## Architecture

```
Internet
  → IIS (Port 80 / 443)
    → IIS ARR  (Reverse Proxy)
      → Node.js Fastify  (Port 3000, localhost only)
          POST /webhook/:endpoint/:key
            → SQLite Queue  (data/queue.db)
              ← Worker  (polls every 3 s)
                → SQL Server  dbo.WebhookEvents
```

## Quick Start (PowerShell module)

```powershell
# 1. Install the module
Install-Module NodeWebhook -Scope CurrentUser

# 2. Deploy application files to the target directory
Import-Module NodeWebhook
Copy-NodeWebhook -Destination 'C:\FastStats\Scripts\node_webhook'

# 3. Configure
cd C:\FastStats\Scripts\node_webhook
notepad .env             # SQL Server connection, port, log level
notepad endpoints.yaml   # endpoint names, URL keys, bearer tokens

# 4. Create SQL Server tables (once)
sqlcmd -S <server> -d <db> -i sql\create-tables.sql

# 5. Install (run as Administrator)
.\setup.ps1 -Action setup

# 6. Verify
.\setup.ps1 -Action status
```

## Development (auto-reload)

```powershell
npm install
npm run dev          # Receiver
npm run dev:worker   # Worker (separate terminal)
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/webhook/:endpoint/:key` | Receive payload and enqueue it |
| `GET`  | `/health` | Health check for IIS ARR |
| `GET`  | `/admin/queue-stats` | Queue status per endpoint |

The `:endpoint` segment identifies the logical webhook source (e.g. `brevo-marketing`).
The `:key` segment is a shared secret that must match the `key` field in `endpoints.yaml`.

## Endpoint Security

Each endpoint in `endpoints.yaml` can stack multiple security layers independently:

| Layer | Config field | Description |
|-------|-------------|-------------|
| URL key | `key` | Secret segment in the URL — always active |
| Bearer token | `bearerToken` | `Authorization: Bearer <token>` |
| API-key header | `apiKey` / `apiKeyHeader` | Arbitrary header, e.g. `x-api-key` |
| IP whitelist | `allowedIps` | List of allowed client IPs |

Example `endpoints.yaml`:

```yaml
endpoints:

  brevo-marketing:
    key: "url-secret-abc123"
    description: "Brevo marketing webhook"
    bearerToken: "my-bearer-token"

  github:
    key: "url-secret-xyz"
    apiKey: "my-api-key"
    apiKeyHeader: "x-hub-signature-256"
    allowedIps:
      - "192.30.252.0"
```

## IIS ARR Setup

1. Install ARR + URL Rewrite Module in IIS
2. Copy `web.config` to the IIS site directory
3. IIS Manager → Server → Application Request Routing Cache → Proxy Settings → **Enable proxy**
4. Register the Brevo webhook URL in Brevo:
   ```
   https://<server>/webhook/brevo-marketing/<url-key>
   Authorization: Bearer <bearerToken>
   ```

`setup.ps1 -Action setup` handles steps 2–4 automatically (creates the IIS virtual directory,
copies `web.config`, and registers `HTTP_X_FORWARDED_FOR` as an allowed server variable).

## setup.ps1 — Service Management

`setup.ps1` installs Node.js dependencies, configures IIS ARR, registers pm2 processes,
and creates a Scheduled Task for autostart on reboot.

```powershell
.\setup.ps1 -Action setup        # First-time install (run as Administrator)
.\setup.ps1 -Action start        # Start receiver + worker
.\setup.ps1 -Action stop         # Stop receiver + worker
.\setup.ps1 -Action restart      # Restart both processes
.\setup.ps1 -Action status       # pm2 process list + queue stats
.\setup.ps1 -Action logs         # Live logs (Ctrl+C to exit)
.\setup.ps1 -Action uninstall    # Remove pm2 processes and scheduled task
```

Optional parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-IisSiteName` | `Default Web Site` | IIS site name |
| `-IisWebRoot` | `C:\inetpub\wwwroot` | Physical path of the IIS site |
| `-AutostartUser` | current user | Windows account for the autostart scheduled task |

The autostart task runs `pm2 resurrect` at system startup — more reliable than the
pm2 registry/login hook because it runs without an interactive login.

## pm2_watchdog.ps1 — Process Health Monitor

An optional scheduled watchdog that checks pm2 process health every N minutes and
automatically restarts any crashed or missing app. Useful as a second safety net
alongside the pm2 autostart task.

**Configure the three variables at the top of the script before use:**

```powershell
$workDir       = 'C:\FastStats\Scripts\node_webhook'     # installation path
$nodeExe       = 'C:\Program Files\nodejs\node.exe'      # path to node.exe
$pm2Bin        = 'C:\Program Files\nodejs\node_modules\pm2\bin\pm2'  # path to pm2 bin
```

The watchdog:
1. Calls `pm2 jlist` to check if the daemon is reachable
2. If the daemon is down, starts all apps from `ecosystem.config.js`
3. Checks each expected app (`webhook-receiver`, `webhook-worker`) for `online` status
4. Restarts any app that is not `online`
5. Logs all actions via `WriteLog` to `logs\watchdog.log`

**Register as a Scheduled Task (example — every 5 minutes):**

```powershell
$script  = 'C:\FastStats\Scripts\node_webhook\pm2_watchdog.ps1'
$action  = New-ScheduledTaskAction -Execute 'pwsh' `
               -Argument "-NonInteractive -NoProfile -File `"$script`"" `
               -WorkingDirectory (Split-Path $script -Parent)
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) `
               -Once -At (Get-Date)
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
               -MultipleInstances IgnoreNew -StartWhenAvailable
Register-ScheduledTask -TaskName 'PM2-Watchdog-NodeWebhook' -TaskPath '\Apteco\' `
    -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
```

Requires the `WriteLog` PowerShell module (`Install-Module WriteLog -Scope CurrentUser`).

## setup_notify.ps1 — Teams Notifications (optional)

Encrypts a Microsoft Teams webhook URL and stores it in a local config file so the watchdog
can send alerts. Uses the `EncryptCredential` module.

Run once, interactively:

```powershell
.\setup_notify.ps1
# Prompts for the Teams webhook URL, encrypts it, and saves it to config\notify_secrets.json
```

Requires `EncryptCredential` (`Install-Module EncryptCredential -Scope CurrentUser`).

## SQL Server Tables

Run once to create `dbo.WebhookEvents`, `dbo.GithubEvents`, and `dbo.ShopifyEvents`:

```powershell
sqlcmd -S <server> -d <db> -i sql\create-tables.sql
```

Custom endpoint routing is configured in `src/handlers.js`. Unknown endpoints fall back to
`dbo.WebhookEvents`.

## .env Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Node.js port |
| `HOST` | `127.0.0.1` | Listen address (localhost only — ARR handles TLS) |
| `SQLITE_PATH` | `./data/queue.db` | SQLite queue path |
| `ENDPOINTS_YAML` | `./endpoints.yaml` | Endpoint configuration file |
| `LOG_LEVEL` | `info` | `trace` / `debug` / `info` / `warn` / `error` |
| `WORKER_POLL_MS` | `3000` | Worker poll interval in ms |
| `WORKER_BATCH` | `10` | Entries processed per poll cycle |
| `WORKER_MAX_ATTEMPTS` | `3` | Max retries before `status=failed` |
| `SQLSERVER_HOST` | — | SQL Server hostname |
| `SQLSERVER_DB` | — | Database name |
| `SQLSERVER_WINDOWS_AUTH` | `false` | `true` to use Windows Authentication |
| `SQLSERVER_USER` | — | SQL login (without Windows Auth) |
| `SQLSERVER_PASS` | — | Password (without Windows Auth) |
| `SQLSERVER_PORT` | `1433` | SQL Server port |
| `SQLSERVER_ENCRYPT` | `true` | Encrypt connection |
| `SQLSERVER_TRUST_CERT` | `false` | Trust server certificate |

## File Structure

```
NodeWebhook\
├── NodeWebhook\                    ← PowerShell module
│   ├── NodeWebhook.psd1
│   ├── NodeWebhook.psm1
│   ├── Public\
│   │   └── Copy-NodeWebhook.ps1   ← deploys app files to a target directory
│   ├── src\
│   │   ├── server.js              ← Fastify HTTP server
│   │   ├── worker.js              ← SQLite queue → SQL Server
│   │   ├── handlers.js            ← per-endpoint SQL Server routing
│   │   ├── db.js                  ← SQLite queue helpers
│   │   ├── sqlserver.js           ← SQL Server connection pool
│   │   └── config.js              ← endpoints.yaml loader
│   ├── sql\
│   │   └── create-tables.sql      ← SQL Server DDL
│   ├── .env.example
│   ├── endpoints.yaml             ← endpoint config template
│   ├── ecosystem.config.js        ← pm2 process definitions
│   ├── web.config                 ← IIS ARR reverse proxy rules
│   ├── setup.ps1                  ← install / start / stop / status / uninstall
│   ├── pm2_watchdog.ps1           ← optional watchdog scheduled task
│   └── setup_notify.ps1          ← optional Teams alert setup
├── README.md
└── publish.ps1
```
