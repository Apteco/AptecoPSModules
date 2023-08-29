function Get-NotificationGroup {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
    )
    
    begin {
        
    }
    
    process {
        
        Get-NotificationGroups | Where-Object { $_.Name -eq $Name }

    }
    
    end {
        
    }
}