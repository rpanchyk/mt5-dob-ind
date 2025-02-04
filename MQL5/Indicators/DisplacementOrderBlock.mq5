//+------------------------------------------------------------------+
//|                                       DisplacementOrderBlock.mq5 |
//|                                         Copyright 2025, rpanchyk |
//|                                      https://github.com/rpanchyk |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, rpanchyk"
#property link        "https://github.com/rpanchyk"
#property version     "1.00"
#property description "Indicator shows displacement order blocks"

/*
   The Displacement Order Block (DOB) in Smart Money Concept (SMC)
   authored by Michael J. Huddleston aka Inner Circle Trader (ICT)
   is identified by the next conditions:
   - Current bar swepts liquidity of previous bar(s).
   - After that the fair value gap (FVG) is formed by the next bars.
   Note: The DOB is the same as the Order Block (OB)
   in Liqudity Inducement Theorem (LIT) of TradingHub community
   authored by Ali Khan aka Mr. Khan.

     x  _____________
    -->|
   |  | |
  | | | |          OB
  | | | |
  | |  |___|_________
   |      | |
          | |     FVG
          | |________
           |   |
              | |
              | |
              | |
               |
*/

#property indicator_chart_window
#property indicator_plots 0
#property indicator_buffers 0

// types
enum ENUM_ARROW_SIZE
  {
   SMALL_ARROW_SIZE = 1, // Small
   REGULAR_ARROW_SIZE = 2, // Regular
   BIG_ARROW_SIZE = 3, // Big
   HUGE_ARROW_SIZE = 4 // Huge
  };

// buffers
//...

// config
input group "Section :: Main";
input bool InpDebugEnabled = true; // Enable debug (verbose logging)

input group "Section :: Style";
input bool InpVisualModeEnabled = true; // Enable visual mode
input int InpArrowShift = 10; // Arrow shift
input ENUM_ARROW_SIZE InpArrowSize = REGULAR_ARROW_SIZE; // Arrow size
input color InpHighObColor = clrGreen; // High order block arrow color
input color InpLowObColor = clrRed; // Low order block arrow color

// constants
const string OBJECT_PREFIX = "LITOB_";

// runtime
//...

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpDebugEnabled)
     {
      Print("LitOrderBlock indicator initialization started");
     }

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   if(InpDebugEnabled)
     {
      Print("LitOrderBlock indicator initialization finished");
     }
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(InpDebugEnabled)
     {
      Print("LitOrderBlock indicator deinitialization started");
     }

   if(!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_OPTIMIZATION) && !MQLInfoInteger(MQL_VISUAL_MODE))
     {
      ObjectsDeleteAll(0, OBJECT_PREFIX);
      if(InpDebugEnabled)
        {
         PrintFormat("Clean object list with %s prefix", OBJECT_PREFIX);
        }
     }

   if(InpDebugEnabled)
     {
      Print("LitOrderBlock indicator deinitialization finished");
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total == prev_calculated)
     {
      return rates_total;
     }

   int startIndex = 1; // last closed bar
   int endIndex = prev_calculated == 0 ? 1 : rates_total - prev_calculated + 1; // first bar shifted to the right
   if(InpDebugEnabled)
     {
      PrintFormat("RatesTotal: %i, PrevCalculated: %i, StartIndex: %i, EndIndex: %i", rates_total, prev_calculated, startIndex, endIndex);
     }

   for(int i = startIndex; i < endIndex; i++)
     {
      //...
     }

   return rates_total;
  }
//+------------------------------------------------------------------+
