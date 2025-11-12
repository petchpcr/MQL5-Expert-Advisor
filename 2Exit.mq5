//+------------------------------------------------------------------+
//|                                                        2Exit.mq5 |
//|                                          Copyright 2025, LocalFX |
//|                               https://www.facebook.com/LocalFX4U |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, LocalFX"
#property link      "https://www.facebook.com/LocalFX4U"
#property version   "1.00"

string Comp_Name     = "LocalFX";
string EA_Name       = "2Exit";

long  MagicNumber    = 7020202;
int   Slippage       = 5;

input double Start_lot     = 0.01;
double step_lot            = 0.01;
input int TP               = 500;
input int Distance         = 500;
input int Money_target     = 5;
input int Point_target     = 5;
bool Backtest_mode         = false;

int middle_space           = 0;
int _tp                    = 0;
int _sl                    = 0;
int _distance              = 0;

double acc_balance         = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_profit          = AccountInfoDouble(ACCOUNT_PROFIT);

double   _ask                 = 0;
double   _bid                 = 0;
double   _spread              = 0;
double   avg_spread           = 0;
double   sum_spread           = 0;
int      count_spread         = 0;
int      totalOpening         = 0;
int      totalPending         = 0;
int      otherSymbolOpening   = 0;
int      otherSymbolPending   = 0;

// Bigest Order
double            bigest_lot  = 0;
ENUM_ORDER_TYPE   bigest_type = NULL;
double            next_lot    = 0;

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

double test_value    = 0;
double test_value2   = 0;

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
      _tp = TP / 5;
      _distance = Distance / 5;
   } else if(_Digits == 4) {
      _tp = TP / 7;
      _distance = Distance / 7;
   } else if(_Digits == 5) {
      _tp = TP;
      _distance = Distance;
   } else {
      _tp = TP;
      _distance = Distance;
   }

   middle_space = _distance * 2;
   _sl = middle_space + _tp;

   return(INIT_SUCCEEDED);
}

void OnTimer()
{
   SaveGlobalVariable();
}

void OnDeinit(const int reason)
{
   if(!Backtest_mode)
   {
      EventKillTimer();
      SaveGlobalVariable();
   }
}

void OnTick()
{
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
   
   if(totalOpening == 0 && totalPending == 0) {
      double _Bprice =  _ask + (_distance * _Point);
      double _Sprice =  _bid - (_distance * _Point);
      PendingBuy(_Bprice, Start_lot);
      PendingSell(_Sprice, Start_lot);
   } else if (totalOpening > 0 && totalPending == 0) {
      PendingNextLot();
   }

   ShowComment();
}

void ScanOrders()
{
   ResetParamiter();

   // ================= Opening Orders =================
   double first_lot_buy  = 0;
   double first_price_buy  = 0;

   double first_lot_sell = 0;
   double first_price_sell = 0;

   for(int i = 0; i < PositionsTotal(); i++) // PositionsTotal() -> Opening
   {
      ulong ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(ticket))
      {
         string symbol = PositionGetString(POSITION_SYMBOL);
         if(symbol == _Symbol) {
            double lot           = PositionGetDouble(POSITION_VOLUME);
            double price         = PositionGetDouble(POSITION_PRICE_OPEN);
            double take_profit   = PositionGetDouble(POSITION_TP);
            double stop_loss     = PositionGetDouble(POSITION_SL);
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);

            maxLot = lot > maxLot ? lot : maxLot;
            
            if(lot > bigest_lot)
            {
               bigest_lot  = lot;
               bigest_type = type;
            }

            if(type == ORDER_TYPE_BUY)
            {
               fcProfitBuy += ((take_profit - price) / _Point) * lot;
               fcLossBuy   += ((price - stop_loss) / _Point) * lot;
               
               if(first_lot_buy == 0) {
                  first_lot_buy     = lot;
                  first_price_buy   = price;
               } else {
                  if(lot < first_lot_buy) {
                     first_lot_buy     = lot;
                     first_price_buy   = price;
                  }
               }

               sumLotBuy += lot;
               countBuy++;
               
            } else if(type == ORDER_TYPE_SELL) {
            
               fcProfitSell += ((price - take_profit) / _Point) * lot;
               fcLossSell   += ((stop_loss - price) / _Point) * lot;

               if(first_lot_sell == 0) {
                  first_lot_sell     = lot;
                  first_price_sell   = price;
               } else {
                  if(lot < first_lot_sell) {
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
         if(symbol == _Symbol) {
            pending_lot  = OrderGetDouble(ORDER_VOLUME_INITIAL);
            pending_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         } else {
            otherSymbolPending++;
         }
      }
   }
   totalPending    = (OrdersTotal() - otherSymbolPending);

   // ================= Remove pending leftover =================
   if((totalPending == 1 && pending_lot == bigest_lot) 
   || (totalPending == 1 && pending_type == ORDER_TYPE_BUY_STOP && bigest_type == ORDER_TYPE_BUY)
   || (totalPending == 1 && pending_type == ORDER_TYPE_SELL_STOP && bigest_type == ORDER_TYPE_SELL)
   || (totalOpening == 0 && totalPending == 1)
   ){
      ClearPending();
   }
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
   double profit_dummy = 0;
   double lot_dummy = 0;
   if(bigest_type == ORDER_TYPE_BUY)
   {
      lot_dummy = sumLotSell;

      while (profit_dummy < fcLossBuy)
      {
         lot_dummy += step_lot;
         profit_dummy = (lot_dummy * _tp) + fcProfitSell;
      }
      //Print("=== SELL Next Lot: "+DoubleToString(lot_dummy, 2)+" | Profit: "+DoubleToString(profit_dummy, 2)+" | FC Loss Buy: "+DoubleToString(fcLossBuy, 2));
      PendingSell(priceSell, lot_dummy);

   } else if(bigest_type == ORDER_TYPE_SELL) {

      lot_dummy = sumLotBuy;

      while (profit_dummy < fcLossSell)
      {
         lot_dummy += step_lot;
         profit_dummy = (lot_dummy * _tp) + fcProfitBuy;
      }
      //Print("=== BUY Next Lot: "+DoubleToString(lot_dummy, 2)+" | Profit: "+DoubleToString(profit_dummy, 2)+" | FC Loss Sell: "+DoubleToString(fcLossSell, 2));
      PendingBuy(priceBuy, lot_dummy);
   }
   next_lot = lot_dummy;
}

void PendingBuy(double _price, double _lot)
{
   if((_ask + ((_distance / 2) * _Point)) > _price) return;

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
   request.price        = NormalizeDouble(_price, _Digits);
   request.tp           = NormalizeDouble(request.price + (_tp * _Point), _Digits);
   request.sl           = NormalizeDouble(request.price - (_sl * _Point), _Digits);
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

void PendingSell(double _price, double _lot)
{
   if((_bid - ((_distance / 2) * _Point)) < _price) return;

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
   request.price        = NormalizeDouble(_price, _Digits);
   request.tp           = NormalizeDouble(request.price - (_tp * _Point), _Digits);
   request.sl           = NormalizeDouble(request.price + (_sl * _Point), _Digits);
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

void AverageSpread()
{
   _spread = MathAbs(_ask - _bid);
   count_spread++;

   sum_spread += _spread;
   avg_spread = sum_spread / count_spread;

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
   bigest_lot           = 0;
   bigest_type          = NULL;
   otherSymbolOpening   = 0;
   otherSymbolPending   = 0;
}

void ShowComment()
{  
   string arw_buy       = (bigest_type == ORDER_TYPE_BUY && countBuy > 0) ? " <------------" : "";
   string arw_sell      = (bigest_type == ORDER_TYPE_SELL && countSell > 0) ? " <------------" : "";
   int show_spread      = (int)(_spread / _Point);
   int show_avg_spread  = (int)(avg_spread / _Point);
   Comment("\n Symbol : " + _Symbol
           + "\n Account balance  :   " + NumberFormat((string)acc_balance)
           + "\n Account profit     :   " + NumberFormat((string)acc_profit)
           + "\n Total Opening : " + IntegerToString(totalOpening)
           + "\n Total Pending : " + IntegerToString(totalPending)
           + "\n Next Lot : " + DoubleToString(next_lot, 2)
           + "\n Current Spread : " + IntegerToString(show_spread)
           + "\n Average Spread : " + IntegerToString(show_avg_spread)
           //+ "\n Digits     :   " + DoubleToString(_Digits, 0)

           + "\n ================== BUY ================= " + arw_buy
           + "\n Count BUY : " + IntegerToString(countBuy) + "   |   Sum Lot : " + DoubleToString(sumLotBuy, 2)
           + "\n Pending Price : " + DoubleToString(priceBuy, _Digits)
           + "\n Forecast Profit : " + DoubleToString(fcProfitBuy, 2)
           + "\n Forecast Loss : -" + DoubleToString(fcLossBuy, 2)
           
           + "\n ================== SELL ================= " + arw_sell
           + "\n Count SELL : " + IntegerToString(countSell) + "   |   Sum Lot : " + DoubleToString(sumLotSell, 2)
           + "\n Pending Price : " + DoubleToString(priceSell, _Digits)
           + "\n Forecast Profit : " + DoubleToString(fcProfitSell, 2)
           + "\n Forecast Loss : -" + DoubleToString(fcLossSell, 2)
           
           + "\n ================ Bigest Lot ==============="
           + "\n Now Bigest Lot : " + DoubleToString(bigest_lot, 2)
           + "\n Now Bigest Type : " + EnumToString(bigest_type)


           + "\n ================ Statistic ==============="
           + "\n Max DD : " + NumberFormat((string)maxDrawDown) + " | " + NumberFormat((string)maxDD_Per) + "%"
           + "\n Max Orders : " + IntegerToString(maxOrders)
           + "\n Highest Lot : " + DoubleToString(maxLot, 2)
          );
}
