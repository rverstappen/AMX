MODULE_NAME='Lighting_UI' (char configFile[], char tpConfigFile[])

#include 'TouchPanelConfig.axi'
#include 'LightingConfig.axi'
#include 'ChannelDefs.axi'

DEFINE_CONSTANT

LIGHTING_OFF = 0
LIGHTING_ON  = 1

DEFINE_VARIABLE

volatile char		DBG_MODULE[] = 'Lighting'
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTps[TP_MAX_PANELS]
volatile dev		gDvControls[MAX_LIGHTING_CONTROLS]
volatile integer	gTpStatus[TP_MAX_PANELS]
non_volatile integer	gControlByTp[TP_MAX_PANELS]
volatile integer        gTpButtons[MAX_BUTTONS_PER_CONTROL]
volatile integer	gButtonState[MAX_LIGHTING_CONTROLS][MAX_BUTTONS_PER_CONTROL]

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
    integer controlId, buttonId
    controlId = gControlByTp[tpId]
//    buttonId = chan - gGeneral.mTpChannelLow + 1
    buttonId = chan
    debug (DBG_MODULE, 6, "'got TP lighting request on channel ',itoa(chan),
    	  	           ', control=',itoa(controlId),'; button=',itoa(buttonId)")
    sendButtonClickCommand (controlId, buttonId)
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
    integer controlId, i
    controlId = gControlByTp[tpId]
    if (controlId > 0)
    {
	// TODO: Show control title
(*
	// Fill in button names
	for (i = 1; i <= length_array(gLightingButtons[controlId]); i++)
	{
	    if (gLightingButtons[controlId][i].mTpChannel > 0)
	    {
		// Show button and update text
		sendCommand (gDvTps[tpId],"'^SHO-',itoa(i),',1'")
		sendCommand (gDvTps[tpId],"'TEXT',itoa(i),'-',gLightingButtons[controlId][i].mName")
		// Update the channel status
		updateButtonChannel (tpId, i, gButtonState[controlId][i])
	    }
	}
  *)
  }
    else
    {
	// TODO: Clear control title if none selected
    }
    // Blank out unused buttons
    for (; i <= gGeneral.mTpChannelHigh; i++)
    {
	sendCommand (gDvTps[tpId],"'^SHO-',itoa(i),',0'")
    }
}

DEFINE_EVENT

(*
  Change to data event
CHANNEL_EVENT[gDvControls, 0]
{
    ON:  { updatePowerState (get_last(gDvControls), LIGHTING_ON) }
    OFF: { updatePowerState (get_last(gDvControls), LIGHTING_OFF) }
}

DEFINE_FUNCTION updatePowerState (integer controlId, integer buttonId, integer ltState)
{
    integer tpId
    gButtonState[controlId][buttonId] = ltState
    debug (DBG_MODULE, 3,
    	   "'Got status update for ',gLightingControls[controlId].mName,': ',itoa(ltState)")
    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
	if (gTpStatus[tpId] = TP_STATUS_OFF)
	    continue
	if (gControlByTp[tpId] != controlId)
	    continue
	updateButtonChannel (tpId, buttonId, ltState)
    }
}

DEFINE_FUNCTION updateButtonChannel (integer tpId, integer buttonId, integer ltState)
{
    [gDvTps[tpId], buttonId] = (ltState = LIGHTING_ON)
}
*)


DEFINE_START
{
    tpReadConfigFile ('LightingConfig', tpConfigFile, gPanels)
    readConfigFile ('LightingConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPanels)),' panel definitions'")
//    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gLightingControls)),' lighting definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'Lighting_UI module is enabled.'")
	setDebugLevel (gGeneral.mDebugLevel)
	setupTpButtonEvents()
	tpMakeLocalDevArray ('Lighting_UI', gDvTps, gPanels, gGeneral.mTpPort)
	rebuild_event()
	wait 293 // 29.3 seconds
	{
	    // Request the high-level configuration from the COMM module
	    sendConfigRequestCommand()
	}
    }
}


DEFINE_FUNCTION setupTpButtonEvents()
{
    integer i
    set_length_array (gTpButtons, gGeneral.mTpChannelHigh)
    for (i = 1; i <= length_array(gGeneral.mTpChannelHigh); i++)
    {
	gTpButtons[i] = i
    }
}

DEFINE_FUNCTION sendConfigRequestCommand ()
{
    debug (DBG_MODULE, 8,
    	   "'sending lighting config request command to ',devtoa(gGeneral.mCommDev)")
    sendCommand (gGeneral.mCommDev, "'?GET-ALL-INPUTS'")
}

DEFINE_FUNCTION sendButtonClickCommand (integer controlId, integer buttonId)
{
    dev cmdDev
//    cmdDev = gLightingControls[controlId].mDev
    cmdDev = gGeneral.mCommDev
    debug (DBG_MODULE, 8,
    	   "'sending lighting control command to ',devtoa(cmdDev),
	    ', controlId=',itoa(controlId),', buttonId=',itoa(buttonId)")
    sendCommand (cmdDev, "'CLICK=>',itoa(controlId),':',itoa(buttonId)")
}

DEFINE_FUNCTION sendCommand (dev cmdDev, char cmdStr[])
{
    debug (DBG_MODULE, 9, "'send_string ',devtoa(cmdDev),', ',cmdStr")
    send_command cmdDev, cmdStr
}

DEFINE_PROGRAM
