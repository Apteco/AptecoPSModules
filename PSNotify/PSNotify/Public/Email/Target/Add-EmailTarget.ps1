function Add-EmailTarget {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$TargetName  # Give this group a name
        ,[Parameter(Mandatory = $true)][string[]]$Receivers # Array of email addresses that should be targeted
    )

    begin {

    }

    process {

        # TODO maybe directly send to all receivers and confirm the email was received

        # Build the target object
        Add-Target -Name $Name -TargetName $TargetName -Definition ([PSCustomObject]@{
            "Receivers" = [Array]@( $Receivers )
        })

        # Get the channel to extend it
        #$channel = Get-TelegramChannel -Name $Name

    }

    end {

    }
}