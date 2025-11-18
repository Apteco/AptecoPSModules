function Set-TimestampFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Format
    )
    process {
        try {
            # Validate the format string by attempting to format the current time.
            [datetime]::Now.ToString($Format) | Out-Null
            $Script:defaultTimestampFormat = $Format
            Write-Verbose -Message "Timestamp format example : $([datetime]::Now.ToString($Format))"
            return $Script:defaultTimestampFormat
            # TODO output example
        } catch {
            throw "Invalid timestamp format string: $Format"
        }
    }
}