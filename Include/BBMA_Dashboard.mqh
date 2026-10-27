//+------------------------------------------------------------------+
//| BBMA_Dashboard.mqh                                               |
//| Chart panel: per-TF status lines, overall status and the         |
//| BUY / SELL / CLOSE ALL buttons.                                  |
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
//| Build the panel (called once from OnInit)                        |
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
   ObjectSetInteger(0, panel, OBJPROP_XSIZE, 600);
   ObjectSetInteger(0, panel, OBJPROP_YSIZE, 225);
   ObjectSetInteger(0, panel, OBJPROP_BGCOLOR, C'30,32,36');
   ObjectSetInteger(0, panel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panel, OBJPROP_COLOR, C'80,84,92');
   ObjectSetInteger(0, panel, OBJPROP_BACK, false);
   ObjectSetInteger(0, panel, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, panel, OBJPROP_HIDDEN, true);

   CreateLabel(g_prefix + "TITLE", x + 14, y + 8,  InpFontSize + 1, clrWhite);
   CreateLabel(g_prefix + "L1",    x + 14, y + 32, InpFontSize, clrSilver);
   CreateLabel(g_prefix + "L2",    x + 14, y + 50, InpFontSize, clrSilver);
   CreateLabel(g_prefix + "L3",    x + 14, y + 68, InpFontSize, clrSilver);
   CreateLabel(g_prefix + "L4",    x + 14, y + 86, InpFontSize, clrSilver);
   CreateLabel(g_prefix + "L5",    x + 14, y + 112, InpFontSize + 1, clrSilver);
   CreateLabel(g_prefix + "L6",    x + 14, y + 132, InpFontSize, clrSilver);
   CreateLabel(g_prefix + "L7",    x + 14, y + 150, InpFontSize, clrSilver);

   CreateButton(g_prefix + "BTN_BUY",   "BUY",       x + 14,  y + 182, 100, 30, C'0,110,70');
   CreateButton(g_prefix + "BTN_SELL",  "SELL",      x + 124, y + 182, 100, 30, C'150,40,40');
   CreateButton(g_prefix + "BTN_CLOSE", "CLOSE ALL", x + 234, y + 182, 110, 30, C'70,72,78');

   UpdateDashboard();
  }

//+------------------------------------------------------------------+
//| One status line for a TF slot, depending on its role             |
//+------------------------------------------------------------------+
string TFLine(const int idx)
  {
   string tf = TFToStr(g_tf[idx]);

   if(!g_use[idx])
      return StringFormat("%-3s [OFF   ]", tf);

   if(idx == g_majorIdx)
      return StringFormat("%-3s [MAJOR ] T:%-4s EXT:%-3s MHV:%-3s CSM:%-3s RE:%-3s",
                          tf, TrendStr(g_a[idx].trend),
                          YN(g_a[idx].extremeBuy || g_a[idx].extremeSell),
                          YN(g_a[idx].mhv),
                          YN(g_a[idx].csmBuy || g_a[idx].csmSell),
                          YN(g_a[idx].reentryBuy || g_a[idx].reentrySell));

   if(idx == g_secondIdx)
      return StringFormat("%-3s [SECOND] T:%-4s GAP:%-3s REJ:%-3s CONF:%-3s",
                          tf, TrendStr(g_a[idx].trend),
                          YN(g_a[idx].gapBuy || g_a[idx].gapSell),
                          YN(g_a[idx].rejectionBuy || g_a[idx].rejectionSell),
                          YN(g_a[idx].tf2Buy || g_a[idx].tf2Sell));

   if(idx == g_thirdIdx)
      return StringFormat("%-3s [THIRD ] EXT:%-3s MHV:%-3s DIR:%-3s FULL:%-3s",
                          tf,
                          YN(g_a[idx].extremeBuy || g_a[idx].extremeSell),
                          YN(g_a[idx].mhv),
                          YN(g_a[idx].csakBuy || g_a[idx].csakSell ||
                             g_a[idx].csmBuy || g_a[idx].csmSell),
                          YN(g_a[idx].fullSetupBuy || g_a[idx].fullSetupSell));

   return StringFormat("%-3s [ON    ]", tf);
  }

//+------------------------------------------------------------------+
//| Refresh the panel texts                                          |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   if(!InpShowPanel)
      return;

   string title = StringFormat("BBMA OMA ALLY MTF  %s  |  %s  |  %s",
                               _Symbol, TFListStr(),
                               (InpConfirmMode == CONFIRM_3TF ? "3TF mode" : "2TF mode"));
   ObjectSetString(0, g_prefix + "TITLE", OBJPROP_TEXT, title);

   ObjectSetString(0, g_prefix + "L1", OBJPROP_TEXT, TFLine(0));
   ObjectSetString(0, g_prefix + "L2", OBJPROP_TEXT, TFLine(1));
   ObjectSetString(0, g_prefix + "L3", OBJPROP_TEXT, TFLine(2));
   ObjectSetString(0, g_prefix + "L4", OBJPROP_TEXT, TFLine(3));

   string status = "WAIT - no valid setup";
   color statusColor = clrSilver;

   if(!g_configOk)
     {
      int required = (InpConfirmMode == CONFIRM_3TF ? 3 : 2);
      status = StringFormat("CONFIG ERROR: %s mode needs exactly %d TF ON (now %d)",
                            (InpConfirmMode == CONFIRM_3TF ? "3TF" : "2TF"),
                            required, g_count);
      statusColor = clrRed;
     }
   else if(g_finalBuy)
     {
      status = "FINAL BUY - all confirmations met";
      statusColor = clrLime;
     }
   else if(g_finalSell)
     {
      status = "FINAL SELL - all confirmations met";
      statusColor = clrTomato;
     }
   else if(g_prepBuy)
     {
      status = (g_thirdIdx >= 0
                ? StringFormat("PREP BUY - 2/%d confirmed, waiting %s",
                               g_count, TFToStr(g_tf[g_thirdIdx]))
                : "PREP BUY - waiting for confirmation");
      statusColor = clrGold;
     }
   else if(g_prepSell)
     {
      status = (g_thirdIdx >= 0
                ? StringFormat("PREP SELL - 2/%d confirmed, waiting %s",
                               g_count, TFToStr(g_tf[g_thirdIdx]))
                : "PREP SELL - waiting for confirmation");
      statusColor = clrGold;
     }

   string l5 = "STATUS: " + status;

   string l6 = StringFormat("POS %d | SPREAD %d pts | DAILY P/L %+.2f%% | %s",
                            CountPositions(),
                            (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD),
                            DailyPct(),
                            (g_blocked ? "BLOCKED" : (InpAutoTrade ? "AUTO" : "SEMI-AUTO")));

   string l7 = StringFormat("TF ON: %s | TF3 rule: %s | Exit: %s | Cut-loss: %s",
                            TFListStr(), TF3RuleStr(),
                            (InpCloseMode == CLOSE_AT_MA ? "MA" :
                             (InpCloseMode == CLOSE_AT_BB ? "BB" : "REVERSE")),
                            (InpCutLossOnCSM ? "ON" : "OFF"));

   ObjectSetString(0, g_prefix + "L5", OBJPROP_TEXT, l5);
   ObjectSetString(0, g_prefix + "L6", OBJPROP_TEXT, l6);
   ObjectSetString(0, g_prefix + "L7", OBJPROP_TEXT, l7);
   ObjectSetInteger(0, g_prefix + "L5", OBJPROP_COLOR, statusColor);

   ChartRedraw(0);
  }

#endif // BBMA_DASHBOARD_MQH
//+------------------------------------------------------------------+
