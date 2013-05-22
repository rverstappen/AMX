#if_not_defined __MARANTZ_CONFIG__
#define __MARANTZ_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'HttpConfig.axi'

DEFINE_TYPE

structure MarantzConfigGeneral
{
    integer	mEnabled		// Whether Marantzs are even present in this system
}

structure MarantzConfigItem
{
    integer	mId
    char	mName[32]
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_MARANTZ			= 2


DEFINE_VARIABLE

volatile MarantzConfigGeneral	gGeneral
volatile MarantzConfigItem	gMarantzs[MAX_HTTP_SERVERS]
volatile HttpConfig		gHttpCfgs[MAX_HTTP_SERVERS]
volatile integer		gThisItem = 0 // marantz servers
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
    case 'marantz':
    {
	gReadMode = READING_MARANTZ
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
	default:
	    debug (moduleName, 3, "'Unknown general config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    case READING_MARANTZ:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gMarantzs) < gThisItem)
	    {
		set_length_array(gMarantzs,     gThisItem)
		set_length_array(gHttpCfgs, gThisItem)
	    }
	}
	case 'name':
	    gMarantzs[gThisItem].mName = propValue
	case 'dev-control':
	    parseDev (gHttpCfgs[gThisItem].mDevControl, propValue)
//	case 'dev-local':
//	    parseDev (gHttpCfgs[gThisItem].mDevLocal, propValue)
	case 'server-ip-address':
	    gHttpCfgs[gThisItem].mServerIpAddress = propValue
	case 'server-port':
	    gHttpCfgs[gThisItem].mServerPort = atoi(propValue)
	default:
	    debug (moduleName, 3, "'Unknown Marantz config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

#end_if // __MARANTZ_CONFIG__
