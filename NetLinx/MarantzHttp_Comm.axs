MODULE_NAME='MarantzHttp_Comm' (char configFile[])

// This Marantz module provides control over multiple Marantz receviers via their HTTP interface.

// We also have to define local devices somewhere in order to receive data back from
// HTTP servers. We will use these in order, one per HTTP server.
DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT1 = 0:40:0
STUPID_AMX_REQUIREMENT2 = 0:41:0
STUPID_AMX_REQUIREMENT3 = 0:42:0
STUPID_AMX_REQUIREMENT4 = 0:43:0
STUPID_AMX_REQUIREMENT5 = 0:44:0
STUPID_AMX_REQUIREMENT6 = 0:45:0
STUPID_AMX_REQUIREMENT7 = 0:46:0
STUPID_AMX_REQUIREMENT8 = 0:47:0
STUPID_AMX_REQUIREMENT9 = 0:48:0
STUPID_AMX_REQUIREMENT10 = 0:49:0

DEFINE_VARIABLE
// This needs to be defined before the inclusion of HttpImpl.axi:
volatile dev gHttpLocalDvPool [] = { 
    STUPID_AMX_REQUIREMENT1, STUPID_AMX_REQUIREMENT2, STUPID_AMX_REQUIREMENT3,
    STUPID_AMX_REQUIREMENT4, STUPID_AMX_REQUIREMENT5, STUPID_AMX_REQUIREMENT6,
    STUPID_AMX_REQUIREMENT7, STUPID_AMX_REQUIREMENT8, STUPID_AMX_REQUIREMENT9,
    STUPID_AMX_REQUIREMENT10 }

DEFINE_VARIABLE
volatile char	DBG_MODULE[] = 'Marantz'

#include 'MarantzConfig.axi'
#include 'HttpImpl.axi'

DEFINE_VARIABLE

volatile char    MARANTZ_SUPPORTED_CHANNEL_STRS[256][64] = {
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''}, // 1-10
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''}, // 11-20
    {''},{''},{''},					// 21-23
    {'PutMasterVolumeBtn%2F%3E'},			// 24
    {'PutMasterVolumeBtn%2F%3C'},			// 25
    {'PutVolumeMute%2Fon'},				// 26
    {'PutZone_OnOff%2FON'},				// 27
    {'PutZone_OnOff%2FOFF'},				// 28
    {''},{''},						// 29-30
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 31-40
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 41-50
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 51-60
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 61-70
    {'cmd0=PutZone_InputFunction%2FBD'},		// 71
    {'cmd0=PutZone_InputFunction%2FSAT'},		// 72
    {''},{''},{''},{''},{''},{''},{''},{''},		// 73-80
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 81-90
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 91-100
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 101-110
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 111-120
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 121-130
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 131-140
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 141-150
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 151-160
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 161-170
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 171-180
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 181-190
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 191-200
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 201-210
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 211-220
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 221-230
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 231-240
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 241-250
    {''},{''},{''},{''},{''},{''}			// 251-256
}

// Array of devices for communication
volatile dev	gDvHttpControl[MAX_HTTP_SERVERS]


DEFINE_FUNCTION initAllMarantzImpl()
{
    integer httpId
    set_length_array (gHttpImpl, length_array(gMarantzs))
    for (httpId = 1; httpId <= length_array(gMarantzs); httpId++)
    {
	initHttpImpl (httpId, gHttpCfgs[httpId], 'GET /MainZone/index.put.asp?cmd0=', '')
    }
}

DEFINE_FUNCTION marantzRelayChannel (integer marantzId, integer chan)
{
    char msg[64]
    msg = MARANTZ_SUPPORTED_CHANNEL_STRS[chan]
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(chan),' (=><',msg,'>)'")
    if (msg != '')
    {
        sendHttp (gHttpCfgs[marantzId], marantzId, msg)
    }
}

DEFINE_FUNCTION handleHttpResponse (integer httpId, char msg[])
{
    debug (DBG_MODULE, 8, "'got Marantz response: ',msg")
}

DEFINE_EVENT

BUTTON_EVENT[gDvHttpControl, 0]
{
    PUSH:		{ marantzRelayChannel (get_last(gDvHttpControl), button.input.channel) }
    HOLD[3,REPEAT]:	{ marantzRelayChannel (get_last(gDvHttpControl), button.input.channel) }
    RELEASE:		{}
}

CHANNEL_EVENT[gDvHttpControl, 0]
{
    ON:			{ marantzRelayChannel (get_last(gDvHttpControl), channel.channel) }
}

DATA_EVENT[gDvHttpControl]
{
    ONLINE:  {}
    OFFLINE: {}
    STRING:  {debug (DBG_MODULE, 9, "'got string: ',data.text")}
    COMMAND: {debug (DBG_MODULE, 9, "'got command: ',data.text")}
}


DEFINE_START
{
    readConfigFile ('MarantzConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gMarantzs)),' Marantz definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'Marantz module is enabled.'")
	setHttpDeviceList (gDvHttpControl, gHttpCfgs)
	initAllMarantzImpl()
    }
    else
    {
	debug (DBG_MODULE, 1, "'Marantz module is disabled.'")
    }
    rebuild_event()
}
