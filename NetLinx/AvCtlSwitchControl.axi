(*
 * Various controls for the audio and video switchers.
 *)

DEFINE_VARIABLE

volatile char bRecvBufAudio[1024]
volatile char bRecvBufVideo[1024]

DEFINE_FUNCTION doInputOutputSwitch (integer inputId, integer outputId)
{
    // Do the A/V switching, including changing scenes and/or local inputs, if necessary, since
    // the input may be either centrally switched or locally connected.
    integer needLocalSwitch
    integer prevInputId

    // Ensure that the power to the output is ON
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
	    debug (DBG_MODULE, 9, "gAllInputs[inputId].mName,': main video switch changing...'")
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
	sendPulse (DBG_MODULE, gAllInputs[inputId].mDev, CHAN_POWER_ON)
    }

    if (gAllInputs[inputId].mSceneChannel != gAllInputs[prevInputId].mSceneChannel)
    {
	wait 35 // wait 3.5 seconds, in case the display was powered off
	{
	    doLocalSetScene (outputId, gAllInputs[inputId].mSceneChannel)
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
    debug (DBG_MODULE, 1, "'switching audio input source ',itoa(input),' to output ',itoa(output)")
    sendAudioCommand ("'CI',itoa(input),'O',itoa(output),'T'")
}

DEFINE_FUNCTION doMainAudioSwitchOff (integer output)
{
    debug (DBG_MODULE, 1, "'switching OFF audio output source ',itoa(output)")
    sendAudioCommand ("'DO',itoa(output),'T'")
}

DEFINE_FUNCTION doMainAudioSetAbsoluteVolume (integer output, sinteger volume)
{
    debug (DBG_MODULE, 1, "'setting audio output ',itoa(output),' volume to ',itoa(volume)")
    sendAudioCommand ("'CO',itoa(output),'VA',itoa(volume),'T'")
}

DEFINE_FUNCTION doMainVideoSwitch (integer input, integer output)
{
    debug (DBG_MODULE, 1, "'switching video input source ',itoa(input),' to output ',itoa(output)")
    sendVideoCommand ("'CI',itoa(input),'O',itoa(output)")
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

DEFINE_FUNCTION sendAudioCommand (char cmdStr[])
{
    debug (DBG_MODULE, 4, "'sending audio command: send_string ',devtoa(gGeneral.mAudioSwitcher),', ',cmdStr")
    send_string gGeneral.mAudioSwitcher, cmdStr
}

DEFINE_FUNCTION sendVideoCommand (char cmdStr[])
{
    debug (DBG_MODULE, 4, "'sending video command: send_command ',devtoa(gGeneral.mVideoSwitcher),', ',cmdStr")
    send_command gGeneral.mVideoSwitcher, cmdStr
}

DEFINE_FUNCTION checkAudioSwitchMatrix ()
{
    integer inputId
    for (inputId = 1; inputId <= length_array(gAllInputs); inputId++)
    {
	if (gAllInputs[inputId].mAudioSwitchId > 0)
	{
	    sendAudioCommand ("'SL0I',itoa(gAllInputs[inputId].mAudioSwitchId),'T'")
	}
    }
}

DEFINE_FUNCTION checkAudioSwitchVolumeLevels ()
{
    integer outputId
    for (outputId = 1; outputId <= length_array(gAllOutputs); outputId++)
    {
	if (gAllOutputs[outputId].mAudioSwitchId > 0)
	{
	    sendAudioCommand ("'SL0O',itoa(gAllOutputs[outputId].mAudioSwitchId),'VT'")
	}
    }
}

DEFINE_FUNCTION setAudioSwitchGainLevels ()
{
    integer inputId
    for (inputId = 1; inputId <= length_array(gAllInputs); inputId++)
    {
	if (gAllInputs[inputId].mAudioSwitchId > 0)
	{
	    sendAudioCommand ("'CL0I',itoa(gAllInputs[inputId].mAudioSwitchId),'VA',itoa(gAllInputs[inputId].mAudioGain),'T'")
	}
    }
}

DEFINE_FUNCTION checkVideoSwitchMatrix ()
{
    sendVideoCommand ("'?C'")
}

DEFINE_EVENT

DATA_EVENT[gGeneral.mAudioSwitcher]
{
    ONLINE:
    {
	send_string gGeneral.mAudioSwitcher,"'SET BAUD 9600,N,8,1 485 DISABLE'"
	send_string gGeneral.mAudioSwitcher,"'HSOFF'"
	send_string gGeneral.mAudioSwitcher,"'XOFF'"
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mAudioSwitcher),') is online'")
        wait 39 // 3.9 seconds after online event
	{
	    checkAudioSwitchMatrix()
	    wait 39 { checkAudioSwitchVolumeLevels() }
	}
    }
    OFFLINE:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mAudioSwitcher),') is offline'")
    }
    COMMAND:
    {
	debug (DBG_MODULE,2,"'Received command from Audio Switcher (',devtoa(gGeneral.mAudioSwitcher),'): ',data.text")
    }
    STRING:
    {
	debug (DBG_MODULE,2,"'Received string from Audio Switcher (',devtoa(gGeneral.mAudioSwitcher),'): ',data.text")
	handleAudioSwitchResponse (bRecvBufAudio)
    }
    ONERROR:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mAudioSwitcher),') has an error: ', data.text")
    }
    STANDBY:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mAudioSwitcher),') is standby'")
    }
    AWAKE:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGeneral.mAudioSwitcher),') is awake'")
    }
}

DATA_EVENT[gGeneral.mVideoSwitcher]
{
    ONLINE:
    {
	debug (DBG_MODULE,1,"'Video Switcher (',devtoa(gGeneral.mVideoSwitcher),') is online'")
        wait 29 // 2.9 seconds after online event
	{
	    checkVideoSwitchMatrix()
	}
    }
    OFFLINE:
    {
	debug (DBG_MODULE,1,"'Video Switcher (',devtoa(gGeneral.mVideoSwitcher),') is offline'")
    }
    COMMAND:
    {
	debug (DBG_MODULE,2,"'Received command from Video Switcher (',devtoa(gGeneral.mVideoSwitcher),'): ',data.text")
	handleVideoSwitchResponse (data.text)
    }
    STRING:
    {
	debug (DBG_MODULE,2,"'Received string from Video Switcher (',devtoa(gGeneral.mVideoSwitcher),'): ',data.text")
	handleVideoSwitchResponse (bRecvBufVideo)
    }
    ONERROR:
    {
	debug (DBG_MODULE,1,"'Video Switcher (',devtoa(gGeneral.mVideoSwitcher),') has an error: ', data.text")
    }
    STANDBY:
    {
	debug (DBG_MODULE,1,"'Video Switcher (',devtoa(gGeneral.mVideoSwitcher),') is standby'")
    }
    AWAKE:
    {
	debug (DBG_MODULE,1,"'Video Switcher (',devtoa(gGeneral.mVideoSwitcher),') is awake'")
    }
}

DEFINE_FUNCTION handleAudioSwitchResponse (char msg[])
{
    debug (DBG_MODULE,9,"'handleAudioSwitchResponse: buffer contains: ',msg")
    while (length_array(msg) > 0)
    {
	select
	{
	active (find_string(msg,'S',1)):
	{
	    // Status message
	    integer levelId
	    if (!find_string(msg,')',1))
	    {
		// We don't have the end of the status message yet, so let the 
		// buffer do its job
		debug (DBG_MODULE,7,"'handleSwitchResponse: incomplete buffer: ',msg")
		return
	    }
	    remove_string(msg,'S',1)
	    if (find_string(msg,'L',1))
	    {
		remove_string(msg,'L',1)
		levelId = atoi(msg)
	    }
	    select
	    {
	    active (find_string(msg,'O',1)):
	    {
		// 'O' for Output
		integer output
		remove_string(msg,'O',1)
		output = atoi(msg)
		select
		{
		active (find_string(msg,'VT( ',1)):
		{
		    remove_string(msg,'VT( ',1)
		    if (msg[1] = 'M')
		    {
			checkAudioMuteStatus (output)
		    }
		    else
		    {
		        checkAudioVolume (output, atoi(msg))
		    }
		    remove_string(msg,')',1)
		} // active 'VT('

		active (find_string(msg,'T( ',1)):
		{
		    integer input
		    remove_string(msg,'T( ',1)
		    input = atoi(msg)
		    if (input > 0)
		    {
		        checkInputToOutput (getInputIdByAudioSwitchId(input),getOutputIdByAudioSwitchId(output))
		    }
		    remove_string(msg,')',1)
		} // active 'T('
		} // select
	    } // active 'O'

	    active (find_string(msg,'I',1)):
	    {
		// 'I' for Output
		integer input
		remove_string(msg,'I',1)
		input = atoi(msg)
		select
		{
		active (find_string(msg,'VT( ',1)):
		{
		    remove_string(msg,'VT( ',1)
		    if (msg[1] = 'M')
		    {
			// We don't handle input mutes right now
			debug (DBG_MODULE,6,"'ignoring gain mute: input=',itoa(input)")
		    }
		    else
		    {
			checkAudioGain (input, atoi(msg))
		    }
		    remove_string(msg,')',1)
		} // active 'VT('
		active (find_string(msg,'T( ',1)):
		{
		    // The list of outputs for this input.
		    integer output
		    remove_string(msg,'T( ',1)
		    for (output = atoi(msg);
			 output > 0;
			 output = atoi(msg))
		    {
		        checkInputToOutput (getInputIdByAudioSwitchId(input),getOutputIdByAudioSwitchId(output))
			remove_string(msg,' ',1)
		    }
		    remove_string(msg,')',1)
		} // active 'T('
		} // select
	    } // active 'I'
	    } // select
	} // active 'S'

	active (1):
	{
	    debug (DBG_MODULE,2,"'ignoring switch msg: ',msg")
	    set_length_array(msg,0)
	} // active 1
	} // select
    } // while
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
    checkAudioSwitchMatrix()
    wait 10
    {
        checkVideoSwitchMatrix()
    }
    wait 20
    {
	checkAudioSwitchVolumeLevels()
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
