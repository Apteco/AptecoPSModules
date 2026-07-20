Function Start-EnvironmentBackgroundJob {

    <#
    .SYNOPSIS
        Kicks off the background jobs that scan for installed modules and global NuGet packages.
    .DESCRIPTION
        Sets $Script:backgroundJobs to a fresh set of jobs. Called once at module import time, and
        again by Update-BackgroundJob whenever there are no jobs in flight, so repeated
        Get-PSEnvironment calls (without -SkipBackgroundCheck) reflect newly installed
        modules/packages instead of silently returning whatever was cached at import time.
    #>

    [CmdletBinding()]
    Param()

    $Script:backgroundJobs = [System.Collections.ArrayList]@()


    #-----------------------------------------------
    # CHECKING POWERHELL 64BIT IN BACKGROUND
    #-----------------------------------------------

    If ( $Script:isCoreInstalled -eq $True ) {

        [void]$Script:backgroundJobs.Add((
            Start-Job -ScriptBlock {
                pwsh { [System.Environment]::Is64BitProcess }
            } -Name "PwshIs64Bit"
        ))

    }


    #-----------------------------------------------
    # CHECKING POWERHELL MODULES IN BACKGROUND
    #-----------------------------------------------

    # TODO add in multiple paths for pscore ?

    [void]$Script:backgroundJobs.Add((
        Start-Job -ScriptBlock {
            param($ModuleRoot, $OS)

            # On Unix split by :

            $pathSeparator = if ($IsWindows -or $OS -match 'Windows') { ';' } else { ':' }

            $env:PSModulePath -split $pathSeparator | ForEach-Object {
                $modulePath = $_
                if (Test-Path $modulePath) {
                    Get-ChildItem $modulePath -Filter *.psd1 -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                        $content = Get-Content $_.FullName -Raw

                        # Extract version
                        if ($content -match "ModuleVersion\s*=\s*(['\`"])(.+?)\1") {
                            $version = $matches[2]
                        } else {
                            $version = 'Unknown'
                        }

                        # Extract PowerShellVersion
                        if ($content -match "PowerShellVersion\s*=\s*(['\`"])(.+?)\1") {
                            $psVersion = $matches[2]
                        } else {
                            $psVersion = 'Not Specified'
                        }

                        # Extract CompatiblePSEditions
                        if ($content -match "CompatiblePSEditions\s*=\s*@\(([^)]+)\)") {
                            $editions = $matches[1] -replace "['\`"\s]", '' -split ','
                        } else {
                            $editions = @('Desktop') # Default for older modules
                        }

                        # Extract Tags from PSData
                        if ($content -match "PSData\s*=\s*@\{[^}]*Tags\s*=\s*@\(([^)]+)\)") {
                            $tags = $matches[1] -replace "['\`"\s]", '' -split ',' | Where-Object { $_ }
                        } else {
                            $tags = @()
                        }

                        # Extract Author
                        if ($content -match "Author\s*=\s*(['\`"])(.+?)\1") {
                            $author = $matches[2]
                        } else {
                            $author = 'Unknown'
                        }

                        # Extract CompanyName
                        if ($content -match "CompanyName\s*=\s*(['\`"])(.+?)\1") {
                            $companyName = $matches[2]
                        } else {
                            $companyName = 'Unknown'
                        }

                        # Determine path-based edition
                        $pathEdition = if ($modulePath -match 'WindowsPowerShell') {
                            'WindowsPowerShell'
                        } elseif ($modulePath -match 'PowerShell\\[67]') {
                            'PSCore'
                        } else {
                            'Shared'
                        }

                        [PSCustomObject][Ordered]@{
                            Name                 = $_.BaseName
                            Version              = $version
                            PowerShellVersion    = $psVersion
                            Author               = $author
                            CompanyName          = $companyName
                            PathEdition          = $pathEdition
                            CompatibleEditions   = $editions -join ', '
                            Tags                 = $tags -join ', '
                            Path                 = $_.DirectoryName
                        }
                    }
                }
            }

        } -Name "InstalledModule" -ArgumentList $Script:moduleRoot, $Script:os
    ))


    #-----------------------------------------------
    # CHECKING GLOBAL NUGET PACKAGES IN BACKGROUND
    #-----------------------------------------------

    [void]$Script:backgroundJobs.Add((
        Start-Job -ScriptBlock {
            param($ModuleRoot, $OS)

            # Load the needed assemblies
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop

            # Paths are dependent on the os
            if ($OS -eq "Windows") {
                $pathsToCheck = @(
                    ( Join-Path $env:USERPROFILE ".nuget\packages" )
                    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\PackageManagement\NuGet\Packages"
                    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\PackageManagement\NuGet\Packages"
                )
            } else {
                $pathsToCheck = @(
                    ( Join-Path $HOME ".nuget/packages" )
                )
            }

            # Dot source the needed function
            . ( Join-Path $ModuleRoot "/Public/Get-LocalPackage.ps1" )

            # Load the packages
            $packages = Get-LocalPackage -NugetRoot $pathsToCheck

            $packages

        } -Name "InstalledGlobalPackages" -ArgumentList $Script:moduleRoot, $Script:os

    ))

}
