(*
 * Various controls for the audio and video switchers.
 *)

#include 'AvMatrixUtil.axi'

DEFINE_VARIABLE

volatile char bRecvBufVideo[1024]

DEFINE_FUNCTION doInputOutputSwitch (integer inputId, integer outputId)
{
    // Do the A/V switching, including changing scenes and/or local inputs, if necessary, since
    // the input may be either centrally switched or locally connected.
    integer needLocalSwitch
    integer prevInputId

    // Ensure that the power to the output is ON
    debug (DBG_MODULE, 9, "'doInputOutputSwitch (inputId=',itoa(inputId),', outputId=',itoa(outputId),')'")
    setOutputPowerStatus (outputId, POWER_STATUS_ON, 1, gAllInputs[inputId].mSlaveAutoOn)
    prevInputId = gInputByOutput[outputId]
    if (prevInputId = inputId)
    {
        debug (DBG_MODULE, 9, "'doInputOutputSwitch (inputId=',itoa(inputId),', outputId=',itoa(outputId),
	      		      '): no change'")
	return
    }
    debug (DBG_MODULE, 9, "'doInputOutputSwitch (inputId=',itoa(inputId),', outputId=',itoa(outputId),
    	  	       	  '): activating switch'")
    gInputByOutput[outputId] = inputId

    needLocalSwitch = 0
    if (prevInputId = 0)
    {
	needLocalSwitch = 1
    }
    if (gAllInputs[inputId].mLocationType = AVCFG_INPUT_TYPE_SWITCH)
    {
	// New output is on a main switch
	if (gAllOutputs[outputId].mAudioSwitchId > 0)
	{
	    debug (DBG_MODULE, 9, "gAllInputs[inputId].mName,': main audio switch changing...'")
	    doMainAudioSwitch (gAllInputs[inputId].mAudioSwitchId, gAllOutputs[outputId].mAudioSwitchId)
	}
	else
	{
	    debug (DBG_MODULE, 9, "gAllInputs[inputId].mName,': no audio switch config'")
	}
	if (gAllOutputs[outputId].mVideoSwitchId > 0)
	{
	    debug (DBG_MODULE, 9, "gAllInputs[inputId].mName,': main video switch changing...'")
	    doMainVideoSwitch (gAllInputs[inputId].mVideoSwitchId, gAllOutputs[outputId].mVideoSwitchId)
	}
	else
	{
	    debug (DBG_MODULE, 9, "gAllInputs[inputId].mName,': no video switch config'")
	}
debug (DBG_MODULE, 9, "'prevInputId: ', itoa(prevInputId)")
	if (prevInputId > 0)
	{
	    if (gAllInputs[prevInputId].mLocationType != AVCFG_INPUT_TYPE_SWITCH)
	    {
		needLocalSwitch = 1
	    }
	}
	if (needLocalSwitch)
	{
	    // We need to change the local input to the switched input
	    wait 20 // wait a couple of seconds, in case the display was powered off
	    {
		doLocalSwitch (outputId, selectLocalInputChannel(inputId,outputId))
		debug (DBG_MODULE, 9, "'checking slave TV input channel: ',gAllInputs[inputId].mSlaveInputChannel")
		if (gAllInputs[inputId].mSlaveInputChannel)
		{
		    wait 5
		    {
		        debug (DBG_MODULE, 5, 'changing slave TV input')
		        doLocalSwitch (gAllOutputs[outputId].mAvrTvId[1], gAllInputs[inputId].mSlaveInputChannel)
		    }
		}
	    }
	}
	else
	{
	    // If the previous player was also on the switch then we don't need to do anything else
	    debug (DBG_MODULE, 5, 'staying on switched input')
	}
    }
    else
    {
	// We are switching to a local input
	wait 20 // wait a couple of seconds, in case the display was powered off
	{
	    doLocalSwitch (outputId, gAllInputs[inputId].mLocalInputChannel)
	    if (gAllInputs[inputId].mSlaveInputChannel)
	    {
	        wait 5
		{
		    debug (DBG_MODULE, 5, 'changing slave TV input')
		    doLocalSwitch (gAllOutputs[outputId].mAvrTvId[1], gAllInputs[inputId].mSlaveInputChannel)
		}
	    }
	}

	// Make sure the input is turned ON
debug (DBG_MODULE, 9, "'Sending pulse to turn on input power: ', inputId")
	sendPulse (DBG_MODULE, gAllInputs[inputId].mDev, CHAN_POWER_ON)
    }

    if (prevInputId > 0)
    {
	if (gAllInputs[inputId].mSceneChannel != gAllInputs[prevInputId].mSceneChannel)
	{
	    wait 35 // wait 3.5 seconds, in case the display was powered off
	    {
		doLocalSetScene (outputId, gAllInputs[inputId].mSceneChannel)
	    }
	}
    }
    else
    {
	debug (DBG_MODULE, 7, "'No need to change scenes; scene channel: ',itoa(gAllInputs[inputId].mSceneChannel)")
    }
}

DEFINE_FUNCTION doMultiInputOutputSwitch (integer inputId, integer outputIds[])
{
    integer i
    for (i = 1; i <= length_array(outputIds); i++)
    {
	doInputOutputSwitch (inputId, outputIds[i])
    }
}

DEFINE_FUNCTION doMainAudioSwitch (integer input, integer output)
{
    char msg[1000]
    if (input > 0)
    {
	debug (DBG_MODULE, 1, "'switching audio input source ',itoa(input),' to output ',itoa(output)")
	encodeMatrixMappingSingle(msg, input, output)
	sendCommand (DBG_MODULE, gGeneral.mDevAudioControl, "'SWITCH:1:',msg")
    }
}

DEFINE_FUNCTION doMainAudioSwitchOff (integer output)
{
    char msg[1000]
    debug (DBG_MODULE, 1, "'switching OFF audio output ',itoa(output)")
    encodeOutputOffSingle(msg, output)
    sendCommand (DBG_MODULE, gGeneral.mDevAudioControl, msg)
}

DEFINE_FUNCTION doMainAudioSetAbsoluteVolume (integer output, sinteger volume)
{
    char msg[1000]
    debug (DBG_MODULE, 1, "'setting absolute volume for audio output source ',itoa(output)")
    encodeOutputAbsoluteVolume(msg, output, volume)
    sendCommand (DBG_MODULE, gGeneral.mDevAudioControl, msg)
}

DEFINE_FUNCTION doMainAudioSetRelativeVolume (integer output, sinteger volume)
{
    char msg[1000]
    debug (DBG_MODULE, 1, "'setting relative volume for audio output source ',itoa(output)")
    encodeOutputRelativeVolume(msg, output, volume)
    sendCommand (DBG_MODULE, gGeneral.mDevAudioControl, msg)
}

DEFINE_FUNCTION doMainVideoSwitch (integer input, integer output)
{
    char msg[1000]
    if (input > 0)
    {
	debug (DBG_MODULE, 1, "'switching video input source ',itoa(input),' to output ',itoa(output)")
	encodeMatrixMappingSingle(msg, input, output)
	sendCommand (DBG_MODULE, gGeneral.mDevVideoControl, "'SWITCH:1:',msg")
    }
}

DEFINE_FUNCTION doMainVideoSetAbsoluteVolume (integer outputId, sinteger volume)
{
    debug (DBG_MODULE, 7, "'AvControl::doMainVideoSetAbsoluteVolume(',itoa(outputId),
	   '): FIX THIS: cannot set video volume (',itoa(volume),')'")
}

DEFINE_FUNCTION doLocalSwitch (integer outputId, integer inputChannel)
{
    integer mappedChannel
    mappedChannel = gAllOutputs[outputId].mChannelMap[inputChannel]
    if (mappedChannel == 0)
    {
	mappedChannel = inputChannel
    }
    debug (DBG_MODULE, 1, "'changing input using channel: ',itoa(mappedChannel)")
    sendPulse (DBG_MODULE, gAllOutputs[outputId].mDev, mappedChannel)
}

DEFINE_FUNCTION doLocalSetScene (integer outputId, integer chan)
{
    debug (DBG_MODULE, 9, "'Checking whether to send scene channel: ',itoa(chan),' ...'")
    if (chan &&        
        gAllOutputs[outputId].mChannelMask[chan] && 
	(gAllOutputs[outputId].mSceneType = AVCFG_OUTPUT_SCENE_TYPE_EXPLICIT))
    {
	debug (DBG_MODULE, 3, "'changing scene using channel: ',itoa(chan),
	      		      ' (=>',itoa(gAllOutputs[outputId].mChannelMap[chan]),')'")
	sendPulse (DBG_MODULE, gAllOutputs[outputId].mDev, gAllOutputs[outputId].mChannelMap[chan])
    }
    else
    {
        debug (DBG_MODULE, 9, "'Scene channel not supported on this output: ',itoa(chan)")
    }
}

DEFINE_FUNCTION checkMatrix (dev matrix)
{
    sendCommand (DBG_MODULE, matrix, 'STATUS?')
}

DEFINE_FUNCTION checkAudioVolumeLevels ()
{
    sendCommand (DBG_MODULE, gGeneral.mDevAudioControl, 'VOLUMES?')
}

DEFINE_EVENT

DATA_EVENT[gGeneral.mDevAudioStatus]
{
    STRING:
    {
	debug (DBG_MODULE,2,"'Received string from Audio Switcher (',devtoa(gGeneral.mDevAudioStatus),'): ',data.text")
//	handleAudioStatus (bRecvBufAudio)
    }
}

DEFINE_FUNCTION checkAudioMuteStatus (integer switchId)
{
    integer outputId
    outputId = getOutputIdByAudioSwitchId (switchId)
    debug (DBG_MODULE,9,"'checking volume: output(',itoa(switchId),')=',itoa(outputId),' -> volume=MUTED'")
    if (gOutputMuteStatus[outputId] != AVCFG_MUTE_STATE_ON)
    {
	// Mute is on but we didn't know it
	debug (DBG_MODULE,1,"'updating volume: output(',itoa(switchId),')=',itoa(outputId),' -> volume=MUTED'")
	gOutputMuteStatus[outputId] = AVCFG_MUTE_STATE_ON
	updateTpVolumeStates (outputId, 0, 1)
    }
}

DEFINE_FUNCTION checkAudioVolume (integer switchId, sinteger vol)
{
    integer outputId
    outputId = getOutputIdByAudioSwitchId (switchId)
    debug (DBG_MODULE,9,"'checking volume: output(',itoa(switchId),')=',itoa(outputId),' -> volume=',itoa(vol)")
    if (gOutputVolume[outputId] != vol)
    {
        debug (DBG_MODULE,1,"'updating volume: output(',itoa(switchId),')=',itoa(outputId),' -> volume=',itoa(vol)")
	gOutputMuteStatus[outputId] = AVCFG_MUTE_STATE_OFF
	gOutputVolume[outputId] = vol
	updateTpVolumeStates (outputId, 0, 1)
    }
}

DEFINE_FUNCTION checkAudioGain (integer switchId, sinteger gain)
{
    integer inputId
    inputId = getInputIdByAudioSwitchId (switchId)
    debug (DBG_MODULE,9,"'checking gain: input(',itoa(switchId),')=',itoa(inputId),' -> volume=',itoa(gain)")
    if (gInputGain[inputId] != gain)
    {
	debug (DBG_MODULE,1,"'updating gain: input=',itoa(inputId),' -> gain=',itoa(gain)")
	gInputGain[inputId] = gain
//	updateTpGainStates (inputId, 0)
    }
}

DEFINE_FUNCTION checkInputToOutput (integer inputId, integer outputId)
{
    debug (DBG_MODULE,9,"'checking matrix: input=',itoa(inputId),' -> output=',itoa(outputId)")
    if (outputId > 0)
    {
	integer prevInputId
	prevInputId = gInputByOutput[outputId]
        if (prevInputId != inputId)
    	{
	    // Check possibility that the switch is inconsistent with the real world:
	    if (prevInputId > 0)
	    {
	        if (gAllInputs[prevInputId].mLocationType = AVCFG_INPUT_TYPE_LOCAL)
		{
		    // False alarm; output is using a local input
		    return
		}
		else if (gAllInputs[prevInputId].mVideoSwitchId == gAllInputs[inputId].mVideoSwitchId)
		{
		    // False alarm; switch input is actually the same and we sometimes overload them 
		    // for multiple purposes (e.g. computer screens delivering music from different 
		    // apps or movies).
		    return
		}
	    }
	    // Matrix is wrong so update it
	    debug (DBG_MODULE,1,"'updating matrix: input=',itoa(inputId),' -> output=',itoa(outputId)")
	    gInputByOutput[outputId] = inputId
	    // update the TPs?
	}
    }
}

DEFINE_FUNCTION integer getOutputIdByAudioSwitchId (integer switchId)
{
    integer i
    for (i = 1; i <= length_array(gAllOutputs); i++)
    {
	if (gAllOutputs[i].mAudioSwitchId = switchId)
	{
	    return i
	}
    }
    return 0
}

DEFINE_FUNCTION integer getInputIdByAudioSwitchId (integer switchId)
{
    integer i
    for (i = 1; i <= length_array(gAllInputs); i++)
    {
	if (gAllInputs[i].mAudioSwitchId = switchId)
	{
	    return i
	}
    }
    return 0
}

DEFINE_FUNCTION handleVideoSwitchResponse (char msg[])
{
    debug (DBG_MODULE,9,"'handleVideoSwitchResponse: buffer contains: ',msg")
    while (length_array(msg) > 0)
    {
	select
	{
	active (find_string(msg,'C',1)):
	{
	    integer output, input
	    remove_string(msg,'C',1)
	    output = atoi(msg)
	    remove_string(msg,'-I',1)
	    input = atoi(msg)
            checkInputToOutput (getInputIdByVideoSwitchId(input),getOutputIdByVideoSwitchId(output))
	    set_length_array(msg,0)
	} // active 'C'
	active (1):
	{
	    debug (DBG_MODULE,2,"'ignoring switch msg: ',msg")
	    set_length_array(msg,0)
	} // active 1
	} // select
    } // while
}

DEFINE_FUNCTION integer getOutputIdByVideoSwitchId (integer switchId)
{
    integer i
    for (i = 1; i <= length_array(gAllOutputs); i++)
    {
	if ((gAllOutputs[i].mVideoSwitchId = switchId) &&
	    ((gAllOutputs[i].mOutputType = AVCFG_OUTPUT_TYPE_RECEIVER) ||
	     (gAllOutputs[i].mOutputType = AVCFG_OUTPUT_TYPE_TV_MASTER)))
	{
	    return i
	}
    }
    return 0
}

DEFINE_FUNCTION integer getInputIdByVideoSwitchId (integer switchId)
{
    integer i
    for (i = 1; i <= length_array(gAllInputs); i++)
    {
	if (gAllInputs[i].mVideoSwitchId = switchId)
	{
	    return i
	}
    }
    return 0
}

DEFINE_FUNCTION checkSwitches()
{
    checkMatrix(gGeneral.mDevAudioControl)
    wait 10
    {
        checkMatrix(gGeneral.mDevVideoControl)
    }
    wait 20
    {
	checkAudioVolumeLevels()
    }
}

DEFINE_FUNCTION integer selectLocalInputChannel (integer inputId, integer outputId)
{
    if ((gAllInputs[inputId].mPrefAudioFormat == AVCFG_AUDIO_FORMAT_ANALOG) &&
	(gAllOutputs[outputId].mSwitchedInputChannelAnalogAudio > 0))
    {
	return gAllOutputs[outputId].mSwitchedInputChannelAnalogAudio
    }
    else
    {
	return gAllOutputs[outputId].mSwitchedInputChannel
    }
}


DEFINE_PROGRAM
wait 35731 // every 59 minutes, 33.1 seconds (somewhat random, so that we probably
     	   // don't interfere with other regular checkups)
{
    checkSwitches()
}
