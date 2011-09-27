MODULE_NAME='Marantz_Comm' (char configFile[])

#include 'MarantzConfig.axi'

DEFINE_CONSTANT

char CR	= $0R

DEFINE_VARIABLE

volatile char DBG_MODULE[] = 'Marantz_Comm'
volatile char gBuf[1024]


DEFINE_EVENT

// Handle button events and pulses from other modules. 
// Channels correspond to the mId field of each MarantzControl.mDev
BUTTON_EVENT[mMarantzDevs, 0]
{
    PUSH: { handleMarantzControl (button.input.channel) }
}

DEFINE_FUNCTION handleMarantzControl (integer chan)
{
    
}

DEFINE_EVENT
DATA_EVENT[gGeneral.mDev]
{
    ONLINE:  { handleConnect() }
    OFFLINE: { handleDisconnect() }
    STRING: 
    {
	wait 20 // let the buffer receive the complete message
	{
	    if (handleMarantzResponse(gBuf))
	    {
	    	clear_buffer gBuf
	    }
	}
    }
    COMMAND: { debug (DBG_MODULE, 1, "'COMM device received command instead of string: ',data.text") }
    ONERROR: { debug (DBG_MODULE, 1, "'COMM device status code: ',itoa(data.number)") }
}

DEFINE_FUNCTION connect()
{
    debug (DBG_MODULE, 2, "'Opening TCP connection to ',gGeneral.mTelnetAddr")
    ip_client_open (gGeneral.mDev.port, gGeneral.mTelnetAddr, gGeneral.mTelnetPort, IP_TCP)
}

DEFINE_FUNCTION disconnect()
{
    debug (DBG_MODULE, 2, 'Closing connection')
    ip_client_close(gGeneral.mDev.port)
}

DEFINE_FUNCTION handleConnect()
{
    debug (DBG_MODULE, 2, "'Connection successful: ',devtoa(gGeneral.mDev)")
}

DEFINE_FUNCTION handleDisconnect()
{
    debug (DBG_MODULE, 2, 'telnet disconnected! Trying again in 30 seconds...')
    wait 300 { connect() }
}

DEFINE_FUNCTION integer handleMarantzResponse (char msg[])
{
    debug (DBG_MODULE, 8, "'Checking message(s) from Marantz: ',msg,'(',itoa(length_array(msg)),')'")
    while (find_string(msg,"CR",1))
    {
	select
    	{
    	active (1):
    	{
	    debug (DBG_MODULE, 2, "'Unhandled (partial?) message from Marantz: ',msg")
	    return 0
    	}
	} // select
	remove_string(msg,"CR",1)
    } // while
}

DEFINE_FUNCTION sendMarantzCommand (char cmd[])
{
    debug (DBG_MODULE, 7, "'sending Marantz command: ',cmd")
    send_string gGeneral.mDev, "cmd,CR"
}


DEFINE_START
{
    readConfigFile ('MarantzConfig', configFile)
    create_buffer gGeneral.mDev, gBuf
    rebuild_event()
    wait 43
    {
	connect()
    }
}

DEFINE_PROGRAM
wait 297 // 2971
{
    // keep the link to the Marantz alive by sending a blank string every 5 mins (approx)
    sendMarantzCommand ('')
}
