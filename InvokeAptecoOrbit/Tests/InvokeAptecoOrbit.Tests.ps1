#
# Pester 5 tests for InvokeAptecoOrbit
#
# These never call a real Orbit API - Invoke-AptecoOrbit / Invoke-RestMethod is mocked
# throughout, since no live instance/credentials are available in CI.
#
# Run with:  Invoke-Pester -Path .\InvokeAptecoOrbit\Tests
#

BeforeAll {
    Import-Module "$( $PSScriptRoot )/../InvokeAptecoOrbit" -Force
}

AfterAll {
    Remove-Module -Name InvokeAptecoOrbit -Force -ErrorAction SilentlyContinue
}

Describe "Resolve-OrbitUrl" {

    It "substitutes dataViewName and explicit path parameters, and appends the query string" {
        InModuleScope InvokeAptecoOrbit {
            $Script:settings.base = "https://example.test/OrbitAPI/"
            $Script:settings.dataView = "Demo"

            $endpoint = [PSCustomObject]@{ urlTemplate = "{dataViewName}/PeopleStage/Systems/{systemName}" }
            $uri = Resolve-OrbitUrl -Endpoint $endpoint -PathParameters @{ systemName = "Demo System" } -QueryParameters @{ count = 10 }

            $uri | Should -Be "https://example.test/OrbitAPI/Demo/PeopleStage/Systems/Demo%20System?count=10"
        }
    }

}

Describe "Get-OrbitEndpointDefinition" {

    It "throws for an unknown endpoint key" {
        InModuleScope InvokeAptecoOrbit {
            $Script:endpoints = @( [PSCustomObject]@{ name = "KnownEndpoint"; method = "GET"; urlTemplate = "Known" } )
            { Get-OrbitEndpointDefinition -Key "MissingEndpoint" } | Should -Throw
        }
    }

    It "returns the matching endpoint definition" {
        InModuleScope InvokeAptecoOrbit {
            $Script:endpoints = @( [PSCustomObject]@{ name = "KnownEndpoint"; method = "GET"; urlTemplate = "Known" } )
            ( Get-OrbitEndpointDefinition -Key "KnownEndpoint" ).urlTemplate | Should -Be "Known"
        }
    }

}

Describe "New-OrbitSession" {

    It "throws when no credential has been set" {
        InModuleScope InvokeAptecoOrbit {
            $Script:credential = $null
            { New-OrbitSession } | Should -Throw "*Connect-AptecoOrbit*"
        }
    }

    It "throws for an unimplemented login type" {
        InModuleScope InvokeAptecoOrbit {
            $Script:credential = New-Object System.Management.Automation.PSCredential ( "user", ( ConvertTo-SecureString "pw" -AsPlainText -Force ) )
            $Script:settings.loginType = "SALTED"
            { New-OrbitSession } | Should -Throw "*not implemented*"
        }
    }

}

Describe "Get-AptecoOrbitPagedData" {

    It "pages until totalCount items have been collected" {
        InModuleScope InvokeAptecoOrbit {
            $Script:settings.pageSize = 2
            $calls = [System.Collections.ArrayList]@()

            Mock Invoke-AptecoOrbit {
                [void]$calls.Add( @{ offset = $QueryParameters.offset; count = $QueryParameters.count } )
                if ( $QueryParameters.offset -eq 0 ) {
                    return [PSCustomObject]@{ list = @(1,2); totalCount = 3 }
                } else {
                    return [PSCustomObject]@{ list = @(3); totalCount = 3 }
                }
            }

            $result = Get-AptecoOrbitPagedData -Key "AnyEndpoint"

            $result.Count | Should -Be 3
            $calls.Count | Should -Be 2
            $calls[0].offset | Should -Be 0
            $calls[1].offset | Should -Be 2
        }
    }

    It "stops immediately when the endpoint reports zero total items" {
        InModuleScope InvokeAptecoOrbit {
            $Script:settings.pageSize = 5

            Mock Invoke-AptecoOrbit {
                return [PSCustomObject]@{ list = @(); totalCount = 0 }
            }

            $result = Get-AptecoOrbitPagedData -Key "EmptyEndpoint"
            $result.Count | Should -Be 0
        }
    }

}

Describe "Get-AptecoOrbitCampaigns" {

    It "builds a breadcrumb PathString from each campaign's folder path" {
        InModuleScope InvokeAptecoOrbit {

            Mock Invoke-AptecoOrbit {
                return [PSCustomObject]@{ diagramId = 42 }
            }

            Mock Get-AptecoOrbitPagedData {
                return @(
                    [PSCustomObject]@{
                        name = "Campaign A"
                        path = @(
                            [PSCustomObject]@{ description = "Root" }
                            [PSCustomObject]@{ description = "Folder" }
                            [PSCustomObject]@{ description = "Campaign A" }
                        )
                    }
                )
            }

            $result = Get-AptecoOrbitCampaigns -System "Demo"

            $result[0].PathString | Should -Be "Campaign A >> Folder >> Root"

        }
    }

}
