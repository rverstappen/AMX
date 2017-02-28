(*
 * POOL control and configuration -- independent of type of thermostat.
 *)

#if_not_defined __POOL__
#define __POOL__

DEFINE_CONSTANT

POOL_MODE_UNKNOWN	= 0
POOL_MODE_PROGRAM	= 1
POOL_MODE_VACATION	= 2
POOL_MODE_OVERRIDE	= 3
POOL_MODE_PERM_HOLD	= 4

POOL_HC_MODE_UNKNOWN	= 0
POOL_HC_MODE_OFF	= 1
POOL_HC_MODE_HEAT	= 2
POOL_HC_MODE_COOL	= 3
POOL_HC_MODE_AUTO	= 4

POOL_HC_STATUS_UNKNOWN	= 0
POOL_HC_STATUS_OFF	= 1
POOL_HC_STATUS_HEAT	= 2
POOL_HC_STATUS_COOL	= 3

POOL_HUM_MODE_UNKNOWN	= 0
POOL_HUM_MODE_AUTO	= 1
POOL_HUM_MODE_HUMIDIFY	= 2
POOL_HUM_MODE_DEHUMIDIFY= 3
POOL_HUM_MODE_OFF	= 4

POOL_PERIOD_UNKNOWN	= 0
POOL_PERIOD_WAKE	= 1
POOL_PERIOD_LEAVE	= 2
POOL_PERIOD_RETURN	= 3
POOL_PERIOD_SLEEP	= 4

POOL_TEMP_SCALE_UNKNOWN		= 0
POOL_TEMP_SCALE_FAHRENHEIT	= 1
POOL_TEMP_SCALE_CELSIUS		= 2
POOL_TEMP_STRLEN		= 16

POOL_FEATURE_OFF	= 0
POOL_FEATURE_ON		= 1


DEFINE_TYPE

structure PoolState
{
    sinteger			mAirTemp
    sinteger			mPoolTemp
    sinteger			mSpaTemp
    sinteger			mPoolSetPoint
    sinteger			mSpaSetPoint
    integer			mPoolPumpState
    integer			mSpaPumpState
    integer			mAuxStates[20]
    char			mPoolName[16]
    char			mSpaName[16]
    char			mAuxNames[16][20]
}

DEFINE_FUNCTION poolTimeString (char result[], integer minutesSinceMidnight)
{
    integer hours, minutes
    hours   = minutesSinceMidnight / 60
    minutes = minutesSinceMidnight % 60
    result = "format('%02u',hours),':',format('%02u',minutes)"
}

DEFINE_FUNCTION integer poolTimeMinutes (char timeStr[])
{
    char timeStrCopy[10]
    integer hours, minutes
    timeStrCopy = timeStr
    hours   = atoi(timeStrCopy)
    remove_string (timeStrCopy,':',1)
    minutes = atoi(timeStrCopy)
    return (60 * hours) + minutes
}

DEFINE_FUNCTION poolDayOfWeekString (char result[], integer dayOfWeek)
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

DEFINE_FUNCTION integer poolDayOfWeekInt (char dayOfWeek[])
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

DEFINE_FUNCTION poolPeriodString (char result[], integer period)
{
    switch (period)
    {
    case POOL_PERIOD_WAKE:	result = 'Wake'
    case POOL_PERIOD_LEAVE:	result = 'Leave'
    case POOL_PERIOD_RETURN:	result = 'Return'
    case POOL_PERIOD_SLEEP:	result = 'Sleep'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION integer poolPeriodInt (char period[])
{
    char periodCopy[4]
    periodCopy = lower_string (left_string(period,4))
    switch (periodCopy)
    {
    case 'wake':	return POOL_PERIOD_WAKE
    case 'leav':	return POOL_PERIOD_LEAVE
    case 'retu':	return POOL_PERIOD_RETURN
    case 'slee':	return POOL_PERIOD_SLEEP
    default:		return POOL_PERIOD_UNKNOWN
    }
}

DEFINE_FUNCTION poolSystemModeStr (char result[], integer mode)
{
    switch (mode)
    {
    case POOL_MODE_PROGRAM:	result = 'Program'
    case POOL_MODE_VACATION:	result = 'Vacation'
    case POOL_MODE_OVERRIDE:	result = 'Override'
    case POOL_MODE_PERM_HOLD:	result = 'Hold'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION integer poolSystemModeInt (char mode[])
{
    char modeCopy[4]
    modeCopy = lower_string (left_string(mode,4))
    switch (modeCopy)
    {
    case 'prog':	return POOL_MODE_PROGRAM
    case 'vaca':	return POOL_MODE_VACATION
    case 'over':	return POOL_MODE_OVERRIDE
    case 'hold':	return POOL_MODE_PERM_HOLD
    default:		return POOL_MODE_UNKNOWN
    }
}

DEFINE_FUNCTION poolHeatCoolModeStr (char result[], integer mode)
{
    switch (mode)
    {
    case POOL_HC_MODE_OFF:	result = 'Off'
    case POOL_HC_MODE_HEAT:	result = 'Heat'
    case POOL_HC_MODE_COOL:	result = 'Cool'
    case POOL_HC_MODE_AUTO:	result = 'Auto'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION integer poolHeatCoolModeInt (char mode[])
{
    char modeCopy[3]
    modeCopy = lower_string (left_string(mode,3))
    switch (modeCopy)
    {
    case 'off':	return POOL_HC_MODE_OFF
    case 'hea':	return POOL_HC_MODE_HEAT
    case 'coo':	return POOL_HC_MODE_COOL
    case 'aut':	return POOL_HC_MODE_AUTO
    default:	return POOL_HC_MODE_UNKNOWN
    }
}

DEFINE_FUNCTION poolHumidifyModeStr (char result[], integer mode)
{
    switch (mode)
    {
    case POOL_HUM_MODE_OFF:		result = 'Off'
    case POOL_HUM_MODE_DEHUMIDIFY:	result = 'Dehumidify'
    case POOL_HUM_MODE_HUMIDIFY:	result = 'Humidify'
    case POOL_HUM_MODE_AUTO:		result = 'Auto'
    default:				result = 'Unknown'
    }
}

DEFINE_FUNCTION integer poolHumidifyModeInt (char mode[])
{
    char modeCopy[3]
    modeCopy = lower_string (left_string(mode,3))
    switch (modeCopy)
    {
    case 'off':	return POOL_HUM_MODE_OFF
    case 'deh':	return POOL_HUM_MODE_DEHUMIDIFY
    case 'hum':	return POOL_HUM_MODE_HUMIDIFY
    case 'aut':	return POOL_HUM_MODE_AUTO
    default:	return POOL_HUM_MODE_UNKNOWN
    }
}

DEFINE_FUNCTION poolHeatCoolStatusStr (char result[], integer mode)
{
    switch (mode)
    {
    case POOL_HC_STATUS_OFF:	result = 'Off'
    case POOL_HC_STATUS_HEAT:	result = 'Heat'
    case POOL_HC_STATUS_COOL:	result = 'Cool'
    default:			result = 'Unknown'
    }
}

DEFINE_FUNCTION setTempStr (char result[], sinteger tempFahr, integer scale)
{
    if (scale = POOL_TEMP_SCALE_CELSIUS)
    	 result = "itoa(fahrenheit2Celsius(tempFahr)),$B0,'C'"
    else
    	 result = "itoa(tempFahr),$B0,'F'"
}

DEFINE_FUNCTION setTwoTempStr (char result[], sinteger tempFahr1, sinteger tempFahr2, integer scale)
{
    if (scale = POOL_TEMP_SCALE_CELSIUS)
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


#end_if // __POOL__
