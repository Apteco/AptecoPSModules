function Get-NotificationGroups {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        
    }
    
    process {

        $groups = $script:store.groups.psobject.copy()
         # TODO add entries of targets to the group

        # Enrich with targets
        <#
        foreach ($group in $groups) {
            $group | Add-Member -MemberType NoteProperty -Name "Targets" -Value ([Array]@())
            foreach ($channel in $script:store.channels) {
                foreach ($target in $channel.Targets) {
                    if ($target.MemberOf -contains $group.GroupId) {
                        $group.Targets += $target
                    }
                }
            }
        }
        #>

        $groups

    }
    
    end {
        
    }
}