
# Apteco PS Modules - PowerShell security encryption module

Execute commands like

```PowerShell
"Hello World" | Convert-PlaintextToSecure
```

to get a string like

```
76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=
```

This string can be decrypted by calling

```PowerShell
"76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=" | Convert-SecureToPlaintext
```

and get back

```
Hello World
```


You better save the strings into variables ;-)

This module is used to double encrypt sensitive data like credentials, tokens etc. They cannot be stolen pretty easily as it uses SecureStrings.

At the first encryption or when calling `Export-Keyfile` a new random keyfile will be generated for salting with AES.
The key ist saved per default in your users profile, but can be exported into any other folder and use it from there.

> **Important**: Encrypted strings are bound to the **machine they were created on** and the **OS user account that created them**. They cannot be decrypted on a different machine or by a different user, even if the keyfile is available. See [Machine and User Binding](#machine-and-user-binding) below for how this works.

If you don't provide a keyfile, it will be automatically generated with your first call of `Convert-PlaintextToSecure`

You can use `Import-Keyfile` to use a keyfile that has been exported before.


# Machine and User Binding

The approach differs by platform.

## Windows — DPAPI (Data Protection API)

On Windows the keyfile is written to disk as a **DPAPI-protected blob** (`CurrentUser` scope).
DPAPI is a Windows OS service that encrypts data using key material derived from the user's
login credentials, managed by LSASS and optionally backed by the machine's TPM.

When the module needs the AES key it calls `ProtectedData.Unprotect()`, which only succeeds
for the **same user on the same machine**. There is no way to bypass this by knowing
the user SID or machine GUID — you need the user's actual Windows credentials.
An attacker who steals the keyfile file cannot unprotect it on a different machine or account.

## Linux / macOS — HMAC-SHA256 binding

DPAPI is not available on Linux. Instead the AES key is derived as:

```
AES key = HMAC-SHA256( key  = keyfile bytes          ← the secret you must possess
                       data = machine_id | user | uid ← read from the OS at runtime )
```

| Value | Source |
|-------|--------|
| `machine_id` | `/etc/machine-id` (set once at OS install) |
| `user` | `$env:UserName` |
| `uid` | numeric user ID from `id -u` |

All three are read from the OS at runtime. There is no parameter a caller can supply
to override them.

> **Limitation**: unlike DPAPI, these binding values are not themselves secret —
> they can be looked up on the machine. The HMAC binding raises the bar against
> opportunistic cross-machine/cross-user keyfile theft, but a targeted attacker
> who has both the keyfile and knowledge of the machine-id + UID could reconstruct
> the key. File permissions (`chmod 600`) are therefore still the primary defence on Linux.

## What this means in practice

- Copying the encrypted string to another machine → decryption fails
- Copying the keyfile to another machine → decryption fails (DPAPI / different machine-id)
- Running as a different user account → decryption fails (DPAPI / different UID)
- Changing the service account → must re-encrypt all credentials

## Scheduled tasks and services

A scheduled task or service **must run as the same OS user account that encrypted the credentials**.
See [Using with Scheduled Tasks or Windows Services](#using-with-scheduled-tasks-or-windows-services) for setup options.


# Keyfile Security

When a keyfile is first created, the module automatically restricts file system access:

- **Windows**: inherited ACEs are removed; only the current user is granted `FullControl`
- **Linux/macOS**: file permissions are set to `600` (owner read/write only)

You can verify and manually tighten permissions at any time:

**Windows**

```PowerShell
# Verify current ACL
Get-Acl -Path "$env:LOCALAPPDATA\AptecoPSModules\key.aes" | Format-List

# Lock down to current user only (removes all inherited rules)
$keyPath = "$env:LOCALAPPDATA\AptecoPSModules\key.aes"
$acl = Get-Acl -Path $keyPath
$acl.SetAccessRuleProtection($true, $false)   # disable inheritance, discard inherited rules
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
    "FullControl",
    [System.Security.AccessControl.AccessControlType]::Allow
)
$acl.SetAccessRule($rule)
Set-Acl -Path $keyPath -AclObject $acl
```

**Linux / macOS**

```bash
# Verify permissions (should show -rw-------)
ls -la ~/.local/share/AptecoPSModules/key.aes

# Restrict to owner only if needed
chmod 600 ~/.local/share/AptecoPSModules/key.aes
```


# Using with Scheduled Tasks or Windows Services

On Windows, DPAPI requires the **user profile to be loaded** when the task runs.
Configure the scheduled task with `LogonType = Password` (not `S4U`), which ensures
the profile is loaded. `S4U` logon may skip profile loading and cause DPAPI to fail.

```PowerShell
# Correct: Password logon loads the user profile
$principal = New-ScheduledTaskPrincipal -UserId "DOMAIN\svc_myservice" -LogonType Password

# Avoid: S4U may not load the profile, causing DPAPI decryption to fail
# $principal = New-ScheduledTaskPrincipal -UserId "DOMAIN\svc_myservice" -LogonType S4U
```

> **Domain environments**: if an administrator resets a service account password **without
> knowing the old password** (a forced reset), Windows cannot re-protect the DPAPI master
> key and it may become permanently inaccessible. Always change service account passwords
> via a normal password change, or use a **Group Managed Service Account (gMSA)** which
> handles rotation automatically without this risk.

## Option 1 — Run as the same user (simplest)

Configure the scheduled task to run as the user who originally encrypted the credentials. The default keyfile at `%LOCALAPPDATA%\AptecoPSModules\key.aes` will be picked up automatically.

## Option 2 — Dedicated service account, profile keyfile

1. Log in as the service account (or use `runas`) and encrypt the credentials once:

```PowerShell
Import-Module EncryptCredential
$encrypted = "MyPassword" | Convert-PlaintextToSecure
# Store $encrypted in your config file or script
```

The keyfile is written to the service account's own profile. The scheduled task or service then runs as that same account and finds the keyfile automatically.

## Option 3 — Custom keyfile location for the service account (Windows)

> **Note**: Because encryption is bound to the OS user, the credentials **must be encrypted by the same service account** that will later decrypt them. You cannot encrypt as one user and decrypt as another.

Use this when you want the keyfile stored centrally (e.g. `ProgramData`) rather than in the service account's roaming profile.

**One-time setup** — run this as the service account (`runas /user:DOMAIN\svc_myservice powershell`):

```PowerShell
Import-Module EncryptCredential

# Place the keyfile in a shared, admin-controlled location
$sharedKey = "C:\ProgramData\AptecoPSModules\svc_myservice.aes"
Export-Keyfile -Path $sharedKey

# Restrict: remove inheritance, grant Administrators + this service account only
$acl = Get-Acl -Path $sharedKey
$acl.SetAccessRuleProtection($true, $false)
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators", "FullControl",
    [System.Security.AccessControl.AccessControlType]::Allow
)
$svcRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "DOMAIN\svc_myservice", "Read",   # the account that will also decrypt
    [System.Security.AccessControl.AccessControlType]::Allow
)
$acl.SetAccessRule($adminRule)
$acl.SetAccessRule($svcRule)
Set-Acl -Path $sharedKey -AclObject $acl

# Now encrypt — must be run as the same service account
$encrypted = "MyPassword" | Convert-PlaintextToSecure
# Store $encrypted in your config file
```

In the scheduled task / service script (running as `svc_myservice`):

```PowerShell
Import-Module EncryptCredential
Import-Keyfile -Path "C:\ProgramData\AptecoPSModules\svc_myservice.aes"
$password = $encryptedString | Convert-SecureToPlaintext
```

## Option 4 — Linux systemd service

Create a dedicated system user, encrypt credentials as that user, and restrict keyfile access.
The systemd service must run as the same user that did the encryption.

```bash
# Copy the keyfile to a directory only the service user can read
sudo mkdir -p /var/lib/apteco
sudo cp ~/.local/share/AptecoPSModules/key.aes /var/lib/apteco/key.aes
sudo chown apteco:apteco /var/lib/apteco/key.aes
sudo chmod 600 /var/lib/apteco/key.aes
```

Example systemd unit (`/etc/systemd/system/myservice.service`):

```ini
[Unit]
Description=My Apteco Service

[Service]
User=apteco
ExecStart=/usr/bin/pwsh -File /opt/apteco/myservice.ps1
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

In the PowerShell script:

```PowerShell
Import-Module EncryptCredential
Import-Keyfile -Path "/var/lib/apteco/key.aes"
$password = $encryptedString | Convert-SecureToPlaintext
```

## Option 5 — C# hosted PowerShell (in-process or out-of-process)

The module works when called from C# via the PowerShell SDK, both with an
in-process runspace and with an out-of-process runspace spawned at a specific
bitness using `PowerShellProcessInstance`.

**In-process** (`Runspace.CreateRunspace()`): the runspace runs inside the C#
process and inherits its Windows identity and profile state directly.

**Out-of-process** (`PowerShellProcessInstance`): a child PowerShell process is
spawned. It inherits the parent process's Windows token and profile state, so
DPAPI behaves identically to the parent.

In both cases the **same `LoadUserProfile` requirement applies** as for scheduled
tasks. If the hosting process is a Windows Service or IIS app pool, ensure the
user profile is loaded before any DPAPI call is made (see the note at the top of
this section).

```csharp
// Out-of-process example — 32-bit PowerShell 5.1
var exe = new FileInfo(
    @"C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe");
var instance = new PowerShellProcessInstance(
    new Version(5, 1), null, exe, false);

using var runspace = RunspaceFactory.CreateOutOfProcessRunspace(null, instance);
runspace.Open();

using var ps = PowerShell.Create();
ps.Runspace = runspace;
ps.AddCommand("Import-Module").AddArgument("EncryptCredential");
ps.Invoke();

ps.Commands.Clear();
ps.AddCommand("Convert-SecureToPlaintext")
  .AddParameter("String", encryptedString);

string plaintext = ps.Invoke<string>().FirstOrDefault();
```

> **Verify DPAPI is available** from the hosting process before deploying.
> Add the snippet below to your startup / health-check logic — it will throw
> immediately with a clear message if the user profile is not loaded, rather
> than failing silently later at runtime:
>
> ```csharp
> // Smoke-test: round-trip a dummy value through DPAPI
> var dummy = System.Text.Encoding.UTF8.GetBytes("dpapi-check");
> var blob  = System.Security.Cryptography.ProtectedData.Protect(
>                 dummy, null,
>                 System.Security.Cryptography.DataProtectionScope.CurrentUser);
> System.Security.Cryptography.ProtectedData.Unprotect(
>                 blob, null,
>                 System.Security.Cryptography.DataProtectionScope.CurrentUser);
> // If this line is reached, DPAPI is working correctly.
> ```


# Migrating to v0.4.0

v0.4.0 introduced machine-and-user binding. All strings encrypted with v0.3.0
or earlier will fail to decrypt with v0.4.0. You need to decrypt the old strings
and re-encrypt them with the new module.

> **Windows note**: v0.4.0 also changes the keyfile format from raw bytes to a
> DPAPI-protected blob. After re-encrypting, run `New-Keyfile` to regenerate the
> keyfile in the new format. The old raw-bytes keyfile will no longer be readable
> by v0.4.0.

## Path A — decrypt before upgrading (recommended)

Do this while v0.3.0 is still installed.

```PowerShell
# 1. Decrypt every stored string using v0.3.0
Import-Module EncryptCredential          # must still be v0.3.0
# Import-Keyfile -Path "C:\...\key.aes"  # only if you use a non-default location

$plain1 = "<your first old encrypted string>"  | Convert-SecureToPlaintext
$plain2 = "<your second old encrypted string>" | Convert-SecureToPlaintext
# repeat for every stored credential

# 2. Upgrade the module
Update-Module EncryptCredential          # or: Install-Module EncryptCredential -Force

# 3. Re-encrypt — this also generates a new DPAPI-protected keyfile automatically
Import-Module EncryptCredential -Force   # loads v0.4.0

$new1 = $plain1 | Convert-PlaintextToSecure
$new2 = $plain2 | Convert-PlaintextToSecure
# replace the stored values with $new1, $new2, etc.
```

## Path B — already upgraded to v0.4.0 without migrating first

If you upgraded before decrypting, the module can no longer read the old strings
because the old keyfile is raw bytes but v0.4.0 expects a DPAPI blob on Windows,
or an HMAC-bound key on Linux.

Decrypt using raw PowerShell (bypasses the module entirely), then re-encrypt:

```PowerShell
# Helper: read raw keyfile bytes (handles binary and legacy text format)
function Read-KeyfileRaw ([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -in @(16, 24, 32)) { return $bytes }

    # Legacy format: one decimal byte value per line
    $lines = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) `
                 -split "`r?`n" | Where-Object { $_.Trim() -ne '' }
    return [byte[]]($lines | ForEach-Object { [byte]$_.Trim() })
}

# Adjust path if you used a custom keyfile location
$keyPath  = "$env:LOCALAPPDATA\AptecoPSModules\key.aes"   # Windows default
# $keyPath = "$env:HOME/.local/share/AptecoPSModules/key.aes"  # Linux default

$keyBytes = Read-KeyfileRaw -Path $keyPath

# Decrypt using the old raw-AES method (no binding, no DPAPI)
function Decrypt-OldString ([string]$Encrypted, [byte[]]$Key) {
    $secure = ConvertTo-SecureString -String $Encrypted -Key $Key
    $plain  = (New-Object PSCredential "x", $secure).GetNetworkCredential().Password
    $secure.Dispose()
    return $plain
}

$plain1 = Decrypt-OldString "<your first old encrypted string>"  $keyBytes
$plain2 = Decrypt-OldString "<your second old encrypted string>" $keyBytes
# repeat for every stored credential

# Re-encrypt with v0.4.0 — a new DPAPI-protected keyfile is created automatically
Import-Module EncryptCredential -Force
# Note: do NOT call Import-Keyfile here — let the module create a fresh keyfile

$new1 = $plain1 | Convert-PlaintextToSecure
$new2 = $plain2 | Convert-PlaintextToSecure
# replace the stored values with $new1, $new2, etc.
```


# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "EncryptCredential" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule EncryptCredential
```

If you want to find more [Apteco scripts in PSGallery](https://www.powershellgallery.com/packages?q=Tags%3A%22Apteco%22), please search with

```PowerShell
Find-Module -Repository "PSGallery" -Tag "Apteco"
```

### Installation via local Repository

If your machine does not have an online connection you can use another machine to save the script from PSGallery website as a local file via your browser. You should have download a file with an `.nupkg` extension. Please don't forget to download all dependencies, too. You could simply unzip the file(s) and put the script somewhere you need it OR do it in an updatable manner and create a local repository if you don't have it already with

```PowerShell
Set-Location "$( $env:USERPROFILE )\Downloads"
New-Item -Name "PSRepo" -ItemType Directory
Register-PSRepository -Name "LocalRepo" -SourceLocation "$( $env:USERPROFILE )\Downloads\PSRepo"
Get-PSRepository
```

On Linux you would use `Set-Location "$( $env:Home )/Downloads"` or create the `.\Downloads` directory.

Then put your downloaded `.nupkg` file into the new created `PSRepo` folder and you should see the module via 

```PowerShell
Find-Module -Repository LocalRepo
```

Then install the script like 

```PowerShell
Find-Module -Repository LocalRepo -Name EncryptCredential -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name EncryptCredential
```

## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location EncryptCredential
Import-Module .\EncryptCredential
```

