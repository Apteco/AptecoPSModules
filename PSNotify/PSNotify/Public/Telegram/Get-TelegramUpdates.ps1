

function Get-TelegramUpdates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
    )

    begin {

    }

    process {

        $updates = Invoke-Telegram -Name $Name -Path "getUpdates" -Method "Get"

        # return
        $updates

    }

    end {

    }
}
