

function Invoke-Upload{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
    )

    begin {


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now
        #$inserts = 0



# TODO [ ] creates a new file and asks for some settings

#-----------------------------------------------
# GENERIC SETTINGS
#-----------------------------------------------

$scriptPath = $Script:moduleRoot


#-----------------------------------------------
# ASK FOR LOGFILE
#-----------------------------------------------

# Default file
$logfileDefault = "$( $scriptPath )\oauth.log"

# Ask for another path
$logfile = Read-Host -Prompt "Where do you want the log file to be saved? Just press Enter for this default [$( $logfileDefault )]"

# ALTERNATIVE: The file dialog is not working from Visual Studio Code, but is working from PowerShell ISE or "normal" PowerShell Console
#$settingsFile = Set-FileName -initialDirectory "$( $scriptPath )" -filter "JSON files (*.json)|*.json"

# If prompt is empty, just use default path
if ( $logfile -eq "" -or $null -eq $logfile) {
    $logfile = $logfileDefault
}

# Check if filename is valid
if(Test-Path -LiteralPath $logfile -IsValid ) {
    Write-Verbose "Logfile '$( $logfile )' is valid"
} else {
    Write-Verbose "Logfile '$( $logfile )' contains invalid characters"
}

# Set the logfile now
Set-Logfile -Path $logfile
Write-Log -Message $Script:logDivider


#-----------------------------------------------
# ASK FOR SETTINGSFILE
#-----------------------------------------------

# Default file
$settingsFileDefault = "$( $scriptPath )\settings.json"

# ALTERNATIVE: The file dialog is not working from Visual Studio Code, but is working from PowerShell ISE or "normal" PowerShell Console
#$settingsFile = Set-FileName -initialDirectory "$( $scriptPath )" -filter "JSON files (*.json)|*.json"

# Ask for another path
$settingsFile = Read-Host -Prompt "Where do you want the settings file to be saved? Just press Enter for this default [$( $settingsFileDefault )]"

# If prompt is empty, just use default path
if ( $settingsFile -eq "" -or $null -eq $settingsFile) {
    $settingsFile = $settingsFileDefault
}

# Check if filename is valid
if(Test-Path -LiteralPath $settingsFile -IsValid ) {
    Write-Log -Message "Settings file '$( $settingsFile )' is valid"
} else {
    Write-Log -Message "Settings file '$( $settingsFile )' contains invalid characters"
}


#-----------------------------------------------
# ASK FOR TOKENFILE
#-----------------------------------------------

# Default file
$tokenFileDefault = "$( $scriptPath )\oauth.token"

# Ask for another path
$tokenFile = Read-Host -Prompt "Where do you want the token file to be saved? Just press Enter for this default [$( $tokenFileDefault )]"

# ALTERNATIVE: The file dialog is not working from Visual Studio Code, but is working from PowerShell ISE or "normal" PowerShell Console
#$settingsFile = Set-FileName -initialDirectory "$( $scriptPath )" -filter "JSON files (*.json)|*.json"

# If prompt is empty, just use default path
if ( $tokenFile -eq "" -or $null -eq $tokenFile) {
    $tokenFile = $tokenFileDefault
}

# Check if filename is valid
if(Test-Path -LiteralPath $tokenFile -IsValid ) {
    Write-Log -Message "Token file '$( $tokenFile )' is valid"
} else {
    Write-Log -Message "Token file '$( $tokenFile )' contains invalid characters"
}


#-----------------------------------------------
# LOG THE NEW SETTINGS CREATION
#-----------------------------------------------

Write-Log -message "Creating a new settings file" -severity ( [Logseverity]::WARNING )


#-----------------------------------------------
# CONFIRM FOR NEXT STEPS
#-----------------------------------------------

# Confirm you want to proceed
$proceed = $Host.UI.PromptForChoice("New Token", "This will create a NEW token. Previous tokens will be invalid immediatly. Please confirm you are sure to proceed?", @('&Yes'; '&No'), 1)

# Leave if answer is not yes
If ( $proceed -eq 0 ) {
    Write-Log -message "Asked for confirmation of new token creation. Answer was 'yes'"
} else {
    Write-Log -message "Asked for confirmation of new token creation. Answer was 'No'"
    Write-Log -message "Leaving the script now"
    exit 0
}