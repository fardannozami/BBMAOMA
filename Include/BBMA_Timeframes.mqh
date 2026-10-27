//+------------------------------------------------------------------+
//| BBMA_Timeframes.mqh                                              |
//| Timeframe registry: which slots are enabled, which role each one |
//| plays (major / second / third) and their indicator handles.      |
//+------------------------------------------------------------------+
#ifndef BBMA_TIMEFRAMES_MQH
#define BBMA_TIMEFRAMES_MQH

//+------------------------------------------------------------------+
//| Reset slots to their fixed order and invalid handles             |
//+------------------------------------------------------------------+
void InitTFArrays()
  {
   g_tf[0] = PERIOD_D1;
   g_tf[1] = PERIOD_H4;
   g_tf[2] = PERIOD_H1;
   g_tf[3] = PERIOD_M15;

   for(int i = 0; i < BBMA_TF_SLOTS; i++)
     {
      g_lastBar[i]    = 0;
      g_h[i].bb       = INVALID_HANDLE;
      g_h[i].ma5      = INVALID_HANDLE;
      g_h[i].ma10     = INVALID_HANDLE;
      g_h[i].ema      = INVALID_HANDLE;
      g_h[i].atr      = INVALID_HANDLE;
      ZeroMemory(g_a[i]);
     }
  }

//+------------------------------------------------------------------+
//| Read the inputs, build the active list and assign the roles      |
//+------------------------------------------------------------------+
void BuildTFList()
  {
   g_use[0] = InpUseD1;
   g_use[1] = InpUseH4;
   g_use[2] = InpUseH1;
   g_use[3] = InpUseM15;

   g_count = 0;
   for(int i = 0; i < BBMA_TF_SLOTS; i++)
     {
      if(g_use[i])
         g_enabled[g_count++] = i;
     }

   int required = (InpConfirmMode == CONFIRM_3TF ? 3 : 2);
   g_configOk = (g_count == required);

   g_majorIdx  = (g_count > 0 ? g_enabled[0] : -1);
   g_secondIdx = (g_count > 1 ? g_enabled[1] : -1);
   g_thirdIdx  = (g_count > 2 ? g_enabled[2] : -1);

   Print("TF config: count=", g_count, " required=", required,
         " ok=", (g_configOk ? "true" : "false"));
  }

//+------------------------------------------------------------------+
//| "4H/1H/15M"                                                      |
//+------------------------------------------------------------------+
string TFListStr()
  {
   string s = "";
   for(int i = 0; i < g_count; i++)
     {
      if(i > 0)
         s += "/";
      s += TFToStr(g_tf[g_enabled[i]]);
     }
   return s;
  }

//+------------------------------------------------------------------+
//| Role name of a slot: MAJOR / SECOND / THIRD / ON / OFF           |
//+------------------------------------------------------------------+
string RoleStr(const int idx)
  {
   if(!g_use[idx])
      return "OFF";
   if(idx == g_majorIdx)
      return "MAJOR";
   if(idx == g_secondIdx)
      return "SECOND";
   if(idx == g_thirdIdx)
      return "THIRD";
   return "ON";
  }

//+------------------------------------------------------------------+
//| Indicator handles                                                |
//+------------------------------------------------------------------+
bool InitHandles(TFHandles &h, const ENUM_TIMEFRAMES tf)
  {
   h.bb   = iBands(_Symbol, tf, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   h.ma5  = iMA(_Symbol, tf, InpFastMA, 0, MODE_SMA, PRICE_HIGH);
   h.ma10 = iMA(_Symbol, tf, InpSlowMA, 0, MODE_SMA, PRICE_LOW);
   h.ema  = iMA(_Symbol, tf, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   h.atr  = iATR(_Symbol, tf, InpATRPeriod);

   if(h.bb == INVALID_HANDLE || h.ma5 == INVALID_HANDLE || h.ma10 == INVALID_HANDLE ||
      h.ema == INVALID_HANDLE || h.atr == INVALID_HANDLE)
     {
      Print("Failed to create indicator handles for ", TFToStr(tf), " err=", GetLastError());
      return false;
     }
   return true;
  }

void ReleaseHandles(TFHandles &h)
  {
   if(h.bb   != INVALID_HANDLE) IndicatorRelease(h.bb);
   if(h.ma5  != INVALID_HANDLE) IndicatorRelease(h.ma5);
   if(h.ma10 != INVALID_HANDLE) IndicatorRelease(h.ma10);
   if(h.ema  != INVALID_HANDLE) IndicatorRelease(h.ema);
   if(h.atr  != INVALID_HANDLE) IndicatorRelease(h.atr);
  }

#endif // BBMA_TIMEFRAMES_MQH
//+------------------------------------------------------------------+
