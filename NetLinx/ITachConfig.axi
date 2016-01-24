#if_not_defined __ITACH_CONFIG__
#define __ITACH_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'HttpConfig.axi'


DEFINE_TYPE

structure ITachConfigGeneral
{
    integer	mEnabled		// Whether ITachs are even present in this system
}

structure ITachConfigItem
{
    integer	mId
    char	mName[32]
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_ITACH			= 2


DEFINE_VARIABLE

volatile ITachConfigGeneral	gGeneral
volatile ITachConfigItem	gDtvs[MAX_HTTP_SERVERS]
volatile HttpConfig		gHttpCfgs[MAX_HTTP_SERVERS]
volatile integer		gThisItem = 0
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
    case 'itach':
    {
	gReadMode = READING_ITACH
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

    case READING_ITACH:
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
	case 'server-ip-address':
	    gHttpCfgs[gThisItem].mServerIpAddress = propValue
	case 'server-port':
	    gHttpCfgs[gThisItem].mServerPort = atoi(propValue)
	default:
	    debug (moduleName, 3, "'Unknown ITach config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

#end_if // __ITACH_CONFIG__
