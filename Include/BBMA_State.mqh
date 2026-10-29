//+------------------------------------------------------------------+
//| BBMA_State.mqh                                                   |
//| All mutable EA state (timeframes, analysis results, signals,     |
//| daily guard) plus the trade object. This file is included once,  |
//| from the main .mq5, after the input variables are declared.      |
//+------------------------------------------------------------------+
#ifndef BBMA_STATE_MQH
#define BBMA_STATE_MQH

#include <Trade\Trade.mqh>

//--- TF registry: fixed slots, highest timeframe first
ENUM_TIMEFRAMES g_tf[BBMA_TF_SLOTS];      // W1, D1, H4, H1, M15, M5
TFHandles       g_h[BBMA_TF_SLOTS];       // indicator handles per slot
TFAnalysis      g_a[BBMA_TF_SLOTS];       // last analysis per slot
datetime        g_lastBar[BBMA_TF_SLOTS]; // last processed bar time per slot
bool            g_use[BBMA_TF_SLOTS];     // slot enabled by inputs

//--- Enabled slots and their role in the confirmation chain
int  g_enabled[BBMA_TF_SLOTS];            // active slot indexes, ascending
int  g_count      = 0;                    // number of active slots
int  g_majorIdx   = -1;                   // highest TF  : trend + re-entry
int  g_secondIdx  = -1;                   // middle TF   : gap / rejection
int  g_thirdIdx   = -1;                   // lowest TF, -1 in 2TF mode
bool g_configOk   = false;                // slot count matches the mode

//--- Current signal state
bool g_prepBuy   = false;
bool g_prepSell  = false;
bool g_finalBuy  = false;
bool g_finalSell = false;
string g_activeSetup = "";

//--- Previous signal state (edge detection)
bool g_prevPrepBuy   = false;
bool g_prevPrepSell  = false;
bool g_prevFinalBuy  = false;
bool g_prevFinalSell = false;

//--- One-shot events, consumed by OnTick()
bool g_eventPrepBuy   = false;
bool g_eventPrepSell  = false;
bool g_eventFinalBuy  = false;
bool g_eventFinalSell = false;

//--- Daily risk guard
int    g_day              = -1;
double g_dayStartBalance  = 0.0;
bool   g_blocked          = false;
bool   g_autoTrade        = false;  // Auto-trade toggle (diaktifkan via tombol AUTO di dashboard)

//--- Trading / UI objects
CTrade       g_trade;
const string g_prefix = "BBMA_";

#endif // BBMA_STATE_MQH
//+------------------------------------------------------------------+
