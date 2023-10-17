Param(
     $SettingsFile
    #,$TokenSettings
)


#-----------------------------------------------
# IMPORT MODULE AND SETTINGS
#-----------------------------------------------

Import-Module AptecoPSFramework, WriteLog
Import-Settings -Path $SettingsFile

$s = Get-Settings
Set-Logfile -Path $s.logfile

Write-Log "----------------------------------------------------"
Write-Log "CHECK TOKEN" -Severity INFO


#-----------------------------------------------
# VALIDATE
#-----------------------------------------------

try {

    # Check via REST API
    $valid = Get-TokenValidation
    $success = $true

    # Log
    Write-Log "Test was successful"

# Token not valid anymore
} catch {

    # Log
    Write-Log "Test was not successful, closing the script" -Severity ERROR

    # # Mail
    # if ( $settings.sendMailOnFailure ) {
    #     $splattedArguments = @{
    #         "to" = $settings.notificationReceiver
    #         "subject" = "[CLEVERREACH] Token is invalid, please check"
    #         "body" = "Refreshment failed, please check if you can create a valid token"
    #     }
    #     Send-Mail @splattedArguments # note the @ instead of $
    # }

    # Exception
    throw "Test was not successful"

}


#-----------------------------------------------
# TTL
#-----------------------------------------------

$ttl = Get-TokenTimeToLive
Write-Log "Token will expire in $( $ttl.ttl ) seconds"


#-----------------------------------------------
# EXCHANGE TOKEN, IF NEEDED
#-----------------------------------------------

If ( $ttl.ttl -le $s.token.refreshTtl ) {

    # Exchange file
    Save-NewToken

}
