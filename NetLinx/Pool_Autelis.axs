MODULE_NAME='Pool_Autelis' (char configFileGeneral[], tpConfigFile[])

#include 'Pool.axi'
#include 'PoolConfigAutelis.axi'
#include 'Pool_UI.axi'

DEFINE_CONSTANT

char NEWLINE		= $0D
char CRLF[]             = {$0D,$0A}

volatile char AUT_MODULE[] = 'AutelisPoolControl'

DEFINE_VARIABLE
volatile char     gCircuitNameMap[16][32]
volatile integer  gCircuitToAuxMap[32]
volatile char     gBuf[1024]

volatile char AUTELIS_STATUS_CMDS[][32] = {
	 {'#SPAHT?'},
	 {'#SPASP?'},
	 {'#SPATMP?'},
	 {'#POOLHT?'},
	 {'#POOLSP?'},
	 {'#POOLTMP?'},
	 {'#NAME1?'},
	 {'#CIR1?'},
	 {'#NAME2?'},
	 {'#CIR2?'},
	 {'#NAME3?'},
	 {'#CIR3?'},
	 {'#NAME4?'},
	 {'#CIR4?'},
	 {'#NAME5?'},
	 {'#CIR5?'},
	 {'#NAME6?'},
	 {'#CIR6?'},
	 {'#NAME7?'},
	 {'#CIR7?'},
	 {'#NAME8?'},
	 {'#CIR8?'},
	 {'#NAME9?'},
	 {'#CIR9?'},
	 {'#NAME10?'},
	 {'#CIR10?'},
	 {'#AIRTMP?'}
}


DEFINE_EVENT
DATA_EVENT[gGeneral.mDevLocal]
{
    ONLINE:  { handleConnect() }
    OFFLINE: { handleDisconnect() }
    STRING: 
    {
	wait 20 // let the buffer receive the complete message
	{
	    if (handleData(gBuf))
	    {
	    	clear_buffer gBuf
	    }
	}
    }
    COMMAND: { debug (AUT_MODULE, 1, "'COMM device received command instead of string: ',data.text") }
    ONERROR: { debug (AUT_MODULE, 1, "'COMM device status code: ',itoa(data.number)") }
}

DEFINE_FUNCTION connect()
{
    debug (AUT_MODULE, 2, "'Opening TCP connection to ',gGeneral.mTcpIpAddress,' port ',gGeneral.mTcpPort")
    ip_client_open (gGeneral.mDevLocal.port, gGeneral.mTcpIpAddress, gGeneral.mTcpPort, IP_TCP)
}

DEFINE_FUNCTION disconnect()
{
    debug (AUT_MODULE, 2, 'Closing connection')
    ip_client_close(gGeneral.mDevLocal.port)
}

DEFINE_FUNCTION handleConnect()
{
    debug (AUT_MODULE, 2, "'Connection successful: ',devtoa(gGeneral.mDevLocal)")
}

DEFINE_FUNCTION handleDisconnect()
{
    debug (AUT_MODULE, 2, 'telnet disconnected! Trying again in 30 seconds...')
    wait 300 { connect() }
}

DEFINE_FUNCTION integer handleData (char data[])
{
    char msg[64]
    debug (AUT_MODULE, 8, "'Got data from Autelis: ',data,'(',itoa(length_array(data)),')'")
    // Split data into messages, using \r\n as the message separator/terminator
    msg = remove_string(data, CRLF, 1)
    while (length_array(msg) > 0)
    {
	set_length_array(msg, length_array(msg)-2)   // remove the \r\n
        debug (AUT_MODULE, 8, "'Got message from Autelis: ',msg,'(',itoa(length_array(msg)),')'")
	select
	{
	active (find_string(msg,'!00 ',1)):
	{
	    remove_string(msg,'!00 ',1)
	    handleAutelisResponse (msg)
	}
	active (find_string(msg,'!10',1)):
	{
	    debug (AUT_MODULE, 2, "'Autelis message problem: ',msg")
	}
	active (find_string(msg,'?01',1)):
	{
	    debug (AUT_MODULE, 2, "'Autelis invalid command sent (programming error): ',msg")
	}
	active (1):
	{
	    debug (AUT_MODULE, 2, "'Unhandled (partial?) message from Autelis: ',msg")
	}
	} // select
        msg = remove_string(data, CRLF, 1)
    }
    return (length_array(data) == 0)
}

DEFINE_FUNCTION handleAutelisResponse (char msg[])
{
    select
    {
    active (find_string(msg,'AIRTMP=',1)):
    {
	remove_string(msg,'AIRTMP=',1)
	doTpUpdateAirTemp (atoi(msg))
    }
    active (find_string(msg,'POOLTMP=',1)):
    {
	remove_string(msg,'POOLTMP=',1)
	doTpUpdatePoolTemp (atoi(msg))
    }
    active (find_string(msg,'SPATMP=',1)):
    {
	remove_string(msg,'SPATMP=',1)
	doTpUpdateSpaTemp (atoi(msg))
    }
    active (find_string(msg,'POOLSP=',1)):
    {
	remove_string(msg,'POOLSP=',1)
	doTpUpdatePoolSetPoint (atoi(msg))
    }
    active (find_string(msg,'SPASP=',1)):
    {
	remove_string(msg,'SPASP=',1)
	doTpUpdateSpaSetPoint (atoi(msg))
    }
    active (find_string(msg,'POOL=',1)):
    {
	remove_string(msg,'POOL=',1)
	doTpUpdatePoolState (atoi(msg))
    }
    active (find_string(msg,'SPA=',1)):
    {
	remove_string(msg,'SPA=',1)
	doTpUpdateSpaState (atoi(msg))
    }
    active (find_string(msg,'NAME',1)):
    {
	remove_string(msg,'NAME',1)
	handleNameUpdate(msg)
    }
    active (find_string(msg,'AUX',1)):
    {
	remove_string(msg,'NAME',1)
	handleAuxUpdate(msg)
    }
    active (1):
    {
	debug (AUT_MODULE, 2, "'Unhandled response from Autelis: ',msg")
    }
    } // select
}

DEFINE_FUNCTION handleNameUpdate(char msg[])
{
    integer circuit
    circuit = atoi(msg)
    remove_string(msg, '=', 1)
    select
    {
    active (find_string(msg, 'POOL', 1)):
    {
	doTpUpdatePoolName ('POOL')
    }
    active (find_string(msg, 'SPA', 1)):
    {
	doTpUpdateSpaName ('SPA')
    }
    active (1):
    {
	integer aux
	aux = gCircuitToAuxMap[circuit]
	doTpUpdateAuxName (aux, msg)
    }
    } // select
}

DEFINE_FUNCTION handleAuxUpdate(char msg[])
{
    integer aux, state
    aux = atoi(msg)
    remove_string(msg, '=', 1)
    state = atoi(msg)
    doTpUpdateAuxState (aux, state)
}

DEFINE_FUNCTION sendAutelisCommand (char cmd[])
{
    debug (AUT_MODULE, 7, "'sending Autelis control command: ',cmd")
    send_string gGeneral.mDevLocal, "cmd,NEWLINE"
}

DEFINE_FUNCTION poolCommIncrPoolSetPoint()
{
    sendAutelisCommand('#POOLSP+')
}

DEFINE_FUNCTION poolCommDecrPoolSetPoint()
{
    sendAutelisCommand('#POOLSP-')
}

DEFINE_FUNCTION poolCommIncrSpaSetPoint()
{
    sendAutelisCommand('#SPASP+')
}

DEFINE_FUNCTION poolCommDecrSpaSetPoint()
{
    sendAutelisCommand('#SPASP-')
}

DEFINE_FUNCTION poolCommTogglePoolPump()
{
    sendAutelisCommand("'#POOL=',autelisState(!gPoolState.mPoolPumpState)")
}

DEFINE_FUNCTION poolCommToggleSpaPump()
{
    sendAutelisCommand("'#SPA=',autelisState(!gPoolState.mSpaPumpState)")
}

DEFINE_FUNCTION poolCommAuxToggle(integer aux, integer state)
{
    sendAutelisCommand("'#CIR',itoa(gGeneral.mAuxCircuits[aux]),'=',autelisState(state)")
}

DEFINE_FUNCTION sendNextStatusRequest()
{
    local_var i
    if ((i < 0) || (i > length_array(AUTELIS_STATUS_CMDS)))
    {
	i = 1
    }
    sendAutelisCommand(AUTELIS_STATUS_CMDS[i])
    i++
}

DEFINE_FUNCTION char[4] autelisState(integer state)
{
    if (state)
	return 'ON'
    else
	return 'OFF'
}

DEFINE_FUNCTION setupCircuitMap()
{
    integer aux
    set_length_array(gCircuitNameMap,  length_array(gGeneral.mAuxCircuits)+2)
    set_length_array(gCircuitToAuxMap, length_array(gGeneral.mAuxCircuits)+2)
    if (gGeneral.mPoolCircuit > 0)
    {
	gCircuitNameMap[gGeneral.mPoolCircuit] = 'POOL'
    }
    if (gGeneral.mSpaCircuit > 0)
    {
	gCircuitNameMap[gGeneral.mSpaCircuit] = 'SPA'
    }
    for (aux = 1; aux <= length_array(gGeneral.mAuxCircuits); aux++)
    {
	integer circuit
	circuit = gGeneral.mAuxCircuits[aux]
	gCircuitToAuxMap[circuit] = aux
        gCircuitNameMap[circuit] = "'AUX',itoa(aux)"
    }
}

DEFINE_START
{
    readConfigs (configFileGeneral, tpConfigFile)
    debug(AUT_MODULE,2,"'Finished reading configuration'")
    create_buffer gGeneral.mDevLocal, gBuf
    if (gGeneral.mEnabled)
    {
	setupCircuitMap()
        wait 97
    	{
	    connect()
    	}
    }
}

DEFINE_PROGRAM
wait 17 // 2971
{
    // Keep requesting the state 
    if (gGeneral.mEnabled)
    {
	sendNextStatusRequest()
    }
}
