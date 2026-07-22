function Add-WebhookChannel {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"

        ,[Parameter(Mandatory = $true)]
         [String]$Url

    )

    process {

        $definition = [PSCustomObject]@{
            "url" = Convert-PlaintextToSecure -String $Url
        }

        Add-Channel -Type "Webhook" -Name $Name -Definition $definition

        # Adds a dummy target (Webhook posts to a single URL) to make it easier with group notifications
        Add-Target -Name $Name -TargetName $Name -Definition ([PSCustomObject]@{})

    }

}
