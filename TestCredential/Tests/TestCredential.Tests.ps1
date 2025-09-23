BeforeAll {

    # Execute this test only with elevated rights
    If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        throw "Please run the tests with elevated rights"
    }

    net user foo p@ssw0rd /add

    Import-Module "$PSScriptRoot/../TestCredential" -Force

}

Describe "Test-Credential" {

    <#
    Context "Interactive mode" {
        It "Returns $true for valid credentials (mocked)" {
            Mock Get-Credential { 
                # Return a dummy PSCredential object
                New-Object System.Management.Automation.PSCredential ("user", (ConvertTo-SecureString "pw" -AsPlainText -Force))
            }
            Mock Start-Job { 
                # Simulate a completed job
                [PSCustomObject]@{ State = "Completed" }
            }
            Test-Credential | Should -BeTrue
        }

        It "Returns $false for failed credentials (mocked)" {
            Mock Get-Credential { 
                New-Object System.Management.Automation.PSCredential ("user", (ConvertTo-SecureString "pw" -AsPlainText -Force))
            }
            Mock Start-Job { 
                [PSCustomObject]@{ State = "Failed" }
            }
            Test-Credential | Should -BeFalse
        }
    }
    #>

    Context "NonInteractive mode" {

        It "Throws if no credentials are provided" {
            { Test-Credential -NonInteractive } | Should -Throw
        }

        It "Returns $true for valid credentials (mocked)" {
            $cred = New-Object System.Management.Automation.PSCredential ("foo", (ConvertTo-SecureString "p@ssw0rd" -AsPlainText -Force))
            #Mock Start-Job { [PSCustomObject]@{ State = "Completed" } }
            Test-Credential -Credentials $cred -NonInteractive | Should -BeTrue
        }

        It "Returns $false for failed credentials (mocked)" {
            $cred = New-Object System.Management.Automation.PSCredential ("foo", (ConvertTo-SecureString "wrong" -AsPlainText -Force))
            #Mock Start-Job { [PSCustomObject]@{ State = "Failed" } }
            Test-Credential -Credentials $cred -NonInteractive | Should -BeFalse
        }

    }
    
    Context "Pipeline input" {
        It "Accepts credentials from pipeline" {
            $cred = New-Object System.Management.Automation.PSCredential ("foo", (ConvertTo-SecureString "p@ssw0rd" -AsPlainText -Force))
            #Mock Start-Job { [PSCustomObject]@{ State = "Completed" } }
            $cred | Test-Credential -NonInteractive | Should -BeTrue
        }
    }

}

AfterAll {
    net user foo /delete
}