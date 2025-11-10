//+------------------------------------------------------------------+
//|                                             Test GoogleSheet.mq5 |
//|                               Copyright 2021, UU School trading. |
//|                                https://www.facebook.com/uutrader |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, UU School trading."
#property link      "https://www.facebook.com/uutrader"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#import "LibMT5Gsheet.ex5"
string gsheetDownloadUpload(string url,string datasheets, string keys, string columes, string updateValue, string updateColumes);
#import


int OnInit()
  {
   long   accountType   = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   string fullname      = AccountInfoString(ACCOUNT_NAME);
   string broker        = AccountInfoString(ACCOUNT_COMPANY);
   string server        = AccountInfoString(ACCOUNT_SERVER);
   string date_time     = TimeToString(TimeLocal(), TIME_DATE|TIME_SECONDS);
   string realOrDemo = "";
   string backtest_mode = "";

   if (accountType == ACCOUNT_TRADE_MODE_DEMO)
   {
      realOrDemo = "DEMO";
   }
   else if (accountType == ACCOUNT_TRADE_MODE_REAL)
   {
       realOrDemo = "REAL";
   }

   bool is_backtesting = (MQLInfoInteger(MQL_TESTER) == 1);
   bool is_optimizing  = (MQLInfoInteger(MQL_OPTIMIZATION) == 1);

   if(is_backtesting || is_optimizing)
   {
      backtest_mode = "Yes";
   }

   string gsheet_url    = "https://script.google.com/macros/s/AKfycbx09ATwfNpBfzAW0dCcYeSH5NdLKofLApZHq0Kvj9vQa5dw9Y3NYTv_VqIqR8YiYLyRkw/exec";
   string datasheets    = "MT5"; //Datasheet
   string keys          = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)); //Key
   string columes       = "3"; //Get(check) Data at column : C [ID]
   string updateValue   = realOrDemo + "," + backtest_mode + "," + server + "," + fullname + "," + broker; //Collect Data in 1 Line
   string updateColumes = "4"; //Send to column : D [AC Type]
   
   string result1 = gsheetDownloadUpload(gsheet_url, datasheets, keys, columes, updateValue, updateColumes);
   Alert(result1);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---
   
  }
//+------------------------------------------------------------------+
