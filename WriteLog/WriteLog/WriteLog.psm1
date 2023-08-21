
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
# ENUMS
#-----------------------------------------------


# Severity Enumeration used by the log function
Enum LogSeverity {
    INFO      = 0
    VERBOSE   = 5
    WARNING   = 10
    ERROR     = 20
}


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach {
    $import = $_
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

# If the variable is not present, it will create a temporary file
<#
If ( $null -eq $Script:logfile ) {
    Write-Warning -Message "There is no variable '`$logfile' present on 'Script' scope. Please define it or it will automatically created as a temporary file."
} else {
    # Testing the path
    If ( ( Test-Path -Path $Script:logfile -IsValid ) -eq $false ) {
        Write-Error -Message "Invalid variable '`$logfile'. The path '$( $Script:logfile )' is invalid."
    }
}

# If a process id (to identify this session by a guid) it will be set automatically here
If ( $null -eq $processId ) {
    Write-Warning -Message "There is no variable '`$processId' present on 'Script' scope. Please define it or it will automatically created as a [GUID]."
}
#>
Write-Verbose -Message "Please setup the logfile with 'Set-Logfile -Path' or it will automatically created as a temporary file."
Write-Verbose -Message "Please setup the process id with 'Set-ProcessId -Id'or it will automatically created as a [GUID]."


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

New-Variable -Name logfile  -Value $null -Scope Script -Force