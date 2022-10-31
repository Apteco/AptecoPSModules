Function Get-Logfile {

    [cmdletbinding()]
    param(
       
    )

    $item = $null
    $logfile = $Script:logfile

    # If the variable is not present, it will create a temporary file
    If ( $null -eq $logfile ) {
     
        Write-Warning -Message "There is no variable '`$logfile' present on 'Script' scope"
        Write-Warning -Message "Please define a path with 'Set-Logfile' or use 'Write-Log' once"
    
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