MODULE_NAME='Roku_Comm' (char configFile[])

// We also have to define local devices somewhere in order to receive data back from
// HTTP servers. We will use these in order, one per HTTP server.
DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT11 = 0:80:0
STUPID_AMX_REQUIREMENT12 = 0:81:0
STUPID_AMX_REQUIREMENT13 = 0:82:0
STUPID_AMX_REQUIREMENT14 = 0:83:0
STUPID_AMX_REQUIREMENT15 = 0:84:0
STUPID_AMX_REQUIREMENT16 = 0:85:0
STUPID_AMX_REQUIREMENT17 = 0:86:0
STUPID_AMX_REQUIREMENT18 = 0:87:0
STUPID_AMX_REQUIREMENT19 = 0:88:0
STUPID_AMX_REQUIREMENT20 = 0:89:0

DEFINE_VARIABLE
// This needs to be defined before the inclusion of HttpImpl.axi:
volatile dev gHttpLocalDvPool [] = { 
    STUPID_AMX_REQUIREMENT11,
    STUPID_AMX_REQUIREMENT12,
    STUPID_AMX_REQUIREMENT13,
    STUPID_AMX_REQUIREMENT14,
    STUPID_AMX_REQUIREMENT15,
    STUPID_AMX_REQUIREMENT16,
    STUPID_AMX_REQUIREMENT17,
    STUPID_AMX_REQUIREMENT18,
    STUPID_AMX_REQUIREMENT19,
    STUPID_AMX_REQUIREMENT20 }

DEFINE_VARIABLE
volatile char	DBG_MODULE[] = 'Roku'

#include 'RokuConfig.axi'
#include 'HttpImpl.axi'

DEFINE_VARIABLE

volatile char    	ROKU_SUPPORTED_CHANNEL_STRS[256][32] = {
    {'keypress/Play'},					// 1
    {'keypress/Stop'},					// 2
    {'keypress/Pause'},					// 3
    {''},{''},						// 4,5
    {'keypress/Fwd'},					// 6
    {'keypress/Rev'},					// 7
    {''},{''},{''},					// 8-10
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 11-20
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 21-30
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 31-40
    {''},{''},{''},					// 41-43
    {'keypress/Home'},					// 44
    {'keypress/Up'},					// 45
    {'keypress/Down'},					// 46
    {'keypress/Left'},					// 47
    {'keypress/Right'},					// 48
    {'keypress/Select'},				// 49
    {'keypress/Back'},					// 50
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 51-60
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 61-70
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 71-80
    {''},						// 81
    {'keypress/InstantReplay'},				// 82
    {''},{''},						// 83-84
    {'keypress/Play'},					// 85		(Play-Pause combo)
    {''},{''},{''},{''},{''},				// 86-90
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 91-100
    {'keypress/Info'},					// 101
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 102-110
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
//    {'keypress/Backspace'},
//    {'keypress/Search'},
//    {'keypress/Enter'},
//    {'keypress/Lit_*'},
}

// Array of devices for communication
volatile dev	gDvHttpControl[MAX_HTTP_SERVERS]


DEFINE_FUNCTION initAllRokuImpl()
{
    integer httpId
    set_length_array (gHttpImpl, length_array(gRokus))
    for (httpId = 1; httpId <= length_array(gRokus); httpId++)
    {
	initHttpImpl (httpId, gHttpCfgs[httpId], "'POST /'", '')
    }
}

DEFINE_FUNCTION rokuRelayChannel (integer rokuId, integer chan)
{
    char msg[32]
    msg = ROKU_SUPPORTED_CHANNEL_STRS[chan]
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(chan),' (=><',msg,'>)'")
    if (msg != '')
    {
        sendHttp (gHttpCfgs[rokuId], rokuId, msg)
    }
}

DEFINE_FUNCTION handleHttpResponse (integer httpId, char msg[])
{
    debug (DBG_MODULE, 8, "'got Roku response: ',msg")
}

DEFINE_EVENT

BUTTON_EVENT[gDvHttpControl, 0]
{
    PUSH:		{ rokuRelayChannel (get_last(gDvHttpControl), push_channel) }
    HOLD[3,REPEAT]:	{ rokuRelayChannel (get_last(gDvHttpControl), push_channel) }
    RELEASE:		{}
}

CHANNEL_EVENT[gDvHttpControl, 0]
{
    ON:			{ rokuRelayChannel (get_last(gDvHttpControl), channel.channel) }
}

DATA_EVENT[gDvHttpControl]
{
    ONLINE:  {debug (DBG_MODULE, 9, "'online: '")}
    OFFLINE: {debug (DBG_MODULE, 9, "'offline: '")}
    STRING:  {debug (DBG_MODULE, 9, "'got string: ',data.text")}
    COMMAND: {debug (DBG_MODULE, 9, "'got command: ',data.text")}
}

DEFINE_START
{
    readConfigFile ('RokuConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gRokus)),' Roku definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'Roku module is enabled.'")
	setHttpDeviceList (gDvHttpControl, gHttpCfgs)
	initAllRokuImpl()
    }
    else
    {
	debug (DBG_MODULE, 1, "'Roku module is disabled.'")
    }
    rebuild_event()
}

