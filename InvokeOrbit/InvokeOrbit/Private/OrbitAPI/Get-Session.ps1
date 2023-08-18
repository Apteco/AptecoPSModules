Function Get-AptecoSession {

    $sessionPath = "$( $settings.sessionFile )"
    
    # if file exists -> read it and check ttl
    $createNewSession = $true
    if ( (Test-Path -Path $sessionPath) -eq $true ) {

        $sessionContent = Get-Content -Encoding UTF8 -Path $sessionPath | ConvertFrom-Json
        
        $expire = [datetime]::ParseExact($sessionContent.expire,"yyyyMMddHHmmss",[CultureInfo]::InvariantCulture)

        if ( $expire -gt [datetime]::Now ) {

            $createNewSession = $false
            $Script:sessionId = $sessionContent.sessionId
            $Script:accessToken = $sessionContent.accessToken

        }

        If ( $Script:endpoints -eq $null ) {
            Get-Endpoints
        }

    }
    
    # file does not exist or date is not valid -> create session
    if ( $createNewSession -eq $true ) {
        
       Create-AptecoSession
        
    }

}