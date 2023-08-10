Function Export-Settings {
﻿

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    Process {
        try {

            # Resolve path first
            $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

            If ( ( Test-Path -Path $absolutePath -IsValid ) -eq $true ) {

                # TODO [x] Handle overwriting the file, currently it will be overwritten
                If ( Test-Path -Path $absolutePath ) {
                    $backupPath = "$( $absolutePath ).$( [Datetime]::Now.ToString("yyyyMMddHHmmss") )"
                    Write-Verbose -message "Moving previous settings file '$( $absolutePath )' to $( $backupPath )" -Verbose
                    Move-Item -Path $absolutePath -Destination $backupPath -Verbose
                }

                # Now save the settings file
                ConvertTo-Json -InputObject  $script:settings -Depth 99 | Set-Content -Path $absolutePath -Encoding utf8 -Verbose

                # Resolve the path now to an absolute path
                $resolvedPath = Resolve-Path -Path $absolutePath


            } else {

                Write-Error -Message "The path '$( $Path )' is invalid."

            }

        } catch {

            Write-Error -Message "The path '$( $Path )' is invalid."

        }

        # Return
        $resolvedPath.Path

    }


}