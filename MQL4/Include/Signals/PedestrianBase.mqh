//+------------------------------------------------------------------+
//|                                         PedestrianBase.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Common\OrderManager.mqh>
#include <Common\Comparators.mqh>
#include <Signals\AbstractSignal.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PedestrianBase : public AbstractSignal
  {
protected:
   double            _skew;
   double            _atrMultiplier;
   virtual PriceRange CalculateRange(string symbol,int shift,double midPrice,int period=0);
   virtual void      SetBuySignal(string symbol,int shift,MqlTick &tick,bool setTp);
   virtual void      SetSellSignal(string symbol,int shift,MqlTick &tick,bool setTp);
   virtual void      SetSellExits(string symbol,int shift,MqlTick &tick);
   virtual void      SetBuyExits(string symbol,int shift,MqlTick &tick);
   virtual void      SetExits(string symbol,int shift,MqlTick &tick);
   virtual bool      IsRangeMode(string symbol,int shift,int period,MqlTick &tick);
   bool IsTrendMode(string symbol,int shift,int period,MqlTick &tick) { return !this.IsRangeMode(symbol,shift,period,tick); }
   int               GetLastClosedTicketNumber(string symbol);

public:
                     PedestrianBase(int period,ENUM_TIMEFRAMES timeframe,int shift=0,double minimumSpreadsTpSl=1,double skew=0.0,double atrMultiplier=0.0,AbstractSignal *aSubSignal=NULL);
   virtual bool      DoesSignalMeetRequirements();
   virtual bool      Validate(ValidationResult *v);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PedestrianBase::PedestrianBase(int period,ENUM_TIMEFRAMES timeframe,int shift=0,double minimumSpreadsTpSl=1,double skew=0.0,double atrMultiplier=0.0,AbstractSignal *aSubSignal=NULL):AbstractSignal(period,timeframe,shift,clrNONE,minimumSpreadsTpSl,aSubSignal)
  {
   this._skew=skew;
   this._atrMultiplier=atrMultiplier;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PedestrianBase::Validate(ValidationResult *v)
  {
   AbstractSignal::Validate(v);

   if(this._compare.IsNotBetween(this._skew,-0.49,0.49))
     {
      v.Result=false;
      v.AddMessage("Atr skew is out of range Min : - 0.49 max 0.49");
     }

   return v.Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PedestrianBase::DoesSignalMeetRequirements()
  {
   if(!(AbstractSignal::DoesSignalMeetRequirements()))
     {
      return false;
     }

   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PriceRange PedestrianBase::CalculateRange(string symbol,int shift,double midPrice,int period=0)
  {
   PriceRange pr;
   pr.mid=midPrice;
   double atr=0;
   if(period==0)
     {
      atr=(this.GetAtr(symbol,shift)*this._atrMultiplier);
     }
   else
     {
      atr=(this.GetAtr(symbol,shift,period)*this._atrMultiplier);
     }
   pr.low=(pr.mid-atr);
   pr.high=(pr.mid+atr);
   return pr;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int PedestrianBase::GetLastClosedTicketNumber(string symbol)
  {
   return OrderManager::GetLastClosedOrderTicket(symbol);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PedestrianBase::SetBuySignal(string symbol,int shift,MqlTick &tick,bool setTp)
  {
   PriceRange pr=this.CalculateRange(symbol,shift,tick.ask);
   pr.mid=pr.mid-((pr.high-pr.low)*this._skew);
   pr.high=tick.ask+(pr.high-pr.mid);
   pr.low=tick.ask-(pr.mid-pr.low);

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
void PedestrianBase::SetSellSignal(string symbol,int shift,MqlTick &tick,bool setTp)
  {
   PriceRange pr=this.CalculateRange(symbol,shift,tick.bid);
   pr.mid=pr.mid+((pr.high-pr.low)*this._skew);
   pr.high=tick.bid+(pr.high-pr.mid);
   pr.low=tick.bid-(pr.mid-pr.low);

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
void PedestrianBase::SetBuyExits(string symbol,int shift,MqlTick &tick)
  {
   PriceRange pr=this.CalculateRange(symbol,shift,tick.bid);
   pr.mid=pr.mid-((pr.high-pr.low)*this._skew);
   pr.high=tick.ask+(pr.high-pr.mid);
   pr.low=tick.ask-(pr.mid-pr.low);
   
   double ap=OrderManager::PairAveragePrice(symbol,OP_BUY);
   double sl=pr.low;
   double pad=((tick.bid-ap)/3);
   if(sl>0 && sl>ap+pad)
     {
      sl=sl-pad;
     }

   this.Signal.isSet=true;
   this.Signal.time=tick.time;
   this.Signal.symbol=symbol;
   this.Signal.orderType=OP_BUY;
   this.Signal.price=tick.ask;
   this.Signal.stopLoss=sl;
   this.Signal.takeProfit=OrderManager::PairHighestTakeProfit(symbol,OP_BUY);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PedestrianBase::SetSellExits(string symbol,int shift,MqlTick &tick)
  {
   PriceRange pr=this.CalculateRange(symbol,shift,tick.ask);
   pr.mid=pr.mid+((pr.high-pr.low)*this._skew);
   pr.high=tick.bid+(pr.high-pr.mid);
   pr.low=tick.bid-(pr.mid-pr.low);

   double ap=OrderManager::PairAveragePrice(symbol,OP_SELL);
   double sl=pr.high;
   double pad=((ap-tick.ask)/3);

   if(sl>0 && sl<ap-pad)
     {
      sl=sl+pad;
     }

   this.Signal.isSet=true;
   this.Signal.time=tick.time;
   this.Signal.symbol=symbol;
   this.Signal.orderType=OP_SELL;
   this.Signal.price=tick.bid;
   this.Signal.stopLoss=sl;
   this.Signal.takeProfit=OrderManager::PairLowestTakeProfit(symbol,OP_SELL);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PedestrianBase::SetExits(string symbol,int shift,MqlTick &tick)
  {
   if(0<OrderManager::PairProfit(symbol))
     {
      if(0<OrderManager::PairOpenPositionCount(OP_BUY,symbol,TimeCurrent()))
        {
         if((!this.Signal.isSet) || (this.Signal.isSet && this.Signal.orderType==OP_BUY))
           {
            this.SetBuyExits(symbol,shift,tick);
           }
        }
      if(0<OrderManager::PairOpenPositionCount(OP_SELL,symbol,TimeCurrent()))
        {
         if((!this.Signal.isSet) || (this.Signal.isSet && this.Signal.orderType==OP_SELL))
           {
            this.SetSellExits(symbol,shift,tick);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PedestrianBase::IsRangeMode(string symbol,int shift,int period,MqlTick &tick)
  {
   bool adxRange=50>this.GetAdx(symbol,shift,period,PRICE_CLOSE).Main;

   double atr=this.GetAtr(symbol,shift,period);
   double high=this.GetHighestPriceInRange(symbol,shift,1);
   double low=this.GetLowestPriceInRange(symbol,shift,1);
   bool atrRange=atr>=(high-low);
   
   //return (adxRange || atrRange);
   return (adxRange);
  }
//+------------------------------------------------------------------+
