MODULE_NAME='ZoneControl' (
    char	configFile[], char tpConfigFile[],
    dev		vdvZoneControl,
    dev		vdvAvControl)

#include 'ZoneConfig.axi'
#include 'TouchPanelConfig.axi'
#include 'TouchPanelPorts.axi'

DEFINE_CONSTANT

integer ZONE_CONTROL_POWER_OFF_ALL	= 11
integer ZONE_CONTROL_POWER_OFF_AV	= 12

DEFINE_VARIABLE

volatile char DBG_MODULE[] = 'ZoneControl'

// Track the zone selection on each TP
persistent integer gTpZoneSelect[TP_MAX_PANELS]

// The TP devices
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTpZoneSelect[TP_MAX_PANELS]
volatile dev		gDvTpZoneControl[TP_MAX_PANELS]


DEFINE_EVENT

BUTTON_EVENT[gDvTpZoneSelect, ZCFG_ZONE_SELECT]  // Zone selection button presses
{
    PUSH:
    {
	// all channels map directly to input IDs
	doTpZoneSelect (get_last(gDvTpZoneSelect), button.input.channel, 0)
    }
}

BUTTON_EVENT[gDvTpZoneSelect, ZCFG_ZONE_SELECT_PREV]
{
    PUSH:
    {
	doTpZoneSelectPrev (get_last(gDvTpZoneSelect))
    }
}

BUTTON_EVENT[gDvTpZoneSelect, ZCFG_ZONE_SELECT_NEXT]
{
    PUSH:
    {
	doTpZoneSelectNext (get_last(gDvTpZoneSelect))
    }
}


DATA_EVENT[gDvTpZoneSelect]
{
    ONLINE:
    {
	// Reconnected to TP; update the buttons
	integer tpId
	integer zoneId
	tpId = get_last(gDvTpZoneSelect)
	updateTpZoneList (tpId)
	zoneId = gTpZoneSelect[tpId]
	doTpZoneSelect (tpId, zoneId, 1)
	debug (DBG_MODULE, 1, "'Restored TP selections: ',devtoa(gDvTpZoneSelect[tpId])")
    }
    OFFLINE: {}
    STRING: { debug (DBG_MODULE, 8, "'received string from TP (',devtoa(data.device),'): ',data.text") }
}

DEFINE_FUNCTION doTpZoneSelect (integer tpId, integer zoneId, integer refresh)
{
    integer prevZoneId
    prevZoneId = gTpZoneSelect[tpId]
    if (refresh || (zoneId != prevZoneId))
    {
        gTpZoneSelect[tpId] = zoneId
        if (zoneId > 0)
    	{
	    debug (DBG_MODULE, 5, "'TP ',devtoa(gDvTpZoneSelect[tpId]),': selected zone ',itoa(zoneId),
	    	     		   ' (',gAllZones[zoneId].mName,')'")
	    send_command gDvTpZoneSelect[tpId],"'TEXT',itoa(ZCFG_ADDRESS_ZONE_NAME),'-',gAllZones[zoneId].mName"
	    send_command gDvTpZoneSelect[tpId],"'TEXT',itoa(ZCFG_ADDRESS_ZONE_SHORT_NAME),'-',gAllZones[zoneId].mShortName"
	    doZoneSwitch (tpId, zoneId, refresh)
    	}
    	else
    	{
	    debug (DBG_MODULE, 5, "'TP ',devtoa(gDvTpZoneSelect[tpId]),': no selected zone'")
	    send_command gDvTpZoneSelect[tpId],"'TEXT',itoa(ZCFG_ADDRESS_ZONE_NAME),'-Press to Select a Zone'"
	    send_command gDvTpZoneSelect[tpId],"'TEXT',itoa(ZCFG_ADDRESS_ZONE_SHORT_NAME),'-Select Zone'"
    	}
    }
}

DEFINE_FUNCTION doTpZoneSelectPrev (integer tpId)
{
    integer zoneId
    zoneId = gTpZoneSelect[tpId]
    if (zoneId <= 1)
    {
	zoneId = length_array(gAllZones)
    }
    else
    {
	zoneId--
    }
    doTpZoneSelect (tpId, zoneId, 0)
}

DEFINE_FUNCTION doTpZoneSelectNext (integer tpId)
{
    integer zoneId
    zoneId = gTpZoneSelect[tpId]
    if (zoneId >= length_array(gAllZones))
    {
	zoneId = 1
    }
    else
    {
	zoneId++
    }
    doTpZoneSelect (tpId, zoneId, 0)
}

DEFINE_FUNCTION doTpZoneSelectByOutput (integer tpId, integer outputId)
{
    // If the current zone does not contain the outputId, then select the first zone that does contain the outputId.
    if (findOutputInZone (gTpZoneSelect[tpId], outputId))
    {
	debug (DBG_MODULE, 7, "'output ',itoa(outputId),' is part of current zone (',
	      		      itoa(gTpZoneSelect[tpId]),'); no change'")
    }
    else
    {
	integer zoneId
	debug (DBG_MODULE, 4, "'output ',itoa(outputId),' is NOT part of current zone (',
	      		      itoa(gTpZoneSelect[tpId]),'); searching for new zone...'")
    	for (zoneId = 1; zoneId <= length_array(gAllZones); zoneId++)
	{
	    if (findOutputInZone (zoneId, outputId))
	    {
		doTpZoneSelect (tpId, zoneId, 1)
		return
	    }
	}
    }
    debug (DBG_MODULE, 4, "'could NOT find new zone for output ',itoa(outputId)")
}

DEFINE_FUNCTION integer findOutputInZone (zoneId, outputId)
{
    if (zoneId > 0)
    {
	integer i
    	for (i = length_array(gAllZones[zoneId].mOutputIds); i > 0; i--)
    	{
	    if (gAllZones[zoneId].mOutputIds[i] = outputId)
	        return zoneId
	}
    }
    return 0
}

DEFINE_FUNCTION updateTpZoneList (integer tpId)
{
    integer i
    if (tpIsIridium(gPanels,tpId))
    {
	send_command gDvTpZoneSelect[tpId],"'IRLB_CLEAR-',itoa(ZCFG_ADDRESS_ZONE_SELECT)"
	send_command gDvTpZoneSelect[tpId],"'IRLB_INDENT-',itoa(ZCFG_ADDRESS_ZONE_SELECT),',3'"
	send_command gDvTpZoneSelect[tpId],"'IRLB_SCROLL_COLOR-',itoa(ZCFG_ADDRESS_ZONE_SELECT),',Grey'"
	send_command gDvTpZoneSelect[tpId],"'IRLB_ADD-',itoa(ZCFG_ADDRESS_ZONE_SELECT),',',itoa(length_array(gAllZones)),',1'"
    }
    for (i = 1; i <= length_array(gAllZones); i++)
    {
	debug (DBG_MODULE, 9, "'sending zone name update to ',devtoa(gDvTpZoneSelect[tpId]),': ',gAllZones[i].mName")
	send_command gDvTpZoneSelect[tpId],"'TEXT',itoa(i),'-',gAllZones[i].mName"
	send_command gDvTpZoneSelect[tpId],"'IRLB_TEXT-',itoa(ZCFG_ADDRESS_ZONE_SELECT),',',
				itoa(i),',',gAllZones[i].mName"
	send_command gDvTpZoneSelect[tpId],"'IRLB_CHANNEL-',itoa(ZCFG_ADDRESS_ZONE_SELECT),',',
				itoa(i),',',itoa(TP_PORT_ZONE_SELECT),',',itoa(i)"
    }
    for (; i <= ZCFG_MAX_ZONES; i++)
    {
	send_command gDvTpZoneSelect[tpId],"'TEXT',itoa(i),'-'"
    }
}


DEFINE_EVENT

BUTTON_EVENT[gDvTpZoneControl, ZONE_CONTROL_POWER_OFF_AV]
{
    PUSH: { doZonePowerOffAv (gTpZoneSelect[get_last(gDvTpZoneControl)]) }
}

BUTTON_EVENT[gDvTpZoneControl, ZONE_CONTROL_POWER_OFF_ALL]
{
    PUSH: { doZonePowerOffAll (gTpZoneSelect[get_last(gDvTpZoneControl)]) }
}

DEFINE_FUNCTION doZonePowerOffAv (integer zoneId)
{
    if (zoneId > 0)
    {
	integer i
	char cmdStr[128]
	cmdStr = "'OUTPUTS-POFF'"
        debug (DBG_MODULE, 4, "'Powering OFF all A/V in zone: ',gAllZones[zoneId].mName")
        for (i = 1; i <= length_array(gAllZones[zoneId].mOutputIds); i++)
    	{
	    cmdStr = "cmdStr,'O',itoa(gAllZones[zoneId].mOutputIds[i])"
	}
	debug (DBG_MODULE, 9, "'send_command ',devtoa(vdvAvControl),', ',cmdStr")
	send_command vdvAvControl, cmdStr
    }
    else
    {
        debug (DBG_MODULE, 4, "'doZonePowerOffAv(): no Zone selected'")
    }    
}

DEFINE_FUNCTION doZonePowerOffAll (integer zoneId)
{
    doZonePowerOffAv (zoneId)
}


DEFINE_FUNCTION doZoneSwitch (integer tpId, integer zoneId, integer refresh)
{
    // Tell other interested parties what the list of A/V outputs is for this zone and whether
    // this was only a refresh (as opposed an explicit switch).
    integer i
    char cmdStr[128]
    cmdStr = "'OUTPUTS-TP',itoa(tpId),'REF',itoa(refresh)"
    if (zoneId > 0)
    {
        debug (DBG_MODULE, 4, "'switching to zone: ',gAllZones[zoneId].mName")
	cmdStr = "cmdStr,'Z',itoa(zoneId)"
        for (i = 1; i <= length_array(gAllZones[zoneId].mOutputIds); i++)
    	{
	    cmdStr = "cmdStr,'O',itoa(gAllZones[zoneId].mOutputIds[i])"
	}
    }
    debug (DBG_MODULE, 9, "'send_command ',devtoa(vdvAvControl),', ',cmdStr")
    send_command vdvAvControl, cmdStr
}

DEFINE_EVENT

// Handle commands from other modules
DATA_EVENT[vdvZoneControl]
{
    ONLINE: {}
    OFFLINE: {}
    COMMAND:
    {
	debug (DBG_MODULE, 5, "'received zone control command from ',devtoa(data.device),': ',data.text")
	handleZoneControlCommand (data.text)
    }
    STRING:
    {
	debug (DBG_MODULE, 5, "'received A/V group control string from ',devtoa(data.device),': ',data.text")
    }
}

DEFINE_FUNCTION handleZoneControlCommand (char msg[])
{
    select
    {
    active (find_string(msg,'SETZONE-',1)):
    {
	// Set the zone for a TP
	remove_string(msg,'SETZONE-',1)
	select
	{
	active (find_string(msg,'TP',1)):
	{
	    // 'TP' for TouchPad
	    integer tpId, zoneId
	    remove_string(msg,'TP',1)
	    tpId = atoi(msg)
	    if (find_string(msg,'Z',1))
	    {
		remove_string(msg,'Z',1)
		zoneId = atoi(msg)
	    }
	    doTpZoneSelect (tpId, zoneId, 0)
	} // active
	} // select
    } // active

    active (find_string(msg,'MATCHZONE-',1)):
    {
	// Set the zone for a TP based on an output ID
	remove_string(msg,'MATCHZONE-',1)
	select
	{
	active (find_string(msg,'TP',1)):
	{
	    // 'TP' for TouchPad
	    integer tpId, outputId
	    remove_string(msg,'TP',1)
	    tpId = atoi(msg)
	    if (find_string(msg,'O',1))
	    {
		remove_string(msg,'O',1)
		outputId = atoi(msg)
	    }
	    doTpZoneSelectByOutput (tpId, outputId)
	} // active
	} // select
    } // active
    } // select
}

DEFINE_START
{
    tpReadConfigFile ('ZoneControl', tpConfigFile, gPanels)
    readConfigFile (DBG_MODULE, configFile)

    set_length_array (gTpZoneSelect, length_array(gPanels))
    tpMakeLocalDevArray ('ZoneControl', gDvTpZoneSelect,  gPanels, TP_PORT_ZONE_SELECT) // gGeneral.mTpPortPlaylistSelect)
    tpMakeLocalDevArray ('ZoneControl', gDvTpZoneControl, gPanels, TP_PORT_ZONE_CONTROL) // gGeneral.mTpPortNowPlaying)
    rebuild_event()
}

