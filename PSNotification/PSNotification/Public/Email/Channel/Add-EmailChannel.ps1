function Add-EmailChannel {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$From
        ,[Parameter(Mandatory = $true)][string]$Username
        ,[Parameter(Mandatory = $true)][string]$Password
        ,[Parameter(Mandatory = $true)][string]$Host
        ,[Parameter(Mandatory = $false)][int]$Port = 587
        #,[Parameter(Mandatory = $true)][string]$Token
    )
    
    begin {
        
    }
    
    process {
        
        # TODO First idea, change later for mailkit

        # This is customised for Telegram
        $definition = [PSCustomObject]@{
            "from" = $From
            "username" = $Username
            "password" = Convert-PlaintextToSecure -String $Password 
            "port" = $Port
            "host" = $Host
        }

        Add-Channel -Type "Email" -Name $Name -Definition $definition

    }
    
    end {
        
    }
}