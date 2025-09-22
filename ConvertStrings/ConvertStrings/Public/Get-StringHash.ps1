<#

This is a way of hashing strings
Please be aware, that algorithms like HMAC need a key that
The hashing algorithm should be in this class System.Security.Cryptography

# examples

# This results in 872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4
Get-StringHash -inputString "HelloWorld" -hashName "SHA256"

# This results in b9e217df88dc1bc96c1e69e1b09a798d6efe0ef69cd3511e7f4becd319fe6036
Get-StringHash -inputString "HelloWorld" -hashName "HMACSHA256" -key "GoGoGo"


#>
Function Get-StringHash {

    [cmdletbinding()]
    param(
         [Parameter(Mandatory=$true)][String]$InputString
        ,[Parameter(Mandatory=$true)][String]$HashName
        ,[Parameter(Mandatory=$false)][String]$Salt = ""
        ,[Parameter(Mandatory=$false)][String]$Key = ""
        ,[Parameter(Mandatory=$false)][switch]$Uppercase = $false
        ,[Parameter(Mandatory=$false)][switch]$KeyIsHex = $false
        ,[Parameter(Mandatory=$false)][switch]$ReturnBytes = $false
    )

    Begin {

        # Choose algorithm: https://learn.microsoft.com/de-de/dotnet/api/system.security.cryptography.hashalgorithm.create?view=net-7.0
        $alg = [System.Security.Cryptography.HashAlgorithm]::Create($HashName)

        # Change key, e.g. for HMACSHA256
        if ( $Key -ne "" ) {
            if ( $KeyIsHex ) {
                $alg.key = Convert-HexToByteArray -HexString $key
            } else {
                $alg.key = [Text.Encoding]::UTF8.GetBytes($key)
            }
        }

    }

    Process {

        #-----------------------------------------------
        # GENERATE BYTES HASH
        #-----------------------------------------------

        # Add salt if needed
        $string = $InputString + $Salt

        $bytes = $alg.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($string))


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        if ( $ReturnBytes -eq $true ) {

            $bytes

        } else {

            # Create bytes from string and hash
            $res = Convert-ByteArrayToHex -ByteArray $bytes

            # Transform uppercase, if needed, and return the result
            if ( $Uppercase ) {
                $res.ToUpper()
            } else {
                $res
            }

        }


    }

}


