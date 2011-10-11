PROGRAM_NAME='AvConfig'

// Audio and video input and output config definitions.
//
// These are used by several modules but must be served up to each module using 
// serialization over TCP. The AvConfigServer module will listen for requests 
// for the AV configuration data.

#if_not_defined __AV_CONFIG__
#define __AV_CONFIG__

#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'ChannelDefs.axi'
#include 'TouchPanelConfig.axi'

DEFINE_CONSTANT

AVCFG_MAX_INPUTS		= 32
AVCFG_MAX_OUTPUTS		= 64

AVCFG_INPUT_TYPE_UNKNOWN	= 0
AVCFG_INPUT_TYPE_SWITCH		= 1
AVCFG_INPUT_TYPE_LOCAL		= 2

AVCFG_OUTPUT_TYPE_UNKNOWN	= 0
AVCFG_OUTPUT_TYPE_AUDIO		= 1	// Speakers, red-white RCA outputs
AVCFG_OUTPUT_TYPE_TV_MASTER	= 2	// Standalone TVs
AVCFG_OUTPUT_TYPE_TV_SLAVE	= 3	// TVs connected to AV Receivers
AVCFG_OUTPUT_TYPE_RECEIVER	= 4	// AV Receiver, usually with slave TV connected, and non-switched (local) AV input(s)

AVCFG_OUTPUT_VOL_UNKNOWN	= 0
AVCFG_OUTPUT_VOL_RELATIVE	= 1
AVCFG_OUTPUT_VOL_DISCRETE	= 2

AVCFG_SCENE_TYPE_UNKNOWN	= 0
AVCFG_SCENE_TYPE_NONE		= 1
AVCFG_SCENE_TYPE_MENU		= 2
AVCFG_SCENE_TYPE_EXPLICIT	= 3

AVCFG_SCENE_UNKNOWN		= 0
AVCFG_SCENE_MUSIC		= 1
AVCFG_SCENE_MOVIES		= 2
AVCFG_SCENE_TV			= 3
AVCFG_SCENE_SPORTS		= 4

AVCFG_IR_TYPE_NORMAL		= 0
AVCFG_IR_TYPE_SEND_COMMAND	= 1

AVCFG_AUDIO_SWITCH_ACTION_NORMAL = 0
AVCFG_AUDIO_SWITCH_ACTION_OFF    = 1

// Default values for outputs that have discrete volume control
sinteger AVCFG_DEFAULT_VOL_MIN		= -700  // -70.0 Db
sinteger AVCFG_DEFAULT_VOL_MAX		=  100  // +10.0 Db
sinteger AVCFG_DEFAULT_VOL_DEFAULT	= -300  // -30.0 Db
sinteger AVCFG_DEFAULT_VOL_INCREMENT	=    5  //   0.5 Db
sinteger AVCFG_DEFAULT_GAIN_MIN		= -100  // -10.0 Db
sinteger AVCFG_DEFAULT_GAIN_MAX		=  100  // +10.0 Db

// Default supported channels are just the power on/off and volume controls
char AVCFG_DEFAULT_SUPPORTED_CHANNELS[] = '9&24.28'
char AVCFG_DEFAULT_CHANNEL_MASK[CHAN_MAX_CHANNELS] =
{
     0,0,0,0,0,0,0,0,1,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,1,1,1,1,1,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 
     0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 
     0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 
     0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 
     0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 
     0,0,0,0,0
}

AVCFG_MAX_SUPPORTED_CHANNEL_STRLEN	= 1024

AVCFG_MUTE_STATE_OFF  = 0
AVCFG_MUTE_STATE_ON   = 1
AVCFG_POWER_STATE_OFF = 0
AVCFG_POWER_STATE_ON  = 1

DEFINE_VARIABLE

volatile integer AVCFG_INPUT_SELECT[] = {
     1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32 }
    // ...should be filled to AVCFG_MAX_INPUTS

volatile integer AVCFG_OUTPUT_SELECT[] = {
     1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
    51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
    61, 62, 63, 64 }
    // ...should be filled to AVCFG_MAX_OUTPUTS

constant integer AVCFG_OUTPUT_SELECT_ALL		= 255
constant integer AVCFG_OUTPUT_SELECT_PREV		= 202
constant integer AVCFG_OUTPUT_SELECT_NEXT		= 203
constant char    AVCFG_ADDRESS_OUTPUT_SELECT[]		= '201'
constant char    AVCFG_ADDRESS_OUTPUT_SELECT_PREV[]	= '202'
constant char    AVCFG_ADDRESS_OUTPUT_SELECT_NEXT[]	= '203'
constant char    AVCFG_ADDRESS_OUTPUT_SELECT_AUDIO[]	= '204'
constant char    AVCFG_ADDRESS_OUTPUT_SELECT_VIDEO[]	= '205'
constant char    AVCFG_ADDRESS_OUTPUT_SELECT_MINI[]	= '206'
constant char    AVCFG_ADDRESS_OUTPUT_NAME[]		= '211'
constant char    AVCFG_ADDRESS_OUTPUT_SHORT_NAME[]	= '212'
constant char    AVCFG_ADDRESS_INPUT_SELECT[]		= '201'
constant char    AVCFG_ADDRESS_INPUT_SELECT_PREV[]	= '202'
constant char    AVCFG_ADDRESS_INPUT_SELECT_NEXT[]	= '203'
constant char    AVCFG_ADDRESS_INPUT_NAME[]		= '211'
constant char    AVCFG_ADDRESS_INPUT_SHORT_NAME[]	= '212'


DEFINE_TYPE

structure AvTpInfo
{
    integer	mEnabled
    integer	mPanelId
    integer	mAudioOutputListOrder[AVCFG_MAX_OUTPUTS]
    integer	mVideoOutputListOrder[AVCFG_MAX_OUTPUTS]
}

structure AvGeneral
{
    dev		mAudioSwitcher
    dev		mVideoSwitcher
    AvTpInfo	mTpDefaults
}

structure AvInput
{
    integer	mId			// ID for referencing other objects
    dev		mDev			// Device for this input
    char	mName[32]		// Name for this AV input
    char	mShortName[16]		// Short name for this AV input
    char	mSupportedChannels[AVCFG_MAX_SUPPORTED_CHANNEL_STRLEN] // List of channels representing buttons
    char	mChannelMask[CHAN_MAX_CHANNELS] // 0/1 array of channels representing buttons
    char	mChannelMap[CHAN_MAX_CHANNELS]	// Map to normalize channels to our standard
    integer	mLocationType		// Is this a switch AV input or local AV input
    integer	mVideoSwitchId		// Video switch input ID (0 if not connected to video switch)
    integer	mAudioSwitchId		// Audio switch input ID (0 if not connected to audio switch)
    sinteger	mAudioGain		// Gain into audio switch
    integer	mLocalInputChannel	// Input channel for this (local) input on its output
    integer	mSlaveAutoOn		// Whether to turn on a slave TV automatically (AVR only) when using this 
    					// input (e.g., maybe set to false for music inputs)
    integer	mScene			// Type of input (to help displays select an appropriate scene)
}


structure AvOutput
{
    // Fields common to all AV outputs
    integer	mId			// Unique ID for this output
    char	mName[32]		// Name for this output
    char	mShortName[16]		// Short name for this output
    integer	mAudioSwitchId		// Audio switch output ID
    integer	mVideoSwitchId		// Video switch output ID
    integer	mOutputType		// Audio, Master TV, Slave TV, or AV Receiver
    integer	mVolType		// Relative or discrete volume.
//    integer	mSceneType		// How scenes are supported, if at all.
    // The following fields are only relevant to controllable output devices, such as TVs and AVRs
    dev		mDev			// Device for this output (AVRs only; not TVs and speakers)
    // The following fields are only relevant to devices that are controlled by IR
    integer	mIrType	    	     	// How to control the IR interface
    char	mSupportedChannels[AVCFG_MAX_SUPPORTED_CHANNEL_STRLEN] // List of channels representing buttons
    char	mChannelMask[CHAN_MAX_CHANNELS] // 0/1 array of channels representing buttons
    char	mChannelMap[CHAN_MAX_CHANNELS]	// Map to normalize channels to our standard
    // The following fields are only relevant to master output devices, such as Master TVs and AVRs
    integer	mSwitchedInputChannel // AMX channel for switched audio input sources (0 = none)
//    integer	mSwitchedVideoInputChannel // AMX channel for switched video input sources (0 = none)
    integer     mLocalInputIds[10]	// Locally connected AV input IDs (mId of AvInputs)
    integer	mAvrTvId[8]		// IDs of the slave TVs connected to this AVR (if this is an AVR)
    // The following fields are only relevant to outputs with discrete volume control:
    sinteger	mVolumeMin  	     	// Minimum discrete volume
    sinteger	mVolumeMax  	     	// Maximum discrete volume
    sinteger	mVolumeDefault		// Default volume for this output (-700 to 100, in 10ths of dB)
    sinteger	mVolumeIncrement	// How much to jump for each up/down click (in 10ths of dB)
    // The following field is calculated automatically after reading the configuration
    integer	mAllInputIds[AVCFG_MAX_INPUTS]	       // IDs of all possible inputs for this output
}

DEFINE_CONSTANT
READING_NONE			= 0
READING_GENERAL			= 1
READING_TOUCH_PANEL		= 2
READING_SUPPORTED_CHANNELS	= 3
READING_INPUT			= 4
READING_OUTPUT			= 5
MAX_SUPPORTED_CHANNEL_NAMELEN	= 64


DEFINE_TYPE

structure SupportedChannels
{
    char	mDeviceName[MAX_SUPPORTED_CHANNEL_NAMELEN]
    char	mChannels[AVCFG_MAX_SUPPORTED_CHANNEL_STRLEN]
    char	mChannelMask[CHAN_MAX_CHANNELS]
    char	mChannelMap[CHAN_MAX_CHANNELS]
}

DEFINE_VARIABLE

volatile AvGeneral gGeneral
volatile AvInput   gAllInputs[AVCFG_MAX_INPUTS]
volatile AvOutput  gAllOutputs[AVCFG_MAX_OUTPUTS]
volatile AvTpInfo  gTpInfo[TP_MAX_PANELS]
volatile SupportedChannels  suppChannels[AVCFG_MAX_OUTPUTS]

volatile integer gThisItem	= 0
volatile integer gMaxInput	= 0
volatile integer gMaxOutput	= 0
volatile integer gReadMode	= READING_NONE
volatile integer gOutputType	= AVCFG_OUTPUT_TYPE_UNKNOWN
volatile integer gVolType	= AVCFG_OUTPUT_VOL_UNKNOWN

DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'general':
    {
	gReadMode = READING_GENERAL
    }
    case 'touch-panel':
    {
	gReadMode = READING_TOUCH_PANEL
    }
    case 'channel-support':
    {
	gReadMode = READING_SUPPORTED_CHANNELS
	// Grow the 'suppChannels' array and add this pair
	set_length_array(suppChannels,length_array(suppChannels)+1)
	set_length_array(suppChannels[length_array(suppChannels)].mChannelMap, CHAN_MAX_CHANNELS)
	set_length_array(suppChannels[length_array(suppChannels)].mChannelMask, CHAN_MAX_CHANNELS)
    }
    case 'input':
    {
	gReadMode = READING_INPUT
	gThisItem = 0
    }
    case 'output':
    {
	gReadMode = READING_OUTPUT
	gOutputType   = AVCFG_OUTPUT_TYPE_UNKNOWN
	gVolType  = AVCFG_OUTPUT_VOL_UNKNOWN
	gThisItem = 0
    }
    case 'audio-output':
    {
	gReadMode = READING_OUTPUT
	gOutputType   = AVCFG_OUTPUT_TYPE_AUDIO
	gVolType  = AVCFG_OUTPUT_VOL_DISCRETE
	gThisItem = 0
    }
    case 'video-output':
    {
	gReadMode = READING_OUTPUT
	gOutputType   = AVCFG_OUTPUT_TYPE_UNKNOWN
	gVolType  = AVCFG_OUTPUT_VOL_UNKNOWN
	gThisItem = 0
    }
    default:
    {
	debug (moduleName, 0, "'unknown config heading: ',heading")
    }
    }
}

DEFINE_FUNCTION handleProperty (char moduleName[], char propName[], char propValue[])
{    
    debug (moduleName, 8, "'read config property (',propName,'): <',propValue,'>'")
    switch (gReadMode)
    {
    case READING_GENERAL:
    {
	switch (propName)
	{
	case 'audio-switcher':
	    parseDev (gGeneral.mAudioSwitcher, propValue)
	case 'video-switcher':
	    parseDev (gGeneral.mVideoSwitcher, propValue)
	case 'audio-output-list-order':
	    parseIntegerList (gGeneral.mTpDefaults.mAudioOutputListOrder, propValue)
	case 'video-output-list-order':
	    parseIntegerList (gGeneral.mTpDefaults.mVideoOutputListOrder, propValue)
	} // switch
    } // case READING_GENERAL

    case READING_TOUCH_PANEL:
    {
	switch (propName)
	{
	case 'panel-id':
	{
	    integer id
	    id = atoi(propValue) - 10000
	    if ((0 < id) && (id <= TP_MAX_PANELS))
	    {
		gThisItem = id
		gTpInfo[gThisItem].mEnabled = 1
		gTpInfo[gThisItem].mPanelId = atoi(propValue)
	    }
	}
	case 'audio-output-list-order':
	    parseIntegerList (gTpInfo[gThisItem].mAudioOutputListOrder, propValue)
	case 'video-output-list-order':
	    parseIntegerList (gTpInfo[gThisItem].mVideoOutputListOrder, propValue)
	} // switch
    } // case READING_GENERAL

    case READING_SUPPORTED_CHANNELS:
    {
	integer thisDevice
	thisDevice = length_array(suppChannels)
	switch (propName)
	{
	case 'name':
	    suppChannels[thisDevice].mDeviceName = propValue
	case 'channels':
	{
	    integer i
	    integer chan
	    integer locAmp
	    integer locDot
	    // Swap all - to . and , to &
	    for (i = 1; i <= length_string(propValue); i++)
	    {
		if (propValue[i] = '-')
		    propValue[i] = '.'
		else if (propValue[i] = ',')
		    propValue[i] = '&'
	    }
	    suppChannels[thisDevice].mChannels = propValue
	    // Fill in the supported buttons 0/1 array
	    for (chan = atoi(propValue);
		 chan > 0;
		 chan = atoi(propValue))
	    {
		locAmp = find_string(propValue,'&',1)
		locDot = find_string(propValue,'.',1)
		select
		{
		active ((locAmp > 0) && (((locDot > 0) && (locAmp < locDot)) || (locDot = 0))):
		{
		    // Ampersand occurred before Dot
		    remove_string(propValue,'&',1)
		    suppChannels[thisDevice].mChannelMask[chan] = 1
		}
		active (locDot > 0):
		{
		    // Dot occurred before Ampersand
		    integer endChan
		    remove_string(propValue,'.',1)
		    endChan = atoi(propValue)
		    for (i = chan; i <= endChan; i++)
		    {
			suppChannels[thisDevice].mChannelMask[i] = 1
		    }
		    if (find_string(propValue,'&',1))
		    {
			remove_string(propValue,'&',1)
		    }
		    else
		    {
			set_length_array(propValue,0)
		    }
		}
		active (1):
		{
		    // must be at last number
		    suppChannels[thisDevice].mChannelMask[chan] = 1
		    set_length_array(propValue,0)
		} // active
		} // select
	    }
	}
	case 'channel-maps':
	{
	    integer lhs
	    char    rhs
	    lhs = atoi(propValue)
	    while (remove_string(propValue,'>',1) != '')
	    {
		rhs = atoi(propValue)
		if ((lhs > 0) && (rhs > 0))
		{
		    suppChannels[thisDevice].mChannelMap[lhs] = rhs
		    debug (moduleName, 9, "'added channel map: ',itoa(lhs),'->',itoa(rhs)")
		}
		remove_string(propValue,',',1)
		lhs = atoi(propValue)
	    }
	}
	} // inner switch
    }  // case READING_SUPPORTED_CHANNEL

    case READING_INPUT:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    gAllInputs[gThisItem].mId = gThisItem
	    gAllInputs[gThisItem].mSupportedChannels	= AVCFG_DEFAULT_SUPPORTED_CHANNELS
	    gAllInputs[gThisItem].mChannelMask		= AVCFG_DEFAULT_CHANNEL_MASK
	    gAllInputs[gThisItem].mScene		= AVCFG_SCENE_UNKNOWN
	    if (gMaxInput < gThisItem)
		gMaxInput = gThisItem
	}
	case 'name':
	{
	    gAllInputs[gThisItem].mName = propValue
	    if (gAllInputs[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gAllInputs[gThisItem].mShortName = propValue
	    }
	}
	case 'short-name':
	    gAllInputs[gThisItem].mShortName = propValue
	case 'dev':
	    parseDev (gAllInputs[gThisItem].mDev, propValue)
	case 'channels':
	{
	    integer i, found
	    for (i = 1; i <= length_array(suppChannels); i++)
	    {
		if (propValue = suppChannels[i].mDeviceName)
		{
		    gAllInputs[gThisItem].mSupportedChannels	= suppChannels[i].mChannels
		    gAllInputs[gThisItem].mChannelMap		= suppChannels[i].mChannelMap
		    gAllInputs[gThisItem].mChannelMask		= suppChannels[i].mChannelMask
		}
	    }
	}
	case 'location':
	    gAllInputs[gThisItem].mLocationType = avcfgGetInputType (propValue)
	case 'video-switch-id':
	    gAllInputs[gThisItem].mVideoSwitchId = atoi(propValue)
	case 'audio-switch-id':
	    gAllInputs[gThisItem].mAudioSwitchId = atoi(propValue)
	case 'audio-gain':
	    gAllInputs[gThisItem].mAudioGain = atoi(propValue)
	case 'local-input-channel':
	    gAllInputs[gThisItem].mLocalInputChannel = atoi(propValue)
	case 'slave-auto-on':
	    gAllInputs[gThisItem].mSlaveAutoOn = parseBoolean (propValue)
	case 'scene':
	    gAllInputs[gThisItem].mScene = avcfgGetScene (propValue)
	default:
	    debug (moduleName, 0, "'Unhandled input property: ',propName")
	} // inner switch
    } // case READING_INPUT

    case READING_OUTPUT:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    gAllOutputs[gThisItem].mId                = gThisItem
	    gAllOutputs[gThisItem].mOutputType        = gOutputType
	    gAllOutputs[gThisItem].mVolType           = gVolType
	    gAllOutputs[gThisItem].mVolumeMin         = AVCFG_DEFAULT_VOL_MIN
	    gAllOutputs[gThisItem].mVolumeMax         = AVCFG_DEFAULT_VOL_MAX
	    gAllOutputs[gThisItem].mVolumeDefault     = AVCFG_DEFAULT_VOL_DEFAULT
	    gAllOutputs[gThisItem].mVolumeIncrement   = AVCFG_DEFAULT_VOL_INCREMENT
	    gAllOutputs[gThisItem].mSupportedChannels = AVCFG_DEFAULT_SUPPORTED_CHANNELS
	    gAllOutputs[gThisItem].mChannelMask       = AVCFG_DEFAULT_CHANNEL_MASK
	    gAllOutputs[gThisItem].mIrType	       = AVCFG_IR_TYPE_NORMAL
	    if (gMaxOutput < gThisItem)
		gMaxOutput = gThisItem
	}
	case 'name':
	{
	    gAllOutputs[gThisItem].mName = propValue
	    if (gAllOutputs[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gAllOutputs[gThisItem].mShortName = propValue
	    }
	}
	case 'short-name':
	    gAllOutputs[gThisItem].mShortName = propValue
	case 'audio-switch-id':
	    gAllOutputs[gThisItem].mAudioSwitchId = atoi(propValue)
	case 'video-switch-id':
	    gAllOutputs[gThisItem].mVideoSwitchId = atoi(propValue)
	case 'av-type':
	    gAllOutputs[gThisItem].mOutputType = avcfgGetOutputType (propValue)
	case 'av-vol-type':
	    gAllOutputs[gThisItem].mVolType = avcfgGetVolumeType (propValue)
	case 'dev':
	    parseDev (gAllOutputs[gThisItem].mDev, propValue)
	case 'channels':
	{
	    integer i
	    for (i = 1; i <= length_array(suppChannels); i++)
	    {
		if (propValue = suppChannels[i].mDeviceName)
		{
		    gAllOutputs[gThisItem].mSupportedChannels	= suppChannels[i].mChannels
		    gAllOutputs[gThisItem].mChannelMap		= suppChannels[i].mChannelMap
		    gAllOutputs[gThisItem].mChannelMask		= suppChannels[i].mChannelMask
		    break // out of the for-loop
		}
	    }
	}
	case 'switched-audio-input-channel':
	    gAllOutputs[gThisItem].mSwitchedInputChannel = atoi(propValue)
	case 'switched-video-input-channel':
	    gAllOutputs[gThisItem].mSwitchedInputChannel = atoi(propValue)
	case 'switched-input-channel':
	    gAllOutputs[gThisItem].mSwitchedInputChannel = atoi(propValue)
	case 'local-inputs':
	    parseIntegerList (gAllOutputs[gThisItem].mLocalInputIds, propValue)
	case 'receiver-tv-ids':
	    parseIntegerList (gAllOutputs[gThisItem].mAvrTvId, propValue)
	case 'receiver-tv-id':
	    parseIntegerList (gAllOutputs[gThisItem].mAvrTvId, propValue)
	case 'volume-min':
	    gAllOutputs[gThisItem].mVolumeMin = atoi(propValue)
	case 'volume-max':
	    gAllOutputs[gThisItem].mVolumeMax = atoi(propValue)
	case 'volume-default':
	    gAllOutputs[gThisItem].mVolumeDefault = atoi(propValue)
	case 'volume-increment':
	    gAllOutputs[gThisItem].mVolumeIncrement = atoi(propValue)
	case 'ir-type':
	    gAllOutputs[gThisItem].mIrType = avcfgGetIrType (propValue)
	default:
	    debug (moduleName, 0, "'Unhandled output property: ',propName")
	} // inner switch
    } // case READING_OUTPUT

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    } // switch
}

DEFINE_FUNCTION calcInputsForOutputs()
{
    integer inputId
    integer outputId
    integer count, i
    for (outputId = 1; outputId <= length_array(gAllOutputs); outputId++)
    {
	count = 0
	set_length_array (gAllOutputs[outputId].mAllInputIds, AVCFG_MAX_INPUTS)
	for (inputId = 1; inputId <= length_array(gAllInputs); inputId++)
	{
	    select
	    {
	    active (gAllOutputs[outputId].mOutputType = AVCFG_OUTPUT_TYPE_AUDIO):
	    {
		if (gAllInputs[inputId].mAudioSwitchId > 0)
		{
		    count++
		    gAllOutputs[outputId].mAllInputIds[count] = inputId
		}
	    } // active
	    active (gAllOutputs[outputId].mOutputType != AVCFG_OUTPUT_TYPE_TV_SLAVE):
	    {
		// We've already processed audio output case; all the remain are
		// non-slave-TV video outputs
		if (gAllInputs[inputId].mVideoSwitchId > 0)
		{
		    count++
		    gAllOutputs[outputId].mAllInputIds[count] = inputId
		}
	    } // active
	    active (1): 
	    {
	    }
	    } // select
	} // for
	// Copy and local input IDs
	for (i = 1; i <= length_array(gAllOutputs[outputId].mLocalInputIds); i++)
	{
	    count++
	    gAllOutputs[outputId].mAllInputIds[count] = gAllOutputs[outputId].mLocalInputIds[i]
	}
	set_length_array (gAllOutputs[outputId].mAllInputIds, count)
    }
}

DEFINE_FUNCTION integer avcfgGetInputType (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'switch':	return AVCFG_INPUT_TYPE_SWITCH
    case 'local':	return AVCFG_INPUT_TYPE_LOCAL
    default:		return AVCFG_INPUT_TYPE_UNKNOWN
    }
}

DEFINE_FUNCTION integer avcfgGetOutputType (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'audio':	return AVCFG_OUTPUT_TYPE_AUDIO
    case 'tv-slave':	return AVCFG_OUTPUT_TYPE_TV_SLAVE
    case 'tv-master':	return AVCFG_OUTPUT_TYPE_TV_MASTER
    case 'receiver':	return AVCFG_OUTPUT_TYPE_RECEIVER
    default:		return AVCFG_OUTPUT_TYPE_UNKNOWN
    }
}

DEFINE_FUNCTION integer avcfgGetVolumeType (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'relative':	return AVCFG_OUTPUT_VOL_RELATIVE
    case 'discrete':	return AVCFG_OUTPUT_VOL_DISCRETE
    default:		return AVCFG_OUTPUT_VOL_UNKNOWN
    }
}

DEFINE_FUNCTION integer avcfgGetIrType (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'send_command':	return AVCFG_IR_TYPE_SEND_COMMAND
    case 'pulse':		return AVCFG_IR_TYPE_NORMAL
    case 'normal':		return AVCFG_IR_TYPE_NORMAL
    default:
    {
	gAllOutputs[gThisItem].mIrType = AVCFG_IR_TYPE_NORMAL
    }
    } // switch
}

DEFINE_FUNCTION integer avcfgGetScene (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'music':	return AVCFG_SCENE_MUSIC
    case 'movies':	return AVCFG_SCENE_MOVIES
    case 'tv':		return AVCFG_SCENE_TV
    case 'sports':	return AVCFG_SCENE_SPORTS
    default:		return AVCFG_SCENE_UNKNOWN
    }
}

DEFINE_FUNCTION integer avcfgGetAudioSwitchAction (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'off':		return AVCFG_AUDIO_SWITCH_ACTION_OFF
    default:		return AVCFG_AUDIO_SWITCH_ACTION_NORMAL
    }
}


#end_if // __AV_OUTPUT_CONFIG__
