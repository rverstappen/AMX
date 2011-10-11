#if_not_defined __DIREC_TV_CONFIG__
#define __DIREC_TV_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'HttpConfig.axi'


DEFINE_TYPE

structure DirecTvConfigGeneral
{
    integer	mEnabled		// Whether DirecTvs are even present in this system
}

structure DirecTvConfigItem
{
    integer	mId
    char	mName[32]
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_DIRECTV			= 2


DEFINE_VARIABLE

volatile DirecTvConfigGeneral	gGeneral
volatile DirecTvConfigItem	gDtvs[MAX_HTTP_SERVERS]
volatile HttpConfig		gHttpCfgs[MAX_HTTP_SERVERS]
volatile integer		gThisItem = 0 // directv servers
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
    case 'directv':
    {
	gReadMode = READING_DIRECTV
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

    case READING_DIRECTV:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gDtvs) < gThisItem)
	    {
		set_length_array(gDtvs,     gThisItem)
		set_length_array(gHttpCfgs, gThisItem)
	    }
	}
	case 'name':
	    gDtvs[gThisItem].mName = propValue
	case 'dev-control':
	    parseDev (gHttpCfgs[gThisItem].mDevControl, propValue)
	case 'dev-local':
	    parseDev (gHttpCfgs[gThisItem].mDevLocal, propValue)
	case 'server-ip-address':
	    gHttpCfgs[gThisItem].mServerIpAddress = propValue
	case 'server-port':
	    gHttpCfgs[gThisItem].mServerPort = atoi(propValue)
	default:
	    debug (moduleName, 3, "'Unknown DirecTv config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

#end_if // __DIREC_TV_CONFIG__
