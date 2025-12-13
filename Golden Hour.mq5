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

string Comp_Name = "Local FX";
string EA_Name = "Golden_Hour";
int slipp = 20;

enum AccCurrency
{
   USD = 1, // USD
   CNT = 100 // CENT
};

enum Switcher
{
   ON = 1,
   OFF = 0
};

enum Notify
{
   NTF_0M   = 0,     // OFF
   NTF_1M   = 60,    // 1 Minutes
   NTF_10M  = 600,   // 10 Minutes
   NTF_15M  = 900,   // 15 Minutes
   NTF_30M  = 1800,  // 30 Minutes
   NTF_1H   = 3600,  // 1 Hour
   NTF_2H   = 7200,  // 2 Hours
   NTF_4H   = 14400, // 4 Hours
   NTF_8H   = 28800, // 8 Hours
   NTF_12H  = 43200  // 12 Hours
};

enum Position
{
   TOP_LEFT  = 0,
   TOP_RIGHT = 3,
   BOTTOM_LEFT = 1,
   BOTTOM_RIGHT  = 2
};

enum InpTimeframe
{
  TF_1M   = PERIOD_M15,  // 1 Minute
  TF_2M   = PERIOD_M2,   // 2 Minutes
  TF_3M   = PERIOD_M3,   // 3 Minutes
  TF_4M   = PERIOD_M4,   // 4 Minutes
  TF_5M   = PERIOD_M5,   // 5 Minutes
  TF_6M   = PERIOD_M6,   // 6 Minutes
  TF_10M  = PERIOD_M10,  // 10 Minutes
  TF_12M  = PERIOD_M12,  // 12 Minutes
  TF_15M  = PERIOD_M15,  // 15 Minutes
  TF_20M  = PERIOD_M20,  // 20 Minutes
  TF_30M  = PERIOD_M30,  // 30 Minutes
  TF_1H   = PERIOD_H1,   // 1 Hour
  TF_2H   = PERIOD_H2,   // 2 Hours
  TF_3H   = PERIOD_H3,   // 3 Hours
  TF_4H   = PERIOD_H4,   // 4 Hours
  TF_6H   = PERIOD_H6,   // 6 Hours
  TF_8H   = PERIOD_H8,   // 8 Hours
  TF_12H  = PERIOD_H12,  // 12 Hours
  TF_1D   = PERIOD_D1,   // 1 Day
  TF_1W   = PERIOD_W1,   // 1 Week
  TF_MN   = PERIOD_MN1   // 1 Month
};

const input string _____Account_____ = "=========== Account ===========";
input double Acc_Rebate         = 8;     // Rebate
double _rebate                  = 0;
input AccCurrency Acc_Currency  = CNT;   // ประเภทบัญชี

const input string _____Trading_____ = "============ Trading ============";
input InpTimeframe Time_frame = TF_30M; // ออกออเดอร์ทุกๆ นาที/ชั่วโมง/...
input double Lot_Size = 0.01; // ขนาด Lot
input double Target = 50.0; // Target

const input string _____Auto_Remove_Order_____ = "======== Auto Remove Order ========";
input Switcher Auto_Remove = false; // โหมดปิดออเดอร์อัตโนมัติ (เฉพาะออเดอร์ที่ปิดได้)
bool FNC_Auto_Remove = false;
input int Remove_At = 500; // ปิดอัตโนมัติ เมื่อออเดอร์ถึงจำนวน...
input int Remove_Percent = 20; // จำนวนออเดอร์ที่ต้องการลบ (คิดเป็น % ของจำนวนที่กำหนดไว้)

const input string _____Limit_Order_____ = "=========== Limit Order ===========";
input Switcher Limit_Order = false; // จำกัดการออกออเดอร์
input int LimitAmount = 500; // เมื่อถึงจำนวน ... ไม้ จะไม่ออกออเดอร์เพิ่ม

const input string _____Martingel_____ = "=========== Martingel ===========";
input Switcher Martingel_MODE    = ON;  // โหมด Martingel
input int    Martingel_at        = 100;  // Martingel เมื่อ Buy หรือ Sell ถึงจำนวน ... ไม้ 
input double Limit_lot_size      = 10.00;  // กำหนด Lot size สูงสุดที่จะออกได้
double       Avg_dist_should_be  = 0;
int          Avg_start_mtgl      = 0;

const input string _____Notification_____ = "=========== Notification ==========";
input Notify Notify_Timer     = NTF_0M; // แจ้งเตือนทุกๆ นาที,ชั่วโมง
input int Notify_DD           = 0;  // แจ้งเตือนเมื่อ Draw Down ถึง ... %
double Notify_DD_per          = 0;
input int Notify_Orders       = 0;  // แจ้งเตือนเมื่อจำนวน Order ถึง ...

const input string _____UI_Position_____ = "============ UI Setting ============";
input Position Button_Position = TOP_RIGHT; // ตำแหน่งของปุ่ม
input Position Label_Position = TOP_LEFT; // ตำแหน่งของรายละเอียด
input datetime St_Date = D'2026.01.01 00:00'; // คำนวณสถิติตั้งแต่วันที่

// ----- [Casual]
long   acc_id        = AccountInfoInteger(ACCOUNT_LOGIN);
string ac_currency   = AccountInfoString(ACCOUNT_CURRENCY);
double first_balance = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_balance = AccountInfoDouble(ACCOUNT_BALANCE);
double acc_profit = AccountInfoDouble(ACCOUNT_PROFIT);
double maxDrawDown = 0;
double maxDD_Per = 0;
double curDD_Per     = 0;

string   _symbol           = _Symbol;
double   _ask              = 0;
double   _bid              = 0;
double   _point            = _Point;
int      _digits           = _Digits;

int totalOrders = 0;
int countBuy = 0;
int countSell = 0;

double TotalLot = 0;
double sumLotBuy = 0;
double sumLotSell = 0;

double currentBuyProfit = 0.0;  // sum of buy profit (money: profit+swap+commission)
double currentSellProfit = 0.0; // sum of sell profit (money: profit+swap+commission)
double NetProfitTotal = 0.0;  // currentBuyProfit + currentSellProfit (money)

double highest_loss = 0;
double highest_profit = 0;
// ----- [Casual]

// ----- [Label]
// Label Class
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
      ObjectSetString(0, name, OBJPROP_TOOLTIP, "");
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

// Manager Class
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

datetime dtToday, dt7DaysAgo, dt30DaysAgo, dt365DaysAgo;
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

// ----- [Average]
// Normal
bool show_avg_line = true;
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
// ----- [Auto Close]

// ----- [Email]
datetime lastNotify = 0;
// ----- [Email]

void LoadVariable()
{
   if (GlobalVariableCheck(EA_Name+"gblLastNotificate"+_symbol))
   {
      lastNotify = (datetime)GlobalVariableGet(EA_Name+"gblLastNotificate"+_symbol);
   }
}

void SaveLastNotificate(double data)
{
  GlobalVariableSet(EA_Name+"gblLastNotificate"+_symbol, data);
}

//+----------------------------------------+
//| Initialize                             |
//+----------------------------------------+
int OnInit()
{
  MustRemove = (int)MathCeil((Remove_At * Remove_Percent) / 100);
  FNC_Auto_Remove = Auto_Remove;
  Notify_DD_per = (Notify_DD / 100) * -1;
  _rebate = Acc_Rebate / Acc_Currency;
  point_avg = _Point * PipAdjust;

  CreateAverageLine();
  CreateLabel();
  SortObject();
  RefreshButton(objButton[0], FNC_Auto_Remove);
  RefreshButton(objButton[1], false);

  return (INIT_SUCCEEDED);
}

//+----------------------------------------+
//| De-Initialize                          |
//+----------------------------------------+
void OnDeinit(const int reason)
{
  ObjectDelete(0, BTN1);
  ObjectDelete(0, BTN2);
  LM.DeleteAll();
}

//+----------------------------------------+
//| On Tick                                |
//+----------------------------------------+
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
  curDD_Per = (acc_profit / acc_balance) * 100;

  _ask     = SymbolInfoDouble(_symbol,SYMBOL_ASK);
  _bid     = SymbolInfoDouble(_symbol,SYMBOL_BID);

  ResetProfitParams();
  CalculateReport();
  UpdateTotalsInPoints();
  NotifyEmail();
  UpdateLabels();
  UpdateAverageLine();
  ShowComment();
  // return;

  if(CloseSideIfTargetReached())
  {
    return;
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
// ----- [All objects]
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
        LM.Get(i).MoveX(LM.Get(i).x + 400);
        
      } else {
        if(cur_group != LM.Get(i).group)
        {
          cur_group = LM.Get(i).group;
          oldX = LM.Get(i).x;
          LM.Get(i).MoveX(LM.Get(i).x + 400);
        } else {
          int prev = LM.Get(i-1).x;
          int cur = LM.Get(i).x;

          int diff = cur - oldX;
          int newX = prev - diff;
          LM.Get(i).MoveX(newX);
          oldX = cur;
        }
      }
      
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
// ----- [All objects]

// ----- [Label]
void CreateLabel()
{
  if(Label_Position == TOP_LEFT || Label_Position == TOP_RIGHT)
  {
    lb_band     = LM.Add("lb_band", Comp_Name+" | "+EA_Name, 0, 10, 20);
    lb_fb       = LM.Add("lb_fb", "www.facebook.com/LocalFX4U", 0, 10, 43);

    lb_t_acc    = LM.Add("lb_t_acc", "===================== Account =====================", 0, 10, 65);
    lb_ab1      = LM.Add("lb_ab1", "Account balance:", 1, 10, 80);
    lb_ab2      = LM.Add("lb_ab2", "-", 1, 170, 80);

    lb_t_cas    = LM.Add("lb_t_cas", "======================= Trade =====================", 0, 10, 100);
    lb_od1      = LM.Add("lb_od1", "Total Order:", 2, 10, 115);
    lb_od2      = LM.Add("lb_od2", "-", 2, 80, 115);
    lb_od3      = LM.Add("lb_od3", "Buy:", 2, 170, 115);
    lb_od4      = LM.Add("lb_od4", "-", 2, 200, 115);
    lb_od5      = LM.Add("lb_od5", "Sell:", 2, 290, 115);
    lb_od6      = LM.Add("lb_od6", "-", 2, 320, 115);

    lb_lt1      = LM.Add("lb_lt1", "Total Lot:", 3, 10, 130);
    lb_lt2      = LM.Add("lb_lt2", "-", 3, 80, 130);
    lb_lt3      = LM.Add("lb_lt3", "Buy:", 3, 170, 130);
    lb_lt4      = LM.Add("lb_lt4", "-", 3, 200, 130);
    lb_lt5      = LM.Add("lb_lt5", "Sell:", 3, 290, 130);
    lb_lt6      = LM.Add("lb_lt6", "-", 3, 320, 130);

    lb_pf1      = LM.Add("lb_pf1", "Net Profit:", 3, 10, 145);
    lb_pf2      = LM.Add("lb_pf2", "-", 3, 80, 145);
    lb_pf3      = LM.Add("lb_pf3", "Buy:", 3, 170, 145);
    lb_pf4      = LM.Add("lb_pf4", "-", 3, 200, 145);
    lb_pf5      = LM.Add("lb_pf5", "Sell:", 3, 290, 145);
    lb_pf6      = LM.Add("lb_pf6", "-", 3, 320, 145);

    lb_t_res    = LM.Add("lb_t_res", "======================= Result ====================", 0, 10, 165);
    lb_dd1      = LM.Add("lb_dd1", "Max DD:", 4, 10, 185);
    lb_dd2      = LM.Add("lb_dd2", "-", 4, 80, 185);
    lb_dd3      = LM.Add("lb_dd3", "-", 4, 200, 185);

    lb_td1      = LM.Add("lb_td1", "Today:", 6, 10, 210);
    lb_td2      = LM.Add("lb_td2", "0.00", 6, 55, 210);
    lb_td3      = LM.Add("lb_td3", "Lot:", 6, 170, 210);
    lb_td4      = LM.Add("lb_td4", "0.00", 6, 200, 210);
    lb_td5      = LM.Add("lb_td5", "Rebate:", 6, 290, 210);
    lb_td6      = LM.Add("lb_td6", "0.00", 6, 340, 210);

    lb_lw1      = LM.Add("lb_lw1", "Week:", 7, 10, 225);
    lb_lw2      = LM.Add("lb_lw2", "0.00", 7, 55, 225);
    lb_lw3      = LM.Add("lb_lw3", "Lot:", 7, 170, 225);
    lb_lw4      = LM.Add("lb_lw4", "0.00", 7, 200, 225);
    lb_lw5      = LM.Add("lb_lw5", "Rebate:", 7, 290, 225);
    lb_lw6      = LM.Add("lb_lw6", "0.00", 7, 340, 225);

    lb_lm1      = LM.Add("lb_lm1", "Month:", 8, 10, 240);
    lb_lm2      = LM.Add("lb_lm2", "0.00", 8, 55, 240);
    lb_lm3      = LM.Add("lb_lm3", "Lot:", 8, 170, 240);
    lb_lm4      = LM.Add("lb_lm4", "0.00", 8, 200, 240);
    lb_lm5      = LM.Add("lb_lm5", "Rebate:", 8, 290, 240);
    lb_lm6      = LM.Add("lb_lm6", "0.00", 8, 340, 240);

    lb_ly1      = LM.Add("lb_ly1", "Year:", 9, 10, 255);
    lb_ly2      = LM.Add("lb_ly2", "0.00", 9, 55, 255);
    lb_ly3      = LM.Add("lb_ly3", "Lot:", 9, 170, 255);
    lb_ly4      = LM.Add("lb_ly4", "0.00", 9, 200, 255);
    lb_ly5      = LM.Add("lb_ly5", "Rebate:", 9, 290, 255);
    lb_ly6      = LM.Add("lb_ly6", "0.00", 9, 340, 255);

    lb_t_ln     = LM.Add("lb_t_ln", "________________________________________________________", 0, 10, 263);

    lb_sa1      = LM.Add("lb_sa1", "Total:", 10, 10, 285);
    lb_sa2      = LM.Add("lb_sa2", "0.00", 10, 55, 285);
    lb_sa3      = LM.Add("lb_sa3", "Lot:", 10, 170, 285);
    lb_sa4      = LM.Add("lb_sa4", "0.00", 10, 200, 285);
    lb_sa5      = LM.Add("lb_sa5", "Rebate:", 10, 290, 285);
    lb_sa6      = LM.Add("lb_sa6", "0.00", 10, 340, 285);
  } 
  else if (Label_Position == BOTTOM_LEFT || Label_Position == BOTTOM_RIGHT)
  {
    lb_band     = LM.Add("lb_band", Comp_Name+" | "+EA_Name, 0, 10, 305);
    lb_fb       = LM.Add("lb_fb", "www.facebook.com/LocalFX4U", 0, 10, 282);

    lb_t_acc    = LM.Add("lb_t_acc", "===================== Account =====================", 0, 10, 260);
    lb_ab1      = LM.Add("lb_ab1", "Account balance:", 1, 10, 245);
    lb_ab2      = LM.Add("lb_ab2", "-", 1, 170, 245);

    lb_t_cas    = LM.Add("lb_t_cas", "======================= Trade =====================", 0, 10, 225);
    lb_od1      = LM.Add("lb_od1", "Total Order:", 2, 10, 210);
    lb_od2      = LM.Add("lb_od2", "-", 2, 80, 210);
    lb_od3      = LM.Add("lb_od3", "Buy:", 2, 170, 210);
    lb_od4      = LM.Add("lb_od4", "-", 2, 200, 210);
    lb_od5      = LM.Add("lb_od5", "Sell:", 2, 290, 210);
    lb_od6      = LM.Add("lb_od6", "-", 2, 320, 210);

    lb_lt1      = LM.Add("lb_lt1", "Total Lot:", 3, 10, 195);
    lb_lt2      = LM.Add("lb_lt2", "-", 3, 80, 195);
    lb_lt3      = LM.Add("lb_lt3", "Buy:", 3, 170, 195);
    lb_lt4      = LM.Add("lb_lt4", "-", 3, 200, 195);
    lb_lt5      = LM.Add("lb_lt5", "Sell:", 3, 290, 195);
    lb_lt6      = LM.Add("lb_lt6", "-", 3, 320, 195);

    lb_pf1      = LM.Add("lb_pf1", "Net Profit:", 3, 10, 180);
    lb_pf2      = LM.Add("lb_pf2", "-", 3, 80, 180);
    lb_pf3      = LM.Add("lb_pf3", "Buy:", 3, 170, 180);
    lb_pf4      = LM.Add("lb_pf4", "-", 3, 200, 180);
    lb_pf5      = LM.Add("lb_pf5", "Sell:", 3, 290, 180);
    lb_pf6      = LM.Add("lb_pf6", "-", 3, 320, 180);

    lb_t_res    = LM.Add("lb_t_res", "======================= Result ====================", 0, 10, 160);
    lb_dd1      = LM.Add("lb_dd1", "Max DD:", 4, 10, 140);
    lb_dd2      = LM.Add("lb_dd2", "-", 4, 80, 140);
    lb_dd3      = LM.Add("lb_dd3", "-", 4, 200, 140);

    lb_td1      = LM.Add("lb_td1", "Today:", 6, 10, 115);
    lb_td2      = LM.Add("lb_td2", "0.00", 6, 55, 115);
    lb_td3      = LM.Add("lb_td3", "Lot:", 6, 170, 115);
    lb_td4      = LM.Add("lb_td4", "0.00", 6, 200, 115);
    lb_td5      = LM.Add("lb_td5", "Rebate:", 6, 290, 115);
    lb_td6      = LM.Add("lb_td6", "0.00", 6, 340, 115);

    lb_lw1      = LM.Add("lb_lw1", "Week:", 7, 10, 100);
    lb_lw2      = LM.Add("lb_lw2", "0.00", 7, 55, 100);
    lb_lw3      = LM.Add("lb_lw3", "Lot:", 7, 170, 100);
    lb_lw4      = LM.Add("lb_lw4", "0.00", 7, 200, 100);
    lb_lw5      = LM.Add("lb_lw5", "Rebate:", 7, 290, 100);
    lb_lw6      = LM.Add("lb_lw6", "0.00", 7, 340, 100);

    lb_lm1      = LM.Add("lb_lm1", "Month:", 8, 10, 85);
    lb_lm2      = LM.Add("lb_lm2", "0.00", 8, 55, 85);
    lb_lm3      = LM.Add("lb_lm3", "Lot:", 8, 170, 85);
    lb_lm4      = LM.Add("lb_lm4", "0.00", 8, 200, 85);
    lb_lm5      = LM.Add("lb_lm5", "Rebate:", 8, 290, 85);
    lb_lm6      = LM.Add("lb_lm6", "0.00", 8, 340, 85);

    lb_ly1      = LM.Add("lb_ly1", "Year:", 9, 10, 70);
    lb_ly2      = LM.Add("lb_ly2", "0.00", 9, 55, 70);
    lb_ly3      = LM.Add("lb_ly3", "Lot:", 9, 170, 70);
    lb_ly4      = LM.Add("lb_ly4", "0.00", 9, 200, 70);
    lb_ly5      = LM.Add("lb_ly5", "Rebate:", 9, 290, 70);
    lb_ly6      = LM.Add("lb_ly6", "0.00", 9, 340, 70);

    lb_t_ln     = LM.Add("lb_t_ln", "________________________________________________________", 0, 10, 63);

    lb_sa1      = LM.Add("lb_sa1", "Total:", 10, 10, 40);
    lb_sa2      = LM.Add("lb_sa2", "0.00", 10, 55, 40);
    lb_sa3      = LM.Add("lb_sa3", "Lot:", 10, 170, 40);
    lb_sa4      = LM.Add("lb_sa4", "0.00", 10, 200, 40);
    lb_sa5      = LM.Add("lb_sa5", "Rebate:", 10, 290, 40);
    lb_sa6      = LM.Add("lb_sa6", "0.00", 10, 340, 40);
  }
  
  LM.Get(lb_band).SetSize(15);
  LM.Get(lb_band).SetColor(clrDeepSkyBlue);
  LM.Get(lb_fb).SetColor(clrGoldenrod);
  LM.Get(lb_t_acc).SetColor(clrLightSlateGray);
  LM.Get(lb_t_res).SetColor(clrLightSlateGray);
  LM.Get(lb_t_cas).SetColor(clrLightSlateGray);
  LM.Get(lb_t_ln).SetColor(clrLightSlateGray);
}

void UpdateLabels()
{
  LM.Get(lb_ab2).SetText(NumberFormat((string)AccountInfoDouble(ACCOUNT_BALANCE)));

  LM.Get(lb_od2).SetText((string)totalOrders);
  LM.Get(lb_od4).SetText((string)countBuy);
  LM.Get(lb_od6).SetText((string)countSell);

  LM.Get(lb_lt2).SetText(NumberFormat((string)TotalLot));
  LM.Get(lb_lt4).SetText(NumberFormat((string)sumLotBuy));
  LM.Get(lb_lt6).SetText(NumberFormat((string)sumLotSell));

  LM.Get(lb_pf2).SetText(NumberFormat((string)NetProfitTotal));
  LM.Get(lb_pf4).SetText(NumberFormat((string)currentBuyProfit));
  LM.Get(lb_pf6).SetText(NumberFormat((string)currentSellProfit));

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
      datetime _close_time = (datetime)(close_time / 1000);
      
      if(deal_entry == DEAL_ENTRY_OUT)// only closed order
      {
        if(_close_time > dtToday)
        {
          _day += profit;
          _day_lot += lot;
        }
        if(_close_time > dt7DaysAgo)
        {
          _week += profit;
          _week_lot += lot;
        }
        if(_close_time > dt30DaysAgo)
        {
          _month += profit;
          _month_lot += lot;
        }
        if(_close_time > dt365DaysAgo)
        {
          _year += profit;
          _year_lot += lot;
        }
        _total += profit;
        _total_lot += lot;
      }
    }

    double pd = _day > 0 ? (_day / (acc_balance - _day)) * 100 : _day / (acc_balance + _day) * 100;
    double pw = _week > 0 ? (_week / (acc_balance - _week)) * 100 : _week / (acc_balance + _week) * 100;
    double pm = _month > 0 ? (_month / (acc_balance - _month)) * 100 : _month / (acc_balance + _month) * 100;
    double py = _year > 0 ? (_year / (acc_balance - _year)) * 100 : _year / (acc_balance + _year) * 100;
    double pa = _total > 0 ? (_total / (acc_balance - _total)) * 100 : _total / (acc_balance + _total) * 100;

    double rb_d = _day_lot * _rebate;
    double rb_w = _week_lot * _rebate;
    double rb_m = _month_lot * _rebate;
    double rb_y = _year_lot * _rebate;
    double rb_a = _total_lot * _rebate;

    LM.Get(lb_td2).SetText(NumberFormat((string)pd)+"%");
    LM.Get(lb_td4).SetText(NumberFormat((string)_day_lot));
    LM.Get(lb_td6).SetText(NumberFormat((string)rb_d));
    LM.Get(lb_lw2).SetText(NumberFormat((string)pw)+"%");
    LM.Get(lb_lw4).SetText(NumberFormat((string)_week_lot));
    LM.Get(lb_lw6).SetText(NumberFormat((string)rb_w));
    LM.Get(lb_lm2).SetText(NumberFormat((string)pm)+"%");
    LM.Get(lb_lm4).SetText(NumberFormat((string)_month_lot));
    LM.Get(lb_lm6).SetText(NumberFormat((string)rb_m));
    LM.Get(lb_ly2).SetText(NumberFormat((string)py)+"%");
    LM.Get(lb_ly4).SetText(NumberFormat((string)_year_lot));
    LM.Get(lb_ly6).SetText(NumberFormat((string)rb_y));
    LM.Get(lb_sa2).SetText(NumberFormat((string)pa)+"%");
    LM.Get(lb_sa4).SetText(NumberFormat((string)_total_lot));
    LM.Get(lb_sa6).SetText(NumberFormat((string)rb_a));
  }
}
// ----- [Label]

// ----- [Button]
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
      if (totalOrders >= Remove_At)
      {
        AutomaticCloseOrders();
      }
      else
      {
        Alert("Current orders less than ", Remove_At);
      }
    }
  }
}
// ----- [Button]

// ----- [Average]
void CreateAverageLine()
{
  if(show_avg_line)
  {
    // --- Buy ---
    if(ObjectFind(0, avgBuy) != -1)
        ObjectDelete(0, avgBuy);

    if(ObjectFind(0, infoBuy) != -1)
        ObjectDelete(0, infoBuy);

    // avg line
    ObjectCreate(0, avgBuy, OBJ_HLINE, 0, 0, 0.00);
    ObjectSetInteger(0, avgBuy, OBJPROP_WIDTH, buy_line_width);
    ObjectSetInteger(0, avgBuy, OBJPROP_COLOR, buy_line_color);

    // text info
    ObjectCreate(0, infoBuy, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_buy_price);
    ObjectSetString(0, infoBuy, OBJPROP_TEXT, "-");
    ObjectSetInteger(0, infoBuy, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
    ObjectSetInteger(0, infoBuy, OBJPROP_COLOR, White);
    ObjectSetInteger(0, infoBuy, OBJPROP_FONTSIZE, font_info_size);
    ObjectSetString(0, infoBuy, OBJPROP_FONT, "Arial");
    
    // --- Sell ---
    if(ObjectFind(0, avgSell) != -1)
        ObjectDelete(0, avgSell);

    if(ObjectFind(0, infoSell) != -1)
        ObjectDelete(0, infoSell);

    // avg line
    ObjectCreate(0, avgSell, OBJ_HLINE, 0, 0, 0.00);
    ObjectSetInteger(0, avgSell, OBJPROP_WIDTH, sell_line_width);
    ObjectSetInteger(0, avgSell, OBJPROP_COLOR, sell_line_color);

    // text info
    ObjectCreate(0, infoSell, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_sell_price);
    ObjectSetString(0, infoSell, OBJPROP_TEXT, "-");
    ObjectSetInteger(0, infoSell, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
    ObjectSetInteger(0, infoSell, OBJPROP_COLOR, White);
    ObjectSetInteger(0, infoSell, OBJPROP_FONTSIZE, font_info_size);
    ObjectSetString(0, infoSell, OBJPROP_FONT, "Arial");
  }
}

void UpdateAverageLine()
{
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   // --- Avg Buy
   double Buy_distance = 0;
   if (countBuy > 0 && sumLotBuy != 0)
   {
      Buy_distance = (currentBuyProfit / (MathAbs(sumLotBuy * tick_value))) * tick_size;
      Average_buy_price = _bid - Buy_distance;
   }
   
  if(show_avg_line)
  {
      // update avg line
      ObjectSetDouble(0, avgBuy, OBJPROP_PRICE, Average_buy_price);

      // update text info
      ObjectCreate(0, infoBuy, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_buy_price);
      ObjectSetString(0, infoBuy, OBJPROP_TEXT, 
         StringFormat("[B]= %.*f | %.1f pips (%.2f %s) Lots= %.2f Orders= %d", 
            _digits, Average_buy_price,
            Buy_distance / point_avg, 
            currentBuyProfit, 
            AccountInfoString(ACCOUNT_CURRENCY), 
            sumLotBuy, countBuy
         )
      );
  }

   // --- Avg Sell
   double Sell_distance = 0;
   if (countSell > 0 && sumLotSell != 0)
   {
      Sell_distance = (currentSellProfit / (MathAbs(sumLotSell * tick_value))) * tick_size;
      Average_sell_price = _ask + Sell_distance;
   }

   if(show_avg_line)
   {
      // update avg line
      ObjectSetDouble(0, avgSell, OBJPROP_PRICE, Average_sell_price);

      // update text info
      ObjectCreate(0, infoSell, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), Average_sell_price);
      ObjectSetString(0, infoSell, OBJPROP_TEXT, 
         StringFormat("[S]= %.*f | %.1f pips (%.2f %s) Lots= %.2f Orders= %d", 
            _digits, Average_sell_price,
            Sell_distance / point_avg, 
            currentSellProfit, 
            AccountInfoString(ACCOUNT_CURRENCY), 
            sumLotSell, countSell
         )
      );
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
    double price = PositionGetDouble(POSITION_PRICE_OPEN);
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
    top_price = top_price == 0 ? price : price > top_price ? price : top_price;
    bottom_price = bottom_price == 0 ? price : price < bottom_price ? price : bottom_price;

    if(volume > Lot_Size)
    {
      Stack_biglot++;
    }
  }

  // --- Casual
  NetProfitTotal = currentBuyProfit + currentSellProfit;

  // --- Martingel OUT Loop
  middle_price = (top_price + bottom_price) / 2;
  range_price = (top_price - bottom_price) / _point;
  Highest_stack = Stack_biglot > Highest_stack ? Stack_biglot : Highest_stack;

  if(Avg_dist_should_be == 0 && (countBuy >= Martingel_at || countSell >= Martingel_at))
  {
    lock_range = range_price;
    Avg_dist_should_be = range_price * 0.1;
  }
}

bool CloseSideIfTargetReached()
{
  bool closeBuys = (currentBuyProfit >= Target);
  bool closeSells = (currentSellProfit >= Target);

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
      request.comment      = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;

      if (!OrderSend(request, result))
        PrintFormat("CloseSideIfTargetReached: close failed, ticket=%I64u retcode=%d comment=%s",
                    ticket, result.retcode, result.comment);
    }
  }

  return true;
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

  // Print("DEBUG: OpenPairOrders(_lot) called");
  if(Martingel_MODE && (countBuy >= Martingel_at || countSell >= Martingel_at))
  {
    MartingelCondition();

  } else {
    OpenPairOrders(Lot_Size);
  }
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
  request.comment      = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;
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
  request.comment      = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;
  if (!OrderSend(request, result))
    PrintFormat("Sell OrderSend failed. retcode=%d comment=%s",
                result.retcode, result.comment);
}

void OpenSingleOrder(ENUM_ORDER_TYPE type, double lot)
{
  MqlTradeRequest request;
  MqlTradeResult result;

  ZeroMemory(request);
  ZeroMemory(result);
  request.action = TRADE_ACTION_DEAL;
  request.symbol = _Symbol;
  request.volume = lot;
  request.deviation = 5;
  request.type = type;
  request.type_filling = ORDER_FILLING_IOC;
  request.comment      = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;
  if (!OrderSend(request, result))
    PrintFormat("Buy OrderSend failed. retcode=%d comment=%s",
                result.retcode, result.comment);
}

void MartingelCondition()
{
  int _dist_every = (int)(range_price / lock_range);

  if(countBuy >= Martingel_at)
  {
    double atlease_price = (bottom_price + (Avg_dist_should_be * _point));
    Print("======= Stack_biglot: ",Stack_biglot," | _dist_every",_dist_every);
    bool condition1 = _ask < Average_sell_price && _bid < Average_sell_price;
    bool condition2 = Stack_biglot < _dist_every;
    // bool condition2 = Average_sell_price < atlease_price;
    bool condition3 = Cur_avg_diff > Avg_dist_should_be;
    Print("======= condition1: ",condition1," | condition2: ",condition2," | condition3: ",condition3);

    if(condition1 && condition2 && condition3)
    {
      double newLot = CalculateBigLot("Buy");
      // Avg_dist_should_be = 0;
      OpenSingleOrder(ORDER_TYPE_BUY, newLot);
    } else {
      OpenSingleOrder(ORDER_TYPE_BUY, Lot_Size);
    }

    OpenSingleOrder(ORDER_TYPE_SELL, Lot_Size);
  }

  if(countSell >= Martingel_at)
  {
    double atlease_price = (top_price - (Avg_dist_should_be * _point));
    Print("======= Stack_biglot: ",Stack_biglot," | _dist_every",_dist_every);
    bool condition1 = _ask > Average_buy_price && _bid > Average_buy_price;
    bool condition2 = Stack_biglot < _dist_every;
    // bool condition2 = Average_sell_price < atlease_price;
    bool condition3 = Cur_avg_diff > Avg_dist_should_be;
    Print("======= condition1: ",condition1," | condition2: ",condition2," | condition3: ",condition3);

    if(condition1 && condition2 && condition3)
    {
      double newLot = CalculateBigLot("Sell");
      // Avg_dist_should_be = 0;
      OpenSingleOrder(ORDER_TYPE_SELL, newLot);
    } else {
      OpenSingleOrder(ORDER_TYPE_SELL, Lot_Size);
    }

    OpenSingleOrder(ORDER_TYPE_BUY, Lot_Size);
  }
}

void ShowComment()
{
  if(show_avg_line)
  {
    Comment(  "\n ===================================== "
           + " MTGL every:  " + NumberFormat((string)Avg_start_mtgl) // 15,000
           + "    |    Diff Should be : " + NumberFormat((string)Avg_dist_should_be) // 15000*10%=1,500
           + "    |    Current : " + NumberFormat((string)Cur_avg_diff) 
           + "    |    Lock : " + NumberFormat((string)lock_range) 
           + "\n ===================================== "
           + " Top:  " + NumberFormat((string)top_price)
           + "    |    Bottom:  " + NumberFormat((string)bottom_price)
           + "    |    Middle price:  " + NumberFormat((string)middle_price)
           + "    |    Range price:  " + NumberFormat((string)range_price)
           + "\n ===================================== "
           + " Highest Lot: " + DoubleToString(maxLot, 2)
           + "    |    Stack:  " + (string)Stack_biglot + " / " + (string)Highest_stack
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

  highest_loss = 0;
  highest_profit = 0;

  Average_buy_price    = 0;
  Average_sell_price   = 0;
  // Avg_dist_should_be   = 0;
  top_price            = 0;
  bottom_price         = 0;
  range_price          = 0;
  middle_price         = 0;
  Stack_biglot         = 0;
}

void NotifyEmail()
{
   if(Notify_Timer > 0)
   {
      datetime curDate = TimeCurrent();
      bool send1 = false;
      bool send2 = false;

      // Notify -> Draw Down
      if(curDD_Per <= Notify_DD_per && Notify_DD > 0)
      {
         int noti_diff = (int)(curDate - lastNotify);
         if (noti_diff >= (int)Notify_Timer)
         {
            string topic = (string)acc_id + "[" + _symbol + "] Draw Down: " + (string)NormalizeDouble(curDD_Per,2) + "% | " + EA_Name;
            string txtTimer = Notify_Timer < 3600 ? (string)((int)Notify_Timer / 60) + " นาที" : (string)((int)Notify_Timer / 3600) + " ชั่วโมง";
            string detail = "แจ้งเตือนอัตโนมัติทุกๆ "+ txtTimer +" จาก EA " + EA_Name + " เมื่อมี Draw Down ต่ำกว่า " + (string)Notify_DD + "%";
            SendMail(topic, detail);
            send1 = true;
         }
      }
      // Notify -> Orders
      if (totalOrders >= Notify_Orders && Notify_Orders > 0)
      {
         int noti_diff = (int)(curDate - lastNotify);
         if (noti_diff >= (int)Notify_Timer)
         {
            string topic = (string)acc_id + "[" + _symbol + "] Opening orders: " + (string)totalOrders + " | " + EA_Name;
            string txtTimer = Notify_Timer < 3600 ? (string)((int)Notify_Timer / 60) + " นาที" : (string)((int)Notify_Timer / 3600) + " ชั่วโมง";
            string detail = "แจ้งเตือนอัตโนมัติทุกๆ "+ txtTimer +" จาก EA " + EA_Name + " เมื่อเปิด order จำนวน " + (string)Notify_Orders + " หรือมากกว่า";
            SendMail(topic, detail);
            send2 = true;
         }
      }

      if(send1 || send2)
      {
         lastNotify = curDate;
         SaveLastNotificate((double)lastNotify);
      }
   }
}

double CalculateBigLot(string type)
{
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double newLot = Lot_Size;
   double step_lot = 0.01;

   double dummy_avg_buy = Average_buy_price <= 0 ? _bid : Average_buy_price;
   double dummy_avg_sell = Average_sell_price <= 0 ? _ask : Average_sell_price;

   double exit_target = Avg_dist_should_be;
   bool first_time = true;
   double res = 0;

   if(type == "Buy")
   {
      while (res >= exit_target || first_time)
      {
        if(Limit_lot_size > 0 && newLot >= Limit_lot_size)
          return newLot;

        first_time = false;
        newLot += step_lot;
        double dummy_distance = (currentBuyProfit / (MathAbs((sumLotBuy + newLot) * tick_value))) * tick_size;
        double dummy_avg = _bid - dummy_distance;
        res = (dummy_avg - dummy_avg_sell) / _Point;
        
      }
      return newLot;

   } else if(type == "Sell")
   {
      while (res >= exit_target || first_time)
      {
        if(Limit_lot_size > 0 && newLot >= Limit_lot_size)
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
// ----- [Helpers]

// ----- [Condition]

// ----- [Condition]

//+------------------------------------------------------------------+
//| Auto Close functions                                             |
//+------------------------------------------------------------------+
void AutomaticCloseOrders()
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
  request.comment      = "FB:" + Comp_Name + " ให้โรบอทช่วยคุณเทรด | " + EA_Name;

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
  swapTotal = 0;

  money_after_closed = 0; // V2
  netTotal = 0;           // V3
}

// ----- [Script V2]
void ProcessCloseV2()
{
  string txt_name = EA_Name + " | Type: 2";
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
// ----- [Script V2]

// ----- [Script V3]
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
// ----- [Script V3]