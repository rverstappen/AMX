MODULE_NAME='PresetControl' (char configFile[], char tpConfigFile[])

#include 'TouchPanelConfig.axi'
#include 'PresetConfig.axi'
#include 'Debug.axi'

DEFINE_CONSTANT

DEFINE_VARIABLE

volatile char		DBG_MODULE[] = 'PresetControl'
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTps[TP_MAX_PANELS]
volatile integer	gTpStatus[TP_MAX_PANELS]
persistent integer	gGridStatus[MAX_AV_GROUPS][MAX_AV_ACTIONS]


DEFINE_EVENT

BUTTON_EVENT[gDvTps, 0]
{
    PUSH: { handleTpPresetEvent (get_last(gDvTps), button.input.channel) }
}

DATA_EVENT[gDvTps]
{
    ONLINE:  { gTpStatus[get_last(gDvTps)] = 1; wait 23 { handleTpOnlineEvent(get_last(gDvTps)) } }
    OFFLINE: { gTpStatus[get_last(gDvTps)] = 0 }
}

DEFINE_FUNCTION handleTpPresetEvent (integer tpId, integer chan)
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
	     sendCommand(DBG_MODULE, gGeneral.mDevControlAv,	gPresets[presetId].mCommandStr)
	case PRESET_TYPE_LUTRON_COMMAND:
	     sendCommand(DBG_MODULE, gGeneral.mDevControlLutron,	gPresets[presetId].mCommandStr)
	case PRESET_TYPE_GENERAL_COMMAND:
	     sendCommand(DBG_MODULE, gPresets[presetId].mCommandDev,gPresets[presetId].mCommandStr)
        case PRESET_TYPE_AV_GRID:
	     handleTpAvGridEvent(tpId, presetId, chan)
    }
}

DEFINE_FUNCTION handleTpAvGridEvent (integer tpId, integer presetId, integer chan)
{
    integer row, col, actionId, groupId, action
    row = (chan - gPresets[presetId].mTpGridChannelsBegin) / gPresets[presetId].mTpGridChannelsRowIncr
    col = (chan - gPresets[presetId].mTpGridChannelsBegin) % gPresets[presetId].mTpGridChannelsRowIncr
    debug (DBG_MODULE, 8, "'Got AV grid event at row ',itoa(row),', column ',itoa(col),': ',
    	  	       	  gPresets[presetId].mName")
    actionId = gPresets[presetId].mAvActionIds[col]
    groupId  = gPresets[presetId].mAvGroupIds[row]
    action   = gAvActions[actionId].mAction
    updateGridRowStatus (row, col, action)

    switch (action)
    {
    case AV_ACTION_OFF:
    {
	doPresetAvPowerOff (gAvGroups[groupId].mOutputIds)
	updateGridRowOnAllTps (presetId, row)
    }
    case AV_ACTION_SWITCH:
    {
	doPresetAvSwitchGroup (gAvActions[actionId].mInputId, gAvGroups[groupId].mOutputIds)
	updateGridRowOnAllTps (presetId, row)
    }
    default: debug (DBG_MODULE, 4, "'Unknown action code: ',itoa(gAvActions[actionId])")
    }
}

DEFINE_FUNCTION handleTpOnlineEvent (integer tpId)
{
    // Refresh the TP's preset button labels
    integer i
    // First, blank out everything
    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(gGeneral.mTpChannelBlankLow),'.',itoa(gGeneral.mTpChannelBlankHigh),',0'")
    for (i = 1; i <= length_array(gPresets); i++)
    {
	if (gPresets[i].mChannel > 0)
	{
	    // Simple preset button
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(gPresets[i].mChannel),',1'")
	    sendCommand (DBG_MODULE, gDvTps[tpId],"'TEXT',itoa(gPresets[i].mChannel),'-',gPresets[i].mName")
	}
	else if (gPresets[i].mType = PRESET_TYPE_AV_GRID)
	{
	    // Draw up the A/V grid preset
	    integer numRows, numCols, row, col, rowIncr, firstChan, rowChan, chan, actionId, groupId
	    numRows = length_array(gPresets[i].mAvGroupIds)
	    firstChan = gPresets[i].mTpGridChannelsBegin
	    rowIncr   = gPresets[i].mTpGridChannelsRowIncr
	    for (row = 0; row <= numRows; row++)
	    {
		rowChan = firstChan + row*rowIncr
		numCols = length_array(gPresets[i].mAvActionIds)
		if (row = 0)
		{
		    // First the column headings
		    for (col = 1; col <= numCols; col++)
		    {
			chan = rowChan + col
			actionId = gPresets[i].mAvActionIds[col]
			if (actionId)
			{
			    sendCommand (DBG_MODULE, gDvTps[tpId],"'TEXT',itoa(chan),'-',gAvActions[actionId].mName")
			}
			else
			{
			    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(chan),',0'")
			}
		    }
		}
		else
		{
		    // Set the row-heading
		    chan = rowChan
		    groupId = gPresets[i].mAvGroupIds[row]
		    sendCommand (DBG_MODULE, gDvTps[tpId],"'TEXT',itoa(chan),'-',gAvGroups[groupId].mName")
		    // Set the button status for the row
		    for (col = 1, chan++; col <= numCols; col++,chan++)
		    {
			sendButtonState (gDvTps[tpId], chan, gGridStatus[row][col])
		    }
		}
		// Hide the remaining column buttons/headers
		if (col < rowIncr-1)
		{
		    sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(rowChan+col+1),'.',itoa(rowChan+rowIncr-1),',0'")
		}
	    }
	    // Blank out remaining rows
	    if (numRows < MAX_AV_GROUPS)
	    {
		sendCommand (DBG_MODULE, gDvTps[tpId],"'^SHO-',itoa(firstChan+((numRows+1)*rowIncr)),'.',
							       itoa(firstChan+(MAX_AV_GROUPS*rowIncr)),',0'")
	    }
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
    sendCommand (DBG_MODULE, gGeneral.mDevControlAv, cmdStr)
}

DEFINE_FUNCTION doPresetAvSwitchGroup (integer inputId, integer outputIds[])
{
    integer i
    char switchCmdStr[128]
    switchCmdStr = "'SWITCH-INPUT',itoa(inputId)"
    for (i = 1; i <= length_array(outputIds); i++)
    {
	switchCmdStr = "switchCmdStr,'O',itoa(outputIds[i])"
    }
    debug (DBG_MODULE, 4, "'Switching input ',itoa(inputId),' to output groups'")
    sendCommand (DBG_MODULE, gGeneral.mDevControlAv, switchCmdStr)
}

DEFINE_FUNCTION doPresetLightsOffAll ()
{
    char cmdStr[128]
    cmdStr = "'PUSH-1'"
    debug (DBG_MODULE, 4, "'Turning OFF all lights'")
    sendCommand (DBG_MODULE, gGeneral.mDevControlLutron, cmdStr)
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
	   chan = rowCol2Channel (presetId,row,col)
	   debug (DBG_MODULE, 9, "'Setting up grid item [',itoa(row),',',itoa(col),']: channel is ',itoa(chan)")
	   gPresetByChannel[chan] = presetId
	}
    }
}

DEFINE_FUNCTION updateGridRowStatus (integer row, integer col, integer action)
{
    integer c
    for (c = 1; c <= MAX_AV_GRID_WIDTH; c++)
    {
	if ((c==col) && (action!=AV_ACTION_OFF))
	    gGridStatus[row][c] = PRESET_STATUS_ON
	else
	    gGridStatus[row][c] = PRESET_STATUS_OFF
    }
}

DEFINE_FUNCTION updateGridRowOnAllTps (integer presetId, integer row)
{
    // Update button state for this row on all open TPs
    integer tpId
    for (tpId = length_array(gPanels); tpId > 0; tpId--)
    {
	if (gTpStatus[tpId])
	    updateGridRowOnTp (tpId, presetId, row)
    }
}

DEFINE_FUNCTION updateGridRowOnTp (integer tpId, integer presetId, integer row)
{
    integer i, chan
    chan = rowCol2Channel (presetId,row,1)
    for (i = 1; i <= MAX_AV_GRID_WIDTH; i++,chan++)
    {
	sendButtonState (gDvTps[tpId], chan, gGridStatus[row][i])
    }
}

DEFINE_FUNCTION integer rowCol2Channel (integer presetId, integer row, integer col)
{
    return gPresets[presetId].mTpGridChannelsBegin + row*gPresets[presetId].mTpGridChannelsRowIncr + col
}

DEFINE_FUNCTION sendButtonState (dev cmdDev, integer chan, integer status)
{
    char params[32]
    switch (status)
    {
	case PRESET_STATUS_UNKNOWN:	params = ',1,1'
	case PRESET_STATUS_OFF:		params = ',2,2'
	case PRESET_STATUS_ON:		params = ',3,3'
	case PRESET_STATUS_PARTIAL:	params = ',4,4'
    }
    sendCommand (DBG_MODULE, cmdDev, "'^ANI-',itoa(chan),',',params")
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

