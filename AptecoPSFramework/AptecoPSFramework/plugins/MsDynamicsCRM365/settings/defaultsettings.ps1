[PSCustomObject]@{

    # General
    "providername" = "DynamicsDataVerse"

    # API
    "base" = "https://xxx.crm11.dynamics.com"             # will be combined with the account domain
    "apiversion" = "9.2"

    "contentType" = "application/json" #"application/json; charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 500                                        # if paging is used for the API requests, this is the default setting for a pagesize
    #"mailingLimit" = 999
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
        # "notificationReceiver" =  "admin@example.com"
        # "sendMailOnSuccess" =  $false
        # "sendMailOnCheck" =  $false
        # "sendMailOnFailure" =  $false

        # Refreshing task
        "taskDefaultName" =  "Apteco Dynamics365 Token Refresher"
        "dailyTaskSchedule" =  1 # runs every day at 6 local time in the morning
        "refreshTtl" = 604800 # seconds; refresh one week before expiration

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
        "refreshTokenAutomatically" = $true
        "myDomain" = "aptecodach-dev-ed"
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
        #"reservedFields" = [Array]@(,"tags")                # If one of these fields are used, the whole process will pause
        "countRowsInputFile" = $true
        #"validateReceivers" = $true
        #"excludeNotValidReceivers" = $false                 # !!! IMPORTANT SETTING $false allows new records to be uploaded to CleverReach, $true means only activated receivers in CleverReach on that list will be updated and tagged
        #"excludeBounces" = $true
        #"excludeGlobalDeactivated" = $false                 # Excludes receivers, that are deactivated on any list. So if there is a receiver active on any list, but active on the currently used list, it will be excluded, if this setting is $true
        #"excludeLocalDeactivated" = $true
        "uploadSize" = 300                                  # Max no of rows per batch upload call, max of 1000
        #"tagSource" = "Apteco"                              # Prefix of the tag, that will be used automatically, when doing mailings (not tagging)
        #"useTagForUploadOnly" = $true
        #"loadRuntimeStatistics" = $true                     # Loads total, active, inactive, bounced receivers of the group after upserting the data. This loads all receivers on the list, so can need a while and cause many api calls
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

    }

    "preview" = [PSCustomObject]@{

    }

    "responses" = [PSCustomObject]@{

    }

}

