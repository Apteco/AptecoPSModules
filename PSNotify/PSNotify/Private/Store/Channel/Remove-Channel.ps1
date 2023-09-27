function Remove-Channel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$Name
    )
    
    begin {
        
    }
    
    process {
        
        $channel = Get-Channel -Name $Name

        # Exclude the channel
        $script:store.channels = $script:store.channels | Where-Object { $_.Name -ne $channel.Name }

        # Now save that
        Set-Store

    }
    
    end {
        
    }
}