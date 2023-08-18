
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
$Env:PSModulePath = ( $modulepath | Select-Object -unique ) -join ";"


#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug -eq $true ) {
    $params = [hashtable]@{
        ReplyToEmail = 'reply@apteco.de'
        settingsFile = '.\settings.json'
        Password = 'def'
        #scriptPath = 'D:\Scripts\CleverReach\PSCleverReachModule'
        MessageName = ''
        EmailFieldName = 'email'
        SmsFieldName = ''
        Path = 'd:\faststats\Publish\Handel\system\Deliveries\PowerShell_1158984 ~ Demo_Fundraising_20230606-155652_55935023-5af7-49bf-8bd7-2e3c67234cd4.txt'
        TransactionType = 'Replace'
        Username = 'abc'
        ReplyToSMS = ''
        UrnFieldName = 'Kunden ID'
        ListName = '1158984 ~ Demo_Fundraising_20230606-155652'
        CommunicationKeyFieldName = 'Communication Key'
    }
}

#Write-Log -message "Got a file with these arguments: $( [Environment]::GetCommandLineArgs() )" -writeToHostToo $false


################################################
#
# NOTES
#
################################################

<#

bla bla

# TODO [x] encrypt the global db parameter
# TODO [ ] activate the clear log functionality

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
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


#-----------------------------------------------
# SET SETTINGS
#-----------------------------------------------

# Set the settings
Import-Settings -Path $params.settingsFile


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

or

            Write-Log -Message "Failed to connect to SQLServer database" -Severity ERROR
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_.Exception

#>


#-----------------------------------------------
# CALL UPLOAD
#-----------------------------------------------

# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    $return = Invoke-Broadcast $params

    # Return the values, if succeeded
    $return

} catch {

    throw $_.Exception
    Exit 1

}


