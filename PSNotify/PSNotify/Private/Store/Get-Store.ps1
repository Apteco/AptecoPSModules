
Function Get-Store {
    [CmdletBinding()]
    param(
        #[Parameter(Mandatory=$true)][String]$Path
    )

    Process {

        $store = $null
        try {

            # Resolve path first
            $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Script:defaultStorefile)

            If ( ( Test-Path -Path $absolutePath -IsValid ) -eq $true ) {

                # Now load the store file
                $storeContent = Get-Content -Path $absolutePath -encoding utf8 -Raw | ConvertFrom-Json #-Depth 99

                # Resolve the path now to an absolute path
                #$resolvedPath = Resolve-Path -Path $absolutePath


            } else {

                Write-Error -Message "The path '$( $Script:defaultStorefile )' is invalid."

            }

        } catch {

            Write-Error -Message "The path '$( $Script:defaultStorefile )' is invalid."

        }

        # Return
        #$resolvedPath.Path
        $Script:store = $storeContent

    }


}
