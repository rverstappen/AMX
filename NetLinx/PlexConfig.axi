#if_not_defined __PLEX_CONFIG__
#define __PLEX_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'


DEFINE_CONSTANT

MAX_PLEX_SERVERS = 10


DEFINE_TYPE

structure PlexConfigGeneral
{
    integer	mEnabled		// Whether plexs are even present in this system
}

structure PlexConfigItem
{
    integer	mId
    char	mName[32]
    dev		mDevControl		// Device for AMX internal control
    dev		mDevLocal		// For socket connection
    char	mServerIpAddress[16]
    integer	mServerPort
    char	mPlayerName[64]
}

DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_PLEX			= 2


DEFINE_VARIABLE

volatile PlexConfigGeneral	gGeneral
volatile PlexConfigItem		gPlexs[MAX_PLEX_SERVERS]
volatile dev			gDvPlexControl[MAX_PLEX_SERVERS]
volatile dev			gDvPlexLocal[MAX_PLEX_SERVERS]
volatile integer		gThisItem = 0 // plex servers
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
    case 'plex':
    {
	gReadMode = READING_PLEX
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
	default:
	{
	    debug (moduleName, 3, "'Unknown general config property: ',propName,' (=',propValue,')'")
	}
	} // switch
    }

    case READING_PLEX:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gPlexs) < gThisItem)
	    {
		set_length_array(gPlexs,	gThisItem)
		set_length_array(gDvPlexControl,gThisItem)
		set_length_array(gDvPlexLocal,	gThisItem)
	    }
	}
	case 'name':
	    gPlexs[gThisItem].mName = propValue
	case 'dev-control':
	{
	    parseDev (gPlexs[gThisItem].mDevControl, propValue)
	    gDvPlexControl[gThisItem] = gPlexs[gThisItem].mDevControl
	    debug (moduleName, 9, "'Got plex control device: ',devtoa(gDvPlexControl[gThisItem])")
	}
	case 'dev-local':
	{
	    parseDev (gPlexs[gThisItem].mDevLocal, propValue)
	    gDvPlexLocal[gThisItem] = gPlexs[gThisItem].mDevLocal
	}
	case 'media-server-ip-address':
	    gPlexs[gThisItem].mServerIpAddress = propValue
	case 'media-server-port':
	    gPlexs[gThisItem].mServerPort = atoi(propValue)
	case 'media-player-name':
	    gPlexs[gThisItem].mPlayerName = propValue
	default:
	    debug (moduleName, 3, "'Unknown Plex config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}


#end_if // __PLEX_CONFIG__
