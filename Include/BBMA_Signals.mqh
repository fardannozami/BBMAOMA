//+------------------------------------------------------------------+
//| BBMA_Signals.mqh                                                 |
//| Signal engine: combines the analysed timeframes into PREP/FINAL  |
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

   if(g_thirdIdx >= 0)
      ApplyTF3Rule(g_a[g_thirdIdx]);

   //--- 2 TF preparation: major TF re-entry + second TF confirmation
   g_prepBuy  = (g_a[g_majorIdx].trend > 0 &&
                 g_a[g_majorIdx].reentryBuy &&
                 g_a[g_secondIdx].tf2Buy);

   g_prepSell = (g_a[g_majorIdx].trend < 0 &&
                 g_a[g_majorIdx].reentrySell &&
                 g_a[g_secondIdx].tf2Sell);

   //--- final signal: 2TF mode = prep, 3TF mode = prep + third TF
   bool need3 = (InpConfirmMode == CONFIRM_3TF);
   g_finalBuy  = (g_prepBuy  && (!need3 || (g_thirdIdx >= 0 && g_a[g_thirdIdx].tf3Buy)));
   g_finalSell = (g_prepSell && (!need3 || (g_thirdIdx >= 0 && g_a[g_thirdIdx].tf3Sell)));

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

   s += " | " + TFToStr(g_tf[g_majorIdx]) + " " + TrendStr(g_a[g_majorIdx].trend) + " re-entry";
   s += " | " + TFToStr(g_tf[g_secondIdx]) + " " +
        ((buy ? g_a[g_secondIdx].tf2Buy : g_a[g_secondIdx].tf2Sell) ? "confirm" : "-");

   if(g_thirdIdx >= 0)
      s += " | " + TFToStr(g_tf[g_thirdIdx]) + " " +
           ((buy ? g_a[g_thirdIdx].tf3Buy : g_a[g_thirdIdx].tf3Sell) ? "confirm" : "-");

   s += " | rule " + TF3RuleStr();
   return s;
  }

#endif // BBMA_SIGNALS_MQH
//+------------------------------------------------------------------+
