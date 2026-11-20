
Function Install-Dependency {

<#
.SYNOPSIS
    Downloads and installs the latest versions of some modules and packages (saved in current folder or machine folder) from the PowerShell Gallery and NuGet.
.DESCRIPTION
    Function to install dependencies from the PowerShell Gallery and NuGet. It is possible to install modules and packages.
    The packages can be installed from the PowerShell Gallery and packages from a NuGet repository.
    Packages can defined as a raw string array or as a pscustomobject with a specific version number.

    Uses Get-PSEnvironment (from the ImportDependency module) to discover already-installed modules and
    local/global NuGet packages, so it only installs or updates what is actually missing or outdated.

    Please make sure to have the Modules WriteLog and ImportDependency, and PowerShellGet (>= 2.2.4), installed.

.EXAMPLE
    Install-Dependency -Module "WriteLog" -LocalPackage "SQLitePCLRaw.core", "Npgsql" -Verbose
.EXAMPLE
    $packages = [Array]@(
        [PSCustomObject]@{
            name="Npgsql"
            version = "4.1.12"
            includeDependencies = $true
        }
    )
    Install-Dependency -Module "WriteLog" -LocalPackage $packages -Verbose

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
.PARAMETER KeepPackage
    By default, the raw .nupkg files left behind by Install-Package -Destination inside LocalPackageFolder are
    removed after a successful install (matching Install-NuGetPackage's default). The .nuspec is extracted out
    of each .nupkg first, so the package stays discoverable by Get-LocalPackage/Import-Dependency. Set this
    switch to keep the .nupkg files instead.
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
         [String[]]$Module = [Array]@()

        ,[Parameter(Mandatory=$false)]
         [Object[]]$GlobalPackage = [Array]@()   # String, or PSCustomObject with name/version -- [String[]] would coerce PSCustomObjects to strings before this even runs

        ,[Parameter(Mandatory=$false)]
         [Object[]]$LocalPackage = [Array]@()    # String, or PSCustomObject with name/version -- [String[]] would coerce PSCustomObjects to strings before this even runs

        ,[Parameter(Mandatory=$false)]
         [String]$LocalPackageFolder = "lib"

        ,[Parameter(Mandatory=$false)]
         [Switch]$ExcludeDependencies = $false

        ,[Parameter(Mandatory=$false)]
         [Switch]$KeepPackage = $false        # Keep the raw .nupkg files in LocalPackageFolder after install (default: remove them, like Install-NuGetPackage)

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

        # Check if this is Pwsh Core. Also gathers already-installed modules and
        # local/global NuGet packages (for the given folder) so the checks below
        # don't need to re-query PowerShellGet/PackageManagement themselves.
        $psEnv = Get-PSEnvironment -LocalPackageFolder $LocalPackageFolder
        $isCore = $psEnv.IsCore
        Write-Log -Message "Using PowerShell version $( $psEnv.PSVersion ) and $( $psEnv.PSEdition ) edition"

        # pwsh keeps the Windows PowerShell inbox module store (...\WindowsPowerShell\v1.0\Modules) on
        # PSModulePath for compatibility. On some hosts that store still ships the .NET Framework builds
        # of PackageManagement/PowerShellGet 1.0.0.1, which throw a TypeInitializationException in
        # Microsoft.PackageManagement.Internal.Utility.Plugin.DynamicType the moment any *-Package*
        # cmdlet touches them under pwsh (.NET 8+). Bind to a modern build (pwsh's own bundled one, or
        # any installed >= 1.4.7 / >= 2.0) before the first Get-PackageSource in Process.
        If ( $isCore -eq $true ) {
            $modernPackageManagement = Get-Module -Name PackageManagement -ListAvailable |
                Where-Object { $_.Version -ge [System.Version]"1.4.7" } | Sort-Object Version -Descending | Select-Object -First 1
            $modernPowerShellGet = Get-Module -Name PowerShellGet -ListAvailable |
                Where-Object { $_.Version -ge [System.Version]"2.0" } | Sort-Object Version -Descending | Select-Object -First 1
            If ( $null -ne $modernPackageManagement -and $null -ne $modernPowerShellGet ) {
                # Remove the (possibly stale/broken) copy loaded at session start, then re-import by
                # name with a minimum version so resolution can never pick the 1.0.0.1 inbox build.
                # -Global is essential: called from inside this module function, Import-Module would only
                # load them into InstallDependency's own scope. PowerShellGet's internal
                # "PackageManagement\Get-Package" calls then can't see that copy, try to load it again and
                # fail with "The module 'PackageManagement' could not be loaded".
                Get-Module -Name PackageManagement, PowerShellGet | Remove-Module -Force -ErrorAction SilentlyContinue
                Import-Module -Name PackageManagement -MinimumVersion 1.4.7 -Force -Global -ErrorAction SilentlyContinue
                Import-Module -Name PowerShellGet -MinimumVersion 2.0 -Force -Global -ErrorAction SilentlyContinue
                Write-Log -Message "Using PackageManagement v$( (Get-Module PackageManagement).Version ) and PowerShellGet v$( (Get-Module PowerShellGet).Version )" -Severity VERBOSE
            } else {
                Write-Log -Message "This pwsh has no PackageManagement >= 1.4.7 / PowerShellGet >= 2.0 available -- only the Windows PowerShell inbox 1.0.0.1 builds, which cannot be loaded from pwsh. Install them once from Windows PowerShell 5.1 ('Install-Module PowerShellGet -Force -AllowClobber -Scope CurrentUser') or via 'Install-PSResource PowerShellGet', then re-run." -Severity WARNING
            }
        }

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

        # A Store/MSIX pwsh's AllUsers module folder (C:\Program Files\WindowsApps\...\Modules) is
        # read-only even for administrators, so it always installs modules for the current user.
        $isStorePwsh = $isCore -eq $true -and $PSHOME -like "*\WindowsApps\*"
        If ( $psEnv.IsElevated -eq $true -and $isStorePwsh -eq $false ) {
            $psScope = "AllUsers"
        } else {
            $psScope = "CurrentUser"
        }

        Write-Log -Message "Using installation scope: $( $psScope )" -Severity VERBOSE

        # Initialise counters (used across Process and reported in End)
        $Script:installCount_m = 0
        $Script:installCount_l = 0
        $Script:installCount_g = 0

    }


    Process {

        #-----------------------------------------------
        # CHECK POWERSHELL GALLERY REPOSITORY
        #-----------------------------------------------

        # TODO Implement version checks with [System.Version]::Parse("x.y.z")
        If ( $Module.Count -gt 0 ) {
            $powershellRepo = @( Get-PackageSource -ProviderName $powerShellSourceProviderName )
            If ( $powershellRepo.Count -eq 0 ) {
                Write-Log "No module repository found! Please make sure to add a repository to your machine!" -Severity WARNING
            }
        }

        # Install newer PackageManagement if needed (already known from Get-PSEnvironment, no extra lookup needed).
        # -ProviderName disambiguates against NuGet.org, which coincidentally also hosts a package
        # named "PackageManagement" -- without it, Install-Package errors with "multiple packages matched".
        If ( $psEnv.PackageManagement -eq "1.0.0.1" -or [String]::IsNullOrEmpty( $psEnv.PackageManagement ) ) {
            Write-Log "PackageManagement is outdated with v$( $psEnv.PackageManagement ). This is updating it now." -Severity WARNING
            try {
                # -Scope: without it Install-Package defaults to AllUsers, whose target for a Store/MSIX
                # pwsh is the read-only C:\Program Files\WindowsApps\...\Modules -- a non-elevated run
                # then silently installs nothing.
                Install-Package -Name PackageManagement -ProviderName $powerShellSourceProviderName -Scope $psScope -Force -AllowClobber | Out-Null
                # The installed binaries won't be used until re-imported: 'Import-Module -Force' merely stacks
                # the new version alongside the old one still loaded in this process, and cmdlets keep resolving
                # to the old module. Removing first, then re-importing the modern build (never the 1.0.0.1
                # inbox one), is what actually swaps the active binaries in-session.
                Remove-Module -Name PackageManagement -Force -ErrorAction SilentlyContinue
                Import-Module -Name PackageManagement -MinimumVersion 1.4.7 -Global -ErrorAction Stop
                Write-Log "PackageManagement re-imported as v$( (Get-Module PackageManagement).Version )" -Severity VERBOSE
            } catch {
                Write-Log "Could not update PackageManagement: $( $_.Exception.Message )" -Severity WARNING
            }
        }

        # Install newer PowerShellGet if needed (already known from Get-PSEnvironment, no extra lookup needed)
        If ( $psEnv.PowerShellGet -eq "1.0.0.1" -or [String]::IsNullOrEmpty( $psEnv.PowerShellGet ) ) {
            Write-Log "PowerShellGet is outdated with v$( $psEnv.PowerShellGet ). This is updating it now." -Severity WARNING
            try {
                Install-Package -Name PowerShellGet -ProviderName $powerShellSourceProviderName -Scope $psScope -Force -AllowClobber | Out-Null
                # Same in-session reload issue as PackageManagement above.
                Remove-Module -Name PowerShellGet -Force -ErrorAction SilentlyContinue
                Import-Module -Name PowerShellGet -MinimumVersion 2.0 -Global -ErrorAction Stop
                Write-Log "PowerShellGet re-imported as v$( (Get-Module PowerShellGet).Version )" -Severity VERBOSE
            } catch {
                Write-Log "Could not update PowerShellGet: $( $_.Exception.Message )" -Severity WARNING
            }
        }

        If ( $Module.Count -gt 0 ) {

            $psGetSource = $null

            try {

                # Get PowerShellGet sources
                $powershellRepo = @( Get-PackageSource -ProviderName $powerShellSourceProviderName )

                # See if PSRepo needs to get registered
                If ( $powershellRepo.count -ge 1 ) {
                    Write-Log -Message "You have at minimum 1 $( $powerShellSourceProviderName ) repository. Good!"  -Severity VERBOSE
                } elseif ( $powershellRepo.count -eq 0 ) {
                    # Auto-register the well-known PSGallery instead of prompting: a $Host.UI.PromptForChoice
                    # here hangs any non-interactive/service/CI run, and the previous 'exit 0' on "No" would
                    # terminate the whole host process. A caller that wants a different gallery can register
                    # it before calling Install-Dependency.
                    Write-Log -Message "No $( $powerShellSourceProviderName ) repository registered -- registering the default PSGallery now" -Severity WARNING
                    try {
                        Register-PSRepository -Default -ErrorAction Stop | Out-Null
                    } catch {
                        Register-PSRepository -Name $powerShellSourceName -SourceLocation $powerShellSourceLocation -InstallationPolicy Trusted -ErrorAction SilentlyContinue | Out-Null
                    }
                    $powershellRepo = @( Get-PackageSource -ProviderName $powerShellSourceProviderName -ErrorAction SilentlyContinue )
                    # A still-empty $powershellRepo falls through to the "no repository available" branch
                    # below, which leaves $psGetSource $null and is turned into a terminating error after
                    # the catch.
                }

                # Choose repository. Prefer PSGallery when present, otherwise the first one -- a
                # Request-Choice prompt here would hang non-interactive/service/CI runs.
                If ( $powershellRepo.count -ge 1 ) {

                    $psGetSource = $powershellRepo | Where-Object { $_.Name -eq $powerShellSourceName } | Select-Object -First 1
                    If ( $null -eq $psGetSource ) {
                        $psGetSource = $powershellRepo[0]
                    }
                    If ( $powershellRepo.count -gt 1 ) {
                        Write-Log -Message "Multiple $( $powerShellSourceProviderName ) repositories found -- using '$( $psGetSource.Name )'" -Severity VERBOSE
                    }

                } else {

                    Write-Log -Message "There is no $( $powerShellSourceProviderName ) repository available"  -Severity WARNING
                    $psGetSource = $null

                }

                # Not prompting to change the repository's trust setting -- that Request-Choice blocks
                # non-interactive runs, and flipping a user's repo trust is a surprising side effect.
                # The module installs below pass -Force so an untrusted PSGallery does not prompt either.
                If ( $null -ne $psGetSource -and $psGetSource.IsTrusted -eq $false ) {
                    Write-Log -Message "Repository '$( $psGetSource.Name )' is not marked trusted; installing with -Force so it does not prompt. Run 'Set-PSRepository -Name $( $psGetSource.Name ) -InstallationPolicy Trusted' to silence this." -Severity VERBOSE
                }

            } catch {

                Write-Log -Message "There is a problem with the repository check!" -Severity WARNING

            }

            # Outside the try so it actually stops the run (unlike the old 'exit 0', which killed the
            # whole host process): if we still have no gallery, module installs below cannot work.
            If ( $null -eq $psGetSource ) {
                throw "No usable $( $powerShellSourceProviderName ) repository is available. Register one (e.g. 'Register-PSRepository -Default') and re-run Install-Dependency."
            }

        }


        #-----------------------------------------------
        # CHECK MODULES DEPENDENCIES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $Module.count -gt 0 ) {

            try {

                Write-Log "Checking Module dependencies" -Severity VERBOSE

                # Already known from Get-PSEnvironment (scanned once in Begin), so no
                # per-module Get-InstalledModule round-trip is needed here anymore.
                $installedModules = @( $psEnv.InstalledModules | Where-Object { $null -ne $_ } )

                $Module | Where-Object { $_ -notin @("PowerShellGet","PackageManagement") } | ForEach-Object {

                    $psModule = $_

                    Write-Log "Checking module: $( $psModule )" -Severity VERBOSE

                    If ( $ExcludeDependencies -eq $true ) {
                        $psModuleDependencies = Find-Module -Name $psModule
                    } else {
                        $psModuleDependencies = Find-Module -Name $psModule -IncludeDependencies
                    }

                    $psModuleDependencies | ForEach-Object {

                        $mod = $_
                        $installedMatches = @( $installedModules | Where-Object { $_.Name -eq $mod.Name } )

                        If ( $installedMatches.Count -gt 0 ) {

                            Write-Log -Message "Module $( $mod.Name ) is already installed" -Severity VERBOSE

                            # Multiple entries can exist per module (e.g. WindowsPowerShell vs PSCore paths), take the newest
                            $alreadyInstalledModule = $installedMatches | Sort-Object { [version]( $_.Version -replace '[^0-9.]', '0' ) } -Descending | Select-Object -First 1

                            If ( [version]( $mod.Version.ToString() -replace '[^0-9.]', '0' ) -gt [version]( $alreadyInstalledModule.Version -replace '[^0-9.]', '0' ) ) {
                                Write-Log -Message "Module $( $mod.Name ) is installed with an older version $( $alreadyInstalledModule.Version ) than the available version $( $mod.Version )" -Severity VERBOSE
                                Update-Module -Name $mod.Name -Force | Out-Null
                                $Script:installCount_m += 1
                            } else {
                                Write-Log -Message "No need to update $( $mod.Name )" -Severity VERBOSE
                            }
                        } else {
                            Write-Log -Message "Installing Module $( $mod.Name )" -Severity VERBOSE
                            # -Force so an untrusted PSGallery does not raise an interactive
                            # "Are you sure you want to install from an untrusted repository?" prompt.
                            Install-Module -Name $mod.Name -Scope $psScope -AllowClobber -Force | Out-Null
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

            $packageSource = $null

            try {

                # Get NuGet sources
                $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName )

                # See if Nuget needs to get registered
                If ( $sources.count -ge 1 ) {
                    Write-Log -Message "You have at minimum 1 $( $packageSourceProviderName ) repository. Good!" -Severity VERBOSE
                } elseif ( $sources.count -eq 0 ) {
                    # Auto-register the public NuGet v2 feed instead of prompting (a PromptForChoice hangs
                    # non-interactive runs; the previous 'exit 0' on "No" terminated the whole host).
                    Write-Log -Message "No $( $packageSourceProviderName ) package source registered -- registering $( $packageSourceName ) ($( $packageSourceLocation )) now" -Severity WARNING
                    Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName -Trusted -ErrorAction SilentlyContinue | Out-Null
                    $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName -ErrorAction SilentlyContinue )
                    # A still-empty $sources falls through to the "no repository available" branch below,
                    # which leaves $packageSource $null and is turned into a terminating error after the catch.
                }

                # Choose repository. Prefer the feed this function registers ($packageSourceName),
                # otherwise the first one -- a Request-Choice prompt here would hang headless runs.
                If ( $sources.count -ge 1 ) {

                    $packageSource = $sources | Where-Object { $_.Name -eq $packageSourceName } | Select-Object -First 1
                    If ( $null -eq $packageSource ) {
                        $packageSource = $sources[0]
                    }
                    If ( $sources.count -gt 1 ) {
                        Write-Log -Message "Multiple $( $packageSourceProviderName ) sources found -- using '$( $packageSource.Name )'" -Severity VERBOSE
                    }

                } else {

                    Write-Log -Message "There is no $( $packageSourceProviderName ) repository available" -Severity WARNING
                    $packageSource = $null

                }

                # Not prompting to change the source's trust setting -- Request-Choice blocks
                # non-interactive runs. The package installs below already pass -Force.
                If ( $null -ne $packageSource -and $packageSource.IsTrusted -eq $false ) {
                    Write-Log -Message "Package source '$( $packageSource.Name )' is not marked trusted; installing with -Force so it does not prompt." -Severity VERBOSE
                }

            } catch {

                Write-Log -Message "There is a problem with the repository" -Severity WARNING

            }

            # Outside the try so it actually stops the run (unlike the old 'exit 0', which killed the
            # whole host process): the package install loop below needs a resolved $packageSource.
            If ( $null -eq $packageSource ) {
                throw "No usable $( $packageSourceProviderName ) package source is available. Register one (e.g. 'Register-PackageSource -Name ""$( $packageSourceName )"" -Location ""$( $packageSourceLocation )"" -ProviderName $( $packageSourceProviderName )') and re-run Install-Dependency."
            }

        }


        #-----------------------------------------------
        # CHECK LOCAL AND GLOBAL PACKAGES FOR INSTALLATION AND UPDATE
        #-----------------------------------------------

        If ( $LocalPackage.count -gt 0 -or $GlobalPackage.Count -gt 0) {

            try {

                Write-Log "Check lib folder" -Severity VERBOSE

                If ( (Test-Path -Path $LocalPackageFolder) -eq $false ) {
                    New-Item -Path $LocalPackageFolder -ItemType Directory
                }

                Write-Log "Checking package dependencies with $( $packageSource.Name )" -Severity VERBOSE

                # Already known from Get-PSEnvironment (scanned once in Begin for $LocalPackageFolder),
                # so no separate Get-Package round-trip is needed here anymore.
                $installedLocalPackages  = @( $psEnv.InstalledLocalPackages  | Where-Object { $null -ne $_ } )
                $installedGlobalPackages = @( $psEnv.InstalledGlobalPackages | Where-Object { $null -ne $_ } )
                $packagesToInstall = [System.Collections.ArrayList]@()
                @( $LocalPackage + $GlobalPackage ) | ForEach-Object {

                    $psPackage = $_
                    $globalFlag = $false
                    $pkg = [System.Collections.ArrayList]@()
                    If ( $GlobalPackage -contains $psPackage ) {
                        $globalFlag = $true
                    }

                    # An explicit pinned version (e.g. to keep an older, edition-specific build like
                    # DuckDB.NET 1.4.4 installed alongside a newer 1.5.0 for the same package Id) means
                    # this exact version is the thing that must exist on disk -- not "any version at
                    # least this new", which is the right semantics for an unpinned "give me latest" request
                    $isPinned = ( ($psPackage.gettype()).Name -eq "PsCustomObject" ) -and ( $null -ne $psPackage.version )

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

                    $installedForScope = If ( $globalFlag -eq $true ) { $installedGlobalPackages } else { $installedLocalPackages }

                    $pkg | ForEach-Object {

                        $p = $_
                        $installedPackageMatches = @( $installedForScope | Where-Object { $_.Id -eq $p.Name } )

                        If ( $installedPackageMatches.Count -gt 0 ) {

                            If ( $isPinned -eq $true ) {

                                # Exact version was explicitly requested -- only this exact version on disk
                                # satisfies it. A newer sibling version installed for another package Id
                                # purpose (e.g. a different PS edition) must not shadow this pinned install
                                $exactMatch = @( $installedPackageMatches | Where-Object { $_.Version -eq $p.Version.ToString() } )
                                If ( $exactMatch.Count -gt 0 ) {
                                    Write-Log -Message "Package $( $p.Name ) $( $p.Version ) is already installed ($( If ( $globalFlag ) { 'global' } else { 'local' } )), skipping" -Severity VERBOSE
                                    return
                                } else {
                                    Write-Log -Message "Package $( $p.Name ) $( $p.Version ) is pinned but not yet installed (other version(s) present: $( ( $installedPackageMatches.Version -join ', ' ) )), installing" -Severity VERBOSE
                                }

                            } else {

                                # Multiple copies can exist on disk (nuspec/zip reads), take the newest
                                $alreadyInstalledPackage = $installedPackageMatches | Sort-Object { [version]( $_.Version -replace '[^0-9.]', '0' ) } -Descending | Select-Object -First 1

                                If ( [version]( $alreadyInstalledPackage.Version -replace '[^0-9.]', '0' ) -ge [version]( $p.Version.ToString() -replace '[^0-9.]', '0' ) ) {
                                    Write-Log -Message "Package $( $p.Name ) is already installed with version $( $alreadyInstalledPackage.Version ) ($( If ( $globalFlag ) { 'global' } else { 'local' } )), skipping" -Severity VERBOSE
                                    return
                                } else {
                                    Write-Log -Message "Package $( $p.Name ) is installed with an older version $( $alreadyInstalledPackage.Version ) than the available version $( $p.Version )" -Severity VERBOSE
                                }

                            }

                        }

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

                # @() forces this to always be an array, even with 0 or 1 matches -- without it, a
                # single match collapses to a scalar object. Windows PowerShell 5.1 (Desktop, unlike
                # PS 6+) has no .Count on scalars, so $pack.Count below is $null, and dividing by it
                # in Write-Progress throws "Attempted to divide by zero", aborting the whole install
                $pack = @( $packagesToInstall | Where-Object { $_.Package.Summary -notlike "*not reference directly*" -and $_.Package.Name -notlike "Xamarin.*"} | Where-Object { $_.Package.Source -eq $packageSource.Name } | Sort-Object Name, Version -Unique -Descending )
                Write-Log -Message "This is likely to install $( $pack.Count ) packages"

                $i = 0
                $pack | ForEach-Object {

                    $p = $_

                    If ( $p.GlobalFlag -eq $true ) {
                        Write-Log -message "Installing $( $p.Package.Name ) with version $( $p.Package.version ) from $( $p.Package.Source ) globally"
                        Install-Package -Name $p.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Version -SkipDependencies -Force | Out-Null
                        $Script:installCount_g += 1
                    } else {
                        Write-Log -message "Installing $( $p.Name ) with version $( $p.version ) from $( $p.Package.Source ) locally"
                        Install-Package -Name $p.Name -Scope $psScope -Source $packageSource.Name -RequiredVersion $p.Version -SkipDependencies -Force -Destination $LocalPackageFolder | Out-Null
                        $Script:installCount_l += 1
                    }

                    Write-Progress -Activity "Package installation in progress" -Status "$( [math]::Round($i/$pack.Count*100) )% Complete:" -PercentComplete ([math]::Round($i/$pack.Count*100))
                    $i += 1

                }

                # Install-Package -Destination leaves the raw .nupkg file as a sibling of the
                # extracted lib/ref/runtimes folders. Only touches LocalPackageFolder, never the
                # global/machine package cache, which is shared state we should not clean up here.
                If ( $KeepPackage -eq $false -and $Script:installCount_l -gt 0 ) {
                    $nupkgFiles = @( Get-ChildItem -Path $LocalPackageFolder -Filter "*.nupkg" -Recurse -File -ErrorAction SilentlyContinue )
                    If ( $nupkgFiles.Count -gt 0 ) {
                        Write-Log -Message "Removing $( $nupkgFiles.Count ) .nupkg file(s) from '$( $LocalPackageFolder )' (use -KeepPackage to keep them)" -Severity VERBOSE
                        $nupkgFiles | ForEach-Object {

                            $nupkgFile = $_
                            $pkgFolder = $nupkgFile.DirectoryName

                            # Extract just the tiny .nuspec first so Get-LocalPackage (ImportDependency) can
                            # still discover this package via its fast nuspec path once the .nupkg is gone --
                            # without it, a package folder with only lib/ref/runtimes has no metadata source
                            # left at all and Import-Dependency silently stops finding it.
                            #
                            # Retried: Install-Package -Destination can still be holding a lock on the
                            # freshly written .nupkg for a moment (observed on Windows PowerShell 5.1's
                            # legacy PackageManagement NuGet provider), so an immediate open/delete can fail
                            # with a sharing violation. Never let that abort the rest of the install --
                            # worst case the .nupkg is just left behind for this one package.
                            $attempt = 0
                            $cleanedUp = $false
                            do {
                                $attempt += 1
                                try {
                                    $zip = [System.IO.Compression.ZipFile]::OpenRead($nupkgFile.FullName)
                                    try {
                                        $nuspecEntry = $zip.Entries | Where-Object { $_.FullName -like "*.nuspec" } | Select-Object -First 1
                                        If ( $null -ne $nuspecEntry ) {
                                            $nuspecPath = Join-Path $pkgFolder $nuspecEntry.Name
                                            If ( (Test-Path -Path $nuspecPath) -eq $false ) {
                                                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($nuspecEntry, $nuspecPath) | Out-Null
                                            }
                                        }
                                    } finally {
                                        $zip.Dispose()
                                    }

                                    Remove-Item -Path $nupkgFile.FullName -Force
                                    $cleanedUp = $true
                                } catch {
                                    If ( $attempt -ge 3 ) {
                                        Write-Log -Message "Could not remove '$( $nupkgFile.FullName )' after $( $attempt ) attempt(s): $( $_.Exception.Message )" -Severity WARNING
                                        $cleanedUp = $true
                                    } else {
                                        Start-Sleep -Milliseconds 300
                                    }
                                }
                            } while ( $cleanedUp -eq $false )

                        }
                    }
                }

            } catch {

                Write-Log -Message "Cannot install local packages! $( $_.Exception.Message )" -Severity WARNING

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
