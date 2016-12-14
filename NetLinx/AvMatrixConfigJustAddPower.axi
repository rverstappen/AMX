// Special config handling for Just Add Power matrix switches:
//
//[jap-input]
//	id=1
//	name=DirecTV 1
//	dev=33121:1:1
//	telnet-ip-address=10.0.0.2
//	audio-delay=19
//
//[jap-output]
//	id=1
//	name=Living Room AVR
//	dev=33135:1:1
//	telnet-ip-address=10.128.0.2
//	control=cec
//      cec-id=e0

DEFINE_CONSTANT
JAP_CONNECT_TYPE_NONE = 0
JAP_CONNECT_TYPE_CEC  = 1


DEFINE_TYPE
structure MatrixJapInput
{
    integer	mId
    dev		mDev
    char	mName[64]
    char	mTelnetIp[64]
    integer	mAudioDelay
    integer     mConnectType
    char	mCecId[64]
}

DEFINE_TYPE
structure MatrixJapOutput
{
    integer	mId
    dev		mDev
    char	mName[64]
    char	mTelnetIp[64]
    integer     mConnectType
    char	mCecId[64]
}

DEFINE_VARIABLE
volatile integer gThisInput
volatile integer gThisOutput
volatile integer gMaxInput
volatile integer gMaxOutput
volatile MatrixJapInput  gCfgJapInputs[MATRIX_MAX_INPUTS]
volatile MatrixJapOutput gCfgJapOutputs[MATRIX_MAX_OUTPUTS]


DEFINE_FUNCTION avMatrixConfigInputProperty(char moduleName[], char propName[], char propValue[])
{
    switch (propName)
    {
    case 'id':
    {
	gThisInput = atoi(propValue)
	if (gMaxInput < gThisInput)
	{
	    gMaxInput = gThisInput
	    set_length_array(gCfgJapInputs,gMaxInput)
	}
	gCfgJapInputs[gThisInput].mId = gThisInput
	gCfgJapInputs[gThisInput].mCecId = 'e0'
    }
    case 'dev':
    {
	parseDev(gCfgJapInputs[gThisInput].mDev, propValue)
    }
    case 'name':
    {
	gCfgJapInputs[gThisInput].mName = propValue
    }
    case 'telnet-ip-address':
    {
	gCfgJapInputs[gThisInput].mTelnetIp = propValue
    }
    case 'audio-delay':
    {
	gCfgJapInputs[gThisInput].mAudioDelay = atoi(propValue)
    }
    case 'control':
    {
	gCfgJapInputs[gThisInput].mConnectType = japConnectType(propValue)
    }
    case 'cec-id':
    {
	gCfgJapInputs[gThisInput].mCecId = propValue
    }
    default:
    {
	debug (moduleName, 1, "'error: unknown input property (',propName,'): <',propValue,'>'")
    }
    } // switch
}

DEFINE_FUNCTION avMatrixConfigOutputProperty(char moduleName[], char propName[], char propValue[])
{
    switch (propName)
    {
    case 'id':
    {
	gThisOutput = atoi(propValue)
	if (gMaxOutput < gThisOutput)
	{
	    gMaxOutput = gThisOutput
	    set_length_array(gCfgJapOutputs,gMaxOutput)
	}
	gCfgJapOutputs[gThisOutput].mId = gThisOutput
	gCfgJapOutputs[gThisOutput].mCecId = 'e0'
    }
    case 'dev':
    {
	parseDev(gCfgJapOutputs[gThisOutput].mDev, propValue)
    }
    case 'name':
    {
	gCfgJapOutputs[gThisOutput].mName = propValue
    }
    case 'telnet-ip-address':
    {
	gCfgJapOutputs[gThisOutput].mTelnetIp = propValue
    }
    case 'control':
    {
	gCfgJapOutputs[gThisOutput].mConnectType = japConnectType(propValue)
    }
    case 'cec-id':
    {
	gCfgJapOutputs[gThisOutput].mCecId = propValue
    }
    default:
    {
	debug (moduleName, 1, "'error: unknown output property (',propName,'): <',propValue,'>'")
    }
    } // switch
}

DEFINE_FUNCTION integer japConnectType (char str[])
{
    switch (str)
    {
    case 'cec':
    	return JAP_CONNECT_TYPE_CEC
    default:
	return JAP_CONNECT_TYPE_NONE
    }
}