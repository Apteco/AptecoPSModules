function Get-NotificationGroup {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"
    
    )

    process {

        Get-NotificationGroups | Where-Object { $_.Name -like $Name }

    }

}