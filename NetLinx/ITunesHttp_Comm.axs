MODULE_NAME='ITunesHttp_Comm' (dev     dvHttpControl,
			       dev     dvHttpLocal,
			       char    httpIp[],
			       integer httpPort,
			       integer TP_COUNT)

// This iTunes module provides basic control over an iTunes server running
// the Apache and a very simple PHP module

#include 'Debug.axi'

DEFINE_CONSTANT

integer ITUNES_MAX_PLAYLISTS = 100
integer ITUNES_MAX_PLAYLIST_NAME_LEN = 100

DEFINE_DEVICE

DEFINE_TYPE

DEFINE_VARIABLE

volatile char    DBG_MODULE[] = 'iTunes HTTP'
volatile char    ITUNES_HTML_PREFIX[] = {'GET /iTunes/control.php?q='}
volatile char    ITUNES_HTML_SUFFIX[1024]
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

volatile char recvBuf[1024]
volatile char crlf[] = {$0D,$0A}

volatile char	     gAllPlaylists[ITUNES_MAX_PLAYLISTS][ITUNES_MAX_PLAYLIST_NAME_LEN]
volatile char	     gNpTitle[100]
volatile char	     gNpAlbumArtist[100]
volatile char	     gNpArtist[100]
volatile char	     gNpAlbum[100]
volatile char	     gNpGenre[100]
volatile integer     gNpRating
volatile integer     gNpYear

#include 'ITunesHttp_UI.axi'

DEFINE_LATCHING

DEFINE_MUTUALLY_EXCLUSIVE

DEFINE_FUNCTION sendToHttpServer (char msg[])
{
    ip_client_open (dvHttpLocal.PORT, httpIp, httpPort, IP_TCP)
    debug (DBG_MODULE, 8, "'sending Apache PHP iTunes message:',ITUNES_HTML_PREFIX,msg,ITUNES_HTML_SUFFIX")
    send_string dvHttpLocal, "ITUNES_HTML_PREFIX,msg,ITUNES_HTML_SUFFIX"
}

DEFINE_FUNCTION handleHttpResponse (char msg[])
{
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

DEFINE_FUNCTION getPlaylists()
{
    sendToHttpServer ('getPlaylists')
}

DEFINE_FUNCTION playPlaylist (integer id)
{
    sendToHttpServer ("'playPlaylist&playlist=',itoa(id)")
}

DEFINE_FUNCTION getNowPlaying()
{
    sendToHttpServer ('nowPlaying')
}

DEFINE_EVENT

BUTTON_EVENT[dvHttpControl, 0]
{
    PUSH:
    {
	stack_var char msg[32]
	msg = ITUNES_SUPPORTED_CHANNEL_STRS[PUSH_CHANNEL]
	debug (DBG_MODULE, 8, "'button press on channel ',itoa(PUSH_CHANNEL),' (',msg,')'")
	if (msg != '')
	{
	    sendToHttpServer (msg)
	}
    }
    HOLD[3,REPEAT]:
    {
    }
    RELEASE:
    {
    }
}

CHANNEL_EVENT[dvHttpControl, 0]
{
    ON:
    {
	stack_var char msg[32]
	msg = ITUNES_SUPPORTED_CHANNEL_STRS[CHANNEL.CHANNEL]
	if (msg != '')
	{
	    sendToHttpServer (msg)
	}
    }
}

DATA_EVENT[dvHttpControl]
{
    ONLINE:  {}
    OFFLINE: {}
    STRING:  {debug (DBG_MODULE, 9, "'got string: ',data.text")}
    COMMAND: {debug (DBG_MODULE, 9, "'got command: ',data.text")}
}

DATA_EVENT[dvHttpLocal]
{
    ONLINE: {}
    STRING:
    {
	handleHttpResponse (recvBuf)
	clear_buffer recvBuf
    }
    OFFLINE: {}
    ONERROR:
    {
	debug (DBG_MODULE, 1, "'TCP connection error: ',itoa(data.number)")
    }
}


DEFINE_START

debug (DBG_MODULE, 0, "'Starting Apache PHP iTunes request interface: ',httpIp,':',itoa(httpPort)")
ITUNES_HTML_SUFFIX = "' HTTP/1.0',crlf,'Host: ',httpIp,':',itoa(httpPort),crlf,'Connection: Keep-Alive',crlf,crlf"
recvBuf = ''
create_buffer dvHttpLocal, recvBuf

