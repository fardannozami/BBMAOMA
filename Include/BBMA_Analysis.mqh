//+------------------------------------------------------------------+
//| BBMA_Analysis.mqh                                                |
//| BBMA pattern detection on a single timeframe and the TF3 rule    |
//| selector. Pure calculation: no alerts, no orders, no UI.         |
//+------------------------------------------------------------------+
#ifndef BBMA_ANALYSIS_MQH
#define BBMA_ANALYSIS_MQH

//+------------------------------------------------------------------+
//| Analyse the last closed bar of one timeframe                     |
//| Fills s with trend, extreme, MHV, CSM, CSAK, re-entry, GAP,      |
//| rejection, direction-after-MHV and full setup flags.             |
//+------------------------------------------------------------------+
bool AnalyzeTF(const ENUM_TIMEFRAMES tf, TFHandles &h, TFAnalysis &s)
  {
   ZeroMemory(s);

   int avail = Bars(_Symbol, tf);
   if(avail < InpExtremeLookback + 6)
      return false;

   int need = InpSetupLookback + 10;
   if(need > avail - 1)
      need = avail - 1;
   if(need < 8)
      return false;

   double bbU[], bbL[], bbM[], ma5[], ma10[], ema[], atr[];
   if(!BufSeries(h.bb,   1, need, bbU))  return false;
   if(!BufSeries(h.bb,   2, need, bbL))  return false;
   if(!BufSeries(h.bb,   0, need, bbM))  return false;
   if(!BufSeries(h.ma5,  0, need, ma5))  return false;
   if(!BufSeries(h.ma10, 0, need, ma10)) return false;
   if(!BufSeries(h.ema,  0, need, ema))  return false;
   if(!BufSeries(h.atr,  0, need, atr))  return false;

   double o1  = iOpen(_Symbol, tf, 1);
   double hi1 = iHigh(_Symbol, tf, 1);
   double lo1 = iLow(_Symbol, tf, 1);
   double c1  = iClose(_Symbol, tf, 1);

   double o2  = iOpen(_Symbol, tf, 2);
   double hi2 = iHigh(_Symbol, tf, 2);
   double lo2 = iLow(_Symbol, tf, 2);
   double c2  = iClose(_Symbol, tf, 2);

   if(c1 <= 0.0 || c2 <= 0.0 || lo1 <= 0.0 || hi1 <= 0.0)
      return false;

   s.bbUpper = bbU[1];
   s.bbLower = bbL[1];
   s.bbMid   = bbM[1];
   s.ma5     = ma5[1];
   s.ma10    = ma10[1];
   s.ema50   = ema[1];
   s.atr     = atr[1];
   s.barTime = iTime(_Symbol, tf, 1);

   //--- trend: price vs EMA50 + EMA50 slope (+ optional MA stack)
   if(c1 > ema[1] && ema[1] >= ema[2])
      s.trend = 1;
   else if(c1 < ema[1] && ema[1] <= ema[2])
      s.trend = -1;

   if(InpRequireMAStack)
     {
      if(s.trend > 0 && ma5[1] < ma10[1])
         s.trend = 0;
      if(s.trend < 0 && ma5[1] > ma10[1])
         s.trend = 0;
     }

   int maxI = MathMin(InpSetupLookback, need - 1);
   int extI = MathMin(InpExtremeLookback, need - 1);

   //--- extreme (touch / break of BB)
   for(int i = 1; i <= extI; i++)
     {
      if(iLow(_Symbol, tf, i)  <= bbL[i]) s.extremeBuy  = true;
      if(iHigh(_Symbol, tf, i) >= bbU[i]) s.extremeSell = true;
     }

   //--- MHV: candle range overlaps MA5/MA10 zone
   double zoneLo = MathMin(ma5[1], ma10[1]);
   double zoneHi = MathMax(ma5[1], ma10[1]);
   s.mhv = (lo1 <= zoneHi && hi1 >= zoneLo);

   //--- CSM: momentum candle
   double body1 = MathAbs(c1 - o1);
   bool bull1 = (c1 > o1);
   s.csmBuy  = (bull1  && body1 >= InpCsmBodyATR * atr[1] && c1 > ma5[1]);
   s.csmSell = (!bull1 && body1 >= InpCsmBodyATR * atr[1] && c1 < ma10[1]);

   //--- CSAK: direction candle right after MHV
   double prevZoneLo = MathMin(ma5[2], ma10[2]);
   double prevZoneHi = MathMax(ma5[2], ma10[2]);
   bool prevMhv = (lo2 <= prevZoneHi && hi2 >= prevZoneLo);
   s.csakBuy  = (prevMhv && c1 > o1 && c1 > ma5[1]);
   s.csakSell = (prevMhv && c1 < o1 && c1 < ma10[1]);

   //--- re-entry: momentum happened, pullback into MA zone, close back in trend direction
   bool hadBullMomentum = false;
   bool hadBearMomentum = false;
   for(int i = 2; i <= maxI; i++)
     {
      double oi  = iOpen(_Symbol, tf, i);
      double ci  = iClose(_Symbol, tf, i);
      double bi  = MathAbs(ci - oi);
      if(ci > oi && bi >= InpCsmBodyATR * atr[i] && ci > ma5[i])
         hadBullMomentum = true;
      if(ci < oi && bi >= InpCsmBodyATR * atr[i] && ci < ma10[i])
         hadBearMomentum = true;
     }

   double tol = InpPullbackTolATR * atr[1];

   s.reentryBuy = (s.trend > 0 && hadBullMomentum &&
                   lo1 <= ma5[1] + tol && c1 > o1 && c1 > ma5[1]);
   s.reentrySell = (s.trend < 0 && hadBearMomentum &&
                    hi1 >= ma10[1] - tol && c1 < o1 && c1 < ma10[1]);

   //--- GAP: candle opens/closes away from the MA5/MA10 zone
   s.gapBuy  = (lo1 > zoneHi) || (o1 > zoneHi && c1 > zoneHi);
   s.gapSell = (hi1 < zoneLo) || (o1 < zoneLo && c1 < zoneLo);

   //--- Rejection: EMA50 outside Bollinger Bands
   s.rejectionBuy  = (ema[1] < bbL[1]);
   s.rejectionSell = (ema[1] > bbU[1]);

   //--- TF2 confirmation (gap or rejection)
   s.tf2Buy  = (s.gapBuy  || s.rejectionBuy);
   s.tf2Sell = (s.gapSell || s.rejectionSell);

   //--- Direction (first CSAK/CSM) after MHV
   bool seenMhv = false;
   bool dirB = false;
   bool dirS = false;
   for(int i = maxI; i >= 1; i--)
     {
      double zl = MathMin(ma5[i], ma10[i]);
      double zh = MathMax(ma5[i], ma10[i]);
      bool mhvI = (iLow(_Symbol, tf, i) <= zh && iHigh(_Symbol, tf, i) >= zl);

      double oi = iOpen(_Symbol, tf, i);
      double ci = iClose(_Symbol, tf, i);
      double bi = MathAbs(ci - oi);
      bool bullDir = (ci > oi && ci > ma5[i]  && bi >= InpCsmBodyATR * atr[i]);
      bool bearDir = (ci < oi && ci < ma10[i] && bi >= InpCsmBodyATR * atr[i]);

      if(!seenMhv)
        {
         if(mhvI)
            seenMhv = true;
        }
      else
        {
         if(bullDir) dirB = true;
         if(bearDir) dirS = true;
        }
     }
   s.dirAfterMhvBuy  = dirB;
   s.dirAfterMhvSell = dirS;

   //--- Full setup: Extreme -> MHV -> CSAK/CSM -> Re-entry
   bool seenExt = false;
   bool seenMhvSeq = false;
   bool seenDir = false;
   bool seenRe = false;

   for(int i = maxI; i >= 1; i--)
     {
      double zl = MathMin(ma5[i], ma10[i]);
      double zh = MathMax(ma5[i], ma10[i]);

      bool extBuyI = (iLow(_Symbol, tf, i) <= bbL[i]);
      bool mhvI = (iLow(_Symbol, tf, i) <= zh && iHigh(_Symbol, tf, i) >= zl);

      double oi = iOpen(_Symbol, tf, i);
      double ci = iClose(_Symbol, tf, i);
      double bi = MathAbs(ci - oi);

      bool dirBuyI = (ci > oi && ci > ma5[i] && bi >= InpCsmBodyATR * atr[i]);
      bool reBuyI  = (iLow(_Symbol, tf, i) <= ma5[i] && ci > oi && ci > ma5[i]);

      if(!seenExt)
        {
         if(extBuyI)
            seenExt = true;
         continue;
        }
      if(!seenMhvSeq)
        {
         if(mhvI)
            seenMhvSeq = true;
         continue;
        }
      if(!seenDir)
        {
         if(dirBuyI)
            seenDir = true;
         continue;
        }
      if(!seenRe && reBuyI)
         seenRe = true;
     }
   s.fullSetupBuy = seenRe;

   //--- sell mirror of the full setup
   seenExt = false;
   seenMhvSeq = false;
   seenDir = false;
   seenRe = false;

   for(int i = maxI; i >= 1; i--)
     {
      double zl = MathMin(ma5[i], ma10[i]);
      double zh = MathMax(ma5[i], ma10[i]);

      bool extSellI = (iHigh(_Symbol, tf, i) >= bbU[i]);
      bool mhvI = (iLow(_Symbol, tf, i) <= zh && iHigh(_Symbol, tf, i) >= zl);

      double oi = iOpen(_Symbol, tf, i);
      double ci = iClose(_Symbol, tf, i);
      double bi = MathAbs(ci - oi);

      bool dirSellI = (ci < oi && ci < ma10[i] && bi >= InpCsmBodyATR * atr[i]);
      bool reSellI  = (iHigh(_Symbol, tf, i) >= ma10[i] && ci < oi && ci < ma10[i]);

      if(!seenExt)
        {
         if(extSellI)
            seenExt = true;
         continue;
        }
      if(!seenMhvSeq)
        {
         if(mhvI)
            seenMhvSeq = true;
         continue;
        }
      if(!seenDir)
        {
         if(dirSellI)
            seenDir = true;
         continue;
        }
      if(!seenRe && reSellI)
         seenRe = true;
     }
   s.fullSetupSell = seenRe;

   s.tf3Buy  = false;
   s.tf3Sell = false;

   return true;
  }

//+------------------------------------------------------------------+
//| Map the TF3 rule selected in the inputs to tf3Buy / tf3Sell      |
//+------------------------------------------------------------------+
void ApplyTF3Rule(TFAnalysis &s)
  {
   bool buy  = false;
   bool sell = false;

   switch(InpTF3Rule)
     {
      case TF3_EXTREME:
         buy  = s.extremeBuy;
         sell = s.extremeSell;
         break;

      case TF3_MHV:
         buy  = s.mhv;
         sell = s.mhv;
         break;

      case TF3_DIRECTION:
         buy  = (s.csakBuy  || s.csmBuy  || s.dirAfterMhvBuy);
         sell = (s.csakSell || s.csmSell || s.dirAfterMhvSell);
         break;

      case TF3_FULL_SETUP:
         buy  = s.fullSetupBuy;
         sell = s.fullSetupSell;
         break;

      default: // TF3_ANY
         buy  = (s.extremeBuy || s.mhv || s.csakBuy || s.csmBuy ||
                 s.reentryBuy || s.fullSetupBuy || s.dirAfterMhvBuy);
         sell = (s.extremeSell || s.mhv || s.csakSell || s.csmSell ||
                 s.reentrySell || s.fullSetupSell || s.dirAfterMhvSell);
         break;
     }

   s.tf3Buy  = buy;
   s.tf3Sell = sell;
  }

#endif // BBMA_ANALYSIS_MQH
//+------------------------------------------------------------------+
