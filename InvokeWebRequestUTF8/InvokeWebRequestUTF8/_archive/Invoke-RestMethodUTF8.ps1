# ExtendFunction

Function Invoke-RestMethodUTF8 {
            
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$true)][string]$AdditionalString
    )
    DynamicParam { Get-BaseParameters "Invoke-RestMethod" }

    Process {
        
        # Do the request
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-RestMethod" -Parameters $PSBoundParameters
        $response = Invoke-RestMethod @updatedParameters

        # Convert Returned content
        #Convert-StringEncoding -string $response -inputEncoding "Windows-1252" -outputEncoding "utf-8"
        Convert-StringEncoding -string $response -inputEncoding ([Console]::OutputEncoding.HeaderName) -outputEncoding ([System.Text.Encoding]::UTF8.HeaderName)
        
    }

}

