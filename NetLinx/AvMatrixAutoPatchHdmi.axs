MODULE_NAME='AvMatrixAutoPatchHdmi' (char configFile[])


DEFINE_VARIABLE

constant char DBG_MODULE[] = 'AutoPatch-HDMI'
volatile char bRecvBuf[1024]


#include 'Debug.axi'
#include 'AvMatrixCommon.axi'
#include 'AvMatrixConfigNoInputOutput.axi'


DEFINE_EVENT

DATA_EVENT[gGeneral.mDevSwitch]
{
    ONLINE:
    {
	debug (DBG_MODULE,1,"'AutoPatch Switcher (',devtoa(gGeneral.mDevSwitch),') is online'")
	sendString (DBG_MODULE,gGeneral.mDevSwitch,"'SET BAUD 9600,N,8,1 485 DISABLE'")
	sendString (DBG_MODULE,gGeneral.mDevSwitch,"'HSOFF'")
	sendString (DBG_MODULE,gGeneral.mDevSwitch,"'XOFF'")
        wait 39 // 3.9 seconds after online event
	{
	    handleMatrixStatusRequest()
	    wait 39 { checkAudioSwitchVolumeLevels() }
	}
    }
    OFFLINE:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mDevSwitch),') is offline'")
    }
    COMMAND:
    {
	debug (DBG_MODULE,2,"'Received command from Audio Switcher (',devtoa(gGeneral.mDevSwitch),'): ',data.text")
    }
    STRING:
    {
	debug (DBG_MODULE,2,"'Received string from Audio Switcher (',devtoa(gGeneral.mDevSwitch),'): ',data.text")
	handleSwitchResponse (bRecvBuf)
    }
    ONERROR:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mDevSwitch),') has an error: ', data.text")
    }
    STANDBY:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mDevSwitch),') is standby'")
    }
    AWAKE:
    {
	debug (DBG_MODULE,1,"'AutoPatch DSP (',devtoa(gGeneral.mDevSwitch),') is awake'")
    }
}


DEFINE_FUNCTION handleSwitchResponse (char buf[])
{
    debug (DBG_MODULE,9,"'handleAudioSwitchResponse: buffer contains: ',buf")
    while (length_array(buf) > 0)
    {
	select
	{
	active (find_string(buf,'S',1)):
	{
	    // Status message
	    AvMatrixMapping mappings[AV_MATRIX_MAX_INPUTS]
	    integer levelId
	    if (!find_string(buf,')',1))
	    {
		// We don't have the end of the status message yet, so let the 
		// buffer do its job
		debug (DBG_MODULE,7,"'handleSwitchResponse: incomplete buffer: ',buf")
		return
	    }
	    remove_string(buf,'S',1)
	    if (find_string(buf,'L',1))
	    {
		remove_string(buf,'L',1)
		levelId = atoi(buf)
	    }
	    select
	    {
	    active (find_string(buf,'O',1)):
	    {
		// 'O' for Output
		integer output
		remove_string(buf,'O',1)
		output = atoi(buf)
		select
		{
		active (find_string(buf,'VT( ',1)):
		{
		    remove_string(buf,'VT( ',1)
		    if (buf[1] = 'M')
		    {
//			checkAudioMuteStatus (output)
		    }
		    else
		    {
//		        checkAudioVolume (output, atoi(buf))
		    }
		    remove_string(buf,')',1)
		} // active 'VT('

		active (find_string(buf,'T( ',1)):
		{
		    integer input
		    remove_string(buf,'T( ',1)
		    input = atoi(buf)
		    debug (DBG_MODULE, 10, "'  received mapping: ',itoa(output),' => ',itoa(input)")
		    if (input > 0)
		    {
			createMatrixMappingSingle(mappings, input, output)
			sendMatrixStatusReply(mappings)			
// move to AvControl:        checkInputToOutput (getInputIdByAudioSwitchId(input),getOutputIdByAudioSwitchId(output))
		    }
		    remove_string(buf,')',1)
		} // active 'T('
		} // select
	    } // active 'O'

	    active (find_string(buf,'I',1)):
	    {
		// 'I' for Input
		integer input
		remove_string(buf,'I',1)
		input = atoi(buf)
		select
		{
		active (find_string(buf,'VT( ',1)):
		{
		    remove_string(buf,'VT( ',1)
		    if (buf[1] = 'M')
		    {
			// We don't handle input mutes right now
			debug (DBG_MODULE,6,"'ignoring gain mute: input=',itoa(input)")
		    }
		    else
		    {
//			checkAudioGain (input, atoi(buf))
		    }
		    remove_string(buf,')',1)
		} // active 'VT('
		active (find_string(buf,'T( ',1)):
		{
		    // The list of outputs for this input.
		    integer outputs[AV_MATRIX_MAX_OUTPUTS]
		    integer output, numOutputs
		    numOutputs = 0
		    remove_string(buf,'T( ',1)
		    for (output = atoi(buf);
			 output > 0;
			 output = atoi(buf))
		    {
//		        checkInputToOutput (getInputIdByAudioSwitchId(input),getOutputIdByAudioSwitchId(output))
			numOutputs++
			outputs[numOutputs] = output
			remove_string(buf,' ',1)
		    }
		    remove_string(buf,')',1)
		    if (numOutputs > 0)
		    {
			createMatrixMappingMultiple(mappings, input, outputs)
			sendMatrixStatusReply(mappings)
		    }
		} // active 'T('
		} // select
	    } // active 'I'
	    } // select
	} // active 'S'

	active (1):
	{
	    debug (DBG_MODULE,2,"'ignoring switch buf: ',buf")
	    set_length_array(buf,0)
	} // active 1
	} // select
    } // while
}

DEFINE_FUNCTION handleMatrixSwitch (AvMatrixMapping mappings[])
{
    integer i, numInputs
    numInputs = length_array(mappings)
    debug (DBG_MODULE, 10, "'handling matrix switch with ',itoa(length_array(mappings)),' mappings'")
    for (i = 1; i <= numInputs; i++)
    {
	integer o, numOutputs
	numOutputs = length_array(mappings[i].mOutputs)
	for (o = 1; o <= numOutputs; o++)
	{
	    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CI',itoa(mappings[i].mInput),'O',itoa(mappings[i].mOutputs[o])")
	}
    }
}

DEFINE_FUNCTION handleMatrixStatusRequest ()
{
    debug (DBG_MODULE, 6, 'handling status request')
    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, '?C')
}

DEFINE_FUNCTION checkAudioSwitchVolumeLevels ()
{
    integer output
    for (output = 1; output <= length_array(gGeneral.mMaxOutputs); output++)
    {
	sendString (DBG_MODULE, gGeneral.mDevSwitch, "'SL0O',itoa(output),'VT'")
    }
}

DEFINE_FUNCTION setAudioSwitchGainLevels ()
{
    integer input
    for (input = 1; input <= gGeneral.mMaxInputs; input++)
    {
	sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'T'")
    }
}

DEFINE_FUNCTION setAbsoluteGain (integer input, sinteger gain)
{
    debug (DBG_MODULE, 5,"'New gain value on input ',itoa(input),' == ',itoa(gain)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'VA',itoa(gain),'T'")
}

DEFINE_FUNCTION setAbsoluteVolume (integer output, sinteger vol)
{
    debug (DBG_MODULE, 5,"'New volume value on output ',itoa(output),' == ',itoa(vol)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VA',itoa(vol),'T'")
}

DEFINE_FUNCTION setRelativeVolume (integer output, sinteger vol)
{
    debug (DBG_MODULE, 5,"'Change volume value on output ',itoa(output),' == ',itoa(vol)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VR',itoa(vol),'T'")
}

DEFINE_FUNCTION setRelativeGain (integer input, sinteger vol)
{
    debug (DBG_MODULE, 5,"'Change gain value on intput ',itoa(input),' == ',itoa(vol)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'VR',itoa(vol),'T'")
}

DEFINE_FUNCTION setAbsoluteMute (integer output, integer muteOn)
{
(*
    debug (DBG_MODULE, 5,"'Setting mute status on output ',itoa(output),' == ',itoa(muteOn==ACFG_MUTE_STATE_ON)")
    if (muteOn = ACFG_MUTE_STATE_ON)
        sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VMT'")
    else
        sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VUT'")
*)
}

DEFINE_FUNCTION setAbsoluteOff (integer output)
{
    debug (DBG_MODULE, 5,"'Turn off output: ',itoa(output)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'DL0O',itoa(output),'T'")
}

DEFINE_FUNCTION doSwitch (integer input, integer output)
{
    debug (DBG_MODULE, 5,"'Switching input ',itoa(input),' to ',itoa(output)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'O',itoa(output),'T'")
}

DEFINE_FUNCTION doMainAudioSwitchOff (integer output)
{
    debug (DBG_MODULE, 1, "'switching OFF audio output source ',itoa(output)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'DO',itoa(output),'T'")
}

DEFINE_FUNCTION doMainAudioSetAbsoluteVolume (integer output, sinteger volume)
{
    debug (DBG_MODULE, 1, "'setting audio output ',itoa(output),' volume to ',itoa(volume)")
    sendString (DBG_MODULE, gGeneral.mDevSwitch, "'CO',itoa(output),'VA',itoa(volume),'T'")
}


DEFINE_START
{
    readConfigFile ('AutoPatchDsp', configFile)
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'module is enabled.'")
	create_buffer gGeneral.mDevSwitch, bRecvBuf
    }
    else
    {
	debug (DBG_MODULE, 1, "'module is disabled.'")
    }
    rebuild_event()
}
