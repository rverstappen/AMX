#include 'TouchPanel.axi'
#include 'TouchPanelPorts.axi'

DEFINE_CONSTANT

char    ITUNES_ADDRESS_PLAYLIST_LIST[]		= '1'

integer ITUNES_ADDRESS_NOW_PLAYING_TITLE	= 11
integer ITUNES_ADDRESS_NOW_PLAYING_ARTIST	= 12
integer ITUNES_ADDRESS_NOW_PLAYING_ALBUM	= 13
integer ITUNES_ADDRESS_NOW_PLAYING_ALBUM_ARTIST	= 14
integer ITUNES_ADDRESS_NOW_PLAYING_GENRE	= 15
integer ITUNES_ADDRESS_NOW_PLAYING_RATING	= 16
integer ITUNES_ADDRESS_NOW_PLAYING_YEAR		= 17
integer ITUNES_ADDRESS_NOW_PLAYING_ALBUM_ARTWORK= 31

DEFINE_VARIABLE

volatile dev dvTpSelectPlaylist[TP_MAX_PANELS]
volatile dev dvTpNowPlaying[TP_MAX_PANELS]

volatile integer gTpStatus[TP_MAX_PANELS]


DEFINE_FUNCTION doTpUpdatePlaylists ()
{
    integer tpId, iRidium, i
    for (tpId = 1; tpId <= TP_COUNT; tpId++)
    {
        iRidium = tpIsIridium(tpId)
	if (gTpStatus[tpId])
	{
	    debug (DBG_MODULE, 5, "'updating playlist list for TP ',itoa(tpId),'; numPlaylists=',
	    	  	itoa(length_array(gAllPlaylists))")
	    if (iRidium)
	    {
		// Set up iRidium's scrolling list
		send_command dvTpSelectPlaylist[tpId],"'IRLB_CLEAR-',       ITUNES_ADDRESS_PLAYLIST_LIST"
		send_command dvTpSelectPlaylist[tpId],"'IRLB_INDENT-',      ITUNES_ADDRESS_PLAYLIST_LIST,',3'"
		send_command dvTpSelectPlaylist[tpId],"'IRLB_SCROLL_COLOR-',ITUNES_ADDRESS_PLAYLIST_LIST,',Grey'"
		send_command dvTpSelectPlaylist[tpId],"'IRLB_ADD-',         ITUNES_ADDRESS_PLAYLIST_LIST,',',
			itoa(length_array(gAllPlaylists)),',1'"
	    }
	    for (i = 1; i <= length_array(gAllPlaylists); i++)
	    {
		debug (DBG_MODULE, 9, "'  adding playlist ',gAllPlaylists[i]")
		if (iRidium)
	    	{
		    send_command dvTpSelectPlaylist[tpId],"'IRLB_TEXT-',    ITUNES_ADDRESS_PLAYLIST_LIST,',',
		    		 itoa(i),',',gAllPlaylists[i]"
	    	    send_command dvTpSelectPlaylist[tpId],"'IRLB_CHANNEL-', ITUNES_ADDRESS_PLAYLIST_LIST,',',
				 itoa(i),',',itoa(TP_PORT_ITUNES_PLAYLIST_SELECT),',',itoa(i)"
		}
		else
	    	{
	   	    send_command dvTpSelectPlaylist[tpId],"'TEXT',itoa(i),'-',gAllPlaylists[i]"
	        }
	    }
	    if (!iRidium)
	    {
	        for (; i<= ITUNES_MAX_PLAYLISTS; i++)
	        {
		    send_command dvTpSelectPlaylist[tpId],"'TEXT',itoa(i),'-'"
	    	}
	    }
	}
    }    
}

DEFINE_FUNCTION doTpUpdateNowPlaying ()
{
    integer tpId
    for (tpId = 1; tpId <= TP_COUNT; tpId++)
    {
	if (gTpStatus[tpId])
	{
	    send_command dvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_TITLE),'-',gNpTitle"
	    send_command dvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_ARTIST),'-',gNpArtist"
	    send_command dvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_ALBUM),'-',gNpAlbum"
	    send_command dvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_GENRE),'-',gNpGenre"
	    if (gNpYear > 0)
	        send_command dvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_YEAR),'-',itoa(gNpYear)"
	    else
	        send_command dvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_YEAR),'-'"
	}
    }    
}

DEFINE_FUNCTION checkNowPlaying()
{
    // Only check if there are any TPs awake right now
    integer tpId
    for (tpId = 1; tpId <= TP_COUNT; tpId++)
    {
	if (gTpStatus[tpId])
	{
	    getNowPlaying()
	    return  // quit the for loop
	}
    }
}

DEFINE_EVENT

BUTTON_EVENT[dvTpSelectPlaylist, 0]
{
    PUSH: { playPlaylist(button.input.channel) }
}

DATA_EVENT[dvTpSelectPlaylist]
{
    ONLINE:  { gTpStatus[get_last(dvTpSelectPlaylist)] = 1; wait 39 { doTpUpdatePlaylists() } }
    OFFLINE: { gTpStatus[get_last(dvTpSelectPlaylist)] = 0 }
}


DEFINE_START

set_length_array (gTpStatus,	TP_COUNT)
{
    integer i
    set_length_array (dvTpSelectPlaylist,	TP_COUNT)
    set_length_array (dvTpNowPlaying,		TP_COUNT)
    for (i = 1; i <= TP_COUNT; i++)
    {
	tpMakeLocalDev (dvTpSelectPlaylist[i],	i, TP_PORT_ITUNES_PLAYLIST_SELECT)
	tpMakeLocalDev (dvTpNowPlaying[i],	i, TP_PORT_ITUNES_NOW_PLAYING)
    }
    rebuild_event()
}

wait 179 // 17.9 seconds after startup (something somewhat random!)
{
    // request the list of playlists
    getPlaylists()
}

DEFINE_PROGRAM

wait 151 // every 15.1 seconds
{
    checkNowPlaying()
}

wait 36398 // about every hour
{
    getPlaylists()
}