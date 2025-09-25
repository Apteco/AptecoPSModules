
#-----------------------------------------------
# NOTES
#-----------------------------------------------

<#

Inspired by Tutorial of RamblingCookieMonster in
http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
and
https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psm1

#>


#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

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

# Add pwsh core path
If ( $Script:isCore -eq $true ) {
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\powershell\7\Modules"
    }
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\powershell\7\Modules"
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\powershell\7\Modules"
}

# Add all paths
# Using $env:PSModulePath for only temporary override
$Env:PSModulePath = @( $modulePath | Sort-Object -unique ) -join ";"


#-----------------------------------------------
# ADD SCRIPT PATH, IF NOT PRESENT
#-----------------------------------------------

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

# Add pwsh core path
If ( $Script:isCore -eq $true ) {
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\powershell\7\Scripts"
    }
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\powershell\7\Scripts"
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\powershell\7\Scripts"
}

# Using $env:Path for only temporary override
$Env:Path = @( $scriptPath | Sort-Object -unique ) -join ";"


#-----------------------------------------------
# ENUMS
#-----------------------------------------------


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

#$PSBoundParameters["Verbose"].IsPresent -eq $true

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
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

# ...


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# Define the variables
#New-Variable -Name execPath -Value $null -Scope Script -Force              # Path of the calling script
New-Variable -Name psVersion -Value $null -Scope Script -Force              # PowerShell version being used
New-Variable -Name psEdition -Value $null -Scope Script -Force              # Edition of PowerShell (e.g., Desktop, Core)
New-Variable -Name platform -Value $null -Scope Script -Force               # Platform type (e.g., Windows, Linux, macOS)
New-Variable -Name frameworkPreference -Value $null -Scope Script -Force    # Preferred .NET framework version
New-Variable -Name isCore -Value $null -Scope Script -Force                 # Indicates if PowerShell Core is being used (True/False)
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


$Script:psVersion = $PSVersionTable.PSVersion.ToString()
$Script:psEdition = $PSVersionTable.PSEdition
$Script:platform = $PSVersionTable.Platform
$Script:is64BitOS = [System.Environment]::Is64BitOperatingSystem
$Script:is64BitProcess = [System.Environment]::Is64BitProcess
<#
$Script:frameworkPreference = @(

    # .NET 8+ (future‑proof)
    'net9.0','net8.0','net8.0-windows','net7.0','net7.0-windows',

    # .NET 6
    'net6.0','net6.0-windows',

    # .NET 5
    'net5.0','net5.0-windows','netcore50',

    # .NET Standard 2.1 → 2.0 → 1.5 → 1.3 → 1.1 → 1.0
    'netstandard2.1','netstandard2.0','netstandard1.5',
    'netstandard1.3','netstandard1.1','netstandard1.0',

    # Classic .NET Framework descending
    'net48','net47','net462'

)
#>

$Script:isCore = ($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')

# Check the operating system, if Core
if ($Script:isCore -eq $true) {
    If ( $IsWindows -eq $true ) {
        $Script:os = "Windows"
    } elseif ( $IsLinux -eq $true ) {
        $Script:os = "Linux"
    } elseif ( $IsMacOS -eq $true ) {
        $Script:os = "MacOS"
    } else {
        throw "Unknown operating system"
    }
} else {
    # [System.Environment]::OSVersion.VersionString()
    # [System.Environment]::Is64BitOperatingSystem
    $Script:os = "Windows"
}

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
    $osDetails = Get-CimInstance -ClassName Win32_OperatingSystem

    # Get architecture details of the OS (not the processor)
    $arch = $osDetails.OSArchitecture

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

# Check lib preference
$Script:frameworkPreference = @()
$ver = [System.Environment]::Version

if ( $PSVersionTable.PSEdition -eq 'Desktop' ) {

    # Desktop PowerShell can load any net4x up to the installed version
    $maxFramework = switch ($ver.Major) {
        4 { "net48" }   # most common Windows PowerShell 5.1 runs on .NET 4.8
        default { "net48" }
    }

    # Add net4x folders descending from the max version
    $net4x = @('net48','net47','net462','net461','net45','net40')
    $Script:frameworkPreference += $net4x[($net4x.IndexOf($maxFramework))..($net4x.Count-1)]

    # Then add netstandard (2.0 is the highest fully supported on .NET 4.8)
    $Script:frameworkPreference += 'netstandard2.0','netstandard1.5','netstandard1.3','netstandard1.1','netstandard1.0'

} else {

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

    # Finally netstandard fall‑back
    $Script:frameworkPreference += 'netstandard2.1','netstandard2.0','netstandard1.5','netstandard1.3','netstandard1.1','netstandard1.0'

}

# Check elevation
if ($Script:os -eq "Windows") {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Script:executingUser = $identity.Name
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $Script:isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

$Script:backgroundJobs = [System.Collections.ArrayList]@()
[void]$Script:backgroundJobs.Add((
    Start-Job -ScriptBlock {
        # Use Get-InstalledModule to retrieve installed modules
        Get-InstalledModule -ErrorAction SilentlyContinue
    } -Name "InstalledModule"
))
[void]$Script:backgroundJobs.Add((
    Start-Job -ScriptBlock {
        # Use Get-InstalledModule to retrieve installed modules
        PackageManagement\Get-Package -ProviderName NuGet -ErrorAction SilentlyContinue
    } -Name "InstalledGlobalPackages"
))


# Check the vcredist installation
$vcredistInstalled = $False
$vcredist64 = $False
$vcRedistCollection = $null

# Possible registry paths for Visual C++ Redistributable installations
If ( $Script:os -eq "Windows" ) {

    # Attempt to retrieve the Visual C++ Redistributable 14 registry entry
    $vcReg = Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\*\VC\Runtimes\*' #-ErrorAction Stop

    If ( $vcReg.Count -gt 0 ) {
        $vcredistInstalled = $True

        $vcRedistCollection = [hashtable]@{}
        $vcReg | ForEach-Object {
            $vcRegItem = $_
            If ( $vcRegItem.PSChildName -like "*64" -and $vcRegItem.Installed -gt 0 ) {
                $vcredist64 = $True
            }
            $vcRedistCollection.Add($vcRegItem.PSChildName, ([PSCustomObject]@{
                        "Version"   = $vcRegItem.Version
                        "Major"     = $vcRegItem.Major
                        "Minor"     = $vcRegItem.Minor
                        "Build"     = $vcRegItem.Build
                        "Installed" = $vcRegItem.Installed
                    }
                )
            )

        }

    }


}

$Script:vcredist = [PSCustomObject]@{
    "installed" = $vcredistInstalled
    "is64bit"   = $vcredist64
    "versions" = $vcRedistCollection
}


#-----------------------------------------------
# MAKE PUBLIC FUNCTIONS PUBLIC
#-----------------------------------------------

#Write-Verbose "Export public functions: $(($Public.Basename -join ", "))" -verbose
Export-ModuleMember -Function $Public.Basename #-verbose  #+ "Set-Logfile"
#Export-ModuleMember -Function $Private.Basename #-verbose  #+ "Set-Logfile"
