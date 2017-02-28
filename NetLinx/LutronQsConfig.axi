#if_not_defined __LUTRON_QS_CONFIG__
#define __LUTRON_QS_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'
#include 'LightingCommon.axi'

DEFINE_TYPE

structure LutronQsGeneral
{
    integer	mEnabled		// Whether Lutron is even present in this system
    integer	mDebugLevel		// How verbose the logging should be
    dev		mDev			// Device to connect and send commands
    char	mDevName[32]		// Telnet device name
    char	mTelnetAddr[32]		// Telnet IP address or hostname
    integer	mTelnetPort		// Telnet port (default is 23)
    char	mUsername[32]		// Username to log in (telnet)
    char	mPassword[32]		// Password (telnet and serial)
    dev		mDevControl		// Device for AMX internal control
}



DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1

DEFINE_VARIABLE

volatile LutronQsGeneral   gGeneral
volatile integer	   gReadMode = READING_NONE

DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'general':
    {
	gReadMode = READING_GENERAL
	gGeneral.mTelnetPort = 23
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
	    lower_string (propValue)
	    gGeneral.mEnabled = (propValue = 'true' || propValue = 't' || propValue = 1)
	case 'debug-level':
	    gGeneral.mDebugLevel = atoi(propValue)
	case 'device':
	    parseDev (gGeneral.mDev, propValue)
	case 'telnet-address':
	    gGeneral.mTelnetAddr = propValue
	case 'telnet-port':
	    gGeneral.mTelnetPort = atoi(propValue)
	case 'username':
	    gGeneral.mUsername = propValue
	case 'password':
	    gGeneral.mPassword = propValue
	case 'dev-control':
	    parseDev (gGeneral.mDevControl, propValue)
	} // switch
    }
    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}


#end_if // __LUTRON_QS_CONFIG__
