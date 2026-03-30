BeforeAll {
    Import-Module "$PSScriptRoot/../ImportDependency" -Force
}

AfterAll {
    Remove-Module ImportDependency -Force -ErrorAction SilentlyContinue
    Remove-Module WriteLog -Force -ErrorAction SilentlyContinue
}


# ---------------------------------------------------------------------------
Describe "Get-TemporaryPath" {
# ---------------------------------------------------------------------------

    It "Returns a non-null string" {
        $result = Get-TemporaryPath
        $result | Should -Not -BeNullOrEmpty
    }

    It "Returns an existing path" {
        $result = Get-TemporaryPath
        Test-Path $result | Should -Be $true
    }

    It "Returns a string type" {
        $result = Get-TemporaryPath
        $result | Should -BeOfType [string]
    }

}


# ---------------------------------------------------------------------------
Describe "Get-LocalPackage" {
# ---------------------------------------------------------------------------

    BeforeAll {
        # Create a temp directory with a mock nuspec file
        $script:tempPkgDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_importdep_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:tempPkgDir | Out-Null

        @"
<?xml version="1.0" encoding="utf-8"?>
<package>
  <metadata>
    <id>TestPackage</id>
    <version>1.2.3</version>
    <description>A test package for Pester</description>
    <authors>Test Author</authors>
  </metadata>
</package>
"@ | Set-Content -Path (Join-Path $script:tempPkgDir "TestPackage.nuspec") -Encoding UTF8

        # Second package in a sub-directory
        $script:tempPkgSubDir = Join-Path $script:tempPkgDir "subpkg"
        New-Item -ItemType Directory -Path $script:tempPkgSubDir | Out-Null

        @"
<?xml version="1.0" encoding="utf-8"?>
<package>
  <metadata>
    <id>SubPackage</id>
    <version>0.5.0</version>
    <description>Sub package</description>
    <authors>Sub Author</authors>
  </metadata>
</package>
"@ | Set-Content -Path (Join-Path $script:tempPkgSubDir "SubPackage.nuspec") -Encoding UTF8
    }

    AfterAll {
        Remove-Item -Path $script:tempPkgDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Returns a package found via nuspec file" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        $result | Should -Not -BeNullOrEmpty
    }

    It "Returns the correct package Id" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        $result.Id | Should -Contain "TestPackage"
    }

    It "Returns the correct package version" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        ($result | Where-Object { $_.Id -eq "TestPackage" }).Version | Should -Be "1.2.3"
    }

    It "Returns the correct package authors" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        ($result | Where-Object { $_.Id -eq "TestPackage" }).Authors | Should -Be "Test Author"
    }

    It "Returns the correct package description" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        ($result | Where-Object { $_.Id -eq "TestPackage" }).Description | Should -Be "A test package for Pester"
    }

    It "Returns packages from sub-directories" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        $result.Id | Should -Contain "SubPackage"
    }

    It "Returns PSCustomObject with all expected properties" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        $pkg = $result | Select-Object -First 1
        $pkg.PSObject.Properties.Name | Should -Contain "Id"
        $pkg.PSObject.Properties.Name | Should -Contain "Version"
        $pkg.PSObject.Properties.Name | Should -Contain "Description"
        $pkg.PSObject.Properties.Name | Should -Contain "Authors"
        $pkg.PSObject.Properties.Name | Should -Contain "Path"
        $pkg.PSObject.Properties.Name | Should -Contain "SizeMB"
        $pkg.PSObject.Properties.Name | Should -Contain "Source"
    }

    It "Source property is 'nuspec' for nuspec-based packages" {
        $result = Get-LocalPackage -NugetRoot $script:tempPkgDir
        ($result | Where-Object { $_.Id -eq "TestPackage" }).Source | Should -Be "nuspec"
    }

    It "Returns empty result for non-existent path" {
        $nonExistent = Join-Path ([System.IO.Path]::GetTempPath()) "nonexistent_pkg_$(Get-Random)"
        $result = Get-LocalPackage -NugetRoot $nonExistent
        $result | Should -BeNullOrEmpty
    }

    It "Accepts multiple NugetRoot paths" {
        $anotherDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_importdep2_$(Get-Random)"
        New-Item -ItemType Directory -Path $anotherDir | Out-Null
        @"
<?xml version="1.0" encoding="utf-8"?>
<package><metadata><id>AnotherPkg</id><version>2.0.0</version><description>X</description><authors>Y</authors></metadata></package>
"@ | Set-Content -Path (Join-Path $anotherDir "AnotherPkg.nuspec") -Encoding UTF8

        $result = Get-LocalPackage -NugetRoot @($script:tempPkgDir, $anotherDir)
        $result.Id | Should -Contain "AnotherPkg"

        Remove-Item -Path $anotherDir -Recurse -Force -ErrorAction SilentlyContinue
    }

}


# ---------------------------------------------------------------------------
Describe "Get-PSEnvironment" {
# ---------------------------------------------------------------------------

    It "Returns an ordered dictionary" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
    }

    It "Contains all required top-level keys" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        foreach ($key in @("PSVersion","PSEdition","OS","IsCore","IsCoreInstalled","DefaultPSCore",
                           "Architecture","CurrentRuntime","Is64BitOS","Is64BitProcess",
                           "ExecutingUser","ExecutionPolicy","IsElevated",
                           "RuntimePreference","FrameworkPreference",
                           "PackageManagement","PowerShellGet","VcRedist",
                           "BackgroundCheckCompleted","InstalledModules","InstalledGlobalPackages",
                           "LocalPackageCheckCompleted","InstalledLocalPackages")) {
            $result.Keys | Should -Contain $key -Because "key '$key' must be present"
        }
    }

    It "PSVersion is a non-empty string" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.PSVersion | Should -Not -BeNullOrEmpty
        $result.PSVersion | Should -BeOfType [string]
    }

    It "OS is one of the recognised values" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.OS | Should -BeIn @("Windows", "Linux", "MacOS")
    }

    It "IsCore is a boolean" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.IsCore | Should -BeOfType [bool]
    }

    It "Is64BitOS is a boolean" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.Is64BitOS | Should -BeOfType [bool]
    }

    It "Is64BitProcess is a boolean" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.Is64BitProcess | Should -BeOfType [bool]
    }

    It "Architecture is a recognised value" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.Architecture | Should -BeIn @("x64", "x32", "ARM64", "ARM", "Unknown")
    }

    It "RuntimePreference is a non-empty string" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.RuntimePreference | Should -Not -BeNullOrEmpty
    }

    It "FrameworkPreference is a non-empty string" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.FrameworkPreference | Should -Not -BeNullOrEmpty
    }

    It "DefaultPSCore contains Version, Is64Bit, Path keys" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.DefaultPSCore.Keys | Should -Contain "Version"
        $result.DefaultPSCore.Keys | Should -Contain "Is64Bit"
        $result.DefaultPSCore.Keys | Should -Contain "Path"
    }

    It "BackgroundCheckCompleted is false when -SkipBackgroundCheck is set" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.BackgroundCheckCompleted | Should -Be $false
    }

    It "LocalPackageCheckCompleted is false when -SkipLocalPackageCheck is set" {
        $result = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
        $result.LocalPackageCheckCompleted | Should -Be $false
    }

    It "BackgroundCheckCompleted is true when background check runs" {
        $result = Get-PSEnvironment -SkipLocalPackageCheck
        $result.BackgroundCheckCompleted | Should -Be $true
    }

    It "LocalPackageCheckCompleted is true when local check runs against a missing folder" {
        # Folder does not exist - check still runs (and finds nothing)
        $result = Get-PSEnvironment -SkipBackgroundCheck -LocalPackageFolder (Join-Path ([System.IO.Path]::GetTempPath()) "no_pkg_$(Get-Random)")
        $result.LocalPackageCheckCompleted | Should -Be $true
    }

    It "InstalledLocalPackages is empty for a temp folder with no packages" {
        $emptyDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_empty_$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyDir | Out-Null
        $result = Get-PSEnvironment -SkipBackgroundCheck -LocalPackageFolder $emptyDir
        $result.InstalledLocalPackages | Should -BeNullOrEmpty
        Remove-Item $emptyDir -Force
    }

    It "InstalledLocalPackages returns packages when a valid lib folder is supplied" {
        $libDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester_lib_$(Get-Random)"
        New-Item -ItemType Directory -Path $libDir | Out-Null
        @"
<?xml version="1.0" encoding="utf-8"?>
<package><metadata><id>LibPkg</id><version>3.0.0</version><description>X</description><authors>Y</authors></metadata></package>
"@ | Set-Content -Path (Join-Path $libDir "LibPkg.nuspec") -Encoding UTF8

        $result = Get-PSEnvironment -SkipBackgroundCheck -LocalPackageFolder $libDir
        $result.InstalledLocalPackages.Id | Should -Contain "LibPkg"

        Remove-Item $libDir -Recurse -Force
    }

}


# ---------------------------------------------------------------------------
Describe "Import-Dependency" {
# ---------------------------------------------------------------------------

    It "Runs without errors when called with no arguments" {
        { Import-Dependency } | Should -Not -Throw
    }

    It "Runs without errors with SuppressWarnings when loading a non-existent module" {
        { Import-Dependency -Module "NonExistentModule_$(Get-Random)" -SuppressWarnings } | Should -Not -Throw
    }

    It "Runs without errors with LoadWholePackageFolder when the folder does not exist" {
        $missingLib = Join-Path ([System.IO.Path]::GetTempPath()) "no_lib_$(Get-Random)"
        { Import-Dependency -LoadWholePackageFolder -LocalPackageFolder $missingLib } | Should -Not -Throw
    }

    It "Accepts a KeepLogfile switch without throwing" {
        { Import-Dependency -KeepLogfile } | Should -Not -Throw
    }

    It "Does not load excluded modules (WriteLog and ImportDependency are skipped)" {
        # If WriteLog is already loaded, importing it via Import-Dependency is a no-op
        # The function itself must not throw
        { Import-Dependency -Module "WriteLog" } | Should -Not -Throw
    }

    It "Loads a local package folder that exists but is empty without throwing" {
        $emptyLib = Join-Path ([System.IO.Path]::GetTempPath()) "empty_lib_$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyLib | Out-Null
        { Import-Dependency -LocalPackageFolder $emptyLib -LoadWholePackageFolder } | Should -Not -Throw
        Remove-Item $emptyLib -Recurse -Force
    }

}
