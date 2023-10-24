# Create a function to read all notification channels

function Get-NotificationChannels {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        $script:store.channels

    }

    end {

    }
}