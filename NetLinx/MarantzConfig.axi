PROGRAM_NAME='MarantzConfig'

// Marantz config definitions.
//
// These are used by several modules but must be served up to each module using 
// serialization over TCP. The MarantzConfigServer module will listen for requests 
// for the Marantz configuration data.

#if_not_defined __MARANTZ_CONFIG__
#define __MARANTZ_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'ChannelDefs.axi'

DEFINE_CONSTANT

MARANTZ_MAX_DEVICE_TYPES	= 8
MARANTZ_MAX_DEVICES		= 32
MARANTZ_MAX_COMMAND_LEN		= 32
MARANTZ_MAX_DEVICE_TYPE_NAME_LEN = 100

DEFINE_TYPE

structure MarantzGeneral
{
    integer	mEnabled		// Whether Marantz is even present in this system
}

structure MarantzDeviceType
{
    char	mTypeName[MARANTZ_MAX_COMMAND_LEN]
    char	mCommandByChannel[CHAN_MAX_CHANNELS][MAX_COMMAND_LEN]
}

structure MarantzDevice
{
    integer	mId			// ID for referencing by other objects
    dev		mDev			// Device to connect and send commands
    char	mName[32]		// Name for this Marantz output
    char	mShortName[16]		// Short name for this Marantz output
    char	mTelnetAddr[32]		// Telnet IP address or hostname
    integer	mTelnetPort		// Telnet port (default is 23)
//    char	mCommandSep[4]		// Separator for commands (usually $0D or $
    char	mCommandByChannel[CHAN_MAX_CHANNELS][MAX_COMMAND_LEN]	// array of commands indexed by channel
    char	mCommandPrefix[MAX_COMMAND_LEN]	// a prefix to add to all non-empty commands
}


DEFINE_CONSTANT

READING_NONE			= 0
READING_DEVICE_TYPE		= 1
READING_DEVICE			= 2


DEFINE_VARIABLE

volatile MarantzGeneral	   gGeneral
volatile MarantzDeviceType gDeviceTypes[MARANTZ_MAX_DEVICE_TYPES]
volatile MarantzDevice	   gControlDevices[MARANTZ_MAX_OUTPUTS]
volatile integer	   gThisItem = 0
volatile integer	   gReadMode = READING_NONE


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
    case 'device-type':
    {
	gReadMode = READING_DEVICE_TYPE
	set_length_array(gDeviceTypes, set_length_array(gDeviceTypes)+1)
	break
    }
    case 'device':
    {
	gReadMode = READING_DEVICE
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
    case READING_GENERAL:
    {
	switch (propName)
	{
	case 'enabled':
	{
	    lower_string (propValue)
	    gGeneral.mEnabled = (propValue = 'true' || propValue = 't' || propValue = 1)
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	} // switch
    }

    case READING_DEVICE:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gControlDevices) < gThisItem)
	    {
		set_length_array(gControlDevices, gThisItem)
	    }
	    gControlDevices[gThisItem].mId = gThisItem
	    break
	}
	case 'device':
	{
	    parseDev (gControlDevices[gThisItem].mDev, propValue)
	    break
	}
	case 'name':
	{
	    gControlDevices[gThisItem].mName = propValue
	    if (gControlDevices[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gControlDevices[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gControlDevices[gThisItem].mShortName = propValue
	    break
	}
	case 'device-type':
	{
	    setCommandByChannel(gControlDevices[gThisItem].mCommandByChannel, propValue)
	    break
	}
	case 'telnet-address':
	{
	    gControlDevices[gThisItem].mTelnetAddr = propValue
	    if (gControlDevices[gThisItem].mTelnetPort = 0)
	        gControlDevices[gThisItem].mTelnetPort = 23
	    break
	}
	case 'telnet-port':
	{
	    gControlDevices[gThisItem].mTelnetport = atoi(propValue)
	    break
	}
	case 'command-separator':
	{
	    gControlDevices[gThisItem].mCommandSep = propValue
	    break
	}
	case 'command-prefix':
	{
	    gControlDevices[gThisItem].mCommandPrefix = propValue
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_DEVICE

    case READING_DEVICE_TYPE:
    {
	switch (propName)
	{
	case 'name':
	{
	    gDeviceTypes[length_array(gDeviceTypes)].mName = propValue
	    break
	}
	case 'channel-command':
	{
	    integer  chanId
	    chanId = atoi(propValue)
	    remove_string(propValue,'->',1)
	    gDeviceTypes[length_array(gDeviceTypes)].mCommandByChannel[chanId] = propValue
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_DEVICE
}

DEFINE_FUNCTION setCommandByChannel (char channelCommands[CHAN_MAX_CHANNELS][], char devTypeName[])
{
    integer i
    for (i = 1; i <= length_array(gDeviceTypes); i++)
    {
	if (devTypeName = gDeviceTypes[i].mName)
	{
	    channelCommands = gDeviceTypes[i].mCommandByChannel
	    return
	}
    }
}

#end_if // __MARANTZ_CONFIG__
