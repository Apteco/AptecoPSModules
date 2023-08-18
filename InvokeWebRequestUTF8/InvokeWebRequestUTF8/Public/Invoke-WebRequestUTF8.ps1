Function Invoke-WebRequestUTF8 {

# To solve these problems, load the content with Invoke-WebRequest rather than Invoke-RestMethod, and convert the content with the function above


    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$true)][string]$AdditionalString
    )
    DynamicParam { Get-BaseParameters "Invoke-WebRequest" }

    Process {

        # Do the request
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters
        $response = Invoke-WebRequest @updatedParameters

        # Convert Returned content
        $fixedContent = Convert-StringEncoding -string $response.Content -inputEncoding ([Console]::OutputEncoding.HeaderName) -outputEncoding ([System.Text.Encoding]::UTF8.HeaderName)

        # Return new object
        [PSCustomObject]@{
            Content = $fixedContent
            OriginalResponse = $response
        }

    }
    
}