function Request-TokenRefresh {
    [CmdletBinding()]
    param (
        # TODO put settingsfile and tokenfile into parameters?
         [Parameter(Mandatory=$true)][String]$SettingsFile
        ,[Parameter(Mandatory=$true)][String]$NewAccessToken
        ,[Parameter(Mandatory=$false)][String]$NewRefreshToken = ""
        ,[Parameter(Mandatory=$false)][Switch]$BackupPreviousFile = $false
    )

    begin {

    }

    process {

        #-----------------------------------------------
        # SET LOGFILE
        #-----------------------------------------------

        # Set log file here, otherwise it could interrupt the process when launched headless from .net in System32
        Set-Logfile -Path "./psoauth.log"


        #-----------------------------------------------
        # EXCHANGE THE TOKEN
        #-----------------------------------------------

        # Read the settingsfile
        $set = Get-Content -Path $SettingsFile -Encoding utf8 -Raw | ConvertFrom-Json

        # Encrypt tokens, if wished
        $refreshToken = ""
        If ( $EncryptToken -eq $true) {
            $accessToken = Get-PlaintextToSecure $NewAccessToken
            If ( $NewRefreshToken -ne "" ) {
                $refreshToken = Get-PlaintextToSecure $NewRefreshToken
                $set.refreshtoken = $refreshToken
            }
        } else {
            $accessToken = $NewAccessToken
            If ( $NewRefreshToken -ne "" ) {
                $refreshToken = $NewRefreshToken
                $set.refreshtoken = $refreshToken
            }
        }

        # The changed settings to save for refreshing
        $set.accesstoken = $accessToken
        $set.unixtime = Get-Unixtime

        # create json object
        $json = ConvertTo-Json -InputObject $set -Depth 99 # -compress

        # TODO implement PSNotify here for email notifications


        #-----------------------------------------------
        # SAVING TO FILE
        #-----------------------------------------------

        # rename settings file if it already exists
        If ( $BackupPreviousFile -eq $true ) {
            If ( Test-Path -Path $SettingsFile ) {
                $backupPath = "$( $SettingsFile ).$( $timestamp.ToString("yyyyMMddHHmmss") )"
                Write-Log -message "Moving previous settings file to $( $backupPath )" -severity ( [Logseverity]::WARNING )
                Move-Item -Path $SettingsFile -Destination $backupPath
            } else {
                Write-Log -message "There was no settings file existing yet"
            }
        }

        # print settings to console
        #$json

        # save settings to file
        $json | Set-Content -path $SettingsFile -Encoding UTF8 -Force


        #-----------------------------------------------
        # SAVE THE TOKENS AS SEPARATE FILE UNENCRYPTED
        #-----------------------------------------------

        If ( $set.saveSeparateTokenFile -eq $true ) {
            Write-Log -message "Saving token to '$( $set.tokenFile )'"
            $NewAccessToken | Set-Content -path "$( $set.tokenFile )" -Encoding UTF8 -Force
        }


    }

    end {

    }

}