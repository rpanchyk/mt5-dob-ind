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
#property indicator_plots 3
#property indicator_buffers 3

// types
enum ENUM_BORDER_STYLE
  {
   BORDER_STYLE_SOLID = STYLE_SOLID, // Solid
   BORDER_STYLE_DASH = STYLE_DASH // Dash
  };

// buffers
double ExtHighPriceBuffer[]; // Higher price of OB
double ExtLowPriceBuffer[]; // Lower price of OB
double ExtTrendBuffer[]; // Trend of OB [0: flat/unknown, -1: down, 1: up]

// config
input group "Section :: Main";
input bool InpDebugEnabled = false; // Enable debug (verbose logging)
input bool InpContinueToMitigation = true; // Continue to mitigation

input group "Section :: Style";
input bool InpVisualModeEnabled = true; // Enable visual mode
input color InpDownTrendColor = clrLightPink; // Down trend (bearish) color
input color InpUpTrendColor = clrLightGreen; // Up trend (bullish) color
input bool InpFill = true; // Fill solid (true) or transparent (false)
input ENUM_BORDER_STYLE InpBoderStyle = BORDER_STYLE_SOLID; // Border line style
input int InpBorderWidth = 2; // Border line width

// constants
const string OBJECT_PREFIX = "DOB_";
const string OBJECT_PREFIX_CONTINUATED = OBJECT_PREFIX + "CONT";
const string OBJECT_SEP = "#";

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

   ArrayInitialize(ExtHighPriceBuffer, EMPTY_VALUE);
   ArraySetAsSeries(ExtHighPriceBuffer, true);
   SetIndexBuffer(0, ExtHighPriceBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetString(0, PLOT_LABEL, "DOB High");
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);

   ArrayInitialize(ExtLowPriceBuffer, EMPTY_VALUE);
   ArraySetAsSeries(ExtLowPriceBuffer, true);
   SetIndexBuffer(1, ExtLowPriceBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetString(1, PLOT_LABEL, "DOB Low");
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);

   ArrayInitialize(ExtTrendBuffer, EMPTY_VALUE);
   ArraySetAsSeries(ExtTrendBuffer, true);
   SetIndexBuffer(2, ExtTrendBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetString(2, PLOT_LABEL, "DOB Trend");
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_NONE);

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

   ArrayFill(ExtHighPriceBuffer, 0, ArraySize(ExtHighPriceBuffer), EMPTY_VALUE);
   ArrayResize(ExtHighPriceBuffer, 0);
   ArrayFree(ExtHighPriceBuffer);

   ArrayFill(ExtLowPriceBuffer, 0, ArraySize(ExtLowPriceBuffer), EMPTY_VALUE);
   ArrayResize(ExtLowPriceBuffer, 0);
   ArrayFree(ExtLowPriceBuffer);

   ArrayFill(ExtTrendBuffer, 0, ArraySize(ExtTrendBuffer), EMPTY_VALUE);
   ArrayResize(ExtTrendBuffer, 0);
   ArrayFree(ExtTrendBuffer);

   if(!MQLInfoInteger(MQL_TESTER))
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

   if(InpContinueToMitigation) // Redraw continuations
     {
      int total = ObjectsTotal(0, 0, OBJ_RECTANGLE);
      for(int i = 0; i < total; i++)
        {
         string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
         if(StringFind(objName, OBJECT_PREFIX_CONTINUATED) == 0)
           {
            string result[];
            StringSplit(objName, StringGetCharacter(OBJECT_SEP, 0), result);

            datetime leftTime = StringToTime(result[1]);
            double leftPrice = StringToDouble(result[2]);
            datetime rightTime = time[0];
            double rightPrice = StringToDouble(result[4]);

            bool isBullish = leftPrice < rightPrice;
            bool isMitigated = (isBullish && rightPrice >= low[1]) || (!isBullish && rightPrice <= high[1]);
            if(isMitigated)
              {
               rightTime = time[1];
               if(ObjectDelete(0, objName))
                 {
                  if(InpDebugEnabled)
                    {
                     PrintFormat("Remove box %s", objName);
                    }

                  DrawBox(leftTime, leftPrice, rightTime, rightPrice, false);
                 }
              }
            else
              {
               ObjectMove(0, objName, 1, rightTime, rightPrice);
               if(InpDebugEnabled)
                 {
                  PrintFormat("Expand box %s", objName);
                 }
              }
           }
        }
     }

   int startIndex = 3; // Newest bar (right side)
   int endIndex = prev_calculated == 0 ? rates_total - startIndex : rates_total - prev_calculated + startIndex; // Oldest bar (left side)
   if(InpDebugEnabled)
     {
      PrintFormat("RatesTotal: %i, PrevCalculated: %i, StartIndex: %i, EndIndex: %i", rates_total, prev_calculated, startIndex, endIndex);
     }

   for(int i = startIndex; i < endIndex; i++) // Go from right to left
     {
      datetime leftTime = time[i];
      datetime rightTime = time[i - 1];

      // Bearish DOB
      if(IsBullishFractal(high, i))
        {
         if(InpDebugEnabled)
           {
            PrintFormat("Bullish fractal on price %f at %s on %i bar", high[i], TimeToString(time[i]), i);
           }

         if(IsBearishFvg(high, low, i))
           {
            if(InpDebugEnabled)
              {
               PrintFormat("Bearish FVG at %s on %i bar", TimeToString(time[i - 1]), i - 1);
              }

            SetBuffers(i, low[i], high[i], -1);

            if(InpVisualModeEnabled)
              {
               if(InpContinueToMitigation)
                 {
                  rightTime = time[0];
                  for(int j = i - startIndex; j > 0; j--) // Search mitigation bar (go from left to right)
                    {
                     if((low[i] <= high[j] && low[i] >= low[j]) || (high[i] >= low[j] && high[i] <= high[j]))
                       {
                        rightTime = time[j];
                        break;
                       }
                    }
                 }

               DrawBox(leftTime, high[i], rightTime, low[i], InpContinueToMitigation && rightTime == time[0]);
              }

            continue;
           }
        }

      // Bullish DOB
      if(IsBearishFractal(low, i))
        {
         if(InpDebugEnabled)
           {
            PrintFormat("Bearish fractal on price %f at %s on %i bar", low[i], TimeToString(time[i]), i);
           }

         if(IsBullishFvg(high, low, i))
           {
            if(InpDebugEnabled)
              {
               PrintFormat("Bullish FVG at %s on %i bar", TimeToString(time[i - 1]), i - 1);
              }

            SetBuffers(i, low[i], high[i], 1);

            if(InpVisualModeEnabled)
              {
               if(InpContinueToMitigation)
                 {
                  rightTime = time[0];
                  for(int j = i - startIndex; j > 0; j--) // Search mitigation bar (go from left to right)
                    {
                     if((high[i] <= high[j] && high[i] >= low[j]) || (low[i] >= low[j] && low[i] <= high[j]))
                       {
                        rightTime = time[j];
                        break;
                       }
                    }
                 }

               DrawBox(leftTime, low[i], rightTime, high[i], InpContinueToMitigation && rightTime == time[0]);
              }

            continue;
           }
        }

      // DOB not detected, set empty values to buffers
      SetBuffers(i, 0, 0, 0);
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
//| Updates buffers with indicator data                              |
//+------------------------------------------------------------------+
void SetBuffers(int index, double highPrice, double lowPrice, double trend)
  {
   ExtHighPriceBuffer[index] = highPrice;
   ExtLowPriceBuffer[index] = lowPrice;
   ExtTrendBuffer[index] = trend;

   if(InpDebugEnabled && trend != 0)
     {
      PrintFormat("Time: %s, ExtTrendBuffer: %f, ExtHighPriceBuffer: %f, ExtLowPriceBuffer: %f",
                  TimeToString(iTime(_Symbol, PERIOD_CURRENT, index)), ExtTrendBuffer[index],
                  ExtHighPriceBuffer[index], ExtLowPriceBuffer[index]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawBox(datetime leftDt, double leftPrice, datetime rightDt, double rightPrice, bool continuated)
  {
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
