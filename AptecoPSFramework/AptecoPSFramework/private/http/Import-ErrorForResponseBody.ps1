# https://stackoverflow.com/questions/18771424/how-to-get-powershell-invoke-restmethod-to-return-body-of-http-500-code-response

<#

Use like
try {

    Invoke-Restmethod ...

} catch {
    ParseErrorForResponseBody -err $_
}

#>
function Import-ErrorForResponseBody() {

    Param(
        $Err
    )

    # Only needed in PS5.1, not in Pwsh
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        if ($err.Exception.Response) {
            $Reader = New-Object System.IO.StreamReader($Err.Exception.Response.GetResponseStream())
            $Reader.BaseStream.Position = 0
            $Reader.DiscardBufferedData()
            $ResponseBody = $Reader.ReadToEnd()
            if ($ResponseBody.StartsWith('{')) {
                $ResponseBody = $ResponseBody | ConvertFrom-Json
            }
            return $ResponseBody
        }
    }
    else {
        return $Err.ErrorDetails.Message
    }

}