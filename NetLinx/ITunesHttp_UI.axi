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

volatile TpCfgGeneral	gTpGeneral
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTpSelectPlaylist[TP_MAX_PANELS]
volatile dev		gDvTpNowPlaying[TP_MAX_PANELS]
volatile integer	gTpStatus[TP_MAX_PANELS]


DEFINE_FUNCTION doTpUpdatePlaylists ()
{
    integer tpId, iRidium, i
    for (tpId = 1; tpId <= length_array(gDvTpSelectPlaylist); tpId++)
    {
        iRidium = tpIsIridium(gPanels, tpId)
	if (gTpStatus[tpId])
	{
	    debug (DBG_MODULE, 5, "'updating playlist list for TP ',itoa(tpId),'; numPlaylists=',
	    	  	itoa(length_array(gAllPlaylists))")
	    if (iRidium)
	    {
		// Set up iRidium's scrolling list
		send_command gDvTpSelectPlaylist[tpId],"'IRLB_CLEAR-',       ITUNES_ADDRESS_PLAYLIST_LIST"
		send_command gDvTpSelectPlaylist[tpId],"'IRLB_INDENT-',      ITUNES_ADDRESS_PLAYLIST_LIST,',3'"
		send_command gDvTpSelectPlaylist[tpId],"'IRLB_SCROLL_COLOR-',ITUNES_ADDRESS_PLAYLIST_LIST,',Grey'"
		send_command gDvTpSelectPlaylist[tpId],"'IRLB_ADD-',         ITUNES_ADDRESS_PLAYLIST_LIST,',',
			itoa(length_array(gAllPlaylists)),',1'"
	    }
	    for (i = 1; i <= length_array(gAllPlaylists); i++)
	    {
		debug (DBG_MODULE, 9, "'  adding playlist ',gAllPlaylists[i]")
		if (iRidium)
	    	{
		    send_command gDvTpSelectPlaylist[tpId],"'IRLB_TEXT-',    ITUNES_ADDRESS_PLAYLIST_LIST,',',
		    		 itoa(i),',',gAllPlaylists[i]"
	    	    send_command gDvTpSelectPlaylist[tpId],"'IRLB_CHANNEL-', ITUNES_ADDRESS_PLAYLIST_LIST,',',
				 itoa(i),',',itoa(gGeneral.mTpPortPlaylistSelect),',',itoa(i)"
		}
		else
	    	{
	   	    send_command gDvTpSelectPlaylist[tpId],"'TEXT',itoa(i),'-',gAllPlaylists[i]"
	        }
	    }
	    if (!iRidium)
	    {
	        for (; i<= ITUNES_MAX_PLAYLISTS; i++)
	        {
		    send_command gDvTpSelectPlaylist[tpId],"'TEXT',itoa(i),'-'"
	    	}
	    }
	}
    }    
}

DEFINE_FUNCTION doTpUpdateNowPlaying ()
{
    integer tpId
    for (tpId = 1; tpId <= length_array(gDvTpNowPlaying); tpId++)
    {
	if (gTpStatus[tpId])
	{
	    send_command gDvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_TITLE),'-',gNpTitle"
	    send_command gDvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_ARTIST),'-',gNpArtist"
	    send_command gDvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_ALBUM),'-',gNpAlbum"
	    send_command gDvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_GENRE),'-',gNpGenre"
	    if (gNpYear > 0)
	        send_command gDvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_YEAR),'-',itoa(gNpYear)"
	    else
	        send_command gDvTpNowPlaying[tpId],"'TEXT',itoa(ITUNES_ADDRESS_NOW_PLAYING_YEAR),'-'"
	}
    }    
}

DEFINE_FUNCTION checkNowPlaying()
{
    // Only check if there are any TPs awake right now
    integer tpId
    for (tpId = 1; tpId <= length_array(gDvTpNowPlaying); tpId++)
    {
	if (gTpStatus[tpId])
	{
	    getNowPlaying(1)
	    return  // quit the for loop
	}
    }
}

DEFINE_EVENT

BUTTON_EVENT[gDvTpSelectPlaylist, 0]
{
    PUSH: { playPlaylist(1,button.input.channel) }
}

DATA_EVENT[gDvTpSelectPlaylist]
{
    ONLINE:  { gTpStatus[get_last(gDvTpSelectPlaylist)] = 1; wait 39 { doTpUpdatePlaylists() } }
    OFFLINE: { gTpStatus[get_last(gDvTpSelectPlaylist)] = 0 }
}


DEFINE_START

wait 179 // 17.9 seconds after startup (something somewhat random!)
{
    // request the list of playlists
    getPlaylists(1)
}

DEFINE_PROGRAM

wait 151 // every 15.1 seconds
{
    checkNowPlaying()
}

wait 36398 // about every hour
{
    getPlaylists(1)
}
