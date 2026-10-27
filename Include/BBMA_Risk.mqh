//+------------------------------------------------------------------+
//| BBMA_Risk.mqh                                                    |
//| Daily guard: daily P/L tracking, loss/target limits and the      |
//| Friday close.                                                    |
//+------------------------------------------------------------------+
#ifndef BBMA_RISK_MQH
#define BBMA_RISK_MQH

//+------------------------------------------------------------------+
//| Daily P/L in percent of the balance at the start of the day      |
//+------------------------------------------------------------------+
double DailyPct()
  {
   if(g_dayStartBalance <= 0.0)
      return 0.0;
   return (AccountInfoDouble(ACCOUNT_EQUITY) - g_dayStartBalance) / g_dayStartBalance * 100.0;
  }

//+------------------------------------------------------------------+
//| Called on every tick/timer: resets the day, enforces the limits  |
//+------------------------------------------------------------------+
void UpdateDaily()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.day != g_day)
     {
      g_day = dt.day;
      g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_blocked = false;
     }

   if(g_dayStartBalance > 0.0 && !g_blocked)
     {
      double pct = DailyPct();

      if(InpDailyLossPct > 0.0 && pct <= -InpDailyLossPct)
        {
         CloseAll();
         g_blocked = true;
         Notify("DAILY LOSS LIMIT", StringFormat("%.2f%% reached", pct));
        }
      else if(InpDailyTargetPct > 0.0 && pct >= InpDailyTargetPct)
        {
         CloseAll();
         g_blocked = true;
         Notify("DAILY TARGET", StringFormat("%.2f%% reached", pct));
        }
     }

   if(InpFridayClose && dt.day_of_week == 5 && dt.hour >= InpFridayHour)
     {
      if(CountPositions() > 0)
         CloseAll();
      g_blocked = true;
     }
  }

#endif // BBMA_RISK_MQH
//+------------------------------------------------------------------+
