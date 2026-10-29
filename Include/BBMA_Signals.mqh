//+------------------------------------------------------------------+
//| BBMA_Signals.mqh                                                 |
//| Signal engine: combines guidebook patterns into PREP/FINAL       |
//| buy-sell states, detects new signals and raises the alerts.      |
//+------------------------------------------------------------------+
#ifndef BBMA_SIGNALS_MQH
#define BBMA_SIGNALS_MQH

//+------------------------------------------------------------------+
//| Re-analyse every enabled TF and rebuild the signal state         |
//+------------------------------------------------------------------+
void UpdateAnalysis()
  {
   if(!g_configOk)
      return;

   for(int i = 0; i < g_count; i++)
     {
      int idx = g_enabled[i];
      if(!AnalyzeTF(g_tf[idx], g_h[idx], g_a[idx]))
         return;
     }

   //--- Two-timeframe preparation: major re-entry plus a middle-TF
   //    EMA rejection or BB-to-EMA gap rejection.
   g_prepBuy  = (g_a[g_majorIdx].reentryBuy &&
                 g_a[g_secondIdx].tf2Buy);

   g_prepSell = (g_a[g_majorIdx].reentrySell &&
                 g_a[g_secondIdx].tf2Sell);

   //--- The guidebook's three-timeframe combinations. The configured
   //    TFs are ordered high to low by BuildTFList().
   bool need3 = (InpConfirmMode == CONFIRM_3TF);
   if(!need3)
     {
      g_finalBuy  = g_prepBuy;
      g_finalSell = g_prepSell;
     }
   else if(g_thirdIdx >= 0)
     {
      int major = g_majorIdx;
      int middle = g_secondIdx;
      int lower = g_thirdIdx;

      bool diamondBuy = (g_a[major].reentryBuy && g_a[middle].tf2Buy &&
                         (g_a[lower].extremeBuy || g_a[lower].mhvBuy || g_a[lower].fullSetupBuy));
      bool diamondSell = (g_a[major].reentrySell && g_a[middle].tf2Sell &&
                          (g_a[lower].extremeSell || g_a[lower].mhvSell || g_a[lower].fullSetupSell));

      string buyPattern = "", sellPattern = "";
      if(g_a[major].fullSetupBuy || g_a[middle].fullSetupBuy || g_a[lower].fullSetupBuy) buyPattern = "FULL SETUP";
      else if(g_a[major].reentryBuy && g_a[middle].extremeBuy && g_a[lower].extremeBuy) buyPattern = "REE";
      else if(g_a[major].reentryBuy && g_a[middle].reentryBuy && g_a[lower].extremeBuy) buyPattern = "RRE";
      else if(g_a[major].reentryBuy && g_a[middle].reentryBuy && g_a[lower].mhvBuy) buyPattern = "RRM";
      else if(g_a[major].reentryBuy && g_a[middle].extremeBuy && g_a[lower].mhvBuy) buyPattern = "REM";
      else if(diamondBuy) buyPattern = "DIAMOND";

      if(g_a[major].fullSetupSell || g_a[middle].fullSetupSell || g_a[lower].fullSetupSell) sellPattern = "FULL SETUP";
      else if(g_a[major].reentrySell && g_a[middle].extremeSell && g_a[lower].extremeSell) sellPattern = "REE";
      else if(g_a[major].reentrySell && g_a[middle].reentrySell && g_a[lower].extremeSell) sellPattern = "RRE";
      else if(g_a[major].reentrySell && g_a[middle].reentrySell && g_a[lower].mhvSell) sellPattern = "RRM";
      else if(g_a[major].reentrySell && g_a[middle].extremeSell && g_a[lower].mhvSell) sellPattern = "REM";
      else if(diamondSell) sellPattern = "DIAMOND";

      g_finalBuy = (buyPattern != "");
      g_finalSell = (sellPattern != "");
      g_activeSetup = (g_finalBuy ? buyPattern : sellPattern);
     }
   else
     {
      g_finalBuy = false;
      g_finalSell = false;
      g_activeSetup = "";
     }

   if(g_finalBuy && g_finalSell)
     {
      g_finalBuy  = false;
      g_finalSell = false;
     }

   //--- rising edges only
   g_eventFinalBuy  = (g_finalBuy  && !g_prevFinalBuy);
   g_eventFinalSell = (g_finalSell && !g_prevFinalSell);

   g_eventPrepBuy  = (g_prepBuy  && !g_prevPrepBuy  && !g_finalBuy);
   g_eventPrepSell = (g_prepSell && !g_prevPrepSell && !g_finalSell);

   g_prevFinalBuy  = g_finalBuy;
   g_prevFinalSell = g_finalSell;
   g_prevPrepBuy   = g_prepBuy;
   g_prevPrepSell  = g_prepSell;

   if(g_eventFinalBuy)
      Notify("BBMA FINAL BUY", BuildSignalMsg(true));
   else if(g_eventFinalSell)
      Notify("BBMA FINAL SELL", BuildSignalMsg(false));
   else if(InpAlertPreparation && g_eventPrepBuy)
      Notify("BBMA PREP BUY", BuildSignalMsg(true));
   else if(InpAlertPreparation && g_eventPrepSell)
      Notify("BBMA PREP SELL", BuildSignalMsg(false));
  }

//+------------------------------------------------------------------+
//| One-line description of a signal for alerts                      |
//+------------------------------------------------------------------+
string BuildSignalMsg(const bool buy)
  {
   string s = (buy ? "BUY" : "SELL");

   if(InpConfirmMode == CONFIRM_3TF && g_activeSetup != "")
      return s + " | " + g_activeSetup + " | " + TFListStr();

   s += " | " + TFToStr(g_tf[g_majorIdx]) + " " + TrendStr(g_a[g_majorIdx].trend) + " re-entry";
   s += " | " + TFToStr(g_tf[g_secondIdx]) + " " +
        ((buy ? g_a[g_secondIdx].tf2Buy : g_a[g_secondIdx].tf2Sell) ? "confirm" : "-");

   return s;
  }

#endif // BBMA_SIGNALS_MQH
//+------------------------------------------------------------------+
