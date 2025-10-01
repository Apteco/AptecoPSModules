

Function Get-Unixtime {

    <#
    .SYNOPSIS
      Shows the current time or a input datetime as a unix timestamp

    .DESCRIPTION
      Unixtime is always UTC

    .PARAMETER  inMilliseconds
      Just use this to parameter [switch] if you want to return the timestamp with milliseconds

    .PARAMETER  timestamp
      Just input a [DateTime] object to calculate another timestamp

    .NOTES
    Name: Get-Unixtime.ps1
    Author: florian.von.bracht@apteco.de
    DateCreated:
    DateUpdated: 2022-10-28
    Site: https://github.com/gitfvb/

    .LINK
    Site: https://github.com/gitfvb/AptecoHelperScripts/blob/master/functions/Time/Get-Unixtime.ps1

    .EXAMPLE
      # Shows the current unix timestamp
      Get-Unixtime

    .EXAMPLE
      # Shows the current unix timestamp with Millseconds
      Get-Unixtime -InMilliseconds

    .EXAMPLE
      # Shows the unix timestamp with milliseconds from two days ago
      Get-Unixtime -InMilliseconds -Timestamp ( Get-Date ).AddDays(-2)

    #>

    [CmdletBinding()]
    [OutputType([UInt64])]
    param(

         [Parameter(Mandatory=$false,ValueFromPipeline)]
         [DateTime] $Timestamp = ( [Datetime]::now )

        ,[Parameter(Mandatory=$false)]
         [Switch] $InMilliseconds = $false

    )

    Process {
        $tsUtc = $Timestamp.ToUniversalTime()
        $dto = [DateTimeOffset]$tsUtc
        if ($InMilliseconds) {
            return [UInt64]$dto.ToUnixTimeMilliseconds()
        } else {
            return [UInt64]$dto.ToUnixTimeSeconds()
        }
    }

}
