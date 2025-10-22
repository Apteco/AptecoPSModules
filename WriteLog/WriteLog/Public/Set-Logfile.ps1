Function Set-Logfile {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path
        ,[Parameter(Mandatory=$false)][switch]$DisableOverride = $False
    )

    Process {

        try {

            If ( (Test-Path -Path $Path -IsValid) -eq $true) {

                # Create the item if not existing
                #If (( Test-Path -Path $Path ) -eq $false) {
                #    Write-Verbose "Create the item"
                #    New-Item -Path $Path -ItemType File
                #}

                #$resolvedPath = Resolve-Path -Path $Path
                #$Script:logfile = $resolvedPath.Path

                $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
                $Script:logfile = $resolvedPath

            } else {

                Write-Error -Message "The path '$( $Path )' is invalid."

            }

        } catch {

            Write-Error -Message "The path '$( $Path )' is invalid."

        }

        # Set override value so we know it was set
        If ( $DisableOverride -eq $true ) {
            $Script:logfileOverride = $false
        } else {
            $Script:logfileOverride = $true
        }

        # Return
        Write-Verbose "Using the file: '$( $Script:logfile )'"

        #$True

    }

}