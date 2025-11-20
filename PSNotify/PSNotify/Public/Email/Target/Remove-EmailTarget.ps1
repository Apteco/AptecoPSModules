function Remove-EmailTarget {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"

        ,[Parameter(Mandatory = $true)]
         [String]$TargetName
    
    )


    process {

        Remove-Target -Name $Name -TargetName $TargetName

    }

}