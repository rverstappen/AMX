PROGRAM_NAME='TouchPanelPorts'

#if_not_defined __TOUCH_PANEL_PORTS__
#define __TOUCH_PANEL_PORTS__

DEFINE_CONSTANT

TP_PORT_MAIN			= 1

TP_PORT_AV_OUTPUT_SELECT	= 4
TP_PORT_AV_OUTPUT_CONTROL	= 5
TP_PORT_AV_INPUT_SELECT		= 6
TP_PORT_AV_INPUT_CONTROL	= 7

TP_PORT_WEATHER			= 17

TP_PORT_ITUNES_PLAYLIST_SELECT	= 18  // Selection from lists
TP_PORT_ITUNES_NOW_PLAYING	= 19  // Now-playing info plus any controls other than standard A/V input controls

TP_PORT_ZONE_SELECT		= 21
TP_PORT_ZONE_CONTROL		= 22

TP_PORT_PRESET_CONTROL		= 23


#end_if // __TOUCH_PANEL_PORTS__