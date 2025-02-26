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
   - Current bar swepts liquidity (LQ) of previous bar(s).
   - After that the fair value gap (FVG) is formed by the next bars.
   Note: The DOB is the same as the Order Block (OB)
   in Liqudity Inducement Theorem (LIT) of TradingHub community
   authored by Ali Khan aka Mr. Khan.

    LQ  _____________
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

enum ENUM_BORDER_STYLE
  {
   BORDER_STYLE_SOLID = STYLE_SOLID, // Solid
   BORDER_STYLE_DASH = STYLE_DASH // Dash
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
const string OBJECT_PREFIX = "DOB_";
const string OBJECT_PREFIX_CONTINUATED = OBJECT_PREFIX + "CONT";
const string OBJECT_SEP = "#";

// runtime
//...

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpDebugEnabled)
     {
      Print("DisplacementOrderBlock indicator initialization started");
     }

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   if(InpDebugEnabled)
     {
      Print("DisplacementOrderBlock indicator initialization finished");
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
      Print("DisplacementOrderBlock indicator deinitialization started");
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
      Print("DisplacementOrderBlock indicator deinitialization finished");
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

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   int startIndex = 3; // newest bar (right side)
   int endIndex = prev_calculated == 0 ? rates_total - startIndex : rates_total - prev_calculated + startIndex; // oldest bar (left side)
   if(InpDebugEnabled)
     {
      PrintFormat("RatesTotal: %i, PrevCalculated: %i, StartIndex: %i, EndIndex: %i", rates_total, prev_calculated, startIndex, endIndex);
     }

   for(int i = startIndex; i < endIndex; i++) // go from right to left
     {
      bool InpContinueToMitigation = true;

      if(IsBullishFractal(high, i))
        {
         if(InpDebugEnabled)
           {
            PrintFormat("Bullish fractal on price %f at %s on %i bar", high[i], TimeToString(time[i]), i);
           }

         if(IsBearishFvg(high, low, i))
           {
            datetime leftTime = time[i];
            datetime rightTime = time[i - 1];

            if(InpContinueToMitigation)
              {
               rightTime = time[0];
               for(int j = i - 3; j > 0; j--) // Search mitigation bar (go from left to right)
                 {
                  if((low[i] < high[j] && low[i] >= low[j]) || (high[i] > low[j] && high[i] <= high[j]))
                    {
                     rightTime = time[j];
                     break;
                    }
                 }
              }

            DrawBox(leftTime, high[i], rightTime, low[i], InpContinueToMitigation);
           }
        }

      if(IsBearishFractal(low, i))
        {
         if(InpDebugEnabled)
           {
            PrintFormat("Bearish fractal on price %f at %s on %i bar", low[i], TimeToString(time[i]), i);
           }

         if(IsBullishFvg(high, low, i))
           {
            datetime leftTime = time[i];
            datetime rightTime = time[i - 1];

            if(InpContinueToMitigation)
              {
               rightTime = time[0];
               for(int j = i - 3; j > 0; j--) // Search mitigation bar (go from left to right)
                 {
                  if((high[i] <= high[j] && high[i] > low[j]) || (low[i] >= low[j] && low[i] < high[j]))
                    {
                     rightTime = time[j];
                     break;
                    }
                 }
              }

            DrawBox(leftTime, low[i], rightTime, high[i], InpContinueToMitigation);
           }
        }
     }

   return rates_total;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBullishFractal(const double &high[], int index)
  {
   double prev = high[index + 1];
   double curr = high[index];
   double next = high[index - 1];

   return curr > prev && curr > next;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBearishFractal(const double &low[], int index)
  {
   double prev = low[index + 1];
   double curr = low[index];
   double next = low[index - 1];

   return curr < prev && curr < next;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBullishFvg(const double &high[], const double &low[], int index)
  {
   double leftHigh = high[index];
   double leftLow = low[index];
   double midHigh = high[index - 1];
   double midLow = low[index - 1];
   double rightHigh = high[index - 2];
   double rightLow = low[index - 2];

   bool hasGap = leftHigh < rightLow;
   bool validLeft = midLow >= leftLow && midHigh >= leftHigh;
   bool validRight = midLow <= rightLow && midHigh <= rightHigh;

   return hasGap && validLeft && validRight;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBearishFvg(const double &high[], const double &low[], int index)
  {
   double leftHigh = high[index];
   double leftLow = low[index];
   double midHigh = high[index - 1];
   double midLow = low[index - 1];
   double rightHigh = high[index - 2];
   double rightLow = low[index - 2];

   bool hasGap = leftLow > rightHigh;
   bool validLeft = midHigh <= leftHigh && midHigh >= leftLow;
   bool validRight = midLow <= rightHigh && midLow >= rightLow;

   return hasGap && validLeft && validRight;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawBox(datetime leftDt, double leftPrice, datetime rightDt, double rightPrice, bool continuated)
  {
   color InpDownTrendColor = clrLightPink; // Down trend color
   color InpUpTrendColor = clrLightGreen; // Up trend color
   bool InpFill = true; // Fill solid (true) or transparent (false)
   ENUM_BORDER_STYLE InpBoderStyle = BORDER_STYLE_SOLID; // Border line style
   int InpBorderWidth = 2; // Border line width

   string objName = (continuated ? OBJECT_PREFIX_CONTINUATED : OBJECT_PREFIX)
                    + OBJECT_SEP
                    + TimeToString(leftDt)
                    + OBJECT_SEP
                    + DoubleToString(leftPrice)
                    + OBJECT_SEP
                    + TimeToString(rightDt)
                    + OBJECT_SEP
                    + DoubleToString(rightPrice);

   if(ObjectFind(0, objName) < 0)
     {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, leftDt, leftPrice, rightDt, rightPrice);

      ObjectSetInteger(0, objName, OBJPROP_COLOR, leftPrice < rightPrice ? InpUpTrendColor : InpDownTrendColor);
      ObjectSetInteger(0, objName, OBJPROP_FILL, InpFill);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, InpBoderStyle);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, InpBorderWidth);
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);

      if(InpDebugEnabled)
        {
         PrintFormat("Draw box: %s", objName);
        }
     }
  }
//+------------------------------------------------------------------+
