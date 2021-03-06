//+------------------------------------------------------------------+
//|                                                RsiBaseConfig.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Signals\Config\HighLowThresholds.mqh>
#include <Signals\Config\AbstractSignalConfig.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct RsiBaseConfig : public AbstractSignalConfig
  {
public:
   ENUM_APPLIED_PRICE AppliedPrice;
   HighLowThresholds Wideband;

   void RsiConfig()
     {
      this.Period=14;
      this.Timeframe=PERIOD_CURRENT;
      this.Shift=0;
      this.AppliedPrice=PRICE_CLOSE;
      this.Wideband.High=70.0;
      this.Wideband.Low=30.0;
     };
  };
//+------------------------------------------------------------------+
