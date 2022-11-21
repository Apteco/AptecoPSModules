Function Get-Logfile {

    [cmdletbinding()]
    param(
    )

    $item = $null
    $logfile = $Script:logfile

    # If the variable is not present, it will create a temporary file
    If ( $null -eq $logfile ) {
     
        Write-Verbose -Message "Please setup the logfile with 'Set-Logfile -Path' or it will automatically created as a temporary file." -InformationAction Continue -Verbose
        Write-Verbose -Message "Please setup the process id with 'Set-ProcessId -Id'or it will automatically created as a [GUID]." -InformationAction Continue -Verbose
            
    } else {

        # Testing the path
        If ( ( Test-Path -Path $logfile -IsValid ) -eq $false ) {
            Write-Error -Message "Invalid variable '`$logfile'. The path '$( $logfile )' is invalid."
        } else {
            $item = Get-Item -Path $logfile
        }

    }

    $item

}