
Function Import-Dependency {

    <#
    .SYNOPSIS
        Imports modules and global/local packages. Local packages are loaded by default from the .\lib folder in the current directory
    .DESCRIPTION
        Module to import dependencies from the PowerShell Gallery and NuGet.

        Please make sure to have the Modules WriteLog and PowerShellGet (>= 2.2.4) installed.

    .EXAMPLE
        Import-Dependency -Module WriteLog, AptecoPSFramework
    .EXAMPLE
        Import-Dependency -GlobalPackage MailKit
    .EXAMPLE
        Import-Dependency -LocalPackage MimeKit, Mailkit
    .EXAMPLE
        Import-Dependency -LocalPackageFolder lib -LoadWholePackageFolder # the default is a lib subfolder, so that does not need to be used

    .PARAMETER Module
        Array of modules to install on local machine via PowerShellGallery.
    .PARAMETER GlobalPackage
        Array of NuGet packages to install on local machine.
    .PARAMETER LocalPackage
        Array of NuGet packages to install in a subfolder of the current folder. Can be changed with parameter LocalPackageFolder.
    .PARAMETER LocalPackageFolder
        Folder name of the local package folder. Default is "lib".
    .PARAMETER InstallScriptAndModuleForCurrentUser
        By default, the modules and scripts will be installed for all users. If you want to install them only for the current user, then set this parameter to $true.
    .PARAMETER SuppressWarnings
        Flag to log warnings, but not put redirect to the host
    .NOTES
        Created by : gitfvb
    .LINK
        Project Site: https://github.com/Apteco/Install-Dependencies/tree/main/ImportDependency

    #>

    [CmdletBinding()]
    Param(

        #[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][String[]]$Script = [Array]@()              # Define specific scripts you want to load -> not needed as PATH will be added

        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [String[]]$Module = [Array]@()              # Define specific modules you want to load

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [String[]]$GlobalPackage = [Array]@()       # Define specific global package to load

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [String[]]$LocalPackage = [Array]@()        # Define a specific local package to load

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [String]$LocalPackageFolder = "lib"         # Where to find local packages

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [Switch]$LoadWholePackageFolder = $false    # Load whole local package folder

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [Switch]$SuppressWarnings = $false           # Flag to log warnings, but not put redirect to the host

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [Switch]$KeepLogfile = $false           # Flag to log warnings, but not put redirect to the host

    )

    Begin {

        Update-BackgroundJob

        #-----------------------------------------------
        # DEBUG
        #-----------------------------------------------
        <#
        Set-Location -Path "C:\Users\Florian\Downloads\dep2"
        $Module = [Array]@()              # Define specific modules you want to load
        $GlobalPackage = [Array]@()       # Define specific global package to load
        $LocalPackage = [Array]@()        # Define a specific local package to load
        $LocalPackageFolder = "lib"         # Where to find local packages
        $LoadWholePackageFolder = $true    # Load whole local package folder
        $VerbosePreference = "Continue"
        #>


        #-----------------------------------------------
        # INPUT DEFINITION
        #-----------------------------------------------

        # TODO fill out

        # SETTTINGS FOR LOADING PACKAGES
        # TODO [ ] Define a priority later for .net versions, but use fixed ones at the moment
        # These lists will be checked in the defined order
        $dotnetDesktopVersions = @("net48","net47","net462","netstandard2.1","netstandard2.0","netstandard1.5","netstandard1.3","netstandard1.1","netstandard1.0")
        $dotnetCoreVersions = @("net6.0","net6.0-windows","net5.0","net5.0-windows","netcore50")
        $targetFolders = @("ref","lib")
        #$runtimes = @("win-x64","win-x86","win10","win7","win")


        #-----------------------------------------------
        # START
        #-----------------------------------------------

        # TODO use the parent logfile if used by a module
        $processStart = [datetime]::now
        $getLogfile = Get-Logfile
        If ( $KeepLogfile -eq $false -and $null -ne $getLogfile ) {
            $currentLogfile = Get-Logfile
            $logfile = ".\dependencies_import.log"
            $logfileAbsolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($logfile)
            Set-Logfile -Path $logfileAbsolute
            Write-Log -message "----------------------------------------------------" -Severity VERBOSE
            Write-Log -Message "Changed logfile from '$( $currentLogfile )' to '$( $logfileAbsolute )'"
        } else {
            $logfile = ".\dependencies_import.log"
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

        Write-Log -Message "Using PowerShell version $( $Script:psVersion ) and $( $Script:powerShellEdition ) edition"
        Write-Log -Message "Using OS: $( $Script:os )"
        Write-Log -Message "Using architecture: $( $Script:architecture )"

        # Check elevation
        if ($Script:os -eq "Windows") {
            Write-Log -Message "User: $( $Script:executingUser )"
            Write-Log -Message "Elevated: $( $Script:isElevated )"
        } else {
            Write-Log -Message "No user and elevation check due to OS"
        }

        # Check environment and process
        Write-Log -Message "OS is 64bit: $( $Script:is64BitOS )"
        Write-Log -Message "Process is 64bit: $( $Script:is64BitProcess )"

        # Decide which lib priority to use
        If ( $Script:isCore -eq $true ) {
            $dotnetVersions = $dotnetCoreVersions + $dotnetDesktopVersions
        } else {
            $dotnetVersions = $dotnetDesktopVersions
        }


    }

    Process {


        #-----------------------------------------------
        # LOAD MODULES
        #-----------------------------------------------

        $modCount = 0
        $successfulModules = [Array]@()
        $failedModules = [Array]@()
        $Module | Where-Object { @("WriteLog", "ImportDependency") -notcontains $_ } | ForEach-Object {
            $mod = $_
            try {
                Write-Verbose "Loading $( $mod )"
                Import-Module -Name $mod -ErrorAction Stop
                $successfulModules += $mod
                $modCount += 1
            } catch {
                $failedModules += $mod
                Write-Warning -Message "Failed loading module '$( $mod )'" -Verbose #-Severity WARNING
            }
        }

        # Reset the process ID if another module loaded it
        Set-ProcessId -Id $processId

        Write-Log -Message "Loaded $( $modCount ) modules" #-Severity VERBOSE
        Write-Log -Message "  Success: $( $successfulModules -join ", " )" #-Severity VERBOSE
        Write-Log -Message "  Failed: $( $failedModules -join ", " )" #-Severity VERBOSE


        #-----------------------------------------------
        # LOAD KERNEL32 FOR ALTERNATIVE DLL LOADING
        #-----------------------------------------------

        $kernel32Loaded = $false
        If ( ( $LocalPackage.Count -gt 0 -or $GlobalPackage.Count -gt 0 -or $LoadWholePackageFolder -eq $true ) -and $Script:os -eq "Windows" ) {

            Add-Type -Language CSharp -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;

            public static class Kernel32 {
                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern IntPtr LoadLibrary(string lpFileName);
                public static string GetError() { return Marshal.GetLastWin32Error().ToString(); }
                public static bool GetEnv() { return Environment.Is64BitProcess; }

            }
"@

            $kernel32Loaded = $true

            # Log Kernel32 environment
            Write-Log -Message "[kernel32] is 64bit: $( [Kernel32]::GetEnv() )"

        }

        Write-Log "[kernel32] loaded: $( $kernel32Loaded )"


        # Taken from https://www.powershellgallery.com/packages/Az.Storage/5.10.0/Content/Az.Storage.psm1
        <#

        function Preload-Assembly {
            param (
                [string]
                $AssemblyDirectory
            )
            if($PSEdition -eq 'Desktop' -and (Test-Path $AssemblyDirectory -ErrorAction Ignore))
            {
                try
                {
                    Get-ChildItem -ErrorAction Stop -Path $AssemblyDirectory -Filter "*.dll" | ForEach-Object {
                        try
                        {
                            Add-Type -Path $_.FullName -ErrorAction Ignore | Out-Null
                        }
                        catch {
                            Write-Verbose $_
                        }
                    }
                }
                catch {}
            }
        }

        #>


        #-----------------------------------------------
        # LOAD LIB FOLDER (DLLs AND ASSEMBLIES)
        #-----------------------------------------------

        Write-Log -Message "Using runtimes in this order: $( $Script:runtimePreference -join ", " )"

        $successCounter = 0
        $failureCounter = 0
        $runtimeSuccessCounter = 0
        $runtimePossibleSuccessCounter = 0
        $runtimeFailureCounter = 0

        If ( $LocalPackage.Count -gt 0 -or $GlobalPackage.Count -gt 0 -or $LoadWholePackageFolder -eq $true) {

            Write-Log -message "Loading libs..."

            # Load the packages we can find
            If ( $LocalPackage.Count -gt 0 -or $LoadWholePackageFolder -eq $true) {
                $localPackages = PackageManagement\Get-Package -Destination $LocalPackageFolder
            }
            $globalPackages = PackageManagement\Get-Package -ProviderName NuGet # TODO This can be replaced with Get-PSEnvironment

            # Filter the packages
            $packagesToLoad = [System.Collections.ArrayList]@()
            $packagesToLoad.AddRange( @( $globalPackages | Where-Object { $_.Name -in $GlobalPackage } ))

            # Decide whether to load all local packages or just a selection
            If ( $LoadWholePackageFolder -eq $true ) {
                $packagesToLoad.AddRange( @( $localPackages ))
            } else {
                $packagesToLoad.AddRange( @($localPackages | Where-Object { $_.Name -in $LocalPackage } ))
            }

            Write-Log -Message "There are $( $packagesToLoad.Count ) packages to load"

            # Load through the packages objects instead of going through the folders
            $i = 0
            $packagesToLoad | ForEach-Object {

                # This is the whole path to the nupkg, but we can use the parent directory
                $pkg = Get-Item -Path $_.source
                $package = $pkg.Directory

                # Counters
                $packageLoaded = 0
                $loadError = 0

                # Check the package ref folder
                If ( ( Test-Path -Path "$( $package.FullName )/ref" ) -eq $true ) {
                    $dotnetFolder = Get-BestReferencePath -PackageRoot $package.FullName
                    If ( (Test-Path -Path $dotnetFolder)  -eq $true -and $packageLoaded -eq 0) {
                        Get-ChildItem -Path $dotnetFolder -Filter "*.dll" | ForEach-Object {
                            $f = $_
                            #"Loading $( $f.FullName )"
                            try {
                                Write-Verbose -Message "Loading package ref '$( $f.FullName )'"
                                If( $Script:isCore ) {
                                    # For PowerShell Core use Add-Type first
                                    Add-Type -Path $f.FullName -ErrorAction Stop | Out-Null
                                } else {
                                    [void][Reflection.Assembly]::LoadFile($f.FullName)
                                }
                                $packageLoaded = 1
                                #"Loaded $( $dotnetFolder )"
                            } catch {
                                Write-Verbose -Message "Failed! Loading package ref '$( $f.FullName )'"
                                $loadError = 1
                            }
                        }
                    }
                }


                # Check the package lib folder
                if ( ( Test-Path -Path "$( $package.FullName )/lib" ) -eq $true -and $packageLoaded -eq 0) {
                    $dotnetFolder = Get-BestFrameworkPath -PackageRoot $package.FullName
                    If ( (Test-Path -Path $dotnetFolder)  -eq $true -and $packageLoaded -eq 0) {
                        Get-ChildItem -Path $dotnetFolder -Filter "*.dll" | ForEach-Object {
                            $f = $_
                            #"Loading $( $f.FullName )"
                            try {
                                Write-Verbose -Message "Loading package lib '$( $f.FullName )'"
                                If( $Script:isCore ) {
                                    # For PowerShell Core use Add-Type first
                                    Add-Type -Path $f.FullName -ErrorAction Stop | Out-Null
                                } else {
                                    [void][Reflection.Assembly]::LoadFile($f.FullName)
                                }
                                $packageLoaded = 1
                                #"Loaded $( $dotnetFolder )"
                            } catch {
                                Write-Verbose -Message "Failed! Loading package lib '$( $f.FullName )'"
                                $loadError = 1
                            }
                        }
                    }
                }

                # Output the current status
                If ($packageLoaded -eq 1) {
                    $successCounter += 1
                    #"OK lib/ref $( $f.fullname )"
                } elseif ($loadError -eq 1) {
                    #"ERROR lib/ref $( $f.fullname )"
                    $failureCounter += 1
                } else {
                    #$notLoadedCounter += 1
                    #"Not loaded lib/ref $( $package.fullname )"
                }


                # Check the runtimes folder
                $runtimeLoaded = 0
                $runtimePossiblyLoaded = 0
                $runtimeLoadError = 0
                #$useKernel32 = 0
                if ( ( Test-Path -Path "$( $package.FullName )/runtimes" ) -eq $true -and $runtimeLoaded -eq 0) {
                    $runtimeFolder = Get-BestRuntimePath -PackageRoot $package.FullName

                    If ( (Test-Path -Path $runtimeFolder) -eq $true -and $runtimeLoaded -eq 0) {
                        Get-ChildItem -Path $runtimeFolder -Filter "*.dll" -Recurse | ForEach-Object {
                            $f = $_
                            #"Loading $( $f.FullName )"
                            try {
                                Write-Verbose -Message "Loading package runtime '$( $f.FullName )'"
                                [void][Reflection.Assembly]::LoadFile($f.FullName)
                                $runtimeLoaded = 1
                                #"Loaded $( $dotnetFolder )"
                            } catch [System.BadImageFormatException] {
                                # Try it one more time with LoadLibrary through Kernel, if the kernel was loaded
                                If ( $kernel32Loaded -eq $true ) {
                                    Write-Log -Severity "WARNING" -Message "Failed! Using kernel32 for loading package runtime '$( $f.FullName )'" -WriteToHostToo $writeToHost
                                    [void][Kernel32]::LoadLibrary($f.FullName)
                                    Write-Log -Severity "WARNING" -Message "Last kernel32 error: $( [Kernel32]::GetError() )" -WriteToHostToo $writeToHost # Error list: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes--0-499-
                                    #Write-Log "$( [Kernel32]::GetEnv() )"
                                    $runtimePossiblyLoaded = 1
                                }
                                #$useKernel32 = 1
                            }  catch {
                                $runtimeLoadError = 1
                            }
                        }

                    }

                }

                # Log stats
                If ( $runtimeLoaded -eq 1 ) {
                    $runtimeSuccessCounter += 1
                } elseif ( $runtimePossiblyLoaded -eq 1 ) {
                    $runtimePossibleSuccessCounter += 1
                } elseif ( $runtimeLoadError -eq 1 ) {
                    $runtimeFailureCounter += 1
                } else {

                }

                # Write progress
                Write-Progress -Activity "Package load in progress" -Status "$( [math]::Round($i/$packagesToLoad.Count*100) )% Complete:" -PercentComplete ([math]::Round($i/$packagesToLoad.Count*100))
                $i += 1

            }



        }

    }

    end {

        #-----------------------------------------------
        # STATUS
        #-----------------------------------------------

        Write-Log -Message "Load status:"
        Write-Log -Message "  Modules loaded: $( $modCount )" #-Severity VERBOSE
        Write-Log -Message "  Lib/ref loaded: $( $successCounter )"
        Write-Log -Message "  Lib/ref failed: $( $failureCounter )"
        Write-Log -Message "  Runtime loaded: $( $runtimeSuccessCounter )"
        Write-Log -Message "  Runtime possibly loaded: $( $runtimePossibleSuccessCounter )"
        Write-Log -Message "  Runtime failed: $( $runtimeFailureCounter )"

        #Add-Type -AssemblyName System.Security


        #-----------------------------------------------
        # FINISHING
        #-----------------------------------------------

        $processEnd = [datetime]::now
        $processDuration = New-TimeSpan -Start $processStart -End $processEnd
        Write-Log -Message "Done! Needed $( [int]$processDuration.TotalSeconds ) seconds in total" #-Severity INFO

        Write-Log -Message "Logfile override: $( Get-LogfileOverride )"

        If ( $KeepLogfile -eq $false -and $null -ne $getLogfile -and '' -ne $getLogfile) {
            Write-Log -Message "Changing logfile back to '$( $currentLogfile )'"
            Set-Logfile -Path $currentLogfile
        }

    }

}