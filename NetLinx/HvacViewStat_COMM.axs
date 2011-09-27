(*
 * This file contains all of the ViewStat specific processing.  
 *
 * It assumes access to the following variables and types:
 * - Contents of Hvac.axi
 * - The gAllHvacs array
 * - The doTpUpdateXyz() functions
 *)

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

DEFINE_VARIABLE

volatile char  VST_MODULE[] = 'HvacViewStat_COMM'
volatile dev  dvAllHvacs[MAX_HVACS]	// The list of VST devices (built at runtime)
volatile char gHvacProgramFetchStateDay   [MAX_HVACS]
volatile char gHvacProgramFetchStatePeriod[MAX_HVACS]

(*
DEFINE_EVENT

DATA_EVENT[vdvHvacControl]
{
    ONLINE:  {}
    OFFLINE: {}
    COMMAND:
    {
	debug (VST_MODULE, 5, "'received ViewStat control command from ',devtoa(data.device),': ',data.text")
	handleControlCommand (data.text)
    }
}

DEFINE_FUNCTION handleControlCommand (char cmd[])
{
}
*)


(*
 * Incoming events from the ViewStat devices are translated into generic events and passed to the UI
 * module for further handling.
 *)
DEFINE_EVENT

DATA_EVENT[dvAllHvacs]
{
    ONLINE:  { handleVstOnline  (get_last(dvAllHvacs)) }
    OFFLINE: { handleVstOffline (get_last(dvAllHvacs)) }
    COMMAND: { handleVstMessage (get_last(dvAllHvacs), data.text) }
    STRING:  { handleVstMessage (get_last(dvAllHvacs), data.text) }
}

LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_INDOOR_TEMP]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(dvAllHvacs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received indoor temperature update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
    doTpUpdateCurrTemp (hvacId, realTemp)
}

LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_INDOOR_HUMIDITY]
{
    integer  hvacId, humidity
    hvacId = get_last(dvAllHvacs)
    humidity = level.value
    debug (VST_MODULE, 6, "'received indoor humidity update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(humidity)")
    doTpUpdateCurrHumidity (hvacId, humidity)
}

LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_CURR_HEAT_SET_POINT]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(dvAllHvacs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received heat set-point update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
    doTpUpdateCurrHeatSetPoint (hvacId, realTemp)
}

LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_CURR_COOL_SET_POINT]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(dvAllHvacs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received cool set-point update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
    doTpUpdateCurrCoolSetPoint (hvacId, realTemp)
}

LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_OUTDOOR_TEMP]
{
    integer  hvacId, vsxTemp
    sinteger realTemp
    hvacId = get_last(dvAllHvacs)
    vsxTemp = level.value
    realTemp = normalizeVsxTemp(vsxTemp)
    debug (VST_MODULE, 6, "'received outdoor temperature update from device(',itoa(hvacId),') ',
    	  	       	  devtoa(level.input.device),': ',itoa(vsxTemp),'(',itoa(realTemp),')'")
//    doTpUpdateCurrOutdoorTemp (hvacId, realTemp)
}

// We're not interested in the forecasts and barometirc pressure readings
//LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_BAROMETRIC_PRESSURE] {}
//LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_HIGH_FORECAST] {}
//LEVEL_EVENT[dvAllHvacs, HVAC_VST_LEVEL_LOW_FORECAST] {}

// Channel event handling for all of the Feedback channels (commented out channels are not 
// interesting to us)
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FILTER_CHANGE]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_SPEED_1]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_SPEED_2]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_SPEED_3]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_LOCK_OUT_STATE]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_STATE_ON]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_STATE_AUTO]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_STATUS]		{}
CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_STATE_AUTO]
    { ON: { doTpSetHvacHcMode (get_last(dvAllHvacs), HVAC_HC_MODE_AUTO) } }
CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_STATE_COOL]
    { ON: { doTpSetHvacHcMode (get_last(dvAllHvacs), HVAC_HC_MODE_COOL) } }
CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_STATE_HEAT]
    { ON: { doTpSetHvacHcMode (get_last(dvAllHvacs), HVAC_HC_MODE_HEAT) } }
CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_STATE_OFF]
    { ON: { doTpSetHvacHcMode (get_last(dvAllHvacs), HVAC_HC_MODE_OFF) } }
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_STATE_EMERGENCY_HEAT]	{}
CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_COOL_STATUS]
    { ON:  { doTpSetHvacHcStatus (get_last(dvAllHvacs), HVAC_HC_STATUS_COOL) }
      OFF: { doTpSetHvacHcStatus (get_last(dvAllHvacs), HVAC_HC_STATUS_OFF) } }
CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_HEAT_STATUS]
    { ON:  { doTpSetHvacHcStatus (get_last(dvAllHvacs), HVAC_HC_STATUS_HEAT) }
      OFF: { doTpSetHvacHcStatus (get_last(dvAllHvacs), HVAC_HC_STATUS_OFF) } }
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HVAC_EMERGENCY_HEAT_STATUS]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HUMIDIFY_STATE_AUTO]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HUMIDIFY_STATE_DEHUMIDIFY]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HUMIDIFY_STATE_HUMIDIFY]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HUMIDIFY_STATE_OFF]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_DEHUMIDIFY_STATUS]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HUMIDIFY_STATUS]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_REVERSING_VALVE_COOL_RELAY]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_REVERSING_VALVE_HEAT_RELAY]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_1ST_STAGE_COMPRESSOR_RELAY]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_2ND_STAGE_COMPRESSOR_RELAY]	{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_1ST_STAGE_HEAT_RELAY]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_2ND_STAGE_HEAT_RELAY]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_DEHUMIDIFY_RELAY]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_HUMIDIFY_RELAY]		{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_RELAY_1]			{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_RELAY_2]			{}
//CHANNEL_EVENT[dvAllHvacs, HVAC_VST_CHAN_FAN_RELAY_3]			{}

CHANNEL_EVENT[dvAllHvacs, 0]
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
    debug (VST_MODULE, 2, "'VST(',devtoa(gAllHvacs[hvacId].mDev),') is ONLINE'")
    vstRequestLevels (hvacId)
}

DEFINE_FUNCTION handleVstOffline (integer hvacId)
{
    debug (VST_MODULE, 4, "'VST(',devtoa(gAllHvacs[hvacId].mDev),') is OFFLINE'")
}

DEFINE_FUNCTION handleVstMessage (integer hvacId, char msg[])
{
    integer spacePos
    char cmdStr[2], modeStr[2]
    debug (VST_MODULE, 7, "'got message from VST(',devtoa(gAllHvacs[hvacId].mDev),'): ',msg")
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
	    gAllHvacs[hvacId].mDailySchedules[day][period].mHeatTemp = atoi(msg)
	    remove_string (msg, ' C', 1)
	    gAllHvacs[hvacId].mDailySchedules[day][period].mCoolTemp = atoi(msg)
	    remove_string (msg, ' HM', 1)
	    gAllHvacs[hvacId].mDailySchedules[day][period].mHumidify = atoi(msg)
	    remove_string (msg, ' DM', 1)
	    gAllHvacs[hvacId].mDailySchedules[day][period].mDehumidify = atoi(msg)
	    remove_string (msg, ' T', 1)
	    time24hr = atoi(msg)
	    gAllHvacs[hvacId].mDailySchedules[day][period].mMinutes =
							 (60 * (time24hr/100)) + (time24hr%100)
	    vstRequestNextProgram (hvacId)
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
	    gAllHvacs[hvacId].mFixedSetPointHeat = atoi(msg)
	}
	if (find_string (msg, ' C', 1))
	{
	    remove_string (msg, ' C', 1)
	    gAllHvacs[hvacId].mFixedSetPointCool = atoi(msg)
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
    commSendCommand (gAllHvacs[hvacId].mDev, 'LEVON')
}

DEFINE_FUNCTION vstRequestProgram (integer hvacId)
{
    // Get system status
    commSendCommand (gAllHvacs[hvacId].mDev, 'ST')

    // Get the first program (Sunday, Wake)
    gHvacProgramFetchStateDay[hvacId] = 0		// Sunday
    gHvacProgramFetchStatePeriod[hvacId] = 1	// Wake
    commSendCommand (gAllHvacs[hvacId].mDev, '?PG D0 SP1')
}

DEFINE_FUNCTION vstRequestNextProgram (integer hvacId)
{
    if ((gHvacProgramFetchStateDay[hvacId] >= 6) && (gHvacProgramFetchStatePeriod[hvacId] >= 4))
    {
	debug (VST_MODULE, 4, "'Completed program fetching for HVAC ',itoa(hvacId)")
	return
    }
    debug (VST_MODULE, 9, "'Setting timer to fetch more programming for HVAC ',itoa(hvacId)")
    wait 13  // 1.3 secs to space things out a bit
    {
	if (gHvacProgramFetchStatePeriod[hvacId] < 4)
	{
	    gHvacProgramFetchStatePeriod[hvacId]++
	}
	else
	{
	    gHvacProgramFetchStateDay[hvacId]++
	    gHvacProgramFetchStatePeriod[hvacId] = 1
	}
	commSendCommand (gAllHvacs[hvacId].mDev, "'?PG D',itoa(gHvacProgramFetchStateDay[hvacId]),
						 ' SP',itoa(gHvacProgramFetchStatePeriod[hvacId])")
    }
}

DEFINE_FUNCTION vstRequestProgramFromNextHvac()
{
    local_var integer hvacId
    hvacId++
    if (hvacId > length_array(gAllHvacs))
    {
	hvacId = 1
    }
    vstRequestProgram (hvacId)
}

DEFINE_FUNCTION hvacCommIncrHeatSetPoint (HvacType hvac)
{
    commCheckUpdateMode (hvac)
    commSendPulse (hvac.mDev, HVAC_VST_CHAN_INCR_HEAT_SETPOINT)
}

DEFINE_FUNCTION hvacCommDecrHeatSetPoint (HvacType hvac)
{
    commCheckUpdateMode (hvac)
    commSendPulse (hvac.mDev, HVAC_VST_CHAN_DECR_HEAT_SETPOINT)
}

DEFINE_FUNCTION hvacCommIncrCoolSetPoint (HvacType hvac)
{
    commCheckUpdateMode (hvac)
    commSendPulse (hvac.mDev, HVAC_VST_CHAN_INCR_COOL_SETPOINT)
}

DEFINE_FUNCTION hvacCommDecrCoolSetPoint (HvacType hvac)
{
    commCheckUpdateMode (hvac)
    commSendPulse (hvac.mDev, HVAC_VST_CHAN_INCR_COOL_SETPOINT)
}

DEFINE_FUNCTION hvacCommSystemModeSwitch (HvacType hvac, integer newMode)
{
    switch (newMode)
    {
    case HVAC_MODE_PROGRAM:
    	 commSendCommand (hvac.mDev, "'MD MP'")
    case HVAC_MODE_VACATION: {}  // not supported
    case HVAC_MODE_OVERRIDE:
    	 commSendCommand (hvac.mDev, "'MD MH H',itoa(hvac.mCurrSetPointHeat),
	 		 	     	   ' C',itoa(hvac.mCurrSetPointCool)")
    case HVAC_MODE_PERM_HOLD:
    	 commSendCommand (hvac.mDev, "'MD MPH'")
    }
}

DEFINE_FUNCTION commCheckUpdateMode (HvacType hvac)
{
    if (hvac.mSystemMode = HVAC_MODE_PROGRAM)
    {
	// We allow user overrides but we need to switch to temporary hold (override) mode
        debug (VST_MODULE, 9, "'switching ViewStat ',itoa(hvac.mId),' to temporary Hold'")
	hvacCommSystemModeSwitch (hvac, HVAC_MODE_OVERRIDE)
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
    // Enclosing in a block reduces the scope of the rebuild_event()
    hvacSetDeviceList (dvAllHvacs, gAllHvacs)
    rebuild_event()
    wait (113) // wait 11.3 seconds to begin requesting programs
    {
	vstRequestProgramFromNextHvac()
    }
}

DEFINE_PROGRAM
{
    // Cycle through each thermostat to sync the program with it; starting a new one every 5-ish minutes
    wait (3227)  // 5:22.7 minutes
    {
	vstRequestProgramFromNextHvac()
    }
}
