function Remove-EmailChannel {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
    )
    
    begin {
        
    }
    
    process {

        Remove-Channel -Name $Name

    }
    
    end {
        
    }
}