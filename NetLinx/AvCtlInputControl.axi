PROGRAM_NAME='AvCtlInputControl'

(*
 * This mini-module provides the service of relaying A/V input actions on touch panels to the native device.
 *)

(*
 * As a mini-module, this file is not a self-contained module. It is separated only
 * to make it easier to understand which parts of the larger module belong together.
 *)

DEFINE_VARIABLE


// The state of each TP's current input's supported channels
persistent integer gTpInputControls[TP_MAX_PANELS][CHAN_MAX_CHANNELS]

persistent sinteger gInputGain[AVCFG_MAX_INPUTS]

DEFINE_FUNCTION updateTpInputControls (integer tpId, integer forceControlResync)
{
    integer i, inputId, outputId
    outputId = gTpOutputSelect[tpId]
    inputId = gTpInput[tpId]
    if (outputId > 0)
    {
        inputId = gInputByOutput[outputId]
    }
    gTpInput[tpId] = inputId
    if (inputId > 0)
    {
	// Update any titles
	updateTpInputName (tpId, inputId)
	debug (DBG_MODULE, 5, "'TP ',devtoa(dvTpInputSelect[tpId]),': selected input ',itoa(inputId),
				       ' (',gAllInputs[inputId].mName,')'")

	// Show only the buttons supported by this input
	if (tpIsIridium(gPanels,tpId))
	{
	    // iRidium doesn't support channel lists yet
	    integer maskVal
	    for (i = 1; i <= CHAN_MAX_CHANNELS; i++)
	    {
		maskVal = gAllInputs[inputId].mChannelMask[i]
		if (forceControlResync || (gTpInputControls[tpId][i] != maskVal))
		{
		    debug (DBG_MODULE, 9, "'send_command ',devtoa(dvTpInputControl[tpId]),', ^SHO-',itoa(i),',',itoa(maskVal)")
		    send_command dvTpInputControl[tpId], "'^SHO-',itoa(i),',',itoa(maskVal)"
		    gTpInputControls[tpId][i] = maskVal
		}
	    }
	}
	else
	{
	    debug (DBG_MODULE, 5, "'send_command ',devtoa(dvTpInputControl[tpId]),', ^SHO-1.500,0'")
	    debug (DBG_MODULE, 5, "'send_command ',devtoa(dvTpInputControl[tpId]),', ^SHO-',gAllInputs[inputId].mSupportedChannels,',1'")
	    send_command dvTpInputControl[tpId], "'^SHO-1.500,0'"
	    send_command dvTpInputControl[tpId], "'^SHO-',gAllInputs[inputId].mSupportedChannels,',1'"
	}
    }
    else
    {
	if (tpIsIridium(gPanels,tpId))
	{
	    for (i = 1; i <= CHAN_MAX_CHANNELS; i++)
	    {
		if (forceControlResync || (gTpInputControls[tpId][i] != 0))
		{
		    debug (DBG_MODULE, 9, "'send_command ',devtoa(dvTpInputControl[tpId]),', ^SHO-',itoa(i),',0'")
	    	    send_command dvTpInputControl[tpId], "'^SHO-',itoa(i),',0'"
	    	    gTpInputControls[tpId][i] = 0
		}
	    }
	}
	else
	{
	    send_command dvTpInputControl[tpId], "'^SHO-1.500,0'"
	}
    }    
}

DEFINE_FUNCTION stopAllAvInputs()
{
    integer inputId
    for (inputId = 1; inputId <= length_array(gAllInputs); inputId++)
    {
	pulse [gAllInputs[inputId].mDev, CHAN_STOP]
    }
}

DEFINE_EVENT

// Relay channel operations for selected input
BUTTON_EVENT[dvTpInputControl, 0]
{
    PUSH:           { doAvInputRelay (get_last(dvTpInputControl), button.input.channel) }
    HOLD[3,REPEAT]: { }
    RELEASE: {}
}

DEFINE_FUNCTION doAvInputRelay (integer tpId, integer chan)
{
    integer inputId
    integer mappedChannel
    inputId = gTpInput[tpId]
    mappedChannel = gAllInputs[inputId].mChannelMap[chan]
    if (mappedChannel = 0)
	mappedChannel = chan
    debug (DBG_MODULE, 8, "'relaying input button press on channel ',itoa(mappedChannel),' to device ',devtoa(gAllInputs[inputId].mDev)")
    pulse [gAllInputs[inputId].mDev, mappedChannel]
}
