PROGRAM_NAME='ArtelisConfig'

// Configuration support for the ARTELIS module

#if_not_defined __ARTELIS_CONFIG__
#define __ARTELIS_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils'
#include 'ConfigServerUtils'


DEFINE_CONSTANT

ARTELIS_READING_UNKNOWN		= 0
ARTELIS_READING_GENERAL		= 1

	        
DEFINE_TYPE

structure ArtelisGeneral
{
    integer	mEnabled
    integer	mDebugLevel
    integer	mTpPort			// Port for Touch Panel events
    char        mTcpIpAddress[32]
    integer     mTcpPort
    dev         mDevLocal
    integer     mSpaCircuit
    integer     mPoolCircuit
    integer     mAuxCircuits[30]
}

DEFINE_VARIABLE

volatile ArtelisGeneral	gGeneral
volatile integer	gThisItem = 0
volatile integer	gReadMode = ARTELIS_READING_UNKNOWN

DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'general':
    {
	gReadMode = ARTELIS_READING_GENERAL
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

    case ARTELIS_READING_GENERAL:
    {
	switch (propName)
	{
	case 'enabled':
	    lower_string (propValue)
	    gGeneral.mEnabled = (propValue = 'true' || propValue = 't' || propValue = 1)
	case 'debug-level':
	    gGeneral.mDebugLevel = atoi(propValue)
	case 'tp-port':
	    gGeneral.mTpPort = atoi(propValue)
	case 'tcp-ip-address':
	    gGeneral.mTcpIpAddress = propValue
	case 'tcp-port':
	    gGeneral.mTcpPort = atoi(propValue)
	case 'dev-local':
	    parseDev (gGeneral.mDevLocal, propValue)
	case 'spa-circuit':
	    gGeneral.mSpaCircuit = atoi(propValue)
	case 'pool-circuit':
	    gGeneral.mPoolCircuit = atoi(propValue)
	case 'aux-circuits':
	    parseIntegerList (gGeneral.mAuxCircuits, propValue)
	default:
	    debug (moduleName, 3, "'Unknown config property: ',propName,' (=',propValue,')'")
	} // switch
    } // case ARTELIS_READING_GENERAL

    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    } // switch

}

#end_if // __ARTELIS_CONFIG__
