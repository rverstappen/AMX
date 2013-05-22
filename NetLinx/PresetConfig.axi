PROGRAM_NAME='PresetConfig'

// Preset config definitions.

#if_not_defined __PRESET_CONFIG__
#define __PRESET_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'

DEFINE_CONSTANT

MAX_PRESETS		= 100
MAX_AV_ACTIONS		= 9
MAX_AV_GROUPS		= 15
MAX_AV_GRID_WIDTH	= 10
MAX_TP_CHANNELS		= 1000

AV_ACTION_UNKNOWN	= 0
AV_ACTION_OFF		= 1
AV_ACTION_SWITCH	= 2

PRESET_TYPE_UNKNOWN		= 0
PRESET_TYPE_AV_COMMAND		= 1
PRESET_TYPE_LUTRON_COMMAND	= 2
PRESET_TYPE_GENERAL_COMMAND	= 9
PRESET_TYPE_AV_GRID		= 11

PRESET_STATUS_UNKNOWN	= 0
PRESET_STATUS_OFF	= 1
PRESET_STATUS_ON	= 2
PRESET_STATUS_PARTIAL	= 3

PRESET_BUTTON_STATE_UNKNOWN	= 1
PRESET_BUTTON_STATE_OFF		= 2
PRESET_BUTTON_STATE_ON		= 3
PRESET_BUTTON_STATE_PARTIAL	= 4


DEFINE_TYPE

structure PresetGeneral
{
    integer	mEnabled		// Whether presets are even present in this system
    dev		mDevControl		// Device for AMX internal control
    dev		mDevControlAv		// Device for AMX internal control for A/V
    dev		mDevControlLutron	// Device for AMX internal control for Lutron
    integer	mTpPort			// Port for Touch Panel events
    integer	mTpChannelBlankLow	// Low channel for auto-blanking
    integer	mTpChannelBlankHigh	// High channel for auto-blanking
}

structure AvOutputGroup
{
    integer	mId
    char	mName[32]
    char	mShortName[32]
    integer	mOutputIds[64]
}

structure AvAction
{
    integer	mId
    char	mName[32]
    char	mShortName[32]
    integer	mInputId
    integer	mAction    
}

structure PresetItem
{
    char	mName[32]
    char	mShortName[32]
    int		mType
    dev		mCommandDev
    char	mCommandStr[256]
    integer	mChannel
    // The following fields apply only to grid presets
    integer	mAvActionIds[MAX_AV_GRID_WIDTH]
    integer	mAvGroupIds[MAX_AV_GROUPS]
    integer	mTpGridChannelsBegin
    integer	mTpGridChannelsRowIncr
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_PRESET			= 2
READING_AV_ACTION		= 3
READING_AV_OUTPUT_GROUP		= 4

DEFINE_VARIABLE

volatile PresetGeneral	gGeneral
volatile AvAction	gAvActions[MAX_AV_ACTIONS]
volatile AvOutputGroup	gAvGroups[MAX_AV_GROUPS]
volatile PresetItem	gPresets[MAX_PRESETS]
volatile integer	gPresetByChannel[MAX_TP_CHANNELS]  // helps to match TP events with presets
volatile integer	gThisItem = 0 // presets
volatile integer	gThisAvAction = 0
volatile integer	gThisAvGroup = 0
volatile integer	gReadMode = READING_NONE

DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'general':
    {
	gReadMode = READING_GENERAL
	break
    }
    case 'av-action':
    {
	gReadMode = READING_AV_ACTION
	break
    }
    case 'av-group':
    {
	gReadMode = READING_AV_OUTPUT_GROUP
	break
    }
    case 'preset':
    {
	gReadMode = READING_PRESET
	gThisItem++
	set_length_array(gPresets, gThisItem)
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
	case 'enabled':
	{
	    gGeneral.mEnabled = getBooleanProp(propValue)
	    break
	}
	case 'dev-control-av':
	{
	    parseDev (gGeneral.mDevControlAv, propValue)
	    break
	}
	case 'dev-control-lutron':
	{
	    parseDev (gGeneral.mDevControlLutron, propValue)
	    break
	}
	case 'dev-control':
	{
	    parseDev (gGeneral.mDevControl, propValue)
	    break
	}
	case 'tp-port':
	{
	    gGeneral.mTpPort = atoi(propValue)
	    break
	}
	case 'tp-channel-blank-range-low':
	{
	    gGeneral.mTpChannelBlankLow = atoi(propValue)
	    break
	}
	case 'tp-channel-blank-range-high':
	{
	    gGeneral.mTpChannelBlankHigh = atoi(propValue)
	    break
	}
	default:
	{
	    debug (moduleName, 3, "'Unknown config property: ',propName,' (=',propValue,')'")
	}
	} // switch
    }

    case READING_AV_ACTION:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisAvAction = atoi(propValue)
	    if (length_array(gAvActions) < gThisAvAction)
	    {
		set_length_array(gAvActions, gThisAvAction)
	    }
	    gAvActions[gThisAvAction].mId = gThisAvAction
	}
	case 'name':
	{
	    gAvActions[gThisAvAction].mName = propValue
	    if (gAvActions[gThisAvAction].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gAvActions[gThisAvAction].mShortName = propValue
	    }
	    break
	}
	case 'av-action':
	{
	    gAvActions[gThisAvAction].mAction = avActionTypeFromStr(propValue)
	}
	case 'av-input-id':
	{
	    gAvActions[gThisAvAction].mInputId = atoi(propValue)
	}
	} // switch
    }

    case READING_AV_OUTPUT_GROUP:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisAvGroup = atoi(propValue)
	    if (length_array(gAvGroups) < gThisAvGroup)
	    {
		set_length_array(gAvGroups, gThisAvGroup)
	    }
	    gAvGroups[gThisAvGroup].mId = gThisAvGroup
	}
	case 'name':
	{
	    gAvGroups[gThisAvGroup].mName = propValue
	    if (gAvGroups[gThisAvGroup].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gAvGroups[gThisAvGroup].mShortName = propValue
	    }
	    break
	}
	case 'av-output-ids':
	{
	    integer id
	    integer count
	    for (id = atoi(propValue); id != 0; id = atoi(propValue))
	    {
		count++
		set_length_array (gAvGroups[gThisAvGroup].mOutputIds, count)
		gAvGroups[gThisAvGroup].mOutputIds[count] = id
		if (remove_string (propValue, ',', 1) == '')
		{
		    propValue = ''
		}
	    }
	    break
	}
	} // switch
    }

    case READING_PRESET:
    {
	switch (propName)
	{
	case 'name':
	{
	    gPresets[gThisItem].mName = propValue
	    if (gPresets[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gPresets[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'type':
	{
	    gPresets[gThisItem].mType = presetTypeFromStr (propValue)
	}
	case 'short-name':
	{
	    gPresets[gThisItem].mShortName = propValue
	    break
	}
	case 'command':
	{
	    gPresets[gThisItem].mCommandStr = propValue
	    break
	}
	case 'command-dev':
	{
	    parseDev (gPresets[gThisItem].mCommandDev, propValue)
	    break
	}
	case 'tp-button-channel':
	{
	    integer chan
	    chan = atoi(propValue)
	    gPresets[gThisItem].mChannel = chan
	}
	case 'av-groups':
	{
	    integer id
	    integer count
	    for (id = atoi(propValue); id != 0; id = atoi(propValue))
	    {
		count++
		set_length_array (gPresets[gThisItem].mAvGroupIds, count)
		gPresets[gThisItem].mAvGroupIds[count] = id
		if (remove_string (propValue, ',', 1) == '')
		{
		    propValue = ''
		}
	    }
	    break
	}
	case 'av-actions':
	{
	    integer ids[MAX_AV_ACTIONS]
	    integer i
	    parseIntegerList (ids, propValue)
	    set_length_array (gPresets[gThisItem].mAvActionIds, length_array(ids))
	    for (i = 1; i <= length_array(ids); i++)
	    {
		gPresets[gThisItem].mAvActionIds[i] = ids[i]
	    }
	    break
	}
	case 'tp-grid-channels-start':
	{
	    gPresets[gThisItem].mTpGridChannelsBegin = atoi(propValue)
	}
	case 'tp-grid-channels-row-increment':
	{
	    integer gridWidth
	    gridWidth = atoi(propValue)
	    if (gridWidth >= MAX_AV_GRID_WIDTH)
	       gridWidth = MAX_AV_GRID_WIDTH
	    gPresets[gThisItem].mTpGridChannelsRowIncr = gridWidth
	}
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

DEFINE_FUNCTION integer avActionTypeFromStr (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'off':		return AV_ACTION_OFF
    case 'switch':	return AV_ACTION_SWITCH
    default:		return AV_ACTION_UNKNOWN
    }
}

DEFINE_FUNCTION integer presetTypeFromStr (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'av-command':		return PRESET_TYPE_AV_COMMAND
    case 'lutron-command':	return PRESET_TYPE_LUTRON_COMMAND
    case 'general-command':	return PRESET_TYPE_GENERAL_COMMAND
    case 'av-grid':		return PRESET_TYPE_AV_GRID
    default:			return PRESET_TYPE_UNKNOWN
    }
}

DEFINE_FUNCTION integer presetButtonStateFromStatus (integer status)
{
    switch (status)
    {
    case PRESET_STATUS_OFF:	return PRESET_BUTTON_STATE_OFF
    case PRESET_STATUS_ON:	return PRESET_BUTTON_STATE_ON
    case PRESET_STATUS_PARTIAL:	return PRESET_BUTTON_STATE_PARTIAL
    default:			return PRESET_BUTTON_STATE_UNKNOWN
    }
}

DEFINE_START
gGeneral.mTpPort = 1		// Anything but zero


#end_if // __PRESET_CONFIG__
