# This one filters out valid properties like street and city and then hashes it

function Get-AddressHash {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true, ValueFromPipeline = $true)][PSCustomObject]$Address  # the address to geocode (should include street, city, postalcode, countrycodes)
        ,[Parameter(Mandatory = $false)][String]$ParameterSetName = "search" # get the params for search or reverse
        ,[Parameter(Mandatory = $false)][String]$Salt = ""  # add a salt for the hash, if you wish to
    )

    begin {
    }

    process {

        # Do it alway in the same order of $allowedProperties
        $inputStringToHash = [System.Text.StringBuilder]::new()

        For ( $i = 0; $i -lt $Script:allowedQueryParameters.$ParameterSetName.Count; $i++ ) {
            $propName = $Script:allowedQueryParameters.$ParameterSetName[$i]
            $propValue = $Address.$propName
            If ( $null -ne $propValue ) {
                If ( $inputStringToHash -is [String] ) {
                    [void]$inputStringToHash.Append( $propValue.toLower() )
                } else {
                    [void]$inputStringToHash.Append( $propValue )
                }
            }
        }

        # return
        Get-StringHash -salt $Salt -InputString $inputStringToHash.ToString() -HashName "sha256"

    }

    end {

    }
}