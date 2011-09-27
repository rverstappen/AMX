MODULE_NAME='WeatherUnderground' (
	dev	dvStatus,
	dev	dvLocalTcp,
	char	currCondLoc[],
	char    airportLoc[],
	char	forecastLoc[],
	integer TP_COUNT)		// Number of TPs

DEFINE_VARIABLE

constant char    DBG_MODULE[]    = 'WeatherUnderground'
constant char    weatherServer[] = 'api.wunderground.com'
constant integer weatherPort     = 80
constant char	 currCondPath[]	 = '/weatherstation/WXCurrentObXML.asp?ID='
constant char    airportPath[]	 = '/auto/wui/geo/WXCurrentObXML/index.xml?query='
constant char	 forecastPath[]	 = '/auto/wui/geo/ForecastXML/index.xml?query='

volatile char    gBuf[150000]
volatile integer gReqNum

DEFINE_START
if ((currCondLoc = '') || (airportLoc = '') || (forecastLoc = ''))
{
    debug (DBG_MODULE, 1, 'Not initializing')
    setInitializedOk (0)
}
else
{
    setInitializedOk (1)
}

#include 'Weather.axi'
#include 'Debug.axi'

DEFINE_FUNCTION handleConnect()
{
    // We enter this function every time we connect and we will cycle through the requests
    switch (gReqNum)
    {
    case 0:
        debug (DBG_MODULE, 2, 'Connected: sending local current conditions request...')
    	sendRequest ("currCondPath,currCondLoc")
	gReqNum = 1
    	break
    case 1:
        debug (DBG_MODULE, 2, 'Connected: sending current airport conditions request...')
        sendRequest ("airportPath,airportLoc")
	gReqNum = 2
    	break
    case 2:
        debug (DBG_MODULE, 2, 'Connected: sending forecast request...')
        sendRequest ("forecastPath,forecastLoc")
	gReqNum = 0
    	break
    default:
        debug (DBG_MODULE, 2, 'handleConnect(): programming error?')
    }
}

DEFINE_FUNCTION handleDisconnect()
{
    // We enter this function every time we disconnect
    switch (gReqNum)
    {
    case 1:
        debug (DBG_MODULE, 2, 'Disconnected: should have received current local conditions.')
	wait 22 { connect() }
    	break
    case 2:
        debug (DBG_MODULE, 2, 'Disconnected: should have received current airport conditions...')
	wait 22 { connect() }
    	break
    case 0:
        debug (DBG_MODULE, 2, 'Disconnected: should have received forecast results...')
	// reconnection happens via main loop wait
    	break
    default:
        debug (DBG_MODULE, 2, 'handleDisconnect(): programming error?')
    }
}

DEFINE_FUNCTION integer handleReply (char msg[])
{
    integer currObsFound
    debug (DBG_MODULE, 3, "'Received ',itoa(length_string(msg)),' bytes from server'")
    currObsFound = find_string(msg,'<current_observation>',1)
    select
    {
    active (currObsFound && find_string(msg,'<observation_location>',1)):
    {
	handleAirportConditions (msg)
    }
    active (currObsFound):
    {
	handleLocalConditions (msg)
    }
    active (find_string(msg,'<forecast>',1)):
    {
	handleForecast (msg)
    } // active
    } // select
    return 1
}

DEFINE_FUNCTION handleAirportConditions (char msg[])
{
	// Current conditions at airport (for current conditions and icon):
	remove_string(msg,'<observation_location>',1)
	getStringField (gCurrCond,	msg, 'weather')
	getStringField (gCurrCondIcon,	msg, 'icon')
	sendAirportFields()
}

DEFINE_FUNCTION handleLocalConditions (char msg[])
{
	remove_string(msg,'<location>',1)
	getStringField (gObserveLocation,	msg, 'full')
	getStringField (gObserveLatitudeStr,	msg, 'latitude')
	getStringField (gObserveLongitudeStr,	msg, 'longitude')
	getStringField (gObserveElevationStr,	msg, 'elevation')
	getStringField (gObserveTimeLongStr,	msg, 'observation_time')
	if (find_string (gObserveTimeLongStr, ' on ', 1))
	{
	    remove_string (gObserveTimeLongStr, ' on ', 1)
	}
	if (getStringField (gCurrTempFStr,	msg, 'temp_f'))
	{
	    gCurrTempF = atof(gCurrTempFStr)
//	    gCurrTempFStr = "ftoa(gCurrTempF),' °F'"
	    gCurrTempFStr = "ftoa(gCurrTempF),' ',$B0,'F'"
	}
	if (getStringField (gCurrTempCStr,	msg, 'temp_c'))
	{
	    gCurrTempC = atof(gCurrTempCStr)
	    gCurrTempCStr = "ftoa(gCurrTempC),' °C'"
	}
	if (getStringField (gRelHumidityStr,	msg, 'relative_humidity'))
	    gRelHumidity = atoi(gRelHumidityStr)
	getStringField (gWindStr,		msg, 'wind_string')
	getStringField (gWindDir,		msg, 'wind_dir')
	if (getStringField (gWindDegreesStr,	msg, 'wind_degrees'))
	    gWindDegrees = atoi(gWindDegreesStr)
	if (getStringField (gWindMphStr,	msg, 'wind_mph'))
	    gWindMph = atof(gWindMphStr)
	if (getStringField (gWindGustMphStr,	msg, 'wind_gust_mph'))
	{
	    gWindGustMph = atof(gWindGustMphStr)
	    gWindStr = "gWindDir,' at ',ftoa(gWindMph),' mph, gusts to ',ftoa(gWindGustMph)"
	}
	if (getStringField (gDewPointFStr,	msg, 'dewpoint_f'))
	    gDewPointF = atof(gDewPointFStr)
	if (getStringField (gDewPointCStr,	msg, 'dewpoint_c'))
	    gDewPointC = atof(gDewPointCStr)
//	gFeelsLikeF = calcWindChillF (gCurrTempF, gWindMph)
//	gFeelsLikeC = calcWindChillC (gCurrTempC, gWindMph)
	sendLocalFields()
}

DEFINE_FUNCTION handleForecast (char msg[])
{
    // The forecast data comes in two sections: a detailed text foreacast for the first
    // few periods, and a "simple forecast" with high/low for all available periods. It would be 
    // best to split the main msg into two parts, since some of the elements have the same names, 
    // especially, <period>.
    local_var char simpleFc[50000]
    integer split, count, i
    char    tmpStr[32]
    split = find_string (msg, '<simpleforecast>', 1)
    simpleFc = right_string (msg, length_array(msg)-split)  // copy the "simple" forecasts
    set_length_array(msg,split)  // shortens the original string

    // Text forecast data
    count = 0
    set_length_array (gForecastFull, MAX_FORECAST_PERIODS)
    remove_string(msg,'<forecastday>',1)
    getStringField (tmpStr, msg, 'period')
    i = atoi(tmpStr)
    while ((i > 0) && (i <= MAX_FORECAST_PERIODS) && (count <= MAX_FORECAST_PERIODS))
    {
	getStringField (gForecastFull[i].mCondIcon,	msg, 'icon')
	if (find_string(msg,'<title>',1))
	    getStringField (gForecastFull[i].mTitle,	msg, 'title')
	if (find_string(msg,'<fcttext>',1))
	    getStringField (gForecastFull[i].mText,	msg, 'fcttext')
	getStringField (tmpStr, msg, 'period')       // next period, if any
	i = atoi(tmpStr)
	count++
    }
    set_length_array (gForecastFull, count)

    // Simple forecast data
    count = 0
    set_length_array (gForecastSimple, MAX_FORECAST_PERIODS)
    remove_string(simpleFc,'<forecastday>',1)
    getStringField (tmpStr, simpleFc, 'period')
    i = atoi(tmpStr)
    while ((i > 0) && (i <= MAX_FORECAST_PERIODS) && (count <= MAX_FORECAST_PERIODS))
    {
	getStringField (tmpStr,	simpleFc, 'day')
	gForecastSimple[i].mDay = atoi(tmpStr)
	getStringField (tmpStr,	simpleFc, 'month')
	gForecastSimple[i].mMonth = atoi(tmpStr)
	getStringField (tmpStr,	simpleFc, 'year')
	gForecastSimple[i].mYear = atoi(tmpStr)
	getStringField (gForecastSimple[i].mTitle, simpleFc, 'weekday')
	// No need to parse everything. First fahrenheit per period is high, second is low:
	getStringField (tmpStr,	simpleFc, 'fahrenheit')
	gForecastSimple[i].mHighF = atoi(tmpStr)
	getStringField (tmpStr,	simpleFc, 'celsius')
	gForecastSimple[i].mHighC = atoi(tmpStr)
	getStringField (tmpStr,	simpleFc, 'fahrenheit')
	gForecastSimple[i].mLowF = atoi(tmpStr)
	getStringField (tmpStr,	simpleFc, 'celsius')
	gForecastSimple[i].mLowC = atoi(tmpStr)
	getStringField (gForecastSimple[i].mCond,	simpleFc, 'conditions')
	getStringField (gForecastSimple[i].mCondIcon,	simpleFc, 'icon')
	getStringField (tmpStr, simpleFc, 'period') // next period, if any
	gForecastSimple[i].mHighFStr = "'H ',itoa(gForecastSimple[i].mHighF),' °F'"
	gForecastSimple[i].mHighCStr = "'H ',itoa(gForecastSimple[i].mHighC),' °C'"
	gForecastSimple[i].mLowFStr  = "'L ',itoa(gForecastSimple[i].mLowF), ' °F'"
	gForecastSimple[i].mLowCStr  = "'L ',itoa(gForecastSimple[i].mLowC), ' °C'"
	i = atoi(tmpStr)
	count++
    }
    set_length_array (gForecastSimple, count)

    if (find_string(simpleFc,'<moon_phase>',1))
    {
	char hour[2], minute[2]
	remove_string(simpleFc,'<sunset>',1)
	getStringField (hour,   simpleFc, 'hour')
	getStringField (minute, simpleFc, 'minute')
	gSunset = "hour,':',minute"
	remove_string(simpleFc,'<sunrise>',1)
	getStringField (hour,   simpleFc, 'hour')
	getStringField (minute, simpleFc, 'minute')
	gSunrise = "hour,':',minute"
    }
    sendForecastFields ()
}

DEFINE_FUNCTION sendAirportFields()
{
    sendField (WEATHER_CHAN_CURR_COND,		gCurrCond,	0)
    sendIconField (WEATHER_CHAN_CURR_COND_ICON,	gCurrCondIcon) 
}

DEFINE_FUNCTION sendLocalFields()
{
    sendField (WEATHER_CHAN_CURR_TEMP_F,	gCurrTempFStr,			1)
    sendField (WEATHER_CHAN_CURR_TEMP_C,	gCurrTempCStr,			1)
//    sendField (WEATHER_CHAN_FEELS_LIKE_F,	gFeelsLikeFStr,			0)
//    sendField (WEATHER_CHAN_FEELS_LIKE_C,	gFeelsLikeCStr,			0)
    sendField (WEATHER_CHAN_WIND_STR,		gWindStr,	     		0)
    sendField (WEATHER_CHAN_OBS_LOCATION,	gObserveLocation,   		0)
    sendField (WEATHER_CHAN_OBS_ELEVATION,	gObserveElevationStr,  		0)
    sendField (WEATHER_CHAN_OBS_TIME_LONG_STR,	gObserveTimeLongStr,   		0)
}

DEFINE_FUNCTION sendForecastFields()
{
    integer i
    char dateStr[32]
    char subTextStr[500]
    for (i = 1; i <= length_array(gForecastFull); i++)
    {
        sendField (WEATHER_CHAN_FORECAST_FULL_TITLE[i],		gForecastFull[i].mTitle,		0)
        sendIconField (WEATHER_CHAN_FORECAST_FULL_ICON[i],	gForecastFull[i].mCondIcon)
        sendField (WEATHER_CHAN_FORECAST_FULL_TEXT[i],		left_string(gForecastFull[i].mText, 100), 0)
	if (length_array(gForecastFull[i].mText) > 100)
	{
	    subTextStr = right_string (gForecastFull[i].mText, length_array(gForecastFull[i].mText)-100)
	    while (length_array(subTextStr) > 0)
	    {
		if (length_array(subTextStr) > 100)
	    	{
		    sendAppendField (WEATHER_CHAN_FORECAST_FULL_TEXT[i], left_string(subTextStr, 100))
		    subTextStr = right_string(subTextStr,length_array(subTextStr)-100)
	    	}
	    	else
	    	{
		    sendAppendField (WEATHER_CHAN_FORECAST_FULL_TEXT[i], subTextStr)
	            break // quit the loop
		}
	    }
	}
    }
    for (i = 1; i <= length_array(gForecastSimple); i++)
    {
	genDateString (dateStr, gForecastSimple[i].mDay, gForecastSimple[i].mMonth, gForecastSimple[i].mYear)
        sendField (WEATHER_CHAN_FORECAST_SIMPLE_TITLE[i],	gForecastSimple[i].mTitle,	0)
        sendField (WEATHER_CHAN_FORECAST_SIMPLE_DATE[i],	dateStr,			0)
    	sendField (WEATHER_CHAN_FORECAST_HIGH_F[i],		gForecastSimple[i].mHighFStr,	0)
    	sendField (WEATHER_CHAN_FORECAST_HIGH_C[i],		gForecastSimple[i].mHighCStr,	0)
    	sendField (WEATHER_CHAN_FORECAST_LOW_F[i],		gForecastSimple[i].mLowFStr,	0)
    	sendField (WEATHER_CHAN_FORECAST_LOW_C[i],		gForecastSimple[i].mLowCStr,	0)
        sendField (WEATHER_CHAN_FORECAST_SIMPLE_COND[i],	gForecastSimple[i].mCond,	0)
        sendIconField (WEATHER_CHAN_FORECAST_SIMPLE_ICON[i],	gForecastSimple[i].mCondIcon)
    }
    sendField (WEATHER_CHAN_SUNRISE,				gSunrise,			0)
    sendField (WEATHER_CHAN_SUNSET,				gSunset,			0)
}
