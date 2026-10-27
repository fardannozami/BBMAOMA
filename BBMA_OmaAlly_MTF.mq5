//+------------------------------------------------------------------+
//|                                       BBMA_OmaAlly_MTF.mq5       |
//|  BBMA Oma Ally multi-timeframe EA for XAUUSD                     |
//|  Selectable TFs: 1D / 4H / 1H / 15M  |  2TF or 3TF confirmation  |
//+------------------------------------------------------------------+
#property copyright "Rebuild for personal use"
#property version   "1.20"
#property description "BBMA Oma Ally MTF for XAUUSD - selectable 1D/4H/1H/15M"
#property description "TF1: trend + re-entry | TF2: gap/rejection | TF3: extreme/MHV/direction/full setup"
#property description "2TF = final at 2 TFs, 3TF = final at 3 TFs. Dashboard + alerts + optional auto-trade."
#property link      ""

//+------------------------------------------------------------------+
//| MODULE MAP (folder: Include/)                                    |
//|------------------------------------------------------------------|
//| BBMA_Types.mqh       enums, constants, TFHandles / TFAnalysis     |
//| BBMA_State.mqh       all global state + the CTrade object         |
//| BBMA_Utils.mqh       text, price-series and volume helpers        |
//| BBMA_Timeframes.mqh  TF registry, roles, indicator handles        |
//| BBMA_Analysis.mqh    BBMA pattern detection for one timeframe     |
//| BBMA_Signals.mqh     PREP/FINAL signal engine + signal text       |
//| BBMA_Alerts.mqh      popup, mobile push and Telegram              |
//| BBMA_Trading.mqh     entries, lot size, close-all, position exits |
//| BBMA_Risk.mqh        daily loss/target guard, Friday close        |
//| BBMA_Dashboard.mqh   chart panel and BUY/SELL/CLOSE buttons      |
//|------------------------------------------------------------------|
//| This file only keeps: inputs, event handlers and the wiring.      |
//+------------------------------------------------------------------+

#include "Include/BBMA_Types.mqh"   //--- must come before the inputs (they use these enums)

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "=== TIMEFRAMES (XAUUSD) ==="
input bool              InpUseD1         = false;     // Enable 1D
input bool              InpUseH4         = true;      // Enable 4H
input bool              InpUseH1         = true;      // Enable 1H
input bool              InpUseM15        = true;      // Enable 15M
input ENUM_CONFIRM_MODE InpConfirmMode   = CONFIRM_3TF; // 2TF or 3TF
input ENUM_TF3_RULE     InpTF3Rule       = TF3_ANY;   // TF3 confirmation rule

input group "=== BBMA PARAMETERS ==="
input int    InpBBPeriod        = 20;     // Bollinger Bands period
input double InpBBDeviation     = 2.0;    // Bollinger Bands deviation
input int    InpFastMA          = 5;      // MA fast (applied to High)
input int    InpSlowMA          = 10;     // MA slow (applied to Low)
input int    InpTrendEMA        = 50;     // Trend EMA (applied to Close)
input int    InpATRPeriod       = 14;     // ATR period
input double InpCsmBodyATR      = 1.2;    // CSM body >= x * ATR
input int    InpExtremeLookback = 3;      // Extreme lookback (bars)
input int    InpSetupLookback   = 20;     // Setup/full-setup lookback (bars)
input double InpPullbackTolATR  = 0.10;   // Pullback tolerance (x ATR)
input bool   InpRequireMAStack  = true;   // Require MA5/MA10 stack with trend

input group "=== SIGNALS / ALERTS ==="
input bool   InpAlertPopup       = true;  // Popup alert
input bool   InpAlertPush        = false; // Push notification (MT5 mobile)
input bool   InpAlertTelegram    = false; // Telegram alert
input string InpTelegramToken    = "";    // Telegram bot token
input string InpTelegramChat     = "";    // Telegram chat id
input bool   InpAlertPreparation = true;  // Also alert 2TF preparation

input group "=== TRADING ==="
input bool            InpAutoTrade     = false;    // Auto-trade (false = semi-auto)
input long            InpMagic         = 20261027; // Magic number
input int             InpSlippage      = 20;       // Slippage (points)
input ENUM_LOT_MODE   InpLotMode       = LOT_FIXED;// Lot mode
input double          InpLot           = 0.01;     // Fixed lot
input double          InpRiskPercent   = 1.0;      // Risk % (compounding)
input double          InpSLATR         = 1.5;      // SL distance (x ATR)
input double          InpRR            = 1.5;      // Reward:Risk
input int             InpMinSLPoints   = 150;      // Minimum SL (points)
input int             InpStopBufferPts = 10;       // Extra stop buffer (points)
input int             InpMaxSpread     = 50;       // Max spread (points, 0 = off)
input int             InpMaxPositions  = 1;        // Max positions
input bool            InpAllowLayering = false;    // Allow more than one position

input group "=== EXIT MANAGEMENT ==="
input ENUM_CLOSE_RULE InpCloseMode     = CLOSE_AT_BB; // Profit-taking rule
input bool            InpCutLossOnCSM  = true;        // Cut loss on CSM + EMA50 break (TF2)
input bool            InpFridayClose   = true;        // Close all on Friday
input int             InpFridayHour    = 22;          // Friday close hour (server)
input double          InpDailyLossPct  = 3.0;         // Max daily loss % (0 = off)
input double          InpDailyTargetPct= 0.0;         // Daily target % (0 = off)

input group "=== DASHBOARD ==="
input bool             InpShowPanel    = true;
input ENUM_BASE_CORNER InpPanelCorner  = CORNER_LEFT_UPPER;
input int              InpPanelX       = 20;
input int              InpPanelY       = 30;
input int              InpFontSize     = 9;

//+------------------------------------------------------------------+
//| Modules (all of them read the inputs above)                      |
//+------------------------------------------------------------------+
#include "Include/BBMA_State.mqh"
#include "Include/BBMA_Utils.mqh"
#include "Include/BBMA_Timeframes.mqh"
#include "Include/BBMA_Analysis.mqh"
#include "Include/BBMA_Alerts.mqh"
#include "Include/BBMA_Signals.mqh"
#include "Include/BBMA_Trading.mqh"
#include "Include/BBMA_Risk.mqh"
#include "Include/BBMA_Dashboard.mqh"

//+------------------------------------------------------------------+
//| Events                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   InitTFArrays();
   BuildTFList();

   string sym = _Symbol;
   StringToUpper(sym);
   if(StringFind(sym, "XAU") < 0 && StringFind(sym, "GOLD") < 0)
      Print("WARNING: this EA is intended for XAUUSD, current symbol: ", _Symbol);

   if(!g_configOk)
     {
      int required = (InpConfirmMode == CONFIRM_3TF ? 3 : 2);
      string msg = StringFormat("CONFIG ERROR: %s mode requires exactly %d enabled TFs, but %d are ON. Enable/disable 1D/4H/1H/15M accordingly.",
                                (InpConfirmMode == CONFIRM_3TF ? "3TF" : "2TF"),
                                required, g_count);
      Print(msg);
      Alert(msg);
     }

   for(int i = 0; i < BBMA_TF_SLOTS; i++)
     {
      if(!g_use[i])
         continue;
      if(!InitHandles(g_h[i], g_tf[i]))
         return INIT_FAILED;
     }

   g_trade.SetExpertMagicNumber((ulong)InpMagic);
   g_trade.SetDeviationInPoints((ulong)InpSlippage);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   g_day = -1;
   g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   CreateDashboard();
   EventSetMillisecondTimer(700);

   Print("BBMA Oma Ally MTF initialized: ", _Symbol, " | TFs=", TFListStr(),
         " | mode=", (InpConfirmMode == CONFIRM_3TF ? "3TF" : "2TF"),
         " | auto=", (InpAutoTrade ? "true" : "false"));

   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0, g_prefix);

   for(int i = 0; i < BBMA_TF_SLOTS; i++)
      ReleaseHandles(g_h[i]);
  }

void OnTick()
  {
   UpdateDaily();

   //--- re-analyse only when a new bar of an enabled TF appears
   if(g_configOk)
     {
      bool need = false;
      for(int i = 0; i < BBMA_TF_SLOTS; i++)
        {
         if(g_use[i] && IsNewBar(g_tf[i], g_lastBar[i]))
            need = true;
        }
      if(need)
         UpdateAnalysis();
     }

   ManagePositions();

   //--- one-shot final signals (auto entry only when InpAutoTrade is on)
   if(g_eventFinalBuy)
     {
      if(InpAutoTrade)
         OpenTrade(1);
      g_eventFinalBuy = false;
     }

   if(g_eventFinalSell)
     {
      if(InpAutoTrade)
         OpenTrade(-1);
      g_eventFinalSell = false;
     }

   g_eventPrepBuy  = false;
   g_eventPrepSell = false;

   UpdateDashboard();
  }

void OnTimer()
  {
   UpdateDaily();
   ManagePositions();
   UpdateDashboard();
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(sparam == g_prefix + "BTN_BUY")
     {
      OpenTrade(1);
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      ChartRedraw(0);
     }
   else if(sparam == g_prefix + "BTN_SELL")
     {
      OpenTrade(-1);
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      ChartRedraw(0);
     }
   else if(sparam == g_prefix + "BTN_CLOSE")
     {
      CloseAll();
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      ChartRedraw(0);
     }
  }
//+------------------------------------------------------------------+
