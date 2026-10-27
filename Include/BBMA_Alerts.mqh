//+------------------------------------------------------------------+
//| BBMA_Alerts.mqh                                                  |
//| Notification channels: popup, mobile push and Telegram.          |
//+------------------------------------------------------------------+
#ifndef BBMA_ALERTS_MQH
#define BBMA_ALERTS_MQH

//+------------------------------------------------------------------+
//| Send one message through every enabled channel and to the log    |
//+------------------------------------------------------------------+
void Notify(const string title, const string msg)
  {
   string text = title + " | " + _Symbol + " | " + msg;
   if(InpAlertPopup)
      Alert(text);
   if(InpAlertPush)
      SendNotification(text);
   if(InpAlertTelegram)
      SendTelegram(text);
   Print(text);
  }

//+------------------------------------------------------------------+
//| Telegram bot message (requires https://api.telegram.org in the   |
//| terminal WebRequest whitelist)                                   |
//+------------------------------------------------------------------+
void SendTelegram(const string msg)
  {
   if(StringLen(InpTelegramToken) < 10 || StringLen(InpTelegramChat) < 1)
      return;

   string url = "https://api.telegram.org/bot" + InpTelegramToken +
                "/sendMessage?chat_id=" + InpTelegramChat +
                "&text=" + UrlEncode(msg);

   char data[], result[];
   string resHeaders;
   int res = WebRequest("GET", url, "", 5000, data, result, resHeaders);
   if(res == -1)
      Print("Telegram WebRequest error ", GetLastError(),
            " - allow https://api.telegram.org in Tools > Options > Expert Advisors");
  }

#endif // BBMA_ALERTS_MQH
//+------------------------------------------------------------------+
