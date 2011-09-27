MODULE_NAME='DirecTvHttp_Comm' (dev     dvHttpControl,
			        dev     dvHttpLocal,
			    	char    httpIp[],
			    	integer httpPort)

// This DirecTV module provides control over a DirecTV server via its HTTP interface.

#include 'Debug.axi'

DEFINE_CONSTANT

DEFINE_DEVICE

DEFINE_VARIABLE

volatile char    DBG_MODULE[] = 'DirecTV HTTP'
volatile char    DIRECTV_HTML_PREFIX[] = {'GET /remote/processKey?key='}
volatile char    DIRECTV_HTML_SUFFIX[1024]
volatile char    DIRECTV_SUPPORTED_CHANNEL_STRS[256][32] = {
    {'play'},				// 1
    {'stop'},				// 2
    {'pause'},				// 3
    {''},{''},				// 4-5
    {'ffwd'},				// 6
    {'rew'},				// 7
    {'record'},				// 8
    {'power'},				// 9
    {'0'},				// 10
    {'1'},				// 11
    {'2'},				// 12
    {'3'},				// 13
    {'4'},				// 14
    {'5'},				// 15
    {'6'},				// 16
    {'7'},				// 17
    {'8'},				// 18
    {'9'},				// 19
    {''},				// 20
    {'enter'},				// 21
    {'chanup'},				// 22
    {'chandown'},			// 23
    {''},{''},{''},			// 24-26
    {'poweron'},			// 27
    {'poweroff'},			// 28
    {''},{''},				// 29-30
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 31-40
    {''},{''},				// 41-42
    {'back'},				// 43
    {'menu'},				// 44
    {'up'},				// 45
    {'down'},				// 46
    {'left'},				// 47
    {'right'},				// 48
    {'select'},				// 49
    {'exit'},				// 50
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 51-60
    {'list'},						// 61
    {''},{''},{''},{''},{''},{''},{''},{''},{''},	// 62-70
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 71-80
    {'advance'},					// 81
    {'replay'},						// 82
    {''},{''},{''},{''},{''},{''},{''},{''},		// 83-90
    {''},{''},{''},{''},{''},				// 91-95
    {'dash'},						// 96
    {''},{''},{''},{''},				// 97-100
    {'info'},						// 101
    {''},{''},						// 102-103
    {'prev'},						// 104
    {'guide'},						// 105
    {''},{''},						// 106-107
    {'format'},						// 108
    {''},{''},						// 109-110
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 111-120
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 121-130
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 131-140
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 141-150
    {'yellow'},						// 151
    {'blue'},						// 152
    {'red'},						// 153
    {'green'},						// 154
    {''},{''},{''},{''},{''},{''},			// 155-160
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 161-170
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 171-180
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 181-190
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 191-200
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 201-210
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 211-220
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 221-230
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 231-240
    {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},	// 241-250
    {''},{''},{''},{''},{''},{''}			// 251-256
}

volatile char recvBuf[1024]
volatile char crlf[] = {$0D,$0A}

DEFINE_LATCHING

DEFINE_MUTUALLY_EXCLUSIVE

DEFINE_FUNCTION sendToHttpServer (char msg[])
{
    ip_client_open (dvHttpLocal.PORT, httpIp, httpPort, IP_TCP)
    debug (DBG_MODULE, 8, "'sending DirecTV message:',DIRECTV_HTML_PREFIX,msg,DIRECTV_HTML_SUFFIX")
    send_string dvHttpLocal, "DIRECTV_HTML_PREFIX,msg,DIRECTV_HTML_SUFFIX"
}

DEFINE_FUNCTION handleHttpResponse (char msg[])
{
    debug (DBG_MODULE, 8, "'got DirecTV response: ',msg")
}

DEFINE_FUNCTION dtvRelayChannel (integer channel)
{
    char msg[32]
    msg = DIRECTV_SUPPORTED_CHANNEL_STRS[push_channel]
    debug (DBG_MODULE, 8, "'button press on channel ',itoa(push_channel),' (',msg,')'")
    if (msg != '')
    {
	sendToHttpServer (msg)
    }
}

DEFINE_EVENT

BUTTON_EVENT[dvHttpControl, 0]
{
    PUSH:		{ dtvRelayChannel (button.input.channel) }
    HOLD[3,REPEAT]:	{ dtvRelayChannel (button.input.channel) }
    RELEASE:		{}
}

CHANNEL_EVENT[dvHttpControl, 0]
{
    ON:
    {
	stack_var char msg[32]
	msg = DIRECTV_SUPPORTED_CHANNEL_STRS[channel.channel]
	if (msg != '')
	{
	    sendToHttpServer (msg)
	}
    }
}

DATA_EVENT[dvHttpControl]
{
    ONLINE:  {}
    OFFLINE: {}
    STRING:  {debug (DBG_MODULE, 9, "'got string: ',data.text")}
    COMMAND: {debug (DBG_MODULE, 9, "'got command: ',data.text")}
}

DATA_EVENT[dvHttpLocal]
{
    ONLINE: {}
    STRING:
    {
	handleHttpResponse (recvBuf)
	clear_buffer recvBuf
    }
    OFFLINE: {}
    ONERROR:
    {
	debug (DBG_MODULE, 1, "'TCP connection error: ',itoa(data.number)")
    }
}


DEFINE_START

debug (DBG_MODULE, 0, "'Starting DirecTV request interface: ',httpIp,':',itoa(httpPort)")
//DIRECTV_HTML_SUFFIX = "'&hold=keyPress HTTP/1.0',crlf,'Host: ',httpIp,':',itoa(httpPort),crlf,'Connection: Keep-Alive',crlf,crlf"
DIRECTV_HTML_SUFFIX = "'&hold=keyPress HTTP/1.0',crlf,'Host: ',httpIp,':',itoa(httpPort),crlf,crlf"
recvBuf = ''
create_buffer dvHttpLocal, recvBuf

