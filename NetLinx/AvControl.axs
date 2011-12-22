MODULE_NAME='AvControl' (
    char configFile[],
    char tpConfigFile[],
    dev  vdvAvControl,
    dev  vdvZoneControl)

#include 'AvConfig.axi'
#include 'TouchPanelConfig.axi'
#include 'ChannelDefs.axi'
#include 'TouchPanelPorts.axi'
#include 'Debug.axi'

DEFINE_VARIABLE

volatile TouchPanel  gPanels[TP_MAX_PANELS]
volatile dev  dvTpInputSelect[TP_MAX_PANELS]	// TP channels for input selection, switching and titles
volatile dev  dvTpInputControl[TP_MAX_PANELS]	// TP channels for input control buttons and sliders
volatile dev  dvTpOutputSelect[TP_MAX_PANELS]	// TP channels for output selection, switching and titles
volatile dev  dvTpOutputControl[TP_MAX_PANELS]	// TP channels for output control buttons and sliders

DEFINE_CONSTANT

sinteger VOL_MIN_LEVEL  =    0
sinteger VOL_MAX_LEVEL  =  255

integer OUTPUT_UI_STATE_UNKNOWN		= 0
integer OUTPUT_UI_STATE_DISABLED	= 1
integer OUTPUT_UI_STATE_ENABLED_OFF	= 2
integer OUTPUT_UI_STATE_ENABLED_ON	= 3

// Used to track power status (on/off); 0 is unknown rather than off because the persistent variables are reset to 0
integer POWER_STATUS_UNKNOWN 	= 0
integer POWER_STATUS_OFF 	= 1
integer POWER_STATUS_ON 	= 2

DEFINE_TYPE

(*
structure AudioStatus
{
    sinteger gain[ACFG_MAX_AUDIO_INPUTS]	// Gain setting for each input 
    sinteger volume[ACFG_MAX_AUDIO_OUTPUTS]	// Volume setting for each output
    integer  volumeMute[ACFG_MAX_AUDIO_OUTPUTS]	// Volume muted state for each output
    integer  power[ACFG_MAX_AUDIO_OUTPUTS]	// On/off 'power' state for eah output
    integer  matrix[ACFG_MAX_AUDIO_OUTPUTS]	// All current crosspoint status
}
*)

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)

DEFINE_VARIABLE

constant char DBG_MODULE[] = 'AvControl'

// Note: As of 2010/01/21, 'persistent' data types don't seem to work -- at least not
// for arrays of integers -- so we may as well put it in faster, non_volatile
// memory.

// Track online status of each TP so that we don't waste time sending updates to
// TPs that are offline
non_volatile integer gTpStatus[TP_MAX_PANELS]

// Track input selection for each TP
non_volatile integer gTpInputSelect[TP_MAX_PANELS]

(*
non_volatile integer gTpOutputUiState[ACFG_MAX_TP_CONTROLLERS][ACFG_MAX_AUDIO_OUTPUTS]	// output UI states
//non_volatile integer gMasterPower[ACFG_MAX_TP_CONTROLLERS]				// master audio output power switches

// gStatus is the global status of the switch, which is relevant across all TPs
AudioStatus gStatus 

// We turn off slider events from time to time to avoid looping and overwhelming the switch
volatile integer gIgnoreSliderLevelEvents[ACFG_MAX_TP_CONTROLLERS]
*)

(*
 * The following #include files are dependent upon some of the prior definitions
 * and are only separated in oder to make it easier to see related parts of the
 * overall module.
 *)

#include 'AvTpPageNames.axi'
#include 'AvCtlOutputSelect.axi'
#include 'AvCtlOutputControl.axi'
#include 'AvCtlInputSelect.axi'
#include 'AvCtlInputControl.axi'
#include 'AvCtlSwitchControl.axi'
#include 'AvCtlPower.axi'

(*
DEFINE_EVENT

// Let's put the event handling first because that's the most interesting.
// Note: we can't use push_channel in HOLD processing, so we'll use 
// button.input.channel all the time

BUTTON_EVENT[dvTpInputSelect,0]
{
    PUSH:
    {
	// Input selection causes a switch of all of the selected outputs
	doInputSelection (get_last(dvTpInputSelect), button.input.channel)
    }
}
*)


(*
BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_VOL_UP]
BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_VOL_DOWN]
{
    PUSH:
    {
	debug (DBG_MODULE,9,"'received button push for volume up/down: ',itoa(button.input.channel)")
	doVolumeControl (gOutputSelect[get_last(dvTpOutputCtl)][audioCtlChannel2Ui(button.input.channel)], 
			 audioCtlChannel2Action(button.input.channel))
    }
    HOLD [2, REPEAT]:
    {
	debug (DBG_MODULE,9,"'received button hold for volume up/down: ',itoa(button.input.channel)")
	doVolumeControl (gOutputSelect[get_last(dvTpOutputCtl)][audioCtlChannel2Ui(button.input.channel)], 
			 audioCtlChannel2VolDir(button.input.channel))
    }
}

BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_VOL_UP_MASTER]
BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_VOL_DOWN_MASTER]
{
    PUSH:
    {
	debug (DBG_MODULE,9,"'received master button push for volume up/down: ',itoa(button.input.channel)")
	doVolumeControlMaster (get_last(dvTpOutputCtl), audioCtlChannel2VolDir(button.input.channel))
    }
    HOLD [2, REPEAT]:
    {
	debug (DBG_MODULE,9,"'received master button hold for volume up/down: ',itoa(button.input.channel)")
	doVolumeControlMaster (get_last(dvTpOutputCtl), audioCtlChannel2VolDir(button.input.channel))
    }
}


BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_VOL_MUTE]
{
    PUSH:
    {
	debug (DBG_MODULE,9,"'received button push for volume mute: ',itoa(button.input.channel)")
	doOutputMute (gOutputSelect[get_last(dvTpOutputCtl)][audioCtlChannel2Ui(button.input.channel)])
    }
}

BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_VOL_MUTE_MASTER]
{
    PUSH:
    {
	debug (DBG_MODULE,9,"'received master button push for volume mute: ',itoa(button.input.channel)")
	doOutputMuteMaster (get_last(dvTpOutputCtl))
    }
}

BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_POWER]
{
    PUSH:
    {
	integer tpId
	tpId = get_last(dvTpOutputCtl)
	debug (DBG_MODULE,9,"'received button push for output on/off: ',itoa(button.input.channel)")
	doOutputPower (tpId, gOutputSelect[tpId][audioCtlChannel2Ui(button.input.channel)], 0, 0)
    }
}

BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_POWER_MASTER]
{
    PUSH:
    {
	debug (DBG_MODULE,9,"'received master button push for power OFF: ',itoa(button.input.channel)")
	doOutputPowerMaster (get_last(dvTpOutputCtl))
    }
}

LEVEL_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_VOL_LEVEL] // volume sliders
{
    integer tpId
    tpId = get_last(dvTpOutputCtl)
    debug (DBG_MODULE,9,"'received level event for volume: ',itoa(level.input.level)")
    doVolumeLevel (tpId,gOutputSelect[tpId][audioCtlChannel2Ui(level.input.level)],level.value)
}

(*
BUTTON_EVENT[dvTpInputCtl,0]
{
    PUSH:
    {
	// TODO: Need to separate selection and control
	dInputCtlSelection (get_last(dvTpInputCtl), button.input.channel)
    }
}

BUTTON_EVENT[dvTpControl,CHAN_GAIN_UP]
BUTTON_EVENT[dvTpControl,CHAN_GAIN_DOWN]
{
    // Note: we can't use push_channel in HOLD processing, so we'll use 
    // button.input.channel all the time
    PUSH:
    {
	doGainControl (gGainInput[get_last(dvTpControl)], button.input.channel)
    }
    HOLD [2, REPEAT]:
    {
	doGainControl (gGainInput[get_last(dvTpControl)], button.input.channel)
    }
}

LEVEL_EVENT[dvTpInputCtl,LEVEL_GAIN] // gain slider
{
    integer tpId
    integer inputId
    tpId = get_last(dvTpGain)
    inputId = gGainInput[tpId]
    // separate direct slider interaction from async feedback
    if (!gIgnoreSliderLevelEvents[tpId])
    {
	sinteger scaledLevel
	scaledLevel = scaleGainLevel (level.value)
	if (gStatus.gain[inputId] != scaledLevel)
	{
	    gStatus.gain[inputId] = scaledLevel
	    debug (DBG_MODULE,9,"'Gain slider handler: level=',itoa(level.value),'; scaled=',itoa(scaledLevel)")
	    setAbsoluteGain (inputId, scaledLevel)
	    updateTpGainPopups (inputId, tpId) // set the Gain slider position (on all other TPs)
	}
    }
}
*)

BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_SELECT_NONE]
{
    PUSH:
    {
	integer tpId
	tpId = get_last(dvTpOutputCtl)
	debug (DBG_MODULE,9,"'received button push for audio select next: ',itoa(button.input.channel)")
	gOutputSelectMod[tpId] = 0
	doControlSelect (tpId)
    }
}

BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_SELECT_PREV]
{
    PUSH:
    {
	integer tpId
	tpId = get_last(dvTpOutputCtl)
	debug (DBG_MODULE,9,"'received button push for audio select next: ',itoa(button.input.channel)")
	if (gOutputSelectMod[tpId] > 0)
	{
	    gOutputSelectMod[tpId]--
	}
	else
	{
	    gOutputSelectMod[tpId] = length_array(gOutputSelect[tpId])
	}
	doControlSelect (tpId)
    }
}

BUTTON_EVENT[dvTpOutputCtl, ACFG_OUTPUT_CTL_SELECT_NEXT]
{
    PUSH:
    {
	integer tpId
	tpId = get_last(dvTpOutputCtl)
	debug (DBG_MODULE,9,"'received button push for audio select next: ',itoa(button.input.channel)")
	if (gOutputSelectMod[tpId] < length_array(gOutputSelect[tpId]))
	{
	    gOutputSelectMod[tpId]++
	}
	else
	{
	    gOutputSelectMod[tpId] = 0
	}
	doControlSelect (tpId)
    }
}

// Matrix grid events
BUTTON_EVENT[dvTpInputGrid,0]
{
    PUSH:
    {
	// all channels map directly to input IDs
	doInputGridSelection (get_last(dvTpInputGrid), button.input.channel)
    }
}

BUTTON_EVENT[dvTpOutputGrid,0]
{
    PUSH:
    {
	// all channels map directly to output IDs
	doOutputGridSelection (get_last(dvTpOutputGrid), button.input.channel)
    }
}

DATA_EVENT[gGen.mAudioSwitcher]
{
    ONLINE:
    {
	send_string gGen.mAudioSwitcher,"'SET BAUD 9600,N,8,1 485 DISABLE'"
	send_string gGen.mAudioSwitcher,"'HSOFF'"
	send_string gGen.mAudioSwitcher,"'XOFF'"
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGen.mAudioSwitcher),') is online'")
    }
    OFFLINE:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGen.mAudioSwitcher),') is offline'")
    }
    COMMAND:
    {
	debug (DBG_MODULE,2,"'Received command from Audio Switcher (',devtoa(gGen.mAudioSwitcher),'): ',data.text")
    }
    STRING:
    {
	debug (DBG_MODULE,2,"'Received string from Audio Switcher (',devtoa(gGen.mAudioSwitcher),'): ',data.text")
	handleSwitchResponse (bRecvBuf)
    }
    ONERROR:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGen.mAudioSwitcher),') has an error: ', data.text")
    }
    STANDBY:
    {
	debug (DBG_MODULE,1,"'Audio Switcher (',devtoa(gGen.mAudioSwitcher),') is standby'")
    }
    AWAKE:
    {
	debug (DBG_MODULE,1,"'AutoPatch DSP (',devtoa(gGen.mAudioSwitcher),') is awake'")
    }
}

// We can use any one of the dvTp devices to determine the TP's "online" status
DATA_EVENT[dvTpOutputGrid]
{
    ONLINE:
    {
	// Reconnected to TP; update the buttons
	reconnectTp (get_last(dvTpOutputGrid))
    }
    OFFLINE:
    {
	disconnectTp (get_last(dvTpOutputGrid))
    }
    STRING:
    {
	debug (DBG_MODULE, 8, "'received string from TP (',devtoa(data.device),'): ',data.text")
    }
}
*)




(*
DEFINE_FUNCTION doInputSelection (integer tpId, integer inputId)
{
    integer i
    integer nOutputs
    debug (DBG_MODULE,9,"'Input Channel Selection Handler -- ',itoa(inputId)")
    // Send feedback to the display
    if (gInputSelect[tpId] > 0)
    {
	// Turn off previous selection
	[dvTpInputSelect[tpId], gInputSelect[tpId]] = 0
    }
    gInputSelect[tpId] = inputId
    // Turn on current selection
    [dvTpInputSelect[tpId], gInputSelect[tpId]] = 1
    updateTpInput (tpId, gInputSelect[tpId])

    // Switch all of the outputs that are not explicitly powered off
    nOutputs = length_array(gOutputSelect[tpId])
    for (i = 1; i <= nOutputs; i++)
    {
	integer outputId
	outputId = gOutputSelect[tpId][i]
	if (outputId > 0)  // should never be zero but check anyway
	{
	    if (gStatus.power[outputId])
	    {
		doSwitch (gInputSelect[tpId], outputId)
	    }
	}
    }
}

DEFINE_FUNCTION doVolumeControl (integer outputId, integer direction)
{
    if (outputId == 0)
    {
	debug (DBG_MODULE,6,'Ignoring volume press on unconnected output')
	return
    }
    if (direction == ACFG_VOL_DIR_UP) // increment volume
    {
	sinteger newVolume
	if (gStatus.volume[outputId] >= MAX_VOLUME) // stay within bounds
	{
	    gStatus.volume[outputId] = MAX_VOLUME
	    debug (DBG_MODULE,9,"'Volume Step-up Handler (',itoa(outputId),'): already at max absolute level: ',itoa(gStatus.volume[outputId])")
	    return
	}
	newVolume = gStatus.volume[outputId] + gAllOutputs[outputId].mVolumeIncrement
	if (newVolume > MAX_VOLUME)
	    newVolume = MAX_VOLUME
	gStatus.volume[outputId] = newVolume
	debug (DBG_MODULE,9,"'Volume Step-up Handler (',itoa(outputId),') increasing to absolute level: ',itoa(newVolume)")
    }
    else // direction == ACFG_VOL_DIR_DOWN, do decrement
    {
	sinteger newVolume
	if (gStatus.volume[outputId] <= MIN_VOLUME) // stay within bounds
	{
	    gStatus.volume[outputId] = MIN_VOLUME
	    debug (DBG_MODULE,9,"'Volume Step-down Handler (',itoa(outputId),'): already at min absolute level: ',itoa(gStatus.volume[outputId])")
	    return
	}
	newVolume = gStatus.volume[outputId] - gAllOutputs[outputId].mVolumeIncrement
	if (newVolume < MIN_VOLUME)
	    newVolume = MIN_VOLUME
	gStatus.volume[outputId] = newVolume
	debug (DBG_MODULE,9,"'Volume Step-up Handler (',itoa(outputId),') decreasing to absolute level: ',itoa(newVolume)")
    }
    setAbsoluteVolume (outputId, gStatus.volume[outputId])
    if (gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_ON)
    {
	// Vol change implies no mute
	gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_OFF 
	updateTpVolumeStates (outputId, 0, 1)
    }
    else
    {
	updateTpVolumeStates (outputId, 0, 0)
    }
}

DEFINE_FUNCTION doVolumeControlMaster (integer tpId, integer direction)
{
    integer outputIdId
    outputIdId = gOutputSelectMod[tpId]
    // if specific output is selected, just modify that one
    if (outputIdId > 0)
    {
	doVolumeControl (gOutputSelect[tpId][outputIdId], direction)
    }
    else
    {
	integer i
	integer nOutputs
	nOutputs = length_array (gOutputSelect[tpId])
	for (i = 1; i <= nOutputs; i++)
	{
	    integer outputId
	    outputId = gOutputSelect[tpId][i]
	    if (outputId > 0)
	    {
		doVolumeControl (outputId, audioCtlChannel2VolDir(button.input.channel))
	    }
	}
    }
}

DEFINE_FUNCTION doOutputMute (integer outputId)
{
    integer muteStatus
    if (outputId = 0)
    {
	debug (DBG_MODULE,6,'Ignoring mute press on unconnected output')
	return
    }
    if (gStatus.power[outputId] = 0)
    {
	debug (DBG_MODULE,6,'Ignoring mute press on powered-off output')
	return
    }
    muteStatus = !gStatus.volumeMute[outputId]
    gStatus.volumeMute[outputId] = muteStatus
    setAbsoluteMute (outputId, muteStatus)
    updateTpVolumeStates (outputId, 0, 1)
}

DEFINE_FUNCTION doOutputMuteMaster (integer tpId)
{
    integer outputIdId
    outputIdId = gOutputSelectMod[tpId]
    // if specific output is selected, just modify that one
    if (outputIdId > 0)
    {
	doOutputMute (gOutputSelect[tpId][outputIdId])
    }
    else
    {
	integer i
	integer nOutputs
	nOutputs = length_array (gOutputSelect[tpId])
	for (i = 1; i <= nOutputs; i++)
	{
	    integer outputId
	    outputId = gOutputSelect[tpId][i]
	    if (outputId > 0)
	    {
		doOutputMute (outputId)
	    }
	}
    }
}

DEFINE_FUNCTION doOutputPower (integer tpId, integer outputId, integer forceOff, integer forceOn)
{
    if (outputId == 0)
    {
	debug (DBG_MODULE,6,'Ignoring power press on unconnected output')
	return
    }
//    if (forceOff || (gStatus.matrix[outputId] && gStatus.power[outputId]))
    if (forceOff || (!forceOn && (gStatus.power[outputId] = ACFG_POWER_STATE_ON)))
    {
	// It's on, so turn it off
	gStatus.matrix[outputId] = 0
	gStatus.power[outputId] = ACFG_POWER_STATE_OFF
	checkDevicePower (outputId, ACFG_POWER_STATE_OFF)
	setAbsoluteOff (outputId)
	// Restore volume level to default for next power on (includes removing mute)
	resetVolumeLevelToDefault (outputId)
    }
    else
    {
	// It's off so switch to the current input, if one selected
	integer inputId
	inputId = gInputSelect[tpId]
	gStatus.matrix[outputId] = inputId
	gStatus.power[outputId] = ACFG_POWER_STATE_ON
	if (inputId > 0)
	{
	    checkDevicePower (outputId, ACFG_POWER_STATE_ON)
	    doSwitch (inputId, outputId)
	}
    }
    updateTpPowerStates (outputId)
}

DEFINE_FUNCTION doOutputPowerMaster (integer tpId)
{
    integer outputIdId
    outputIdId = gOutputSelectMod[tpId]
    // if specific output is selected, just modify that one
    if (outputIdId > 0)
    {
	doOutputPower (tpId,gOutputSelect[tpId][outputIdId],0,0)
    }
    else
    {
	// Power OFF for the entire group
	integer i
	integer nOutputs
	integer status
//	status = !gMasterPower[tpId]
//	gMasterPower[tpId] = status
	nOutputs = length_array (gOutputSelect[tpId])
	for (i = 1; i <= nOutputs; i++)
	{
	    integer outputId
	    outputId = gOutputSelect[tpId][i]
	    if (outputId > 0)
	    {
//		doOutputPower (tpId,outputId,!status,status)
		doOutputPower (tpId,outputId,1,0)
	    }
	}
//	updateTpMasterPowerState(tpId,status)
	updateTpMasterPowerState(tpId,ACFG_POWER_STATE_ON)
    }
}

DEFINE_FUNCTION doControlSelect (tpId)
{
    char    titleStr[16]
    integer outputIdId
    outputIdId = gOutputSelectMod[tpId]
    if (outputIdId = 0)
    {
	titleStr = 'ALL'
    }
    else
    {
	titleStr = gAllOutputs[gOutputSelect[tpId][outputIdId]].mShortName
    }
    debug (DBG_MODULE, 5, "'Setting audio output selection to: ',titleStr")
    send_command dvTpOutputCtl[tpId],"'TEXT',itoa(ACFG_OUTPUT_CTL_SELECT_TITLE),'-',titleStr"
}

DEFINE_FUNCTION doVolumeLevel (integer tpId, integer outputId, sinteger levelVal)
{
    sinteger scaledLevel
    if (outputId == 0)
    {
	debug (DBG_MODULE,6,'Ignoring level change on unconnected output')
	return
    }
    if (gIgnoreSliderLevelEvents[tpId])
    {
	debug (DBG_MODULE,9,'Ignoring slider level event for this TP')
	return
    }
    scaledLevel = scaleVolumeLevel (levelVal)
    if (gStatus.volume[outputId] != scaledLevel)
    {
	gStatus.volume[outputId] = scaledLevel
	debug (DBG_MODULE,9,"'Volume slider handler: level=',itoa(levelVal),'; scaled=',itoa(scaledLevel)")
	setAbsoluteVolume (outputId, scaledLevel)
	if (gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_ON)
	{
	    gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_OFF
	    updateTpVolumeStates (outputId, 0, 1)
	}
	else
	{
	    updateTpVolumeStates (outputId, tpId, 0)
	}
    }
}


(*
DEFINE_FUNCTION doInputGainSelection (integer tpId, integer inputId)
{
    debug (DBG_MODULE,9,"'Input Channel Selection Handler -- ',itoa(inputId)")
    // Input selection
    if (gInputCtl[tpId] > 0)
    {
	[dvTpInputCtl[tpId], gInputCtl[tpId]] = 0
    }
    gGainInput[tpId] = inputId
    [dvTPGain[tpId], gGainInput[tpId]] = 1
    // Send update to gain controls on this TP:
    updateTpGainLevel (tpId, scaleGainToLevel(gStatus.gain[gGainInput[tpId]]))
}
*)
(*
DEFINE_FUNCTION doGainControl (integer inputId, integer chan)
{
    if (chan == CHAN_GAIN_UP) // increment gain
    {
	if (gStatus.gain[inputId] >= MAX_GAIN) // stay within bounds
	{
	    gStatus.gain[inputId] = MAX_GAIN
	    debug (DBG_MODULE,9,"'Gain Step-up Handler (',itoa(inputId),'): already at max absolute level: ',itoa(gStatus.gain[inputId])")
	    return
	}
	gStatus.gain[inputId]++
	debug (DBG_MODULE,9,"'Gain Step-up Handler (',itoa(inputId),') increasing to absolute level: ',itoa(gStatus.gain[inputId])")
    }
    else // chan == CHAN_GAIN_DOWN, do decrement
    {
	if (gStatus.gain[inputId] < MIN_GAIN) // stay within bounds
	{
	    gStatus.gain[inputId] = MIN_GAIN
	    debug (DBG_MODULE,9,"'Gain Step-down Handler (',itoa(inputId),'): already at min absolute level: ',itoa(gStatus.gain[inputId])")
	    return
	}
	gStatus.gain[inputId]--
	debug (DBG_MODULE,9,"'Gain Step-up Handler (',itoa(inputId),') decreasing to absolute level: ',itoa(gStatus.gain[inputId])")
    }
    setAbsoluteGain (inputId, gStatus.gain[inputId])
    updateTpGainPopups (inputId, 0) // set the Gain slider position (on all TPs)
}
*)

// Function definitions
DEFINE_FUNCTION doInputGridSelection(integer tpId, integer input)
{
    // If currently selected input is pressed again, .
    if (input = gInputGrid[tpId])
    {
	// Send feedback to the previously selected TP button
	[dvTpInputGrid[tpId],gInputGrid[tpId]] = 0    // off
	gInputGrid[tpId] = 0
	debug (DBG_MODULE,5,"'Previous input deselected: ',itoa(input)")
    }
    else
    {
	// Turn off the previously selected TP button and turn on the new one
    	[dvTpInputGrid[tpId],gInputGrid[tpId]] = 0    // off
	gInputGrid[tpId] = input
    	[dvTpInputGrid[tpId],gInputGrid[tpId]] = 1    // on
	debug (DBG_MODULE,5,"'New input selected: ',itoa(input)")
    }
}

DEFINE_FUNCTION doOutputGridSelection (integer tpId, integer outputId)
{
    // If currently selected output is pressed again, .
    if (outputId = gOutputGrid[tpId])
    {
	// Send feedback to the previously selected TP button and disconnect at switch
	debug (DBG_MODULE,5,"'Previous output deselected: ',itoa(outputId)")
//	doOutputTurnOff (tpId, outputId)
    }
    else
    {
	// Turn off the previously selected TP button and turn on the new one
    	[dvTpOutputGrid[tpId],gOutputGrid[tpId]] = 0    // off
	gOutputGrid[tpId] = outputId
    	[dvTpOutputGrid[tpId],gOutputGrid[tpId]] = 1    // on
	debug (DBG_MODULE,5,"'New output selected: ',itoa(outputId)")
	doSwitch (gInputGrid[tpId], gOutputGrid[tpId])
    }
}

DEFINE_FUNCTION resetVolumeLevelsToDefault ()
{
    integer outputId
    for (outputId = 1; outputId <= length_array(gAllOutputs); outputId++)
    {
	resetVolumeLevelToDefault (outputId)
    }
}

DEFINE_FUNCTION resetGainLevelsToDefault ()
{
    integer inputId
    for (inputId = 1; inputId <= length_array(gAllInputs); inputId++)
    {
	resetGainLevelToDefault (inputId)
    }
}

DEFINE_FUNCTION resetVolumeLevelToDefault (integer outputId)
{
    sinteger defVol
    gStatus.volume[outputId] = gAllOutputs[outputId].mDefaultVolume
    gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_OFF
    setAbsoluteVolume (outputId, gStatus.volume[outputId])
    updateTpVolumeStates (outputId, 0, 1)
}

DEFINE_FUNCTION resetGainLevelToDefault (integer inputId)
{
    sinteger defGain
    defGain = gAllInputs[inputId].mDefaultGain
    if (defGain != gStatus.gain[inputId])
    {
	gStatus.gain[inputId] = defGain
	setAbsoluteGain (inputId, defGain)
//	updateTpGainStates (inputId, 0, 0) // set the Gain slider position (on all TPs)
    }
}

DEFINE_FUNCTION setAbsoluteGain (integer inputId, sinteger gain)
{
    debug (DBG_MODULE, 5, "'New gain value on input ',itoa(inputId),' == ',itoa(gain)")
    sendString (gGeneral.mAudioSwitcher, "'CL0I',itoa(inputId),'VA',itoa(gain),'T'")
}

DEFINE_FUNCTION setAbsoluteVolume (integer outputId, sinteger vol)
{
    debug (DBG_MODULE, 5,"'New volume value on output ',itoa(outputId),' == ',itoa(vol)")
    sendString (gGeneral.mAudioSwitcher, "'CL0O',itoa(outputId),'VA',itoa(vol),'T'")
}

DEFINE_FUNCTION setAbsoluteMute (integer outputId, integer muteOn)
{
    debug (DBG_MODULE, 5,"'Setting mute status on output ',itoa(outputId),' == ',itoa(muteOn==ACFG_MUTE_STATE_ON)")
    if (muteOn = ACFG_MUTE_STATE_ON)
        sendString (gGeneral.mAudioSwitcher, "'CL0O',itoa(outputId),'VMT'")
    else
        sendString (gGeneral.mAudioSwitcher, "'CL0O',itoa(outputId),'VUT'")
}

DEFINE_FUNCTION setAbsoluteOff (integer outputId)
{
    debug (DBG_MODULE, 5,"'Turn off output: ',itoa(outputId)")
    sendString (gGeneral.mAudioSwitcher, "'DL0O',itoa(outputId),'T'")
}

DEFINE_FUNCTION doSwitch (integer inputId, integer outputId)
{
    debug (DBG_MODULE, 5,"'Switching input ',itoa(inputId),' to ',itoa(outputId)")
    sendString (gGeneral.mAudioSwitcher, "'CL0I',itoa(inputId),'O',itoa(outputId),'T'")
}

DEFINE_FUNCTION sendString (dev dv, char msg[])
{
    send_string dv, msg
    debug (DBG_MODULE, 8, "'Sent string to ',devtoa(dv),': ',msg")
}

(*
DEFINE_FUNCTION updateTpGainState (integer tpId, sinteger lev)
{
    gIgnoreSliderLevelEvents[tpId] = 1
    send_level dvTpControlCtl[tpId], LEVEL_GAIN, lev
    wait 1  // = 0.1 sec
    {
	gIgnoreSliderLevelEvents[tpId] = 0
    }
}

DEFINE_FUNCTION updateTpGainStates (integer inputId, integer skipTpId)
{
    // Update any other TPs that also happen to be controlling this input
    sinteger lev
    integer tpId
    lev = scaleGainToLevel(gStatus.gain[inputId])
    for (tpId = 1; tpId <= length_array(dvTpGain); tpId++)
    {
	if (tpId = skipTpId)
	{
	    continue
	}
	if (gGainInput[tpId] = inputId)
	{
	    updateTpGainState (tpId, lev)
	}
    }
}
*)

DEFINE_FUNCTION updateTpVolumeStates (integer outputId, integer skipTpId, integer forceMuteStatus)
{
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
}

DEFINE_FUNCTION updateTpVolumeState (integer tpId, integer tpUiId, sinteger lev, integer forceMuteStatus, integer muteEnabled)
{
    // Update the volume slider
    gIgnoreSliderLevelEvents[tpId] = 1
    send_level dvTpOutputCtl[tpId], audioCtlUi2VolumeLevel(tpUiId), lev
    wait 1 // 0.1 sec
    {
	gIgnoreSliderLevelEvents[tpId] = 0
    }
    if (forceMuteStatus)
    {
	// Update the mute button
	[dvTpOutputCtl[tpId],audioCtlUi2VolMuteAddress(tpUiId)] = (muteEnabled)
	// Enable/disable the volume buttons and slider based on mute state
	send_string dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolUpAddress(tpUiId)),'.',itoa(audioCtlUi2VolDownAddress(tpUiId)),',',itoa(muteEnabled)"
    }
}

DEFINE_FUNCTION updateTpPowerStates (integer outputId)
{
    // Update any TPs that happen to be controlling this output
    integer nTps
    integer tpId
    integer nOutputs
    integer i
    nTps = length_array(dvTpOutputCtl)
    for (tpId = 1; tpId <= nTps; tpId++)
    {
	if (gTpStatus[tpId] = 0)
	    continue
	nOutputs = length_array(gOutputSelect[tpId])
	for (i = 1; i <= nOutputs; i++)
	{
	    if (gOutputSelect[tpId][i] = outputId)
	    {
		updateTpPowerState (tpId, i, gStatus.power[outputId])
		updateTpOutputUi (tpId, i, outputId)
	    }
	}
    }
}

DEFINE_FUNCTION updateTpPowerState (integer tpId, integer tpUiId, integer status)
{
    [dvTpOutputCtl[tpId],audioCtlUi2PowerAddress(tpUiId)] = (status = ACFG_POWER_STATE_ON)
}

DEFINE_FUNCTION updateTpMasterPowerState (integer tpId, integer status)
{
    [dvTpOutputCtl[tpId],ACFG_OUTPUT_CTL_POWER_MASTER] = status
}


(*
    sinteger lev
    integer tpId
    integer muteEnabled
    lev = scaleVolumeToLevel(gStatus.volume[outputId])
    muteEnabled = (gStatus.volumeMute[outputId] = MUTE_STATE_ON)
    for (tpId = 1; tpId <= length_array(dvTpVolume); tpId++)
    {
	if (tpId = skipTpId)
	{
	    continue
	}
	if (gVolOutput[tpId] = outputId)
	{
	    updateTpVolumePopup (tpId, lev, forceMuteStatus, muteEnabled)
	}
    }
}
*)

DEFINE_FUNCTION updateTpInputs (integer tpId)
{
    integer i
    integer nInputs
    nInputs = length_array (gAllInputs)
    for (i = 1; i <= nInputs; i++)
    {
	send_command dvTpInputSelect[tpId],"'TEXT',itoa(i),'-',gAllInputs[i].mShortName"
	send_command dvTpInputGrid[tpId], "'TEXT',itoa(i),'-',gAllInputs[i].mShortName"
	[dvTpInputSelect[tpId],i] = (i = gInputSelect[tpId])
	[dvTpInputGrid[tpId],i]   = (i = gInputGrid[tpId])
    }
    updateTpInput (tpId, gInputSelect[tpId])
}

DEFINE_FUNCTION updateTpGridOutputs (integer tpId)
{
    integer i
    integer nOutputs
    nOutputs = length_array (gAllOutputs)
    for (i = 1; i <= nOutputs; i++)
    {
	send_command dvTpOutputGrid[tpId],"'TEXT',itoa(i),'-',gAllOutputs[i].mShortName"
	[dvTpOutputGrid[tpId],i] = (i = gOutputGrid[tpId])
    }
}

DEFINE_FUNCTION updateTpOutputs (integer tpId)
{
    integer i
    integer nOutputs
    nOutputs = length_array(gOutputSelect[tpId])
    gIgnoreSliderLevelEvents[tpId] = 1
    for (i = 1; i <= nOutputs; i++)
    {
	integer outputId
	outputId = gOutputSelect[tpId][i]
	updateTpOutput (tpId, i, outputId)
    }
    for (; i <= ACFG_MAX_AUDIO_OUTPUTS; i++)
    {
	updateTpOutput (tpId, i, 0)
    }
    // Set the visibility of the prev/next buttons
//  send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(ACFG_OUTPUT_CTL_SELECT_PREV),'&',itoa(ACFG_OUTPUT_CTL_SELECT_PREV),',',itoa(nOutputs>0)"
    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(ACFG_OUTPUT_CTL_SELECT_PREV),',',itoa(nOutputs>1)"
    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(ACFG_OUTPUT_CTL_SELECT_NEXT),',',itoa(nOutputs>1)"
    doControlSelect(tpId)
    wait 10 // 10 = 1 sec
    {
	// wait a second for the TP to process all this stuff
	gIgnoreSliderLevelEvents[tpId] = 0
    }
}

DEFINE_FUNCTION updateTpOutputUi (integer tpId, integer tpUiId, integer outputId)
{
    if (outputId = 0)
    {
	if (gTpOutputUiState[tpId][tpUiId] != OUTPUT_UI_STATE_DISABLED)
	{
	    
	    if (0) // Bug in iRidium not handing & and . in these commands
	    {
		send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2TitleAddress(tpUiId)),'&',
							  itoa(audioCtlUi2PowerAddress(tpUiId)),'&',
							  itoa(audioCtlUi2VolDownAddress(tpUiId)),'&',
							  itoa(audioCtlUi2VolUpAddress(tpUiId)),'&',
							  itoa(audioCtlUi2VolMuteAddress(tpUiId)),'&',
							  itoa(audioCtlUi2VolumeLevel(tpUiId)),',0'"
//		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolumeLevel(tpUiId)),',0'"
	    }
	    else
	    {
		send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2TitleAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2PowerAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolDownAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolUpAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolMuteAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolumeLevel(tpUiId)),',0'"
	    }
	    gTpOutputUiState[tpId][tpUiId] = OUTPUT_UI_STATE_DISABLED
	}
    }
    else
    {
	switch (gTpOutputUiState[tpId][tpUiId])
	{
	case OUTPUT_UI_STATE_ENABLED_OFF:
	{
	    if (gStatus.power[outputId] = ACFG_POWER_STATE_ON)
	    {
		// Previous UI state was off but we need it on
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolDownAddress(tpUiId)),',1'"
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolUpAddress(tpUiId)),',1'"
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolMuteAddress(tpUiId)),',1'"
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolumeLevel(tpUiId)),',1'"
		gTpOutputUiState[tpId][tpUiId] = OUTPUT_UI_STATE_ENABLED_ON
	    }
	    break
	} // case
	case OUTPUT_UI_STATE_ENABLED_ON:
	{
	    if (gStatus.power[outputId] = ACFG_POWER_STATE_OFF)
	    {
		// Previous UI state was on but we need it off
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolDownAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolUpAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolMuteAddress(tpUiId)),',0'"
		send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolumeLevel(tpUiId)),',0'"
		gTpOutputUiState[tpId][tpUiId] = OUTPUT_UI_STATE_ENABLED_OFF
	    }
	    break
	} // case
	default:
	{
	    // We're not sure, so set them all to what they're supposed to be
	    integer powerOn
	    powerOn = gStatus.power[outputId] = ACFG_POWER_STATE_ON
	    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2TitleAddress(tpUiId)),',1'"
	    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2PowerAddress(tpUiId)),',1'"
	    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolDownAddress(tpUiId)),',1'"
	    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolUpAddress(tpUiId)),',1'"
	    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolMuteAddress(tpUiId)),',1'"
	    send_command dvTpOutputCtl[tpId],"'^SHO-',itoa(audioCtlUi2VolumeLevel(tpUiId)),',1'"
	    send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolDownAddress(tpUiId)),',',itoa(powerOn)"
	    send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolUpAddress(tpUiId)),',',itoa(powerOn)"
	    send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolMuteAddress(tpUiId)),',',itoa(powerOn)"
	    send_command dvTpOutputCtl[tpId],"'^ENA-',itoa(audioCtlUi2VolumeLevel(tpUiId)),',',itoa(powerOn)"
	    if (powerOn)
		gTpOutputUiState[tpId][tpUiId] = OUTPUT_UI_STATE_ENABLED_ON
	    else
		gTpOutputUiState[tpId][tpUiId] = OUTPUT_UI_STATE_ENABLED_OFF
	} // default
	} // switch
    }
}

DEFINE_FUNCTION updateTpOutput (integer tpId, integer tpUiId, integer outputId)
{
    if (outputId > 0)
    {
	send_command dvTpOutputCtl[tpId],"'TEXT',itoa(audioCtlUi2TitleAddress(tpUiId)),'-',gAllOutputs[outputId].mShortName"
	[dvTpOutputCtl[tpId],audioCtlUi2VolMuteAddress(tpUiId)] = (gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_ON)
	[dvTpOutputCtl[tpId],audioCtlUi2PowerAddress(tpUiId)]   = (gStatus.power[outputId]      = ACFG_POWER_STATE_ON)
	debug(DBG_MODULE,9,"'foo: check power state  (',itoa(audioCtlUi2PowerAddress(tpUiId)),'): ',itoa(gStatus.power[outputId])")
	send_level dvTpOutputCtl[tpId], audioCtlUi2VolumeLevel(tpUiId), scaleVolumeToLevel(gStatus.volume[outputId])
    }
    else
    {
//	[dvTpOutputCtl[tpId],audioCtlUi2VolMuteAddress(tpUiId)] = 0
//	[dvTpOutputCtl[tpId],audioCtlUi2PowerAddress(tpUiId)]   = 0
	send_level dvTpOutputCtl[tpId], audioCtlUi2VolumeLevel(tpUiId), 0
    }
    updateTpOutputUi (tpId, tpUiId, outputId)
}

DEFINE_FUNCTION updateTpInput (integer tpId, integer inputId)
{
    if (inputId > 0)
    {
	send_command dvTpInputSelect[tpId],"'TEXT',itoa(ACFG_INPUT_TITLE),'-',gAllInputs[inputId].mName"
	send_command dvTpInputSelect[tpId],"'TEXT',itoa(ACFG_INPUT_SHORT_TITLE),'-',gAllInputs[inputId].mShortName"
    }
    else
    {
	send_command dvTpInputSelect[tpId],"'TEXT',itoa(ACFG_INPUT_TITLE),'-Select Input'"
	send_command dvTpInputSelect[tpId],"'TEXT',itoa(ACFG_INPUT_SHORT_TITLE),'-Select Input'"
    }
}

DEFINE_FUNCTION checkDevicePower (integer outputId, integer onOrOff)
{
    if (gAllOutputs[outputId].mLocalInputChannel == 0)
    {
	// This output has no power switch to fiddle with
	return
    }
    select
    {
    active (onOrOff = ACFG_POWER_STATE_OFF):
    {
	debug (DBG_MODULE, 2, "'pulsing OFF to device ',devtoa(gAllOutputs[outputId].mDev)")
	doOutputPulse (outputId, CHAN_POWER_OFF)
    }
    active (onOrOff = ACFG_POWER_STATE_ON):
    {
	debug (DBG_MODULE, 2, "'pulsing ON to device ',devtoa(gAllOutputs[outputId].mDev)")
	doOutputPulse (outputId, CHAN_POWER_ON)
	wait 10 // 10 = 1 second
	{
	    debug (DBG_MODULE, 2, "'pulsing A/V input switch (',
		itoa(gAllOutputs[outputId].mLocalInputChannel),
		' to device ',devtoa(gAllOutputs[outputId].mDev)")
	    doOutputPulse (outputId), gAllOutputs[outputId].mLocalInputChannel)
	}
    }
    active (1):
    {
	debug (DBG_MODULE, 1, "'programming error: checkDevicePower (',itoa(outputId),',',itoa(onOrOff),')'")
    } // active
    } // select
}

DEFINE_FUNCTION reconnectTp (integer tpId)
{
    gTpStatus[tpId] = 1
    updateTpInputs (tpId)
    updateTpOutputs (tpId)
    debug (DBG_MODULE,9,"'Restored TP selections: ',
	devtoa(dvTpInputSelect[tpId]),', ',devtoa(dvTpOutputSelect[tpId]),', ',
	devtoa(dvTpOutputCtl[tpId]),', ',devtoa(dvTpInputGrid[tpId]),' & ',
	devtoa(dvTpOutputGrid[tpId])")
}

DEFINE_FUNCTION disconnectTp (integer tpId)
{
    gTpStatus[tpId] = 0
    gIgnoreSliderLevelEvents[tpId] = 1
}

DEFINE_FUNCTION checkSwitchMatrix ()
{
    integer inputId
    for (inputId = 1; inputId <= length_array(gAllInputs); inputId++)
    {
	sendString (gGeneral.mAudioSwitcher, "'SL0I',itoa(inputId),'T'")
    }
}

DEFINE_FUNCTION checkSwitchVolumeLevels ()
{
    integer outputId
    for (outputId = 1; outputId <= length_array(gAllOutputs); outputId++)
    {
	sendString (gGeneral.mAudioSwitcher, "'SL0O',itoa(outputId),'VT'")
    }
}

DEFINE_FUNCTION handleSwitchResponse (char msg[])
{
    debug (DBG_MODULE,9,"'handleSwitchResponse: buffer contains: ',msg")
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
		integer outputId
		remove_string(msg,'O',1)
		outputId = atoi(msg)
		select
		{
		active (find_string(msg,'VT( ',1)):
		{
		    remove_string(msg,'VT( ',1)
		    if (msg[1] = 'M')
		    {
			debug (DBG_MODULE,6,"'checking volume: output=',itoa(outputId),' -> volume=MUTED'")
			if (gStatus.volumeMute[outputId] != ACFG_MUTE_STATE_ON)
			{
			    // Mute is on but we didn't know it
			    debug (DBG_MODULE,1,"'updating volume: output=',itoa(outputId),' -> volume=MUTED'")
			    gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_ON
			    updateTpVolumeStates (outputId, 0, 1)
			}
		    }
		    else
		    {
			sinteger vol
			vol = atoi(msg)
			debug (DBG_MODULE,6,"'checking volume: output=',itoa(outputId),' -> volume=',itoa(vol)")
			if (gStatus.volume[outputId] != vol)
			{
			    debug (DBG_MODULE,1,"'updating volume: output=',itoa(outputId),' -> volume=',itoa(vol)")
			    gStatus.volumeMute[outputId] = ACFG_MUTE_STATE_OFF
			    gStatus.volume[outputId] = vol
			    updateTpVolumeStates (outputId, 0, 1)
			}
		    }
		    remove_string(msg,')',1)
		} // active 'VT('
		active (find_string(msg,'T( ',1)):
		{
		    integer inputId
		    remove_string(msg,'T( ',1)
		    inputId = atoi(msg)
		    debug (DBG_MODULE,6,"'checking matrix: input=',itoa(inputId),' -> output=',itoa(outputId)")
		    if (gStatus.matrix[outputId] != inputId)
		    {
			// Matrix is wrong so update it
			debug (DBG_MODULE,1,"'updating matrix: input=',itoa(inputId),' -> output=',itoa(outputId)")
			gStatus.matrix[outputId] = inputId
			gStatus.power[outputId] = ACFG_POWER_STATE_ON
			// update the TPs?
		    }
		    remove_string(msg,')',1)
		} // active 'T('
		} // select
	    } // active 'O'
	    active (find_string(msg,'I',1)):
	    {
		// 'I' for Output
		integer inputId
		remove_string(msg,'I',1)
		inputId = atoi(msg)
		select
		{
		active (find_string(msg,'VT( ',1)):
		{
		    remove_string(msg,'VT( ',1)
		    if (msg[1] = 'M')
		    {
			// We don't handle input mutes right now
			debug (DBG_MODULE,6,"'ignoring gain mute: input=',itoa(inputId)")
		    }
		    else
		    {
			sinteger gain
			gain = atoi(msg)
			debug (DBG_MODULE,6,"'checking gain: input=',itoa(inputId),' -> gain=',itoa(gain)")
			if (gStatus.gain[inputId] != gain)
			{
			    debug (DBG_MODULE,1,"'updating gain: input=',itoa(inputId),' -> gain=',itoa(gain)")
			    gStatus.gain[inputId] = gain
//			    updateTpGainStates (inputId, 0)
			}
		    }
		    remove_string(msg,')',1)
		} // active 'VT('
		active (find_string(msg,'T( ',1)):
		{
		    // The list of outputs for this input.
		    integer outputId
		    remove_string(msg,'T( ',1)
		    for (outputId = atoi(msg);
			 outputId > 0;
			 outputId = atoi(msg))
		    {
			debug (DBG_MODULE,6,"'checking matrix: input=',itoa(inputId),' -> output=',itoa(outputId)")
			if (gStatus.matrix[outputId] != inputId)
			{
			    // Matrix is wrong so update it
			    debug (DBG_MODULE,1,"'updating matrix: input=',itoa(inputId),' -> output=',itoa(outputId)")
			    gStatus.matrix[outputId] = inputId
			    gStatus.power[outputId] = ACFG_POWER_STATE_ON
			    // update the TPs?
			}
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

DEFINE_FUNCTION sinteger scaleTo (sinteger value, 
				  sinteger minFromVal, sinteger maxFromVal,
				  sinteger minToVal,   sinteger maxToVal,
				  integer  verify)
{
    sinteger result
    result = minToVal + ((maxToVal-minToVal)*(value-minFromVal))/(maxFromVal-minFromVal)
    if (verify)
    {
	// Verify that the scaling would scale back to the same value in reverse.
	sinteger check;
	check = scaleTo (result, minToVal, maxToVal, minFromVal, maxFromVal, 0)
	if (check != value)
	{
	    if (check > value)
	    {
		if (result > minToVal)
		    return (result - 1)
	    }
	    else
	    {
		if (result < maxToVal)
		    return (result + 1)
	    }
	}
    }
    return result
}

DEFINE_FUNCTION sinteger scaleVolumeLevel (sinteger levelValue)
{
    // Scale a number between 0 & 255 to -100 & +700
    return scaleTo (levelValue, MIN_LEVEL, MAX_LEVEL, MIN_VOLUME, MAX_VOLUME, 0)
}

DEFINE_FUNCTION sinteger scaleVolumeToLevel (sinteger volume)
{
    // Scale a number between -100 & +700 to 0 & 255
    return scaleTo (volume, MIN_VOLUME, MAX_VOLUME, MIN_LEVEL, MAX_LEVEL, 1)
}

DEFINE_FUNCTION sinteger scaleGainLevel (sinteger levelValue)
{
    // Scale a number between 0 & 255 to -100 & +100
    return scaleTo (levelValue, MIN_LEVEL, MAX_LEVEL, MIN_GAIN, MAX_GAIN, 0)
}

DEFINE_FUNCTION sinteger scaleGainToLevel (sinteger gain)
{
    // Scale a number between -100 & +100 to 0 & 255
    return scaleTo (gain, MIN_GAIN, MAX_GAIN, MIN_LEVEL, MAX_LEVEL, 1)
}

DEFINE_FUNCTION checkVolumeDefaults()
{
    integer i
    for (i = 1; i <= length_array(gAllOutputs); i++)
    {
	if (gStatus.volume[i] = 0)
	{
	    // We must be going through a cold start-up (rare)
	    gStatus.volume[i] = gAllOutputs[i].mDefaultVolume
	}
    }
}
*)

DEFINE_FUNCTION checkTpOutputZone (integer tpId, integer outputId)
{
    // Send a message to the ZoneControl module to verify that an appropriate zone is selected for this output.
    send_command vdvZoneControl, "'MATCHZONE-TP',itoa(tpId),'O',itoa(outputId)"
}


DEFINE_EVENT

// TP reconnection: We should use the devices with the highest-numbered port so
// that we can send things down the other ports, which have already be reconnected. 
DATA_EVENT[dvTpInputControl]
{
    ONLINE:
    {
	// Either the Master just restarted or the TP was just turned on again
	integer tpId
	integer outputIdId
	tpId = get_last(dvTpInputControl)
	debug (DBG_MODULE, 1, "'TP ',itoa(tpId),' (',devtoa(dvTpInputControl[tpId]),') is online; playerId=',
	      		      itoa(gTpInput[tpId])")
	updateTpOutputListFull (tpId)
	outputIdId = gTpOutputSelect[tpId]
	doTpOutputSelect (tpId, outputIdId, 1)
	debug (DBG_MODULE, 1, "'Restored TP output selections: ',devtoa(dvTpOutputSelect[tpId])")
	doTpInputSelect (tpId, gTpInput[tpId], 1)
    }
    OFFLINE: {}
    STRING: { debug (DBG_MODULE, 8, "'received string from TP (',devtoa(data.device),'): ',data.text") }
}

// Handle commands from other modules
DATA_EVENT[vdvAvControl]
{
    ONLINE: {}
    OFFLINE: {}
    COMMAND:
    {
	debug (DBG_MODULE, 5, "'received A/V group control command from ',devtoa(data.device),': ',data.text")
	handleAvControlCommand (data.text)
    }
    STRING:
    {
	debug (DBG_MODULE, 5, "'received A/V group control string from ',devtoa(data.device),': ',data.text")
    }
}

DEFINE_FUNCTION handleAvControlCommand (char msg[])
{
    select
    {
    active (find_string(msg,'OUTPUTS-',1)):
    {
	// Set the output list for a TP
	remove_string(msg,'OUTPUTS-',1)
	select
	{

	active (find_string(msg,'TP',1)):
	{
	    // 'TP' for TouchPad
	    integer tpId, count, refresh, groupId
	    remove_string(msg,'TP',1)
	    tpId = atoi(msg)
	    count = 0
	    set_length_array (gTpOutputSelectList[tpId], AVCFG_MAX_OUTPUTS)
	    if (find_string(msg,'REF',1))
	    {
		remove_string(msg,'REF',1)
		refresh = atoi(msg)
	    }
	    if (find_string(msg,'Z',1))
	    {
		remove_string(msg,'Z',1)
		groupId = atoi(msg)
	    }
	    while (find_string(msg,'O',1))
	    {
		integer outputId
		remove_string(msg,'O',1)
		outputId = atoi(msg)
		count++
		gTpOutputSelectList[tpId][count] = outputId
	    }
	    set_length_array (gTpOutputSelectList[tpId], count)
	    doTpSetZone (tpId, groupId, !refresh)
	} // active
	} // select
    } // active

    active (find_string(msg,'POWER-OFF',1)):
    {
	// Power OFF (A/V devices in the following list)
	integer outputId
	remove_string(msg,'POWER-OFF',1)
	if (find_string(msg,'ALL',1))
	{
	    // Power OFF all of the A/V output devices and PAUSE all of the input devices
	    integer i
	    remove_string(msg,'ALL',1)
	    for (i = 1; i <= length_array(gAllOutputs); i++)
	    {
		setOutputPowerStatus (i, POWER_STATUS_OFF, 1, 1)
	    }
	    stopAllAvInputs()
	}
	else
	{
	    while (find_string(msg,'O',1))
	    {
		remove_string(msg,'O',1)
		setOutputPowerStatus (atoi(msg), POWER_STATUS_OFF, 1, 1)
	    }
	}
    } // active

    active (find_string(msg,'SWITCH-',1)):
    {
	// Switch outputs to a new input
	remove_string(msg,'SWITCH-',1)
	select
	{
	active (find_string(msg,'INPUT',1)):
	{
	    // 'INPUT' for setting the input for the output list
	    integer inputId, count
	    integer outputIds[AVCFG_MAX_OUTPUTS]
	    remove_string(msg,'INPUT',1)
	    inputId = atoi(msg)
	    count = 0
	    set_length_array (outputIds, AVCFG_MAX_OUTPUTS)
	    while (find_string(msg,'O',1))
	    {
		integer outputId
		remove_string(msg,'O',1)
		outputId = atoi(msg)
		count++
		outputIds[count] = outputId
	    }
	    set_length_array (outputIds, count)
	    doMultiInputOutputSwitch (inputId, outputIds)
	} // active
	} // select
    } // active
    } // select
}


DEFINE_START
{
    integer i
    tpReadConfigFile ('AvControl', tpConfigFile, gPanels)
    tpMakeLocalDevArray ('AvControl', dvTpInputSelect,	gPanels, TP_PORT_AV_INPUT_SELECT)
    tpMakeLocalDevArray ('AvControl', dvTpInputControl,	gPanels, TP_PORT_AV_INPUT_CONTROL)
    tpMakeLocalDevArray ('AvControl', dvTpOutputSelect,	gPanels, TP_PORT_AV_OUTPUT_SELECT)
    tpMakeLocalDevArray ('AvControl', dvTpOutputControl,gPanels, TP_PORT_AV_OUTPUT_CONTROL)
    rebuild_event()
}

// Without the wait here, it seems like this module causes some strange initialization problem:
wait 11
{
    set_length_array (gAllOutputs, AVCFG_MAX_OUTPUTS)
    readConfigFile (DBG_MODULE, configFile)
    set_length_array (gAllInputs,  gMaxInput)
    set_length_array (gAllOutputs, gMaxOutput)
    set_length_array (gOutputPowerStatus, gMaxOutput)
    calcInputsForOutputs ()
    rebuild_event()
    create_buffer gGeneral.mAudioSwitcher, bRecvBufAudio
    create_buffer gGeneral.mVideoSwitcher, bRecvBufVideo
}

wait 377 // 37.7 seconds after startup
{
    setAudioSwitchGainLevels()	// Reset gain levels to configured defaults
}

