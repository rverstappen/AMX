(*
 * This module is intended to be included as part of an AMX NetLinx implementation of thermostat control
 * with no dependency on the actual thermostats being used. We only deal with the generic definitions in
 * Hvac.axi and HvacTpChanDefs.axi.
 *)

#include 'Hvac.axi'
#include 'HvacTpChanDefs.axi'
#include 'TouchPanelConfig.axi'

DEFINE_VARIABLE

volatile char DBG_MODULE[] = 'Hvac'

volatile   TouchPanel	    gPanels[TP_MAX_PANELS]
volatile   dev		    gDvTpControl[TP_MAX_PANELS]	// Individual HVAC display/control
volatile   dev		    gDvTpSummary[TP_MAX_PANELS]	// Summary of all HVAC thermostats
volatile   integer 	    gTpStatus[TP_MAX_PANELS]
volatile   integer	    gTpHvacSelect[TP_MAX_PANELS]
persistent integer	    gTpPrefScale[TP_MAX_PANELS]

volatile   HvacState	    gHvacState[MAX_HVACS]


DEFINE_EVENT


(*
 * Control events from the UI are translated into events to send to the COMM module.
 *)
DEFINE_EVENT

BUTTON_EVENT[gDvTpControl,HVAC_CHAN_CTL_HEAT_SET_POINT_INCR]
BUTTON_EVENT[gDvTpControl,HVAC_CHAN_CTL_HEAT_SET_POINT_DECR]
BUTTON_EVENT[gDvTpControl,HVAC_CHAN_CTL_COOL_SET_POINT_INCR]
BUTTON_EVENT[gDvTpControl,HVAC_CHAN_CTL_COOL_SET_POINT_DECR]
{
    PUSH:
    {
	integer hvacId
	hvacId = gTpHvacSelect[get_last(gDvTpControl)]
	if (hvacId > 0)
	{
	    switch (button.input.channel)
	    {
	    case HVAC_CHAN_CTL_HEAT_SET_POINT_INCR: hvacCommIncrHeatSetPoint(hvacId)
	    case HVAC_CHAN_CTL_HEAT_SET_POINT_DECR: hvacCommDecrHeatSetPoint(hvacId)
	    case HVAC_CHAN_CTL_COOL_SET_POINT_INCR: hvacCommIncrCoolSetPoint(hvacId)
	    case HVAC_CHAN_CTL_COOL_SET_POINT_DECR: hvacCommDecrCoolSetPoint(hvacId)
	    }
	}
    }
}

BUTTON_EVENT[gDvTpControl,HVAC_CHAN_CTL_THERMOSTAT_MODE_HOLD_TOGGLE]
{
    PUSH:
    {
	integer hvacId
	hvacId = gTpHvacSelect[get_last(gDvTpControl)]
	if (hvacId > 0)
	{
	    if (gHvacState[hvacId].mSystemMode = HVAC_MODE_PERM_HOLD)
		hvacCommSystemModeSwitch (hvacId, HVAC_MODE_PROGRAM)
	    else
		hvacCommSystemModeSwitch (hvacId, HVAC_MODE_PERM_HOLD)
	    // The COMM module should tell us when the mode change has been successful
	}
    }
}

BUTTON_EVENT[gDvTpSummary,0]
{
    PUSH:
    {
	gTpHvacSelect[get_last(gDvTpSummary)] = button.input.channel
	doTpRefreshControl (get_last(gDvTpSummary))
    }
}

DATA_EVENT[gDvTpSummary]
{
    ONLINE:  { doTpConnected (get_last(gDvTpSummary)) }
    OFFLINE: { doTpDisconnected (get_last(gDvTpSummary)) }
    COMMAND: {}
}

DEFINE_FUNCTION doTpConnected (integer tpId)
{
    // TP was just (re)connected. Refresh the current summary state and the state of the device selected
    // for full control.  Since this module is not really a high priority, we will wait a few seconds 
    // before sending the refresh so as not to compete with other, more important, modules.
    gTpStatus[tpId] = 1
    wait 13 // 1.3 seconds
    {
	if (gTpStatus[tpId])  // maybe it disconnected changed during the wait
	{
	    doTpRefreshControl (tpId)
	    doTpRefreshSummary (tpId)
	}
    }
}

DEFINE_FUNCTION doTpDisconnected (integer tpId)
{
    gTpStatus[tpId] = 0
}

DEFINE_FUNCTION doTpRefreshSummary (integer tpId)
{
    integer  hvacId, hcStatusButtonState, hcModeButtonState
    char     currTempStr[HVAC_TEMP_STRLEN]
    char     heatSetPointStr[HVAC_TEMP_STRLEN]
    char     coolSetPointStr[HVAC_TEMP_STRLEN]
    debug (DBG_MODULE, 5, "'refreshing TP summary for TP: ',itoa(tpId)")
    for (hvacId = 1; hvacId <= length_array(gHvacs); hvacId++)
    {
	setTempStr (currTempStr,   	 gHvacState[hvacId].mCurrTemp,		gTpPrefScale[tpId])
	setTempStr (heatSetPointStr,	 gHvacState[hvacId].mCurrSetPointHeat,	gTpPrefScale[tpId])
	setTempStr (coolSetPointStr,	 gHvacState[hvacId].mCurrSetPointHeat,	gTpPrefScale[tpId])
	if (gPanels[tpId].mSize = TP_SIZE_SMALL)
	    send_command gDvTpSummary, "'TEXT',HVAC_ADDRESS_TITLE[hvacId],'-',	gHvacs[hvacId].mShortName"
	else
	    send_command gDvTpSummary, "'TEXT',HVAC_ADDRESS_TITLE[hvacId],'-',	gHvacs[hvacId].mName"
	send_command gDvTpSummary, "'TEXT',HVAC_ADDRESS_CURR_TEMP[hvacId],'-',	currTempStr"
	send_command gDvTpSummary, "'TEXT',HVAC_ADDRESS_HEAT_SET_POINT[hvacId],'-',heatSetPointStr"
	send_command gDvTpSummary, "'TEXT',HVAC_ADDRESS_COOL_SET_POINT[hvacId],'-',coolSetPointStr"
	send_command gDvTpSummary, "'TEXT',HVAC_ADDRESS_CURR_HUMIDITY[hvacId],'-',itoa(gHvacState[hvacId].mCurrHumidity),'%'"
	// Send button status to multi-state buttons
	hcStatusButtonState = getHcStatusButtonState (gHvacState[hvacId])
	send_command gDvTpSummary, "'^ANI-',HVAC_ADDRESS_CURR_TEMP[hvacId],',',
		     		  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
    }
}

DEFINE_FUNCTION doTpRefreshControl (integer tpId)
{
    integer  hvacId, sysModeButtonState, hcStatusButtonState, hcModeButtonState
    char     currTempStr[HVAC_TEMP_STRLEN]
    char     currHumStr[HVAC_TEMP_STRLEN]
    char     sysModeStr[12]
    char     hcModeStr[12]
    char     hcStatusStr[12]
    char     heatSetPointStr[HVAC_TEMP_STRLEN]
    char     coolSetPointStr[HVAC_TEMP_STRLEN]
    hvacId = gTpHvacSelect[tpId]
    debug (DBG_MODULE, 5, "'refreshing TP control for TP: ',itoa(tpId),'; HVAC=',itoa(hvacId)")
    if (hvacId > 0)
    {
	currHumStr = "itoa(gHvacState[hvacId].mCurrHumidity),'%'"
	sysModeButtonState  = getSysModeButtonState  (gHvacState[hvacId])
	hcModeButtonState   = getHcModeButtonState   (gHvacState[hvacId])
	hcStatusButtonState = getHcStatusButtonState (gHvacState[hvacId])
	hvacSystemModeStr     (sysModeStr,  gHvacState[hvacId].mSystemMode)
	hvacHeatCoolModeStr   (hcModeStr,   gHvacState[hvacId].mHeatCoolMode)
	hvacHeatCoolStatusStr (hcStatusStr, gHvacState[hvacId].mHeatCoolStatus)
	setTempStr (currTempStr,   	 gHvacState[hvacId].mCurrTemp,		gTpPrefScale[tpId])
	setTempStr (heatSetPointStr,   	 gHvacState[hvacId].mCurrSetPointHeat,	gTpPrefScale[tpId])
	setTempStr (coolSetPointStr,   	 gHvacState[hvacId].mCurrSetPointCool,	gTpPrefScale[tpId])
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_TITLE,'-',		gHvacs[hvacId].mName"
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_CURR_TEMP,'-',	currTempStr"
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_CURR_HUMIDITY,'-',	currHumStr"
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HEAT_SET_POINT,'-',	heatSetPointStr"
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_COOL_SET_POINT,'-',	coolSetPointStr"
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_SYSTEM_MODE,'-',	sysModeStr"
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_STATUS,'-',	hcStatusStr"
	send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_MODE,'-',	hcModeStr"
	send_command gDvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_CURR_TEMP,',',
				  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	send_command gDvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HEAT_SET_POINT,',',
				  itoa(hcModeButtonState),',',itoa(hcModeButtonState)"
	send_command gDvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_SYSTEM_MODE_ICON,',',
				      itoa(sysModeButtonState),',',itoa(sysModeButtonState)"
	send_command gDvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HC_STATUS_ICON,',',
				  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	// Update the 'Hold' toggle button
    	[gDvTpControl[tpId], HVAC_ADDRESS_CTL_THERMOSTAT_MODE_HOLD_TOGGLE] = getSysHoldState(gHvacState[hvacId])
    }
}

DEFINE_FUNCTION doTpUpdateCurrTemp (integer hvacId, sinteger currTemp)
{
    gHvacState[hvacId].mCurrTemp = currTemp
    doTpUpdateTempField (hvacId, currTemp, HVAC_ADDRESS_CURR_TEMP[hvacId], HVAC_ADDRESS_CTL_CURR_TEMP)
}

DEFINE_FUNCTION doTpUpdateCurrHeatSetPoint (integer hvacId, sinteger setPoint)
{
    gHvacState[hvacId].mCurrSetPointHeat = setPoint
    doTpUpdateTempField (hvacId, setPoint, HVAC_ADDRESS_HEAT_SET_POINT[hvacId], 
    				 	   HVAC_ADDRESS_CTL_HEAT_SET_POINT)
}

DEFINE_FUNCTION doTpUpdateCurrCoolSetPoint (integer hvacId, sinteger setPoint)
{
    gHvacState[hvacId].mCurrSetPointCool = setPoint
    doTpUpdateTempField (hvacId, setPoint, HVAC_ADDRESS_COOL_SET_POINT[hvacId], 
    				 	   HVAC_ADDRESS_CTL_COOL_SET_POINT)
}

DEFINE_FUNCTION doTpUpdateTempField (integer hvacId, sinteger tempVal, 
				     char summaryField[], char controlField[])
{
    integer tpId
    char    tempStr[HVAC_TEMP_STRLEN]
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	setTempStr (tempStr, tempVal, gTpPrefScale[tpId])
	send_command gDvTpSummary, "'TEXT',summaryField,'-',tempStr"
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command gDvTpControl, "'TEXT',controlField,'-',tempStr"
	}
    }
}

DEFINE_FUNCTION doTpUpdateCurrHumidity (integer hvacId, integer humidity)
{
    gHvacState[hvacId].mCurrHumidity = humidity
    doTpUpdateHumField (hvacId, humidity, HVAC_ADDRESS_CURR_HUMIDITY[hvacId],
    		       			  HVAC_ADDRESS_CTL_CURR_HUMIDITY)
}

DEFINE_FUNCTION doTpUpdateCurrHumidifySetPoint (integer hvacId, integer setPoint)
{
    gHvacState[hvacId].mCurrSetPointHumidify = setPoint
    doTpUpdateHumField (hvacId, setPoint, '', HVAC_ADDRESS_CTL_HUMIDIFY_SET_POINT)
}

DEFINE_FUNCTION doTpUpdateCurrDehumidifySetPoint (integer hvacId, integer setPoint)
{
    gHvacState[hvacId].mCurrSetPointDehumidify = setPoint
    doTpUpdateHumField (hvacId, setPoint, '', HVAC_ADDRESS_CTL_DEHUMIDIFY_SET_POINT)
}

DEFINE_FUNCTION doTpUpdateHumField (integer hvacId, integer humidity, 
				    char summaryField[], char controlField[])
{
    integer tpId
    char    humStr[16]
    humStr = "itoa(humidity),'%'"
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	if (summaryField != '')
	{
	    send_command gDvTpSummary, "'TEXT',summaryField,'-',humStr"
	}
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command gDvTpControl, "'TEXT',controlField,'-',humStr"
	}
    }
}

DEFINE_FUNCTION doTpUpdateSystemMode (integer hvacId, integer sysMode)
{
    integer tpId, sysModeButtonState
    char    sysModeStr[12]
    gHvacState[hvacId].mSystemMode = sysMode
    sysModeButtonState = getSysModeButtonState (gHvacState[hvacId])
    hvacSystemModeStr (sysModeStr, sysMode)
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    // Update the system mode
	    send_command gDvTpControl[tpId], "'TEXT', HVAC_ADDRESS_CTL_SYSTEM_MODE,'-',sysModeStr"
	    send_command gDvTpControl[tpId], "'^ANI-',HVAC_ADDRESS_CTL_SYSTEM_MODE_ICON,',',
				      itoa(sysModeButtonState),',',itoa(sysModeButtonState)"
	    // Update the 'Hold' toggle button
    	    [gDvTpControl[tpId], HVAC_ADDRESS_CTL_THERMOSTAT_MODE_HOLD_TOGGLE] = getSysHoldState(gHvacState[hvacId])
	}
    }
}

DEFINE_FUNCTION doTpSetHvacHcMode (integer hvacId, integer hcMode)
{
    integer tpId, hcModeButtonState
    char    hcModeStr[12]
    gHvacState[hvacId].mHeatCoolMode = hcMode
    hcModeButtonState = getHcModeButtonState (gHvacState[hvacId])
    hvacHeatCoolModeStr (hcModeStr, hcMode)
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_MODE,'-',hcModeStr"
	    send_command gDvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HC_MODE_ICON,',',
				      itoa(hcModeButtonState),',',itoa(hcModeButtonState)"
	}
    }
}

DEFINE_FUNCTION doTpSetHvacHcStatus (integer hvacId, integer hcStatus)
{
    integer tpId, hcStatusButtonState
    char hcStatusStr[12]
    gHvacState[hvacId].mHeatCoolStatus = hcStatus
    hcStatusButtonState = getHcStatusButtonState (gHvacState[hvacId])
    hvacHeatCoolStatusStr (hcStatusStr, hcStatus)
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	send_command gDvTpSummary, "'^ANI-',HVAC_ADDRESS_CURR_TEMP[hvacId],',',
		     		  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command gDvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_STATUS,'-',hcStatusStr"
	    send_command gDvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HC_STATUS_ICON,',',
				      itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	}
    }
}

DEFINE_FUNCTION integer getHcModeButtonState (HvacState hvac)
{
    // The button state is the same as the mHeatCoolMode (except for unknown status)
    // This makes it possible to use multi-state general buttons to change the color of text, etc.
    if (hvac.mHeatCoolMode = HVAC_HC_MODE_UNKNOWN)
        return 1
    else
	return hvac.mHeatCoolMode
}

DEFINE_FUNCTION integer getSysModeButtonState (HvacState hvac)
{
    // The button state is the same as the mSystemMode (except for unknown status, which we will map to 5)
    // This makes it possible to use multi-state general buttons to change the color of text, etc.
    if (hvac.mSystemMode = HVAC_MODE_UNKNOWN)
        return 5
    else
	return hvac.mSystemMode
}

DEFINE_FUNCTION integer getSysHoldState (HvacState hvac)
{
    // Return whether the hvac is in the HOLD state
    return (hvac.mSystemMode = HVAC_MODE_PERM_HOLD)
}

DEFINE_FUNCTION integer getHcStatusButtonState (HvacState hvac)
{
    // The button state is the same as the mHeatCoolStatus (except for unknown status)
    // This makes it possible to use multi-state general buttons to change the color of text, etc.
    if (hvac.mHeatCoolStatus = HVAC_HC_STATUS_UNKNOWN)
        return 1
    else
	return hvac.mHeatCoolStatus
}


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


DEFINE_FUNCTION readConfigs (char configFile[], char tpConfigFile[])
{
    tpReadConfigFile ('HvacConfig', tpConfigFile, gPanels)
    readConfigFile ('HvacConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPanels)),' panel definitions'")
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gHvacs)),' hvac definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'Hvacs module is enabled.'")
	tpMakeLocalDevArray ('HvacConfig', gDvTpControl, gPanels, gGeneral.mTpPortControl)
	tpMakeLocalDevArray ('HvacConfig', gDvTpSummary, gPanels, gGeneral.mTpPortSummary)
	set_length_array (gTpStatus,		length_array(gPanels))
	set_length_array (gTpHvacSelect,	length_array(gPanels))
	set_length_array (gTpPrefScale,		length_array(gPanels))
	set_length_array (gHvacState,		length_array(gHvacs))
    }
    else
    {
	debug (DBG_MODULE, 1, "'Hvacs module is disabled.'")
    }
    rebuild_event()
}
