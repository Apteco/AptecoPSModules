# TODO [ ] implement settings the settings


Function Set-Settings {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$PSCustom
    )

    Process {

        $script:settings = $PSCustom

        # Set the logfile, if it is set, otherwise it will create automatically a new temporary file
        If ( $Script:settings.logfile -ne "" ) {
            Set-Logfile -Path $Script:settings.logfile
        }
        
    }

}