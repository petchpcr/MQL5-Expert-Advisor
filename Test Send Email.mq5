//+------------------------------------------------------------------+
//|                                             Test Send Email.mq5 |
//|                               Copyright 2021, UU School trading. |
//|                                https://www.facebook.com/uutrader |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, UU School trading."
#property link "https://www.facebook.com/uutrader"
#property version "1.00"

string EA_Name       = "Test";

#include <Controls\Dialog.mqh>
#include <Controls\Panel.mqh>
#include <Controls\Button.mqh>

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

const input string _____Notification_____ = "=========== Notification ==========";
input Notify Notify_Timer     = NTF_0M; // แจ้งเตือนทุกๆ นาที,ชั่วโมง
input int Notify_DD           = 0;  // แจ้งเตือนเมื่อ Draw Down ถึง ... %
double Notify_DD_per          = 0;
input int Notify_Orders       = 0;  // แจ้งเตือนเมื่อจำนวน Order ถึง ...

double curDD_Per = 0;

class CMainDialog : public CAppDialog
{
public:
   virtual void OnClickButtonClose()
   {
      Print("DEBUG: OnClickButtonClose - Prevented ExpertRemove.");
      // Destroy(); // Temporarily disabled to verify behavior
   }
};

CMainDialog *dlg;
CPanel *panel;
CButton *btn;

datetime lastNotify = 0;

int OnInit()
{
  Notify_DD_per = (double)Notify_DD * -1;
  LoadVariable();

  

  /*
  Print("DEBUG: OnInit Started");

  // Cleanup existing objects to prevent creation errors
  // Aggressively cleanup ANY object starting with these names
  // 0 = Main Window, -1 = All Object Types
  ObjectsDeleteAll(ChartID(), "MainDialog", 0, -1);
  ObjectsDeleteAll(ChartID(), "Panel1", 0, -1);
  ObjectsDeleteAll(ChartID(), "Button1", 0, -1);
  
  // Just in case, try to find if any exist and print
  if(ObjectFind(ChartID(), "MainDialog") >= 0) Print("DEBUG: WARNING - MainDialog still exists after delete attempt!");

  dlg = new CMainDialog();
  panel = new CPanel();
  btn = new CButton();

  // Check pointers using CheckPointer
  if(CheckPointer(dlg) == POINTER_INVALID || CheckPointer(panel) == POINTER_INVALID || CheckPointer(btn) == POINTER_INVALID)
  {
     Print("DEBUG: Memory Allocation Failed");
     return(INIT_FAILED);
  }

  // Create Main Dialog
  if(!dlg.Create(ChartID(), "MainDialog", 0, 0, 0, 200, 150))
  {
    Print("DEBUG: MainDialog Create Failed. Error: ", GetLastError());
    // Try to delete again?
    return(INIT_FAILED);
  }
  Print("DEBUG: MainDialog Created Successfully");
  dlg.Run();

  // Create Panel
  if(!panel.Create(ChartID(), "Panel1", 0, 10, 10, 190, 90))
  {
    Print("DEBUG: Panel Create Failed. Error: ", GetLastError());
    return(INIT_FAILED);
  }
  dlg.Add(panel);

  // Create Button
  if(!btn.Create(ChartID(), "Button1", 0, 20, 20, 160, 50))
  {
    Print("DEBUG: Button Create Failed. Error: ", GetLastError());
    return(INIT_FAILED);
  }
  btn.Text("Click me");
  dlg.Add(btn);

  Print("DEBUG: OnInit Completed Successfully");
  */
  return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
  Comment("");
  // Print("DEBUG: OnDeinit Called. Reason Code: ", reason);

  // if(CheckPointer(dlg) == POINTER_DYNAMIC)
  // {
  //   dlg.Destroy();
  //   delete dlg;
  //   dlg = NULL;
  // }
  // if(CheckPointer(panel) == POINTER_DYNAMIC)
  // {
  //   delete panel;
  //   panel = NULL;
  // }
  // if(CheckPointer(btn) == POINTER_DYNAMIC)
  // {
  //   delete btn;
  //   btn = NULL;
  // }
  // Print("DEBUG: OnDeinit Completed");
}

void LoadVariable()
{
  if (GlobalVariableCheck(EA_Name+"gblLastNotificate"+_Symbol))
   {
      lastNotify = (datetime)GlobalVariableGet(EA_Name+"gblLastNotificate"+_Symbol);
   }
}

void SaveLastNotificate(double data)
{
  GlobalVariableSet(EA_Name+"gblLastNotificate"+_Symbol, data);
}

void OnTick()
{
  double acc_balance   = AccountInfoDouble(ACCOUNT_BALANCE);
  double acc_profit    = AccountInfoDouble(ACCOUNT_PROFIT);
  curDD_Per = (acc_profit / acc_balance) * 100;
  
  int totalOrders = PositionsTotal();

  if(Notify_Timer > 0)
  {
    // Notify -> Orders
    if (totalOrders >= Notify_Orders && Notify_Orders > 0)
    {
      datetime curDate = TimeCurrent();
      int noti_diff = (int)(curDate - lastNotify);
      if (noti_diff >= (int)Notify_Timer)
      {
        lastNotify = curDate;
        SaveLastNotificate((double)lastNotify);
        SendMail(EA_Name+" Opening orders", "totalOrders: " + (string)totalOrders + "\n | lastNotify: " + (string)lastNotify);
      }
    }
    // Notify -> Draw Down
    if(curDD_Per <= Notify_DD_per && Notify_DD > 0)
    {
      datetime curDate = TimeCurrent();
      int noti_diff = (int)(curDate - lastNotify);
      if (noti_diff >= (int)Notify_Timer)
      {
        lastNotify = curDate;
        SaveLastNotificate((double)lastNotify);
        SendMail(EA_Name+" Draw Down", "Current Draw Down: " + (string)curDD_Per + "\n | lastNotify: " + (string)lastNotify);
      }
    }
  }
  
  Comment("CurDate: " + (string)TimeCurrent()
      + "\nLast Notify: " + (string)lastNotify
      + "\nCount Diff: " + (string)(int)(TimeCurrent() - lastNotify) + " / " + (string)Notify_Timer
      + "\n ===================================== "
      + "\ntotalOrders: " + (string)totalOrders
      + "\nNotify Orders: " + (string)Notify_Orders
      + "\n ===================================== "
      + "\ncur DD_Per: " + (string)NormalizeDouble(curDD_Per,2) + "%"
      + "\nNotify DD_Per: " + (string)(int)(Notify_DD_per) + "%"
    );
}

void OnTimer()
{
}

void OnTrade()
{
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
}

double OnTester()
{
  return (0.0);
}

void OnTesterInit()
{
}

void OnTesterPass()
{
}

void OnTesterDeinit()
{
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
  if(CheckPointer(dlg) == POINTER_DYNAMIC)
     dlg.ChartEvent(id, lparam, dparam, sparam);

  if (id == CHARTEVENT_OBJECT_CLICK && sparam == "Button1")
  {
    Print("Button Clicked!");
  }
}

void OnBookEvent(const string &symbol)
{
}
