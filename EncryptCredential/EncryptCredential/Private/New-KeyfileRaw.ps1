
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
            [System.IO.File]::WriteAllBytes($Path, $Key)

            # Restrict file access to the current user only
            If ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
                # Windows: remove inherited ACEs, grant current user full control
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
                # Linux/macOS: owner read/write only (600)
                & chmod 600 $Path
            }

        } else {

            Write-Warning -Message "Path is invalid. Please check '$( $Path )'"

        }

    }

}