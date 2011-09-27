PROGRAM_NAME='Eagle Main'

#include 'TouchPanelPorts.axi'

DEFINE_DEVICE

// It sucks that we also have to define these devices in the main and not 
// just in the configuration files.
dvSystem2Device1 = 5001:1:2
dvSystem2Device2 = 5001:2:2
dvSystem2Device3 = 5001:3:2
dvSystem2Device4 = 5001:4:2
dvSystem2Device5 = 5001:5:2
dvSystem2Device6 = 5001:6:2
dvSystem2Device7 = 5001:7:2
dvSystem2Device8 = 5001:8:2

// Virtual A/V devices
vdvPlex			= 33021:1:0
vdvItunes		= 33022:1:0
vdvWeatherStatus	= 33023:1:0	// various stats sent to NetLinx channels
//vdvLutronConnect	= 33024:1:0
vdvDtv1			= 33031:1:0
vdvDtv2			= 33032:1:0
vdvDtv3			= 33033:1:0
dvPlexLocal		= 0:21:0
dvItunesLocal		= 0:22:0
dvWeatherLocal		= 0:23:0
dvDtv1Local		= 0:24:0
dvDtv2Local		= 0:25:0
dvDtv3Local		= 0:26:0
//dvLutronLocal		= 0:27:0

// Virtual devices for inter-module communications
vdvAvInputSelect	= 33051:TP_PORT_AV_INPUT_SELECT:0
vdvAvOutputSelect	= 33051:TP_PORT_AV_OUTPUT_SELECT:0
vdvZoneSelect		= 33051:TP_PORT_ZONE_SELECT:0
vdvHvacControl		= 33051:TP_PORT_HVAC_CONTROL:0
vdvHvacStatus		= 33052:TP_PORT_HVAC_CONTROL:0

// Virtual devices for IP control
vdvIp1			= 33041:1:0

DEFINE_VARIABLE

char	tpConfigFile[] = 'TouchPanels.cfg'

char    avConfigFile[] = 'AudioVideo.cfg'
char    zoneConfigFile[] = 'ZoneConfig.cfg'
//char    zoneConfigIp[]	  = '127.0.0.1'
//integer zoneConfigPort	  = 30305

char    lutronConfigFile1[] = 'Lutron.cfg'
char    lutronConfigFile2[] = 'LutronAuto.cfg'

char    gPlexHost[]   = '192.168.188.11'
integer gPlexPort     = 32400
char    gPlexPlayer[] = 'MacMini1.local.'

char    gItunesHost[] = '192.168.188.12'
integer gItunesPort   = 80

char    gDtvHost1[] = '192.168.188.31'
char    gDtvHost2[] = '192.168.188.32'
char    gDtvHost3[] = '192.168.188.33'
integer gDtvPort    = 8080

//char	weatherZipCode[] = '89451'
char	gWunderStationId[] = 'MC7350'
char	gWunderAirportId[] = 'KTRK'
char	gWunderForecastId[] = 'KTRK'

char    hvacConfigFile[] = 'Hvac.cfg'
char    automationConfigFile[] = 'Automation.cfg'

char	relayConfigFile[] = 'Relays.cfg'
dev	dvAllRelays[] = { 5001:8:1, 1021:1:1, 1022:1:1 }

char	presetConfigFile[] = 'Presets.cfg'
char	dmxConfigFile[] = 'Dmx.cfg'

integer TP_COUNT = 7

DEFINE_MODULE 'AvControl' avCtl (avConfigFile,tpConfigFile,vdvAvOutputSelect,vdvZoneSelect)
DEFINE_MODULE 'Plex_Comm' Plex (vdvPlex,dvPlexLocal,gPlexHost,gPlexPort,gPlexPlayer)
DEFINE_MODULE 'ITunesHttp_Comm' iTunesHttp (vdvItunes,dvItunesLocal,gItunesHost,gItunesPort, TP_COUNT)
DEFINE_MODULE 'DirecTvHttp_Comm' dtvHttp1 (vdvDtv1,dvDtv1Local,gDtvHost1,gDtvPort)
DEFINE_MODULE 'DirecTvHttp_Comm' dtvHttp2 (vdvDtv2,dvDtv2Local,gDtvHost2,gDtvPort)
DEFINE_MODULE 'DirecTvHttp_Comm' dtvHttp3 (vdvDtv3,dvDtv3Local,gDtvHost3,gDtvPort)
DEFINE_MODULE 'ZoneControl' zoneConn (zoneConfigFile,TP_COUNT,vdvZoneSelect,vdvAvOutputSelect)
DEFINE_MODULE 'Lutron_Comm' lutronComm (lutronConfigFile1, lutronConfigFile2)
DEFINE_MODULE 'RelayControl'  relayConn  (relayConfigFile,  tpConfigFile, dvAllRelays)
DEFINE_MODULE 'PresetControl' presetConn (presetConfigFile, tpConfigFile)
//DEFINE_MODULE 'WeatherDotCom_Comm' weatherCom (vdvWeatherStatus,dvWeatherLocal,weatherZipCode)
DEFINE_MODULE 'WeatherUnderground' wunder (vdvWeatherStatus,dvWeatherLocal,gWunderStationId,gWunderAirportId,gWunderForecastId,TP_COUNT)
DEFINE_MODULE 'Hvac_UI' hvacUi (TP_COUNT, vdvHvacStatus, vdvHvacControl, hvacConfigFile)
//DEFINE_MODULE 'Automation' automat (automationConfigFile)
DEFINE_MODULE 'IpControlledDevices_Comm' ipDevices()
DEFINE_MODULE 'Dmx' dmx(dmxConfigFile, tpConfigFile)


DEFINE_START

set_pulse_time(3)

DEFINE_EVENT

DEFINE_PROGRAM