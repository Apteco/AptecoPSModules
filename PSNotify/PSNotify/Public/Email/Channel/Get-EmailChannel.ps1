function Get-EmailChannel {

    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
        [String]$Name
        
    )

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                # Check if the email channel exists
                $channel = $null
                Get-Channel -Name $Name | Where-Object { $_.Type -eq "Email" } | ForEach-Object {
                    $channel = $_
                }

                If ( $null -eq $channel ) {
                    throw "Channel $( $Name ) not found!"
                }

                break
            }

            'Collection' {
                
                $channel = @( Get-NotificationChannels -Type "Email" )

                break
            }

        }


        #return
        $channel

    }

}