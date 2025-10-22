Function Get-PSEnvironment {

    <#
    .SYNOPSIS
        Retrieves detailed information about the current PowerShell environment, including version, edition, OS, architecture,
        user context, installed modules, and local/global packages.

    .DESCRIPTION
        The Get-PSEnvironment function collects and returns a comprehensive overview of the PowerShell runtime and environment.
        It can optionally check for installed modules, global packages, and local packages in a specified folder. The output is
        an ordered dictionary containing environment details, package information, and diagnostic flags.

    .PARAMETER LocalPackageFolder
        The path to the folder where local packages are stored and checked. Defaults to '.\lib'.

    .PARAMETER SkipBackgroundCheck
        If specified, skips the background check for installed modules and global packages to improve performance.

    .PARAMETER SkipLocalPackageCheck
        If specified, skips the check for local packages in the specified folder to improve performance.

    .EXAMPLE
        Get-PSEnvironment

        Returns a full environment report, including installed modules and local packages in the default '.\lib' folder.

    .EXAMPLE
        Get-PSEnvironment -SkipBackgroundCheck

        Returns environment information but skips the check for installed modules and global packages for faster execution.

    .EXAMPLE
        Get-PSEnvironment -LocalPackageFolder "C:\MyPackages" -SkipLocalPackageCheck

        Checks environment and global packages, but skips checking for local packages in 'C:\MyPackages'.

    #>

    [CmdletBinding()]
    param(

         [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
         [String]$LocalPackageFolder = ".\lib"      # Where to find local packages

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
         [Switch]$SkipBackgroundCheck = $false      # When installed modules and installed global packages are not needed, this step can be skipped because they cost around 1-2 seconds

        ,[Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
         [Switch]$SkipLocalPackageCheck = $false    # When installed modules and installed local packages are not needed, this step can be skipped because they cost around 1-2 seconds

    )

    process {

        $didBackgroundCheck = $False
        $didLocalPackageCheck = $False

        # Update background job to gather modules and global packages
        If ( $SkipBackgroundCheck -ne $True ) {
            Update-BackgroundJob
            $didBackgroundCheck = $True
        }

        # Check local lib folder
        If ( $SkipLocalPackageCheck -ne $True ) {
            If ( [System.Version]::Parse($Script:powerShellGet) -lt [System.Version]::Parse("2.2.5") -and $Script:isCore -eq $True ) {
                # The check is invalid, please update!
                throw "Please install PowerShellGet in pwsh with administrator privilege to minimum of 2.2.5 like 'Install-Module PowerShellGet -Force -AllowClobber'"
            }
            $libPathToCheck = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LocalPackageFolder)
            Write-Verbose "Checking path '$( $libPathToCheck )' for local packages"
            If ( (Test-Path -Path $libPathToCheck) -eq $true ) {
                $localPackages = PackageManagement\Get-Package -Destination $LocalPackageFolder
                Write-Verbose "Found $( $localPackages.Count ) local packages"
            }
            $didLocalPackageCheck = $True
        }

        [Ordered]@{
            "PSVersion"                     = $Script:psVersion
            "PSEdition"                     = $Script:psEdition
            "OS"                            = $Script:os
            #Platform        = $Script:platform
            "IsCore"                        = $Script:isCore
            "IsCoreInstalled"               = $Script:isCoreInstalled
            "DefaultPSCore" = [Ordered]@{
                "Version"                   = $Script:defaultPsCoreVersion
                "Is64Bit"                   = $Script:defaultPsCoreIs64Bit
                "Path"                      = $Script:defaultPsCorePath
            }
            "Architecture"                  = $Script:architecture
            "CurrentRuntime"                = Get-CurrentRuntimeId
            "Is64BitOS"                     = $Script:is64BitOS
            "Is64BitProcess"                = $Script:is64BitProcess
            "ExecutingUser"                 = $Script:executingUser
            "IsElevated"                    = $Script:isElevated
            "RuntimePreference"             = $Script:runtimePreference -join ', '
            "FrameworkPreference"           = $Script:frameworkPreference -join ', '
            "PackageManagement"             = $Script:packageManagement
            "PowerShellGet"                 = $Script:powerShellGet
            "VcRedist"                      = $Script:vcredist
            "BackgroundCheckCompleted"      = $didBackgroundCheck
            "InstalledModules"              = $Script:installedModules
            "InstalledGlobalPackages"       = $Script:installedGlobalPackages
            "LocalPackageCheckCompleted"    = $didLocalPackageCheck
            "InstalledLocalPackages"        = $localPackages
        }

    }

}