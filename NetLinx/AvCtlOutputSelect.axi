PROGRAM_NAME='AvCtlOutputSelect'

(*
 * This mini-module provides the service of managing A/V input selections on touch panels and
 * updating of touch panel screens with buttons appropriate for the current input.
 *
 * In order to perform these services, we need to track which player each TP 
 * is managing. AV Input selection for a TP can happen directly from the TP or
 * from another module. In any case, when an input is selected, the buttons
 * shown on the TP may be updated according to the buttons supported by the 
 * input.
 *)

(*
 * As a mini-module, this file is not a self-contained module. It is separated only
 * to make it easier to understand which parts of the larger module belong together.
 *)

DEFINE_CONSTANT

DEFINE_VARIABLE

// gOutputSelectList is the list of outputs currently available on the TP. This
// list can change over time (including by external modules, such as ZoneControl).
// gOutputSelect is an index into the gOutputSelectList array and represents the
// primary output currently selected on the TP.
non_volatile integer gTpOutputSelectList[TP_MAX_PANELS][AVCFG_MAX_OUTPUTS]
non_volatile integer gTpOutputSelect[TP_MAX_PANELS]
non_volatile integer gTpZoneSelect[TP_MAX_PANELS]
non_volatile integer gTpOutputSelectByZone[TP_MAX_PANELS][32]

DEFINE_EVENT

BUTTON_EVENT[dvTpOutputSelect, AVCFG_OUTPUT_SELECT]
{
    PUSH:
    {
	// Force the hiding of the output selection popups
     	send_command dvTpOutputSelect[get_last(dvTpOutputSelect)],"'@PPF-',AV_OUTPUT_SELECTOR_FULL_POPUP"
     	send_command dvTpOutputSelect[get_last(dvTpOutputSelect)],"'@PPF-',AV_OUTPUT_SELECTOR_MINI_POPUP"
	doTpOutputSelect (get_last(dvTpOutputSelect), button.input.channel, 0)
    }
}

BUTTON_EVENT[dvTpOutputSelect, AVCFG_OUTPUT_SELECT_PREV]
{
    PUSH: { doTpOutputSelectPrev (get_last(dvTpOutputSelect)) }
}

BUTTON_EVENT[dvTpOutputSelect, AVCFG_OUTPUT_SELECT_NEXT]
{
    PUSH: { doTpOutputSelectNext (get_last(dvTpOutputSelect)) }
}

DEFINE_FUNCTION doTpOutputSelect (integer tpId, integer outputId, integer force)
{
    integer prevOutputId
    prevOutputId = gTpOutputSelect[tpId]

    // Send update to the first set of volume controls on this TP
//    gStatus.power[gOutputSelect[tpId][1]] = ACFG_POWER_STATE_ON
//    updateTpVolumeState (tpId, 1, scaleVolumeToLevel(gStatus.volume[gOutputSelect[tpId][1]]),
//			 1, gStatus.volumeMute[gOutputSelect[tpId][1]])

    debug (DBG_MODULE,9,"'Output Channel Selection Handler -- ',itoa(outputId)")
    if (force || (outputId != prevOutputId))
    {
	integer multipleOutputs
	gTpOutputSelect[tpId] = outputId
	setTpZoneOutput (tpId, outputId)
        if (outputId > 0)
    	{
//	    outputId = gTpOutputSelectList[tpId][outputIdId]
	    if (outputId = AVCFG_OUTPUT_SELECT_ALL)
	    {
		debug (DBG_MODULE, 5, "'TP ',devtoa(dvTpOutputSelect[tpId]),': selected output ',itoa(outputId),' (ALL)'")
		send_command dvTpOutputSelect[tpId],"'TEXT',AVCFG_ADDRESS_OUTPUT_NAME,'-ALL'"
		send_command dvTpOutputSelect[tpId],"'TEXT',AVCFG_ADDRESS_OUTPUT_SHORT_NAME,'-ALL'"
	    }
	    else
	    {
		debug (DBG_MODULE, 5, "'TP ',devtoa(dvTpOutputSelect[tpId]),': selected output ',itoa(outputId),
				       ' (',gAllOutputs[outputId].mName,')'")
		send_command dvTpOutputSelect[tpId],"'TEXT',AVCFG_ADDRESS_OUTPUT_NAME,'-',gAllOutputs[outputId].mName"
		send_command dvTpOutputSelect[tpId],"'TEXT',AVCFG_ADDRESS_OUTPUT_SHORT_NAME,'-',gAllOutputs[outputId].mShortName"
		send_command dvTpOutputControl[tpId],"'^SHO-',itoa(CHAN_POWER_SLAVE_TOGGLE),',',
					itoa(gAllOutputs[outputId].mAvrTvId>0)"
	    }

	    // Check the power button status(es)
	    checkTpOutputPower (tpId, outputId)
	    if (gAllOutputs[outputId].mAvrTvId)
	    {
		checkTpOutputPower (tpId, gAllOutputs[outputId].mAvrTvId)
	    }

	    // Make sure the current zone contains this output ID
	    checkTpOutputZone (tpId, outputId)
	}
    	else
    	{
	    debug (DBG_MODULE, 5, "'TP ',devtoa(dvTpOutputSelect[tpId]),': no selected Output'")
	    send_command dvTpOutputSelect[tpId],"'TEXT',AVCFG_ADDRESS_OUTPUT_NAME,'-Press to Select Output'"
	    send_command dvTpOutputSelect[tpId],"'TEXT',AVCFG_ADDRESS_OUTPUT_SHORT_NAME,'-Select Output'"
		send_command dvTpOutputControl[tpId],"'^SHO-',itoa(CHAN_POWER_SLAVE_TOGGLE),',0'"
    	}
	// Enable or disable the output selection popup and the prev/next buttons
(*
	multipleOutputs = (length_array(gTpOutputSelectList[tpId]) > 1)
//	send_command dvTpOutputSelect[tpId], "'^ENA-',AVCFG_ADDRESS_OUTPUT_NAME,',',itoa(multipleOutputs)"
//	send_command dvTpOutputSelect[tpId], "'^ENA-',AVCFG_ADDRESS_OUTPUT_SHORT_NAME,',',itoa(multipleOutputs)"
	send_command dvTpOutputSelect[tpId], "'^ENA-',AVCFG_ADDRESS_OUTPUT_SELECT_NEXT,',',itoa(multipleOutputs)"
	send_command dvTpOutputSelect[tpId], "'^ENA-',AVCFG_ADDRESS_OUTPUT_SELECT_PREV,',',itoa(multipleOutputs)"
*)

	// Update the inputs for this TP/output
	updateTpInputs (tpId)

	// Reset the controls for the input connected to this output
	updateTpInputControls (tpId, 0)
	updateTpOutputControls (tpId)
    }
}

DEFINE_FUNCTION doTpOutputSelectPrev (integer tpId)
{
    integer outputId, prevOutputId, i
    outputId = gTpOutputSelect[tpId]
    prevOutputId = outputId
    for (i = 1; i <= length_array(gTpOutputSelectList[tpId]); i++)
    {
	if (outputId = gTpOutputSelectList[tpId][i])
	{
	    if (i = 1)
	    {
		prevOutputId = gTpOutputSelectList[tpId][length_array(gTpOutputSelectList[tpId])]
	    }
	    else
	    {
		prevOutputId = gTpOutputSelectList[tpId][i-1]
	    }
	    break
	}
    }
    if (outputId != prevOutputId)
    {
        doTpOutputSelect (tpId, prevOutputId, 0)
    }
}

DEFINE_FUNCTION doTpOutputSelectNext (integer tpId)
{
    integer outputId, nextOutputId, i
    outputId = gTpOutputSelect[tpId]
    nextOutputId = outputId
    for (i = 1; i <= length_array(gTpOutputSelectList[tpId]); i++)
    {
	if (outputId = gTpOutputSelectList[tpId][i])
	{
	    if (i < length_array(gTpOutputSelectList[tpId]))
	    {
		nextOutputId = gTpOutputSelectList[tpId][i+1]
	    }
	    else
	    {
		nextOutputId = gTpOutputSelectList[tpId][1]
	    }
	    break
	}
    }
    if (outputId != nextOutputId)
    {
        doTpOutputSelect (tpId, nextOutputId, 0)
    }
}

DEFINE_FUNCTION doTpSetZone (integer tpId, integer zoneId, integer updateSelection)
{
    debug (DBG_MODULE,9,"'setting to A/V zone: ',itoa(zoneId)")
    if (zoneId > 0)
    {
	integer outputId
	gTpZoneSelect[tpId] = zoneId
	outputId = gTpOutputSelectByZone[tpId][zoneId]
	if ((outputId = 0) && (length_array(gTpOutputSelectList[tpId]) > 0))
	{
	    outputId = gTpOutputSelectList[tpId][1]
	}
	if (updateSelection)
	{
	    doTpOutputSelect (tpId, outputId, 0)
	}
    }
    updateTpOutputListMini(tpId)
}

DEFINE_FUNCTION updateTpOutputListFull (integer tpId)
{
    select
    {
    active (tpIsIridium(gPanels,tpId) && gTpInfo[tpId].mEnabled):
	updateTpOutputListFull_Iridium (tpId, gTpInfo[tpId])
    active (tpIsIridium(gPanels,tpId) && !gTpInfo[tpId].mEnabled):
	updateTpOutputListFull_Iridium (tpId, gGeneral.mTpDefaults)
    active (!tpIsIridium(gPanels,tpId) && gTpInfo[tpId].mEnabled):
	updateTpOutputListFull_Standard (tpId, gTpInfo[tpId])
    active (!tpIsIridium(gPanels,tpId) && !gTpInfo[tpId].mEnabled):
	updateTpOutputListFull_Standard (tpId, gGeneral.mTpDefaults)
    }
}

DEFINE_FUNCTION updateTpOutputListMini (integer tpId)
{
    select
    {
    active (tpIsIridium(gPanels,tpId) && gTpInfo[tpId].mEnabled):
	updateTpOutputListMini_Iridium (tpId, gTpInfo[tpId])
    active (tpIsIridium(gPanels,tpId) && !gTpInfo[tpId].mEnabled):
	updateTpOutputListMini_Iridium (tpId, gGeneral.mTpDefaults)
    active (!tpIsIridium(gPanels,tpId) && gTpInfo[tpId].mEnabled):
	updateTpOutputListMini_Standard (tpId, gTpInfo[tpId])
    active (!tpIsIridium(gPanels,tpId) && !gTpInfo[tpId].mEnabled):
	updateTpOutputListMini_Standard (tpId, gGeneral.mTpDefaults)
    }
}

DEFINE_FUNCTION updateTpOutputListFull_Iridium (integer tpId, AvTpInfo tpInfo)
{
    integer outputId, i
    send_command dvTpOutputSelect[tpId],"'IRLB_CLEAR-',       AVCFG_ADDRESS_OUTPUT_SELECT_AUDIO"
    send_command dvTpOutputSelect[tpId],"'IRLB_INDENT-',      AVCFG_ADDRESS_OUTPUT_SELECT_AUDIO,',3'"
    send_command dvTpOutputSelect[tpId],"'IRLB_SCROLL_COLOR-',AVCFG_ADDRESS_OUTPUT_SELECT_AUDIO,',Grey'"
    send_command dvTpOutputSelect[tpId],"'IRLB_ADD-',         AVCFG_ADDRESS_OUTPUT_SELECT_AUDIO,',',
		    itoa(length_array(tpInfo.mAudioOutputListOrder)),',1'"
    for (i = 1; i <= length_array(tpInfo.mAudioOutputListOrder); i++)
    {
	outputId = tpInfo.mAudioOutputListOrder[i]
	send_command dvTpOutputSelect[tpId],"'IRLB_TEXT-',    AVCFG_ADDRESS_OUTPUT_SELECT_AUDIO,',',
		itoa(i),',',gAllOutputs[outputId].mName"
	send_command dvTpOutputSelect[tpId],"'IRLB_CHANNEL-', AVCFG_ADDRESS_OUTPUT_SELECT_AUDIO,',',
		itoa(i),',',itoa(TP_PORT_AV_OUTPUT_SELECT),',',itoa(outputId)"
    }
    send_command dvTpOutputSelect[tpId],"'IRLB_CLEAR-',       AVCFG_ADDRESS_OUTPUT_SELECT_VIDEO"
    send_command dvTpOutputSelect[tpId],"'IRLB_INDENT-',      AVCFG_ADDRESS_OUTPUT_SELECT_VIDEO,',3'"
    send_command dvTpOutputSelect[tpId],"'IRLB_SCROLL_COLOR-',AVCFG_ADDRESS_OUTPUT_SELECT_VIDEO,',Grey'"
    send_command dvTpOutputSelect[tpId],"'IRLB_ADD-',         AVCFG_ADDRESS_OUTPUT_SELECT_VIDEO,',',
		    itoa(length_array(tpInfo.mVideoOutputListOrder)),',1'"
    for (i = 1; i <= length_array(tpInfo.mVideoOutputListOrder); i++)
    {
	outputId = tpInfo.mVideoOutputListOrder[i]
	send_command dvTpOutputSelect[tpId],"'IRLB_TEXT-',    AVCFG_ADDRESS_OUTPUT_SELECT_VIDEO,',',
		itoa(i),',',gAllOutputs[outputId].mName"
	send_command dvTpOutputSelect[tpId],"'IRLB_CHANNEL-', AVCFG_ADDRESS_OUTPUT_SELECT_VIDEO,',',
		itoa(i),',',itoa(TP_PORT_AV_OUTPUT_SELECT),',',itoa(outputId)"
    }
}

DEFINE_FUNCTION updateTpOutputListFull_Standard (integer tpId, AvTpInfo tpInfo)
{
    integer outputId, i
    for (i = 1; i <= length_array(tpInfo.mVideoOutputListOrder); i++)
    {
	outputId = tpInfo.mVideoOutputListOrder[i]
	send_command dvTpOutputSelect[tpId],"'TEXT-',itoa(i),',',gAllOutputs[i].mName"
    }
    for (; i <= length_array(tpInfo.mAudioOutputListOrder); i++)
    {
	outputId = tpInfo.mAudioOutputListOrder[i]
	send_command dvTpOutputSelect[tpId],"'TEXT-',itoa(i),',',gAllOutputs[i].mName"
    }
    for (; i <= AVCFG_MAX_OUTPUTS; i++)
    {
	send_command dvTpOutputSelect[tpId],"'TEXT-',itoa(i),','"
    }
}

DEFINE_FUNCTION updateTpOutputListMini_Iridium (integer tpId, AvTpInfo tpInfo)
{
    integer outputId, i
    send_command dvTpOutputSelect[tpId],"'IRLB_CLEAR-',       AVCFG_ADDRESS_OUTPUT_SELECT_MINI"
    send_command dvTpOutputSelect[tpId],"'IRLB_INDENT-',      AVCFG_ADDRESS_OUTPUT_SELECT_MINI,',3'"
    send_command dvTpOutputSelect[tpId],"'IRLB_SCROLL_COLOR-',AVCFG_ADDRESS_OUTPUT_SELECT_MINI,',Grey'"
    send_command dvTpOutputSelect[tpId],"'IRLB_ADD-',         AVCFG_ADDRESS_OUTPUT_SELECT_MINI,',',
		    itoa(length_array(gTpOutputSelectList[tpId])),',1'"
    for (i = 1; i <= length_array(gTpOutputSelectList[tpId]); i++)
    {
	outputId = gTpOutputSelectList[tpId][i]
	send_command dvTpOutputSelect[tpId],"'IRLB_TEXT-',    AVCFG_ADDRESS_OUTPUT_SELECT_MINI,',',
		    itoa(i),',',gAllOutputs[outputId].mName"
	send_command dvTpOutputSelect[tpId],"'IRLB_CHANNEL-', AVCFG_ADDRESS_OUTPUT_SELECT_MINI,',',
		    itoa(i),',',itoa(TP_PORT_AV_OUTPUT_SELECT),',',itoa(outputId)"
    }
}

DEFINE_FUNCTION updateTpOutputListMini_Standard (integer tpId, AvTpInfo tpInfo)
{
    integer outputId, i
    for (i = 1; i <= length_array(gTpOutputSelectList[tpId]); i++)
    {
	outputId = gTpOutputSelectList[tpId][i]
	send_command dvTpOutputSelect[tpId],"'TEXT-',itoa(i),',',gAllOutputs[outputId].mName"
    }
    for (; i <= AVCFG_MAX_OUTPUTS; i++)
    {
	send_command dvTpOutputSelect[tpId],"'TEXT-',itoa(i),','"
    }
}

DEFINE_FUNCTION integer getTpOutputId (integer tpId)
{
    integer outputId
    outputId = gTpOutputSelect[tpId]
    if (outputId > 0)
    {
//	integer outputId
//	outputId = gTpOutputSelectList[tpId][outputIdId]
	if (outputId = AVCFG_OUTPUT_SELECT_ALL)
	{
	    // If we're looking at the ALL output then use the list of inputs 
	    // for the first output in the list -- which may or may not be the
	    // same as the rest of the list, but usually it is and errors will
	    // be picked up later.
	    outputId = 1
	}
	return outputId
    }
    return 0
}

DEFINE_FUNCTION setTpZoneOutput (integer tpId, integer outputId)
{
    integer zoneId
    zoneId = gTpZoneSelect[tpId]
    if (zoneId > 0)
    {
	integer i
	for (i = 1; i <= length_array(gTpOutputSelectList[tpId]); i++)
	{
	    if (outputId = gTpOutputSelectList[tpId][i])
	    {
		gTpOutputSelectByZone[tpId][zoneId] = outputId
	    }
	}
    }
}
