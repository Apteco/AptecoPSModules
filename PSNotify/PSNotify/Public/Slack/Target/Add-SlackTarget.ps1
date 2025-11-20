function Add-SlackTarget {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"

        ,[Parameter(Mandatory = $true)]
         [String]$TargetName

    )

    process {

        # Get updates
        $conversations = Get-SlackConversations -Name $Name

        # Choose the right update for the chat
        $channel = $conversations | Out-GridView -PassThru

        # Build the target object
        Add-Target -Name $Name -TargetName $TargetName -Definition ([PSCustomObject]@{
            "ChatId" = $channel.id
        })

        # Get the channel to extend it
        #$channel = Get-TelegramChannel -Name $Name

    }

}