
# TODO Exchange this function with the officially published module

<#

# Example creates something like
# VrmpwjSjKEADWe+rv4CF+KrZ
Get-RandomString -length 24


Get-RandomString -length 10
RMUyX+s40r

Get-RandomString -length 32 -ExcludeSpecialChars -ExcludeNumbers -ExcludeLowerCase
EQUETZHJSZFEDSXDPYXHENURRVJSYZXS

Get-RandomString -length 32 -ExcludeSpecialChars -ExcludeNumbers -ExcludeLowerCase -ExcludeUpperCase -AllowedCharacters @("a","b","c","*")
ccbcbb*c*acabcccbbccacbc*a***baa

#>

Function Get-RandomString() {

    <#
    .SYNOPSIS
        Create a random string with a defined length. You can include/exclude different character sets and characters.

    .DESCRIPTION
        Apteco PS Modules - Create a random string

        The random string will automatically be created with a mixture of
        numbers "0", "1", "2", "3", "4", "5", "6", "8", "9"
        lowercase "a", "b", "c", "d", "e", "f", "g", "h", "j", "k", "m", "n", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
        uppercase "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
        and special characters "*", "#", "=", "-", "+", "|", "~"

        You can exclude the different sets individually like with -ExcludeSpecialChars

        With the parameter -AllowedCharacters you can define an array with only valid characters, so only they will be used to
        create the random string.

    .PARAMETER Length
        Amount of characters you want to get as final string

    .PARAMETER AllowedCharacters
        Additionally allowed characters - if you want to only have those characters, do it like
        Get-RandomString -length 32 -ExcludeSpecialChars -ExcludeNumbers -ExcludeLowerCase -ExcludeUpperCase -AllowedCharacters @("a","b","c","*")

    .PARAMETER ExcludeNumbers
        Exclude numbers from the final string

    .PARAMETER ExcludeLowerCase
        Exclude lower characters from the final string

    .PARAMETER ExcludeUpperCase
        Exclude UPPER characters from the final string

    .PARAMETER ExcludeSpecialChars
        Exclude special characters from the final string

    .EXAMPLE
        Get-RandomString -length 24

    .EXAMPLE
        Get-RandomString -length 32 -ExcludeSpecialChars -ExcludeNumbers -ExcludeLowerCase

    .EXAMPLE
        Get-RandomString -length 32 -AllowedCharacters @("a","b","c","*")

    .EXAMPLE
        Get-RandomString -length 32 -ExcludeSpecialChars -ExcludeNumbers -ExcludeLowerCase -ExcludeUpperCase -AllowedCharacters @("a","b","c","*")

    .EXAMPLE
        10,20 | Get-RandomString

    .EXAMPLE
        1..10 | Get-RandomString

    .EXAMPLE
        1..10 | % { Get-RandomString -length 20 }

    .INPUTS
        int

    .OUTPUTS
        String

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [cmdletbinding()]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)][int]$Length
        ,[Parameter(Mandatory=$false)][String[]]$AllowedCharacters = [String]@()
        ,[Parameter(Mandatory=$false)][Switch]$ExcludeNumbers
        ,[Parameter(Mandatory=$false)][Switch]$ExcludeLowerCase
        ,[Parameter(Mandatory=$false)][Switch]$ExcludeUpperCase
        ,[Parameter(Mandatory=$false)][Switch]$ExcludeSpecialChars
    )

    begin {

        # Add characters to use

        $chars = [Array]@()

        $chars += $AllowedCharacters

        If ( $ExcludeNumbers -eq $false ) {
            $chars += @("0", "1", "2", "3", "4", "5", "6", "8", "9")
        }

        If ( $ExcludeLowerCase -eq $false ) {
            $chars += @("a", "b", "c", "d", "e", "f", "g", "h", "j", "k", "m", "n", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z")
        }

        If ( $ExcludeUpperCase -eq $false ) {
            $chars += @("A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")
        }

        If ( $ExcludeSpecialChars -eq $false ) {
            $chars += @("*", "#","=","-","+","|","~")
        }

        If ( $chars.Count -eq 0 ) {
            Write-Warning -Message "No characters left for Generation of RandomString"
        }

    }

    process {

        # Create a new random variable
        $random = [Random]::new()

        # Put the string together
        $stringBuilder = [System.Text.StringBuilder]::new($Length)
        for ($i = 0; $i -lt $Length; $i++) {
            [void]$stringBuilder.Append( $chars[$random.Next($chars.Length)] )
        }

        #return
        return $stringBuilder.ToString()

    }


}
