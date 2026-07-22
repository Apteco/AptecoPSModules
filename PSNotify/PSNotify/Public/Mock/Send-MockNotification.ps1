function Send-MockNotification {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$true)]
         [String]$Name                                # The mock channel to use

        ,[Parameter(Mandatory=$false)]
         [String]$Title

        ,[Parameter(Mandatory=$true)]
         [String]$Text

    )

    process {

        $channel = Get-MockChannel -Name $Name

        $entry = [PSCustomObject]@{
            "name" = $Name
            "title" = $Title
            "text" = $Text
            "timestamp" = [datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss.fff")
        }

        $filename = "$( [datetime]::Now.ToString('yyyyMMddHHmmssfff') )_$( [guid]::NewGuid().ToString() ).json"
        $filepath = Join-Path -Path $channel.Definition.folder -ChildPath $filename

        ConvertTo-Json -InputObject $entry -Depth 99 | Out-File -FilePath $filepath -Encoding utf8

        # Return the written file path so callers/tests can inspect the notification
        $filepath

    }

}
