
Function Create-KeyFile {
    
<#
This function creates a new keyfile
#>

    param(
         [Parameter(Mandatory=$true)][string]$Path
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

            Write-Verbose -Message "Path is valid. Creating a new keyfile at '$( $Path )'" -Verbose

            $Key = New-Object Byte[] $ByteLength   # You can use 16, 24, or 32 for AES
            [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
            $Key | Set-Content -Encoding UTF8 -Path $Path

        } else {

            Write-Warning -InputObject "Path is invalid. Please check '$( $Path )'"
            
        }

    }
    
}