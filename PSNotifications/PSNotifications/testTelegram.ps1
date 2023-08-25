
$botName = "PSNotifBot"
$token = "6307879875:AAEYxxxxxxx"

$me = Invoke-Restmethod -Uri "https://api.telegram.org/bot$( $token )/getMe" -Method "Get"

<#
id                          : 6307879875
is_bot                      : True
first_name                  : PSNotifications
username                    : PSNotifBot
can_join_groups             : True
can_read_all_group_messages : False
supports_inline_queries     : False
#>

# Get the last messages

$u = Invoke-Restmethod -Uri "https://api.telegram.org/bot$( $token )/getUpdates" -Method "Get"

<#
[
  {
    "update_id": 234603659,
    "message": {
      "message_id": 1,
      "from": {
        "id": 1788718246,
        "is_bot": false,
        "first_name": "Florian",
        "last_name": "von B",
        "username": "knightflo",
        "language_code": "de"
      },
      "chat": {
        "id": 1788718246,
        "first_name": "Florian",
        "last_name": "von B",
        "username": "knightflo",
        "type": "private"
      },
      "date": 1692950845,
      "text": "/start",
      "entities": [
        {
          "offset": 0,
          "length": 6,
          "type": "bot_command"
        }
      ]
    }
  },
  {
    "update_id": 234603660,
    "message": {
      "message_id": 2,
      "from": {
        "id": 1788718246,
        "is_bot": false,
        "first_name": "Florian",
        "last_name": "von B",
        "username": "knightflo",
        "language_code": "de"
      },
      "chat": {
        "id": 1788718246,
        "first_name": "Florian",
        "last_name": "von B",
        "username": "knightflo",
        "type": "private"
      },
      "date": 1692950848,
      "text": "Hello"
    }
  },
  {
    "update_id": 234603661,
    "message": {
      "message_id": 3,
      "from": {
        "id": 1788718246,
        "is_bot": false,
        "first_name": "Florian",
        "last_name": "von B",
        "username": "knightflo",
        "language_code": "de"
      },
      "chat": {
        "id": 1788718246,
        "first_name": "Florian",
        "last_name": "von B",
        "username": "knightflo",
        "type": "private"
      },
      "date": 1692951290,
      "text": "/start",
      "entities": [
        {
          "offset": 0,
          "length": 6,
          "type": "bot_command"
        }
      ]
    }
  }
]
#>

# Get the last chat id
$chatId = ( $u.result | select -last 1 ).message.chat.id

$body = [PSCustomObject]@{
    "chat_id" = $chatId
    "text" = "This is a test from powershell"
    "disable_notification" = $false
}
$bodyJson = ConvertTo-Json -InputObject $body

Invoke-RestMethod -ContentType "application/json" -Method "POST" -Uri "https://api.telegram.org/bot$( $token )/sendMessage" -Body $bodyJson
