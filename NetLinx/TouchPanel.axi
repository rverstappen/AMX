PROGRAM_NAME='TouchPanel'

#if_not_defined __TOUCH_PANEL__
#define __TOUCH_PANEL__

DEFINE_CONSTANT

TP_MAX_PANELS = 64
TP_DEV_NUMBER_OFFSET = 10000

TP_STATUS_DISCONNECTED = 0
TP_STATUS_CONNECTED    = 1

DEFINE_FUNCTION integer tpIsIridium (integer tpId)
{
    // For now, all TPs are iRidium
    return 1
}

DEFINE_FUNCTION tpMakeLocalDev (dev result, integer id, integer port)
{
    result = (TP_DEV_NUMBER_OFFSET+id):port:0
}

#end_if // __TOUCH_PANEL__