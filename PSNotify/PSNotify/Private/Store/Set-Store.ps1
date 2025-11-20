Function Set-Store {
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

                # TODO [x] Handle overwriting the file, currently it will be overwritten
                If ( Test-Path -Path $absolutePath ) {
                    $backupPath = "$( $absolutePath ).$( [Datetime]::Now.ToString("yyyyMMddHHmmssffff") )"
                    Write-Verbose -message "Moving previous store file '$( $absolutePath )' to $( $backupPath )" #-Verbose
                    Move-Item -Path $absolutePath -Destination $backupPath #-Verbose
                }

                # Now save the store file
                ConvertTo-Json -InputObject $script:store -Depth 99 | Set-Content -Path $absolutePath -Encoding utf8 # -Verbose

                # Resolve the path now to an absolute path
                $resolvedPath = Resolve-Path -Path $absolutePath


            } else {

                Write-Error -Message "The path '$( $Script:defaultStorefile )' is invalid."

            }

        } catch {

            Write-Error -Message "The path '$( $Script:defaultStorefile )' is invalid."

        }

        # Return
        $script:store

    }


}
