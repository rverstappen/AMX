PROGRAM_NAME='Debug'

#if_not_defined __DEBUG_FUNC__
#define __DEBUG_FUNC__

DEFINE_CONSTANT

DEBUG_LEVEL = 10



DEFINE_FUNCTION debug (char pkgName[], integer dbgLevel, char msg[])
{
    if ((dbgLevel = 0) || ((DEBUG_LEVEL > 0) && (dbgLevel <= DEBUG_LEVEL)))
    {
        send_string 0, "pkgName,'[',itoa(dbgLevel),']: ',msg"
    }
}

DEFINE_FUNCTION char[17] devtoa (dev dv)
{
    return "itoa(dv.number),':',itoa(dv.port),':',itoa(dv.system)"
}

DEFINE_FUNCTION char[17] devchantoa (devchan dvc)
{
    return "itoa(dvc.device.number),':',itoa(dvc.device.port),':',itoa(dvc.device.system),', ',itoa(dvc.channel)"
}


#end_if // __DEBUG_FUNC__
