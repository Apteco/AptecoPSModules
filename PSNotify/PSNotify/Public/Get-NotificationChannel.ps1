# Create a function to read all notification channels

function Get-NotificationChannel {

    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [String]$Name

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         #[ValidateSet("Email", "Teams", "Telegram", "Slack", "All")]
         [ChannelType]$Type = [ChannelType]::All

    )

    process {

        $channels = @()

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                $channels = @( $script:store.channels | Where-Object { $_.name -like $Name } )

                break
            }

            'Collection' {
                
                If ( $Type -eq [ChannelType]::All ) {
                    $channels = @( $script:store.channels )
                } else {
                    $channels = @( $script:store.channels | Where-Object { $_.Type -eq $Type } )
                }

                break
            }

        }

    }

}