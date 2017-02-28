MODULE_NAME='LutronQs_Comm' (char configFileGeneral[])

#include 'LutronQsConfig.axi'

DEFINE_CONSTANT

char NEWLINE_TELNET[2]	= {$0D,$0A}
char NEWLINE_SERIAL	= $0D
char NEWLINE		= $0D
char TAB		= $09

DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT1 = 0:55:0
STUPID_AMX_REQUIREMENT2 = 0:56:0
STUPID_AMX_REQUIREMENT3 = 0:57:0
STUPID_AMX_REQUIREMENT4 = 0:58:0
STUPID_AMX_REQUIREMENT5 = 0:59:0

DEFINE_VARIABLE
volatile dev gLocalDvPool [] = { 
    STUPID_AMX_REQUIREMENT1, STUPID_AMX_REQUIREMENT2, STUPID_AMX_REQUIREMENT3,
    STUPID_AMX_REQUIREMENT4, STUPID_AMX_REQUIREMENT5 }

volatile char DBG_MODULE[] = 'LutronQs_Comm'
volatile char gBuf[1024]

DEFINE_EVENT

// Handle commands from other modules
DATA_EVENT[gGeneral.mDevControl]
{
    ONLINE:  {}
    OFFLINE: {}
    COMMAND:
    {
	debug (DBG_MODULE, 5, "'received Lutron control command from ',devtoa(data.device),': ',data.text")
	handleLutronCommand (data.text)
    }
    STRING:
    {
	debug (DBG_MODULE, 5, "'received Lutron control string from ',devtoa(data.device),': ',data.text")
    }
}

DEFINE_FUNCTION handleLutronCommand (char msg[])
{
    debug (DBG_MODULE, 9, "'Lutron pass-thru msg: ',msg")
    sendLutronCommand(msg)
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
	    if (handleReply(gBuf))
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

DEFINE_FUNCTION integer handleReply (char msg[])
{
    debug (DBG_MODULE, 8, "'Got message from Lutron: ',msg,'(',itoa(length_array(msg)),')'")
    select
    {
    active (find_string(msg,'login:',1)):
    {
	debug (DBG_MODULE, 2, 'Sending telnet login...')
	sendLutronCommand (gGeneral.mUsername)
	return 1
    }
    active (find_string(msg,'password:',1)):
    {
	debug (DBG_MODULE, 2, 'Sending telnet password...')
	sendLutronCommand (gGeneral.mPassword)
	return 1
    }
    active (find_string(msg,'QNET>',1)):
    {
	debug (DBG_MODULE, 2, "'Unhandled complete message from Lutron: ',msg")
	return 1
    }
    active (1):
    {
	debug (DBG_MODULE, 2, "'Unhandled (partial?) message from Lutron: ',msg")
	return 0
    }
    } // select
}

DEFINE_FUNCTION sendLutronCommand (char cmd[])
{
    debug (DBG_MODULE, 7, "'sending Lutron control command: ',cmd")
    send_string gGeneral.mDev, "cmd,NEWLINE_TELNET"
}


DEFINE_START
{
    readConfigFile ('LutronQsConfig', configFileGeneral)
    debug(DBG_MODULE,2,"'Finished reading configuration'")
    create_buffer gGeneral.mDev, gBuf
    rebuild_event()
    if (gGeneral.mEnabled)
    {
        wait 43
    	{
	    connect()
    	}
    }
}

DEFINE_PROGRAM
wait 297 // 2971
{
    // keep the link to the Lutron alive by sending a blank string every 5 mins (approx)
    if (gGeneral.mEnabled)
    {
        sendLutronCommand ('')
    }
}
