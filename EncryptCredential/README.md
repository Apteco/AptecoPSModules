
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

This module is used to double encrypt sensitive data like credentials, tokens etc.

# Security model

Since version 0.4.0 encryption happens in two layers:

1. **Keyfile layer**: AES-256 via SecureString with a random 32 byte keyfile. The keyfile is created
   automatically on first use, stored in your user profile (`%LOCALAPPDATA%\AptecoPSModules\key.aes`)
   and restricted to your user account (NTFS ACL on Windows, `chmod 600` on Linux/macOS).
2. **Machine binding layer**: the result is encrypted a second time bound to the machine.
   On Windows this uses DPAPI with the keyfile as additional entropy, on Linux/macOS AES-256 with
   keys derived from the keyfile and the machine id (`/etc/machine-id`), protected against
   tampering with HMAC-SHA256.

So even if an attacker steals **both** the encrypted string **and** the keyfile, they cannot decrypt
it on another machine.

The `-Scope` parameter of `Convert-PlaintextToSecure` controls the binding:

| Scope | Meaning |
|-------|---------|
| `Machine` (default) | Decryptable only on this machine, by any account that can read the keyfile |
| `User` | Decryptable only on this machine AND only by the account that encrypted it |
| `Portable` | Legacy single-layer format (keyfile only) - only use this if you need to move ciphertexts to another machine together with the keyfile |

```PowerShell
# Bind to this machine and the current user account
"Hello World" | Convert-PlaintextToSecure -Scope User
```

Strings encrypted with versions before 0.4.0 are detected automatically and stay decryptable
(downwards compatible). Note for the `Machine` scope on Windows: encryption works across accounts
on the same machine, e.g. you can encrypt as an admin user and decrypt as a service account - as
long as that account can read the keyfile (use `Export-Keyfile` to place it somewhere both
accounts can access, or grant read access on the file).

Limitations you should know about:

- Anyone who can execute code as your user on this machine (or as any keyfile-reading account
  for `Machine` scope) can decrypt the values. This is inherent to any non-interactive
  credential storage.
- On Linux/macOS there is no DPAPI, so machine binding is derived from `/etc/machine-id`.
  An attacker who steals the keyfile AND the machine id can reconstruct the key offline.

# Migration from versions before 0.4.0

Nothing breaks when you update: strings encrypted with 0.3.x and earlier are detected by their
format and keep decrypting with the keyfile only. But they do **not** get the new machine binding
automatically - they stay as secure (or insecure) as before. To benefit from the new protection,
re-encrypt them once on the machine where they are used:

```PowerShell
# Decrypt with the old format, re-encrypt with the new machine-bound format
$newString = $oldString | Convert-SecureToPlaintext | Convert-PlaintextToSecure
```

Then replace the stored value (e.g. in your settings file) with `$newString`.

Important points for the migration:

- Keep your existing keyfile. Do **not** call `New-Keyfile` before all old strings are
  re-encrypted, otherwise they become unreadable.
- Re-encrypt **on the machine that will decrypt later**, under an account that can read the
  keyfile. With `-Scope User` it must be exactly the account that will decrypt later
  (e.g. the service account), so for shared machine setups stay with the default `Machine` scope.
- You can identify already migrated strings by their prefix: new machine-bound strings start
  with `ApSec2|`, legacy strings with `76492d1116743f0423413b16050a5345`.
- If you previously copied the keyfile to several machines to share encrypted settings files,
  that only continues to work with `-Scope Portable`. The recommended way is instead to
  re-encrypt the credentials once per machine, so every machine holds its own machine-bound
  ciphertexts.
- The re-encryption briefly handles the plaintext in your session, so run it in a trusted
  interactive session and avoid writing the plaintext to logs or transcripts
  (`Stop-Transcript` if in doubt).

# Keyfile handling

At the first encryption a new random keyfile will be generated automatically.
The key is saved per default in your users profile, but can be exported into any other folder
with `Export-Keyfile` and used from there.

You can use `Import-Keyfile` to use a keyfile that has been exported before.

`New-Keyfile` regenerates the keyfile - all previously encrypted strings become invalid, so
re-encrypt your credentials afterwards.


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

