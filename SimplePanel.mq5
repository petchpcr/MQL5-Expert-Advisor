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

input int InpPanelX = 1200; // Default Panel X
input int InpPanelY = 20;  // Default Panel Y


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
      y = y-20;
      if(!CreateLabel(m_lbl_status, "[BOOST]", "StatusKey", x1_key+295, y, x2_key, y+20)) return false;
      
      y = 60; // Reset for Data Section

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
      if(!m_separator.Create(m_chart_id, m_name+"Sep", m_subwin, 10, y_sep, 370, y_sep+1)) return false;
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
      if(!m_separator2.Create(m_chart_id, m_name+"Sep2", m_subwin, 10, y_sep, 370, y_sep+1)) return false;
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
      if(!m_separator3.Create(m_chart_id, m_name+"Sep3", m_subwin, 10, y_sep, 370, y_sep+1)) return false;
      if(!m_separator3.ColorBackground(C'60,60,60')) return false;
      if(!Add(m_separator3)) return false;

      int x_h_col1 = 10;
      int x_h_col2 = 95;
      int x_h_col3 = 160;
      int x_h_col4 = 250;
      int x_h_col5 = 310;
      y += 5; // Header
      if(!CreateLabel(m_lbl_h_period, "",    "HPeriod", x_h_col1, y, x_h_col1+50, y+20)) return false;
      if(!CreateLabel(m_lbl_h_gain, "Gain %",      "HGain", x_h_col2, y, x_h_col2+50, y+20)) return false;
      if(!CreateLabel(m_lbl_h_profit, "Profit $",  "HProfit", x_h_col3, y, x_h_col3+50, y+20)) return false;
      if(!CreateLabel(m_lbl_h_lot, "Lot",          "HLot", x_h_col4, y, x_h_col4+50, y+20)) return false;
      if(!CreateLabel(m_lbl_h_rebate, "Rebate",    "HRebate", x_h_col5, y, x_h_col5+50, y+20)) return false;

      y += summary_step; 

      int x_ly_col1 = 10;
      int x2_ly_col1 = x_ly_col1+50;
      if(!CreateLabel(m_lbl_h_daily, "Daily (7D)", "HDaily", x_ly_col1, y-10, x2_ly_col1, y+10)) return false;

      // -- Separator -----------------------------
      y_sep = y;
      if(!m_separator4.Create(m_chart_id, m_name+"Sep4", m_subwin, x2_ly_col1+10, y_sep, 370, y_sep+1)) return false;
      if(!m_separator4.ColorBackground(C'60,60,60')) return false;
      if(!Add(m_separator4)) return false;

      // History List (7 Days)
      y += 10; // Start History
      for(int i=0; i<7; i++)
      {
          // Date Label
          if(!CreateLabel(m_lbl_hist_date[i], "Date", "HDate"+(string)i, x_h_col1, y, x_h_col1+50, y+20)) return false;
          // Percent Label
          if(!CreateLabel(m_lbl_hist_per[i], "0.00", "HPer"+(string)i, x_h_col2, y, x_h_col2+50, y+20)) return false;
          // Value Label
          if(!CreateLabel(m_lbl_hist_val[i], "0.00", "HVal"+(string)i, x_h_col3, y, x_h_col3+50, y+20)) return false;
          // Lot Label
          if(!CreateLabel(m_lbl_hist_lot[i], "0.00", "LVal"+(string)i, x_h_col4, y, x_h_col4+50, y+20)) return false;
          // Rebate Label
          if(!CreateLabel(m_lbl_hist_rebate[i], "0.00", "RVal"+(string)i, x_h_col5, y, x_h_col5+50, y+20)) return false;
          y += 20;
      }

      y += 10;
      if(!CreateLabel(m_lbl_h_weekly, "Weekly (4W)", "HWeekly", x_ly_col1, y-10, x2_ly_col1, y+10)) return false;
      // -- Separator -----------------------------
      y_sep = y;
      if(!m_separator5.Create(m_chart_id, m_name+"Sep5", m_subwin, x2_ly_col1+30, y_sep, 370, y_sep+1)) return false;
      if(!m_separator5.ColorBackground(C'60,60,60')) return false;
      if(!Add(m_separator5)) return false;

       y += 10;
       // Weekly History (4 Weeks)
       // Weekly History (4 Weeks)
       for(int i=0; i<4; i++)
       {
           if(!CreateLabel(m_lbl_week_date[i], "Week", "WDate"+(string)i, x_h_col1, y, x_h_col1+50, y+20)) return false;
           if(!CreateLabel(m_lbl_week_per[i],  "0.00", "WPer"+(string)i, x_h_col2, y, x_h_col2+50, y+20)) return false;
           if(!CreateLabel(m_lbl_week_val[i],  "0.00", "WVal"+(string)i, x_h_col3, y, x_h_col3+50, y+20)) return false;
           if(!CreateLabel(m_lbl_week_lot[i],  "0.00", "WLot"+(string)i, x_h_col4, y, x_h_col4+50, y+20)) return false;
           if(!CreateLabel(m_lbl_week_rebate[i],"0.00", "WReb"+(string)i, x_h_col5, y, x_h_col5+50, y+20)) return false;
           y += 20;
       }
 
       y += 10;
       if(!CreateLabel(m_lbl_h_monthly, "Monthly (2M)", "HMonthly", x_ly_col1, y-10, x2_ly_col1, y+10)) return false;
       // -- Separator -----------------------------
       y_sep = y;
       if(!m_separator6.Create(m_chart_id, m_name+"Sep6", m_subwin, x2_ly_col1+30, y_sep, 370, y_sep+1)) return false;
       if(!m_separator6.ColorBackground(C'60,60,60')) return false;
       if(!Add(m_separator6)) return false;

       y += 10;
       // Monthly History (2 Months)
       for(int i=0; i<2; i++)
       {
           if(!CreateLabel(m_lbl_mon_date[i], "Month", "MDate"+(string)i, x_h_col1, y, x_h_col1+50, y+20)) return false;
           if(!CreateLabel(m_lbl_mon_per[i],  "0.00",  "MPer"+(string)i, x_h_col2, y, x_h_col2+50, y+20)) return false;
           if(!CreateLabel(m_lbl_mon_val[i],  "0.00",  "MVal"+(string)i, x_h_col3, y, x_h_col3+50, y+20)) return false;
           if(!CreateLabel(m_lbl_mon_lot[i],  "0.00",  "MLot"+(string)i, x_h_col4, y, x_h_col4+50, y+20)) return false;
           if(!CreateLabel(m_lbl_mon_rebate[i],"0.00", "MReb"+(string)i, x_h_col5, y, x_h_col5+50, y+20)) return false;
           y += 20;
       }

       y += 10;
       if(!CreateLabel(m_lbl_h_yearly, "This Year", "HYearly", x_ly_col1, y-10, x2_ly_col1, y+10)) return false;
       // -- Separator -----------------------------
       y_sep = y;
       if(!m_separator7.Create(m_chart_id, m_name+"Sep7", m_subwin, x2_ly_col1+10, y_sep, 370, y_sep+1)) return false;
       if(!m_separator7.ColorBackground(C'60,60,60')) return false;
       if(!Add(m_separator7)) return false;

       y += 10;
       // Yearly History (Current Year)
       if(!CreateLabel(m_lbl_year_date, "Year", "YDate", x_h_col1, y, x_h_col1+50, y+20)) return false;
       if(!CreateLabel(m_lbl_year_per,  "0.00", "YPer", x_h_col2, y, x_h_col2+50, y+20)) return false;
       if(!CreateLabel(m_lbl_year_val,  "0.00", "YVal", x_h_col3, y, x_h_col3+50, y+20)) return false;
       if(!CreateLabel(m_lbl_year_lot,  "0.00", "YLot", x_h_col4, y, x_h_col4+50, y+20)) return false;
       if(!CreateLabel(m_lbl_year_rebate, "0.00", "YReb", x_h_col5, y, x_h_col5+50, y+20)) return false;

       return true;
   }
   
   // Helper: Get Time for D1/W1/MN1 (Calendar Based)
   datetime GetTime(ENUM_TIMEFRAMES tf, int index)
   {
      datetime current = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(current, dt);
      
      if(tf == PERIOD_D1)
      {
         datetime today_midnight = current - (current % 86400); 
         return today_midnight - (index * 86400); 
      }
      else if(tf == PERIOD_W1)
      {
         datetime today_midnight = current - (current % 86400);
         int days_since_sun = dt.day_of_week; // 0=Sun
         datetime week_start = today_midnight - (days_since_sun * 86400);
         return week_start - (index * 7 * 86400);
      }
      else if(tf == PERIOD_MN1)
      {
         dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
         
         // Current Month Start
         int months_total = dt.year * 12 + (dt.mon - 1);
         months_total -= index;
         
         dt.year = months_total / 12;
         dt.mon = (months_total % 12) + 1;
         
         return StructToTime(dt);
      }
      return 0;
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
      if(profit > 0) m_lbl_profit_val.Color(clrGain);
      else if(profit < 0) m_lbl_profit_val.Color(clrLoss);
      else m_lbl_profit_val.Color(clrWhite);
      
      // Update History
      UpdateHistory();
   }
   
   void UpdateHistory()
   {
      datetime current = TimeCurrent();
      datetime today_midnight = current - (current % 86400); // 00:00:00 Today

      // --- LOOP 1: Check Triggers for Big Loop ---
      // Trigger if never run (m_last_calc_date == 0) OR if new day arrived
      if(m_last_calc_date < today_midnight)
      {
         UpdateHistoricalCache();
         m_last_calc_date = today_midnight;
      }
      
      // --- LOOP 2: Realtime Data (Today ONLY) ---
      double t_prof = 0, t_dep = 0, t_lot = 0;
      
      if(HistorySelect(today_midnight, current))
      {
         int deals = HistoryDealsTotal();
         for(int i=0; i<deals; i++)
         {
            ulong ticket = HistoryDealGetTicket(i);
            double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            double s = HistoryDealGetDouble(ticket, DEAL_SWAP);
            double c = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            double v = HistoryDealGetDouble(ticket, DEAL_VOLUME);
            long type = HistoryDealGetInteger(ticket, DEAL_TYPE);
            long deal_entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
            
            if(deal_entry == DEAL_ENTRY_IN)
            {
               t_lot += v;
            }

            if(type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL)
            {
               t_prof += (p + s + c);
            }
            else if(type == DEAL_TYPE_BALANCE || type == DEAL_TYPE_CREDIT)
            {
               t_dep += p; 
            }
            else
            {
               t_prof += (p + s + c);
            }
         }
      }
      
      // --- Aggregation & Display ---
      
      double running_balance = AccountInfoDouble(ACCOUNT_BALANCE);

      // 1. Daily History (7 Days)
      for(int i=0; i<7; i++)
      {
         datetime t_d = GetTime(PERIOD_D1, i);
         double d_p = 0, d_d = 0, d_l = 0;
         
         if(i==0) // Today
         {
             d_p = t_prof; d_d = t_dep; d_l = t_lot;
         }
         else // History
         {
             string date_str = TimeToString(t_d, TIME_DATE);
             if(GlobalVariableCheck("GH_D_" + date_str + "_P")) {
                 d_p = GlobalVariableGet("GH_D_" + date_str + "_P");
                 d_d = GlobalVariableGet("GH_D_" + date_str + "_D");
                 d_l = GlobalVariableGet("GH_D_" + date_str + "_L");
             }
         }
         
         // Calculate Percent (Backwards Balance Logic)
         // Balance at End of Day = running_balance
         // Balance at Start of Day = running_balance - (Profit + Deposit)
         double start_bal = running_balance - (d_p + d_d);
         double base = start_bal;
         if(base <= 0.1) base += d_d; // If started empty, use deposit base
         
         double per = 0;
         if(base > 0) per = (d_p / base) * 100.0;
         
         // Update Labels
         m_lbl_hist_date[i].Text(TimeToString(t_d, TIME_DATE));
         m_lbl_hist_date[i].Color(clrBase);

         m_lbl_hist_val[i].Text(FormatNumber(d_p));
         m_lbl_hist_per[i].Text("(" + DoubleToString(per, 2) + "%)");
         m_lbl_hist_lot[i].Text(FormatNumber(d_l));
         m_lbl_hist_rebate[i].Text(FormatNumber(d_l * 0.05)); // Rebate logic same as lot for now
         
         if(d_p > 0) { m_lbl_hist_val[i].Color(clrGain); m_lbl_hist_per[i].Color(clrGain); }
         else if(d_p < 0) { m_lbl_hist_val[i].Color(clrLoss); m_lbl_hist_per[i].Color(clrLoss); }
         else { m_lbl_hist_val[i].Color(clrBase); m_lbl_hist_per[i].Color(clrBase); }
         
         running_balance = start_bal; // Step back for next iteration
      }
      
      // 2. Weekly History
      running_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      for(int i=0; i<4; i++)
      {
         datetime t_w = GetTime(PERIOD_W1, i);
         double w_p = 0, w_d = 0, w_l = 0;
         
         if(i==0) // This Week
         {
             // Partial + Realtime
             if(GlobalVariableCheck("GH_PARTIAL_W_P")) {
                 w_p = GlobalVariableGet("GH_PARTIAL_W_P") + t_prof; // Add Today's
                 w_d = GlobalVariableGet("GH_PARTIAL_W_D") + t_dep;
                 w_l = GlobalVariableGet("GH_PARTIAL_W_L") + t_lot;
             } else {
                 w_p = t_prof; w_d = t_dep; w_l = t_lot;
             }
         }
         else // Past Weeks
         {
             string date_str = TimeToString(t_w, TIME_DATE);
             if(GlobalVariableCheck("GH_W_" + date_str + "_P")) {
                 w_p = GlobalVariableGet("GH_W_" + date_str + "_P");
                 w_d = GlobalVariableGet("GH_W_" + date_str + "_D");
                 w_l = GlobalVariableGet("GH_W_" + date_str + "_L");
             }
         }
         
         double start_bal = running_balance - (w_p + w_d);
         double base = start_bal;
         if(base <= 0.1) base += w_d;
         
         double per = 0;
         if(base > 0) per = (w_p / base) * 100.0;
         
         m_lbl_week_date[i].Text(TimeToString(t_w, TIME_DATE));
         m_lbl_week_date[i].Color(clrBase);
         m_lbl_week_val[i].Text(FormatNumber(w_p));
         m_lbl_week_per[i].Text("(" + DoubleToString(per, 2) + "%)");
         m_lbl_week_lot[i].Text(FormatNumber(w_l));
         m_lbl_week_rebate[i].Text(FormatNumber(w_l * 0.05));
         
         if(w_p > 0) { m_lbl_week_val[i].Color(clrGain); m_lbl_week_per[i].Color(clrGain); }
         else if(w_p < 0) { m_lbl_week_val[i].Color(clrLoss); m_lbl_week_per[i].Color(clrLoss); }
         else { m_lbl_week_val[i].Color(clrBase); m_lbl_week_per[i].Color(clrBase); }
         
         running_balance = start_bal;
      }
      
      // 3. Monthly History
      running_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      for(int i=0; i<2; i++)
      {
         datetime t_m = GetTime(PERIOD_MN1, i);
         double m_p = 0, m_d = 0, m_l = 0;
         
         if(i==0) // This Month
         {
             if(GlobalVariableCheck("GH_PARTIAL_M_P")) {
                 m_p = GlobalVariableGet("GH_PARTIAL_M_P") + t_prof;
                 m_d = GlobalVariableGet("GH_PARTIAL_M_D") + t_dep;
                 m_l = GlobalVariableGet("GH_PARTIAL_M_L") + t_lot;
             } else {
                 m_p = t_prof; m_d = t_dep; m_l = t_lot;
             }
         }
         else // Past Month
         {
             string date_str = TimeToString(t_m, TIME_DATE);
             if(GlobalVariableCheck("GH_M_" + date_str + "_P")) {
                 m_p = GlobalVariableGet("GH_M_" + date_str + "_P");
                 m_d = GlobalVariableGet("GH_M_" + date_str + "_D");
                 m_l = GlobalVariableGet("GH_M_" + date_str + "_L");
             }
         }
         
         double start_bal = running_balance - (m_p + m_d);
         double base = start_bal;
         if(base <= 0.1) base += m_d;
         
         double per = 0;
         if(base > 0) per = (m_p / base) * 100.0;
         
         m_lbl_mon_date[i].Text(TimeToString(t_m, TIME_DATE));
         m_lbl_mon_date[i].Color(clrBase);
         m_lbl_mon_val[i].Text(FormatNumber(m_p));
         m_lbl_mon_per[i].Text("(" + DoubleToString(per, 2) + "%)");
         m_lbl_mon_lot[i].Text(FormatNumber(m_l));
         m_lbl_mon_rebate[i].Text(FormatNumber(m_l * 0.05));

         if(m_p > 0) { m_lbl_mon_val[i].Color(clrGain); m_lbl_mon_per[i].Color(clrGain); }
         else if(m_p < 0) { m_lbl_mon_val[i].Color(clrLoss); m_lbl_mon_per[i].Color(clrLoss); }
         else { m_lbl_mon_val[i].Color(clrBase); m_lbl_mon_per[i].Color(clrBase); }
         
         running_balance = start_bal;
      }
      
      // 4. Yearly History (Current Only)
      running_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double y_p = 0, y_d = 0, y_l = 0;
      
      if(GlobalVariableCheck("GH_PARTIAL_Y_P")) {
          y_p = GlobalVariableGet("GH_PARTIAL_Y_P") + t_prof;
          y_d = GlobalVariableGet("GH_PARTIAL_Y_D") + t_dep;
          y_l = GlobalVariableGet("GH_PARTIAL_Y_L") + t_lot;
      } else {
          y_p = t_prof; y_d = t_dep; y_l = t_lot;
      }
      
      double y_start_bal = running_balance - (y_p + y_d);
      double y_base = y_start_bal;
      if(y_base <= 0.1) y_base += y_d;
         
      double y_per = 0;
      if(y_base > 0) y_per = (y_p / y_base) * 100.0;
      
      MqlDateTime dt_y; TimeCurrent(dt_y);
      dt_y.mon=1; dt_y.day=1; dt_y.hour=0; dt_y.min=0; dt_y.sec=0; // Start of Year
      
      m_lbl_year_date.Text(TimeToString(StructToTime(dt_y), TIME_DATE));
      m_lbl_year_date.Color(clrBase);
      m_lbl_year_val.Text(FormatNumber(y_p));
      m_lbl_year_per.Text("(" + DoubleToString(y_per, 2) + "%)");
      m_lbl_year_lot.Text(FormatNumber(y_l));
      m_lbl_year_rebate.Text(FormatNumber(y_l * 0.05));
      
      if(y_p > 0) { m_lbl_year_val.Color(clrGain); m_lbl_year_per.Color(clrGain); }
      else if(y_p < 0) { m_lbl_year_val.Color(clrLoss); m_lbl_year_per.Color(clrLoss); }
      else { m_lbl_year_val.Color(clrBase); m_lbl_year_per.Color(clrBase); }
      
      // Cleanup old cache
      CleanupCachedHistory();
   }

   // Cleanup old cache data that is no longer displayed
   void CleanupCachedHistory()
   {
      // 1. Daily: Delete 8th day (Index 7)
      datetime t_d = GetTime(PERIOD_D1, 7);
      if(t_d > 0)
      {
         string date_str = TimeToString(t_d, TIME_DATE);
         GlobalVariableDel("GH_D_" + date_str + "_P");
         GlobalVariableDel("GH_D_" + date_str + "_D");
         GlobalVariableDel("GH_D_" + date_str + "_L");
      }
      
      // 2. Weekly: Delete 5th week (Index 4)
      datetime t_w = GetTime(PERIOD_W1, 4);
      if(t_w > 0)
      {
         string date_str = TimeToString(t_w, TIME_DATE);
         GlobalVariableDel("GH_W_" + date_str + "_P");
         GlobalVariableDel("GH_W_" + date_str + "_D");
         GlobalVariableDel("GH_W_" + date_str + "_L");
      }
      
      // 3. Monthly: Delete 3rd month (Index 2)
      datetime t_m = GetTime(PERIOD_MN1, 2);
      if(t_m > 0)
      {
         string date_str = TimeToString(t_m, TIME_DATE);
         GlobalVariableDel("GH_M_" + date_str + "_P");
         GlobalVariableDel("GH_M_" + date_str + "_D");
         GlobalVariableDel("GH_M_" + date_str + "_L");
      }
   }
   
   // Big Loop: Calculate and Cache History up to Yesterday
   void UpdateHistoricalCache()
   {
      datetime current = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(current, dt);
      
      // End of Yesterday (23:59:59 of previous day)
      datetime today_midnight = current - (current % 86400);
      datetime time_end = today_midnight - 1; 

      // 1. Determine Start Dates for all requirements
      // Daily: Need past 6 days (Index 1-6)
      datetime t_d_start = GetTime(PERIOD_D1, 6);
      
      // Weekly: Need past 3 weeks (Index 1-3) + Current Week Partial (Index 0)
      datetime t_w_start = GetTime(PERIOD_W1, 3);
      
      // Monthly: Need past 1 month (Index 1) + Current Month Partial (Index 0)
      datetime t_m_start = GetTime(PERIOD_MN1, 1);
      
      // Yearly: Current Year Partial
      dt.mon = 1; dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
      datetime t_y_start = StructToTime(dt);
      
      // Find minimum start date
      datetime time_start = t_d_start;
      if(t_w_start < time_start) time_start = t_w_start;
      if(t_m_start < time_start) time_start = t_m_start;
      if(t_y_start < time_start) time_start = t_y_start;

      // 2. Select History
      if(!HistorySelect(time_start, time_end)) return;
      
      // 3. Initialize Accumulators
      double d_prof[7], d_dep[7], d_lot[7]; ArrayInitialize(d_prof,0); ArrayInitialize(d_dep,0); ArrayInitialize(d_lot,0);
      double w_prof[4], w_dep[4], w_lot[4]; ArrayInitialize(w_prof,0); ArrayInitialize(w_dep,0); ArrayInitialize(w_lot,0);
      double m_prof[2], m_dep[2], m_lot[2]; ArrayInitialize(m_prof,0); ArrayInitialize(m_dep,0); ArrayInitialize(m_lot,0);
      double y_prof = 0, y_dep = 0, y_lot = 0;

      // Pre-calculate Time Ranges for checking
      datetime d_times[8]; 
      for(int i=0; i<7; i++) d_times[i] = GetTime(PERIOD_D1, i);
      d_times[7] = 0; 
      
      datetime w_times[5]; 
      for(int i=0; i<4; i++) w_times[i] = GetTime(PERIOD_W1, i);
      w_times[4] = 0;

      datetime m_times[3];
      for(int i=0; i<2; i++) m_times[i] = GetTime(PERIOD_MN1, i);
      m_times[2] = 0;
      
      // Iterate Deals
      int deals = HistoryDealsTotal();
      for(int i=0; i<deals; i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         
         double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         double s = HistoryDealGetDouble(ticket, DEAL_SWAP);
         double c = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         double v = HistoryDealGetDouble(ticket, DEAL_VOLUME);
         long type = HistoryDealGetInteger(ticket, DEAL_TYPE);
         long deal_entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         
         double net_profit = 0;
         double net_deposit = 0;
         double net_lot = 0;
         
         if(deal_entry == DEAL_ENTRY_IN)
         {
            net_lot = v;
         }

         if(type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL)
         {
            net_profit = p + s + c;
         }
         else if(type == DEAL_TYPE_BALANCE || type == DEAL_TYPE_CREDIT)
         {
            net_deposit = p;
         }
         else
         {
            net_profit = p + s + c;
         }

         // Bucket: Daily (1..6)
         for(int k=1; k<7; k++) {
             if(deal_time >= d_times[k] && deal_time < d_times[k-1]) {
                 d_prof[k] += net_profit; d_dep[k] += net_deposit; d_lot[k] += net_lot; break;
             }
         }
         
         // Bucket: Weekly (0..3)
         // Week 0 here means "This Week up to Yesterday"
         for(int k=0; k<4; k++) {
             datetime next_bound = (k==0) ? today_midnight : w_times[k-1]; 
             if(deal_time >= w_times[k] && deal_time < next_bound) {
                 w_prof[k] += net_profit; w_dep[k] += net_deposit; w_lot[k] += net_lot; break;
             }
         }
         
         // Bucket: Monthly (0..1)
         for(int k=0; k<2; k++) {
             datetime next_bound = (k==0) ? today_midnight : m_times[k-1];
             if(deal_time >= m_times[k] && deal_time < next_bound) {
                 m_prof[k] += net_profit; m_dep[k] += net_deposit; m_lot[k] += net_lot; break;
             }
         }
         
         // Bucket: Yearly (Current Year)
         if(deal_time >= t_y_start && deal_time < today_midnight) {
             y_prof += net_profit; y_dep += net_deposit; y_lot += net_lot;
         }
      }
      
      // 4. Save to Global Variables
      // Daily 1-6
      for(int k=1; k<7; k++) {
          string date_str = TimeToString(d_times[k], TIME_DATE);
          GlobalVariableSet("GH_D_" + date_str + "_P", d_prof[k]);
          GlobalVariableSet("GH_D_" + date_str + "_D", d_dep[k]);
          GlobalVariableSet("GH_D_" + date_str + "_L", d_lot[k]);
      }
      
      // Weekly 1-3
      for(int k=1; k<4; k++) {
          string date_str = TimeToString(w_times[k], TIME_DATE);
          GlobalVariableSet("GH_W_" + date_str + "_P", w_prof[k]);
          GlobalVariableSet("GH_W_" + date_str + "_D", w_dep[k]);
          GlobalVariableSet("GH_W_" + date_str + "_L", w_lot[k]);
      }
      // Weekly 0 (Partial)
      GlobalVariableSet("GH_PARTIAL_W_P", w_prof[0]); // Profit
      GlobalVariableSet("GH_PARTIAL_W_D", w_dep[0]); // Deposit
      GlobalVariableSet("GH_PARTIAL_W_L", w_lot[0]); // Lot (Volume)
      
      // Monthly 1
      for(int k=1; k<2; k++) {
          string date_str = TimeToString(m_times[k], TIME_DATE);
          GlobalVariableSet("GH_M_" + date_str + "_P", m_prof[k]);
          GlobalVariableSet("GH_M_" + date_str + "_D", m_dep[k]);
          GlobalVariableSet("GH_M_" + date_str + "_L", m_lot[k]);
      }
      // Monthly 0 (Partial)
      GlobalVariableSet("GH_PARTIAL_M_P", m_prof[0]); 
      GlobalVariableSet("GH_PARTIAL_M_D", m_dep[0]); 
      GlobalVariableSet("GH_PARTIAL_M_L", m_lot[0]);
      
      // Yearly (Partial)
      GlobalVariableSet("GH_PARTIAL_Y_P", y_prof); 
      GlobalVariableSet("GH_PARTIAL_Y_D", y_dep); 
      GlobalVariableSet("GH_PARTIAL_Y_L", y_lot);
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

      StyleLabel(m_lbl_status, C'255, 191, 128');

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
      StyleLabel(m_lbl_date_dd, clrBase);

      StyleLabel(m_lbl_h_period, gray);
      StyleLabel(m_lbl_h_gain, gray);
      StyleLabel(m_lbl_h_profit, gray);
      StyleLabel(m_lbl_h_lot, gray);
      StyleLabel(m_lbl_h_rebate, gray);

      StyleLabel(m_lbl_h_daily, C'128, 170, 255');
      StyleLabel(m_lbl_h_weekly, C'128, 170, 255');
      StyleLabel(m_lbl_h_monthly, C'128, 170, 255');
      StyleLabel(m_lbl_h_yearly, C'128, 170, 255');

      m_separator.ColorBorder(C'60,60,60');
      m_separator2.ColorBorder(C'60,60,60');
      m_separator3.ColorBorder(C'60,60,60');
      m_separator4.ColorBorder(C'60,60,60');
      m_separator5.ColorBorder(C'60,60,60');
      m_separator6.ColorBorder(C'60,60,60');
      m_separator7.ColorBorder(C'60,60,60');

      // History Style
      for(int i=0; i<7; i++)
      {
         m_lbl_hist_date[i].ColorBackground(C'30,30,30');
         m_lbl_hist_date[i].Color(clrBase);
         
         m_lbl_hist_per[i].ColorBackground(C'30,30,30');
         m_lbl_hist_val[i].ColorBackground(C'30,30,30');
         m_lbl_hist_lot[i].ColorBackground(C'30,30,30');
         m_lbl_hist_lot[i].Color(clrBase);
         m_lbl_hist_rebate[i].ColorBackground(C'30,30,30');
         m_lbl_hist_rebate[i].Color(clrBase);
         // Color handled dynamically
      }
      
      // Weekly History Style
      for(int i=0; i<4; i++)
      {
         m_lbl_week_date[i].ColorBackground(C'30,30,30');
         m_lbl_week_date[i].Color(clrBase);

         m_lbl_week_per[i].ColorBackground(C'30,30,30');
         m_lbl_week_val[i].ColorBackground(C'30,30,30');
         m_lbl_week_lot[i].ColorBackground(C'30,30,30');
         m_lbl_week_lot[i].Color(clrBase);
         m_lbl_week_rebate[i].ColorBackground(C'30,30,30');
         m_lbl_week_rebate[i].Color(clrBase);
      }
      
      // Monthly Style
      for(int i=0; i<2; i++)
      {
         m_lbl_mon_date[i].ColorBackground(C'30,30,30');
         m_lbl_mon_date[i].Color(clrBase);

         m_lbl_mon_per[i].ColorBackground(C'30,30,30');
         m_lbl_mon_val[i].ColorBackground(C'30,30,30');
         m_lbl_mon_lot[i].ColorBackground(C'30,30,30');
         m_lbl_mon_lot[i].Color(clrBase);
         m_lbl_mon_rebate[i].ColorBackground(C'30,30,30');
         m_lbl_mon_rebate[i].Color(clrBase);
      }
      
      // Yearly Style
      m_lbl_year_date.ColorBackground(C'30,30,30');
      m_lbl_year_date.Color(clrBase);
      m_lbl_year_per.ColorBackground(C'30,30,30');
      m_lbl_year_val.ColorBackground(C'30,30,30');
      m_lbl_year_lot.ColorBackground(C'30,30,30');
      m_lbl_year_lot.Color(clrBase);
      m_lbl_year_rebate.ColorBackground(C'30,30,30');
      m_lbl_year_rebate.Color(clrBase);
   }
   
   void StyleLabel(CLabel &lbl, color clr)
   {
      lbl.ColorBackground(C'30,30,30');
      lbl.Color(clr);
   }
   
private:
   CLabel m_lbl_band, m_lbl_page, m_lbl_status;

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

   CLabel m_lbl_h_period, m_lbl_h_gain, m_lbl_h_profit, m_lbl_h_lot, m_lbl_h_rebate;
   CLabel m_lbl_h_daily, m_lbl_h_weekly, m_lbl_h_monthly, m_lbl_h_yearly;
   CLabel m_lbl_hist_date[7];
   CLabel m_lbl_hist_per[7];
   CLabel m_lbl_hist_val[7];
   CLabel m_lbl_hist_lot[7];
   CLabel m_lbl_hist_rebate[7];
   
   // Weekly History Labels
   CLabel m_lbl_week_date[4];
   CLabel m_lbl_week_per[4];
   CLabel m_lbl_week_val[4];
   CLabel m_lbl_week_lot[4];
   CLabel m_lbl_week_rebate[4];

   // Monthly History Labels
   CLabel m_lbl_mon_date[2];
   CLabel m_lbl_mon_per[2];
   CLabel m_lbl_mon_val[2];
   CLabel m_lbl_mon_lot[2];
   CLabel m_lbl_mon_rebate[2];

   // Yearly History Labels
   CLabel m_lbl_year_date;
   CLabel m_lbl_year_per;
   CLabel m_lbl_year_val;
   CLabel m_lbl_year_lot;
   CLabel m_lbl_year_rebate;

   CPanel m_separator,m_separator2,m_separator3,m_separator4,m_separator5,m_separator6,m_separator7;
   
protected:
   ulong m_last_click_time;
   datetime m_last_calc_date; // Last date the Big Loop was run
   
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

color clrBase = C'180,180,180';
color clrGain = C'71, 209, 71';
color clrLoss = C'255, 77, 77';

int OnInit()
{
   // Set Defaults from Inputs
   PanelX = InpPanelX;
   PanelY = InpPanelY;
   PanelMinX = InpPanelX;
   PanelMinY = InpPanelY;

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

   // 5. Create Panel (Increased Height for Monthly/Yearly)
   if(!AppWindow.Create(0,"Golden Hour",0,startX,startY,startX+380,startY+680))
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

   // Check for Click on ClearDD Label
   if(id == CHARTEVENT_OBJECT_CLICK && StringFind(sparam, "ClearDD") >= 0)
   {
      Print("Click!");
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
