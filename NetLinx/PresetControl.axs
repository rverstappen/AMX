MODULE_NAME='PresetControl' (char configFile[], char tpConfigFile[])

#include 'TouchPanelConfig.axi'
#include 'PresetConfig.axi'
#include 'Debug.axi'

DEFINE_CONSTANT


DEFINE_VARIABLE

volatile char		DBG_MODULE[] = 'PresetControl'
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTps[TP_MAX_PANELS]

DEFINE_EVENT

BUTTON_EVENT[gDvTps, 0]
{
    PUSH: { handleTpPresetEvent(button.input.channel) }
}

DATA_EVENT[gDvTps]
{
    ONLINE: { wait 32 { handleTpOnlineEvent(get_last(gDvTps)) } }
}

DEFINE_FUNCTION handleTpPresetEvent (integer chan)
{
    integer presetId
    presetId = gPresetByChannel[chan]
    if (presetId = 0)
    {
	debug (DBG_MODULE, 3,
	       "'got TP request on channel ',itoa(chan),' but no preset exists for that channel'")
	return
    }
    debug (DBG_MODULE, 6, "'got TP request on channel ',itoa(chan),', preset ',itoa(presetId)")
    switch (gPresets[presetId].mType)
    {
	case PRESET_TYPE_AV_COMMAND:
	     sendCommand(gGeneral.mDevControlAv,	gPresets[presetId].mCommandStr)
	case PRESET_TYPE_LUTRON_COMMAND:
	     sendCommand(gGeneral.mDevControlLutron,	gPresets[presetId].mCommandStr)
	case PRESET_TYPE_GENERAL_COMMAND:
	     sendCommand(gPresets[presetId].mCommandDev,	gPresets[presetId].mCommandStr)
        case PRESET_TYPE_AV_GRID:
	     handleTpGridEvent(presetId, chan)
    }
}

DEFINE_FUNCTION handleTpGridEvent (integer presetId, integer chan)
{
    integer row, col, actionId, groupId
    row = (chan - gPresets[presetId].mTpGridChannelsBegin) / gPresets[presetId].mTpGridChannelsRowIncr
    col = (chan - gPresets[presetId].mTpGridChannelsBegin) % gPresets[presetId].mTpGridChannelsRowIncr
    debug (DBG_MODULE, 8, "'Got AV grid event at row ',itoa(row),', column ',itoa(col),': ',
    	  	       	  gPresets[presetId].mName")
    actionId = gPresets[presetId].mAvActionIds[col]
    groupId  = gPresets[presetId].mAvGroupIds[row]
    switch (gAvActions[actionId].mAction)
    {
    case AV_ACTION_OFF:		doPresetAvPowerOff    (gAvGroups[groupId].mOutputIds)
    case AV_ACTION_SWITCH:	doPresetAvSwitchGroup (gAvActions[actionId].mInputId,
    	 					       gAvGroups[groupId].mOutputIds)
    default: debug (DBG_MODULE, 4, "'Unknown action code: ',itoa(gAvActions[actionId])")
    }
}

DEFINE_FUNCTION handleTpOnlineEvent (integer tpId)
{
    // Refresh the TP's preset button labels
    integer i
    for (i = 1; i <= length_array(gPresets); i++)
    {
	if (gPresets[i].mChannel > 0)
	{
	    // Simple preset button
	    sendCommand (gDvTps[tpId],"'TEXT',itoa(gPresets[i].mChannel),'-',gPresets[i].mName")
	}
	else if (gPresets[i].mType = PRESET_TYPE_AV_GRID)
	{
	    // Draw up the A/V grid preset
	    integer row, col, chan, actionId, groupId
	    for (row = 0; row <= length_array(gPresets[i].mAvGroupIds); row++)
	    {
		if (row = 0)
		{
		    // First the column headings
		    for (col = 1; col <= length_array(gPresets[i].mAvActionIds); col++)
		    {
			chan = gPresets[i].mTpGridChannelsBegin + col
			actionId = gPresets[i].mAvActionIds[col]
			sendCommand (gDvTps[tpId],"'TEXT',itoa(chan),'-',gAvActions[actionId].mName")
		    }
		}
		else
		{
		    // Set the row-heading
		    chan = gPresets[i].mTpGridChannelsBegin + row*gPresets[i].mTpGridChannelsRowIncr
		    groupId = gPresets[i].mAvGroupIds[row]
		    sendCommand (gDvTps[tpId],"'TEXT',itoa(chan),'-',gAvGroups[groupId].mName")
		}
		// Hide the remaining column buttons/headers
		for (col = length_array(gPresets[i].mAvActionIds) + 1;
		     col <= gPresets[i].mTpGridChannelsRowIncr - 1;
		     col++)
		{
		    // Blank out the remaining column headings
		    chan = gPresets[i].mTpGridChannelsBegin + row*gPresets[i].mTpGridChannelsRowIncr + col
		    sendCommand (gDvTps[tpId],"'^SHO-',itoa(chan),',0'")
		}
	    }
	    // Blank out all of the remaining rows
	    for (; row <= MAX_AV_GROUPS; row++)
	    {
		for (col = 0; col <= gPresets[i].mTpGridChannelsRowIncr-1; col++)
		{
		    // Blank out the remaining column headings
		    chan = gPresets[i].mTpGridChannelsBegin + row*gPresets[i].mTpGridChannelsRowIncr + col
		    sendCommand (gDvTps[tpId],"'^SHO-',itoa(chan),',0'")
		}
	    }	    
	}
    }
    // Blank out unused buttons
    for (i = gGeneral.mTpChannelBlankLow; i <= gGeneral.mTpChannelBlankHigh; i++)
    {
	if (!gPresetByChannel[i])
	{
	    sendCommand (gDvTps[tpId],"'^SHO-',itoa(i),',0'")
	}
    }
}

DEFINE_FUNCTION doPresetAvPowerOffAll ()
{
    char cmdStr[128]
    cmdStr = "'POWER-OFFALL'"
    debug (DBG_MODULE, 2, "'Powering OFF all A/V outputs'")
    debug (DBG_MODULE, 9, "'send_command ',devtoa(gGeneral.mDevControlAv),', ',cmdStr")
    send_command gGeneral.mDevControlAv, cmdStr
}

DEFINE_FUNCTION doPresetAvPowerOff (integer outputIds[])
{
    integer i
    char cmdStr[128]
    cmdStr = "'POWER-OFF'"
    for (i = 1; i <= length_array(outputIds); i++)
    {
	cmdStr = "cmdStr,'O',itoa(outputIds[i])"
    }
    debug (DBG_MODULE, 4, "'Powering OFF some A/V outputs'")
    debug (DBG_MODULE, 9, "'send_command ',devtoa(gGeneral.mDevControlAv),', ',cmdStr")
    sendCommand (gGeneral.mDevControlAv, cmdStr)
}

DEFINE_FUNCTION doPresetAvSwitchGroup (integer inputId, integer outputIds[])
{
    integer i
    char cmdStr[128]
    cmdStr = "'SWITCH-INPUT',itoa(inputId)"
    for (i = 1; i <= length_array(outputIds); i++)
    {
	cmdStr = "cmdStr,'O',itoa(outputIds[i])"
    }
    debug (DBG_MODULE, 4, "'Switching input ',itoa(inputId),' to output groups'")
    sendCommand (gGeneral.mDevControlAv, cmdStr)
}

DEFINE_FUNCTION doPresetLightsOffAll ()
{
    char cmdStr[128]
    cmdStr = "'PUSH-1'"
    debug (DBG_MODULE, 4, "'Turning OFF all lights'")
    sendCommand (gGeneral.mDevControlLutron, cmdStr)
}

DEFINE_FUNCTION setupPresets ()
{
    integer i
    for (i = 1; i <= length_array(gPresets); i++)
    {
	switch (gPresets[i].mType)
	{
	case PRESET_TYPE_AV_GRID:
	    setupAvGridPreset(i)
	default:
	    gPresetByChannel[gPresets[i].mChannel] = i
	}
    }
}

DEFINE_FUNCTION setupAvGridPreset (integer presetId)
{
    integer row, col, chan
    for (row = 1; row <= length_array(gPresets[presetId].mAvGroupIds); row++)
    {
	for (col = 1; col <= length_array(gPresets[presetId].mAvActionIds); col++)
	{
	   chan = gPresets[presetId].mTpGridChannelsBegin + row*gPresets[presetId].mTpGridChannelsRowIncr + col
	   debug (DBG_MODULE, 9, "'Setting up grid item [',itoa(row),',',itoa(col),']: channel is ',itoa(chan)")
	   gPresetByChannel[chan] = presetId
	}
    }
}

DEFINE_FUNCTION sendCommand (dev cmdDev, char cmdStr[])
{
    debug (DBG_MODULE, 9, "'send_command ',devtoa(cmdDev),', ',cmdStr")
    send_command cmdDev, cmdStr
}

DEFINE_START
{
    tpReadConfigFile ('PresetConfig', tpConfigFile, gPanels)
    readConfigFile ('PresetConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPanels)),' panel definitions'")
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPresets)),' preset definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'Presets module is enabled.'")
	setupPresets()
	tpMakeLocalDevArray ('PresetConfig', gDvTps, gPanels, gGeneral.mTpPort)
    	rebuild_event()
    }
    else
    {
	debug (DBG_MODULE, 1, "'Presets module is disabled.'")
    }
}

DEFINE_PROGRAM

