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
# ENUMS
#-----------------------------------------------


#-----------------------------------------------
# IMPORT IMPORTDEPENDENCY MODULE
#-----------------------------------------------

If ( ( get-module -Name ImportDependency ).Count -ge 1 ) {
    Write-Verbose "Module ImportDependency is already imported"
} else {
    Write-Verbose "Importing module ImportDependency"
    Import-Module -Name ImportDependency
}


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -Recurse -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach-Object {
    $import = $_
    Write-Verbose "Load $( $import.fullname )"
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
    }
}


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# Define the variables
New-Variable -Name timestamp -Value $null -Scope Script -Force      # Start time of this module
New-Variable -Name logDivider -Value $null -Scope Script -Force     # String of dashes to use in logs
New-Variable -Name moduleRoot -Value $null -Scope Script -Force     # Current location root of this module
New-Variable -Name PipelineBuffer -Value $null -Scope Script -Force # Buffer for the incremental load pipeline
New-Variable -Name PipelineOptions -Value $null -Scope Script -Force # Options for
New-Variable -Name isDuckDBLoaded -Value $null -Scope Script -Force    # Flag indicating whether DuckDB.NET is available
New-Variable -Name DefaultConnection -Value $null -Scope Script -Force  # Default DuckDB connection (in-memory, auto-initialized on module load)
New-Variable -Name psModules -Value $null -Scope Script -Force          # Module dependencies
New-Variable -Name psPackages -Value $null -Scope Script -Force         # NuGet package dependencies
New-Variable -Name psAssemblies -Value $null -Scope Script -Force       # .NET assembly dependencies
New-Variable -Name psScripts -Value $null -Scope Script -Force          # Script dependencies

# Set the variables now
$Script:timestamp = [datetime]::Now
$Script:moduleRoot = $PSScriptRoot.ToString()

# Internal pipeline buffer per table
$Script:isDuckDBLoaded = $false
$Script:PipelineBuffer  = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[PSObject]]]::new()
$Script:PipelineOptions = [System.Collections.Generic.Dictionary[string, hashtable]]::new()


#-----------------------------------------------
# IMPORT DEPENDENCIES
#-----------------------------------------------

# Load dependencies
. ( Join-Path -Path $PSScriptRoot.ToString() -ChildPath "/bin/dependencies.ps1" )

# Load modules
Write-Verbose "There are currently $($Script:psModules.Count) modules defined as dependencies: $($Script:psModules -join ", ")"
If ( $Script:psModules.Count -gt 0 ) {
    Import-Dependency -Module $psModules
}

# TODO For future you need in linux maybe this module for outgrid-view, which is also supported on console only: microsoft.powershell.consoleguitools
Write-Verbose "There are currently $($Script:psPackages.Count) packages defined as dependencies: $($Script:psPackages -join ", ")"
Import-Package

# Load assemblies
$Script:psAssemblies | ForEach-Object {
    $ass = $_
    Add-Type -AssemblyName $ass
}

# Auto-initialize an in-memory DuckDB connection so that Initialize-SQLPipeline
# is only required when a persistent file-based database is needed.
if ($Script:isDuckDBLoaded) {
    try {
        $Script:DefaultConnection = New-DuckDBConnection -DbPath ':memory:'
        Initialize-PipelineMetadata -Connection $Script:DefaultConnection
        Write-Verbose "DuckDB in-memory connection initialized automatically. Call Initialize-SQLPipeline -DbPath to switch to a file-based database."
    } catch {
        Write-Warning "Failed to auto-initialize DuckDB in-memory connection: $_"
    }
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET THE VERBOSE PREFERENCE BACK TO THE ORIGINAL VALUE
#-----------------------------------------------

If ( $Verbose -eq $true ) {
    $VerbosePreference = $previousVerbosePreference
}
