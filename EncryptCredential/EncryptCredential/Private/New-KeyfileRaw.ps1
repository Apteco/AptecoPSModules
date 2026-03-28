
Function New-KeyfileRaw {

<#
    This function creates a new keyfile
#>

    param(
         [Parameter(Mandatory=$true)][String]$Path
        ,[Parameter(Mandatory=$false)][int]$ByteLength = 32
        ,[Parameter(Mandatory=$false)][Switch]$Force
    )

    $writeFile = $false

    # Evaluate if the file should be created
    if ( (Test-Path -Path $Path) -eq $true ) {

        If ( $Force -eq $true ) {
            $writeFile = $true
            Write-Warning "The keyfile at '$( $Path )' already exists. It will be removed now"
            Remove-Item -Path $Path
        } else {
            Write-Warning "The keyfile at '$( $Path )' already exists. Please use -Force to overwrite the file."
        }

    } else {

        # File does not exist -> create it
        $writeFile = $true

    }

    If ( $writeFile -eq $true) {

        # Checking the path validity
        If ( (Test-Path -Path $Path -IsValid) -eq $true ) {

            Write-Verbose -Message "Path is valid. Creating a new keyfile at '$( $Path )'" #-Verbose

            $Key = New-Object Byte[] $ByteLength   # You can use 16, 24, or 32 for AES
            $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
            $rng.GetBytes($Key)
            $rng.Dispose()

            If ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {

                # Windows: DPAPI-protect the key bytes before writing to disk.
                # The resulting blob can only be decrypted by the same user on the
                # same machine — it is backed by Windows credential infrastructure
                # (LSASS, optionally TPM).  The raw AES key never touches disk.
                Add-Type -AssemblyName System.Security
                $protected = [System.Security.Cryptography.ProtectedData]::Protect(
                    $Key,
                    $null,
                    [System.Security.Cryptography.DataProtectionScope]::CurrentUser
                )
                [System.IO.File]::WriteAllBytes($Path, $protected)

                # ACL: also restrict file access to the current user (defence in depth)
                $acl = Get-Acl -Path $Path
                $acl.SetAccessRuleProtection($true, $false)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
                    "FullControl",
                    [System.Security.AccessControl.AccessControlType]::Allow
                )
                $acl.SetAccessRule($rule)
                Set-Acl -Path $Path -AclObject $acl

            } else {

                # Linux/macOS: save raw bytes, restrict to owner read/write only (600)
                [System.IO.File]::WriteAllBytes($Path, $Key)
                & chmod 600 $Path

            }

        } else {

            Write-Warning -Message "Path is invalid. Please check '$( $Path )'"

        }

    }

}