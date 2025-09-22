function Remove-TelegramTarget {


    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$TargetName
    )

    begin {

    }

    process {

        Remove-Target -Name $Name -TargetName $TargetName

    }

    end {

    }
}