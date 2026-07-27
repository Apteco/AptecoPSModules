#-----------------------------------------------
#region: VERBOSE OUTPUT
#-----------------------------------------------

param(
    [bool]$Verbose = $false
)

If ( $Verbose -eq $true ) {
    $previousVerbosePreference = $VerbosePreference
    $VerbosePreference = "Continue"
} else {
    $VerbosePreference = "SilentlyContinue"
}

#endregion: VERBOSE OUTPUT


#-----------------------------------------------
#region: NOTES
#-----------------------------------------------

<#

Inspired by Tutorial of RamblingCookieMonster in
http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
and
https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psm1

#>

#endregion: NOTES


#-----------------------------------------------
# OS CHECK
#-----------------------------------------------

Write-Verbose "Checking the Core and OS"

$preCheckisCore = $PSVersionTable.Keys -contains "PSEdition" -and $PSVersionTable.PSEdition -eq 'Core'

# Check the operating system, if Core
if ($preCheckisCore -eq $true) {
    If ( $IsWindows -eq $true ) {
        $preCheckOs = "Windows"
    } elseif ( $IsLinux -eq $true ) {
        $preCheckOs = "Linux"
    } elseif ( $IsMacOS -eq $true ) {
        $preCheckOs = "MacOS"
    } else {
        throw "Unknown operating system"
    }
} else {
    $preCheckOs = "Windows"
}


#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

If ( $preCheckOs -eq "Windows" -and $preCheckisCore -eq $false ) {

    Write-Verbose "Adding Module path on Windows (when not using Core)"

    $modulePath = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
        "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
        "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
        "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
        "$( [System.Environment]::GetEnvironmentVariable("windir") )\system32\WindowsPowerShell\v1.0\Modules"
    )

    # Add the 64bit path, if present. In 32bit the ProgramFiles variables only returns the x86 path
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\WindowsPowerShell\Modules"
    }

    # Add all paths
    # Using $env:PSModulePath for only temporary override
    $Env:PSModulePath = @( $modulePath | Sort-Object -unique ) -join ";"

}

# Check if all module paths are accessible, if not remove them from the path to avoid errors when loading modules
$pathSeparator = if ($preCheckOs -eq 'Windows') { ';' } else { ':' }
$env:PSModulePath = ($env:PSModulePath -split $pathSeparator | Where-Object {
    try {
        [System.IO.Directory]::GetFiles($_) | Out-Null
        $true
    } catch {
        $false
    }
}) -join $pathSeparator


#-----------------------------------------------
# ADD SCRIPT PATH, IF NOT PRESENT
#-----------------------------------------------

If ( $preCheckOs -eq "Windows" -and $preCheckisCore -eq $false ) {

    Write-Verbose "Adding Script path on Windows (when not using Core)"


    #$envVariables = [System.Environment]::GetEnvironmentVariables()
    $scriptPath = @( [System.Environment]::GetEnvironmentVariable("Path") -split ";" ) + @(
        "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Scripts"
        "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Scripts"
        "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Scripts"
    )

    # Add the 64bit path, if present. In 32bit the ProgramFiles variables only returns the x86 path
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\WindowsPowerShell\Scripts"
    }

    # Using $env:Path for only temporary override
    $Env:Path = @( $scriptPath | Sort-Object -unique ) -join ";"

}


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

#$PSBoundParameters["Verbose"].IsPresent -eq $true

Write-Verbose "Loading public and private functions"

# Captured once here since $PSScriptRoot only resolves to the module root at this top-level
# scope; Private functions dot-sourced from their own file would otherwise see their own folder.
$Script:moduleRoot = $PSScriptRoot.ToString()

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach-Object {
    $import = $_
    Write-Verbose "Load function $( $import.fullname )" #-verbose
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
    }
}


#-----------------------------------------------
# LOAD WINDOWS SPECIFIC FUNCTIONS
#-----------------------------------------------

Write-Verbose "Loading Windows specific functions"

$WindowsPrivate  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/Windows/*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
If ( $preCheckOs -eq "Windows" ) {
    @( $WindowsPrivate ) | ForEach-Object {
        $import = $_
        Write-Verbose "Load function $( $import.fullname )" #-verbose
        Try {
            . $import.fullname
        } Catch {
            Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
        }
    }
}


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

Write-Verbose "Define internal module variables"

# Define the variables
#New-Variable -Name execPath -Value $null -Scope Script -Force              # Path of the calling script
New-Variable -Name psVersion -Value $null -Scope Script -Force              # PowerShell version being used
New-Variable -Name psEdition -Value $null -Scope Script -Force              # Edition of PowerShell (e.g., Desktop, Core)
New-Variable -Name platform -Value $null -Scope Script -Force               # Platform type (e.g., Windows, Linux, macOS)
New-Variable -Name frameworkPreference -Value $null -Scope Script -Force    # Preferred .NET framework version
New-Variable -Name runtimePreference -Value $null -Scope Script -Force      # Preferred OS native framework version
New-Variable -Name isCore -Value $null -Scope Script -Force                 # Indicates if PowerShell Core is being used (True/False)
New-Variable -Name isCoreInstalled -Value $null -Scope Script -Force        # Indicates if PowerShell Core is already installed (True/False)
New-Variable -Name defaultPsCoreVersion -Value $null -Scope Script -Force   # Default version of PowerShell Core that is used
New-Variable -Name defaultPsCoreIs64Bit -Value $null -Scope Script -Force   # If default PowerShell is 64-bit (True/False)
New-Variable -Name defaultPsCorePath -Value $null -Scope Script -Force      # Default Path where PowerShell Core is installed
New-Variable -Name os -Value $null -Scope Script -Force                     # Operating system name
New-Variable -Name is64BitOS -Value $null -Scope Script -Force              # Indicates if the OS is 64-bit (True/False)
New-Variable -Name is64BitProcess -Value $null -Scope Script -Force         # Indicates if the process is 64-bit (True/False)
New-Variable -Name executingUser -Value $null -Scope Script -Force          # User executing the script
New-Variable -Name isElevated -Value $null -Scope Script -Force             # Indicates if the script is running with elevated privileges (True/False)
New-Variable -Name packageManagement -Value $null -Scope Script -Force      # Package management system in use (e.g., NuGet, APT)
New-Variable -Name powerShellGet -Value $null -Scope Script -Force          # Version of PowerShellGet module
New-Variable -Name vcredist -Value $null -Scope Script -Force               # Indicates if Visual C++ Redistributable is installed (True/False)
New-Variable -Name installedModules -Value $null -Scope Script -Force               # Caches all installed PowerShell modules
New-Variable -Name backgroundJobs -Value $null -Scope Script -Force               # Hidden variable to store background jobs
New-Variable -Name installedGlobalPackages -Value $null -Scope Script -Force               # Caches all installed NuGet Global Packages
New-Variable -Name executionPolicy -Value $null -Scope Script -Force        # Current execution policy

# Filling some default values
$Script:isCore = $preCheckisCore
$Script:os = $preCheckOs
$Script:psVersion = $PSVersionTable.PSVersion.ToString()
$Script:powerShellEdition = $PSVersionTable.PSEdition # Need to write that out because psedition is reserved
$Script:platform = $PSVersionTable.Platform
$Script:is64BitOS = [System.Environment]::Is64BitOperatingSystem
$Script:is64BitProcess = [System.Environment]::Is64BitProcess
$Script:executionPolicy = [PSCustomObject]@{
    "LocalMachine" = Get-ExecutionPolicy -Scope LocalMachine
    "MachinePolicy" = Get-ExecutionPolicy -Scope MachinePolicy
    "Process" = Get-ExecutionPolicy -Scope Process
    "CurrentUser" = Get-ExecutionPolicy -Scope CurrentUser
    "UserPolicy" = Get-ExecutionPolicy -Scope UserPolicy
}


#-----------------------------------------------
# CHECKING POWERSHELL CORE DETAILS
#-----------------------------------------------

Write-Verbose "Checking more details about PS Core"

# Check if pscore is installed
$pwshCommand = Get-Command -commandType Application -Name "pwsh*"
If ( $pwshCommand.Count -gt 0 ) {
    $Script:defaultPsCoreVersion = $pwshCommand[0].Version
    $Script:isCoreInstalled = $true
    if ($Script:os -eq "Windows") {
        # For Windows
        $Script:defaultPsCorePath = ( get-command -name "pwsh*" -CommandType Application | where-object { $_.Source.replace("\pwsh.exe","") -eq ( pwsh { $pshome } ) } ).Source
    } elseif ( $Script:os -eq "Linux" ) {
        # For Linux
        If ( $null -ne (which pwse) ) {
            $Script:defaultPsCorePath = (which pwse)
        }
    }
} else {
    $Script:isCoreInstalled = $false
}


#-----------------------------------------------
# CHECKING PROCESSOR ARCHITECTURE
#-----------------------------------------------

Write-Verbose "Checking the processor architecture"

# Checking the processor architecture and operating system architecture
If ( $null -ne [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture ) {

    Switch ( [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString().toUpper() ) {
        'X64'      { $arch = 'x64' }
        'X86'      { $arch = 'x32' }
        'ARM64'    { $arch = 'arm64' }
        'ARM'      { $arch = 'arm' }
        Default    { $arch = 'Unknown' }
    }

} else {

    # Used code from: https://gist.github.com/asheroto/cfa26dd00177a03c81635ea774406b2b
    # Get OS details using Get-CimInstance because the registry key for Name is not always correct with Windows 11
    try {

        $osDetails = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop

        # Get architecture details of the OS (not the processor)
        $arch = $osDetails.OSArchitecture

    } catch {

        # CIM/WMI can be blocked in locked-down environments (e.g. Windows Sandbox's WDAGUtilityAccount).
        # Confirmed in exactly that environment: RuntimeInformation.ProcessArchitecture (the primary check
        # above) came back empty there too, on an otherwise perfectly ordinary ARM64 machine (works fine
        # outside the sandbox on the same hardware/PS build) -- so both of the first two checks can fail
        # at once on a real ARM64 box. Is64BitOperatingSystem alone only distinguishes 32-bit vs 64-bit; it
        # cannot tell ARM64 from x64, so it used to normalize to a generic "64-bit" that got misclassified
        # as "x64" further down -- causing DuckDB's native loader to pick the wrong (win-x64 instead of
        # win-arm64) runtime folder entirely, and fail with ERROR_BAD_EXE_FORMAT despite a perfectly valid
        # x64 binary being loaded (it was just the wrong architecture for the real CPU). PROCESSOR_ARCHITECTURE
        # is set directly by the OS and was confirmed to still be available and correct in that same
        # locked-down sandbox, so check it before falling back further.
        Write-Verbose "Could not query Win32_OperatingSystem via CIM: $( $_.Exception.Message )"
        If ( -not [String]::IsNullOrEmpty( $env:PROCESSOR_ARCHITECTURE ) ) {
            Write-Verbose "Falling back to the PROCESSOR_ARCHITECTURE environment variable"
            $arch = $env:PROCESSOR_ARCHITECTURE
        } else {
            Write-Verbose "Falling back to Is64BitOperatingSystem"
            $arch = If ( [System.Environment]::Is64BitOperatingSystem ) { "64-bit" } else { "32-bit" }
        }

    }

}

# Normalize architecture
if ($arch -match "(?i)32") {
    $Script:architecture = "x32"
} elseif ($arch -match "(?i)64" -and $arch -match "(?i)ARM") {
    $Script:architecture = "ARM64"
} elseif ($arch -match "(?i)64") {
    $Script:architecture = "x64"
} elseif ($arch -match "(?i)ARM") {
    $Script:architecture = "ARM"
} else {
    $Script:architecture = "Unknown"
}


#-----------------------------------------------
# CHECKING .NET PACKAGE RUNTIME PREFERENCE ORDER
#-----------------------------------------------

Write-Verbose "Checking the .NET package runtime preference order"

# Check which runtimes to prefer
$Script:runtimePreference = @()
switch ($Script:os) {

    'Windows'{

        If ($Script:architecture -eq "ARM64") {
            $Script:runtimePreference = @( "win-arm64", "win-arm", "win-x64" )
        }

        If ($Script:architecture -eq "ARM") {
            $Script:runtimePreference = @( "win-arm" )
        }

        If ($Script:architecture -eq "x64") {
            $Script:runtimePreference = @( "win-x64" )
        }

        $Script:runtimePreference += @( "win-x86" )
        $Script:runtimePreference += @( "win" )


    }

    'Linux'   {

        If ($Script:architecture -eq "ARM64") {
            $Script:runtimePreference = @( "linux-arm64", "linux-arm", "linux-x64" )
        }

        If ($Script:architecture -eq "ARM") {
            $Script:runtimePreference = @( "linux-arm" )
        }

        If ($Script:architecture -eq "x64") {
            $Script:runtimePreference = @( "linux-x64" )
        }

        $Script:runtimePreference += @( "linux-x86" )
    }

    'MacOS'  {

        If ($Script:architecture -eq "ARM64") {
            $Script:runtimePreference = @( "osx-arm64" )
        }

        If ($Script:architecture -eq "x64") {
            $Script:runtimePreference = @( "osx-x64" )
        }

    }
    default     {
        throw "Unsupported OS: $os"
    }
}


#-----------------------------------------------
# CHECKING .NET PACKAGE REF/LIB PREFERENCE ORDER
#-----------------------------------------------

Write-Verbose "Checking the .NET package ref/lib preference order"

# Check lib preference
$Script:frameworkPreference = @()
$ver = [System.Environment]::Version

# If this is core, add the important framework folders first
If ( $Script:isCore -eq $True ) {

    # PowerShell 7+ runs on .NET 6, 7, or 8 – pick the highest available
    $major = $ver.Major   # 6,7,8 …
    $minor = $ver.Minor   # usually 0

    # Add the exact netX.Y folder first
    $Script:frameworkPreference += "net$( $major ).$( $minor )"
    # Add newer “windows” variants if they exist
    $Script:frameworkPreference += "net$( $major ).$( $minor )-windows"

    # Add previous major versions
    for ($m = $major-1; $m -ge 5; $m--) {
        $Script:frameworkPreference += "net$( $m ).0"
        $Script:frameworkPreference += "net$( $m ).0-windows"
    }

    # Finally netcore/netstandard fall‑back
    $Script:frameworkPreference += 'netcoreapp2.1','netcoreapp2.0','netstandard2.1','netstandard2.0','netstandard1.5','netstandard1.3','netstandard1.1','netstandard1.0'

}

# Then add .NET Framework folders for Desktop PowerShell, it could be a try to load them

# Desktop PowerShell can load any net4x up to the installed version
$maxFramework = switch ($ver.Major) {
    4 { "net48" }   # most common Windows PowerShell 5.1 runs on .NET 4.8
    default { "net48" }
}

# Add net4x folders descending from the max version
$net4x = @('net48','net471','net47','net462','net461','net45','net40')
$Script:frameworkPreference += $net4x[($net4x.IndexOf($maxFramework))..($net4x.Count-1)]

# Just the fallback for up to .NET 4.8
if ( $Script:powerShellEdition -eq 'Desktop' ) {

    # Then add netstandard (2.0 is the highest fully supported on .NET 4.8)
    $Script:frameworkPreference += 'netstandard2.0','netstandard1.5','netstandard1.3','netstandard1.1','netstandard1.0'

}


#-----------------------------------------------
# CHECKING ELEVATION
#-----------------------------------------------

Write-Verbose "Checking Elevation"

# Check elevation
if ($Script:os -eq "Windows") {
    $id = Get-CurrentWindowsIdentity
    $Script:executingUser = $id.ExecutingUser
    $Script:isElevated = $id.IsElevated
} elseif ( $Script:os -eq "Linux" -or $Script:os -eq "MacOS" ) {
    $Script:executingUser = whoami
    $Script:isElevated = -not [String]::IsNullOrEmpty($env:SUDO_USER)
}

Write-Verbose "Checking PackageManagement and PowerShellGet versions"

# Initial snapshot at import time. Get-PSEnvironment re-checks this live on every call via
# Get-LatestModuleVersion rather than reading this cached value, since PackageManagement/
# PowerShellGet can be installed/updated after this module was imported.
$Script:packageManagement = Get-LatestModuleVersion -Name "PackageManagement"
$Script:powerShellGet = Get-LatestModuleVersion -Name "PowerShellGet"


Write-Verbose "Add background jobs to work out the installed modules and packages"

# Extracted into Start-EnvironmentBackgroundJob (Private) so Update-BackgroundJob can also call it
# to re-scan on demand, instead of only ever running once at import time.
Start-EnvironmentBackgroundJob


#-----------------------------------------------
# CHECKING VCREDIST
#-----------------------------------------------

Write-Verbose "Checking VCRedist"

# Initial snapshot at import time. Get-PSEnvironment re-checks this live on every call via
# Get-VcRedistStatus rather than reading this cached value, since vcredist can be installed
# after this module was imported (e.g. via InstallDependency's Install-VcRedist).
$Script:vcredist = Get-VcRedistStatus


#-----------------------------------------------
# MAKE PUBLIC FUNCTIONS PUBLIC
#-----------------------------------------------

Write-Verbose "Exporting public functions"

Export-ModuleMember -Function $Public.Basename #-verbose  #+ "Set-Logfile"


#-----------------------------------------------
# SET THE VERBOSE PREFERENCE BACK TO THE ORIGINAL VALUE
#-----------------------------------------------

If ( $Verbose -eq $true ) {
    $VerbosePreference = $previousVerbosePreference
}
