//+------------------------------------------------------------------+
//|                                                  SimplePanel.mq5 |
//|                                          Copyright 2025, LocalFX |
//|                               https://www.facebook.com/LocalFX4U |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, LocalFX"
#property link "https://www.facebook.com/LocalFX4U"
#property version "1.00"

#property strict
#include <Controls/Dialog.mqh>
#include <Controls/Button.mqh>
#include <Controls/Label.mqh>

// Define custom class to access protected members
class CSimplePanel : public CAppDialog
{
public:
   // Method to check minimized state
   bool IsMinimized() { return(m_minimized); }
   // Method to set minimized state (wrapper for protected Minimize)
   void SetMinimized(bool min) { if(min) Minimize(); else Maximize(); }
   
   // Public method to process caption clicks (called from OnChartEvent)
   void ProcessCaptionClick()
   {
      ulong now = GetTickCount();
      
      if(now - m_last_click_time < 500) // 500ms threshold for double click
      {
         // Toggle State
         if(IsMinimized()) Maximize();
         else Minimize();
         
         // Reset time to prevent triple-click triggering
         m_last_click_time = 0;
      }
      else
      {
         m_last_click_time = now;
      }
   }
   
   // Create Data Labels (Balance, Equity, Profit)
   bool CreateDataLabels()
   {
      int x1_key = 10, x2_key = 70;
      int x1_val = 80, x2_val = 200;
      int y = 10;
      int step = 25;

      // Band & Page
      if(!CreateLabel(m_lbl_band, "FB: Local FX", "BandKey", x1_key, y, x2_key, y+20)) return false;
      y += step;
      if(!CreateLabel(m_lbl_page, "www.facebook.com/LocalFX4U", "PageKey", x1_key, y, x2_key, y+20)) return false;
      
      y = 60;

      // Balance
      if(!CreateLabel(m_lbl_balance_key, "Balance:", "BalKey", x1_key, y, x2_key, y+20)) return false;
      if(!CreateLabel(m_lbl_balance_val, "0.00",     "BalVal", x1_val, y, x2_val, y+20)) return false;
      
      y += step;
      // Equity
      if(!CreateLabel(m_lbl_equity_key, "Equity:",   "EqKey",  x1_key, y, x2_key, y+20)) return false;
      if(!CreateLabel(m_lbl_equity_val, "0.00",      "EqVal",  x1_val, y, x2_val, y+20)) return false;
      
      y -= step;
      int x_col1 = 220;
      int w_col1_key = 90; // "Spread:" width
      
      if(!CreateLabel(m_lbl_spread_key, "Current Spread:", "SprdKey", x_col1, y, x_col1+w_col1_key, y+20)) return false;
      if(!CreateLabel(m_lbl_spread_val, "0",    "SprdVal", x_col1+w_col1_key+15, y, x_col1+100, y+20)) return false;

      y += step;
      if(!CreateLabel(m_lbl_avg_spread_key, "Average Spread:", "AvgSprdKey", x_col1, y, x_col1+w_col1_key, y+20)) return false;
      if(!CreateLabel(m_lbl_avg_spread_val, "0",        "AvgSprdVal", x_col1+w_col1_key+15, y, 270, y+20)) return false;

      y += step+5;
      // -- Separator -----------------------------
      int y_sep = y;
      if(!m_separator.Create(m_chart_id, m_name+"Sep", m_subwin, 10, y_sep, 420, y_sep+1)) return false;
      if(!m_separator.ColorBackground(C'60,60,60')) return false;
      if(!Add(m_separator)) return false;

      y += 5;
      // Summary Table (3x3)
      int x_sum_col1 = 10;
      int x_sum_col2 = 110;
      int x_sum_col3 = 220;
      int summary_step = 25;

      // Row 1: Total
      if(!CreateLabel(m_lbl_ord_total_key, "Total:", "OrdTotKey", x_sum_col1, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_ord_total_val, "3,000",       "OrdTotVal", x_sum_col1+45, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_total_key,   "Lot:",    "LotTotKey", x_sum_col2, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_total_val,   "10,000.00",       "LotTotVal", x_sum_col2+30, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_profit_key,  "Profit:",   "OrdSellKey", x_sum_col3, y, x_sum_col3+70, y+20)) return false;
      if(!CreateLabel(m_lbl_profit_val,  "0.00",       "OrdSellVal", x_sum_col3+45, y, x_sum_col3+70, y+20)) return false;
      y += summary_step;

      // Row 2: Long
      if(!CreateLabel(m_lbl_ord_buy_key, "Long:",   "OrdBuyKey", x_sum_col1, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_ord_buy_val, "0",          "OrdBuyVal", x_sum_col1+45, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_buy_key,   "Lot:",       "LotBuyKey", x_sum_col2, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_buy_val,   "10,000.00",          "LotBuyVal", x_sum_col2+30, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_buy_key,  "Profit:",      "ProfBuyKey", x_sum_col3, y, x_sum_col3+70, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_buy_val,  "-1,000,000.00",          "ProfBuyVal", x_sum_col3+45, y, x_sum_col3+70, y+20)) return false;
      y += summary_step;

      // Row 3: Short
      if(!CreateLabel(m_lbl_ord_sell_key, "Short:", "ProfTotKey", x_sum_col1, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_ord_sell_val, "0",     "ProfTotVal", x_sum_col1+45, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_sell_key,   "Lot:",    "LotSellKey", x_sum_col2, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_sell_val,   "10,000.00",      "LotSellVal", x_sum_col2+30, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_sell_key,  "Profit:",   "ProfSellKey", x_sum_col3, y, x_sum_col3+70, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_sell_val,  "-1,000,000.00",       "ProfSellVal", x_sum_col3+45, y, x_sum_col3+70, y+20)) return false;
      y += summary_step;
      
      y += 5; // Extra spacing before separator
      // -- Separator -----------------------------
      y_sep = y;
      if(!m_separator2.Create(m_chart_id, m_name+"Sep2", m_subwin, 10, y_sep, 420, y_sep+1)) return false;
      if(!m_separator2.ColorBackground(C'60,60,60')) return false;
      if(!Add(m_separator2)) return false;

      int x_dd_col1 = 10;
      int x_dd_col2 = 90;
      int x_dd_col3 = 160;
      int x_dd_col4 = 260;
      y += 5;
      // Row 1: Current DD
      if(!CreateLabel(m_lbl_cur_dd_key, "Current DD:", "CurDDKey", x_dd_col1, y, x_dd_col1+50, y+20)) return false;
      if(!CreateLabel(m_lbl_cur_dd_per, "(-10.00%)",   "CurDDPer", x_dd_col2, y, x_dd_col2+50, y+20)) return false;
      if(!CreateLabel(m_lbl_cur_dd_val, "-1,000,000.00",        "CurDDVal", x_dd_col3, y, x_dd_col3+50, y+20)) return false;
      if(!CreateLabel(m_lbl_clear_dd, "[Clear Max DD]",        "ClearDD", x_dd_col4, y, x_dd_col3+50, y+20)) return false;
      y += summary_step-5;

      // Row 2: Max DD
      if(!CreateLabel(m_lbl_max_dd_key, "Max DD:",    "MaxDDKey", x_dd_col1, y, x_dd_col1+50, y+20)) return false;
      if(!CreateLabel(m_lbl_max_dd_per, "(-10.00%)",  "MaxDDPer", x_dd_col2, y, x_dd_col2+50, y+20)) return false;
      if(!CreateLabel(m_lbl_max_dd_val, "-1,000,000.00",       "MaxDDVal", x_dd_col3, y, x_dd_col3+50, y+20)) return false;
      if(!CreateLabel(m_lbl_date_dd, "2026.01.25",        "DateDD", x_dd_col4+10, y, x_dd_col3+50, y+20)) return false;
      y += summary_step;

      y += 5; // Extra spacing before separator
      // -- Separator -----------------------------
      y_sep = y;
      if(!m_separator3.Create(m_chart_id, m_name+"Sep3", m_subwin, 10, y_sep, 420, y_sep+1)) return false;
      if(!m_separator3.ColorBackground(C'60,60,60')) return false;
      if(!Add(m_separator3)) return false;

      // History List (7 Days)
      y += 5; // Start History
      for(int i=0; i<7; i++)
      {
          // Date Label
          if(!CreateLabel(m_lbl_hist_date[i], "Date", "HDate"+(string)i, 10, y, 90, y+20)) return false;
          // Percent Label
          if(!CreateLabel(m_lbl_hist_per[i], "0.00", "HPer"+(string)i, 90, y, 270, y+20)) return false;
          // Value Label
          if(!CreateLabel(m_lbl_hist_val[i], "0.00", "HVal"+(string)i, 145, y, 270, y+20)) return false;
          // Lot Label
          if(!CreateLabel(m_lbl_hist_lot[i], "0.00", "LVal"+(string)i, 220, y, 270, y+20)) return false;
          // Rebate Label
          if(!CreateLabel(m_lbl_hist_rebate[i], "0.00", "RVal"+(string)i, 310, y, 270, y+20)) return false;
          y += 20;
      }

      y += 10;
      // -- Separator -----------------------------
      y_sep = y;
      if(!m_separator4.Create(m_chart_id, m_name+"Sep4", m_subwin, 10, y_sep, 420, y_sep+1)) return false;
      if(!m_separator4.ColorBackground(C'60,60,60')) return false;
      if(!Add(m_separator4)) return false;




      return true;
   }
   
   // Helper to create a single label
   bool CreateLabel(CLabel &lbl, string text, string name, int x1, int y1, int x2, int y2)
   {
      if(!lbl.Create(m_chart_id, m_name+"Lbl"+name, m_subwin, x1, y1, x2, y2)) return false;
      if(!lbl.Text(text)) return false;
      if(!Add(lbl)) return false;
      return true;
   }
   
   void UpdateData()
   {
      if(IsMinimized()) return; 
      
      // Update Values
      m_lbl_balance_val.Text(FormatNumber(AccountInfoDouble(ACCOUNT_BALANCE)));
      m_lbl_balance_val.Color(clrWhite); // Force Color

      m_lbl_equity_val.Text(FormatNumber(AccountInfoDouble(ACCOUNT_EQUITY)));
      m_lbl_equity_val.Color(clrWhite); // Force Color
      
      double profit = AccountInfoDouble(ACCOUNT_PROFIT);
      m_lbl_profit_val.Text(FormatNumber(profit));
      
      // Color Profit
      if(profit >= 0) m_lbl_profit_val.Color(clrLime);
      else m_lbl_profit_val.Color(clrRed);
      
      // Update History
      UpdateHistory();
   }
   
   void UpdateHistory()
   {
      double running_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      // Loop from Today (0) backwards to 7 days ago
      for(int i=0; i<7; i++)
      {
         datetime t_start = iTime(_Symbol, PERIOD_D1, i);
         datetime t_end   = (i==0) ? TimeCurrent() : iTime(_Symbol, PERIOD_D1, i-1);
         
         // 1. Select History
         HistorySelect(t_start, t_end);
         int deals = HistoryDealsTotal();
         
         double day_profit = 0;
         double day_deposit = 0; // Net Deposits/Withdrawals
         double day_lot = 0;
         double day_rebate = 0;
         
         for(int j=0; j<deals; j++)
         {
            ulong ticket = HistoryDealGetTicket(j);
            double l = HistoryDealGetDouble(ticket, DEAL_VOLUME);
            double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            double s = HistoryDealGetDouble(ticket, DEAL_SWAP);
            double c = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            long type = HistoryDealGetInteger(ticket, DEAL_TYPE);
            
            // Check Deal Type
            if(type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL)
            {
               day_profit += (p + s + c);
               day_lot += l;
            }
            else if(type == DEAL_TYPE_BALANCE || type == DEAL_TYPE_CREDIT)
            {
               day_deposit += p; 
            }
            else
            {
               // Other types (Charges, Corrections, etc) treated as profit/loss component
               day_profit += (p + s + c);
            }
         }
         
         // 2. Calculate Start Balance of the Day
         // Current Balance = StartBalance + Profit + Deposits
         // StartBalance = CurrentBalance - Profit - Deposits
         double start_balance = running_balance - (day_profit + day_deposit);
         
         // 3. Percent
         // If start_balance is effectively 0 (e.g. first deposit day), use the deposit as the base
         double base_capital = start_balance;
         if(base_capital <= 0.1) base_capital += day_deposit; // Use intraday capital if start was empty
         
         double percent = 0;
         if(base_capital > 0) percent = (day_profit / base_capital) * 100.0;
         
         // 4. Update Labels
         m_lbl_hist_date[i].Text(TimeToString(t_start, TIME_DATE));
         m_lbl_hist_date[i].Color(C'180,180,180'); // Light Gray
         m_lbl_hist_lot[i].Color(C'180,180,180');
         m_lbl_hist_rebate[i].Color(C'180,180,180');

         string valText = FormatNumber(day_profit);
         string perText = "(" + DoubleToString(percent, 2) + "%)";
         string lotText = "Lot: " + FormatNumber(day_lot);
         string rebateText = "Rebate: " + FormatNumber(day_lot);
         m_lbl_hist_per[i].Text(perText);
         m_lbl_hist_val[i].Text(valText);
         m_lbl_hist_lot[i].Text(lotText);
         m_lbl_hist_rebate[i].Text(rebateText);
         
         if(day_profit > 0) 
         {
            m_lbl_hist_per[i].Color(clrLime);
            m_lbl_hist_val[i].Color(clrLime);
            
         }
         else if(day_profit < 0)
         {
            m_lbl_hist_per[i].Color(clrRed);
            m_lbl_hist_val[i].Color(clrRed);
         }
         else 
         {
            m_lbl_hist_per[i].Color(C'180,180,180');
            m_lbl_hist_val[i].Color(C'180,180,180');
         }

         // 5. Prepare balance for next iteration (yesterday)
         running_balance = start_balance;
      }
   }

   // Helper: Format number with commas
   string FormatNumber(double val)
   {
      string v = DoubleToString(MathAbs(val), 2);
      string integ = StringSubstr(v, 0, StringLen(v)-3);
      string fract = StringSubstr(v, StringLen(v)-3);
      
      string res = "";
      int len = StringLen(integ);
      
      for(int i=0; i<len; i++)
      {
         if(i > 0 && (len-i)%3 == 0) res += ",";
         res += StringSubstr(integ, i, 1);
      }
      
      if(val < 0) res = "-" + res;
      return(res + fract);
   }

   // Apply Dark Theme Colors
   void ApplyDarkTheme()
   {
      int total = ControlsTotal();
      for(int i=0; i<total; i++)
      {
         CWnd* control = Control(i);
         if(control == NULL) continue;
         
         string name = control.Name();
         
         // Client Area
         if(StringFind(name, "Client") >= 0)
         {
            CWndClient* client = (CWndClient*)control;
            client.ColorBackground(C'30,30,30');
            client.ColorBorder(C'30,30,30');
         }
         // Background
         else if(StringFind(name, "Back") >= 0)
         {
             CPanel* panel = (CPanel*)control;
             panel.ColorBackground(C'30,30,30');
             panel.ColorBorder(C'60,60,60');
         }
         // Caption
         else if(StringFind(name, "Caption") >= 0)
         {
             CEdit* caption = (CEdit*)control;
             caption.ColorBackground(C'45,45,48');
             caption.ColorBorder(C'60,60,60');
             caption.Color(clrWhite); // Text Color
             caption.Font("Arial Bold"); // Bold Text for Caption
         }
         // Border (if exists)
         else if(StringFind(name, "Border") >= 0)
         {
             CPanel* border = (CPanel*)control;
             border.ColorBackground(C'30,30,30');
             border.ColorBorder(C'60,60,60');
         }
          // Generic Labels (Apply Segoe UI globally)
          else if(StringFind(name, "Lbl") >= 0)
          {
              CLabel* lbl = (CLabel*)control;
              lbl.Font("Segoe UI");
          }
      }
      
      color gray = C'128,128,128';
      // Data Labels Style
      StyleLabel(m_lbl_band, C'102, 140, 255');
      m_lbl_band.Font("Segoe UI Bold");
      m_lbl_band.FontSize(15);
      
      StyleLabel(m_lbl_page, C'179, 198, 255');
      m_lbl_page.Font("Segoe UI Bold");
      m_lbl_page.FontSize(11);

      StyleLabel(m_lbl_balance_key, gray);
      StyleLabel(m_lbl_balance_val, clrWhite);
      
      StyleLabel(m_lbl_equity_key, gray);
      StyleLabel(m_lbl_equity_val, clrWhite);
      
      StyleLabel(m_lbl_profit_key, gray);
      // Profit Value Color is handled dynamically in UpdateData
      
      StyleLabel(m_lbl_spread_key, gray);
      StyleLabel(m_lbl_spread_val, clrWhite);

      StyleLabel(m_lbl_avg_spread_key, gray);
      StyleLabel(m_lbl_avg_spread_val, clrWhite);

      // Summary Style
      StyleLabel(m_lbl_ord_total_key, gray);
      StyleLabel(m_lbl_ord_total_val, clrWhite);
      StyleLabel(m_lbl_ord_buy_key, gray);
      StyleLabel(m_lbl_ord_buy_val, clrWhite);
      StyleLabel(m_lbl_ord_sell_key, gray);
      StyleLabel(m_lbl_ord_sell_val, clrWhite);

      StyleLabel(m_lbl_lot_total_key, gray);
      StyleLabel(m_lbl_lot_total_val, clrWhite);
      StyleLabel(m_lbl_lot_buy_key, gray);
      StyleLabel(m_lbl_lot_buy_val, clrWhite);
      StyleLabel(m_lbl_lot_sell_key, gray);
      StyleLabel(m_lbl_lot_sell_val, clrWhite);

      StyleLabel(m_lbl_prof_buy_key, gray);
      StyleLabel(m_lbl_prof_buy_val, clrWhite);
      StyleLabel(m_lbl_prof_sell_key, gray);
      StyleLabel(m_lbl_prof_sell_val, clrWhite);
      
      StyleLabel(m_lbl_cur_dd_key, gray);
      StyleLabel(m_lbl_cur_dd_val, C'255, 204, 204');
      StyleLabel(m_lbl_cur_dd_per, C'255, 204, 204');
      StyleLabel(m_lbl_clear_dd, clrWhite);
      StyleLabel(m_lbl_max_dd_key, gray);
      StyleLabel(m_lbl_max_dd_val, C'255, 128, 128');
      StyleLabel(m_lbl_max_dd_per, C'255, 128, 128');
      StyleLabel(m_lbl_date_dd, C'180,180,180');

      // History Style
      for(int i=0; i<7; i++)
      {
         m_lbl_hist_date[i].ColorBackground(C'30,30,30');
         m_lbl_hist_date[i].Color(C'180,180,180');
         
         m_lbl_hist_per[i].ColorBackground(C'30,30,30');
         m_lbl_hist_val[i].ColorBackground(C'30,30,30');
         m_lbl_hist_lot[i].ColorBackground(C'30,30,30');
         m_lbl_hist_rebate[i].ColorBackground(C'30,30,30');
         // Color handled dynamically
      }
   }
   
   void StyleLabel(CLabel &lbl, color clr)
   {
      lbl.ColorBackground(C'30,30,30');
      lbl.Color(clr);
   }
   
private:
   CLabel m_lbl_band, m_lbl_page;

   CLabel m_lbl_balance_key, m_lbl_balance_val;
   CLabel m_lbl_equity_key, m_lbl_equity_val;
   CLabel m_lbl_profit_key, m_lbl_profit_val;
   CLabel m_lbl_spread_key, m_lbl_spread_val;
   CLabel m_lbl_avg_spread_key, m_lbl_avg_spread_val;
   
   // Summary Labels
   CLabel m_lbl_ord_total_key, m_lbl_ord_total_val;
   CLabel m_lbl_ord_buy_key, m_lbl_ord_buy_val;
   CLabel m_lbl_ord_sell_key, m_lbl_ord_sell_val;
   
   CLabel m_lbl_lot_total_key, m_lbl_lot_total_val;
   CLabel m_lbl_lot_buy_key, m_lbl_lot_buy_val;
   CLabel m_lbl_lot_sell_key, m_lbl_lot_sell_val;
   
   CLabel m_lbl_prof_buy_key, m_lbl_prof_buy_val;
   CLabel m_lbl_prof_sell_key, m_lbl_prof_sell_val;

   CLabel m_lbl_cur_dd_key, m_lbl_cur_dd_val, m_lbl_cur_dd_per;
   CLabel m_lbl_max_dd_key, m_lbl_max_dd_val, m_lbl_max_dd_per;
   CLabel m_lbl_clear_dd, m_lbl_date_dd;

   CPanel m_separator,m_separator2,m_separator3,m_separator4;
   CLabel m_lbl_hist_date[7];
   CLabel m_lbl_hist_per[7];
   CLabel m_lbl_hist_val[7];
   CLabel m_lbl_hist_lot[7];
   CLabel m_lbl_hist_rebate[7];
   
protected:
   ulong m_last_click_time;
   
   // Override to prevent Close button creation
   virtual bool CreateButtonClose() { return(true); }
   
   // Override to prevent MinMax button creation 
   virtual bool CreateButtonMinMax() { return(true); }
};

CSimplePanel AppWindow;


int PanelX = 120;
int PanelY = 20;
int PanelMinX = 120;
int PanelMinY = 20;
bool CurrentStateMinimized = false;

int OnInit()
{
   // 1. Load Minimized State
   if(GlobalVariableCheck("SimplePanel_IsMinimized")) 
      CurrentStateMinimized = (bool)GlobalVariableGet("SimplePanel_IsMinimized");
   
   // 2. Load Maximized Positions
   if(GlobalVariableCheck("SimplePanel_Max_X")) PanelX = (int)GlobalVariableGet("SimplePanel_Max_X");
   if(GlobalVariableCheck("SimplePanel_Max_Y")) PanelY = (int)GlobalVariableGet("SimplePanel_Max_Y");

   // 3. Load Minimized Positions
   if(GlobalVariableCheck("SimplePanel_Min_X")) PanelMinX = (int)GlobalVariableGet("SimplePanel_Min_X");
   if(GlobalVariableCheck("SimplePanel_Min_Y")) PanelMinY = (int)GlobalVariableGet("SimplePanel_Min_Y");

   // 4. Determine Start Position
   int startX = CurrentStateMinimized ? PanelMinX : PanelX;
   int startY = CurrentStateMinimized ? PanelMinY : PanelY;

   // 5. Create Panel (Increased Height for Summary)
   if(!AppWindow.Create(0,"Golden Hour",0,startX,startY,startX+430,startY+580))
      return(INIT_FAILED);
      
   AppWindow.Run();
   
   // Create Data Labels
   if(!AppWindow.CreateDataLabels())
      Print("Error creating Data labels");
      
   // Update data immediately if not minimized
   if(!CurrentStateMinimized) AppWindow.UpdateData();
   
   // 6. Restore Minimized State
   if(CurrentStateMinimized)
   {
      AppWindow.SetMinimized(true);
      AppWindow.Move(PanelMinX, PanelMinY);
   }
   
   // Enable Mouse Move Event
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1);
   
   // Apply Dark Theme
   AppWindow.ApplyDarkTheme();
   ChartRedraw();

   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   // Final Save (State only, positions are saved on interaction)
   GlobalVariableSet("SimplePanel_IsMinimized", AppWindow.IsMinimized());
   
   AppWindow.Destroy(reason);
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 0); 
}

void OnTick()
{
   AppWindow.UpdateData();
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Check for Click on Caption
   if(id == CHARTEVENT_OBJECT_CLICK && StringFind(sparam, "Caption") >= 0)
   {
      AppWindow.ProcessCaptionClick();
   }

   AppWindow.ChartEvent(id,lparam,dparam,sparam);
   
   // Check current state after event processing
   bool isMin = AppWindow.IsMinimized();
   
   // --- CASE 1: State Change (Toggle Button Clicked) ---
   if(isMin != CurrentStateMinimized)
   {
      CurrentStateMinimized = isMin;
      GlobalVariableSet("SimplePanel_IsMinimized", CurrentStateMinimized);
      
      if(CurrentStateMinimized)
      {
         // Changed to Minimized: Jump to saved Minimized Position
         AppWindow.Move(PanelMinX, PanelMinY);
      }
      else
      {
         // Changed to Maximized: Jump to saved Maximized Position
         AppWindow.Move(PanelX, PanelY);
      }
   }
   
   // --- CASE 2: Mouse Release (Position Change) ---
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int mouseState = (int)StringToInteger(sparam);
      
      // If Left Button is NOT pressed (Released)
      if((mouseState & 1) == 0)
      {
         int currentX = AppWindow.Left();
         int currentY = AppWindow.Top();
         
         if(CurrentStateMinimized)
         {
            // IF MOVED while Minimized
            if(currentX != PanelMinX || currentY != PanelMinY)
            {
               PanelMinX = currentX;
               PanelMinY = currentY;
               GlobalVariableSet("SimplePanel_Min_X", PanelMinX);
               GlobalVariableSet("SimplePanel_Min_Y", PanelMinY);
            }
         }
         else
         {
            // IF MOVED while Maximized
            if(currentX != PanelX || currentY != PanelY)
            {
               PanelX = currentX;
               PanelY = currentY;
               GlobalVariableSet("SimplePanel_Max_X", PanelX);
               GlobalVariableSet("SimplePanel_Max_Y", PanelY);
            }
         }
      }
   }
}
