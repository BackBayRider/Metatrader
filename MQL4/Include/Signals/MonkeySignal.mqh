//+------------------------------------------------------------------+
//|                                                 MonkeySignal.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Signals\MonkeySignalBase.mqh>
#include <Signals\AdxSignal.mqh>
#include <Signals\RsiBands.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MonkeySignal : public MonkeySignalBase
  {
private:
   bool              _hedgeExitsToggler;
   int               _exitRangePeriod;
   datetime          _lastTrigger;
   RsiBands         *_rsiBands;
   AdxSignal        *_adxSignal;
   MonkeySignalConfig _config;
   PriceRange        GetAtrTrigger(CandleMetrics &candle,string symbol,int shift,int period,double triggerLevel,bool drawIndicator,color indicatorColor);
   PriceRange        GetRangeNullZone(string symbol,int shift,int period,double percentHeight,bool drawIndicator,color indicatorColor);
   PriceRange        GetTrendNullZone(string symbol,int shift,int period,double percentHeight,bool drawIndicator,color indicatorColor);
   PriceRange        CalculateRange(string symbol,int shift);
   PriceRange        CalculateExitsBuy(string symbol,int shift);
   PriceRange        CalculateExitsSell(string symbol,int shift);
   void              SetBuySignal(string symbol,int shift,MqlTick &tick,bool setTp);
   void              SetSellSignal(string symbol,int shift,MqlTick &tick,bool setTp);
   void              SetSellExits(string symbol,int shift,MqlTick &tick);
   void              SetBuyExits(string symbol,int shift,MqlTick &tick);
   void              SetExits(string symbol,int shift,MqlTick &tick);
   void              FilterByLastClosedOrderClosePrice(int shift);

public:
                     MonkeySignal(MonkeySignalConfig &config,AbstractSignal *aSubSignal=NULL);
                    ~MonkeySignal();
   SignalResult     *Analyzer(string symbol,int shift);
   virtual bool      Validate(ValidationResult *v);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::MonkeySignal(MonkeySignalConfig &config,AbstractSignal *aSubSignal=NULL):MonkeySignalBase(config,aSubSignal)
  {
   this._hedgeExitsToggler=false;
   this._lastTrigger=TimeCurrent();
   this._config=config;
   this._rsiBands=new RsiBands(config.RsiBands);
   this._adxSignal=new AdxSignal(config.AdxSignal);
   if(this._config.TrendPeriod<this._config.RangePeriod)
     {
      this._exitRangePeriod=this._config.TrendPeriod;
     }
   else
     {
      this._exitRangePeriod=this._config.RangePeriod;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::~MonkeySignal()
  {
   delete this._rsiBands;
   delete this._adxSignal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MonkeySignal::Validate(ValidationResult *v)
  {
   AbstractSignal::Validate(v);
   this._rsiBands.Validate(v);
   this._adxSignal.Validate(v);

   if(!this._compare.IsGreaterThanOrEqualTo(this._config.AtrTriggerLevel,0.0))
     {
      v.Result=false;
      v.AddMessage("Trigger level must be zero or greater.");
     }
   return v.Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PriceRange MonkeySignal::GetRangeNullZone(string symbol,int shift,int period,double percentHeight,bool drawIndicator,color indicatorColor)
  {
   PriceRange rangeNullZone=this.CalculateRangeByPriceLowHigh(symbol,shift,period);
   double rangeNullZoneHalfSpread=(rangeNullZone.high-rangeNullZone.low)*(percentHeight/2);
   rangeNullZone.low=rangeNullZone.mid-rangeNullZoneHalfSpread;
   rangeNullZone.high=rangeNullZone.mid+rangeNullZoneHalfSpread;

   if(drawIndicator)
     {
      this.DrawIndicatorRectangle(symbol,shift,rangeNullZone.high,rangeNullZone.low,"_rangeNullZone",period,indicatorColor);
     }

   return rangeNullZone;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PriceRange MonkeySignal::GetTrendNullZone(string symbol,int shift,int period,double percentHeight,bool drawIndicator,color indicatorColor)
  {
   PriceRange trendNullZone=this.CalculateRangeByPriceLowHigh(symbol,shift,period);
   double trendNullZoneHalfSpread=(trendNullZone.high-trendNullZone.low)*(percentHeight/2);
   trendNullZone.low=trendNullZone.mid-trendNullZoneHalfSpread;
   trendNullZone.high=trendNullZone.mid+trendNullZoneHalfSpread;

   if(drawIndicator)
     {
      this.DrawIndicatorRectangle(symbol,shift,trendNullZone.high,trendNullZone.low,"_trendNullZone",period,indicatorColor);
     }

   return trendNullZone;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PriceRange MonkeySignal::GetAtrTrigger(CandleMetrics &candle,string symbol,int shift,int period,double triggerLevel,bool drawIndicator,color indicatorColor)
  {
   double atr=this.GetAtr(symbol,shift,period);
   double atrTriggerWidth=atr*triggerLevel;

   PriceRange atrTrigger;
   atrTrigger.high=candle.Open+atrTriggerWidth;
   atrTrigger.low=candle.Open-atrTriggerWidth;

   if(drawIndicator)
     {
      this.DrawIndicatorRectangle(symbol,shift,atrTrigger.high,atrTrigger.low,"_atrTrigger",1,indicatorColor);
     }

   return atrTrigger;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PriceRange MonkeySignal::CalculateExitsBuy(string symbol,int shift)
  {
   PriceRange pr;
   double atr=(this.GetAtr(symbol,shift,this._config.AtrPeriod)*this._config.AtrExitsMultiplier);

   pr=this.CalculateRangeByPriceLowHigh(symbol,shift,this._exitRangePeriod);
   pr.high=pr.high;
   pr.low=pr.low-atr;

   return pr;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PriceRange MonkeySignal::CalculateExitsSell(string symbol,int shift)
  {
   PriceRange pr;
   double atr=(this.GetAtr(symbol,shift,this._config.AtrPeriod)*this._config.AtrExitsMultiplier);

   pr=this.CalculateRangeByPriceLowHigh(symbol,shift,this._exitRangePeriod);
   pr.high=pr.high+atr;
   pr.low=pr.low;

   return pr;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::SetBuySignal(string symbol,int shift,MqlTick &tick,bool setTp)
  {
   PriceRange pr=this.CalculateExitsBuy(symbol,shift);

   double tp=0;
   if(setTp)
     {
      tp=pr.high;
     }

   this.Signal.isSet=true;
   this.Signal.time=tick.time;
   this.Signal.symbol=symbol;
   this.Signal.orderType=OP_BUY;
   this.Signal.price=tick.ask;
   this.Signal.stopLoss=pr.low;
   this.Signal.takeProfit=tp;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::SetSellSignal(string symbol,int shift,MqlTick &tick,bool setTp)
  {
   PriceRange pr=this.CalculateExitsSell(symbol,shift);

   double tp=0;
   if(setTp)
     {
      tp=pr.low;
     }

   this.Signal.isSet=true;
   this.Signal.time=tick.time;
   this.Signal.symbol=symbol;
   this.Signal.orderType=OP_SELL;
   this.Signal.price=tick.bid;
   this.Signal.stopLoss=pr.high;
   this.Signal.takeProfit=tp;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::SetBuyExits(string symbol,int shift,MqlTick &tick)
  {
   PriceRange pr=this.CalculateExitsBuy(symbol,shift);

   double sl=OrderManager::PairHighestStopLoss(symbol,OP_BUY);
   if(sl>0 && pr.low>sl)
     {
      sl=pr.low;
     }

   double tp=OrderManager::PairHighestTakeProfit(symbol,OP_BUY);
   if(tp>0 && pr.high<tp)
     {
      tp=pr.high;
     }

   this.Signal.isSet=true;
   this.Signal.time=tick.time;
   this.Signal.symbol=symbol;
   this.Signal.orderType=OP_BUY;
   this.Signal.price=tick.ask;
   this.Signal.stopLoss=sl;
   this.Signal.takeProfit=tp;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::SetSellExits(string symbol,int shift,MqlTick &tick)
  {
   PriceRange pr=this.CalculateExitsSell(symbol,shift);

   double sl=OrderManager::PairLowestStopLoss(symbol,OP_SELL);
   if(sl>0 && pr.high<sl)
     {
      sl=pr.high;
     }

   double tp=OrderManager::PairLowestTakeProfit(symbol,OP_SELL);
   if(tp>0 && pr.low>tp)
     {
      tp=pr.low;
     }

   this.Signal.isSet=true;
   this.Signal.time=tick.time;
   this.Signal.symbol=symbol;
   this.Signal.orderType=OP_SELL;
   this.Signal.price=tick.bid;
   this.Signal.stopLoss=sl;
   this.Signal.takeProfit=tp;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::SetExits(string symbol,int shift,MqlTick &tick)
  {
   int hasBuys=0<OrderManager::PairOpenPositionCount(OP_BUY,symbol);
   int hasSells=0<OrderManager::PairOpenPositionCount(OP_SELL,symbol);

   if(Comparators::Xor(hasBuys,hasSells))
     {
      if(hasBuys)
        {
         this.SetBuyExits(symbol,shift,tick);
        }
      if(hasSells)
        {
         this.SetSellExits(symbol,shift,tick);
        }
     }
   else if(Comparators::And(hasBuys,hasSells))
     {
      this._hedgeExitsToggler=(!this._hedgeExitsToggler);
      if(this._hedgeExitsToggler)
        {
         this.SetBuyExits(symbol,shift,tick);
        }
      else
        {
         this.SetSellExits(symbol,shift,tick);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonkeySignal::FilterByLastClosedOrderClosePrice(int shift)
  {
   if(this.Signal.isSet)
     {
      double positionCt=OrderManager::PairOpenPositionCount(this.Signal.orderType,this.Signal.symbol);
      if(positionCt<1)
        {
         Order o;
         if(OrderManager::GetLastClosedOrder(o,this.Signal.symbol) && this.Signal.price>0)
           {
            PriceRange ocr;
            double atr=this.GetAtr(this.Signal.symbol,shift,this._config.AtrPeriod)*this._config.AtrTriggerLevel;
            ocr.high=o.closePrice+atr;
            ocr.low=o.closePrice-atr;

            if(this._compare.IsBetween(this.Signal.price,ocr.low,ocr.high))
              {
               this.Signal.Reset();
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalResult *MonkeySignal::Analyzer(string symbol,int shift)
  {
   MqlTick tick;
   bool gotTick=SymbolInfoTick(symbol,tick);

   if(gotTick)
     {
      CandleMetrics *candle=this.GetCandleMetrics(symbol,shift);
      if(candle.IsSet && candle.Time!=this._lastTrigger)
        {

         PriceRange rangeNullZone=this.GetRangeNullZone(
                                                        symbol
                                                        ,shift+this._config.RangeShift
                                                        ,this._config.RangePeriod
                                                        ,this._config.RangeNullZoneWidth
                                                        ,true
                                                        ,this._config.IndicatorColorRangeNull);

         PriceRange trendNullZone=this.GetTrendNullZone(
                                                        symbol
                                                        ,shift+this._config.TrendShift
                                                        ,this._config.TrendPeriod
                                                        ,this._config.TrendBufferWidth
                                                        ,true
                                                        ,this._config.IndicatorColorTrendNull);

         PriceRange atrTrigger=this.GetAtrTrigger(
                                                  candle
                                                  ,symbol
                                                  ,shift
                                                  ,this._config.AtrPeriod
                                                  ,this._config.AtrTriggerLevel
                                                  ,true
                                                  ,this._config.IndicatorColorAtr);

         bool sellSignal=false,buySignal=false,setTp=false;

         if(candle.High>=atrTrigger.high || candle.Low<=atrTrigger.low)
           {
            if(this._compare.IsNotBetween(candle.Close,rangeNullZone.low,rangeNullZone.high))
              {
               bool trendingUp=this._adxSignal.IsBullish(symbol,shift) && this._compare.IsGreaterThan(candle.Close,trendNullZone.high);
               bool trendingDown=this._adxSignal.IsBearish(symbol,shift) && this._compare.IsLessThan(candle.Close,trendNullZone.low);
               bool rsiSell=this._rsiBands.IsSellSignal(symbol,shift);
               bool rsiBuy=this._rsiBands.IsBuySignal(symbol,shift);

               if((trendingDown || trendingUp) && (this._compare.IsNotBetween(candle.Close,trendNullZone.low,trendNullZone.high)))
                 {
                  // trend, no oscillator
                  if(trendingDown)
                    {
                     this.DrawIndicatorArrow(symbol,shift,trendNullZone.low,(char)218,5,"_trendingDown",this._config.IndicatorColorArrows);
                    }
                  if(trendingUp)
                    {
                     this.DrawIndicatorArrow(symbol,shift,trendNullZone.low,(char)217,5,"_trendingUp",this._config.IndicatorColorArrows);
                    }

                  sellSignal=this._adxSignal.IsBearishCrossover(symbol,shift);
                  buySignal=this._adxSignal.IsBullishCrossover(symbol,shift);
                  setTp=false;
                 }
               else if((rsiSell || rsiBuy) && (this._compare.IsBetween(candle.Close,trendNullZone.low,trendNullZone.high)))
                 {
                  // no trend, use oscillator
                  this.DrawIndicatorArrow(symbol,shift,trendNullZone.low,(char)216,5,"_ranging",this._config.IndicatorColorArrows);
                  sellSignal=rsiSell;
                  buySignal=rsiBuy;
                  setTp=this._rsiBands.IsInMidBand(symbol,shift);
                 }
              }
           }

         if(Comparators::Xor(sellSignal,buySignal))
           {
            if(sellSignal)
              {
               this.SetSellSignal(symbol,shift,tick,setTp);
              }

            if(buySignal)
              {
               this.SetBuySignal(symbol,shift,tick,setTp);
              }

            // signal confirmation
            if(!this.DoesSubsignalConfirm(symbol,shift))
              {
               this.Signal.Reset();
              }
            else
              {
               this._lastTrigger=candle.Time;
              }
           }
         else
           {
            this.Signal.Reset();
           }
        }

      this.SetExits(symbol,shift,tick);
      delete candle;
     }

   this.FilterByLastClosedOrderClosePrice(shift);

   return this.Signal;
  }
//+------------------------------------------------------------------+
