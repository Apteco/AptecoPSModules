function Add-TeamsChannel {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$Webhook
    )
    
    begin {
        
    }
    
    process {
        
        # Encrypt the token
        #$encryptedToken = Convert-PlaintextToSecure -String $Token

        # This is customised for Telegram
        $definition = [PSCustomObject]@{
            "webhook" = Convert-PlaintextToSecure -String $Webhook #$encryptedToken
        }

        Add-Channel -Type "Teams" -Name $Name -Definition $definition

    }
    
    end {
        
    }
}