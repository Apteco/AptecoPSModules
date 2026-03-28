Function Read-Keyfile {
<#
    Returns raw file bytes for Get-BoundKey to interpret.

    Supports three formats:
      - Windows v0.4.0+: DPAPI-protected blob (variable length, always > 32 bytes)
      - Binary (Linux / Windows v0.3.0): raw AES key, exactly 16, 24, or 32 bytes
      - Legacy text (all platforms, very old): UTF8, one decimal byte value per line
#>
    param(
        [Parameter(Mandatory=$true)][String]$Path
    )

    $rawBytes = [System.IO.File]::ReadAllBytes($Path)

    # Binary file: either a raw AES key (16/24/32 bytes) or a Windows DPAPI blob (> 32 bytes).
    # Return as-is in both cases; Get-BoundKey handles the interpretation.
    If ($rawBytes.Length -in @(16, 24, 32) -or
        (($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) -and $rawBytes.Length -gt 32)) {
        return $rawBytes
    }

    # Legacy text format: each line is a decimal byte value, possibly with UTF8 BOM.
    # ReadAllText with UTF8 encoding strips the BOM automatically.
    $lines = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) -split "`r?`n" |
                 Where-Object { $_.Trim() -ne '' }

    return [byte[]]($lines | ForEach-Object { [byte]$_.Trim() })

}
