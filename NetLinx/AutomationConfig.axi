PROGRAM_NAME='AutomationConfig'

// Configuration support for the Automation module

#if_not_defined __AUTOMATION_CONFIG__
#define __AUTOMATION_CONFIG__

#include 'ConfigUtils'
#include 'ConfigServerUtils'


DEFINE_CONSTANT

AUTOCFG_ITEM_TYPE_UNKNOWN	= 0
AUTOCFG_ITEM_TYPE_TIME_OF_DAY	= 1

AUTOCFG_MAX_AUTOMATIONS		= 100
AUTOCFG_MAX_TIME_LINE_EVENTS	= 32

AUTOCFG_READING_UNKNOWN		= 0
AUTOCFG_READING_MAIN		= 1
AUTOCFG_READING_AUTOMATION	= 2

	        
DEFINE_TYPE

structure AutomationConfig
{
    double	mLatitude
    double	mLongitude
}

structure AutomationInput
{
    char	mSunrise[8]
    char	mSunset[8]
}

structure AutomationItem
{
    // Common attributes for automation items
    integer	mId
    char	mName[32]
    dev		mDev
    char	mCommand[256]
    integer	mType
    // Attributes specific to time-of-day automations

    // Implementation members:
    long	mTlArray[AUTOCFG_MAX_TIME_LINE_EVENTS]
}


DEFINE_VARIABLE

volatile AutomationConfig	gMainConfig
volatile AutomationItem		gItems[AUTOCFG_MAX_AUTOMATIONS]
volatile integer		gReadMode
volatile integer		gThisItem

DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'general':
    {
	gReadMode = AUTOCFG_READING_MAIN
	break
    }
    case 'automation':
    {
	gReadMode = AUTOCFG_READING_AUTOMATION
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

    case AUTOCFG_READING_MAIN:
    {
	switch (propName)
	{
	case 'latitude':
	{
	    gMainConfig.mLatitude = atof(propValue)
	    break
	}
	case 'longitude':
	{
	    gMainConfig.mLongitude = atof(propValue)
	    break
	}
	} // switch
    } // case AUTOCFG_READING_MAIN

    case AUTOCFG_READING_AUTOMATION:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gItems) < gThisItem)
	    {
		set_length_array(gItems, gThisItem)
	    }
	    gItems[gThisItem].mId = gThisItem
	    break
	}
	case 'name':
	{
	    gItems[gThisItem].mName = propValue
	    break
	}
	case 'dev':
	{
	    parseDev (gItems[gThisItem].mDev, propValue)
	    break
	}
	case 'command':
	{
	    gItems[gThisItem].mCommand = propValue
	    break
	}
	case 'type':
	{
	    gItems[gThisItem].mType = automationType(propValue)
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case AUTOCFG_READING_AUTOMATION
    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

DEFINE_FUNCTION integer automationType (char typeStr[])
{
    lower_string (typeStr)
    switch (typeStr)
    {
    case 'time-of-day':		return AUTOCFG_ITEM_TYPE_TIME_OF_DAY
    default:			return AUTOCFG_ITEM_TYPE_UNKNOWN
    }
}

#end_if // __AUTOMATION_CONFIG__
