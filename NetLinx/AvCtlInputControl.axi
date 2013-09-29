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
    integer i, prevInputId, inputId, outputId, update
    outputId = gTpOutputSelect[tpId]
    prevInputId = gTpInput[tpId]
    if (outputId > 0)
    {
        inputId = gInputByOutput[outputId]
    }
    else
    {
	inputId = 0
    }
    gTpInput[tpId] = inputId
    update = ((prevInputId = inputId) || forceControlResync)
    if (update)
    {
	sendCommand (DBG_MODULE, dvTpInputControl[tpId], "'^SHO-1.500,0'")
	if (inputId > 0)
	{
	    // Update any titles
	    updateTpInputName (tpId, inputId)
	    debug (DBG_MODULE, 5, "'TP ',devtoa(dvTpInputSelect[tpId]),': selected input ',itoa(inputId),' (',gAllInputs[inputId].mName,')'")

	    // Show only the buttons supported by this input
	    if (tpIsIridium(gPanels,tpId))
	    {
		// iRidium doesn't support long complex channel lists yet. Example:
		//   send_command 10005:7:0, ^SHO-1.3&6.19&21.23&27&28&42&43.50&61&62&81&82&96&101&104&105&108&151.154&201,1
		// only hits the first few addresses; perhaps a problem with not specifying a range
		integer buttonOn
		for (i = 1; i <= CHAN_MAX_CHANNELS; i++)
		{
		    buttonOn = gAllInputs[inputId].mChannelMask[i]
		    if (buttonOn)
		    {
			sendCommand (DBG_MODULE, dvTpInputControl[tpId], "'^SHO-',itoa(i),',1'")
		    }
		}
	    }
	    else
	    {
		sendCommand (DBG_MODULE, dvTpInputControl[tpId], "'^SHO-',gAllInputs[inputId].mSupportedChannels,',1'")
	    }
	}
    }
    debug (DBG_MODULE, 5, "'TP ',devtoa(dvTpInputSelect[tpId]),': no update of buttons necessary'")
}

DEFINE_FUNCTION stopAllAvInputs()
{
    integer inputId
    for (inputId = 1; inputId <= length_array(gAllInputs); inputId++)
    {
	pulse [gAllInputs[inputId].mDev, CHAN_STOP]
    }
}

DEFINE_FUNCTION checkInputPowerOn (integer inputId)
{
    if (!gAllInputs[inputId].mAlwaysOn)
    {
	pulse [gAllInputs[inputId].mDev, CHAN_POWER_ON]
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
