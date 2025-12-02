//+------------------------------------------------------------------+
//|                                                PVC Red China.mq5 |
//|                                          Copyright 2025, LocalFX |
//|                               https://www.facebook.com/LocalFX4U |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, LocalFX"
#property link      "https://www.facebook.com/LocalFX4U"
#property version   "1.00"

input double InpLot            = 0.01;  // lot size per cycle
input double Target            = 100.0; // target profit in money

double      BuyProfitTotal     = 0.0;   // sum of buy profit (money: profit+swap+commission)
double      SellProfitTotal    = 0.0;   // sum of sell profit (money: profit+swap+commission)
double      NetProfitTotal     = 0.0;   // BuyProfitTotal + SellProfitTotal (money)

int         TotalOrdersCount   = 0;
int         BuyOrdersCount     = 0;
int         SellOrdersCount    = 0;

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
bool HasOpenPositionForSymbol()
  {
   const int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL)==_Symbol)
         return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
datetime GetLatestOrderOpenTime()
  {
   datetime lastOpenTime=0;

   const int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL)==_Symbol)
        {
         datetime openTime=(datetime)PositionGetInteger(POSITION_TIME);
         if(openTime>lastOpenTime)
            lastOpenTime=openTime;
        }
     }

   if(lastOpenTime>0)
      return(lastOpenTime);

   if(HistorySelect(0,TimeCurrent()))
     {
      const int historyTotal=HistoryOrdersTotal();
      for(int i=historyTotal-1;i>=0;i--)
        {
         ulong ticket=HistoryOrderGetTicket(i);
         if(HistoryOrderGetString(ticket,ORDER_SYMBOL)==_Symbol)
           {
            ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)HistoryOrderGetInteger(ticket,ORDER_TYPE);
            if(type==ORDER_TYPE_BUY || type==ORDER_TYPE_SELL)
              {
               datetime openTime=(datetime)HistoryOrderGetInteger(ticket,ORDER_TIME_SETUP);
               if(openTime>lastOpenTime)
                  lastOpenTime=openTime;
               break;
              }
           }
        }
     }
   return(lastOpenTime);
  }
//+------------------------------------------------------------------+
void UpdateTotalsInPoints()
  {
   BuyProfitTotal  = 0.0;
   SellProfitTotal = 0.0;
   NetProfitTotal   = 0.0;

   TotalOrdersCount = 0;
   BuyOrdersCount   = 0;
   SellOrdersCount  = 0;

   const int total=PositionsTotal();

   //--- open positions
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;

      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double posProfit = PositionGetDouble(POSITION_PROFIT)
                        +PositionGetDouble(POSITION_SWAP)
                        +PositionGetDouble(POSITION_COMMISSION);

      if(type==POSITION_TYPE_BUY)
        {
         BuyProfitTotal+=posProfit;
         BuyOrdersCount++;
        }
      else
      if(type==POSITION_TYPE_SELL)
        {
         SellProfitTotal+=posProfit;
         SellOrdersCount++;
        }

      TotalOrdersCount++;
     }

   //--- closed deals in history (to ensure commission from history is included)
   if(HistorySelect(0,TimeCurrent()))
     {
      const int dealsTotal=HistoryDealsTotal();
      for(int i=0;i<dealsTotal;i++)
        {
         ulong dealTicket=HistoryDealGetTicket(i);
         if(HistoryDealGetString(dealTicket,DEAL_SYMBOL)!=_Symbol)
            continue;

         ENUM_DEAL_TYPE dealType=(ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket,DEAL_TYPE);
         if(dealType!=DEAL_TYPE_BUY && dealType!=DEAL_TYPE_SELL)
            continue;

         double dealProfit = HistoryDealGetDouble(dealTicket,DEAL_PROFIT)
                            +HistoryDealGetDouble(dealTicket,DEAL_SWAP)
                            +HistoryDealGetDouble(dealTicket,DEAL_COMMISSION);

         if(dealType==DEAL_TYPE_BUY)
            BuyProfitTotal+=dealProfit;
         else
            SellProfitTotal+=dealProfit;
        }
     }

   NetProfitTotal = BuyProfitTotal + SellProfitTotal;
  }
void OpenPairOrders(const double lot)
  {
   MqlTradeRequest request;
   MqlTradeResult  result;

   ZeroMemory(request);
   ZeroMemory(result);
   request.action        =TRADE_ACTION_DEAL;
   request.symbol        =_Symbol;
   request.volume        =lot;
   request.deviation     =5;
   request.type          =ORDER_TYPE_BUY;
   request.type_filling  =ORDER_FILLING_IOC;
   if(!OrderSend(request,result))
      PrintFormat("Buy OrderSend failed. retcode=%d comment=%s",
                  result.retcode,result.comment);

   ZeroMemory(request);
   ZeroMemory(result);
   request.action        =TRADE_ACTION_DEAL;
   request.symbol        =_Symbol;
   request.volume        =lot;
   request.deviation     =5;
   request.type          =ORDER_TYPE_SELL;
   request.type_filling  =ORDER_FILLING_IOC;
   if(!OrderSend(request,result))
      PrintFormat("Sell OrderSend failed. retcode=%d comment=%s",
                  result.retcode,result.comment);
  }
//+------------------------------------------------------------------+
void CheckAndOpenOrders()
  {
   const ENUM_TIMEFRAMES currentTf=(ENUM_TIMEFRAMES)Period();
   const datetime currentBarOpen=iTime(_Symbol,currentTf,0);
   const datetime lastOrderOpen=GetLatestOrderOpenTime();

   PrintFormat("DEBUG: TF=%d currentBarOpen=%s lastOrderOpen=%s",
               currentTf,
               TimeToString(currentBarOpen,TIME_DATE|TIME_SECONDS),
               TimeToString(lastOrderOpen,TIME_DATE|TIME_SECONDS));

   if(lastOrderOpen>=currentBarOpen)
     {
      Print("DEBUG: Skip open – lastOrderOpen >= currentBarOpen");
      return;
     }

   Print("DEBUG: OpenPairOrders(InpLot) called");
   OpenPairOrders(InpLot);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   return(INIT_SUCCEEDED);
  }
  
  
void OnTick()
  {
   UpdateTotalsInPoints();
   Comment(
      "TotalOrders=",TotalOrdersCount,
      "  BuyOrders=",BuyOrdersCount,
      "  SellOrders=",SellOrdersCount,"\n",
      "BuyProfitTotal=",DoubleToString(BuyProfitTotal,1),
      "  SellProfitTotal=",DoubleToString(SellProfitTotal,1),
      "  NetProfitTotal=",DoubleToString(NetProfitTotal,1)
   );
   CheckAndOpenOrders();
   
  }
  
