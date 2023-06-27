
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
        settingsFile = '.\settings.json'
        Password = 'def'
        #scriptPath = 'D:\Scripts\CleverReach\PSCleverReachModule'
        MessageName = '8088752 ~ Demo_Fundraising'
        TestRecipient = '{"Email":"reply@apteco.de","Sms":null,"Personalisation":{"Kunden ID":"","email":"florian.von.bracht@apteco.de","Vorname":"","Communication Key":"93d02a55-9dda-4a68-ae5b-e8423d36fc20"}}'
        Username = 'abc'
        mode = 'prepare'
        ListName = ''
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
#Import-Module EncryptCredential # Not needed later, if we don't encrypt here
#Set-ExecutionDirectory -Path $dir


#-----------------------------------------------
# ADD MORE PLUGINS
#-----------------------------------------------

#Add-PluginFolder "D:\Scripts\CleverReach\Plugins"


#-----------------------------------------------
# SET SETTINGS
#-----------------------------------------------

# Set the settings
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
    $return = Test-Send $params

    # Return the values, if succeeded
    $return

} catch {

    throw $_.Exception
    Exit 1

}


