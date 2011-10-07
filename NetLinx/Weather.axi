(*
 * The include file provides functionaliy that is common across all weather sources. 
 * It should be included after certain variables have been declared.
 *)

#include 'TouchPanel.axi'
#include 'TouchPanelPorts.axi'

DEFINE_CONSTANT

// These channel ports are sent text strings and can be used in Touch Panel screens
char WEATHER_CHAN_CURR_TEMP_F[]		= '11'
char WEATHER_CHAN_CURR_TEMP_C[]		= '12'
char WEATHER_CHAN_FEELS_LIKE_F[]	= '13'
char WEATHER_CHAN_FEELS_LIKE_C[]	= '14'
char WEATHER_CHAN_CURR_COND[]		= '15'
char WEATHER_CHAN_CURR_COND_STR[]	= '16'
char WEATHER_CHAN_CURR_COND_ICON[]	= '17'
char WEATHER_CHAN_OBS_LOCATION[]	= '21'
char WEATHER_CHAN_OBS_LATITUDE[]	= '22'
char WEATHER_CHAN_OBS_LONGITUDE[]	= '23'
char WEATHER_CHAN_OBS_ELEVATION[]	= '24'
char WEATHER_CHAN_OBS_TIME_LONG_STR[]	= '25'
char WEATHER_CHAN_REL_HUMIDITY[]	= '26'
char WEATHER_CHAN_WIND_STR[]		= '27'
char WEATHER_CHAN_WIND_DIR[]		= '28'
char WEATHER_CHAN_WIND_DEGREES[]	= '29'
char WEATHER_CHAN_WIND_MPH[]		= '30'
char WEATHER_CHAN_WIND_GUST_MPH[]	= '31'

char WEATHER_CHAN_SUNRISE[]		= '51'
char WEATHER_CHAN_SUNSET[]		= '52'

char MAX_FORECAST_PERIODS = 9

DEFINE_VARIABLE

volatile char WEATHER_CHAN_FORECAST_FULL_TITLE	[MAX_FORECAST_PERIODS][3] =
	 { '111','121','131','141','151','161','171','181','191' }
volatile char WEATHER_CHAN_FORECAST_FULL_DATE	[MAX_FORECAST_PERIODS][3] =
	 { '112','122','132','142','152','162','172','182','192' }
volatile char WEATHER_CHAN_FORECAST_FULL_TEXT	[MAX_FORECAST_PERIODS][3] =
	 { '113','123','133','143','153','163','173','183','193' }
volatile char WEATHER_CHAN_FORECAST_FULL_COND	[MAX_FORECAST_PERIODS][3] =
	 { '117','127','137','147','157','167','177','187','197' }
volatile char WEATHER_CHAN_FORECAST_FULL_ICON	[MAX_FORECAST_PERIODS][3] =
	 { '118','128','138','148','158','168','178','188','198' }

volatile char WEATHER_CHAN_FORECAST_SIMPLE_TITLE [MAX_FORECAST_PERIODS][3] =
	 { '311','321','331','341','351','361','371','381','391' }
volatile char WEATHER_CHAN_FORECAST_SIMPLE_DATE	[MAX_FORECAST_PERIODS][3] =
	 { '312','322','332','342','352','362','372','382','392' }
volatile char WEATHER_CHAN_FORECAST_HIGH_F	[MAX_FORECAST_PERIODS][3] =
	 { '313','323','333','343','353','363','373','383','393' }
volatile char WEATHER_CHAN_FORECAST_HIGH_C	[MAX_FORECAST_PERIODS][3] =
	 { '314','324','334','344','354','364','374','384','394' }
volatile char WEATHER_CHAN_FORECAST_LOW_F	[MAX_FORECAST_PERIODS][3] =
	 { '315','325','335','345','355','365','375','385','395' }
volatile char WEATHER_CHAN_FORECAST_LOW_C	[MAX_FORECAST_PERIODS][3] =
	 { '316','326','336','346','356','366','376','386','396' }
volatile char WEATHER_CHAN_FORECAST_SIMPLE_COND	[MAX_FORECAST_PERIODS][3] =
	 { '317','327','337','347','357','367','377','387','397' }
volatile char WEATHER_CHAN_FORECAST_SIMPLE_ICON	[MAX_FORECAST_PERIODS][3] =
	 { '318','328','338','348','358','368','378','388','398' }

volatile integer	gInitialized = 0
volatile dev		dvTp[TP_MAX_PANELS]
volatile integer 	gTpStatus[TP_MAX_PANELS]

DEFINE_TYPE

STRUCTURE ForecastPeriodFull
{
    char     mTitle[32]
    integer  mDay
    integer  mMonth
    integer  mYear
    char     mText[500]
    char     mCond[32]
    char     mCondIcon[20]
}

STRUCTURE ForecastPeriodSimple
{
    char     mTitle[32]
    integer  mDay
    integer  mMonth
    integer  mYear
    sinteger mHighF
    sinteger mHighC
    sinteger mLowF
    sinteger mLowC
    char     mHighFStr[8]
    char     mHighCStr[8]
    char     mLowFStr[8]
    char     mLowCStr[8]
    char     mCond[32]
    char     mCondIcon[20]
}

DEFINE_VARIABLE

volatile char		gObserveLocation[50]
volatile char		gObserveLatitudeStr[12]
volatile char		gObserveLongitudeStr[12]
volatile char		gObserveElevationStr[8]
volatile char		gObserveTimeLongStr[50]
volatile char		gCurrTempFStr[8]
volatile char		gCurrTempCStr[8]
volatile char		gFeelsLikeFStr[8]
volatile char		gFeelsLikeCStr[8]
volatile float		gCurrTempF
volatile float		gCurrTempC
volatile sinteger	gFeelsLikeF
volatile sinteger	gFeelsLikeC
volatile char		gRelHumidityStr[3]
volatile integer	gRelHumidity
volatile char		gWindStr[32]
volatile char		gWindDir[12]
volatile char		gWindDegreesStr[12]
volatile integer	gWindDegrees
volatile char		gWindMphStr[12]
volatile float		gWindMph
volatile char		gWindGustMphStr[12]
volatile float		gWindGustMph
volatile char		gDewPointFStr[5]
volatile char		gDewPointCStr[5]
volatile float		gDewPointF
volatile float		gDewPointC

volatile char gRequestTime[8]
volatile char gForecastTime[24]
volatile char gSunrise[8]
volatile char gSunset[8]
volatile char gCurrCond[32]
volatile char gCurrCondIcon[20]
volatile char gWind[10]
volatile char gHumidity[4]
volatile char gVisibility[5]
volatile ForecastPeriodFull   gForecastFull[MAX_FORECAST_PERIODS]
volatile ForecastPeriodSimple gForecastSimple[MAX_FORECAST_PERIODS]


DEFINE_CONSTANT
crlf[2] = {$0D,$0A}

DEFINE_EVENT
DATA_EVENT[dvLocalTcp]
{
    ONLINE: { handleConnect() }
    STRING: 
    {
	wait 20 // let the buffer receive the complete message
	{
	    if (handleReply(gBuf))
	    {
	    	clear_buffer gBuf
	    }
	}
    }
    OFFLINE: { handleDisconnect() }
    ONERROR: { debug (DBG_MODULE, 1, "'dvLocalTcp status code: ',itoa(data.number)") }
}

DEFINE_FUNCTION connect()
{
    debug (DBG_MODULE, 2, 'Opening connection')
    ip_client_open (dvLocalTcp.port, weatherServer, weatherPort, IP_TCP)
}

DEFINE_FUNCTION disconnect()
{
    debug (DBG_MODULE, 2, 'Closing connection')
    ip_client_close(dvLocalTcp.port)
}

DEFINE_FUNCTION sendRequest(char req[])
{
    debug (DBG_MODULE, 1, "'Sending request: GET ',req,' HTTP/1.0',crlf,'Host: ',weatherServer")
    send_string dvLocalTcp,"'GET ',req,' HTTP/1.0',crlf,'Host: ',weatherServer,crlf,crlf"
}

DEFINE_FUNCTION integer getStringField (char result[], char msg[], char tag[])
{
//debug (DBG_MODULE,9,"'foo1: ',msg")
    remove_string (msg,"'<',tag,'>'",1)
    result = left_string (msg, find_string(msg,"'</',tag,'>'",1)-1)
    remove_string (msg,"'</',tag,'>'",1)
    debug(DBG_MODULE,9,"'got field: ',tag,'=',result")
    return length_array(result)
}

DEFINE_FUNCTION sendField (char addressPort[], char value[], integer checkColor)
{
    local_var char cmdStr[600]
    integer i
    cmdStr = "'TEXT',addressPort,'-',value"
    sendCommand (dvStatus, cmdStr)
    for (i = 1; i <= TP_COUNT; i++)
    {
	if (gTpStatus[i])
	{
	    sendCommand (dvTp[i], cmdStr)
	}
    }
}

DEFINE_FUNCTION sendAppendField (char addressPort[], char value[])
{
    local_var char cmdStr[600]
    integer i
    cmdStr = "'^BAT-',addressPort,',0,',value"
    sendCommand (dvStatus, cmdStr)
    for (i = 1; i <= TP_COUNT; i++)
    {
	if (gTpStatus[i])
	{
	    sendCommand (dvTp[i], cmdStr)
	}
    }
}

DEFINE_FUNCTION sendIconField (char addressPort[], char value[])
{
    local_var char cmdStr[100]
    integer i
    cmdStr = "'^BMP-',addressPort,',0,',value,'.png'"
    sendCommand (dvStatus, cmdStr)
    for (i = 1; i <= TP_COUNT; i++)
    {
	if (gTpStatus[i])
	{
	    sendCommand (dvTp[i], cmdStr)
	}
    }
}

DEFINE_FUNCTION sendFieldTp (integer tpId, char addressPort[], char value[], integer checkColor)
{
    sendCommand (dvTp[tpId], "'TEXT',addressPort,'-',value")
}

DEFINE_FUNCTION sendTempIntFieldTp (integer tpId, char addressPort[], sinteger temp, char scale)
{
    // AMX bug? Need to create a new string rather than pass a constructed string to send_command.
    char str[8]
    str = "itoa(temp),$B0,scale"
    sendCommand (dvTp[tpId], "'TEXT',addressPort,'-',str")
}

DEFINE_FUNCTION sendTempFloatFieldTp (integer tpId, char addressPort[], float temp, char scale)
{
    // AMX bug? Need to create a new string rather than pass a constructed string to send_command.
    char str[8]
    str = "ftoa(temp),$B0,scale"
    sendCommand (dvTp[tpId], "'TEXT',addressPort,'-',str")
}

DEFINE_FUNCTION sendAppendFieldTp (integer tpId, char addressPort[], char value[])
{
    sendCommand (dvTp[tpId], "'^BAT-',addressPort,',0,',value")
}

DEFINE_FUNCTION sendIconFieldTp (integer tpId, char addressPort[], char value[])
{
    sendCommand (dvTp[tpId], "'^BMP-',addressPort,',0,',value,'.png'")
}

DEFINE_FUNCTION refreshTp (integer tpId)
{
    integer i
    char    dateStr[32]
    char    subTextStr[500]
    debug (DBG_MODULE, 4, "'Refreshing weather for TP ',devtoa(dvTp[tpId])")
    sendTempFloatFieldTp (tpId, WEATHER_CHAN_CURR_TEMP_F,	gCurrTempF,	'F')
    sendTempFloatFieldTp (tpId, WEATHER_CHAN_CURR_TEMP_C,	gCurrTempC,	'C')
//    sendFieldTp (tpId, WEATHER_CHAN_FEELS_LIKE_F,	"ftoa(gFeelsLikeF),$0B,'F'",	0)
//    sendFieldTp (tpId, WEATHER_CHAN_FEELS_LIKE_C,	"ftoa(gFeelsLikeC),$0B,'C'",	0)
    sendFieldTp (tpId, WEATHER_CHAN_CURR_COND_STR,	gCurrCond,	     		0)
    sendIconFieldTp (tpId, WEATHER_CHAN_CURR_COND_ICON,	gCurrCondIcon)
    sendFieldTp (tpId, WEATHER_CHAN_OBS_LOCATION,	gObserveLocation,     		0)
    sendFieldTp (tpId, WEATHER_CHAN_OBS_LATITUDE,	gObserveLatitudeStr,   		0)
    sendFieldTp (tpId, WEATHER_CHAN_OBS_LONGITUDE,	gObserveLongitudeStr,  		0)
    sendFieldTp (tpId, WEATHER_CHAN_OBS_ELEVATION,	gObserveElevationStr,  		0)
    sendFieldTp (tpId, WEATHER_CHAN_OBS_TIME_LONG_STR,	gObserveTimeLongStr,  		0)
    sendFieldTp (tpId, WEATHER_CHAN_REL_HUMIDITY,	itoa(gRelHumidity),		0)
    sendFieldTp (tpId, WEATHER_CHAN_WIND_STR,		gWindStr,			0)
    sendFieldTp (tpId, WEATHER_CHAN_SUNRISE,		gSunrise,			0)
    sendFieldTp (tpId, WEATHER_CHAN_SUNSET,		gSunset,			0)
    for (i = 1; i <= MAX_FORECAST_PERIODS; i++)
    {
	genDateString (dateStr, gForecastFull[i].mDay, gForecastFull[i].mMonth, gForecastFull[i].mYear)
        sendFieldTp (tpId, WEATHER_CHAN_FORECAST_FULL_TITLE[i],		gForecastFull[i].mTitle,	0)
        sendFieldTp (tpId, WEATHER_CHAN_FORECAST_FULL_DATE[i],		dateStr,			0)
        sendIconFieldTp (tpId, WEATHER_CHAN_FORECAST_FULL_ICON[i],	gForecastFull[i].mCondIcon)
        sendFieldTp (tpId, WEATHER_CHAN_FORECAST_FULL_TEXT[i],		left_string(gForecastFull[i].mText, 100), 0)
	if (length_array(gForecastFull[i].mText) > 100)
	{
	    subTextStr = right_string (gForecastFull[i].mText, length_array(gForecastFull[i].mText)-100)
	    while (length_array(subTextStr) > 0)
	    {
		if (length_array(subTextStr) > 100)
		{
		    sendAppendFieldTp (tpId, WEATHER_CHAN_FORECAST_FULL_TEXT[i], left_string(subTextStr, 100))
		    subTextStr = right_string(subTextStr,length_array(subTextStr)-100)
		}
		else
		{
		    sendAppendFieldTp (tpId, WEATHER_CHAN_FORECAST_FULL_TEXT[i], subTextStr)
		    break // quit the inner loop
		}
	    }
	}
    }
    for (i = 1; i <= MAX_FORECAST_PERIODS; i++)
    {
	genDateString (dateStr, gForecastSimple[i].mDay, gForecastSimple[i].mMonth, gForecastSimple[i].mYear)
        sendFieldTp (tpId, WEATHER_CHAN_FORECAST_SIMPLE_TITLE[i],	gForecastSimple[i].mTitle,		0)
    	sendFieldTp (tpId, WEATHER_CHAN_FORECAST_SIMPLE_DATE[i],	dateStr,				0)
    	sendFieldTp (tpId, WEATHER_CHAN_FORECAST_HIGH_F[i],		gForecastSimple[i].mHighFStr,		0)
    	sendFieldTp (tpId, WEATHER_CHAN_FORECAST_HIGH_C[i],		gForecastSimple[i].mHighCStr,		0)
    	sendFieldTp (tpId, WEATHER_CHAN_FORECAST_LOW_F[i],		gForecastSimple[i].mLowFStr,		0)
    	sendFieldTp (tpId, WEATHER_CHAN_FORECAST_LOW_C[i],		gForecastSimple[i].mLowCStr,		0)
        sendFieldTp (tpId, WEATHER_CHAN_FORECAST_SIMPLE_COND[i],	gForecastSimple[i].mCond,		0)
        sendIconFieldTp (tpId, WEATHER_CHAN_FORECAST_SIMPLE_ICON[i],	gForecastSimple[i].mCondIcon)
    }
}

DEFINE_FUNCTION genDateString (char result[], integer day, integer month, integer year)
{
    result = "itoa(month),'/',itoa(day),'/',itoa(year)"
}

(*
DEFINE_FUNCTION sinteger calcWindChillF (float temp, float wind)
{
    return 35.74 + 0.6215*temp - 35.75*power_value(wind,0.16) + 0.4275*power_value(temp,0.16)
}

DEFINE_FUNCTION sinteger calcWindChillC (float temp, float wind)
{
    return 13.12 + 0.6215*temp - 11.37*power_value(wind,0.16) + 0.3965*power_value(temp,0.16)
}
*)

DEFINE_FUNCTION sendCommand (dev cmdDev, char cmdStr[])
{
    debug (DBG_MODULE, 9, "'send_command ',devtoa(cmdDev),', ',cmdStr")
    send_command cmdDev, cmdStr
}

DEFINE_FUNCTION integer initializedOk()
{
    return gInitialized;
}

DEFINE_FUNCTION setInitializedOk (integer initOk)
{
    gInitialized = initOk;
}

DEFINE_EVENT
DATA_EVENT[dvTp]
{
    ONLINE:
    { 
	// Either the Master just restarted or the TP was just turned on again
        integer tpId
      	tpId = get_last(dvTp)
     	gTpStatus[tpId] = 1
      	refreshTp(tpId)
    }
    OFFLINE: { gTpStatus[get_last(dvTp)] = 0 }
    STRING: { debug (DBG_MODULE, 8, "'received string from TP (',devtoa(data.device),'): ',data.text") }
}


DEFINE_START
{
    integer i
    create_buffer dvLocalTcp, gBuf

    if (initializedOk())
    {
	//wait 1232	// 123.2 seconds (no real hurry to start this!)
    	wait 123	// 12.3 seconds (no real hurry to start this!)
    	{
	    connect()
	}
    }
    // Initialize the TP device array
    set_length_array (dvTp, TP_COUNT)
    for (i = 1; i <= TP_COUNT; i++)
    {
	tpMakeLocalDev (dvTp[i],    i, TP_PORT_WEATHER)
    }
    rebuild_event()
}


DEFINE_PROGRAM
wait 6053	// about every 10 minutes
{
    if (initializedOk())
        connect()
}
