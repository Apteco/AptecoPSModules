# TODO please be aware, that the join-object function does not support $null yet

[PSCustomObject]@{

    # General
    "logfile" = ""
    "encoding" = "utf8"
    "nameConcatChar" = " ~ "
    "currentDate" = [datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss")

    # Chosen plugin
    "plugin" = [PSCustomObject]@{                           # This will be filled with the plugin that you need to choose
        "guid" = ""                                         # The guid of the plugin that will be used with this settings file
        "name" = ""
        "version" = "0.0.1"
        "lastUpdate" = "2023-06-15"
    }
    "pluginFolders" = [Array]@()                            # Default folders that should been loaded to look for plugins

    # Network and Security
    "changeTLS" = $true                                     # change TLS automatically to a newer version
    "allowedProtocols" = @(,"Tls12")                        # Protocols that should be used like Tls12, Tls13, SSL3
    "keyfile" = ""                                          # Define a path in here, if you use another keyfile for https://www.powershellgallery.com/packages/EncryptCredential/0.0.2

    # PowerShell
    "powershellExePath" =  "powershell.exe"                 # Could be changed to something like pwsh.exe for the scheduled task of refreshing token and response gathering


}