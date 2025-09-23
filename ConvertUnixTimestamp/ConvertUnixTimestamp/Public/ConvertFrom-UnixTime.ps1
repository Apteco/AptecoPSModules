
Function ConvertFrom-UnixTime {

    <#
    .SYNOPSIS
      Shows a unix timestamp as a datetime object

    .DESCRIPTION
      Unixtime is always UTC

    .PARAMETER  unixtime
      A unix timestamp as integer

    .PARAMETER  inMilliseconds
      Use this [switch] if the timestamp is in milliseconds

    .PARAMETER  convertToLocalTimezone
      Convert the DateTime into the local timezone, otherwise the return value will be UTC

    .NOTES
      Name: Get-DateTimeFromUnixtime.ps1
      Author: florian.von.bracht@apteco.de
      DateCreated:
      DateUpdated: 2022-10-28
      Site: https://github.com/gitfvb/

    .LINK
      Site: https://github.com/gitfvb/AptecoHelperScripts/blob/master/functions/Time/Get-DateTimeFromUnixtime.ps1

    .EXAMPLE
      # Converts a unix timestamp as integer into a System.DateTime object as UTC
      ConvertFrom-UnixTime -Unixtime 1591775090

    .EXAMPLE
      # Converts a unix timestamp as integer into a System.DateTime object with the local timezone
      ConvertFrom-UnixTime -Unixtime 1591775090 -ConvertToLocalTimezone

    .EXAMPLE
      # Converts a unix timestamp with milliseconds as integer into a System.DateTime object
      ConvertFrom-UnixTime -Unixtime 1591775146091 -InMilliseconds

    .EXAMPLE
      # Creates a DateTime from a Unixtimestamp and outputs as ISO 8601 format
      ( ConvertFrom-UnixTime -Unixtime $lastSession.timestamp ).ToString("yyyy-MM-ddTHH:mm:ssK")

    #>

    [cmdletbinding()]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline)][UInt64] $Unixtime
        ,[Parameter(Mandatory=$false)][switch] $InMilliseconds = $false
        ,[Parameter(Mandatory=$false)][switch] $ConvertToLocalTimezone = $false
    )

    Begin {

    }

    Process {

        if ( $InMilliseconds ) {
            $timestamp = (Get-Date -Date "1970/01/01").AddMilliseconds($Unixtime)
        } else {
            $timestamp = (Get-Date -Date "1970/01/01").AddSeconds($Unixtime)
        }

        $timestamp = [System.TimeZoneInfo]::ConvertTimeFromUtc($timestamp,[System.TimeZoneInfo]::Utc) # Load the date with the utc timezone first

        if ( $ConvertToLocalTimezone -eq $true ) {
            $timestamp = [System.TimeZoneInfo]::ConvertTimeFromUtc($timestamp,[System.TimeZoneInfo]::Local)
        }

        return $timestamp

    }

    End {

    }

}