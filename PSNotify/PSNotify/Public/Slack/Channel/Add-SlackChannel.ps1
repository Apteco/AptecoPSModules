function Add-SlackChannel {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$Token
    )
    
    begin {
        
    }
    
    process {
        
        # Encrypt the token
        #$encryptedToken = Convert-PlaintextToSecure -String $Token

        # This is customised for Telegram
        $definition = [PSCustomObject]@{
            "token" = Convert-PlaintextToSecure -String $Token #$encryptedToken
        }

        Add-Channel -Type "Slack" -Name $Name -Definition $definition

    }
    
    end {
        
    }
}