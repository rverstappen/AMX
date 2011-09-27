PROGRAM_NAME='LutronConfig'

// Lutron config definitions.
//
// These are used by several modules but must be served up to each module using 
// serialization over TCP. The LutronConfigServer module will listen for requests 
// for the Lutron configuration data.

#if_not_defined __LUTRON_CONFIG__
#define __LUTRON_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'

DEFINE_CONSTANT

LUTRON_DEV_TYPE_UNKNOWN	= 0
LUTRON_DEV_TYPE_TELNET	= 1
LUTRON_DEV_TYPE_SERIAL	= 2

LUTRON_MAX_OUTPUTS	= 300
LUTRON_MAX_INPUTS	= 300

LUTRON_OUTPUT_TYPE_UNKNOWN	= 0
LUTRON_OUTPUT_TYPE_DIMMER	= 1
LUTRON_OUTPUT_TYPE_SWITCHED	= 2
LUTRON_OUTPUT_TYPE_BLIND	= 3
LUTRON_OUTPUT_TYPE_FAN		= 4

LUTRON_INPUT_TYPE_UNKNOWN	= 0
LUTRON_INPUT_TYPE_KEYPAD	= 1

DEFINE_TYPE

structure LutronGeneral
{
    integer	mEnabled		// Whether Lutron is even present in this system
    dev		mDev			// Device to connect and send commands
    integer	mDevType		// 'telnet' or 'serial' (default)
    char	mDevName[32]		// Telnet or serial device name
    char	mTelnetAddr[32]		// Telnet IP address or hostname
    integer	mTelnetPort		// Telnet port (default is 23)
    char	mUsername[32]		// Username to log in (telnet)
    char	mPassword[32]		// Password (telnet and serial)
    dev		mDevControl		// Device for AMX internal control
}

structure LutronOutput
{
    integer	mId			// ID for referencing by other objects
    char	mName[32]		// Name for this Lutron output
    char	mShortName[16]		// Short name for this Lutron output
    integer	mType			// Lutron output type (dimmer, switched, etc.)
    char	mAddress[16]		// Lutron address
}

structure LutronInput
{
    integer	mId			// ID for referencing by other objects
    char	mName[32]		// Name for this Lutron input
    char	mShortName[16]		// Short name for this Lutron input
    integer	mType			// Lutron input type (individual control or keypad control)
    char	mAddress[16]		// Lutron address
    char	mButtonNames[32][24]	// For keypads
}

DEFINE_FUNCTION integer lutronOutputTypeFromStr (char str[])
{
    switch (str)
    {
    case 'dimmer':	return LUTRON_OUTPUT_TYPE_DIMMER
    case 'switched':	return LUTRON_OUTPUT_TYPE_SWITCHED
    case 'blind':	return LUTRON_OUTPUT_TYPE_BLIND
    case 'fan':		return LUTRON_OUTPUT_TYPE_FAN
    default:		return LUTRON_OUTPUT_TYPE_UNKNOWN
    }
}

DEFINE_FUNCTION char[8] lutronStrFromOutputType (integer type)
{
    switch (type)
    {
    case LUTRON_OUTPUT_TYPE_DIMMER:	return 'dimmer'
    case LUTRON_OUTPUT_TYPE_SWITCHED:	return 'switched'
    case LUTRON_OUTPUT_TYPE_BLIND:	return 'blind'
    case LUTRON_OUTPUT_TYPE_FAN:	return 'fan'
    default:				return 'unknown'
    }
}

DEFINE_FUNCTION integer lutronInputTypeFromStr (char str[])
{
    switch (str)
    {
    case 'keypad':	return LUTRON_INPUT_TYPE_KEYPAD
    default:		return LUTRON_INPUT_TYPE_UNKNOWN
    }
}

DEFINE_FUNCTION char[8] lutronStrFromInputType (integer type)
{
    switch (type)
    {
    case LUTRON_INPUT_TYPE_KEYPAD:	return 'keypad'
    default:				return 'unknown'
    }
}


DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_OUTPUT			= 2
READING_INPUT			= 3

DEFINE_VARIABLE

volatile LutronGeneral	   gGeneral
volatile LutronOutput	   gOutputs[LUTRON_MAX_OUTPUTS]
volatile LutronInput	   gInputs[LUTRON_MAX_INPUTS]
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
	gGeneral.mDevType = LUTRON_DEV_TYPE_TELNET
	break
    }
    case 'output':
    {
	gReadMode = READING_OUTPUT
	gThisItem = 0
	break
    }
    case 'input':
    {
	gReadMode = READING_INPUT
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
	case 'device':
	{
	    parseDev (gGeneral.mDev, propValue)
	    break
	}
	case 'device-type':
	{
	    lower_string (propValue)
	    switch (propValue)
	    {
	    case 'telnet':	gGeneral.mDevType = LUTRON_DEV_TYPE_TELNET
	    case 'serial':	gGeneral.mDevType = LUTRON_DEV_TYPE_SERIAL
	    }
	    break
	}
	case 'telnet-address':
	{
	    gGeneral.mTelnetAddr = propValue
	    if (gGeneral.mTelnetPort = 0)
	        gGeneral.mTelnetPort = 23
	    break
	}
	case 'telnet-port':
	{
	    gGeneral.mTelnetport = atoi(propValue)
	    break
	}
	case 'username':
	{
	    gGeneral.mUsername = propValue
	    break
	}
	case 'password':
	{
	    gGeneral.mPassword = propValue
	    break
	}
	case 'dev-control':
	{
	    parseDev (gGeneral.mDevControl, propValue)
	    break
	}
	} // switch
    }

    case READING_OUTPUT:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gOutputs) < gThisItem)
	    {
		set_length_array(gOutputs, gThisItem)
	    }
	    gOutputs[gThisItem].mId = gThisItem
	    break
	}
	case 'name':
	{
	    gOutputs[gThisItem].mName = propValue
	    if (gOutputs[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gOutputs[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gOutputs[gThisItem].mShortName = propValue
	    break
	}
	case 'type':
	{
	    gOutputs[gThisItem].mType = lutronOutputTypeFromStr (propValue)
	    break
	}
	case 'address':
	{
	    gOutputs[gThisItem].mAddress = propValue
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_OUTPUT

    case READING_INPUT:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gInputs) < gThisItem)
	    {
		set_length_array(gInputs, gThisItem)
	    }
	    gInputs[gThisItem].mId = gThisItem
	    break
	}
	case 'name':
	{
	    gInputs[gThisItem].mName = propValue
	    if (gInputs[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gInputs[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gInputs[gThisItem].mShortName = propValue
	    break
	}
	case 'type':
	{
	    gInputs[gThisItem].mType = lutronOutputTypeFromStr (propValue)
	    break
	}
	case 'address':
	{
	    gInputs[gThisItem].mAddress = propValue
	    break
	}
	case 'buttons':
	{
//	    gInputs[gThisItem].mButtonNames = atoi(propValue)
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_INPUT
    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}


#end_if // __LUTRON_CONFIG__
