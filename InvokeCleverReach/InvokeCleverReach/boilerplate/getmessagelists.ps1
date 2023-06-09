
################################################
#
# INPUT
#
################################################

Param(
    [hashtable] $params
)


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false



#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug -eq $true ) {

    $params = [hashtable]@{
        Password = 'ko'
        Username = 'ko'
        scriptPath = 'C:\faststats\Scripts\cleverreach'
        settingsFile = '.\settings.json'
    }

}


################################################
#
# NOTES
#
################################################

<#

bla bla

#>


################################################
#
# SCRIPT ROOT
#
################################################

if ( $debug -eq $true ) {

    if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
        $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    }

    $params.scriptPath = $scriptPath

}

# Some local settings
$dir = $params.scriptPath
Set-Location $dir


################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# IMPORT MODULE
#-----------------------------------------------

Import-Module "D:\Scripts\PSModules\InvokeCleverReach" -Verbose
Set-ExecutionDirectory -Path $dir


#-----------------------------------------------
# SETTINGS
#-----------------------------------------------

# Set the settings
<#
$settings = Get-settings
$settings.logfile = ".\file.log"
Set-Settings -PSCustom $settings
#>
Import-Settings -Path $params.settingsFile


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


################################################
#
# PROGRAM
#
################################################

# TODO [x] check if we need to make a try catch here -> not needed, if we use a combination like

<#
            $msg = "Temporary count of $( $mssqlResult ) is less than $( $rowsCount ) in the original export. Please check!" 
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

#>


#-----------------------------------------------
# GET MESSAGES
#-----------------------------------------------


#try {

    # Do the upload
    $return = Get-Groups -InputHashtable $params

    # Return the values, if succeeded
    $return

#} catch {

#    throw $_.Exception

#}



