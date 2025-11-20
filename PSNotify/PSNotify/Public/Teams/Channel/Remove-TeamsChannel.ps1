function Remove-TeamsChannel {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"

    )

    process {

        Remove-Channel -Name $Name

    }

}