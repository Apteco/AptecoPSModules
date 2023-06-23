<#
Function Set-ExecutionDirectory {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    Process {
        try {
            
            If ( ( Test-Path -Path $Path -IsValid ) -eq $true ) {
                If (( Test-Path -Path $Path ) -eq $false) {
                    Write-Host "Create the Path"
                    $item = New-Item -Path $Path -ItemType Directory
                }
    
                $resolvedPath = Resolve-Path -Path $Path
                $Script:execPath = $resolvedPath.Path
    
            } else {

                Write-Error -Message "The path '$( $Path )' is invalid."

            }

        } catch {

            Write-Error -Message "The path '$( $Path )' is invalid."

        }

        # Return
        $Script:execPath

    }

}
#>