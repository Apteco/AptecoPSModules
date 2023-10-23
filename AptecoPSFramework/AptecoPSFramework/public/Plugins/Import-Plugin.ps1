function Import-Plugin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String] $Guid
    )

    begin {

    }

    process {


        $success = $false


        #-----------------------------------------------
        # CHECK THE PLUGIN
        #-----------------------------------------------

        # Pick the plugin
        $plugin = @(, ($Script:plugins | Where-Object { $_.guid -eq $Guid }))

        # Check the plugin
        If ( $plugin.count -eq 0 ) {
            Write-Error "Plugin couldn't be found. Please check your guid"
            throw "Plugin couldn't be found. Please check your guid"
            Exit 1
        } elseif ( $plugin.count -gt 1 ) {
            Write-Error "There are more than 1 plugins with the guid, please check your guids!"
            throw "There are more than 1 plugins with the guid, please check your guids!"
            Exit 1
        }


        #-----------------------------------------------
        # LOAD ADDITIONAL PLUGIN SETTINGS
        #-----------------------------------------------

        # Load the plugin settings file
        $pluginSettingsFile = Join-Path -Path $plugin.path -ChildPath "/settings/defaultsettings.ps1"
        Try {
            $pluginSettings = [PSCustomObject]( . $pluginSettingsFile )
        } Catch {
            Write-Error -Message "Failed to import default settings $( $pluginSettingsFile )"
        }
        #$Script:debug = $Script:settings
        # Add more settings from plugin, e.g. if there are new properties due to an update
        #$Script:debug = $Script:settings
        #$scriptSettings = $Script:settings.psobject.copy()
        #$extendedSettings = Add-PropertyRecurse -source $pluginSettings -toExtend $scriptSettings
        $extendedSettings = Join-PSCustomObject -Left $pluginSettings -Right $Script:settings -AddPropertiesFromRight -MergePSCustomObjects -MergeArrays -MergeHashtables

        # Now harmonise them if there are the same attributes with different values
        #$joinedSettings = Join-Objects -source $extendedSettings -extend $pluginSettings

        #Write-Verbose ( convertto-json $script:settings ) -Verbose

        # Put it back into the variable
        $Script:settings = $extendedSettings
        #$Script:debug = $pluginSettings
        $Script:pluginPath = $plugin.path


        #-----------------------------------------------
        # OVERWRITE META DATA
        #-----------------------------------------------

        # TODO maybe this is not always needed

        If ( $Script:settings.plugin.guid -eq "" ) {

            $Script:settings.plugin."guid" = $plugin.guid
            $Script:settings.plugin."name" = $plugin.name
            $Script:settings.plugin."version" = $plugin.version
            $Script:settings.plugin."lastUpdate" = $plugin.lastUpdate

        }


        #-----------------------------------------------
        # CREATE DYNAMIC MODULE FOR THIS PLUGIN AND PUBLISH IT GLOBALLY
        #-----------------------------------------------

        <#

        This creates a complety dynamic created module which has some default functions that should always be available,
        but can also be extended by custom functions for specific integrations. This dynamic module can be shown via
        Get-Module

        #>

        $pluginParam = [PSCustomObject]@{
            "plugin" = $plugin
            "settings" = $Script:settings
            "variables" = [PSCustomObject]@{
                "moduleRoot" = $Script:moduleRoot
                "logDivider" = $Script:logDivider
                "debugMode" = $Script:debugMode
                "timestamp" = $Script:timestamp
                "execPath" = $Script:execPath
                "processId" = $Script:processId
            }
        }

        New-Module -Name "$( $plugin.Name )" -ArgumentList $pluginParam -ScriptBlock {

            # argument input object
            param(
                [PSCustomObject]$InputPlugin
            )

            #Write-Verbose ( $Input | ConvertTo-Json ) -Verbose

            #-----------------------------------------------
            # CHECK
            #-----------------------------------------------

            # TODO is the extension of the module path needed here, too? The parent module changes the $Env variable => NO, that works!
            # TODO is the change of the service protocol (TLS) needed here, too? The parent module changes [System.Net.ServicePointManager]::SecurityProtocol


            #-----------------------------------------------
            # CREATE VARIABLES FROM PARENT MODULE
            #-----------------------------------------------

            $InputPlugin.variables.PSObject.Properties | ForEach-Object {
                New-Variable -Name $_.Name -Value $_.Value -Scope Script -Force
            }

            $plugin = $InputPlugin.plugin


            #-----------------------------------------------
            # DOT SOURCE PRIVATE PARENT AND PLUGIN SCRIPTS
            #-----------------------------------------------

            #$Plugins  = @( Get-ChildItem -Path "$( $PSScriptRoot )/plugins/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PrivateParent = @( Get-ChildItem -Path "$( $moduleRoot )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PrivatePlugin = @( Get-ChildItem -Path "$( $plugin.path )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PublicPlugin = @( Get-ChildItem -Path "$( $plugin.path )/public/*.ps1" -Recurse -ErrorAction SilentlyContinue )

            # dot source the files
            @( $PrivateParent + $PrivatePlugin + $PublicPlugin ) | ForEach-Object {
                $import = $_
                #Write-Host "Load $( $import.fullname )"
                Try {
                    . $import.fullname
                } Catch {
                    Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
                }
            }


            #-----------------------------------------------
            # LOAD PARENT AND PLUGIN DEPENDENCIES
            #-----------------------------------------------

            # TODO only using modules yet, but also look at packages and scripts

            # Load dependencies
            . ( Join-Path -Path $moduleRoot -ChildPath "/bin/dependencies.ps1" )

            try {
                @( $psModules + $plugin.dependencies.psModules ) | ForEach-Object {
                    $mod = $_
                    Import-Module -Name $mod -ErrorAction Stop
                }
            } catch {
                Write-Error "Error loading dependencies. Please execute 'Install-AptecoPSFramework' or 'Install-Plugin' now"
                Exit 0
            }


            #-----------------------------------------------
            # DEFINE MORE VARIABLES
            #-----------------------------------------------

            New-Variable -Name settings -Value $InputPlugin.settings -Scope Script -Force       # Path of the calling script
            New-Variable -Name pluginRoot -Value $plugin.path -Scope Script -Force              # Path of the calling script
            New-Variable -Name pluginDebug -Value $null -Scope Script -Force                    # Debug variable for the scripts
            New-Variable -Name variableCache -Value $null -Scope Script -Force                  # Caching variable for shared plugin information like apiusage

            #Write-verbose ( Convertto-json $Script:settings -dept 99 ) -Verbose
            $Script:variableCache = [Hashtable]@{}


            #-----------------------------------------------
            # EXPORT PUBLIC FUNCTIONS
            #-----------------------------------------------

            Export-ModuleMember -Function $PublicPlugin.Basename #-verbose  #+ "Set-Logfile"

            # TODO Check if we need to set the process identifier, because it is already a public function
            # Get-ProcessId
            # Set-ProcessIdentifier


        } | Import-Module -Global

        #$class = $plugin.class #[DemoPlugin]::new($plugin.path)
        #$class.load()
        #$Script:plugin = $class




        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        $success = $true

        $success


    }

    end {

    }
}