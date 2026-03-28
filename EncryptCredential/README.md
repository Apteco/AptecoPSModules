
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

> **Important**: The encrypted strings are tied to the **keyfile**, not to a specific machine or user account. Because the module encrypts with AES using the keyfile as the key (not Windows DPAPI), the encrypted strings **can** be used on other machines or by other user accounts — as long as the same keyfile is available and readable. Guard the keyfile accordingly.

If you don't provide a keyfile, it will be automatically generated with your first call of `Convert-PlaintextToSecure`

You can use `Import-Keyfile` to use a keyfile that has been exported before.


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

## Option 3 — Shared keyfile with restricted ACL (Windows)

Use this when the encrypting user and the running account are different.

```PowerShell
# One-time setup: export the keyfile to a shared, admin-controlled location
$sharedKey = "C:\ProgramData\AptecoPSModules\key.aes"
Export-Keyfile -Path $sharedKey

# Lock down: remove inheritance, grant Administrators + service account only
$acl = Get-Acl -Path $sharedKey
$acl.SetAccessRuleProtection($true, $false)

$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators",
    "FullControl",
    [System.Security.AccessControl.AccessControlType]::Allow
)
$svcRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "DOMAIN\svc_myservice",   # replace with your service account
    "Read",
    [System.Security.AccessControl.AccessControlType]::Allow
)
$acl.SetAccessRule($adminRule)
$acl.SetAccessRule($svcRule)
Set-Acl -Path $sharedKey -AclObject $acl
```

In the scheduled task / service script, import the keyfile before decrypting:

```PowerShell
Import-Module EncryptCredential
Import-Keyfile -Path "C:\ProgramData\AptecoPSModules\key.aes"
$password = $encryptedString | Convert-SecureToPlaintext
```

## Option 4 — Linux systemd service

Create a dedicated system user and restrict keyfile access:

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

