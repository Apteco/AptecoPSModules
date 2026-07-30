<#

Extracts the response body of a failed Invoke-RestMethod/Invoke-WebRequest call, so the real
Orbit API error message (e.g. field-level validation details) surfaces instead of a generic
"The remote server returned an error" exception.

Adapted from https://stackoverflow.com/questions/18771424/how-to-get-powershell-invoke-restmethod-to-return-body-of-http-500-code-response

#>
function Get-OrbitErrorResponseBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$ErrorRecord
    )

    if ( $PSVersionTable.PSVersion.Major -lt 6 ) {

        if ( $null -eq $ErrorRecord.Exception.Response ) {
            return $null
        }

        $reader = New-Object System.IO.StreamReader( $ErrorRecord.Exception.Response.GetResponseStream() )
        try {
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $body = $reader.ReadToEnd()
        } finally {
            $reader.Close()
        }

        if ( $body.StartsWith("{") ) {
            return ( $body | ConvertFrom-Json )
        }
        return $body

    }

    return $ErrorRecord.ErrorDetails.Message

}
