//+------------------------------------------------------------------+
//|                                                PVC Red China.mq5 |
//|                                          Copyright 2025, LocalFX |
//|                               https://www.facebook.com/LocalFX4U |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, LocalFX"
#property link "https://www.facebook.com/LocalFX4U"
#property version "1.00"
#property strict

#include <Controls/Dialog.mqh>
#include <Controls/Label.mqh>

#define BTN1 "BTN_Auto_Remove"
#define BTN2 "BTN_CLEAR_NOW"

bool isVIP = true;
string Comp_Name = "Local FX";
string Comp_Link = "www.facebook.com/LocalFX4U";
string EA_Name = "Golden Hour";
int Slippage = 10;

#import "LibMT5Approve.ex5"
string gsheetDownloadUpload(string url,string datasheets, string keys, string columes, string updateValue, string updateColumes);
#import

string gsheet_url    = "https://script.google.com/macros/s/AKfycbxAnCOP-RpUzq16DcPt9WsDytjjxbldHEG5XVMfelp8wacSRwhlqJxKM2V3jkVcijtx/exec";
string datasheets    = "MT5"; // Datasheet

long   acc_id        = AccountInfoInteger(ACCOUNT_LOGIN);
long   accountType   = AccountInfoInteger(ACCOUNT_TRADE_MODE);
string ac_currency   = AccountInfoString(ACCOUNT_CURRENCY);
string fullname      = AccountInfoString(ACCOUNT_NAME);
string broker        = AccountInfoString(ACCOUNT_COMPANY);
string server        = AccountInfoString(ACCOUNT_SERVER);
string date_time     = TimeToString(TimeLocal(), TIME_DATE|TIME_SECONDS);
string realOrDemo    = accountType == ACCOUNT_TRADE_MODE_DEMO ? "DEMO" : accountType == ACCOUNT_TRADE_MODE_REAL ? "REAL" : "-";
string backtest_mode = "";

string keys             = IntegerToString(acc_id); //Key
string columes          = "3"; //Get(check) Data at column : C [ID]
string updateValue      = "";  //Collect Data in 1 Line
string updateColumes    = "4"; //Send to column : D [AC Type]
string approve_account  = "";
double dateApprove      = 0;

enum AccCurrency
{
   USD = 1,  // USD
   CNT = 100 // CENT
};

enum Switcher
{
   ON = 1,
   OFF = 0
};

enum RiskLevel
{
   Low = 1,  // เสี่ยงต่ำ
   Normal = 2,  // เสี่ยงปานกลาง
   High = 3 // เสี่ยงสูง
};

enum Notify
{
   NTF_5M = 300,   // 5 Minutes
   NTF_10M = 600,  // 10 Minutes
   NTF_15M = 900,  // 15 Minutes
   NTF_30M = 1800, // 30 Minutes
   NTF_45M = 2700, // 45 Minutes
   NTF_1H = 3600,  // 1 Hour
   NTF_2H = 7200,  // 2 Hours
   NTF_4H = 14400, // 4 Hours
   NTF_8H = 28800, // 8 Hours
   NTF_12H = 43200 // 12 Hours
};

enum Position
{
   TOP_LEFT = 0,
   TOP_RIGHT = 3,
   BOTTOM_LEFT = 1,
   BOTTOM_RIGHT = 2
};

enum InpTimeframe
{
   TF_1M = PERIOD_M1,   // 1 Minute
   TF_2M = PERIOD_M2,   // 2 Minutes
   TF_3M = PERIOD_M3,   // 3 Minutes
   TF_4M = PERIOD_M4,   // 4 Minutes
   TF_5M = PERIOD_M5,   // 5 Minutes
   TF_6M = PERIOD_M6,   // 6 Minutes
   TF_10M = PERIOD_M10, // 10 Minutes
   TF_12M = PERIOD_M12, // 12 Minutes
   TF_15M = PERIOD_M15, // 15 Minutes
   TF_20M = PERIOD_M20, // 20 Minutes
   TF_30M = PERIOD_M30, // 30 Minutes
   TF_1H = PERIOD_H1,   // 1 Hour
   TF_2H = PERIOD_H2,   // 2 Hours
   TF_3H = PERIOD_H3,   // 3 Hours
   TF_4H = PERIOD_H4,   // 4 Hours
   TF_6H = PERIOD_H6,   // 6 Hours
   TF_8H = PERIOD_H8,   // 8 Hours
   TF_12H = PERIOD_H12, // 12 Hours
   TF_1D = PERIOD_D1,   // 1 Day
   TF_1W = PERIOD_W1,   // 1 Week
   TF_MN = PERIOD_MN1   // 1 Month
};

const input string _____Account_____ = "=========== Account ===========";
input double Acc_Rebate = 8; // Rebate
double _rebate = 0;
input AccCurrency Acc_Currency = CNT; // ประเภทบัญชี

const input string _____Trading_____ = "============ Trading ============";
input InpTimeframe Time_frame = TF_20M; // ออกออเดอร์ทุกๆ นาที/ชั่วโมง/...
input Switcher Allow_Buy = ON;          // เปิดฝั่ง Buy
input Switcher Allow_Sell = ON;         // เปิดฝั่ง Sell
input double Lot_Size = 0.01;           // ขนาด Lot
input double Target = 2.0;              // Target

const input string _____Boost_____ = "=========== Boost mode ===========";
input Switcher Boost_MODE = ON;   // เพิ่ม lot size ในช่วงปลอดภัย
input RiskLevel Risk_level = Low; // ระดับความเสี่ยงที่รับได้
bool isBoost = false;

const input string _____Safe_____ = "=========== Safe mode ============";
input Switcher Safe_MODE = ON; // ช่วยลด DD เมื่อโดนลาก
input int Safe_DD = 20;         // เปิด Safe mode เมื่อมี Draw Down ถึง ... %
double Safe_DD_per = 0;
double Safe_min_DD = 0;
string Safe_Type = "";

const string _____Auto_Remove_Order_____ = "======== Auto Remove Order ========";
Switcher Auto_Remove = OFF; // โหมดปิดออเดอร์อัตโนมัติ (เฉพาะออเดอร์ที่ปิดได้)
bool FNC_Auto_Remove = false;
int Remove_At = 500;     // ปิดอัตโนมัติ เมื่อออเดอร์ถึงจำนวน...
int Remove_Percent = 20; // จำนวนออเดอร์ที่ต้องการลบ (คิดเป็น % ของจำนวนที่กำหนดไว้)

const input string _____Limit_Order_____ = "=========== Limit Order ===========";
input Switcher Limit_Order = OFF; // จำกัดการออกออเดอร์
input int LimitAmount = 500;        // เมื่อถึงจำนวน ... ไม้ จะไม่ออกออเดอร์เพิ่ม

const string _____Martingel_____ = "=========== Martingel ===========";
Switcher Martingel_MODE = OFF; // โหมด Martingel
int Martingel_at = 100;        // Martingel เมื่อ Buy หรือ Sell ถึงจำนวน ... ไม้
double Limit_lot_size = 10.00; // กำหนด Lot size สูงสุดที่จะออกได้
double Avg_dist_should_be = 0;
int Avg_start_mtgl = 0;

const input string _____Notification_____ = "=========== Notification ==========";
input Switcher Notify_App = OFF;    // แจ้งเตือนผ่าน MT5 ในมือถือ
input Switcher Notify_Email = OFF;  // แจ้งเตือนผ่าน Email
input Notify Notify_Timer = NTF_1H; // แจ้งเตือนทุกๆ นาที,ชั่วโมง
input int Notify_DD = 50;            // แจ้งเตือนเมื่อ Draw Down ถึง ... %
double Notify_DD_per = 0;
input int Notify_Orders = 0; // แจ้งเตือนเมื่อจำนวน Order ถึง ...

const input string _____UI_Position_____ = "============ UI Setting ============";
input int InpPanelX = 1500; // ตำแน่งเริ่มต้นของ UI แนวนอน
input int InpPanelY = 20;  // ตำแน่งเริ่มต้นของ UI แนวตั้ง

Position Button_Position = TOP_RIGHT;    // ตำแหน่งของปุ่ม
Position Label_Position = BOTTOM_RIGHT;  // ตำแหน่งของรายละเอียด
datetime St_Date = D'2026.01.01 00:00'; // คำนวณสถิติตั้งแต่วันที่

// ----- [Casual]
double first_balance = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_balance = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_profit = AccountInfoDouble(ACCOUNT_PROFIT);
double maxDrawDown = 0;
double maxDD_Per = 0;
datetime maxDD_Date = 0;
double curDrawDown = 0;
double curDD_Per = 0;

string _symbol = _Symbol;
double _ask = 0;
double _bid = 0;
double _point = _Point;
int _digits = _Digits;

int totalOrders = 0;
int countBuy = 0;
int countSell = 0;

double TotalLot = 0;
double sumLotBuy = 0;
double sumLotSell = 0;

double currentBuyProfit = 0.0;  // sum of buy profit (money: profit+swap+commission)
double currentSellProfit = 0.0; // sum of sell profit (money: profit+swap+commission)
double NetProfitTotal = 0.0;    // currentBuyProfit + currentSellProfit (money)

double highest_loss = 0;
double highest_profit = 0;
// ----- [Casual]

// ----- [Label]
// Label Class
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
      if(!CreateLabel(m_lbl_band, "FB: "+Comp_Name, "BandKey", x1_key, y, x2_key, y+20)) return false;
      y += step;
      if(!CreateLabel(m_lbl_page, Comp_Link, "PageKey", x1_key, y, x2_key, y+20)) return false;
      y = y-20;
      if(!CreateLabel(m_lbl_status, "", "StatusKey", x1_key+295, y, x2_key, y+20)) return false;

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
      if(!CreateLabel(m_lbl_ord_total_val, "0",       "OrdTotVal", x_sum_col1+45, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_total_key,   "Lot:",    "LotTotKey", x_sum_col2, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_total_val,   "0.00",       "LotTotVal", x_sum_col2+30, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_profit_key,  "Profit:",   "OrdSellKey", x_sum_col3, y, x_sum_col3+70, y+20)) return false;
      if(!CreateLabel(m_lbl_profit_val,  "0.00",       "OrdSellVal", x_sum_col3+45, y, x_sum_col3+70, y+20)) return false;
      y += summary_step;

      // Row 2: Long
      if(!CreateLabel(m_lbl_ord_buy_key, "Long:",   "OrdBuyKey", x_sum_col1, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_ord_buy_val, "0",          "OrdBuyVal", x_sum_col1+45, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_buy_key,   "Lot:",       "LotBuyKey", x_sum_col2, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_buy_val,   "0.00",          "LotBuyVal", x_sum_col2+30, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_buy_key,  "Profit:",      "ProfBuyKey", x_sum_col3, y, x_sum_col3+70, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_buy_val,  "0.00",          "ProfBuyVal", x_sum_col3+45, y, x_sum_col3+70, y+20)) return false;
      y += summary_step;

      // Row 3: Short
      if(!CreateLabel(m_lbl_ord_sell_key, "Short:", "ProfTotKey", x_sum_col1, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_ord_sell_val, "0",     "ProfTotVal", x_sum_col1+45, y, x_sum_col1+90, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_sell_key,   "Lot:",    "LotSellKey", x_sum_col2, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_lot_sell_val,   "0.00",      "LotSellVal", x_sum_col2+30, y, x_sum_col2+80, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_sell_key,  "Profit:",   "ProfSellKey", x_sum_col3, y, x_sum_col3+70, y+20)) return false;
      if(!CreateLabel(m_lbl_prof_sell_val,  "0.00",       "ProfSellVal", x_sum_col3+45, y, x_sum_col3+70, y+20)) return false;
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
      if(!CreateLabel(m_lbl_cur_dd_per, "(0%)",   "CurDDPer", x_dd_col2, y, x_dd_col2+50, y+20)) return false;
      if(!CreateLabel(m_lbl_cur_dd_val, "0.00",        "CurDDVal", x_dd_col3, y, x_dd_col3+50, y+20)) return false;
      if(!CreateLabel(m_lbl_clear_dd, "[Clear Max DD]",        "ClearDD", x_dd_col4, y, x_dd_col3+50, y+20)) return false;
      y += summary_step-5;

      // Row 2: Max DD
      if(!CreateLabel(m_lbl_max_dd_key, "Max DD:",    "MaxDDKey", x_dd_col1, y, x_dd_col1+50, y+20)) return false;
      if(!CreateLabel(m_lbl_max_dd_per, "(0%)",  "MaxDDPer", x_dd_col2, y, x_dd_col2+50, y+20)) return false;
      if(!CreateLabel(m_lbl_max_dd_val, "0.00",       "MaxDDVal", x_dd_col3, y, x_dd_col3+50, y+20)) return false;
      if(!CreateLabel(m_lbl_date_dd, "",        "DateDD", x_dd_col4+10, y, x_dd_col3+50, y+20)) return false;
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
      string txt_status = "";
      if(isBoost)
         txt_status = "[BOOST]";
      if(Safe_Type != "")
         txt_status = "[SAFE]";

      m_lbl_status.Text(txt_status);

      m_lbl_balance_val.Text(FormatNumber(AccountInfoDouble(ACCOUNT_BALANCE)));
      m_lbl_balance_val.Color(clrWhite);

      m_lbl_equity_val.Text(FormatNumber(AccountInfoDouble(ACCOUNT_EQUITY)));
      m_lbl_equity_val.Color(clrWhite);
      
      double profit = AccountInfoDouble(ACCOUNT_PROFIT);
      m_lbl_profit_val.Text(FormatNumber(profit));
      if(profit > 0) m_lbl_profit_val.Color(clrGain);
      else if(profit < 0) m_lbl_profit_val.Color(clrLoss);
      else m_lbl_profit_val.Color(clrWhite);
      
      m_lbl_spread_val.Text((string)(int)(_spread / _point));
      m_lbl_avg_spread_val.Text((string)(int)(avg_spread / _point));

      m_lbl_ord_total_val.Text((string)totalOrders);
      m_lbl_lot_total_val.Text(FormatNumber(TotalLot));

      m_lbl_ord_buy_val.Text((string)countBuy);
      m_lbl_lot_buy_val.Text(FormatNumber(sumLotBuy));
      m_lbl_prof_buy_val.Text(FormatNumber(currentBuyProfit));
      if(currentBuyProfit > 0) m_lbl_prof_buy_val.Color(clrGain);
      else if(currentBuyProfit < 0) m_lbl_prof_buy_val.Color(clrLoss);
      else m_lbl_prof_buy_val.Color(clrWhite);

      m_lbl_ord_sell_val.Text((string)countSell);
      m_lbl_lot_sell_val.Text(FormatNumber(sumLotSell));
      m_lbl_prof_sell_val.Text(FormatNumber(currentSellProfit));
      if(currentSellProfit > 0) m_lbl_prof_sell_val.Color(clrGain);
      else if(currentSellProfit < 0) m_lbl_prof_sell_val.Color(clrLoss);
      else m_lbl_prof_sell_val.Color(clrWhite);

      m_lbl_cur_dd_val.Text(FormatNumber(curDrawDown));
      m_lbl_cur_dd_per.Text("(" + FormatNumber(curDD_Per) + "%)");

      string txtMaxDD_date = maxDD_Date == 0 ? "" : TimeToString(maxDD_Date, TIME_DATE);
      m_lbl_max_dd_val.Text(FormatNumber(maxDrawDown));
      m_lbl_max_dd_per.Text("(" + FormatNumber(maxDD_Per) + "%)");
      m_lbl_date_dd.Text(txtMaxDD_date);

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

            if (HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
            {
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
             if(GlobalVariableCheck(EncodeAZ("ghd") + date_str + "_P")) {
                 d_p = GlobalVariableGet(EncodeAZ("ghd") + date_str + "_P");
                 d_d = GlobalVariableGet(EncodeAZ("ghd") + date_str + "_D");
                 d_l = GlobalVariableGet(EncodeAZ("ghd") + date_str + "_L");
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
         m_lbl_hist_rebate[i].Text(FormatNumber(d_l * _rebate)); // Rebate logic same as lot for now
         
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
             if(GlobalVariableCheck(EncodeAZ("ghptwp"))) {
                 w_p = GlobalVariableGet(EncodeAZ("ghptwp")) + t_prof; // Add Today's
                 w_d = GlobalVariableGet(EncodeAZ("ghptwd")) + t_dep;
                 w_l = GlobalVariableGet(EncodeAZ("ghptwl")) + t_lot;
             } else {
                 w_p = t_prof; w_d = t_dep; w_l = t_lot;
             }
         }
         else // Past Weeks
         {
             string date_str = TimeToString(t_w, TIME_DATE);
             if(GlobalVariableCheck(EncodeAZ("ghw") + date_str + "_P")) {
                 w_p = GlobalVariableGet(EncodeAZ("ghw") + date_str + "_P");
                 w_d = GlobalVariableGet(EncodeAZ("ghw") + date_str + "_D");
                 w_l = GlobalVariableGet(EncodeAZ("ghw") + date_str + "_L");
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
         m_lbl_week_rebate[i].Text(FormatNumber(w_l * _rebate));
         
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
             if(GlobalVariableCheck(EncodeAZ("ghptmp"))) {
                 m_p = GlobalVariableGet(EncodeAZ("ghptmp")) + t_prof;
                 m_d = GlobalVariableGet(EncodeAZ("ghptmd")) + t_dep;
                 m_l = GlobalVariableGet(EncodeAZ("ghptml")) + t_lot;
             } else {
                 m_p = t_prof; m_d = t_dep; m_l = t_lot;
             }
         }
         else // Past Month
         {
             string date_str = TimeToString(t_m, TIME_DATE);
             if(GlobalVariableCheck(EncodeAZ("ghm") + date_str + "_P")) {
                 m_p = GlobalVariableGet(EncodeAZ("ghm") + date_str + "_P");
                 m_d = GlobalVariableGet(EncodeAZ("ghm") + date_str + "_D");
                 m_l = GlobalVariableGet(EncodeAZ("ghm") + date_str + "_L");
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
         m_lbl_mon_rebate[i].Text(FormatNumber(m_l * _rebate));

         if(m_p > 0) { m_lbl_mon_val[i].Color(clrGain); m_lbl_mon_per[i].Color(clrGain); }
         else if(m_p < 0) { m_lbl_mon_val[i].Color(clrLoss); m_lbl_mon_per[i].Color(clrLoss); }
         else { m_lbl_mon_val[i].Color(clrBase); m_lbl_mon_per[i].Color(clrBase); }
         
         running_balance = start_bal;
      }
      
      // 4. Yearly History (Current Only)
      running_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double y_p = 0, y_d = 0, y_l = 0;
      
      if(GlobalVariableCheck(EncodeAZ("ghptyp"))) {
          y_p = GlobalVariableGet(EncodeAZ("ghptyp")) + t_prof;
          y_d = GlobalVariableGet(EncodeAZ("ghptyd")) + t_dep;
          y_d = GlobalVariableGet(EncodeAZ("ghptyl")) + t_dep;
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
      m_lbl_year_rebate.Text(FormatNumber(y_l * _rebate));
      
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
         GlobalVariableDel(EncodeAZ("ghd") + date_str + "_P");
         GlobalVariableDel(EncodeAZ("ghd") + date_str + "_D");
         GlobalVariableDel(EncodeAZ("ghd") + date_str + "_L");
      }
      
      // 2. Weekly: Delete 5th week (Index 4)
      datetime t_w = GetTime(PERIOD_W1, 4);
      if(t_w > 0)
      {
         string date_str = TimeToString(t_w, TIME_DATE);
         GlobalVariableDel(EncodeAZ("ghw") + date_str + "_P");
         GlobalVariableDel(EncodeAZ("ghw") + date_str + "_D");
         GlobalVariableDel(EncodeAZ("ghw") + date_str + "_L");
      }
      
      // 3. Monthly: Delete 3rd month (Index 2)
      datetime t_m = GetTime(PERIOD_MN1, 2);
      if(t_m > 0)
      {
         string date_str = TimeToString(t_m, TIME_DATE);
         GlobalVariableDel(EncodeAZ("ghm") + date_str + "_P");
         GlobalVariableDel(EncodeAZ("ghm") + date_str + "_D");
         GlobalVariableDel(EncodeAZ("ghm") + date_str + "_L");
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
         if (HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
         {
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
               y_prof += net_profit; y_dep += net_deposit;
            }
         }
      }
      
      // 4. Save to Global Variables
      // Daily 1-6
      for(int k=1; k<7; k++) {
          string date_str = TimeToString(d_times[k], TIME_DATE);
          GlobalVariableSet(EncodeAZ("ghd") + date_str + "_P", d_prof[k]);
          GlobalVariableSet(EncodeAZ("ghd") + date_str + "_D", d_dep[k]);
          GlobalVariableSet(EncodeAZ("ghd") + date_str + "_L", d_lot[k]);
      }
      
      // Weekly 1-3
      for(int k=1; k<4; k++) {
          string date_str = TimeToString(w_times[k], TIME_DATE);
          GlobalVariableSet(EncodeAZ("ghw") + date_str + "_P", w_prof[k]);
          GlobalVariableSet(EncodeAZ("ghw") + date_str + "_D", w_dep[k]);
          GlobalVariableSet(EncodeAZ("ghw") + date_str + "_L", w_lot[k]);
      }
      // Weekly 0 (Partial)
      GlobalVariableSet(EncodeAZ("ghptwp"), w_prof[0]); // Profit
      GlobalVariableSet(EncodeAZ("ghptwd"), w_dep[0]); // Deposit
      GlobalVariableSet(EncodeAZ("ghptwl"), w_lot[0]); // Lot (Volume)
      
      // Monthly 1
      for(int k=1; k<2; k++) {
          string date_str = TimeToString(m_times[k], TIME_DATE);
          GlobalVariableSet(EncodeAZ("ghm") + date_str + "_P", m_prof[k]);
          GlobalVariableSet(EncodeAZ("ghm") + date_str + "_D", m_dep[k]);
          GlobalVariableSet(EncodeAZ("ghm") + date_str + "_L", m_lot[k]);
      }
      // Monthly 0 (Partial)
      GlobalVariableSet(EncodeAZ("ghptmp"), m_prof[0]); 
      GlobalVariableSet(EncodeAZ("ghptmd"), m_dep[0]); 
      GlobalVariableSet(EncodeAZ("ghptml"), m_lot[0]);
      
      // Yearly (Partial)
      GlobalVariableSet(EncodeAZ("ghptyp"), y_prof); 
      GlobalVariableSet(EncodeAZ("ghptyd"), y_dep); 
      GlobalVariableSet(EncodeAZ("ghptyl"), y_lot);
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
      StyleLabel(m_lbl_prof_sell_key, gray);
      
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
   CLabel m_lbl_lot_total_key, m_lbl_lot_total_val;
   
   CLabel m_lbl_ord_buy_key, m_lbl_ord_buy_val;
   CLabel m_lbl_lot_buy_key, m_lbl_lot_buy_val;
   CLabel m_lbl_prof_buy_key, m_lbl_prof_buy_val;
   
   CLabel m_lbl_ord_sell_key, m_lbl_ord_sell_val;
   CLabel m_lbl_lot_sell_key, m_lbl_lot_sell_val;
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

// ----- [Label]

// ----- [Button]
struct Button
{
   int index;
   string name;
   string text;
   int width;
   int higth;
   int disX;
   color clrText;
   color clrBackground;

   void setX(int newX)
   {
      disX = newX;
   }
};

Button objButton[] = {
    {1, BTN1, "Auto Clear", 130, 40, 0, clrWhite, clrMediumSeaGreen},
    {2, BTN2, "Clear Now!", 130, 40, 0, clrWhite, clrMaroon},
};
// ----- [Button]

// ----- [Spread]
double   _spread              = 0;
double   avg_spread           = 0;
double   sum_spread           = 0;
int      count_spread         = 0;
datetime spread_date          = 0;
// ----- [Spread]

// ----- [Average]
// Normal
bool show_avg_line = false;
int font_info_size = 12;
int PipAdjust;
double point_avg;
// Buy
string avgSell = "Sell_avg_line_" + _Symbol;
string infoSell = "Sell_info_" + _Symbol;
int buy_line_width = 3;
color buy_line_color = Blue;
double Average_buy_price = 0;
// Sell
string avgBuy = "Buy_avg_line_" + _Symbol;
string infoBuy = "Buy_info_" + _Symbol;
int sell_line_width = 3;
color sell_line_color = Red;
double Average_sell_price = 0;
// ----- [Average]

// ----- [Martingel]
double top_price, bottom_price, middle_price, range_price, lock_range, Cur_avg_diff, maxLot;
int Stack_biglot, Highest_stack;
// ----- [Martingel]

// ----- [Auto Close]
struct KeyValue
{
   int ticket;
   int type;
   double lotsize;
   double price;
   double profit;
   double swap;
};

void AddKeyValue(KeyValue &arr[], int ticket, int type, double lotsize, double price, double profit, double swap)
{
   int size = ArraySize(arr);  // หาขนาดอาเรย์ปัจจุบัน
   ArrayResize(arr, size + 1); // ขยายอาเรย์เพิ่ม 1 ช่อง

   arr[size].ticket = ticket;
   arr[size].type = type;
   arr[size].lotsize = lotsize;
   arr[size].price = price;
   arr[size].profit = profit;
   arr[size].swap = swap;
}

KeyValue arrLoss[];
KeyValue arrProfit[];
KeyValue arrDelete[];

// ----- [Safe Mode]
KeyValue arrSafeLoss[];
KeyValue arrSafeProfit[];
double SafeSumLoss = 0;
double SafeBuyProfit = 0;
double SafeSellProfit = 0;
// ----- [Safe Mode]

int MustRemove = 0;
int removed = 0;
int removed_buy = 0;
int removed_sell = 0;

double lossTotal = 0;
double lossTotal2 = 0;
double profitTotal = 0;
double profitTotal2 = 0;
double swapTotal = 0;

double money_after_closed = 0; // V2
double netTotal = 0;           // V3
// ----- [Auto Close]

// ----- [Notify]
datetime lastNotify = 0;
// ----- [Notify]

void LoadGlobalPanel()
{
   // SimplePanel_IsMinimized = pnismd
   if(GlobalVariableCheck(EncodeAZ("pnismd") + _symbol + EA_Name)) 
      CurrentStateMinimized = (bool)GlobalVariableGet(EncodeAZ("pnismd") + _symbol + EA_Name);
   
   // SimplePanel_Max_X = pnmaxx
   if(GlobalVariableCheck(EncodeAZ("pnmaxx") + _symbol + EA_Name)) 
      PanelX = (int)GlobalVariableGet(EncodeAZ("pnmaxx") + _symbol + EA_Name);
   // SimplePanel_Max_Y = pnmaxy
   if(GlobalVariableCheck(EncodeAZ("pnmaxy") + _symbol + EA_Name)) 
      PanelY = (int)GlobalVariableGet(EncodeAZ("pnmaxy") + _symbol + EA_Name);

   // SimplePanel_Min_X = pnminx
   if(GlobalVariableCheck(EncodeAZ("pnminx") + _symbol + EA_Name)) 
      PanelMinX = (int)GlobalVariableGet(EncodeAZ("pnminx") + _symbol + EA_Name);
   // SimplePanel_Min_Y = pnminy
   if(GlobalVariableCheck(EncodeAZ("pnminy") + _symbol + EA_Name)) 
      PanelMinY = (int)GlobalVariableGet(EncodeAZ("pnminy") + _symbol + EA_Name);
}

void LoadVariable()
{
   // gblUserApproveDate = apvdate
   if (GlobalVariableCheck(EncodeAZ("apvdate") + (string)acc_id + EA_Name))
   {
      dateApprove = GlobalVariableGet(EncodeAZ("apvdate") + (string)acc_id + EA_Name);
   }
   // gblLastNotificate = lsntfct
   if (GlobalVariableCheck(EncodeAZ("lsntfct") + _symbol + EA_Name))
   {
      lastNotify = (datetime)GlobalVariableGet(EncodeAZ("lsntfct") + _symbol + EA_Name);
   }
   // gblMaxDrawDownMoney = mxddmny
   if (GlobalVariableCheck(EncodeAZ("mxddmny") + _symbol + EA_Name))
   {
      maxDrawDown = GlobalVariableGet(EncodeAZ("mxddmny") + _symbol + EA_Name);
   }
   // gblMaxDrawDownPer = mxddper
   if (GlobalVariableCheck(EncodeAZ("mxddper") + _symbol + EA_Name))
   {
      maxDD_Per = GlobalVariableGet(EncodeAZ("mxddper") + _symbol + EA_Name);
   }
   // gblMaxDrawDownDate = mdddate
   if (GlobalVariableCheck(EncodeAZ("mdddate") + _symbol + EA_Name))
   {
      maxDD_Date = (datetime)GlobalVariableGet(EncodeAZ("mdddate") + _symbol + EA_Name);
   }
   // gblAverageSpread = avgsprd
   if(GlobalVariableCheck(EncodeAZ("avgsprd") + _symbol + EA_Name))
   {
      avg_spread = GlobalVariableGet(EncodeAZ("avgsprd") + _symbol + EA_Name);
   }
   // gblSpreadUpdate = sprdupd
   if(GlobalVariableCheck(EncodeAZ("sprdupd") + _symbol + EA_Name))
   {
      spread_date = (datetime)GlobalVariableGet(EncodeAZ("sprdupd") + _symbol + EA_Name);
   }
}

void SaveUserApprove(double apvDate)
{
   GlobalVariableSet(EncodeAZ("apvdate") + (string)acc_id + EA_Name, apvDate);
}

void SaveLastNotificate(double data)
{
   GlobalVariableSet(EncodeAZ("lsntfct") + _symbol + EA_Name, data);
}

void SaveMaxDrawDown(double dd_money, double dd_per, datetime dd_date)
{
   GlobalVariableSet(EncodeAZ("mxddmny") + _symbol + EA_Name, dd_money);
   GlobalVariableSet(EncodeAZ("mxddper") + _symbol + EA_Name, dd_per);
   GlobalVariableSet(EncodeAZ("mdddate") + _symbol + EA_Name, (double)dd_date);
}

void SaveAvgSpread(double new_spread, datetime new_date)
{
   GlobalVariableSet(EncodeAZ("avgsprd") + _symbol + EA_Name, new_spread);
   GlobalVariableSet(EncodeAZ("sprdupd") + _symbol + EA_Name, (double)new_date);
}

//+----------------------------------------+
//| Initialize                             |
//+----------------------------------------+
int OnInit()
{
   LoadVariable();

   if(isVIP)
   {
      show_avg_line = true;
   } else {
      datetime dtDecode = (datetime)(dateApprove - (acc_id * 7));
      int diff_days = (int)(TimeCurrent() / 86400) - (int)(dtDecode / 86400);
      if(diff_days >= 1 || diff_days < 0)
      {
         if(!CheckApproveAccount())
         {
            Print("Account not approved to use this EA.\nPlease contact LocalFX for more information.");
            return(INIT_FAILED);
         }   
      }
   }

   MustRemove = (int)MathCeil((Remove_At * Remove_Percent) / 100);
   FNC_Auto_Remove = Auto_Remove;
   Safe_DD_per = (double)MathAbs(Safe_DD) * -1;
   Safe_min_DD = Safe_DD_per;
   // if(Safe_min_DD >= 0)
   // {
   //    Safe_min_DD = -10;
   // }
   Notify_DD_per = (double)MathAbs(Notify_DD) * -1;
   _rebate = Acc_Rebate / Acc_Currency;
   point_avg = _Point * PipAdjust;
   isBoost = Boost_MODE;

   CreateAverageLine();

   // Panel Set Defaults from Inputs
   PanelX = InpPanelX;
   PanelY = InpPanelY;
   PanelMinX = InpPanelX;
   PanelMinY = InpPanelY;

   LoadGlobalPanel();
   CreateLabel();

   return (INIT_SUCCEEDED);
}

//+----------------------------------------+
//| De-Initialize                          |
//+----------------------------------------+
void OnDeinit(const int reason)
{
   if(ObjectFind(0, avgBuy) != -1)
      ObjectDelete(0, avgBuy);
   if(ObjectFind(0, infoBuy) != -1)
      ObjectDelete(0, infoBuy);
   if(ObjectFind(0, avgSell) != -1)
      ObjectDelete(0, avgSell);
   if(ObjectFind(0, infoSell) != -1)
      ObjectDelete(0, infoSell);

   GlobalVariableSet(EncodeAZ("pnismd") + _symbol + EA_Name, AppWindow.IsMinimized());
   
   AppWindow.Destroy(reason);
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 0); 

   Comment("");
}

//+----------------------------------------+
//| On Tick                                |
//+----------------------------------------+
void OnTick()
{
   // if(TimeLocal() >= D'2026.01.12 00:00' || accountType == ACCOUNT_TRADE_MODE_REAL)
   // {
   //    return;
   // }

   acc_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   acc_profit = AccountInfoDouble(ACCOUNT_PROFIT);

   if (acc_profit < maxDrawDown)
   {
      maxDrawDown = acc_profit;
      maxDD_Per = (maxDrawDown / acc_balance) * 100;
      maxDD_Date = TimeCurrent();
      SaveMaxDrawDown(maxDrawDown, maxDD_Per, maxDD_Date);
   }
   curDrawDown = acc_profit < 0 ? acc_profit : 0;
   curDD_Per = (acc_profit / acc_balance) * 100;

   _ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
   _bid = SymbolInfoDouble(_symbol, SYMBOL_BID);

   AverageSpread();
   ResetProfitParams();
   UpdateTotalsInPoints();
   NotifyFeatures();
   if(!CurrentStateMinimized) AppWindow.UpdateData();
   UpdateAverageLine();
   ShowComment();
   // return;

   if(_spread > (avg_spread + (3 * _point)))
   {
      return;
   }

   if(!isBoost)
   {
      if (CloseSideIfTargetReached())
      {
         return;
      }
   }

   if (totalOrders >= Remove_At && FNC_Auto_Remove)
   {
      AutomaticCloseOrders();
   }

   if (!(Limit_Order && totalOrders >= LimitAmount))
   {
      CheckAndOpenOrders();
   }
}

//+----------------------------------------+
//| UI functions                           |
//+----------------------------------------+
// ----- [Event]
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   AppWindow.ChartEvent(id,lparam,dparam,sparam);

   if (id == CHARTEVENT_OBJECT_CLICK)
   {
      // Check for Click on Caption
      if(StringFind(sparam, "Caption") >= 0)
         AppWindow.ProcessCaptionClick();

      // Check for Click on ClearDD Label
      if(StringFind(sparam, "ClearDD") >= 0)
      {
         SaveMaxDrawDown(0, 0, 0);
         maxDrawDown = 0;
         maxDD_Per = 0;
         maxDD_Date = 0;
      }
   }

   // Check current state after event processing
   bool isMin = AppWindow.IsMinimized();

   // --- CASE 1: State Change (Toggle Button Clicked) ---
   if(isMin != CurrentStateMinimized)
   {
      CurrentStateMinimized = isMin;
      GlobalVariableSet(EncodeAZ("pnismd") + _symbol + EA_Name, CurrentStateMinimized);
      
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
               GlobalVariableSet(EncodeAZ("pnminx") + _symbol + EA_Name, PanelMinX);
               GlobalVariableSet(EncodeAZ("pnminy") + _symbol + EA_Name, PanelMinY);
            }
         }
         else
         {
            // IF MOVED while Maximized
            if(currentX != PanelX || currentY != PanelY)
            {
               PanelX = currentX;
               PanelY = currentY;
               GlobalVariableSet(EncodeAZ("pnmaxx") + _symbol + EA_Name, PanelX);
               GlobalVariableSet(EncodeAZ("pnmaxy") + _symbol + EA_Name, PanelY);
            }
         }
      }
   }
}
// ----- [Event]

// ----- [Label]
void CreateLabel()
{
   int startX = CurrentStateMinimized ? PanelMinX : PanelX;
   int startY = CurrentStateMinimized ? PanelMinY : PanelY;

   // 5. Create Panel (Increased Height for Monthly/Yearly)
   if(!AppWindow.Create(0, EA_Name ,0,startX,startY,startX+380,startY+680))
      return;
      
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
}
// ----- [Label]

// ----- [Spread]
void AverageSpread()
{
   datetime curDate = TimeCurrent();
   int date_diff = (int)(curDate - spread_date);
   // Print("curDate = ",curDate," | spread_date = ",spread_date," | date_diff = ",date_diff);

   _spread = MathAbs(_ask - _bid);

   bool is_backtesting = (MQLInfoInteger(MQL_TESTER) == 1);
   bool is_optimizing  = (MQLInfoInteger(MQL_OPTIMIZATION) == 1);

   if(is_backtesting || is_optimizing)
   {
      if(_spread > (avg_spread + (3 * _point)) && avg_spread > 0 && date_diff < 7200)
      {
         return;
      }
   } else {
      if(_spread > (avg_spread + (3 * _point)) && avg_spread > 0)
      {
         return;
      }
   }
   
   sum_spread += _spread;
   count_spread++;

   avg_spread = sum_spread / count_spread;

   if(date_diff >= 3600) // Save every 1 Hour
   {
      spread_date = curDate;
      SaveAvgSpread(avg_spread, curDate);
      sum_spread   = 0;
      count_spread = 0;
   }
}
// ----- [Spread]

// ----- [Average]
void CreateAverageLine()
{
   if (show_avg_line)
   {
      // --- Buy ---
      if (ObjectFind(0, avgBuy) != -1)
         ObjectDelete(0, avgBuy);

      if (ObjectFind(0, infoBuy) != -1)
         ObjectDelete(0, infoBuy);

      // avg line
      ObjectCreate(0, avgBuy, OBJ_HLINE, 0, 0, 0.00);
      ObjectSetInteger(0, avgBuy, OBJPROP_WIDTH, buy_line_width);
      ObjectSetInteger(0, avgBuy, OBJPROP_COLOR, buy_line_color);

      // // text info
      // ObjectCreate(0, infoBuy, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_buy_price);
      // ObjectSetString(0, infoBuy, OBJPROP_TEXT, "-");
      // ObjectSetInteger(0, infoBuy, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
      // ObjectSetInteger(0, infoBuy, OBJPROP_COLOR, White);
      // ObjectSetInteger(0, infoBuy, OBJPROP_FONTSIZE, font_info_size);
      // ObjectSetString(0, infoBuy, OBJPROP_FONT, "Arial");

      // --- Sell ---
      if (ObjectFind(0, avgSell) != -1)
         ObjectDelete(0, avgSell);

      if (ObjectFind(0, infoSell) != -1)
         ObjectDelete(0, infoSell);

      // avg line
      ObjectCreate(0, avgSell, OBJ_HLINE, 0, 0, 0.00);
      ObjectSetInteger(0, avgSell, OBJPROP_WIDTH, sell_line_width);
      ObjectSetInteger(0, avgSell, OBJPROP_COLOR, sell_line_color);

      // // text info
      // ObjectCreate(0, infoSell, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_sell_price);
      // ObjectSetString(0, infoSell, OBJPROP_TEXT, "-");
      // ObjectSetInteger(0, infoSell, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      // ObjectSetInteger(0, infoSell, OBJPROP_COLOR, White);
      // ObjectSetInteger(0, infoSell, OBJPROP_FONTSIZE, font_info_size);
      // ObjectSetString(0, infoSell, OBJPROP_FONT, "Arial");
   }
}

void UpdateAverageLine()
{
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   // Print("tick_value = ",tick_value," | tick_size = ",tick_size);
   // --- Avg Buy
   double Buy_distance = 0;
   if (countBuy > 0 && sumLotBuy != 0)
   {
      Buy_distance = (currentBuyProfit / (MathAbs(sumLotBuy * tick_value))) * tick_size;
      Average_buy_price = _bid - Buy_distance;
   }

   if (show_avg_line)
   {
      // update avg line
      ObjectSetDouble(0, avgBuy, OBJPROP_PRICE, Average_buy_price);

      // // update text info
      // ObjectCreate(0, infoBuy, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_buy_price);
      // ObjectSetString(0, infoBuy, OBJPROP_TEXT,
      //                 StringFormat("[B]= %.*f | %.1f pips (%.2f %s) Lots= %.2f Orders= %d",
      //                              _digits, Average_buy_price,
      //                              Buy_distance / point_avg,
      //                              currentBuyProfit,
      //                              AccountInfoString(ACCOUNT_CURRENCY),
      //                              sumLotBuy, countBuy));
   }

   // --- Avg Sell
   double Sell_distance = 0;
   if (countSell > 0 && sumLotSell != 0)
   {
      Sell_distance = (currentSellProfit / (MathAbs(sumLotSell * tick_value))) * tick_size;
      Average_sell_price = _ask + Sell_distance;
   }

   if (show_avg_line)
   {
      // update avg line
      ObjectSetDouble(0, avgSell, OBJPROP_PRICE, Average_sell_price);

      // // update text info
      // ObjectCreate(0, infoSell, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_sell_price);
      // ObjectSetString(0, infoSell, OBJPROP_TEXT,
      //                 StringFormat("[S]= %.*f | %.1f pips (%.2f %s) Lots= %.2f Orders= %d",
      //                              _digits, Average_sell_price,
      //                              Sell_distance / point_avg,
      //                              currentSellProfit,
      //                              AccountInfoString(ACCOUNT_CURRENCY),
      //                              sumLotSell, countSell));
   }

   double dummy_avg_buy = Average_buy_price <= 0 ? _bid : Average_buy_price;
   double dummy_avg_sell = Average_sell_price <= 0 ? _ask : Average_sell_price;

   Cur_avg_diff = MathAbs(dummy_avg_buy - dummy_avg_sell) / _Point;
}
// ----- [Average]

//+------------------------------------------------------------------+
//| Trading functions                                                |
//+------------------------------------------------------------------+
// ----- [Trading]
bool CheckSafeMode()
{
   if(Safe_Type != "")
   {
      if(curDD_Per >= Safe_min_DD) 
      {
         Safe_Type = "";
         return false;
      }
      return true;

   } else {
      if (curDD_Per <= Safe_DD_per && Safe_DD > 0)
      {
         return true;
      } 
      return false;
   }
}

double GetPositionCommission(long position_id)
{
   double commission = 0;
   
   if(HistorySelectByPosition(position_id))
   {
      int deals = HistoryDealsTotal();
      
      for(int i = 0; i < deals; i++)
      {
         ulong deal_ticket = HistoryDealGetTicket(i);
         if(deal_ticket > 0)
         {
            double deal_commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
            commission += deal_commission;
         }
      }
   }
   // Print("posID : ",position_id," | commission : ",commission);
   return commission;
}

void UpdateTotalsInPoints()
{
   const int total = PositionsTotal();

   bool OpenSafeMode = Safe_MODE ? CheckSafeMode() : false;
   isBoost = OpenSafeMode ? false : Boost_MODE;

   //--- open positions
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (!PositionSelectByTicket(ticket))
         continue;

      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      long posID = PositionGetInteger(POSITION_IDENTIFIER);
      // double posProfit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + GetPositionCommission(posID);
      double posProfit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double volume = PositionGetDouble(POSITION_VOLUME);

      // loss (-)
      if (posProfit < 0)
      {
         highest_loss = highest_loss == 0 ? posProfit : posProfit < highest_loss ? posProfit
                                                                                 : highest_loss;
         if(OpenSafeMode)
         {
            int posTicket = (int)ticket;
            InsertArraySorted(arrSafeLoss, "ASC", posTicket, (int)type, volume, price, posProfit, PositionGetDouble(POSITION_SWAP));
         }
      }
      // profit (+)
      else if (posProfit > 0)
      {
         highest_profit = highest_profit == 0 ? posProfit : posProfit > highest_profit ? posProfit
                                                                                       : highest_profit;
         if(OpenSafeMode)
         {
            int posTicket = (int)ticket;
            AddKeyValue(arrSafeProfit, posTicket, (int)type, volume, price, posProfit, PositionGetDouble(POSITION_SWAP));
            if (type == POSITION_TYPE_BUY)
            {
               SafeBuyProfit += posProfit;
            } 
            else if (type == POSITION_TYPE_SELL)
            {
               SafeSellProfit += posProfit;
            }
         }
      }

      if (type == POSITION_TYPE_BUY)
      {
         sumLotBuy += volume;
         currentBuyProfit += posProfit;
         countBuy++;
      }
      else if (type == POSITION_TYPE_SELL)
      {
         sumLotSell += volume;
         currentSellProfit += posProfit;
         countSell++;
      }

      TotalLot += volume;
      totalOrders++;

      // --- Martingel IN Loop
      maxLot = volume > maxLot ? volume : maxLot;
      top_price = top_price == 0 ? price : price > top_price ? price
                                                             : top_price;
      bottom_price = bottom_price == 0 ? price : price < bottom_price ? price
                                                                      : bottom_price;

      if (volume > Lot_Size)
      {
         Stack_biglot++;
      }
   }

   // --- Casual
   NetProfitTotal = currentBuyProfit + currentSellProfit;

   // --- Safe Mode
   if(OpenSafeMode)
   {
      if(countBuy > countSell)
      {
         Safe_Type = "buy";
      } 
      else if(countSell > countBuy)
      {
         Safe_Type = "sell";
      }

      ArrayResize(arrSafeLoss, 20);
      for (int i = 0; i < ArraySize(arrSafeLoss); i++)
      {
         SafeSumLoss += arrSafeLoss[i].profit;
      }
   }

   // --- Martingel OUT Loop
   middle_price = (top_price + bottom_price) / 2;
   range_price = (top_price - bottom_price) / _point;
   Highest_stack = Stack_biglot > Highest_stack ? Stack_biglot : Highest_stack;

   if (Avg_dist_should_be == 0 && (countBuy >= Martingel_at || countSell >= Martingel_at))
   {
      lock_range = range_price;
      Avg_dist_should_be = range_price * 0.1;
   }
}

bool CloseSideIfTargetReached()
{
   bool closeBuys = (currentBuyProfit >= Target);
   bool closeSells = (currentSellProfit >= Target);

   if(isBoost)
   {
      closeBuys = countBuy <= 15 ? (currentBuyProfit >= (Target * Risk_level)) : closeBuys;
      closeSells = countSell <= 15 ? (currentSellProfit >= (Target * Risk_level)) : closeSells;
   }

   if(Safe_Type != "")
   {
      if(CloseTargetSafeMode())
      {
         return false;
      }

      if(Safe_Type == "buy")
      {
         closeBuys = currentBuyProfit >= 0;
         closeSells = false;
      }
      else if(Safe_Type == "sell")
      {
         closeBuys = false;
         closeSells = currentSellProfit >= 0;
      }
   }
   
   if (!closeBuys && !closeSells)
   {
      return false;
   }

   MqlTick         tick;

   if(!SymbolInfoTick(_Symbol, tick))
   {
      Print("CST: Failed to get tick");
      return false;
   }

   const int total = PositionsTotal();

   for (int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (!PositionSelectByTicket(ticket))
         continue;

      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if ((type == POSITION_TYPE_BUY && closeBuys) ||
          (type == POSITION_TYPE_SELL && closeSells))
      {
         double volume = PositionGetDouble(POSITION_VOLUME);
         double price = (type == POSITION_TYPE_BUY)
                            ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                            : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);

         request.action = TRADE_ACTION_DEAL;
         request.symbol = _Symbol;
         request.volume = volume;
         request.deviation = 5;
         request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         request.price = price;
         request.position = ticket;
         request.type_filling = ORDER_FILLING_IOC;
         request.comment = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;

         if (!OrderSend(request, result))
            PrintFormat("CloseSideIfTargetReached: close failed, ticket=%I64u retcode=%d comment=%s",
                        ticket, result.retcode, result.comment);
      }
   }

   Avg_dist_should_be = 0;
   return true;
}

bool CloseTargetSafeMode()
{
   double diff_profit = 0;

   if(Safe_Type == "buy")
   {
      diff_profit = SafeSellProfit + SafeSumLoss;
   } 
   else if(Safe_Type == "sell")
   {
      diff_profit = SafeBuyProfit + SafeSumLoss;
   }

   if(diff_profit >= Target)
   {
      int safe_removed = 0;

      for (int i = 0; i < ArraySize(arrSafeLoss); i++)
      {
         if (ClosePositionByTicket(arrSafeLoss[i].ticket, arrSafeLoss[i].lotsize))
         {
            safe_removed++;
         }
      }
      for (int i = 0; i < ArraySize(arrSafeProfit); i++)
      {
         if(Safe_Type == "buy" && arrSafeProfit[i].type == POSITION_TYPE_BUY)
         {
            continue;
         } 
         else if (Safe_Type == "sell" && arrSafeProfit[i].type == POSITION_TYPE_SELL)
         {
            continue;
         }

         if (ClosePositionByTicket(arrSafeProfit[i].ticket, arrSafeProfit[i].lotsize))
         {
            safe_removed++;
         }
      }
      

      Avg_dist_should_be = 0;
      return true;
   }

   return false;
}

void CheckAndOpenOrders()
{
   const ENUM_TIMEFRAMES currentTf = (ENUM_TIMEFRAMES)Time_frame;
   const datetime currentBarOpen = iTime(_Symbol, currentTf, 0);
   const datetime lastOrderOpen = GetLatestOrderOpenTime();

   // PrintFormat("DEBUG: TF=%d currentBarOpen=%s lastOrderOpen=%s",
   //             currentTf,
   //             TimeToString(currentBarOpen, TIME_DATE | TIME_SECONDS),
   //             TimeToString(lastOrderOpen, TIME_DATE | TIME_SECONDS));

   if (lastOrderOpen >= currentBarOpen)
   {
      // Print("DEBUG: Skip open – lastOrderOpen >= currentBarOpen");
      return;
   }

   if(isBoost)
   {
      if (CloseSideIfTargetReached())
      {
         return;
      }
   }

   if(!Allow_Buy && !Allow_Sell)
   {
      return;
   }
   
   if (Martingel_MODE && (countBuy >= Martingel_at || countSell >= Martingel_at))
   {
      MartingelCondition();
   }
   else
   {
      double Lot_buy = Lot_Size;
      double Lot_sell = Lot_Size;

      if(isBoost)
      {
         Lot_buy = countBuy < 15 ? Lot_Size * Risk_level : Lot_Size;
         Lot_sell = countSell < 15 ? Lot_Size * Risk_level : Lot_Size;
      }

      OpenPairOrders(Lot_buy, Lot_sell);
   }
}

void OpenPairOrders(const double lot_buy, const double lot_sell)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   MqlTick         tick;

   if(!SymbolInfoTick(_Symbol, tick))
   {
      Print("OPO: Failed to get tick");
      return;
   }

   if(Allow_Buy)
   {
      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _Symbol;
      request.volume = lot_buy;
      request.deviation = 5;
      request.type = ORDER_TYPE_BUY;
      request.price = NormalizeDouble(tick.ask, _Digits);
      request.type_filling = ORDER_FILLING_IOC;
      request.comment = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;
      if (!OrderSend(request, result))
         PrintFormat("Buy OrderSend failed. retcode=%d comment=%s",
                     result.retcode, result.comment);
   }

   if(Allow_Sell)
   {
      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _Symbol;
      request.volume = lot_sell;
      request.deviation = 5;
      request.type = ORDER_TYPE_SELL;
      request.price = NormalizeDouble(tick.bid, _Digits);
      request.type_filling = ORDER_FILLING_IOC;
      request.comment = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;
      if (!OrderSend(request, result))
         PrintFormat("Sell OrderSend failed. retcode=%d comment=%s",
                     result.retcode, result.comment);
   }
}

void OpenSingleOrder(ENUM_ORDER_TYPE type, double lot)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   MqlTick         tick;

   if(!SymbolInfoTick(_Symbol, tick))
   {
      Print("OSO: Failed to get tick");
      return;
   }
   
   ZeroMemory(request);
   ZeroMemory(result);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot;
   request.deviation = 5;
   request.type = type;
   if(type == ORDER_TYPE_BUY)
   {
      request.price = NormalizeDouble(tick.ask, _Digits);
   } 
   else if(type == ORDER_TYPE_SELL) 
   {
      request.price = NormalizeDouble(tick.bid, _Digits);
   }
   request.type_filling = ORDER_FILLING_IOC;
   request.comment = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;
   if (!OrderSend(request, result))
      PrintFormat("Buy OrderSend failed. retcode=%d comment=%s",
                  result.retcode, result.comment);
}

void MartingelCondition()
{
   int _dist_every = (int)(range_price / lock_range);

   if (countBuy >= Martingel_at)
   {
      double atlease_price = (bottom_price + (Avg_dist_should_be * _point));
      // Print("======= Stack_biglot: ", Stack_biglot, " | _dist_every", _dist_every);
      bool condition1 = _ask < Average_sell_price && _bid < Average_sell_price;
      bool condition2 = Stack_biglot < _dist_every;
      // bool condition2 = Average_sell_price < atlease_price;
      bool condition3 = Cur_avg_diff > Avg_dist_should_be;
      // Print("======= condition1: ", condition1, " | condition2: ", condition2, " | condition3: ", condition3);

      if (true && condition2 && condition3)
      {
         double newLot = CalculateBigLot("Buy");
         // Avg_dist_should_be = 0;
         OpenSingleOrder(ORDER_TYPE_BUY, newLot); 
      }
      else
      {
         OpenSingleOrder(ORDER_TYPE_BUY, Lot_Size);
      }

      OpenSingleOrder(ORDER_TYPE_SELL, Lot_Size);
   }

   if (countSell >= Martingel_at)
   {
      double atlease_price = (top_price - (Avg_dist_should_be * _point));
      // Print("======= Stack_biglot: ", Stack_biglot, " | _dist_every", _dist_every);
      bool condition1 = _ask > Average_buy_price && _bid > Average_buy_price;
      bool condition2 = Stack_biglot < _dist_every;
      // bool condition2 = Average_sell_price < atlease_price;
      bool condition3 = Cur_avg_diff > Avg_dist_should_be;
      // Print("======= condition1: ", condition1, " | condition2: ", condition2, " | condition3: ", condition3);

      if (true && condition2 && condition3)
      {
         double newLot = CalculateBigLot("Sell");
         // Avg_dist_should_be = 0;
         OpenSingleOrder(ORDER_TYPE_SELL, newLot);
      }
      else
      {
         OpenSingleOrder(ORDER_TYPE_SELL, Lot_Size);
      }

      OpenSingleOrder(ORDER_TYPE_BUY, Lot_Size);
   }
}

void ShowComment()
{
   if (false)
   {
      Comment("\n ===================================== " + " MTGL every:  " + NumberFormat((string)Avg_start_mtgl) // 15,000
              + "    |    Diff Should be : " + NumberFormat((string)Avg_dist_should_be)                             // 15000*10%=1,500
              + "    |    Current : " + NumberFormat((string)Cur_avg_diff) + "    |    Lock : " + NumberFormat((string)lock_range) 
              + "\n ===================================== " 
              + " Top:  " + NumberFormat((string)top_price) + "    |    Bottom:  " + NumberFormat((string)bottom_price) + "    |    Middle price:  " + NumberFormat((string)middle_price) + "    |    Range price:  " + NumberFormat((string)range_price) 
              + "\n ===================================== " + " Highest Lot: " + DoubleToString(maxLot, 2) + "    |    Stack:  " + (string)Stack_biglot + " / " + (string)Highest_stack
              + "\n =====================================  Safe_Type : " + Safe_Type + " | Min_DD : " + (string)Safe_min_DD 
              + "\n =====================================  Safe_Arr : " + (string)ArraySize(arrSafeLoss) + " | Loss : " + (string)SafeSumLoss
            );
   }
}
// ----- [Trading]

// ----- [Helpers]
void ResetProfitParams()
{
   totalOrders = 0;
   countBuy = 0;
   countSell = 0;

   TotalLot = 0;
   sumLotBuy = 0;
   sumLotSell = 0;

   currentBuyProfit = 0.0;
   currentSellProfit = 0.0;
   NetProfitTotal = 0.0;

   ArrayResize(arrSafeLoss, 0);
   ArrayResize(arrSafeProfit, 0);
   SafeSumLoss = 0;
   SafeBuyProfit = 0;
   SafeSellProfit = 0;

   highest_loss = 0;
   highest_profit = 0;

   Average_buy_price = 0;
   Average_sell_price = 0;
   // Avg_dist_should_be   = 0;
   top_price = 0;
   bottom_price = 0;
   range_price = 0;
   middle_price = 0;
   Stack_biglot = 0;
}

void NotifyFeatures()
{
   if (!Notify_Email && !Notify_App)
   {
      return;
   }

   datetime curDate = TimeCurrent();
   bool send1 = false;
   bool send2 = false;

   // Notify -> Draw Down
   if (curDD_Per <= Notify_DD_per && Notify_DD > 0)
   {
      int noti_diff = (int)(curDate - lastNotify);
      if (noti_diff >= (int)Notify_Timer)
      {
         string topic = (string)acc_id + " [" + _symbol + "] Draw Down: " + (string)NormalizeDouble(curDD_Per, 2) + "% | " + EA_Name;
         string txtTimer = Notify_Timer < 3600 ? (string)((int)Notify_Timer / 60) + " นาที" : (string)((int)Notify_Timer / 3600) + " ชั่วโมง";
         string detail = "แจ้งเตือนอัตโนมัติทุกๆ " + txtTimer + " จาก EA " + EA_Name + " เมื่อมี Draw Down ต่ำกว่า -" + (string)Notify_DD + "%";
         string txtApp = "→ [" + _symbol + "] Draw Down: " + (string)NormalizeDouble(curDD_Per, 2) + "%\n" + detail;

         if (Notify_Email)
            SendMail(topic, detail);
         if (Notify_App)
            SendNotification(txtApp);

         send1 = true;
      }
   }
   // Notify -> Orders
   if (totalOrders >= Notify_Orders && Notify_Orders > 0)
   {
      int noti_diff = (int)(curDate - lastNotify);
      if (noti_diff >= (int)Notify_Timer)
      {
         string topic = (string)acc_id + " [" + _symbol + "] Opening orders: " + (string)totalOrders + " | " + EA_Name;
         string txtTimer = Notify_Timer < 3600 ? (string)((int)Notify_Timer / 60) + " นาที" : (string)((int)Notify_Timer / 3600) + " ชั่วโมง";
         string detail = "แจ้งเตือนอัตโนมัติทุกๆ " + txtTimer + " จาก EA " + EA_Name + " เมื่อเปิด order จำนวน " + (string)Notify_Orders + " หรือมากกว่า";
         string txtApp = "→ [" + _symbol + "] Opening orders: " + (string)totalOrders + "\n" + detail;

         if (Notify_Email)
            SendMail(topic, detail);
         if (Notify_App)
            SendNotification(txtApp);

         send2 = true;
      }
   }

   if (send1 || send2)
   {
      lastNotify = curDate;
      SaveLastNotificate((double)lastNotify);
   }
}

double CalculateBigLot(string type)
{
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double newLot = Lot_Size;
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step_lot = minLot;

   double dummy_avg_buy = Average_buy_price <= 0 ? _bid : Average_buy_price;
   double dummy_avg_sell = Average_sell_price <= 0 ? _ask : Average_sell_price;

   double exit_target = Avg_dist_should_be;
   bool first_time = true;
   double res = 0;

   if (type == "Buy")
   {
      while (res >= exit_target || first_time)
      {
         if (Limit_lot_size > 0 && newLot >= Limit_lot_size)
            return newLot;

         first_time = false;
         newLot += step_lot;
         double dummy_distance = (currentBuyProfit / (MathAbs((sumLotBuy + newLot) * tick_value))) * tick_size;
         double dummy_avg = _bid - dummy_distance;
         res = (dummy_avg - dummy_avg_sell) / _Point;
      }
      return newLot;
   }
   else if (type == "Sell")
   {
      while (res >= exit_target || first_time)
      {
         if (Limit_lot_size > 0 && newLot >= Limit_lot_size)
            return newLot;

         first_time = false;
         newLot += step_lot;
         double dummy_distance = (currentSellProfit / (MathAbs((sumLotSell + newLot) * tick_value))) * tick_size;
         double dummy_avg = _ask + dummy_distance;
         res = (dummy_avg_buy - dummy_avg) / _Point;
      }
      // Print("=== newLot:",newLot);
      return newLot;
   }

   return 0;
}

datetime GetLatestOrderOpenTime()
{
   datetime lastOpenTime = 0;

   const int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) &&
          PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
         if (openTime > lastOpenTime)
            lastOpenTime = openTime;
      }
   }

   if (lastOpenTime > 0)
      return (lastOpenTime);

   if (HistorySelect(0, TimeCurrent()))
   {
      const int historyTotal = HistoryOrdersTotal();
      for (int i = historyTotal - 1; i >= 0; i--)
      {
         ulong ticket = HistoryOrderGetTicket(i);
         if (HistoryOrderGetString(ticket, ORDER_SYMBOL) == _Symbol)
         {
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)HistoryOrderGetInteger(ticket, ORDER_TYPE);
            if (type == ORDER_TYPE_BUY || type == ORDER_TYPE_SELL)
            {
               datetime openTime = (datetime)HistoryOrderGetInteger(ticket, ORDER_TIME_SETUP);
               if (openTime > lastOpenTime)
                  lastOpenTime = openTime;
               break;
            }
         }
      }
   }
   return (lastOpenTime);
}

string NumberFormat(string val)
{
   string s = StringFormat("%.2f", MathAbs((double)val));
   int dot = StringFind(s, ".");
   for (int i = (dot == -1 ? StringLen(s) : dot) - 3; i > 0; i -= 3)
      s = StringSubstr(s, 0, i) + "," + StringSubstr(s, i);
   if ((double)val < 0)
      s = "-" + s;

   return s;
}

string EncodeAZ(string text)
{
   StringToLower(text);
   string out = "";

   for(int i = 0; i < StringLen(text); i++)
   {
      int c = StringGetCharacter(text, i);
      if(c >= 'a' && c <= 'z')
      {
         int v = c - 'a' + 1;
         out += StringFormat("%02d", v);
      }
   }
   return out;
}

string DecodeAZ(string code)
{
   string out = "";

   for(int i = 0; i + 1 < StringLen(code); i += 2)
   {
      int v = (int)StringToInteger(StringSubstr(code, i, 2));

      if(v >= 1 && v <= 26)
         out += CharToString((uchar)('a' + v - 1));
   }
   return out;
}
// ----- [Helpers]

// ----- [Condition]
bool CheckApproveAccount()
{
   bool is_backtesting = (MQLInfoInteger(MQL_TESTER) == 1);
   bool is_optimizing  = (MQLInfoInteger(MQL_OPTIMIZATION) == 1);

   if(is_backtesting || is_optimizing)
   {
      backtest_mode = "Yes";
   }

   updateValue   = realOrDemo + "," + server + "," + fullname + "," + broker; // Collect Data in 1 Line
   approve_account = gsheetDownloadUpload(gsheet_url, datasheets, keys, columes, updateValue, updateColumes);

   if(approve_account != "true")
   {
      SaveUserApprove(0);
      return false;
   } else {
      double dtEncode = (double)TimeCurrent() + (acc_id * 7);
      SaveUserApprove(dtEncode);
      dateApprove = dtEncode;
   }

   return true;
}
// ----- [Condition]

//+------------------------------------------------------------------+
//| Auto Close functions                                             |
//+------------------------------------------------------------------+
void AutomaticCloseOrders()
{
   if(highest_profit > 0)
   {
      ResetParams();
      double res = MathAbs(highest_loss) / highest_profit;
      if (res < 2)
      {
         ProcessCloseV2();
      }
      else
      {
         ProcessCloseV3();
      }
      ResetParams();
   }
}

bool ClosePositionByTicket(int ticket, double lots)
{
   if (!PositionSelectByTicket(ticket))
      return (false);

   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double price = (type == POSITION_TYPE_BUY)
                      ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                      : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lots;
   request.price = price;
   request.deviation = Slippage;
   request.position = ticket;
   request.type = (type == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
   request.type_filling = ORDER_FILLING_IOC;
   request.comment = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;

   if (!OrderSend(request, result))
   {
      PrintFormat("ClosePositionByTicket failed ticket=%d retcode=%d comment=%s",
                  ticket, result.retcode, result.comment);
      return (false);
   }
   return (true);
}

void ResetParams()
{
   ArrayResize(arrLoss, 0);
   ArrayResize(arrProfit, 0);
   ArrayResize(arrDelete, 0);
   removed = 0;
   removed_buy = 0;
   removed_sell = 0;

   lossTotal = 0;
   lossTotal2 = 0;
   profitTotal = 0;
   profitTotal2 = 0;
   swapTotal = 0;

   money_after_closed = 0; // V2
   netTotal = 0;           // V3
}

//+------------------------------------------------------------------+
//| Process Auto Close V2 Logic                                      |
//+------------------------------------------------------------------+
void ProcessCloseV2()
{
   string txt_name = EA_Name + " | Type: 2";
   int first_count_profit = 0;
   // -------------------------------------------------------
   // ( 1 ) This loop for get all loss profit(-).
   // -------------------------------------------------------
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if (posType == POSITION_TYPE_BUY || posType == POSITION_TYPE_SELL)
      {
         double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         // loss (-)
         if (profit < 0)
         {
            int posTicket = (int)ticket;
            double price = PositionGetDouble(POSITION_PRICE_OPEN);
            double lots = PositionGetDouble(POSITION_VOLUME);
            double swap = PositionGetDouble(POSITION_SWAP);
            InsertArraySorted(arrLoss, "ASC", posTicket, (int)posType, lots, price, profit, swap);
         }
         else if (profit > 0)
         {
            first_count_profit++;
         }
      }
   }
   if (first_count_profit == 0)
   {
      return;
   }
   // -----------
   // ( 1 ) END
   // -----------

   for (int j = 0; j < ArraySize(arrLoss); j++)
   {
      int big_loss_ticket = arrLoss[j].ticket;
      int big_loss_type = arrLoss[j].type;
      double big_loss_price = arrLoss[j].price;
      double big_loss_profit = arrLoss[j].profit;
      double big_loss_swap = arrLoss[j].swap;
      double big_loss_lot = arrLoss[j].lotsize;
      bool going = true;

      // ------------------------------------------------------------------------------
      // ( 2 ) This loop for put all profit(+) orders to array.
      //       Process : put all data in array by sort profit(+) DESC.
      //       * make it ready to DELETE in next step( 3 )
      // ------------------------------------------------------------------------------

      ArrayResize(arrProfit, 0);
      double sum_all_profit = 0;

      for (int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if (ticket == 0 || !PositionSelectByTicket(ticket))
            continue;

         if (PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;

         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if (posType == POSITION_TYPE_BUY || posType == POSITION_TYPE_SELL)
         {
            double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            // profit (+)
            if (profit > 0)
            {
               int posTicket = (int)ticket;
               double price = PositionGetDouble(POSITION_PRICE_OPEN);
               double lots = PositionGetDouble(POSITION_VOLUME);
               double swap = PositionGetDouble(POSITION_SWAP);
               sum_all_profit = sum_all_profit + profit;
               InsertArraySorted(arrProfit, "DESC", posTicket, (int)posType, lots, price, profit, swap);
            }
         }
      }
      // -----------
      // ( 2 ) END
      // -----------

      // -------------------------------------------------------------------------------------
      // ( 3 ) This loop for sum many profit in arry( 2 ) to compare with BIG LOSS( 1 ),
      //       until profit(+) is enough for BIG LOSS(-). Then start delete orders.
      //
      //       Condition is start from highest profit(+) first.
      // -------------------------------------------------------------------------------------

      double compare_profit = 0;
      KeyValue arrDummy[];

      for (int i = 0; i < ArraySize(arrProfit); i++)
      {
         compare_profit = compare_profit + arrProfit[i].profit;
         AddKeyValue(arrDummy, arrProfit[i].ticket, arrProfit[i].type, arrProfit[i].lotsize, arrProfit[i].price, arrProfit[i].profit, arrProfit[i].swap);

         // Profit is enough for MONEY_AFTER_CLOSED (included BIG LOSS)
         if (compare_profit > MathAbs(big_loss_profit + money_after_closed))
         {
            // Print("------ Break because enough -----");
            break;
         }

         // Until the last order(+)
         if ((i == ArraySize(arrProfit) - 1))
         {
            // but profit isn't enough for MONEY_AFTER_CLOSED (included BIG LOSS)
            // if((compare_profit + big_loss_profit + money_after_closed) < 0)
            if ((big_loss_profit + money_after_closed) < compare_profit)
            {
               // Print("------ Stop because enough by last order -----");
               ArrayResize(arrDummy, 0);
               going = false;
            }
            compare_profit = 0;
         }
      }

      if (!going)
      {
         continue;
      }

      if (ArraySize(arrDummy) > 0)
      {

         // Put BIG LOSS(-) and many profit orders(+) in arrDelete
         AddKeyValue(arrDelete, big_loss_ticket, big_loss_type, big_loss_lot, big_loss_price, big_loss_profit, big_loss_swap);
         lossTotal = lossTotal + big_loss_profit;
         swapTotal = swapTotal + big_loss_swap;
         // Print("==> (-) Tick : "+big_loss_ticket+" Profit : "+big_loss_profit);
         for (int i = 0; i < ArraySize(arrDummy); i++)
         {
            AddKeyValue(arrDelete, arrDummy[i].ticket, arrDummy[i].type, arrDummy[i].lotsize, arrDummy[i].price, arrDummy[i].profit, arrDummy[i].swap);
            profitTotal = profitTotal + arrDummy[i].profit;
            swapTotal = swapTotal + arrDummy[i].swap;
            // Print("==> (+) Tick : "+arrDummy[i].ticket+" Profit : "+arrDummy[i].profit);
         }

         // Start delete order 1 by 1
         for (int i = 0; i < ArraySize(arrDelete); i++)
         {
            if (ClosePositionByTicket(arrDelete[i].ticket, arrDelete[i].lotsize))
            {
               if (arrDelete[i].type == POSITION_TYPE_BUY)
                  removed_buy++;
               else if (arrDelete[i].type == POSITION_TYPE_SELL)
                  removed_sell++;

               removed++;
               // Print("Remove order [" + IntegerToString(arrDelete[i].ticket) + "] success!");
            }
            else
            {
               // Print("Cannot remove order [" + IntegerToString(arrDelete[i].ticket) + "]");
            }
         }
      }

      // Print("Debug --- "+profitTotal+" "+lossTotal+" = "+money_after_closed);
      ArrayResize(arrDummy, 0);
      ArrayResize(arrDelete, 0);

      if (removed >= MustRemove)
      {
         break;
      }

      // -----------
      // ( 3 ) END
      // -----------
   }

   // -------------------------------------------------------------------------------------------------------
   // ( 4.1 ) Last step if got Profit(+) after closed [Too much profit], remove more to make it equal zero(0)
   // -------------------------------------------------------------------------------------------------------
   money_after_closed = profitTotal + lossTotal;
   string txtLoss = "";
   string txtProfit = "";
   if (money_after_closed > 0)
   {
      double sum_all_loss = 0;
      ArrayResize(arrLoss, 0);

      for (int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if (ticket == 0 || !PositionSelectByTicket(ticket))
            continue;

         if (PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;

         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if (posType == POSITION_TYPE_BUY || posType == POSITION_TYPE_SELL)
         {
            double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            // loss (-)
            if (profit < 0)
            {
               sum_all_loss = sum_all_loss + profit;

               if (MathAbs(sum_all_loss) <= money_after_closed)
               {
                  int posTicket = (int)ticket;
                  double price = PositionGetDouble(POSITION_PRICE_OPEN);
                  double lots = PositionGetDouble(POSITION_VOLUME);
                  double swap = PositionGetDouble(POSITION_SWAP);

                  lossTotal2 = lossTotal2 + profit;
                  InsertArraySorted(arrLoss, "ASC", posTicket, (int)posType, lots, price, profit, swap);
               }
               else
               {
                  sum_all_loss = sum_all_loss - profit;
               }
            }
         }
      }

      // Start delete order 1 by 1
      for (int i = 0; i < ArraySize(arrLoss); i++)
      {
         if (ClosePositionByTicket(arrLoss[i].ticket, arrLoss[i].lotsize))
         {
            if (arrLoss[i].type == POSITION_TYPE_BUY)
               removed_buy++;
            else if (arrLoss[i].type == POSITION_TYPE_SELL)
               removed_sell++;

            removed++;
         }
      }
      money_after_closed = profitTotal + lossTotal + lossTotal2;
      txtLoss = ", " + DoubleToString(lossTotal2, 2);
   }

   // -------------------------------------------------------------------------------------------------------
   // ( 4.2 ) Last step if got Loss(-) after closed [Too much loss], remove more to make it equal zero(0)
   // -------------------------------------------------------------------------------------------------------
   else if (money_after_closed < 0)
   {
      double sum_all_profit = 0;
      ArrayResize(arrProfit, 0);

      for (int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if (ticket == 0 || !PositionSelectByTicket(ticket))
            continue;

         if (PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;

         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if (posType == POSITION_TYPE_BUY || posType == POSITION_TYPE_SELL)
         {
            double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            // profit (+)
            if (profit > 0)
            {
               double prev_sum = sum_all_profit;
               sum_all_profit = sum_all_profit + profit;
               if (sum_all_profit <= MathAbs(money_after_closed))
               {
                  int posTicket = (int)ticket;
                  double price = PositionGetDouble(POSITION_PRICE_OPEN);
                  double lots = PositionGetDouble(POSITION_VOLUME);
                  double swap = PositionGetDouble(POSITION_SWAP);
                  profitTotal2 = profitTotal2 + profit;
                  InsertArraySorted(arrProfit, "DESC", posTicket, posType, lots, price, profit, swap);
               }
               else
               {
                  sum_all_profit = sum_all_profit - profit;
               }
            }
         }
      }

      // Start delete order 1 by 1
      for (int i = 0; i < ArraySize(arrProfit); i++)
      {
         if (ClosePositionByTicket(arrProfit[i].ticket, arrProfit[i].lotsize))
         {
            if (arrProfit[i].type == POSITION_TYPE_BUY)
               removed_buy++;
            else if (arrProfit[i].type == POSITION_TYPE_SELL)
               removed_sell++;

            removed++;
         }
      }
      money_after_closed = profitTotal + lossTotal + profitTotal2;
      txtProfit = ", " + DoubleToString(profitTotal2, 2);
   }

   // -----------
   // ( 4 ) END
   // -----------
   Print(txt_name + " | Money result: Profit[" + DoubleToString(profitTotal, 2) + txtProfit + "] - Loss[" + DoubleToString(lossTotal, 2) + txtLoss + "] = Net[" + DoubleToString(money_after_closed, 2) + "] | Orders removed: Buy[" + IntegerToString(removed_buy) + "] + Sell[" + IntegerToString(removed_sell) + "] = Total[" + IntegerToString(removed) + "]");
}

//+------------------------------------------------------------------+
//| Process Auto Close V3 Logic                                      |
//+------------------------------------------------------------------+
void ProcessCloseV3()
{
   string txt_name = EA_Name + " | Type: 3";

   CreateDummy();

   double compare_loss = 0;

   for (int i = 0; i < ArraySize(arrLoss); i++)
   {
      compare_loss = compare_loss + arrLoss[i].profit;

      if (MathAbs(compare_loss) > profitTotal)
      {
         compare_loss = compare_loss - arrLoss[i].profit;
         // Print("+++ Enough : "+compare_loss+" ("+arrLoss[i].profit+") | "+profitTotal);
         break;
      }
      else
      {
         // Print("--- ["+i+"]["+compare_loss+"] put => "+arrLoss[i].profit);
         AddKeyValue(arrDelete, arrLoss[i].ticket, arrLoss[i].type, arrLoss[i].lotsize, arrLoss[i].price, arrLoss[i].profit, arrLoss[i].swap);
      }
   }

   if (ArraySize(arrDelete) > 0)
   {
      // Delete loss(-)
      for (int i = 0; i < ArraySize(arrDelete); i++)
      {
         if (ClosePositionByTicket(arrDelete[i].ticket, arrDelete[i].lotsize))
         {
            if (arrDelete[i].type == POSITION_TYPE_BUY)
               removed_buy++;
            else if (arrDelete[i].type == POSITION_TYPE_SELL)
               removed_sell++;

            lossTotal = lossTotal + arrDelete[i].profit;
            swapTotal = swapTotal + arrDelete[i].swap;
            // Print("Remove order [" + IntegerToString(arrDelete[i].ticket) + "] success!");
         }
         else
         {
            // Print("Cannot remove order [" + IntegerToString(arrDelete[i].ticket) + "]");
         }
      }

      // Delete profit(+)
      for (int i = 0; i < ArraySize(arrProfit); i++)
      {
         if (ClosePositionByTicket(arrProfit[i].ticket, arrProfit[i].lotsize))
         {
            if (arrProfit[i].type == POSITION_TYPE_BUY)
               removed_buy++;
            else if (arrProfit[i].type == POSITION_TYPE_SELL)
               removed_sell++;

            swapTotal = swapTotal + arrProfit[i].swap;
            // Print("Remove order [" + IntegerToString(arrProfit[i].ticket) + "] success!");
         }
         else
         {
            // Print("Cannot remove order [" + IntegerToString(arrProfit[i].ticket) + "]");
         }
      }
      netTotal = profitTotal + lossTotal;
      removed = removed_buy + removed_sell;
   }

   Print(txt_name + " | Money result: Profit[" + DoubleToString(profitTotal, 2) + "] - Loss[" + DoubleToString(lossTotal, 2) + "] = Net[" + DoubleToString(netTotal, 2) + "] | Orders removed: Buy[" + IntegerToString(removed_buy) + "] + Sell[" + IntegerToString(removed_sell) + "] = Total[" + IntegerToString(removed) + "]");
}

//----- [Helpers]
void CreateDummy()
{
   // Put loss(-) orders in 2D Array, And insert order by DESC
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if (posType == POSITION_TYPE_BUY || posType == POSITION_TYPE_SELL)
      {
         double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

         int posTicket = (int)ticket;
         double price = PositionGetDouble(POSITION_PRICE_OPEN);
         double lots = PositionGetDouble(POSITION_VOLUME);
         double swap = PositionGetDouble(POSITION_SWAP);

         // Profit orders(+) | Sum all profit
         if (profit > 0)
         {
            profitTotal = profitTotal + profit;
            AddKeyValue(arrProfit, posTicket, (int)posType, lots, price, profit, swap);
         }

         // Loss orders(-) | Put loss orders in array
         if (profit < 0)
         {
            InsertArraySorted(arrLoss, "DESC", posTicket, (int)posType, lots, price, profit, swap);
         }
      }
   }
}

void InsertArraySorted(KeyValue &arr[], string format, int ticket, int type, double lot, double price, double profit, double swap)
{
   KeyValue num;
   num.ticket = ticket;
   num.type = type;
   num.lotsize = lot;
   num.price = price;
   num.profit = profit;
   num.swap = swap;

   int size = ArraySize(arr);
   ArrayResize(arr, size + 1);

   int pos = size;

   if (format == "ASC")
   {
      for (int i = 0; i < size; i++)
      {
         if (num.profit < arr[i].profit)
         {
            pos = i;
            break;
         }
      }
   }
   else
   { // DESC
      for (int i = 0; i < size; i++)
      {
         if (num.profit > arr[i].profit)
         {
            pos = i;
            break;
         }
      }
   }

   for (int i = size; i > pos; i--)
      arr[i] = arr[i - 1];

   arr[pos] = num;
}
//----- [Helpers]