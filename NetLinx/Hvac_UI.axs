MODULE_NAME='Hvac_UI' (integer TP_COUNT, dev vdvHvacStatus, dev vdvHvacControl, char configFile[])

(*
 * This module is intended to be included as part of an AMX NetLinx implementation of thermostat control
 * with no dependency on the actual thermostats being used. We only deal with the generic definitions in
 * Hvac.axi and HvacTpChanDefs.axi.
 *)

#include 'Hvac.axi'
#include 'HvacTpChanDefs.axi'
#include 'TouchPanel.axi'
#include 'TouchPanelPorts.axi'

DEFINE_VARIABLE

volatile char DBG_HVAC_TP[] = 'Hvac_UI'

volatile dev dvTpControl[TP_MAX_PANELS]	// Individual HVAC display/control
volatile dev dvTpSummary[TP_MAX_PANELS]	// Summary of all HVAC thermostats

volatile   integer gTpStatus[TP_MAX_PANELS]
volatile   integer gTpHvacSelect[TP_MAX_PANELS]
persistent integer gTpPrefScale[TP_MAX_PANELS]

volatile HvacType gAllHvacs[MAX_HVACS]


DEFINE_EVENT


(*
 * Control events from the UI are translated into events to send to the COMM module.
 *)
DEFINE_EVENT

BUTTON_EVENT[dvTpControl,HVAC_CHAN_CTL_HEAT_SET_POINT_INCR]
BUTTON_EVENT[dvTpControl,HVAC_CHAN_CTL_HEAT_SET_POINT_DECR]
BUTTON_EVENT[dvTpControl,HVAC_CHAN_CTL_COOL_SET_POINT_INCR]
BUTTON_EVENT[dvTpControl,HVAC_CHAN_CTL_COOL_SET_POINT_DECR]
{
    PUSH:
    {
	integer hvacId
	hvacId = gTpHvacSelect[get_last(dvTpControl)]
	if (hvacId > 0)
	{
	    switch (button.input.channel)
	    {
	    case HVAC_CHAN_CTL_HEAT_SET_POINT_INCR: hvacCommIncrHeatSetPoint(gAllHvacs[hvacId])
	    case HVAC_CHAN_CTL_HEAT_SET_POINT_DECR: hvacCommDecrHeatSetPoint(gAllHvacs[hvacId])
	    case HVAC_CHAN_CTL_COOL_SET_POINT_INCR: hvacCommIncrCoolSetPoint(gAllHvacs[hvacId])
	    case HVAC_CHAN_CTL_COOL_SET_POINT_DECR: hvacCommDecrCoolSetPoint(gAllHvacs[hvacId])
	    }
	}
    }
}

BUTTON_EVENT[dvTpControl,HVAC_CHAN_CTL_THERMOSTAT_MODE_HOLD_TOGGLE]
{
    PUSH:
    {
	integer hvacId
	hvacId = gTpHvacSelect[get_last(dvTpControl)]
	if (hvacId > 0)
	{
	    if (gAllHvacs[hvacId].mSystemMode = HVAC_MODE_PERM_HOLD)
		hvacCommSystemModeSwitch (gAllHvacs[hvacId], HVAC_MODE_PROGRAM)
	    else
		hvacCommSystemModeSwitch (gAllHvacs[hvacId], HVAC_MODE_PERM_HOLD)
	    // The COMM module should tell us when the mode change has been successful
	}
    }
}

BUTTON_EVENT[dvTpSummary,0]
{
    PUSH:
    {
	gTpHvacSelect[get_last(dvTpSummary)] = button.input.channel
	doTpRefreshControl (get_last(dvTpSummary))
    }
}

DATA_EVENT[dvTpSummary]
{
    ONLINE:  { doTpConnected (get_last(dvTpSummary)) }
    OFFLINE: { doTpDisconnected (get_last(dvTpSummary)) }
    COMMAND: {}
}

DEFINE_FUNCTION doTpConnected (integer tpId)
{
    // TP was just (re)connected. Refresh the current summary state and the state of the device selected
    // for full control.  Since this module is not really a high priority, we will wait a few seconds 
    // before sending the refresh so as not to compete with other, more important, modules.
    gTpStatus[tpId] = 1
    wait 59 // 5.9 seconds
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
    debug (DBG_HVAC_TP, 5, "'refreshing TP summary for TP: ',itoa(tpId)")
    for (hvacId = 1; hvacId <= length_array(gAllHvacs); hvacId++)
    {
	setTempStr (currTempStr,   	 gAllHvacs[hvacId].mCurrTemp,		gTpPrefScale[tpId])
	setTempStr (heatSetPointStr,	 gAllHvacs[hvacId].mCurrSetPointHeat,	gTpPrefScale[tpId])
	setTempStr (coolSetPointStr,	 gAllHvacs[hvacId].mCurrSetPointHeat,	gTpPrefScale[tpId])
	send_command dvTpSummary, "'TEXT',HVAC_ADDRESS_TITLE[hvacId],'-',	gAllHvacs[hvacId].mName"
	send_command dvTpSummary, "'TEXT',HVAC_ADDRESS_CURR_TEMP[hvacId],'-',	currTempStr"
	send_command dvTpSummary, "'TEXT',HVAC_ADDRESS_HEAT_SET_POINT[hvacId],'-',heatSetPointStr"
	send_command dvTpSummary, "'TEXT',HVAC_ADDRESS_COOL_SET_POINT[hvacId],'-',coolSetPointStr"
	send_command dvTpSummary, "'TEXT',HVAC_ADDRESS_CURR_HUMIDITY[hvacId],'-',itoa(gAllHvacs[hvacId].mCurrHumidity),'%'"
	// Send button status to multi-state buttons
	hcStatusButtonState = getHcStatusButtonState (gAllHvacs[hvacId])
	send_command dvTpSummary, "'^ANI-',HVAC_ADDRESS_CURR_TEMP[hvacId],',',
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
    debug (DBG_HVAC_TP, 5, "'refreshing TP control for TP: ',itoa(tpId),'; HVAC=',itoa(hvacId)")
    if (hvacId > 0)
    {
	currHumStr = "itoa(gAllHvacs[hvacId].mCurrHumidity),'%'"
	sysModeButtonState  = getSysModeButtonState  (gAllHvacs[hvacId])
	hcModeButtonState   = getHcModeButtonState   (gAllHvacs[hvacId])
	hcStatusButtonState = getHcStatusButtonState (gAllHvacs[hvacId])
	hvacSystemModeStr     (sysModeStr,  gAllHvacs[hvacId].mSystemMode)
	hvacHeatCoolModeStr   (hcModeStr,   gAllHvacs[hvacId].mHeatCoolMode)
	hvacHeatCoolStatusStr (hcStatusStr, gAllHvacs[hvacId].mHeatCoolStatus)
	setTempStr (currTempStr,   	 gAllHvacs[hvacId].mCurrTemp,		gTpPrefScale[tpId])
	setTempStr (heatSetPointStr,   	 gAllHvacs[hvacId].mCurrSetPointHeat,	gTpPrefScale[tpId])
	setTempStr (coolSetPointStr,   	 gAllHvacs[hvacId].mCurrSetPointCool,	gTpPrefScale[tpId])
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_TITLE,'-',		gAllHvacs[hvacId].mName"
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_CURR_TEMP,'-',	currTempStr"
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_CURR_HUMIDITY,'-',	currHumStr"
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HEAT_SET_POINT,'-',	heatSetPointStr"
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_COOL_SET_POINT,'-',	coolSetPointStr"
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_SYSTEM_MODE,'-',	sysModeStr"
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_STATUS,'-',	hcStatusStr"
	send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_MODE,'-',		hcModeStr"
	send_command dvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_CURR_TEMP,',',
				  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	send_command dvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HEAT_SET_POINT,',',
				  itoa(hcModeButtonState),',',itoa(hcModeButtonState)"
	send_command dvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_SYSTEM_MODE_ICON,',',
				      itoa(sysModeButtonState),',',itoa(sysModeButtonState)"
	send_command dvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HC_STATUS_ICON,',',
				  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	// Update the 'Hold' toggle button
    	[dvTpControl[tpId], HVAC_ADDRESS_CTL_THERMOSTAT_MODE_HOLD_TOGGLE] = getSysHoldState(gAllHvacs[hvacId])
    }
}

DEFINE_FUNCTION doTpUpdateCurrTemp (integer hvacId, sinteger currTemp)
{
    gAllHvacs[hvacId].mCurrTemp = currTemp
    doTpUpdateTempField (hvacId, currTemp, HVAC_ADDRESS_CURR_TEMP[hvacId], HVAC_ADDRESS_CTL_CURR_TEMP)
}

DEFINE_FUNCTION doTpUpdateCurrHeatSetPoint (integer hvacId, sinteger setPoint)
{
    gAllHvacs[hvacId].mCurrSetPointHeat = setPoint
    doTpUpdateTempField (hvacId, setPoint, HVAC_ADDRESS_HEAT_SET_POINT[hvacId], 
    				 	   HVAC_ADDRESS_CTL_HEAT_SET_POINT)
}

DEFINE_FUNCTION doTpUpdateCurrCoolSetPoint (integer hvacId, sinteger setPoint)
{
    gAllHvacs[hvacId].mCurrSetPointCool = setPoint
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
	send_command dvTpSummary, "'TEXT',summaryField,'-',tempStr"
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command dvTpControl, "'TEXT',controlField,'-',tempStr"
	}
    }
}

DEFINE_FUNCTION doTpUpdateCurrHumidity (integer hvacId, integer humidity)
{
    gAllHvacs[hvacId].mCurrHumidity = humidity
    doTpUpdateHumField (hvacId, humidity, HVAC_ADDRESS_CURR_HUMIDITY[hvacId],
    		       			  HVAC_ADDRESS_CTL_CURR_HUMIDITY)
}

DEFINE_FUNCTION doTpUpdateCurrHumidifySetPoint (integer hvacId, integer setPoint)
{
    gAllHvacs[hvacId].mCurrSetPointHumidify = setPoint
    doTpUpdateHumField (hvacId, setPoint, '', HVAC_ADDRESS_CTL_HUMIDIFY_SET_POINT)
}

DEFINE_FUNCTION doTpUpdateCurrDehumidifySetPoint (integer hvacId, integer setPoint)
{
    gAllHvacs[hvacId].mCurrSetPointDehumidify = setPoint
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
	    send_command dvTpSummary, "'TEXT',summaryField,'-',humStr"
	}
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command dvTpControl, "'TEXT',controlField,'-',humStr"
	}
    }
}

DEFINE_FUNCTION doTpUpdateSystemMode (integer hvacId, integer sysMode)
{
    integer tpId, sysModeButtonState
    char    sysModeStr[12]
    gAllHvacs[hvacId].mSystemMode = sysMode
    sysModeButtonState = getSysModeButtonState (gAllHvacs[hvacId])
    hvacSystemModeStr (sysModeStr, sysMode)
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    // Update the system mode
	    send_command dvTpControl[tpId], "'TEXT', HVAC_ADDRESS_CTL_SYSTEM_MODE,'-',sysModeStr"
	    send_command dvTpControl[tpId], "'^ANI-',HVAC_ADDRESS_CTL_SYSTEM_MODE_ICON,',',
				      itoa(sysModeButtonState),',',itoa(sysModeButtonState)"
	    // Update the 'Hold' toggle button
    	    [dvTpControl[tpId], HVAC_ADDRESS_CTL_THERMOSTAT_MODE_HOLD_TOGGLE] = getSysHoldState(gAllHvacs[hvacId])
	}
    }
}

DEFINE_FUNCTION doTpSetHvacHcMode (integer hvacId, integer hcMode)
{
    integer tpId, hcModeButtonState
    char    hcModeStr[12]
    gAllHvacs[hvacId].mHeatCoolMode = hcMode
    hcModeButtonState = getHcModeButtonState (gAllHvacs[hvacId])
    hvacHeatCoolModeStr (hcModeStr, hcMode)
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_MODE,'-',hcModeStr"
	    send_command dvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HC_MODE_ICON,',',
				      itoa(hcModeButtonState),',',itoa(hcModeButtonState)"
	}
    }
}

DEFINE_FUNCTION doTpSetHvacHcStatus (integer hvacId, integer hcStatus)
{
    integer tpId, hcStatusButtonState
    char hcStatusStr[12]
    gAllHvacs[hvacId].mHeatCoolStatus = hcStatus
    hcStatusButtonState = getHcStatusButtonState (gAllHvacs[hvacId])
    hvacHeatCoolStatusStr (hcStatusStr, hcStatus)
    for (tpId = length_array(gTpHvacSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	send_command dvTpSummary, "'^ANI-',HVAC_ADDRESS_CURR_TEMP[hvacId],',',
		     		  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	if (gTpHvacSelect[tpId] = hvacId)
	{
	    send_command dvTpControl, "'TEXT',HVAC_ADDRESS_CTL_HC_STATUS,'-',hcStatusStr"
	    send_command dvTpControl, "'^ANI-',HVAC_ADDRESS_CTL_HC_STATUS_ICON,',',
				      itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
	}
    }
}

DEFINE_FUNCTION integer getHcModeButtonState (HvacType hvac)
{
    // The button state is the same as the mHeatCoolMode (except for unknown status)
    // This makes it possible to use multi-state general buttons to change the color of text, etc.
    if (hvac.mHeatCoolMode = HVAC_HC_MODE_UNKNOWN)
        return 1
    else
	return hvac.mHeatCoolMode
}

DEFINE_FUNCTION integer getSysModeButtonState (HvacType hvac)
{
    // The button state is the same as the mSystemMode (except for unknown status, which we will map to 5)
    // This makes it possible to use multi-state general buttons to change the color of text, etc.
    if (hvac.mSystemMode = HVAC_MODE_UNKNOWN)
        return 5
    else
	return hvac.mSystemMode
}

DEFINE_FUNCTION integer getSysHoldState (HvacType hvac)
{
    // Return whether the hvac is in the HOLD state
    return (hvac.mSystemMode = HVAC_MODE_PERM_HOLD)
}

DEFINE_FUNCTION integer getHcStatusButtonState (HvacType hvac)
{
    // The button state is the same as the mHeatCoolStatus (except for unknown status)
    // This makes it possible to use multi-state general buttons to change the color of text, etc.
    if (hvac.mHeatCoolStatus = HVAC_HC_STATUS_UNKNOWN)
        return 1
    else
	return hvac.mHeatCoolStatus
}


DEFINE_START

set_length_array (gTpStatus,		TP_COUNT)
set_length_array (gTpHvacSelect,	TP_COUNT)
set_length_array (gTpPrefScale,		TP_COUNT)
{
    // This block is to do with touch pad events
    integer i
    set_length_array (dvTpSummary,	TP_COUNT)
    set_length_array (dvTpControl,	TP_COUNT)
    for (i = 1; i <= TP_COUNT; i++)
    {
	tpMakeLocalDev (dvTpSummary[i],    i, TP_PORT_HVAC_SUMMARY)
	tpMakeLocalDev (dvTpControl[i],    i, TP_PORT_HVAC_CONTROL)
    }
    rebuild_event()
}
hvacReadSettings (gAllHvacs, configFile)

#include 'HvacViewStat_COMM.axs'