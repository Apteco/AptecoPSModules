function Add-Target {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$Name
        ,[Parameter(Mandatory = $true)][String]$TargetName
        ,[Parameter(Mandatory = $true)][PSCustomObject]$Definition
    )
    
    begin {
        
    }
    
    process {
        

        $channel = Get-Channel -Name $Name

        $channel.Targets += [PSCustomObject]@{
            "TargetName" = $TargetName
            "Definition" = $Definition
        }

        Update-Channel -Name $Name -NewChannel $channel

    }
    
    end {
        
    }
}