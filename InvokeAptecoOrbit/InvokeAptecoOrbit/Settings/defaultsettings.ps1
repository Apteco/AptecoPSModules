@{

    # General
    "encoding" = "utf8"

    # Orbit API
    "base"     = "https://partner.apteco.io/OrbitAPI/"   # Default base url, override via Connect-AptecoOrbit -BaseUrl
    "dataView" = ""                                       # Filled in by Connect-AptecoOrbit
    "loginType" = "SIMPLE"                                 # SIMPLE is currently supported; SALTED is not implemented yet
    "pageSize" = 100                                      # Default page size for paged downloads

    # Session handling
    "sessionFile"  = ( Join-Path -Path ( [System.IO.Path]::GetTempPath() ) -ChildPath "invokeaptecoorbit_session.json" )
    "ttl"          = 60                                   # Session time to live in minutes
    "encryptToken" = $true                                # Encrypt the session token at rest via EncryptCredential

    # Network and Security
    "changeTLS"        = $true
    "allowedProtocols" = @("Tls12","Tls13")

}
