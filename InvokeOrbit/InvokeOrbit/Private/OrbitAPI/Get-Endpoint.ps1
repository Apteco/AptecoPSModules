# Get-Endpoint -Key "CreateLoginParameters"
Function Get-Endpoint{

    param(
        [String]$Key
    )
    
    # Check if the endpoint should be loaded now or is prefetched
    If ( $script:settings.loadEndpoints -eq "SINGLE" ) {
        # TODO [ ] implement this single request
    } else {
        $Script:endpoints | where { $_.name -eq $Key } | Select -first 1
    }


}