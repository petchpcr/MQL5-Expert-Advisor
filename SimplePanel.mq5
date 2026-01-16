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
      // Print("ProcessCaptionClick called. Now: ", now, " Last: ", m_last_click_time, " Diff: ", (now - m_last_click_time));
      
      if(now - m_last_click_time < 500) // 500ms threshold for double click
      {
         // Print("Double Click Detected!");
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
   
   // Equity Labels
   bool CreateEquityLabel()
   {
      // 1. Key Label "Equity:"
      int x1 = 10;
      int y1 = 40; // Below Caption
      int x2 = 70;
      int y2 = 60;
      if(!m_lbl_equity_key.Create(m_chart_id, m_name+"LblEqKey", m_subwin, x1, y1, x2, y2)) return false;
      if(!m_lbl_equity_key.Text("Equity:")) return false;
      if(!Add(m_lbl_equity_key)) return false;
      
      // 2. Value Label "0.00"
      x1 = 80;
      x2 = 200;
      if(!m_lbl_equity_val.Create(m_chart_id, m_name+"LblEqVal", m_subwin, x1, y1, x2, y2)) return false;
      if(!m_lbl_equity_val.Text("0.00")) return false;
      if(!Add(m_lbl_equity_val)) return false;
      
      return true;
   }
   
   void UpdateEquity()
   {
      if(IsMinimized()) return; 
      m_lbl_equity_val.Text(DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
   }
   
private:
   CLabel m_lbl_equity_key;
   CLabel m_lbl_equity_val;
   
protected:
   ulong m_last_click_time;
   
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

int OnInit()
{
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

   Print("Init | State: ", CurrentStateMinimized ? "Min" : "Max", 
         " | MaxPos: ", PanelX, ",", PanelY, 
         " | MinPos: ", PanelMinX, ",", PanelMinY);

   // 5. Create Panel
   if(!AppWindow.Create(0,"AppWindow2",0,startX,startY,startX+240,startY+304))
      return(INIT_FAILED);
      
   AppWindow.Run();
   
   // Create Data Labels
   if(!AppWindow.CreateEquityLabel())
      Print("Error creating Equity labels");
      
   // Update data immediately if not minimized
   if(!CurrentStateMinimized) AppWindow.UpdateEquity();
   
   // 6. Restore Minimized State
   if(CurrentStateMinimized)
   {
      AppWindow.SetMinimized(true);
      AppWindow.Move(PanelMinX, PanelMinY);
   }
   
   // Enable Mouse Move Event
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1);

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
AppWindow.UpdateEquity();
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
         Print("Minimized -> Jumped to: ", PanelMinX, ",", PanelMinY);
      }
      else
      {
         // Changed to Maximized: Jump to saved Maximized Position
         AppWindow.Move(PanelX, PanelY);
         Print("Maximized -> Jumped to: ", PanelX, ",", PanelY);
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
               Print("Saved Min Pos: ", PanelMinX, ",", PanelMinY);
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
               Print("Saved Max Pos: ", PanelX, ",", PanelY);
            }
         }
      }
   }
}
