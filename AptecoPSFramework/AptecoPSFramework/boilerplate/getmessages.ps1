
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
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

#$envVariables = [System.Environment]::GetEnvironmentVariables()
$modulePath = @( $Env:PSModulePath -split ";" ) + @( 
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
    #"C:\Program Files\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
    #"$( $Env:windir )\system32\WindowsPowerShell\v1.0\Modules"
)
$Env:PSModulePath = ( $modulepath | select -unique ) -join ";"

<#
$Env:PSModulePath = @(
    $Env:PSModulePath
    "$( $Env:ProgramFiles )\WindowsPowerShell\Modules"
    "$( $Env:HOMEDRIVE )\$( $Env:HOMEPATH )\Documents\WindowsPowerShell\Modules"
    #$( $Env:windir )\system32\WindowsPowerShell\v1.0\Modules"
) -join ";"
#>


#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug -eq $true ) {

    $params = [hashtable]@{
        Password = 'ko'
        Username = 'ko'
        #scriptPath = 'C:\faststats\Scripts\cleverreach'
        settingsFile = '.\settings.json'
        #mode='taggingOnly'
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
<#
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
#>

################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# IMPORT MODULE
#-----------------------------------------------

Import-Module "AptecoPSFramework" -Verbose
#Set-ExecutionDirectory -Path $dir


#-----------------------------------------------
# ADD MORE PLUGINS
#-----------------------------------------------

#Add-PluginFolder "D:\Scripts\CleverReach\Plugins"


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


# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    $return = Get-Messages -InputHashtable $params

    # Return the values, if succeeded
    $return

} catch {

    throw $_.Exception
    Exit 1

}




