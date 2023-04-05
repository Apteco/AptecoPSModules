
Function Convert-StringEncoding {

    <#
    .SYNOPSIS
        Converts a string between different encodings. This is useful e.g. if you have APIs, that deliver UTF8 data, but does not deliver
        the encoding information, so PowerShell (especially 5.1 and before) is interpreting it in the default encoding which is 
        not always UTF8.

    .DESCRIPTION
        Apteco PS Modules - Convert String Encoding

        Example calls (will create some strange outputs, depending on your configuration, so better look at example below in the source code):

        Convert-StringEncoding -string "žluťoučký kůň úpěl ďábelské ódy" -inputEncoding "Windows-1252" -outputEncoding "utf-8"
        Convert-StringEncoding -string "žluťoučký kůň úpěl ďábelské ódy" -inputEncoding ([Console]::OutputEncoding.HeaderName) -outputEncoding ([System.Text.Encoding]::UTF8.HeaderName)

        Use one of these encodings header names for input and output
        Especially for Pwsh7 make sure to use the HeaderName of the encoding like "Windows-1252" instead of "iso-8859-1"
        [System.Text.Encoding]::GetEncodings()

        
        
        More explanation of this function and the background

        # representation as bytes from this string: žluťoučký kůň úpěl ďábelské ódy
        # [System.Text.encoding]::UTF8.GetBytes("žluťoučký kůň úpěl ďábelské ódy") -join ","
        $utf8StringBytesArr = @(197,190,108,117,197,165,111,117,196,141,107,195,189,32,107,197,175,197,136,32,195,186,112,196,155,108,32,196,143,195,161,98,101,108,115,107,195,169,32,195,179,100,121)

        # Output of original string
        Write-Host "`nThis is the correct encoding representation of the string:`n$( [System.Text.encoding]::UTF8.GetString($utf8StringBytesArr) )"

        # Create a wrong encoding representation of the UTF-8 string and output it,  be aware default encoding and console encoding diffes in some powershell environments like Pwsh7
        $stringDefaultEncoding = [System.Text.encoding]::GetEncoding(([Console]::OutputEncoding.HeaderName)).GetString($utf8StringBytesArr)
        Write-Host "`nThis is the wrong encoding representation of the string:`n$( $stringDefaultEncoding )"

        # Convert the string from the default encoding to the original encoding utf8 in this example
        $stringCorrectEncoding = Convert-StringEncoding -string $stringDefaultEncoding -inputEncoding ([Console]::OutputEncoding.HeaderName) -outputEncoding ([System.Text.Encoding]::UTF8.HeaderName)
        Write-Host "`nThis is the correct encoding representation of the string after reverse conversion:`n$( $stringCorrectEncoding )"

        To solve these problems, load the content with Invoke-WebRequest rather than Invoke-RestMethod, and convert the content with the function above

        # So instead of
        $response = Invoke-RestMethod -Uri "https://www.example.com/api"

        # Do this
        $response = Invoke-WebRequest -Uri "https://www.example.com/api"

        # Convert data to utf8 encoding
        $fixedResponse = Convert-StringEncoding -string $response.Content -inputEncoding ([Console]::OutputEncoding.HeaderName) -outputEncoding ([System.Text.Encoding]::UTF8.HeaderName)

        # Now parse the json or whatever like
        $json = ConvertFrom-Json -InputObject $fixedResponse
        $json



    .PARAMETER String
        String to change the encoding for

    .PARAMETER InputEncoding
        The input encoding like "Windows-1252" or ([Console]::OutputEncoding.HeaderName) as a string

    .PARAMETER OutputEncoding
        The output encoding for the string. Default is UTF8

    .EXAMPLE
        Convert-StringEncoding -string "žluťoučký kůň úpěl ďábelské ódy" -inputEncoding "Windows-1252" -outputEncoding "utf-8"

    .EXAMPLE
        Convert-StringEncoding -string "žluťoučký kůň úpěl ďábelské ódy" -inputEncoding ([Console]::OutputEncoding.HeaderName) -outputEncoding ([System.Text.Encoding]::UTF8.HeaderName)
    
    .EXAMPLE
        "žluťoučký kůň úpěl ďábelské ódy", "Hellö Wörld" | Convert-StringEncoding -inputEncoding "Windows-1252" -outputEncoding "utf-8"
        
    .INPUTS
        String

    .OUTPUTS
        String

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>


    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true)][String]$String
        ,[Parameter(Mandatory=$true)][String]$InputEncoding
        ,[Parameter(Mandatory=$false)][String]$OutputEncoding = "utf-8"
    )    

    Process {

        # Check input encoding, if wrong it throws an exception
        [System.Text.Encoding]::GetEncoding($InputEncoding) | Out-Null

        # Convert the bytes back
        $bytesArr = [System.Text.Encoding]::GetEncoding($InputEncoding).GetBytes($String)
        $str = [System.Text.encoding]::GetEncoding($OutputEncoding).GetString($bytesArr)

        # Return result
        return $str

    }

}
