Function Read-Keyfile {
<#
    Returns the AES key bytes from the keyfile.
    Supports both formats:
      - New: raw binary (16/24/32 bytes written with WriteAllBytes)
      - Legacy: UTF8 text with one decimal number per line (written with Set-Content -Encoding UTF8)
#>
    param(
        [Parameter(Mandatory=$true)][String]$Path
    )

    $rawBytes = [System.IO.File]::ReadAllBytes($Path)

    If ($rawBytes.Length -in @(16, 24, 32)) {
        # Binary keyfile (new format)
        return $rawBytes
    }

    # Legacy text format: each line is a decimal byte value, possibly with UTF8 BOM.
    # ReadAllText with UTF8 encoding strips the BOM automatically.
    $lines = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) -split "`r?`n" |
                 Where-Object { $_.Trim() -ne '' }

    return [byte[]]($lines | ForEach-Object { [byte]$_.Trim() })

}
