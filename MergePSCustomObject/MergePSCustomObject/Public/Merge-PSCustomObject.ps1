
function Merge-PSCustomObject {


    <#
    .SYNOPSIS
        This function merges two hashtables into one. It uses the "Left" one as the kind of master and extends it with "Right"

    .DESCRIPTION
        Apteco PS Modules - PowerShell merge PSCustomObject

        The function uses the "Left" one as the kind of master and extends it with "Right"
        This runs recursively through the PSCustomObject and merges all values
        By default, properties in "Left" get overwritten, but with the flag "AddPropertiesFromRight"
        it also adds properties from the right one
        add the -verbose flag if you want to know more whats about to happen

    .PARAMETER Left
        Master PSCustomObject that is the base and where values are getting replaced from right

    .PARAMETER Right
        Those values will be added into the left one

    .PARAMETER AddKeysFromRight
        Add properties from right to left, otherwise not matching keys from right will be ignored

    .PARAMETER MergePSCustomObjects
        PSCustomObjects with the same name would be overwritten by default. Use this flag to merge them

    .PARAMETER MergeArrays
        Array with the same name would be overwritten by default. Use this flag to merge them

    .PARAMETER MergeHashtables
        Hashtables with the same name would be overwritten by default. Use this flag to merge them

    .EXAMPLE
        $left = [PSCustomObject]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
        }

        $right = [PSCustomObject]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
        }

        Merge-PSCustomObject -Left $left -right $right

        results to

        firstname lastname
        --------- --------
        Florian   von Bracht

        So it replaces all values on left with the ones from right

    .EXAMPLE
        $left = [PSCustomObject]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
        }

        $right = [PSCustomObject]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
        }

        Merge-PSCustomObject -Left $left -right $right -AddPropertiesFromRight

        results to

        firstname Street          lastname
        --------- ------          --------
        Florian   Schaumainkai 87 von Bracht

        So it adds properties from right to left that are not existing in left

    .EXAMPLE
        $left = [PSCustomObject]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
            "address" = [PSCustomObject]@{
                "Street" = "Schaumainkai 87"
            }
        }

        $right = [PSCustomObject]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
            "address" = [PSCustomObject]@{
                "Postcode" = 60596
            }
        }

        Merge-PSCustomObject -Left $left -right $right

        results to

        firstname lastname   address
        --------- --------   -------
        Florian   von Bracht @{Postcode=60596}


        So it replaces the PSCustomObject from left with the one from right.
        Using the `-MergeHashtables` flag will merge the child PSCustomObject as well

    .EXAMPLE
        $left = [PSCustomObject]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
            "address" = [PSCustomObject]@{
                "Street" = "Schaumainkai 87"
            }
        }

        $right = [PSCustomObject]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
            "address" = [PSCustomObject]@{
                "Street" = "Kaiserstraße 35"
                "Postcode" = 60596
            }
        }

        Merge-PSCustomObject -Left $left -right $right -MergePSCustomObjects

        So it replaces the also nested PSCustomObjects from left with the one from right.
        Using the `-AddPropertiesFromRight` flag will add properties from right to left, also in nested PSCustomObjects

        It results to

        firstname lastname   address
        --------- --------   -------
        Florian   von Bracht @{Street=Kaiserstraße 35}

    .EXAMPLE
        $left = [PSCustomObject]@{
            "firstname" = "Florian"
            "lastname" = "Friedrichs"
            "address" = [PSCustomObject]@{
                "Street" = "Schaumainkai 87"
            }
        }

        $right = [PSCustomObject]@{
            "lastname" = "von Bracht"
            "Street" = "Schaumainkai 87"
            "address" = [PSCustomObject]@{
                "Street" = "Kaiserstraße 35"
                "Postcode" = 60596
            }
        }

        Merge-PSCustomObject -Left $left -right $right -MergePSCustomObjects -AddPropertiesFromRight


        will result to

        firstname Street          lastname   address
        --------- ------          --------   -------
        Florian   Schaumainkai 87 von Bracht @{Postcode=60596; Street=Kaiserstraße 35}

    .INPUTS
        PSCustomObject

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
         [Parameter(Mandatory=$true,ValueFromPipeline)][PSCustomObject]$Left
        ,[Parameter(Mandatory=$true)][PSCustomObject]$Right
        ,[Parameter(Mandatory=$false)][Switch]$AddPropertiesFromRight = $false
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
        $joined = [PSCustomObject]@{}

        # Go through the left object
        If ( $Left -is [PSCustomObject] ) {

            # Read all properties
            $leftProps = $Left.PsObject.Properties.name
            $rightProps = $Right.PsObject.Properties.name

            # Compare
            $compare = Compare-Object -ReferenceObject $leftProps -DifferenceObject $rightProps -IncludeEqual

            # Go through all properties
            $compare | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object {
                $propLeft = $_.InputObject
                $joined | Add-Member -MemberType NoteProperty -Name $propLeft -Value $Left.($propLeft)
                Write-Verbose "Add '$( $propLeft )' from left side"
            }

            # Now check if we can add more properties
            If ( $AddPropertiesFromRight -eq $true ) {
                $compare | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object {
                    $propRight = $_.InputObject
                    $joined | Add-Member -MemberType NoteProperty -Name $propRight -Value $Right.($propRight)
                    Write-Verbose "Add '$( $propRight )' from right side"
                }
            }

            # Now overwrite existing values or check to go deeper if needed
            $compare | Where-Object { $_.SideIndicator -eq "==" } | ForEach-Object {

                $propEqual = $_.InputObject

                If ( $MergePSCustomObjects -eq $true -and $Left.($propEqual) -is [PSCustomObject] -and $Right.($propEqual) -is [PSCustomObject] -and @( $Right.($propEqual).psobject.properties ).Count -gt 0 ) {

                    Write-Verbose "Going recursively into '$( $propEqual )'"

                    # Recursively call this function, if it is nested ps custom
                    $params = [Hashtable]@{
                        "Left" = $Left.($propEqual)
                        "Right" = $Right.($propEqual)
                        "AddPropertiesFromRight" = $AddPropertiesFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Merge-PSCustomObject @params
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $recursive

                } elseif ( $MergeArrays -eq $true -and $Left.($propEqual) -is [Array] -and $Right.($propEqual) -is [Array] ) {

                    Write-Verbose "Merging arrays from '$( $propEqual )'"

                    # Merge array
                    $newArr = [Array]@( $Left.($propEqual) + $Right.($propEqual) ) | Sort-Object -unique
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $newArr

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
                        "AddKeysFromRight" = $AddPropertiesFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Merge-Hashtable @params
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $recursive

                } else {

                    # just overwrite existing values if datatypes of attribute are different or no merging is wished
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $Right.($propEqual)
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

