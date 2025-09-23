BeforeAll {
    # Import the module
    Import-Module $PSScriptRoot/../"MergePSCustomObject"

    # From https://stackoverflow.com/questions/50870891/how-to-compare-two-arrays-with-custom-objects-in-pester
    # Changed to send back the difference
    Function Should-BeObject {
        Param (
            [Parameter(Position=0)][Object[]]$b, [Parameter(ValueFromPipeLine = $True)][Object[]]$a
        )
        $Property = ($a | Select-Object -First 1).PSObject.Properties | Select-Object -Expand Name
        $Difference = Compare-Object $b $a -Property $Property
        #Try {
            "$($Difference | Select-Object -First 1)" #| Should -BeNullOrEmpty
        #} Catch {
        #    $PSCmdlet.WriteError($_)
        #}
    }

}

Describe 'Merge-PSCustomObject' {

    Context 'No extra flags with minimal input parameter' {

        It 'Plain objects without nesting and other datatypes and flags' {

            # Define the test objects
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

            #$result | Should -Be $expectedResult # Does not work with objects

            # Delivers something back if the property values are differing
            $result | Should-BeObject $expectedResult | Should -BeNullOrEmpty

            # Compare with json? better for nested objects?
            #(ConvertTo-Json $result) | Should -Be (ConvertTo-Json $expectedResult)

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

            # Delivers something back if the property values are differing
            $result | Should-BeObject $expectedResult | Should -BeNullOrEmpty

        }

    }

    }





}








