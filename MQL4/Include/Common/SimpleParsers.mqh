//+------------------------------------------------------------------+
//|                                                SimpleParsers.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class SimpleParsers
  {
public:
   int               ParseCsvLine(string str,string &result[]);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SimpleParsers::ParseCsvLine(string str,string &result[])
  {
   string sep=",";
   ushort u_sep=StringGetCharacter(sep,0);
   int k=StringSplit(str,u_sep,result);
   return k;
  }
//+------------------------------------------------------------------+
