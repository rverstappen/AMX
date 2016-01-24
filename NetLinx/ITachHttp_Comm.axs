MODULE_NAME='ITachHttp_Comm' (char configFile[])

// This iTach module provides control over multiple iTach IP2IR devices via their HTTP interface.

// We also have to define local devices somewhere in order to receive data back from
// HTTP servers. We will use these in order, one per HTTP server.
DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT1 = 0:100:0
STUPID_AMX_REQUIREMENT2 = 0:101:0
STUPID_AMX_REQUIREMENT3 = 0:102:0
STUPID_AMX_REQUIREMENT4 = 0:103:0
STUPID_AMX_REQUIREMENT5 = 0:104:0
STUPID_AMX_REQUIREMENT6 = 0:105:0
STUPID_AMX_REQUIREMENT7 = 0:106:0
STUPID_AMX_REQUIREMENT8 = 0:107:0
STUPID_AMX_REQUIREMENT9 = 0:108:0
STUPID_AMX_REQUIREMENT10 = 0:109:0

DEFINE_VARIABLE
// This needs to be defined before the inclusion of HttpImpl.axi:
volatile dev gHttpLocalDvPool [] = { 
    STUPID_AMX_REQUIREMENT1, STUPID_AMX_REQUIREMENT2, STUPID_AMX_REQUIREMENT3,
    STUPID_AMX_REQUIREMENT4, STUPID_AMX_REQUIREMENT5, STUPID_AMX_REQUIREMENT6,
    STUPID_AMX_REQUIREMENT7, STUPID_AMX_REQUIREMENT8, STUPID_AMX_REQUIREMENT9,
    STUPID_AMX_REQUIREMENT10 }

DEFINE_VARIABLE
volatile char	DBG_MODULE[] = 'ITach'

#include 'ITachConfig.axi'
#include 'HttpImpl.axi'

DEFINE_VARIABLE

volatile char    ITACH_SUPPORTED_CHANNEL_STRS[256][32] = {
    {'/version'},					// 1
    {'stop'},						// 2
    {'pause'},						// 3
    {''},{''},						// 4-5
    {'ffwd'},						// 6
    {'rew'},						// 7
    {'record'},						// 8
    {'power'},						// 9
    {'0'},						// 10
    {'1'},						// 11
    {'2'},						// 12
    {'3'},						// 13
    {'4'},						// 14
    {'5'},						// 15
    {'6'},						// 16
    {'7'},						// 17
    {'8'},						// 18
    {'9'},						// 19
    {''},						// 20
    {'enter'},						// 21
    {'chanup'},						// 22
    {'chandown'},					// 23
    {''},{''},{''},					// 24-26
    {'poweron'},					// 27
    {'poweroff'},					// 28
    {''},{''},						// 29-30
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 31-40
    {''},{''},						// 41-42
    {'back'},						// 43
    {'menu'},						// 44
    {'up'},						// 45
    {'down'},						// 46
    {'left'},						// 47
    {'right'},						// 48
    {'select'},						// 49
    {'exit'},						// 50
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 51-60
    {'list'},						// 61
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 62-70
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 71-80
    {'advance'},					// 81
    {'replay'},						// 82
    {''},{''},{''},{''},{''},{''},{''},{''},		// 83-90
    {''},{''},{''},{''},{''},				// 91-95
    {'dash'},						// 96
    {''},{''},{''},{''},				// 97-100
    {'info'},						// 101
    {''},{''},						// 102-103
    {'prev'},						// 104
    {'guide'},						// 105
    {''},{''},						// 106-107
    {'format'},						// 108
    {''},{''},						// 109-110
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 111-120
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 121-130
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 131-140
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 141-150
    {'yellow'},						// 151
    {'blue'},						// 152
    {'red'},						// 153
    {'green'},						// 154
    {''},{''},{''},{''},{''},{''},			// 155-160
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 161-170
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 171-180
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 181-190
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 191-200
    {'active'},						// 201
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 202-210
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 211-220
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 221-230
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 231-240
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 241-250
    {''},{''},{''},{''},{''},{''}			// 251-256
}

volatile dev	gDvHttpControl[MAX_HTTP_SERVERS]  // Array of devices for HTTP communication


DEFINE_FUNCTION initAllDtvImpl()
{
    integer httpId
    set_length_array (gHttpImpl, length_array(gDtvs))
    for (httpId = 1; httpId <= length_array(gDtvs); httpId++)
    {
	initHttpImpl (httpId, gHttpCfgs[httpId], 'GET /api/v1', '')
    }
}

DEFINE_FUNCTION dtvRelayChannel (integer dtvId, integer chan)
{
    char msg[32]
    msg = ITACH_SUPPORTED_CHANNEL_STRS[chan]
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(chan),' (=><',msg,'>)'")
    if (msg != '')
    {
        sendHttp (gHttpCfgs[dtvId], dtvId, msg)
    }
}

DEFINE_FUNCTION handleHttpResponse (integer httpId, char msg[])
{
    debug (DBG_MODULE, 8, "'got iTach response: ',msg")
}

DEFINE_EVENT

BUTTON_EVENT[gDvHttpControl, 0]
{
    PUSH:		{ dtvRelayChannel (get_last(gDvHttpControl), button.input.channel) }
    HOLD[3,REPEAT]:	{ dtvRelayChannel (get_last(gDvHttpControl), button.input.channel) }
    RELEASE:		{}
}

CHANNEL_EVENT[gDvHttpControl, 0]
{
    ON:			{ dtvRelayChannel (get_last(gDvHttpControl), channel.channel) }
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
    readConfigFile ('ITachConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gDtvs)),' iTach definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'iTach module is enabled.'")
	setHttpDeviceList (gDvHttpControl, gHttpCfgs)
	initAllDtvImpl()
    }
    else
    {
	debug (DBG_MODULE, 1, "'iTach module is disabled.'")
    }
    rebuild_event()
}
