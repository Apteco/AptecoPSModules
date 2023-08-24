# TODO please be aware, that the join-object function does not support $null yet

[PSCustomObject]@{

    # General
    "logfile" = ""
    "encoding" = "utf8"
    "currentDate" = [datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss")

    # Network and Security
    "changeTLS" = $true                                     # change TLS automatically to a newer version
    "allowedProtocols" = @(,"Tls12")                        # Protocols that should be used like Tls12, Tls13, SSL3
    "keyfile" = ""                                          # Define a path in here, if you use another keyfile for https://www.powershellgallery.com/packages/EncryptCredential/0.0.2

    # PowerShell
    "powershellExePath" =  "powershell.exe"                 # Could be changed to something like pwsh.exe for the scheduled task of refreshing token and response gathering

    # general settings
    "base" = "https://nominatim.openstreetmap.org"
    "sqliteDB" = ""
    "connectionString" = "Data Source=datasource;Initial Catalog=database;Trusted_Connection=True;" #\SQL-P-APTECO
    "countRowsInputFile" = $true

    # OSM specific
    "resultsLanguage" = "de"      # provide country code for the language of the results
    "useragent" = "AptecoCustomerXXX"
    "millisecondsPerRequest" = 1000

    # field mapping
    "map" = [PSCustomObject]@{
        "street" = "Strasse2"
        "city" = "Ort"
        "postalcode" = "PLZ"
        #countrycode = ""
    }

    # csv settings
    "delimiter" = "`t"
    "qualifier" = ""        # not implemented yet
    #"encoding" = "utf8"

}