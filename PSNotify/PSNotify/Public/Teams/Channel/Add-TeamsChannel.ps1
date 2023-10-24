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

        # Adds a dummy target (because we don't have multiple targets in Teams) to the channel to make it easier with group notifications
        Add-Target -Name $Name -TargetName $Name -Definition ([PSCustomObject]@{})

    }

    end {

    }
}