//+------------------------------------------------------------------+
//| BBMA_Trading.mqh                                                 |
//| Order execution and basket management: lot sizing, single entry  |
//| with SL/TP or layering (instant + limit/stop pending orders),    |
//| close-all, exit rules, break-even and percentage trailing.       |
//|                                                                  |
//| A "basket" = every position and pending order of this EA on the  |
//| current symbol. Only one basket (one direction) is open at once. |
//+------------------------------------------------------------------+
#ifndef BBMA_TRADING_MQH
#define BBMA_TRADING_MQH

bool TradingWindowOk();   // defined in BBMA_Risk.mqh

//+------------------------------------------------------------------+
//| Ownership helpers                                                |
//+------------------------------------------------------------------+
bool IsOwnPosition()
  {
   return (PositionGetString(POSITION_SYMBOL) == _Symbol &&
           PositionGetInteger(POSITION_MAGIC) == InpMagic);
  }

bool IsOwnOrder()
  {
   return (OrderGetString(ORDER_SYMBOL) == _Symbol &&
           OrderGetInteger(ORDER_MAGIC) == InpMagic);
  }

//+------------------------------------------------------------------+
//| Own positions of this EA: dir 0 = all, >0 = buys, <0 = sells      |
//+------------------------------------------------------------------+
int CountPositions(const int dir = 0)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i) == 0 || !IsOwnPosition())
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if(dir == 0 ||
         (dir > 0 && type == POSITION_TYPE_BUY) ||
         (dir < 0 && type == POSITION_TYPE_SELL))
         count++;
     }
   return count;
  }

//--- Own pending orders: dir 0 = all, >0 = buy side, <0 = sell side
int CountPendings(const int dir = 0)
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderGetTicket(i) == 0 || !IsOwnOrder())
         continue;
      long type = OrderGetInteger(ORDER_TYPE);
      bool buySide = (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP);
      if(dir == 0 || (dir > 0 && buySide) || (dir < 0 && !buySide))
         count++;
     }
   return count;
  }

//--- Direction of the open basket: 1 buy, -1 sell, 0 none
int BasketDir()
  {
   if(CountPositions(1) > 0 || CountPendings(1) > 0)
      return 1;
   if(CountPositions(-1) > 0 || CountPendings(-1) > 0)
      return -1;
   return 0;
  }

//--- Floating P/L of all own positions (profit + swap)
double BasketProfit()
  {
   double p = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i) == 0 || !IsOwnPosition())
         continue;
      p += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
     }
   return p;
  }

//+------------------------------------------------------------------+
//| 1 pip = 10 points (XAUUSD 2 digits: 10 pips = $1.00)             |
//+------------------------------------------------------------------+
double PipSize()
  {
   return _Point * 10.0;
  }

//+------------------------------------------------------------------+
//| Lot size: fixed, or risk % of balance spread over <orders>,      |
//| capped by free margin.                                           |
//+------------------------------------------------------------------+
double CalcLot(const double dist, const double price, const int dir, const int orders = 1)
  {
   double lot = InpLot;

   if(InpLotMode == LOT_COMPOUND)
     {
      double risk = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

      if(tickValue <= 0.0 || tickSize <= 0.0)
         return NormalizeLot(InpLot);

      double lossPerLot = (dist / tickSize) * tickValue;
      if(lossPerLot <= 0.0)
         return NormalizeLot(InpLot);

      lot = risk / lossPerLot / MathMax(1, orders);
     }

   lot = NormalizeLot(lot);

   double margin = 0.0;
   ENUM_ORDER_TYPE ot = (dir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(OrderCalcMargin(ot, _Symbol, lot, price, margin))
     {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      double share = freeMargin * 0.9 / MathMax(1, orders);
      if(margin > 0.0 && margin > share)
         lot = NormalizeLot(lot * (share / margin));
     }

   return lot;
  }

//+------------------------------------------------------------------+
//| Stop distance from the ATR of the major TF                        |
//+------------------------------------------------------------------+
double StopDistance()
  {
   double atr = g_a[g_majorIdx].atr;
   if(atr <= 0.0 && g_thirdIdx >= 0)
      atr = g_a[g_thirdIdx].atr;
   if(atr <= 0.0)
      return 0.0;

   double dist = MathMax(atr * InpSLATR, InpMinSLPoints * _Point);
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   return MathMax(dist, (stopsLevel + InpStopBufferPts) * _Point);
  }

//+------------------------------------------------------------------+
//| Pending orders of one layering basket                            |
//+------------------------------------------------------------------+
void PlaceLayers(const int dir, const double price, const double lot, const double dist, const bool withSLTP)
  {
   bool useLimit = (InpOrderMode == ORDERS_INSTANT_LIMIT || InpOrderMode == ORDERS_INSTANT_STOP_LIM);
   bool useStop  = (InpOrderMode == ORDERS_INSTANT_STOP  || InpOrderMode == ORDERS_INSTANT_STOP_LIM);
   double step = InpDistancePips * PipSize();
   if(step <= 0.0)
      return;

   datetime exp = 0;
   ENUM_ORDER_TYPE_TIME tt = ORDER_TIME_GTC;

   for(int k = 1; k <= InpLevels; k++)
     {
      if(useLimit)
        {
         double p = NormalizeDouble(dir > 0 ? price - k * step : price + k * step, _Digits);
         double sl = 0.0, tp = 0.0;
         if(withSLTP)
           {
            sl = NormalizeDouble(dir > 0 ? p - dist : p + dist, _Digits);
            tp = NormalizeDouble(dir > 0 ? p + dist * InpRR : p - dist * InpRR, _Digits);
           }
         bool ok = (dir > 0 ? g_trade.BuyLimit(lot, p, _Symbol, sl, tp, tt, exp, "BBMA_L")
                            : g_trade.SellLimit(lot, p, _Symbol, sl, tp, tt, exp, "BBMA_L"));
         if(!ok)
            Print("Limit order failed: ", g_trade.ResultRetcode(), " ", g_trade.ResultComment());
        }
      if(useStop)
        {
         double p = NormalizeDouble(dir > 0 ? price + k * step : price - k * step, _Digits);
         double sl = 0.0, tp = 0.0;
         if(withSLTP)
           {
            sl = NormalizeDouble(dir > 0 ? p - dist : p + dist, _Digits);
            tp = NormalizeDouble(dir > 0 ? p + dist * InpRR : p - dist * InpRR, _Digits);
           }
         bool ok = (dir > 0 ? g_trade.BuyStop(lot, p, _Symbol, sl, tp, tt, exp, "BBMA_S")
                            : g_trade.SellStop(lot, p, _Symbol, sl, tp, tt, exp, "BBMA_S"));
         if(!ok)
            Print("Stop order failed: ", g_trade.ResultRetcode(), " ", g_trade.ResultComment());
        }
     }
  }

//+------------------------------------------------------------------+
//| Open a basket: dir 1 = buy, -1 = sell                            |
//| manual = true when started from a dashboard button               |
//+------------------------------------------------------------------+
bool OpenTrade(const int dir, const bool manual = false)
  {
   if(!g_configOk)
     {
      Print("TF configuration is invalid - no trade.");
      return false;
     }

   if(g_blocked)
     {
      Print("Trade blocked (daily limit / Friday close).");
      return false;
     }

   if(!manual && !TradingWindowOk())
      return false;

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      Print("Trading is not allowed (terminal or EA settings).");
      return false;
     }

   //--- one basket at a time
   if(BasketDir() != 0)
      return false;
   if(InpMaxPositions > 0 && CountPositions() >= InpMaxPositions)
      return false;

   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(InpMaxSpread > 0 && spread > InpMaxSpread)
     {
      Print("Spread too high: ", spread, " > ", InpMaxSpread);
      return false;
     }

   double dist = StopDistance();
   if(dist <= 0.0)
      return false;

   double price = (dir > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                           : SymbolInfoDouble(_Symbol, SYMBOL_BID));
   if(price <= 0.0)
      return false;

   bool layering = (InpOrderMode != ORDERS_SINGLE);
   int  perSide  = ((InpOrderMode == ORDERS_INSTANT_STOP_LIM) ? 2 : 1);
   int  orders   = (layering ? 1 + InpLevels * perSide : 1);
   bool withSLTP = (!layering || InpLayerSLTP);

   double sl = 0.0, tp = 0.0;
   if(withSLTP)
     {
      sl = NormalizeDouble(dir > 0 ? price - dist : price + dist, _Digits);
      tp = NormalizeDouble(dir > 0 ? price + dist * InpRR : price - dist * InpRR, _Digits);
     }

   double lot = CalcLot(dist, price, dir, orders);
   if(lot <= 0.0)
      return false;

   bool ok = (dir > 0 ? g_trade.Buy(lot, _Symbol, price, sl, tp, "BBMA_MTF")
                      : g_trade.Sell(lot, _Symbol, price, sl, tp, "BBMA_MTF"));

   if(!ok)
     {
      Print("Order failed: retcode=", g_trade.ResultRetcode(), " ", g_trade.ResultComment());
      return false;
     }

   Print("Opened ", (dir > 0 ? "BUY " : "SELL "), lot, " ", _Symbol, " SL=", sl, " TP=", tp,
         (layering ? StringFormat(" + %d layer(s)", orders - 1) : ""));

   if(layering && InpLevels > 0)
      PlaceLayers(dir, price, lot, dist, withSLTP);

   g_beDone = false;
   g_basketPeakPct = 0.0;
   return true;
  }

//+------------------------------------------------------------------+
//| Delete every pending order of this EA                            |
//+------------------------------------------------------------------+
void DeletePendings()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !IsOwnOrder())
         continue;
      g_trade.OrderDelete(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Close every position and pending order of this EA                |
//+------------------------------------------------------------------+
void CloseAll()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsOwnPosition())
         continue;
      g_trade.PositionClose(ticket);
     }
   DeletePendings();
   g_beDone = false;
   g_basketPeakPct = 0.0;
  }

//+------------------------------------------------------------------+
//| Move the SL of every own position of direction dir to entry      |
//| (+ buffer). Used by the "At reverse signal" close rule.          |
//+------------------------------------------------------------------+
void BreakEvenAll(const int dir)
  {
   double buffer = InpStopBufferPts * _Point;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsOwnPosition())
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if((dir > 0 && type != POSITION_TYPE_BUY) || (dir < 0 && type != POSITION_TYPE_SELL))
         continue;

      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double be = NormalizeDouble(dir > 0 ? open + buffer : open - buffer, _Digits);
      double px = (dir > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK));

      //--- only improve the stop, and only when price is beyond it
      if(dir > 0 && (curSL >= be || px <= be))
         continue;
      if(dir < 0 && ((curSL > 0.0 && curSL <= be) || px >= be))
         continue;

      g_trade.PositionModify(ticket, be, tp);
     }
  }

//+------------------------------------------------------------------+
//| Percentage trailing on the floating profit of the basket.        |
//| Start at InpTrailStartPct of balance, then keep the locked level |
//| at peak - (start - lock). Close all when profit falls back to it. |
//+------------------------------------------------------------------+
bool TrailingHit()
  {
   if(InpTrailStartPct <= 0.0 || InpTrailLockPct <= 0.0)
      return false;

   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(bal <= 0.0)
      return false;

   double pct = BasketProfit() / bal * 100.0;
   if(pct > g_basketPeakPct)
      g_basketPeakPct = pct;

   if(g_basketPeakPct < InpTrailStartPct)
      return false;

   double lockLevel = g_basketPeakPct - (InpTrailStartPct - InpTrailLockPct);
   return (pct <= lockLevel);
  }

//+------------------------------------------------------------------+
//| Exit rules for the open basket. Profit targets use the major TF,  |
//| cut-loss uses the second TF.                                     |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   if(g_majorIdx < 0 || g_secondIdx < 0)
      return;

   int nPos = CountPositions();

   //--- stale pending orders without any open position
   if(nPos == 0)
     {
      g_beDone = false;
      g_basketPeakPct = 0.0;
      if(InpPendingExpiryHours > 0 && CountPendings() > 0)
        {
         datetime now = TimeCurrent();
         for(int i = OrdersTotal() - 1; i >= 0; i--)
           {
            ulong ticket = OrderGetTicket(i);
            if(ticket == 0 || !IsOwnOrder())
               continue;
            if(now - (datetime)OrderGetInteger(ORDER_TIME_SETUP) >= InpPendingExpiryHours * 3600)
               g_trade.OrderDelete(ticket);
           }
        }
      return;
     }

   int dir = (CountPositions(1) > 0 ? 1 : -1);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   TFAnalysis maj = g_a[g_majorIdx];
   TFAnalysis sec = g_a[g_secondIdx];

   bool close = false;
   string why = "";

   if(TrailingHit())
     {
      close = true;
      why = StringFormat("trailing lock (peak %.2f%%)", g_basketPeakPct);
     }
   else if(dir > 0)
     {
      if(InpCutLossOnCSM && sec.csmSell && sec.ema50 > 0.0 && bid < sec.ema50)
        { close = true; why = "cut-loss CSM+EMA50"; }
      else if(InpCloseMode == CLOSE_AT_MA && maj.ma10 > 0.0 && bid < maj.ma10)
        { close = true; why = "close at MA (break MA low)"; }
      else if(InpCloseMode == CLOSE_AT_BB && maj.bbUpper > 0.0 && bid >= maj.bbUpper)
        { close = true; why = "close at upper BB"; }
      else if(InpCloseMode == CLOSE_AT_REVERSE)
        {
         if(!g_beDone && maj.bbUpper > 0.0 && bid >= maj.bbUpper)
           { BreakEvenAll(1); g_beDone = true; }
         if(maj.extremeSell || sec.csmSell || g_finalSell)
           { close = true; why = "reverse (extreme major / CSM TF2 / sell signal)"; }
        }
     }
   else
     {
      if(InpCutLossOnCSM && sec.csmBuy && sec.ema50 > 0.0 && ask > sec.ema50)
        { close = true; why = "cut-loss CSM+EMA50"; }
      else if(InpCloseMode == CLOSE_AT_MA && maj.ma5 > 0.0 && ask > maj.ma5)
        { close = true; why = "close at MA (break MA high)"; }
      else if(InpCloseMode == CLOSE_AT_BB && maj.bbLower > 0.0 && ask <= maj.bbLower)
        { close = true; why = "close at lower BB"; }
      else if(InpCloseMode == CLOSE_AT_REVERSE)
        {
         if(!g_beDone && maj.bbLower > 0.0 && ask <= maj.bbLower)
           { BreakEvenAll(-1); g_beDone = true; }
         if(maj.extremeBuy || sec.csmBuy || g_finalBuy)
           { close = true; why = "reverse (extreme major / CSM TF2 / buy signal)"; }
        }
     }

   if(close)
     {
      Print("Closing basket (", nPos, " pos): ", why);
      CloseAll();
     }
  }

#endif // BBMA_TRADING_MQH
//+------------------------------------------------------------------+
