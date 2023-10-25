

function Get-Messages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
    )

    begin {


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "GETMESSAGES"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }

        #-----------------------------------------------
        # DEPENDENCIES
        #-----------------------------------------------

        #Import-Module MeasureRows
        #Import-Module SqlServer
        #Import-Module ConvertUnixTimestamp
        #Import-Lib -IgnorePackageStructure

    }

    process {

        # Load options from the settings
        $options = $Script:settings.upload.options
        Write-Log "Loaded $( $options.Count ) options from settings" -severity INFO #-WriteToHostToo $false
        
        # Transform into the first format
        $mailingsList = [System.Collections.ArrayList]@()
        $options | ForEach-Object {
            $option = $_
            [void]$mailingsList.add(
                [Mailing]@{
                    mailingId = $option.key
                    mailingName = $option.label
                }
            )
        }

        # Transform the mailings array into the needed output format
        $columns = @(
            @{
                name="id"
                expression={ $_.mailingId }
            }
            @{
                name="name"
                expression={ $_.toString() }
            }
        )

        $messages = [System.Collections.ArrayList]@()
        [void]$messages.AddRange(@( $mailingsList | Select-Object $columns ))

        If ( $messages.count -gt 0 ) {

            Write-Log "Loaded $( $messages.Count ) messages" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No messages loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

        }

        # Return
        $messages

    }

    end {

    }

}

