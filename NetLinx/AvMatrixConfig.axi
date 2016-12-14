#if_not_defined __AV_MATRIX_CONFIG__
#define __AV_MATRIX_CONFIG__


#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'


DEFINE_TYPE

structure AvMatrixGeneral
{
    integer	mEnabled
    dev		mDevControl
    dev		mDevSwitch
    dev		mDevAv
    integer	mMaxInputs
    integer	mMaxOutputs
}


DEFINE_CONSTANT

READING_NONE			= 0
READING_GENERAL			= 1
READING_INPUT			= 2
READING_OUTPUT			= 3
MATRIX_MAX_INPUTS		= 32
MATRIX_MAX_OUTPUTS		= 64

DEFINE_VARIABLE

volatile AvMatrixGeneral	gGeneral
volatile integer		gReadMode	= READING_NONE


DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'general':
    {
	gReadMode = READING_GENERAL
    }
    case 'input':
    {
	gReadMode = READING_INPUT
    }
    case 'output':
    {
	gReadMode = READING_OUTPUT
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
	case 'dev-control':
	    parseDev (gGeneral.mDevControl, propValue)
	case 'dev-switch':
	    parseDev (gGeneral.mDevSwitch, propValue)
	case 'dev-av':
	    parseDev (gGeneral.mDevAv, propValue)
	case 'max-inputs':
	    gGeneral.mMaxInputs = atoi(propValue)
	case 'max-output':
	    gGeneral.mMaxOutputs = atoi(propValue)
	} // switch
    } // case READING_GENERAL
    case READING_INPUT:
    {
	avMatrixConfigInputProperty(moduleName, propName, propValue)
    } // case READING_INPUT
    case READING_OUTPUT:
    {
	avMatrixConfigOutputProperty(moduleName, propName, propValue)
    } // case READING_OUTPUT
    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    } // switch
}