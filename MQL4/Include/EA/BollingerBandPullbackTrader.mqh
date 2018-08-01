//+------------------------------------------------------------------+
//|                                  BollingerBandPullbackTrader.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property description "Criteria:"
#property description "1. Price touches bollinger band."
#property description "2. Price pulls back to the moving average."
#property description "3. Enter order anticipating price to move toward touched bollinger band."
#property description "4. Stopout level is to be controlled by Atr defined range around current price."
#property strict

#include <PLManager\PLManager.mqh>
#include <Schedule\ScheduleSet.mqh>
#include <Signals\SignalSet.mqh>
#include <Signals\AtrExits.mqh>
#include <Signals\MovingAveragePullback.mqh>
#include <Signals\BollingerBandsTouch.mqh>
#include <PortfolioManager\PortfolioManager.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BollingerBandPullbackTrader
  {
private:
   PortfolioManager *portfolioManager;
   SymbolSet        *ss;
   ScheduleSet      *sched;
   OrderManager     *om;
   PLManager        *plman;
   SignalSet        *signalSet;
   AtrExits         *exitSignal;

public:
   double CustomTestResult() 
     {
      return portfolioManager.CustomTestResult();
     }
   void              BollingerBandPullbackTrader(
                                                 string watchedSymbols,

                                                 int bollingerBandPullbackBbPeriod,
                                                 bool bollingerBandPullbackFadeTouch,
                                                 int bollingerBandPullbackTouchPeriod,
                                                 double bollingerBandPullbackBbDeviation,
                                                 ENUM_APPLIED_PRICE bollingerBandPullbackBbAppliedPrice,
                                                 int bollingerBandPullbackTouchShift,
                                                 int bollingerBandPullbackBbShift,
                                                 color bollingerBandPullbackBbIndicatorColor,
                                                 color bollingerBandPullbackTouchIndicatorColor,

                                                 int bollingerBandPullbackMaPeriod,int bollingerBandPullbackMaShift,
                                                 ENUM_MA_METHOD bollingerBandPullbackMaMethod,
                                                 ENUM_APPLIED_PRICE bollingerBandPullbackMaAppliedPrice,
                                                 int bollingerBandPullbackMaColor,

                                                 int bollingerBandPullbackAtrPeriod,double bollingerBandPullbackAtrMultiplier,
                                                 int bollingerBandPullbackShift,int bollingerBandPullbackAtrColor,

                                                 double bollingerBandPullbackMinimumTpSlDistance,
                                                 ENUM_TIMEFRAMES bollingerBandPullbackTimeframe,
                                                 int parallelSignals,double lots,double profitTarget,
                                                 double maxLoss,int slippage,ENUM_DAY_OF_WEEK startDay,
                                                 ENUM_DAY_OF_WEEK endDay,string startTime,string endTime,
                                                 bool scheduleIsDaily,bool tradeAtBarOpenOnly,bool pinExits,
                                                 bool switchDirectionBySignal);
   void             ~BollingerBandPullbackTrader();
   void              Execute();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BollingerBandPullbackTrader::BollingerBandPullbackTrader(
                                                              string watchedSymbols,

                                                              int bollingerBandPullbackBbPeriod,
                                                              bool bollingerBandPullbackFadeTouch,
                                                              int bollingerBandPullbackTouchPeriod,
                                                              double bollingerBandPullbackBbDeviation,
                                                              ENUM_APPLIED_PRICE bollingerBandPullbackBbAppliedPrice,
                                                              int bollingerBandPullbackTouchShift,
                                                              int bollingerBandPullbackBbShift,
                                                              color bollingerBandPullbackBbIndicatorColor,
                                                              color bollingerBandPullbackTouchIndicatorColor,

                                                              int bollingerBandPullbackMaPeriod,int bollingerBandPullbackMaShift,
                                                              ENUM_MA_METHOD bollingerBandPullbackMaMethod,
                                                              ENUM_APPLIED_PRICE bollingerBandPullbackMaAppliedPrice,
                                                              int bollingerBandPullbackMaColor,

                                                              int bollingerBandPullbackAtrPeriod,double bollingerBandPullbackAtrMultiplier,
                                                              int bollingerBandPullbackShift,int bollingerBandPullbackAtrColor,

                                                              double bollingerBandPullbackMinimumTpSlDistance,
                                                              ENUM_TIMEFRAMES bollingerBandPullbackTimeframe,
                                                              int parallelSignals,double lots,double profitTarget,
                                                              double maxLoss,int slippage,ENUM_DAY_OF_WEEK startDay,
                                                              ENUM_DAY_OF_WEEK endDay,string startTime,string endTime,
                                                              bool scheduleIsDaily,bool tradeAtBarOpenOnly,bool pinExits,
                                                              bool switchDirectionBySignal)
  {
   string symbols=watchedSymbols;
   this.ss=new SymbolSet();
   this.ss.AddSymbolsFromCsv(symbols);

   this.sched=new ScheduleSet();
   if(scheduleIsDaily==true)
     {
      this.sched.AddWeek(startTime,endTime,startDay,endDay);
     }
   else
     {
      this.sched.Add(new Schedule(startDay,startTime,endDay,endTime));
     }

   this.om=new OrderManager();
   this.om.Slippage=slippage;

   this.plman=new PLManager(ss,om);
   this.plman.ProfitTarget=profitTarget;
   this.plman.MaxLoss=maxLoss;
   this.plman.MinAge=60;
   
   this.exitSignal=new AtrExits(
                                          bollingerBandPullbackAtrPeriod,
                                          bollingerBandPullbackAtrMultiplier,
                                          bollingerBandPullbackTimeframe,
                                          bollingerBandPullbackShift,
                                          1,
                                          bollingerBandPullbackAtrColor);
   this.signalSet=new SignalSet();
   this.signalSet.ExitSignal=this.exitSignal;
   int i;
   for(i=0;i<parallelSignals;i++)
     {
      this.signalSet.Add(
                         new BollingerBandsTouch(
                         bollingerBandPullbackBbPeriod+(bollingerBandPullbackBbPeriod*i),
                         bollingerBandPullbackTimeframe,
                         bollingerBandPullbackFadeTouch,
                         bollingerBandPullbackTouchPeriod,
                         bollingerBandPullbackBbDeviation,
                         bollingerBandPullbackBbAppliedPrice,
                         bollingerBandPullbackTouchShift,
                         bollingerBandPullbackBbShift,
                         bollingerBandPullbackShift,
                         bollingerBandPullbackMinimumTpSlDistance,
                         bollingerBandPullbackBbIndicatorColor,
                         bollingerBandPullbackTouchIndicatorColor
                         ));
      this.signalSet.Add(
                         new MovingAveragePullback(
                         bollingerBandPullbackMaPeriod+(bollingerBandPullbackMaPeriod*i),
                         bollingerBandPullbackTimeframe,
                         bollingerBandPullbackMaMethod,
                         bollingerBandPullbackMaAppliedPrice,
                         bollingerBandPullbackMaShift,
                         bollingerBandPullbackShift,
                         bollingerBandPullbackMaColor));
     }

   this.portfolioManager=new PortfolioManager(lots,this.ss,this.sched,this.om,this.plman,this.signalSet);
   this.portfolioManager.tradeEveryTick=!tradeAtBarOpenOnly;
   this.portfolioManager.AllowExitsToBackslide(!pinExits);
   this.portfolioManager.ClosePositionsOnOppositeSignal(switchDirectionBySignal);
   this.portfolioManager.Initialize();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BollingerBandPullbackTrader::~BollingerBandPullbackTrader()
  {
   delete portfolioManager;
   delete ss;
   delete sched;
   delete om;
   delete plman;
   delete exitSignal;
   delete signalSet;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BollingerBandPullbackTrader::Execute()
  {
   this.portfolioManager.Execute();
  }
//+------------------------------------------------------------------+
