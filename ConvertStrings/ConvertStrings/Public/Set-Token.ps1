<#

New string function to replace multiple strings in a string. Multiple replacements can be defined as a hashtable with the string to replace a key and value as the replacement

$string = "Hello, this is a #PLACEHOLDER1# great world to #VERB#"

$ht = [hashtable]@{
    "#PLACEHOLDER1#" = "really"
    "#VERB#" = "live"
}

Set-Token -InputString $string -Replacements $ht

# Hello, this is a really great world to live


#>

Function Set-Token {

    param(
         [Parameter(Mandatory=$true)][array]$InputString
        ,[Parameter(Mandatory=$true)][Hashtable]$Replacements
    )

    Process {

        $newString = $InputString

        $Replacements.Keys | ForEach-Object {
            $key = $_
            $newString = $newString -replace $key, $Replacements.$key
        }

        # Return
        return $newString

    }

}