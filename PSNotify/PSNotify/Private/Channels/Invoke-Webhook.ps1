
function Invoke-Webhook {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Name                                # The webhook channel to use
        ,[Parameter(Mandatory=$false)][ValidateScript({
            If ($_ -is [PSCustomObject]) {
                [PSCustomObject]$_
            }
        })]$Body = [PSCustomObject]@{}   # Body to upload, will automatically be transformed into JSON
    )
    DynamicParam {
        # All parameters, except Uri and body (needed as an object)
        $p = Get-BaseParameters "Invoke-WebRequest"
        [void]$p.remove("Uri")
        [void]$p.remove("Body")
        $p
    }

    Begin {

        # Check if the webhook channel exists
        $channel = Get-WebhookChannel -Name $Name

        # Decrypt webhook url
        $url = Convert-SecureToPlaintext -String $channel.definition.url

        # Reduce input parameters to only allowed ones
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        # Add additional headers from the settings, e.g. for api gateways or proxies
        $Script:store.additionalHeaders.PSObject.Properties | ForEach-Object {
            $updatedParameters.add($_.Name, $_.Value)
        }

    }

    Process {

        # Add the contenttype
        $updatedParameters.ContentType = "application/json;charset=utf-8"

        # Prepare URL
        $updatedParameters.Uri = $url

        # Prepare Body
        If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
            $updatedParameters.Body = ConvertTo-Json -InputObject $Body -Depth 99
        }

        # Execute the request
        try {

            $wr = Invoke-WebRequest @updatedParameters -UseBasicParsing

            If ( $wr.StatusCode -ge 200 -and $wr.StatusCode -lt 300 ) {
                $return = $wr.Content
            } else {
                throw "Error at webhook request"
            }

        } catch {
            throw $_
        }

        $return

    }

    End {

    }

}
