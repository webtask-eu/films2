//+------------------------------------------------------------------+

//|                                                      «iSing».mq5 |

//|                                          © 2021, Yuriy Smagin    |

//|                     https://www.mql5.com/ru/users/daodzin        |

//+------------------------------------------------------------------+

#property copyright "© 2021, Yuriy Smagin"

#property link "https://www.mql5.com/ru/users/daodzin"

#property version "1.5"



#include <Trade\PositionInfo.mqh>// импорт библиотеки информации иб открытой позиции

#include <Trade\AccountInfo.mqh> // импорт библиотеки информации о счете

#include <Trade\Trade.mqh>       // импорт торговой библиотеки

#include <Expert\Money\MoneyFixedLot.mqh>

#include <Trade\SymbolInfo.mqh>

#include <Trade\HistoryOrderInfo.mqh>

#include <Trade\DealInfo.mqh>




//#include "..\Libraries\orderwrappers.mq5"



//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

struct HANDLE

{

   int               MA_CHART;

}

handleMa; // что это?

struct IND_DATA

{

   double            MA_CHART[];

}

ind_date; // что это?



CSymbolInfo symbolInfo; // Обьявляем класс PositionInfo.mqh

CPositionInfo m_position; // Обьявляем класс PositionInfo.mqh

CTrade trade; // Обьявляем класс Trade.mqh

CAccountInfo account_info; // объявляем класс AccountInfo.mqh

//CHistoryOrderInfo m_history;

CDealInfo m_history;

MqlRates mqlRates[]; // Структура для хранения информации о ценах, объемах и спреде.

MqlTick mqlTick; // Структура для хранения последних цен по символу.

MqlDateTime dt; // Структура даты содержит в себе восемь полей типа int.



input group "Main Settings"
// Максимальное отклонение после которой открывается сделка
input int signal_deviation = 17; // Maximum deviation after which a trade is opened
// Динамический поиск отклонения
input bool autodeviation = false; // Dynamic deviation search
// Динамический поиск отклонения
input bool autodeviationHighLow = false; // Work with highs and lows
// Количество баров для рассчета отклонения
input int autodevCountBars = 10; // Number of bars to calculate the deviation
//При - делится среднее, при + умножается среднее для поиска точки входа.
input double autpdevCoeff = 1; // For '-', divide the average, for '+', multiply the average to find the entry point.
//По какому бару проверяем открытие, 0 или 1
input int barNOpen = 0; // Check opening based on which bar, 0 or 1


/* фильтр бытрого снижения или падения, входим только если от образования
минимального или максимального значения прошло N количество секунд */
input group "Filters"
// Работа только по закрытию бара
input bool closeBarOnly = false; // Work only on bar close
// Пережидаем быстрые снижения или падения N-количество секунд, 0 отключено
input int waitFastMovement = 0; // Wait for fast upward or downward movements for N seconds, 0 to disable
/*только одна открытая сделка в день помогает отфильтровать серию убыточных сделок при резком движении*/
input bool oneOrderInDay = true; // Only one open trade per day
/*работаем только в сторону положительного спреда*/
input bool onlySwapPlus = false; // Work in the direction of positive swap
/*Разделить покупки и продажи*/
//input bool sepatateBuyAndSell = true; // Отдельно покупки и продажи
//Дистанция между открытиями
input int minimumDistancePips = 0; // Distance between openings
double minimumDistancePipsPointed = 0; //переменная для хранения значения 0.00040



// Настройка рестарта сигнала
input group "Restart Signal"
enum RestartSignalType
{
/*
   crossMa = 0, // По обратному пересечению
   narrowingRange = 1, // При сужении диапазона
   skipBars = 2, // По количеству последующих баров
 */
  crossMa = 0,        // On reverse crossing of Moving Averages
   narrowingRange = 1, // On narrowing range
   skipBars = 2,       // Number of subsequent bars to skip

};


// Тип рестарта сигнала
input RestartSignalType typeRestartSignal = crossMa; // Type of signal restart
// Рестарт сигнала по обратному пересечению средней
input bool restartSignalByMa = true; // Signal restart on reverse crossing of Moving Averages
// Или диапазон после которого начинается новый поиск сигнала
input double restartSignalRange = 10; // Or the range after which a new signal search begins
 // Или по количеству баров после сигнала
input int countRestartBars = 10; // Or the number of bars after the signal for restart
// переменная для хранения номера бара сделки, для рестарта сигнала по количеству баров
int numberDealBars; // Variable for storing the bar number of the trade, for signal restart based on the number of bars



input group "MoneyManagment"
//  Лот сделки
input double userLot = 0.1; // Trade lot size
// Тейкпрофит по последней серии убытков
input bool lastLossBack = true; // Take profit based on the last losing streak
// Разделять покупки и продажи при просчете убытка
bool separate = true; // Separate buys and sells when calculating loss
// Какой процент процент добавить к профиту по серии убытков
input double lastLossBackAddPercent = 1.2; // Percentage to add to the profit after a losing streak
//Коэфициент умножения лота и уменьшения размера тейкпрофита
input double lastLossBackLot = 1; // Lot multiplier and take profit size reduction factor
//  Риск при котором увеличивается обьем пропорционально
input double risk = 0.05; // Risk at which volume increases proportionally

input double Maxlots = 10; // Maximum allowable lot size


double lotmin = 0, lotmax = 0, lotstep = 0, userMargin = 0;



/* Секция управления параметрами стоп-лосса и тейк-профита */

input group "S/L & T/P"
//Разрешить использование тейк-профита
input bool UseTakeProfit = false; // Allow the use of take profit
//  Размер тейк-профита в пунктах
input int takeProfit = 900; // Take profit size in points
//Разрешить использование стоп-лосса
input bool UseStopLoss = false; // Allow the use of stop loss
//  Размер стоп-лосса в пунктах
input int stopLoss = 900; // Stop loss size in points

double takeProfitPointed, stopLossPointed; //переменные для перевода значений к виду 0.0040

/* ------------------------------------------------------- */



// Настройка скользящей средней

input group "Indicators"

input int period_MA_CHART = 12; //  Indicator Moving Average period

input ENUM_MA_METHOD Signal_MA_Method = MODE_SMA; // Moving Average(10,0,...) Method of averaging

input ENUM_APPLIED_PRICE Signal_MA_Applied = PRICE_CLOSE; // Moving Average(10,0,...) Prices series



input group "Other"

sinput int _Magic = 122341; //  Magic number

bool Log = true; //  Log

bool ShortLog = true; // ShortLog



/* --------------различные способы закрытия сделок----------------*/

input group "Close Settings"
//По какому бару проверяем закрытие, 0 или 1
input int barNClose = 0; // Check closing based on which bar, 0 or 1
input double closeByHighLow = 0;
// Закрытие сделки спустя определенное время
//Время через которое закроется сделка, по умолчанию 2 часа.
bool closeAfterTime = false; // Close the trade after a certain time
input datetime inpLiveOrder = D'1970.01.01 02:00:00'; // Time when the trade will be closed, default is 2 hours.



/* --------------Мультивалютная работа------------*/
//мультивалютная торговля
input bool multicurrancyMode=true; // Multicurrency trading
//мультивалютный тейкпрофит
input bool multicurrancyTP=false; // Multicurrency take profit

/* ------------- Торговые фильтры -------------------*/

input group "Trade Filters"
// Максимальный спред
input int maxSpread = 20; // Maximum spread
input bool onlybuyfilter=false;
input bool onlysellfilter=false;





double contract, noLoss;

bool atrSignal = false, restartSignalSell = false, restartSignalBuy = false;

datetime timeUP = 0, timeDN = 0;

double minimalStopLevel;



//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

double            m_adjusted_point;             // point value adjusted for 3 or 5 points

int OnInit()

{
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(symbolInfo.Digits()==3 || symbolInfo.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=symbolInfo.Point()*digits_adjust;
//--- initialize common information
   symbolInfo.Name(Symbol());
   minimalStopLevel = (double) SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * m_adjusted_point;
   /*if(account_info.MarginMode() == ACCOUNT_MARGIN_MODE_RETAIL_NETTING)

     {

      Print("СТОП! Счет используется для внебиржевого рынка при учете позиций в режиме неттинг (по одному символу может быть только одна позиция)!");

      return (INIT_PARAMETERS_INCORRECT);

     }*/
   minimumDistancePipsPointed = minimumDistancePips * m_adjusted_point;
   TesterHideIndicators(false); // спрячем индикаторы при тестировании
   trade.SetExpertMagicNumber(_Magic); // установим магик номер для торговых ордеров советника
   handleMa.MA_CHART = iMA(_Symbol, _Period, period_MA_CHART, 0, Signal_MA_Method, Signal_MA_Applied);
   ArraySetAsSeries(ind_date.MA_CHART, true);
   ArraySetAsSeries(mqlRates,true);
//---
   return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

datetime newBarDate = 0, priceMinimumSaved_date = 0, priceMaximumSaved_date = 0;

double newBarPrice = 0, priceMaximumSaved = 0;

double priceMinimumSaved = 0, maxprice = 0, priceMaximumSaved0;

int startNewBar = 0;

int BarsSaved; //для сохранения бара для фильтра работы только по новому бару

double openBarPriceSell, openBarPriceBuy;

//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

string temp_string;

string format_string;

string output_string;

int DaySave;
double signal_deviation_pointed;


void OnTick()

{
   double            m_adjusted_point;             // point value adjusted for 3 or 5 points
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(symbolInfo.Digits()==3 || symbolInfo.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=symbolInfo.Point()*digits_adjust;
   signal_deviation_pointed = signal_deviation *m_adjusted_point;
   if(StringLen(output_string) > 2000)
   {
      output_string="";
   }
//  if(dt.day !=DaySave)
//  {DaySave=dt.day; temp_string="";output_string="";}
// double Lots = lots();//lots();
   double Lots = userLot;
   double stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*m_adjusted_point;
// double Lots= NormalizeDouble(MathFloor((account_info.Balance()/200))/100,2);
//Сбрасываем по дефолту тейкпрофит и стоплосс
   takeProfitPointed = takeProfit * m_adjusted_point; // приведем тейкпрофит к значения 0.0040
   stopLossPointed = stopLoss * m_adjusted_point; // приведем стоплосс к значению 0.0040
   double lastTotalLoss; // последняя серия убытков
   double tickPrice; // цена тика при объеме в 1 лот
   double losInpips; // расчет в пунктах последней серии убытков
   string commentMm = ""; //для хранения метки и выборки ордера (например что не нужно его закрывать т.к он управляется тейкпрофитом)
   bool stopSellByFilter = false; // Для фильтров на продажу
   bool stopBuyByFilter = false; // Для фильтров на продажу
//Print(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE));
//if(!UseStopLoss && stopLoss!=220) TesterStop(); // отключим подбор stopLoss если стоплосс отключен
//if(!UseTakeProfit && takeProfit!=2000) TesterStop();// отключим подбор takeProfit если тейкпрофит отключен
   double minimum_priceMaximumSaved_different = 0;
//разрешена ли торговля
   bool tradeAllowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
//получаем размер свободной маржи
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//получаем текущие цены
   if(!SymbolInfoTick(_Symbol, mqlTick))
   {
      Print("Can't receive current prices.");
      Print(__FUNCTION__, " ", GetLastError());
      return;
   }
   double lastOpenPrice = 0; //для хранения цены последних открытых сделок
//PosModify(tradeAllowed);
//---
//Фильтр работы по новому бару
   if(Bars(_Symbol, _Period) == BarsSaved && closeBarOnly)
   {
      //Print("Filtre. Wait New Bar Opened");
      return;
   }
   BarsSaved = Bars(_Symbol, _Period);
   /* ---------Рассчет скорости движенoия цены----------- */
// Если открылся новый бар запишем время открытия бара, например 12:30:05
   if(isNewBar(_Period))
   {
      // Обнуляем все значения переменных
      newBarDate = 0;
      priceMinimumSaved_date = 0;
      newBarPrice = 0;
      priceMinimumSaved = 0;
      maxprice = 0;
      priceMaximumSaved_date = 0;
      priceMaximumSaved = 0;
      newBarDate = mqlTick.time; // запишем дату бара
      newBarPrice = mqlTick.bid; // запишем текущую цену
      //Print("Новый бар "+_Period, "Цена "+newBarPrice, "Время "+newBarDate);
      startNewBar = 1;
   }
//рассчитаем для покупок
   datetime TimeBuyDifference = 0;
   if(priceMinimumSaved == 0)
      priceMinimumSaved = mqlTick.bid; // запишем текущую цену
   if(mqlTick.bid < priceMinimumSaved && startNewBar == 1)  // Если текущая цена меньше сохраненной цены
   {
      priceMinimumSaved = mqlTick.bid; // запомним минимульную цену
      priceMinimumSaved_date = mqlTick.time; // запомним время минимальной цены
      // TimeBuyDifference = priceMinimumSaved_date - newBarDate; // вычислим разницу между временем открытия и временем минимума, 13:30:05-12:31 = 65
   }
   TimeBuyDifference = (priceMinimumSaved_date != 0) ? mqlTick.time - priceMinimumSaved_date : 0; // вычислим разницу между текущим временем и временем ценового минимума
//рассчитаем для продаж
   datetime TimeSellDifference = priceMaximumSaved_date;
   if(priceMaximumSaved == 0)
      priceMaximumSaved = mqlTick.bid; //замишем текущую цену
   if(mqlTick.bid > priceMaximumSaved && startNewBar == 1)
   {
      priceMaximumSaved = mqlTick.bid;
      priceMaximumSaved_date = mqlTick.time;
      // TimeSellDifference=priceMaximumSaved_date-newBarDate; // Вычислим разницу между временем открытия и временем минимума, 13:30:05-12:31 = 65
   }
   TimeSellDifference = (priceMaximumSaved_date != 0) ? mqlTick.time - priceMaximumSaved_date : 0; // вычислим разницу между текущим временем и временем ценового максимума
   /* -------------------- */
// Производит конвертацию из значения типа datetime (количество секунд с 01.01.1970) в переменную типа структуры MqlDateTime.
   TimeToStruct(iTime(_Symbol, _Period, 0), dt);
// Получает в массив rates_array исторические данные структуры MqlRates указанного символа-периода в указанном количестве.
   int countCopybars=0;
   if(autodeviation)
   {
      countCopybars=autodevCountBars;
   }
   else
   {
      countCopybars=1;
   }
   if(CopyRates(_Symbol, _Period, 0, countCopybars+1, mqlRates) < 0)
   {
      Print("Problem with CopyRates mqlRates");
      Print(__FUNCTION__, " ", GetLastError());
   }
//Отсчет элементов копируемых данных (индикаторный буфер с индексом buffer_num) от стартовой позиции ведется от настоящего к прошлому
   CopyBuffer(handleMa.MA_CHART, 0, 0, countCopybars+2, ind_date.MA_CHART);
   double signal_deviation_mod;
   /*---начинаем вычисление максимального отклонения цены от средней скользящей*/
//double deviation=0;    //для записи текущих отклонений
   double deviationAverageHigh=0;    //для записи среднего отклонения
   double deviationAverageLow=0;    //для записи среднего отклонения
   double deviationmax=0; //для сохранения максимального известного отклонения
   double deviationmin=0; //для сохранения максимального известного отклонения
//datetime time=0;        //для записи времени максимального отклонения что бы сравнить с графиком
   if(autodeviation == true)
   {
      //запускаем цикл последовательного вычитания цены средней из цен открытия
      //если результат вычитания больше предыдущего то записываем новое значение
      //или проводим поиск в массиве максимального большого результата вычитания
      for(int x=1; x<=autodevCountBars; x++)
      {
         if(autodeviationHighLow==false)
         {
            deviationAverageHigh = deviationAverageHigh + (mqlRates[x].high - ind_date.MA_CHART[x]);
            deviationAverageLow  = deviationAverageLow  + (mqlRates[x].low  - ind_date.MA_CHART[x]);
         }
         else
         {
            deviationAverageHigh = mqlRates[x].high - ind_date.MA_CHART[x];
            if(deviationAverageHigh>deviationmax)
            {
               deviationmax=deviationAverageHigh;  //записываем максимальное значение и время этого значения
            }
            deviationAverageLow = ind_date.MA_CHART[x] - mqlRates[x].low;
            if(deviationAverageLow>deviationmin)
            {
               deviationmin=deviationAverageLow;  //записываем максимальное значение и время этого значения
            }
         }
         //deviation=MathAbs(ind_date.MA_CHART[x]-mqlRates[x].close);
         //if(deviation>deviationmax){deviationmax=deviation;time=mqlRates[x].time;}//записываем максимальное значение и время этого значения
         //Print("Количество рассчетов x: "+x+ " ind_date.MA_CHART[x] "+ind_date.MA_CHART[x]+" mqlRates[x].high "+mqlRates[x].high);
      }
      //Print("deviationAverage: "+deviationAverage + "Делим на: "+autodevCountBars);
      if(autodeviationHighLow==false)
      {
         deviationAverageHigh = deviationAverageHigh/autodevCountBars;
         deviationAverageLow  = deviationAverageLow/autodevCountBars;
      }
      //Print("deviationAverageHigh получается: "+deviationAverageHigh);
      //Print("deviationAverageLow получается: " +deviationAverageLow);
      if(autodeviationHighLow==false)
      {
         if(autpdevCoeff > 0)
         {
            deviationAverageHigh=deviationAverageHigh*autpdevCoeff;
            deviationAverageLow=deviationAverageLow*autpdevCoeff;
         }
         else
         {
            deviationAverageHigh=deviationAverageHigh/MathAbs(autpdevCoeff);
            deviationAverageLow=deviationAverageLow/MathAbs(autpdevCoeff);
         }
      }
      else
      {
         if(autpdevCoeff > 0)
         {
            deviationAverageHigh=deviationmax*autpdevCoeff;
            deviationAverageLow=deviationmin*autpdevCoeff;
         }
         else
         {
            deviationAverageHigh=deviationmax/MathAbs(autpdevCoeff);
            deviationAverageLow=deviationmin/MathAbs(autpdevCoeff);
         }
      }
   }
//рестарт сигнала на покупку
   if((mqlTick.bid >= ind_date.MA_CHART[0] && restartSignalByMa) ||  // Если цена обратно пересекла или задела среднюю
//   ((ind_date.MA_CHART[0] - mqlTick.bid) >= signal_deviation_pointed && restartSignalRange > 0) || // Если разница между средней и ценой стала меньше заданного
         ((Bars(Symbol(), Period()) - numberDealBars) >= countRestartBars && countRestartBars > 0) // Если прошло такое то количество баров с момента последней сделки
     )
   {
      restartSignalBuy = false;
   }
//рестарт сигнала на продажу
   if((mqlTick.bid <= ind_date.MA_CHART[0] && restartSignalByMa) ||  // Если цена обратно пересекла или задела среднюю
//    ((mqlTick.bid - ind_date.MA_CHART[0]) >= signal_deviation_pointed && restartSignalRange > 0) || // Если разница между средней и ценой стала меньше заданного
         ((Bars(Symbol(), Period()) - numberDealBars) >= countRestartBars && countRestartBars > 0) // Если прошло такое то количество баров с момента последней сделки
     )
   {
      restartSignalSell = false;
   }
// Если сделок нет, продолжаем работать
   if(!SelectPosition())
   {
      restartSignalBuy = false;
      restartSignalSell = false;
      startNewBar = 1;
   }
//Print("GetLossHistoryLastPositionsTotal(multicurrancyTP) "+GetLossHistoryLastPositionsTotal(multicurrancyTP));
   signal_deviation_mod = signal_deviation_pointed;
   if(autodeviation == true)
   {
      signal_deviation_mod = deviationAverageLow;
   }
//--- подготовим заголовок спецификации
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//Print("CHECK restartSignalBuy "+restartSignalBuy+" MA: "+ind_date.MA_CHART[1]+" bid: "+mqlTick.bid+" result: "+(ind_date.MA_CHART[1] - mqlTick.bid) + "signal: "+signal_deviation_mod);
//На покупку
   bool checksSwapBuy = false;
   if(onlySwapPlus == true && SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG) < SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT))
   {
      if(Log)
      {
        Print("Condition 6. Negative swap, exiting. " + (string)SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG));
      }
      checksSwapBuy = true;
   }
   if(!tradeAllowed)
   {
      temp_string=StringFormat("Trade Not Allowed\n",_Symbol);
      StringAdd(output_string,temp_string);
   }
   bool noMoney = false;
   if(!CheckMoneyForTrade(_Symbol,Lots,ORDER_TYPE_BUY))
   {
      if(ShortLog)
      {
         Print("Not enough money");
      }
      temp_string=StringFormat("Not enough money\n",_Symbol);
      StringAdd(output_string,temp_string);
      noMoney = true;
   }
   double d=NormalizeDouble((ind_date.MA_CHART[barNOpen] - mqlTick.bid),_Digits);
   double s=_Symbol;
   double sg=signal_deviation_mod;
   if((ind_date.MA_CHART[barNOpen] - mqlTick.bid) >= MathAbs(signal_deviation_mod) && !restartSignalBuy && onlysellfilter==false && checksSwapBuy==false  && tradeAllowed==true && noMoney==false)    // если разница между средней и ценой больше сигнального отклонения
   {
      if(ShortLog)
      {
         Print("Have a Buy Signal: "+_Symbol+" deviation: "+d+" signal point: "+sg+" Date: "+dt.day+"."+dt.mon+"."+dt.year+" "+dt.hour+":"+dt.min+":"+dt.sec+"\n");
      }
      temp_string=StringFormat("Have a Buy Signal: "+_Symbol+" deviation: "+d+" signal point: "+sg+" Date: "+dt.day+"."+dt.mon+"."+dt.year+" "+dt.hour+":"+dt.min+":"+dt.sec+"\n",_Symbol);
      StringAdd(output_string,temp_string);
      //Фильтр одной сделки в день
      bool stopBuyByFilterOneDay = false;
      if(GetLastOpenOrderDay(POSITION_TYPE_BUY) == DayMQL4() && oneOrderInDay==true)
      {
         Print("Condition 3. One trade per day filter is active.");
         stopBuyByFilterOneDay = true;
         temp_string=StringFormat("Only One Day Deals Filter Acive\n",_Symbol);
         StringAdd(output_string,temp_string);
      }

      //Фильтр быстрого движения
      if((int) TimeBuyDifference < waitFastMovement && waitFastMovement > 0 )
      {
         stopBuyByFilter = true;
         if(ShortLog)
         {
            Print("Stop By Fast Movement Filter. " + (int) TimeBuyDifference + " < " + (int) waitFastMovement);
         }
         temp_string=StringFormat("Stop By Fast Movement Filter. " + (int) TimeBuyDifference + " < " + (int) waitFastMovement+"\n",_Symbol);
         StringAdd(output_string,temp_string);
      }
      //Фильтр расстояния между сделками
      lastOpenPrice = minimumDistancePips > 0 ? GetPriceLastPositions(POSITION_TYPE_BUY) : 0; //если фильтр активен, рассчитаем дистанцию
      if(lastOpenPrice != 0 && minimumDistancePips > 0 && lastOpenPrice - mqlTick.ask < minimumDistancePipsPointed)  //если дитанция меньше и открытая сделка есть
      {
         stopBuyByFilter = true;
         if(ShortLog)
         {
            Print("Stop By Distance Filter. Current Distance:" + (string)(lastOpenPrice - mqlTick.ask) + " < " + (string) minimumDistancePipsPointed);
         }
         temp_string=StringFormat("Stop By Distance Filter. Current Distance:" + (string)(lastOpenPrice - mqlTick.ask) + " < " + (string) minimumDistancePipsPointed+"\n",_Symbol);
         StringAdd(output_string,temp_string);
      }
      //Фильтр максимального спреда
      if(SymbolInfoInteger(Symbol(),SYMBOL_SPREAD) > maxSpread)
      {
         stopBuyByFilter=true;
         if(ShortLog)
         {
            Print("Stop Buy Spread Filter. Now: ", SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
         }
         temp_string=StringFormat("Stop Buy Spread Filter. Now: "+ SymbolInfoInteger(Symbol(),SYMBOL_SPREAD)+"\n",_Symbol);
         StringAdd(output_string,temp_string);
      }
      //Считаем лосс по своему символу или по чужим тоже?
      if(separate == true)
      {
         lastTotalLoss = MathAbs(GetLossHistoryLastPositionsTotal(multicurrancyTP, 1)); // последняя серия убытков
         if(Log)
         {
            Print("BUY separate GetLossHistoryLastPositionsTotal(multicurrancyTP): "+lastTotalLoss);
         }
      }
      else
      {
         lastTotalLoss = MathAbs(GetLossHistoryLastPositionsTotal(multicurrancyTP, 0)); // последняя серия убытков
         if(Log)
         {
            Print("BUY GetLossHistoryLastPositionsTotal(multicurrancyTP): "+lastTotalLoss);
         }
      }
      //Режим режим рассчета тейкпрофита по предыдущему убытку
      if(lastLossBack && lastTotalLoss>0)  // убедимся что нет открытых позиций
      {
         tickPrice = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); // цена тика при объеме в 1 лот
         //для форекс
         if(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_CALC_MODE)==SYMBOL_CALC_MODE_FOREX)
         {
            losInpips = MathAbs(MathRound(lastTotalLoss / (userLot*10))); // расчет в пунктах последней серии убытков
            losInpips *= m_adjusted_point; // приведем тейкпрофит к значения 0.0040
            //Print("losInpips forex"+losInpips);
         }
         //для cfd
         if(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_CALC_MODE)==SYMBOL_CALC_MODE_CFD)
         {
            losInpips = MathAbs(MathRound(lastTotalLoss / (userLot*100))); // расчет в пунктах последней серии убытков
            losInpips *= m_adjusted_point /100; // приведем тейкпрофит к значения 0.0040
            //Print("losInpips CFD"+losInpips);
         }
         //для cfd-index
         if(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_CALC_MODE)==SYMBOL_CALC_MODE_CFDINDEX)
         {
            losInpips = MathAbs(MathRound(lastTotalLoss / (userLot*10))); // расчет в пунктах последней серии убытков
            losInpips *= m_adjusted_point ; // приведем тейкпрофит к значения 0.0040
            //Print("losInpips CFD-index"+losInpips);
         }
         // Если losInpips равен 0, то устанавливаем takeProfitPointed равным takeProfit, умноженному на значение m_adjusted_point, иначе устанавливаем takeProfitPointed равным losInpips, увеличенному на losInpips, умноженный на значение lastLossBackAddPercent, разделенное на 10.
         if(losInpips == 0)
            takeProfitPointed = takeProfit * m_adjusted_point;
         else
            takeProfitPointed = losInpips + (losInpips * lastLossBackAddPercent / 10);
         //Print("losInpips takeProfitPointed"+takeProfitPointed);
         if(Log)
         {
            Print("BUY losInpips: "+losInpips+" lastLossBackAddPercent: "+lastLossBackAddPercent+" Итог takeProfitPointed: "+takeProfitPointed);
         }
         if(losInpips != 0)
         {
            commentMm = "closeByTp";
         }
         if(Log)
         {
            Print("Тейкпрофит 1 по серии убытков активен. Суммарный убыток по последним позициям: "+(string)lastTotalLoss + " В пунктах "+(string)losInpips);
         }
         if(lastLossBackLot > 0 && losInpips > 0)
         {
            Lots = Lots * lastLossBackLot; // последняя серия убытков
            takeProfitPointed = takeProfitPointed / lastLossBackLot;
         }
      }
      if(Log)
      {
         Print("Хотим купить stopBuyByFilter "+stopBuyByFilter);
      }
      // Проверка на минимальные значения тейкпрофита
      double tpBuy;
      // Если (mqlTick.ask + takeProfitPointed) меньше minimalStopLevel, то присваиваем tpBuy значение (mqlTick.ask + takeProfitPointed) + minimalStopLevel, иначе присваиваем tpBuy значение mqlTick.ask + takeProfitPointed.
      if((mqlTick.ask + takeProfitPointed) < minimalStopLevel)
         tpBuy = (mqlTick.ask + takeProfitPointed) + minimalStopLevel;
      else
         tpBuy = mqlTick.ask + takeProfitPointed;
      tpBuy = tpBuy+stops_level;
      //Print("stops_level: "+stops_level);
      if(!stopBuyByFilter) //если фильтры пройдены
         if(trade.Buy(Lots, _Symbol, mqlTick.ask, mqlTick.bid - stopLossPointed, tpBuy, commentMm))
         {
            if(Log)
            {
               Print("Покупка по цене: ", trade.ResultPrice(), ", объем:", trade.ResultVolume(),
                     " была успешно выполнена, Ticket#:", trade.ResultDeal(), "!!");
            }
            temp_string=StringFormat("Buy by Price: "+ trade.ResultPrice()+ ", Lot:"+ trade.ResultVolume()+
                                     " success, Ticket#:"+ trade.ResultDeal()+ "!!"+"\n",_Symbol);
            StringAdd(output_string,temp_string);
            trade.PrintResult();
            restartSignalBuy = true;
            numberDealBars = Bars(Symbol(), Period()); // запоминаем номер бара для сброса сигнала по количеству баров
            openBarPriceBuy = iOpen(NULL,0,0);
         }
         else
         {
            if(ShortLog)
            {
               Print("Запрос на покупку объема:", trade.RequestVolume(), ", sl:", trade.RequestSL(),
                     ", tp:", trade.RequestTP(), ", по цене:", trade.RequestPrice(),
                     " не может быть выполнен -ошибка:", trade.ResultRetcodeDescription());
            }
            temp_string=StringFormat("Buy Request:"+ trade.RequestVolume()+ ", sl:"+ trade.RequestSL(),
                                     ", tp:"+ trade.RequestTP()+ ", by price :"+ trade.RequestPrice()+
                                     " can't be approve -error:"+ trade.ResultRetcodeDescription()+"\n",_Symbol);
            StringAdd(output_string,temp_string);
            trade.PrintRequest();
            return;
         }
   }
//Условия на продажу
   signal_deviation_mod = signal_deviation_pointed;
   if(autodeviation == true)
   {
      signal_deviation_mod = deviationAverageHigh;
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!CheckMoneyForTrade(_Symbol,Lots,ORDER_TYPE_SELL))
   {
      if(ShortLog)
      {
         Print("Not enough money");
      }
      temp_string=StringFormat("Not enough money\n",_Symbol);
      StringAdd(output_string,temp_string);
      noMoney = true;
   }


   bool checksSwapSell = false;
   if(onlySwapPlus == true && SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG) > SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT))
   {
      if(Log)
      {
         Print("Условие 6. Своп на продажу больше чем на покупку. " + (string) SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG));
      }
      checksSwapSell = true;
   }
   if(mqlTick.bid - ind_date.MA_CHART[barNOpen] >= signal_deviation_mod && !restartSignalSell && onlybuyfilter==false && checksSwapSell==false && tradeAllowed==true && noMoney==false)
   {
      if(ShortLog)
      {
         Print("Have a Sell Signal: "+_Symbol+" deviation: "+d+" signal point: "+sg+" Date: "+dt.day+"."+dt.mon+"."+dt.year+" "+dt.hour+":"+dt.min+":"+dt.sec+"\n");
      }
      temp_string=StringFormat("Have a Sell Signal: "+_Symbol+" deviation: "+d+" signal point: "+sg+" Date: "+dt.day+"."+dt.mon+"."+dt.year+" "+dt.hour+":"+dt.min+":"+dt.sec+"\n",_Symbol);
      StringAdd(output_string,temp_string);
      //Фильтр одной сделки в день
      if(GetLastOpenOrderDay(POSITION_TYPE_SELL) == DayMQL4() && oneOrderInDay)
      {
         temp_string=StringFormat("Only One Day Deals Filter Acive\n",_Symbol);
         StringAdd(output_string,temp_string);
         stopSellByFilter = true;
      }
      //Фильтр быстрого движения
      if((int) TimeSellDifference < waitFastMovement && waitFastMovement > 0)
      {
         if(ShortLog)
         {
            Print("Stop By Fast Movement Filter. " + (int) TimeSellDifference + " < " + (int) waitFastMovement);
         }
         temp_string=StringFormat("Stop By Fast Movement Filter. " + (int) TimeSellDifference + " < " + (int) waitFastMovement+"\n",_Symbol);
         StringAdd(output_string,temp_string);
         stopSellByFilter = true;
      }
      //Фильтр расстояния между сделками
      lastOpenPrice = minimumDistancePips > 0 ? GetPriceLastPositions(POSITION_TYPE_SELL) : 0; //если фильтр активен, рассчитаем дистанцию
      if(lastOpenPrice != 0 && minimumDistancePips > 0 && mqlTick.bid - lastOpenPrice < minimumDistancePipsPointed)  //если дитанция меньше и открытая сделка есть
      {
         stopSellByFilter = true;
         if(ShortLog)
         {
            Print("Stop By Distance Filter. Current Distance:" + (string)(lastOpenPrice - mqlTick.bid) + " < " + (string) minimumDistancePipsPointed);
         }
         temp_string=StringFormat("Stop By Distance Filter. Current Distance:" + (string)(lastOpenPrice - mqlTick.bid) + " < " + (string) minimumDistancePipsPointed+"\n",_Symbol);
         StringAdd(output_string,temp_string);
      }
      //Фильтр максимального спреда
      if(SymbolInfoInteger(Symbol(),SYMBOL_SPREAD) > maxSpread)
      {
         if(ShortLog)
         {
            Print("Stop Buy Spread Filter. Now: ", SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
         }
         temp_string=StringFormat("Stop Buy Spread Filter. Now: "+ SymbolInfoInteger(Symbol(),SYMBOL_SPREAD)+"\n",_Symbol);
         StringAdd(output_string,temp_string);
         stopSellByFilter=true;
      }
      if(separate == true)
      {
         lastTotalLoss = MathAbs(GetLossHistoryLastPositionsTotal(multicurrancyTP,-1));  // последняя серия убытков
         if(Log)
         {
            Print("SELL separate GetLossHistoryLastPositionsTotal(multicurrancyTP): "+lastTotalLoss);
         }
      }
      else
      {
         lastTotalLoss = MathAbs(GetLossHistoryLastPositionsTotal(multicurrancyTP,0));  // последняя серия убытков
         if(Log)
         {
            Print("SELL GetLossHistoryLastPositionsTotal(multicurrancyTP): "+lastTotalLoss);
         }
      }
      //Режим режим рассчета тейкпрофита по предыдущему убытку
      if(lastLossBack && lastTotalLoss>0)  // убедимся что нет открытых позиций
      {
         tickPrice = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); // цена тика при объеме в 1 лот
         //для форекс
         if(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_CALC_MODE)==SYMBOL_CALC_MODE_FOREX)
         {
            losInpips = MathAbs(MathRound(lastTotalLoss / (userLot*10))); // расчет в пунктах последней серии убытков
            losInpips *= m_adjusted_point; // приведем тейкпрофит к значения 0.0040
         }
         //для cfd
         if(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_CALC_MODE)==SYMBOL_CALC_MODE_CFD)
         {
            losInpips = MathAbs(MathRound(lastTotalLoss / (userLot*100))); // расчет в пунктах последней серии убытков
            losInpips *= m_adjusted_point /100; // приведем тейкпрофит к значения 0.0040
         }
         //для cfd-index
         if(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_CALC_MODE)==SYMBOL_CALC_MODE_CFDINDEX)
         {
            losInpips = MathAbs(MathRound(lastTotalLoss / (userLot*10))); // расчет в пунктах последней серии убытков
            losInpips *= m_adjusted_point ; // приведем тейкпрофит к значения 0.0040
         }
         // Если losInpips равен 0, то устанавливаем takeProfitPointed равным takeProfit * m_adjusted_point, иначе устанавливаем takeProfitPointed равным losInpips + (losInpips * lastLossBackAddPercent / 10).
         if(losInpips == 0)
            takeProfitPointed = takeProfit * m_adjusted_point;
         else
            takeProfitPointed = losInpips + (losInpips * lastLossBackAddPercent / 10);
         if(Log)
         {
            Print("SELL losInpips: "+losInpips+" lastLossBackAddPercent: "+lastLossBackAddPercent+" Итог takeProfitPointed: "+takeProfitPointed);
         }
         if(Log)
         {
            Print("Тейкпрофит по серии убытков активен. Суммарный убыток по последним позициям: "+(string)lastTotalLoss + " В пунктах "+(string)losInpips);
         }
         if(losInpips != 0)
         {
            commentMm = "closeByTp";
         }
         if(lastLossBackLot > 0 && losInpips > 0)
         {
            Lots = Lots * lastLossBackLot; // последняя серия убытков
            takeProfitPointed = takeProfitPointed / lastLossBackLot;
         }
      }
      // Проверка на минимальные значения тейкпрофита
      double tpSell;
      if((mqlTick.bid - takeProfitPointed) < minimalStopLevel)
         tpSell = (mqlTick.bid - takeProfitPointed) - minimalStopLevel;
      else
         tpSell = mqlTick.bid - takeProfitPointed;
      tpSell = tpSell - stops_level;
      //Print("stops_level: "+stops_level);
      if(!stopSellByFilter)
         if(trade.Sell(Lots, _Symbol, mqlTick.bid, mqlTick.ask + stopLossPointed, tpSell, commentMm))
         {
            if(Log)
            {
               Print("Продажа по цене: ", trade.ResultPrice(), ", объем:", trade.ResultVolume(),
                     " была успешно выполнена, Ticket#:", trade.ResultDeal(), "!!");
            }
            temp_string=StringFormat("Sell by Price: "+ trade.ResultPrice()+ ", Lot:"+ trade.ResultVolume()+
                                     " success, Ticket#:"+ trade.ResultDeal()+ "!!"+"\n",_Symbol);
            StringAdd(output_string,temp_string);
            trade.PrintResult();
            restartSignalSell = true;
            numberDealBars = Bars(Symbol(), Period()); // запоминаем номер бара для сброса сигнала по количеству баров
            openBarPriceSell = iOpen(NULL,0,0);
         }
         else
         {
            if(Log)
            {
               Print("Запрос на продажу объема:", trade.RequestVolume(), ", sl:", trade.RequestSL(),
                     ", tp:", trade.RequestTP(), ", по цене:", trade.RequestPrice(),
                     " не может быть выполнен -ошибка:", trade.ResultRetcodeDescription());
            }
            temp_string=StringFormat("Buy Request:"+ trade.RequestVolume()+ ", sl:"+ trade.RequestSL(),
                                     ", tp:"+ trade.RequestTP()+ ", by price :"+ trade.RequestPrice()+
                                     " can't be approve -error:"+ trade.ResultRetcodeDescription()+"\n",_Symbol);
            StringAdd(output_string,temp_string);
            trade.PrintRequest();
            return;
         }
   }
   bool reverse = false;
   if((mqlTick.bid >= ind_date.MA_CHART[barNClose] && closeByHighLow ==0) /*|| (mqlTick.bid >= openBarPriceBuy && numberDealBars == Bars(Symbol(), Period()) )*//*(mqlTick.bid - ind_date.MA_CHART[0]) > closeByHighLow*/)
      CloseLastPositionsWithConditionSkip(POSITION_TYPE_BUY, commentMm);
   if((mqlTick.bid <= ind_date.MA_CHART[barNClose] && closeByHighLow ==0) /*|| (mqlTick.bid <= openBarPriceSell && numberDealBars == Bars(Symbol(), Period())  )*/ /*(ind_date.MA_CHART[0] - mqlTick.bid ) > closeByHighLow */)
      CloseLastPositionsWithConditionSkip(POSITION_TYPE_SELL, commentMm);
   Comment(output_string);
}



// Размер свободных средств, необходимых для открытия 1 лота на покупку

double GetMarginRequired(const string Symb)

{
   MqlTick Tick;
   double MarginInit, MarginMain;
   return ((SymbolInfoTick(Symb, Tick) && SymbolInfoMarginRate(Symb, ORDER_TYPE_BUY, MarginInit, MarginMain)) ? MarginInit * Tick.ask *
           SymbolInfoDouble(Symb, SYMBOL_TRADE_TICK_VALUE) / (SymbolInfoDouble(Symb, SYMBOL_TRADE_TICK_SIZE) * AccountInfoInteger(ACCOUNT_LEVERAGE)) : 0);
}

//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

double lots()

{
   lotstep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   lotmax = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   lotmin = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   userMargin = GetMarginRequired(Symbol());
   double uLot = lotstep * MathRound((AccountInfoDouble(ACCOUNT_FREEMARGIN) * risk / userMargin) / lotstep);
   if(uLot < lotmin)
      uLot = lotmin;
   if(uLot > lotmax)
      uLot = lotmax;
   return (uLot);
}



//+------------------------------------------------------------------+

//| Возвращяет день месяца

//+------------------------------------------------------------------+

int DayMQL4()

{
   MqlDateTime tm;
   TimeCurrent(tm);
   return (tm.day);
}



//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

void PosModify()

{
   int posTotal = PositionsTotal();
   if(posTotal > 0)
   {
      for(int i = 0; i < posTotal; i++)
      {
         ulong posTicket = PositionGetTicket(i);
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         double posOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         double posTP = PositionGetDouble(POSITION_TP);
         double posSL = PositionGetDouble(POSITION_SL);
         datetime time_diff = TimeCurrent() - (datetime) PositionGetInteger(POSITION_TIME);
         //  Print("PositionGetInteger(POSITION_TIME: "+PositionGetInteger(POSITION_TIME)+" TimeCurrent(): "+TimeCurrent()+" diff "+time_diff);
         if(time_diff > inpLiveOrder)  //если разница между временем открытия и текущим временем больше inpLiveOrder закрываем сделку
         {
            m_position.SelectByIndex(i);
            trade.PositionClose(posTicket);
         }
      }
   }
}

//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

double CheckContractVolume(double volume)

{
   double v = volume;
   double volumeStep = 0;
   volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int ratio = (int) floor(volume / volumeStep);
   if(fabs(ratio * volumeStep - volume) > 0.0000001)
      v = ratio * volumeStep;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   return ((v < minLot ? minLot : v > maxLot ? maxLot : v));
}

//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

double RiskLots(double uRisk, int SL)

{
   double RiskMony, Lot;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double FreeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   long accountLeverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   RiskMony = floor(FreeMargin * uRisk / 100);
   Lot = CheckContractVolume(RiskMony * m_adjusted_point / NormalizeDouble((SL * m_adjusted_point * tickValue), _Digits));
   return (Lot);
}

//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

void OnDeinit(const int reason)

{
   Comment("");
}

//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

bool newBar(ENUM_TIMEFRAMES tf)

{
   datetime currTime = iTime(_Symbol, tf, 0);
   static datetime timeLastBar;
   bool ret = timeLastBar != currTime;
   if(ret)
      timeLastBar = currTime;
   return (ret);
}

//+------------------------------------------------------------------+



//+------------------------------------------------------------------+

//| Position select depending on netting or hedging                  |

//+------------------------------------------------------------------+

bool SelectPosition()

{
   bool res = false;
//--- check position in Hedging mode
   uint total = PositionsTotal();
   for(uint i = 0; i < total; i++)
   {
      string position_symbol = PositionGetSymbol(i);
      if((_Symbol == position_symbol || multicurrancyMode) && _Magic == PositionGetInteger(POSITION_MAGIC))
      {
         res = true;
         break;
      }
   }
   return (res);
}



//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

void CloseAllPositions(int POSITION_TYPE)

{
   for(int i = PositionsTotal() - 1; i >= 0; i--)  // returns the number of current positions
      if(m_position.SelectByIndex(i))  // selects the position by index for further access to its properties
         if(m_position.Symbol() == _Symbol && m_position.Magic() == _Magic)
         {
            if(m_position.PositionType() == POSITION_TYPE)
               trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
         }
}



//+------------------------------------------------------------------+

//| Profit all positions                                             |

//+------------------------------------------------------------------+

double ProfitAllPositions(int POSITION_TYPE)

{
   double profit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(m_position.SelectByIndex(i))  // selects the position by index for further access to its properties
         if(m_position.Symbol() == _Symbol && m_position.Magic() == _Magic && m_position.PositionType() == POSITION_TYPE)
            profit += m_position.Commission() + m_position.Swap() + m_position.Profit();
//---
   return (profit);
}

//+------------------------------------------------------------------+



//|  Получим сумму последних отрицательных позиции в истории         |

//+------------------------------------------------------------------+

double GetLossHistoryLastPositionsTotal(bool multCurr=false, int pos_type = 0)

{
   uint ticketSaved = 0;
   double LossSaved = 0;
   datetime startDate = 0;
   ENUM_DEAL_TYPE type;
   ENUM_POSITION_TYPE type_pos;
   if(pos_type==1)
   {
      type=DEAL_TYPE_SELL;
      type_pos=POSITION_TYPE_SELL;
   }
   if(pos_type== -1)
   {
      type=DEAL_TYPE_BUY;
      type_pos=POSITION_TYPE_BUY;
   }
   /*
      Print("CheckOpenPositions()");
      if(CheckOpenPositions(multicurrancyMode) > 0 )
        {Print("CheckOpenPositions() зашли");
         startDate = GetDateLastPositions(multicurrancyMode,type); // начальная граница установлена на 1970 год
         Print("Начальная дата из рассчета GetDateLastPositions: "+ TimeToString(startDate, TIME_DATE|TIME_MINUTES|TIME_SECONDS));
        }
   */
   if(CountPositions(pos_type) <= 0)
   {
      //Print("нет открытой позы, смотрим лосс");
      startDate = GetDateLastPositions(multicurrancyMode,type); // начальная граница установлена на 1970 год
      //Print("Начальная дата из рассчета GetDateLastPositions: "+ TimeToString(startDate, TIME_DATE|TIME_MINUTES|TIME_SECONDS));
   }
   else
   {
      startDate = GetDateLastOpenPositions(multicurrancyMode,type_pos); // начальная граница установлена на 1970 год
      //Print("есть открытая поза, то смотрим есть ли минуса с момента открытия последней сделки startDate "+startDate);

      //return (LossSaved);
   }
//Print("CheckOpenPositions(multicurrancyMode): "+CheckOpenPositions(multicurrancyMode));
   datetime end = TimeCurrent(); // конечная граница установлена на текущее серверное время
//--- запросим в кэш программы всю торговую историю
   bool result = HistorySelect(startDate, end);
   if(result==false)
   {
      Print("Problem HistorySelect");
   }
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)  // По всем сделкам от конца к началу
   {
      ulong ticket = HistoryDealGetTicket(i); // Определение тикета сделки и ее выделение
      //продажи
      if(pos_type == 1)
      {
         if(ticket != 0 && HistoryDealGetDouble(ticket, DEAL_PROFIT) > 0 && HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_SELL))     // Выходим если последняя сделка в профите
         {
            //Print("Last BUY Profit  > 0 exit : Tiket "+ticket+" "+ HistoryDealGetDouble(ticket, DEAL_PROFIT));
            break;
         }
         if(ticket != 0 && HistoryDealGetDouble(ticket, DEAL_PROFIT)  < 0 && (HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol) && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_SELL))
         {
            // Print("Выбрали только продажи");
            LossSaved += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            //Print("Found BUY Loss :  Tiket "+ticket+" "+LossSaved);
         }
      }
      //покупки
      if(pos_type == -1)
      {
         if(ticket != 0 && HistoryDealGetDouble(ticket, DEAL_PROFIT) > 0 && HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY))     // Выходим если последняя сделка в профите
         {
            //Print("Last SELL Profit > 0 exit Tiket "+ticket+" "+ HistoryDealGetDouble(ticket, DEAL_PROFIT));
            break;
         }
         if(ticket != 0 && HistoryDealGetDouble(ticket, DEAL_PROFIT)  < 0 && (HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol) && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY))
         {
            //Print("Выбрали только покупки");
            LossSaved += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            //Print("Found SELL Loss :  Tiket "+ticket+" "+LossSaved);
         }
      }
      //работа в режиме счета предыдущих убытков без зависимости от типа позиции
      if(pos_type == 0)
      {
         if(ticket != 0 && HistoryDealGetDouble(ticket, DEAL_PROFIT) > 0 && HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)    // Выходим если последняя сделка в профите
         {
            //Print("Last Order Profit > 0 exit Tiket "+ticket+" "+ HistoryDealGetDouble(ticket, DEAL_PROFIT));
            break;
         }
         if(ticket != 0 && HistoryDealGetDouble(ticket, DEAL_PROFIT)  < 0 && (HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol))
         {
            //Print("Выбрали только покупки");
            LossSaved += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            //Print("Found Order Loss :  Tiket "+ticket+" "+LossSaved);
            break;
         }
      }
   } //for
   return (LossSaved);
} // func



//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

int GetLastOpenOrderDay(int POSITION_TYPE)

{
   datetime day = 0;
   int ticketSaved = 0;
   for(int i = 0; i <= PositionsTotal() - 1; i++)
      if(m_position.SelectByIndex(i))  // selects the position by index for further access to its properties
         if(m_position.Symbol() == _Symbol && m_position.Magic() == _Magic && m_position.PositionType() == POSITION_TYPE && ((int) m_position.Ticket() > ticketSaved))
         {
            ticketSaved = (int) m_position.Ticket();
            day = m_position.Time();
         }
   TimeToStruct(day, dt);
//---
   return (dt.day);
}



//| Last Count Profit positions                                             |

//+------------------------------------------------------------------+

double ProfitLastPositions(int POSITION_TYPE)

{
   double profit = 0.0;
   for(int i = 0; i <= PositionsTotal() - 1; i++)
      if(m_position.SelectByIndex(i))  // selects the position by index for further access to its properties
         if(m_position.Symbol() == _Symbol && m_position.Magic() == _Magic && m_position.PositionType() == POSITION_TYPE)
            profit = m_position.Commission() + m_position.Swap() + m_position.Profit();
//---
   return (profit);
}



//|  Получим количество открытых позиций                             |

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckOpenPositions(bool multCurrancyMode=false)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(m_position.SelectByIndex(i))  // selects the position by index for further access to its properties
         if((m_position.Symbol() == _Symbol || multCurrancyMode) && m_position.Magic() == _Magic)
            return (true);
   return (false);
}



//|  Count positions                                             |

//+------------------------------------------------------------------+

int CountPositions(int pos_type)

{
   //Print("Вошли CountPositions");
   ENUM_POSITION_TYPE type;
   if(pos_type==0)
   {
      type=POSITION_TYPE_SELL;
   }
   if(pos_type== 1)
   {
      type=POSITION_TYPE_BUY;
   }
   int count = 0;
   for(int i = PositionsTotal(); i >= 0; i--)
   {
      //Print("Вошли for PositionsTotal() "+PositionsTotal());
      if(m_position.SelectByIndex(i))  // selects the position by index for further access to its properties
      {
         //Print("m_position.PositionType() "+m_position.PositionType()+" type "+type);
         if(m_position.Symbol() == _Symbol && m_position.Magic() == _Magic && m_position.PositionType() == type)
         {
            count += 1;
         }
      }
   }
   return (count);
}



//|  Получим дату последней открытой позиции                         |
//+------------------------------------------------------------------+

datetime GetDateLastOpenPositions(bool multCurrancyMode = false, ENUM_POSITION_TYPE ordertype =0)
  {
  
  int changeOrderType = 0;
  if (ordertype ==1){changeOrderType =0;};
  if (ordertype ==0){changeOrderType =1;};
  
   uint ticketSaved = 0;
   datetime lastOpenDate = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)  // количество открытых позиций
     {//Print( "GetDateLastOpenPositions for");
      if(m_position.SelectByIndex(i))  // выбираем позицию по id для получения настроек
        {//Print( "GetDateLastOpenPositions select ordertype "+changeOrderType+" m_position.PositionType() "+m_position.PositionType());
         if(m_position.PositionType() == changeOrderType && (m_position.Symbol() == _Symbol || multCurrancyMode) && m_position.Magic() == _Magic)  // если позиция принадлежит текущему инструменту и этому советнику
           {
            if(m_position.Ticket() > ticketSaved)  // и тикет больше сохраненного тикета
              {
               ticketSaved = (int) m_position.Ticket(); // сохраняем наибольший тикет
               lastOpenDate = m_position.Time();
              } // if
           } // if
        } // if
     } // for
   return (lastOpenDate);
  } // func


// | Получим время первой положительной сделки |
// +--------------------------------------------+
datetime GetDateLastPositions(bool multCurrancyMode = false, ENUM_DEAL_TYPE ordertype = 0)
{
   //Print("GetDateLastPositions зашли");
   datetime lastOpenDate = 0;
   uint ticketSaved = 0;
   for(int i = HistoryOrdersTotal() - 1; i >= 0; i--)  // просматриваем сделки с конца
   {
      //Print("GetDateLastPositions в цикл");
      if(m_history.SelectByIndex(i))  // выбираем позицию по id для получения настроек
      {
         //Print("GetDateLastPositions OrderType "+m_history.DealType()+" m_history.Ticket() "+m_history.Ticket()+" ordertype "+ordertype);
         if(m_history.DealType() == ordertype && (m_history.Symbol() == _Symbol /*|| multCurrancyMode*/) && m_history.Magic() == _Magic)  // если позиция принадлежит текущему инструменту и этому советнику
         {
            if(m_history.Profit() >= 0)  // проверяем, что прибыль положительная
            {
               ticketSaved = (int) m_history.Ticket(); // сохраняем наибольший тикет
               lastOpenDate =  m_history.Time(); // возвращаем время первой положительной сделки.
               //Print("Found TIme Profit first "+ticketSaved+" time "+lastOpenDate);
               break;
            }
         }
      }
   }
   return lastOpenDate;
}




//|  Получим цену последней открытой позиции                         |

//+------------------------------------------------------------------+

double GetPriceLastPositions(int POSITION_TYPE)

{
   uint ticketSaved = 0;
   double lastOpenPrice = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)  // количество открытых позиций
   {
      if(m_position.SelectByIndex(i))  // выбираем позицию по id для получения настроек
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == _Magic)  // если позиция принадлежит текущему инструменту и этому советнику
         {
            if(m_position.PositionType() == POSITION_TYPE  // если тип позиции заданный
                  &&
                  m_position.Ticket() > ticketSaved) // и тикет больше сохраненного тикета
            {
               ticketSaved = (int) m_position.Ticket(); // сохраняем наибольший тикет
               lastOpenPrice = m_position.PriceOpen();
            } // if
         } // if
      } // if
   } // for
   return (lastOpenPrice);
} // func



//+------------------------------------------------------------------+

//|                                                                  |

//+------------------------------------------------------------------+

void CloseLastPositionsWithConditionSkip(int POSITION_TYPE, string commentSkip = "")

{
   uint ticket = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)  // returns the number of current positions
   {
      if(m_position.SelectByIndex(i))  // selects the position by index for further access to its properties
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == _Magic)
         {
            if(m_position.PositionType() == POSITION_TYPE && ticket < m_position.Ticket() && m_position.Comment() != "closeByTp")
            {
               ticket = (int) m_position.Ticket();
            }
         }
      }
   }
//  Print("Попытка закрыть сделку "+ticket);
   if(ticket > 0)
   {
      if(SymbolInfoInteger(Symbol(),SYMBOL_SPREAD) < maxSpread)
      {
         m_position.SelectByTicket(ticket);
         trade.PositionClose(ticket); // close a position by the specified symbol
      }
      else
      {
         if(ShortLog)
         {
            //Print("Can't close, spread too mutch, Now: "+SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
         }
         temp_string=StringFormat("Can't close, spread too mutch. Now: "+ SymbolInfoInteger(Symbol(),SYMBOL_SPREAD)+"\n",_Symbol);
         StringAdd(output_string,temp_string);
      }
   }
}


//+------------------------------------------------------------------+

//| возвращает true если появился новый бар, иначе false             |

//+------------------------------------------------------------------+

bool isNewBar(ENUM_TIMEFRAMES timeFrame)

{
//----
   static datetime old_Times[21]; // массив для хранения старых значений
   bool res = false; // переменная результата анализа
   int i = 0; // номер ячейки массива old_Times[]
   datetime new_Time[1]; // время нового бара
   switch(timeFrame)
   {
   case PERIOD_M1:
      i = 0;
      break;
   case PERIOD_M2:
      i = 1;
      break;
   case PERIOD_M3:
      i = 2;
      break;
   case PERIOD_M4:
      i = 3;
      break;
   case PERIOD_M5:
      i = 4;
      break;
   case PERIOD_M6:
      i = 5;
      break;
   case PERIOD_M10:
      i = 6;
      break;
   case PERIOD_M12:
      i = 7;
      break;
   case PERIOD_M15:
      i = 8;
      break;
   case PERIOD_M20:
      i = 9;
      break;
   case PERIOD_M30:
      i = 10;
      break;
   case PERIOD_H1:
      i = 11;
      break;
   case PERIOD_H2:
      i = 12;
      break;
   case PERIOD_H3:
      i = 13;
      break;
   case PERIOD_H4:
      i = 14;
      break;
   case PERIOD_H6:
      i = 15;
      break;
   case PERIOD_H8:
      i = 16;
      break;
   case PERIOD_H12:
      i = 17;
      break;
   case PERIOD_D1:
      i = 18;
      break;
   case PERIOD_W1:
      i = 19;
      break;
   case PERIOD_MN1:
      i = 20;
      break;
   }
// скопируем время последнего бара в ячейку new_Time[0]
   int copied = CopyTime(_Symbol, timeFrame, 0, 1, new_Time);
   if(copied > 0)  // все ок. данные скопированы
   {
      if(old_Times[i] != new_Time[0])  // если старое время бара не равно новому
      {
         if(old_Times[i] != 0)
            res = true; // если это не первый запуск, то истина = новый бар
         old_Times[i] = new_Time[0]; // запоминаем время бара
      }
   }
//----
   return (res);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+



bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)

{
//--- получим цену открытия
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- значения необходимой и свободной маржи
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//--- вызовем функцию проверки
   if(!OrderCalcMargin(type,symb,lots,price,margin))
   {
      //--- что-то пошло не так, сообщим и вернем false
      //Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
   }
//--- если не хватает средств на проведение операции
   if(margin>free_margin)
   {
      //--- сообщим об ошибке и вернем false
     // Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
   }
//--- проверка прошла успешно
   return(true);
}
//+------------------------------------------------------------------+
