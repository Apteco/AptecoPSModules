function Send-GroupNotification {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$Message 
    )
    
    begin {
        
    }
    
    process {
        
        $group = Get-NotificationGroups | Where-Object { $_.Name -eq $Name }

        # Check
        if ( $group.count -eq 0 ) {
            throw "Group $( $Name ) does not exist"
        } elseif ( $group.count -gt 1 ) {
            throw "More than 1 group $( $Name ) with this name"
        }

        $targets = Get-NotificationTargets | where-object { $_.MemberOf -contains $group.GroupId }

        # Send a message to each target
        # TODO this needs to be refined later, Send-Notification does not exist yet
        foreach ( $target in $targets ) {
            #Send-Notification -Channel $target.Channel -Target $target.TargetName -Message $Message
            Switch ( $target.type ) {
                "Telegram" {
                    Send-TelegramNotification -Name $target.Name -Target $target.targetname -Text $Message
                }
                # "Teams" {
                #     Send-SlackNotification -Name $target.Name -Target $target.targetname -Text $Message
                # }
                # "Slack" {
                #     Send-SlackNotification -Name $target.Name -Target $target.targetname -Text $Message
                # }
                # "Mail" {
                #     Send-MailNotification -Name $target.Name -Target $target.targetname -Text $Message
                # }
            }
            
        }

    }
    
    end {
        
    }
}