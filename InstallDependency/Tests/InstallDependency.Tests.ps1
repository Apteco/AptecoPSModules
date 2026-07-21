BeforeAll {
    Import-Module "$PSScriptRoot/../InstallDependency" -Force

    # Make sure the repository Install-Dependency expects (a trusted NuGet source) is
    # registered, so its interactive "register/trust?" prompts never trigger in a
    # non-interactive CI run. Some runners (observed on Windows PowerShell 5.1 on GitHub
    # Actions) ship with a pre-registered NuGet source of their own that is not trusted;
    # merely trying to flip it to Trusted can silently fail depending on the provider/
    # environment, and Install-Dependency then keeps using that untrusted source rather
    # than hitting the interactive trust prompt path, so genuinely existing packages stop
    # resolving. Only touch the machine's package sources when the current state isn't
    # already exactly what's needed (one trusted NuGet source) -- e.g. a dev machine that
    # already has a trusted nuget.org source registered is left alone.
    try {
        $existingNuGetSources = @( Get-PackageSource -ProviderName NuGet -ErrorAction SilentlyContinue )
        $alreadyGood = $existingNuGetSources.Count -eq 1 -and $existingNuGetSources[0].IsTrusted -eq $true
        if (-not $alreadyGood) {
            $existingNuGetSources | ForEach-Object {
                Unregister-PackageSource -Name $_.Name -ProviderName NuGet -ErrorAction SilentlyContinue
            }
            Register-PackageSource -Name "NuGet v2" -Location "https://www.nuget.org/api/v2" -ProviderName NuGet -Trusted -ErrorAction Stop | Out-Null
        }
    } catch { }
    try {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    } catch { }

    # Builds a fake Get-PSEnvironment result. PackageManagement/PowerShellGet
    # are always set to "healthy" versions here: leaving them blank makes
    # Install-Dependency believe they're outdated and call the (unmocked,
    # real) Install-Package -Force to "fix" them, which we never want during
    # a test run.
    function New-FakePSEnvironment {
        param(
            [bool]$IsElevated = $false,
            [string]$ExecutingUser = "TestUser",
            [array]$InstalledModules = @(),
            [array]$InstalledLocalPackages = @(),
            [array]$InstalledGlobalPackages = @()
        )
        [PSCustomObject]@{
            IsCore                   = $false
            PSVersion                = "5.1.0"
            PSEdition                = "Desktop"
            OS                       = "Windows"
            Architecture             = "x64"
            ExecutingUser            = $ExecutingUser
            IsElevated               = $IsElevated
            ExecutionPolicy          = [PSCustomObject]@{ Process = "RemoteSigned" }
            PackageManagement        = "1.4.7"
            PowerShellGet            = "2.2.5"
            InstalledModules         = $InstalledModules
            InstalledLocalPackages   = $InstalledLocalPackages
            InstalledGlobalPackages  = $InstalledGlobalPackages
        }
    }
}

Describe "Install-Dependency" {

    BeforeEach {

        # Isolate the module from the real machine state without mocking
        # network-facing/installing cmdlets that Pester cannot mock reliably:
        #
        # - WriteLog's functions (Get-Logfile/Set-Logfile/Write-Log/...) are
        #   NOT mocked: Write-Log's -Severity parameter is typed as the
        #   [LogSeverity] enum, which lives inside the WriteLog module and is
        #   not resolvable from a Pester-generated mock proxy, so mocking it
        #   blows up parameter binding. Running WriteLog for real is cheap
        #   and side effects are contained by running from a temp folder.
        #
        # - Get-PackageSource/Get-Package/Find-Package/Install-Package (all
        #   from PackageManagement) declare provider-dependent DYNAMIC
        #   parameter sets ("NuGet" vs "PowerShellGet"). Pester's mock proxy
        #   flattens those into a single static parameter set, which makes
        #   ordinary calls like `Get-PackageSource -ProviderName ...` fail
        #   with "Parameter set cannot be resolved" even though the real
        #   cmdlet handles it fine. So these run for real too: they're
        #   read-only/safe (Get-PackageSource), or a no-op for the nonsense
        #   package names used below (Find-Package finds nothing, so
        #   Install-Package is never actually reached), or short-circuited
        #   before Install-Package is reached by the "already installed"
        #   skip logic (see the package skip-logic tests below).

        $script:testWorkDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "InstallDependencyTests_$( [guid]::NewGuid() )"
        New-Item -Path $script:testWorkDir -ItemType Directory -Force | Out-Null
        Push-Location $script:testWorkDir

        $script:testLocalFolder = Join-Path -Path $script:testWorkDir -ChildPath "lib"

        Mock -ModuleName InstallDependency Get-PSEnvironment { New-FakePSEnvironment }

        Mock -ModuleName InstallDependency Find-Module    { @() }
        Mock -ModuleName InstallDependency Install-Module { }
        Mock -ModuleName InstallDependency Update-Module  { }

    }

    AfterEach {
        Pop-Location
        if (Test-Path $script:testWorkDir) {
            Remove-Item $script:testWorkDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Elevation checks" {

        It "Throws when GlobalPackage is requested without elevation" {
            { Install-Dependency -GlobalPackage "SomePackage" -LocalPackageFolder $script:testLocalFolder } | Should -Throw
        }

        It "Does not require elevation for Module or LocalPackage" {
            { Install-Dependency -Module "SomeModule" -LocalPackage "definitely-nonexistent-package-installdependency-tests" -LocalPackageFolder $script:testLocalFolder } | Should -Not -Throw
        }

    }

    Context "Nothing to install" {

        It "Completes without throwing when no parameters are specified" {
            { Install-Dependency } | Should -Not -Throw
        }

        It "Logs that there is nothing to install for each category" {
            Install-Dependency
            $logContent = Get-Content -Path (Join-Path $script:testWorkDir "dependencies_install.log") -Raw
            $logContent | Should -Match "There is no module to install"
            $logContent | Should -Match "There is no package to install"
        }

    }

    Context "Module installation" {

        It "Installs a module that is not yet present" {
            Mock -ModuleName InstallDependency Find-Module {
                param($Name)
                [PSCustomObject]@{ Name = $Name; Version = [Version]"2.0.0" }
            }

            Install-Dependency -Module "DemoModule"

            Should -Invoke -ModuleName InstallDependency Install-Module -Times 1 -ParameterFilter { $Name -eq "DemoModule" -and $Scope -eq "CurrentUser" }
        }

        It "Updates a module when Get-PSEnvironment reports an older installed version" {
            Mock -ModuleName InstallDependency Find-Module {
                param($Name)
                [PSCustomObject]@{ Name = $Name; Version = [Version]"2.0.0" }
            }
            Mock -ModuleName InstallDependency Get-PSEnvironment {
                New-FakePSEnvironment -InstalledModules @( [PSCustomObject]@{ Name = "DemoModule"; Version = "1.0.0" } )
            }

            Install-Dependency -Module "DemoModule"

            Should -Invoke -ModuleName InstallDependency Update-Module -Times 1 -ParameterFilter { $Name -eq "DemoModule" }
            Should -Invoke -ModuleName InstallDependency Install-Module -Times 0
        }

        It "Does nothing when Get-PSEnvironment reports the current version already installed" {
            Mock -ModuleName InstallDependency Find-Module {
                param($Name)
                [PSCustomObject]@{ Name = $Name; Version = [Version]"1.0.0" }
            }
            Mock -ModuleName InstallDependency Get-PSEnvironment {
                New-FakePSEnvironment -InstalledModules @( [PSCustomObject]@{ Name = "DemoModule"; Version = "1.0.0" } )
            }

            Install-Dependency -Module "DemoModule"

            Should -Invoke -ModuleName InstallDependency Install-Module -Times 0
            Should -Invoke -ModuleName InstallDependency Update-Module -Times 0
        }

        It "Uses AllUsers scope when the session is elevated" {
            Mock -ModuleName InstallDependency Get-PSEnvironment {
                New-FakePSEnvironment -IsElevated $true -ExecutingUser "Admin"
            }
            Mock -ModuleName InstallDependency Find-Module {
                param($Name)
                [PSCustomObject]@{ Name = $Name; Version = [Version]"2.0.0" }
            }

            Install-Dependency -Module "DemoModule"

            Should -Invoke -ModuleName InstallDependency Install-Module -Times 1 -ParameterFilter { $Scope -eq "AllUsers" }
        }

        It "Resolves dependencies via Find-Module unless -ExcludeDependencies is set" {
            Mock -ModuleName InstallDependency Find-Module {
                param($Name)
                [PSCustomObject]@{ Name = $Name; Version = [Version]"2.0.0" }
            }

            Install-Dependency -Module "DemoModule"

            Should -Invoke -ModuleName InstallDependency Find-Module -ParameterFilter { $IncludeDependencies -eq $true }
        }

        It "Skips dependency resolution when -ExcludeDependencies is set" {
            Mock -ModuleName InstallDependency Find-Module {
                param($Name)
                [PSCustomObject]@{ Name = $Name; Version = [Version]"2.0.0" }
            }

            Install-Dependency -Module "DemoModule" -ExcludeDependencies

            Should -Invoke -ModuleName InstallDependency Find-Module -ParameterFilter { -not $IncludeDependencies }
        }

    }

    Context "Local package installation" {

        It "Does not throw when no matching package is found, and still creates the local package folder" {
            { Install-Dependency -LocalPackage "definitely-nonexistent-package-installdependency-tests" -LocalPackageFolder $script:testLocalFolder } | Should -Not -Throw
            Test-Path $script:testLocalFolder | Should -BeTrue
        }

        It "Keeps a PSCustomObject package entry intact instead of stringifying it (regression: -LocalPackage was typed [String[]], which coerced PSCustomObjects to strings before the function body ever ran)" {
            $verboseOutput = Install-Dependency `
                -LocalPackage ( [PSCustomObject]@{ name = "definitely-nonexistent-package-installdependency-tests"; version = "1.2.3" } ) `
                -LocalPackageFolder $script:testLocalFolder -ExcludeDependencies -Verbose 4>&1 | Out-String

            $verboseOutput | Should -Match "Looking for definitely-nonexistent-package-installdependency-tests with version 1\.2\.3"
            $verboseOutput | Should -Not -Match "without specific version"
        }

        It "Skips a package that Get-PSEnvironment reports as already installed at a newer version" {
            # Newtonsoft.Json is a small, stable, dependency-free NuGet package - real Find-Package
            # lookup, but pinning a version far beyond anything real guarantees the skip triggers
            # regardless of whatever the actual latest version happens to be.
            Mock -ModuleName InstallDependency Get-PSEnvironment {
                New-FakePSEnvironment -InstalledLocalPackages @( [PSCustomObject]@{ Id = "Newtonsoft.Json"; Version = "999.999.999" } )
            }

            # -ExcludeDependencies keeps this a single-package NuGet v2 lookup instead of a
            # full dependency-graph resolution, which can otherwise take a long time for a
            # popular package like Newtonsoft.Json.
            Install-Dependency -LocalPackage "Newtonsoft.Json" -LocalPackageFolder $script:testLocalFolder -ExcludeDependencies

            $logContent = Get-Content -Path (Join-Path $script:testWorkDir "dependencies_install.log") -Raw
            $logContent | Should -Match "Newtonsoft\.Json is already installed with version 999\.999\.999 \(local\), skipping"
            $logContent | Should -Not -Match "Installing Newtonsoft\.Json"
        }

    }

    Context "Global package installation" {

        BeforeEach {
            Mock -ModuleName InstallDependency Get-PSEnvironment {
                New-FakePSEnvironment -IsElevated $true -ExecutingUser "Admin"
            }
        }

        It "Does not throw for an elevated session with no matching package" {
            { Install-Dependency -GlobalPackage "definitely-nonexistent-package-installdependency-tests" -LocalPackageFolder $script:testLocalFolder } | Should -Not -Throw
        }

        It "Keeps a PSCustomObject package entry intact instead of stringifying it (regression: -GlobalPackage was typed [String[]])" {
            $verboseOutput = Install-Dependency `
                -GlobalPackage ( [PSCustomObject]@{ name = "definitely-nonexistent-package-installdependency-tests"; version = "1.2.3" } ) `
                -LocalPackageFolder $script:testLocalFolder -ExcludeDependencies -Verbose 4>&1 | Out-String

            $verboseOutput | Should -Match "Looking for definitely-nonexistent-package-installdependency-tests with version 1\.2\.3"
            $verboseOutput | Should -Not -Match "without specific version"
        }

        It "Skips a package that Get-PSEnvironment reports as already installed globally at a newer version" {
            Mock -ModuleName InstallDependency Get-PSEnvironment {
                New-FakePSEnvironment -IsElevated $true -ExecutingUser "Admin" -InstalledGlobalPackages @( [PSCustomObject]@{ Id = "Newtonsoft.Json"; Version = "999.999.999" } )
            }

            Install-Dependency -GlobalPackage "Newtonsoft.Json" -LocalPackageFolder $script:testLocalFolder -ExcludeDependencies

            $logContent = Get-Content -Path (Join-Path $script:testWorkDir "dependencies_install.log") -Raw
            $logContent | Should -Match "Newtonsoft\.Json is already installed with version 999\.999\.999 \(global\), skipping"
            $logContent | Should -Not -Match "Installing Newtonsoft\.Json"
        }

    }

    Context "Switch parameters" {

        It "Accepts -SuppressWarnings without throwing" {
            { Install-Dependency -SuppressWarnings } | Should -Not -Throw
        }

        It "Accepts -KeepLogfile without throwing" {
            { Install-Dependency -KeepLogfile } | Should -Not -Throw
        }

        It "Accepts -KeepPackage without throwing" {
            { Install-Dependency -KeepPackage } | Should -Not -Throw
        }

    }

    Context "KeepPackage switch (regression: Install-Package -Destination leaves the raw .nupkg as a sibling of the extracted lib/ref/runtimes folders, which broke Import-Dependency's loader)" {

        It "Removes the .nupkg file from LocalPackageFolder after a real install by default" {
            # Newtonsoft.Json is small, stable, dependency-free -- -ExcludeDependencies keeps this a
            # single real download instead of a full dependency-graph resolution.
            Install-Dependency -LocalPackage "Newtonsoft.Json" -LocalPackageFolder $script:testLocalFolder -ExcludeDependencies

            $nupkgFiles = @( Get-ChildItem -Path $script:testLocalFolder -Filter "*.nupkg" -Recurse -File -ErrorAction SilentlyContinue )
            $nupkgFiles.Count | Should -Be 0
        }

        It "Keeps the .nupkg file in LocalPackageFolder when -KeepPackage is specified" {
            Install-Dependency -LocalPackage "Newtonsoft.Json" -LocalPackageFolder $script:testLocalFolder -ExcludeDependencies -KeepPackage

            $nupkgFiles = @( Get-ChildItem -Path $script:testLocalFolder -Filter "*.nupkg" -Recurse -File -ErrorAction SilentlyContinue )
            $nupkgFiles.Count | Should -BeGreaterThan 0
        }

        It "Does not remove unrelated files in LocalPackageFolder when no package was actually installed" {
            New-Item -Path $script:testLocalFolder -ItemType Directory -Force | Out-Null
            $preExistingNupkg = Join-Path $script:testLocalFolder "SomeOther.1.0.0.nupkg"
            Set-Content -Path $preExistingNupkg -Value "placeholder"

            Install-Dependency -LocalPackage "definitely-nonexistent-package-installdependency-tests" -LocalPackageFolder $script:testLocalFolder

            Test-Path $preExistingNupkg | Should -BeTrue
        }

        It "Leaves a .nuspec behind when removing the .nupkg, so the package stays discoverable by Get-LocalPackage (regression: deleting the .nupkg outright removed the package's only metadata source, so Import-Dependency stopped finding it entirely)" {
            Install-Dependency -LocalPackage "Newtonsoft.Json" -LocalPackageFolder $script:testLocalFolder -ExcludeDependencies

            $nuspecFiles = @( Get-ChildItem -Path $script:testLocalFolder -Filter "*.nuspec" -Recurse -File -ErrorAction SilentlyContinue )
            $nuspecFiles.Count | Should -BeGreaterThan 0

            $found = Get-LocalPackage -NugetRoot $script:testLocalFolder
            ($found | Where-Object { $_.Id -eq "Newtonsoft.Json" }) | Should -Not -BeNullOrEmpty
        }

    }

}

Describe "Install-NuGetPackage" {

    BeforeEach {
        $script:testOutputDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "InstallDependencyTests_$( [guid]::NewGuid() )"
        New-Item -Path $script:testOutputDir -ItemType Directory -Force | Out-Null

        Mock -ModuleName InstallDependency Invoke-RestMethod {
            [PSCustomObject]@{ versions = @("1.0.0", "1.1.0", "2.0.0") }
        }
        Mock -ModuleName InstallDependency Invoke-WebRequest { }
        Mock -ModuleName InstallDependency Expand-Archive    { }
        Mock -ModuleName InstallDependency Remove-Item       { }
    }

    AfterEach {
        if (Test-Path $script:testOutputDir) {
            Remove-Item $script:testOutputDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Resolves the latest version when -Version is not specified" {
        Install-NuGetPackage -PackageId "DemoPackage" -OutputDir $script:testOutputDir

        Should -Invoke -ModuleName InstallDependency Invoke-RestMethod -Times 1
        Should -Invoke -ModuleName InstallDependency Invoke-WebRequest -ParameterFilter { $Uri -like "*demopackage.2.0.0.nupkg" }
    }

    It "Uses the specified version when provided and skips version lookup" {
        Install-NuGetPackage -PackageId "DemoPackage" -Version "1.5.0" -OutputDir $script:testOutputDir

        Should -Invoke -ModuleName InstallDependency Invoke-RestMethod -Times 0
        Should -Invoke -ModuleName InstallDependency Invoke-WebRequest -ParameterFilter { $Uri -like "*demopackage.1.5.0.nupkg" }
    }

    It "Removes the downloaded nupkg by default" {
        Install-NuGetPackage -PackageId "DemoPackage" -Version "1.5.0" -OutputDir $script:testOutputDir

        Should -Invoke -ModuleName InstallDependency Remove-Item -Times 1
    }

    It "Keeps the downloaded nupkg when -KeepPackage is specified" {
        Install-NuGetPackage -PackageId "DemoPackage" -Version "1.5.0" -OutputDir $script:testOutputDir -KeepPackage

        Should -Invoke -ModuleName InstallDependency Remove-Item -Times 0
    }

    It "Returns the path to the extracted package" {
        $result = Install-NuGetPackage -PackageId "DemoPackage" -Version "1.5.0" -OutputDir $script:testOutputDir
        $result | Should -Be (Join-Path $script:testOutputDir "demopackage.1.5.0")
    }

    It "Extracts into a folder named after the lowercased package id and version" {
        Install-NuGetPackage -PackageId "DemoPackage" -Version "1.5.0" -OutputDir $script:testOutputDir

        Should -Invoke -ModuleName InstallDependency Expand-Archive -ParameterFilter {
            $DestinationPath -eq (Join-Path $script:testOutputDir "demopackage.1.5.0")
        }
    }

}

Describe "Install-VcRedist" -Skip:([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
    # Install-VcRedist itself short-circuits to "return $true" on non-Windows before ever touching
    # Get-VcRedistStatus/Request-Choice/Start-BitsTransfer/Start-Process (vcredist is a Windows-only
    # concept), so none of the mocked behaviour below is reachable off Windows. [System.Environment]::
    # OSVersion.Platform is used over $IsWindows because $IsWindows does not exist in Windows
    # PowerShell 5.1 (Desktop edition only defines it from PS 6+).

    BeforeEach {
        Mock -ModuleName InstallDependency Start-BitsTransfer { }
        Mock -ModuleName InstallDependency Start-Process     { }
    }

    It "Returns true without installing when already installed" {
        Mock -ModuleName InstallDependency Get-VcRedistStatus {
            [PSCustomObject]@{ Installed = $true; Is64Bit = $true; Versions = @{} }
        }

        Install-VcRedist -Force | Should -BeTrue

        Should -Invoke -ModuleName InstallDependency Start-BitsTransfer -Times 0
        Should -Invoke -ModuleName InstallDependency Start-Process -Times 0
    }

    It "Installs when missing and -Force is used, skipping the prompt" {
        $script:vcRedistCheckCount = 0
        Mock -ModuleName InstallDependency Get-VcRedistStatus {
            $script:vcRedistCheckCount++
            if ($script:vcRedistCheckCount -eq 1) {
                [PSCustomObject]@{ Installed = $false; Is64Bit = $false; Versions = $null }
            } else {
                [PSCustomObject]@{ Installed = $true; Is64Bit = $true; Versions = @{} }
            }
        }

        Install-VcRedist -Force | Should -BeTrue

        Should -Invoke -ModuleName InstallDependency Start-BitsTransfer -Times 1
        Should -Invoke -ModuleName InstallDependency Start-Process -Times 1 -ParameterFilter { $ArgumentList -eq "/install /q /norestart" }
    }

    It "Prompts and skips the install when the user declines" {
        Mock -ModuleName InstallDependency Get-VcRedistStatus {
            [PSCustomObject]@{ Installed = $false; Is64Bit = $false; Versions = $null }
        }
        Mock -ModuleName InstallDependency Request-Choice { 2 } # "No"

        Install-VcRedist | Should -BeFalse

        Should -Invoke -ModuleName InstallDependency Request-Choice -Times 1
        Should -Invoke -ModuleName InstallDependency Start-BitsTransfer -Times 0
    }

    It "Prompts and installs when the user accepts" {
        $script:vcRedistCheckCount = 0
        Mock -ModuleName InstallDependency Get-VcRedistStatus {
            $script:vcRedistCheckCount++
            if ($script:vcRedistCheckCount -eq 1) {
                [PSCustomObject]@{ Installed = $false; Is64Bit = $false; Versions = $null }
            } else {
                [PSCustomObject]@{ Installed = $true; Is64Bit = $true; Versions = @{} }
            }
        }
        Mock -ModuleName InstallDependency Request-Choice { 1 } # "Yes"

        Install-VcRedist | Should -BeTrue

        Should -Invoke -ModuleName InstallDependency Start-BitsTransfer -Times 1
    }

    It "Returns false when the re-check after installing still shows it missing" {
        Mock -ModuleName InstallDependency Get-VcRedistStatus {
            [PSCustomObject]@{ Installed = $false; Is64Bit = $false; Versions = $null }
        }

        Install-VcRedist -Force | Should -BeFalse
    }

    It "Downloads from the provided -DownloadUri" {
        $script:vcRedistCheckCount = 0
        Mock -ModuleName InstallDependency Get-VcRedistStatus {
            $script:vcRedistCheckCount++
            if ($script:vcRedistCheckCount -eq 1) {
                [PSCustomObject]@{ Installed = $false; Is64Bit = $false; Versions = $null }
            } else {
                [PSCustomObject]@{ Installed = $true; Is64Bit = $true; Versions = @{} }
            }
        }

        Install-VcRedist -Force -DownloadUri "https://example.com/vc_redist.x64.exe"

        Should -Invoke -ModuleName InstallDependency Start-BitsTransfer -ParameterFilter { $Source -eq "https://example.com/vc_redist.x64.exe" }
    }

}

AfterAll {
    Remove-Module "InstallDependency" -Force -ErrorAction SilentlyContinue
}
