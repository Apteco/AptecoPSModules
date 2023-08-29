

function Add-NotificationGroupTarget {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][String]$Group
        ,[Parameter(Mandatory = $true)][String]$Channel
        ,[Parameter(Mandatory = $true)][String]$Target
    )
    
    begin {
        
    }
    
    process {
        
        # Get all the data
        $chosenGroup = Get-NotificationGroup -Name $Group
        $chosenChannel = Get-Channel -Name $Channel
        $chosenTarget = $chosenChannel.Targets | where { $_.TargetName -eq $Target }
        #$Script:debug = $newTarget
        # Modify the target and add the group id to it
        $chosenTarget."MemberOf" += $chosenGroup.GroupId

        Update-Channel -Name $Channel -NewChannel $chosenChannel

    }
    
    end {
        
    }
}