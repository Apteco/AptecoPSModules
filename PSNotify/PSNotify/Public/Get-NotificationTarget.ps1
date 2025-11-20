# Create a function to read all notification channels

function Get-NotificationTarget {
    
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [String]$Name

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         #[ValidateSet("Email", "Teams", "Telegram", "Slack", "All")]
         [ChannelType]$Type = [ChannelType]::All

    )


    process {

        $targets = [System.Collections.ArrayList]@()

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                $channels = @( Get-NotificationChannel -Type "All" | Where-Object { $_.Targets.TargetName -like $Name } )
                
                break
            }

            'Collection' {
                
                $channels = @( Get-NotificationChannel -Type $Type )

                break
            }

        }

        $channels | ForEach-Object {

            $channel = $_

            $channel.Targets | ForEach-Object {

                $target = $_

                [void]$targets.Add(
                    [PSCustomObject]@{
                        "channelid" = $channel.ChannelId
                        "name" = $channel.Name
                        "type" = $channel.Type
                        "added" = $channel.DateAdded
                        "modified" = $channel.DateModified
                        "targetid" = $target.TargetId
                        "targetname" = $target.TargetName
                        "memberof" = $target.MemberOf
                    }
                )

            }

        }

        # return
        $targets

    }

}