(*
 * This module is intended to be included as part of an AMX NetLinx implementation of pool/spacontrol
 * with no dependency on the actual pool controller being used. We only deal with the generic definitions in
 * Pool.axi and PoolTpChanDefs.axi.
 *)

#if_not_defined __POOL_UI__
#define __POOL_UI__

#include 'Pool.axi'
#include 'PoolTpChanDefs.axi'
#include 'TouchPanelConfig.axi'

DEFINE_VARIABLE

volatile char DBG_MODULE[] = 'Pool_UI'

volatile   TpCfgGeneral     gTpGeneral
volatile   TouchPanel	    gPanels[TP_MAX_PANELS]
volatile   dev		    gDvTp[TP_MAX_PANELS]
volatile   integer 	    gTpStatus[TP_MAX_PANELS]
volatile   integer	    gTpPoolSelect[TP_MAX_PANELS]
persistent integer	    gTpPrefScale[TP_MAX_PANELS]

volatile   PoolState	    gPoolState
volatile   char             gAuxNames[10][32]
volatile   integer          gAuxStates[10]


(*
 * Control events from the UI are translated into events to send to the COMM module.
 *)
DEFINE_EVENT

BUTTON_EVENT[gDvTp,POOL_CHAN_POOL_SET_POINT_INCR]
BUTTON_EVENT[gDvTp,POOL_CHAN_POOL_SET_POINT_DECR]
BUTTON_EVENT[gDvTp,POOL_CHAN_SPA_SET_POINT_INCR]
BUTTON_EVENT[gDvTp,POOL_CHAN_SPA_SET_POINT_DECR]
{
    PUSH:
    {
    switch (button.input.channel)
    {
    case POOL_CHAN_POOL_SET_POINT_INCR: poolCommIncrPoolSetPoint()
    case POOL_CHAN_POOL_SET_POINT_DECR: poolCommDecrPoolSetPoint()
    case POOL_CHAN_SPA_SET_POINT_INCR: poolCommIncrSpaSetPoint()
    case POOL_CHAN_SPA_SET_POINT_DECR: poolCommDecrSpaSetPoint()
    }
    }
}

BUTTON_EVENT[gDvTp,POOL_CHAN_POOL_PUMP_STATUS]
BUTTON_EVENT[gDvTp,POOL_CHAN_SPA_PUMP_STATUS]
{
    PUSH:
    {
    switch (button.input.channel)
    {
    case POOL_CHAN_POOL_PUMP_STATUS: poolCommTogglePoolPump()
    case POOL_CHAN_SPA_PUMP_STATUS:  poolCommToggleSpaPump()
    }
    }
}

BUTTON_EVENT[gDvTp,POOL_CHAN_AUX]
{
    PUSH:
    {
	integer aux
	aux = button.input.channel - POOL_CHAN_AUX_OFFSET
// need to look up correct channel
	poolCommAuxToggle (button.input.channel - POOL_CHAN_AUX_OFFSET, !gPoolState.mAuxStates[aux])
    }
}

BUTTON_EVENT[gDvTp,0]
{
    PUSH:
    {
	gTpPoolSelect[get_last(gDvTp)] = button.input.channel
	doTpRefresh (get_last(gDvTp))
    }
}

DATA_EVENT[gDvTp]
{
    ONLINE:  { doTpConnected (get_last(gDvTp)) }
    OFFLINE: { doTpDisconnected (get_last(gDvTp)) }
    COMMAND: {}
}

DEFINE_FUNCTION doTpConnected (integer tpId)
{
    // TP was just (re)connected. Refresh the current state.
    debug (DBG_MODULE, 4, "'TP reconnected: ',itoa(tpId)")
    gTpStatus[tpId] = 1
    wait 17 // 1.7 seconds
    {
	if (gTpStatus[tpId])  // maybe it disconnected changed during the wait
	{
	    doTpRefresh (tpId)
	}
    }
}

DEFINE_FUNCTION doTpDisconnected (integer tpId)
{
    gTpStatus[tpId] = 0
}

DEFINE_FUNCTION doTpRefresh (integer tpId)
{
    integer i
    debug (DBG_MODULE, 5, "'refreshing TP summary for TP: ',itoa(tpId)")
    doTpRefreshTemp(tpId, POOL_ADDRESS_AIR_TEMP,           gPoolState.mAirTemp)
    doTpRefreshTemp(tpId, POOL_ADDRESS_POOL_TEMP,          gPoolState.mPoolTemp)
    doTpRefreshTemp(tpId, POOL_ADDRESS_SPA_TEMP,           gPoolState.mSpaTemp)
    doTpRefreshTemp(tpId, POOL_ADDRESS_POOL_SET_POINT,     gPoolState.mPoolSetPoint)
    doTpRefreshTemp(tpId, POOL_ADDRESS_SPA_SET_POINT,      gPoolState.mSpaSetPoint)
    doTpRefreshString(tpId, POOL_ADDRESS_POOL_PUMP_STATUS, gPoolState.mPoolName)
    doTpRefreshString(tpId, POOL_ADDRESS_SPA_PUMP_STATUS,  gPoolState.mSpaName)
    doTpRefreshState(tpId, POOL_CHAN_POOL_PUMP_STATUS,     gPoolState.mPoolPumpState)
    doTpRefreshState(tpId, POOL_CHAN_SPA_PUMP_STATUS,      gPoolState.mSpaPumpState)
    for (i = length_array(gPoolState.mAuxNames); i > 0; i--)
    {
        doTpRefreshString(tpId, POOL_ADDRESS_AUX_NAMES[i], gPoolState.mAuxNames[i])
	doTpRefreshState(tpId,  POOL_CHAN_AUX[i],          gPoolState.mAuxStates[i])
    }

    // Send button status to multi-state buttons
//    StatusButtonState = getHcStatusButtonState (gHvacState[hvacId])
//    send_command gDvTpSummary, "'^ANI-',HVAC_ADDRESS_CURR_TEMP[hvacId],',',
//	     		  itoa(hcStatusButtonState),',',itoa(hcStatusButtonState)"
}

DEFINE_FUNCTION doTpRefreshTemp (integer tpId, char tpAddress[], sinteger temp)
{
    char     tempStr[32]
    setTempStr (tempStr, temp, gTpPrefScale[tpId])
    sendCommand (DBG_MODULE, gDvTp[tpId], "'TEXT',tpAddress,'-',tempStr")
}

DEFINE_FUNCTION doTpRefreshString (integer tpId, char tpAddress[], char str[])
{
    sendCommand (DBG_MODULE, gDvTp[tpId], "'TEXT',tpAddress,'-',str")
}

DEFINE_FUNCTION doTpRefreshState (integer tpId, integer tpChannel, integer state)
{
    [gDvTp[tpId], tpChannel] = state
}

DEFINE_FUNCTION doTpUpdateAirTemp (sinteger currTemp)
{
    gPoolState.mAirTemp = currTemp
    doTpUpdateTempField (currTemp, POOL_ADDRESS_AIR_TEMP)
}

DEFINE_FUNCTION doTpUpdatePoolTemp (sinteger currTemp)
{
    gPoolState.mPoolTemp = currTemp
    doTpUpdateTempField (currTemp, POOL_ADDRESS_POOL_TEMP)
}

DEFINE_FUNCTION doTpUpdateSpaTemp (sinteger currTemp)
{
    gPoolState.mSpaTemp = currTemp
    doTpUpdateTempField (currTemp, POOL_ADDRESS_SPA_TEMP)
}

DEFINE_FUNCTION doTpUpdatePoolSetPoint (sinteger setPoint)
{
    gPoolState.mPoolSetPoint = setPoint
    doTpUpdateTempField (setPoint, POOL_ADDRESS_POOL_SET_POINT)
}

DEFINE_FUNCTION doTpUpdateSpaSetPoint (sinteger setPoint)
{
    gPoolState.mSpaSetPoint = setPoint
    doTpUpdateTempField (setPoint, POOL_ADDRESS_SPA_SET_POINT)
}

DEFINE_FUNCTION doTpUpdatePoolName (char name[])
{
    gPoolState.mPoolName = name
    doTpUpdateStringField (POOL_ADDRESS_POOL_NAME, name)
}

DEFINE_FUNCTION doTpUpdateSpaName (char name[])
{
    gPoolState.mSpaName = name
    doTpUpdateStringField (POOL_ADDRESS_SPA_NAME, name)
}

DEFINE_FUNCTION doTpUpdateAuxName (integer aux, char name[])
{
    if (length_array(gPoolState.mAuxNames) < aux)
    {
	set_length_array(gPoolState.mAuxNames, aux)
	set_length_array(gPoolState.mAuxStates, aux)
    }
    debug (DBG_MODULE, 6, "'Updating AUX ',itoa(aux),' name: ',name")
    gPoolState.mAuxNames[aux] = name
    doTpUpdateStringField (POOL_ADDRESS_AUX_NAMES[aux], name)
}

DEFINE_FUNCTION doTpUpdatePoolState (integer state)
{
    integer tpId
    gPoolState.mPoolPumpState = state
    for (tpId = length_array(gTpPoolSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
        [gDvTp[tpId], POOL_CHAN_POOL_PUMP_STATUS] = state
    }
}

DEFINE_FUNCTION doTpUpdateSpaState (integer state)
{
    integer tpId
    gPoolState.mSpaPumpState = state
    for (tpId = length_array(gTpPoolSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
        [gDvTp[tpId], POOL_CHAN_SPA_PUMP_STATUS] = state
    }
}

DEFINE_FUNCTION doTpUpdateAuxState (integer aux, integer state)
{
    integer tpId
    gPoolState.mAuxStates[aux] = state
    for (tpId = length_array(gTpPoolSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
        [gDvTp[tpId], POOL_CHAN_AUX[aux]] = state
    }
}

DEFINE_FUNCTION doTpUpdateTempField (sinteger tempVal, char summaryField[])
{
    integer tpId
    char    tempStr[POOL_TEMP_STRLEN]
    for (tpId = length_array(gTpPoolSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	setTempStr (tempStr, tempVal, gTpPrefScale[tpId])
	sendCommand (DBG_MODULE, gDvTp[tpId], "'TEXT',summaryField,'-',tempStr")
    }
}

DEFINE_FUNCTION doTpUpdateStringField (char summaryField[], char str[])
{
    integer tpId
    for (tpId = length_array(gTpPoolSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	sendCommand (DBG_MODULE, gDvTp[tpId], "'TEXT',summaryField,'-',str")
    }
}

DEFINE_FUNCTION doTpUpdateSystemMode (integer sysMode)
{
    integer tpId, sysModeButtonState
    char    sysModeStr[12]
(*
    gPoolState.mSystemMode = sysMode
    sysModeButtonState = getSysModeButtonState (gPoolState)
    poolSystemModeStr (sysModeStr, sysMode)
    for (tpId = length_array(gTpPoolSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
        // Update the system mode
	send_command gDvTp[tpId], "'TEXT', POOL_ADDRESS_SYSTEM_MODE,'-',sysModeStr"
	send_command gDvTp[tpId], "'^ANI-',POOL_ADDRESS_SYSTEM_MODE_ICON,',',
				      itoa(sysModeButtonState),',',itoa(sysModeButtonState)"
	// Update the 'Hold' toggle button
    	[gDvTp[tpId], POOL_ADDRESS_THERMOSTAT_MODE_HOLD_TOGGLE] = getSysHoldState(gPoolState)
    }
*)
}

DEFINE_FUNCTION doTpSetPoolHcMode (integer hcMode)
{
    integer tpId, hcModeButtonState
    char    hcModeStr[12]
(*    gPoolState.mHeatCoolMode = hcMode
    hcModeButtonState = getHcModeButtonState (gPoolState)
    poolHeatCoolModeStr (hcModeStr, hcMode)
    for (tpId = length_array(gTpPoolSelect); tpId > 0; tpId--)
    {
	if (!gTpStatus[tpId])
	    continue
	send_command gDvTp, "'TEXT',POOL_ADDRESS_HC_MODE,'-',hcModeStr"
	send_command gDvTp, "'^ANI-',POOL_ADDRESS_HC_MODE_ICON,',',
				      itoa(hcModeButtonState),',',itoa(hcModeButtonState)"
    }
*)
}

DEFINE_FUNCTION readConfigs (char configFile[], char tpConfigFile[])
{
    tpReadConfigFile ('PoolConfig', tpConfigFile, gTpGeneral, gPanels)
    readConfigFile ('PoolConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPanels)),' panel definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'Pools module is enabled.'")
	tpMakeLocalDevArray ('PoolConfig', gDvTp, gPanels, gGeneral.mTpPort)
	set_length_array (gTpStatus,		length_array(gPanels))
	set_length_array (gTpPoolSelect,	length_array(gPanels))
	set_length_array (gTpPrefScale,		length_array(gPanels))
    }
    else
    {
	debug (DBG_MODULE, 1, "'Pools module is disabled.'")
    }
    rebuild_event()
}


#end_if // __POOL_UI__
