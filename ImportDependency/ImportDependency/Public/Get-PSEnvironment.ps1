Function Get-PSEnvironment {
    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
        [String]$LocalPackageFolder = ".\lib"         # Where to find local packages


#        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
#        [Switch]$DoNotCheckLocalPackages = $false           # Flag to log warnings, but not put redirect to the host

    )

    process {

        # Update background job to gather modules and global packages
        Update-BackgroundJob

        # Check local lib folder
        $libPathToCheck = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LocalPackageFolder)
        Write-Verbose "Checking path '$( $libPathToCheck )' for local packages"
        If ( (Test-Path -Path $libPathToCheck) -eq $true ) {
            $localPackages = PackageManagement\Get-Package -Destination $LocalPackageFolder
            Write-Verbose "Found $( $localPackages.Count ) local packages"
        }

        [Ordered]@{
            "PSVersion"           = $Script:psVersion
            "PSEdition"           = $Script:psEdition
            "OS"                  = $Script:os
            #Platform        = $Script:platform
            "IsCore"              = $Script:isCore
            "Architecture"        = $Script:architecture
            "CurrentRuntime"      = Get-CurrentRuntimeId
            "Is64BitOS"           = $Script:is64BitOS
            "Is64BitProcess"      = $Script:is64BitProcess
            "ExecutingUser"       = $Script:executingUser
            "IsElevated"          = $Script:isElevated
            "RuntimePreference"   = $Script:runtimePreference -join ', '
            "FrameworkPreference" = $Script:frameworkPreference -join ', '
            "PackageManagement"   = $Script:packageManagement
            "PowerShellGet"       = $Script:powerShellGet
            "VcRedist"            = $Script:vcredist
            "InstalledModules"    = $Script:installedModules
            "InstalledGlobalPackages" = $Script:installedGlobalPackages
            "InstalledLocalPackages" = $localPackages
        }

    }

}