//+------------------------------------------------------------------+
//| BBMA_Trading.mqh                                                 |
//| Order execution and position management: lot sizing, entry with  |
//| SL/TP, close-all and the exit rules of open positions.           |
//+------------------------------------------------------------------+
#ifndef BBMA_TRADING_MQH
#define BBMA_TRADING_MQH

//+------------------------------------------------------------------+
//| Own positions of this EA: dir 0 = all, >0 = buys, <0 = sells      |
//+------------------------------------------------------------------+
int CountPositions(const int dir = 0)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      long type = PositionGetInteger(POSITION_TYPE);
      if(dir == 0)
         count++;
      else if(dir > 0 && type == POSITION_TYPE_BUY)
         count++;
      else if(dir < 0 && type == POSITION_TYPE_SELL)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Lot size: fixed, or risk % of balance, capped by free margin     |
//+------------------------------------------------------------------+
double CalcLot(const double dist, const double price, const int dir)
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

      lot = risk / lossPerLot;
     }

   lot = NormalizeLot(lot);

   double margin = 0.0;
   ENUM_ORDER_TYPE ot = (dir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(OrderCalcMargin(ot, _Symbol, lot, price, margin))
     {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(margin > 0.0 && margin > freeMargin * 0.9)
         lot = NormalizeLot(lot * (freeMargin * 0.9 / margin));
     }

   return lot;
  }

//+------------------------------------------------------------------+
//| Open a market order: dir 1 = buy, -1 = sell                      |
//+------------------------------------------------------------------+
bool OpenTrade(const int dir)
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

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      Print("Trading is not allowed (terminal or EA settings).");
      return false;
     }

   int total = CountPositions();
   if(!InpAllowLayering && total >= 1)
      return false;
   if(total >= InpMaxPositions)
      return false;

   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(InpMaxSpread > 0 && spread > InpMaxSpread)
     {
      Print("Spread too high: ", spread, " > ", InpMaxSpread);
      return false;
     }

   //--- stop distance from ATR of the major TF (fallback: third TF)
   double atr = g_a[g_majorIdx].atr;
   if(atr <= 0.0 && g_thirdIdx >= 0)
      atr = g_a[g_thirdIdx].atr;
   if(atr <= 0.0)
      return false;

   double dist = MathMax(atr * InpSLATR, InpMinSLPoints * _Point);
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   dist = MathMax(dist, (stopsLevel + InpStopBufferPts) * _Point);

   double price = (dir > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                           : SymbolInfoDouble(_Symbol, SYMBOL_BID));
   if(price <= 0.0)
      return false;

   double sl = (dir > 0 ? price - dist : price + dist);
   double tp = (dir > 0 ? price + dist * InpRR : price - dist * InpRR);

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   double lot = CalcLot(dist, price, dir);
   if(lot <= 0.0)
      return false;

   bool ok = false;
   if(dir > 0)
      ok = g_trade.Buy(lot, _Symbol, price, sl, tp, "BBMA_MTF");
   else
      ok = g_trade.Sell(lot, _Symbol, price, sl, tp, "BBMA_MTF");

   if(!ok)
      Print("Order failed: retcode=", g_trade.ResultRetcode(), " ", g_trade.ResultComment());
   else
      Print("Opened ", (dir > 0 ? "BUY " : "SELL "), lot, " ", _Symbol,
            " SL=", sl, " TP=", tp);

   return ok;
  }

//+------------------------------------------------------------------+
//| Close every position of this EA on the current symbol            |
//+------------------------------------------------------------------+
void CloseAll()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      g_trade.PositionClose(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Apply the exit rules to the open positions                       |
//| Cut-loss uses the second TF, profit targets the major TF.        |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   if(g_majorIdx < 0 || g_secondIdx < 0)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double ma5   = g_a[g_majorIdx].ma5;
   double ma10  = g_a[g_majorIdx].ma10;
   double bbU   = g_a[g_majorIdx].bbUpper;
   double bbL   = g_a[g_majorIdx].bbLower;

   bool csmBuy  = g_a[g_secondIdx].csmBuy;
   bool csmSell = g_a[g_secondIdx].csmSell;
   double ema50 = g_a[g_secondIdx].ema50;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      long type = PositionGetInteger(POSITION_TYPE);
      bool close = false;
      string why = "";

      if(type == POSITION_TYPE_BUY)
        {
         if(InpCutLossOnCSM && csmSell && ema50 > 0.0 && bid < ema50)
           {
            close = true;
            why = "cut-loss CSM+EMA50";
           }
         else if(InpCloseMode == CLOSE_AT_MA && ma5 > 0.0 && bid <= ma5)
           {
            close = true;
            why = "close at MA";
           }
         else if(InpCloseMode == CLOSE_AT_BB && bbU > 0.0 && bid >= bbU)
           {
            close = true;
            why = "close at upper BB";
           }
         else if(InpCloseMode == CLOSE_AT_REVERSE && g_finalSell)
           {
            close = true;
            why = "reverse signal";
           }
        }
      else if(type == POSITION_TYPE_SELL)
        {
         if(InpCutLossOnCSM && csmBuy && ema50 > 0.0 && ask > ema50)
           {
            close = true;
            why = "cut-loss CSM+EMA50";
           }
         else if(InpCloseMode == CLOSE_AT_MA && ma10 > 0.0 && ask >= ma10)
           {
            close = true;
            why = "close at MA";
           }
         else if(InpCloseMode == CLOSE_AT_BB && bbL > 0.0 && ask <= bbL)
           {
            close = true;
            why = "close at lower BB";
           }
         else if(InpCloseMode == CLOSE_AT_REVERSE && g_finalBuy)
           {
            close = true;
            why = "reverse signal";
           }
        }

      if(close)
        {
         if(g_trade.PositionClose(ticket))
            Print("Closed #", ticket, ": ", why);
        }
     }
  }

#endif // BBMA_TRADING_MQH
//+------------------------------------------------------------------+
