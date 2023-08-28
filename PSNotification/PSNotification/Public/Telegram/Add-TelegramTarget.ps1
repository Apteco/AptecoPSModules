function Add-TelegramTarget {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$TargetName
    )
    
    begin {
        
    }
    
    process {
        
        Write-Verbose "Please make sure to write a message to your bot in the right chat" -Verbose

        Read-Host "Press any key to continue..."

        # Get updates
        $updates = Get-TelegramUpdates -Name $Name

        # Choose the right update for the chat
        $message = $updates.message | Out-GridView -PassThru

        # Determine the chat id
        $chatId = $message.chat.id

        # Build the target object
        Add-Target -Name $Name -TargetName $TargetName -Definition ([PSCustomObject]@{
            "ChatId" = $chatId
        })

        # Get the channel to extend it
        #$channel = Get-TelegramChannel -Name $Name
        
    }
    
    end {
        
    }
}