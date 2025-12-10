
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
$Script:executionPolicy = Get-ExecutionPolicy -Scope MachinePolicy


Write-Verbose "Checking more details about PS Core"

# Check if pscore is installed
$pwshCommand = Get-Command -commandType Application -Name "pwsh*"
$Script:defaultPsCoreVersion = $pwshCommand[0].Version
If ( $pwshCommand.Count -gt 0 ) {
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


Write-Verbose "Checking the .NET package lib preference order"

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
    $net4x = @('net48','net471','net47','net462','net461','net45','net40')
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
    $Script:frameworkPreference += 'netcoreapp2.0','netstandard2.1','netstandard2.0','netstandard1.5','netstandard1.3','netstandard1.1','netstandard1.0'

}


Write-Verbose "Checking Elevation"

# Check elevation
# TODO check for MacOS
if ($Script:os -eq "Windows") {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Script:executingUser = $identity.Name
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $Script:isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
} elseif ( $Script:os -eq "Linux" ) {
    $Script:executingUser = whoami
    $Script:isElevated = -not [String]::IsNullOrEmpty($env:SUDO_USER)
}

Write-Verbose "Checking PackageManagement and PowerShellGet versions"

# Check if PackageManagement and PowerShellGet are available
$Script:packageManagement = ( Get-Module -Name "PackageManagement" -ListAvailable -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1 ).Version.toString()
$Script:powerShellGet = ( Get-Module -Name "PowerShellGet" -ListAvailable -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1 ).Version.toString()


Write-Verbose "Add background jobs to work out the installed modules and packages"

# Add jobs to find out more about installed modules and packages in the background

# TODO add in multiple paths for pscore ?

$Script:backgroundJobs = [System.Collections.ArrayList]@()
If ( $Script:isCoreInstalled -eq $True ) {
    
    [void]$Script:backgroundJobs.Add((
        Start-Job -ScriptBlock {
            pwsh { [System.Environment]::Is64BitProcess }
        } -Name "PwshIs64Bit"
    ))

}

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

    } -Name "InstalledModule" -ArgumentList $PSScriptRoot.ToString(), $preCheckOs
))

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

    } -Name "InstalledGlobalPackages" -ArgumentList $PSScriptRoot.ToString(), $preCheckOs

))


Write-Verbose "Checking VCRedist"

# Check the vcredist installation
$vcredistInstalled = $False
$vcredist64 = $False
$vcRedistCollection = $null

# Possible registry paths for Visual C++ Redistributable installations
If ( $Script:os -eq "Windows" ) {

    try {

        # Attempt to retrieve the Visual C++ Redistributable 14 registry entry
        $vcReg = [Array]@( Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\*\VC\Runtimes\*' -ErrorAction Stop )

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
    } catch {
        Write-Verbose "VCRedist is not installed"
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

Write-Verbose "Exporting public functions"

Export-ModuleMember -Function $Public.Basename #-verbose  #+ "Set-Logfile"
