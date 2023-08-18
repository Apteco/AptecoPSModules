
Function Set-DebugMode {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][Boolean]$DebugMode
    )

    Process {

        $Script:debugMode = $DebugMode

        If ( $Script:settings.logfile -ne "") {
            If ( $DebugMode -eq $true ) {
                $Script:settings.logfile = "$( $Script:settings.logfile ).debug"
            } else {
                $Script:settings.logfile = $Script:settings.logfile -replace ".debug"
            }
            Set-Logfile -Path $Script:settings.logfile
            #Write-Log -Message "Current logfile: $( $Script:settings.logfile )" -Severity INFO
        }

    }


}