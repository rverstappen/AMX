#if_not_defined __POWER_MANAGEMENT_CONFIG__
#define __POWER_MANAGEMENT_CONFIG__

// UI Support for power management. 

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'


DEFINE_CONSTANT
MAX_POWER_CONTROLS = 256

DEFINE_TYPE

structure PowerManConfigGeneral
{
    integer	mEnabled		// Whether power controls are present in this system
    integer	mTpPort			// Port for Touch Panel events
    integer	mTpChannelLow		// Low channel for displaying controls
    integer	mTpChannelHigh		// High channel for displaying controls
}

structure PowerManConfigItem
{
    integer	mId
    char	mName[32]
    dev		mDev
    integer	mTpChannel		// Button on TP displays
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_POWER_ITEM		= 2


DEFINE_VARIABLE

volatile PowerManConfigGeneral	gGeneral
volatile PowerManConfigItem	gPowerControls[MAX_POWER_CONTROLS]
volatile integer		gThisItem = 0
volatile integer		gReadMode = READING_NONE
volatile integer		gControlByChannel[1000]  // map TP channel -> PM control item


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
    case 'power-item':
    {
	gReadMode = READING_POWER_ITEM
	gThisItem++
	if (gThisItem > length_array(gPowerControls))
	{
	    set_length_array (gPowerControls, gThisItem)
	}
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
	case 'tp-port':
	    gGeneral.mTpPort = atoi(propValue)
	case 'tp-channel-range-low':
	    gGeneral.mTpChannelLow = atoi(propValue)
	case 'tp-channel-range-high':
	    gGeneral.mTpChannelHigh = atoi(propValue)
	default:
	    debug (moduleName, 3, "'Unknown general config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    case READING_POWER_ITEM:
    {
	switch (propName)
	{
	case 'name':
	    gPowerControls[gThisItem].mName = propValue
	case 'dev':
	    parseDev (gPowerControls[gThisItem].mDev, propValue)
	case 'tp-button-channel':
	    gPowerControls[gThisItem].mTpChannel = atoi(propValue)
	default:
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

#end_if // __POWER_MANAGEMENT_CONFIG__
