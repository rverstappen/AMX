(*
 * HVAC control and configuration -- independent of type of thermostat.
 *)

#if_not_defined __HVAC__
#define __HVAC__

#include 'Debug.axi'

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

structure HvacType
{
    integer			mId
    char			mName[32]
    dev				mDev
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

DEFINE_FUNCTION hvacReadSettings (HvacType hvacs[], char fileName[])
{
    char lineStr[256]
//    char propStr[64]
    char dayStr[3]
    char timeStr[5]
    char periodStr[8]
    slong fd, result
    integer hvacId, dayId, periodId
    integer space

    debug ('HVAC',3,"'Reading HVAC device configuration from file: ',fileName")
    fd = file_open (fileName, FILE_READ_ONLY)
    if (fd < 0)
    {
	debug ('HVAC',0,"'Error opening file for reading (',fileName,'): ',itoa(result)")
	return
    }

    for (result = file_read_line (fd, lineStr, 256);
    	 result >= 0;
	 result = file_read_line (fd, lineStr, 256))
    {
	{
	    // Handle each line as we encounter it
	    select
	    {
	    active (find_string(lineStr,'PERIOD=',1)):
	    {
		remove_string(lineStr,'PERIOD=',1)
		periodId = hvacPeriodInt (lineStr)
		if (find_string(lineStr,'TIME=',1))
		{
		    remove_string(lineStr,'TIME=',1)
		    hvacs[hvacId].mDailySchedules[dayId][periodId].mMinutes = hvacTimeMinutes(lineStr)
		}
		if (find_string(lineStr,'HEAT_TEMP=',1))
		{
		    remove_string(lineStr,'HEAT_TEMP=',1)
		    hvacs[hvacId].mDailySchedules[dayId][periodId].mHeatTemp = atoi(lineStr)
		}
		if (find_string(lineStr,'COOL_TEMP=',1))
		{
		    remove_string(lineStr,'COOL_TEMP=',1)
		    hvacs[hvacId].mDailySchedules[dayId][periodId].mCoolTemp = atoi(lineStr)
		}
		if (find_string(lineStr,'DEHUMIDIFY=',1))
		{
		    // put DEHUMIDIFY_SP before HUMIDIFY_SP, otherwise it won't be found
		    remove_string(lineStr,'DEHUMIDIFY=',1)
		    hvacs[hvacId].mDailySchedules[dayId][periodId].mDehumidify = atoi(lineStr)
		} // active
	    	if (find_string(lineStr,'HUMIDIFY=',1))
		{
		    remove_string(lineStr,'HUMIDIFY=',1)
		    hvacs[hvacId].mDailySchedules[dayId][periodId].mHumidify = atoi(lineStr)
		}
	    } // active

	    active (find_string(lineStr,'ID=',1)):
	    {
		remove_string(lineStr,'ID=',1)
		hvacId = atoi(lineStr)
		if (length_array(hvacs) < hvacId)
		    set_length_array(hvacs,hvacId)
		hvacs[hvacId].mId = hvacId
		set_length_array(hvacs[hvacId].mDailySchedules,7)
		if (find_string(lineStr,'NAME=',1))
		{
		    remove_string(lineStr,'NAME=',1)
		    hvacs[hvacId].mName = left_string(lineStr,find_string(lineStr,' DEV=',1))
		}
		if (find_string(lineStr,'DEV=',1))
		{
		    remove_string(lineStr,'DEV=',1)
		    parseDev (hvacs[hvacId].mDev, lineStr)
		}
	    	if (find_string(lineStr,'SYS_MODE=',1))
		{
		    remove_string(lineStr,'SYS_MODE=',1)
		    hvacs[hvacId].mSystemMode = hvacSystemModeInt(lineStr)
		}
		if (find_string(lineStr,'HC_MODE=',1))
		{
		    remove_string(lineStr,'HC_MODE=',1)
		    hvacs[hvacId].mHeatCoolMode = hvacHeatCoolModeInt(lineStr)
		}
		if (find_string(lineStr,'HUM_MODE=',1))
		{
		    remove_string(lineStr,'HUM_MODE=',1)
		    hvacs[hvacId].mHumidifyMode = hvacHumidifyModeInt(lineStr)
		}
	    }
	    active (find_string(lineStr,'HEAT_SP=',1)):
	    {
		remove_string(lineStr,'HEAT_SP=',1)
		hvacs[hvacId].mFixedSetPointHeat = atoi(lineStr)
		if (find_string(lineStr,'COOL_SP=',1))
		{
		    remove_string(lineStr,'COOL_SP=',1)
		    hvacs[hvacId].mFixedSetPointCool = atoi(lineStr)
		}
		if (find_string(lineStr,'HUMIDIFY_SP=',1))
		{
		    remove_string(lineStr,'HUMIDIFY_SP=',1)
		    hvacs[hvacId].mFixedSetPointHumidify = atoi(lineStr)
		}
		if (find_string(lineStr,'DEHUMIDIFY_SP=',1))
		{
		    // put DEHUMIDIFY_SP before HUMIDIFY_SP, otherwise it won't be found
		    remove_string(lineStr,'DEHUMIDIFY_SP=',1)
		    hvacs[hvacId].mFixedSetPointDehumidify = atoi(lineStr)
		}
	    }
	    active (find_string(lineStr,'DAY=',1)):
	    {
		remove_string(lineStr,'DAY=',1)
		dayId = hvacDayOfWeekInt (lineStr)
		set_length_array(hvacs[hvacId].mDailySchedules[dayId],4)
	    } // active
	    } // select
	} // while
    } // for

    if (result != -9)  // if not EOF
    {
	debug ('HVAC',0,"'Error reading file (',fileName,'): ',itoa(result)") 
    }
    file_close (fd)
    debug ('HVAC',3,"'Finished reading ',itoa(length_array(hvacs)),
    	  	     ' HVAC device configurations from file: ',fileName")
}

DEFINE_FUNCTION hvacSaveSettings (HvacType hvac[], char fileName[])
{
    // It is safer to write to a tmp file and move it than to overwrite the file...
    char tmpFileName[100]
    char tmpFileName2[100]
    char lineStr[256]
    char modeStr[8]
    char dayStr[3]
    char timeStr[5]
    char periodStr[8]
    slong fd, result
    integer hvacId, dayId, periodId

    debug ('HVAC',3,"'Saving ',itoa(length_array(hvac)),' HVAC device configurations to file: ',fileName")
    tmpFileName  = "fileName,'.tmp'"
    tmpFileName2 = "fileName,'.prev'"
    fd = file_open (tmpFileName, FILE_RW_NEW)
    if (fd < 0)
    {
	debug ('HVAC',0,"'Error opening file for writing (',tmpFileName,'): ',itoa(result)")
	return
    }

    result = 0
    for (hvacId = 1; (result >= 0) && (hvacId <= length_array(hvac)); hvacId++)
    {
	lineStr = "'ID=', itoa(hvac[hvacId].mId)"
	hvacSystemModeStr (modeStr, hvac[hvacId].mSystemMode)
	lineStr = "lineStr,' SYS_MODE=', modeStr"
	hvacHeatCoolModeStr (modeStr, hvac[hvacId].mHeatCoolMode)
	lineStr = "lineStr,' HC_MODE=', modeStr"
	hvacHumidifyModeStr (modeStr, hvac[hvacId].mHumidifyMode)
	lineStr = "lineStr,' HUM_MODE=', modeStr"
	result = file_write_line (fd, lineStr, length_array(lineStr))
	lineStr = "'  HEAT_SP=',		itoa(hvac[hvacId].mFixedSetPointHeat)"
	lineStr = "lineStr,'  COOL_SP=',	itoa(hvac[hvacId].mFixedSetPointCool)"
	lineStr = "lineStr,'  HUMIDIFY_SP=',	itoa(hvac[hvacId].mFixedSetPointHumidify)"
	lineStr = "lineStr,'  DEHUMIDIFY_SP=',	itoa(hvac[hvacId].mFixedSetPointDehumidify)"
	result = file_write_line (fd, lineStr, length_array(lineStr))
	for (dayId = 1; (result >= 0) && (dayId <= 7); dayId++)
	{
	    hvacDayOfWeekString (dayStr, dayId)
	    lineStr = "'  DAY=',dayStr"
	    result = file_write_line (fd, lineStr, length_array(lineStr))
	    for (periodId = 1; (result >= 0) && (periodId <= 4); periodId++)
	    {
		hvacPeriodString (periodStr, periodId)
		hvacTimeString (timeStr, hvac[hvacId].mDailySchedules[dayId][periodId].mMinutes)
		lineStr = "'    PERIOD=',periodStr"
		lineStr = "lineStr,' TIME=', timeStr"
		lineStr = "lineStr,' HEAT_TEMP=',
			  itoa(hvac[hvacId].mDailySchedules[dayId][periodId].mHeatTemp)"
		lineStr = "lineStr,' COOL_TEMP=',
			  itoa(hvac[hvacId].mDailySchedules[dayId][periodId].mCoolTemp)"
		lineStr = "lineStr,' HUMIDIFY=',
			  itoa(hvac[hvacId].mDailySchedules[dayId][periodId].mHumidify)"
		lineStr = "lineStr,' DEHUMIDIFY=',
			  itoa(hvac[hvacId].mDailySchedules[dayId][periodId].mDehumidify)"
		result = file_write_line (fd, lineStr, length_array(lineStr))
	    }
	}
    }
    if (result < 0)
    {
	debug ('HVAC',0,"'Error writing file (',tmpFileName,'): ',itoa(result)") 
    }

    file_close (fd)
    result  = file_rename (fileName, tmpFileName2)
    if (result >= 0)
    {
	// move new file in place and remote the old file
	result = file_rename (tmpFileName, fileName)
	file_delete (tmpFileName2)
    }
    else
    {
	// try to put the original file back!
	file_rename (tmpFileName2, fileName)
    }
    if (result < 0)
    {
	debug ('HVAC',0,"'Error renaming file (',tmpFileName,'->',fileName,'): ',itoa(result)") 
    }
}

DEFINE_FUNCTION hvacSetDeviceList (dev dvList[], HvacType hvacs[])
{
    integer i
    set_length_array (dvList, length_array(hvacs))
    for (i = 1; i <= length_array(hvacs); i++)
    {
	dvList[i] = hvacs[i].mDev
    }
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

(*
DEFINE_FUNCTION hvacCheckSetPoint (HvacType hvac)
{
    sinteger setPoint
    switch (hvac.mSystemMode)
    {
    case HVAC_MODE_PROGRAM:
    {
	switch (hvac.mCurrentPeriod)
	{
	case HVAC_PERIOD_WAKE:		setPoint = hvac.mDailySchedules[
	}
    }
    }
}
*)

DEFINE_FUNCTION sinteger getHcSetPoint (HvacType hvac)
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

DEFINE_FUNCTION setHcSetPointStr (char result[], HvacType hvac, integer scale)
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

DEFINE_FUNCTION parseDev (dev result, char propValue[])
{
    integer  colon1, colon2
    colon1 = find_string (propValue, ':',1)
    if (colon1)
    {
	colon2 = find_string (propValue, ':', colon1+1)
	if (colon2)
	{
	    result.Number = atoi(propValue)
	    result.Port   = atoi(right_string(propValue,length_array(propValue)-colon1+1))
	    result.System = atoi(right_string(propValue,length_array(propValue)-colon2+1))
	    return
	}
    }
    debug ('HVAC',1,"'ConfigBase::parseDev(): Error processing DEV string: ',propValue")
}

#end_if // __HVAC__
