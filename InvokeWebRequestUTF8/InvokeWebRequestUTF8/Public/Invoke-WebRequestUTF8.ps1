Function Invoke-WebRequestUTF8 {

    # To solve these problems, load the content with Invoke-WebRequest rather than Invoke-RestMethod, and convert the content with the function above

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$true)][string]$AdditionalString
    )
    DynamicParam { Get-BaseParameters "Invoke-WebRequest" }

    Process {

        # Replace the body with UTF8 encoded body if needed
        $bodyToEncode = $PSBoundParameters.Body

        # Prepare only allowed parameters for Invoke-WebRequest
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters
        
        # Encode the body to UTF8 if it's a string due to issues with default encoding in PowerShell 5.1
        If ( $updatedParameters.ContainsKey("Body") -and $bodyToEncode -is [string] ) {
            # Encode Body to UTF8 bytes
            $updatedParameters.Body = [System.Text.Encoding]::UTF8.GetBytes($bodyToEncode)
        }

        # Do the request
        $response = Invoke-WebRequest @updatedParameters

        # Convert Returned content
        #$fixedContent = Convert-StringEncoding -String $response.Content -InputEncoding ([Console]::OutputEncoding.HeaderName) -OutputEncoding ([System.Text.Encoding]::UTF8.HeaderName)
        $fixedContent = [Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray())

        # Return new object
        [PSCustomObject]@{
            Content = $fixedContent
            OriginalResponse = $response
        }

    }

}