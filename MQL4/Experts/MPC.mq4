//+------------------------------------------------------------------+
//|                                                              MPC |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property description "Does Magic."
#property strict

#include <PLManager\PLManager.mqh>
#include <Signals\ExtremeBreak.mqh>
#include <Schedule\ScheduleSet.mqh>
#include <Common\Comparators.mqh>

input int ExtremeBreakPeriod=24;
input int ExtremeBreakShift=2;
input double Lots=0.4;
input double ProfitTarget=60; // Profit target in account currency
input double MaxLoss=60; // Maximum allowed loss in account currency
input int Slippage=10; // Allowed slippage
extern ENUM_DAY_OF_WEEK Start_Day=1;//Start Day
extern ENUM_DAY_OF_WEEK End_Day=5;//End Day
extern string   Start_Time="00:00";//Start Time
extern string   End_Time="24:00";//End Time
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MPC
  {
private:
   bool              deleteLogger;
public:
   ScheduleSet      *schedule;
   OrderManager     *orderManager;
   PLManager        *plmanager;
   AbstractSignal   *signal;
   BaseLogger       *logger;
   datetime          time;
   double            lotSize;
                     MPC(double lots,ScheduleSet *aSchedule,OrderManager *aOrderManager,PLManager *aPlmanager,AbstractSignal *aSignal,BaseLogger *aLogger);
                    ~MPC();
   bool              Validate(ValidationResult *validationResult);
   bool              Validate();
   bool              ValidateAndLog();
   void              ExpertOnInit();
   void              ExpertOnTick();
   bool              CanTrade();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MPC::MPC(double lots,ScheduleSet *aSchedule,OrderManager *aOrderManager,PLManager *aPlmanager,AbstractSignal *aSignal,BaseLogger *aLogger=NULL)
  {
   this.lotSize=lots;
   this.schedule=aSchedule;
   this.orderManager=aOrderManager;
   this.plmanager=aPlmanager;
   this.signal=aSignal;
   if(aLogger==NULL)
     {
      this.logger=new BaseLogger();
      this.deleteLogger=true;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MPC::~MPC()
  {
   if(this.deleteLogger==true)
     {
      delete this.logger;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MPC::Validate()
  {
   ValidationResult *validationResult=new ValidationResult();
   return this.Validate(validationResult);
   delete validationResult;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MPC::Validate(ValidationResult *validationResult)
  {
   validationResult.Result=true;
   Comparators compare;

   bool omv=this.orderManager.Validate(validationResult);
   bool plv=this.plmanager.Validate(validationResult);
   bool sigv=this.signal.Validate(validationResult);

   validationResult.Result=(omv && plv && sigv);

   if(!compare.IsGreaterThan(this.lotSize,(double)0))
     {
      validationResult.AddMessage("Lots must be greater than zero.");
      validationResult.Result=false;
     }

   return validationResult.Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MPC::ValidateAndLog()
  {
   string border[]=
     {
      "",
      "!~ !~ !~ !~ !~ User Settings validation failed ~! ~! ~! ~! ~!",
      ""
     };
   ValidationResult *v=new ValidationResult();
   bool out=mpc.Validate(v);
   if(out==false)
     {
      this.logger.Log(border);
      this.logger.Warn(v.Messages);
      this.logger.Log(border);
     }
   delete v;
   return out;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MPC::ExpertOnInit()
  {
   if(!this.ValidateAndLog())
     {
      ExpertRemove();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MPC::ExpertOnTick()
  {
   if(!this.CanTrade())
     {
      return;
     }
   if(Time[0]!=this.time)
     {
      this.time=Time[0];
      if(this.schedule.IsActive(TimeCurrent()))
        {
         this.signal.Analyze();
         if(this.signal.Signal<0)
           {
            if(false==OrderSend(this.signal.Symbol,OP_SELL,this.lotSize,Bid,this.orderManager.Slippage,0,0))
              {
               this.logger.Error("OrderSend : "+(string)GetLastError());
              }
           }
         if(this.signal.Signal>0)
           {
            if(false==OrderSend(this.signal.Symbol,OP_BUY,this.lotSize,Ask,this.orderManager.Slippage,0,0))
              {
               this.logger.Error("OrderSend : "+(string)GetLastError());
              }
           }
        }
     }
   this.plmanager.Execute();
  }
//+------------------------------------------------------------------+
//|Rules to stop the bot from even trying to trade                   |
//+------------------------------------------------------------------+
bool MPC::CanTrade()
  {
   return this.plmanager.CanTrade();
  }

MPC *mpc;
SymbolSet *ss;
ScheduleSet *sched;
OrderManager *om;
PLManager *plman;
ExtremeBreak *signal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deinit()
  {
   delete mpc;
   delete ss;
   delete sched;
   delete om;
   delete plman;
   delete signal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void init()
  {
   string symbols=Symbol();
   ss=new SymbolSet();
   ss.AddSymbolsFromCsv(symbols);

   sched=new ScheduleSet();
   sched.AddWeek(Start_Time,End_Time,Start_Day,End_Day);

   om=new OrderManager();
   om.Slippage=Slippage;

   plman=new PLManager(ss,om);
   plman.ProfitTarget=ProfitTarget;
   plman.MaxLoss=MaxLoss;
   plman.MinAge=60;

   signal=new ExtremeBreak(ExtremeBreakPeriod,symbols,(ENUM_TIMEFRAMES)Period(),ExtremeBreakShift);

   mpc=new MPC(Lots,sched,om,plman,signal);

   mpc.ExpertOnInit();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   mpc.ExpertOnTick();
  }
//+------------------------------------------------------------------+
