MODULE_NAME='TouchPanel' (char tpConfigFile[])

#include 'TouchPanelConfig.axi'
#include 'Debug.axi'

DEFINE_CONSTANT
char    TP_ADDRESS_WELCOME[] = '11'
integer TP_PAGE_CHANNELS_BEGIN = 101
integer TP_PAGE_CHANNELS_COUNT = 100    // i.e., 100 max num pages in TP design

DEFINE_VARIABLE

constant char		DBG_MODULE[]    = 'TouchPanel'
volatile TpCfgGeneral	gTpGeneral
volatile TouchPanel	gPanels[TP_MAX_PANELS]
volatile dev		gDvTps[TP_MAX_PANELS]
volatile integer	gTpPageMemory[TP_MAX_PANELS]


DEFINE_EVENT

DATA_EVENT[gDvTps]
{
    ONLINE:
    {
	// Either the Master just restarted or the TP was just turned on again
	handleConnect (get_last(gDvTps))
    }
    OFFLINE: {}
    STRING: { debug (DBG_MODULE, 8, "'received string from TP (',devtoa(data.device),'): ',data.text") }
}


DEFINE_START
{
    tpReadConfigFile ('TouchPanel', tpConfigFile, gTpGeneral, gPanels)
    tpMakeLocalDevArray ('TouchPanel', gDvTps, gPanels, gTpGeneral.mTpPort)
    rebuild_event()
}


DEFINE_FUNCTION handleConnect(integer tpId)
{
    debug (DBG_MODULE, 3, "'TP ',itoa(tpId),' (',devtoa(gDvTps[tpId]),') is online'")
    updateTpTitle(tpId)
}

DEFINE_FUNCTION updateTpTitle (integer tpId)
{
    if (length_array(gPanels[tpId].mWelcome) > 0)
    {
	debug (DBG_MODULE, 3, "'Found personal welcome message: ', gPanels[tpId].mWelcome")
	sendCommand (DBG_MODULE, gDvTps[tpId], "'TEXT',TP_ADDRESS_WELCOME,'-',gPanels[tpId].mWelcome")
    }
    else if (length_array(gTpGeneral.mWelcome) > 0)
    {
	debug (DBG_MODULE, 3, "'Found general welcome message: ', gTpGeneral.mWelcome")
	sendCommand (DBG_MODULE, gDvTps[tpId], "'TEXT',TP_ADDRESS_WELCOME,'-',gTpGeneral.mWelcome")
    }
    else
    {
	debug (DBG_MODULE, 3, "'No welcome message for this device'")
    }
}

// We need to define these because usually there is other config reading required.
DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
}

DEFINE_FUNCTION handleProperty (char moduleName[], char propName[], char propValue[])
{    
}

