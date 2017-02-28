MODULE_NAME='Hvac_ViewStat' (char configFile[], char tpConfigFile[])

(*
 * This file contains all of the ViewStat specific processing.  
 *
 * It assumes access to the following variables and types:
 * - Contents of Hvac.axi and Hvac_UI.axi
 * - The gHvacs array
 * - The gHvacState array
 * - The gHvacDvs array
 * - The doTpUpdateXyz() functions
 *)

#include 'Hvac.axi'
#include 'HvacConfig.axi'
#include 'Hvac_UI.axi'


DEFINE_CONSTANT

HVAC_VST_CHAN_WEATHER_ALERT			= 139	// Control
HVAC_VST_CHAN_INCR_COOL_SETPOINT		= 140	// Control
HVAC_VST_CHAN_DECR_COOL_SETPOINT		= 141	// Control
HVAC_VST_CHAN_INCR_HEAT_SETPOINT		= 143	// Control
HVAC_VST_CHAN_DECR_HEAT_SETPOINT		= 144	// Control
HVAC_VST_CHAN_INCR_HUMIDIFY_SETPOINT		= 148	// Control
HVAC_VST_CHAN_DECR_HUMIDIFY_SETPOINT		= 149	// Control
HVAC_VST_CHAN_INCR_DEHUMIDIFY_SETPOINT		= 150	// Control
HVAC_VST_CHAN_DECR_DEHUMIDIFY_SETPOINT		= 151	// Control
HVAC_VST_CHAN_FILTER_CHANGE			= 160	// Feedback
HVAC_VST_CHAN_FAN_SPEED_1			= 209	// Control/Feedback
HVAC_VST_CHAN_FAN_SPEED_2			= 210	// Control/Feedback
HVAC_VST_CHAN_FAN_SPEED_3			= 211	// Control/Feedback
HVAC_VST_CHAN_LOCK_OUT_STATE			= 212	// Control/Feedback
HVAC_VST_CHAN_FAN_STATE_ON			= 214	// Control/Feedback
HVAC_VST_CHAN_FAN_STATE_AUTO			= 215	// Control/Feedback
HVAC_VST_CHAN_FAN_STATUS			= 216	// Feedback
HVAC_VST_CHAN_HVAC_STATE_AUTO			= 219	// Control/Feedback
HVAC_VST_CHAN_HVAC_STATE_COOL			= 220	// Control/Feedback
HVAC_VST_CHAN_HVAC_STATE_HEAT			= 221	// Control/Feedback
HVAC_VST_CHAN_HVAC_STATE_OFF			= 222	// Control/Feedback
HVAC_VST_CHAN_HVAC_STATE_EMERGENCY_HEAT		= 223	// Control/Feedback
HVAC_VST_CHAN_HVAC_COOL_STATUS			= 224	// Feedback
HVAC_VST_CHAN_HVAC_HEAT_STATUS			= 225	// Feedback
HVAC_VST_CHAN_HVAC_EMERGENCY_HEAT_STATUS	= 227	// Feedback
HVAC_VST_CHAN_HUMIDIFY_STATE_AUTO		= 228	// Control/Feedback
HVAC_VST_CHAN_HUMIDIFY_STATE_DEHUMIDIFY		= 229	// Control/Feedback
HVAC_VST_CHAN_HUMIDIFY_STATE_HUMIDIFY		= 230	// Control/Feedback
HVAC_VST_CHAN_HUMIDIFY_STATE_OFF		= 231	// Control/Feedback
HVAC_VST_CHAN_DEHUMIDIFY_STATUS			= 232	// Feedback
HVAC_VST_CHAN_HUMIDIFY_STATUS			= 233	// Feedback
HVAC_VST_CHAN_REVERSING_VALVE_COOL_RELAY	= 240	// Feedback
HVAC_VST_CHAN_REVERSING_VALVE_HEAT_RELAY	= 241	// Feedback
HVAC_VST_CHAN_1ST_STAGE_COMPRESSOR_RELAY	= 242	// Feedback
HVAC_VST_CHAN_2ND_STAGE_COMPRESSOR_RELAY	= 243	// Feedback
HVAC_VST_CHAN_1ST_STAGE_HEAT_RELAY		= 244	// Feedback
HVAC_VST_CHAN_2ND_STAGE_HEAT_RELAY		= 245	// Feedback
HVAC_VST_CHAN_DEHUMIDIFY_RELAY			= 246	// Feedback
HVAC_VST_CHAN_HUMIDIFY_RELAY			= 247	// Feedback
HVAC_VST_CHAN_FAN_RELAY_1			= 248	// Feedback
HVAC_VST_CHAN_FAN_RELAY_2			= 249	// Feedback
HVAC_VST_CHAN_FAN_RELAY_3			= 250	// Feedback

HVAC_VST_LEVEL_INDOOR_TEMP			= 1	// Feedback
HVAC_VST_LEVEL_INDOOR_HUMIDITY			= 2	// Feedback
HVAC_VST_LEVEL_CURR_HEAT_SET_POINT		= 3	// Control/Feedback
HVAC_VST_LEVEL_CURR_COOL_SET_POINT		= 4	// Control/Feedback
HVAC_VST_LEVEL_OUTDOOR_TEMP			= 5	// Control
HVAC_VST_LEVEL_BAROMETRIC_PRESSURE		= 6	// Control
HVAC_VST_LEVEL_HIGH_FORECAST			= 7	// Control
HVAC_VST_LEVEL_LOW_FORECAST			= 8	// Control

HVAC_VST_TIMELINE_ID_FETCH_STATUSES		= 1	// Timeline
HVAC_VST_TIMELINE_ID_FETCH_PROGRAMS		= 2	// Timeline


DEFINE_VARIABLE

volatile char VST_MODULE[] = 'Hvac_ViewStat'
volatile char gHvacProgramFetchStateDay   [MAX_HVACS]
volatile char gHvacProgramFetchStatePeriod[MAX_HVACS]


(*
 * Incoming events from the ViewStat devices are translated into generic events and passed to the UI
 * module for further handling.
 *)
DEFINE_EVENT

DATA_EVENT[gHvacDvs]
{
    ONLINE:  { handleVstOnline  (get_last(gHvacDvs)) }
    OFFLINE: { handleVstOffline (get_last(gHvacDvs)) }
    COMMAND: { handleVstMessage (get_last(gHvacDvs), data.text) }
    STRING:  { handleVstMessage (get_last(gHvacDvs), data.text) }
}

LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_INDOOR_TEMP]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(gHvacDvs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received indoor temperature update from device(',itoa(hvacId),', ',
    	  	          gHvacs[hvacId].mShortName,') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
    doTpUpdateCurrTemp (hvacId, realTemp)
}

LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_INDOOR_HUMIDITY]
{
    integer  hvacId, humidity
    hvacId = get_last(gHvacDvs)
    humidity = level.value
    debug (VST_MODULE, 6, "'received indoor humidity update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(humidity)")
    doTpUpdateCurrHumidity (hvacId, humidity)
}

LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_CURR_HEAT_SET_POINT]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(gHvacDvs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received heat set-point update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
    doTpUpdateCurrHeatSetPoint (hvacId, realTemp)
}

LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_CURR_COOL_SET_POINT]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(gHvacDvs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received cool set-point update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
    doTpUpdateCurrCoolSetPoint (hvacId, realTemp)
}

LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_OUTDOOR_TEMP]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(gHvacDvs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received outdoor temperature update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
//    doTpUpdateCurrOutdoorTemp (hvacId, realTemp)
}

// We're not interested in the forecasts and barometirc pressure readings
//LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_BAROMETRIC_PRESSURE] {}
//LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_HIGH_FORECAST] {}
//LEVEL_EVENT[gHvacDvs, HVAC_VST_LEVEL_LOW_FORECAST] {}

// Channel event handling for all of the Feedback channels (commented out channels are not 
// interesting to us)
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FILTER_CHANGE]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_SPEED_1]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_SPEED_2]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_SPEED_3]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_LOCK_OUT_STATE]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_STATE_ON]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_STATE_AUTO]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_STATUS]		{}
CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_STATE_AUTO]
    { ON: { doTpSetHvacHcMode (get_last(gHvacDvs), HVAC_HC_MODE_AUTO) } }
CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_STATE_COOL]
    { ON: { doTpSetHvacHcMode (get_last(gHvacDvs), HVAC_HC_MODE_COOL) } }
CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_STATE_HEAT]
    { ON: { doTpSetHvacHcMode (get_last(gHvacDvs), HVAC_HC_MODE_HEAT) } }
CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_STATE_OFF]
    { ON: { doTpSetHvacHcMode (get_last(gHvacDvs), HVAC_HC_MODE_OFF) } }
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_STATE_EMERGENCY_HEAT]	{}
CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_COOL_STATUS]
    { ON:  { doTpSetHvacHcStatus (get_last(gHvacDvs), HVAC_HC_STATUS_COOL) }
      OFF: { doTpSetHvacHcStatus (get_last(gHvacDvs), HVAC_HC_STATUS_OFF) } }
CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_HEAT_STATUS]
    { ON:  { doTpSetHvacHcStatus (get_last(gHvacDvs), HVAC_HC_STATUS_HEAT) }
      OFF: { doTpSetHvacHcStatus (get_last(gHvacDvs), HVAC_HC_STATUS_OFF) } }
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HVAC_EMERGENCY_HEAT_STATUS]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HUMIDIFY_STATE_AUTO]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HUMIDIFY_STATE_DEHUMIDIFY]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HUMIDIFY_STATE_HUMIDIFY]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HUMIDIFY_STATE_OFF]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_DEHUMIDIFY_STATUS]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HUMIDIFY_STATUS]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_REVERSING_VALVE_COOL_RELAY]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_REVERSING_VALVE_HEAT_RELAY]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_1ST_STAGE_COMPRESSOR_RELAY]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_2ND_STAGE_COMPRESSOR_RELAY]	{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_1ST_STAGE_HEAT_RELAY]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_2ND_STAGE_HEAT_RELAY]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_DEHUMIDIFY_RELAY]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_HUMIDIFY_RELAY]		{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_RELAY_1]			{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_RELAY_2]			{}
//CHANNEL_EVENT[gHvacDvs, HVAC_VST_CHAN_FAN_RELAY_3]			{}

CHANNEL_EVENT[gHvacDvs, 0]
{
    ON:
    {
	char chanName[64]
	vstChannelName(chanName, channel.channel)
	debug (VST_MODULE, 9, "'got channel (',itoa(channel.channel),': ',chanName,')  ON event from ',
	      		      devtoa(channel.device)")
    }
    OFF:
    {
	char chanName[64]
	vstChannelName(chanName, channel.channel)
	debug (VST_MODULE, 9, "'got channel (',itoa(channel.channel),': ',chanName,') OFF event from ',
	      		      devtoa(channel.device)")
    }
}

DEFINE_FUNCTION vstChannelName (char result[], integer vstChan)
{
    switch (vstChan)
    {
    case HVAC_VST_CHAN_WEATHER_ALERT:
    	 result = 'HVAC_VST_CHAN_WEATHER_ALERT'
    case HVAC_VST_CHAN_INCR_COOL_SETPOINT:
    	 result = 'HVAC_VST_CHAN_INCR_COOL_SETPOINT'
    case HVAC_VST_CHAN_DECR_COOL_SETPOINT:
    	 result = 'HVAC_VST_CHAN_DECR_COOL_SETPOINT'
    case HVAC_VST_CHAN_INCR_HEAT_SETPOINT:
    	 result = 'HVAC_VST_CHAN_INCR_HEAT_SETPOINT'
    case HVAC_VST_CHAN_DECR_HEAT_SETPOINT:
    	 result = 'HVAC_VST_CHAN_DECR_HEAT_SETPOINT'
    case HVAC_VST_CHAN_INCR_HUMIDIFY_SETPOINT:
    	 result = 'HVAC_VST_CHAN_INCR_HUMIDIFY_SETPOINT'
    case HVAC_VST_CHAN_DECR_HUMIDIFY_SETPOINT:
    	 result = 'HVAC_VST_CHAN_DECR_HUMIDIFY_SETPOINT'
    case HVAC_VST_CHAN_INCR_DEHUMIDIFY_SETPOINT:
    	 result = 'HVAC_VST_CHAN_INCR_DEHUMIDIFY_SETPOINT'
    case HVAC_VST_CHAN_DECR_DEHUMIDIFY_SETPOINT:
    	 result = 'HVAC_VST_CHAN_DECR_DEHUMIDIFY_SETPOINT'
    case HVAC_VST_CHAN_FILTER_CHANGE:
    	 result = 'FILTER_CHANGE'
    case HVAC_VST_CHAN_FAN_SPEED_1:
    	 result = 'FAN_SPEED_1'
    case HVAC_VST_CHAN_FAN_SPEED_2:
    	 result = 'FAN_SPEED_2'
    case HVAC_VST_CHAN_FAN_SPEED_3:
    	 result = 'FAN_SPEED_3'
    case HVAC_VST_CHAN_LOCK_OUT_STATE:
    	 result = 'LOCK_OUT_STATE'
    case HVAC_VST_CHAN_FAN_STATE_ON:
    	 result = 'FAN_STATE_ON'
    case HVAC_VST_CHAN_FAN_STATE_AUTO:
    	 result = 'FAN_STATE_AUTO'
    case HVAC_VST_CHAN_FAN_STATUS:
    	 result = 'FAN_STATUS'
    case HVAC_VST_CHAN_HVAC_STATE_AUTO:
    	 result = 'HVAC_STATE_AUTO'
    case HVAC_VST_CHAN_HVAC_STATE_COOL:
    	 result = 'HVAC_STATE_COOL'
    case HVAC_VST_CHAN_HVAC_STATE_HEAT:
    	 result = 'HVAC_STATE_HEAT'
    case HVAC_VST_CHAN_HVAC_STATE_OFF:
    	 result = 'HVAC_STATE_OFF'
    case HVAC_VST_CHAN_HVAC_STATE_EMERGENCY_HEAT:
    	 result = 'HVAC_STATE_EMERGENCY_HEAT'
    case HVAC_VST_CHAN_HVAC_COOL_STATUS:
    	 result = 'HVAC_COOL_STATUS'
    case HVAC_VST_CHAN_HVAC_HEAT_STATUS:
    	 result = 'HVAC_HEAT_STATUS'
    case HVAC_VST_CHAN_HVAC_EMERGENCY_HEAT_STATUS:
    	 result = 'HVAC_EMERGENCY_HEAT_STATUS'
    case HVAC_VST_CHAN_HUMIDIFY_STATE_AUTO:
    	 result = 'HUMIDIFY_STATE_AUTO'
    case HVAC_VST_CHAN_HUMIDIFY_STATE_DEHUMIDIFY:
    	 result = 'HUMIDIFY_STATE_DEHUMIDIFY'
    case HVAC_VST_CHAN_HUMIDIFY_STATE_HUMIDIFY:
    	 result = 'HUMIDIFY_STATE_HUMIDIFY'
    case HVAC_VST_CHAN_HUMIDIFY_STATE_OFF:
    	 result = 'HUMIDIFY_STATE_OFF'
    case HVAC_VST_CHAN_DEHUMIDIFY_STATUS:
    	 result = 'DEHUMIDIFY_STATUS'
    case HVAC_VST_CHAN_HUMIDIFY_STATUS:
    	 result = 'HVACDIFY_STATUS'
    case HVAC_VST_CHAN_REVERSING_VALVE_COOL_RELAY:
    	 result = 'REVERSING_VALVE_COOL_RELAY'
    case HVAC_VST_CHAN_REVERSING_VALVE_HEAT_RELAY:
    	 result = 'REVERSING_VALVE_HEAT_RELAY'
    case HVAC_VST_CHAN_1ST_STAGE_COMPRESSOR_RELAY:
    	 result = '1ST_STAGE_COMPRESSOR_RELAY'
    case HVAC_VST_CHAN_2ND_STAGE_COMPRESSOR_RELAY:
    	 result = '2ND_STAGE_COMPRESSOR_RELAY'
    case HVAC_VST_CHAN_1ST_STAGE_HEAT_RELAY:
    	 result = '1ST_STAGE_HEAT_RELAY'
    case HVAC_VST_CHAN_2ND_STAGE_HEAT_RELAY:
    	 result = '2ND_STAGE_HEAT_RELAY'
    case HVAC_VST_CHAN_DEHUMIDIFY_RELAY:
    	 result = 'DEHUMIDIFY_RELAY'
    case HVAC_VST_CHAN_HUMIDIFY_RELAY:
    	 result = 'HUMIDIFY_RELAY'
    case HVAC_VST_CHAN_FAN_RELAY_1:
    	 result = 'FAN_RELAY_1'
    case HVAC_VST_CHAN_FAN_RELAY_2:
    	 result = 'FAN_RELAY_2'
    case HVAC_VST_CHAN_FAN_RELAY_3:
    	 result = 'HVACRELAY_3'
    default:
    	 result = '<unknown>'
    }
}

DEFINE_FUNCTION sinteger normalizeVsxTemp (integer vsxTemp)
{
    return type_cast(vsxTemp) - 120
}

DEFINE_FUNCTION handleVstOnline (integer hvacId)
{
    debug (VST_MODULE, 2, "'VST(',devtoa(gHvacs[hvacId].mDev),') is ONLINE'")
    vstRequestLevels (hvacId)
}

DEFINE_FUNCTION handleVstOffline (integer hvacId)
{
    debug (VST_MODULE, 4, "'VST(',devtoa(gHvacs[hvacId].mDev),') is OFFLINE'")
}

DEFINE_FUNCTION handleVstMessage (integer hvacId, char msg[])
{
    integer spacePos
    char cmdStr[2], modeStr[2]
    debug (VST_MODULE, 9, "'got message from VST(',devtoa(gHvacs[hvacId].mDev),'): ',msg")
    spacePos = find_string(msg,' ',1)
    if (spacePos > 0)
	cmdStr = left_string(msg,spacePos-1)
    else
	cmdStr = msg
    cmdStr = left_string(msg, find_string(msg,' ',1)-1)
    switch (cmdStr)
    {

    case 'PG':
    {
	integer day, period, time24hr
	remove_string (msg, 'PG D', 1)
	day = atoi(msg) + 1
	remove_string (msg, ' SP', 1)
	period = atoi(msg)
	debug (VST_MODULE, 9, "'Checking program for HVAC ',itoa(hvacId),': day=',itoa(day),'; sp=',itoa(period)")
	if ((day >= 1) && (period >= 1))
	{
	    remove_string (msg, ' HT', 1)
	    gHvacState[hvacId].mDailySchedules[day][period].mHeatTemp = atoi(msg)
	    remove_string (msg, ' C', 1)
	    gHvacState[hvacId].mDailySchedules[day][period].mCoolTemp = atoi(msg)
	    remove_string (msg, ' HM', 1)
	    gHvacState[hvacId].mDailySchedules[day][period].mHumidify = atoi(msg)
	    remove_string (msg, ' DM', 1)
	    gHvacState[hvacId].mDailySchedules[day][period].mDehumidify = atoi(msg)
	    remove_string (msg, ' T', 1)
	    time24hr = atoi(msg)
	    gHvacState[hvacId].mDailySchedules[day][period].mMinutes =
							 (60 * (time24hr/100)) + (time24hr%100)
	}
    }

    case 'SP':
    {
	// got hudify/dehumidify set-point info: "SP H{#} D{#}"
	integer humPoint, dehumPoint
	remove_string (msg, 'SP H', 1)
	humPoint = atoi(msg)
	remove_string (msg, ' D', 1)
	dehumPoint = atoi(msg)
	debug (VST_MODULE, 6, "'received humidify set-points for HVAC ',itoa(hvacId),': H=',
	      		      itoa(humPoint),', D=',itoa(dehumPoint)")
	doTpUpdateCurrHumidifySetPoint   (hvacId, humPoint)
	doTpUpdateCurrDehumidifySetPoint (hvacId, dehumPoint)
    }

    case 'MD':
    {
	// got thermostat mode: "MD M[P|V|H|PH]"
	remove_string (msg, 'MD M', 1)
	debug (VST_MODULE, 6, "'mode for HVAC ',itoa(hvacId),': ',msg")
	spacePos = find_string(msg,' ',1)
	if (spacePos > 0)
	    modeStr = left_string(msg,spacePos-1)
	else
	    modeStr = msg
	switch (modeStr)
	{
	// Put 'PH' first because otherwise Netlinx compiler thinks it's a switch on chars, not strings
	case 'PH':
	{
	    doTpUpdateSystemMode (hvacId, HVAC_MODE_PERM_HOLD)
	}
	case 'P':
	{
	    doTpUpdateSystemMode (hvacId, HVAC_MODE_PROGRAM)
	}
	case 'V':
	{
	    doTpUpdateSystemMode (hvacId, HVAC_MODE_VACATION)
	}
	case 'H':
	{
	    doTpUpdateSystemMode (hvacId, HVAC_MODE_OVERRIDE)
	}
	}
	if (find_string (msg, ' H', 1))
	{
	    remove_string (msg, ' H', 1)
	    gHvacState[hvacId].mFixedSetPointHeat = atoi(msg)
	}
	if (find_string (msg, ' C', 1))
	{
	    remove_string (msg, ' C', 1)
	    gHvacState[hvacId].mFixedSetPointCool = atoi(msg)
	}
    }

    case 'FM':
    {
    	 // got scale (Fahrenheit/Celsius): "FM S[F|H]"
    }
    } // switch
}

DEFINE_FUNCTION vstRequestLevels (integer hvacId)
{
    commSendCommand (gHvacs[hvacId].mDev, 'LEVON')
}

DEFINE_FUNCTION vstRequestStatusAll ()
{
    // Get system status for each Hvac using a timeline to smooth out the data responses
    long tmLine[MAX_HVACS]
    createTimeLineArray (tmLine, length_array(gHvacs), 6113)	// 6.113 seconds
    debug (VST_MODULE,2,'Starting timeline to request system program statuses')
    timeline_create (HVAC_VST_TIMELINE_ID_FETCH_STATUSES, tmLine, length_array(tmLine), 
    		     TIMELINE_RELATIVE, TIMELINE_ONCE)
}

DEFINE_FUNCTION vstRequestProgramAll ()
{
    // Get system status for each Hvac using a timeline to smooth out the data responses
    long tmLine[1000]
    createTimeLineArray (tmLine, length_array(gHvacs) * 28, 7723)	// 7.723 seconds
    debug (VST_MODULE,2,'Starting timeline to request system program statuses')
    timeline_create (HVAC_VST_TIMELINE_ID_FETCH_PROGRAMS, tmLine, length_array(tmLine), 
    		     TIMELINE_RELATIVE, TIMELINE_ONCE)
}

DEFINE_FUNCTION createTimeLineArray (long tmLine[], integer len, long milliSecs)
{
    integer i
    set_length_array(tmLine, len)
    for (i = 1; i <= len; i++)
    {
	tmLine[i] = milliSecs
    }
}

DEFINE_EVENT

TIMELINE_EVENT [HVAC_VST_TIMELINE_ID_FETCH_STATUSES]
{
    vstRequestStatus (timeline.sequence)
}

TIMELINE_EVENT [HVAC_VST_TIMELINE_ID_FETCH_PROGRAMS]
{
    integer hvacId, dayPeriod, day, period
    hvacId    = 1 + timeline.sequence / 28
    dayPeriod =     timeline.sequence % 28
    day	      =     dayPeriod / 4
    period    = 1 + dayPeriod % 4
    vstRequestProgram (hvacId, day, period)
}

DEFINE_FUNCTION vstRequestStatus (integer hvacId)
{
    // Get system status
    debug (VST_MODULE,2,"'Requesting system status for hvac: ',itoa(hvacId)")
    commSendCommand (gHvacs[hvacId].mDev, 'ST')
}

DEFINE_FUNCTION vstRequestProgram (integer hvacId, integer day, integer period)
{
    // Get a program for the given hvac/day/period combination
    debug (VST_MODULE,2,"'Requesting program for hvac=',
    	  		itoa(hvacId),', day=',itoa(day),', period=',itoa(period)")
    commSendCommand (gHvacs[hvacId].mDev, "'?PG D',itoa(day),' SP',itoa(period)")
}

DEFINE_FUNCTION hvacCommIncrHeatSetPoint (integer hvacId)
{
    commCheckUpdateMode (hvacId)
    commSendPulse (gHvacs[hvacId].mDev, HVAC_VST_CHAN_INCR_HEAT_SETPOINT)
}

DEFINE_FUNCTION hvacCommDecrHeatSetPoint (integer hvacId)
{
    commCheckUpdateMode (hvacId)
    commSendPulse (gHvacs[hvacId].mDev, HVAC_VST_CHAN_DECR_HEAT_SETPOINT)
}

DEFINE_FUNCTION hvacCommIncrCoolSetPoint (integer hvacId)
{
    commCheckUpdateMode (hvacId)
    commSendPulse (gHvacs[hvacId].mDev, HVAC_VST_CHAN_INCR_COOL_SETPOINT)
}

DEFINE_FUNCTION hvacCommDecrCoolSetPoint (integer hvacId)
{
    commCheckUpdateMode (hvacId)
    commSendPulse (gHvacs[hvacId].mDev, HVAC_VST_CHAN_INCR_COOL_SETPOINT)
}

DEFINE_FUNCTION hvacCommToggleSetHold (integer hvacId)
{
    hvacCommSystemModeSwitch (hvacId, HVAC_MODE_PERM_HOLD)
}

DEFINE_FUNCTION hvacCommSystemModeSwitch (integer hvacId, integer newMode)
{
    switch (newMode)
    {
    case HVAC_MODE_PROGRAM:
    	 commSendCommand (gHvacs[hvacId].mDev, "'MD MP'")
    case HVAC_MODE_VACATION: {}  // not supported
    case HVAC_MODE_OVERRIDE:
    	 commSendCommand (gHvacs[hvacId].mDev,
	 		  "'MD MH H',itoa(gHvacState[hvacId].mCurrSetPointHeat),
	 		   ' C',itoa(gHvacState[hvacId].mCurrSetPointCool)")
    case HVAC_MODE_PERM_HOLD:
    	 commSendCommand (gHvacs[hvacId].mDev,
	 		  "'MD MPH H',itoa(gHvacState[hvacId].mCurrSetPointHeat),
	 		   ' C',itoa(gHvacState[hvacId].mCurrSetPointCool)")
    }
    // Ask for verification of mode change
    vstRequestStatus (hvacId)
}

DEFINE_FUNCTION commCheckUpdateMode (integer hvacId)
{
    if (gHvacState[hvacId].mSystemMode = HVAC_MODE_PROGRAM)
    {
	// We allow user overrides but we need to switch to temporary hold (override) mode
        debug (VST_MODULE, 9, "'switching ViewStat ',itoa(hvacId),' to temporary Hold'")
	hvacCommSystemModeSwitch (hvacId, HVAC_MODE_OVERRIDE)
    }
}

DEFINE_FUNCTION commSendCommand (dev vstDev, char vstCommand[])
{
    debug (VST_MODULE, 9, "'sending control command to ViewStat ',devtoa(vstDev),': ',vstCommand")
    send_command vstDev, vstCommand
}

DEFINE_FUNCTION commSendPulse (dev vstDev, integer vstChan)
{
    debug (VST_MODULE, 9, "'sending control pulse to ViewStat ',devtoa(vstDev),': ',itoa(vstChan)")
    pulse [vstDev, vstChan]
}

DEFINE_START
{
    readConfigs (configFile, tpConfigFile)
    if (gGeneral.mEnabled)
    {
        wait (113) // wait 11.3 seconds after reboot to begin requesting statuses and programs
        {
	    vstRequestStatusAll()
	    wait (113) { vstRequestProgramAll() }
        }
    }
}

DEFINE_PROGRAM
{
    // Cycle through each thermostat to sync the status every 15 minutes (approx)
    wait (9227)  // 15:22.7 minutes
    {
        if (gGeneral.mEnabled)
	{
	    vstRequestStatusAll()
	}
    }
    // Cycle through each thermostat to sync the program every 4 hours (approx)
    wait (144973)  // 4:01:37.3 hours
    {
        if (gGeneral.mEnabled)
	{
	    vstRequestProgramAll()
	}
    }
}
