#if_not_defined __WUNDERGROUND_CONFIG__
#define __WUNDERGROUND_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'HttpConfig.axi'


DEFINE_TYPE

structure WundergroundConfigGeneral
{
    integer	mEnabled		// Whether this module is active
    integer	mDebugLevel
    dev		mDevStatus
    integer	mTpPort
    char	mCurrCondLoc[32]
    char	mAirportLoc[32]
    char	mForecastLoc[32]
    char	mServerName[64]
    integer	mServerPort
    char	mCurrCondPath[256]
    char	mAirportPath[256]
    char	mForecastPath[256]
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1


DEFINE_VARIABLE

volatile WundergroundConfigGeneral	gGeneral
volatile HttpConfig			gHttpCfgs[MAX_HTTP_SERVERS]
volatile integer			gReadMode = READING_NONE


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
	case 'dev-status':
	    parseDev (gGeneral.mDevStatus, propValue)
	case 'tp-port':
	    gGeneral.mTpPort      = atoi(propValue)
	case 'current-conditions-loc':
	    gGeneral.mCurrCondLoc = propValue
	case 'airport-loc':
	    gGeneral.mAirportLoc  = propValue
	case 'forecast-loc':
	    gGeneral.mForecastLoc = propValue
	case 'web-api-server':
	    gGeneral.mServerName  = propValue
	case 'web-api-port':
	    gGeneral.mServerPort = atoi(propValue)
	case 'current-conditions-path':
	    gGeneral.mCurrCondPath = propValue
	case 'airport-path':
	    gGeneral.mAirportPath = propValue
	case 'forecast-path':
	    gGeneral.mForecastPath = propValue

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

#end_if // __WUNDERGROUND_CONFIG__
