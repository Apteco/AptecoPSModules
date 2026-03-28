Function Get-BoundKey {
<#
    Derives or recovers a machine-and-user-bound 32-byte AES key from raw keyfile bytes.

    SECURITY MODEL
    --------------
    Windows
      New-KeyfileRaw writes the keyfile as a DPAPI-protected blob (CurrentUser scope).
      Get-BoundKey calls ProtectedData.Unprotect() to recover the original random bytes.
      Unprotect only succeeds for the same user on the same machine; it is backed by
      Windows credential infrastructure (LSASS, optionally TPM-backed master key).
      Unlike the previous HMAC approach, knowing the user SID or machine GUID alone
      is NOT sufficient — the user's actual login credentials are part of the key
      material managed by Windows.

    Linux / macOS
      The keyfile holds raw random bytes (no DPAPI available).
      An HMAC-SHA256 is computed over those bytes using machine identity
      (/etc/machine-id) and the current numeric UID as the HMAC key.
      This raises the bar against cross-machine / cross-user keyfile theft but is
      a software-only binding — the binding values are not themselves secret.

    In both cases the binding is determined by the operating system at runtime.
    There is no parameter a caller can supply to override or forge the identity.
#>

    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory=$true)][byte[]]$RawKey
    )

    if ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {

        # Windows: keyfile is a DPAPI blob written by New-KeyfileRaw.
        # Unprotect recovers the original AES key bytes.
        # This only succeeds for the same user on the same machine.
        Add-Type -AssemblyName System.Security
        try {
            return [byte[]][System.Security.Cryptography.ProtectedData]::Unprotect(
                $RawKey,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )
        } catch [System.Security.Cryptography.CryptographicException] {
            throw (
                "Keyfile cannot be decrypted by DPAPI. Possible causes: " +
                "(1) the keyfile was created on a different machine or by a different user account; " +
                "(2) it is in the legacy raw-bytes format from v0.3.0 or earlier — " +
                "see 'Migrating to v0.4.0' in the README."
            )
        }

    } else {

        # Linux / macOS: HMAC-SHA256 binding.
        # machine-id + username + numeric UID are read from the OS at runtime;
        # they cannot be overridden by the calling script.
        $machineId = $null
        foreach ($candidate in @('/etc/machine-id', '/var/lib/dbus/machine-id')) {
            if (Test-Path -Path $candidate) {
                $machineId = ([System.IO.File]::ReadAllText($candidate)).Trim()
                break
            }
        }
        if ([string]::IsNullOrEmpty($machineId)) {
            throw (
                "Cannot determine machine identity: neither /etc/machine-id nor " +
                "/var/lib/dbus/machine-id was found. Ensure one of these files exists."
            )
        }

        $userName = [System.Environment]::UserName
        $uid      = (& id -u 2>$null)
        $binding  = "${machineId}|${userName}|${uid}"

        $bindingBytes = [System.Text.Encoding]::UTF8.GetBytes($binding)
        $hmac = [System.Security.Cryptography.HMACSHA256]::new($RawKey)
        try {
            return [byte[]]$hmac.ComputeHash($bindingBytes)   # always 32 bytes
        } finally {
            $hmac.Dispose()
        }

    }

}
