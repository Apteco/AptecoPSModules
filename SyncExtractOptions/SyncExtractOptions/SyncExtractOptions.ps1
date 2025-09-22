
<#PSScriptInfo

.VERSION 0.2.1

.GUID 41f30667-962f-4796-a080-017c0debadeb

.AUTHOR florian.von.bracht@apteco.de

.COMPANYNAME Apteco GmbH

.COPYRIGHT 2022 Apteco GmbH. All rights reserved.

.TAGS PSEdition_Desktop Windows Apteco

.LICENSEURI https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836

.PROJECTURI https://github.com/Apteco/AptecoPSModules/tree/main/SyncExtractOptions

.ICONURI https://www.apteco.de/sites/default/files/favicon_3.ico

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
0.3.0 Adding a new parameter for extract only: -ExtractOnly
0.2.1 Fix for loading XML from a variable
0.2.0 Preverse Whitespace in XML
      Small improvements
      Allow wildcards for matching tablenames with -like
0.1.1 Adding icon for info
      Adding Apteco tag to info
0.1.0 Initial release of SyncExtractOptions script through psgallery

.PRIVATEDATA

#>

<#

.DESCRIPTION

This script is used to switch off or switch on some data sources in FastStats Designer to allow a build with only a few tables (like customer data)
and then later do a bigger build with customer and transactional data.

This example just changes the behaviour of the extract options and saves it in the same xml

SyncExtractOptions -DesignFile "C:\Apteco\Build\20220714\designs\20220714.xml" -Include "Bookings", "People"

Do the same, but also execute DesignerConsole to load the data

SyncExtractOptions -DesignFile "C:\Apteco\Build\20220714\designs\20220714.xml" -Include "Bookings", "People" -StartDesigner

To execute from a scheduled task, do it like
Program/Script
    powershell.exe
Add arguments
    -Command "& 'SyncExtractOptions' -DesignFile 'C:\Apteco\Build\20220714\designs\20220714.xml' -Include 'Bookings', 'People'"

Two more examples
powershell.exe -Command "& 'SyncExtractOptions' -DesignFile 'C:\Apteco\Build\20221107\designs\20221107.xml' -Exclude 'Bookings', 'People' -StartDesigner"
powershell.exe -Command "& 'SyncExtractOptions' -DesignFile 'C:\Apteco\Build\20221107\designs\20221107.xml' -Exclude 'People' -Include 'Bookings' -StartDesigner"


It also works with incremental extracts with discards. When you put the table into the exclude list, the table won't be
extracted and no records will be discarded. It will just output something like
07.11.2022 10:42:57     INFO            Bookings will not be extracted.  44.998 record(s) were previously extracted.

You do not need to put all tables in the include or exclude list. Only those tables will be changed to extract or not to extract.

Use the -Verbose flag if you want to get more details

Don't forget that if you turn off some tables with -Exclude than they are turned off until you actively turn them on again.

Wildcards are supported now, too, so you could do
SyncExtractOptions -DesignFile "C:\Apteco\Build\20220714\designs\20220714.xml" -Include "Bookings*"
if you have multiple tables that begin with 'Bookings'

#>

#-----------------------------------------------
# SCRIPT INPUT
#-----------------------------------------------

param(
     [String]$DesignFile
    ,[String[]]$Include
    ,[String[]]$Exclude
    ,[Switch]$ExtractOnly
    ,[Switch]$StartDesigner
    ,[Switch]$Verbose
)


#-----------------------------------------------
# SETTINGS
#-----------------------------------------------

$settings = [PSCustomObject]@{
    "designFile" = $DesignFile
    "include" = $Include
    "exclude" = $Exclude
    "startDesignerConsole" = $false
    "designerConsolePath" = "$( $Env:PROGRAMFILES )\Apteco\FastStats Designer\DesignerConsole.exe"
}

# Set Designer start option
If ( $StartDesigner -eq $true ) {
    $settings.startDesignerConsole = $true
}

# Check Designer Console
If ( (Test-Path -Path $settings.designerConsolePath ) -eq $true ) {
    Write-Verbose "Designer Console found at: '$( $settings.designerConsolePath )'"
} else {
    Write-Verbose "Designer Console not found at: '$( $settings.designerConsolePath )'"
}


#-----------------------------------------------
# VERBOSE SETTINGS
#-----------------------------------------------

$verbosePref = $VerbosePreference
If ( $Verbose -eq $true ) {
    $VerbosePreference = "Continue"
}


#-----------------------------------------------
# TEST FILES
#-----------------------------------------------

# Test the path
If ( ( Test-Path -Path $settings.designFile ) -eq $false ) {

    Write-Error -message "Design file is not valid"
    exit 1

}

# Resolve the path
$resolvedDesignFilePath = Resolve-Path -Path $settings.designFile


#-----------------------------------------------
# LOAD XML
#-----------------------------------------------

# Load xml of design
Write-Verbose "Load the xml from '$( $resolvedDesignFilePath.Path )'"
$x = [xml]::new()
$x.PreserveWhitespace = $true
$x.LoadXml((Get-Content -Path $resolvedDesignFilePath.Path -Encoding utf8 -Raw))


#-----------------------------------------------
# CHANGE THE NEEDED EXTRACT OPTIONS
#-----------------------------------------------

# Pick the tables
$x.FastStatsDesign.DataSources.DatabaseDataSource | ForEach-Object {

    $databaseDataSource = $_

    $settings.include | Where-Object { $databaseDataSource.TableName -like $_ } | ForEach-Object {
        Write-Verbose "Setting $( $databaseDataSource.TableName ) to 'EveryTime'"
        $databaseDataSource.ExtractOptions = 'EveryTime' # Never|EveryTime
    }

    $settings.exclude | Where-Object { $databaseDataSource.TableName -like $_ } | ForEach-Object {
        Write-Verbose "Setting $( $databaseDataSource.TableName ) to 'Never'"
        $databaseDataSource.ExtractOptions = 'Never' # Never|EveryTime
    }

}


#-----------------------------------------------
# SET EXTRACT ONLY IF SET
#-----------------------------------------------

# TODO to get this work for 1:n relations, you need to change the keys from "Auto" to either "String" or "Numeric"

If ( $ExtractOnly -eq $true ) {

    # Run auto discovery
    $x.FastStatsDesign.SystemConfig.Automated.Selector_Codes = "False"

    # Load system if no errors found finding selector codes
    $x.FastStatsDesign.SystemConfig.Automated.Compile_System = "False"

} else {

    # Set this back to defaults

    # Run auto discovery
    $x.FastStatsDesign.SystemConfig.Automated.Selector_Codes = "True"

    # Load system if no errors found finding selector codes
    $x.FastStatsDesign.SystemConfig.Automated.Compile_System = "True"

}


#-----------------------------------------------
# POSTEXTRACT
#-----------------------------------------------

# to deactivate this, those two would need to be emptied
#$x.FastStatsDesign.SystemConfig.DataExtract.PostExtractCommand
#$x.FastStatsDesign.SystemConfig.DataExtract.PostExtractArgs


#-----------------------------------------------
# SAVE XML
#-----------------------------------------------

# Save the xml
Write-Verbose "Save the xml to '$( $resolvedDesignFilePath.Path )'"
$x.PreserveWhitespace = $true # maybe not needed
$x.Save($resolvedDesignFilePath.Path) # you need absolute paths


#-----------------------------------------------
# START DESIGNER CONSOLE, IF NEEDED
#-----------------------------------------------

If ( $settings.startDesignerConsole -eq $true) {
    Write-Verbose "Starting DesignerConsole"
    Start-Process -FilePath "$( $settings.designerConsolePath )" -ArgumentList @( $resolvedDesignFilePath.Path, "/load" ) -NoNewWindow
}


#-----------------------------------------------
# RESET VERBOSE SETTINGS
#-----------------------------------------------

If ( $Verbose -eq $true ) {
    $VerbosePreference = $verbosePref
}


#-----------------------------------------------
# EXIT
#-----------------------------------------------

#exit 0