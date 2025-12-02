//+------------------------------------------------------------------+
//|                                                PVC Red China.mq5 |
//|                                          Copyright 2025, LocalFX |
//|                               https://www.facebook.com/LocalFX4U |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, LocalFX"
#property link "https://www.facebook.com/LocalFX4U"
#property version "1.00"

int slipp = 20;
input double InpLot = 0.01; // lot size per cycle
input double Target = 50.0; // target profit in money
input int MaxOrders = 300;
input int RemovePercent = 30;

int MustRemove = 0;
int removed = 0;
int removed_buy = 0;
int removed_sell = 0;

double lossTotal = 0;
double lossTotal2 = 0;
double profitTotal = 0;
double swapTotal = 0;

double money_after_closed = 0; // V2
double netTotal = 0;           // V3

struct KeyValue
{
  int ticket;
  int type;
  double lotsize;
  double profit;
  double swap;
};

void AddKeyValue(KeyValue &arr[], int ticket, int type, double lotsize, double profit, double swap)
{
  int size = ArraySize(arr);  // หาขนาดอาเรย์ปัจจุบัน
  ArrayResize(arr, size + 1); // ขยายอาเรย์เพิ่ม 1 ช่อง

  arr[size].ticket = ticket;
  arr[size].type = type;
  arr[size].lotsize = lotsize;
  arr[size].profit = profit;
  arr[size].swap = swap;
}

KeyValue arrLoss[];
KeyValue arrProfit[];
KeyValue arrDelete[];

double BuyProfitTotal = 0.0;  // sum of buy profit (money: profit+swap+commission)
double SellProfitTotal = 0.0; // sum of sell profit (money: profit+swap+commission)
double NetProfitTotal = 0.0;  // BuyProfitTotal + SellProfitTotal (money)

int TotalOrdersCount = 0;
int BuyOrdersCount = 0;
int SellOrdersCount = 0;

//+------------------------------------------------------------------+
void ResetProfitParams()
{
  BuyProfitTotal  = 0.0;
  SellProfitTotal = 0.0;
  NetProfitTotal  = 0.0;

  TotalOrdersCount = 0;
  BuyOrdersCount   = 0;
  SellOrdersCount  = 0;
}

double first_balance = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_balance = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_profit = AccountInfoDouble(ACCOUNT_PROFIT);
double net_profit = 0;
double net_profit_per = 0;
double maxDrawDown = 0;
double maxDD_Per = 0;

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
bool HasOpenPositionForSymbol()
{
  const int total = PositionsTotal();
  for (int i = 0; i < total; i++)
  {
    ulong ticket = PositionGetTicket(i);
    if (PositionSelectByTicket(ticket) &&
        PositionGetString(POSITION_SYMBOL) == _Symbol)
      return (true);
  }
  return (false);
}
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
void CloseSideIfTargetReached()
{
  // work on latest totals
  UpdateTotalsInPoints();

  bool closeBuys = (BuyProfitTotal >= Target);
  bool closeSells = (SellProfitTotal >= Target);

  if (!closeBuys && !closeSells)
    return;

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
      double price  = (type == POSITION_TYPE_BUY)
                        ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                        : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);
      ZeroMemory(result);

      request.action      = TRADE_ACTION_DEAL;
      request.symbol      = _Symbol;
      request.volume      = volume;
      request.deviation   = 5;
      request.type        = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price       = price;
      request.position    = ticket;
      request.type_filling= ORDER_FILLING_IOC;

      if (!OrderSend(request, result))
        PrintFormat("CloseSideIfTargetReached: close failed, ticket=%I64u retcode=%d comment=%s",
                    ticket, result.retcode, result.comment);
    }
  }
}
//+------------------------------------------------------------------+
void UpdateTotalsInPoints()
{
  const int total = PositionsTotal();

  //--- open positions
  for (int i = 0; i < total; i++)
  {
    ulong ticket = PositionGetTicket(i);
    if (!PositionSelectByTicket(ticket))
      continue;

    if (PositionGetString(POSITION_SYMBOL) != _Symbol)
      continue;

    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double posProfit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

    if (type == POSITION_TYPE_BUY)
    {
      BuyProfitTotal += posProfit;
      BuyOrdersCount++;
    }
    else if (type == POSITION_TYPE_SELL)
    {
      SellProfitTotal += posProfit;
      SellOrdersCount++;
    }

    TotalOrdersCount++;
  }

  NetProfitTotal = BuyProfitTotal + SellProfitTotal;
}
void OpenPairOrders(const double lot)
{
  MqlTradeRequest request;
  MqlTradeResult result;

  ZeroMemory(request);
  ZeroMemory(result);
  request.action = TRADE_ACTION_DEAL;
  request.symbol = _Symbol;
  request.volume = lot;
  request.deviation = 5;
  request.type = ORDER_TYPE_BUY;
  request.type_filling = ORDER_FILLING_IOC;
  if (!OrderSend(request, result))
    PrintFormat("Buy OrderSend failed. retcode=%d comment=%s",
                result.retcode, result.comment);

  ZeroMemory(request);
  ZeroMemory(result);
  request.action = TRADE_ACTION_DEAL;
  request.symbol = _Symbol;
  request.volume = lot;
  request.deviation = 5;
  request.type = ORDER_TYPE_SELL;
  request.type_filling = ORDER_FILLING_IOC;
  if (!OrderSend(request, result))
    PrintFormat("Sell OrderSend failed. retcode=%d comment=%s",
                result.retcode, result.comment);
}
//+------------------------------------------------------------------+
void CheckAndOpenOrders()
{
  const ENUM_TIMEFRAMES currentTf = (ENUM_TIMEFRAMES)Period();
  const datetime currentBarOpen = iTime(_Symbol, currentTf, 0);
  const datetime lastOrderOpen = GetLatestOrderOpenTime();

  PrintFormat("DEBUG: TF=%d currentBarOpen=%s lastOrderOpen=%s",
              currentTf,
              TimeToString(currentBarOpen, TIME_DATE | TIME_SECONDS),
              TimeToString(lastOrderOpen, TIME_DATE | TIME_SECONDS));

  if (lastOrderOpen >= currentBarOpen)
  {
    Print("DEBUG: Skip open – lastOrderOpen >= currentBarOpen");
    return;
  }

  Print("DEBUG: OpenPairOrders(InpLot) called");
  OpenPairOrders(InpLot);
}
//+------------------------------------------------------------------+
string NumberFormat(string val)
{
   string s = StringFormat("%.2f", MathAbs((double)val));
   int dot = StringFind(s, ".");
   for(int i = (dot == -1 ? StringLen(s) : dot) - 3; i > 0; i -= 3)
      s = StringSubstr(s, 0, i) + "," + StringSubstr(s, i);
   if((double)val < 0) s = "-" + s;
   
   return s;
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  MustRemove = (int)MathCeil((MaxOrders * RemovePercent) /100);
  return (INIT_SUCCEEDED);
}

void OnTick()
{
  acc_balance = AccountInfoDouble(ACCOUNT_BALANCE);
  acc_profit = AccountInfoDouble(ACCOUNT_PROFIT);

  if (acc_profit < maxDrawDown)
  {
    maxDrawDown = acc_profit;
    maxDD_Per = (maxDrawDown / acc_balance) * 100;
  }

  net_profit = acc_balance - first_balance;
  net_profit_per = (net_profit / first_balance) * 100;

  ResetProfitParams();
  UpdateTotalsInPoints();
  CloseSideIfTargetReached();
  Comment(
      "================ Account ===============\n",
      "Account balance: ", NumberFormat((string)AccountInfoDouble(ACCOUNT_BALANCE)), "\n",
      "Account profit: ", NumberFormat((string)acc_profit), "\n",
      "================ Result ===============\n",
      "Net profit:   " + NumberFormat((string)net_profit), " | ", NumberFormat((string)net_profit_per), "%\n",
      "Max DD:   " + NumberFormat((string)maxDrawDown), " | ", NumberFormat((string)maxDD_Per), "%\n",
      "================ Casual ===============\n",
      "TotalOrders: ", TotalOrdersCount,
      "  BuyOrders: ", BuyOrdersCount,
      "  SellOrders: ", SellOrdersCount, "\n",
      "BuyProfitTotal: ", DoubleToString(BuyProfitTotal, 1),
      "  SellProfitTotal: ", DoubleToString(SellProfitTotal, 1),
      "  NetProfitTotal: ", DoubleToString(NetProfitTotal, 1));
  CheckAndOpenOrders();
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
  swapTotal = 0;

  money_after_closed = 0; // V2
  netTotal = 0;           // V3
}

//+------------------------------------------------------------------+
//| Process Auto Close V2 Logic                                      |
//+------------------------------------------------------------------+
void ProcessCloseV2()
{
  string txt_name = script_name + " | Type: 2";
  // -------------------------------------------------------
  // ( 1 ) This loop for get all loss profit(-).
  // -------------------------------------------------------
  for (int i = 0; i < OrdersTotal(); i++)
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol())
    {
      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
        double profit = OrderProfit() + OrderSwap();
        // loss (-)
        if (profit < 0)
        {
          InsertArrayLoss("ASC", OrderTicket(), OrderType(), OrderLots(), profit, OrderSwap());
        }
      }
    }
  }
  // -----------
  // ( 1 ) END
  // -----------

  for (int j = 0; j < ArraySize(arrLoss); j++)
  {
    int big_loss_ticket = arrLoss[j].ticket;
    int big_loss_type = arrLoss[j].type;
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

    for (int i = 0; i < OrdersTotal(); i++)
    {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol())
      {
        if (OrderType() == OP_BUY || OrderType() == OP_SELL)
        {
          double profit = OrderProfit() + OrderSwap();
          // profit (+)
          if (profit > 0)
          {
            sum_all_profit = sum_all_profit + profit;
            InsertArrayProfit("DESC", OrderTicket(), OrderType(), OrderLots(), profit, OrderSwap());
          }
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
      AddKeyValue(arrDummy, arrProfit[i].ticket, arrProfit[i].type, arrProfit[i].lotsize, arrProfit[i].profit, arrProfit[i].swap);

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
        if ((i == ArraySize(arrProfit) - 1) && compare_profit < (big_loss_profit + money_after_closed))
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
      AddKeyValue(arrDelete, big_loss_ticket, big_loss_type, big_loss_lot, big_loss_profit, big_loss_swap);
      lossTotal = lossTotal + big_loss_profit;
      swapTotal = swapTotal + big_loss_swap;
      // Print("==> (-) Tick : "+big_loss_ticket+" Profit : "+big_loss_profit);
      for (int i = 0; i < ArraySize(arrDummy); i++)
      {
        AddKeyValue(arrDelete, arrDummy[i].ticket, arrDummy[i].type, arrDummy[i].lotsize, arrDummy[i].profit, arrDummy[i].swap);
        profitTotal = profitTotal + arrDummy[i].profit;
        swapTotal = swapTotal + arrDummy[i].swap;
        // Print("==> (+) Tick : "+arrDummy[i].ticket+" Profit : "+arrDummy[i].profit);
      }

      // Start delete order 1 by 1
      for (int i = 0; i < ArraySize(arrDelete); i++)
      {
        double price_ = arrDelete[i].type == OP_BUY ? Bid : Ask;
        if (OrderClose(arrDelete[i].ticket, arrDelete[i].lotsize, price_, slipp))
        {
          if (arrDelete[i].type == OP_BUY)
            removed_buy++;
          else if (arrDelete[i].type == OP_SELL)
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

    if (removed >= mustRemove)
    {
      break;
    }

    // -----------
    // ( 3 ) END
    // -----------
  }

  // -------------------------------------------------------------------------------------
  // ( 4 ) Last step if got Profit(+) after closed [Too much profit], remove more to make it equal zero(0)
  // -------------------------------------------------------------------------------------
  money_after_closed = profitTotal + lossTotal;
  string txtLoss = "";
  if (money_after_closed > 0)
  {
    double sum_all_loss = 0;
    ArrayResize(arrLoss, 0);

    for (int i = 0; i < OrdersTotal(); i++)
    {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol())
      {
        if (OrderType() == OP_BUY || OrderType() == OP_SELL)
        {
          double profit = OrderProfit() + OrderSwap();
          // loss (-)
          if (profit < 0)
          {
            sum_all_loss = sum_all_loss + profit;

            if (MathAbs(sum_all_loss) <= money_after_closed)
            {
              lossTotal2 = lossTotal2 + profit;
              InsertArrayLoss("ASC", OrderTicket(), OrderType(), OrderLots(), profit, OrderSwap());
            }
            else
            {
              sum_all_loss = sum_all_loss - profit;
            }
          }
        }
      }
    }

    // Start delete order 1 by 1
    for (int i = 0; i < ArraySize(arrLoss); i++)
    {
      double price_ = arrLoss[i].type == OP_BUY ? Bid : Ask;
      if (OrderClose(arrLoss[i].ticket, arrLoss[i].lotsize, price_, slipp))
      {
        if (arrLoss[i].type == OP_BUY)
          removed_buy++;
        else if (arrLoss[i].type == OP_SELL)
          removed_sell++;

        removed++;
      }
    }
    money_after_closed = profitTotal + lossTotal + lossTotal2;
    txtLoss = ", " + DoubleToString(lossTotal2, 2);
  }

  // -----------
  // ( 4 ) END
  // -----------
  Print(txt_name + "\n\n Money result: Profit[" + DoubleToString(profitTotal, 2) + "] - Loss[" + DoubleToString(lossTotal, 2) + txtLoss + "] = Net[" + DoubleToString(money_after_closed, 2) + "]" + "\n Orders removed: Buy[" + IntegerToString(removed_buy) + "] + Sell[" + IntegerToString(removed_sell) + "] = Total[" + IntegerToString(removed) + "]");
}

void InsertArrayLoss(string format, int ticket, int type, double lot, double profit, double swap)
{
  KeyValue num;
  num.ticket = ticket;
  num.type = type;
  num.lotsize = lot;
  num.profit = profit;
  num.swap = swap;

  int pos = -1;
  int head_i = -1;
  int tail_i = -1;

  if (ArraySize(arrLoss) == 0)
  {
    AddKeyValue(arrLoss, ticket, type, lot, profit, swap);
    return;
  }

  if (format == "ASC")
  {
    for (int i = 0; i < ArraySize(arrLoss); i++)
    {
      if (num.profit > arrLoss[i].profit)
      {
        if (head_i == -1 || (arrLoss[head_i].profit == arrLoss[i].profit && head_i < i) || arrLoss[head_i].profit < arrLoss[i].profit)
        {
          head_i = i;
        }
      }
      else if (num.profit < arrLoss[i].profit)
      {
        if (tail_i == -1 || (arrLoss[tail_i].profit == arrLoss[i].profit && tail_i > i) || arrLoss[tail_i].profit > arrLoss[i].profit)
        {
          tail_i = i;
        }
      }
    }
  }
  else if (format == "DESC")
  {
    for (int i = 0; i < ArraySize(arrLoss); i++)
    {
      if (num.profit < arrLoss[i].profit)
      {
        if (head_i == -1 || (arrLoss[head_i].profit == arrLoss[i].profit && head_i > i) || arrLoss[head_i].profit > arrLoss[i].profit)
        {
          head_i = i;
        }
      }
      else if (num.profit > arrLoss[i].profit)
      {
        if (tail_i == -1 || (arrLoss[tail_i].profit == arrLoss[i].profit && tail_i < i) || arrLoss[tail_i].profit < arrLoss[i].profit)
        {
          tail_i = i;
        }
      }
    }
  }

  if (head_i == -1 && tail_i >= 0)
  {
    pos = 0;
  }
  else if (tail_i == -1 && head_i >= 0)
  {
    pos = head_i + 1;
  }
  else
  {
    int diff_i = tail_i - head_i;
    pos = (diff_i == 1) ? head_i + 1 : tail_i - 1;
  }

  ArrayResize(arrLoss, ArraySize(arrLoss) + 1);

  for (int i = ArraySize(arrLoss) - 1; i > pos; i--)
    arrLoss[i] = arrLoss[i - 1];

  arrLoss[pos] = num;

  /*for(int i = 0; i < ArraySize(arrLoss); i++)
  {
     Print("Order #", i,
           "  Ticket=", arrLoss[i].ticket,
           "  Type=", arrLoss[i].type,
           "  Lot=", arrLoss[i].lotsize,
           "  Profit=", arrLoss[i].profit);
  }*/
}

void InsertArrayProfit(string format, int ticket, int type, double lot, double profit, double swap)
{
  KeyValue num;
  num.ticket = ticket;
  num.type = type;
  num.lotsize = lot;
  num.profit = profit;
  num.swap = swap;

  int pos = -1;
  int head_i = -1;
  int tail_i = -1;

  if (ArraySize(arrProfit) == 0)
  {
    AddKeyValue(arrProfit, ticket, type, lot, profit, swap);
    return;
  }

  if (format == "ASC")
  {
    for (int i = 0; i < ArraySize(arrProfit); i++)
    {
      if (num.profit > arrProfit[i].profit)
      {
        if (head_i == -1 || (arrProfit[head_i].profit == arrProfit[i].profit && head_i < i) || arrProfit[head_i].profit < arrProfit[i].profit)
        {
          head_i = i;
        }
      }
      else if (num.profit < arrProfit[i].profit)
      {
        if (tail_i == -1 || (arrProfit[tail_i].profit == arrProfit[i].profit && tail_i > i) || arrProfit[tail_i].profit > arrProfit[i].profit)
        {
          tail_i = i;
        }
      }
    }
  }
  else if (format == "DESC")
  {
    for (int i = 0; i < ArraySize(arrProfit); i++)
    {
      if (num.profit < arrProfit[i].profit)
      {
        if (head_i == -1 || (arrProfit[head_i].profit == arrProfit[i].profit && head_i > i) || arrProfit[head_i].profit > arrProfit[i].profit)
        {
          head_i = i;
        }
      }
      else if (num.profit > arrProfit[i].profit)
      {
        if (tail_i == -1 || (arrProfit[tail_i].profit == arrProfit[i].profit && tail_i < i) || arrProfit[tail_i].profit < arrProfit[i].profit)
        {
          tail_i = i;
        }
      }
    }
  }

  if (head_i == -1 && tail_i >= 0)
  {
    pos = 0;
  }
  else if (tail_i == -1 && head_i >= 0)
  {
    pos = head_i + 1;
  }
  else
  {
    int diff_i = tail_i - head_i;
    pos = (diff_i == 1) ? head_i + 1 : tail_i - 1;
  }

  ArrayResize(arrProfit, ArraySize(arrProfit) + 1);

  for (int i = ArraySize(arrProfit) - 1; i > pos; i--)
    arrProfit[i] = arrProfit[i - 1];

  arrProfit[pos] = num;

  /*for(int i = 0; i < ArraySize(arrProfit); i++)
  {
     Print("Order #", i,
           "  Ticket=", arrProfit[i].ticket,
           "  Type=", arrProfit[i].type,
           "  Lot=", arrProfit[i].lotsize,
           "  Profit=", arrProfit[i].profit);
  }*/
}

//+------------------------------------------------------------------+
//| Process Auto Close V3 Logic                                      |
//+------------------------------------------------------------------+
void ProcessCloseV3()
{
  string txt_name = script_name + " | Type: 3";

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
      AddKeyValue(arrDelete, arrLoss[i].ticket, arrLoss[i].type, arrLoss[i].lotsize, arrLoss[i].profit, arrLoss[i].swap);
    }
  }

  if (ArraySize(arrDelete) > 0)
  {
    // Delete loss(-)
    for (int i = 0; i < ArraySize(arrDelete); i++)
    {
      double price_ = arrDelete[i].type == OP_BUY ? Bid : Ask;
      if (OrderClose(arrDelete[i].ticket, arrDelete[i].lotsize, price_, slipp))
      {
        if (arrDelete[i].type == OP_BUY)
          removed_buy++;
        else if (arrDelete[i].type == OP_SELL)
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
      double price_ = arrProfit[i].type == OP_BUY ? Bid : Ask;
      if (OrderClose(arrProfit[i].ticket, arrProfit[i].lotsize, price_, slipp))
      {
        if (arrProfit[i].type == OP_BUY)
          removed_buy++;
        else if (arrProfit[i].type == OP_SELL)
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

  Print(txt_name + "\n\n Money result: Profit[" + DoubleToString(profitTotal, 2) + "] - Loss[" + DoubleToString(lossTotal, 2) + "] = Net[" + DoubleToString(netTotal, 2) + "]" + "\n Orders removed: Buy[" + IntegerToString(removed_buy) + "] + Sell[" + IntegerToString(removed_sell) + "] = Total[" + IntegerToString(removed) + "]");
}

void CreateDummy()
{
  // Put loss(-) orders in 2D Array, And insert order by DESC
  for (int i = 0; i < OrdersTotal(); i++)
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol())
    {
      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
        double profit = OrderProfit() + OrderSwap();

        // Profit orders(+) | Sum all profit
        if (profit > 0)
        {
          profitTotal = profitTotal + profit;
          AddKeyValue(arrProfit, OrderTicket(), OrderType(), OrderLots(), profit, OrderSwap());
        }

        // Loss orders(-) | Put loss orders in array
        if (profit < 0)
        {
          InsertMultiArray("DESC", OrderTicket(), OrderType(), OrderLots(), profit, OrderSwap());
        }
      }
    }
  }
}

void InsertMultiArray(string format, int ticket, int type, double lot, double profit, double swap)
{
  int pos = -1;
  int head_i = -1;
  int tail_i = -1;

  if (ArraySize(arrLoss) == 0)
  {
    AddKeyValue(arrLoss, ticket, type, lot, profit, swap);
    return;
  }

  if (format == "ASC")
  {
    for (int i = 0; i < ArraySize(arrLoss); i++)
    {
      if (profit > arrLoss[i].profit)
      {
        if (head_i == -1 || (arrLoss[head_i].profit == arrLoss[i].profit && head_i < i) || arrLoss[head_i].profit < arrLoss[i].profit)
        {
          head_i = i;
        }
      }
      else if (profit < arrLoss[i].profit)
      {
        if (tail_i == -1 || (arrLoss[tail_i].profit == arrLoss[i].profit && tail_i > i) || arrLoss[tail_i].profit > arrLoss[i].profit)
        {
          tail_i = i;
        }
      }
    }
  }
  else if (format == "DESC")
  {
    for (int i = 0; i < ArraySize(arrLoss); i++)
    {
      if (profit < arrLoss[i].profit)
      {
        if (head_i == -1 || (arrLoss[head_i].profit == arrLoss[i].profit && head_i > i) || arrLoss[head_i].profit > arrLoss[i].profit)
        {
          head_i = i;
        }
      }
      else if (profit > arrLoss[i].profit)
      {
        if (tail_i == -1 || (arrLoss[tail_i].profit == arrLoss[i].profit && tail_i < i) || arrLoss[tail_i].profit < arrLoss[i].profit)
        {
          tail_i = i;
        }
      }
    }
  }

  if (head_i == -1 && tail_i >= 0)
  {
    pos = 0;
  }
  else if (tail_i == -1 && head_i >= 0)
  {
    pos = head_i + 1;
  }
  else
  {
    int diff_i = tail_i - head_i;
    pos = (diff_i == 1) ? head_i + 1 : tail_i - 1;
  }

  ArrayResize(arrLoss, ArraySize(arrLoss) + 1);

  for (int i = ArraySize(arrLoss) - 1; i > pos; i--)
    arrLoss[i] = arrLoss[i - 1];

  KeyValue num;
  num.ticket = ticket;
  num.type = type;
  num.lotsize = lot;
  num.profit = profit;
  num.swap = swap;

  arrLoss[pos] = num;

  /*for(int i = 0; i < ArraySize(arrProfit); i++)
  {
     Print("Order #", i,
           "  Ticket=", arrProfit[i].ticket,
           "  Type=", arrProfit[i].type,
           "  Lot=", arrProfit[i].lotsize,
           "  Profit=", arrProfit[i].profit);
  }*/
}
