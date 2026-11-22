//+------------------------------------------------------------------+
//| BBMA_Risk.mqh                                                    |
//| Daily guard: daily P/L tracking, loss/target limits, trading     |
//| window after open / before close, and the Friday close.          |
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
//| Today's trading session of the symbol, in seconds from midnight  |
//| (server time). Returns false when the broker gives no sessions.  |
//+------------------------------------------------------------------+
bool TodaySession(int &startSec, int &endSec)
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   startSec = 86400;
   endSec   = 0;
   datetime from = 0, to = 0;
   for(uint i = 0; i < 10; i++)
     {
      if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, i, from, to))
         break;
      int f = (int)(from % 86400);
      int t = (int)(to - (from - f));   // "to" can be 24:00 (86400)
      if(f < startSec) startSec = f;
      if(t > endSec)   endSec = t;
     }
   return (endSec > startSec);
  }

int NowSec()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return dt.hour * 3600 + dt.min * 60 + dt.sec;
  }

//+------------------------------------------------------------------+
//| New auto entries only from InpSessionBufferMin after the daily   |
//| open until InpSessionBufferMin before the daily close.           |
//+------------------------------------------------------------------+
bool TradingWindowOk()
  {
   if(InpSessionBufferMin <= 0)
      return true;
   int s, e;
   if(!TodaySession(s, e))
      return true;
   int now = NowSec();
   int buf = InpSessionBufferMin * 60;
   return (now >= s + buf && now <= e - buf);
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

   //--- Friday: close everything shortly before the market closes
   if(InpFridayClose && dt.day_of_week == 5)
     {
      int s, e;
      bool closing;
      if(TodaySession(s, e))
         closing = (NowSec() >= e - MathMax(InpSessionBufferMin, 15) * 60);
      else
         closing = (dt.hour >= InpFridayHour);

      if(closing)
        {
         if(CountPositions() > 0 || CountPendings() > 0)
            CloseAll();
         g_blocked = true;
        }
     }
  }

#endif // BBMA_RISK_MQH
//+------------------------------------------------------------------+
