// Central A/V power control.  Turns off switchers and amps when not in use.

#if_not_defined __AV_CTL_POWER__
#define __AV_CTL_POWER__

// Note: We assume that the following global variables are already defined:
// dev		gGlobalPowerDevs[]
// integer	gGlobalPowerTimeout

#include 'Debug.axi'

DEFINE_VARIABLE
// Track feedback status of powered devices:
volatile integer gPowerStatus[AVCFG_MAX_GLOBAL_POWER_DEVS]

DEFINE_FUNCTION integer avEnsurePowerOn()
{
    if (avPowerStatus())
    {
        return AVCFG_POWER_STATE_ON
    }
    else
    {
	avPowerUp(1)
	return AVCFG_POWER_STATE_POWERING_UP
    }
}

DEFINE_FUNCTION integer avPowerStatus()
{
    integer i
    for (i = 1; i <= length_array(gGlobalPowerDevs); i++)
    {
	if (!gPowerStatus[i])
	    return 0
    }
    return 1
}

DEFINE_FUNCTION avPowerUp (integer force)
{
    integer i
    debug (DBG_MODULE, 1, 'Powering up all central A/V devices')
    for (i = 1; i <= length_array(gGlobalPowerDevs); i++)
    {
	if (force || !gPowerStatus[i])
	    avSendPowerCmd (gGlobalPowerDevs[i], 1)
    }
}

DEFINE_FUNCTION avPowerDown()
{
    integer i
    debug (DBG_MODULE, 1, 'Powering down all central A/V devices')
    for (i = 1; i <= length_array(gGlobalPowerDevs); i++)
    {
	avSendPowerCmd (gGlobalPowerDevs[i], 0)
    }
}

DEFINE_FUNCTION avSendPowerCmd (dev cmdDev, integer onOff)
{
    debug (DBG_MODULE, 8,
    	   "'sending power control command to ',devtoa(cmdDev),', ',itoa(onOff)")
    send_command cmdDev, "'POWER=>',itoa(onOff)"
}


// Timeline management.
// The A/V system will be powered down if no outputs are being used for a certain time.

DEFINE_VARIABLE

constant long   TL_POWER_DOWN = 11
long	 	gTlArray[1] = { 1 }  // Overridden at start-up

DEFINE_FUNCTION avStartPowerDownTimer()
{
    if (gGlobalPowerTimeout > 0)
    {
	debug (DBG_MODULE, 2,
	       "'Starting A/V power down timer: ',itoa(gGlobalPowerTimeout),' seconds'")
	gTlArray[1] = 1000 * gGlobalPowerTimeout
	if (timeline_active (TL_POWER_DOWN))
	    timeline_restart (TL_POWER_DOWN)
	else
	    timeline_create (TL_POWER_DOWN, gTlArray, 1, TIMELINE_ABSOLUTE, TIMELINE_ONCE)
    }
}

DEFINE_FUNCTION avCancelPowerDownTimer()
{
    if (timeline_active (TL_POWER_DOWN))
    {
	debug (DBG_MODULE, 2, "'YYYYYYYYYYYYY Stopping A/V power down'")
	timeline_kill (TL_POWER_DOWN)
    }
}

DEFINE_EVENT
TIMELINE_EVENT[TL_POWER_DOWN]
{
    debug (DBG_MODULE, 1, "'XXXXXXXXXXXXXX Powering down A/V system...'")
    avPowerDown()
}

CHANNEL_EVENT[gGlobalPowerDevs, 0]
{
    ON:  { updatePowerStatus(get_last(gGlobalPowerDevs), AVCFG_POWER_STATE_ON)  }
    OFF: { updatePowerStatus(get_last(gGlobalPowerDevs), AVCFG_POWER_STATE_OFF) }
}

DEFINE_FUNCTION updatePowerStatus (integer devId, integer pState)
{
    debug (DBG_MODULE, 3,
    	   "'Got status update for ',devtoa(gGlobalPowerDevs[devId]),': ',itoa(pState)")
    gPowerStatus[devId] = pState
}


#end_if // __AV_CTL_POWER__
