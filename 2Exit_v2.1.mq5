//+------------------------------------------------------------------+
//|                                                   2Exit_v2.1.mq5 |
//|                                          Copyright 2025, LocalFX |
//|                               https://www.facebook.com/LocalFX4U |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, LocalFX"
#property link      "https://www.facebook.com/LocalFX4U"
#property version   "2.10"
#property strict

string Comp_Name     = "LocalFX";
string EA_Name       = "2Exit_v2.1";

long  MagicNumber    = 7020202;
int   Slippage       = 5;
// EU - TP:200 | DT:100 | Lot:0.05 | NetProfit:37% | MaxDD:30% | MaxOrder:8 | Session:Tokyo
// GU - TP:150 | DT:75 | Lot:0.05 | NetProfit:??% | MaxDD:??% | | MaxOrder:?? | Session:Tokyo
input double Start_lot     = 0.01;
double step_lot            = 0.01;
input int Target           = 5;
input int Distance         = 100;
bool Backtest_mode         = false;

int middle_space           = 0;
int _sl                    = 0;
int _distance              = 0;

double first_balance       = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_balance         = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_profit          = AccountInfoDouble(ACCOUNT_PROFIT);
double net_profit          = 0;
double net_profit_per      = 0;

double   _ask                 = 0;
double   _bid                 = 0;
double   _spread              = 0;
double   avg_spread           = 0;
double   sum_spread           = 0;
double   hst_spread           = 0;
int      count_spread         = 0;
int      totalOpening         = 0;
int      totalPending         = 0;
int      otherSymbolOpening   = 0;
int      otherSymbolPending   = 0;

// Indicator
int rsiHandle;

// Bigest Order
long              fst_order_time  = 0;
double            fst_order_lot   = 0;
ENUM_ORDER_TYPE   fst_order_type  = NULL;

long              fnl_order_time  = 0;
ENUM_ORDER_TYPE   fnl_order_type  = NULL;

// Buy
int    countBuy      = 0;
double sumLotBuy     = 0;
double fcProfitBuy   = 0;
double fcLossBuy     = 0;
double priceBuy      = 0;

// Sell
int    countSell     = 0;
double sumLotSell    = 0;
double fcProfitSell  = 0;
double fcLossSell    = 0;
double priceSell     = 0;

// Statistic
double maxLot        = 0;
double maxDrawDown   = 0;
double maxDD_Per     = 0;
int    maxOrders     = 0;

struct MarketTime
{
   string session;
   int open;
   int close;
};

MarketTime marketGMT[] = {
   {"London", 8, 16},
   {"Newyork", 13, 22},
   {"Tokyo", 0, 9}
};

struct KeyValue
{
   int ticket;
   int type;
   double lotsize;
};

void AddKeyValue(KeyValue &arr[], int ticket, int type, double lotsize)
{
   int size = ArraySize(arr);
   ArrayResize(arr, size + 1);

   arr[size].ticket = ticket;
   arr[size].type = type;
   arr[size].lotsize = lotsize;
}
KeyValue arrDelete[];

string gv_spread = EA_Name + "_Spread_" + _Symbol;

void LoadVariable()
{
   if(GlobalVariableCheck(gv_spread))
   {
      avg_spread = GlobalVariableGet(gv_spread);
   }
}

void SaveGlobalVariable()
{
   GlobalVariableSet(gv_spread, avg_spread);
}

int OnInit()
{
   bool is_backtesting = (MQLInfoInteger(MQL_TESTER) == 1);
   bool is_optimizing  = (MQLInfoInteger(MQL_OPTIMIZATION) == 1);
   Backtest_mode = is_backtesting || is_optimizing;
   if(!Backtest_mode)
   {
      EventSetTimer(3600); // 1 Hour
   }

   LoadVariable();

   if(_Digits == 3) {
      _distance = Distance / 5;
   } else if(_Digits == 4) {
      _distance = Distance / 7;
   } else if(_Digits == 5) {
      _distance = Distance;
   } else {
      _distance = Distance;
   }
   
   //Minimum_profit = _tp * Start_lot;
   middle_space = _distance * 2;

   //rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_MEDIAN);

   return(INIT_SUCCEEDED);
}

void OnTimer()
{
   SaveGlobalVariable();
   sum_spread   = 0;
   count_spread = 0;
}

void OnDeinit(const int reason)
{
   if(!Backtest_mode)
   {
      EventKillTimer();
      SaveGlobalVariable();
   }
}
double rsiValue[];
double currentRSI = 0;
double prevRSI = 0;
void OnTick()
{
   ArrayResize(rsiValue, 0);
   if(CopyBuffer(rsiHandle, 0, 0, 3, rsiValue) > 0)
   {
      currentRSI = rsiValue[0]; // RSI แท่งปัจจุบัน
      prevRSI    = rsiValue[1]; // RSI แท่งก่อนหน้า
   }
   
   
   acc_balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   acc_profit    = AccountInfoDouble(ACCOUNT_PROFIT);

   if(acc_profit < maxDrawDown)
   {
      maxDrawDown = acc_profit;
      maxDD_Per   = (maxDrawDown / acc_balance) * 100;
   }  

   _ask          = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   _bid          = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
   AverageSpread();
   ScanOrders();
   
   if(CheckTargetProfit())
   {
      return;
   }

   if(totalOpening == 0 && totalPending == 0) {
      if(CheckSignal())
      {
         double _Bprice =  _ask + (_distance * _Point);
         double _Sprice =  _bid - (_distance * _Point);
         PendingBuy(_Bprice, Start_lot, true);
         PendingSell(_Sprice, Start_lot, true);
      }
   } else if (totalOpening > 0 && totalPending == 0) {
      PendingNextLot();
   }

   net_profit       = acc_balance - first_balance;
   net_profit_per   = (net_profit / first_balance) * 100;
   ShowComment();
}

void ScanOrders()
{
   ResetParamiter();

   // ================= Opening Orders =================
   long   first_time_buy   = 0;
   double first_lot_buy    = 0;
   double first_price_buy  = 0;

   long   first_time_sell  = 0;
   double first_lot_sell   = 0;
   double first_price_sell = 0;

   for(int i = 0; i < PositionsTotal(); i++) // PositionsTotal() -> Opening
   {
      ulong ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(ticket))
      {
         string symbol = PositionGetString(POSITION_SYMBOL);
         long   magic  = PositionGetInteger(POSITION_MAGIC);
         if(symbol == _Symbol && magic == MagicNumber) {
            double lot           = PositionGetDouble(POSITION_VOLUME);
            double price         = PositionGetDouble(POSITION_PRICE_OPEN);
            double take_profit   = PositionGetDouble(POSITION_TP);
            double stop_loss     = PositionGetDouble(POSITION_SL);
            long   time_open     = PositionGetInteger(POSITION_TIME_MSC);
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);

            maxLot = lot > maxLot ? lot : maxLot;
            
            // FIRST order
            if(fst_order_time == 0) {
               fst_order_time = time_open;
               fst_order_lot  = lot;
               fst_order_type = type;
            } else if(time_open < fst_order_time) {
               fst_order_time = time_open;
               fst_order_lot  = lot;
               fst_order_type = type;
            }

            // Last/Final order
            if(fnl_order_time == 0) {
               fnl_order_time = time_open;
               fnl_order_type = type;
            } else if(time_open > fnl_order_time)
            {
               fnl_order_time  = time_open;
               fnl_order_type  = type;
            }

            if(type == ORDER_TYPE_BUY)
            {
               fcProfitBuy += ((take_profit - price) / _Point) * lot;
               fcLossBuy   += ((price - stop_loss) / _Point) * lot;
               
               if(first_time_buy == 0) {
                  first_time_buy     = time_open;
                  first_lot_buy      = lot;
                  first_price_buy    = price;
               } else {
                  if(time_open < first_time_buy) {
                     first_time_buy     = time_open;
                     first_lot_buy      = lot;
                     first_price_buy    = price;
                  }
               }

               sumLotBuy += lot;
               countBuy++;
               
            } else if(type == ORDER_TYPE_SELL) {
            
               fcProfitSell += ((price - take_profit) / _Point) * lot;
               fcLossSell   += ((stop_loss - price) / _Point) * lot;

               if(first_time_sell == 0) {
                  first_time_sell    = time_open;
                  first_lot_sell     = lot;
                  first_price_sell   = price;
               } else {
                  if(time_open < first_time_sell) {
                     first_time_sell    = time_open;
                     first_lot_sell     = lot;
                     first_price_sell   = price;
                  }
               }
               
               sumLotSell   += lot;
               countSell++;
            }

            /*PrintFormat("Ticket: %d | Symbol: %s | Type: %s | Price: %.5f",
                        ticket, symbol, EnumToString(type), price);*/
         } else {
            otherSymbolOpening++;
         }
      }
   }

   priceBuy  = first_price_buy;
   priceSell = first_price_sell;
   totalOpening  = (PositionsTotal() - otherSymbolOpening);
   maxOrders = totalOpening > maxOrders ? totalOpening : maxOrders;

   // ================= Pending Orders =================
   double          pending_lot   = 0;
   ENUM_ORDER_TYPE pending_type  = NULL;

   for(int i = 0; i < OrdersTotal(); i++) // OrdersTotal() -> Pending
   {
      ulong ticket = OrderGetTicket(i);
      
      if(OrderSelect(ticket))
      {
         string symbol = OrderGetString(ORDER_SYMBOL);
         string magic = OrderGetString(ORDER_SYMBOL);
         if(symbol == _Symbol && magic == magic) {
            pending_lot  = OrderGetDouble(ORDER_VOLUME_INITIAL);
            pending_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         } else {
            otherSymbolPending++;
         }
      }
   }
   totalPending    = (OrdersTotal() - otherSymbolPending);

   // ================= Remove pending leftover =================
   if((totalOpening == 1 && totalPending == 1) && (pending_lot == fst_order_lot)){
      ClearPending();
   }
}

bool CheckTargetProfit()
{
   if(acc_profit >= Target)
   {
      Print("==== Close by Target ====");
      ClearOpening();
      ClearPending();
      return true;
      
   }
   return false;
}

bool CheckSignal()
{
   if(isMarketOpen("Tokyo"))
   {
      return true;
   }
   return false;
}

void PendingNextLot()
{
   if(priceBuy == 0 && priceSell > 0)
   {
      priceBuy = priceSell + (middle_space * _Point);
   } else if(priceBuy > 0 && priceSell == 0) {
      priceSell = priceBuy - (middle_space * _Point);
   }

   // Check lot size -> then Do pending
   double lot_dummy  = 0;
   double _diff      = 0;
   if(fnl_order_type == ORDER_TYPE_BUY)
   {
      while (_diff < Start_lot)
      {
         lot_dummy = lot_dummy == 0 ? Start_lot : lot_dummy + step_lot;
         _diff     = (sumLotSell + lot_dummy) - sumLotBuy;
      }
      
      //Print("=== SELL Next Lot: "+DoubleToString(lot_dummy, 2));
      PendingSell(priceSell, lot_dummy, false);

   } else if(fnl_order_type == ORDER_TYPE_SELL) {

      while (_diff < Start_lot)
      {
         lot_dummy = lot_dummy == 0 ? Start_lot : lot_dummy + step_lot;
         _diff     = (sumLotBuy + lot_dummy) - sumLotSell;
      }
      
      //Print("=== BUY Next Lot: "+DoubleToString(lot_dummy, 2));
      PendingBuy(priceBuy, lot_dummy, false);
   }
}

void PendingBuy(double _price, double _lot, bool from_first)
{
   if((_ask + ((_distance / 2) * _Point)) > _price) return;

   double pending_price = from_first ? _price - avg_spread : _price;

   // prepare request/result
   MqlTradeRequest request;
   MqlTradeResult  result;
   MqlTradeCheckResult check;
   ZeroMemory(request);
   ZeroMemory(result);
   ZeroMemory(check);
   
   request.action       = TRADE_ACTION_PENDING;
   request.symbol       = _Symbol;
   request.volume       = _lot;
   request.type         = ORDER_TYPE_BUY_STOP;
   request.price        = NormalizeDouble(pending_price, _Digits);
   request.tp           = 0.0;
   request.sl           = 0.0;
   request.deviation    = Slippage;
   request.magic        = MagicNumber;
   request.type_filling = ORDER_FILLING_IOC;
   request.comment      = Comp_Name + " | " + EA_Name;
   
   // recommended: validate request before sending
   if(!OrderCheck(request,check))
   {
      PrintFormat("OrderCheck failed: retcode=%d comment=%s", check.retcode, check.comment);
      return;
      
   } else {
      // send order
      if(!OrderSend(request,result))
      {
         PrintFormat("OrderSend returned false - result.retcode=%d comment=%s", result.retcode, result.comment);
         return;
      }
   }
}

void PendingSell(double _price, double _lot, bool from_first)
{
   if((_bid - ((_distance / 2) * _Point)) < _price) return;

   double pending_price = from_first ? _price + avg_spread : _price;

   // prepare request/result
   MqlTradeRequest request;
   MqlTradeResult  result;
   MqlTradeCheckResult check;
   ZeroMemory(request);
   ZeroMemory(result);
   ZeroMemory(check);
   
   request.action       = TRADE_ACTION_PENDING;
   request.symbol       = _Symbol;
   request.volume       = _lot;
   request.type         = ORDER_TYPE_SELL_STOP;
   request.price        = NormalizeDouble(pending_price, _Digits);
   request.tp           = 0.0;
   request.sl           = 0.0;
   request.deviation    = Slippage;
   request.magic        = MagicNumber;
   request.type_filling = ORDER_FILLING_IOC;
   request.comment      = Comp_Name + " | " + EA_Name;
   
   // recommended: validate request before sending
   if(!OrderCheck(request,check))
   {
      PrintFormat("OrderCheck failed: retcode=%d comment=%s", check.retcode, check.comment);
      return;
      
   } else {
      // send order
      if(!OrderSend(request,result))
      {
         PrintFormat("OrderSend returned false - result.retcode=%d comment=%s", result.retcode, result.comment);
         return;
      }
   }
}

void ClearOpening()
{
   for(int i = 0; i < PositionsTotal(); i++) // PositionsTotal() -> Opening
   {
      string symbol = PositionGetString(POSITION_SYMBOL);
      if(symbol == _Symbol) {
         ulong ticket = PositionGetTicket(i);
         double lot  = PositionGetDouble(POSITION_VOLUME);
         long type   = PositionGetInteger(POSITION_TYPE);
         AddKeyValue(arrDelete, (int)ticket, (int)type, lot);
      }
   }
   // Put in array because "Protect from orders touched TP/SL before OrderSend()"
   for(int i = 0; i < ArraySize(arrDelete); i++)
   {
      double _price = 0;
      ENUM_ORDER_TYPE _type  = NULL;
      
      if(arrDelete[i].type == POSITION_TYPE_BUY)
      {
         _price = _bid; // Close BUY → set BID
         _type = ORDER_TYPE_SELL; // Close Buy should do Sell back
         
      } else if(arrDelete[i].type == POSITION_TYPE_SELL) {
      
         _price = _ask; // Close SELL → set ASK
         _type = ORDER_TYPE_BUY; // Close Sell should do Buy back
      }
      
      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);
      ZeroMemory(result);
      
      request.action       = TRADE_ACTION_DEAL;
      request.position     = arrDelete[i].ticket;
      request.symbol       = _Symbol;
      request.volume       = arrDelete[i].lotsize;
      request.type         = _type;
      request.price        = _price;
      request.deviation    = Slippage;
      request.magic        = MagicNumber;
      request.type_filling = ORDER_FILLING_IOC;
      request.comment      = Comp_Name + " | " + EA_Name;

      if(!OrderSend(request,result))
      {
         PrintFormat("--> OrderSend (ticket=%I64u) returned false - result.retcode=%d comment=%s", arrDelete[i].ticket, result.retcode, result.comment);
      }
   }
   ArrayResize(arrDelete, 0);
}

bool ClearPending()
{
   int pending_now_symbol   = 0;
   int removed              = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      
      if(OrderSelect(ticket))
      {
         string symbol = OrderGetString(ORDER_SYMBOL);
         if(symbol == _Symbol)
         {
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            pending_now_symbol++;

            if(type != ORDER_TYPE_BUY && type != ORDER_TYPE_SELL)
            {
               // prepare request/result
               MqlTradeRequest request;
               MqlTradeResult  result;
               MqlTradeCheckResult check;
               ZeroMemory(request);
               ZeroMemory(result);
               ZeroMemory(check);

               request.action = TRADE_ACTION_REMOVE;
               request.order  = ticket;
               request.symbol = symbol;

               if(!OrderSend(request, result))
               {
                  PrintFormat("❌ Delete pending order %s (%d) at %s failed!, Error: %d",EnumToString(type), ticket, symbol, GetLastError());
               } else {
                  removed++;
               }
            }
         }
      }
   }
   
   if(removed == pending_now_symbol)
   {
      totalPending = 0;
      return true;
   } else {
      return false;
   }
}

bool isMarketOpen(string _session)
{
   datetime gmt_time = TimeGMT();
   MqlDateTime dt;
   TimeToStruct(gmt_time, dt);

   for (int i = 0; i < ArraySize(marketGMT); i++)
   {
      if(marketGMT[i].session == _session
         && dt.hour >= marketGMT[i].open
         && dt.hour < marketGMT[i].close){
         return true;
      }
   }
   
   return false;
}

void AverageSpread()
{
   _spread = MathAbs(_ask - _bid);

   sum_spread += _spread;
   count_spread++;

   avg_spread = sum_spread / count_spread;
   hst_spread = _spread > hst_spread ? _spread : hst_spread;
}

string NumberFormat(string val)
{
   string s = StringFormat("%.2f", MathAbs((double)val));
   int dot = StringFind(s, ".");
   for(int i = (dot == -1 ? StringLen(s) : dot) - 3; i > 0; i -= 3)
      s = StringSubstr(s, 0, i) + "," + StringSubstr(s, i);
   if((double)val < 0) s = "-" + s;
   
   return s;
}

void ResetParamiter()
{
   // Buy
   countBuy        = 0;
   sumLotBuy       = 0;
   fcProfitBuy     = 0;
   fcLossBuy       = 0;
   priceBuy        = 0;

   // Sell
   countSell       = 0;
   sumLotSell      = 0;
   fcProfitSell    = 0;
   fcLossSell      = 0;
   priceSell       = 0;

   // Casual
   // fst_order_time       = 0;
   // fst_order_lot        = 0;
   // fst_order_type       = NULL;
   
   // fnl_order_time       = 0;
   // fnl_order_type       = NULL;
   
   otherSymbolOpening   = 0;
   otherSymbolPending   = 0;
}

void ShowComment()
{  
   string arw_buy       = (fnl_order_type == ORDER_TYPE_BUY && countBuy > 0) ? " <------------" : "";
   string arw_sell      = (fnl_order_type == ORDER_TYPE_SELL && countSell > 0) ? " <------------" : "";
   int show_spread      = (int)(_spread / _Point);
   int show_avg_spread  = (int)(avg_spread / _Point);
   int show_hst_spread  = (int)(hst_spread / _Point);
   long vol = iVolume(_Symbol, PERIOD_CURRENT, 1);
   
   Comment("\n " + EA_Name + " -> Symbol : " + _Symbol
           + "\n Account balance  :   " + NumberFormat((string)acc_balance)
           + "\n Account profit     :   " + NumberFormat((string)acc_profit)
           + "\n Net profit     :   " + NumberFormat((string)net_profit) + " | " + NumberFormat((string)net_profit_per) + "%"
           + "\n Total Opening : " + IntegerToString(totalOpening)
           + "\n Total Pending : " + IntegerToString(totalPending)
           + "\n First Lot : " + DoubleToString(fst_order_lot)
           + "\n First Type : " + IntegerToString(fst_order_type)
           + "\n Last Time : " + IntegerToString(fnl_order_time)
           + "\n Last Type : " + IntegerToString(fnl_order_type)
           //+ "\n iVolume : " + (string)vol
           //+ "\n iRSI : " + (string)rsiHandle
           //+ "\n iRSI : " + (string)currentRSI
           //+ "\n iRSI : " + (string)prevRSI
           //+ "\n Digits     :   " + DoubleToString(_Digits, 0)

           + "\n ================== BUY ================= " + arw_buy
           + "\n Count BUY : " + IntegerToString(countBuy)
           + "\n Sum Lot : " + DoubleToString(sumLotBuy, 2)
           //+ "\n Pending Price : " + DoubleToString(priceBuy, _Digits)
           + "\n Forecast Profit : " + DoubleToString(fcProfitBuy, 2)
           //+ "\n Forecast Loss : -" + DoubleToString(fcLossBuy, 2)
           
           + "\n ================== SELL ================= " + arw_sell
           + "\n Count SELL : " + IntegerToString(countSell)
           + "\n Sum Lot : " + DoubleToString(sumLotSell, 2)
           //+ "\n Pending Price : " + DoubleToString(priceSell, _Digits)
           + "\n Forecast Profit : " + DoubleToString(fcProfitSell, 2)
           //+ "\n Forecast Loss : -" + DoubleToString(fcLossSell, 2)
           
           + "\n ================== Spread ================= "
           + "\n Average : " + IntegerToString(show_avg_spread)
           + "\n Current : " + IntegerToString(show_spread)
           + "\n Highest : " + IntegerToString(show_hst_spread)

           + "\n ================ Statistic ==============="
           + "\n Max DD : " + NumberFormat((string)maxDrawDown) + " | " + NumberFormat((string)maxDD_Per) + "%"
           + "\n Max Orders : " + IntegerToString(maxOrders)
           + "\n Bigest Lot : " + DoubleToString(maxLot, 2)
           + "\n ================ Statistic ==============="
          );
}
