function Add-Target {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name

        ,[Parameter(Mandatory = $true)]
         [String]$TargetName

        ,[Parameter(Mandatory = $true)]
         [PSCustomObject]$Definition

    )


    process {


        $channel = Get-Channel -Name $Name

        $channel.Targets += [PSCustomObject]@{
            "TargetId" = [guid]::NewGuid().ToString()
            "TargetName" = $TargetName
            "Definition" = $Definition
            "MemberOf" = [Array]@()
        }

        Update-Channel -Name $Name -NewChannel $channel

    }

}