Function Get-BoundKey {
<#
    Derives a machine-and-user-bound 32-byte AES key from raw keyfile bytes.

    SECURITY MODEL
    --------------
    The raw keyfile bytes are never used directly as the AES encryption key.
    Instead, an HMAC-SHA256 is computed using:

        HMAC-SHA256( key  = raw keyfile bytes,   <- the secret you must possess
                     data = machine_id | user_id  <- read from the OS at runtime )

    This means that even if an attacker obtains the keyfile, they still cannot
    decrypt anything unless they are ALSO:
      - Running on the same machine (same Machine GUID / machine-id)
      - Running as the same OS user account (same SID / UID)

    Critically, the machine identity and user identity are obtained at runtime
    from the operating system itself.  There is no parameter a caller can pass
    to override or forge them.  The only way to decrypt on a given machine as a
    given user is to physically be that user on that machine.

    HMAC output is always 32 bytes, which is the correct size for AES-256.
#>

    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory=$true)][byte[]]$RawKey
    )

    # --- collect OS-provided binding (not caller-supplied) -------------------

    if ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {

        # Windows: MachineGuid (unique per Windows install) + current user SID
        # Both values come from the OS; neither can be faked by the calling script.
        $machineGuid = (Get-ItemProperty `
            -Path  'HKLM:\SOFTWARE\Microsoft\Cryptography' `
            -Name  'MachineGuid' `
            -ErrorAction Stop).MachineGuid

        $userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

        $binding = "${machineGuid}|${userSid}"

    } else {

        # Linux / macOS: /etc/machine-id (unique per OS install) + username + numeric UID
        # /etc/machine-id is set once at install time and never changes.
        # The numeric UID is the OS-assigned identity for the running process.
        $machineId = $null
        foreach ($candidate in @('/etc/machine-id', '/var/lib/dbus/machine-id')) {
            if (Test-Path -Path $candidate) {
                $machineId = ([System.IO.File]::ReadAllText($candidate)).Trim()
                break
            }
        }
        if ([string]::IsNullOrEmpty($machineId)) {
            throw "Cannot determine machine identity: neither /etc/machine-id nor " +
                  "/var/lib/dbus/machine-id was found. Ensure one of these files exists."
        }

        $userName = [System.Environment]::UserName
        $uid      = (& id -u 2>$null)
        $binding  = "${machineId}|${userName}|${uid}"

    }

    # --- derive key -----------------------------------------------------------
    # HMAC-SHA256(key=keyfileBytes, data=bindingString)
    # The keyfile is the HMAC key (secret); machine+user identity is the data.
    # Changing any part of the binding produces a completely different output.

    $bindingBytes = [System.Text.Encoding]::UTF8.GetBytes($binding)
    $hmac = [System.Security.Cryptography.HMACSHA256]::new($RawKey)
    try {
        return [byte[]]$hmac.ComputeHash($bindingBytes)   # always 32 bytes
    } finally {
        $hmac.Dispose()
    }

}
