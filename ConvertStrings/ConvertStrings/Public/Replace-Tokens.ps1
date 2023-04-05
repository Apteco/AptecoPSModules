
<#
New string function to replace multiple strings in a string. Multiple replacements can be defined as a hashtable with the string to replace a key and value as the replacement
#>

Function Set-Tokens {
    
    param(
         [Parameter(Mandatory=$true)][array]$InputString
        ,[Parameter(Mandatory=$true)][Hashtable]$Replacements
    )

    Process {
        
        $newString = $InputString

        $Replacements.Keys | ForEach {
            $key = $_
            $newString = $newString -replace $key, $Replacements.$key
        }

        # Return
        return $newString
        
    }

}