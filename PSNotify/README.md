

# Quickstart

```PowerShell
# Check your executionpolicy: https:/go.microsoft.com/fwlink/?LinkID=135170
Get-ExecutionPolicy

# Either set it to Bypass to generally allow scripts for current user
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
# or
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then install this module and other dependencies
install-script install-dependencies, import-dependencies
install-module writelog
Install-Dependencies -module PSNotify


# Then you can import the module and it will tell you the path for your channel store, when using -verbose flag
Import-Module PSNotify -Verbose
```

This will install the module. After installation there will be an automatic "store" file created in the current user account. Then you can add different channels to that module.

A "channel" is something like `Teams|Slack|Email|Telegram`. A target specifies a defined #channel in slack or a chat in telegram. A group is a combination of different targets

# Telegram

## Pre-Requisites

1. Go to the @Botfather Account 
1. Create a new bot with `/newbot` and follow the steps like giving it a name `PSNotify` and a username `PSNotifBot`. You are completely free with this naming. The username must be unique in Telegram, so this can take a moment to find a free one.
1. After that you are getting the token that you will need. To get your token, it is easier with [https://desktop.telegram.org/](Telegram Desktop) or [https://web.telegram.org/k/](Telegram Web)
    1. Optionally you can define a password for the bot via `/p password`
1. Then click in the same message on the link for the bot and you can chat with it. This module is not intended to receive something, so only broadcasting messages for now. If you want to use a group with colleagues, just create a new group and add your bot.

## Add channel to PSNotify

Add the channel now to this module

```PowerShell
Import-Module PSNotify
Add-TelegramChannel -Name "MyNewChannel" -Token "tokenfromtelegram"
Add-TelegramTarget -Name "MyNewChannel" -TargetName "MyNewTarget"

# Send two messages - One with notification, another one without notification
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

Then add already existing targets to your group. In the end it is a reference to your channel/target

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

## Pre-Requisites

Good resource: https://learn.microsoft.com/en-us/azure/data-factory/how-to-send-notifications-to-teams?tabs=data-factory

1. Create a new team
1. Add a new connector to one of the channels named `Incoming Webhook`, give it a name like `IncomingNotifications` and create it finally.
1. Then you a url like https://apteco365.webhook.office.com/webhookb2/71d1c7d7-xxxx-xxxx-xxxx-xxxxxxxxxxxx@131c9905-xxxx-xxxx-xxxx-xxxxxxxxxxxx/IncomingWebhook/cb6e6cxxxxxxxxxxxxxxxxxxxx/801883d2-xxxx-xxxx-xxxx-xxxxxxxxxxxx
1. With that url you are able to send a post and add this url to this module.


## Add channel to PSNotify

Add the channel now to this module

```PowerShell
Import-Module PSNotify
Add-TeamsChannel -Name "MyNewTeamsChannel" -Webhook "https://apteco365.webhook.office.com/webhookb2/71d1c7d7-xxxx-xxxx-xxxx-xxxxxxxxxxxx@131c9905-xxxx-xxxx-xxxx-xxxxxxxxxxxx/IncomingWebhook/cb6e6cxxxxxxxxxxxxxxxxxxxx/801883d2-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

Send-TeamsUpdate -Name "MyNewTeamsChannel" -Title "Great title!" -Text "Hello World"
```


# Slack

## Pre-Requisites

1. Follow the pretty good explanations here, create an app there: https://api.slack.com/tutorials/tracks/getting-a-token
1. After creating the app it directs you back to that link and attached the app id similar to here: https://api.slack.com/tutorials/tracks/getting-a-token?app_id_from_manifest=Z05XXXXXXXX
1. When you scroll down to Step 1 on that page, tadaa.... there is the token you can use now in this module. It is easy like that!


## Add channel to PSNotify

Add the channel now to this module

```PowerShell
Import-Module PSNotify
Add-SlackChannel -Name "MyNewSlackChannel" -Token "xoxb-not-a-real-token-this-will-not-work"
Add-SlackTarget -Name "MyNewSlackChannel" -TargetName "MyNewSlackTarget"


Send-SlackNotification -Name "MyNewSlackChannel" -Target "MyNewSlackTarget" -Text "Hello World"
```

There will be some misunderstanding with the terminology. A target in this module is a Slack channel.

More Slack specific commands

```PowerShell
Get-SlackConversations -Name "MyNewSlackChannel"
```


# Email

## Pre-Requisites

To make this happen, we need `MailKit` and `MimeKit` first. You can install it with

```PowerShell
Install-MailKit -Verbose
```

This will automatically install it into `%LOCALAPPDATA%\AptecoPSModules\PSNotify\lib`. As this loads also all dependencies, this can be something around 440MB. When you are sure you only need MailKit and MimeKit, then you can manually delete all other packages in that folder. This can also improve performance.

## Add channel to PSNotify


Add the channel now to this module

```PowerShell
Import-Module PSNotify

$emailParams = [Hashtable]@{
    "Name" = "example" # TODO rename this entry
    "From" = "sender@example.com"
    "Username" = "sender@example.com"
    "Password" = "acbdefg" # TODO remove this!
    "Host" = "smtp.ionos.de"
    "Port" = 465
    "UseSSL" = $true
}

# Add the email channel with the parameters above
# Note: The @ is correct!
Add-EmailChannel @emailParams

# Now add targets, which is a group of receivers
Add-EmailTarget -Name "example" -TargetName "Email1" -Receivers "florian.von.bracht@apteco.de", "user@example.com" # TODO rename this entry

# And send an email
Send-Mailnotification -Name ionos -Target Email1 -Subject "Achtung Test!" -Text "Beware of the text"
```
