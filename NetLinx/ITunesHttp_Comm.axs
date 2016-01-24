MODULE_NAME='ITunesHttp_Comm' (char configFile[], char tpConfigFile[])

// This iTunes module provides basic control over an iTunes server running
// the Apache and a very simple PHP module

// We also have to define local devices somewhere in order to receive data back from
// HTTP servers. We will use these in order, one per HTTP server.
DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT11 = 0:20:0
STUPID_AMX_REQUIREMENT12 = 0:21:0
STUPID_AMX_REQUIREMENT13 = 0:22:0
STUPID_AMX_REQUIREMENT14 = 0:23:0
STUPID_AMX_REQUIREMENT15 = 0:24:0
STUPID_AMX_REQUIREMENT16 = 0:25:0
STUPID_AMX_REQUIREMENT17 = 0:26:0
STUPID_AMX_REQUIREMENT18 = 0:27:0
STUPID_AMX_REQUIREMENT19 = 0:28:0
STUPID_AMX_REQUIREMENT20 = 0:29:0

DEFINE_VARIABLE
// This needs to be defined before the inclusion of HttpImpl.axi:
volatile dev gHttpLocalDvPool [] = { 
    STUPID_AMX_REQUIREMENT11, STUPID_AMX_REQUIREMENT12, STUPID_AMX_REQUIREMENT13,
    STUPID_AMX_REQUIREMENT14, STUPID_AMX_REQUIREMENT15, STUPID_AMX_REQUIREMENT16,
    STUPID_AMX_REQUIREMENT17, STUPID_AMX_REQUIREMENT18, STUPID_AMX_REQUIREMENT19,
    STUPID_AMX_REQUIREMENT20 }

DEFINE_VARIABLE
volatile char	DBG_MODULE[] = 'ITunes HTTP'


#include 'ITunesConfig.axi'
#include 'TouchPanelConfig.axi'
#include 'HttpImpl.axi'

DEFINE_CONSTANT

integer ITUNES_MAX_PLAYLISTS = 100
integer ITUNES_MAX_PLAYLIST_NAME_LEN = 100

DEFINE_VARIABLE

volatile char    ITUNES_SUPPORTED_CHANNEL_STRS[256][32] = {
    {'play'},				// 1
    {'stop'},				// 2
    {'pause'},				// 3
    {'nextTrack'},			// 4
    {'backTrack'},			// 5
    {'fastForward'},			// 6
    {'rewind'},			// 7
    {''},{''},{''},					// 8-10
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 11-20
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 21-30
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 31-40
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 41-50
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 51-60
    {''},{''},{''},					// 61-63
    {'getPlaylists'},					// 64
    {''},{''},{''},{''},{''},{''},			// 65-70
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 71-80
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 81-90
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 91-100
    {''},						// 101
    {'favorites'},					// 102
    {''},{''},{''},{''},{''},{''},{''},{''},		// 103-110
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

volatile char	     gAllPlaylists[ITUNES_MAX_PLAYLISTS][ITUNES_MAX_PLAYLIST_NAME_LEN]
volatile char	     gNpTitle[100]
volatile char	     gNpAlbumArtist[100]
volatile char	     gNpArtist[100]
volatile char	     gNpAlbum[100]
volatile char	     gNpGenre[100]
volatile integer     gNpRating
volatile integer     gNpYear

#include 'ITunesHttp_UI.axi'

DEFINE_VARIABLE

volatile dev	gDvHttpControl[MAX_HTTP_SERVERS]  // Array of devices for HTTP communication


DEFINE_FUNCTION initAllITunesImpl()
{
    integer httpId
    set_length_array (gHttpImpl, length_array(gITunes))
    for (httpId = 1; httpId <= length_array(gITunes); httpId++)
    {
	initHttpImpl (httpId, gHttpCfgs[httpId], 'GET /iTunes/control.php?q=', '')
    }
}

DEFINE_FUNCTION relayChannel (integer iTunesId, integer chan)
{
    char msg[32]
    msg = ITUNES_SUPPORTED_CHANNEL_STRS[chan]
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(chan),' (=><',msg,'>)'")
    if (msg != '')
    {
        sendHttp (gHttpCfgs[iTunesId], iTunesId, msg)
    }
}

DEFINE_FUNCTION handleHttpResponse (integer httpId, char msg[])
{
    // TO DO: handle different iTunes servers. Right now, events from different servers would be handled as
    // a single server. Need to match TPs to servers.
    select
    {
    active (find_string(msg,'PLAYLISTS:',1)):
    {
	integer  comma
	integer  count
	char     playlist[100]
	remove_string(msg,'PLAYLISTS:',1)
	comma = find_string(msg,',',1)
	set_length_array(gAllPlaylists,ITUNES_MAX_PLAYLISTS)
	while (comma > 0)
	{
	    count++
	    gAllPlaylists[count] = left_string (msg, comma-1)
	    debug (DBG_MODULE, 9, "'Found a playlist: ',gAllPlaylists[count]")
	    remove_string(msg,',',1)
	    comma = find_string(msg,',',1)
	}
	if (length_array(msg) > 0)
	{
	    count++
	    gAllPlaylists[count] = msg
	    debug (DBG_MODULE, 9, "'Found final playlist: ',gAllPlaylists[count]")
	}
	set_length_array(gAllPlaylists,count)
	doTpUpdatePlaylists()
    } // active 'PLAYLISTS:'

    active (find_string(msg,'NOW_PLAYING:',1)):
    {
	char field[100]
	integer tabCh
	remove_string(msg,'NOW_PLAYING:',1)
	while (length_array(msg) > 0)
	{
	    tabCh = find_string(msg,'	',1)
	    if (tabCh > 0)
	    {
		field = left_string(msg,tabCh-1) 
		remove_string(msg,'	',1)
	    }
	    else
	    {
	        field = msg
		set_length_array(msg,0)
	    }
	    select
	    {
	    active (find_string(field,'TITLE:',1)):
	    {
		remove_string(field,'TITLE:',1)
		gNpTitle = field
		debug (DBG_MODULE,9,"'found now playing title: ',gNpTitle")
	    }
	    active (find_string(field,'ALBUM_ARTIST:',1)):
	    {
		remove_string(field,'ALBUM_ARTIST:',1)
		gNpAlbumArtist = field
		debug (DBG_MODULE,9,"'found now playing album: ',gNpAlbumArtist")
	    }
	    active (find_string(field,'ARTIST:',1)):
	    {
		remove_string(field,'ARTIST:',1)
		gNpArtist = field
		debug (DBG_MODULE,9,"'found now playing artist: ',gNpArtist")
	    }
	    active (find_string(field,'ALBUM:',1)):
	    {
		remove_string(field,'ALBUM:',1)
		gNpAlbum = field
		debug (DBG_MODULE,9,"'found now playing album: ',gNpAlbum")
	    }
	    active (find_string(field,'GENRE:',1)):
	    {
		remove_string(field,'GENRE:',1)
		gNpGenre = field
		debug (DBG_MODULE,9,"'found now playing genre: ',gNpGenre")
	    }
	    active (find_string(field,'RATING:',1)):
	    {
		remove_string(field,'RATING:',1)
		gNpRating = atoi(field)
		debug (DBG_MODULE,9,"'found now playing rating: ',itoa(gNpRating)")
	    }
	    active (find_string(field,'YEAR:',1)):
	    {
		remove_string(field,'YEAR:',1)
		gNpYear = atoi(field)
		debug (DBG_MODULE,9,"'found now playing year: ',itoa(gNpYear)")
	    }
	    } // select
	} // while
	doTpUpdateNowPlaying()
    } // active 'NOW_PLAYING:'
    } // select
}

DEFINE_FUNCTION getPlaylists (integer iTunesId)
{
    sendHttp (gHttpCfgs[iTunesId], iTunesId, 'getPlaylists')
}

DEFINE_FUNCTION playPlaylist (integer iTunesId, integer playlistId)
{
    sendHttp (gHttpCfgs[iTunesId], iTunesId, "'playPlaylist&playlist=',itoa(playlistId)")
}

DEFINE_FUNCTION getNowPlaying (integer iTunesId)
{
    sendHttp (gHttpCfgs[iTunesId], iTunesId, 'nowPlaying')
}

DEFINE_EVENT

BUTTON_EVENT[gDvHttpControl, 0]
{
    PUSH:		{ relayChannel (get_last(gDvHttpControl), button.input.channel) }
    HOLD[3,REPEAT]:	{ relayChannel (get_last(gDvHttpControl), button.input.channel) }
    RELEASE:		{}
}

CHANNEL_EVENT[gDvHttpControl, 0]
{
    ON:			{ relayChannel (get_last(gDvHttpControl), channel.channel) }
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
    tpReadConfigFile ('ITunesConfig', tpConfigFile, gTpGeneral, gPanels)
    readConfigFile ('ITunesConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gPanels)),' panel definition(s)'")
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gITunes)),' iTunes server definition(s)'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'ITunesHttp_Comm module is enabled.'")
	setHttpDeviceList (gDvHttpControl, gHttpCfgs)
	initAllITunesImpl()
//	tpMakeLocalDevArray ('ITunesHttp_Comm', gDvTps ,             gPanels, gGeneral.mTpPort)
	tpMakeLocalDevArray ('ITunesHttp_Comm', gDvTpSelectPlaylist, gPanels, gGeneral.mTpPortPlaylistSelect)
	tpMakeLocalDevArray ('ITunesHttp_Comm', gDvTpNowPlaying,     gPanels, gGeneral.mTpPortNowPlaying)
    }
    else
    {
	debug (DBG_MODULE, 1, "'ITunesHttp_Comm module is disabled.'")
    }
    rebuild_event()
}

