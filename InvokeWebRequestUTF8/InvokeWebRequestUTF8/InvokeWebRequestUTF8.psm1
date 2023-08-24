
#-----------------------------------------------
# NOTES
#-----------------------------------------------

<#

Got the base from: https://github.com/PowerShell/PowerShell/issues/6585#issuecomment-379523326

If you want to learn more about the different exceptions, because Invoke-WebRequest e.g. have
different ones ([System.Net.WebException], [Microsoft.PowerShell.Commands.HttpResponseException])
for PS 5.1 and PS Core, have a look at the referenced link.

#>


#-----------------------------------------------
# REFERENCES
#-----------------------------------------------

# Dependencies ExtendFunction, ConvertStrings
Import-Module ExtendFunction, ConvertStrings


#-----------------------------------------------
# ENUMS
#-----------------------------------------------


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/Public/*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/Private/*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
@( $Public + $Private ) | ForEach-Object {
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

# ...


#-----------------------------------------------
# READ IN CONFIG FILES AND VARIABLES
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# ...