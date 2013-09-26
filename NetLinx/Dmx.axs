MODULE_NAME='Dmx' (char configFile[], char tpConfigFile[])

#include 'TouchPanelConfig.axi'
#include 'DmxConfig.axi'

DEFINE_CONSTANT

DMX_CHAN_RED	= 1
DMX_CHAN_GREEN	= 2
DMX_CHAN_BLUE	= 3

DMX_MAX_BUTTONS	= 100

DMX_BUTTON_RAINBOW	= 9	// Channel to start rainbow timeline
DMX_TIME_LINE_RAINBOW	= 1	// TimeLine for rainbow colorchanges

DEFINE_VARIABLE

volatile char		DBG_MODULE[] = 'DMX'
volatile integer	DMX_RGB_LEVEL_CHANNELS[] = { DMX_CHAN_RED, DMX_CHAN_GREEN, DMX_CHAN_BLUE }

volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTps[TP_MAX_PANELS]
volatile dev		gDvRgbs[DMX_MAX_DMXS]
persistent integer	gTpSelection[TP_MAX_PANELS]
volatile integer	gTpStatus[TP_MAX_PANELS]
volatile integer        gRgbButtons[DMX_MAX_DMXS]
volatile integer        gRgbPresetButtons[DMX_MAX_DMX_PRESETS]
volatile integer	gDoDatRainbowThing

DEFINE_EVENT

BUTTON_EVENT[gDvTps, gRgbButtons]
{
    PUSH: { handleTpDmxEvent(get_last(gDvTps),button.input.channel) }
}

BUTTON_EVENT[gDvTps, gRgbPresetButtons]
{
    PUSH: { handleTpPresetEvent(get_last(gDvTps),button.input.channel) }
}

DATA_EVENT[gDvTps]
{
    ONLINE:  { handleTpOnlineEvent(get_last(gDvTps)) }
    OFFLINE: { handleTpOfflineEvent(get_last(gDvTps)) }
}

DEFINE_FUNCTION handleTpDmxEvent (integer tpId, integer chan)
{
    integer dmxId
    dmxId = gDmxByChannel[chan]
    if (dmxId = 0)
    {
	debug (DBG_MODULE, 3,
	       "'got TP request on channel ',itoa(chan),' but no DMX exists for that channel'")
	return
    }
    debug (DBG_MODULE, 6, "'got TP request on channel ',itoa(chan),', DMX ',itoa(dmxId)")
    gTpSelection[tpId] = dmxId
}

DEFINE_FUNCTION handleTpPresetEvent (integer tpId, integer chan)
{
    integer dmxId, presetId
    dmxId    = gTpSelection[tpId]
    presetId = gPresetByChannel[chan]
    if (dmxId = 0)
    {
	debug (DBG_MODULE, 3,
	       "'got TP preset request on channel ',itoa(chan),' but no TP DMX selection exists for that TP'")
	return
    }
    if (presetId = 0)
    {
	debug (DBG_MODULE, 3,
	       "'got TP preset request on channel ',itoa(chan),' but no DMX preset exists for that channel'")
	return
    }
    debug (DBG_MODULE, 6, "'got TP preset request on channel ',itoa(chan),', preset ',itoa(presetId)")
    switch (gDmxRgbPresets[presetId].mType)
    {
    case DMX_TYPE_RGB:
    {
    	dmxSetRgbPreset(dmxId, presetId)
	refreshTpRgbLevels (tpId)
	break
    }
    case DMX_TYPE_RGB_CYCLE_RAINBOW:
    {
    	dmxStartRgbRainbow (dmxId, presetId)
	break
    }
    }
}

DEFINE_FUNCTION handleTpOnlineEvent (integer tpId)
{
    refreshTpRgbLevels (tpId)
    refreshTpDmxButtons (tpId)
    refreshTpPresetButtons (tpId)
    gTpStatus[tpId] = TP_STATUS_ON
}

DEFINE_FUNCTION refreshTpRgbLevels (integer tpId)
{
    integer dmxId
    dmxId = gTpSelection[tpId]
    send_level gDvTps[tpId], DMX_CHAN_RED,   gDmxRgbs[dmxId].mLevelRed
    send_level gDvTps[tpId], DMX_CHAN_GREEN, gDmxRgbs[dmxId].mLevelGreen
    send_level gDvTps[tpId], DMX_CHAN_BLUE,  gDmxRgbs[dmxId].mLevelBlue
}

DEFINE_FUNCTION refreshTpDmxButtons (integer tpId)
{
    // Refresh the TP's DMX button labels
    integer i
    for (i = 1; i <= length_array(gDmxRgbs); i++)
    {
	if (gDmxRgbs[i].mTpChannel > 0)
	{
	    // Simple button
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'TEXT',itoa(gDmxRgbs[i].mTpChannel),'-',gDmxRgbs[i].mName")
	}
    }
    // Blank out unused buttons
    for (i = gGeneral.mTpChannelRgbLow; i <= gGeneral.mTpChannelRgbHigh; i++)
    {
	if (!gDmxByChannel[i])
	{
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(i),',0'")
	}
    }
}

DEFINE_FUNCTION refreshTpPresetButtons (integer tpId)
{
    // Refresh the TP's DMX preset labels
    integer i
    for (i = 1; i <= length_array(gDmxRgbPresets); i++)
    {
	if (gDmxRgbPresets[i].mTpChannel > 0)
	{
	    // Simple button
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(gDmxRgbPresets[i].mTpChannel),',1'")
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'TEXT', itoa(gDmxRgbPresets[i].mTpChannel),'-',gDmxRgbPresets[i].mName")
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'^BCF-',itoa(gDmxRgbPresets[i].mTpChannel),',0,#',
	    		 format('%02X',gDmxRgbPresets[i].mLevelRed),
	    		 format('%02X',gDmxRgbPresets[i].mLevelGreen),
	    		 format('%02X',gDmxRgbPresets[i].mLevelBlue)")
	}
    }
    for (i = gGeneral.mTpChannelRgbPresetLow; i <= gGeneral.mTpChannelRgbPresetHigh; i++)
    {
	if (!gPresetByChannel[i])
	{
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(i),',0'")
	}
    }
}

DEFINE_FUNCTION handleTpOfflineEvent (integer tpId)
{
    gTpStatus[tpId] = TP_STATUS_OFF
}

DEFINE_EVENT

LEVEL_EVENT[gDvTps, DMX_RGB_LEVEL_CHANNELS] // RGB sliders
{
    integer tpId
    tpId = get_last(gDvTps)
    if (gTpStatus[tpId] = TP_STATUS_ON)
    {
    	debug (DBG_MODULE,9,"'received level event for RGB[',itoa(level.input.level),']: ',itoa(level.value)")
    	doRgbLevel (tpId,level.input.level,level.value)
    }
    else
    {
    	debug (DBG_MODULE,9,"'ignoring level event for offline TP[',itoa(tpId),']'")
    }
}

DEFINE_FUNCTION doRgbLevel (integer tpId, integer rgbChan, integer rgbLevel)
{
    integer dmxId, rgb
    dmxId = gTpSelection[tpId]
    switch (rgbChan)
    {
    case 1:
    {
	gDmxRgbs[dmxId].mLevelRed = rgbLevel
	rgb = gDmxRgbs[dmxId].mChannelRed
	break
    }
    case 2:
    {
	gDmxRgbs[dmxId].mLevelGreen = rgbLevel
	rgb = gDmxRgbs[dmxId].mChannelGreen
	break
    }
    case 3:
    {
	gDmxRgbs[dmxId].mLevelBlue = rgbLevel
	rgb = gDmxRgbs[dmxId].mChannelBlue
	break
    }
    default: 
    {
	debug (DBG_MODULE,3,"'doRgbLevel: configuration error? Cannot map rgbChan: ',itoa(rgbChan)")
    }
    }
    debug (DBG_MODULE,9,"'Setting RGB channel ',itoa(rgb),' to ',itoa(rgbLevel)")
    sendRgbCommand (gDmxRgbs[dmxId].mDev, rgb, rgbLevel, 0)
}

DEFINE_EVENT

DATA_EVENT[gDvRgbs]
{
    ONLINE:  {}
    OFFLINE: {}
    STRING:  {debug (DBG_MODULE, 9, "'got string from ',devtoa(data.device),': ',  data.text")}
    COMMAND: {debug (DBG_MODULE, 9, "'got command from ',devtoa(data.device),': ', data.text")}
}


DEFINE_START
{
    tpReadConfigFile ('DmxConfig', tpConfigFile, gPanels)
    readConfigFile ('DmxConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPanels)),' panel definitions'")
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gDmxRgbs)),' DMX RGB device definitions'")
    if (gGeneral.mEnabled)
    {
        setDebugLevel (gGeneral.mDebugLevel)
	debug (DBG_MODULE, 1, "'DMX module is enabled.'")
	setupDmxDevices()
	setupDmxRgbPresets()
	setupTpDevices()
	tpMakeLocalDevArray ('DmxConfig', gDvTps, gPanels, gGeneral.mTpPort)
	rebuild_event()
    }
}

DEFINE_FUNCTION setupDmxDevices()
{
    // Copy the RGB devices from gDmxRgbs to gDvRgbs
    integer i
    set_length_array(gRgbButtons,0)
    for (i = 1; i <= length_array(gDmxRgbs); i++)
    {
	gDvRgbs[i] = gDmxRgbs[i].mDev
	gDmxByChannel[gDmxRgbs[i].mTpChannel] = i
        set_length_array(gRgbButtons,length_array(gRgbButtons)+1)
	gRgbButtons[length_array(gRgbButtons)] = gDmxRgbs[i].mTpChannel
    }
}

DEFINE_FUNCTION setupDmxRgbPresets()
{
    integer i
    set_length_array(gRgbPresetButtons,0)
    for (i = 1; i <= length_array(gDmxRgbPresets); i++)
    {
	gPresetByChannel[gDmxRgbPresets[i].mTpChannel] = i
        set_length_array(gRgbPresetButtons,length_array(gRgbPresetButtons)+1)
	gRgbPresetButtons[length_array(gRgbPresetButtons)] = gDmxRgbPresets[i].mTpChannel
    }
}

DEFINE_FUNCTION setupTpDevices()
{
    // Set the gTpSelection to the first one if none selected yet.
    integer i
    for (i = 1; i <= length_array(gPanels); i++)
    {
	if (!gTpSelection[i])
	{
	    gTpSelection[i] = 1
	}
    }
}

DEFINE_FUNCTION dmxStartRgbRainbow (integer dmxId, integer presetId)
{
    gDoDatRainbowThing = 1

(*
    integer interval // in milliseconds
    integer rgbJump  // how much to change at each transition
    // Stop the rainbow timeline if necessary
    if (time_line_active(DMX_TIME_LINE_RAINBOW))
        time_line_kill(DMX_TIME_LINE_RAINBOW)
    // Determine the interval between transitions (min 0.2 sec) and the RGB jump amount.
    // There are 255 possible transitions between each of the 6 colors in the color wheel:
    rgbJump = 1
    interval = (1000*6*255) / gDmxRgbPresets[presetId].mCycleSeconds
    if (interval < 200)
    {
        if (interval = 0)
    	    interval = 1
	rgbJump = 200 / interval
	interval = 200
    }
*)
}

DEFINE_FUNCTION dmxSetRgbPreset (integer dmxId, integer presetId)
{
    gDoDatRainbowThing = 0
    gDmxRgbs[dmxId].mLevelRed   = gDmxRgbPresets[presetId].mLevelRed
    gDmxRgbs[dmxId].mLevelGreen = gDmxRgbPresets[presetId].mLevelGreen
    gDmxRgbs[dmxId].mLevelBlue  = gDmxRgbPresets[presetId].mLevelBlue
    dmxSendRgb (gDmxRgbs[dmxId], gDmxRgbPresets[presetId].mFadeDecisecs)
}

DEFINE_FUNCTION dmxSendRgb (DmxRgb dmx, integer fadeDecisecs)
{
    sendRgbCommandAll (dmx.mDev,
    		       dmx.mChannelRed,   dmx.mLevelRed,
    		       dmx.mChannelGreen, dmx.mLevelGreen,
    		       dmx.mChannelBlue,  dmx.mLevelBlue,
		       fadeDecisecs)
}

DEFINE_FUNCTION sendRgbCommand (dev rgbDev, integer rgbChan, integer rgbLevel, integer fadeDecisecs)
{
    char cmd[60]
    cmd = "'F',format('%03d',rgbChan),'@',format('%03d',rgbLevel),':',format('%03d',fadeDecisecs),$0D"
    sendDmxCommand (rgbDev, cmd)
}

DEFINE_FUNCTION sendRgbCommandAll (dev rgbDev, integer redChan, integer redLevel, 
	integer greenChan, integer greenLevel, integer blueChan, integer blueLevel, integer fadeDecisecs)
{
    char cmd[60]
    cmd = "'F',format('%03d',redChan),  '@',format('%03d',redLevel),  ',',
               format('%03d',greenChan),'@',format('%03d',greenLevel),',',
	       format('%03d',blueChan), '@',format('%03d',blueLevel),':',
	       format('%03d',fadeDecisecs),$0D"
    sendDmxCommand (rgbDev, cmd)
}

DEFINE_FUNCTION sendDmxCommand (dev dv, char cmd[])
{
    debug (DBG_MODULE, 8, "'sending DMX command to ',devtoa(dv),': ',cmd")
    send_string dv, cmd
}

DEFINE_PROGRAM

wait 37 // 3.7 seconds (prime-number-ish)
{
    if (gDoDatRainbowThing)
        doDatRainbowThing()
}

DEFINE_FUNCTION doDatRainbowThing()
{
    // All this is just temporary for now... (until it's generalized)
    local_var integer dmxId
    dmxId = 1
    bumpRainbow (dmxId)
}

DEFINE_VARIABLE

DEFINE_FUNCTION bumpRainbow(integer dmxId)
{
    switch (gDmxRgbs[dmxId].mChannelCycleState)
    {
    case DMX_RAINBOW_START:
    {
	gDmxRgbs[dmxId].mLevelRed   = 255
	gDmxRgbs[dmxId].mLevelGreen = 0
	gDmxRgbs[dmxId].mLevelBlue  = 0
        gDmxRgbs[dmxId].mChannelCycleState = DMX_RAINBOW_GREEN_UP
    }

    case DMX_RAINBOW_GREEN_UP:
    {
	gDmxRgbs[dmxId].mLevelGreen++
	if (gDmxRgbs[dmxId].mLevelGreen >= 255)
	{
	    gDmxRgbs[dmxId].mLevelGreen = 255
	    gDmxRgbs[dmxId].mChannelCycleState = DMX_RAINBOW_RED_DOWN
	}
    }

    case DMX_RAINBOW_RED_DOWN:
    {
	gDmxRgbs[dmxId].mLevelRed--
	if (gDmxRgbs[dmxId].mLevelRed = 0)
	{
	    gDmxRgbs[dmxId].mChannelCycleState = DMX_RAINBOW_BLUE_UP
	}
    }

    case DMX_RAINBOW_BLUE_UP:
    {
	gDmxRgbs[dmxId].mLevelBlue++
	if (gDmxRgbs[dmxId].mLevelBlue >= 255)
	{
	    gDmxRgbs[dmxId].mLevelBlue = 255
	    gDmxRgbs[dmxId].mChannelCycleState = DMX_RAINBOW_GREEN_DOWN
	}
    }

    case DMX_RAINBOW_GREEN_DOWN:
    {
	gDmxRgbs[dmxId].mLevelGreen--
	if (gDmxRgbs[dmxId].mLevelGreen = 0)
	{
	    gDmxRgbs[dmxId].mChannelCycleState = DMX_RAINBOW_RED_UP
	}
    }

    case DMX_RAINBOW_RED_UP:
    {
	gDmxRgbs[dmxId].mLevelRed++
	if (gDmxRgbs[dmxId].mLevelRed >= 255)
	{
	    gDmxRgbs[dmxId].mLevelRed = 255
	    gDmxRgbs[dmxId].mChannelCycleState = DMX_RAINBOW_BLUE_DOWN
	}
    }

    case DMX_RAINBOW_BLUE_DOWN:
    {
	gDmxRgbs[dmxId].mLevelBlue--
	if (gDmxRgbs[dmxId].mLevelBlue = 0)
	{
	    gDmxRgbs[dmxId].mChannelCycleState = DMX_RAINBOW_GREEN_UP
	}
    }

    } // switch
    dmxSendRgb (gDmxRgbs[dmxId], 0)
}