#if_not_defined __NET_BOOTER_CONFIG__
#define __NET_BOOTER_CONFIG__

// Support for Synaccess netBooter power management. 
// 
// In particular, this works for the NP-0801DS product but maybe also others.  
// This module provides channel support for power ON, OFF and ON/OFF-toggle (future).
// Multiple netBooters are supported and each outlet gets its own AMX virtual device ID.

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'HttpConfig.axi'


DEFINE_CONSTANT
MAX_NETBOOTERS = 16
MAX_NETBOOTER_PORTS_PER_DEVICE = 16
MAX_NETBOOTER_PORTS = MAX_NETBOOTERS * MAX_NETBOOTER_PORTS_PER_DEVICE

DEFINE_TYPE

structure NetBooterConfigGeneral
{
    integer	mEnabled		// Whether netBooters are even present in this system
}

structure NetBooterConfigItem
{
    integer	mId
    char	mName[32]
    integer	mNumPorts
    char	mPortNames[MAX_NETBOOTER_PORTS_PER_DEVICE][32]
    integer	mHttpId			// Reference to HTTP server (implementation)
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_NETBOOTER		= 2


DEFINE_VARIABLE

volatile NetBooterConfigGeneral	gGeneral
volatile NetBooterConfigItem    gNetBooters[MAX_NETBOOTERS]
volatile HttpConfig		gHttpCfgs[MAX_HTTP_SERVERS]
volatile integer		gThisItem = 0 // netBooter servers
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
    case 'net-booter':
    {
	gReadMode = READING_NETBOOTER
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

    case READING_NETBOOTER:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gNetBooters) < gThisItem)
	    {
		set_length_array(gNetBooters,    gThisItem)
		set_length_array(gHttpCfgs, gThisItem)
	    }
	}
	case 'name':
	    gNetBooters[gThisItem].mName = propValue
	case 'dev-control':
	    parseDev (gHttpCfgs[gThisItem].mDevControl, propValue)
//	case 'dev-local':
//	    parseDev (gHttpCfgs[gThisItem].mDevLocal, propValue)
	case 'server-ip-address':
	    gHttpCfgs[gThisItem].mServerIpAddress = propValue
	case 'server-port':
	    gHttpCfgs[gThisItem].mServerPort = atoi(propValue)
	case 'server-username':
	    gHttpCfgs[gThisItem].mServerUsername = propValue
	case 'server-password':
	    gHttpCfgs[gThisItem].mServerPassword = propValue
	case 'num-ports':
	    gNetBooters[gThisItem].mNumPorts = atoi(propValue)
	default:
	{
	    if (left_string(propName,5) = 'port-')
	    {
		integer portNum
		remove_string(propName,'port-',1)
		portNum=atoi(propName)
		gNetBooters[gThisItem].mPortNames[portNum] = propValue
	    }
	    else
	    {
		debug (moduleName, 3, "'Unknown NetBooter config property: ',propName,' (=',propValue,')'")
	    }
	}
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

#end_if // __NET_BOOTER_CONFIG__
