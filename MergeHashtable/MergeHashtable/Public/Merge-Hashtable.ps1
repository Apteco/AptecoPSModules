

function Merge-Hashtable {

    <#
    .SYNOPSIS
        This function merges two hashtables into one. It uses the "Left" one as the kind of master and extends it with "Right"

    .DESCRIPTION
        Apteco PS Modules - PowerShell merge hashtables

        The function uses the "Left" one as the kind of master and extends it with "Right"
        This runs recursively through the hashtable and merges all values
        By default, keys in "Left" get overwritten, but with the flag "AddKeysFromRight"
        it also adds key from the right one
        add the -verbose flag if you want to know more whats about to happen

        Caution:
        This module is not an ordered dictionary so it will not preserve the correct order.
        You are invited to extend the module via pull request if you would like this functionality ;-)

    .PARAMETER Left
        Master Hashtable that is the base and where values are getting replaced from right

    .PARAMETER Right
        Those values will be added into the left one

    .PARAMETER AddKeysFromRight
        Add key from right to left, otherwise not matching keys from right will be ignored

    .PARAMETER MergePSCustomObjects
        PSCustomObjects with the same name would be overwritten by default. Use this flag to merge them

    .PARAMETER MergeArrays
        Array with the same name would be overwritten by default. Use this flag to merge them

    .PARAMETER MergeHashtables
        Hashtables with the same name would be overwritten by default. Use this flag to merge them

    .EXAMPLE

        $left = [hashtable]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
        }

        $right = [hashtable]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
        }

        Merge-Hashtable -Left $left -right $right

        results to

        Name                           Value
        ----                           -----
        lastname                       von Bracht
        firstname                      Florian

        So it replaces all values on left with the ones from right

    .EXAMPLE
        $left = [hashtable]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
        }

        $right = [hashtable]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
        }

        Merge-Hashtable -Left $left -right $right -AddKeysFromRight

        results to

        Name                           Value
        ----                           -----
        Street                         Schaumainkai 87
        lastname                       von Bracht
        firstname                      Florian

        So it adds key from right to left that are not existing in left

    .EXAMPLE
        $left = [hashtable]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
            "address" = [hashtable]@{
                "Street" = "Schaumainkai 87"
            }
        }

        $right = [hashtable]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
            "address" = [hashtable]@{
                "Postcode" = 60596
            }
        }

        Merge-Hashtable -Left $left -right $right

        results to

        Name                           Value
        ----                           -----
        lastname                       von Bracht
        address                        {[Postcode, 60596]}
        firstname                      Florian

        So it replaces the hashtable from left with the one from right. Using the -MergeHashtables flag will merge
        the child hashtables as well

    .EXAMPLE
        $left = [hashtable]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
            "address" = [hashtable]@{
                "Street" = "Schaumainkai 87"
            }
        }

        $right = [hashtable]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
            "address" = [hashtable]@{
                "Street" = "Kaiserstraße 35"
                "Postcode" = 60596
            }
        }

        $h = Merge-Hashtable -Left $left -right $right -MergeHashtables

        So it replaces the also nested hashtables from left with the one from right. Using the -AddKeysFromRight flag will
        add keys from right to left, also in nested hashtables

        It results to

        Name                           Value
        ----                           -----
        lastname                       von Bracht
        address                        {[Street, Kaiserstraße 35]}
        firstname                      Florian

    .EXAMPLE
        $left = [hashtable]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
            "address" = [hashtable]@{
                "Street" = "Schaumainkai 87"
            }
        }

        $right = [hashtable]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
            "address" = [hashtable]@{
                "Street" = "Kaiserstraße 35"
                "Postcode" = 60596
            }
        }

        Merge-Hashtable -Left $left -right $right -MergeHashtables -AddKeysFromRight

        will result to

        Name                           Value
        ----                           -----
        Street                         Schaumainkai 87
        lastname                       von Bracht
        address                        {[Postcode, 60596], [Street, Kaiserstraße 35]}
        firstname                      Florian

    .INPUTS
        Hashtable

    .OUTPUTS
        Hashtable

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>


    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
         [Parameter(Mandatory=$true,ValueFromPipeline)][hashtable]$Left
        ,[Parameter(Mandatory=$true)][hashtable]$Right
        ,[Parameter(Mandatory=$false)][Switch]$AddKeysFromRight = $false
        ,[Parameter(Mandatory=$false)][Switch]$MergePSCustomObjects = $false
        ,[Parameter(Mandatory=$false)][Switch]$MergeArrays = $false
        ,[Parameter(Mandatory=$false)][Switch]$MergeHashtables = $false
    )

    begin {

        if ( $null -eq $Left ) {
            # return
            return $null
        }

        if ( $null -eq $Right ) {
            # return
            Write-Warning "-Right is null!"
        }

    }

    process {

        # Create an empty object
        $joined = [Hashtable]@{}

        # Go through the left object
        If ( $Left -is [hashtable] ) {

            # Read all properties
            $leftProps = @( $Left.Keys )
            $rightProps = @( $Right.Keys )

            # Compare
            $compare = Compare-Object -ReferenceObject $leftProps -DifferenceObject $rightProps -IncludeEqual

            # Go through all properties
            $compare | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object {
                $propLeft = $_.InputObject
                $joined.Add($propLeft, $Left.($propLeft))
                Write-Verbose "Add '$( $propLeft )' from left side"
            }

            # Now check if we can add more properties
            If ( $AddKeysFromRight -eq $true ) {
                $compare | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object {
                    $propRight = $_.InputObject
                    $joined.Add($propRight, $Right.($propRight))
                    Write-Verbose "Add '$( $propRight )' from right side"
                }

            }

            # Now overwrite existing values or check to go deeper if needed
            $compare | Where-Object { $_.SideIndicator -eq "==" } | ForEach-Object {

                $propEqual = $_.InputObject

                If ( $MergePSCustomObjects -eq $true -and ( $Left.($propEqual) -is [PSCustomObject] -or $Left.($propEqual) -is [System.Collections.Specialized.OrderedDictionary] ) -and ( $Right.($propEqual) -is [PSCustomObject] -or $Right.($propEqual) -is [System.Collections.Specialized.OrderedDictionary] ) -and $Right.($propEqual).Keys.Count -gt 0 ) {

                    Write-Verbose "Going recursively into '$( $propEqual )'"

                    # Check if we have all dependencies installed
                    If (( Get-InstalledModule | Where-Object { $_.Name -eq "MergePSCustomObject" } ).count -eq 0 )
                    {
                        Write-Warning "You need to install the module 'MergePSCustomObject' to use this feature"
                        Write-Warning "Install-Module -Name MergePSCustomObject"
                        Write-Warning "https://www.powershellgallery.com/packages/MergePSCustomObject"
                        throw "Please install 'MergePSCustomObject'"
                    }

                    # Recursively call this function, if it is nested ps custom
                    $params = [Hashtable]@{
                        "Left" = [PSCustomObject]( $Left.($propEqual) )
                        "Right" = [PSCustomObject]( $Right.($propEqual) )
                        "AddPropertiesFromRight" = $AddKeysFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Merge-PSCustomObject @params
                    $joined.Add($propEqual, $recursive)


                } elseif ( $MergeArrays -eq $true -and $Left.($propEqual) -is [Array] -and $Right.($propEqual) -is [Array] ) {

                    Write-Verbose "Merging arrays from '$( $propEqual )'"

                    # Merge array
                    $newArr = [Array]@( $Left.($propEqual) + $Right.($propEqual) ) | Sort-Object -unique
                    $joined.Add($propEqual, $newArr)

                } elseif ( $MergeArrays -eq $true -and $Left.($propEqual) -is [System.Collections.ArrayList] -and $Right.($propEqual) -is [System.Collections.ArrayList] ) {

                    Write-Verbose "Merging arraylists from '$( $propEqual )'"

                    # Merge arraylist
                    $newArr = [System.Collections.ArrayList]@()
                    $newArr.AddRange($Left.($propEqual))
                    $newArr.AddRange($Right.($propEqual))
                    $newArrSorted = [System.Collections.ArrayList]@( $newArr | Sort-Object -Unique )
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $newArrSorted

                } elseif ( $MergeHashtables -eq $true -and $Left.($propEqual) -is [hashtable] -and $Right.($propEqual) -is [hashtable] -and @( $Right.($propEqual).Keys ).Count -gt 0) {

                    Write-Verbose "Merging hashtables from '$( $propEqual )'"

                    # Recursively call this function, if it is nested hashtable
                    $params = [Hashtable]@{
                        "Left" = $Left.($propEqual)
                        "Right" = $Right.($propEqual)
                        "AddKeysFromRight" = $AddKeysFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Merge-Hashtable @params
                    $joined.Add($propEqual, $recursive)

                } else {

                    # just overwrite existing values if datatypes of attribute are different or no merging is wished
                    $joined.Add($propEqual, $Right.($propEqual))
                    Write-Verbose "Overwrite '$( $propEqual )' with value from right side"
                    #Write-Verbose "Datatypes of '$( $propEqual )' are not the same on left and right"

                }


            }

        }

        # return
        $joined

    }

    end {

    }
}
