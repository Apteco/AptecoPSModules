
Function Export-Settings {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    Process {
        try {

            If ( ( Test-Path -Path $Path -IsValid ) -eq $true ) {
                # TODO [ ] Handle overwriting the file, currently it will be overwritten
                #If (( Test-Path -Path $Path ) -eq $true) {
                #$resolvedPath = Resolve-Path -Path $Path
                ConvertTo-Json -InputObject  $script:settings -Depth 99 | Set-Content -Path $Path -Encoding utf8 -Verbose
                #} 
    
            } else {

                Write-Error -Message "The path '$( $Path )' is invalid."

            }

        } catch {

            Write-Error -Message "The path '$( $Path )' is invalid."

        }

        # Return
        $resolvedPath

    }


}