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

(*
AVCFG_VOL_DIR_UP     = 1
AVCFG_VOL_DIR_DOWN   = 2
AVCFG_GAIN_DIR_UP    = 1
AVCFG_GAIN_DIR_DOWN  = 2

// Input control channels
//AVCFG_INPUT_TITLE	= 91
//AVCFG_INPUT_SHORT_TITLE	= 92

AVCFG_OUTPUT_CTL_SELECT_TITLE	= 5
AVCFG_OUTPUT_CTL_SELECT_NONE	= 6
AVCFG_OUTPUT_CTL_SELECT_PREV	= 7
AVCFG_OUTPUT_CTL_SELECT_NEXT	= 8

// Output control channels for multiple output TP displays.
//  See below for "support" arrays and functions.
AVCFG_OUTPUT_CTL_VOL_UP_MASTER	= 1
AVCFG_OUTPUT_CTL_VOL_DOWN_MASTER	= 2
AVCFG_OUTPUT_CTL_VOL_MUTE_MASTER	= 3
AVCFG_OUTPUT_CTL_VOL_LEVEL_MASTER= 4
AVCFG_OUTPUT_CTL_POWER_MASTER	= 9
AVCFG_OUTPUT_CTL_VOL_UP_1	= 11
AVCFG_OUTPUT_CTL_VOL_DOWN_1	= 12
AVCFG_OUTPUT_CTL_VOL_MUTE_1	= 13
AVCFG_OUTPUT_CTL_VOL_LEVEL_1	= 14
AVCFG_OUTPUT_CTL_TITLE_1		= 18
AVCFG_OUTPUT_CTL_POWER_1		= 19
AVCFG_OUTPUT_CTL_VOL_UP_2	= 21
AVCFG_OUTPUT_CTL_VOL_DOWN_2	= 22
AVCFG_OUTPUT_CTL_VOL_MUTE_2	= 23
AVCFG_OUTPUT_CTL_VOL_LEVEL_2	= 24
AVCFG_OUTPUT_CTL_TITLE_2		= 28
AVCFG_OUTPUT_CTL_POWER_2		= 29
AVCFG_OUTPUT_CTL_VOL_UP_3	= 31
AVCFG_OUTPUT_CTL_VOL_DOWN_3	= 32
AVCFG_OUTPUT_CTL_VOL_MUTE_3	= 33
AVCFG_OUTPUT_CTL_VOL_LEVEL_3	= 34
AVCFG_OUTPUT_CTL_TITLE_3		= 38
AVCFG_OUTPUT_CTL_POWER_3		= 39
AVCFG_OUTPUT_CTL_VOL_UP_4	= 41
AVCFG_OUTPUT_CTL_VOL_DOWN_4	= 42
AVCFG_OUTPUT_CTL_VOL_MUTE_4	= 43
AVCFG_OUTPUT_CTL_VOL_LEVEL_4	= 44
AVCFG_OUTPUT_CTL_TITLE_4		= 48
AVCFG_OUTPUT_CTL_POWER_4		= 49
AVCFG_OUTPUT_CTL_VOL_UP_5	= 51
AVCFG_OUTPUT_CTL_VOL_DOWN_5	= 52
AVCFG_OUTPUT_CTL_VOL_MUTE_5	= 53
AVCFG_OUTPUT_CTL_VOL_LEVEL_5	= 54
AVCFG_OUTPUT_CTL_TITLE_5		= 58
AVCFG_OUTPUT_CTL_POWER_5		= 59
AVCFG_OUTPUT_CTL_VOL_UP_6	= 61
AVCFG_OUTPUT_CTL_VOL_DOWN_6	= 62
AVCFG_OUTPUT_CTL_VOL_MUTE_6	= 63
AVCFG_OUTPUT_CTL_VOL_LEVEL_6	= 64
AVCFG_OUTPUT_CTL_TITLE_6		= 68
AVCFG_OUTPUT_CTL_POWER_6		= 69
AVCFG_OUTPUT_CTL_VOL_UP_7	= 71
AVCFG_OUTPUT_CTL_VOL_DOWN_7	= 72
AVCFG_OUTPUT_CTL_VOL_MUTE_7	= 73
AVCFG_OUTPUT_CTL_VOL_LEVEL_7	= 74
AVCFG_OUTPUT_CTL_TITLE_7		= 78
AVCFG_OUTPUT_CTL_POWER_7		= 79
AVCFG_OUTPUT_CTL_VOL_UP_8	= 81
AVCFG_OUTPUT_CTL_VOL_DOWN_8	= 82
AVCFG_OUTPUT_CTL_VOL_MUTE_8	= 83
AVCFG_OUTPUT_CTL_VOL_LEVEL_8	= 84
AVCFG_OUTPUT_CTL_TITLE_8		= 88
AVCFG_OUTPUT_CTL_POWER_8		= 89
AVCFG_OUTPUT_CTL_VOL_UP_9	= 91
AVCFG_OUTPUT_CTL_VOL_DOWN_9	= 92
AVCFG_OUTPUT_CTL_VOL_MUTE_9	= 93
AVCFG_OUTPUT_CTL_VOL_LEVEL_9	= 94
AVCFG_OUTPUT_CTL_TITLE_9		= 98
AVCFG_OUTPUT_CTL_POWER_9		= 99
AVCFG_OUTPUT_CTL_VOL_UP_10	= 101
AVCFG_OUTPUT_CTL_VOL_DOWN_10	= 102
AVCFG_OUTPUT_CTL_VOL_MUTE_10	= 103
AVCFG_OUTPUT_CTL_VOL_LEVEL_10	= 104
AVCFG_OUTPUT_CTL_TITLE_10	= 118
AVCFG_OUTPUT_CTL_POWER_10	= 109
AVCFG_OUTPUT_CTL_VOL_UP_11	= 111
AVCFG_OUTPUT_CTL_VOL_DOWN_11	= 112
AVCFG_OUTPUT_CTL_VOL_MUTE_11	= 113
AVCFG_OUTPUT_CTL_VOL_LEVEL_11	= 114
AVCFG_OUTPUT_CTL_TITLE_11	= 118
AVCFG_OUTPUT_CTL_POWER_11	= 119
AVCFG_OUTPUT_CTL_VOL_UP_12	= 121
AVCFG_OUTPUT_CTL_VOL_DOWN_12	= 122
AVCFG_OUTPUT_CTL_VOL_MUTE_12	= 123
AVCFG_OUTPUT_CTL_VOL_LEVEL_12	= 124
AVCFG_OUTPUT_CTL_TITLE_12	= 128
AVCFG_OUTPUT_CTL_POWER_12	= 129
AVCFG_OUTPUT_CTL_VOL_UP_13	= 131
AVCFG_OUTPUT_CTL_VOL_DOWN_13	= 132
AVCFG_OUTPUT_CTL_VOL_MUTE_13	= 133
AVCFG_OUTPUT_CTL_VOL_LEVEL_13	= 134
AVCFG_OUTPUT_CTL_TITLE_13	= 138
AVCFG_OUTPUT_CTL_POWER_13	= 139
AVCFG_OUTPUT_CTL_VOL_UP_14	= 141
AVCFG_OUTPUT_CTL_VOL_DOWN_14	= 142
AVCFG_OUTPUT_CTL_VOL_MUTE_14	= 143
AVCFG_OUTPUT_CTL_VOL_LEVEL_14	= 144
AVCFG_OUTPUT_CTL_TITLE_14	= 148
AVCFG_OUTPUT_CTL_POWER_14	= 149
AVCFG_OUTPUT_CTL_VOL_UP_15	= 151
AVCFG_OUTPUT_CTL_VOL_DOWN_15	= 152
AVCFG_OUTPUT_CTL_VOL_MUTE_15	= 153
AVCFG_OUTPUT_CTL_VOL_LEVEL_15	= 154
AVCFG_OUTPUT_CTL_TITLE_15	= 158
AVCFG_OUTPUT_CTL_POWER_15	= 159
AVCFG_OUTPUT_CTL_VOL_UP_16	= 161
AVCFG_OUTPUT_CTL_VOL_DOWN_16	= 162
AVCFG_OUTPUT_CTL_VOL_MUTE_16	= 163
AVCFG_OUTPUT_CTL_VOL_LEVEL_16	= 164
AVCFG_OUTPUT_CTL_TITLE_16	= 168
AVCFG_OUTPUT_CTL_POWER_16	= 169
AVCFG_OUTPUT_CTL_VOL_UP_17	= 171
AVCFG_OUTPUT_CTL_VOL_DOWN_17	= 172
AVCFG_OUTPUT_CTL_VOL_MUTE_17	= 173
AVCFG_OUTPUT_CTL_VOL_LEVEL_17	= 174
AVCFG_OUTPUT_CTL_TITLE_17	= 178
AVCFG_OUTPUT_CTL_POWER_17	= 179
AVCFG_OUTPUT_CTL_VOL_UP_18	= 181
AVCFG_OUTPUT_CTL_VOL_DOWN_18	= 182
AVCFG_OUTPUT_CTL_VOL_MUTE_18	= 183
AVCFG_OUTPUT_CTL_VOL_LEVEL_18	= 184
AVCFG_OUTPUT_CTL_TITLE_18	= 188
AVCFG_OUTPUT_CTL_POWER_18	= 189
// Keep going if there are more outputs! :-)
*)

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

constant integer AVCFG_OUTPUT_SELECT_ALL = 255

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


(*
constant integer AVCFG_OUTPUT_CTL_VOL_UP[] = {
    AVCFG_OUTPUT_CTL_VOL_UP_1,
    AVCFG_OUTPUT_CTL_VOL_UP_2,
    AVCFG_OUTPUT_CTL_VOL_UP_3,
    AVCFG_OUTPUT_CTL_VOL_UP_4,
    AVCFG_OUTPUT_CTL_VOL_UP_5,
    AVCFG_OUTPUT_CTL_VOL_UP_6,
    AVCFG_OUTPUT_CTL_VOL_UP_7,
    AVCFG_OUTPUT_CTL_VOL_UP_8,
    AVCFG_OUTPUT_CTL_VOL_UP_9,
    AVCFG_OUTPUT_CTL_VOL_UP_10,
    AVCFG_OUTPUT_CTL_VOL_UP_11,
    AVCFG_OUTPUT_CTL_VOL_UP_12,
    AVCFG_OUTPUT_CTL_VOL_UP_13,
    AVCFG_OUTPUT_CTL_VOL_UP_14,
    AVCFG_OUTPUT_CTL_VOL_UP_15,
    AVCFG_OUTPUT_CTL_VOL_UP_16,
    AVCFG_OUTPUT_CTL_VOL_UP_17,
    AVCFG_OUTPUT_CTL_VOL_UP_18}
constant integer AVCFG_OUTPUT_CTL_VOL_DOWN[] = {
    AVCFG_OUTPUT_CTL_VOL_DOWN_1,
    AVCFG_OUTPUT_CTL_VOL_DOWN_2,
    AVCFG_OUTPUT_CTL_VOL_DOWN_3,
    AVCFG_OUTPUT_CTL_VOL_DOWN_4,
    AVCFG_OUTPUT_CTL_VOL_DOWN_5,
    AVCFG_OUTPUT_CTL_VOL_DOWN_6,
    AVCFG_OUTPUT_CTL_VOL_DOWN_7,
    AVCFG_OUTPUT_CTL_VOL_DOWN_8,
    AVCFG_OUTPUT_CTL_VOL_DOWN_9,
    AVCFG_OUTPUT_CTL_VOL_DOWN_10,
    AVCFG_OUTPUT_CTL_VOL_DOWN_11,
    AVCFG_OUTPUT_CTL_VOL_DOWN_12,
    AVCFG_OUTPUT_CTL_VOL_DOWN_13,
    AVCFG_OUTPUT_CTL_VOL_DOWN_14,
    AVCFG_OUTPUT_CTL_VOL_DOWN_15,
    AVCFG_OUTPUT_CTL_VOL_DOWN_16,
    AVCFG_OUTPUT_CTL_VOL_DOWN_17,
    AVCFG_OUTPUT_CTL_VOL_DOWN_18}
constant integer AVCFG_OUTPUT_CTL_VOL_MUTE[] = {
    AVCFG_OUTPUT_CTL_VOL_MUTE_1,
    AVCFG_OUTPUT_CTL_VOL_MUTE_2,
    AVCFG_OUTPUT_CTL_VOL_MUTE_3,
    AVCFG_OUTPUT_CTL_VOL_MUTE_4,
    AVCFG_OUTPUT_CTL_VOL_MUTE_5,
    AVCFG_OUTPUT_CTL_VOL_MUTE_6,
    AVCFG_OUTPUT_CTL_VOL_MUTE_7,
    AVCFG_OUTPUT_CTL_VOL_MUTE_8,
    AVCFG_OUTPUT_CTL_VOL_MUTE_9,
    AVCFG_OUTPUT_CTL_VOL_MUTE_10,
    AVCFG_OUTPUT_CTL_VOL_MUTE_11,
    AVCFG_OUTPUT_CTL_VOL_MUTE_12,
    AVCFG_OUTPUT_CTL_VOL_MUTE_13,
    AVCFG_OUTPUT_CTL_VOL_MUTE_14,
    AVCFG_OUTPUT_CTL_VOL_MUTE_15,
    AVCFG_OUTPUT_CTL_VOL_MUTE_16,
    AVCFG_OUTPUT_CTL_VOL_MUTE_17,
    AVCFG_OUTPUT_CTL_VOL_MUTE_18}
constant integer AVCFG_OUTPUT_CTL_VOL_LEVEL[] = {
    AVCFG_OUTPUT_CTL_VOL_LEVEL_1,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_2,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_3,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_4,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_5,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_6,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_7,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_8,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_9,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_10,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_11,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_12,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_13,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_14,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_15,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_16,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_17,
    AVCFG_OUTPUT_CTL_VOL_LEVEL_18}
constant integer AVCFG_OUTPUT_CTL_POWER[] = {
    AVCFG_OUTPUT_CTL_POWER_1,
    AVCFG_OUTPUT_CTL_POWER_2,
    AVCFG_OUTPUT_CTL_POWER_3,
    AVCFG_OUTPUT_CTL_POWER_4,
    AVCFG_OUTPUT_CTL_POWER_5,
    AVCFG_OUTPUT_CTL_POWER_6,
    AVCFG_OUTPUT_CTL_POWER_7,
    AVCFG_OUTPUT_CTL_POWER_8,
    AVCFG_OUTPUT_CTL_POWER_9,
    AVCFG_OUTPUT_CTL_POWER_10,
    AVCFG_OUTPUT_CTL_POWER_11,
    AVCFG_OUTPUT_CTL_POWER_12,
    AVCFG_OUTPUT_CTL_POWER_13,
    AVCFG_OUTPUT_CTL_POWER_14,
    AVCFG_OUTPUT_CTL_POWER_15,
    AVCFG_OUTPUT_CTL_POWER_16,
    AVCFG_OUTPUT_CTL_POWER_17,
    AVCFG_OUTPUT_CTL_POWER_18}

DEFINE_FUNCTION integer audioCtlChannel2Ui (integer channel)
{
    // the output UI is the channel divided by 10 with remainder discarded (i.e., integer division)
    return channel / 10
}

DEFINE_FUNCTION integer audioCtlChannel2Action (integer channel)
{
    // the action is the remainder after the channel is divided by 10 (i.e., integer 'mod')
    return channel - (10*(channel/10))
}

DEFINE_FUNCTION integer audioCtlChannel2VolDir (integer channel)
{
    // the volume direction happens also to be the remainder after the channel is divided by 10 (i.e., integer 'mod')
    return channel - (10*(channel/10))
}

DEFINE_FUNCTION integer audioCtlUi2VolUpAddress (integer ui)
{
    // the address (channel) of a output title is 11, 21, 31, etc.
    return ((ui*10)+1)
}

DEFINE_FUNCTION integer audioCtlUi2VolDownAddress (integer ui)
{
    // the address (channel) of a output title is 12, 22, 32, etc.
    return ((ui*10)+2)
}

DEFINE_FUNCTION integer audioCtlUi2VolMuteAddress (integer ui)
{
    // the address (channel) of a output title is 13, 23, 33, etc.
    return ((ui*10)+3)
}

DEFINE_FUNCTION integer audioCtlUi2VolumeLevel (integer ui)
{
    // the address (channel) of a output title is 14, 24, 34, etc.
    return ((ui*10)+4)
}

DEFINE_FUNCTION integer audioCtlUi2TitleAddress (integer ui)
{
    // the address (channel) of a output title is 18, 28, 38, etc.
    return ((ui*10)+8)
}

DEFINE_FUNCTION integer audioCtlUi2PowerAddress (integer ui)
{
    // the address (channel) of a output title is 19, 29, 39, etc.
    return ((ui*10)+9)
}
*)

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
    integer	mAvrTvId		// ID of the slave TV connected to this AVR (if this is an AVR)
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
	break
    }
    case 'input':
    {
	gReadMode = READING_INPUT
	gThisItem = 0
	break
    }
    case 'output':
    {
	gReadMode = READING_OUTPUT
	gOutputType   = AVCFG_OUTPUT_TYPE_UNKNOWN
	gVolType  = AVCFG_OUTPUT_VOL_UNKNOWN
	gThisItem = 0
	break
    }
    case 'audio-output':
    {
	gReadMode = READING_OUTPUT
	gOutputType   = AVCFG_OUTPUT_TYPE_AUDIO
	gVolType  = AVCFG_OUTPUT_VOL_DISCRETE
	gThisItem = 0
	break
    }
    case 'video-output':
    {
	gReadMode = READING_OUTPUT
	gOutputType   = AVCFG_OUTPUT_TYPE_UNKNOWN
	gVolType  = AVCFG_OUTPUT_VOL_UNKNOWN
	gThisItem = 0
	break
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
	{
	    parseDev (gGeneral.mAudioSwitcher, propValue)
	    break
	}
	case 'video-switcher':
	{
	    parseDev (gGeneral.mVideoSwitcher, propValue)
	    break
	}
	case 'audio-output-list-order':
	{
	    integer id, i
	    for (id = atoi(propValue);
		 (id > 0) && (propValue != "");
		 id = atoi(propValue))
	    {
		i++
		set_length_array (gGeneral.mTpDefaults.mAudioOutputListOrder, i)
		gGeneral.mTpDefaults.mAudioOutputListOrder[i] = id
		if (remove_string(propValue,',',1) = '')
		    break
	    }
	} // case
	case 'video-output-list-order':
	{
	    integer id, i
	    for (id = atoi(propValue);
		 (id > 0) && (propValue != "");
		 id = atoi(propValue))
	    {
		i++
		set_length_array (gGeneral.mTpDefaults.mVideoOutputListOrder, i)
		gGeneral.mTpDefaults.mVideoOutputListOrder[i] = id
		if (remove_string(propValue,',',1) = '')
		    break
	    }
	} // case
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
	{
	    integer id, i
	    for (id = atoi(propValue);
		 (id > 0) && (propValue != "");
		 id = atoi(propValue))
	    {
		i++
		set_length_array (gTpInfo[gThisItem].mAudioOutputListOrder, i)
		gTpInfo[gThisItem].mAudioOutputListOrder[i] = id
		if (remove_string(propValue,',',1) = '')
		    break
	    }
	} // case
	case 'video-output-list-order':
	{
	    integer id, i
	    for (id = atoi(propValue);
		 (id > 0) && (propValue != "");
		 id = atoi(propValue))
	    {
		i++
		set_length_array (gTpInfo[gThisItem].mVideoOutputListOrder, i)
		gTpInfo[gThisItem].mVideoOutputListOrder[i] = id
		if (remove_string(propValue,',',1) = '')
		    break
	    }
	} // case
	} // switch
    } // case READING_GENERAL

    case READING_SUPPORTED_CHANNELS:
    {
	integer thisDevice
	thisDevice = length_array(suppChannels)
	switch (propName)
	{
	case 'name':
	{
	    suppChannels[thisDevice].mDeviceName = propValue
	    break
	}
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
	    break
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
	    break
	}
	}
	break
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
	    break
	}
	case 'name':
	{
	    gAllInputs[gThisItem].mName = propValue
	    if (gAllInputs[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gAllInputs[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gAllInputs[gThisItem].mShortName = propValue
	    break
	}
	case 'dev':
	{
	    parseDev (gAllInputs[gThisItem].mDev, propValue)
	    break
	}
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
		    break
		}
	    }
	    break
	}
	case 'location':
	{
	    switch (propValue)
	    {
	    case 'switch':
	    {
		gAllInputs[gThisItem].mLocationType = AVCFG_INPUT_TYPE_SWITCH
		break
	    }
	    case 'local':
	    {
		gAllInputs[gThisItem].mLocationType = AVCFG_INPUT_TYPE_LOCAL
		break
	    }
	    default:
	    {
		gAllInputs[gThisItem].mLocationType = AVCFG_INPUT_TYPE_UNKNOWN
		break
	    }
	    } // switch (propValue)
	    break
	}
	case 'video-switch-id':
	{
	    gAllInputs[gThisItem].mVideoSwitchId = atoi(propValue)
	    break
	}
	case 'audio-switch-id':
	{
	    gAllInputs[gThisItem].mAudioSwitchId = atoi(propValue)
	    break
	}
	case 'audio-gain':
	{
	    gAllInputs[gThisItem].mAudioGain = atoi(propValue)
	    break
	}
	case 'local-input-channel':
	{
	    gAllInputs[gThisItem].mLocalInputChannel = atoi(propValue)
	    break
	}
	case 'slave-auto-on':
	{
	    lower_string (propValue)
	    if (propValue = 'true')
	    {
	    	gAllInputs[gThisItem].mSlaveAutoOn = 1
	    }
	    else
	    {
	    	gAllInputs[gThisItem].mSlaveAutoOn = (atoi(propValue) != 0)
	    }
	    break
	}
	case 'scene':
	{
	    gAllInputs[gThisItem].mScene = avcfgGetScene (propValue)
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled input property: ',propName")
	    break
	}
	break
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
	    break
	}
	case 'name':
	{
	    gAllOutputs[gThisItem].mName = propValue
	    if (gAllOutputs[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gAllOutputs[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gAllOutputs[gThisItem].mShortName = propValue
	    break
	}
	case 'audio-switch-id':
	{
	    gAllOutputs[gThisItem].mAudioSwitchId = atoi(propValue)
	    break
	}
	case 'video-switch-id':
	{
	    gAllOutputs[gThisItem].mVideoSwitchId = atoi(propValue)
	    break
	}
	case 'av-type':
	{
	    propValue = lower_string(propValue)
	    switch (propValue)
	    {
	    case 'audio':
	    	gAllOutputs[gThisItem].mOutputType = AVCFG_OUTPUT_TYPE_AUDIO
	    case 'tv-slave':
	    	gAllOutputs[gThisItem].mOutputType = AVCFG_OUTPUT_TYPE_TV_SLAVE
	    case 'tv-master':
	    	gAllOutputs[gThisItem].mOutputType = AVCFG_OUTPUT_TYPE_TV_MASTER
	    case 'receiver':
	    	gAllOutputs[gThisItem].mOutputType = AVCFG_OUTPUT_TYPE_RECEIVER
	    default:
	    	gAllOutputs[gThisItem].mOutputType = AVCFG_OUTPUT_TYPE_UNKNOWN
	    }
	    break
	}
	case 'av-vol-type':
	{
	    propValue = lower_string(propValue)
	    switch (propValue)
	    {
	    case 'relative':
	    	gAllOutputs[gThisItem].mVolType = AVCFG_OUTPUT_VOL_RELATIVE
		break
	    case 'discrete':
	    	gAllOutputs[gThisItem].mVolType = AVCFG_OUTPUT_VOL_DISCRETE
		break
	    default:
	    	gAllOutputs[gThisItem].mVolType = AVCFG_OUTPUT_VOL_UNKNOWN
		break
	    }
	    break
	}
	case 'dev':
	{
	    parseDev (gAllOutputs[gThisItem].mDev, propValue)
	    break
	}
	case 'channels':
	{
	    integer i
	    for (i = 1; i <= length_array(suppChannels); i++)
	    {
		if (propValue = suppChannels[i].mDeviceName)
		{
		    gAllOutputs[gThisItem].mSupportedChannels	= suppChannels[i].mChannels
		    gAllOutputs[gThisItem].mChannelMap		= suppChannels[i].mChannelMap
		    gAllOutputs[gThisItem].mChannelMask	= suppChannels[i].mChannelMask
		    break
		}
	    }
	    debug (moduleName,9,"'found channel list: ',suppChannels[i].mDeviceName,'; mask[9]=',itoa(gAllOutputs[gThisItem].mChannelMask[9])")
	    break
	}
	case 'switched-audio-input-channel':
	{
	    gAllOutputs[gThisItem].mSwitchedInputChannel = atoi(propValue)
	    break
	}
	case 'switched-video-input-channel':
	{
	    gAllOutputs[gThisItem].mSwitchedInputChannel = atoi(propValue)
	    break
	}
	case 'switched-input-channel':
	{
	    gAllOutputs[gThisItem].mSwitchedInputChannel = atoi(propValue)
	    break
	}
	case 'local-inputs':
	{
	    integer count
	    integer inputId
	    count = 0
	    for (inputId = atoi(propValue); inputId > 0; inputId = atoi(propValue))
	    {
		count++
		set_length_array(gAllOutputs[gThisItem].mLocalInputIds, count)
		gAllOutputs[gThisItem].mLocalInputIds[count] = inputId
		if (remove_string (propValue, ',', 1) == '')
		{
		    // No more commas, so we are finished with the list
		    propValue = ""
		}
	    }
	    break
	}
	case 'receiver-tv-id':
	{
	    gAllOutputs[gThisItem].mAvrTvId = atoi(propValue)
	    break
	}
	case 'volume-min':
	{
	    gAllOutputs[gThisItem].mVolumeMin = atoi(propValue)
	    break
	}
	case 'volume-max':
	{
	    gAllOutputs[gThisItem].mVolumeMax = atoi(propValue)
	    break
	}
	case 'volume-default':
	{
	    gAllOutputs[gThisItem].mVolumeDefault = atoi(propValue)
	    break
	}
	case 'volume-increment':
	{
	    gAllOutputs[gThisItem].mVolumeIncrement = atoi(propValue)
	    break
	}
	case 'ir-type':
	{
	    select
	    {
	    active (propValue = 'send_command'):
	    {
		gAllOutputs[gThisItem].mIrType = AVCFG_IR_TYPE_SEND_COMMAND
	    }
	    active (propValue = 'pulse'):
	    {
		gAllOutputs[gThisItem].mIrType = AVCFG_IR_TYPE_NORMAL
	    }
	    active (propValue = 'normal'):
	    {
		gAllOutputs[gThisItem].mIrType = AVCFG_IR_TYPE_NORMAL
	    }
	    active (1):
	    {
		debug (moduleName, 0, "'Incorrect property value for ',propName,': ',propValue")
		gAllOutputs[gThisItem].mIrType = AVCFG_IR_TYPE_NORMAL
	    } // active
	    } // select
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled output property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_OUTPUT

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
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
