function Send-WebhookNotification {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$true)]
         [String]$Name                                # The webhook channel to use

        ,[Parameter(Mandatory=$false)]
         [String]$Title

        ,[Parameter(Mandatory=$true)]
         [String]$Text

        ,[Parameter(Mandatory=$false)]
         [PSCustomObject]$Body                         # Optional custom payload, overrides Title/Text

    )

    process {

        If ( $PSBoundParameters.ContainsKey("Body") -eq $false ) {
            $Body = [PSCustomObject]@{
                "title" = $Title
                "text" = $Text
            }
        }

        Invoke-Webhook -Name $Name -Method "POST" -Body $Body

    }

}
