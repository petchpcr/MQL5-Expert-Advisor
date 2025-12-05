//+------------------------------------------------------------------+
//|                                                PVC Red China.mq5 |
//|                                          Copyright 2025, LocalFX |
//|                               https://www.facebook.com/LocalFX4U |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, LocalFX"
#property link "https://www.facebook.com/LocalFX4U"
#property version "1.00"
#property strict

#define BTN1 "BTN_Auto_Remove"
#define BTN2 "BTN_CLEAR_NOW"

string ea_name = "Golden Hour";

enum Position
{
   TOP_LEFT  = 0,
   TOP_RIGHT = 3,
   BOTTOM_LEFT = 1,
   BOTTOM_RIGHT  = 2
};

const input string _____UI_Position_____ = "=========== UI Position ===========";
input Position Button_Position = TOP_RIGHT; // ตำแหน่งของปุ่ม
input Position Label_Position = TOP_LEFT; // ตำแหน่งของรายละเอียด

const input string _____Auto_Remove_Order_____ = "======== Auto Remove Order ========";
input bool Auto_Remove = false; // โหมดปิดออเดอร์อัตโนมัติ (เฉพาะออเดอร์ที่ปิดได้)
bool FNC_Auto_Remove = false;
input int Remove_At = 300; // ปิดอัตโนมัติ เมื่อออเดอร์ถึงจำนวน...
input int Remove_Percent = 30; // จำนวนออเดอร์ที่ต้องการลบ (คิดเป็น % ของจำนวนที่กำหนดไว้)

const input string _____Limit_Order_____ = "=========== Limit Order ===========";
input bool Limit_Order = true; // จำกัดการออกออเดอร์ (สูงสุดที่ 300 ออเดอร์)
int LimitAmount = 300;

const input string _____Trading_____ = "============ Trading ============";
input double Lot_Size = 0.01; // ขนาด Lot
input double Target = 50.0; // Target

const input string _____Statistic_____ = "============ Statistic ============";
input datetime St_Date = D'2025.01.01 00:00'; // คำนวณสถิติตั้งแต่วันที่

int slipp = 20;
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

//+------------------------------------------------------------------+
//|   Label Class                                                    |
//+------------------------------------------------------------------+
class CLabel
{
public:
   string name;
   string text;
   int    group, x, y;
   color  clr;
   int    fontSize;
   string fontName;

   CLabel()
   {
      name     = "";
      text     = "";
      x        = 0;
      y        = 0;
      clr      = clrWhite;
      fontSize = 10;
      fontName = "Arial";
   }

   bool Create(string _name, string _text, int _group, int _x, int _y)
   {
      name  = _name;
      text  = _text;
      group = _group;
      x     = _x;
      y     = _y;

      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return false;

      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, fontName);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);

      ObjectSetInteger(0, name, OBJPROP_CORNER, Label_Position);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);

      return true;
   }


   void SetText(string _text)
   {
      text = _text;
      ObjectSetString(0, name, OBJPROP_TEXT, text);
   }

   void SetSize(int _size)
   {
      fontSize = _size;
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   }

   void SetColor(color _clr)
   {
      clr = _clr;
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }

   void MoveAll(int _x, int _y)
   {
      x = _x; y = _y;
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   }

   void MoveX(int _x)
   {
      x = _x;
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   }

   void MoveY(int _y)
   {
      y = _y;
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   }
   
   void Delete()
   {
      ObjectDelete(0, name);
   }
};

//+------------------------------------------------------------------+
//|   Manager Class                                                  |
//+------------------------------------------------------------------+
class CLabelManager
{
private:
   CLabel *labels[];

public:

   int Add(string name, string text, int group, int x, int y)
   {
      int n = ArraySize(labels);
      ArrayResize(labels, n + 1);

      labels[n] = new CLabel;
      labels[n].Create(name, text, group, x, y);

      return n;
   }

   CLabel* Get(int index)
   {
      if(index < 0 || index >= ArraySize(labels))
         return NULL;

      return labels[index];
   }

   void Delete(int index)
   {
      if(index < 0 || index >= ArraySize(labels))
         return;

      labels[index].Delete();
      delete labels[index];
   }

   void DeleteAll()
   {
      for(int i=0; i < ArraySize(labels); i++)
      {
         labels[i].Delete();
         delete labels[i];
      }

      ArrayResize(labels, 0);
   }

   int Count()
   {
      return ArraySize(labels);
   }
};

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

int TotalOrdersCount = 0;
int BuyOrdersCount = 0;
int SellOrdersCount = 0;

double TotalLot = 0;
double BuyLot = 0;
double SellLot = 0;

double BuyProfitTotal = 0.0;  // sum of buy profit (money: profit+swap+commission)
double SellProfitTotal = 0.0; // sum of sell profit (money: profit+swap+commission)
double NetProfitTotal = 0.0;  // BuyProfitTotal + SellProfitTotal (money)

double highest_loss = 0;
double highest_profit = 0;

// *** แกะ MVP การรวบแบบที่ 2 (คาดว่ารวบโดยใช้เส้น avg)
// *** rebate per d/w/m
// *** Max DD + Current DD
// *** ตัวแปรเอาไว้บันทึกค่าหลังปิดโปรแกรม

//+------------------------------------------------------------------+
void ResetProfitParams()
{
  TotalOrdersCount = 0;
  BuyOrdersCount = 0;
  SellOrdersCount = 0;

  TotalLot = 0;
  BuyLot = 0;
  SellLot = 0;

  BuyProfitTotal = 0.0;
  SellProfitTotal = 0.0;
  NetProfitTotal = 0.0;

  highest_loss = 0;
  highest_profit = 0;
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
//| MQL4-style constants for compatibility                          |
//+------------------------------------------------------------------+
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
  request.deviation = slipp;
  request.position = ticket;
  request.type = (type == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
  request.type_filling = ORDER_FILLING_IOC;

  if (!OrderSend(request, result))
  {
    PrintFormat("ClosePositionByTicket failed ticket=%d retcode=%d comment=%s",
                ticket, result.retcode, result.comment);
    return (false);
  }
  return (true);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CloseSideIfTargetReached()
{
  bool closeBuys = (BuyProfitTotal >= Target);
  bool closeSells = (SellProfitTotal >= Target);

  if (!closeBuys && !closeSells)
    return false;

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

      if (!OrderSend(request, result))
        PrintFormat("CloseSideIfTargetReached: close failed, ticket=%I64u retcode=%d comment=%s",
                    ticket, result.retcode, result.comment);
    }
  }

  return true;
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
    double volume = PositionGetDouble(POSITION_VOLUME);

    // loss (-)
    if (posProfit < 0)
    {
      highest_loss = highest_loss == 0 ? posProfit : posProfit < highest_loss ? posProfit
                                                                              : highest_loss;
    }
    // profit (+)
    else if (posProfit > 0)
    {
      highest_profit = highest_profit == 0 ? posProfit : posProfit > highest_profit ? posProfit
                                                                                    : highest_profit;
    }

    if (type == POSITION_TYPE_BUY)
    {
      BuyLot += volume;
      BuyProfitTotal += posProfit;
      BuyOrdersCount++;
    }
    else if (type == POSITION_TYPE_SELL)
    {
      SellLot += volume;
      SellProfitTotal += posProfit;
      SellOrdersCount++;
    }

    TotalLot += volume;
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

  // PrintFormat("DEBUG: TF=%d currentBarOpen=%s lastOrderOpen=%s",
  //             currentTf,
  //             TimeToString(currentBarOpen, TIME_DATE | TIME_SECONDS),
  //             TimeToString(lastOrderOpen, TIME_DATE | TIME_SECONDS));

  if (lastOrderOpen >= currentBarOpen)
  {
    // Print("DEBUG: Skip open – lastOrderOpen >= currentBarOpen");
    return;
  }

  // Print("DEBUG: OpenPairOrders(Lot_Size) called");
  OpenPairOrders(Lot_Size);
}
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
CLabelManager LM;
int lb_band,lb_fb,lb_t_acc,lb_t_res,lb_t_cas,lb_t_ln;
int lb_ab1,lb_ab2;
int lb_od1,lb_od2,lb_od3,lb_od4,lb_od5,lb_od6;
int lb_lt1,lb_lt2,lb_lt3,lb_lt4,lb_lt5,lb_lt6;
int lb_pf1,lb_pf2,lb_pf3,lb_pf4,lb_pf5,lb_pf6;
int lb_dd1,lb_dd2,lb_dd3;
int lb_td1,lb_td2,lb_td3,lb_td4,lb_td5,lb_td6;
int lb_lw1,lb_lw2,lb_lw3,lb_lw4,lb_lw5,lb_lw6;
int lb_lm1,lb_lm2,lb_lm3,lb_lm4,lb_lm5,lb_lm6;
int lb_ly1,lb_ly2,lb_ly3,lb_ly4,lb_ly5,lb_ly6;
int lb_sa1,lb_sa2,lb_sa3,lb_sa4,lb_sa5,lb_sa6;

long dtToday, dt7DaysAgo, dt30DaysAgo, dt365DaysAgo;

int OnInit()
{
  MustRemove = (int)MathCeil((Remove_At * Remove_Percent) / 100);
  FNC_Auto_Remove = Auto_Remove;

  CreateLabel();
  CalculateReport();
  SortObject();
  RefreshButton(objButton[0], FNC_Auto_Remove);
  RefreshButton(objButton[1], false);

  return (INIT_SUCCEEDED);
}

void CreateLabel()
{
  
  if(Label_Position == TOP_LEFT || Label_Position == TOP_RIGHT)
  {
    lb_band     = LM.Add("lb_band", "Local FX - "+ea_name, 0, 10, 20);
    lb_fb       = LM.Add("lb_fb", "www.facebook.com/LocalFX4U", 0, 10, 43);

    lb_t_acc    = LM.Add("lb_t_acc", "============== Account ==============", 0, 10, 65);
    lb_ab1      = LM.Add("lb_ab1", "Account balance:", 1, 10, 80);
    lb_ab2      = LM.Add("lb_ab2", "-", 1, 130, 80);

    lb_t_cas    = LM.Add("lb_t_cas", "=============== Trade ===============", 0, 10, 100);
    lb_od1      = LM.Add("lb_od1", "Total Order:", 2, 10, 115);
    lb_od2      = LM.Add("lb_od2", "-", 2, 80, 115);
    lb_od3      = LM.Add("lb_od3", "Buy:", 2, 130, 115);
    lb_od4      = LM.Add("lb_od4", "-", 2, 160, 115);
    lb_od5      = LM.Add("lb_od5", "Sell:", 2, 200, 115);
    lb_od6      = LM.Add("lb_od6", "-", 2, 230, 115);

    lb_lt1      = LM.Add("lb_lt1", "Total Lot:", 3, 10, 130);
    lb_lt2      = LM.Add("lb_lt2", "-", 3, 80, 130);
    lb_lt3      = LM.Add("lb_lt3", "Buy:", 3, 130, 130);
    lb_lt4      = LM.Add("lb_lt4", "-", 3, 160, 130);
    lb_lt5      = LM.Add("lb_lt5", "Sell:", 3, 200, 130);
    lb_lt6      = LM.Add("lb_lt6", "-", 3, 230, 130);

    lb_pf1      = LM.Add("lb_pf1", "Net Profit:", 3, 10, 145);
    lb_pf2      = LM.Add("lb_pf2", "-", 3, 80, 145);
    lb_pf3      = LM.Add("lb_pf3", "Buy:", 3, 130, 145);
    lb_pf4      = LM.Add("lb_pf4", "-", 3, 160, 145);
    lb_pf5      = LM.Add("lb_pf5", "Sell:", 3, 200, 145);
    lb_pf6      = LM.Add("lb_pf6", "-", 3, 230, 145);

    lb_t_res    = LM.Add("lb_t_res", "=============== Result ==============", 0, 10, 165);
    lb_dd1      = LM.Add("lb_dd1", "Max DD:", 4, 10, 185);
    lb_dd2      = LM.Add("lb_dd2", "-", 4, 80, 185);
    lb_dd3      = LM.Add("lb_dd3", "-", 4, 190, 185);

    lb_td1      = LM.Add("lb_td1", "Today:", 6, 10, 210);
    lb_td2      = LM.Add("lb_td2", "0.00", 6, 55, 210);
    lb_td3      = LM.Add("lb_td3", "Lot:", 6, 130, 210);
    lb_td4      = LM.Add("lb_td4", "0.00", 6, 155, 210);
    lb_td5      = LM.Add("lb_td5", "Rebate:", 6, 200, 210);
    lb_td6      = LM.Add("lb_td6", "0.00", 6, 250, 210);

    lb_lw1      = LM.Add("lb_lw1", "Week:", 7, 10, 225);
    lb_lw2      = LM.Add("lb_lw2", "0.00", 7, 55, 225);
    lb_lw3      = LM.Add("lb_lw3", "Lot:", 7, 130, 225);
    lb_lw4      = LM.Add("lb_lw4", "0.00", 7, 155, 225);
    lb_lw5      = LM.Add("lb_lw5", "Rebate:", 7, 200, 225);
    lb_lw6      = LM.Add("lb_lw6", "0.00", 7, 250, 225);

    lb_lm1      = LM.Add("lb_lm1", "Month:", 8, 10, 240);
    lb_lm2      = LM.Add("lb_lm2", "0.00", 8, 55, 240);
    lb_lm3      = LM.Add("lb_lm3", "Lot:", 8, 130, 240);
    lb_lm4      = LM.Add("lb_lm4", "0.00", 8, 155, 240);
    lb_lm5      = LM.Add("lb_lm5", "Rebate:", 8, 200, 240);
    lb_lm6      = LM.Add("lb_lm6", "0.00", 8, 250, 240);

    lb_ly1      = LM.Add("lb_ly1", "Year:", 9, 10, 255);
    lb_ly2      = LM.Add("lb_ly2", "0.00", 9, 55, 255);
    lb_ly3      = LM.Add("lb_ly3", "Lot:", 9, 130, 255);
    lb_ly4      = LM.Add("lb_ly4", "0.00", 9, 155, 255);
    lb_ly5      = LM.Add("lb_ly5", "Rebate:", 9, 200, 255);
    lb_ly6      = LM.Add("lb_ly6", "0.00", 9, 250, 255);

    lb_t_ln     = LM.Add("lb_t_ln", "---------------------------------------------------------------", 0, 10, 270);

    lb_sa1      = LM.Add("lb_sa1", "Total:", 10, 10, 285);
    lb_sa2      = LM.Add("lb_sa2", "0.00", 10, 55, 285);
    lb_sa3      = LM.Add("lb_sa3", "Lot:", 10, 130, 285);
    lb_sa4      = LM.Add("lb_sa4", "0.00", 10, 155, 285);
    lb_sa5      = LM.Add("lb_sa5", "Rebate:", 10, 200, 285);
    lb_sa6      = LM.Add("lb_sa6", "0.00", 10, 250, 285);
  } 
  else if (Label_Position == BOTTOM_LEFT || Label_Position == BOTTOM_RIGHT)
  {
    lb_band     = LM.Add("lb_band", "Local FX - "+ea_name, 0, 10, 285);
    lb_fb       = LM.Add("lb_fb", "www.facebook.com/LocalFX4U", 0, 10, 262);

    lb_t_acc    = LM.Add("lb_t_acc", "============== Account ==============", 0, 10, 240);
    lb_ab1      = LM.Add("lb_ab1", "Account balance:", 1, 10, 225);
    lb_ab2      = LM.Add("lb_ab2", "-", 1, 130, 225);

    lb_t_cas    = LM.Add("lb_t_cas", "=============== Trade ===============", 0, 10, 205);
    lb_od1      = LM.Add("lb_od1", "Total Order:", 2, 10, 190);
    lb_od2      = LM.Add("lb_od2", "-", 2, 80, 190);
    lb_od3      = LM.Add("lb_od3", "Buy:", 2, 130, 190);
    lb_od4      = LM.Add("lb_od4", "-", 2, 160, 190);
    lb_od5      = LM.Add("lb_od5", "Sell:", 2, 200, 190);
    lb_od6      = LM.Add("lb_od6", "-", 2, 230, 190);

    lb_lt1      = LM.Add("lb_lt1", "Total Lot:", 3, 10, 175);
    lb_lt2      = LM.Add("lb_lt2", "-", 3, 80, 175);
    lb_lt3      = LM.Add("lb_lt3", "Buy:", 3, 130, 175);
    lb_lt4      = LM.Add("lb_lt4", "-", 3, 160, 175);
    lb_lt5      = LM.Add("lb_lt5", "Sell:", 3, 200, 175);
    lb_lt6      = LM.Add("lb_lt6", "-", 3, 230, 175);

    lb_pf1      = LM.Add("lb_pf1", "Net Profit:", 3, 10, 160);
    lb_pf2      = LM.Add("lb_pf2", "-", 3, 80, 160);
    lb_pf3      = LM.Add("lb_pf3", "Buy:", 3, 130, 160);
    lb_pf4      = LM.Add("lb_pf4", "-", 3, 160, 160);
    lb_pf5      = LM.Add("lb_pf5", "Sell:", 3, 200, 160);
    lb_pf6      = LM.Add("lb_pf6", "-", 3, 230, 160);

    lb_t_res    = LM.Add("lb_t_res", "=============== Result ==============", 0, 10, 140);
    lb_dd1      = LM.Add("lb_dd1", "Max DD:", 4, 10, 120);
    lb_dd2      = LM.Add("lb_dd2", "-", 4, 80, 120);
    lb_dd3      = LM.Add("lb_dd3", "-", 4, 190, 120);

    lb_td1      = LM.Add("lb_td1", "Today:", 6, 10, 95);
    lb_td2      = LM.Add("lb_td2", "0.00", 6, 55, 95);
    lb_td3      = LM.Add("lb_td3", "Lot:", 6, 130, 95);
    lb_td4      = LM.Add("lb_td4", "0.00", 6, 155, 95);
    lb_td5      = LM.Add("lb_td5", "Rebate:", 6, 200, 95);
    lb_td6      = LM.Add("lb_td6", "0.00", 6, 250, 95);

    lb_lw1      = LM.Add("lb_lw1", "Week:", 7, 10, 80);
    lb_lw2      = LM.Add("lb_lw2", "0.00", 7, 55, 80);
    lb_lw3      = LM.Add("lb_lw3", "Lot:", 7, 130, 80);
    lb_lw4      = LM.Add("lb_lw4", "0.00", 7, 155, 80);
    lb_lw5      = LM.Add("lb_lw5", "Rebate:", 7, 200, 80);
    lb_lw6      = LM.Add("lb_lw6", "0.00", 7, 250, 80);

    lb_lm1      = LM.Add("lb_lm1", "Month:", 8, 10, 65);
    lb_lm2      = LM.Add("lb_lm2", "0.00", 8, 55, 65);
    lb_lm3      = LM.Add("lb_lm3", "Lot:", 8, 130, 65);
    lb_lm4      = LM.Add("lb_lm4", "0.00", 8, 155, 65);
    lb_lm5      = LM.Add("lb_lm5", "Rebate:", 8, 200, 65);
    lb_lm6      = LM.Add("lb_lm6", "0.00", 8, 250, 65);

    lb_ly1      = LM.Add("lb_ly1", "Year:", 9, 10, 50);
    lb_ly2      = LM.Add("lb_ly2", "0.00", 9, 55, 50);
    lb_ly3      = LM.Add("lb_ly3", "Lot:", 9, 130, 50);
    lb_ly4      = LM.Add("lb_ly4", "0.00", 9, 155, 50);
    lb_ly5      = LM.Add("lb_ly5", "Rebate:", 9, 200, 50);
    lb_ly6      = LM.Add("lb_ly6", "0.00", 9, 250, 50);

    lb_t_ln     = LM.Add("lb_t_ln", "---------------------------------------------------------------", 0, 10, 35);

    lb_sa1      = LM.Add("lb_sa1", "Total:", 10, 10, 20);
    lb_sa2      = LM.Add("lb_sa2", "0.00", 10, 55, 20);
    lb_sa3      = LM.Add("lb_sa3", "Lot:", 10, 130, 20);
    lb_sa4      = LM.Add("lb_sa4", "0.00", 10, 155, 20);
    lb_sa5      = LM.Add("lb_sa5", "Rebate:", 10, 200, 20);
    lb_sa6      = LM.Add("lb_sa6", "0.00", 10, 250, 20);
  }
  

  LM.Get(lb_band).SetSize(15);
  LM.Get(lb_band).SetColor(clrDeepSkyBlue);
  LM.Get(lb_fb).SetColor(clrGoldenrod);
  LM.Get(lb_t_acc).SetColor(clrLightSlateGray);
  LM.Get(lb_t_res).SetColor(clrLightSlateGray);
  LM.Get(lb_t_cas).SetColor(clrLightSlateGray);
  LM.Get(lb_t_ln).SetColor(clrLightSlateGray);
}

void SortObject()
{
  // ------------- Label -------------
  if(Label_Position == Button_Position)
  {
    for (int i = 0; i < LM.Count(); i++)
    {
      LM.Get(i).MoveY(LM.Get(i).y + 60);
    }
  } 

  if(Label_Position == TOP_RIGHT || Label_Position == BOTTOM_RIGHT)
  {
    int cur_group = 0;
    int oldX = 0;

    for (int i = 0; i < LM.Count(); i++)
    {
      if(LM.Get(i).group == 0)
      {
        LM.Get(i).MoveX(LM.Get(i).x + 280);
        
      } else {
        if(cur_group != LM.Get(i).group)
        {
          cur_group = LM.Get(i).group;
          oldX = LM.Get(i).x;
          LM.Get(i).MoveX(LM.Get(i).x + 280);
        } else {
          int prev = LM.Get(i-1).x;
          int cur = LM.Get(i).x;

          int diff = cur - oldX;
          int newX = prev - diff;
          LM.Get(i).MoveX(newX);
          oldX = cur;
        }
      }
      
      if(Label_Position == BOTTOM_RIGHT && Label_Position != Button_Position)
      {
        LM.Get(i).MoveY(LM.Get(i).y + 20);
      }
    }
  }
  else if(Label_Position == BOTTOM_LEFT && Label_Position != Button_Position)
  {
    for (int i = 0; i < LM.Count(); i++)
    {
      LM.Get(i).MoveY(LM.Get(i).y + 20);
    }
  }
  
  // ------------- Button -------------
  int btnX = 0;
  int space = 10;

  if(Button_Position == TOP_LEFT || Button_Position == BOTTOM_LEFT)
  {
    for (int i = 0; i < ArraySize(objButton); i++)
    {
      btnX += space;
      if(i > 0)
        btnX += objButton[i-1].width;
      
      objButton[i].disX = btnX;
    }
  } 
  else if(Button_Position == TOP_RIGHT || Button_Position == BOTTOM_RIGHT)
  {
    for (int i = ArraySize(objButton) - 1; i >= 0; i--)
    {
      btnX = objButton[i].width + space;

      if(i < ArraySize(objButton) - 1)
        btnX += objButton[i+1].disX;
      
      objButton[i].disX = btnX;
    }
  }
}

void RefreshButton(Button &btn, bool key)
{
  string btnText = btn.text;
  color clrText = btn.clrText;
  color clrBg = btn.clrBackground;

  if (btn.name == BTN1)
  {
    btnText += key ? " [ON]" : " [OFF]";
    clrText = key ? clrText : clrDimGray;
    clrBg = key ? clrBg : clrDarkGray;
  }
  else if (btn.name == BTN2)
  {
  }

  CreateButton(btn, btnText, clrText, clrBg);
}

void OnDeinit(const int reason)
{
  ObjectDelete(0, BTN1);
  ObjectDelete(0, BTN2);
  LM.DeleteAll();
}

void UpdateLabels()
{
  LM.Get(lb_ab2).SetText(NumberFormat((string)AccountInfoDouble(ACCOUNT_BALANCE)));

  LM.Get(lb_od2).SetText((string)TotalOrdersCount);
  LM.Get(lb_od4).SetText((string)BuyOrdersCount);
  LM.Get(lb_od6).SetText((string)SellOrdersCount);

  LM.Get(lb_lt2).SetText(DoubleToString(TotalLot, 2));
  LM.Get(lb_lt4).SetText(DoubleToString(BuyLot, 2));
  LM.Get(lb_lt6).SetText(DoubleToString(SellLot, 2));

  LM.Get(lb_pf2).SetText(DoubleToString(NetProfitTotal, 1));
  LM.Get(lb_pf4).SetText(DoubleToString(BuyProfitTotal, 1));
  LM.Get(lb_pf6).SetText(DoubleToString(SellProfitTotal, 1));

  LM.Get(lb_dd2).SetText(NumberFormat((string)maxDrawDown));
  LM.Get(lb_dd3).SetText("("+NumberFormat((string)maxDD_Per)+"%)");
}

void CalculateReport()
{
  datetime from_time = St_Date;
  datetime to_time   = TimeCurrent();

  if(HistorySelect(from_time, to_time))
  {
    int total_deals   = HistoryDealsTotal();

    double _day = 0;
    double _week = 0;
    double _month = 0;
    double _year = 0;
    double _total = 0;

    double _day_lot = 0;
    double _week_lot = 0;
    double _month_lot = 0;
    double _year_lot = 0;
    double _total_lot = 0;

    for(int i = 0; i < total_deals; i++)
    {
      ulong deal_ticket = HistoryDealGetTicket(i);
      string symbol     = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);

      if(symbol != _Symbol)
      {  
          continue;
      }

      long deal_entry   = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      long deal_type    = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
      long magic        = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      double lot        = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
      double swap       = HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
      double comm       = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
      double profit     = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) + swap + comm;
      long close_time   = HistoryDealGetInteger(deal_ticket, DEAL_TIME_MSC);
      
      if(deal_entry == DEAL_ENTRY_OUT)// only closed order
      {
        if(close_time > dtToday)
        {
          _day += profit;
          _day_lot += lot;
        }
        if(close_time > dt7DaysAgo)
        {
          _week += profit;
          _week_lot += lot;
        }
        if(close_time > dt30DaysAgo)
        {
          _month += profit;
          _month_lot += lot;
        }
        if(close_time > dt365DaysAgo)
        {
          _year += profit;
          _year_lot += lot;
        }
        _total += profit;
        _total_lot += lot;
      }
    }

    LM.Get(lb_td2).SetText(NumberFormat((string)_day));
    LM.Get(lb_td4).SetText(NumberFormat((string)_day_lot));
    LM.Get(lb_lw2).SetText(NumberFormat((string)_week));
    LM.Get(lb_lw4).SetText(NumberFormat((string)_week_lot));
    LM.Get(lb_lm2).SetText(NumberFormat((string)_month));
    LM.Get(lb_lm4).SetText(NumberFormat((string)_month_lot));
    LM.Get(lb_ly2).SetText(NumberFormat((string)_year));
    LM.Get(lb_ly4).SetText(NumberFormat((string)_year_lot));
    LM.Get(lb_sa2).SetText(NumberFormat((string)_total));
    LM.Get(lb_sa4).SetText(NumberFormat((string)_total_lot));
  }
}

void OnTick()
{
  datetime curDate  = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
  dtToday           = curDate;
  dt7DaysAgo        = curDate - 6*24*60*60;
  dt30DaysAgo       = curDate - 29*24*60*60;
  dt365DaysAgo      = curDate - 364*24*60*60;

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
  CalculateReport();
  UpdateTotalsInPoints();
  UpdateLabels();
  // return;

  if(CloseSideIfTargetReached())
  {
    return;
  }
  
  if (TotalOrdersCount >= Remove_At && FNC_Auto_Remove)
  {
    CloseOrderConditions();
  }

  if (!(Limit_Order && TotalOrdersCount >= LimitAmount))
  {
    CheckAndOpenOrders();
  }
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

void CloseOrderConditions()
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

//+------------------------------------------------------------------+
//| Process Auto Close V2 Logic                                      |
//+------------------------------------------------------------------+
void ProcessCloseV2()
{
  string txt_name = ea_name + " | Type: 2";
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
        double lots = PositionGetDouble(POSITION_VOLUME);
        double swap = PositionGetDouble(POSITION_SWAP);
        InsertArrayLoss("ASC", posTicket, (int)posType, lots, profit, swap);
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
          double lots = PositionGetDouble(POSITION_VOLUME);
          double swap = PositionGetDouble(POSITION_SWAP);
          sum_all_profit = sum_all_profit + profit;
          InsertArrayProfit("DESC", posTicket, (int)posType, lots, profit, swap);
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

  // -------------------------------------------------------------------------------------
  // ( 4 ) Last step if got Profit(+) after closed [Too much profit], remove more to make it equal zero(0)
  // -------------------------------------------------------------------------------------
  money_after_closed = profitTotal + lossTotal;
  string txtLoss = "";
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
            double lots = PositionGetDouble(POSITION_VOLUME);
            double swap = PositionGetDouble(POSITION_SWAP);

            lossTotal2 = lossTotal2 + profit;
            InsertArrayLoss("ASC", posTicket, (int)posType, lots, profit, swap);
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
  string txt_name = ea_name + " | Type: 3";

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

  Print(txt_name + "\n\n Money result: Profit[" + DoubleToString(profitTotal, 2) + "] - Loss[" + DoubleToString(lossTotal, 2) + "] = Net[" + DoubleToString(netTotal, 2) + "]" + "\n Orders removed: Buy[" + IntegerToString(removed_buy) + "] + Sell[" + IntegerToString(removed_sell) + "] = Total[" + IntegerToString(removed) + "]");
}

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
      double lots = PositionGetDouble(POSITION_VOLUME);
      double swap = PositionGetDouble(POSITION_SWAP);

      // Profit orders(+) | Sum all profit
      if (profit > 0)
      {
        profitTotal = profitTotal + profit;
        AddKeyValue(arrProfit, posTicket, (int)posType, lots, profit, swap);
      }

      // Loss orders(-) | Put loss orders in array
      if (profit < 0)
      {
        InsertMultiArray("DESC", posTicket, (int)posType, lots, profit, swap);
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

//+------------------------------------------------------------------+
//| Button Session                                                   |
//+------------------------------------------------------------------+
void CreateButton(Button &btn, string text, color textColor, color backColor)
{
  if (ObjectFind(0, btn.name) != -1)
    ObjectDelete(0, btn.name);

  ObjectCreate(0, btn.name, OBJ_BUTTON, 0, 0, 0);

  int disX = btn.disX;
  int disY = 0;
  int spaceY = 10;

  if(Button_Position == TOP_LEFT || Button_Position == TOP_RIGHT)
  {
    disY = btn.higth - spaceY;
  } 
  else if(Button_Position == BOTTOM_LEFT || Button_Position == BOTTOM_RIGHT)
  {
    disY = btn.higth + spaceY;
  }

  ObjectSetInteger(0, btn.name, OBJPROP_CORNER, Button_Position);
  ObjectSetInteger(0, btn.name, OBJPROP_XDISTANCE, disX);
  ObjectSetInteger(0, btn.name, OBJPROP_YDISTANCE, disY);
  ObjectSetInteger(0, btn.name, OBJPROP_XSIZE, btn.width);
  ObjectSetInteger(0, btn.name, OBJPROP_YSIZE, btn.higth);

  ObjectSetInteger(0, btn.name, OBJPROP_COLOR, textColor);
  ObjectSetString(0, btn.name, OBJPROP_TEXT, text);
  ObjectSetInteger(0, btn.name, OBJPROP_FONTSIZE, 12);
  ObjectSetString(0, btn.name, OBJPROP_FONT, "Arial");

  // ปรับสีพื้นหลัง (รองรับ)
  ObjectSetInteger(0, btn.name, OBJPROP_BGCOLOR, backColor);
  // ทำให้ปุ่มดูโค้ง (แบบจำลอง ด้วย BORDER_FLAT)
  ObjectSetInteger(0, btn.name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
}

//+------------------------------------------------------------------+
//| Process Sesesion                                                 |
//+------------------------------------------------------------------+
void SetButtonEnabled(string name, bool enabled)
{
  if (enabled)
  {
    // สีตอน enabled
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlue);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, !enabled);
    ObjectSetString(0, name, OBJPROP_TOOLTIP, "Click");
  }
  else
  {
    // สีตอน disable
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrDarkGray);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, !enabled);
    ObjectSetString(0, name, OBJPROP_TOOLTIP, "Disabled");
  }
}

//+------------------------------------------------------------------+
//| Event Sesesion                                                   |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
  if (id == CHARTEVENT_OBJECT_CLICK)
  {
    if (sparam == BTN1)
    {
      FNC_Auto_Remove = !FNC_Auto_Remove;
      RefreshButton(objButton[0], FNC_Auto_Remove);
    }

    if (sparam == BTN2)
    {
      if (TotalOrdersCount >= Remove_At)
      {
        CloseOrderConditions();
      }
      else
      {
        Alert("Current orders less than ", Remove_At);
      }
    }
  }
}