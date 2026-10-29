//+------------------------------------------------------------------+
//| BBMA_Analysis.mqh                                                |
//| BBMA pattern detection on a single timeframe. Pure calculation:  |
//| no alerts, no orders, no UI.                                      |
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
   if(avail < 10)
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

   //--- Extreme: MA10 low outside lower BB / MA5 high outside upper BB,
   //    followed by a reversal candle.
   s.extremeBuy  = (ma10[1] < bbL[1] && lo1 <= bbL[1] && c1 > o1);
   s.extremeSell = (ma5[1] > bbU[1] && hi1 >= bbU[1] && c1 < o1);

   //--- MA5/10 zone for the sequence checks below
   double zoneLo = MathMin(ma5[1], ma10[1]);
   double zoneHi = MathMax(ma5[1], ma10[1]);

   //--- CSM and CSAK/CSD: directional breaks of the MA and BB levels.
   bool bull1 = (c1 > o1);
   s.csmBuy  = (bull1 && c1 > ma5[1] && c1 > bbU[1]);
   s.csmSell = (!bull1 && c1 < ma10[1] && c1 < bbL[1]);
   s.csakBuy  = (bull1 && c1 > ma5[1] && c1 > bbM[1]);
   s.csakSell = (!bull1 && c1 < ma10[1] && c1 < bbM[1]);

   //--- Re-entry: prior candle rejects the MA5/10 edge, then this
   //    closed candle confirms with CSAK or CSM in the same direction.
   bool rejectedBuyMA  = (lo2 <= ma10[2] && c2 > ma10[2]);
   bool rejectedSellMA = (hi2 >= ma5[2] && c2 < ma5[2]);
   s.reentryBuy  = (rejectedBuyMA && (s.csakBuy || s.csmBuy));
   s.reentrySell = (rejectedSellMA && (s.csakSell || s.csmSell));

   //--- MHV: after an extreme, price returns to the MA zone and no
   //    opposing CSM has broken the extreme level.
   int extremeBuyBar = -1, extremeSellBar = -1;
   for(int i = 2; i <= maxI; i++)
     {
      if(extremeBuyBar < 0 && ma10[i] < bbL[i] && iLow(_Symbol, tf, i) <= bbL[i] && iClose(_Symbol, tf, i) > iOpen(_Symbol, tf, i))
         extremeBuyBar = i;
      if(extremeSellBar < 0 && ma5[i] > bbU[i] && iHigh(_Symbol, tf, i) >= bbU[i] && iClose(_Symbol, tf, i) < iOpen(_Symbol, tf, i))
         extremeSellBar = i;
     }
   bool buyExtremeBroken = false, sellExtremeBroken = false;
   if(extremeBuyBar > 1)
     {
      double extremeLow = iLow(_Symbol, tf, extremeBuyBar);
      for(int i = extremeBuyBar - 1; i >= 1; i--)
         if(iClose(_Symbol, tf, i) < iOpen(_Symbol, tf, i) && iClose(_Symbol, tf, i) < ma10[i] && iClose(_Symbol, tf, i) < bbL[i] && iClose(_Symbol, tf, i) < extremeLow)
            buyExtremeBroken = true;
     }
   if(extremeSellBar > 1)
     {
      double extremeHigh = iHigh(_Symbol, tf, extremeSellBar);
      for(int i = extremeSellBar - 1; i >= 1; i--)
         if(iClose(_Symbol, tf, i) > iOpen(_Symbol, tf, i) && iClose(_Symbol, tf, i) > ma5[i] && iClose(_Symbol, tf, i) > bbU[i] && iClose(_Symbol, tf, i) > extremeHigh)
            sellExtremeBroken = true;
     }
   bool atMAZone = (lo1 <= zoneHi && hi1 >= zoneLo);
   s.mhvBuy  = (extremeBuyBar > 1 && !buyExtremeBroken && atMAZone);
   s.mhvSell = (extremeSellBar > 1 && !sellExtremeBroken && atMAZone);
   s.mhv = (s.mhvBuy || s.mhvSell);

   //--- Rejected EMA50: EMA50 is on the trend side of BB mid and the
   //    closed candle rejects it. GAP: EMA50 is beyond an outer BB and
   //    price rejects that same outer band.
   s.rejectionBuy  = (ema[1] < bbM[1] && lo1 <= ema[1] && c1 > ema[1] && bull1);
   s.rejectionSell = (ema[1] > bbM[1] && hi1 >= ema[1] && c1 < ema[1] && !bull1);
   s.gapBuy  = (ema[1] < bbL[1] && lo1 <= bbL[1] && c1 > bbL[1] && bull1);
   s.gapSell = (ema[1] > bbU[1] && hi1 >= bbU[1] && c1 < bbU[1] && !bull1);

   //--- TF2 confirmation (gap or rejection)
   s.tf2Buy  = (s.gapBuy  || s.rejectionBuy);
   s.tf2Sell = (s.gapSell || s.rejectionSell);

   //--- Direction after MHV and the full Extreme > TPW > MHV >
   //    Direction > Re-entry sequence, evaluated oldest to newest.
   bool seenExtremeForMhvBuy = false, seenExtremeForMhvSell = false;
   bool passedMhvBuy = false, passedMhvSell = false;
   bool seenExtBuy = false, seenTpwBuy = false, seenMhvSeqBuy = false, seenDirBuy = false;
   bool seenExtSell = false, seenTpwSell = false, seenMhvSeqSell = false, seenDirSell = false;
   bool fullBuy = false, fullSell = false;
   double extremeLow = 0.0, extremeHigh = 0.0;
   for(int i = maxI; i >= 1; i--)
     {
      double oi = iOpen(_Symbol, tf, i), ci = iClose(_Symbol, tf, i);
      double hi = iHigh(_Symbol, tf, i), lo = iLow(_Symbol, tf, i);
      bool bull = (ci > oi), bear = (ci < oi);
      double zl = MathMin(ma5[i], ma10[i]), zh = MathMax(ma5[i], ma10[i]);
      bool inZone = (lo <= zh && hi >= zl);
      bool extBuyI = (ma10[i] < bbL[i] && lo <= bbL[i] && bull);
      bool extSellI = (ma5[i] > bbU[i] && hi >= bbU[i] && bear);
      bool csmBuyI = (bull && ci > ma5[i] && ci > bbU[i]);
      bool csmSellI = (bear && ci < ma10[i] && ci < bbL[i]);
      bool dirBuyI = (bull && ci > ma5[i] && ci > bbM[i]);
      bool dirSellI = (bear && ci < ma10[i] && ci < bbM[i]);
      bool rejectBuyI = false, rejectSellI = false;
      if(i < maxI)
        {
         double olderClose = iClose(_Symbol, tf, i + 1);
         double olderLow = iLow(_Symbol, tf, i + 1);
         double olderHigh = iHigh(_Symbol, tf, i + 1);
         rejectBuyI = (olderLow <= ma10[i + 1] && olderClose > ma10[i + 1]);
         rejectSellI = (olderHigh >= ma5[i + 1] && olderClose < ma5[i + 1]);
        }

      if(extBuyI)
        { seenExtremeForMhvBuy = true; passedMhvBuy = false; }
      else if(seenExtremeForMhvBuy && csmSellI && ci < iLow(_Symbol, tf, i + 1))
        { seenExtremeForMhvBuy = false; passedMhvBuy = false; }
      else if(seenExtremeForMhvBuy && inZone)
        passedMhvBuy = true;
      else if(passedMhvBuy && dirBuyI)
        s.dirAfterMhvBuy = true;

      if(extSellI)
        { seenExtremeForMhvSell = true; passedMhvSell = false; }
      else if(seenExtremeForMhvSell && csmBuyI && ci > iHigh(_Symbol, tf, i + 1))
        { seenExtremeForMhvSell = false; passedMhvSell = false; }
      else if(seenExtremeForMhvSell && inZone)
        passedMhvSell = true;
      else if(passedMhvSell && dirSellI)
        s.dirAfterMhvSell = true;

      if(extBuyI)
        { seenExtBuy = true; seenTpwBuy = false; seenMhvSeqBuy = false; seenDirBuy = false; fullBuy = false; extremeLow = lo; continue; }
      if(seenExtBuy)
        {
         if(csmSellI && ci < extremeLow) { seenExtBuy = false; continue; }
         if(!seenTpwBuy) { if(inZone) seenTpwBuy = true; continue; }
         if(!seenMhvSeqBuy) { if(inZone && !csmSellI) seenMhvSeqBuy = true; continue; }
         if(!seenDirBuy) { if(dirBuyI) seenDirBuy = true; continue; }
         if(rejectBuyI && dirBuyI) fullBuy = true;
        }

      if(extSellI)
        { seenExtSell = true; seenTpwSell = false; seenMhvSeqSell = false; seenDirSell = false; fullSell = false; extremeHigh = hi; continue; }
      if(seenExtSell)
        {
         if(csmBuyI && ci > extremeHigh) { seenExtSell = false; continue; }
         if(!seenTpwSell) { if(inZone) seenTpwSell = true; continue; }
         if(!seenMhvSeqSell) { if(inZone && !csmBuyI) seenMhvSeqSell = true; continue; }
         if(!seenDirSell) { if(dirSellI) seenDirSell = true; continue; }
         if(rejectSellI && dirSellI) fullSell = true;
        }
     }
   s.fullSetupBuy = fullBuy;
   s.fullSetupSell = fullSell;

   return true;
  }

#endif // BBMA_ANALYSIS_MQH
//+------------------------------------------------------------------+
