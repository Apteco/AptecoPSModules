
<#PSScriptInfo

.VERSION 0.1.1

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

#> 

#-----------------------------------------------
# SCRIPT INPUT
#-----------------------------------------------

param(
     [String]$DesignFile
    ,[String[]]$Include
    ,[String[]]$Exclude
    ,[Switch]$StartDesigner
    ,[Switch]$Verbose
)


#-----------------------------------------------
# SETTINGS
#-----------------------------------------------

$settings = [PSCustomObject]@{

    designFile = $DesignFile

    include = $Include

    exclude = $Exclude

    startDesignerConsole = $StartDesigner #$true
    designerConsolePath = "$( $Env:PROGRAMFILES )\Apteco\FastStats Designer\DesignerConsole.exe"

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
$x = [xml](Get-Content -Path $resolvedDesignFilePath.Path -Encoding utf8 -Raw)


#-----------------------------------------------
# CHANGE THE NEEDED OPTIONS
#-----------------------------------------------

# Pick the tables
$x.FastStatsDesign.DataSources.DatabaseDataSource | where { $_.TableName -in ( $settings.include + $settings.exclude ) } | ForEach {
    $databaseDataSource = $_
    If ( $settings.include -contains $databaseDataSource.TableName ) {
        Write-Verbose "Setting $( $databaseDataSource.TableName ) to 'EveryTime'"
        $databaseDataSource.ExtractOptions = 'EveryTime' # Never|EveryTime
    } else {
        Write-Verbose "Setting $( $databaseDataSource.TableName ) to 'Never'"
        $databaseDataSource.ExtractOptions = 'Never' # Never|EveryTime
    }
}


#-----------------------------------------------
# SAVE XML
#-----------------------------------------------

# Save the xml
Write-Verbose "Save the xml to '$( $resolvedDesignFilePath.Path )'"
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