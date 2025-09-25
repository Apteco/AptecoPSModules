Function Get-PSEnvironment {
    [CmdletBinding()]
    param()

    process {

        Update-BackgroundJob

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
        }

    }

}