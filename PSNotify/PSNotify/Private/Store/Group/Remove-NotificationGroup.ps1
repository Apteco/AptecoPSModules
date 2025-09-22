function Remove-NotificationGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$Name
    )

    begin {

    }

    process {

        $group = Get-NotificationGroup -Name $Name

        # Exclude the group
        $script:store.groups = $script:store.groups | Where-Object { $_.Name -ne $group.Name }

        # TODO Remove the id of the group from targets

        # Now save that
        Set-Store

    }

    end {

    }
}