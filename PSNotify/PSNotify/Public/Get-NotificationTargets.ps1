# Create a function to read all notification channels

function Get-NotificationTargets {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        $targets = [System.Collections.ArrayList]@()

        $script:store.channels | ForEach-Object {

            $channel = $_

            $channel.Targets | ForEach-Object {

                $target = $_

                [void]$targets.Add([PSCustomObject]@{
                    "channelid" = $channel.ChannelId
                    "name" = $channel.Name
                    "type" = $channel.Type
                    "added" = $channel.DateAdded
                    "modified" = $channel.DateModified
                    "targetid" = $target.TargetId
                    "targetname" = $target.TargetName
                    "memberof" = $target.MemberOf
                })

            }

        }

        # return
        $targets

    }

    end {

    }
}