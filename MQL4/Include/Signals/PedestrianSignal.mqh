//+------------------------------------------------------------------+
//|                                             PedestrianSignal.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Signals\PedestrianSignalBase.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PedestrianSignal : public PedestrianSignalBase
  {
protected:
   int _rangePeriod;
   ENUM_TIMEFRAMES _intradayTimeframe;
   int _intradayPeriod;
public:
                     PedestrianSignal(int period,ENUM_TIMEFRAMES timeframe,double minimumSpreadsTpSl,double skew,double atrMultiplier,int rangePeriod,ENUM_TIMEFRAMES intradayTimeframe,int intradayPeriod,AbstractSignal *aSubSignal=NULL);
   SignalResult     *Analyzer(string symbol,int shift);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PedestrianSignal::PedestrianSignal(int period,ENUM_TIMEFRAMES timeframe,double minimumSpreadsTpSl,double skew,double atrMultiplier,int rangePeriod,ENUM_TIMEFRAMES intradayTimeframe,int intradayPeriod,AbstractSignal *aSubSignal=NULL):PedestrianSignalBase(period,timeframe,0,minimumSpreadsTpSl,skew,atrMultiplier,aSubSignal)
  {
   this._rangePeriod=rangePeriod;
   this._intradayTimeframe=intradayTimeframe;
   this._intradayPeriod=intradayPeriod;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalResult *PedestrianSignal::Analyzer(string symbol,int shift)
  {
   MqlTick tick;
   bool gotTick=SymbolInfoTick(symbol,tick);
   
   if(gotTick)
     {
      bool isRangeMode=this.IsRangeMode(symbol,shift,this._rangePeriod);

      PriceRange pr=this.CalculateRangeByPriceLowHigh(symbol,shift+1,this._rangePeriod);

      double ma1=this.GetMovingAverage(symbol,shift,0,MODE_SMA,PRICE_CLOSE,this.Timeframe(),this._rangePeriod);
      double ma2=this.GetMovingAverage(symbol,shift+this._rangePeriod,0,MODE_SMA,PRICE_CLOSE,this.Timeframe(),this._rangePeriod);
      
      double rsi=this.GetRsi(symbol,shift,this._intradayTimeframe,this._intradayPeriod,PRICE_CLOSE);
      
      PriceRange bb=this.GetBollingerBands(symbol,shift,2.7,0,PRICE_CLOSE,this._intradayTimeframe,this._intradayPeriod);
      
      bool trendSell=ma1<ma2 && (tick.ask<pr.low);
      bool trendBuy=ma1>ma2 && (tick.bid>pr.high);

      double intradayHigh=this.GetHighestPriceInRange(symbol,1,this._intradayPeriod,this._intradayTimeframe);
      double intradayLow=this.GetLowestPriceInRange(symbol,1,this._intradayPeriod,this._intradayTimeframe);

      bool rangeSell=(tick.bid>pr.mid) && (tick.bid<pr.high) && (tick.bid>intradayHigh) && ma1>ma2 && (tick.bid>ma1) && rsi>60 && tick.bid>bb.high;
      bool rangeBuy=(tick.ask<pr.mid) && (tick.ask>pr.low) && (tick.ask<intradayLow) && ma1<ma2 && (tick.ask<ma1) && rsi<40 && tick.ask<bb.low;

      bool sellSignal=(_compare.Ternary(isRangeMode,rangeSell,trendSell));
      bool buySignal=(_compare.Ternary(isRangeMode,rangeBuy,trendBuy));

      if(_compare.Xor(sellSignal,buySignal) && isRangeMode)
        {
         if(sellSignal)
           {
            this.SetSellSignal(symbol,shift,tick,isRangeMode);
           }

         if(buySignal)
           {
            this.SetBuySignal(symbol,shift,tick,isRangeMode);
           }

         // signal confirmation
         if(!this.DoesSubsignalConfirm(symbol,shift))
           {
            this.Signal.Reset();
           }
        }
      else
        {
         this.Signal.Reset();
        }

      // if there is an order open...
      if(1<=OrderManager::PairOpenPositionCount(symbol,TimeCurrent()))
        {
         this.SetExits(symbol,shift,tick);
        }

     }

   return this.Signal;
  }
//+------------------------------------------------------------------+
