

function Send-SlackNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
        ,[Parameter(Mandatory=$true)][String]$Target                                # The telegram channel to use
        ,[Parameter(Mandatory=$true)][String]$Text                                # The telegram channel to use
    )
    
    begin {
        
    }
    
    process {

        # Get the right target for this channel
        $channel = Get-Channel -Name $Name 
        $channelTarget = $channel.Targets | where-object { $_.TargetName -eq $Target }
        #$Script:debug = $target

        #Write-Verbose -Message ( ConvertTo-Json -Depth 99 -InputObject $target -compress) -Verbose

        # Build the body
        $body = [PSCustomObject]@{
            "channel" = $channelTarget.Definition.ConversationChannel       # replace this from channel
            "text" = $Text
        }
        
        # Send the message
        Invoke-Slack -Name $Name -Path "chat.postMessage" -Method "POST" -Body $body

    }
    
    end {
        
    }
}

