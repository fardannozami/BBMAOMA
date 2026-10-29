//+------------------------------------------------------------------+
//| BBMA_Dashboard.mqh                                               |
//| Dashboard tabel (scanner-style): simbol, status per TF,          |
//| tombol BUY/SELL/CLOSE, Allow, Signals dan baris status bawah.    |
//+------------------------------------------------------------------+
#ifndef BBMA_DASHBOARD_MQH
#define BBMA_DASHBOARD_MQH

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
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
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
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
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
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
  }

//+------------------------------------------------------------------+
//| TF column -> slot index (W1=-1,D1=0,H4=1,H1=2,M15=3,M5=-1)       |
//+------------------------------------------------------------------+
int DashSlot(const int col)
  {
   switch(col)
     {
      case 0: return -1; // W1
      case 1: return 0;  // D1
      case 2: return 1;  // H4
      case 3: return 2;  // H1
      case 4: return 3;  // M15
      case 5: return -1; // M5
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
   if(slot == g_majorIdx)      { buy = g_a[slot].reentryBuy;  sell = g_a[slot].reentrySell; }
   else if(slot == g_secondIdx){ buy = g_a[slot].tf2Buy;      sell = g_a[slot].tf2Sell; }
   else if(slot == g_thirdIdx) { buy = g_a[slot].tf3Buy;      sell = g_a[slot].tf3Sell; }
   else return;

   if(buy && sell)
     { text = "B/S"; bg = C'160,120,0'; fg = clrGold; return; }
   if(buy)
     { text = "Re";  bg = C'40,90,40';   fg = clrLime; return; }
   if(sell)
     { text = "Re";  bg = C'120,40,40';  fg = clrTomato; return; }

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
   ObjectSetInteger(0, panel, OBJPROP_XSIZE, 760);
   ObjectSetInteger(0, panel, OBJPROP_YSIZE, 120);
   ObjectSetInteger(0, panel, OBJPROP_BGCOLOR, C'30,32,36');
   ObjectSetInteger(0, panel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panel, OBJPROP_COLOR, C'80,84,92');
   ObjectSetInteger(0, panel, OBJPROP_BACK, false);
   ObjectSetInteger(0, panel, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, panel, OBJPROP_HIDDEN, true);

   CreateLabel(g_prefix + "TITLE", x + 14, y + 7, InpFontSize + 1, clrWhite);

   //--- header row background (visual strip only)
   ObjectCreate(0, g_prefix + "H_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_XDISTANCE, x + 14);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_YDISTANCE, y + 30);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_XSIZE, 746);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_YSIZE, 20);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BGCOLOR, C'60,64,70');
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BORDER_COLOR, C'50,52,56');
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_BACK, false);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, g_prefix + "H_BG", OBJPROP_HIDDEN, true);

   //--- header row (label text on top)
   int hx[6] = { x + 16, x + 116, x + 156, x + 196, x + 236, x + 276 };
   int hw[6] = { 90, 40, 40, 40, 40, 45 };
   string hd[6] = { "SYMBOLS", "W1", "D1", "H4", "H1", "M15" };
   for(int c = 0; c < 6; c++)
     {
      string bg = StringFormat("%sH%d_BG", g_prefix, c);
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, hx[c] - 2);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 30);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, hw[c]);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, 20);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
      ObjectSetInteger(0, bg, OBJPROP_BACK, false);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);

      string nm = StringFormat("%sH%d", g_prefix, c);
      CreateLabel(nm, hx[c], y + 33, InpFontSize, clrSilver);
      ObjectSetString(0, nm, OBJPROP_TEXT, hd[c]);
      ObjectSetInteger(0, nm, OBJPROP_XSIZE, hw[c] - 4);
     }

   //--- M5 + Close All header
   {
    string bg = g_prefix + "H6_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 319);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 30);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 35);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "H6", x + 321, y + 33, InpFontSize, clrSilver);
   ObjectSetString(0, g_prefix + "H6", OBJPROP_TEXT, "M5");
   ObjectSetInteger(0, g_prefix + "H6", OBJPROP_XSIZE, 31);

   {
    string bg = g_prefix + "HCA_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 354);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 30);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 140);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "HCA", x + 356, y + 33, InpFontSize, clrSilver);
   ObjectSetString(0, g_prefix + "HCA", OBJPROP_TEXT, "Close All");
   ObjectSetInteger(0, g_prefix + "HCA", OBJPROP_XSIZE, 136);

   {
    string bg = g_prefix + "HA_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 494);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 30);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 60);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "HA", x + 496, y + 33, InpFontSize, clrSilver);
   ObjectSetString(0, g_prefix + "HA", OBJPROP_TEXT, "Allow");
   ObjectSetInteger(0, g_prefix + "HA", OBJPROP_XSIZE, 56);

   {
    string bg = g_prefix + "HS_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 554);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 30);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 206);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'60,64,70');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "HS", x + 556, y + 33, InpFontSize, clrSilver);
   ObjectSetString(0, g_prefix + "HS", OBJPROP_TEXT, "Signals");
   ObjectSetInteger(0, g_prefix + "HS", OBJPROP_XSIZE, 202);

   //--- symbol row: background + text label
   {
    string bg = g_prefix + "SYM_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 14);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 54);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 90);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 22);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'120,30,30');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "SYM", x + 16, y + 57, InpFontSize, clrWhite);
   ObjectSetString(0, g_prefix + "SYM", OBJPROP_TEXT, _Symbol);
   ObjectSetInteger(0, g_prefix + "SYM", OBJPROP_XSIZE, 86);

   //--- TF cells row: background + text label
   for(int c = 1; c < 6; c++)
     {
      string bg = StringFormat("%sC%d_BG", g_prefix, c);
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, hx[c] - 2);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 54);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, hw[c]);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, 22);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'50,52,56');
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
      ObjectSetInteger(0, bg, OBJPROP_BACK, false);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);

      string nm = StringFormat("%sC%d", g_prefix, c);
      CreateLabel(nm, hx[c], y + 57, InpFontSize, clrSilver);
      ObjectSetString(0, nm, OBJPROP_TEXT, "--");
      ObjectSetInteger(0, nm, OBJPROP_XSIZE, hw[c] - 4);
     }

   {
    string bg = g_prefix + "C6_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 319);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 54);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 35);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 22);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "C6", x + 321, y + 57, InpFontSize, clrSilver);
   ObjectSetString(0, g_prefix + "C6", OBJPROP_TEXT, "--");
   ObjectSetInteger(0, g_prefix + "C6", OBJPROP_XSIZE, 31);

   //--- Close All buttons
   CreateButton(g_prefix + "BTN_BUY",   "BUY",  x + 354, y + 54, 44, 22, C'0,110,70');
   CreateButton(g_prefix + "BTN_SELL",  "SELL", x + 398, y + 54, 44, 22, C'150,40,40');
   CreateButton(g_prefix + "BTN_CLOSE", "CLOSE",x + 442, y + 54, 48, 22, C'80,84,92');

   //--- Allow + Signals row: background + text label
   {
    string bg = g_prefix + "CA_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 494);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 54);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 60);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 22);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "CA", x + 496, y + 57, InpFontSize, clrTomato);
   ObjectSetString(0, g_prefix + "CA", OBJPROP_TEXT, "\x2717");
   ObjectSetInteger(0, g_prefix + "CA", OBJPROP_XSIZE, 56);

   {
    string bg = g_prefix + "CS_BG";
    ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, bg, OBJPROP_CORNER, InpPanelCorner);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x + 554);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y + 54);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE, 206);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE, 22);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_BORDER_COLOR, C'50,52,56');
    ObjectSetInteger(0, bg, OBJPROP_BACK, false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   }
   CreateLabel(g_prefix + "CS", x + 556, y + 57, InpFontSize, clrSilver);
   ObjectSetString(0, g_prefix + "CS", OBJPROP_TEXT, "--");
   ObjectSetInteger(0, g_prefix + "CS", OBJPROP_XSIZE, 202);

   //--- footer status lines
   CreateLabel(g_prefix + "F1", x + 14, y + 82, InpFontSize, clrSilver);
   CreateLabel(g_prefix + "F2", x + 14, y + 98, InpFontSize, clrSilver);

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
                   StringFormat("BBMA Oma Ally Analyzer Dashboard EA  %s", _Symbol));

   //--- TF cells
   for(int c = 1; c < 6; c++)
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
   {
    int slot = DashSlot(5); // M5
    string text; color bg, fg;
    TFCellStatus(slot, text, bg, fg);
    ObjectSetString(0, g_prefix + "C6", OBJPROP_TEXT, text);
    ObjectSetInteger(0, g_prefix + "C6", OBJPROP_COLOR, fg);
    ObjectSetInteger(0, g_prefix + "C6_BG", OBJPROP_BGCOLOR, bg);
   }

   //--- Symbol cell (always visible)
   ObjectSetString(0, g_prefix + "SYM", OBJPROP_TEXT, _Symbol);
   ObjectSetInteger(0, g_prefix + "SYM", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, g_prefix + "SYM_BG", OBJPROP_BGCOLOR, C'120,30,30');

   //--- Allow
   bool allowed = (InpAutoTrade && !g_blocked);
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
   string f1 = StringFormat("%s  |  TFs: %s  |  %s",
                            (InpAutoTrade ? "Full Auto Mode" : "Semi Auto Mode"),
                            TFListStr(),
                            (InpConfirmMode == CONFIRM_3TF ? "3TF" : "2TF"));
   ObjectSetString(0, g_prefix + "F1", OBJPROP_TEXT, f1);
   ObjectSetInteger(0, g_prefix + "F1", OBJPROP_COLOR, (InpAutoTrade ? clrLime : C'180,184,190'));

   string f2;
   color f2c;
   if(!g_configOk)
     {
      int required = (InpConfirmMode == CONFIRM_3TF ? 3 : 2);
      f2 = StringFormat("CONFIG ERROR: %s mode needs %d TF ON (now %d)",
                        (InpConfirmMode == CONFIRM_3TF ? "3TF" : "2TF"), required, g_count);
      f2c = clrTomato;
     }
   else if(g_blocked)
     {
      f2 = "Risk Management Controller is Inactive";
      f2c = clrTomato;
     }
   else
     {
      f2 = "Risk Management Controller is Active";
      f2c = clrLime;
     }
   ObjectSetString(0, g_prefix + "F2", OBJPROP_TEXT, f2);
   ObjectSetInteger(0, g_prefix + "F2", OBJPROP_COLOR, f2c);

   ChartRedraw(0);
  }

#endif // BBMA_DASHBOARD_MQH