//+------------------------------------------------------------------+
//| BBMA_Types.mqh                                                   |
//| Enumerations, constants and data structures shared by all BBMA   |
//| modules. Nothing here depends on state or on input variables.    |
//+------------------------------------------------------------------+
#ifndef BBMA_TYPES_MQH
#define BBMA_TYPES_MQH

//--- Number of timeframe slots handled by the EA.
//    Slot order: W1, D1, H4, H1, M15, M5
#define BBMA_TF_SLOTS 6

//+------------------------------------------------------------------+
//| Enums                                                            |
//+------------------------------------------------------------------+
//--- How many timeframes must confirm before a signal becomes FINAL
enum ENUM_CONFIRM_MODE
  {
   CONFIRM_2TF = 0,   // 2 TF
   CONFIRM_3TF = 1    // 3 TF
  };

//--- Position sizing method
enum ENUM_LOT_MODE
  {
   LOT_FIXED    = 0, // Fixed lot
   LOT_COMPOUND = 1  // Risk % compounding
  };

//--- How a position is closed for profit
enum ENUM_CLOSE_RULE
  {
   CLOSE_AT_MA      = 0, // At MA (short term)
   CLOSE_AT_BB      = 1, // At BB top/bottom (medium)
   CLOSE_AT_REVERSE = 2  // At reverse signal (long term)
  };

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
//--- Indicator handles of one timeframe
struct TFHandles
  {
   int bb;
   int ma5;
   int ma10;
   int ema;
   int atr;
  };

//--- Result of the BBMA analysis of one timeframe
struct TFAnalysis
  {
   int      trend;          // 1 bull, -1 bear, 0 none
   bool     extremeBuy;
   bool     extremeSell;
   bool     mhv;
   bool     mhvBuy;
   bool     mhvSell;
   bool     csmBuy;
   bool     csmSell;
   bool     csakBuy;
   bool     csakSell;
   bool     reentryBuy;
   bool     reentrySell;
   bool     gapBuy;
   bool     gapSell;
   bool     rejectionBuy;
   bool     rejectionSell;
   bool     dirAfterMhvBuy;
   bool     dirAfterMhvSell;
   bool     fullSetupBuy;
   bool     fullSetupSell;
   bool     tf2Buy;
   bool     tf2Sell;
   double   bbUpper;
   double   bbLower;
   double   bbMid;
   double   ma5;
   double   ma10;
   double   ema50;
   double   atr;
   datetime barTime;
  };

#endif // BBMA_TYPES_MQH
//+------------------------------------------------------------------+
