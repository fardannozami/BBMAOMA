//+------------------------------------------------------------------+
//| BBMA_Dashboard.mqh                                               |
//| Dashboard tabel (scanner-style): simbol, status per TF,          |
//| tombol BUY/SELL/CLOSE, Allow, Signals dan baris status bawah.    |
//+------------------------------------------------------------------+
#ifndef BBMA_DASHBOARD_MQH
#define BBMA_DASHBOARD_MQH

double g_dashMaxDD = 0.0;
double g_dashMaxGain = 0.0;
int    g_dashDay = -1;

//+------------------------------------------------------------------+
//| Panel primitives                                                 |
//+------------------------------------------------------------------+
void CreateLabel(const string name, const int x, const int y, const int size, const color clr)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
  }

void CreateCell(const string name, const int x, const int y, const int w, const int h,
                const string text, const color bg, const color fg, const int size)
  {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'50,52,56');
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
  }

void CreateButton(const string name, const string text, const int x, const int y,
                  const int w, const int h, const color bg)
  {
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'90,92,98');
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
  }

//+------------------------------------------------------------------+
//| TF column -> slot index (W1=0,D1=1,H4=2,H1=3,M15=4,M5=5)        |
//+------------------------------------------------------------------+
int DashSlot(const int col)
  {
   switch(col)
     {
      case 1: return 0; // W1
      case 2: return 1; // D1
      case 3: return 2; // H4
      case 4: return 3; // H1
      case 5: return 4; // M15
      case 6: return 5; // M5
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Status teks/warna untuk satu sel TF                              |
//+------------------------------------------------------------------+
void TFCellStatus(const int slot, string &text, color &bg, color &fg)
  {
   text = "--";
   bg   = C'50,52,56';
   fg   = C'150,152,158';

   if(slot < 0 || slot >= BBMA_TF_SLOTS || !g_use[slot] || g_a[slot].barTime == 0)
      return;

   bool buy = false, sell = false;
   string buyType = "", sellType = "";
   if(g_a[slot].reentryBuy)  { buy = true; buyType = "Re"; }
   else if(g_a[slot].extremeBuy) { buy = true; buyType = "Ex"; }
   else if(g_a[slot].mhvBuy) { buy = true; buyType = "MHV"; }
   else if(g_a[slot].fullSetupBuy) { buy = true; buyType = "Full"; }
   else if(g_a[slot].rejectionBuy) { buy = true; buyType = "Rj"; }
   else if(g_a[slot].gapBuy) { buy = true; buyType = "Gap"; }

   if(g_a[slot].reentrySell) { sell = true; sellType = "Re"; }
   else if(g_a[slot].extremeSell) { sell = true; sellType = "Ex"; }
   else if(g_a[slot].mhvSell) { sell = true; sellType = "MHV"; }
   else if(g_a[slot].fullSetupSell) { sell = true; sellType = "Full"; }
   else if(g_a[slot].rejectionSell) { sell = true; sellType = "Rj"; }
   else if(g_a[slot].gapSell) { sell = true; sellType = "Gap"; }

   if(buy && sell)
     { text = "B/S"; bg = C'160,120,0'; fg = clrGold; return; }
   if(buy)
     { text = buyType; bg = C'40,90,40'; fg = clrLime; return; }
   if(sell)
     { text = sellType; bg = C'120,40,40'; fg = clrTomato; return; }

   int t = g_a[slot].trend;
   if(t > 0) { text = "UP"; bg = C'30,60,30';  fg = clrLime; }
   else if(t < 0) { text = "DN"; bg = C'80,30,30'; fg = clrTomato; }
  }

//+------------------------------------------------------------------+
//| Build the dashboard panel (called once from OnInit)              |
//+------------------------------------------------------------------+
void CreateDashboard()
  {
   if(!InpShowPanel)
      return;

   int x = InpPanelX;
   int y = InpPanelY;

   string panel = g_prefix + "PANEL";
   ObjectCreate(0, panel, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, panel, OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(0, panel, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, panel, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, panel, OBJPROP_XSIZE, 1040);
   ObjectSetInteger(0, panel, OBJPROP_YSIZE, 145);
   ObjectSetInteger(0, panel, OBJPROP_BGCOLOR, C'30,32,36');
   ObjectSetInteger(0, panel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panel, OBJPROP_COLOR, C'80,84,92');
   ObjectSetInteger(0, panel, OBJPROP_BACK, false);
   ObjectSetInteger(0, panel, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, panel, OBJPROP_HIDDEN, true);

   CreateLabel(g_prefix + "TITLE", x + 335, y + 6, InpFontSize + 2, clrWhite);

   //--- header row background (visual strip only)
   ObjectCreate(0, g_prefix + "H_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_XDISTANCE, x + 14);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_YDISTANCE, y + 40);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_XSIZE, 1012);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_YSIZE, 34);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BGCOLOR, C'60,64,70');
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BORDER_COLOR, C'50,52,56');
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BACK, false);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_HIDDEN, true);

   //--- header row (label text on top)
   int hx[7] = { x + 16, x + 176, x + 251, x + 326, x + 401, x + 476, x + 551 };
   int hw[7] = { 175, 75, 75, 75, 75, 75, 78 };
   string hd[7] = { "SYMBOLS", "W1", "D1", "H4", "H1", "M15", "M5" };
   for(int c = 0; c < 7; c++)
     {
      string bg = StringFormat("%sH%d_BG", g_prefix, c);
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, hx[c] - 2);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 40);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, hw[c]);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, 34);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, (c == 4 ? C'128,0,0' : C'128,128,128'));
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
      ObjectSetInteger(0, bg, OBJPROP_BACK, false);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);

      string nm = StringFormat("%sH%d", g_prefix, c);
      CreateLabel(nm, hx[c], y + 49, InpFontSize, clrWhite);
      ObjectSetString(0, nm, OBJPROP_TEXT, hd[c]);
      ObjectSetInteger(0, nm, OBJPROP_XSIZE, hw[c] - 4);
     }

   //--- Close All, Allow and Signals headers
   {
    string bg = g_prefix + "H6_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 629);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 40);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 225);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 34);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "H6", x + 631, y + 49, InpFontSize, clrWhite);
   ObjectSetString(0, g_prefix + "H6", OBJPROP_TEXT, "Close All");
   ObjectSetInteger(0, g_prefix + "H6", OBJPROP_XSIZE, 221);

   {
    string bg = g_prefix + "HCA_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 854);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 40);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 75);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 34);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "HCA", x + 856, y + 49, InpFontSize, clrWhite);
   ObjectSetString(0, g_prefix + "HCA", OBJPROP_TEXT, "Allow");
   ObjectSetInteger(0, g_prefix + "HCA", OBJPROP_XSIZE, 71);

   {
    string bg = g_prefix + "HA_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 929);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 40);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 111);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 34);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "HA", x + 931, y + 49, InpFontSize, clrWhite);
   ObjectSetString(0, g_prefix + "HA", OBJPROP_TEXT, "Signals");
   ObjectSetInteger(0, g_prefix + "HA", OBJPROP_XSIZE, 107);

   //--- symbol row: background + text label
   {
    string bg = g_prefix + "SYM_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 14);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 74);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 175);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 35);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'120,30,30');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "SYM", x + 16, y + 84, InpFontSize, clrWhite);
   ObjectSetString(0, g_prefix + "SYM", OBJPROP_TEXT, _Symbol);
   ObjectSetInteger(0, g_prefix + "SYM", OBJPROP_XSIZE, 171);

   //--- TF cells row: background + text label
   for(int c = 1; c < 7; c++)
     {
      string bg = StringFormat("%sC%d_BG", g_prefix, c);
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, hx[c] - 2);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 74);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, hw[c]);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, 35);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'50,52,56');
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
      ObjectSetInteger(0, bg, OBJPROP_BACK, false);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);

      string nm = StringFormat("%sC%d", g_prefix, c);
      CreateLabel(nm, hx[c], y + 84, InpFontSize, clrSilver);
      ObjectSetString(0, nm, OBJPROP_TEXT, "--");
      ObjectSetInteger(0, nm, OBJPROP_XSIZE, hw[c] - 4);
     }

   //--- Close All buttons
   CreateButton(g_prefix + "BTN_BUY",   "Buy",  x + 629, y + 74, 75, 35, C'0,150,0');
   CreateButton(g_prefix + "BTN_SELL",  "Sell", x + 704, y + 74, 75, 35, C'220,0,0');
   CreateButton(g_prefix + "BTN_CLOSE", "Close",x + 779, y + 74, 75, 35, C'128,128,128');

   //--- Allow + Signals row: background + text label
   {
    string bg = g_prefix + "CA_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 854);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 74);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 75);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 35);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "CA", x + 856, y + 84, InpFontSize, clrTomato);
   ObjectSetString(0, g_prefix + "CA", OBJPROP_TEXT, "\x2717");
   ObjectSetInteger(0, g_prefix + "CA", OBJPROP_XSIZE, 71);

   {
    string bg = g_prefix + "CS_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 929);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 74);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 111);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 35);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "CS", x + 931, y + 84, InpFontSize, clrSilver);
   ObjectSetString(0, g_prefix + "CS", OBJPROP_TEXT, "--");
   ObjectSetInteger(0, g_prefix + "CS", OBJPROP_XSIZE, 107);

   //--- footer status lines
   CreateLabel(g_prefix + "F1", x + 465, y + 121, InpFontSize, clrSilver);
   ObjectSetInteger(0, g_prefix + "F1", OBJPROP_SELECTABLE, true);
   string riskNames[16] = { "R0", "R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9", "R10", "R11", "R12", "R13", "R14", "R15" };
   for(int r = 0; r < 16; r++)
     {
      CreateLabel(g_prefix + riskNames[r], x, y + 150 + r * 34, (r == 0 ? InpFontSize + 2 : InpFontSize), (r == 0 || r == 15 ? clrLime : clrWhite));
      ObjectSetString(0, g_prefix + riskNames[r], OBJPROP_FONT, "Consolas");
     }

   UpdateDashboard();
  }

//+------------------------------------------------------------------+
//| Refresh the dashboard                                            |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   if(!InpShowPanel)
      return;

   ObjectSetString(0, g_prefix + "TITLE", OBJPROP_TEXT,
                   "BBMA Oma Ally Analyzer Dashboard EA V1.27");

   //--- TF cells
   for(int c = 1; c < 7; c++)
     {
      int slot = DashSlot(c);
      string text; color bg, fg;
      TFCellStatus(slot, text, bg, fg);
      string nm = StringFormat("%sC%d", g_prefix, c);
      string bgnm = StringFormat("%sC%d_BG", g_prefix, c);
      ObjectSetString(0, nm, OBJPROP_TEXT, text);
      ObjectSetInteger(0, nm, OBJPROP_COLOR, fg);
      ObjectSetInteger(0, bgnm, OBJPROP_BGCOLOR, bg);
     }
   //--- Symbol cell (always visible)
   ObjectSetString(0, g_prefix + "SYM", OBJPROP_TEXT, _Symbol);
   ObjectSetInteger(0, g_prefix + "SYM", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, g_prefix + "SYM_BG", OBJPROP_BGCOLOR, C'120,30,30');

   //--- Allow
   bool allowed = (g_autoTrade && !g_blocked);
   ObjectSetString(0, g_prefix + "CA", OBJPROP_TEXT, (allowed ? "\x2713" : "\x2717"));
   ObjectSetInteger(0, g_prefix + "CA", OBJPROP_COLOR, (allowed ? clrLime : clrTomato));
   ObjectSetInteger(0, g_prefix + "CA_BG", OBJPROP_BGCOLOR, C'50,52,56');

   //--- Signals
   string sigText = "--";
   color sigColor = C'150,152,158';
   if(g_finalBuy)      { sigText = "BUY";  sigColor = clrLime; }
   else if(g_finalSell){ sigText = "SELL"; sigColor = clrTomato; }
   else if(g_prepBuy)  { sigText = "PREP BUY";  sigColor = clrGold; }
   else if(g_prepSell) { sigText = "PREP SELL"; sigColor = clrGold; }
   ObjectSetString(0, g_prefix + "CS", OBJPROP_TEXT, sigText);
   ObjectSetInteger(0, g_prefix + "CS", OBJPROP_COLOR, sigColor);
   ObjectSetInteger(0, g_prefix + "CS_BG", OBJPROP_BGCOLOR, C'50,52,56');

   //--- footer
   string f1 = (g_autoTrade ? "Full Auto Mode" : "Semi Auto Mode");
   ObjectSetString(0, g_prefix + "F1", OBJPROP_TEXT, f1);
   ObjectSetInteger(0, g_prefix + "F1", OBJPROP_COLOR, (g_autoTrade ? clrLime : C'180,184,190'));

   //--- Account and daily risk information below the trading dashboard
   MqlDateTime nowParts;
   TimeToStruct(TimeCurrent(), nowParts);
   int dayKey = nowParts.year * 1000 + nowParts.day_of_year;
   if(g_dashDay != dayKey)
     {
      g_dashDay = dayKey;
      g_dashMaxDD = 0.0;
      g_dashMaxGain = 0.0;
     }
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyPct = DailyPct();
   if(dailyPct < 0.0 && -dailyPct > g_dashMaxDD) g_dashMaxDD = -dailyPct;
   if(dailyPct > g_dashMaxGain) g_dashMaxGain = dailyPct;
   double dailyAmount = equity - g_dayStartBalance;
   datetime dayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   datetime dayEnd = dayStart + 86400;
   double closedDaily = 0.0;
   if(HistorySelect(dayStart, TimeCurrent()))
     {
      for(int deal = 0; deal < HistoryDealsTotal(); deal++)
        {
         ulong ticket = HistoryDealGetTicket(deal);
         if(ticket == 0) continue;
         closedDaily += HistoryDealGetDouble(ticket, DEAL_PROFIT)
                      + HistoryDealGetDouble(ticket, DEAL_SWAP)
                      + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        }
     }
   double maxAmount = (g_dayStartBalance > 0.0 ? g_dayStartBalance * InpDailyLossPct / 100.0 : 0.0);
   double profitToLock = (InpDailyTargetPct > 0.0 && g_dayStartBalance > 0.0 ? g_dayStartBalance * InpDailyTargetPct / 100.0 : 0.0);
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   string riskText[16];
   riskText[0] = "Risk Management Controller is Active";
   if(g_blocked) riskText[0] = "Risk Management Controller is Inactive";
   riskText[1] = "Counters will be reset on Next Day Start.";
   riskText[2] = StringFormat("From : %s To : %s", TimeToString(dayStart, TIME_DATE), TimeToString(dayEnd, TIME_DATE));
   riskText[3] = "ACCOUNT DRAWDOWN =================";
   riskText[4] = StringFormat("Account Initial Balance                         : %.2f %s", g_dayStartBalance, currency);
   riskText[5] = StringFormat("Current Account Equity                          : %.2f %s", equity, currency);
   riskText[6] = StringFormat("Current Balance Variation                       : %.2f%%", (g_dayStartBalance > 0.0 ? (equity-g_dayStartBalance)/g_dayStartBalance*100.0 : 0.0));
   riskText[7] = "DAILY DRAWDOWN =====================";
   riskText[8] = StringFormat("Today Starting Balance                         : %.2f %s", g_dayStartBalance, currency);
   riskText[9] = StringFormat("DrawDown Max Threshold                         : %.2f %% [ Today Highest DD : %.2f%% ]", InpDailyLossPct, g_dashMaxDD);
   riskText[10] = StringFormat("DrawDown Max Amount                            : -%.2f %s", maxAmount, currency);
   riskText[11] = StringFormat("Closed Daily PnL                               : %.2f %s", closedDaily, currency);
   riskText[12] = StringFormat("Total Daily PnL                                : %.2f %s (%.2f %%)", dailyAmount, currency, dailyPct);
   riskText[13] = StringFormat("Today Highest Gain                             : %.2f%%", g_dashMaxGain);
   riskText[14] = StringFormat("Profit to lock                                 : %.2f %s", profitToLock, currency);
   riskText[15] = (g_blocked ? ">>> Max Threshold Hit. Trading is blocked." : ">>> Max Threshold Not Hit. Trade is allowed.");
   for(int r = 0; r < 16; r++)
     {
      string name = StringFormat("%sR%d", g_prefix, r);
      ObjectSetString(0, name, OBJPROP_TEXT, riskText[r]);
      ObjectSetInteger(0, name, OBJPROP_COLOR, (r == 0 || r == 15 ? clrLime : clrWhite));
     }

   ChartRedraw(0);
  }

#endif // BBMA_DASHBOARD_MQH
