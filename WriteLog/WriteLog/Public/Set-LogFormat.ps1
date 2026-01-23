function Set-LogFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Format
    )
    process {
        $Script:defaultOutputFormat = $Format
    }
}