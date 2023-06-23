[PSCustomObject]@{

    # General
    "providername" = "PSCleverReach"

    # API
    "base" = "https://rest.cleverreach.com/v3/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json; charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 500                                        # if paging is used for the API requests, this is the default setting for a pagesize
    "mailingLimit" = 999
    "additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod
    "logAPIrequests" = $true                                # log information like 'GET https://rest.cleverreach.com:443/v3/groups.json/1158984/stats'
    
    # Token refreshment
    "token" = [PSCustomObject]@{

        # Email notifications
        "notificationReceiver" =  "admin@example.com"
        "sendMailOnSuccess" =  $false
        "sendMailOnCheck" =  $false
        "sendMailOnFailure" =  $false

        # Refreshing task
        "taskDefaultName" =  "Apteco CleverReach Token Refresher"
        "dailyTaskSchedule" =  6
        

        #"tokenfile" =  "C:\Test\cr.token"
        #"createTokenFile" = $true

        # Not implemented yet, but settings for the token file        
        "exportTokenToFile" = $true                         # only used, if the token usage is on 'generate'
        "tokenUsage" = "consume"                            # consume|generate -> please have only one setting where you generate the token
        "encryptTokenFile" = $false                         # only used, if the token usage is on 'generate', when 'consume' then the tokenfile will be decrypted
                                                            # be careful, that the encryption is user dependent so cannot be shared between multiple users
        "tokenFilePath" = ""                             # path for the file that should be consumed or generated

    }

    # API Authentication 
    "login" = [PSCustomObject]@{
        "refreshTtl" = 604800                               # 7 days in seconds
        "refreshtoken" = ""
        "accesstoken" = ""
        "refreshTokenAutomatically" = $true
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
        "reservedFields" = [Array]@(,"tags")                       # If one of these fields are used, the whole process will pause
        "countRowsInputFile" = $true
        "validateReceivers" = $true
        "excludeNotValidReceivers" = $false
        "excludeBounces" = $true
        "excludeGlobalDeactivated" = $true
        "excludeLocalDeactivated" = $true
        "uploadSize" = 3                                  # Max no of rows per batch upload call, max of 1000
        "tagSource" = "Apteco"                              # Prefix of the tag, that will be used automatically, when doing mailings (not tagging)
        "useTagForUploadOnly" = $true
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{
        
        # Settings for the copy of the mailing
        "defaultContentType" = "html/text"                             # "html", "text" or "html/text"
        "defaultEditor" = "wizard"
        "defaultOpenTracking" = $true
        "defaultClickTracking" = $true

        # Release/sending
        "defaultReleaseOffset" = 120                        # Default amount of seconds that are added to the current unix timestamp to release the mailing

    }

    "preview" =  [PSCustomObject]@{
        "previewGroupName" = "Apteco_Preview"
    }

}