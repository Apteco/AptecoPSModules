# TODO [ ] implement settings the settings


Function Set-Settings {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$PSCustom
    )

    Process {

        # Exchange relativ paths
        $resolvedLogPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PSCustom."logfile")
        $PSCustom."logfile" = $resolvedLogPath

        $resolvedKeyFile = ""
        If ( $PSCustom."keyfile" -ne "" ) {
            $resolvedKeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PSCustom."keyfile")
        }
        $PSCustom."keyfile" = $resolvedKeyFile

        # Set the settings
        $script:settings = $PSCustom
        #$Script:debug = $script:settings

        # Set the logfile, if it is set, otherwise it will create automatically a new temporary file
        If ( $Script:settings.logfile -ne "" ) {
            Set-Logfile -Path $Script:settings.logfile
        }
        
    }

}