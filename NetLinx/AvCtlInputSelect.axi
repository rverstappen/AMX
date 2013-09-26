PROGRAM_NAME='AvCtlInputSelect'

(*
 * This mini-module provides the service of managing A/V input selections on touch panels and
 * updating of touch panel screens with buttons appropriate for the current input.
 *
 * In order to perform these services, we need to track which input each TP 
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

// The state of each TP's current input selection
persistent integer gTpInput[TP_MAX_PANELS]

// Track the state of each input selection for each output
persistent integer gInputByOutput[AVCFG_MAX_OUTPUTS]

DEFINE_EVENT

// Handle input selection buttons
BUTTON_EVENT[dvTpInputSelect, AVCFG_INPUT_SELECT]
{
    PUSH: { doTpInputSelect (get_last(dvTpInputSelect), button.input.channel, 0) }
}

// Handle input selection commands
DATA_EVENT[vdvAvControl]
{
    ONLINE: {}
    OFFLINE: {}
    COMMAND:
    {
	debug (DBG_MODULE, 5, "'received command from ',devtoa(data.device),': ',data.text")
	select
	{
	active (find_string(data.text,'CHANGE',1)):
	{
	    // 'Change' command
	    select
	    {
	    active (find_string(data.text,'TP',1)):
	    {
		// 'TP' for TouchPanel
		integer tpId
		remove_string(data.text,'TP',1)
		tpId = atoi(data.text)
		select
		{
		active (find_string(data.text,'I',1)):
		{
		    integer inputId
		    remove_string(data.text,'I',1)
		    inputId = atoi(data.text)
		    doTpInputSelect (tpId, inputId, 0)
		} // active
		} // select
	    } // active
	    } // select
	} // active
	} // select
    }
    STRING:
    {
	debug (DBG_MODULE, 5, "'received string from ',devtoa(data.device),': ',data.text,' (ignored)'")
    }
}

DEFINE_FUNCTION doTpInputSelect (integer tpId, integer inputId, integer forceControlResync)
{
    integer prevInputId
    prevInputId = gTpInput[tpId]

    // Hide the popups, if showing
    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'@PPF-',AV_INPUT_SELECTOR_FULL_POPUP")
    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'@PPF-',AV_INPUT_SELECTOR_MINI_POPUP")

    if (!forceControlResync && (inputId = prevInputId))
    {
	debug (DBG_MODULE, 9, "'ignoring input selection for TP (',itoa(tpId),'): input hasn''t changed'")
	return
    }
    gTpInput[tpId] = inputId

    // Force turning on the input device
    pulse [gAllInputs[inputId].mDev, CHAN_POWER_ON]

    // Perform any switches necesary
    if (inputId != prevInputId)
    {
	doInputSwitch (tpId, inputId)
    }

    // Update the control buttons for this input
    updateTpInputControls (tpId, forceControlResync)
}

DEFINE_FUNCTION updateTpInputName (integer tpId, inputId)
{
    if (inputId > 0)
    {
   	sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'TEXT',AVCFG_ADDRESS_INPUT_NAME,      '-',gAllInputs[inputId].mName")
   	sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'TEXT',AVCFG_ADDRESS_INPUT_SHORT_NAME,'-',gAllInputs[inputId].mShortName")
    }
    else
    {
	if (gTpOutputSelect[tpId] > 0)
	{
	    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'TEXT',AVCFG_ADDRESS_INPUT_NAME, '-Press to Select Input'")
	}
	else
	{
	    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'TEXT',AVCFG_ADDRESS_INPUT_NAME, '-Select Input (After Output)'")
	}
   	sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'TEXT',AVCFG_ADDRESS_INPUT_SHORT_NAME,'-Select Input'")
    }
}

DEFINE_FUNCTION updateTpInputs (integer tpId)
{
    integer outputId, iRidium
    iRidium = tpIsIridium (gPanels,tpId)
    outputId = getTpOutputId (tpId)
    if (outputId > 0)
    {
	integer currInputId, i, inputId
	currInputId = gInputByOutput[outputId]
	updateTpInputName (tpId, currInputId)
	if (iRidium)
    	{
	    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'IRLB_CLEAR-',       AVCFG_ADDRESS_INPUT_SELECT")
	    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'IRLB_INDENT-',      AVCFG_ADDRESS_INPUT_SELECT,',3'")
	    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'IRLB_SCROLL_COLOR-',AVCFG_ADDRESS_INPUT_SELECT,',Grey'")
	    sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'IRLB_ADD-',         AVCFG_ADDRESS_INPUT_SELECT,',',
			itoa(length_array(gAllOutputs[outputId].mAllInputIds)),',1'")
        }
	for (i = 1; i <= length_array(gAllOutputs[outputId].mAllInputIds); i++)
	{
	    inputId = gAllOutputs[outputId].mAllInputIds[i]
	    debug (DBG_MODULE, 9, "'sending input name update to ',devtoa(dvTpInputSelect[tpId]),': ',
	    	  	       gAllInputs[inputId].mName")
	    if (iRidium)
	    {
		sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'IRLB_TEXT-',    AVCFG_ADDRESS_INPUT_SELECT,',',
			     itoa(i),',',gAllInputs[inputId].mName")
	    	sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'IRLB_CHANNEL-', AVCFG_ADDRESS_INPUT_SELECT,',',
			     itoa(i),',',itoa(TP_PORT_AV_INPUT_SELECT),',',itoa(gAllInputs[inputId].mId)")
	    }
	    else
	    {
	   	sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'TEXT',itoa(i),'-',gAllInputs[inputId].mName")
	    }
	}
	if (!iRidium)
	{
	    for (; i<= AVCFG_MAX_INPUTS; i++)
	    {
	   	sendCommand (DBG_MODULE, dvTpInputSelect[tpId],"'TEXT',itoa(i),'-'")
	    }
	}
    }
    else
    {
	debug (DBG_MODULE, 9, "'no output selected, so no input list to update'")
	updateTpInputName (tpId, 0)
    }
}

DEFINE_FUNCTION doInputSwitch (integer tpId, integer inputId)
{
    integer outputId
    outputId = getTpOutputId (tpId)
    select
    {
    active (outputId = AVCFG_OUTPUT_SELECT_ALL):
    {
	integer i
	for (i = 1; i <= gTpOutputSelectList[tpId]; i++)
	{
	    integer oId
	    oId = gTpOutputSelectList[tpId][i]
	    if (oId != AVCFG_OUTPUT_SELECT_ALL)
	    {
	        doInputOutputSwitch (inputId, oId)
	    }
	}
	gInputByOutput[outputId] = inputId
    }
    active (outputId > 0):
    {
	doInputOutputSwitch (inputId, outputId)
    } // active
    } // select
}

DEFINE_FUNCTION integer getInputIdForOutputId (integer outputId)
{
    return gInputByOutput[outputId]
}
