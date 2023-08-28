function Remove-Target {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][String]$Name
        ,[Parameter(Mandatory = $true)][String]$TargetName
    )
    
    begin {
        
    }
    
    process {
        
        $channel = Get-Channel -Name $Name

        $channel.targets = $channel.targets | Where-Object { $_.Name -ne $TargetName }

        # Exclude the channel
        #$script:store.channels = $script:store.channels | Where-Object { $_.Name -ne $channel.Name }
        Update-Channel -Name $Name -NewChannel $channel

    }
    
    end {
        
    }
}