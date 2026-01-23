Function Remove-AdditionalLogfile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [String] $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [String] $Path

        # [Parameter(Mandatory = $true, ParameterSetName = 'ByIndex')]
        # [int] $Index

    )

    Process {
        
        switch ($PSCmdlet.ParameterSetName) {

            'ByName' {
                $matches = @( $Script:additionalLogs | Where-Object { $_.Name -eq $Name } )
            }

            'ByPath' {
                $matches = @( $Script:additionalLogs | Where-Object { $_.Options -and $_.Options.Path -eq $Path } )
            }

            # 'ByIndex' {
            #     if ($Index -lt 0 -or $Index -ge $Script:additionalLogs.Count) {
            #         Write-Error "Index $Index is out of range (0..$($Script:additionalLogs.Count - 1))."
            #         return
            #     }
            #     $matches = @( $Script:additionalLogs[$Index] )
            # }

            default {
                Write-Error "Invalid parameter set. Use -Name, -Path or -Index."
                return
            }

        }

        if (-not $matches -or $matches.Count -eq 0) {
            Write-Error "No additional logfile found for the given criteria."
            return
        }

        foreach ($item in $matches) {
            if ($PSCmdlet.ShouldProcess("Additional log '$($item.Name)'", 'Remove')) {
                $Script:additionalLogs.Remove($item)
            }
        }

    }

}