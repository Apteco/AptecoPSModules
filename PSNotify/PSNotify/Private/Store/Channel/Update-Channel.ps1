
Function Update-Channel {

    [CmdletBinding()]
    param(

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"
         
        ,[Parameter(Mandatory = $true)]
         [PSCustomObject]$NewChannel        # Give the channel a name, this is the "identifier for this channel"

    )

    Process {

        # Remove the channel and add it afterwards
        $channel = Get-Channel -Name $Name
        $script:store.channels = [Array]@( $script:store.channels | Where-Object { $_.Name -ne $channel.Name } )

        # Modify the updated channel and add it back
        $NewChannel."DateModified" = [datetime]::Now.ToString("yyyyMMddHHmmss")
        $script:store.channels += $NewChannel

        # Now save that to the store
        Set-Store

        # Return
        Get-Channel -Name $NewChannel.Name

    }

}

