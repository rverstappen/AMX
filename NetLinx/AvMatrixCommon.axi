#if_not_defined __AV_MATRIX_COMMON__
#define __AV_MATRIX_COMMON__

#include 'AvMatrixConfig.axi'
#include 'AvMatrixUtil.axi'


DEFINE_EVENT
DATA_EVENT[gGeneral.mDevControl]
{
    ONLINE: { debug (DBG_MODULE,1,"gGeneral.mDevControl,' is ONLINE'") }
    OFFLINE: { debug (DBG_MODULE,1,"gGeneral.mDevControl,' is OFFLINE'") }
    COMMAND:
    {
	debug (DBG_MODULE,2,"'Received AV control command (',devtoa(gGeneral.mDevControl),'): ',data.text")
	handleMatrixControlCommand (data.text)
    }
    STRING:
    {
	debug (DBG_MODULE,2,"'Received AV control string (',devtoa(gGeneral.mDevControl),'): ',data.text")
	handleMatrixControlString (data.text)
    }
}

DEFINE_FUNCTION handleMatrixControlCommand(char cmd[])
{
    AvMatrixMapping mappings[AV_MATRIX_MAX_OUTPUTS]
    select
    {
    active (find_string(cmd,'SWITCH:',1)):
    {
	remove_string(cmd,'SWITCH:',1)
	set_length_array(mappings,atoi(cmd))
	remove_string(cmd,':',1)
	debug (DBG_MODULE, 7, 'Start processing switch command:')
	decodeMatrixMappings (cmd, mappings)
	debugMatrix (mappings)
	handleMatrixSwitch (mappings)
    } // active
    active (find_string(cmd,'POWER-OFF:',1)):
    {
        char     ioChar
	integer  inputOrOutput
        remove_string(cmd,'POWER-OFF:',1)
	ioChar = cmd[1]
	cmd = right_string(cmd,length_array(cmd)-1)
	inputOrOutput = atoi(cmd)
	debug (DBG_MODULE, 7, "'Turning off ',ioChar,itoa(inputOrOutput)")
	if (ioChar == 'O')
        {
	    setAbsoluteOff(inputOrOutput)
        }
    }
    active (find_string(cmd,'SET-VOLUME:',1)):
    {
        char     ioChar
	integer  inputOrOutput
	sinteger lev
        remove_string(cmd,'SET-VOLUME:',1)
	ioChar = cmd[1]
	cmd = right_string(cmd,length_array(cmd)-1)
	inputOrOutput = atoi(cmd)
        remove_string(cmd,'>',1)
	lev = atoi(cmd)
	debug (DBG_MODULE, 7, "'Setting volume for ',ioChar,itoa(inputOrOutput),' to level ',itoa(lev)")
	if (ioChar == 'O')
        {
	    setAbsoluteVolume(inputOrOutput, lev)
        }
	else if (ioChar == 'I')
        {
	    setAbsoluteGain(inputOrOutput, lev)
        }
    }
    active (find_string(cmd,'ADJ-VOLUME:',1)):
    {
        char     ioChar
	integer  inputOrOutput
	sinteger lev
        remove_string(cmd,'ADJ-VOLUME:',1)
	ioChar = cmd[1]
	cmd = right_string(cmd,length_array(cmd)-1)
	inputOrOutput = atoi(cmd)
        remove_string(cmd,'>',1)
	lev = atoi(cmd)
	debug (DBG_MODULE, 7, "'Setting volume for ',ioChar,itoa(inputOrOutput),' by ',itoa(lev)")
	if (ioChar == 'O')
        {
	    setRelativeVolume(inputOrOutput, lev)
        }
	else if (ioChar == 'I')
        {
	    setRelativeGain(inputOrOutput, lev)
        }
    }
    active (find_string(cmd,'STATUS?',1)):
    {
	handleMatrixStatusRequest()
    } // active
    } // select
}

DEFINE_FUNCTION handleMatrixControlString(char msg[])
{
}

DEFINE_FUNCTION sendMatrixStatusReply (AvMatrixMapping mappings[])
{
    char msg[1024]
    debugMatrix(mappings)
    encodeMatrixMappings (msg, mappings)
    sendString (DBG_MODULE, gGeneral.mDevAv, "'STATUS:',msg")
}

#end_if // __AV_MATRIX_COMMON__
