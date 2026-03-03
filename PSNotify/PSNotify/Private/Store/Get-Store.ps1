
Function Get-Store {
    [CmdletBinding()]
    param(
        #[Parameter(Mandatory=$true)][String]$Path
    )

    Process {

        try {

            # Resolve path first
            $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Script:defaultStorefile)

            If ( ( Test-Path -Path $absolutePath -IsValid ) -eq $true ) {

                # Assign inside the try so a parse/IO failure cannot set $Script:store to $null
                $Script:store = Get-Content -Path $absolutePath -encoding utf8 -Raw | ConvertFrom-Json #-Depth 99

            } else {

                Write-Error -Message "The path '$( $Script:defaultStorefile )' is invalid."

            }

        } catch {

            Write-Error -Message "Failed to load store from '$( $Script:defaultStorefile )': $_"

        }

    }


}
