<#
.SYNOPSYS

This script uses the Telegram library to provide basic funcions to the token-related bot. It's translated from the C# version

.PARAMETERS

-token <string>

Your bot's token

.NOTES
    File Name  : powerTelegram.ps1  
    Author     : Gerard Forcada - garfius@gmail.com
    Requires   : Newtonsoft jsn library
    Translated from c# version
  
#>
param([string]$token = $(throw "Your bot's token is needed !"));

$runningPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

#you may replace to the convenient location
try{
    Add-Type -Path $($runningPath + "\files\Newtonsoft.Json.dll")
    Add-Type -Path $($runningPath + "\files\NetTelegramBotApi.dll")
}catch{
    Write-Host "Problem including classes, where are the DLL's ?" -ForegroundColor Red -BackgroundColor Yellow
    exit
}

$imageFile = $($runningPath + "\files\t_logo.png")
$docFile = $($runningPath + "\files\Telegram_Bot_API.htm")
$docUtf8 = $($runningPath + "\files\Пример UTF8 filename.txt")

function runBot($accessToken){
    
    $bot =  New-Object NetTelegramBotApi.TelegramBot($accessToken)
    $getMe = New-Object NetTelegramBotApi.Requests.GetMe
    $me = $bot.MakeRequestAsync($getMe).Result

    if ($me -eq $null)
    {
        Write-Host "GetMe() FAILED. Do you forget to add your AccessToken to config.json?"
        Write-Host "(Press ENTER to quit)"
        return
    }

    [System.Console]::WriteLine("{0} (@{1}) connected!", $me.FirstName, $me.Username)      
    [System.Console]::WriteLine("Find @{0} in Telegram and send him a message - it will be displayed here", $me.Username)
    Write-Host "(Press ctrl + c to stop listening and quit)"
    [string]$uploadedPhotoId = $null;
    [string]$uploadedDocumentId = $null;
    [long]$offset = 0;

    try
    {
        while (!$stopMe)
        {
            
            $getupdates = New-Object -TypeName NetTelegramBotApi.Requests.GetUpdates
            $getupdates.Offset = $offset
            $updates = $bot.MakeRequestAsync($getupdates).Result;
                    
            if ($updates -ne $null){
                foreach($update in $updates){
                    
                    $offset = $update.UpdateId + 1;
                    
                    if ($update.Message -eq $null)
                    {
                        break;
                    }

                    $from = $update.Message.From;
                    $text = $update.Message.Text;
                    $photos = $update.Message.Photo;
                    
                    [System.Console]::WriteLine("Msg from {0} {1} ({2}) at {4}: {3}",$from.FirstName,$from.LastName,$from.Username,$text,$update.Message.Date)

                    if ($photos -ne $null){
                        $webClient = New-Object -TypeNAme System.Net.WebClient
                        foreach ($photo in $photos){
                            [System.Console]::WriteLine("  New image arrived: size {1}x{2} px, {3} bytes, id: {0}", $photo.FileId, $photo.Height, $photo.Width, $photo.FileSize);
                            $file = $bot.MakeRequestAsync($(New-Object NetTelegramBotApi.Requests.GetFile($photo.FileId))).Result;
                            $tempFileName = [System.IO.Path]::GetTempFileName();
                            $webClient.DownloadFile($file.FileDownloadUrl, $tempFileName);
                            [System.Console]::WriteLine("    Saved to {0}", $tempFileName);

                        }
                    }

                    if ($text -eq "/photo")
                        {
                            if ([System.String]::IsNullOrEmpty($uploadedPhotoId)){
                                $reqAction = New-Object NetTelegramBotApi.Requests.SendChatAction($update.Message.Chat.Id, "upload_photo");
                                $bot.MakeRequestAsync($reqAction).Wait();
                                [System.Threading.Thread]::Sleep(500)
                                $fileStream = [System.IO.File]::OpenRead($imageFile)
                                $req = New-Object NetTelegramBotApi.Requests.SendPhoto($update.Message.Chat.Id,$( New-Object NetTelegramBotApi.Requests.FileToSend($fileStream, "Telegram_logo.png")))
                                $req.Caption = "Telegram_logo.png"
                                $msg = $bot.MakeRequestAsync($req).Result;
                                $uploadedPhotoId = $msg.Photo[$msg.Photo.Count -1].FileId
                                $fileStream.close()
                            }
                            else
                            {
                                $req = New-Object NetTelegramBotApi.Requests.SendPhoto($update.Message.Chat.Id,$( New-Object NetTelegramBotApi.Requests.FileToSend($uploadedPhotoId)))
                                $req.Caption =  "Resending photo id=" + $uploadedPhotoId
                                $bot.MakeRequestAsync($req).Wait();
                            }
                            
                        }

                        if ($text -eq "/doc")
                        {
                            if ([System.String]::IsNullOrEmpty($uploadedDocumentId))
                            {
                                $reqAction = New-Object NetTelegramBotApi.Requests.SendChatAction($update.Message.Chat.Id, "upload_document");
                                $bot.MakeRequestAsync($reqAction).Wait();
                                [System.Threading.Thread]::Sleep(500)
                                $fileStream = [System.IO.File]::OpenRead($docFile)
                                $req = New-Object NetTelegramBotApi.Requests.SendDocument($update.Message.Chat.Id,$(New-Object NetTelegramBotApi.Requests.FileToSend($fileStream), "Telegram_Bot_API.htm"));
                                $msg = $bot.MakeRequestAsync($req).Result;
                                $uploadedDocumentId = $msg.Document.FileId;
                                $fileStream.close()
                                
                            }
                            else
                            {
                                $req = New-Object NetTelegramBotApi.Requests.SendDocument($update.Message.Chat.Id,$(New-Object NetTelegramBotApi.Requests.FileToSend($uploadedDocumentId)));
                                $bot.MakeRequestAsync($req).Wait();
                            }
                            continue;
                        }

                        if ($text -eq "/docutf8")
                        {
                            $reqAction = New-Object NetTelegramBotApi.Requests.SendChatAction($update.Message.Chat.Id, "upload_document");
                            $bot.MakeRequestAsync($reqAction).Wait();
                            [System.Threading.Thread]::Sleep(500)
                            $fileStream = [System.IO.File]::OpenRead($docUtf8)
                            $req = New-Object NetTelegramBotApi.Requests.SendDocument($update.Message.Chat.Id,$(New-Object NetTelegramBotApi.Requests.FileToSend($fileStream, "Пример UTF8 filename.txt")));
                            $msg = $bot.MakeRequestAsync($req).Result;
                            $uploadedDocumentId = $msg.Document.FileId;
                            $fileStream.close()
                        }

                        if ($text -eq "/help")
                        {
                            $keyb = New-Object -TypeName NetTelegramBotApi.Types.ReplyKeyboardMarkup
                            $keyb.Keyboard = "/photo ", "/doc ", "/docutf8 ","/help"
                            $keyb.OneTimeKeyboard = $true
                            $keyb.ResizeKeyboard = $true
                            $reqAction = New-Object NetTelegramBotApi.Requests.SendMessage($update.Message.Chat.Id, "Here is all my commands");
                            $reqAction.ReplyMarkup = $keyb
                            $bot.MakeRequestAsync($reqAction).Wait();
                            
                        }

                        if (($update.Message.Text.Length % 2) -eq 0)
                        {
                            $reqAction = new-object NetTelegramBotApi.Requests.SendMessage($update.Message.Chat.Id,$("You wrote *" + $update.Message.Text.Length + " characters*"))
                            $reqAction.ParseMode = [NetTelegramBotApi.Requests.SendMessage+ParseModeEnum]::Markdown
                            $bot.MakeRequestAsync($reqAction).Wait();
                        }
                        else
                        {
                            $bot.MakeRequestAsync($(New-Object NetTelegramBotApi.Requests.ForwardMessage($update.Message.Chat.Id, $update.Message.Chat.Id, $update.Message.MessageId))).Wait();
                        }
                }
            }
            if(!$psISE)
            {
                $stopME = [System.Console]::KeyAvailable
            }
        }
        write-host "Key pressed."
    }
    finally
    {
        write-host "Ctrl+c pressed."
    }
}

runBot $token
