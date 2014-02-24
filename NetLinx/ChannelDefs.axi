PROGRAM_NAME='ChannelDefs'

// Standardized channel definitions. 
//
// In spite of the SNAPI definitions, there is variation between channels used 
// by various components and so we instead use this set of channels as the "standard"
// across our components. The variations occur in IR files and other modules.
// One can either change the IR and module files, or provide a map to fix any
// inconsistencies.
//
// Regarding video players, specifically:
// Not all video players will support all codes, of course. The intention is that
// a single GUI element can display the most common controls and hide/show any
// controls that are only availabel to some players. This way, we can develop
// a consistent and easily "skinnable" user interface for all (or most) video
// players.
//
// Personal thoughts: the SNAPI (and Duet, for that matter) looks like a rush 
// job. It appears that there was a lot of copy/pasting in places such as the 
// reference to "menu button" all over the place (but not everywhere).
// Source inputs are supposedly deprecated but there is nothing to replace them. 
//

#if_not_defined __CHANNEL_DEFS__
#define __CHANNEL_DEFS__

DEFINE_CONSTANT

integer CHAN_PLAY		= 1	// Momentary: Play
integer CHAN_STOP		= 2	// Momentary: Stop
integer CHAN_PAUSE		= 3	// Momentary: Pause
integer CHAN_SKIP_FORWARD	= 4	// Momentary: Next track/chapter
integer CHAN_SKIP_BACKWARD	= 5	// Momentary: Previous track/chapter
integer CHAN_FAST_FORWARD	= 6	// Momentary: Fast forward
integer CHAN_REWIND		= 7	// Momentary: Rewind
integer CHAN_RECORD		= 8	// Momentary: Record
integer CHAN_POWER		= 9	// Momentary: Toggle power (on/off)
integer CHAN_POWER_FB		= 9	// Feedback:  Power status (on/off)
integer CHAN_DIGIT_0		= 10	// Momentary: Press button digit 0
integer CHAN_DIGIT_1		= 11	// Momentary: Press button digit 1
integer CHAN_DIGIT_2		= 12	// Momentary: Press button digit 2
integer CHAN_DIGIT_3		= 13	// Momentary: Press button digit 3
integer CHAN_DIGIT_4		= 14	// Momentary: Press button digit 4
integer CHAN_DIGIT_5		= 15	// Momentary: Press button digit 5
integer CHAN_DIGIT_6		= 16	// Momentary: Press button digit 6
integer CHAN_DIGIT_7		= 17	// Momentary: Press button digit 7
integer CHAN_DIGIT_8		= 18	// Momentary: Press button digit 8
integer CHAN_DIGIT_9		= 19	// Momentary: Press button digit 9
integer CHAN_PLUS_10		= 20	// Momentary: Press button plus 10
integer CHAN_ENTER		= 21	// Momentary: Press button enter (digits)
integer CHAN_CHANNEL_UP         = 22    // Momentary: Channel up
integer CHAN_CHANNEL_DOWN       = 23    // Momentary: Channel down
integer CHAN_VOL_UP             = 24    // Ramping:   Ramp volume up
integer CHAN_VOL_UP_FB          = 24    // Feedback:  Volume ramp up feedback
integer CHAN_VOL_DOWN           = 25    // Ramping:   Ramp volume down
integer CHAN_VOL_DOWN_FB        = 25    // Feedback:  Volume ramp down feedback
integer CHAN_VOL_MUTE		= 26	// Momentary: Mute toggle
integer CHAN_VOL_MUTE_FB        = 26    // Feedback:  Volume mute feedback
integer CHAN_POWER_ON		= 27    // Momentary: Set power on
integer CHAN_POWER_OFF		= 28    // Momentary: Set power off
integer CHAN_POWER_SLAVE_TOGGLE	= 29    // Momentary: Toggle power on for slave TV (connected to AVR)
integer CHAN_POWER_SLAVE_FB	= 29    // Feedback:  Slave TV (connected to AVR) feedback
integer CHAN_POWER_SLAVE_ON	= 30    // Momentary: Set power on for slave TV (connected to AVR)
integer CHAN_POWER_SLAVE_OFF	= 31    // Momentary: Set power on for slave TV (connected to AVR)
integer CHAN_DOT		= 32	// Momentary: Press button dot (.)

integer CHAN_MENU_CANCEL	= 43	// Momentary: Cancel menu
integer CHAN_MENU_MENU		= 44	// Momentary: Main menu
integer CHAN_MENU_UP		= 45	// Momentary: Navigate up
integer CHAN_MENU_DOWN		= 46	// Momentary: Navigate down
integer CHAN_MENU_LEFT		= 47	// Momentary: Navigate left
integer CHAN_MENU_RIGHT		= 48	// Momentary: Navigate right
integer CHAN_MENU_SELECT	= 49	// Momentary: Select menu item
integer CHAN_MENU_EXIT		= 50	// Momentary: Cancel/return/back
integer CHAN_MENU_UP_LT         = 51    // Momentary: Navigate up left button
integer CHAN_MENU_UP_RT         = 52    // Momentary: Navigate up right button
integer CHAN_MENU_DOWN_LT       = 53    // Momentary: Navigate down left button
integer CHAN_MENU_DOWN_RT       = 54    // Momentary: Navigate down right button
integer CHAN_MENU_OPTIONS	= 55	// Momentary: Options menu
integer CHAN_MENU_DISC		= 56	// Momentary: Top level BD/DVD/etc disc menu

integer CHAN_DVR_LIST		= 61	// Momentary: Show DVR recording list
integer CHAN_LIVE_TV            = 62    // Momentary: Skip to live TV
integer CHAN_SLEEP              = 63    // Momentary: Set sleep time
integer CHAN_PLAYLISTS		= 64	// Momentary: Get/refresh the playlists

integer CHAN_INPUT_GENERAL	= 70	// Momentary: Input selection or list navigation
integer CHAN_INPUT_HDMI_1	= 71	// Momentary: Switch to HDMI input 1
integer CHAN_INPUT_HDMI_2	= 72	// Momentary: Switch to HDMI input 2
integer CHAN_INPUT_HDMI_3	= 73	// Momentary: Switch to HDMI input 3
integer CHAN_INPUT_HDMI_4	= 74	// Momentary: Switch to HDMI input 4
integer CHAN_INPUT_HDMI_5	= 75	// Momentary: Switch to HDMI input 5

integer CHAN_SHORT_SKIP_FORWARD  = 81    // Momentary: Short skip forward
integer CHAN_SHORT_SKIP_BACKWARD = 82    // Momentary: Instant replay
integer CHAN_LONG_SKIP_FORWARD   = 83    // Momentary: Long skip forward
integer CHAN_LONG_SKIP_BACKWARD  = 84    // Momentary: Long instant replay
integer CHAN_PLAY_PAUSE_COMBO	 = 85	 // Momentary: Play/Pause combo

integer CHAN_DASH		= 96	// Momentary: '-'
integer CHAN_PLUS_100           = 97    // Momentary: Press button plus 100
integer CHAN_PLUS_1000          = 98    // Momentary: Press button plus 1000
integer CHAN_DISPLAY		= 99    // Momentary: Display
integer CHAN_SUBTITLE		= 100   // Momentary: Toggle subtitles
integer CHAN_INFO		= 101   // Momentary: Program/movie info
integer CHAN_FAVORITES		= 102   // Momentary: Favorites list
integer CHAN_CONTINUE           = 103   // Momentary: Continue
integer CHAN_JUMP               = 104   // Momentary: Jump back to previous channel
integer CHAN_GUIDE		= 105	// Momentary: Program guide
integer CHAN_PAGE_UP		= 106   // Momentary: Scroll page up
integer CHAN_PAGE_DOWN		= 107   // Momentary: Scroll page down
integer CHAN_WIDE_FORMAT	= 108	// Momentary: Wide screen format
integer CHAN_3D			= 109	// Momentary: 3D mode
integer CHAN_SCENE_MENU		= 110	// Momentary: Scene-type selector (eg., music, movie, sports, etc.)
integer CHAN_SCENE_MUSIC	= 111	// Momentary: Explicit scene-type (usually music)
integer CHAN_SCENE_MOVIES	= 112	// Momentary: Explicit scene-type (usually movies)
integer CHAN_SCENE_TV		= 113	// Momentary: Explicit scene-type (usually general TV)
integer CHAN_SCENE_SPORTS	= 114	// Momentary: Explicit Scene-type (usually sports)
integer CHAN_SCENE_UP		= 118   // Momentary: next scene
integer CHAN_SCENE_DOWN		= 119   // Momentary: next scene

integer CHAN_EJECT		= 120	// Momentary: Eject disc
integer CHAN_PICTURE_MODE_1	= 121	// Momentary: Picture mode (usually standard)
integer CHAN_PICTURE_MODE_2	= 122	// Momentary: Picture mode (usually dynamic)
integer CHAN_PICTURE_MODE_3	= 123	// Momentary: Picture mode (usually cinema 1)
integer CHAN_PICTURE_MODE_4	= 124	// Momentary: Picture mode (usually cinema 2)
integer CHAN_PICTURE_MODE_5	= 125	// Momentary: Picture mode (usually cinema 3)
integer CHAN_PICTURE_MODE_6	= 126	// Momentary: Picture mode (usually user defined)
integer CHAN_PICTURE_MODE_7	= 127	// Momentary: Picture mode (usually user defined)
integer CHAN_PICTURE_MODE_8	= 128	// Momentary: Picture mode (usually user defined)
integer CHAN_PICTURE_MODE_9	= 129	// Momentary: Picture mode (usually user defined)

integer CHAN_SHARPNESS_UP	= 131	// Momentary: Sharpness up
integer CHAN_SHARPNESS_DOWN	= 132	// Momentary: Sharpness down
integer CHAN_BRIGHTNESS_UP	= 133	// Momentary: Brightness up
integer CHAN_BRIGHTNESS_DOWN	= 134	// Momentary: Brightness down
integer CHAN_CONTRAST_UP	= 135	// Momentary: Contrast up
integer CHAN_CONTRAST_DOWN	= 136	// Momentary: Contrast down

integer CHAN_GAIN_UP            = 140   // Ramping:   Ramp gain up
integer CHAN_GAIN_UP_FB         = 140   // Feedback:  Gain ramping up feedback
integer CHAN_GAIN_DOWN          = 141   // Ramping:   Ramp gain down
integer CHAN_GAIN_DOWNN_FB      = 141   // Feedback:  Gain ramping down feedback
integer CHAN_GAIN_MUTE_ON       = 143   // Discrete:  Set gain mute on
integer CHAN_GAIN_MUTE_FB       = 143   // Feedback:  Gain mute feedback
integer CHAN_GAIN_MUTE          = 144   // Momentary: Cycle gain mute

integer CHAN_MISC_YELLOW	= 151	// Momentary: Yellow misc button
integer CHAN_MISC_BLUE		= 152	// Momentary: Blue misc button
integer CHAN_MISC_RED		= 153	// Momentary: Red misc button
integer CHAN_MISC_GREEN		= 154	// Momentary: Green misc button

integer CHAN_SOUND_PROGRAM_MISC		= 161	// Momentary: cycle through sound programs
integer CHAN_SOUND_PROGRAM_NEXT		= 162	// Momentary: Next DSP effect
integer CHAN_SOUND_PROGRAM_PREV		= 163	// Momentary: Prev DSP effect
integer CHAN_SOUND_PROGRAM_MOVIE	= 164	// Momentary: cycle through movie sound programs
integer CHAN_SOUND_PROGRAM_MUSIC	= 165	// Momentary: cycle through music sound programs

integer CHAN_SOUND_BOOST		= 171
integer CHAN_SOUND_SURROUND_DECODE	= 172
integer CHAN_SOUND_STRAIGHT		= 173
integer CHAN_SOUND_PURE_DIRECT		= 174

integer CHAN_FRAME_FWD          = 185   // Momentary: Frame forward
integer CHAN_FRAME_REV          = 186   // Momentary: Frame reverse
integer CHAN_SLOW_FWD           = 188   // Momentary: Slow forward
integer CHAN_SLOW_REV           = 189   // Momentary: Slow reverse

integer CHAN_PIP_POS            = 191   // Momentary: Cycle pip position
integer CHAN_PIP_SWAP           = 193   // Momentary: Swap pip
integer CHAN_PIP                = 194   // Momentary: Cycle pip
integer CHAN_PIP_ON             = 195   // Discrete:  Set pip on
integer CHAN_PIP_FB             = 195   // Feedback:  Pip feedback

integer CHAN_VOL_MUTE_ON        = 199   // Discrete:  Set volume mute
integer CHAN_VOL_MUTE_ON_FB     = 199   // Feedback:  Volume mute feedback

integer CHAN_PLAY_FB            = 241   // Feedback:  Play feedback
integer CHAN_STOP_FB            = 242   // Feedback:  Stop feedback
integer CHAN_PAUSE_FB           = 243   // Feedback:  Pause feedback
integer CHAN_SFWD_FB            = 246   // Feedback:  Scan forward feedback
integer CHAN_SREV_FB            = 247   // Feedback:  Scan reverse feedback
integer CHAN_RECORD_FB          = 248   // Feedback:  Record feedback
integer CHAN_SLOW_FWD_FB        = 249   // Feedback:  Slow forward feedback
integer CHAN_SLOW_REV_FB        = 250   // Feedback:  Slow reverse feedback
integer CHAN_DEVICE_ONLINE      = 251   // Feedback:  Device online event
integer CHAN_DATA_INITIALIZED   = 252   // Feedback:  Data initialized event

integer CHAN_MAX_CHANNELS	= 255   // Change this if more channels are added

integer LEVEL_VOLUME		= 1	// 0-255
integer LEVEL_GAIN		= 5	// 0-255

integer CHAN_VOLUME_CHANNELS[] = {
    CHAN_VOL_UP, CHAN_VOL_DOWN, CHAN_VOL_MUTE}

integer CHAN_POWER_CHANNELS[] = {
    CHAN_POWER, CHAN_POWER_ON, CHAN_POWER_OFF, CHAN_POWER_SLAVE_TOGGLE, CHAN_POWER_SLAVE_ON, CHAN_POWER_SLAVE_OFF}

integer CHAN_AVR_ADVANCED[] = {
    CHAN_MENU_MENU,
    CHAN_MENU_UP,
    CHAN_MENU_DOWN,
    CHAN_MENU_LEFT,
    CHAN_MENU_RIGHT,
    CHAN_MENU_SELECT,
    CHAN_MENU_EXIT,
    CHAN_MENU_UP_LT,
    CHAN_MENU_UP_RT,
    CHAN_MENU_DOWN_LT,
    CHAN_MENU_DOWN_RT,
    CHAN_MENU_OPTIONS,
    CHAN_INPUT_GENERAL, 
    CHAN_INPUT_HDMI_1,
    CHAN_INPUT_HDMI_2,
    CHAN_INPUT_HDMI_3,
    CHAN_INPUT_HDMI_4,
    CHAN_INPUT_HDMI_5,
    CHAN_DISPLAY,
    CHAN_FAVORITES,
    CHAN_PAGE_UP,
    CHAN_PAGE_DOWN,
    CHAN_WIDE_FORMAT, 
    CHAN_3D,
    CHAN_SCENE_MENU,
    CHAN_SCENE_MUSIC,
    CHAN_SCENE_MOVIES,
    CHAN_SCENE_SPORTS,
    CHAN_SCENE_TV,
    CHAN_MISC_YELLOW,
    CHAN_MISC_BLUE,
    CHAN_MISC_RED,
    CHAN_MISC_GREEN,
    CHAN_SOUND_PROGRAM_MISC,
    CHAN_SOUND_PROGRAM_NEXT,
    CHAN_SOUND_PROGRAM_PREV,
    CHAN_SOUND_PROGRAM_MOVIE,
    CHAN_SOUND_PROGRAM_MUSIC,
    CHAN_SOUND_BOOST,
    CHAN_SOUND_SURROUND_DECODE,
    CHAN_SOUND_STRAIGHT,
    CHAN_SOUND_PURE_DIRECT
}

DEFINE_TYPE


#end_if // __CHANNEL_DEFS__
