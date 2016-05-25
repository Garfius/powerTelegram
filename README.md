# powerTelegram
Telegram bot adaptation for PowerShell from [c# powershell bot](https://github.com/MrRoundRobin/telegram.bot). Tested on powershell 4 and 5.

This script provides useful example to learn how to use telegram windows library 'DLL' under powershell. It also pretends to give command line access to bot messaging from windows O.S. useful for automation, alerts and scheduling.

[![license](https://img.shields.io/github/license/mrroundrobin/telegram.bot.svg?maxAge=2592000)](https://raw.githubusercontent.com/MrRoundRobin/telegram.bot/master/LICENSE.txt)

## Telegram Bot Api Library

C# library to talk to Telegrams Bot API (https://core.telegram.org/bots/api)

## Usage

Make sure the requiered libraries are located at .\files

```powershell
  .\powerTelegram.ps1 -token "----your token----"
```

## Alternate silent usage to send static messages

```powershell
$fixedBotKey = "----your token----"
$message = "Wow, it's working !"
$targetUserId = 123456

$bot =  New-Object NetTelegramBotApi.TelegramBot($fixedBotKey)
$getMe = New-Object NetTelegramBotApi.Requests.GetMe
$me = $bot.MakeRequestAsync($getMe).Result

if ($me -eq $null)
{
    exit
}

$reqAction = New-Object NetTelegramBotApi.Requests.SendMessage($targetUserId, $message);
$bot.MakeRequestAsync($reqAction).Wait();
```

see [telegram.bot.examples](https://github.com/MrRoundRobin/telegram.bot.examples)

## API Coverage

Updated to [Bot API 2.1](https://core.telegram.org/bots/2-0-intro)
