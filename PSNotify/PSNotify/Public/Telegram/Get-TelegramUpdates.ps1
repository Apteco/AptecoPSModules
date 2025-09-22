<#

# On the first (and subsequent) call you can get the messages of the last 24 hours...
PS C:\Users\Florian> Get-TelegramUpdates -name "MyNewChannel" -verbose

update_id message
--------- -------
234603669 @{message_id=25; from=; chat=; date=1700812949; text=New2}
234603670 @{message_id=26; from=; chat=; date=1700813489; text=New3}
234603671 @{message_id=27; from=; chat=; date=1700813490; text=New4}
234603672 @{message_id=28; from=; chat=; date=1700813493; text=New 5}

# ... until you use the offset parameter with the last update_id+1 like here:
PS C:\Users\Florian> Get-TelegramUpdates -name "MyNewChannel" -verbose -Offset 234603673

# Telegram remembers this offset and will only give you more messages that followed that last id

#>

function Get-TelegramUpdates {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
        ,[Parameter(Mandatory=$false)][long]$Offset = 0                           # The id of the last message + 1 to only receiver new messages
        ,[Parameter(Mandatory=$false)][int]$Limit = 100                           # The number of messages you want to receive with one call
        ,[Parameter(Mandatory=$false)][int]$Timeout = 0                           # Timeout for the call
    )

    begin {

    }

    process {

        $body = [PSCustomObject]@{
            "offset" = $Offset
            "limit" = $Limit
            "timeout" = $Timeout
        }

        $updates = Invoke-Telegram -Name $Name -Path "getUpdates" -Method "POST" -Body $body

        # return
        $updates

    }

    end {

    }
}
