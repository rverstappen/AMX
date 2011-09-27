MODULE_NAME='IpControlledDevices_Comm' ()

#include 'IpControlledDeviceConfig.axi'

DEFINE_VARIABLE

volatile char DBG_MODULE[] = 'IpControlledDevices_Comm'
volatile char gBuf[IP_DEV_MAX_DEVICES][256]

DEFINE_EVENT

// Handle button events and pulses from other modules. 
BUTTON_EVENT[gVdvControl, 0]
{
    PUSH:		{ handleDeviceControl (get_last(gVdvControl), button.input.channel) }
    RELEASE:		{}
    HOLD[3,REPEAT]:	{}
}

// Handle button events and pulses from other modules. 
CHANNEL_EVENT[gVdvControl, 0]
{
    ON:	{ handleDeviceControl (get_last(gVdvControl), channel.channel) }
}

DEFINE_FUNCTION handleDeviceControl (integer id, integer chan)
{
    sendIpControlledDeviceCommand (gIpDevices[id].mDevIp,
	"gIpDevices[id].mCommandPrefix,gIpDevices[id].mCommandByChannel[chan],gIpDevices[id].mCommandSep")
}

DEFINE_FUNCTION sendIpControlledDeviceCommand (dev dv, char cmd[])
{
    debug (DBG_MODULE, 7, "'sending IpControlledDevices command to ',devtoa(dv),': ',cmd")
    send_string dv, "cmd"
}

DEFINE_EVENT
DATA_EVENT[gVdvIp]
{
    ONLINE:  { handleConnect(get_last(gVdvIp)) }
    OFFLINE: { handleDisconnect(get_last(gVdvIp)) }
    STRING: 
    {
	integer id
	id = get_last(gVdvIp)
	if (handleIpDeviceResponse(id,gBuf[id]))
	{
	    clear_buffer gBuf[id]
	}
    }
    COMMAND: { debug (DBG_MODULE, 1, "'COMM device received command instead of string: ',data.text") }
    ONERROR:
    {
	debug (DBG_MODULE, 1, "'COMM device status code: ',itoa(data.number)"); 
    	wait 300 { connect(get_last(gVdvIp)) }
    }
}

DEFINE_FUNCTION connect (integer id)
{
    debug (DBG_MODULE, 2, "'Opening TCP connection to ',gIpDevices[id].mTelnetAddr")
    ip_client_open (gIpDevices[id].mDevIp.port,
    		    gIpDevices[id].mTelnetAddr,
		    gIpDevices[id].mTelnetPort, IP_TCP)
}

DEFINE_FUNCTION disconnect (integer id)
{
    debug (DBG_MODULE, 2, 'Closing connection')
    ip_client_close (gIpDevices[id].mDevIp.port)
}

DEFINE_FUNCTION handleConnect (integer id)
{
    debug (DBG_MODULE, 2, "'Connection successful: ',devtoa(gIpDevices[id].mDevIp)")
}

DEFINE_FUNCTION handleDisconnect (integer id)
{
    debug (DBG_MODULE, 2, "'telnet disconnected for ',devtoa(gIpDevices[id].mDevIp),
    	  	       	   '! Trying again in 30 seconds...'")
    wait 300 { connect(id) }
}

DEFINE_FUNCTION integer handleIpDeviceResponse (integer id, char msg[])
{
    debug (DBG_MODULE, 8, "'Checking message(s) from IpControlledDevice (',itoa(id),'): ',msg,'(',itoa(length_array(msg)),')'")
    while (find_string(msg,gIpDevices[id].mCommandSep,1))
    {
	select
    	{
    	active (1):
    	{
	    debug (DBG_MODULE, 2, "'Unhandled (partial?) message from IpControlledDevices: ',msg")
	    return 0
    	}
	} // select
	remove_string(msg,gIpDevices[id].mCommandSep,1)
    } // while
    return 1
}


DEFINE_START
{
    local_var integer id
    readConfigFile ('IpControlledDevicesConfig', 'IpDevices.cfg')
    for (id = 1; id <= length_array(gIpDevices); id++)
    {
	create_buffer gIpDevices[id].mDevIp, gBuf[id]
    }
debug(DBG_MODULE,9,"'num control devices: ',itoa(length_array(gVdvControl))")
debug(DBG_MODULE,9,"'1. gVdvControl[1]: ',devtoa(gVdvControl[1])")
    gVdvControl[1] = 33041:1:0
debug(DBG_MODULE,9,"'2. gVdvControl[1]: ',devtoa(gVdvControl[1])")
    rebuild_event()
    wait 43
    {
	for (id = 1; id <= length_array(gIpDevices); id++)
	{
	    connect(id)
	}
    }
}
