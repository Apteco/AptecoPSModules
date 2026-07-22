function Get-WebhookChannel {

    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
        [String]$Name

    )

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                # Check if the channel exists
                $channel = $null
                Get-Channel -Name $Name | Where-Object { $_.Type -eq "Webhook" } | ForEach-Object {
                    $channel = $_
                }

                If ( $null -eq $channel ) {
                    throw "Channel $( $Name ) not found!"
                }

                break
            }

            'Collection' {

                $channel = @( Get-NotificationChannels -Type "Webhook" )

                break
            }

        }

        #return
        $channel

    }

}
