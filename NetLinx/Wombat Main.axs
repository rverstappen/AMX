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

// We have to define the actual virtual devices somewhere, not just in config 
// files. This is a stupid AMX requirement. At least by declaring a virtual
// device with port 1, the virtual devices for all the other ports wil work.
// For example, declaring 33031:1:0 will also enable  33031:2:0, 33031:3:0,
// etc. So, here we actually have 1,000s of virtual devices that we can use
// in configuration files.  
// BTW: I call this stupid because not only is this requirement inconvenient,
// it is also inconsistent. It is fine to not explicitly declare 'local' 
// socket devices, like 0:21:0, 0:22:0, etc. It's also OK not to define real
// devices, like 5001:1:1 -- unless they are remote devices, like 5001:1:2.
// All this implementation-dependent nonsense should really be under the
// NetLinx hood.
DEFINE_DEVICE
STUPID_AMX_REQUIREMENT1  = 33021:1:0	// and 33021:2:0, 33021:3:0, etc.
STUPID_AMX_REQUIREMENT2  = 33022:1:0	// and ...
STUPID_AMX_REQUIREMENT3  = 33023:1:0	// and ...
STUPID_AMX_REQUIREMENT4  = 33024:1:0
STUPID_AMX_REQUIREMENT5  = 33025:1:0
STUPID_AMX_REQUIREMENT6  = 33026:1:0
STUPID_AMX_REQUIREMENT7  = 33027:1:0
STUPID_AMX_REQUIREMENT8  = 33028:1:0
STUPID_AMX_REQUIREMENT9  = 33029:1:0
STUPID_AMX_REQUIREMENT10 = 33030:1:0
STUPID_AMX_REQUIREMENT11 = 33031:1:0
STUPID_AMX_REQUIREMENT12 = 33032:1:0
STUPID_AMX_REQUIREMENT13 = 33033:1:0
STUPID_AMX_REQUIREMENT14 = 33034:1:0
STUPID_AMX_REQUIREMENT15 = 33035:1:0
STUPID_AMX_REQUIREMENT16 = 33036:1:0
STUPID_AMX_REQUIREMENT17 = 33037:1:0
STUPID_AMX_REQUIREMENT18 = 33038:1:0
STUPID_AMX_REQUIREMENT19 = 33039:1:0
STUPID_AMX_REQUIREMENT20 = 33040:1:0
STUPID_AMX_REQUIREMENT21 = 33041:1:0
STUPID_AMX_REQUIREMENT22 = 33042:1:0
STUPID_AMX_REQUIREMENT23 = 33043:1:0
STUPID_AMX_REQUIREMENT24 = 33044:1:0
STUPID_AMX_REQUIREMENT25 = 33045:1:0
STUPID_AMX_REQUIREMENT26 = 33046:1:0
STUPID_AMX_REQUIREMENT27 = 33047:1:0
STUPID_AMX_REQUIREMENT28 = 33048:1:0
STUPID_AMX_REQUIREMENT29 = 33049:1:0
STUPID_AMX_REQUIREMENT30 = 33050:1:0
STUPID_AMX_REQUIREMENT31 = 33051:1:0
STUPID_AMX_REQUIREMENT32 = 33052:1:0
STUPID_AMX_REQUIREMENT33 = 33053:1:0
STUPID_AMX_REQUIREMENT34 = 33054:1:0
STUPID_AMX_REQUIREMENT35 = 33055:1:0
STUPID_AMX_REQUIREMENT36 = 33056:1:0
STUPID_AMX_REQUIREMENT37 = 33057:1:0
STUPID_AMX_REQUIREMENT38 = 33058:1:0
STUPID_AMX_REQUIREMENT39 = 33059:1:0
STUPID_AMX_REQUIREMENT100 = 33100:1:0
STUPID_AMX_REQUIREMENT101 = 33101:1:0
STUPID_AMX_REQUIREMENT102 = 33102:1:0
STUPID_AMX_REQUIREMENT103 = 33103:1:0
STUPID_AMX_REQUIREMENT104 = 33104:1:0
STUPID_AMX_REQUIREMENT105 = 33105:1:0
STUPID_AMX_REQUIREMENT106 = 33106:1:0
STUPID_AMX_REQUIREMENT107 = 33107:1:0
STUPID_AMX_REQUIREMENT108 = 33108:1:0
STUPID_AMX_REQUIREMENT109 = 33109:1:0
STUPID_AMX_REQUIREMENT110 = 33110:1:0
STUPID_AMX_REQUIREMENT111 = 33111:1:0
STUPID_AMX_REQUIREMENT112 = 33112:1:0
STUPID_AMX_REQUIREMENT113 = 33113:1:0
STUPID_AMX_REQUIREMENT114 = 33114:1:0
STUPID_AMX_REQUIREMENT115 = 33115:1:0
STUPID_AMX_REQUIREMENT116 = 33116:1:0
STUPID_AMX_REQUIREMENT117 = 33117:1:0
STUPID_AMX_REQUIREMENT118 = 33118:1:0
STUPID_AMX_REQUIREMENT119 = 33119:1:0
STUPID_AMX_REQUIREMENT120 = 33120:1:0
STUPID_AMX_REQUIREMENT121 = 33121:1:0
STUPID_AMX_REQUIREMENT122 = 33122:1:0
STUPID_AMX_REQUIREMENT123 = 33123:1:0
STUPID_AMX_REQUIREMENT124 = 33124:1:0
STUPID_AMX_REQUIREMENT125 = 33125:1:0
STUPID_AMX_REQUIREMENT126 = 33126:1:0
STUPID_AMX_REQUIREMENT127 = 33127:1:0
STUPID_AMX_REQUIREMENT128 = 33128:1:0
STUPID_AMX_REQUIREMENT129 = 33129:1:0
STUPID_AMX_REQUIREMENT130 = 33130:1:0
STUPID_AMX_REQUIREMENT131 = 33131:1:0
STUPID_AMX_REQUIREMENT132 = 33132:1:0
STUPID_AMX_REQUIREMENT133 = 33133:1:0
STUPID_AMX_REQUIREMENT134 = 33134:1:0
STUPID_AMX_REQUIREMENT135 = 33135:1:0
STUPID_AMX_REQUIREMENT136 = 33136:1:0
STUPID_AMX_REQUIREMENT137 = 33137:1:0
STUPID_AMX_REQUIREMENT138 = 33138:1:0
STUPID_AMX_REQUIREMENT139 = 33139:1:0
STUPID_AMX_REQUIREMENT140 = 33140:1:0
STUPID_AMX_REQUIREMENT141 = 33141:1:0
STUPID_AMX_REQUIREMENT142 = 33142:1:0
STUPID_AMX_REQUIREMENT143 = 33143:1:0
STUPID_AMX_REQUIREMENT144 = 33144:1:0
STUPID_AMX_REQUIREMENT145 = 33145:1:0
STUPID_AMX_REQUIREMENT146 = 33146:1:0
STUPID_AMX_REQUIREMENT147 = 33147:1:0
STUPID_AMX_REQUIREMENT148 = 33148:1:0
STUPID_AMX_REQUIREMENT149 = 33149:1:0

// Virtual devices for inter-module communications
vdvAvInputSelect	= 33051:TP_PORT_AV_INPUT_SELECT:0
vdvAvOutputSelect	= 33051:TP_PORT_AV_OUTPUT_SELECT:0
vdvZoneSelect		= 33051:TP_PORT_ZONE_SELECT:0

// Virtual devices for IP control
vdvIp1			= 33041:1:0

DEFINE_VARIABLE

char	tpConfigFile[] = 'TouchPanels.cfg'
char    avConfigFile[] = 'AudioVideo.cfg'
char    zoneConfigFile[] = 'ZoneConfig.cfg'
char    lutronConfigFile1[] = 'Lutron.cfg'
char    lutronConfigFile2[] = 'LutronAuto.cfg'
char	plexConfigFile[]    = 'Plex.cfg'
char	rokuConfigFile[]    = 'Roku.cfg'
char	dtvConfigFile[]    = 'DirecTV.cfg'
char	itunesConfigFile[]    = 'iTunes.cfg'
char	itachConfigFile[]    = 'iTach.cfg'

//char	weatherZipCode[] = '89451'

char    hvacConfigFile[] = 'Hvac.cfg'
char    automationConfigFile[] = 'Automation.cfg'

char	relayConfigFile[] = 'Relays.cfg'
dev	dvAllRelays[] = { 5001:8:1, 1021:1:1, 1022:1:1 }

char	presetConfigFile[] = 'Presets.cfg'
char	dmxConfigFile[] = 'Dmx.cfg'
char	netBooterConfigFile[] = 'NetBooter.cfg'
char	powerManConfigFile[] = 'Power.cfg'
char	lightingConfigFile[] = 'Lighting.cfg'
char	marantzConfigFile[] = 'Marantz.cfg'
char    wunderConfigFile[]  = 'Wunderground.cfg'
char	japConfigFile[] = 'JustAddPower.cfg'
char	autoPatchConfigFile[] = 'AutoPatchDsp.cfg'

// Unfortunately, we have to hard-code these parameters:
DEFINE_DEVICE
dvJAP_SWITCH   = 0:4:0
vdvJAP_SWITCH  = 33001:1:1
DEFINE_VARIABLE
char JAP_SWITCH_IP[15] = '192.168.189.23';
char JAP_SWITCH_USERNAME[15] = 'cisco';
char JAP_SWITCH_PASSWORD[15] = 'cisco';
char JAP_SWITCH_PRIVILEGED_PASSWORD[15] = '';
char JAP_SWITCH_LICENCE_KEY[256] = 'Wmv7cRxaPdukfjukj1czqZe11PCg6KUG03X0R1DhcnUUD9T4fZmRUreXvxTn+smALTDaDNEIeo7LxbGn';
persistent Char JAP_FAVORITES[][1000] =
{'', '', '', '', '', '', '', ''};

define_module 'JAP_AVSwitch_Cisco_v2_3' jap_switch( vdvJAP_SWITCH, dvJAP_SWITCH,
  JAP_SWITCH_IP, JAP_SWITCH_USERNAME, JAP_SWITCH_PASSWORD,
  JAP_SWITCH_PRIVILEGED_PASSWORD, JAP_SWITCH_LICENCE_KEY, JAP_FAVORITES);

DEFINE_MODULE 'TouchPanel' tps (tpConfigFile)
DEFINE_MODULE 'AvControl' avCtl (avConfigFile,tpConfigFile,vdvAvOutputSelect,vdvZoneSelect)
DEFINE_MODULE 'Plex_Comm' plex (plexConfigFile)
DEFINE_MODULE 'Roku_Comm' roku (rokuConfigFile)
DEFINE_MODULE 'ITunesHttp_Comm' iTunesHttp (itunesConfigFile, tpConfigFile)
DEFINE_MODULE 'DirecTvHttp_Comm' dtvHttp (dtvConfigFile)
DEFINE_MODULE 'ITachHttp_Comm' dtvHttp (itachConfigFile)
DEFINE_MODULE 'ZoneControl' zoneConn (zoneConfigFile, tpConfigFile,vdvZoneSelect,vdvAvOutputSelect)
DEFINE_MODULE 'Lutron_Comm' lutronComm (lutronConfigFile1, lutronConfigFile2)
DEFINE_MODULE 'RelayControl'  relayConn  (relayConfigFile,  tpConfigFile, dvAllRelays)
DEFINE_MODULE 'PresetControl' presetConn (presetConfigFile, tpConfigFile)
//DEFINE_MODULE 'WeatherDotCom_Comm' weatherCom (vdvWeatherStatus,dvWeatherLocal,weatherZipCode)
DEFINE_MODULE 'Wunderground' wunder (wunderConfigFile, tpConfigFile)
DEFINE_MODULE 'Hvac_ViewStat' hvacVst (hvacConfigFile, tpConfigFile)
//DEFINE_MODULE 'Automation' automat (automationConfigFile)
DEFINE_MODULE 'IpControlledDevices_Comm' ipDevices()
DEFINE_MODULE 'Dmx' dmx(dmxConfigFile, tpConfigFile)
DEFINE_MODULE 'NetBooterHttp_Comm' netBooter(netBooterConfigFile)
DEFINE_MODULE 'PowerManagement_UI' powerMan(powerManConfigFile, tpConfigFile)
DEFINE_MODULE 'Lighting_UI' lighting(lightingConfigFile, tpConfigFile)
DEFINE_MODULE 'MarantzHttp_Comm' marantz(marantzConfigFile)
DEFINE_MODULE 'AvMatrixAutoPatchDsp' autoPatch(autoPatchConfigFile)
DEFINE_MODULE 'AvMatrixJustAddPower' jap(japConfigFile)


DEFINE_START

set_pulse_time(3)

DEFINE_EVENT

DEFINE_PROGRAM