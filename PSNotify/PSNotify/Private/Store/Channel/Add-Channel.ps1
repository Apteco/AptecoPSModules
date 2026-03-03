function Add-Channel {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name

        ,[Parameter(Mandatory = $true)]
         [ChannelType]$Type

        ,[Parameter(Mandatory = $true)]
         [PSCustomObject]$Definition

    )

    process {

        # Check if the channel already exists
        If ( @( $script:store.channels | Where-Object { $_.Name -eq $Name } ).Count -gt 0 ) {
            throw "Channel '$( $Name )' already exists"
        }

        # Add the channel to the store
        $script:store.channels += [PSCustomObject]@{
            "ChannelId" = [guid]::NewGuid().ToString()
            "Name" = $Name
            "Type" = $Type # Telegram, Teams, Email, Slack
            "Definition" = $Definition
            "Targets" = [Array]@()
            "DateAdded" = [datetime]::Now.ToString("yyyyMMddHHmmss")
            "DateModified" = [datetime]::Now.ToString("yyyyMMddHHmmss")
        }

        # Now save that
        Set-Store

    }

}