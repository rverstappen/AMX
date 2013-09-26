MODULE_NAME='PowerManagement_UI' (char configFile[], char tpConfigFile[])

#include 'TouchPanelConfig.axi'
#include 'PowerManagementConfig.axi'
#include 'ChannelDefs.axi'

DEFINE_CONSTANT

POWER_MAN_OFF = 0
POWER_MAN_ON  = 1

DEFINE_VARIABLE

volatile char		DBG_MODULE[] = 'PowerMan'
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTps[TP_MAX_PANELS]
volatile dev		gDvControls[MAX_POWER_CONTROLS]
volatile integer	gTpStatus[TP_MAX_PANELS]
volatile integer        gTpButtons[MAX_POWER_CONTROLS]
volatile integer	gControlState[MAX_POWER_CONTROLS]

DEFINE_EVENT

BUTTON_EVENT[gDvTps, gTpButtons]
{
    PUSH: { handleTpButtonEvent(get_last(gDvTps),button.input.channel) }
    RELEASE: {}
}

DATA_EVENT[gDvTps]
{
    ONLINE:  { handleTpOnlineEvent(get_last(gDvTps)) }
    OFFLINE: { handleTpOfflineEvent(get_last(gDvTps)) }
}

DEFINE_FUNCTION handleTpButtonEvent (integer tpId, integer chan)
{
    integer controlId
    controlId = gControlByChannel[chan]
    if (controlId = 0)
    {
	debug (DBG_MODULE, 3,
	       "'got TP PM request on channel ',itoa(chan),
	       ' but no PM control exists for that channel'")
	return
    }
    debug (DBG_MODULE, 6, "'got TP PM request on channel ',itoa(chan),
    	  	           ', control ',itoa(controlId)")
    togglePower (controlId)
}

DEFINE_FUNCTION handleTpOnlineEvent (integer tpId)
{
    refreshTpControlButtons (tpId)
    gTpStatus[tpId] = TP_STATUS_ON
}

DEFINE_FUNCTION handleTpOfflineEvent (integer tpId)
{
    gTpStatus[tpId] = TP_STATUS_OFF
}

DEFINE_FUNCTION refreshTpControlButtons (integer tpId)
{
    // Refresh the TP's button labels
    integer i
    for (i = 1; i <= length_array(gPowerControls); i++)
    {
	if (gPowerControls[i].mTpChannel > 0)
	{
	    // Show button and update text
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(i),',1'")
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'TEXT',itoa(gPowerControls[i].mTpChannel),'-',
					           gPowerControls[i].mName")
	    // Update the channel status
	    updatePowerChannel (tpId, i, gControlState[i])
	}
    }
    // Blank out unused buttons
    for (i = gGeneral.mTpChannelLow; i <= gGeneral.mTpChannelHigh; i++)
    {
	if (!gControlByChannel[i])
	{
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(i),',0'")
	}
    }
}

DEFINE_FUNCTION togglePower (integer controlId)
{
    // We just send the power command to the virtual device without updating the TP because
    // the vitual device should tell us whether it worked through a channel event.
    switch (gControlState[controlId])
    {
    case POWER_MAN_OFF:	sendPowerCommand (gPowerControls[controlId].mDev, POWER_MAN_ON)
    case POWER_MAN_ON:  sendPowerCommand (gPowerControls[controlId].mDev, POWER_MAN_OFF)
    }
}

DEFINE_EVENT

CHANNEL_EVENT[gDvControls, 0]
{
    ON:  { updatePowerState (get_last(gDvControls), POWER_MAN_ON) }
    OFF: { updatePowerState (get_last(gDvControls), POWER_MAN_OFF) }
}

DEFINE_FUNCTION updatePowerState (integer controlId, integer pmState)
{
    integer tpId
    gControlState[controlId] = pmState
    debug (DBG_MODULE, 3,
    	   "'Got status update for ',gPowerControls[controlId].mName,': ',itoa(pmState)")
    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
	if (gTpStatus[tpId] = TP_STATUS_OFF)
	    continue
	updatePowerChannel (tpId, controlId, pmState)
    }
}

DEFINE_FUNCTION updatePowerChannel (integer tpId, integer controlId, integer pmState)
{
    [gDvTps[tpId], gPowerControls[controlId].mTpChannel] = (pmState = POWER_MAN_ON)
}


DEFINE_START
{
    tpReadConfigFile ('PowerManagementConfig', tpConfigFile, gPanels)
    readConfigFile ('PowerManagementConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPanels)),' panel definitions'")
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPowerControls)),' power device definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'PowerManagement_UI module is enabled.'")
	setupDevices()
	tpMakeLocalDevArray ('PowerManagement_UI', gDvTps, gPanels, gGeneral.mTpPort)
	rebuild_event()
    }
}

DEFINE_FUNCTION setupDevices()
{
    // Copy the power control devices from gPowerControls to gDvControls
    integer i
    set_length_array (gDvControls, length_array(gPowerControls))
    set_length_array (gTpButtons, 0)
    for (i = 1; i <= length_array(gPowerControls); i++)
    {
	gDvControls[i] = gPowerControls[i].mDev
	gControlByChannel[gPowerControls[i].mTpChannel] = i
        set_length_array(gTpButtons,length_array(gTpButtons)+1)
	gTpButtons[length_array(gTpButtons)] = gPowerControls[i].mTpChannel
    }
}

DEFINE_FUNCTION sendPowerCommand (dev cmdDev, integer onOff)
{
    debug (DBG_MODULE, 8,
    	   "'sending power control command to ',devtoa(cmdDev),', ',itoa(onOff)")
    sendCommand (DBG_MODULE, cmdDev, "'POWER=>',itoa(onOff)")
}

DEFINE_PROGRAM
