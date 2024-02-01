//+------------------------------------------------------------------+
//|                           Rollback entry Pending stop orders.mq5 |
//|                         Copyright © 2021-2022, Vladimir Karputov |
//|                      https://www.mql5.com/en/users/barabashkakvn |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2021-2022, Vladimir Karputov"
#property link      "https://www.mql5.com/en/users/barabashkakvn"
#property version   "1.003"
#property description "'Take Profit', 'Stop Loss', 'Trailing', "
#property description "'Minimum indent' and 'Pending: Indent' - in Points (1.00055-1.00045=10 points)"
#property description "'Search signals on ...' a new bar'"
/*
   barabashkakvn Trading engine 4.015
*/
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
//---
CPositionInfo  m_position;                   // object of CPositionInfo class
CTrade         m_trade;                      // object of CTrade class
CSymbolInfo    m_symbol;                     // object of CSymbolInfo class
CAccountInfo   m_account;                    // object of CAccountInfo class
CDealInfo      m_deal;                       // object of CDealInfo class
COrderInfo     m_order;                      // object of COrderInfo class
CMoneyFixedMargin *m_money;                  // object of CMoneyFixedMargin class
//+------------------------------------------------------------------+
//| Enum Lor or Risk                                                 |
//+------------------------------------------------------------------+
enum ENUM_LOT_OR_RISK
  {
   lots_min=0, // Lots Min
   lot=1,      // Constant lot
   risk=2,     // Risk in percent for a deal (range: from 1.00 to 100.00)
  };
//+------------------------------------------------------------------+
//| Enum Trade Mode                                                  |
//+------------------------------------------------------------------+
enum ENUM_TRADE_MODE
  {
   buy=0,      // Allowed only BUY positions
   sell=1,     // Allowed only SELL positions
   buy_sell=2, // Allowed BUY and SELL positions
  };
//+------------------------------------------------------------------+
//| Enum Bar Сurrent                                                 |
//+------------------------------------------------------------------+
enum ENUM_BAR_CURRENT
  {
   bar_0=0,    // bar #0 (at every tick)
   bar_1=1,    // bar #1 (on a new bar)
  };
//--- input parameters
input group             "Trading settings"
input ENUM_TIMEFRAMES      InpWorkingPeriod        = PERIOD_CURRENT; // Working timeframe
input uint                 InpStopLoss             = 150;            // Stop Loss (SL)
input uint                 InpTakeProfit           = 460;            // Take Profit (TP)
input ENUM_BAR_CURRENT     InpTrailingBarCurrent   = bar_1;          // Trailing on ...
input uint                 InpTrailingStop         = 250;            // Trailing Stop, min distance from price to SL ('0' -> OFF)
input uint                 InpTrailingStep         = 50;             // Trailing Step
input group             "Position size management (lot calculation)"
input ENUM_LOT_OR_RISK     InpLotOrRisk            = risk;           // Money management lot: Lot OR Risk
input double               InpVolumeLotOrRisk      = 3.0;            // The value for "Money management"
input group             "Trade mode"
input ENUM_TRADE_MODE      InpTradeMode            = buy_sell;       // Trade mode:
input group             "Signal"
input uint                 InpMinimumIndent        = 15;             // Minimum indent from the price to High Low
input group             "Time control"
input bool                 InpTimeControl          = false;          // Use time control
input uchar                InpStartHour            = 10;             // Start Hour
input uchar                InpStartMinute          = 01;             // Start Minute
input uchar                InpEndHour              = 15;             // End Hour
input uchar                InpEndMinute            = 02;             // End Minute
input group             "Pending Order Parameters"
input ushort               InpPendingExpiration    = 600;            // Pending: Expiration, in minutes ('0' -> OFF)
input uint                 InpPendingIndent        = 5;              // Pending: Indent
input uint                 InpPendingMaxSpread     = 12;             // Pending: Maximum spread ('0' -> OFF)
input group             "Additional features"
input bool                 InpPrintLog             = true;           // Print log
input uchar                InpFreezeCoefficient    = 3;              // Coefficient (if Freeze==0 Or StopsLevels==0)
input ulong                InpDeviation            = 10;             // Deviation, in Points (1.00045-1.00055=10 points)
input ulong                InpMagic                = 133504359;      // Magic number
//---
double   m_stop_loss                = 0.0;      // Stop Loss                  -> double
double   m_take_profit              = 0.0;      // Take Profit                -> double
double   m_trailing_stop            = 0.0;      // Trailing Stop              -> double
double   m_trailing_step            = 0.0;      // Trailing Step              -> double
double   m_minimum_indent           = 0.0;      // Minimum indent             -> double
double   m_pending_indent           = 0.0;      // Pending: Indent            -> double
double   m_pending_max_spread       = 0.0;      // Pending: Maximum spread    -> double

datetime m_prev_bars                = 0;        // "0" -> D'1970.01.01 00:00';
int      m_bar_current              = 0;
bool     m_need_delete_all          = false;    // delete all pending orders
bool     m_waiting_pending_order    = false;    // waiting for a pending order
bool     m_init_error               = false;    // error on InInit
//--- the tactic is this: ***,
//---    and pending orders (if the spread was verified)
//---    just shoot and zero out the arrays of structures
//+------------------------------------------------------------------+
//| Structurt Pending                                                |
//+------------------------------------------------------------------+
struct STRUCT_PENDING
  {
   ENUM_ORDER_TYPE   pending_type;           // pending order type
   double            volume;                 // pending order volume
   double            price;                  // pending order price
   double            stop_loss;              // pending order stop loss, in pips * m_adjusted_point (if "0.0" -> the m_stop_loss)
   double            take_profit;            // pending order take profit, in pips * m_adjusted_point (if "0.0" -> the m_take_profit)
   double            indent;                 // pending indent, in pips * m_adjusted_point
   long              expiration;             // expiration (extra time)
   //--- Constructor
                     STRUCT_PENDING()
     {
      pending_type               = WRONG_VALUE;
      volume                     = 0.0;
      price                      = 0.0;
      stop_loss                  = 0.0;
      take_profit                = 0.0;
      indent                     = 0.0;
      expiration                 = 0;
     }
  };
STRUCT_PENDING SPending[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- forced initialization of variables
   m_stop_loss                = 0.0;      // Stop Loss                  -> double
   m_take_profit              = 0.0;      // Take Profit                -> double
   m_trailing_stop            = 0.0;      // Trailing Stop              -> double
   m_trailing_step            = 0.0;      // Trailing Step              -> double
   m_minimum_indent           = 0.0;      // Minimum indent             -> double
   m_pending_indent           = 0.0;      // Pending: Indent            -> double
   m_pending_max_spread       = 0.0;      // Pending: Maximum spread    -> double
   m_prev_bars                = 0;        // "0" -> D'1970.01.01 00:00';
   m_bar_current              = 0;
   m_need_delete_all          = false;    // delete all pending orders
   m_waiting_pending_order    = false;    // waiting for a pending order
   m_init_error               = false;    // error on InInit
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      string err_text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                      "Трейлинг невозможен: параметр \"Trailing Step\" равен нулю!":
                      "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
         Print(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
      else // if the Expert Advisor is run on the chart, tell the user about the error
         Alert(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
      //---
      m_init_error=true;
      return(INIT_SUCCEEDED);
     }
//---
   ResetLastError();
   if(!m_symbol.Name(Symbol())) // sets symbol name
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: CSymbolInfo.Name");
      return(INIT_FAILED);
     }
   RefreshRates();
//---
   if(InpPendingExpiration>0)
     {
      int exp_type=(int)SYMBOL_EXPIRATION_SPECIFIED;
      int expiration=(int)m_symbol.TradeTimeFlags();
      if((expiration&exp_type)!=exp_type)
        {
         string err_text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                         "На символе "+m_symbol.Name()+" нельзя задать Срок истечения для отложенного ордера!":
                         "On the symbol "+m_symbol.Name()+" you can not set the expiration date for a pending order!";
         if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
            Print(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
         else // if the Expert Advisor is run on the chart, tell the user about the error
            Alert(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
         //---
         m_init_error=true;
         return(INIT_SUCCEEDED);
        }
     }
//---
   m_trade.SetExpertMagicNumber(InpMagic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(InpDeviation);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
//---
   m_stop_loss                = InpStopLoss                 * m_symbol.Point();
   m_take_profit              = InpTakeProfit               * m_symbol.Point();
   m_trailing_stop            = InpTrailingStop             * m_symbol.Point();
   m_trailing_step            = InpTrailingStep             * m_symbol.Point();
   m_minimum_indent           = InpMinimumIndent            * m_symbol.Point();
   m_pending_indent           = InpPendingIndent            * m_symbol.Point();
   m_pending_max_spread       = InpPendingMaxSpread         * m_symbol.Point();
//--- check the input parameter "Lots"
   string err_text="";
   if(InpLotOrRisk==lot)
     {
      if(!CheckVolumeValue(InpVolumeLotOrRisk,err_text))
        {
         if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
            Print(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
         else // if the Expert Advisor is run on the chart, tell the user about the error
            Alert(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
         //---
         m_init_error=true;
         return(INIT_SUCCEEDED);
        }
     }
   else
      if(InpLotOrRisk==risk)
        {
         if(m_money!=NULL)
            delete m_money;
         m_money=new CMoneyFixedMargin;
         if(m_money!=NULL)
           {
            if(InpVolumeLotOrRisk<1 || InpVolumeLotOrRisk>100)
              {
               Print(__FILE__," ",__FUNCTION__,", ERROR: ");
               Print("The value for \"Money management\" (",DoubleToString(InpVolumeLotOrRisk,2),") -> invalid parameters");
               Print("   parameter must be in the range: from 1.00 to 100.00");
               //---
               m_init_error=true;
               return(INIT_SUCCEEDED);
              }
            if(!m_money.Init(GetPointer(m_symbol),InpWorkingPeriod,m_symbol.Point()*digits_adjust))
              {
               Print(__FILE__," ",__FUNCTION__,", ERROR: CMoneyFixedMargin.Init");
               //---
               m_init_error=true;
               return(INIT_SUCCEEDED);
              }
            m_money.Percent(InpVolumeLotOrRisk);
           }
         else
           {
            Print(__FILE__," ",__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
            return(INIT_FAILED);
           }
        }
//---
   m_bar_current=1;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(m_money!=NULL)
      delete m_money;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(m_init_error)
      return;
//---
   if(m_need_delete_all)
     {
      if(IsPendingOrdersExists())
        {
         DeleteAllPendingOrders();
         return;
        }
      else
         m_need_delete_all=false;
     }
//---
   int size_need_pending=ArraySize(SPending);
   if(size_need_pending>0)
     {
      if(!m_waiting_pending_order)
         for(int i=size_need_pending-1; i>=0; i--)
           {
            m_waiting_pending_order=true;
            PlaceOrders(i);
           }
      return;
     }
//---
   if(InpTrailingBarCurrent==bar_0) // trailing at every tick
     {
      Trailing();
     }
//--- we work only at the time of the birth of new bar
   datetime time_0=iTime(m_symbol.Name(),InpWorkingPeriod,0);
   if(time_0==m_prev_bars)
      return;
   m_prev_bars=time_0;
   if(InpTrailingBarCurrent==bar_1) // trailing only at the time of the birth of new bar
     {
      Trailing();
     }
//--- search for trading signals only at the time of the birth of new bar
   if(!RefreshRates())
     {
      m_prev_bars=0;
      return;
     }
//--- search for trading signals
   if(!SearchTradingSignals())
     {
      m_prev_bars=0;
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//--- get transaction type as enumeration value
   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
//--- if transaction is result of addition of the transaction in history
   if(type==TRADE_TRANSACTION_DEAL_ADD)
     {
      ResetLastError();
      if(HistoryDealSelect(trans.deal))
         m_deal.Ticket(trans.deal);
      else
        {
         Print(__FILE__," ",__FUNCTION__,", ERROR: ","HistoryDealSelect(",trans.deal,") error: ",GetLastError());
         return;
        }
      if(m_deal.Symbol()==m_symbol.Name() && m_deal.Magic()==InpMagic)
        {
         ENUM_DEAL_TYPE deal_type   = m_deal.DealType();
         ENUM_DEAL_ENTRY deal_entry = m_deal.Entry();
         if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
           {
            if(deal_entry==DEAL_ENTRY_IN || deal_entry==DEAL_ENTRY_INOUT)
              {
               m_need_delete_all=true;
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: ","RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: ","Ask == 0.0 OR Bid == 0.0");
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the position volume                     |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем меньше минимально допустимого SYMBOL_VOLUME_MIN=%.2f",min_volume);
      else
         error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем больше максимально допустимого SYMBOL_VOLUME_MAX=%.2f",max_volume);
      else
         error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем не кратен минимальному шагу SYMBOL_VOLUME_STEP=%.2f, ближайший правильный объем %.2f",
                                        volume_step,ratio*volume_step);
      else
         error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                        volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Lot Check                                                        |
//+------------------------------------------------------------------+
double LotCheck(double lots,CSymbolInfo &symbol)
  {
//--- calculate maximum volume
   double volume=NormalizeDouble(lots,2);
   double stepvol=symbol.LotsStep();
   if(stepvol>0.0)
      volume=stepvol*MathFloor(volume/stepvol);
//---
   double minvol=symbol.LotsMin();
   if(volume<minvol)
      volume=0.0;
//---
   double maxvol=symbol.LotsMax();
   if(volume>maxvol)
      volume=maxvol;
//---
   return(volume);
  }
//+------------------------------------------------------------------+
//| Check Freeze and Stops levels                                    |
//+------------------------------------------------------------------+
void FreezeStopsLevels(double &freeze,double &stops)
  {
//--- check Freeze and Stops levels
   /*
   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------

   SYMBOL_TRADE_STOPS_LEVEL determines the number of points for minimum indentation of the
      StopLoss and TakeProfit levels from the current closing price of the open position
   ------------------------------------------------|------------------------------------------
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|------------------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid                        |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
   ------------------------------------------------------------------------------------------
   */
   double coeff=(double)InpFreezeCoefficient;
   if(!RefreshRates() || !m_symbol.Refresh())
      return;
//--- FreezeLevel -> for pending order and modification
   double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
     {
      if(InpFreezeCoefficient>0)
         freeze_level=(m_symbol.Ask()-m_symbol.Bid())*coeff;
     }
   else
      freeze_level*=coeff;
//--- StopsLevel -> for TakeProfit and StopLoss
   double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
     {
      if(InpFreezeCoefficient>0)
         stop_level=(m_symbol.Ask()-m_symbol.Bid())*coeff;
     }
   else
      stop_level*=coeff;
//---
   freeze=freeze_level;
   stops=stop_level;
//---
   return;
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print(__FILE__," ",__FUNCTION__,", Symbol: ",symbol.Name()+", "+
         "Code of request result: "+IntegerToString(trade.ResultRetcode())+", "+
         "Code of request result as a string: "+trade.ResultRetcodeDescription(),
         "Trade execution mode: "+symbol.TradeExecutionDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal())+", "+
         "Order ticket: "+IntegerToString(trade.ResultOrder())+", "+
         "Order retcode external: "+IntegerToString(trade.ResultRetcodeExternal())+", "+
         "Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits())+", "+
         "Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits())+", "+
         "Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStop==0)
      return;
   double freeze=0.0,stops=0.0;
   FreezeStopsLevels(freeze,stops);
   double max_levels=(freeze>stops)?freeze:stops;
   /*
   SYMBOL_TRADE_STOPS_LEVEL determines the number of points for minimum indentation of the
      StopLoss and TakeProfit levels from the current closing price of the open position
   ------------------------------------------------|------------------------------------------
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|------------------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid                        |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
   ------------------------------------------------------------------------------------------

   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------
   */
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
           {
            double price_current = m_position.PriceCurrent();
            double price_open    = m_position.PriceOpen();
            double stop_loss     = m_position.StopLoss();
            double take_profit   = m_position.TakeProfit();
            double ask           = m_symbol.Ask();
            double bid           = m_symbol.Bid();
            //---
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(price_current-price_open>m_trailing_stop+m_trailing_step)
                  if(stop_loss<price_current-(m_trailing_stop+m_trailing_step))
                     if(m_trailing_stop>=max_levels && (take_profit-bid>=max_levels || take_profit==0.0))
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(price_current-m_trailing_stop),
                                                   take_profit))
                           if(InpPrintLog)
                              Print(__FILE__," ",__FUNCTION__,", ERROR: ","Modify BUY ",m_position.Ticket(),
                                    " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                    ", description of result: ",m_trade.ResultRetcodeDescription());
                        if(InpPrintLog)
                          {
                           RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                        continue;
                       }
              }
            else
              {
               if(price_open-price_current>m_trailing_stop+m_trailing_step)
                  if((stop_loss>(price_current+(m_trailing_stop+m_trailing_step))) || (stop_loss==0))
                     if(m_trailing_stop>=max_levels && ask-take_profit>=max_levels)
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(price_current+m_trailing_stop),
                                                   take_profit))
                           if(InpPrintLog)
                              Print(__FILE__," ",__FUNCTION__,", ERROR: ","Modify SELL ",m_position.Ticket(),
                                    " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                    ", description of result: ",m_trade.ResultRetcodeDescription());
                        if(InpPrintLog)
                          {
                           RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                       }
              }
           }
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultModify(CTrade &trade,CSymbolInfo &symbol,CPositionInfo &position)
  {
   Print("File: ",__FILE__,", symbol: ",symbol.Name());
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
   Print("Freeze Level: "+DoubleToString(symbol.FreezeLevel(),0),", Stops Level: "+DoubleToString(symbol.StopsLevel(),0));
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
  }
//+------------------------------------------------------------------+
//| Search trading signals                                           |
//+------------------------------------------------------------------+
bool SearchTradingSignals(void)
  {
   if(!TimeControlHourMinute())
      return(true);
   int size_need_pending=ArraySize(SPending);
   if(size_need_pending>0)
      return(true);
   int count_buy_stops=0,count_sell_stops=0;
   CalculateAllPendingOrders(count_buy_stops,count_sell_stops);
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int start_pos=0,count=3;
   if(CopyRates(m_symbol.Name(),PERIOD_CURRENT,start_pos,count,rates)!=count)
     {
      m_prev_bars=0;
      return(false);
     }
//--- BUY Signal
   if(count_buy_stops==0 && rates[1].high-m_symbol.Ask()>=m_minimum_indent)
     {
      size_need_pending=ArraySize(SPending);
      ArrayResize(SPending,size_need_pending+1);
      SPending[size_need_pending].pending_type=ORDER_TYPE_BUY_STOP;
      SPending[size_need_pending].price=rates[1].high;
      SPending[size_need_pending].indent=m_pending_indent;
      if(InpPendingExpiration>0)
         SPending[size_need_pending].expiration=(long)(InpPendingExpiration*60);
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,", OK: ","Signal BUY STOP");
     }
//--- SELL Signal
   if(count_sell_stops==0 && m_symbol.Bid()-rates[1].low>=m_minimum_indent)
     {
      size_need_pending=ArraySize(SPending);
      ArrayResize(SPending,size_need_pending+1);
      SPending[size_need_pending].pending_type=ORDER_TYPE_SELL_STOP;
      SPending[size_need_pending].price=rates[1].low;
      SPending[size_need_pending].indent=m_pending_indent;
      if(InpPendingExpiration>0)
         SPending[size_need_pending].expiration=(long)(InpPendingExpiration*60);
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,", OK: ","Signal BUY STOP");
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders(void)
  {
   double freeze=0.0,stops=0.0;
   FreezeStopsLevels(freeze,stops);
   /*
   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------
   */
//---
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==InpMagic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_LIMIT)
              {
               if(m_symbol.Ask()-m_order.PriceOpen()>=freeze)
                  if(!m_trade.OrderDelete(m_order.Ticket()))
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", ERROR: ","CTrade.OrderDelete ",m_order.Ticket());
               continue;
              }
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
              {
               if(m_order.PriceOpen()-m_symbol.Ask()>=freeze)
                  if(!m_trade.OrderDelete(m_order.Ticket()))
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", ERROR: ","CTrade.OrderDelete ",m_order.Ticket());
               continue;
              }
            if(m_order.OrderType()==ORDER_TYPE_SELL_LIMIT)
              {
               if(m_order.PriceOpen()-m_symbol.Bid()>=freeze)
                  if(!m_trade.OrderDelete(m_order.Ticket()))
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", ERROR: ","CTrade.OrderDelete ",m_order.Ticket());
               continue;
              }
            if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
              {
               if(m_symbol.Bid()-m_order.PriceOpen()>=freeze)
                  if(!m_trade.OrderDelete(m_order.Ticket()))
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", ERROR: ","CTrade.OrderDelete ",m_order.Ticket());
               continue;
              }
           }
  }
//+------------------------------------------------------------------+
//| Is pending orders exists                                         |
//+------------------------------------------------------------------+
bool IsPendingOrdersExists(void)
  {
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==InpMagic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Place Orders                                                     |
//+------------------------------------------------------------------+
void PlaceOrders(const int index)
  {
   double freeze=0.0,stops=0.0;
   FreezeStopsLevels(freeze,stops);
   /*
   SYMBOL_TRADE_STOPS_LEVEL determines the number of points for minimum indentation of the
      StopLoss and TakeProfit levels from the current closing price of the open position
   ------------------------------------------------|------------------------------------------
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|------------------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid                        |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
   ------------------------------------------------------------------------------------------

   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------
   */
   double spread=m_symbol.Ask()-m_symbol.Bid();
   if(m_pending_max_spread>0.0 && spread>m_pending_max_spread)
     {
      m_waiting_pending_order=false;
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,
               ", ERROR: ","Spread Ask-Bid (",DoubleToString(spread,m_symbol.Digits()),")",
               " > Maximum spread (",DoubleToString(m_pending_max_spread,m_symbol.Digits()),")");
      return;
     }
//--- buy limit
   if(SPending[index].pending_type==ORDER_TYPE_BUY_LIMIT)
     {
      if(SPending[index].price==0.0)
         SPending[index].price=m_symbol.Ask()-m_pending_indent;
      else
         if(SPending[index].indent>0)
            SPending[index].price=SPending[index].price-SPending[index].indent;
      if(m_symbol.Ask()-SPending[index].price<stops) // check price
         SPending[index].price=m_symbol.Ask()-stops;
      SPending[index].stop_loss=(m_stop_loss==0.0)?0.0:SPending[index].price-m_stop_loss;
      SPending[index].take_profit=(m_take_profit==0.0)?0.0:SPending[index].price+m_take_profit;
      double sl=SPending[index].stop_loss;
      if(sl<=0.0) // check sl
         sl=0.0;
      else
         if(SPending[index].price-sl<stops)
            sl=SPending[index].price-stops;
      double tp=SPending[index].take_profit;
      if(tp<=0.0) // check tp
         tp=0.0;
      else
         if(tp-SPending[index].price<stops)
            tp=SPending[index].price+stops;
      PendingOrder(index,sl,tp);
      ArrayRemove(SPending,index,1);
      m_waiting_pending_order=false;
      return;
     }
//--- sell limit
   if(SPending[index].pending_type==ORDER_TYPE_SELL_LIMIT)
     {
      if(SPending[index].price==0.0)
         SPending[index].price=m_symbol.Bid()+m_pending_indent;
      else
         if(SPending[index].indent>0)
            SPending[index].price=SPending[index].price+SPending[index].indent;
      if(SPending[index].price-m_symbol.Bid()<stops) // check price
         SPending[index].price=m_symbol.Bid()+stops;
      SPending[index].stop_loss=(m_stop_loss==0.0)?0.0:SPending[index].price+m_stop_loss;
      SPending[index].take_profit=(m_take_profit==0.0)?0.0:SPending[index].price-m_take_profit;
      double sl=SPending[index].stop_loss;
      if(sl<=0.0) // check sl
         sl=0.0;
      else
         if(sl-SPending[index].price<stops)
            sl=SPending[index].price+stops;
      double tp=SPending[index].take_profit;
      if(tp<=0.0) // check tp
         tp=0.0;
      else
         if(SPending[index].price-tp<stops)
            tp=SPending[index].price-stops;
      PendingOrder(index,sl,tp);
      ArrayRemove(SPending,index,1);
      m_waiting_pending_order=false;
      return;
     }
//--- buy stop
   if(SPending[index].pending_type==ORDER_TYPE_BUY_STOP)
     {
      if(SPending[index].price==0.0)
         SPending[index].price=m_symbol.Ask()+m_pending_indent;
      else
         if(SPending[index].indent>0)
            SPending[index].price=SPending[index].price+SPending[index].indent;
      if(SPending[index].price-m_symbol.Ask()<stops) // check price
         SPending[index].price=m_symbol.Ask()+stops;
      SPending[index].stop_loss=(m_stop_loss==0.0)?0.0:SPending[index].price-m_stop_loss;
      SPending[index].take_profit=(m_take_profit==0.0)?0.0:SPending[index].price+m_take_profit;
      double sl=SPending[index].stop_loss;
      if(sl<=0.0)// check sl
         sl=0.0;
      else
         if(SPending[index].price-sl<stops)
            sl=SPending[index].price-stops;
      double tp=SPending[index].take_profit;
      if(tp<=0.0) // check tp
         tp=0.0;
      else
         if(tp-SPending[index].price<stops)
            tp=SPending[index].price+stops;
      PendingOrder(index,sl,tp);
      ArrayRemove(SPending,index,1);
      m_waiting_pending_order=false;
      return;
     }
//--- sell stop
   if(SPending[index].pending_type==ORDER_TYPE_SELL_STOP)
     {
      if(SPending[index].price==0.0)
         SPending[index].price=m_symbol.Bid()-m_pending_indent;
      else
         if(SPending[index].indent>0)
            SPending[index].price=SPending[index].price-SPending[index].indent;
      if(m_symbol.Bid()-SPending[index].price<stops) // check price
         SPending[index].price=m_symbol.Bid()-stops;
      SPending[index].stop_loss=(m_stop_loss==0.0)?0.0:SPending[index].price+m_stop_loss;
      SPending[index].take_profit=(m_take_profit==0.0)?0.0:SPending[index].price-m_take_profit;
      double sl=SPending[index].stop_loss;
      if(sl<=0.0) // check sl
         sl=0.0;
      else
         if(sl-SPending[index].price<stops)
            sl=SPending[index].price+stops;
      double tp=SPending[index].take_profit;
      if(tp<=0.0) // check tp
         tp=0.0;
      else
         if(SPending[index].price-tp<stops)
            tp=SPending[index].price-stops;
      PendingOrder(index,sl,tp);
      ArrayRemove(SPending,index,1);
      m_waiting_pending_order=false;
      return;
     }
  }
//+------------------------------------------------------------------+
//| Pending order                                                    |
//+------------------------------------------------------------------+
bool PendingOrder(const int index,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
   double long_lot=0.0;
   double short_lot=0.0;
   double check_lot=0.0;
   ENUM_ORDER_TYPE check_order_type=-1;
   double check_price=0.0;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   switch(SPending[index].pending_type)
     {
      case  ORDER_TYPE_BUY:
         check_order_type=ORDER_TYPE_BUY;
         break;
      case ORDER_TYPE_SELL:
         check_order_type=ORDER_TYPE_SELL;
         break;
      case ORDER_TYPE_BUY_LIMIT:
         check_order_type=ORDER_TYPE_BUY;
         break;
      case ORDER_TYPE_SELL_LIMIT:
         check_order_type=ORDER_TYPE_SELL;
         break;
      case ORDER_TYPE_BUY_STOP:
         check_order_type=ORDER_TYPE_BUY;
         break;
      case ORDER_TYPE_SELL_STOP:
         check_order_type=ORDER_TYPE_SELL;
         break;
      default:
         return(false);
         break;
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   if(check_order_type==ORDER_TYPE_BUY)
      check_price=m_symbol.Ask();
   else
      check_price=m_symbol.Bid();
//--- volume calculation
   if(SPending[index].volume>0.0)
      check_lot=SPending[index].volume;
   else
     {
      //---
      if(InpLotOrRisk==risk)
        {
         bool error=false;
         long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", OK: ","sl=",DoubleToString(sl,m_symbol.Digits()),
                  ", CheckOpenLong: ",DoubleToString(long_lot,2),
                  ", Balance: ",    DoubleToString(m_account.Balance(),2),
                  ", Equity: ",     DoubleToString(m_account.Equity(),2),
                  ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
         if(long_lot==0.0)
           {
            if(InpPrintLog)
               Print(__FILE__," ",__FUNCTION__,", ERROR: ","CMoneyFixedMargin.CheckOpenLong returned the value of \"0.0\"");
            error=true;
           }
         //---
         short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", OK: ","sl=",DoubleToString(sl,m_symbol.Digits()),
                  ", CheckOpenLong: ",DoubleToString(short_lot,2),
                  ", Balance: ",    DoubleToString(m_account.Balance(),2),
                  ", Equity: ",     DoubleToString(m_account.Equity(),2),
                  ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
         if(short_lot==0.0)
           {
            if(InpPrintLog)
               Print(__FILE__," ",__FUNCTION__,", ERROR: ","CMoneyFixedMargin.CheckOpenShort returned the value of \"0.0\"");
            error=true;
           }
         //---
         if(error)
            return(false);
        }
      else
         if(InpLotOrRisk==lot)
           {
            long_lot=InpVolumeLotOrRisk;
            short_lot=InpVolumeLotOrRisk;
           }
         else
            if(InpLotOrRisk==lots_min)
              {
               long_lot=m_symbol.LotsMin();
               short_lot=m_symbol.LotsMin();
              }
            else
               return(false);
      //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
      if(check_order_type==ORDER_TYPE_BUY)
         check_lot=long_lot;
      else
         check_lot=short_lot;
     }
//---
   if(m_symbol.LotsLimit()>0.0)
     {
      double volume_buys        = 0.0;
      double volume_sells       = 0.0;
      double volume_buy_limits  = 0.0;
      double volume_sell_limits = 0.0;
      double volume_buy_stops   = 0.0;
      double volume_sell_stops  = 0.0;
      CalculateAllVolumes(volume_buys,volume_sells,
                          volume_buy_limits,volume_sell_limits,
                          volume_buy_stops,volume_sell_stops);
      if(volume_buys+volume_sells+
         volume_buy_limits+volume_sell_limits+
         volume_buy_stops+volume_sell_stops+check_lot>m_symbol.LotsLimit())
        {
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", ERROR: ","#0 ,",EnumToString(SPending[index].pending_type),", ",
                  "Volume Buy's (",DoubleToString(volume_buys,2),")",
                  "Volume Sell's (",DoubleToString(volume_sells,2),")",
                  "Volume Buy limit's (",DoubleToString(volume_buy_limits,2),")",
                  "Volume Sell limit's (",DoubleToString(volume_sell_limits,2),")",
                  "Volume Buy stops's (",DoubleToString(volume_buy_stops,2),")",
                  "Volume Sell stops's (",DoubleToString(volume_sell_stops,2),")",
                  "Check lot (",DoubleToString(check_lot,2),")",
                  " > Lots Limit (",DoubleToString(m_symbol.LotsLimit(),2),")");
         return(false);
        }
     }
//--- check maximal number of allowed pending orders
   int account_limit_orders=m_account.LimitOrders();
   if(account_limit_orders>0)
     {
      int all_pending_orders=CalculateAllPendingOrders();
      /*
            there is 8,  and there will be  9 > restriction 10 -> OK
            there is 9,  and there will be 10 > restriction 10 -> OK
            there is 10, and there will be 11 > restriction 10 -> ERROR
      */
      if(all_pending_orders+1>account_limit_orders)
         return(false);
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check=m_account.FreeMarginCheck(m_symbol.Name(),
                            check_order_type,check_lot,check_price);
   double margin_check=m_account.MarginCheck(m_symbol.Name(),
                       check_order_type,check_lot,SPending[index].price);
   if(free_margin_check>margin_check)
     {
      bool result=false;
      if(SPending[index].expiration>0)
        {
         datetime time_expiration=TimeCurrent()+(datetime)SPending[index].expiration;
         result=m_trade.OrderOpen(m_symbol.Name(),
                                  SPending[index].pending_type,check_lot,0.0,
                                  m_symbol.NormalizePrice(SPending[index].price),
                                  m_symbol.NormalizePrice(sl),
                                  m_symbol.NormalizePrice(tp),
                                  ORDER_TIME_SPECIFIED,
                                  time_expiration);
        }
      else
        {
         result=m_trade.OrderOpen(m_symbol.Name(),
                                  SPending[index].pending_type,check_lot,0.0,
                                  m_symbol.NormalizePrice(SPending[index].price),
                                  m_symbol.NormalizePrice(sl),
                                  m_symbol.NormalizePrice(tp));
        }
      if(result)
        {
         if(m_trade.ResultOrder()==0)
           {
            if(InpPrintLog)
               Print(__FILE__," ",__FUNCTION__,", ERROR: ","#1 ",EnumToString(SPending[index].pending_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
            return(false);
           }
         else
           {
            if(InpPrintLog)
               Print(__FILE__," ",__FUNCTION__,", OK: ","#2 ",EnumToString(SPending[index].pending_type)," -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
            return(true);
           }
        }
      else
        {
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", ERROR: ","#3 ",EnumToString(SPending[index].pending_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
         return(false);
        }
     }
   else
     {
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,", ERROR: CAccountInfo.FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return(false);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Calculate all volumes                                            |
//+------------------------------------------------------------------+
void CalculateAllVolumes(double &volumne_buys,double &volumne_sells,
                         double &volumne_buy_limits,double &volumne_sell_limits,
                         double &volumne_buy_stops,double &volumne_sell_stops)
  {
   volumne_buys         = 0.0;
   volumne_sells        = 0.0;
   volumne_buy_limits   = 0.0;
   volumne_sell_limits  = 0.0;
   volumne_buy_stops    = 0.0;
   volumne_sell_stops   = 0.0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name())
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               volumne_buys+=m_position.Volume();
            else
               if(m_position.PositionType()==POSITION_TYPE_SELL)
                  volumne_sells+=m_position.Volume();
           }
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name())
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_LIMIT)
               volumne_buy_limits+=m_order.VolumeInitial();
            else
               if(m_order.OrderType()==ORDER_TYPE_SELL_LIMIT)
                  volumne_sell_limits+=m_order.VolumeInitial();
               else
                  if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
                     volumne_buy_stops+=m_order.VolumeInitial();
                  else
                     if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
                        volumne_sell_stops+=m_order.VolumeInitial();
           }
  }
//+------------------------------------------------------------------+
//| Calculate all pending orders                                     |
//+------------------------------------------------------------------+
int CalculateAllPendingOrders(void)
  {
   int count=0;
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         count++;
//---
   return(count);
  }
//+------------------------------------------------------------------+
//| Calculate all pending orders                                     |
//+------------------------------------------------------------------+
void CalculateAllPendingOrders(int &count_buy_stops,int &count_sell_stops)
  {
   count_buy_stops   = 0;
   count_sell_stops  = 0;
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==InpMagic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
               count_buy_stops++;
            else
               if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
                  count_sell_stops++;
           }
  }
//+------------------------------------------------------------------+
//| TimeControl                                                      |
//+------------------------------------------------------------------+
bool TimeControlHourMinute(void)
  {
   if(!InpTimeControl)
      return(true);
   MqlDateTime STimeCurrent;
   datetime time_current=TimeCurrent();
   if(time_current==D'1970.01.01 00:00')
      return(false);
   TimeToStruct(time_current,STimeCurrent);
   if((InpStartHour*60*60+InpStartMinute*60)<(InpEndHour*60*60+InpEndMinute*60)) // intraday time interval
     {
      /*
      Example:
      input uchar    InpStartHour      = 5;        // Start hour
      input uchar    InpEndHour        = 10;       // End hour
      0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
      _  _  _  _  _  +  +  +  +  +  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  +  +  +  +  +  _  _  _  _  _  _
      */
      if((STimeCurrent.hour*60*60+STimeCurrent.min*60>=InpStartHour*60*60+InpStartMinute*60) &&
         (STimeCurrent.hour*60*60+STimeCurrent.min*60<InpEndHour*60*60+InpEndMinute*60))
         return(true);
     }
   else
      if((InpStartHour*60*60+InpStartMinute*60)>(InpEndHour*60*60+InpEndMinute*60)) // time interval with the transition in a day
        {
         /*
         Example:
         input uchar    InpStartHour      = 10;       // Start hour
         input uchar    InpEndHour        = 5;        // End hour
         0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
         _  _  _  _  _  _  _  _  _  _  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  _  _  _  _  _  +  +  +  +  +  +
         */
         if(STimeCurrent.hour*60*60+STimeCurrent.min*60>=InpStartHour*60*60+InpStartMinute*60 ||
            STimeCurrent.hour*60*60+STimeCurrent.min*60<InpEndHour*60*60+InpEndMinute*60)
            return(true);
        }
      else
         return(false);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Close all positions First Swap                                   |
//+------------------------------------------------------------------+
void CloseAllPositionsFirstSwap(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
           {
            double swap=m_position.Swap();
            if(swap<=0.0)
               continue;
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", ERROR: ","BUY PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", ERROR: ","SELL PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
           }
  }
//+------------------------------------------------------------------+
