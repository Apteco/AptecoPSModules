
# Post something in a team

$webhook = "https://apteco365.webhook.office.com/webhookb2/71d1c7d7-xxxx-xxxx-xxxx-xxxxxxxxxxxx@131c9905-xxxx-xxxx-xxxx-xxxxxxxxxxxx/IncomingWebhook/cb6e6cxxxxxxxxxxxxxxxxxxxx/801883d2-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$body = [PSCustomObject]@{
    "title" = "This is a test from powershell2"
    "text" = "This is a test from powershell1"
    "themeColor" = "0076D7"
    # "sections" = [Array]@(
    #     [PSCustomObject]@{
    #         "activityTitle" = "This is a test from powershell3"
    #         "activitySubtitle" = "This is a test from powershell4"
    #         "activityImage" = "https://www.apteco.com/wp-content/uploads/2019/10/apteco-logo.png"
    #         "facts" = @(
    #             [PSCustomObject]@{
    #                 "name" = "This is a test from powershell5"
    #                 "value" = "This is a test from powershell6"
    #             }
    #         )
    #     }
    # )
}

$bodyJson = ConvertTo-Json -InputObject $body -Depth 99

Invoke-RestMethod -Method Post -Uri $webhook -Body $bodyJson -ContentType "application/json"


# Send a message in a chat

<#
But this requires a registered app in Azure

POST https://graph.microsoft.com/v1.0/teams/fbe2bf47-16c8-47cf-b4a5-4b9b187c508b/channels/19:4a95f7d8db4c4e7fae857bcebe0623e6@thread.tacv2/messages
Content-type: application/json

{
  "body": {
    "content": "Hello World"
  }
}
#>