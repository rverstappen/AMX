(*
 * HVAC control and configuration -- independent of type of thermostat.
 *)

#if_not_defined __HVAC__
#define __HVAC__

DEFINE_CONSTANT

MAX_HVACS = 32

HVAC_MODE_UNKNOWN	= 0
HVAC_MODE_PROGRAM	= 1
HVAC_MODE_VACATION	= 2
HVAC_MODE_OVERRIDE	= 3
HVAC_MODE_PERM_HOLD	= 4

HVAC_HC_MODE_UNKNOWN	= 0
HVAC_HC_MODE_OFF	= 1
HVAC_HC_MODE_HEAT	= 2
HVAC_HC_MODE_COOL	= 3
HVAC_HC_MODE_AUTO	= 4

HVAC_HC_STATUS_UNKNOWN	= 0
HVAC_HC_STATUS_OFF	= 1
HVAC_HC_STATUS_HEAT	= 2
HVAC_HC_STATUS_COOL	= 3

HVAC_HUM_MODE_UNKNOWN	= 0
HVAC_HUM_MODE_AUTO	= 1
HVAC_HUM_MODE_HUMIDIFY	= 2
HVAC_HUM_MODE_DEHUMIDIFY= 3
HVAC_HUM_MODE_OFF	= 4

HVAC_PERIOD_UNKNOWN	= 0
HVAC_PERIOD_WAKE	= 1
HVAC_PERIOD_LEAVE	= 2
HVAC_PERIOD_RETURN	= 3
HVAC_PERIOD_SLEEP	= 4

HVAC_TEMP_SCALE_UNKNOWN		= 0
HVAC_TEMP_SCALE_FAHRENHEIT	= 1
HVAC_TEMP_SCALE_CELSIUS		= 2

HVAC_TEMP_STRLEN	= 16

DEFINE_TYPE

structure HvacSchedPeriod
{
    integer	mMinutes	// minutes since midnight
    sinteger	mHeatTemp
    sinteger	mCoolTemp
    integer	mHumidify
    integer	mDehumidify
}

structure HvacState
{
    sinteger			mCurrTemp
    integer			mCurrHumidity
    sinteger			mCurrSetPointHeat
    sinteger			mCurrSetPointCool
    integer			mCurrSetPointHumidify
    integer			mCurrSetPointDehumidify
    integer			mCurrentPeriod			// if running in Program mode
    sinteger			mFixedSetPointHeat
    sinteger			mFixedSetPointCool
    integer			mFixedSetPointHumidify
    integer			mFixedSetPointDehumidify
//    integer			mFanSpeed
//    integer			mFanStatus
    integer			mSystemMode
    integer			mHeatCoolMode
    integer			mHumidifyMode
//    integer			mEmergencyHeatMode
    integer			mHeatCoolStatus
//    integer			mEmergencyHeatStatus
    integer			mDehumidifyStatus
    integer			mHumidifyStatus
    integer			mHoldStatus
    HvacSchedPeriod		mDailySchedules[7][4]
}

DEFINE_FUNCTION hvacTimeString (char result[], integer minutesSinceMidnight)
{
    integer hours, minutes
    hours   = minutesSinceMidnight / 60
    minutes = minutesSinceMidnight % 60
    result = "format('%02u',hours),':',format('%02u',minutes)"
}

DEFINE_FUNCTION integer hvacTimeMinutes (char timeStr[])
{
    char timeStrCopy[10]
    integer hours, minutes
    timeStrCopy = timeStr
    hours   = atoi(timeStrCopy)
    remove_string (timeStrCopy,':',1)
    minutes = atoi(timeStrCopy)
    return (60 * hours) + minutes
}

DEFINE_FUNCTION hvacDayOfWeekString (char result[], integer dayOfWeek)
{
    switch (dayOfWeek)
    {
    case 1:	result = 'Sun'
    case 2:	result = 'Mon'
    case 3:	result = 'Tue'
    case 4:	result = 'Wed'
    case 5:	result = 'Thu'
    case 6:	result = 'Fri'
    case 7:	result = 'Sat'
    default:	result = 'Unk'
    }
}

DEFINE_FUNCTION integer hvacDayOfWeekInt (char dayOfWeek[])
{
    char dayOfWeekCopy[3]
    dayOfWeekCopy = lower_string (left_string(dayOfWeek,3))
    switch (dayOfWeekCopy)
    {
    case 'sun':	return 1
    case 'mon':	return 2
    case 'tue':	return 3
    case 'wed':	return 4
    case 'thu':	return 5
    case 'fri':	return 6
    case 'sat':	return 7
    default:	return 0
    }
}

DEFINE_FUNCTION hvacPeriodString (char result[], integer period)
{
    switch (period)
    {
    case HVAC_PERIOD_WAKE:	result = 'Wake'
    case HVAC_PERIOD_LEAVE:	result = 'Leave'
    case HVAC_PERIOD_RETURN:	result = 'Return'
    case HVAC_PERIOD_SLEEP:	result = 'Sleep'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION integer hvacPeriodInt (char period[])
{
    char periodCopy[4]
    periodCopy = lower_string (left_string(period,4))
    switch (periodCopy)
    {
    case 'wake':	return HVAC_PERIOD_WAKE
    case 'leav':	return HVAC_PERIOD_LEAVE
    case 'retu':	return HVAC_PERIOD_RETURN
    case 'slee':	return HVAC_PERIOD_SLEEP
    default:		return HVAC_PERIOD_UNKNOWN
    }
}

DEFINE_FUNCTION hvacSystemModeStr (char result[], integer mode)
{
    switch (mode)
    {
    case HVAC_MODE_PROGRAM:	result = 'Program'
    case HVAC_MODE_VACATION:	result = 'Vacation'
    case HVAC_MODE_OVERRIDE:	result = 'Override'
    case HVAC_MODE_PERM_HOLD:	result = 'Hold'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION integer hvacSystemModeInt (char mode[])
{
    char modeCopy[4]
    modeCopy = lower_string (left_string(mode,4))
    switch (modeCopy)
    {
    case 'prog':	return HVAC_MODE_PROGRAM
    case 'vaca':	return HVAC_MODE_VACATION
    case 'over':	return HVAC_MODE_OVERRIDE
    case 'hold':	return HVAC_MODE_PERM_HOLD
    default:		return HVAC_MODE_UNKNOWN
    }
}

DEFINE_FUNCTION hvacHeatCoolModeStr (char result[], integer mode)
{
    switch (mode)
    {
    case HVAC_HC_MODE_OFF:	result = 'Off'
    case HVAC_HC_MODE_HEAT:	result = 'Heat'
    case HVAC_HC_MODE_COOL:	result = 'Cool'
    case HVAC_HC_MODE_AUTO:	result = 'Auto'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION integer hvacHeatCoolModeInt (char mode[])
{
    char modeCopy[3]
    modeCopy = lower_string (left_string(mode,3))
    switch (modeCopy)
    {
    case 'off':	return HVAC_HC_MODE_OFF
    case 'hea':	return HVAC_HC_MODE_HEAT
    case 'coo':	return HVAC_HC_MODE_COOL
    case 'aut':	return HVAC_HC_MODE_AUTO
    default:	return HVAC_HC_MODE_UNKNOWN
    }
}

DEFINE_FUNCTION hvacHumidifyModeStr (char result[], integer mode)
{
    switch (mode)
    {
    case HVAC_HUM_MODE_OFF:		result = 'Off'
    case HVAC_HUM_MODE_DEHUMIDIFY:	result = 'Dehumidify'
    case HVAC_HUM_MODE_HUMIDIFY:	result = 'Humidify'
    case HVAC_HUM_MODE_AUTO:		result = 'Auto'
    default:				result = 'Unknown'
    }
}

DEFINE_FUNCTION integer hvacHumidifyModeInt (char mode[])
{
    char modeCopy[3]
    modeCopy = lower_string (left_string(mode,3))
    switch (modeCopy)
    {
    case 'off':	return HVAC_HUM_MODE_OFF
    case 'deh':	return HVAC_HUM_MODE_DEHUMIDIFY
    case 'hum':	return HVAC_HUM_MODE_HUMIDIFY
    case 'aut':	return HVAC_HUM_MODE_AUTO
    default:	return HVAC_HUM_MODE_UNKNOWN
    }
}

DEFINE_FUNCTION hvacHeatCoolStatusStr (char result[], integer mode)
{
    switch (mode)
    {
    case HVAC_HC_STATUS_OFF:	result = 'Off'
    case HVAC_HC_STATUS_HEAT:	result = 'Heat'
    case HVAC_HC_STATUS_COOL:	result = 'Cool'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION sinteger getHcSetPoint (HvacState hvac)
{
    switch (hvac.mHeatCoolStatus)
    {
    case HVAC_HC_STATUS_COOL:
	return hvac.mCurrSetPointCool
    case HVAC_HC_STATUS_HEAT:
	return hvac.mCurrSetPointHeat
    default:
	return hvac.mCurrSetPointHeat  // should probably do this differently...
    }
}

DEFINE_FUNCTION setHcSetPointStr (char result[], HvacState hvac, integer scale)
{
    // Ususally either the heating *or* cooling setpoint is active, but if the thermostat mode is
    // 'auto', we suppose they could both be active(?)
    switch (hvac.mHeatCoolStatus)
    {
    case HVAC_HC_STATUS_COOL:
	setTempStr (result, hvac.mCurrSetPointCool, scale)
    case HVAC_HC_STATUS_HEAT:
	setTempStr (result, hvac.mCurrSetPointHeat, scale)
    default:
    {
	// Check what the H/C mode is
	switch (hvac.mHeatCoolMode)
	{
	case HVAC_HC_MODE_COOL:
	    setTempStr (result, hvac.mCurrSetPointCool, scale)
	case HVAC_HC_MODE_HEAT:
	    setTempStr (result, hvac.mCurrSetPointHeat, scale)
	case HVAC_HC_MODE_AUTO:
	    // Put both setpoints in the string?
	    setTwoTempStr (result, hvac.mCurrSetPointHeat, hvac.mCurrSetPointHeat, scale)
	case HVAC_HC_MODE_OFF:
	    result = 'Off'
	default:
	    result = '?'
	} // inner switch
    } // default
    } // switch
}

DEFINE_FUNCTION setTempStr (char result[], sinteger tempFahr, integer scale)
{
    if (scale = HVAC_TEMP_SCALE_CELSIUS)
    	 result = "itoa(fahrenheit2Celsius(tempFahr)),$B0,'C'"
    else
    	 result = "itoa(tempFahr),$B0,'F'"
}

DEFINE_FUNCTION setTwoTempStr (char result[], sinteger tempFahr1, sinteger tempFahr2, integer scale)
{
    if (scale = HVAC_TEMP_SCALE_CELSIUS)
    	 result = "itoa(fahrenheit2Celsius(tempFahr1)),' / ',itoa(fahrenheit2Celsius(tempFahr2)),$B0,'C'"
    else
    	 result = "itoa(tempFahr1),' / ',itoa(tempFahr2),$B0,'F'"
}

DEFINE_FUNCTION sinteger fahrenheit2Celsius (sinteger degFahr)
{
    return (((degFahr-32) * 5) / 9)
}

DEFINE_FUNCTION sinteger celsius2Fahrenheit (sinteger degCels)
{
    return (((degCels*9) / 5) + 32)
}


#end_if // __HVAC__
