function Add-Channel {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][String]$Name
        ,[Parameter(Mandatory = $true)][String]$Type
        ,[Parameter(Mandatory = $true)][PSCustomObject]$Definition
    )
    
    begin {
        
    }
    
    process {
        
        # Check if the channel already exists
        try {
            $channel = @( Get-Channel -Name $Name )

            If ( $channel.count -gt 0 ) {
                throw "Channel $( $Name ) already exists"
            }
        } catch {
            # Do nothing
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
    
    end {
        
    }
}