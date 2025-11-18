function Set-LogFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Format
    )
    process {
        $Script:defaultOutputFormat = $Format
    }
}