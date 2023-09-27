

function Send-TelegramNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
        ,[Parameter(Mandatory=$true)][String]$Target                                # The telegram channel to use
        ,[Parameter(Mandatory=$true)][String]$Text                                # The telegram channel to use
        ,[Parameter(Mandatory=$false)][Switch]$DisableNotification = $false                        # The chat id to use
    )
    
    begin {
        
    }
    
    process {

        # Get the right target for this channel
        $channel = Get-Channel -Name $Name 
        $channelTarget = $channel.Targets | where-object { $_.TargetName -eq $Target }
        #$Script:debug = $target

        #Write-Verbose -Message ( ConvertTo-Json -Depth 99 -InputObject $target -compress) -Verbose

        # Handle the switch (otherwise will be passed with a "IsPresent" property")
        If ( $DisableNotification -eq $true ) {
            $disable = $true
        } else {
            $disable = $false
        }

        # Build the body
        $body = [PSCustomObject]@{
            "chat_id" = $channelTarget.Definition.ChatId       # replace this from channel
            "text" = $Text
            "disable_notification" = $disable
        }
        
        # Send the message
        Invoke-Telegram -Name $Name -Path "sendMessage" -Method "POST" -Body $body

    }
    
    end {
        
    }
}

