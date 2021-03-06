//+------------------------------------------------------------------+
//|                                           MonkeySignalConfig.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Signals\Config\RsiBandsConfig.mqh>
#include <Signals\Config\AdxSignalConfig.mqh>
#include <Signals\Config\AbstractSignalConfig.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct MonkeySignalConfig : public AbstractSignalConfig
  {
public:
   int               AtrPeriod;
   double            AtrTriggerLevel;
   double            AtrExitsMultiplier;
   int               RangePeriod;
   int               RangeShift;
   double            RangeNullZoneWidth;
   int               TrendPeriod;
   int               TrendShift;
   double            TrendBufferWidth;
   color             IndicatorColorAtr;
   color             IndicatorColorArrows;
   color             IndicatorColorRangeNull;
   color             IndicatorColorTrendNull;
   RsiBandsConfig    RsiBands;
   AdxSignalConfig   AdxSignal;

   void MonkeySignalConfig()
     {
      this.AtrTriggerLevel=2;
      this.AtrExitsMultiplier=0.5;
      this.RangePeriod=14;
      this.RangeNullZoneWidth=0.33;
      this.TrendPeriod=120;
      this.TrendShift=12;
      this.IndicatorColorAtr=clrAqua;
      this.IndicatorColorArrows=clrMediumTurquoise;
      this.IndicatorColorRangeNull=clrRed;
      this.IndicatorColorTrendNull=clrYellow;
     };
  };
//+------------------------------------------------------------------+
