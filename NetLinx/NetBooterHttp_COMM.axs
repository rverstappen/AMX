MODULE_NAME='NetBooterHttp_Comm' (char configFile[])

// We have to define the actual virtual devices somewhere, not just in config 
// files. This is a stupid AMX requirement. At least by declaring a virtual
// device with port 1, the virtual devices for all the other ports wil work.
// For example, declaring 33031:1:0 will also enable  33031:2:0, 33031:3:0,
// etc. So, here we actually have 1,000s of virtual devices that we can use
// in configuration files.  
// BTW: I call this stupid because not only is this requirement inconvenient,
// it is also inconsistent. It's OK not to define real
// devices, like 5001:1:1 -- unless they are remote devices, like 5001:1:2.
// All this implementation-dependent nonsense should really be under the
// NetLinx hood.
DEFINE_DEVICE
STUPID_AMX_REQUIREMENT1  = 33060:1:0	// and 33060:2:0, 33060:3:0, etc.
STUPID_AMX_REQUIREMENT2  = 33061:1:0	// and ...
STUPID_AMX_REQUIREMENT3  = 33062:1:0	// and ...
STUPID_AMX_REQUIREMENT4  = 33063:1:0
STUPID_AMX_REQUIREMENT5  = 33064:1:0
STUPID_AMX_REQUIREMENT6  = 33065:1:0
STUPID_AMX_REQUIREMENT7  = 33066:1:0
STUPID_AMX_REQUIREMENT8  = 33067:1:0
STUPID_AMX_REQUIREMENT9  = 33068:1:0
STUPID_AMX_REQUIREMENT10 = 33069:1:0

// We also have to define local devices somewhere in order to receive data back from
// HTTP servers. We will use these in order, one per HTTP server.
DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT11 = 0:60:0
STUPID_AMX_REQUIREMENT12 = 0:61:0
STUPID_AMX_REQUIREMENT13 = 0:62:0
STUPID_AMX_REQUIREMENT14 = 0:63:0
STUPID_AMX_REQUIREMENT15 = 0:64:0
STUPID_AMX_REQUIREMENT16 = 0:65:0
STUPID_AMX_REQUIREMENT17 = 0:66:0
STUPID_AMX_REQUIREMENT18 = 0:67:0
STUPID_AMX_REQUIREMENT19 = 0:68:0
STUPID_AMX_REQUIREMENT20 = 0:69:0

DEFINE_VARIABLE
// This needs to be defined before the inclusion of HttpImpl.axi:
volatile dev gHttpLocalDvPool [] = { 
    STUPID_AMX_REQUIREMENT11, STUPID_AMX_REQUIREMENT12, STUPID_AMX_REQUIREMENT13,
    STUPID_AMX_REQUIREMENT14, STUPID_AMX_REQUIREMENT15, STUPID_AMX_REQUIREMENT16,
    STUPID_AMX_REQUIREMENT17, STUPID_AMX_REQUIREMENT18, STUPID_AMX_REQUIREMENT19,
    STUPID_AMX_REQUIREMENT20 }

DEFINE_VARIABLE
volatile char	DBG_MODULE[] = 'netBooter'

#include 'NetBooterConfig.axi'
#include 'HttpImpl.axi'
#include 'ChannelDefs.axi'

DEFINE_VARIABLE

// Array of devices for communication
volatile	dev	gDvControl[MAX_NETBOOTER_PORTS]
volatile	integer gNetbooterByDv[MAX_NETBOOTER_PORTS]
non_volatile	integer	gPortState[MAX_NETBOOTERS][MAX_NETBOOTER_PORTS_PER_DEVICE]

DEFINE_FUNCTION setNetBooterDeviceList ()
{
    integer i, j, count
    count = 0
    for (i = 1; i <= length_array(gNetBooters); i++)
    {
	set_length_array (gDvControl, length_array(gDvControl) + gNetBooters[i].mNumPorts)
	for (j = 1; j <= gNetBooters[i].mNumPorts; j++)
	{
	    count++
	    gNetbooterByDv[count] = i
	    gDvControl[count] = gHttpCfgs[i].mDevControl.Number:j:0
	    debug (DBG_MODULE, 5, "'Added control device: ',devtoa(gDvControl[count])")
	}
    }
}

DEFINE_FUNCTION initAllNetBooterImpl()
{
    integer httpId
    set_length_array (gHttpImpl, length_array(gNetBooters))
    for (httpId = 1; httpId <= length_array(gNetBooters); httpId++)
    {
	initHttpImpl (httpId, gHttpCfgs[httpId], "'GET /cmd.cgi?'", '')
    }
}

DEFINE_FUNCTION netBooterRelayChannel (integer netBooterId, integer portNum, integer chan)
{
    char msg[32]
    switch (chan)
    {
    case CHAN_POWER_ON:		msg = "'$A3%20',itoa(portNum),'%201'"
    case CHAN_POWER_OFF:	msg = "'$A3%20',itoa(portNum),'%200'"
    }
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(chan),' (=><',msg,'>)'")
    if (msg != '')
    {
        sendHttp (gHttpCfgs[netBooterId], netBooterId, msg)
    }
}

DEFINE_FUNCTION sendStatusRequestAll()
{
    integer i
    for (i = 1; i <= length_array(gHttpCfgs); i++)
    {
	sendStatusRequest(i)
    }
}

DEFINE_FUNCTION sendStatusRequest (integer netBooterId)
{
    sendHttp (gHttpCfgs[netBooterId], netBooterId, '$A5')
}

DEFINE_FUNCTION handleHttpResponse (integer netBooterId, char msg[])
{
    debug (DBG_MODULE, 8, "'got NetBooter response: ',msg")
    remove_string (msg, "crlf,crlf",1)
    select
    {
    active (find_string(msg,'$A0,',1)): // comma in message
    {
	// Received a status update.
	// Note: port 1 is last in status message, so we need to reverse processing
	integer portId, len
	remove_string (msg,'$A0,',1)
	len = find_string(msg,',',1) - 1
	msg = left_string (msg, len)
	debug (DBG_MODULE, 8, "'Port status received: ',msg")
	for (portId = 1;
	     (portId <= gNetBooters[netBooterId].mNumPorts) && (len > 0); 
	     portId++, len--)
	{
	    updatePortStatus (netBooterId, portId, (msg[len] = '1'))
	}
    }
    active (find_string(msg,'$A0',1)):  // no comma in message
    {
	// Received an OK, send a request for status
	debug (DBG_MODULE, 8, "'Status OK; requesting ON/OFF status...'")
	sendStatusRequest (netBooterId)
    }
    active (find_string(msg,'$AF',1)):  // no comma in message
    {
	// Received an error
	debug (DBG_MODULE, 3, "'Received error status: ',msg")
    }
    active (1):
    {
	debug (DBG_MODULE, 3, "'Unknown message: ',msg")
    }
    } // select
}

DEFINE_FUNCTION updatePortStatus (integer netBooterId, integer portId, integer status)
{
    debug (DBG_MODULE, 9,
    	   "'Updating channel status of ',gNetBooters[netBooterId].mName,' / ',
	   gNetBooters[netBooterId].mPortNames[portId],': ',itoa(status)")
    gPortState[netBooterId][portId] = status
    [gHttpCfgs[netBooterId].mDevControl.Number:portId:0, 1] = status

}

DEFINE_EVENT

(*
BUTTON_EVENT[gDvControl, 0]
{
    PUSH:
    {
	netBooterRelayChannel (gNetbooterByDv[get_last(gDvControl)],
			       button.input.device.port,
			       button.input.channel)
    }
    RELEASE: {}
}
*)

CHANNEL_EVENT[gDvControl, 0]
{
    ON:
    {
	netBooterRelayChannel (gNetbooterByDv[get_last(gDvControl)],
			       channel.device.port,
			       channel.channel)
    }
}

DATA_EVENT[gDvControl]
{
    ONLINE:  {debug (DBG_MODULE, 9, "'[control] online: '")}
    OFFLINE: {debug (DBG_MODULE, 9, "'[control] offline: '")}
    STRING:  {debug (DBG_MODULE, 9, "'[control] got string: ',data.text")}
    COMMAND: { handleCommand (gNetbooterByDv[get_last(gDvControl)],data.device.port,data.text) }
}

DEFINE_FUNCTION handleCommand (integer netBooterId, integer portNum, char cmd[])
{
    debug (DBG_MODULE, 5, "'handling command: ', cmd")
    select
    {
    active (find_string(cmd,'POWER=>',1)):
    {
	integer onOff
	remove_string(cmd,'POWER=>',1)
	select
	{
	active ((cmd[1] = '0') || (find_string(cmd,'OFF',1))):
	{
	    netBooterRelayChannel (netBooterId, portNum, CHAN_POWER_OFF)
	}
	active ((cmd[1] = '1') || (find_string(cmd,'ON',1))):
	{
	    netBooterRelayChannel (netBooterId, portNum, CHAN_POWER_ON)
	}
	active (1):
	{
	    debug (DBG_MODULE, 3, "'unknown POWER command: ',cmd")
        }
	} // select
    }
    active (1):
    {
	debug (DBG_MODULE, 2, "'UNHANDLED command: ', cmd")
    }
    } // select
}

DEFINE_START
{
    readConfigFile ('NetBooterConfig', configFile)
    debug (DBG_MODULE, 1, "'Read ',itoa(length_array(gNetBooters)),' NetBooter definitions'")
    if (gGeneral.mEnabled)
    {
	debug (DBG_MODULE, 1, "'NetBooter module is enabled.'")
	setNetBooterDeviceList()
	initAllNetBooterImpl()
	USE_HTTP_QUEUE = 1
    }
    else
    {
	debug (DBG_MODULE, 1, "'NetBooter module is disabled.'")
    }
    rebuild_event()
}

DEFINE_PROGRAM
{
    // Every 17.1 seconds
    wait 171 { sendStatusRequestAll() }
}