#if_not_defined __POOL_TP_CHAN_DEFS__
#define __POOL_TP_CHAN_DEFS__


DEFINE_CONSTANT

(*
 * The reason we define most of the addresses as strings is to avoid calling atoi() for every
 * text field update.
 *)

// Display fields for currently selected thermostat
char POOL_ADDRESS_AIR_TEMP[]		= '51'
char POOL_ADDRESS_POOL_TEMP[]		= '61'
char POOL_ADDRESS_POOL_SET_POINT[]	= '62'
char POOL_ADDRESS_POOL_HEAT_STATUS[]	= '63'
char POOL_ADDRESS_POOL_PUMP_STATUS[]	= '64'
char POOL_ADDRESS_POOL_NAME[]		= '64'
char POOL_ADDRESS_SPA_TEMP[]		= '71'
char POOL_ADDRESS_SPA_SET_POINT[]	= '72'
char POOL_ADDRESS_SPA_HEAT_STATUS[]	= '73'
char POOL_ADDRESS_SPA_PUMP_STATUS[]	= '74'
char POOL_ADDRESS_SPA_NAME[]		= '74'
char POOL_ADDRESS_AUX_NAMES[][3] = {
     '81', '82', '83', '84', '85', '86', '87', '88', '89', '90'
}


// Control fields for heating set points
integer POOL_CHAN_POOL_SET_POINT_INCR	= 101
integer POOL_CHAN_POOL_SET_POINT_DECR	= 102
integer POOL_CHAN_SPA_SET_POINT_INCR	= 103
integer POOL_CHAN_SPA_SET_POINT_DECR	= 104

// Control fields for hansling the pool and spa pump circuits
integer POOL_CHAN_POOL_PUMP_STATUS	= 64
integer POOL_CHAN_SPA_PUMP_STATUS	= 74

// Control fields for toggling the aux circuits
integer POOL_CHAN_AUX_OFFSET = 80
integer POOL_CHAN_AUX_1	= 81
integer POOL_CHAN_AUX_2	= 82
integer POOL_CHAN_AUX_3	= 83
integer POOL_CHAN_AUX_4	= 84
integer POOL_CHAN_AUX_5	= 85
integer POOL_CHAN_AUX_6	= 86
integer POOL_CHAN_AUX_7	= 87
integer POOL_CHAN_AUX_8	= 88
integer POOL_CHAN_AUX_9	= 89
integer POOL_CHAN_AUX_10 = 90
integer POOL_CHAN_AUX[] = {
    POOL_CHAN_AUX_1,
    POOL_CHAN_AUX_2,
    POOL_CHAN_AUX_3,
    POOL_CHAN_AUX_4,
    POOL_CHAN_AUX_5,
    POOL_CHAN_AUX_6,
    POOL_CHAN_AUX_7,
    POOL_CHAN_AUX_8,
    POOL_CHAN_AUX_9,
    POOL_CHAN_AUX_10
}

#end_if // __POOL_TP_CHAN_DEFS__

