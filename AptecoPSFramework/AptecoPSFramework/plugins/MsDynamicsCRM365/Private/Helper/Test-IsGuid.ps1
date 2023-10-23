# Helpful function of: https://morgantechspace.com/2021/01/powershell-check-if-string-is-valid-guid-or-not.html

function Test-IsGuid {
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StringGuid
    )

   $ObjectGuid = [System.Guid]::empty
   return [System.Guid]::TryParse($StringGuid,[System.Management.Automation.PSReference]$ObjectGuid) # Returns True if successfully parsed

}