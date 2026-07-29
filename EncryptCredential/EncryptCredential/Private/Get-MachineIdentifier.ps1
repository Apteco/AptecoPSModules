Function Get-MachineIdentifier {

<#
    Returns a stable identifier for the current machine on non-Windows platforms.
    Used to derive the machine-bound outer encryption key where DPAPI is not available.

    Sources in priority order:
      - /etc/machine-id (systemd)
      - /var/lib/dbus/machine-id (dbus)
      - IOPlatformUUID (macOS)
      - machine name (weak fallback)
#>

    [CmdletBinding()]
    param()

    ForEach ( $idPath in @( '/etc/machine-id', '/var/lib/dbus/machine-id' ) ) {
        If ( Test-Path -Path $idPath ) {
            $id = ( [System.IO.File]::ReadAllText($idPath) ).Trim()
            If ( $id.Length -gt 0 ) {
                return $id
            }
        }
    }

    # macOS
    If ( $null -ne ( Get-Command -Name "ioreg" -ErrorAction SilentlyContinue ) ) {
        $line = & ioreg -rd1 -c IOPlatformExpertDevice 2>$null | Select-String -Pattern 'IOPlatformUUID' | Select-Object -First 1
        If ( $null -ne $line ) {
            $parts = "$( $line )" -split '"'
            If ( $parts.Count -ge 2 ) {
                return $parts[-2]
            }
        }
    }

    # Weak fallback, better than nothing
    Write-Warning -Message "No machine id found, falling back to the machine name. Machine binding is weak on this platform."
    return [System.Environment]::MachineName

}
