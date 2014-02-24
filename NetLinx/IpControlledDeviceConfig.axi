PROGRAM_NAME='IpControlledDeviceConfig'

// IP controlled device config definitions.

#if_not_defined __IP_CONTROLLED_DEVICE_CONFIG__
#define __IP_CONTROLLED_DEVICE_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'ChannelDefs.axi'

DEFINE_CONSTANT

IP_DEV_MAX_DEVICE_TYPES	= 8
IP_DEV_MAX_DEVICES		= 32
IP_DEV_MAX_COMMAND_LEN		= 32
IP_DEV_MAX_DEVICE_TYPE_NAME_LEN = 100

DEFINE_TYPE

structure IpDevGeneral
{
    integer	mEnabled		// Whether any IP devices are even present in this system
}

structure IpDevType
{
    char	mName[IP_DEV_MAX_COMMAND_LEN]
    char	mCommandByChannel[CHAN_MAX_CHANNELS][IP_DEV_MAX_COMMAND_LEN]
					// array of commands indexed by channel
    char	mCommandSep[4]		// Separator for commands (usually $0D or $0A$0D)
    char	mCommandPrefix[IP_DEV_MAX_COMMAND_LEN]
					// a prefix to add to all non-empty commands
}

structure IpDevice
{
    integer	mId			// ID for referencing by other objects
    dev		mDevIp			// Virtual device to connect and send commands
    dev		mDevControl		// Virtual device to receive AMX pulses and button presses
    char	mName[32]		// Name for this IP device
    char	mShortName[16]		// Short name for this IP device
    char	mTelnetAddr[32]		// Telnet IP address or hostname
    integer	mTelnetPort		// Telnet port (default is 23)
    char	mCommandSep[4]		// Separator for commands (usually $0D, $0A or $0D$0A)
    char	mCommandByChannel[CHAN_MAX_CHANNELS][IP_DEV_MAX_COMMAND_LEN]
					// array of commands indexed by channel
    char	mCommandPrefix[IP_DEV_MAX_COMMAND_LEN]
					// a prefix to add to all non-empty commands
}


DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_DEVICE_TYPE		= 2
READING_DEVICE			= 3


DEFINE_VARIABLE

volatile IpDevGeneral	gGeneral
volatile IpDevType	gDeviceTypes[IP_DEV_MAX_DEVICE_TYPES]
volatile IpDevice	gIpDevices[IP_DEV_MAX_DEVICES]
volatile dev		gVdvControl[IP_DEV_MAX_DEVICES]
volatile dev		gVdvIp[IP_DEV_MAX_DEVICES]
volatile integer	gThisItem = 0
volatile integer	gReadMode = READING_NONE


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
	set_length_array(gDeviceTypes, length_array(gDeviceTypes)+1)
	set_length_array(gDeviceTypes[length_array(gDeviceTypes)].mCommandByChannel, CHAN_MAX_CHANNELS)
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
	    gGeneral.mEnabled = getBooleanProp(propValue)
	default:
	    debug (moduleName, 3, "'Unknown general config property: ',propName,' (=',propValue,')'")
	} // switch
    }

    case READING_DEVICE_TYPE:
    {
	switch (propName)
	{
	case 'name':
	{
	    lower_string (propValue)
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
	case 'command-separator':
	{
	    parseSeparator (gDeviceTypes[length_array(gDeviceTypes)].mCommandSep, propValue)
	    break
	}
	case 'command-prefix':
	{
	    gDeviceTypes[length_array(gDeviceTypes)].mCommandPrefix = propValue
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_DEVICE_TYPE

    case READING_DEVICE:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gIpDevices) < gThisItem)
	    {
		set_length_array (gIpDevices,	gThisItem)
		set_length_array (gVdvControl,	gThisItem)
		set_length_array (gVdvIp,	gThisItem)
	    }
	    gIpDevices[gThisItem].mId = gThisItem
	    gIpDevices[gThisItem].mTelnetPort = 23
	    break
	}
	case 'name':
	{
	    gIpDevices[gThisItem].mName = propValue
	    if (gIpDevices[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gIpDevices[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gIpDevices[gThisItem].mShortName = propValue
	    break
	}
	case 'device-type':
	{
	    lower_string (propValue)
	    copyDeviceTypeInfo (gIpDevices[gThisItem], propValue)
	    break
	}
	case 'control-device':
	{
	    parseDev (gIpDevices[gThisItem].mDevControl, propValue)
	    gVdvControl[gThisItem] = gIpDevices[gThisItem].mDevControl
	    break
	}
	case 'ip-device':
	{
	    parseDev (gIpDevices[gThisItem].mDevIp, propValue)
	    gVdvIp[gThisItem] = gIpDevices[gThisItem].mDevIp
	    break
	}
	case 'telnet-address':
	{
	    gIpDevices[gThisItem].mTelnetAddr = propValue
	    break
	}
	case 'telnet-port':
	{
	    gIpDevices[gThisItem].mTelnetport = atoi(propValue)
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
    } // switch
}

DEFINE_FUNCTION copyDeviceTypeInfo (IpDevice  ipDev, char devTypeName[])
{
    integer i, j
    for (i = 1; i <= length_array(gDeviceTypes); i++)
    {
debug('foo',9,"'check: ',devTypeName,'=',gDeviceTypes[i].mName,'?'")
	if (devTypeName = gDeviceTypes[i].mName)
	{
debug('foo',9,"'  check: ',gDeviceTypes[i].mCommandByChannel,'?'")
	    set_length_array (ipDev.mCommandByChannel, length_array(gDeviceTypes[i].mCommandByChannel))
	    for (j = length_array(gDeviceTypes[i].mCommandByChannel); j > 0; j--)
	    {
		ipDev.mCommandByChannel[j] = gDeviceTypes[i].mCommandByChannel[j]
	    }
debug('foo',9,"'  check: ',gDeviceTypes[i].mCommandSep,'?'")
	    ipDev.mCommandSep	    = gDeviceTypes[i].mCommandSep
debug('foo',9,"'  check: ',gDeviceTypes[i].mCommandPrefix,'?'")
	    ipDev.mCommandPrefix    = gDeviceTypes[i].mCommandPrefix
debug('foo',9,"'  checks complete'")
	    return
	}
    }
}

DEFINE_FUNCTION parseSeparator (char result[], char sepStr[])
{
    // Copy sepStr while replacing ASCII references with actual value
    integer i, j
    j = 1
    set_length_array(result,4)
    for (i = 1; j < length_array(sepStr); i++)
    {
	if (sepStr[j] = '$')
	{
	    remove_string (sepStr,'$',1)
	    result[i] = hextoi(sepStr)
	    if (sepStr != '')
	    {
		for (j = 1; ((('0' <= sepStr[j]) && (sepStr[j] <= '9')) ||
	    	       	     (('A' <= sepStr[j]) && (sepStr[j] <= 'F')) ||
			     (('a' <= sepStr[j]) && (sepStr[j] <= 'f'))); j++)
		    ; // all we want to do is move j along
	    }
	}
	else
	{
	    result[i] = sepStr[j]
	    j++
	}
    }
}

#end_if // __IP_CONTROLLED_DEVICE_CONFIG__
