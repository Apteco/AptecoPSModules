
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

The raw keyfile bytes are **never** used directly as the AES encryption key.
Before any encryption or decryption, the module derives the actual key via HMAC-SHA256:

```
AES key = HMAC-SHA256( key  = keyfile bytes       ← the secret you must possess
                       data = machine_id | user_id ← read from the OS at runtime )
```

### Where the identity comes from

| Platform | Machine identity | User identity |
|----------|-----------------|---------------|
| Windows | `MachineGuid` from `HKLM:\SOFTWARE\Microsoft\Cryptography` | Current user SID via `WindowsIdentity.GetCurrent()` |
| Linux | `/etc/machine-id` (set once at OS install time) | `$env:UserName` + numeric UID from `id -u` |

Both values are **read from the operating system at runtime**. There is no parameter a script or caller can pass to override them. The only way to decrypt on a given machine as a given user is to actually be running as that user on that machine.

### What this means in practice

- Copying the encrypted string to another machine → decryption fails (different machine ID)
- Copying the keyfile to another machine and running the same script → decryption fails (different machine ID)
- Running as a different user account on the same machine → decryption fails (different SID / UID)
- An attacker who steals the keyfile but is on a different machine → cannot decrypt

### What this does NOT protect against

- An attacker who **is already running as the same user on the same machine** (they have everything needed)
- Physical access to the machine combined with extraction of `/etc/machine-id` and the keyfile (both inputs to the HMAC are then known)

The binding adds a meaningful extra layer, but it is not a substitute for protecting the keyfile itself with strict file permissions. Both defences work together.

### Scheduled tasks and services

Because the binding uses the OS user identity at runtime, a scheduled task or service **must run as the same user account that originally encrypted the credentials**. If you change the service account, you must re-encrypt. See [Using with Scheduled Tasks or Windows Services](#using-with-scheduled-tasks-or-windows-services) for setup options.


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

Because encryption is AES-based (not Windows DPAPI), the encrypted strings are portable. The only requirement is that **the account running the task or service can read the keyfile**.

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

