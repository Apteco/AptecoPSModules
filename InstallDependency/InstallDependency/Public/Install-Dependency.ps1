
# TODO make sure to use PowerShellGet v2.2.4 or higher and PackageManagement v1.4 or higher
# TODO make heavy use of ImportDependency
# TODO always use -allowclobber where possible
# TODO for packages, have a look at this one

<#

# Download the two DuckDB packages from Nuget without Install-Package or Save-Package
Invoke-WebRequest -UseBasicParsing -Uri https://www.nuget.org/api/v2/package/DuckDB.NET.Bindings.Full -OutFile ./lib
Invoke-WebRequest -UseBasicParsing -Uri https://www.nuget.org/api/v2/package/DuckDB.NET.Data.Full -OutFile ./lib

# Expand and delete the nupkg files
Set-Location ./lib
Get-ChildItem -Path ./lib/ -Filter *.nupkg | % { Expand-Archive -Path $_; Remove-Item -Path $_ }
Set-Location ..

# Import the lib folder
import-module importdependency
import-dependency -LoadWholePackageFolder -LocalPackageFolder .\lib

#>


Function Install-Dependency {

<#
.SYNOPSIS
    Downloads and installs the latest versions of some scripts, modules and packages (saved in current folder of machine folder) from the PowerShell Gallery and NuGet.
.DESCRIPTION
    Script to install dependencies from the PowerShell Gallery and NuGet. It is possible to install scripts, modules and packages.
    The packages can be installed from the PowerShell Gallery and packages from a NuGet repository.
    Packages can defined as a raw string array or as a pscustomobject with a specific version number.

    Please make sure to have the Modules WriteLog and PowerShellGet (>= 2.2.4) installed.

.EXAMPLE
    Install-Dependencies -Module "WriteLog" -LocalPackage "SQLitePCLRaw.core", "Npgsql" -Verbose
.EXAMPLE
    $packages = [Array]@(
        [PSCustomObject]@{
            name="Npgsql"
            version = "4.1.12"
            includeDependencies = $true
        }
    )
    Install-Dependencies -Module "WriteLog" -LocalPackage $packages -Verbose

.PARAMETER Script
    Array of scripts to install on local machine via PowerShellGallery.
.PARAMETER Module
    Array of modules to install on local machine via PowerShellGallery.
.PARAMETER GlobalPackage
    Array of NuGet packages to install on local machine.
.PARAMETER LocalPackage
    Array of NuGet packages to install in a subfolder of the current folder. Can be changed with parameter LocalPackageFolder.
.PARAMETER LocalPackageFolder
    Folder name of the local package folder. Default is "lib".
.PARAMETER ExcludeDependencies
    By default, this script is installing dependencies for every nuget package. This can be deactivated with this switch.
.PARAMETER SuppressWarnings
    Flag to log warnings, but not redirect to the host.
.PARAMETER KeepLogfile
    Flag to keep an existing logfile rather than creating a new one.
.NOTES
    Created by : gitfvb
.LINK
    Project Site: https://github.com/Apteco/Install-Dependencies/tree/main/Install-Dependencies
#>


    [CmdletBinding()]
    Param(

         [Parameter(Mandatory=$false)]
         [String[]]$Script = [Array]@()

        ,[Parameter(Mandatory=$false)]
         [String[]]$Module = [Array]@()

        ,[Parameter(Mandatory=$false)]
         [String[]]$GlobalPackage = [Array]@()

        ,[Parameter(Mandatory=$false)]
         [String[]]$LocalPackage = [Array]@()

        ,[Parameter(Mandatory=$false)]
         [String]$LocalPackageFolder = "lib"

        ,[Parameter(Mandatory=$false)]
         [Switch]$ExcludeDependencies = $false

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
         [Switch]$SuppressWarnings = $false           # Flag to log warnings, but not put redirect to the host

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
         [Switch]$KeepLogfile = $false           # Flag to keep existing logfile

    )


    Begin {

        # Set explicitly verbose output and remember it
        If ( $SuppressWarnings -ne $true -and $PSBoundParameters["Verbose"].IsPresent -eq $true -and $PSBoundParameters["Verbose"] -eq $True) {
            $originalVerbosity = $VerbosePreference
            $VerbosePreference = 'Continue'
        }

        Write-Verbose "Proceeding with start settings"


        #-----------------------------------------------
        # START
        #-----------------------------------------------

        $processStart = [datetime]::now
        $getLogfile = Get-Logfile

        If ( $KeepLogfile -eq $false -and $null -ne $getLogfile ) {
            $currentLogfile = Get-Logfile
            $logfile = ".\dependencies_install.log"
            $logfileAbsolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($logfile)
            Set-Logfile -Path $logfileAbsolute
            Write-Log -message "----------------------------------------------------" -Severity VERBOSE
            Write-Log -Message "Changed logfile from '$( $currentLogfile )' to '$( $logfileAbsolute )'"
        } else {
            $logfile = ".\dependencies_install.log"
            Set-Logfile -Path $logfile
            Write-Log -message "----------------------------------------------------" -Severity VERBOSE
        }

        # Remember the current processID
        $processId = Get-ProcessId

        $writeToHost = $true
        If ( $SuppressWarnings -eq $true ) {
            $writeToHost = $false
        }


        #-----------------------------------------------
        # DOING SOME CHECKS
        #-----------------------------------------------

        # Check if this is Pwsh Core
        $psEnv = Get-PSEnvironment -SkipLocalPackageCheck
        $isCore = $psEnv.IsCore
        Write-Log -Message "Using PowerShell version $( $psEnv.PSVersion ) and $( $psEnv.PSEdition ) edition"

        # Operating system
        $os = $psEnv.OS
        Write-Log -Message "Using OS: $( $os )"
        Write-Log -Message "Using architecture: $( $psEnv.Architecture )"

        # Check elevation
        if ($os -eq "Windows") {
            Write-Log -Message "User: $( $psEnv.ExecutingUser )"
            Write-Log -Message "Elevated: $( $psEnv.IsElevated )"
        } else {
            Write-Log -Message "No user and elevation check due to OS"
        }

        # Check execution policy
        Write-Log -Message "Your execution policy is currently: $( $psEnv.ExecutionPolicy.Process )" -Severity VERBOSE

        # Check if elevated rights are needed
        If ( $GlobalPackage.Count -gt 0 -and $psEnv.IsElevated -eq $false) {
            throw "To install global packages, you need elevated rights, so please restart PowerShell with Administrator privileges!"
        }


        #-----------------------------------------------
        # NUGET SETTINGS
        #-----------------------------------------------

        $packageSourceName = "NuGet v2"
        $packageSourceLocation = "https://www.nuget.org/api/v2"
        $packageSourceProviderName = "NuGet"


        #-----------------------------------------------
        # POWERSHELL GALLERY SETTINGS
        #-----------------------------------------------

        $powerShellSourceName = "PSGallery"
        $powerShellSourceLocation = "https://www.powershellgallery.com/api/v2"
        $powerShellSourceProviderName = "PowerShellGet"

        If ( $psEnv.IsElevated -eq $true ) {
            $psScope = "AllUsers"
        } else {
            $psScope = "CurrentUser"
        }

        Write-Log -Message "Using installation scope: $( $psScope )" -Severity VERBOSE

        # Initialise counters (used across Process and reported in End)
        $Script:installCount_s = 0
        $Script:installCount_m = 0
        $Script:installCount_l = 0
        $Script:installCount_g = 0

    }


    Process {

        #-----------------------------------------------
        # CHECK POWERSHELL GALLERY REPOSITORY
        #-----------------------------------------------

        # TODO Implement version checks with [System.Version]::Parse("x.y.z")
        If ( $Script.Count -gt 0 -or $Module.Count -gt 0 ) {
            $powershellRepo = @( Get-PackageSource -ProviderName $powerShellSourceProviderName )
            If ( $powershellRepo.Count -eq 0 ) {
                Write-Log "No module/script repository found! Please make sure to add a repository to your machine!" -Severity WARNING
            }
        }

        # Install newer PackageManagement if needed
        $currentPM = get-installedmodule | where-object { $_.Name -eq "PackageManagement" }
        If ( $currentPM.Version -eq "1.0.0.1" -or $currentPM.Count -eq 0 ) {
            Write-Log "PackageManagement is outdated with v$( $currentPM.Version ). This is updating it now." -Severity WARNING
            Install-Package -Name PackageManagement -Force
        }

        # Install newer PowerShellGet if needed
        $currentPSGet = get-installedmodule | where-object { $_.Name -eq "PowerShellGet" }
        If ( $currentPSGet.Version -eq "1.0.0.1" -or $currentPSGet.Count -eq 0 ) {
            Write-Log "PowerShellGet is outdated with v$( $currentPSGet.Version ). This is updating it now." -Severity WARNING
            Install-Package -Name PowerShellGet -Force
        }

        If ( $Script.Count -gt 0 -or $Module.Count -gt 0 ) {

            try {

                # Get PowerShellGet sources
                $powershellRepo = @( Get-PackageSource -ProviderName $powerShellSourceProviderName )

                # See if PSRepo needs to get registered
                If ( $powershellRepo.count -ge 1 ) {
                    Write-Log -Message "You have at minimum 1 $( $powerShellSourceProviderName ) repository. Good!"  -Severity VERBOSE
                } elseif ( $powershellRepo.count -eq 0 ) {
                    Write-Log -Message "You don't have $( $powerShellSourceProviderName ) as a module/script source, do you want to register it now?" -Severity WARNING
                    $registerPsRepoDecision = $Host.UI.PromptForChoice("", "Register $( $powerShellSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
                    If ( $registerPsRepoDecision -eq "0" ) {

                        Register-PSRepository -Name $powerShellSourceName -SourceLocation $powerShellSourceLocation

                        # Load sources again
                        $powershellRepo = @( Get-PSRepository -ProviderName $powerShellSourceProviderName )

                    } else {
                        Write-Log "No package repository found! Please make sure to add a PowerShellGet repository to your machine!" -Severity ERROR
                        exit 0
                    }
                }

                # Choose repository
                If ( $powershellRepo.count -gt 1 ) {

                    $psGetSources = $powershellRepo.Name
                    $psGetSourceChoice = Request-Choice -title "Script/module Source" -message "Which $( $powerShellSourceProviderName ) repository do you want to use?" -choices $psGetSources
                    $psGetSource = $psGetSources[$psGetSourceChoice -1]

                } elseif ( $powershellRepo.count -eq 1 ) {

                    $psGetSource = $powershellRepo[0]

                } else {

                    Write-Log -Message "There is no $( $powerShellSourceProviderName ) repository available"  -Severity WARNING
                    Exit 0

                }

                # Do you want to trust that source?
                If ( $psGetSource.IsTrusted -eq $false ) {
                    Write-Log -Message "Your source is not trusted. Do you want to trust it now?" -Severity WARNING
                    $trustChoice = Request-Choice -title "Trust script/module Source" -message "Do you want to trust $( $psGetSource.Name )?" -choices @("Yes", "No")
                    If ( $trustChoice -eq 1 ) {
                        Set-PSRepository -Name $psGetSource.Name -InstallationPolicy Trusted
                    }
                }

            } catch {

                Write-Log -Message "There is a problem with the repository check!" -Severity WARNING

            }

        }


        #-----------------------------------------------
        # CHECK SCRIPT DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $Script.Count -gt 0 ) {

            try {

                Write-Log "Checking Script dependencies" -Severity VERBOSE

                $Script | ForEach-Object {

                    $psScript = $_

                    Write-Log "Checking script: $( $psScript )" -Severity VERBOSE

                    $installedScripts = Get-InstalledScript

                    If ( $ExcludeDependencies -eq $true ) {
                        $psScriptDependencies = Find-Script -Name $psScript
                    } else {
                        $psScriptDependencies = Find-Script -Name $psScript -IncludeDependencies
                    }

                    $psScriptDependencies | ForEach-Object {

                        $scr = $_

                        If ( $installedScripts.Name -contains $scr.Name ) {
                            Write-Log -Message "Script $( $scr.Name ) is already installed" -Severity VERBOSE

                            $alreadyInstalledScript = $installedScripts | Where-Object { $_.Name -eq $scr.Name }

                            If ( $scr.Version -gt $alreadyInstalledScript.Version ) {
                                Write-Log -Message "Script $( $scr.Name ) is installed with an older version $( $alreadyInstalledScript.Version ) than the available version $( $scr.Version )" -Severity VERBOSE
                                Update-Script -Name $scr.Name
                                $Script:installCount_s += 1
                            } else {
                                Write-Log -Message "No need to update $( $scr.Name )" -Severity VERBOSE
                            }
                        } else {
                            Write-Log -Message "Installing Script $( $scr.Name )" -Severity VERBOSE
                            Install-Script -Name $scr.Name -Scope $psScope
                            $Script:installCount_s += 1
                        }

                    }

                }

            } catch {

                Write-Log -Message "Cannot install scripts!" -Severity WARNING

            }

        } else {

            Write-Log "There is no script to install" -Severity VERBOSE

        }


        #-----------------------------------------------
        # CHECK MODULES DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $Module.count -gt 0 ) {

            try {

                Write-Log "Checking Module dependencies" -Severity VERBOSE

                $Module | Where-Object { $_ -notin @("PowerShellGet","PackageManagement") } | ForEach-Object {

                    $psModule = $_

                    Write-Log "Checking module: $( $psModule )" -Severity VERBOSE

                    $installedModules = Get-InstalledModule

                    If ( $ExcludeDependencies -eq $true ) {
                        $psModuleDependencies = Find-Module -Name $psModule
                    } else {
                        $psModuleDependencies = Find-Module -Name $psModule -IncludeDependencies
                    }

                    $psModuleDependencies | ForEach-Object {

                        $mod = $_

                        If ( $installedModules.Name -contains $mod.Name ) {
                            Write-Log -Message "Module $( $mod.Name ) is already installed" -Severity VERBOSE

                            $alreadyInstalledModule = $installedModules | Where-Object { $_.Name -eq $mod.Name }

                            If ( $mod.Version -gt $alreadyInstalledModule.Version ) {
                                Write-Log -Message "Module $( $mod.Name ) is installed with an older version $( $alreadyInstalledModule.Version ) than the available version $( $mod.Version )" -Severity VERBOSE
                                Update-Module -Name $mod.Name
                                $Script:installCount_m += 1
                            } else {
                                Write-Log -Message "No need to update $( $mod.Name )" -Severity VERBOSE
                            }
                        } else {
                            Write-Log -Message "Installing Module $( $mod.Name )" -Severity VERBOSE
                            Install-Module -Name $mod.Name -Scope $psScope -AllowClobber
                            $Script:installCount_m += 1
                        }

                    }

                }

            } catch {

                Write-Log -Message "Cannot install modules!" -Severity WARNING

            }

        } else {

            Write-Log "There is no module to install" -Severity VERBOSE

        }


        #-----------------------------------------------
        # CHECK PACKAGES NUGET REPOSITORY
        #-----------------------------------------------

        If ( $GlobalPackage.Count -gt 0 -or $LocalPackage.Count -gt 0 ) {

            try {

                # Get NuGet sources
                $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName )

                # See if Nuget needs to get registered
                If ( $sources.count -ge 1 ) {
                    Write-Log -Message "You have at minimum 1 $( $packageSourceProviderName ) repository. Good!" -Severity VERBOSE
                } elseif ( $sources.count -eq 0 ) {
                    Write-Log -Message "You don't have $( $packageSourceProviderName ) as a PackageSource, do you want to register it now?" -Severity WARNING
                    $registerNugetDecision = $Host.UI.PromptForChoice("", "Register $( $packageSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
                    If ( $registerNugetDecision -eq "0" ) {

                        Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName

                        # Load sources again
                        $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName )

                    } else {
                        Write-Log "No package repository found! Please make sure to add a NuGet repository to your machine!" -Severity ERROR
                        exit 0
                    }
                }

                # Choose repository
                If ( $sources.count -gt 1 ) {

                    $packageSources = $sources.Name
                    $packageSourceChoice = Request-Choice -title "PackageSource" -message "Which $( $packageSourceProviderName ) repository do you want to use?" -choices $packageSources
                    $packageSource = $sources[$packageSourceChoice -1]

                } elseif ( $sources.count -eq 1 ) {

                    $packageSource = $sources[0]

                } else {

                    Write-Log -Message "There is no $( $packageSourceProviderName ) repository available" -Severity WARNING
                    Exit 0

                }

                # Do you want to trust that source?
                If ( $packageSource.IsTrusted -eq $false ) {
                    Write-Log -Message "Your source is not trusted. Do you want to trust it now?" -Severity WARNING
                    $trustChoice = Request-Choice -title "Trust Package Source" -message "Do you want to trust $( $packageSource.Name )?" -choices @("Yes", "No")
                    If ( $trustChoice -eq 1 ) {
                        Set-PackageSource -Name $packageSource.Name -Trusted
                    }
                }

            } catch {

                Write-Log -Message "There is a problem with the repository" -Severity WARNING

            }

        }


        #-----------------------------------------------
        # CHECK LOCAL AND GLOBAL PACKAGES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $LocalPackage.count -gt 0 -or $GlobalPackage.Count -gt 0) {

            try {

                Write-Log "Check lib folder" -Severity VERBOSE

                If ( (Test-Path -Path $LocalPackageFolder) -eq $false ) {
                    New-Item -Name $LocalPackageFolder -ItemType Directory
                }

                Write-Log "Checking package dependencies with $( $packageSource.Name )" -Severity VERBOSE

                $localPackages = Get-Package -Destination $LocalPackageFolder
                $globalPackages = Get-Package
                $installedPackages = $localPackages + $globalPackages
                $packagesToInstall = [System.Collections.ArrayList]@()
                @( $LocalPackage + $GlobalPackage ) | ForEach-Object {

                    $psPackage = $_
                    $globalFlag = $false
                    $pkg = [System.Collections.ArrayList]@()
                    If ( $GlobalPackage -contains $psPackage ) {
                        $globalFlag = $true
                    }

                    Write-Log "Checking package: $( $psPackage )" -severity VERBOSE

                    If ( ($psPackage.gettype()).Name -eq "PsCustomObject" ) {
                        If ( $null -eq $psPackage.version ) {
                            Write-Verbose "Looking for $( $psPackage.name ) without specific version."
                            If ( $ExcludeDependencies -eq $true ) {
                                [void]@( Find-Package $psPackage.name -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)})
                            } else {
                                [void]@( Find-Package $psPackage.name -IncludeDependencies -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)})
                            }
                        } else {
                            Write-Verbose "Looking for $( $psPackage.name ) with version $( $psPackage.version )"
                            If ( $ExcludeDependencies -eq $true ) {
                                [void]@( Find-Package $psPackage.name -Source $packageSource.Name -ErrorAction Continue -RequiredVersion $psPackage.version ).foreach({$pkg.add($_)})
                            } else {
                                [void]@( Find-Package $psPackage.name -IncludeDependencies -Source $packageSource.Name -ErrorAction Continue -RequiredVersion $psPackage.version ).foreach({$pkg.add($_)})
                            }
                        }
                    } else {
                        Write-Verbose "Looking for $( $psPackage ) without specific version"
                        If ( $ExcludeDependencies -eq $true ) {
                            [void]@( Find-Package $psPackage -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)})
                        } else {
                            [void]@( Find-Package $psPackage -IncludeDependencies -Source $packageSource.Name -ErrorAction Continue ).foreach({$pkg.add($_)})
                        }
                    }

                    $pkg | ForEach-Object {
                        $p = $_
                        $pd = [PSCustomObject]@{
                            "GlobalFlag" = $globalFlag
                            "Package"    = $p
                            "Name"       = $p.Name
                            "Version"    = $p.Version
                        }
                        [void]$packagesToInstall.Add($pd)
                    }

                }

                Write-Log -Message "Done with searching for $( $packagesToInstall.Count ) packages"

                $pack = $packagesToInstall | Where-Object { $_.Package.Summary -notlike "*not reference directly*" -and $_.Package.Name -notlike "Xamarin.*"} | Where-Object { $_.Package.Source -eq $packageSource.Name } | Sort-Object Name, Version -Unique -Descending
                Write-Log -Message "This is likely to install $( $pack.Count ) packages"

                $i = 0
                $pack | ForEach-Object {

                    $p = $_

                    If ( $p.GlobalFlag -eq $true ) {
                        Write-Log -message "Installing $( $p.Package.Name ) with version $( $p.Package.version ) from $( $p.Package.Source ) globally"
                        Install-Package -Name $p.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Version -SkipDependencies -Force
                        $Script:installCount_g += 1
                    } else {
                        Write-Log -message "Installing $( $p.Name ) with version $( $p.version ) from $( $p.Package.Source ) locally"
                        Install-Package -Name $p.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Version -SkipDependencies -Force -Destination $LocalPackageFolder
                        $Script:installCount_l += 1
                    }

                    Write-Progress -Activity "Package installation in progress" -Status "$( [math]::Round($i/$pack.Count*100) )% Complete:" -PercentComplete ([math]::Round($i/$pack.Count*100))
                    $i += 1

                }

            } catch {

                Write-Log -Message "Cannot install local packages!" -Severity WARNING

            }

        } else {

            Write-Log "There is no package to install" -Severity VERBOSE

        }

        # Reset the process ID if another module overrode it
        Set-ProcessId -Id $processId

    }


    End {

        #-----------------------------------------------
        # STATUS
        #-----------------------------------------------

        Write-Log -Message "STATUS:" -Severity INFO
        Write-Log -Message "  $( $Script:installCount_l ) local packages installed into '$( $LocalPackageFolder )'" -Severity INFO
        Write-Log -Message "  $( $Script:installCount_g ) global packages installed" -Severity INFO
        Write-Log -Message "  $( $Script:installCount_m ) modules installed with scope '$( $psScope )'" -Severity INFO
        Write-Log -Message "  $( $Script:installCount_s ) scripts installed with scope '$( $psScope )'" -Severity INFO


        #-----------------------------------------------
        # FINISHING
        #-----------------------------------------------

        $processEnd = [datetime]::now
        $processDuration = New-TimeSpan -Start $processStart -End $processEnd
        Write-Log -Message "Done! Needed $( [int]$processDuration.TotalSeconds ) seconds in total" -Severity INFO

        Write-Log -Message "Logfile override: $( Get-LogfileOverride )"

        If ( $KeepLogfile -eq $false -and $null -ne $getLogfile -and '' -ne $getLogfile ) {
            Write-Log -Message "Changing logfile back to '$( $currentLogfile )'"
            Set-Logfile -Path $currentLogfile
        }

        # Set explicitly verbose output back
        If ( $SuppressWarnings -ne $true -and $PSBoundParameters["Verbose"].IsPresent -eq $true -and $PSBoundParameters["Verbose"] -eq $True) {
            $VerbosePreference = $originalVerbosity
        }

    }

}
