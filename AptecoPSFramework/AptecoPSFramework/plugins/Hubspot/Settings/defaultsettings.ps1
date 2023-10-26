[PSCustomObject]@{

    # General
    "providername" = "PSHubspot"

    # API
    "base" = "https://api.hubapi.com/"                      # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json; charset=utf-8"                      # content type string that is always used for API requests
    "apiversion" = "3"
    "pageSize" = 100                                        # if paging is used for the API requests, this is the default setting for a pagesize
    "mailingLimit" = 999
    "additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod
    "logAPIrequests" = $true                                # log information like 'GET https://rest.cleverreach.com:443/v3/groups.json/1158984/stats'

    # Error handling
    "errorhandling" = [PSCustomObject]@{

        # Delay, if a problem happens and will be repeated
        "HttpErrorDelay" = 10000 # wait ten seconds to let the limits fill up againg

        # Specific http errors and their settings
        "RepeatOnHttpErrors" = [Array]@(502,429)
        "MaximumRetriesOnHttpErrorList" = 3

        # Generic errors like 404 that are not on the specific list
        "MaximumRetriesGeneric" = 1

    }

    # Token refreshment
    "token" = [PSCustomObject]@{

        # Email notifications
        #"notificationReceiver" =  "admin@example.com"
        #"sendMailOnSuccess" =  $false
        #"sendMailOnCheck" =  $false
        #"sendMailOnFailure" =  $false

        # Refreshing task
        "taskDefaultName" =  "Apteco Hubspot Token Refresher"
        #"dailyTaskSchedule" =  6 # runs every day at 6 local time in the morning
        #"refreshTtl" = 604800 # seconds; refresh one week before expiration

        # Process to use for refresh task
        "powershellExePath" = "powershell.exe" # e.g. use pwsh.exe for PowerShell7

        #"tokenfile" =  "C:\Test\cr.token"
        #"createTokenFile" = $true
        "tokenSettingsFile" = "" # Path for the settings file that contains important information about the token creation and refreshing

        # Not implemented yet, but settings for the token file
        "exportTokenToFile" = $true                         # only used, if the token usage is on 'generate'
        "tokenUsage" = "consume"                            # consume|generate -> please have only one setting where you generate the token
        "encryptTokenFile" = $false                         # only used, if the token usage is on 'generate', when 'consume' then the tokenfile will be decrypted
                                                            # be careful, that the encryption is user dependent so cannot be shared between multiple users
        "tokenFilePath" = ""                                # path for the file containing the token that should be consumed or generated
    }

    # API Authentication
    "login" = [PSCustomObject]@{
        #"refreshTtl" = 604800                               # 7 days in seconds
        "refreshtoken" = ""
        "accesstoken" = ""
        #"refreshTokenAutomatically" = $true
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
        "countRowsInputFile" = $true
        "uploadSize" = 300                                  # Max no of rows per batch upload call, max of 1000
        "options" = [Array]@(
            [PSCustomObject]@{
                "key" = "add"
                "label" = "Add to a list"
            }
            [PSCustomObject]@{
                "key" = "del"
                "label" = "Remove from a list"
            }
        )
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{
    }

    "preview" = [PSCustomObject]@{
    }

}

