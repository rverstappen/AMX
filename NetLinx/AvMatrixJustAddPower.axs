MODULE_NAME='AvMatrixJustAddPower' (char configFile[])

#include 'Debug.axi'

DEFINE_VARIABLE
volatile char    	JAP_SUPPORTED_CEC_CHANNEL_STRS[256][32] = {
    {'44 44'},						// 1  (Play)
    {'44 45'},						// 2  (Stop)
    {'44 46'},						// 3  (Pause)
    {'44 4B'},						// 4  (Skip forward)
    {'44 4C'},						// 5  (Skip backward)
    {'44 49'},						// 6  (Fast forward)
    {'44 48'},						// 7  (Rewind)
    {'44 47'},						// 8  (Record)
    {'44 40'},                                          // 9  (Power toggle)
    {'44 20'},                                          // 10 (0)
    {'44 21'},                                          // 11 (1)
    {'44 22'},                                          // 12 (2)
    {'44 23'},                                          // 13 (3)
    {'44 24'},                                          // 14 (4)
    {'44 25'},                                          // 15 (5)
    {'44 26'},                                          // 16 (6)
    {'44 27'},                                          // 17 (7)
    {'44 28'},                                          // 18 (8)
    {'44 29'},                                          // 19 (9)
    {''},						// 20 (Plus-10)
    {'44 2B'},                                          // 21 (Enter)
    {'44 30'},                                          // 22 (Channel up)
    {'44 30'},                                          // 23 (Channel down)
    {'44 41'},                                          // 24 (Vol up)
    {'44 42'},                                          // 25 (Vol down)
    {'44 43'},						// 26 (Mute)
    {'04'},						// 27 (Power ON)
    {'36'},						// 28 (Power OFF)
    {'44 40'},						// 29 (Slave Power toggle)
    {'04'},						// 30 (Slave Power ON)
    {'36'},						// 31 (Slave Power OFF)
    {'44 2A'},						// 32 (Dot)
    {''},{''},{''},{''},{''},{''},{''},{''},		// 33-40
    {''},{''},						// 41-42
    {'44 0D'},						// 43 (Menu Cancel)
    {'44 09'},						// 44 (Main Menu)
    {'44 01'},						// 45 (Menu Up)
    {'44 02'},						// 46 (Menu Down)
    {'44 03'},						// 47 (Menu Left)
    {'44 04'},						// 48 (Menu Right)
    {'44 00'},						// 49 (Menu Select)
    {'44 0D'},						// 50 (Menu Exit)
    {'44 07'},						// 51 (Menu Up Left)
    {'44 05'},						// 52 (Menu Up Right)
    {'44 08'},						// 53 (Menu Down Left)
    {'44 06'},						// 54 (Menu Down Right)
    {'44 0B'},						// 55 (Options Menu)
    {''},{''},{''},{''},{''},				// 56-60
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 61-69
    {'44 34'},						// 70 (Input Select)
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 71-80
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 81-90
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 91-100
    {'44 35'},						// 101 (Info)
    {'44 0C'},						// 102 (Favorites)
    {'44 2F'},						// 103 (Continue)
    {'44 32'},						// 104 (Jump Prev Channel)
    {'44 53'},						// 105 (Guide)
    {'44 37'},						// 106 (Page Up)
    {'44 38'},						// 107 (Page Down)
    {'44 50'},						// 108 (Angle/Wide Fmt)
    {''},{''},						// 109-110
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 111-119
    {'44 4A'},						// 120 (Eject)
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 121-130
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 131-140
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 141-150
    {'44 74'},						// 151 (Yellow)
    {'44 71'},						// 152 (Blue)
    {'44 72'},						// 153 (Red)
    {'44 73'},						// 154 (Green)
    {''},{''},{''},{''},{''},{''},			// 155-160
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

constant char DBG_MODULE[] = 'JustAddPower'

#include 'AvMatrixCommon.axi'
#include 'AvMatrixConfigJustAddPower.axi'

DEFINE_VARIABLE

volatile dev  gDvInputEvents[MATRIX_MAX_INPUTS]
volatile dev  gDvOutputEvents[MATRIX_MAX_OUTPUTS]
volatile char gRecvBuf[1024]
volatile char gInputBuf[MATRIX_MAX_INPUTS][256]
volatile char gOutputBuf[MATRIX_MAX_INPUTS][256]

// We also have to define local devices somewhere in order to receive data back from
// HTTP servers. We will use these in order, one per HTTP server.
DEFINE_CONSTANT
STUPID_AMX_REQUIREMENT121 = 0:121:0
STUPID_AMX_REQUIREMENT122 = 0:122:0
STUPID_AMX_REQUIREMENT123 = 0:123:0
STUPID_AMX_REQUIREMENT124 = 0:124:0
STUPID_AMX_REQUIREMENT125 = 0:125:0
STUPID_AMX_REQUIREMENT126 = 0:126:0
STUPID_AMX_REQUIREMENT127 = 0:127:0
STUPID_AMX_REQUIREMENT128 = 0:128:0
STUPID_AMX_REQUIREMENT129 = 0:129:0
STUPID_AMX_REQUIREMENT130 = 0:130:0
STUPID_AMX_REQUIREMENT131 = 0:131:0
STUPID_AMX_REQUIREMENT132 = 0:132:0
STUPID_AMX_REQUIREMENT133 = 0:133:0
STUPID_AMX_REQUIREMENT134 = 0:134:0
STUPID_AMX_REQUIREMENT135 = 0:135:0
STUPID_AMX_REQUIREMENT136 = 0:136:0
STUPID_AMX_REQUIREMENT137 = 0:137:0
STUPID_AMX_REQUIREMENT138 = 0:138:0
STUPID_AMX_REQUIREMENT139 = 0:139:0
STUPID_AMX_REQUIREMENT140 = 0:140:0
STUPID_AMX_REQUIREMENT141 = 0:141:0
STUPID_AMX_REQUIREMENT142 = 0:142:0
STUPID_AMX_REQUIREMENT143 = 0:143:0
STUPID_AMX_REQUIREMENT144 = 0:144:0
STUPID_AMX_REQUIREMENT145 = 0:145:0
STUPID_AMX_REQUIREMENT146 = 0:146:0
STUPID_AMX_REQUIREMENT147 = 0:147:0
STUPID_AMX_REQUIREMENT148 = 0:148:0
STUPID_AMX_REQUIREMENT149 = 0:149:0
STUPID_AMX_REQUIREMENT150 = 0:150:0
STUPID_AMX_REQUIREMENT151 = 0:151:0
STUPID_AMX_REQUIREMENT152 = 0:152:0
STUPID_AMX_REQUIREMENT153 = 0:153:0
STUPID_AMX_REQUIREMENT154 = 0:154:0
STUPID_AMX_REQUIREMENT155 = 0:155:0
STUPID_AMX_REQUIREMENT156 = 0:156:0
STUPID_AMX_REQUIREMENT157 = 0:157:0
STUPID_AMX_REQUIREMENT158 = 0:158:0
STUPID_AMX_REQUIREMENT159 = 0:159:0
STUPID_AMX_REQUIREMENT160 = 0:160:0
STUPID_AMX_REQUIREMENT161 = 0:161:0
STUPID_AMX_REQUIREMENT162 = 0:162:0
STUPID_AMX_REQUIREMENT163 = 0:163:0
STUPID_AMX_REQUIREMENT164 = 0:164:0
STUPID_AMX_REQUIREMENT165 = 0:165:0
STUPID_AMX_REQUIREMENT166 = 0:166:0
STUPID_AMX_REQUIREMENT167 = 0:167:0
STUPID_AMX_REQUIREMENT168 = 0:168:0
STUPID_AMX_REQUIREMENT169 = 0:169:0
STUPID_AMX_REQUIREMENT170 = 0:170:0

volatile dev  gDvInputJapTelnet[] = {
    STUPID_AMX_REQUIREMENT121,
    STUPID_AMX_REQUIREMENT122,
    STUPID_AMX_REQUIREMENT123,
    STUPID_AMX_REQUIREMENT124,
    STUPID_AMX_REQUIREMENT125,
    STUPID_AMX_REQUIREMENT126,
    STUPID_AMX_REQUIREMENT127,
    STUPID_AMX_REQUIREMENT128,
    STUPID_AMX_REQUIREMENT129,
    STUPID_AMX_REQUIREMENT130,
    STUPID_AMX_REQUIREMENT131,
    STUPID_AMX_REQUIREMENT132,
    STUPID_AMX_REQUIREMENT133,
    STUPID_AMX_REQUIREMENT134,
    STUPID_AMX_REQUIREMENT135,
    STUPID_AMX_REQUIREMENT136,
    STUPID_AMX_REQUIREMENT137,
    STUPID_AMX_REQUIREMENT138,
    STUPID_AMX_REQUIREMENT139,
    STUPID_AMX_REQUIREMENT140
}

volatile dev  gDvOutputJapTelnet[] = {
    STUPID_AMX_REQUIREMENT141,
    STUPID_AMX_REQUIREMENT142,
    STUPID_AMX_REQUIREMENT143,
    STUPID_AMX_REQUIREMENT144,
    STUPID_AMX_REQUIREMENT145,
    STUPID_AMX_REQUIREMENT146,
    STUPID_AMX_REQUIREMENT147,
    STUPID_AMX_REQUIREMENT148,
    STUPID_AMX_REQUIREMENT149,
    STUPID_AMX_REQUIREMENT150,
    STUPID_AMX_REQUIREMENT151,
    STUPID_AMX_REQUIREMENT152,
    STUPID_AMX_REQUIREMENT153,
    STUPID_AMX_REQUIREMENT154,
    STUPID_AMX_REQUIREMENT155,
    STUPID_AMX_REQUIREMENT156,
    STUPID_AMX_REQUIREMENT157,
    STUPID_AMX_REQUIREMENT158,
    STUPID_AMX_REQUIREMENT159,
    STUPID_AMX_REQUIREMENT160,
    STUPID_AMX_REQUIREMENT161,
    STUPID_AMX_REQUIREMENT162,
    STUPID_AMX_REQUIREMENT163,
    STUPID_AMX_REQUIREMENT164,
    STUPID_AMX_REQUIREMENT165,
    STUPID_AMX_REQUIREMENT166,
    STUPID_AMX_REQUIREMENT167,
    STUPID_AMX_REQUIREMENT168,
    STUPID_AMX_REQUIREMENT169,
    STUPID_AMX_REQUIREMENT170
}

DEFINE_EVENT

DATA_EVENT[gGeneral.mDevSwitch]
{
    ONLINE:
    {
	debug (DBG_MODULE,1,"'JustAddPower Switcher (',devtoa(gGeneral.mDevSwitch),') is online'")
        wait 47 // 3.9 seconds after online event
	{
	    handleMatrixStatusRequest()
	}
    }
    OFFLINE:
    {
	debug (DBG_MODULE,1,"'JustAddPower Switch (',devtoa(gGeneral.mDevSwitch),') is offline'")
    }
    COMMAND:
    {
	debug (DBG_MODULE,2,"'Received command from JustAddPower Switch (',devtoa(gGeneral.mDevSwitch),'): ',data.text")
    }
    STRING:
    {
	debug (DBG_MODULE,2,"'Received string from JustAddPower Switch (',devtoa(gGeneral.mDevSwitch),'): ',data.text")
	handleSwitchResponse (gRecvBuf)
    }
    ONERROR:
    {
	debug (DBG_MODULE,1,"'JustAddPower Switch (',devtoa(gGeneral.mDevSwitch),') has an error: ', data.text")
    }
    STANDBY:
    {
	debug (DBG_MODULE,1,"'JustAddPower Switch (',devtoa(gGeneral.mDevSwitch),') is standby'")
    }
    AWAKE:
    {
	debug (DBG_MODULE,1,"'JustAddPower Switch (',devtoa(gGeneral.mDevSwitch),') is awake'")
    }
}


DEFINE_FUNCTION handleSwitchResponse (char buf[])
{
    debug (DBG_MODULE,9,"'handleSwitchResponse: buffer contains: ',buf")
}

DEFINE_FUNCTION handleMatrixSwitch (AvMatrixMapping mappings[])
{
    integer i, numInputs
    numInputs = length_array(mappings)
    debug (DBG_MODULE, 10, "'handling matrix switch with ',itoa(length_array(mappings)),' mappings'")
    for (i = 1; i <= numInputs; i++)
    {
	integer o, numOutputs
	numOutputs = length_array(mappings[i].mOutputs)
	for (o = 1; o <= numOutputs; o++)
	{
	    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'SW ',itoa(mappings[i].mOutputs[o]),'=',itoa(mappings[i].mInput),';'")
	}
    }
}

DEFINE_FUNCTION handleMatrixStatusRequest ()
{
    debug (DBG_MODULE, 6, 'handling status request')
    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, 'SW?')
}

DEFINE_FUNCTION checkAudioSwitchVolumeLevels ()
{
    integer output
    for (output = 1; output <= length_array(gGeneral.mMaxOutputs); output++)
    {
//	sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'SL0O',itoa(output),'VT'")
    }
}

DEFINE_FUNCTION setAudioSwitchGainLevels ()
{
    integer input
    for (input = 1; input <= gGeneral.mMaxInputs; input++)
    {
//	sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'T'")
    }
}

DEFINE_FUNCTION setAbsoluteGain (integer input, sinteger gain)
{
    debug (DBG_MODULE, 5,"'New gain value on input ',itoa(input),' == ',itoa(gain)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'VA',itoa(gain),'T'")
}

DEFINE_FUNCTION setAbsoluteVolume (integer output, sinteger vol)
{
    debug (DBG_MODULE, 5,"'New volume value on output ',itoa(output),' == ',itoa(vol)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VA',itoa(vol),'T'")
}

DEFINE_FUNCTION setRelativeVolume (integer output, sinteger vol)
{
    debug (DBG_MODULE, 5,"'Change volume value on output ',itoa(output),' == ',itoa(vol)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VR',itoa(vol),'T'")
}

DEFINE_FUNCTION setRelativeGain (integer input, sinteger vol)
{
    debug (DBG_MODULE, 5,"'Change gain value on intput ',itoa(input),' == ',itoa(vol)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'VR',itoa(vol),'T'")
}

DEFINE_FUNCTION setAbsoluteMute (integer output, integer muteOn)
{
(*
    debug (DBG_MODULE, 5,"'Setting mute status on output ',itoa(output),' == ',itoa(muteOn==ACFG_MUTE_STATE_ON)")
    if (muteOn = ACFG_MUTE_STATE_ON)
        sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VMT'")
    else
        sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0O',itoa(output),'VUT'")
*)
}

DEFINE_FUNCTION setAbsoluteOff (integer output)
{
    debug (DBG_MODULE, 5,"'Turn off output: ',itoa(output)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'DL0O',itoa(output),'T'")
}

DEFINE_FUNCTION doSwitch (integer input, integer output)
{
    debug (DBG_MODULE, 5,"'Switching input ',itoa(input),' to ',itoa(output)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CL0I',itoa(input),'O',itoa(output),'T'")
}

DEFINE_FUNCTION doMainAudioSwitchOff (integer output)
{
    debug (DBG_MODULE, 1, "'switching OFF audio output source ',itoa(output)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'DO',itoa(output),'T'")
}

DEFINE_FUNCTION doMainAudioSetAbsoluteVolume (integer output, sinteger volume)
{
    debug (DBG_MODULE, 1, "'setting audio output ',itoa(output),' volume to ',itoa(volume)")
//    sendCommand (DBG_MODULE, gGeneral.mDevSwitch, "'CO',itoa(output),'VA',itoa(volume),'T'")
}

DEFINE_FUNCTION initJapInputDeviceList(MatrixJapInput cfg[])
{
    integer i, numInputs
    numInputs = length_array(cfg)
    set_length_array(gDvInputEvents,    numInputs)
    set_length_array(gDvInputJapTelnet, numInputs)
    for (i = 1; i <= numInputs; i++)
    {
	gDvInputEvents[i] = cfg[i].mDev
    }
}

DEFINE_FUNCTION initJapOutputDeviceList(MatrixJapOutput cfg[])
{
    integer i, numOutputs
    numOutputs = length_array(cfg)
    set_length_array(gDvOutputEvents,    numOutputs)
    set_length_array(gDvOutputJapTelnet, numOutputs)
    for (i = 1; i <= numOutputs; i++)
    {
	gDvOutputEvents[i] = cfg[i].mDev
    }
}

DEFINE_FUNCTION japRelayChannel (integer japOutputId, integer chan)
{
    char msg[128]
    char msgParams[32]
    debug (DBG_MODULE, 8, "'event on channel ',itoa(chan)")
    switch (gCfgJapOutputs[japOutputId].mConnectType)
    {
    case JAP_CONNECT_TYPE_CEC:
    {
        msgParams = JAP_SUPPORTED_CEC_CHANNEL_STRS[chan]
        debug (DBG_MODULE, 8, "'event on channel ',itoa(chan),' (=><',msgParams,'>)'")
	if (msgParams != '')
	{
	    msg = "'CEC_SEND_BYTES ',gCfgJapOutputs[japOutputId].mCecId,' ',msgParams,$0A"
            sendMessage (gDvOutputJapTelnet[japOutputId], msg)
	}
    }
    } // switch
}


DEFINE_EVENT

// First, handling for internal events

BUTTON_EVENT[gDvOutputEvents, 0]
{
    PUSH:		{ japRelayChannel (get_last(gDvOutputEvents), push_channel) }
    HOLD[3,REPEAT]:	{ japRelayChannel (get_last(gDvOutputEvents), push_channel) }
    RELEASE:		{}
}

CHANNEL_EVENT[gDvOutputEvents, 0]
{
    ON:			{ japRelayChannel (get_last(gDvOutputEvents), channel.channel) }
}

DATA_EVENT[gDvOutputEvents]
{
    ONLINE:  {debug (DBG_MODULE, 9, "'online: '")}
    OFFLINE: {debug (DBG_MODULE, 9, "'offline: '")}
    STRING:  {debug (DBG_MODULE, 9, "'got string: ',data.text")}
    COMMAND: {debug (DBG_MODULE, 9, "'got command: ',data.text")}
}

// Second, handle telnet comm events.

DEFINE_EVENT
DATA_EVENT[gDvInputJapTelnet]
{
    ONLINE:  { handleInputConnect(get_last(gDvInputJapTelnet)) }
    OFFLINE: { handleInputDisconnect(get_last(gDvInputJapTelnet)) }
    STRING: 
    {
	integer id
	id = get_last(gDvInputJapTelnet)
	if (handleInputResponse(id,gInputBuf[id]))
	{
	    clear_buffer gInputBuf[id]
	}
    }
    COMMAND: { debug (DBG_MODULE, 1, "'JAP telnet received command instead of string: ',data.text") }
    ONERROR:
    {
	debug (DBG_MODULE, 1, "'JAP telnet status code: ',itoa(data.number)")
    	wait 300 { connect(gDvInputJapTelnet[get_last(gDvInputJapTelnet)].port, gCfgJapInputs[get_last(gDvInputJapTelnet)].mTelnetIp) }
    }
}

DATA_EVENT[gDvOutputJapTelnet]
{
    ONLINE:  { handleOutputConnect(get_last(gDvOutputJapTelnet)) }
    OFFLINE: { handleOutputDisconnect(get_last(gDvOutputJapTelnet)) }
    STRING: 
    {
	integer id
	id = get_last(gDvOutputJapTelnet)
	if (handleOutputResponse(id,gOutputBuf[id]))
	{
	    clear_buffer gOutputBuf[id]
	}
    }
    COMMAND: { debug (DBG_MODULE, 1, "'JAP telnet received command instead of string: ',data.text") }
    ONERROR:
    {
	debug (DBG_MODULE, 1, "'JAP telnet status code: ',itoa(data.number)")
    	wait 300 { connect(gDvOutputJapTelnet[get_last(gDvOutputJapTelnet)].port, gCfgJapOutputs[get_last(gDvOutputJapTelnet)].mTelnetIp) }
    }
}

DEFINE_FUNCTION handleInputConnect (integer id)
{
    debug (DBG_MODULE, 2, "'Input connection successful: ',devtoa(gCfgJapInputs[id].mTelnetIp)")
}

DEFINE_FUNCTION handleOutputConnect (integer id)
{
    debug (DBG_MODULE, 2, "'Output connection successful: ',devtoa(gCfgJapOutputs[id].mTelnetIp)")
}

DEFINE_FUNCTION handleInputDisconnect (integer id)
{
    debug (DBG_MODULE, 2, "'telnet disconnected for ',devtoa(gCfgJapInputs[id].mTelnetIp),
    	  	       	   '! Trying again in 30 seconds...'")
    wait 300 { connect(gDvInputJapTelnet[id].port, gCfgJapInputs[id].mTelnetIp) }
}

DEFINE_FUNCTION handleOutputDisconnect (integer id)
{
    debug (DBG_MODULE, 2, "'telnet disconnected for ',devtoa(gCfgJapOutputs[id].mTelnetIp),
    	  	       	   '! Trying again in 30 seconds...'")
    wait 300 { connect(gDvOutputJapTelnet[id].port, gCfgJapOutputs[id].mTelnetIp) }
}

DEFINE_FUNCTION integer handleInputResponse (integer id, char msg[])
{
    debug (DBG_MODULE, 8, "'Received message(s) from JAP input (',gCfgJapInputs[id].mTelnetIp,'): ',msg,'(',itoa(length_array(msg)),')'")
    return 1
}

DEFINE_FUNCTION integer handleOutputResponse (integer id, char msg[])
{
    debug (DBG_MODULE, 8, "'Received message(s) from JAP output (',gCfgJapOutputs[id].mTelnetIp,'): ',msg,'(',itoa(length_array(msg)),')'")
    return 1
}

DEFINE_FUNCTION sendMessage (dev dv, char cmd[])
{
    debug (DBG_MODULE, 7, "'sending JAP command to ',devtoa(dv),': ',cmd")
    send_string dv, "cmd"
}

DEFINE_FUNCTION connect (integer srcPort, char ipAddr[])
{
    debug (DBG_MODULE, 2, "'Opening TCP connection to ',ipAddr")
    ip_client_open (srcPort, ipAddr, 23, IP_TCP)
}

DEFINE_FUNCTION disconnect (integer srcPort, char ipAddr[])
{
    debug (DBG_MODULE, 2, "'Closing connection to ',ipAddr")
    ip_client_close (srcPort)
}


DEFINE_START
{
    readConfigFile ('JustAddPower', configFile)
    if (gGeneral.mEnabled)
    {
	integer id
	debug (DBG_MODULE, 1, "'module is enabled.'")
	initJapInputDeviceList  (gCfgJapInputs)
	initJapOutputDeviceList (gCfgJapOutputs)
	create_buffer gGeneral.mDevSwitch, gRecvBuf
	for (id = 1; id <= length_array(gCfgJapInputs); id++)
	{
	    create_buffer gDvInputJapTelnet[id], gInputBuf[id]
	}
	for (id = 1; id <= length_array(gCfgJapOutputs); id++)
	{
	    create_buffer gDvOutputJapTelnet[id], gOutputBuf[id]
	}
	rebuild_event()
//	wait 241 // 24.1 secs
	wait 51 // 5.1 secs
	{
	    local_var id2
	    for (id2 = 1; id2 <= length_array(gCfgJapInputs); id2++)
	    {
		connect(gDvInputJapTelnet[id2].port, gCfgJapInputs[id2].mTelnetIp)
	    }
	    for (id2 = 1; id2 <= length_array(gCfgJapOutputs); id2++)
	    {
		connect(gDvOutputJapTelnet[id2].port, gCfgJapOutputs[id2].mTelnetIp)
	    }
	}
    }
    else
    {
	debug (DBG_MODULE, 1, "'module is disabled.'")
    }

}
