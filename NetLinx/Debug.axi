#if_not_defined __DEBUG_FUNC__
#define __DEBUG_FUNC__

DEFINE_VARIABLE

gDebugLevel = 10

DEFINE_FUNCTION setDebugLevel (integer lev)
{
     gDebugLevel = lev
}

DEFINE_FUNCTION debug (char pkgName[], integer dbgLevel, char msg[])
{
    if ((dbgLevel = 0) || ((gDebugLevel > 0) && (dbgLevel <= gDebugLevel)))
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

DEFINE_FUNCTION sendCommand (char dbgModule[], dev cmdDev, char cmdStr[])
{
    debug (dbgModule, 9, "'send_command ',devtoa(cmdDev),', ',cmdStr")
    send_command cmdDev, cmdStr
}


#end_if // __DEBUG_FUNC__
