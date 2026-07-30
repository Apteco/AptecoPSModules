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

    It "throws for an unsupported login type" {
        InModuleScope InvokeAptecoOrbit {
            $Script:credential = New-Object System.Management.Automation.PSCredential ( "user", ( ConvertTo-SecureString "pw" -AsPlainText -Force ) )
            $Script:settings.loginType = "OTHER"
            { New-OrbitSession } | Should -Throw "*not supported*"
        }
    }

    It "builds the SALTED PasswordHash from the server's login parameters and logs in" {
        InModuleScope InvokeAptecoOrbit {

            $Script:credential = New-Object System.Management.Automation.PSCredential ( "user", ( ConvertTo-SecureString "AB" -AsPlainText -Force ) )
            $Script:settings.loginType = "SALTED"
            $Script:settings.encryptToken = $false
            $Script:settings.sessionFile = Join-Path ( [System.IO.Path]::GetTempPath() ) "invokeaptecoorbit_test_session_$( [guid]::NewGuid() ).json"
            $Script:endpoints = @(
                [PSCustomObject]@{ name = "CreateLoginParameters"; method = "POST"; urlTemplate = "Login/Parameters" }
                [PSCustomObject]@{ name = "CreateSessionSalted"; method = "POST"; urlTemplate = "Login/Salted" }
            )

            $captured = @{}

            Mock Invoke-RestMethod {
                if ( $Uri -like "*Login/Parameters*" ) {
                    return [PSCustomObject]@{ saltPassword = $true; userSalt = "US"; hashAlgorithm = "SHA256"; loginSalt = "LS" }
                }
                $captured.Body = $Body
                return [PSCustomObject]@{ sessionId = "sid"; accessToken = "tok" }
            }

            New-OrbitSession

            # Protect-OrbitPassword("AB") = "@C" ('A'=65 odd -> 64='@', 'B'=66 even -> 67='C'), then + userSalt "US"
            $step1 = "@CUS"
            $step2 = Get-OrbitStringHash -InputString $step1 -HashName "SHA256"
            $expectedHash = Get-OrbitStringHash -InputString $step2 -HashName "SHA256" -Salt "LS"

            $captured.Body.PasswordHash | Should -Be $expectedHash
            $captured.Body.LoginSalt | Should -Be "LS"
            $Script:sessionId | Should -Be "sid"

            Remove-Item -Path $Script:settings.sessionFile -ErrorAction SilentlyContinue

        }
    }

}

Describe "Protect-OrbitPassword" {

    It "shifts even character codes up and odd character codes down by one" {
        InModuleScope InvokeAptecoOrbit {
            # 'A' = 65 (odd) -> 64 = '@' ; 'B' = 66 (even) -> 67 = 'C'
            Protect-OrbitPassword -Password "AB" | Should -Be "@C"
        }
    }

}

Describe "Get-OrbitStringHash" {

    It "matches the known SHA-256 test vector for 'abc'" {
        InModuleScope InvokeAptecoOrbit {
            Get-OrbitStringHash -InputString "abc" -HashName "SHA256" | Should -Be "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        }
    }

    It "produces a different hash when a salt is appended" {
        InModuleScope InvokeAptecoOrbit {
            $unsalted = Get-OrbitStringHash -InputString "abc" -HashName "SHA256"
            $salted = Get-OrbitStringHash -InputString "abc" -HashName "SHA256" -Salt "pepper"
            $salted | Should -Not -Be $unsalted
        }
    }

    It "uppercases the result when requested" {
        InModuleScope InvokeAptecoOrbit {
            Get-OrbitStringHash -InputString "abc" -HashName "SHA256" -Uppercase $true | Should -Be "BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD"
        }
    }

}

Describe "Get-OrbitErrorResponseBody" {

    It "extracts ErrorDetails.Message (PowerShell 6+ path)" {
        InModuleScope InvokeAptecoOrbit {

            if ( $PSVersionTable.PSVersion.Major -lt 6 ) {
                Set-ItResult -Skipped -Because "requires PowerShell 6+ for the ErrorDetails path"
                return
            }

            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("boom"),
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new("Validation failed: Field X is required")

            Get-OrbitErrorResponseBody -ErrorRecord $errorRecord | Should -Be "Validation failed: Field X is required"

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

Describe "Export-AptecoOrbitAudience" {

    It "resolves the export template columns, triggers the export, and polls GetFile until content is returned" {
        InModuleScope InvokeAptecoOrbit {

            $state = @{ getFileAttempts = 0 }

            Mock Invoke-AptecoOrbit {
                switch ( $Key ) {
                    "GetAudienceWorkbookItemDetail" {
                        return [PSCustomObject]@{
                            definition = [PSCustomObject]@{
                                columns = @(
                                    [PSCustomObject]@{ columnId = 1; scope = [PSCustomObject]@{ variableName = "Email" }; description = "Email"; exportDetail = "Code"; exportUnclassifiedAs = ""; valueFormat = "" }
                                )
                            }
                        }
                    }
                    "ExportAudienceLatestUpdateSync" {
                        return [PSCustomObject]@{ filePath = "exports/audience.csv" }
                    }
                    "GetFile" {
                        $state.getFileAttempts++
                        if ( $state.getFileAttempts -lt 3 ) {
                            return ""
                        }
                        return "Email`ntest@example.com"
                    }
                }
            }

            $result = Export-AptecoOrbitAudience -System "Demo" -AudienceId 246 -WorkbookItemId "wb-1" -PollIntervalSeconds 0 -MaxPollAttempts 5

            $result | Should -Be "Email`ntest@example.com"
            $state.getFileAttempts | Should -Be 3

        }
    }

    It "throws if the export never becomes available within MaxPollAttempts" {
        InModuleScope InvokeAptecoOrbit {

            Mock Invoke-AptecoOrbit {
                switch ( $Key ) {
                    "GetAudienceWorkbookItemDetail" { return [PSCustomObject]@{ definition = [PSCustomObject]@{ columns = @() } } }
                    "ExportAudienceLatestUpdateSync" { return [PSCustomObject]@{ filePath = "exports/audience.csv" } }
                    "GetFile" { return "" }
                }
            }

            { Export-AptecoOrbitAudience -System "Demo" -AudienceId 1 -WorkbookItemId "wb-1" -PollIntervalSeconds 0 -MaxPollAttempts 2 } | Should -Throw "*did not produce a downloadable file*"

        }
    }

}
