//+------------------------------------------------------------------+
//| BBMA_Utils.mqh                                                   |
//| Small helpers without side effects: text formatting for the UI,  |
//| price-series access and new-bar detection.                       |
//+------------------------------------------------------------------+
#ifndef BBMA_UTILS_MQH
#define BBMA_UTILS_MQH

//+------------------------------------------------------------------+
//| Text helpers                                                     |
//+------------------------------------------------------------------+
//--- "PERIOD_H1" -> "H1"
string TFToStr(const ENUM_TIMEFRAMES tf)
  {
   string s = EnumToString(tf);
   StringReplace(s, "PERIOD_", "");
   return s;
  }

string YN(const bool b)
  {
   return (b ? "YES" : "-");
  }

string TrendStr(const int t)
  {
   if(t > 0)
      return "UP";
   if(t < 0)
      return "DOWN";
   return "FLAT";
  }

//--- Short label of the selected TF3 rule, used on the dashboard/alerts
string TF3RuleStr()
  {
   switch(InpTF3Rule)
     {
      case TF3_EXTREME:
         return "EXTREME";
      case TF3_MHV:
         return "MHV";
      case TF3_DIRECTION:
         return "DIRECTION";
      case TF3_FULL_SETUP:
         return "FULL";
      default:
         return "ANY";
     }
  }

//--- Minimal URL escaping for the Telegram request
string UrlEncode(string s)
  {
   StringReplace(s, "%", "%25");
   StringReplace(s, " ", "%20");
   StringReplace(s, "\n", "%0A");
   StringReplace(s, "&", "%26");
   StringReplace(s, "#", "%23");
   StringReplace(s, "?", "%3F");
   return s;
  }

//+------------------------------------------------------------------+
//| Market data helpers                                              |
//+------------------------------------------------------------------+
//--- True once per new bar of the given timeframe
bool IsNewBar(const ENUM_TIMEFRAMES tf, datetime &last)
  {
   datetime t = iTime(_Symbol, tf, 0);
   if(t == 0)
      return false;
   if(t != last)
     {
      last = t;
      return true;
     }
   return false;
  }

//--- Copy <count> values of an indicator buffer, index 0 = newest bar
bool BufSeries(const int handle, const int buffer, const int count, double &arr[])
  {
   ArraySetAsSeries(arr, true);
   int copied = CopyBuffer(handle, buffer, 0, count, arr);
   return (copied == count);
  }

//+------------------------------------------------------------------+
//| Volume helpers                                                   |
//+------------------------------------------------------------------+
//--- Round a lot to the broker step and clamp it to min/max
double NormalizeLot(double lot)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mn   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(step <= 0.0)
      step = 0.01;

   lot = MathFloor(lot / step + 1e-9) * step;
   lot = MathMax(mn, MathMin(mx, lot));

   int digits = (int)MathMax(0.0, MathCeil(-MathLog10(step)));
   return NormalizeDouble(lot, digits);
  }

#endif // BBMA_UTILS_MQH
//+------------------------------------------------------------------+
