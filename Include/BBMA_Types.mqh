//+------------------------------------------------------------------+
//| BBMA_Types.mqh                                                   |
//| Enumerations, constants and data structures shared by all BBMA   |
//| modules. Nothing here depends on state or on input variables.    |
//+------------------------------------------------------------------+
#ifndef BBMA_TYPES_MQH
#define BBMA_TYPES_MQH

//--- Number of timeframe slots handled by the EA.
//    Slot order is fixed, highest timeframe first: 0=1D 1=4H 2=1H 3=15M
#define BBMA_TF_SLOTS 4

//+------------------------------------------------------------------+
//| Enums                                                            |
//+------------------------------------------------------------------+
//--- How many timeframes must confirm before a signal becomes FINAL
enum ENUM_CONFIRM_MODE
  {
   CONFIRM_2TF = 0,   // 2 TF
   CONFIRM_3TF = 1    // 3 TF
  };

//--- Which confirmation the third (lowest) timeframe must show
enum ENUM_TF3_RULE
  {
   TF3_ANY        = 0, // Any of the TF3 confirmations
   TF3_EXTREME    = 1, // Extreme only
   TF3_MHV        = 2, // MHV only
   TF3_DIRECTION  = 3, // First CSAK/CSM after MHV
   TF3_FULL_SETUP = 4  // Extreme > MHV > CSM/CSAK > Re-entry
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
   bool     tf3Buy;
   bool     tf3Sell;
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
