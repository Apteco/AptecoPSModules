function Get-LogFormat {
    [CmdletBinding()]
    param()
    process {
        return $Script:defaultOutputFormat
    }
}