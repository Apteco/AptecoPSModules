Function Set-ProcessId {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Id
    )

    # Set override value so we know it was set
    $Script:processIdOverride = $true

    $Script:processId = $Id

    # Return
    Write-Verbose "Using the process id: $( $Id )"


}