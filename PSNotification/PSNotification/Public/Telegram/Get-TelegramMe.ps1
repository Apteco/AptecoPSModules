

function Get-TelegramMe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
    )
    
    begin {
        
    }
    
    process {

        $me = Invoke-Telegram -Name $Name -Path "getMe" -Method "Get"
        $me
    }
    
    end {
        
    }
}
