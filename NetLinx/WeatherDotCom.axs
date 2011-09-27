MODULE_NAME='WeatherDotCom' (
	dev	dvStatus,
	dev	dvLocalTcp,
	char	zipCode[],
	integer TP_COUNT)		// Number of TPs

DEFINE_VARIABLE

constant char    DBG_MODULE[] = 'WeatherDotCom_Comm'
constant char    weatherServer[] = 'xoap.weather.com'
constant integer weatherPort     = 80

volatile char gBuf[150000]

#include 'Weather.axi'
#include 'Debug.axi'

DEFINE_FUNCTION handleConnect()
{
    debug (DBG_MODULE, 2, 'Connected: sending request...')
    sendRequest ("'/weather/local/',zipCode,'?cc=*&dayf=5&link=xoap&prod=xoap&par=1077935534&key=6dcb4f116e8d61e4'")
    wait 100
    {
	disconnect()
    }
}

DEFINE_FUNCTION handleDisconnect()
{
    debug (DBG_MODULE, 2, 'Disconnected.')
}

DEFINE_FUNCTION handleReply (char msg[])
{
    debug (DBG_MODULE, 3, "'Received ',itoa(length_string(msg)),' bytes from server'")
    if (find_string(msg,'<loc id=',1)) // Start! Found Zip code!
    {
	// Current conditions:
	remove_string(msg,'<loc id=',1)
	getStringField (gRequestTime,	msg, 'tm')	// Current time (of our request)
	getStringField (gSunrise,	msg, 'sunr')	// Sunrise
	getStringField (gSunset,	msg, 'suns')	// Sunset
	getStringField (gForecastTime,	msg, 'lsup')	// Forecast time
	getStringField (gCurrTempFStr,	msg, 'tmp')	// Current temperature
	getStringField (gFeelsLikeFStr,	msg, 'flik')	// Feels like temperature
	getStringField (gCurrCond,	msg, 't')	// Current conditions
	getStringField (gCurrCondIcon,	msg, 'icon')	// Current conditions icon ID
	// Skip barometric pressure (for now)
	// Skip wind (for now)
	getStringField (gHumidity,	msg, 'hmid')	// Humidity
	getStringField (gVisibility,	msg, 'vis')	// Visibility
	// Skip UV (for now)
	getStringField (gDewPointFStr,	msg, 'dewp')	// Dewpoint
	// Skip moon (for now)

	// Forecast conditions:
	getDailyFields (gForecast[1], msg, '0')		// '0' = today
	getDailyFields (gForecast[2], msg, '1')		// '1' = tomorrow
	getDailyFields (gForecast[3], msg, '2')		// '2' = etc.
	getDailyFields (gForecast[4], msg, '3')
	getDailyFields (gForecast[5], msg, '4')
	
	// Send out to the TPs
	sendCurrentStatus()
    }
}

DEFINE_FUNCTION getDailyFields (ForecastPeriod forecast, char msg[], char dayNum[])
{
    remove_string(msg,"'<day d="',dayNum,'" t="'",1)
    forecast.mPeriodName = left_string(msg,find_string(msg,'"',1)-1)
    remove_string(msg,' dt="',1)
    forecast.mPeriodDate = left_string(msg,find_string(msg,'"',1)-1)
    getStringField (forecast.mHighTemp,	msg, 'hi')
    getStringField (forecast.mLowTemp,	msg, 'low')
    getStringField (forecast.mCond,	msg, 't')
    getStringField (forecast.mCondIcon,	msg, 'icon')
}
