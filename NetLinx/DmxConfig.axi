PROGRAM_NAME='DmxConfig'

// Configuration support for the DMX module

#if_not_defined __DMX_CONFIG__
#define __DMX_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils'
#include 'ConfigServerUtils'


DEFINE_CONSTANT

DMX_MAX_DMXS			= 10
DMX_MAX_DMX_PRESETS		= 30
DMX_MAX_TIME_LINE_EVENTS	= 32

DMX_TYPE_UNKNOWN		= 0
DMX_TYPE_RGB			= 1
DMX_TYPE_RGB_CYCLE_RAINBOW	= 2
DMX_TYPE_RGB_CYCLE_CUSTOM	= 3

DMX_READING_UNKNOWN		= 0
DMX_READING_GENERAL		= 1
DMX_READING_DMX_RGB		= 2
DMX_READING_DMX_RGB_PRESET	= 3
DMX_READING_PROGRAM		= 4

	        
DEFINE_TYPE

structure DmxGeneral
{
    integer	mEnabled
    integer	mTpPort			// Port for Touch Panel events
    integer	mTpChannelRgbLow	// Low channel for RGB DMX auto-blanking
    integer	mTpChannelRgbHigh	// High channel for RGB DMX auto-blanking
    integer	mTpChannelRgbPresetLow	// Low channel for RGB preset auto-blanking
    integer	mTpChannelRgbPresetHigh	// High channel for RGB preset auto-blanking
}

structure DmxRgb
{
    integer	mId
    char	mName[32]
    dev		mDev
    integer     mChannelRed
    integer	mChannelGreen
    integer	mChannelBlue
    integer	mTpChannel	// which button this is on TP displays
    integer	mLevelRed
    integer	mLevelGreen
    integer	mLevelBlue
}

structure DmxRgbPreset
{
    integer	mId
    char	mName[32]
    integer	mType
    integer	mLevelRed
    integer	mLevelGreen
    integer	mLevelBlue
    integer	mFadeDecisecs
    integer	mCycleSeconds	// For cycles, such as the rainbow
    integer	mTpChannel	// which button this is on TP displays
}

structure DmxProgram
{
    integer	mId
    char	mName[32]
    // TO DO!
}


DEFINE_VARIABLE

volatile DmxGeneral	gGeneral
volatile DmxRgb		gDmxRgbs[DMX_MAX_DMXS]
volatile DmxRgbPreset	gDmxRgbPresets[DMX_MAX_DMX_PRESETS]
//volatile DmxProgram	gDmxPrograms[DMX_MAX_PROGRAMS]
volatile integer	gDmxByChannel[1000]  // helps to match TP events with DMX selection
volatile integer	gPresetByChannel[1000]  // helps to match TP events with DMX selection
volatile integer	gThisItem = 0
volatile integer	gThisPreset = 0
volatile integer	gReadMode = DMX_READING_UNKNOWN

DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'general':
    {
	gReadMode = DMX_READING_GENERAL
	break
    }
    case 'dmx-rgb-preset':
    {
	gReadMode = DMX_READING_DMX_RGB_PRESET
	gThisPreset = 0
	break
    }
    case 'dmx-rgb':
    {
	gReadMode = DMX_READING_DMX_RGB
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

    case DMX_READING_GENERAL:
    {
	switch (propName)
	{
	case 'enabled':
	{
	    lower_string (propValue)
	    gGeneral.mEnabled = (propValue = 'true' || propValue = 't' || propValue = 1)
	    break
	}
	case 'tp-port':
	{
	    gGeneral.mTpPort = atoi(propValue)
	    break
	}
	case 'tp-channel-rgb-range-low':
	{
	    gGeneral.mTpChannelRgbLow = atoi(propValue)
	    break
	}
	case 'tp-channel-rgb-range-high':
	{
	    gGeneral.mTpChannelRgbHigh = atoi(propValue)
	    break
	}
	case 'tp-channel-rgb-preset-range-low':
	{
	    gGeneral.mTpChannelRgbPresetLow = atoi(propValue)
	    break
	}
	case 'tp-channel-rgb-preset-range-high':
	{
	    gGeneral.mTpChannelRgbPresetHigh = atoi(propValue)
	    break
	}
	default:
	{
	    debug (moduleName, 3, "'Unknown config property: ',propName,' (=',propValue,')'")
	}
	} // switch
    } // case DMX_READING_GENERAL

    case DMX_READING_DMX_RGB:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gDmxRgbs) < gThisItem)
	    {
		set_length_array(gDmxRgbs, gThisItem)
	    }
	    gDmxRgbs[gThisItem].mId = gThisItem
	    break
	}
	case 'name':
	{
	    gDmxRgbs[gThisItem].mName = propValue
	    break
	}
	case 'dev':
	{
	    parseDev (gDmxRgbs[gThisItem].mDev, propValue)
	    break
	}
	case 'red-channel':
	{
	    gDmxRgbs[gThisItem].mChannelRed = atoi(propValue)
	    break
	}
	case 'green-channel':
	{
	    gDmxRgbs[gThisItem].mChannelGreen = atoi(propValue)
	    break
	}
	case 'blue-channel':
	{
	    gDmxRgbs[gThisItem].mChannelBlue = atoi(propValue)
	    break
	}
	case 'tp-button-channel':
	{
	    gDmxRgbs[gThisItem].mTpChannel = atoi(propValue)
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case DMX_READING_DMX

    case DMX_READING_DMX_RGB_PRESET:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisPreset = atoi(propValue)
	    if (length_array(gDmxRgbPresets) < gThisPreset)
	    {
		set_length_array(gDmxRgbPresets, gThisPreset)
	    }
	    gDmxRgbPresets[gThisPreset].mId = gThisPreset
	    break
	}
	case 'name':
	{
	    gDmxRgbPresets[gThisPreset].mName = propValue
	    break
	}
	case 'red-level':
	{
	    gDmxRgbPresets[gThisPreset].mLevelRed = atoi(propValue)
	    break
	}
	case 'green-level':
	{
	    gDmxRgbPresets[gThisPreset].mLevelGreen = atoi(propValue)
	    break
	}
	case 'blue-level':
	{
	    gDmxRgbPresets[gThisPreset].mLevelBlue = atoi(propValue)
	    break
	}
	case 'fade-decisecs':
	{
	    gDmxRgbPresets[gThisPreset].mFadeDecisecs = atoi(propValue)
	    break
	}
	case 'cycle-seconds':
	{
	    gDmxRgbPresets[gThisPreset].mCycleSeconds = atoi(propValue)
	    break
	}
	case 'tp-button-channel':
	{
	    gDmxRgbPresets[gThisPreset].mTpChannel = atoi(propValue)
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case DMX_READING_DMX_RGB_PRESET

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

DEFINE_FUNCTION integer presetTypeFromStr (char str[])
{
    lower_string (str)
    switch (str)
    {
    case 'rgb-preset':		return DMX_TYPE_RGB
    case 'rgb-rainbow':		return DMX_TYPE_RGB_CYCLE_RAINBOW
    case 'rgb-cycle':		return DMX_TYPE_RGB_CYCLE_CUSTOM
    default:			return DMX_TYPE_UNKNOWN
    }
}

#end_if // __DMX_CONFIG__
