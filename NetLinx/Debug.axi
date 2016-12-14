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
	char subMsg[256]
	integer len, subMsgLen
	len = length_array(msg)
        while (len > 0)
	{
	    subMsg = left_string(msg,256)
	    subMsgLen = length_array(subMsg)
	    len = len - subMsgLen
	    msg = right_string(msg,len)
	    send_string 0, "pkgName,'[',itoa(dbgLevel),']: ',subMsg"
     	}
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

DEFINE_FUNCTION sendString (char dbgModule[], dev strDev, char str[])
{
    debug (dbgModule, 9, "'send_string ',devtoa(strDev),', ',str")
    send_string strDev, str
}

DEFINE_FUNCTION sendLevel (char dbgModule[], dev cmdDev, integer lev, integer value)
{
    debug (dbgModule, 9, "'send_level ',devtoa(cmdDev),', ',itoa(lev),', ',itoa(value)")
    send_level cmdDev, lev, value
}

DEFINE_FUNCTION sendPulse (char dbgModule[], dev cmdDev, integer chan)
{
    debug (dbgModule, 9, "'pulse[',devtoa(cmdDev),', ',itoa(chan),']'")
    pulse[cmdDev, chan]
}


#end_if // __DEBUG_FUNC__
