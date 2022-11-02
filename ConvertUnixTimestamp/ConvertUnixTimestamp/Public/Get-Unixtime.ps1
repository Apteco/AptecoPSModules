

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

    [cmdletbinding()]
    param(
         [Parameter(Mandatory=$false,ValueFromPipeline)][DateTime] $Timestamp = ( [Datetime]::now )
        ,[Parameter(Mandatory=$false)][switch] $InMilliseconds = $false
    )

    Begin {

        $multiplier = 1

        if ( $InMilliseconds ) {
            $multiplier = 1000
        }

    }

    Process {

        $tsUtc = $Timestamp.ToUniversalTime()
        $tsFormatted = Get-Date $tsUtc -UFormat %s
        $unixtime = [UInt64]([double]::Parse($tsFormatted) * $multiplier)
        if ( $InMilliseconds ) {
          $unixtime += $tsUtc.Millisecond
        }

        return $unixtime

    }

    End {

    }

}
