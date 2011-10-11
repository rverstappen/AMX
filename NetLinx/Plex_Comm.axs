MODULE_NAME='Plex_Comm' (char configFile[])

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
    {''},{''},{''},{''},				// 41-44
    {'navigation/moveUp'},				// 45
    {'navigation/moveDown'},				// 46
    {'navigation/moveLeft'},				// 47
    {'navigation/moveRight'},				// 48
    {'navigation/select'},				// 49
    {'navigation/back'},				// 50
    {'navigation/contextMenu'},				// 51
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 52-60
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


// We have to define the actual devices somewhere. This is a stupid AMX requirement.
DEFINE_DEVICE
STUPID_AMX_REQUIREMENT1 = 33021:1:1
STUPID_AMX_REQUIREMENT2 = 33021:2:1
STUPID_AMX_REQUIREMENT3 = 33021:3:1
STUPID_AMX_REQUIREMENT4 = 33021:4:1
STUPID_AMX_REQUIREMENT5 = 33021:5:1
STUPID_AMX_REQUIREMENT6 = 33021:6:1


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

DEFINE_FUNCTION handleHttpResponse (char msg[])
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

