#if_not_defined __LIGHTING_CONFIG__
#define __LIGHTING_CONFIG__

// UI Support for lighting systems, such as Lutron. 

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'


DEFINE_CONSTANT
MAX_LIGHTING_CONTROLS = 256
MAX_BUTTONS_PER_CONTROL = 32

DEFINE_TYPE

structure LightingConfigGeneral
{
    integer	mEnabled		// Whether lighting controls are present in this system
    integer	mDebugLevel		// Log message level
    integer	mTpPort			// Port for Touch Panel events
//    integer	mTpChannelLow		// Low channel for displaying controls
    integer	mTpChannelHigh		// High channel for displaying controls
    dev		mCommDev
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1


DEFINE_VARIABLE

volatile LightingConfigGeneral	gGeneral
volatile LightingControl	gLightingControls[MAX_LIGHTING_CONTROLS]
volatile LightingControlButton	gLightingButtons[MAX_LIGHTING_CONTROLS][MAX_BUTTONS_PER_CONTROL]
volatile integer		gThisItem = 0
volatile integer		gReadMode = READING_NONE
volatile integer		gControlByChannel[1000]  // map TP channel -> control item


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
	    gGeneral.mEnabled = getBooleanProp(propValue)
	case 'debug-level':
	    gGeneral.mDebugLevel = atoi(propValue)
	case 'tp-port':
	    gGeneral.mTpPort = atoi(propValue)
//	case 'tp-channel-range-low':
//	    gGeneral.mTpChannelLow = atoi(propValue)
	case 'tp-channel-range-high':
	    gGeneral.mTpChannelHigh = atoi(propValue)
	case 'comm-dev':
	    parseDev (gGeneral.mCommDev, propValue)
	default:
	    debug (moduleName, 3, "'Unknown general config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

#end_if // __LIGHTING_CONFIG__
