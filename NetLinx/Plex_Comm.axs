MODULE_NAME='Plex_Comm' (char configFile[])

// We also have to define local devices somewhere in order to receive data back from
// HTTP servers. We will use these in order, one per HTTP server.
DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT11 = 0:70:0
STUPID_AMX_REQUIREMENT12 = 0:71:0
STUPID_AMX_REQUIREMENT13 = 0:72:0
STUPID_AMX_REQUIREMENT14 = 0:73:0
STUPID_AMX_REQUIREMENT15 = 0:74:0
STUPID_AMX_REQUIREMENT16 = 0:75:0
STUPID_AMX_REQUIREMENT17 = 0:76:0
STUPID_AMX_REQUIREMENT18 = 0:77:0
STUPID_AMX_REQUIREMENT19 = 0:78:0
STUPID_AMX_REQUIREMENT20 = 0:79:0

DEFINE_VARIABLE
// This needs to be defined before the inclusion of HttpImpl.axi:
volatile dev gHttpLocalDv [] = { 
    STUPID_AMX_REQUIREMENT11, STUPID_AMX_REQUIREMENT12, STUPID_AMX_REQUIREMENT13,
    STUPID_AMX_REQUIREMENT14, STUPID_AMX_REQUIREMENT15, STUPID_AMX_REQUIREMENT16,
    STUPID_AMX_REQUIREMENT17, STUPID_AMX_REQUIREMENT18, STUPID_AMX_REQUIREMENT19,
    STUPID_AMX_REQUIREMENT20 }

DEFINE_VARIABLE
volatile char	DBG_MODULE[] = 'Plex'

#include 'PlexConfig.axi'
#include 'HttpImpl.axi'

DEFINE_VARIABLE

//volatile integer	PLEX_SUPPORTED_CHANNELS[] = {1,2,3,4,5,6,7,45,46,47,48,49,50,51,81,82,83,84,106,107}
volatile char    	PLEX_SUPPORTED_CHANNEL_STRS[256][32] = {
    {'playback/play'},					// 1
    {'playback/stop'},					// 2
    {'playback/pause'},					// 3
    {'playback/skipNext'},				// 4
    {'playback/skipPrevious'},				// 5
    {'playback/fastForward'},				// 6
    {'playback/rewind'},				// 7
    {''},{''},{''},					// 8-10
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 11-20
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 21-30
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 31-40
    {''},{''},{''},					// 41-43
    {'navigation/contextMenu'},				// 44
    {'navigation/moveUp'},				// 45
    {'navigation/moveDown'},				// 46
    {'navigation/moveLeft'},				// 47
    {'navigation/moveRight'},				// 48
    {'navigation/select'},				// 49
    {'navigation/back'},				// 50
    {''},{''},{''},{''},				// 51-54
    {'navigation/toggleOSD'},				// 55
    {''},{''},{''},{''},{''},				// 56-60
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 61-70
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 71-80
    {'playback/stepForward'},				// 81
    {'playback/stepBack'},				// 82
    {'playback/bigStepForward'},			// 83
    {'playback/bigStepBack'},				// 84
    {''},{''},{''},{''},{''},{''},			// 85-90
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 91-100
    {''},{''},{''},{''},{''},				// 101-105
    {'navigation/pageUp'},				// 106
    {'navigation/pageDown'},				// 107
    {''},{''},{''},					// 108-110
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
//    {'navigation/nextLetter'},
//    {'navigation/previousLetter'},
//    {'navigation/toggleOSD'},
}

// Array of devices for communication
volatile dev	gDvHttpControl[MAX_HTTP_SERVERS]


DEFINE_FUNCTION initAllPlexImpl()
{
    integer httpId
    set_length_array (gHttpImpl, length_array(gPlexs))
    for (httpId = 1; httpId <= length_array(gPlexs); httpId++)
    {
	initHttpImpl (httpId, gHttpCfgs[httpId], "'GET /system/players/',gPlexs[httpId].mPlayerName,'/'", '')
    }
}

DEFINE_FUNCTION plexRelayChannel (integer plexId, integer chan)
{
    char msg[32]
    msg = PLEX_SUPPORTED_CHANNEL_STRS[chan]
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(chan),' (=><',msg,'>)'")
    if (msg != '')
    {
        sendHttp (gHttpCfgs[plexId], plexId, msg)
    }
}

DEFINE_FUNCTION handleHttpResponse (integer httpId, char msg[])
{
    debug (DBG_MODULE, 8, "'got Plex response: ',msg")
}

DEFINE_EVENT

BUTTON_EVENT[gDvHttpControl, 0]
{
    PUSH:		{ plexRelayChannel (get_last(gDvHttpControl), push_channel) }
    HOLD[3,REPEAT]:	{ plexRelayChannel (get_last(gDvHttpControl), push_channel) }
    RELEASE:		{}
}

CHANNEL_EVENT[gDvHttpControl, 0]
{
    ON:			{ plexRelayChannel (get_last(gDvHttpControl), channel.channel) }
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
    readConfigFile ('PlexConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPlexs)),' Plex definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'Plex module is enabled.'")
	setHttpDeviceList (gDvHttpControl, gHttpCfgs)
	initAllPlexImpl()

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
	debug (DBG_MODULE, 1, "'Plex module is disabled.'")
    }
    rebuild_event()
}

