#if_not_defined __HVAC_CONFIG__
#define __HVAC_CONFIG__

#include 'Debug.axi'
#include 'Hvac.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'


DEFINE_TYPE

structure HvacConfigGeneral
{
    integer	mEnabled		// Whether hvacs are even present in this system
    dev		mDevControl		// Device for AMX internal control
    integer	mTpPortControl		// Port for Touch Panel events for individual HVAC control
    integer	mTpPortSummary		// Port for Touch Panel events for HVAC summaries
}

structure HvacConfigHvacItem
{
    integer	mId
    char	mName[32]
    char	mShortName[16]
    dev		mDev
    sinteger	mAwayHeatTemp
    sinteger	mAwayCoolTemp
    sinteger	mVacationHeatTemp
    sinteger	mVacationCoolTemp
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_HVAC			= 2


DEFINE_VARIABLE

volatile HvacConfigGeneral	gGeneral
volatile HvacConfigHvacItem	gHvacs[MAX_HVACS]
volatile dev			gHvacDvs[MAX_HVACS]
volatile integer		gThisItem = 0 // hvacs
volatile integer		gReadMode = READING_NONE


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
    case 'hvac':
    {
	gReadMode = READING_HVAC
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
	case 'dev-control':
	{
	    parseDev (gGeneral.mDevControl, propValue)
	    break
	}
	case 'tp-port-control':
	{
	    gGeneral.mTpPortControl = atoi(propValue)
	    break
	}
	case 'tp-port-summary':
	{
	    gGeneral.mTpPortSummary = atoi(propValue)
	    break
	}
	default:
	{
	    debug (moduleName, 3, "'Unknown general config property: ',propName,' (=',propValue,')'")
	}
	} // switch
    }

    case READING_HVAC:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gHvacs) < gThisItem)
	    {
		set_length_array(gHvacs,   gThisItem)
		set_length_array(gHvacDvs, gThisItem)
	    }
	    break
	}
	case 'name':
	{
	    gHvacs[gThisItem].mName = propValue
	    if (gHvacs[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gHvacs[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gHvacs[gThisItem].mShortName = propValue
	    break
	}
	case 'dev':
	{
	    parseDev (gHvacs[gThisItem].mDev, propValue)
	    gHvacDvs[gThisItem] = gHvacs[gThisItem].mDev
	    break
	}
	case 'away-heat-temp':
	{
	    gHvacs[gThisItem].mAwayHeatTemp = atoi(propValue)
	}
	case 'away-cool-temp':
	{
	    gHvacs[gThisItem].mAwayCoolTemp = atoi(propValue)
	}
	case 'vacation-heat-temp':
	{
	    gHvacs[gThisItem].mVacationHeatTemp = atoi(propValue)
	}
	case 'vacation-cool-temp':
	{
	    gHvacs[gThisItem].mVacationCoolTemp = atoi(propValue)
	}
	default:
	{
	    debug (moduleName, 3, "'Unknown HVAC config property: ',propName,' (=',propValue,')'")
	}
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}


DEFINE_START
gGeneral.mTpPortControl = 1		// Anything but zero
gGeneral.mTpPortSummary = 1		// Anything but zero


#end_if // __HVAC_CONFIG__
