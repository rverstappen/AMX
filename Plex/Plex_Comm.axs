MODULE_NAME='Plex_Comm' (dev     dvPlexControl,
			 dev     dvPlexLocal,
			 char    plexMediaServerIp[],
			 integer plexMediaServerPort,
			 char    plexMediaPlayerName[])

DEFINE_VARIABLE

volatile gDebugLevel = 10
volatile char    PLEX_HTML_PREFIX[] = {'GET /system/players/'}
volatile char    PLEX_HTML_SUFFIX[1024]
//volatile integer PLEX_SUPPORTED_CHANNELS[] = {1,2,3,4,5,6,7,45,46,47,48,49,50,51,85,86}
volatile char    PLEX_SUPPORTED_CHANNEL_STRS[256][32] = {
    {'playback/play'},			// 1
    {'playback/stop'},			// 2
    {'playback/pause'},			// 3
    {'playback/skipNext'},		// 4
    {'playback/skipPrevious'},		// 5
    {'playback/fastForward'},		// 6
    {'playback/rewind'},		// 7
    {''},{''},{''},					// 8-10
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 11-20
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 21-30
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 31-40
    {''},{''},{''},{''},				// 41-44
    {'navigation/moveUp'},		// 45
    {'navigation/moveDown'},		// 46
    {'navigation/moveLeft'},		// 47
    {'navigation/moveRight'},		// 48
    {'navigation/select'},		// 49
    {'navigation/back'},		// 50
    {'navigation/contextMenu'},		// 51
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 52-60
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 61-70
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 71-80
    {'playback/stepForward'},		// 81
    {'playback/stepBack'},		// 82
    {'playback/bigStepForward'},	// 83
    {'playback/bigStepBack'},		// 84
    {''},{''},{''},{''},{''},{''},			// 85-90
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 91-100
    {''},{''},{''},{''},{''},				// 101-105
    {'navigation/pageUp'},		// 106
    {'navigation/pageDown'},		// 107
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

volatile char plexRecvBuf[1024]
volatile char crlf[] = {$0D,$0A}

DEFINE_FUNCTION debug (integer dbgLevel, char msg[]) //Debug messages
{
    if ((dbgLevel = 0) || ((gDebugLevel > 0) && (dbgLevel <= gDebugLevel)))
    {
        send_string 0, "'Plex_Comm: ',msg"
    }
}

DEFINE_FUNCTION sendToPlex (char msg[])
{
    ip_client_open (dvPlexLocal.PORT, plexMediaServerIp, plexMediaServerPort, IP_TCP)
    debug (8, "'sending Plex message:',PLEX_HTML_PREFIX,plexMediaPlayerName,'/',msg,PLEX_HTML_SUFFIX")
    send_string dvPlexLocal, "PLEX_HTML_PREFIX,plexMediaPlayerName,'/',msg,PLEX_HTML_SUFFIX"
}


DEFINE_START

debug (0, "'Starting Plex interface: ',plexMediaServerIp,':',itoa(plexMediaServerPort)")
PLEX_HTML_SUFFIX = "' HTTP/1.0',crlf,'Host: ',plexMediaServerIp,':',itoa(plexMediaServerPort),crlf,'Connection: Keep-Alive',crlf,crlf"
plexRecvBuf = ''
create_buffer dvPlexLocal, plexRecvBuf
// Delay connection until we need to send something

DEFINE_EVENT

BUTTON_EVENT[dvPlexControl, 0]
{
    PUSH:
    {
	stack_var char plexMsg[32]
	plexMsg = PLEX_SUPPORTED_CHANNEL_STRS[PUSH_CHANNEL]
	debug (5, "'button press on channel ',itoa(PUSH_CHANNEL),' (',plexMsg,')'")
	if (plexMsg != '')
	{
	    sendToPlex (plexMsg)
	}
    }
    HOLD[3,REPEAT]:
    {
    }
    RELEASE:
    {
    }
}

CHANNEL_EVENT[dvPlexControl, 0]
{
    ON:
    {
	stack_var char plexMsg[32]
	plexMsg = PLEX_SUPPORTED_CHANNEL_STRS[CHANNEL.CHANNEL]
	if (plexMsg != '')
	{
	    sendToPlex (plexMsg)
	}
    }
}

DATA_EVENT[dvPlexControl]
{
    ONLINE:  {}
    OFFLINE: {}
    STRING:  {debug (9, "'got string: ',data.text")}
    COMMAND: {debug (9, "'got command: ',data.text")}
}

DATA_EVENT[dvPlexLocal]
{
    ONLINE:
    {
	debug (9, 'Plex TCP connection OK')
    }
    STRING:
    {
	debug (5, "'Plex received string from server: ',plexRecvBuf")
	plexRecvBuf = ''
	clear_buffer plexRecvBuf
    }
    OFFLINE:
    {
	debug (7, 'Plex TCP connection closed')
    }
    ONERROR:
    {
	debug (1, "'Plex TCP connection error: ',itoa(data.number)")
    }
}

DEFINE_PROGRAM
