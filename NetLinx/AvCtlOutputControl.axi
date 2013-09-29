
DEFINE_VARIABLE

// Remember on/off status of each output
persistent integer gOutputPowerStatus[AVCFG_MAX_OUTPUTS]

// Remember mute status of each output that supports discrete volume control
persistent integer gOutputMuteStatus[AVCFG_MAX_OUTPUTS]

// Track the volume level for each output that supports discrete volume control
persistent sinteger gOutputVolume[AVCFG_MAX_OUTPUTS]

// Status of whether to ignore volume level events for a given TP
volatile integer gTpIgnoreVolumeLevels[TP_MAX_PANELS]

// The state of each TP's current output's supported channels
volatile integer gTpOutputControls[TP_MAX_PANELS][CHAN_MAX_CHANNELS]

DEFINE_EVENT

// Handle power buttons for selected output
BUTTON_EVENT[dvTpOutputControl, CHAN_POWER_CHANNELS]
{
    PUSH:
    {
	integer outputId
	integer tpId
	tpId = get_last(dvTpOutputControl)
	outputId = gTpOutputSelect[tpId]
	debug (DBG_MODULE, 8, "'handling output power button press on channel ',itoa(button.input.channel)")
	switch (button.input.channel)
	{
	case CHAN_POWER:
	{
	    // Toggle the power state
	    if (gOutputPowerStatus[outputId] = POWER_STATUS_ON)
	    {
		setOutputPowerStatus (outputId, POWER_STATUS_OFF, 1, 1)
	    }
	    else
	    {
		setOutputPowerStatus (outputId, POWER_STATUS_ON, 1, 1)
	    }
	}
	case CHAN_POWER_ON:
	{
	    setOutputPowerStatus (outputId, POWER_STATUS_ON, 1, 1)
	}
	case CHAN_POWER_OFF:
	{
	    setOutputPowerStatus (outputId, POWER_STATUS_OFF, 1, 1)
	}
	case CHAN_POWER_SLAVE_TOGGLE:
	{
	    integer i
	    for (i = 1; i <= length_array(gAllOutputs[outputId].mAvrTvId); i++)
	    {
		integer slaveTvId
		slaveTvId = gAllOutputs[outputId].mAvrTvId[i]
	    	debug (DBG_MODULE, 9, "'slave power TOGGLE: ',itoa(slaveTvId)")
		if (gOutputPowerStatus[slaveTvId] = POWER_STATUS_ON)
		{
		    setOutputPowerStatus (slaveTvId, POWER_STATUS_OFF, 1, 0)
		}
		else
		{
		    setOutputPowerStatus (slaveTvId, POWER_STATUS_ON, 1, 0)
		}
	    }
	}
	case CHAN_POWER_SLAVE_ON:
	{
	    integer i
	    for (i = 1; i <= length_array(gAllOutputs[outputId].mAvrTvId); i++)
	    {
		integer slaveTvId
		slaveTvId = gAllOutputs[outputId].mAvrTvId[i]
		debug (DBG_MODULE, 9, "'slave power ON: ',itoa(slaveTvId)")
		setOutputPowerStatus (slaveTvId, POWER_STATUS_ON, 1, 0)
	    }
	}
	case CHAN_POWER_SLAVE_OFF:
	{
	    integer i
	    for (i = 1; i <= length_array(gAllOutputs[outputId].mAvrTvId); i++)
	    {
		integer slaveTvId
		slaveTvId = gAllOutputs[outputId].mAvrTvId[i]
		debug (DBG_MODULE, 9, "'slave power OFF: ',itoa(slaveTvId)")
		setOutputPowerStatus (slaveTvId, POWER_STATUS_OFF, 1, 0)
	    }
	}
	default:
	{
	    debug (DBG_MODULE, 8, "'relaying other output on/off press on channel ',itoa(PUSH_CHANNEL)")
	    doOutputPulse (outputId, push_channel)
	}
	}
    }
}

DEFINE_FUNCTION setOutputPowerStatus (integer outputId, integer newStatus, integer force, integer slaveToo)
{
    integer currentStatus
    integer currentSlaveStatus
    integer slaveTvId
    integer slaveAutoOn
    integer inputId
    local_var integer waitingId

debug (DBG_MODULE,9,"'Slave too: ',itoa(slaveToo)")
    slaveTvId = gAllOutputs[outputId].mAvrTvId[1]
debug (DBG_MODULE,9,"'Slave TV ID: ',itoa(slaveTvId)")
    currentStatus = gOutputPowerStatus[outputId]
    if (slaveTvId)
    {
	currentSlaveStatus = gOutputPowerStatus[slaveTvId]
    }
    else
    {
	currentSlaveStatus = currentStatus
    }
debug (DBG_MODULE,9,"'Slave status: ',itoa(currentSlaveStatus)")
    inputId = getInputIdForOutputId(outputId)
    if (inputId > 0)
    {
	slaveAutoOn = gAllInputs[inputId].mSlaveAutoOn
debug (DBG_MODULE,9,"'Slave Auto On 1: ',itoa(slaveAutoOn)")
    }
debug (DBG_MODULE,9,"'Slave Auto On 2: ',itoa(slaveAutoOn)")

    switch (newStatus)
    {
    case POWER_STATUS_ON:
    {
	if (force || (currentStatus != POWER_STATUS_ON))
	{
	    debug (DBG_MODULE, 2, "'turning ON device: ',gAllOutputs[outputId].mName")
	    setOutputPowerStatusExec (outputId, POWER_STATUS_ON)
	}
	else
	{
	    debug (DBG_MODULE, 8, "'device is already ON: ',gAllOutputs[outputId].mName")
	}
	gOutputPowerStatus[outputId] = POWER_STATUS_ON
	if (slaveToo && (slaveTvId > 0))
	{
//	    if ((currentSlaveStatus != POWER_STATUS_ON) && slaveAutoOn)
	    if (currentSlaveStatus != POWER_STATUS_ON)
	    {
		debug (DBG_MODULE, 2, "'also turning ON slave device: ',gAllOutputs[slaveTvId].mName")
		gOutputPowerStatus[slaveTvId] = POWER_STATUS_ON
		waitingId = slaveTvId
		wait 10
		{
		    setOutputPowerStatusExec (waitingId, POWER_STATUS_ON)
		}
	    }
	}
	checkPowerUp()
    }

    case POWER_STATUS_OFF:
    {
	if (force || (gOutputPowerStatus[outputId]) != POWER_STATUS_OFF)
	{
	    integer i
	    debug (DBG_MODULE, 2, "'turning OFF device: ',gAllOutputs[outputId].mName")
	    setOutputPowerStatusExec (outputId, POWER_STATUS_OFF)
	    for (i = 1; i <= length_array(gAllOutputs[outputId].mAvrTvId); i++)
	    {
		slaveTvId = gAllOutputs[outputId].mAvrTvId[i]
		debug (DBG_MODULE, 2, "'also turning OFF slave device: ',gAllOutputs[slaveTvId].mName")
		waitingId = slaveTvId
		wait 10
		{
		    setOutputPowerStatusExec (waitingId, POWER_STATUS_OFF)
		}
	    }
	    for (i = 1; i <= length_array(gAllOutputs[outputId].mLocalInputIds); i++)
	    {
		integer localInputId
		localInputId = gAllOutputs[outputId].mLocalInputIds[i]
		debug (DBG_MODULE, 2, "'also turning OFF local input device: ',gAllInputs[localInputId].mName")
		pulse [gAllInputs[localInputId].mDev, CHAN_POWER_OFF]
	    }
	}
	else
	{
	    debug (DBG_MODULE, 8, "'device is already OFF: ',gAllOutputs[outputId].mName")
	}
	gOutputPowerStatus[outputId] = POWER_STATUS_OFF
	if (slaveTvId > 0)
	{
	    gOutputPowerStatus[slaveTvId] = POWER_STATUS_OFF
	}
	resetOutputVolumeDefault (outputId)
	checkPowerDown()
    }

    default: {}

    } // switch

    if (currentStatus != gOutputPowerStatus[outputId])
    {
	// Update TP power status buttons on all TPs
	checkAllTpOutputPower (outputId)
    }
    if (slaveTvId > 0)
    {
	if (currentSlaveStatus != gOutputPowerStatus[slaveTvId])
	{
	    // Update TP slave power status buttons on all TPs
	    checkAllTpOutputPower (slaveTvId)
	}
    }
}

DEFINE_FUNCTION setOutputPowerStatusExec (integer outputId, integer status)
{
    if (gAllOutputs[outputId].mAudioSwitchId > 0)
    {
	if (status = POWER_STATUS_ON)
	{
	    integer inputId
	    inputId = getInputIdForOutputId(outputId)
	    doMainAudioSwitch (gAllInputs[inputId].mAudioSwitchId, gAllOutputs[outputId].mAudioSwitchId)
	}
	else
	{
	    doMainAudioSwitchOff (gAllOutputs[outputId].mAudioSwitchId)
	}
    }
    if ((gAllOutputs[outputId].mVideoSwitchId > 0) ||
        (gAllOutputs[outputId].mOutputType = AVCFG_OUTPUT_TYPE_RECEIVER) ||
        (gAllOutputs[outputId].mOutputType = AVCFG_OUTPUT_TYPE_TV_MASTER) ||
        (gAllOutputs[outputId].mOutputType = AVCFG_OUTPUT_TYPE_TV_SLAVE))
    {
	if (status = POWER_STATUS_ON)
	{
	    doOutputPulse (outputId, CHAN_POWER_ON)
	}
	else
	{
	    doOutputPulse (outputId, CHAN_POWER_OFF)
	}
    }
}

DEFINE_FUNCTION checkAllTpOutputPower (integer outputId)
{
    integer onOff
    integer tpId
    onOff = (gOutputPowerStatus[outputId] = POWER_STATUS_ON)
    for (tpId = 1; tpId <= length_array(dvTpOutputControl); tpId++)
    {
	checkTpOutputPower (tpId, outputId)
    }
}

DEFINE_FUNCTION checkTpOutputPower (integer tpId, integer outputId)
{
    integer onOff
    onOff = (gOutputPowerStatus[outputId] = POWER_STATUS_ON)
    debug (DBG_MODULE, 6, "'TP ',devtoa(dvTpOutputSelect[tpId]),': checking TP output power for ',
			   gAllOutputs[outputId].mName,' (',itoa(outputId),')'")

    // If this TP is handling the same output (or the output's slave TV), then update that TP's output power info
    select
    {
    active (gTpOutputSelect[tpId] = 0):
    {
    }
    active (gTpOutputSelect[tpId] = outputId):
    {
        debug (DBG_MODULE, 9, "'setting power feedback (',itoa(onOff),') for main device: ',
	    	  	      gAllOutputs[outputId].mName")
    	[dvTpOutputControl[tpId], CHAN_POWER_FB] = onOff
    }
    active (gAllOutputs[outputId].mOutputType = AVCFG_OUTPUT_TYPE_TV_SLAVE):
    {
	if (outputId = gAllOutputs[gTpOutputSelect[tpId]].mAvrTvId[1])
	{
	    debug (DBG_MODULE, 9, "'setting power feedback (',itoa(onOff),') for slave device: ',
		      		  gAllOutputs[outputId].mName")
	    [dvTpOutputControl[tpId], CHAN_POWER_SLAVE_FB] = onOff
	}
    } // active
    } // select
}

DEFINE_EVENT

// Handle volume up/down/mute buttons for selected output
BUTTON_EVENT[dvTpOutputControl, CHAN_VOLUME_CHANNELS]
{
    PUSH:
    {
	doVolumeControl (get_last(dvTpOutputControl), button.input.channel)
    }
    HOLD[3,REPEAT]:
    {
	doVolumeControl (get_last(dvTpOutputControl), button.input.channel)
    }
    RELEASE:
    {
	debug (DBG_MODULE, 8, "'detected output button release on channel ',itoa(button.input.channel)")
    }
}

DEFINE_FUNCTION resetOutputVolumeDefault (integer outputId)
{
    if (gAllOutputs[outputId].mVolType != AVCFG_OUTPUT_VOL_DISCRETE)
    {
	debug (DBG_MODULE, 7, "'AvCtlOutputControl::resetOutputVolumeDefault(',itoa(outputId),
	      		   '): not resetting default volume (no discrete controls)'")
	return
    }
    gOutputVolume[outputId] = gAllOutputs[outputId].mVolumeDefault
    if (gAllOutputs[outputId].mAudioSwitchId > 0)
    {
	debug (DBG_MODULE, 7, "'AvCtlOutputControl::resetOutputVolumeDefault(',itoa(outputId),
	      		   '): setting to default volume (',itoa(gAllOutputs[outputId].mVolumeDefault),')'")
	doMainAudioSetAbsoluteVolume (gAllOutputs[outputId].mAudioSwitchId, gAllOutputs[outputId].mVolumeDefault)
    }
    else
    {
	doMainVideoSetAbsoluteVolume (gAllOutputs[outputId].mVideoSwitchId, gAllOutputs[outputId].mVolumeDefault)
    }
}

DEFINE_FUNCTION doVolumeControl (integer tpId, integer chan)
{
    if (gAllOutputs[gTpOutputSelect[tpId]].mVolType != AVCFG_OUTPUT_VOL_DISCRETE)
    {
	doVolumeControlNonDiscrete (tpId, chan)
    }
    else
    {
	doVolumeControlDiscrete (tpId, chan)
    }
}

DEFINE_FUNCTION doVolumeControlNonDiscrete (integer tpId, integer chan)
{
    // Just relay the non-discrete volume controls
    integer outputId
    outputId = gTpOutputSelect[tpId]
    debug (DBG_MODULE, 8, "'relaying output button press on channel ',itoa(chan),
      	  	     	      ' to device ',devtoa(gAllOutputs[outputId].mDev)")
    doOutputPulse (outputId, chan)
}

DEFINE_FUNCTION doVolumeControlDiscrete (integer tpId, integer chan)
{
    // Handle discrete volume controls
    integer outputId
    outputId = gTpOutputSelect[tpId]
    switch (chan)
    {
    case CHAN_VOL_UP:
    {
	if (gOutputVolume[outputId] >= gAllOutputs[outputId].mVolumeMax)
	{
	    gOutputVolume[outputId] = gAllOutputs[outputId].mVolumeMax
	    debug (DBG_MODULE, 7, "'volume is at max already (',itoa(gOutputVolume[outputId]),')'")
	    return
	}
	gOutputVolume[outputId] = gOutputVolume[outputId] + gAllOutputs[outputId].mVolumeIncrement
	if (gOutputVolume[outputId] >= gAllOutputs[outputId].mVolumeMax)
	{
	    gOutputVolume[outputId] = gAllOutputs[outputId].mVolumeMax
	}
	debug (DBG_MODULE, 7, "'increasing volume to ',itoa(gOutputVolume[outputId])")
	setAbsoluteVolume (outputId)
    }

    case CHAN_VOL_DOWN:
    {
	if (gOutputVolume[outputId] <= gAllOutputs[outputId].mVolumeMin)
	{
	    gOutputVolume[outputId] = gAllOutputs[outputId].mVolumeMin
	    debug (DBG_MODULE, 7, "'volume is at min already (',itoa(gOutputVolume[outputId]),')'")
	    return
	}
	gOutputVolume[outputId] = gOutputVolume[outputId] - gAllOutputs[outputId].mVolumeIncrement
	if (gOutputVolume[outputId] <= gAllOutputs[outputId].mVolumeMin)
	{
	    gOutputVolume[outputId] = gAllOutputs[outputId].mVolumeMin
	}
	debug (DBG_MODULE, 7, "'decreasing volume to ',itoa(gOutputVolume[outputId])")
	setAbsoluteVolume (outputId)
    }

    case CHAN_VOL_MUTE:
    {
(*
	if (gOutputMuteStatus[outputId] = )
	{
	    gOutputVolume[outputId] = gAllOutputs[outputId].mVolumeMin
	    debug (DBG_MODULE, 7, "'volume is at min already (',itoa(gOutputVolume[outputId]),')'")
	    return
	}
	gOutputVolume[outputId] = gOutputVolume[outputId] - gAllOutputs[outputId].mVolumeIncrement
	if (gOutputVolume[outputId] <= gAllOutputs[outputId].mVolumeMin)
	{
	    gOutputVolume[outputId] = gAllOutputs[outputId].mVolumeMin
	}
	debug (DBG_MODULE, 7, "'decreasing volume to ',itoa(gOutputVolume[outputId])")
	setAbsoluteVolume (outputId)
*)
    }

    default:
    {
	debug (DBG_MODULE, 7, "'AvCtlOutputControl::doVolumeControlDiscrete(',itoa(outputId),'): unhandled switch-case!'")
    }
    }
}

DEFINE_FUNCTION setAbsoluteVolume (integer outputId)
{
    if (gAllOutputs[outputId].mVideoSwitchId > 0)
    {
	doMainVideoSetAbsoluteVolume (gAllOutputs[outputId].mVideoSwitchId, gOutputVolume[outputId])
    }
    else
    {
        doMainAudioSetAbsoluteVolume (gAllOutputs[outputId].mAudioSwitchId, gOutputVolume[outputId])
    }
}

DEFINE_FUNCTION checkVolumeDefaults()
{
    integer i
    for (i = 1; i <= length_array(gAllOutputs); i++)
    {
	if (gOutputVolume[i] = 0)
	{
	    // We must be going through a cold start-up (rare)
	    gOutputVolume[i] = gAllOutputs[i].mVolumeDefault
	}
    }
}

DEFINE_FUNCTION updateTpVolumeStates (integer outputId, integer skipTpId, integer forceMuteStatus)
{
(*
    // Update any other TPs that happen to be controlling this output
    sinteger lev
    integer  muteEnabled
    integer  tpId
    integer  nTps
    integer  i
    integer  nOutputs
    lev = scaleVolumeToLevel(gStatus.volume[outputId])
    muteEnabled = (gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_ON)
    nTps = length_array(dvTpOutputCtl)
    for (tpId = 1; tpId <= nTps; tpId++)
    {
	if (tpId = skipTpId)
	{
	    continue
	}
	if (gTpStatus[tpId] = 0)
	{
	    continue
	}
	nOutputs = length_array(gOutputSelect[tpId])
	for (i = 1; i <= nOutputs; i++)
	{
	    if (gOutputSelect[tpId][i] = outputId)
	    {
		updateTpVolumeState (tpId, i, lev, forceMuteStatus, muteEnabled)
		break   // since outputId only occurs once per TP
	    }
	}
    }
*)
}

DEFINE_FUNCTION updateTpVolumeState (integer tpId, integer tpUiId, sinteger lev, integer forceMuteStatus, integer muteEnabled)
{
(*
    // Update the volume slider
    gTpIgnoreVolumeLevels[tpId] = 1
    send_level dvTpOutputControl[tpId], audioCtlUi2VolumeLevel(tpUiId), lev
    wait 1 // 0.1 sec
    {
	gTpIgnoreVolumeLevels[tpId] = 0
    }
    if (forceMuteStatus)
    {
	// Update the mute button
	[dvTpOutputCtl[tpId],audioCtlUi2VolMuteAddress(tpUiId)] = (muteEnabled)
	// Enable/disable the volume buttons and slider based on mute state
	send_string dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolUpAddress(tpUiId)),'.',itoa(audioCtlUi2VolDownAddress(tpUiId)),',',itoa(muteEnabled)"
    }
*)
}

DEFINE_EVENT

// Handle power buttons for selected output
BUTTON_EVENT[dvTpOutputControl, CHAN_TV_ADVANCED]
{
    PUSH:
    {
	integer outputId
	integer tpId
	tpId = get_last(dvTpOutputControl)
	outputId = gTpOutputSelect[tpId]
	debug (DBG_MODULE, 8, "'handling output button press on channel ',itoa(button.input.channel)")
	if (length_array(gAllOutputs[outputId].mAvrTvId) > 0)
	{
	    debug (DBG_MODULE, 9, "'passing to slave: ',itoa(gAllOutputs[outputId].mAvrTvId[1])")
	    outputId = gAllOutputs[outputId].mAvrTvId[1]
	}
	doOutputPulse (outputId, button.input.channel)
    }
}

DEFINE_FUNCTION doOutputPulse (integer outputId, integer chan)
{
    integer mappedChannel
    mappedChannel = gAllOutputs[outputId].mChannelMap[chan]
    if (mappedChannel = 0)
        mappedChannel = chan
    if (gAllOutputs[outputId].mIrType = AVCFG_IR_TYPE_SEND_COMMAND)
    {
	debug (DBG_MODULE, 9, "'AvCtlOutputControl::doOutputPulse(',itoa(outputId),',',itoa(chan),
	      		      '): send_command ',devtoa(gAllOutputs[outputId].mDev),', SP',itoa(mappedChannel)")
	send_command gAllOutputs[outputId].mDev, "'SP',mappedChannel"
    }
    else
    {
	debug (DBG_MODULE, 9, "'AvCtlOutputControl::doOutputPulse(',itoa(outputId),',',itoa(chan),
	      		      '): pulse [',devtoa(gAllOutputs[outputId].mDev),', ',itoa(mappedChannel),']'")
	pulse [gAllOutputs[outputId].mDev, mappedChannel]
    }
}


DEFINE_FUNCTION updateTpOutputControls (integer tpId)
{
    integer i, outputId
    outputId = gTpOutputSelect[tpId]
    debug (DBG_MODULE,9,"'updateTpOutputControls(',devtoa(dvTpOutputControl[tpId]),'): outputId=',itoa(outputId)")
    sendCommand (DBG_MODULE, dvTpOutputControl[tpId], "'^SHO-1.500,0'")
    if (outputId > 0)
    {
	// Show only the buttons supported by this output
	if (tpIsIridium(gPanels,tpId))
	{
	    // iRidium doesn't support complex channel lists yet
	    integer buttonOn
	    for (i = 1; i <= CHAN_MAX_CHANNELS; i++)
	    {
		buttonOn = gAllOutputs[outputId].mChannelMask[i]
		if (buttonOn)
		{
		    sendCommand (DBG_MODULE, dvTpOutputControl[tpId], "'^SHO-',itoa(i),',1'")
		}
	    }
	}
	else
	{
	    sendCommand (DBG_MODULE, dvTpOutputControl[tpId], "'^SHO-',gAllOutputs[outputId].mSupportedChannels,',1'")
	}

	// Enabled Slave TV power button, if it exists
	if (length_array(gAllOutputs[outputId].mAvrTvId) > 0)
	{
	    sendCommand (DBG_MODULE, dvTpOutputControl[tpId], "'^SHO-',itoa(CHAN_POWER_SLAVE_FB),',1'")
	}
    }
}

DEFINE_FUNCTION checkPowerUp()
{
    avCancelPowerDownTimer()
    avEnsurePowerOn()
}

DEFINE_FUNCTION checkPowerDown()
{
    if (allOutputDevicesOff())
    {
	debug (DBG_MODULE, 2, "'All A/V output devices are OFF'")
	avStartPowerDownTimer()
    }
    else
    {
	debug (DBG_MODULE, 9, "'Some A/V output devices are ON'")
    }
}

DEFINE_FUNCTION integer allOutputDevicesOff()
{
    integer outputId
debug(DBG_MODULE,9,"'Check gOutputPowerStatus length: ',itoa(length_array(gOutputPowerStatus))")
    for (outputId = length_array(gOutputPowerStatus); outputId > 0; outputId--)
    {
	if (gOutputPowerStatus[outputId] != POWER_STATUS_OFF)
	    return 0
    }
    return 1
}