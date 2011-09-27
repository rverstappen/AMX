MODULE_NAME='RelayControl' (char configFile[], char tpConfigFile[], dev dvRelays[])

#include 'TouchPanelConfig.axi'
#include 'RelayConfig.axi'

DEFINE_CONSTANT

DEFINE_VARIABLE

volatile char		DBG_MODULE[] = 'RelayControl'
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTps[TP_MAX_PANELS]

DEFINE_EVENT

// Handle button events and commands from touchpanels and other modules. 

// Channels correspond to the mId field of each RelayControl.
BUTTON_EVENT[gGeneral.mDevControl, 0]
{
    PUSH: { handleRelayPush (button.input.channel) }
}

BUTTON_EVENT[gDvTps, 0]
{
    PUSH: { handleRelayPush (button.input.channel) }
}

// Handle commands from other modules
DATA_EVENT[gGeneral.mDevControl]
{
    ONLINE:  {}
    OFFLINE: {}
    COMMAND:
    {
	debug (DBG_MODULE, 5, "'received Relay control command from ',devtoa(data.device),': ',data.text")
	handleRelayCommand (data.text)
    }
    STRING:
    {
	debug (DBG_MODULE, 5, "'received Relay control string from ',devtoa(data.device),': ',data.text")
    }
}

DEFINE_FUNCTION handleRelayCommand (char msg[])
{
    select
    {
    active (find_string(msg,'PUSH-',1)):
    {
	// 'Push' a control button
	remove_string(msg,'PUSH-',1)
	handleRelayPush (atoi(msg))
    } // active
    active (find_string(msg,'ON-',1)):
    {
	// Turn on a control button
	remove_string(msg,'ON-',1)
	handleRelayOn (atoi(msg))
    } // active
    active (find_string(msg,'OFF-',1)):
    {
	// Turn off a control button
	remove_string(msg,'OFF-',1)
	handleRelayOff (atoi(msg))
    } // active
    } // select
}

DEFINE_FUNCTION handleRelayPush (integer id)
{
//    debug (DBG_MODULE, 9, "'push request for relay: ',gRelays[id].mName,'[',atoi(gRelays[id].mId),']'")
//    pulse [gRelays[id].mDev, gRelays[id].mChannel]
}

DEFINE_FUNCTION handleRelayOn (integer id)
{
    debug (DBG_MODULE, 9, "'ON request for relay: ',gRelays[id].mName,'[',itoa(gRelays[id].mId),']'")
    switch (gRelays[id].mType)
    {
    case RELAY_TYPE_PASSIVE:
	debug (DBG_MODULE, 9, "'pulse [',devchantoa(gRelays[id].mDevChan1),']'")
	pulse [gRelays[id].mDevChan1]
    case RELAY_TYPE_ACTIVE:
	debug (DBG_MODULE, 9, "'on [',devchantoa(gRelays[id].mDevChan1),']'")
	on [gRelays[id].mDevChan1]
    default:
	debug (DBG_MODULE, 9, "'Cannot determine relay type for relay: ',gRelays[id].mName,
	      		       '[',itoa(gRelays[id].mId),']'")
    }
}

DEFINE_FUNCTION handleRelayOff (integer id)
{
    debug (DBG_MODULE, 9, "'OFF request for relay: ',gRelays[id].mName,'[',itoa(gRelays[id].mId),']'")
    switch (gRelays[id].mType)
    {
    case RELAY_TYPE_PASSIVE:
	debug (DBG_MODULE, 9, "'pulse [',devchantoa(gRelays[id].mDevChan2),']'")
	pulse [gRelays[id].mDevChan2]
    case RELAY_TYPE_ACTIVE:
	debug (DBG_MODULE, 9, "'off [',devchantoa(gRelays[id].mDevChan1),']'")
	off [gRelays[id].mDevChan1]
    default:
	debug (DBG_MODULE, 9, "'Cannot determine relay type for relay: ',gRelays[id].mName,
	      		       '[',itoa(gRelays[id].mId),']'")
    }
}

DEFINE_START
{
    tpReadConfigFile ('RelayConfig', tpConfigFile, gPanels)
    readConfigFile ('RelayConfig', configFile)
    if (gGeneral.mEnabled)
    {
	tpMakeLocalDevArray (gDvTps, gPanels, gGeneral.mTpPort)
    	rebuild_event()
    }
}

DEFINE_PROGRAM
