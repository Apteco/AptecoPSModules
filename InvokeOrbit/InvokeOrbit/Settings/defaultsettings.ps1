[PSCustomObject]@{

    # General
    "logfile" = ""
    "encoding" = "utf8"

    # Orbit API settings
    "base" = "https://partner.apteco.io/OrbitAPI/"             # Default url # TODO [ ] remove this url later or exchange
    "fsSystem" = "Demo"
    "psSystem" = "Demo"
    "loadEndpoints" = "ATREQUEST"                           # ATREQUEST|PRELOADLIST|PRELOADALL -> if using PRELOADLIST, please provide a list
    "endpoints" = @("GetVersionDetails", "GetSessionDetails", "GetPeopleStageSystems", "GetPeopleStageSystem", "GetElementStatusForDescendants")

    #logfile="$( $scriptPath )\orbit_api_upload.log"     # path and name of log file

    # security
    "changeTLS" = $true                                   # should tls be changed on the system?
    #sessionFile = "$( $scriptPath )\session.json"       # name of the session file
    "ttl" = 60                                            # Time to live in minutes for the current session
    "encryptToken" = $true                                # $true|$false if the session token should be encrypted

    # login data
    "login" = [PSCustomObject]@{
        "type" = "SIMPLE"                 # SIMPLE|SALTED
        "dataView" = "Demo"
        "user" = "demo"
        "pass" = $passEncrypted 

    }

    # upload settings
    "upload" = [PSCustomObject]@{
        "type" = "MULTIPART" # ONEPART|MULTIPART
    }

    # multipart settings, if needed
    "multipart" = [PSCustomObject]@{
        "noParts" = 3           # How many parts do you want to have? Another todo could be in future to enter fixed 
        "partPrefix" = "part"
        "secondsToWait" = 30
    }


}