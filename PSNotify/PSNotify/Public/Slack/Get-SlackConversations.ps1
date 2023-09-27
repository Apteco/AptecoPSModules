

function Get-SlackConversations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
    )
    
    begin {
        
    }
    
    process {

        $conversations = Invoke-Slack -Name $Name -Path "conversations.list" -Query @{"pretty"=1} -Method "Get"

        <#
            id                         : C011XXXXXXX
            name                       : product-updates
            is_channel                 : True
            is_group                   : False
            is_im                      : False
            is_mpim                    : False
            is_private                 : False
            created                    : 1585821063
            is_archived                : True
            is_general                 : False
            unlinked                   : 0
            name_normalized            : product-updates
            is_shared                  : False
            is_org_shared              : False
            is_pending_ext_shared      : False
            pending_shared             : {}
            context_team_id            : T03FYT9PL
            updated                    : 1638367400082
            parent_conversation        : 
            creator                    : UUEXXXXXX
            is_ext_shared              : False
            shared_team_ids            : {T03XXXXXX}
            pending_connected_team_ids : {}
            is_member                  : False
            topic                      : @{value=; creator=; last_set=0}
            purpose                    : @{value=Discussion of the product updates etc; creator=UUEXXXXXX; last_set=1585821064}
            previous_names             : {}
            num_members                : 30
        #>

        # return
        $conversations.channels

    }
    
    end {
        
    }
}
