BeforeAll {
    # Import the module
    Import-Module $PSScriptRoot/../"MergeHashtable" -Force

    # Sibling module needed for the -MergePSCustomObjects recursion tests further down
    if ( -not ( Get-Module -ListAvailable -Name "MergePSCustomObject" ) ) {
        Install-Module -Name MergePSCustomObject -Force -Scope CurrentUser -Repository PSGallery
    }
    Import-Module MergePSCustomObject -Force
}

Describe 'Merge-Hashtable' {

    Context 'No extra flags with minimal input parameter' {

        It 'Plain hashtables without nesting and other datatypes and flags' {

            $left = [hashtable]@{
                "firstname" = "Florian"
                "lastname" = "Friedrichs"
            }

            $right = [hashtable]@{
                "lastname" = "von Bracht"
                "Street" = "Schaumainkai 87"
            }

            $result = Merge-Hashtable -Left $left -right $right

            $result.Keys | Should -Not -Contain "Street"
            $result["firstname"] | Should -Be "Florian"
            $result["lastname"] | Should -Be "von Bracht"

        }

    }

    Context 'Extra flags' {

        It 'Adds keys from right with -AddKeysFromRight' {

            $left = [hashtable]@{
                "firstname" = "Florian"
                "lastname" = "Friedrichs"
            }

            $right = [hashtable]@{
                "lastname" = "von Bracht"
                "Street" = "Schaumainkai 87"
            }

            $result = Merge-Hashtable -Left $left -right $right -AddKeysFromRight

            $result["firstname"] | Should -Be "Florian"
            $result["lastname"] | Should -Be "von Bracht"
            $result["Street"] | Should -Be "Schaumainkai 87"

        }

    }

    Context 'Nested Hashtable values' {

        It 'Overwrites the nested hashtable with the one from right by default' {

            $left = [hashtable]@{
                "address" = [hashtable]@{ "street" = "Schaumainkai 87" }
            }
            $right = [hashtable]@{
                "address" = [hashtable]@{ "postcode" = 60596 }
            }

            $result = Merge-Hashtable -Left $left -right $right

            $result.address.Keys | Should -Not -Contain "street"
            $result.address["postcode"] | Should -Be 60596

        }

        It 'Merges the nested hashtable recursively with -MergeHashtables' {

            $left = [hashtable]@{
                "address" = [hashtable]@{ "street" = "Schaumainkai 87" }
            }
            $right = [hashtable]@{
                "address" = [hashtable]@{ "postcode" = 60596 }
            }

            $result = Merge-Hashtable -Left $left -right $right -MergeHashtables -AddKeysFromRight

            $result.address["street"] | Should -Be "Schaumainkai 87"
            $result.address["postcode"] | Should -Be 60596

        }

        It 'Keeps the filled left hashtable when the nested right hashtable is empty (regression)' {

            $left = [hashtable]@{
                "nested" = [hashtable]@{ "firstname" = "Flo" }
            }
            $right = [hashtable]@{
                "nested" = [hashtable]@{}
            }

            $result = Merge-Hashtable -Left $left -right $right -MergeHashtables

            $result.nested["firstname"] | Should -Be "Flo"

        }

    }

    Context 'Nested PSCustomObject values (combination with Merge-PSCustomObject)' {

        It 'Overwrites the nested PSCustomObject with the one from right by default' {

            $left = [hashtable]@{
                "product" = [PSCustomObject]@{ "name" = "Orbit" }
            }
            $right = [hashtable]@{
                "product" = [PSCustomObject]@{ "owner" = "Apteco" }
            }

            $result = Merge-Hashtable -Left $left -right $right

            $result.product.PSObject.Properties.Name | Should -Not -Contain "name"
            $result.product.owner | Should -Be "Apteco"

        }

        It 'Merges the nested PSCustomObject recursively via Merge-PSCustomObject with -MergePSCustomObjects' {

            $left = [hashtable]@{
                "product" = [PSCustomObject]@{ "name" = "Orbit" }
            }
            $right = [hashtable]@{
                "product" = [PSCustomObject]@{ "owner" = "Apteco" }
            }

            $result = Merge-Hashtable -Left $left -right $right -MergePSCustomObjects -AddKeysFromRight

            $result.product | Should -BeOfType [PSCustomObject]
            $result.product.name | Should -Be "Orbit"
            $result.product.owner | Should -Be "Apteco"

        }

    }

    Context 'Arrays and ArrayLists with -MergeArrays' {

        It 'Merges [Array] values and removes duplicates' {

            $left = [hashtable]@{ "tags" = [Array]@("a","b") }
            $right = [hashtable]@{ "tags" = [Array]@("b","c") }

            $result = Merge-Hashtable -Left $left -right $right -MergeArrays

            @( $result["tags"] | Sort-Object ) | Should -Be @("a","b","c")

        }

        It 'Merges [ArrayList] values, removes duplicates, and keeps the key addressable (regression for the Add-Member bug)' {

            $left = [hashtable]@{ "tags" = [System.Collections.ArrayList]@("a","b") }
            $right = [hashtable]@{ "tags" = [System.Collections.ArrayList]@("b","c") }

            $result = Merge-Hashtable -Left $left -right $right -MergeArrays

            # The merged key must be a real hashtable entry, not just an ETS NoteProperty
            $result.Keys | Should -Contain "tags"
            $result.Count | Should -Be 1
            @( $result["tags"] | Sort-Object ) | Should -Be @("a","b","c")

        }

    }

    Context 'Deep combination of Hashtable and PSCustomObject nesting' {

        It 'Merges a Hashtable that contains a PSCustomObject that contains a Hashtable' {

            $left = [hashtable]@{
                "firstname" = "Florian"
                "settings" = [PSCustomObject]@{
                    "theme" = "dark"
                    "profile" = [hashtable]@{ "name" = "Orbit" }
                }
            }

            $right = [hashtable]@{
                "lastname" = "von Bracht"
                "settings" = [PSCustomObject]@{
                    "language" = "de"
                    "profile" = [hashtable]@{ "owner" = "Apteco" }
                }
            }

            $result = Merge-Hashtable -Left $left -Right $right -AddKeysFromRight -MergePSCustomObjects -MergeHashtables

            $result["firstname"] | Should -Be "Florian"
            $result["lastname"] | Should -Be "von Bracht"
            $result.settings | Should -BeOfType [PSCustomObject]
            $result.settings.theme | Should -Be "dark"
            $result.settings.language | Should -Be "de"
            $result.settings.profile["name"] | Should -Be "Orbit"
            $result.settings.profile["owner"] | Should -Be "Apteco"

        }

    }

}
