

Install-Module PSNotification

This will install the module. After installation there will be an automatic "store" file created in the current user account. Then you can add different channels to that module.

A "channel" is something like `Teams|Slack|Email|Telegram`. A target specifies a defined #channel in slack or a chat in telegram. A group is a combination of different targets

# Telegram

## Pre-Requisites

1. Go to the @Botfather Account 
1. Create a new bot with `/newbot` and follow the steps like giving it a name `PSNotification` and a username `PSNotifBot`. You are completely free with this naming. The username must be unique in Telegram, so this can take a moment to find a free one.
1. After that you are getting the token that you will need. To get your token, it is easier with [https://desktop.telegram.org/](Telegram Desktop) or [https://web.telegram.org/k/](Telegram Web)
    1. Optionally you can define a password for the bot via `/p password`
1. Then click in the same message on the link for the bot and you can chat with it. This module is not intended to receive something, so only broadcasting messages for now. If you want to use a group with colleagues, just create a new group and add your bot.

## Add channel to PSNotification

Add the channel now to this module

```PowerShell
Import-Module PSNotification
Add-TelegramChannel -Name "MyNewChannel" -Token "tokenfromtelegram"
Add-TelegramTarget -Name "MyNewChannel" -TargetName "MyNewTarget"


Send-TelegramNotification -Name "MyNewChannel" -Target "MyNewTarget" -Text "Hello World"
Send-TelegramNotification -Name "MyNewChannel" -Target "MyNewTarget" -Text "Hello World" -DisableNotification
```


More telegram specific commands

```PowerShell
Get-TelegramMe -Name "MyNewChannel"
Get-TelegramUpdates -Name "MyNewChannel"
```

## Add a target to a notification group

A notification group combines multiple channels/targets together. It needs to be created first

```PowerShell
Add-NotificationGroup -Name "MyNewGroup"
```

Then add targets to your group

```PowerShell
Add-NotificationGroupTarget -Group "MyNewGroup" -Channel "MyNewChannel" -Target "MyNewTarget"
```

## Send a message to a notification group

```PowerShell
Send-GroupNotification -Name "MyNewGroup" -Message "Hello world"
```

## Notes

This should allow you to wait in PowerShell until someone has written a message directly to the bot or a group and choose that message. From that message we get the chat_id, which is needed for conversations.
This module should be able to handle multiple chat_ids via a virtual group, maybe with different channels.

# Teams

Good resource: https://learn.microsoft.com/en-us/azure/data-factory/how-to-send-notifications-to-teams?tabs=data-factory

1. Create a new team
1. Add a new connector to one of the channels named `Incoming Webhook`, give it a name like `IncomingNotifications` and create it finally.
1. Then you a url like https://apteco365.webhook.office.com/webhookb2/71d1c7d7-xxxx-xxxx-xxxx-xxxxxxxxxxxx@131c9905-xxxx-xxxx-xxxx-xxxxxxxxxxxx/IncomingWebhook/cb6e6cxxxxxxxxxxxxxxxxxxxx/801883d2-xxxx-xxxx-xxxx-xxxxxxxxxxxx
1. With that url you are able to send a post


# Slack

https://api.slack.com/tutorials/tracks/getting-a-token