MODULE_NAME='DirecTvHttp_Comm' (char configFile[])

// This DirecTV module provides control over multiple DirecTV servers via their HTTP interface.

DEFINE_VARIABLE
volatile char	DBG_MODULE[] = 'DirecTV'

#include 'DirecTvConfig.axi'
#include 'HttpImpl.axi'

DEFINE_VARIABLE

volatile char    DIRECTV_SUPPORTED_CHANNEL_STRS[256][32] = {
    {'play'},						// 1
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
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 201-210
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 211-220
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 221-230
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 231-240
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 241-250
    {''},{''},{''},{''},{''},{''}			// 251-256
}

// Array of devices for communication
volatile dev	gDvHttpControl[MAX_HTTP_SERVERS]


// We have to define the actual devices somewhere. This is a stupid AMX requirement.
DEFINE_DEVICE
STUPID_AMX_REQUIREMENT1  = 33031:1:1
STUPID_AMX_REQUIREMENT2  = 33031:2:1
STUPID_AMX_REQUIREMENT3  = 33031:3:1
STUPID_AMX_REQUIREMENT4  = 33031:4:1
STUPID_AMX_REQUIREMENT5  = 33031:5:1
STUPID_AMX_REQUIREMENT6  = 33031:6:1
STUPID_AMX_REQUIREMENT7  = 33031:7:1
STUPID_AMX_REQUIREMENT8  = 33031:8:1
STUPID_AMX_REQUIREMENT9  = 33031:9:1
STUPID_AMX_REQUIREMENT10 = 33031:10:1
STUPID_AMX_REQUIREMENT11 = 33031:11:1
STUPID_AMX_REQUIREMENT12 = 33031:12:1


DEFINE_FUNCTION initAllDtvImpl()
{
    integer httpId
    set_length_array (gHttpImpl, length_array(gDtvs))
    for (httpId = 1; httpId <= length_array(gDtvs); httpId++)
    {
	initHttpImpl (httpId, gHttpCfgs[httpId], 'GET /remote/processKey?key=', '&hold=keyPress')
    }
}

DEFINE_FUNCTION dtvRelayChannel (integer dtvId, integer chan)
{
    char msg[32]
    msg = DIRECTV_SUPPORTED_CHANNEL_STRS[chan]
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(chan),' (=><',msg,'>)'")
    if (msg != '')
    {
        sendHttp (gHttpCfgs[dtvId], dtvId, msg)
    }
}

DEFINE_FUNCTION handleHttpResponse (char msg[])
{
    debug (DBG_MODULE, 8, "'got DirecTV response: ',msg")
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
    readConfigFile ('DirecTvConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gDtvs)),' DirecTV definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'DirecTV module is enabled.'")
	setHttpDeviceList (gDvHttpControl, gHttpCfgs)
	initAllDtvImpl()

	// For some (AMX) reason, create_buffer must be called directly in DEFINE_START
	{    integer httpId
	    for (httpId = 1; httpId <= length_array(gHttpLocalDv); httpId++)
	    {
	    	create_buffer gHttpLocalDv[httpId], gHttpImpl[httpId].mRecvBuf
	    }
	}
    }
    else
    {
	debug (DBG_MODULE, 1, "'DirecTV module is disabled.'")
    }
    rebuild_event()
}
