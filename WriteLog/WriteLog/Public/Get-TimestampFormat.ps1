function Get-TimestampFormat {
    [CmdletBinding()]
    param()
    process {
        return $Script:defaultTimestampFormat
    }
}