//+------------------------------------------------------------------+
//|                                                   Pedestrian.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict
#include <Signals\PedestrianSignal.mqh>
#include <EA\PortfolioManagerBasedBot\BasePortfolioManagerBot.mqh>
#include <EA\Pedestrian\PedestrianConfig.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Pedestrian : public BasePortfolioManagerBot
  {
public:
   void              Pedestrian(PedestrianConfig &config);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Pedestrian::Pedestrian(PedestrianConfig &config):BasePortfolioManagerBot(config)
  {
   this.signalSet.Add(new PedestrianSignal(
                      config.botPeriod,
                      config.botTimeframe,
                      config.botMinimumTpSlDistance,
                      config.botSkew,
                      config.botAtrMultiplier,
                      config.botRangePeriod,
                      config.botIntradayTimeframe,
                      config.botIntradayPeriod));
   this.Initialize();
  }
//+------------------------------------------------------------------+
