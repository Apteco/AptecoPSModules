BeforeAll {
    # Import the module
    Import-Module $PSScriptRoot/../"MergePSCustomObject" -Force

    # Sibling module needed for the -MergeHashtables recursion tests further down
    if ( -not ( Get-Module -ListAvailable -Name "MergeHashtable" ) ) {
        Install-Module -Name MergeHashtable -Force -Scope CurrentUser -Repository PSGallery
    }
    Import-Module MergeHashtable -Force

    # From https://stackoverflow.com/questions/50870891/how-to-compare-two-arrays-with-custom-objects-in-pester
    # Changed to send back the difference
    Function Should-BeObject {
        Param (
            [Parameter(Position=0)][Object[]]$b, [Parameter(ValueFromPipeLine = $True)][Object[]]$a
        )
        $Property = ($a | Select-Object -First 1).PSObject.Properties | Select-Object -Expand Name
        $Difference = Compare-Object $b $a -Property $Property
        "$($Difference | Select-Object -First 1)" #| Should -BeNullOrEmpty
    }

}

Describe 'Merge-PSCustomObject' {

    Context 'No extra flags with minimal input parameter' {

        It 'Plain objects without nesting and other datatypes and flags' {

            $left = [PSCustomObject]@{
                "firstname" = "Florian"
                "lastname" = "Friedrichs"
            }

            $right = [PSCustomObject]@{
                "lastname" = "von Bracht"
                "Street" = "Schaumainkai 87"
            }

            $expectedResult = [PSCustomObject]@{
                "firstname" = "Florian"
                "lastname" = "von Bracht"
            }

            $result = Merge-PSCustomObject -Left $left -right $right

            $result | Should-BeObject $expectedResult | Should -BeNullOrEmpty

        }

        It 'Does not add properties from right that are not present on left' {

            $left = [PSCustomObject]@{ "firstname" = "Florian" }
            $right = [PSCustomObject]@{ "Street" = "Schaumainkai 87" }

            $result = Merge-PSCustomObject -Left $left -right $right

            $result.PSObject.Properties.Name | Should -Not -Contain "Street"
            $result.firstname | Should -Be "Florian"

        }

    }

    Context 'Extra flags' {

        It 'Add properties from right' {

            $left = [PSCustomObject]@{
                "firstname" = "Florian"
                "lastname" = "Friedrichs"
            }

            $right = [PSCustomObject]@{
                "lastname" = "von Bracht"
                "Street" = "Schaumainkai 87"
            }

            $expectedResult = [PSCustomObject]@{
                "firstname" = "Florian"
                "Street" = "Schaumainkai 87"
                "lastname" = "von Bracht"
            }

            $result = Merge-PSCustomObject -Left $left -right $right -AddPropertiesFromRight

            $result | Should-BeObject $expectedResult | Should -BeNullOrEmpty

        }

    }

    Context 'Nested PSCustomObject values' {

        It 'Overwrites the nested object with the one from right by default' {

            $left = [PSCustomObject]@{
                "address" = [PSCustomObject]@{ "street" = "Schaumainkai 87" }
            }
            $right = [PSCustomObject]@{
                "address" = [PSCustomObject]@{ "postcode" = 60596 }
            }

            $result = Merge-PSCustomObject -Left $left -right $right

            $result.address.PSObject.Properties.Name | Should -Not -Contain "street"
            $result.address.postcode | Should -Be 60596

        }

        It 'Merges the nested object recursively with -MergePSCustomObjects' {

            $left = [PSCustomObject]@{
                "address" = [PSCustomObject]@{ "street" = "Schaumainkai 87" }
            }
            $right = [PSCustomObject]@{
                "address" = [PSCustomObject]@{ "postcode" = 60596 }
            }

            $result = Merge-PSCustomObject -Left $left -right $right -MergePSCustomObjects -AddPropertiesFromRight

            $result.address.street | Should -Be "Schaumainkai 87"
            $result.address.postcode | Should -Be 60596

        }

        It 'Keeps the filled left object when the nested right object is empty (regression)' {

            $left = [PSCustomObject]@{
                "address" = [PSCustomObject]@{ "firstname" = "Flo" }
            }
            $right = [PSCustomObject]@{
                "address" = [PSCustomObject]@{}
            }

            $result = Merge-PSCustomObject -Left $left -right $right -MergePSCustomObjects

            $result.address.firstname | Should -Be "Flo"

        }

    }

    Context 'Nested Hashtable values (combination with Merge-Hashtable)' {

        It 'Overwrites the nested hashtable with the one from right by default' {

            $left = [PSCustomObject]@{
                "address" = [hashtable]@{ "street" = "Schaumainkai 87" }
            }
            $right = [PSCustomObject]@{
                "address" = [hashtable]@{ "postcode" = 60596 }
            }

            $result = Merge-PSCustomObject -Left $left -right $right

            $result.address.Keys | Should -Not -Contain "street"
            $result.address["postcode"] | Should -Be 60596

        }

        It 'Merges the nested hashtable recursively via Merge-Hashtable with -MergeHashtables' {

            $left = [PSCustomObject]@{
                "address" = [hashtable]@{ "street" = "Schaumainkai 87" }
            }
            $right = [PSCustomObject]@{
                "address" = [hashtable]@{ "postcode" = 60596 }
            }

            $result = Merge-PSCustomObject -Left $left -right $right -MergeHashtables -AddPropertiesFromRight

            $result.address | Should -BeOfType [hashtable]
            $result.address["street"] | Should -Be "Schaumainkai 87"
            $result.address["postcode"] | Should -Be 60596

        }

    }

    Context 'Arrays and ArrayLists with -MergeArrays' {

        It 'Merges [Array] properties and removes duplicates' {

            $left = [PSCustomObject]@{ "tags" = [Array]@("a","b") }
            $right = [PSCustomObject]@{ "tags" = [Array]@("b","c") }

            $result = Merge-PSCustomObject -Left $left -right $right -MergeArrays

            @( $result.tags | Sort-Object ) | Should -Be @("a","b","c")

        }

        It 'Merges [ArrayList] properties and removes duplicates' {

            $left = [PSCustomObject]@{ "tags" = [System.Collections.ArrayList]@("a","b") }
            $right = [PSCustomObject]@{ "tags" = [System.Collections.ArrayList]@("b","c") }

            $result = Merge-PSCustomObject -Left $left -right $right -MergeArrays

            $result.PSObject.Properties.Name | Should -Contain "tags"
            @( $result.tags | Sort-Object ) | Should -Be @("a","b","c")

        }

    }

    Context 'Deep combination of PSCustomObject and Hashtable nesting' {

        It 'Merges a PSCustomObject that contains a Hashtable that contains a PSCustomObject' {

            $left = [PSCustomObject]@{
                "firstname" = "Florian"
                "settings" = [hashtable]@{
                    "theme" = "dark"
                    "profile" = [PSCustomObject]@{ "name" = "Orbit" }
                }
            }

            $right = [PSCustomObject]@{
                "lastname" = "von Bracht"
                "settings" = [hashtable]@{
                    "language" = "de"
                    "profile" = [PSCustomObject]@{ "owner" = "Apteco" }
                }
            }

            $result = Merge-PSCustomObject -Left $left -Right $right -AddPropertiesFromRight -MergePSCustomObjects -MergeHashtables

            $result.firstname | Should -Be "Florian"
            $result.lastname | Should -Be "von Bracht"
            $result.settings | Should -BeOfType [hashtable]
            $result.settings["theme"] | Should -Be "dark"
            $result.settings["language"] | Should -Be "de"
            $result.settings["profile"].name | Should -Be "Orbit"
            $result.settings["profile"].owner | Should -Be "Apteco"

        }

    }

}
