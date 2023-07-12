
# TODO Put this into separate module and publish it

# The function uses the "Left" one as the kind of master and extends it with "Right"
# By default, keys in "Left" get overwritten, but with the flag "AddKeysFromRight"
# it also adds key from the right one
# add the -verbose flag if you want to know more whats about to happen
function Join-Hashtable {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true,ValueFromPipeline)][PSCustomObject]$Left
        ,[Parameter(Mandatory=$true)][PSCustomObject]$Right
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
            $compare | where { $_.SideIndicator -eq "<=" } | ForEach-Object {
                $propLeft = $_.InputObject
                $joined.Add($propLeft, $Left.($propLeft))
                Write-Verbose "Add '$( $propLeft )' from left side"
            }

            # Now check if we can add more properties
            If ( $AddKeysFromRight -eq $true ) {
                $compare | where { $_.SideIndicator -eq "=>" } | ForEach-Object {
                    $propRight = $_.InputObject
                    $joined.Add($propRight, $Right.($propRight))
                    Write-Verbose "Add '$( $propRight )' from right side"
                }
                
            }

            # Now overwrite existing values or check to go deeper if needed
            $compare | where { $_.SideIndicator -eq "==" } | ForEach-Object {

                $propEqual = $_.InputObject

                If ( $MergePSCustomObjects -eq $true -and $Left.($propEqual) -is [PSCustomObject] -and $Right.($propEqual) -is [PSCustomObject] -and @( $Right.($propEqual).psobject.properties ).Count -gt 0) {

                    Write-Verbose "Going recursively into '$( $propEqual )'"

                    # Recursively call this function, if it is nested ps custom
                    $params = [Hashtable]@{
                        "Left" = $Left.($propEqual)
                        "Right" = $Right.($propEqual)
                        "AddPropertiesFromRight" = $AddKeysFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Join-PSCustomObject @params
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

                    # Recursively call this function, if it is nested hashtable
                    $params = [Hashtable]@{
                        "Left" = $Left.($propEqual)
                        "Right" = $Right.($propEqual)
                        "AddKeysFromRight" = $AddKeysFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Join-Hashtable @params
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


#-----------------------------------------------
# TESTING HASHTABLES
#-----------------------------------------------
<#
$leftHt = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
}

$rightHt = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
}

Join-Hashtable -Left $leftHt -right $rightHt -verbose -AddKeysFromRight
#>
