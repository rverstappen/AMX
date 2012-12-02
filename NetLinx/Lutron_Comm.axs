MODULE_NAME='Lutron_Comm' (char configFileGeneral[], char configFileAuto[])

#include 'LutronConfig.axi'

DEFINE_CONSTANT

char NEWLINE_TELNET[2]	= {$0D,$0A}
char NEWLINE_SERIAL	= $0D
char NEWLINE		= $0D
char TAB		= $09

DEFINE_VARIABLE

volatile char DBG_MODULE[] = 'Lutron_Comm'
volatile char gBuf[1024]

DEFINE_EVENT

// Handle button events and pulses from other modules. 
// Channels correspond to the mId field of each LutronInput.
BUTTON_EVENT[gGeneral.mDevControl, 0]
{
    PUSH: { handleLutronControlPush (button.input.channel) }
}

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
    select
    {
    active (find_string(msg,'CLICK=>',1)):
    {
	// 'Push' a control button
	remove_string(msg,'CLICK=>',1)
	handleLutronControlPush (atoi(msg))
    } // active
    active (find_string(msg,'OUTPUT-SETLEVEL=>',1)):
    {
	// Set the (dimmer/fan/etc.) level of an output
	integer id, lev
	remove_string (msg,'OUTPUT-SETLEVEL=>',1)
	id = atoi(msg)
	remove_string (msg,',',1)
	lev = atoi(msg)
	handleLutronOutputSetLevel (id, lev)
    } // active
    active (find_string(msg,'?GET-ALL-OUTPUTS',1)):
    {
	// Get the list of IDs, names and short-names
	remove_string(msg,'?GET-ALL-OUTPUTS',1)
	handleLutronGetAllOutputs (0:1:0)
    } // active
    active (find_string(msg,'?GET-ALL-INPUTS',1)):
    {
	// Get the list of IDs, names and short-names
	remove_string(msg,'?GET-ALL-INPUTS',1)
	handleLutronGetAllInputs (0:1:0)
    } // active
    active (1):
    {
        debug (DBG_MODULE, 9, "'Lutron pass-thru msg: ',msg")
        sendLutronCommand(msg)
    }
    } // select
}

DEFINE_FUNCTION handleLutronOutputSetLevel (integer id, integer lev)
{
    debug (DBG_MODULE, 9, "'got Lutron  for ',gOutputs[id].mAddress,
    	  	           ': type=',lutronStrFromOutputType(gOutputs[id].mType)")
    switch (gOutputs[id].mType)
    {
    case LUTRON_OUTPUT_TYPE_DIMMER:	sendLutronCommand ("'FADEDIM, ',lev,', 0, 0, [',
    	 						     gOutputs[id].mAddress,']'")
    case LUTRON_OUTPUT_TYPE_SWITCHED:	sendLutronCommand ("'FADEDIM, ',lev,', 0, 0, [',
    	 						     gOutputs[id].mAddress,']'")
//    case LUTRON_TYPE_FAN:		sendLutronCommand ("'FADEDIM, ',lev,', 0, 0, [',
//    	 						     gOutputs[id].mAddress,']'")
//    case LUTRON_TYPE_BLIND:		sendLutronCommand ("'FADEDIM, ',lev,', 0, 0, [',
//    	 						     gOutputs[id].mAddress,']'")
    }
}

DEFINE_FUNCTION handleLutronControlPush (integer id)
{
    debug (DBG_MODULE, 9, "'got Lutron push for ',gInputs[id].mAddress,
    	  	           ': type=',lutronStrFromInputType(gInputs[id].mType)")
//    switch (gInputs[id].mType)
//    {
//    case LUTRON_INPUT_TYPE_KEYPAD:	sendLutronCommand ("'KBP, [',gInputs[id].mAddress,'], ', 
//    	 					  	  	itoa(gInputs[id].mButton)")
//    }
}

DEFINE_FUNCTION handleLutronGetAllOutputs (dev replyDev)
{
    local_var char replyMsg[1024]
    debug (DBG_MODULE, 9, "'got request for all Lutron Output IDs and names; replying to device: ',devtoa(replyDev)")
    if (length_array(replyMsg) = 0)
    {
	integer i
	replyMsg = 'GETALLOUTPUTS-'
	for (i = 1; i < length_array(gOutputs); i++)
	{
	    replyMsg = "replyMsg,itoa(gOutputs[i].mId),TAB,gOutputs[i].mName,TAB,gOutputs[i].mShortName,NEWLINE"
	}
    }
    send_command replyDev, replyMsg
}

DEFINE_FUNCTION handleLutronGetAllInputs (dev replyDev)
{
    char replyMsg[1024]
    integer i, j

    debug (DBG_MODULE, 9, "'got request for all Lutron IDs and names; replying to device: ',devtoa(replyDev)")
(* FINISH THIS!!!!
	for (i = 1; i <= length_array(gInputs); i++)
	{
	    // Input control ID and name:
	    replyMsg = "'INPUT-DEF=>',itoa(gInputs[i].mId),TAB,
	    	         gInputs[i].mName,TAB,gInputs[i].mShortName,NEWLINE"
	    // Input control buttons:
	    for (j = 1; j <= length_array(gInputs[i].mButtonNames[j]); j++)
	    {
		if (length_array(gInputs[i].mButtonNames[j]) != '')
		{
		    replyMsg += "itoa(g"
		}
	    }
	    send_command replyDev, replyMsg
	}
    }
*)
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
    debug (DBG_MODULE, 2, "'Connecting to Lutron; type=',itoa(gGeneral.mDevType)")
    switch (gGeneral.mDevType)
    {
    case LUTRON_DEV_TYPE_TELNET:
    {
	debug (DBG_MODULE, 2, "'Opening TCP connection to ',gGeneral.mTelnetAddr")
	ip_client_open (gGeneral.mDev.port, gGeneral.mTelnetAddr, gGeneral.mTelnetPort, IP_TCP)
    }
    }
}

DEFINE_FUNCTION disconnect()
{
    switch (gGeneral.mDevType)
    {
    case LUTRON_DEV_TYPE_TELNET:
    {
	debug (DBG_MODULE, 2, 'Closing connection')
	ip_client_close(gGeneral.mDev.port)
    }
    }
}

DEFINE_FUNCTION handleConnect()
{
    debug (DBG_MODULE, 2, "'Connection successful: ',devtoa(gGeneral.mDev)")
}

DEFINE_FUNCTION handleDisconnect()
{
    switch (gGeneral.mDevType)
    {
    case LUTRON_DEV_TYPE_TELNET:
    {
	debug (DBG_MODULE, 2, 'telnet disconnected! Trying again in 30 seconds...')
	wait 300 { connect() }
    }
    case LUTRON_DEV_TYPE_SERIAL:
    {
	debug (DBG_MODULE, 2, 'serial disconnect???')
	wait 300 { connect() }
    }
    }
}

DEFINE_FUNCTION integer handleReply (char msg[])
{
    debug (DBG_MODULE, 8, "'Got message from Lutron: ',msg,'(',itoa(length_array(msg)),')'")
    select
    {
    active (find_string(msg,'KBP, ',1)):
    {
	char    address[16]
	integer buttonNum
	integer endAddress
	remove_string (msg,'KBP, ',1)
	endAddress = find_string (msg,'], ',1)
	address = left_string (msg,endAddress+1)
	buttonNum = atoi(right_string (msg, endAddress+3))
	debug (DBG_MODULE, 8, "'Got keypad press: ',address,', ',itoa(buttonNum)")
	return 1
    }
    active (find_string(msg,'login successful',1)):
    {
	debug (DBG_MODULE, 2, 'Successful login with Lutron; all is good!')
	debug (DBG_MODULE, 2, 'Turning on Keypad Button monitoring')
	sendLutronCommand ('PROMPTOFF')
	sendLutronCommand ('KBMON')
	return 1
    }
    active (find_string(msg,'LOGIN:',1)):
    {
	switch (gGeneral.mDevType)
	{
	case LUTRON_DEV_TYPE_TELNET:
	{
	    debug (DBG_MODULE, 2, 'Sending telnet login...')
	    sendLutronCommand ("gGeneral.mUsername,', ',gGeneral.mPassword")
	}
	case LUTRON_DEV_TYPE_SERIAL:
	{
	    debug (DBG_MODULE, 2, 'Sending serial login...')
	    sendLutronCommand ("', ',gGeneral.mPassword")
	}
	}
	return 1
    }
    active (find_string(msg,'LNET>',1)):
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
    switch (gGeneral.mDevType)
    {
    case LUTRON_DEV_TYPE_TELNET:	send_string gGeneral.mDev, "cmd,NEWLINE_TELNET"
    case LUTRON_DEV_TYPE_SERIAL:	send_string gGeneral.mDev, "cmd,NEWLINE_SERIAL"
    }
}


DEFINE_START
{
    readConfigFile ('LutronConfig', configFileGeneral)
    readConfigFile ('LutronConfig', configFileAuto)
    debug(DBG_MODULE,2,"'Finished reading configuration; favorite control ID = ',
    			itoa(gGeneral.mFavoriteInputId)")
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
