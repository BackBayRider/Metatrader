//+------------------------------------------------------------------+
//|                                        BacktestOptimizations.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Stats\PortfolioStats.mqh>
#include <Common\Comparators.mqh>
#include <BacktestOptimizations\BacktestOptimizationsConfig.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BacktestOptimizations
  {
private:
   Comparators       _compare;
   int               _metricsCount;
   int               _metricsPassed;
   int               _metricsFailed;
   double            _score;
   double            _initialScore;

   void CountMetric(int weight)
     {
      this._metricsCount+=weight;
     };

   void Pass(int weight)
     {
      this.CountMetric(weight);
      this._metricsPassed+=weight;
     };

   void Fail(int weight)
     {
      this.CountMetric(weight);
      this._metricsFailed+=weight;
     };

   BacktestOptimizations *GainsStdDevLimit(double max,double min,int weight)
     {
      if(max<=min)
        {
         return GetPointer(this);
        }
      if(_compare.IsBetween(PortfolioStats::GainsStdDev(),min,max))
        {
         this.Pass(weight);
        }
      else
        {
         this.Fail(weight);
        }
      return GetPointer(this);
     };

   BacktestOptimizations *LossesStdDevLimit(double max,double min,int weight)
     {
      if(max<=min)
        {
         return GetPointer(this);
        }
      if(_compare.IsBetween(PortfolioStats::LossesStdDev(),min,max))
        {
         this.Pass(weight);
        }
      else
        {
         this.Fail(weight);
        }
      return GetPointer(this);
     };

   BacktestOptimizations *NetProfitRange(double max,double min,int weight)
     {
      if(max<=min)
        {
         return GetPointer(this);
        }
      if(_compare.IsBetween(PortfolioStats::NetProfit(),min,max))
        {
         this.Pass(weight);
        }
      else
        {
         this.Fail(weight);
        }
      return GetPointer(this);
     };

   BacktestOptimizations *ExpectancyRange(double max,double min,int weight)
     {
      if(max<=min)
        {
         return GetPointer(this);
        }
      if(_compare.IsBetween(PortfolioStats::ProfitPerTrade(),min,max))
        {
         this.Pass(weight);
        }
      else
        {
         this.Fail(weight);
        }
      return GetPointer(this);
     };

   BacktestOptimizations *TradesPerDayRange(double max,double min,int weight)
     {
      if(max<=min)
        {
         return GetPointer(this);
        }
      double tradesPerDay=0;
      double days=PortfolioStats::HistoryDuration().ToDays();
      int totalTrades=PortfolioStats::TotalTrades();

      if(_compare.IsGreaterThan(days,0.0))
        {
         tradesPerDay=(((double)totalTrades)/days);
        }

      if(_compare.IsBetween(tradesPerDay,min,max))
        {
         this.Pass(weight);
        }
      else
        {
         this.Fail(weight);
        }
      return GetPointer(this);
     };

   BacktestOptimizations *LargestLossPerTotalGainLimit(double highestPercent,int weight)
     {
      if(highestPercent<=0)
        {
         return GetPointer(this);
        }
      double targetMaxLoss=PortfolioStats::TotalGain() *(highestPercent/100);
      double largestLoss=Stats::AbsoluteValue(PortfolioStats::LargestLoss());
      if(_compare.IsLessThan(largestLoss,targetMaxLoss))
        {
         this.Pass(weight);
        }
      else
        {
         this.Fail(weight);
        }
      return GetPointer(this);
     };

   BacktestOptimizations *MedianLossPerMedianGainPercentLimit(double highestPercent, int weight)
     {
      if(highestPercent<=0)
        {
         return GetPointer(this);
        }
      double max=(highestPercent/100);
      double medianLossPerMedianGain=0;
      double medianGain=PortfolioStats::MedianGain();
      double medianLoss=Stats::AbsoluteValue(PortfolioStats::MedianLoss());
      if(medianGain>0)
        {
         medianLossPerMedianGain=medianLoss/medianGain;
         if(_compare.IsLessThan(medianLossPerMedianGain,max))
           {
            this.Pass(weight);
           }
         else
           {
            this.Fail(weight);
           }
        }
      else
        {
         this.Fail(weight);
        }
      return GetPointer(this);
     };

   BacktestOptimizations *FactorBy_PassFail(double weight)
     {
      if(this._metricsCount>0)
        {
         this._score=this._score+((double)(this.Configuration.InitialScore*weight *((double)this._metricsPassed)/((double)this._metricsCount)));
        }
      return GetPointer(this);
     };

   BacktestOptimizations *FactorBy_TotalReturn(double weight)
     {
      double net=PortfolioStats::NetProfit();
      double initialBalance=(AccountBalance()-net);

      double factor=(this.Configuration.InitialScore *weight *(Stats::AbsoluteValue(net)/initialBalance));

      if(_compare.IsGreaterThan(net,0.0))
        {
         this._score=this._score+factor;
        }
      else
        {
         this._score=this._score-factor;
        }
      return GetPointer(this);
     };

   BacktestOptimizations *FactorBy_GainsSlopeUpward(int granularity,double weight)
     {
      if(granularity<=6)
        {
         return GetPointer(this);
        }
      double pointsPerLoop=(this.Configuration.InitialScore*weight *((double)((double)1.0)/(((double)granularity)-2)));
      double r[];
      PortfolioStats::PeriodicAveragesOfReturns(r,Strings::Null,granularity);
      int ct=ArraySize(r);
      if(ct<=6)
        {
         this._score=this._score-(pointsPerLoop*granularity);
         return GetPointer(this);
        }
      int i=0;
      int j=1;
      int k=2;
      double vi;
      double vj;
      double vk;
      double vSum;
      double score=1;
      for(i=0,j=1,k=2;k<ct;i++,j++,k++)
        {
         vi=r[i];
         vj=r[j];
         vk=r[k];
         vSum=vj+vk;

         if(vi<vSum)
           {
            this._score=this._score+pointsPerLoop;
           }
         else
           {
            this._score=this._score-pointsPerLoop;
           }
        }
      return GetPointer(this);
     };

   BacktestOptimizations *FactorBy_GainsSlopeUpward(double weight)
     {
      return this.FactorBy_GainsSlopeUpward(this.Configuration.FactorBy_GainsSlopeUpward_Granularity,weight);
     };
public:
   BacktestOptimizationsConfig Configuration;

   void BacktestOptimizations(BacktestOptimizationsConfig &config)
     {
      this.Configuration=(config);
      this._score=this.Configuration.InitialScore;
      this._metricsCount=0;
      this._metricsPassed=0;
      this._metricsFailed=0;
     };

   double GetScore()
     {
      return (this
              .GainsStdDevLimit()
              .LossesStdDevLimit()
              .NetProfitRange()
              .ExpectancyRange()
              .TradesPerDayRange()
              .LargestLossPerTotalGainLimit()
              .MedianLossPerMedianGainPercentLimit()
              .FactorBy_TotalReturn(10)
              .FactorBy_GainsSlopeUpward(10)
              .FactorBy_PassFail(80)
              ._score / 100 );
     }

   BacktestOptimizations *GainsStdDevLimit()
     {
      return this.GainsStdDevLimit(this.Configuration.GainsStdDevLimitMax,this.Configuration.GainsStdDevLimitMin,this.Configuration.GainsStdDevLimitWeight);
     };

   BacktestOptimizations *LossesStdDevLimit()
     {
      return this.LossesStdDevLimit(this.Configuration.LossesStdDevLimitMax,this.Configuration.LossesStdDevLimitMin,this.Configuration.LossesStdDevLimitWeight);
     };

   BacktestOptimizations *NetProfitRange()
     {
      return this.NetProfitRange(this.Configuration.NetProfitRangeMax,this.Configuration.NetProfitRangeMin,this.Configuration.NetProfitRangeWeight);
     };

   BacktestOptimizations *ExpectancyRange()
     {
      return this.ExpectancyRange(this.Configuration.ExpectancyRangeMax,this.Configuration.ExpectancyRangeMin,this.Configuration.ExpectancyRangeWeight);
     };

   BacktestOptimizations *TradesPerDayRange()
     {
      return this.TradesPerDayRange(this.Configuration.TradesPerDayRangeMax,this.Configuration.TradesPerDayRangeMin,this.Configuration.TradesPerDayRangeWeight);
     };

   BacktestOptimizations *LargestLossPerTotalGainLimit()
     {
      return this.LargestLossPerTotalGainLimit(this.Configuration.LargestLossPerTotalGainLimit,this.Configuration.LargestLossPerTotalGainWeight);
     };

   BacktestOptimizations *MedianLossPerMedianGainPercentLimit()
     {
      return this.MedianLossPerMedianGainPercentLimit(this.Configuration.MedianLossPerMedianGainPercentLimit,this.Configuration.MedianLossPerMedianGainPercentWeight);
     };
  };
//+------------------------------------------------------------------+
