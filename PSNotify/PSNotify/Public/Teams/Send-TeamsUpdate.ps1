

function Send-TeamsNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$Name                                # The telegram channel to use
        #,[Parameter(Mandatory=$true)][String]$Target                                # The telegram channel to use
        ,[Parameter(Mandatory=$true)][String]$Title                                # The telegram channel to use
        ,[Parameter(Mandatory=$true)][String]$Text                                # The telegram channel to use
        #,[Parameter(Mandatory=$false)][Switch]$DisableNotification = $false                        # The chat id to use
    )

    begin {

    }

    process {

        # Get the right target for this channel
        $channel = Get-Channel -Name $Name
        #$channelTarget = $channel.Targets | where-object { $_.TargetName -eq $Target }
        #$Script:debug = $target
        #Write-Verbose -Message ( ConvertTo-Json -Depth 99 -InputObject $target -compress) -Verbose

        $body = [PSCustomObject]@{
            "title" = $Title
            "text" = $Text
            #"themeColor" = "0076D7"
            # "sections" = [Array]@(
            #     [PSCustomObject]@{
            #         "activityTitle" = "This is a test from powershell3"
            #         "activitySubtitle" = "This is a test from powershell4"
            #         "activityImage" = "https://www.apteco.com/wp-content/uploads/2019/10/apteco-logo.png"
            #         "facts" = @(
            #             [PSCustomObject]@{
            #                 "name" = "This is a test from powershell5"
            #                 "value" = "This is a test from powershell6"
            #             }
            #         )
            #     }
            # )
        }

        Invoke-Teams -Name $Name -Method "POST" -Body $body

    }

    end {

    }
}

