BeforeAll {

    $userName = "foo"
    $password = "p@ssw0rd"

    # Check the operating system
    if ($IsWindows -eq $True -or $PSVersionTable.PSEdition -eq "Desktop") {

        # Execute this test only with elevated rights
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

        If ( $isElevated -eq $False ) {
            throw "Please run the tests with elevated rights"
        }
        # Windows user creation
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        New-LocalUser -Name $userName -Password $securePassword -Description "New dummy user account"
    } elseif ($IsLinux -eq $True ) {
        # Linux user creation
        $hashedPassword = & openssl passwd -1 $password
        & sudo useradd -m -p $hashedPassword $userName
    }

    #net user foo p@ssw0rd /add

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
            $cred = New-Object System.Management.Automation.PSCredential ($userName, (ConvertTo-SecureString $password -AsPlainText -Force))
            #Mock Start-Job { [PSCustomObject]@{ State = "Completed" } }
            Test-Credential -Credentials $cred -NonInteractive | Should -BeTrue
        }

        It "Returns $false for failed credentials (mocked)" {
            $cred = New-Object System.Management.Automation.PSCredential ($userName, (ConvertTo-SecureString "wrong" -AsPlainText -Force))
            #Mock Start-Job { [PSCustomObject]@{ State = "Failed" } }
            Test-Credential -Credentials $cred -NonInteractive | Should -BeFalse
        }

    }
    
    Context "Pipeline input" {
        It "Accepts credentials from pipeline" {
            $cred = New-Object System.Management.Automation.PSCredential ($userName, (ConvertTo-SecureString $password -AsPlainText -Force))
            #Mock Start-Job { [PSCustomObject]@{ State = "Completed" } }
            $cred | Test-Credential -NonInteractive | Should -BeTrue
        }
    }

}

AfterAll {
    # Cleanup: Remove the user after tests
    if ($IsWindows -eq $True -or $PSVersionTable.PSEdition -eq "Desktop") {
        Remove-LocalUser -Name $userName -ErrorAction SilentlyContinue
    } elseif ($IsLinux) {
        & sudo userdel -r $userName
    }
}