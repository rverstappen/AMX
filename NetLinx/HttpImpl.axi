#if_not_defined __HTTP_IMPL__
#define __HTTP_IMPL__

// Common HTTP module implementation. Handles HTTP message construction and reply events.
//
// Real modules must provide:
// - a definition of char DBG_MODULE[] = 'ModuleName' before including this file.
// - a definition of the function handleHttpResponse(char msg[]) anywhere in the module.


#include 'HttpConfig.axi'


DEFINE_TYPE
    
structure HttpImpl
{
    char	mHtmlPrefix[512]
    char	mHtmlSuffix[512]
    char	mRecvBuf[1024]
}

DEFINE_VARIABLE

volatile HttpImpl	gHttpImpl[MAX_HTTP_SERVERS]
volatile dev		gHttpLocalDv[MAX_HTTP_SERVERS]
volatile char		crlf[] = {$0D,$0A}


DEFINE_FUNCTION sendHttp (HttpConfig http, integer httpId, char msg[])
{
    ip_client_open (http.mDevLocal.port, http.mServerIpAddress, http.mServerPort, IP_TCP)
    debug (DBG_MODULE, 8, "'sending HTTP message:',
	  	                 gHttpImpl[httpId].mHtmlPrefix,msg,gHttpImpl[httpId].mHtmlSuffix")
    send_string http.mDevLocal, "gHttpImpl[httpId].mHtmlPrefix,msg,gHttpImpl[httpId].mHtmlSuffix"
}

DEFINE_FUNCTION initHttpImpl (integer httpId, HttpConfig http, char prefix[], char innerSuffix[])
{
    debug (DBG_MODULE, 1, "'Initializing HTTP interface: ',http.mServerIpAddress,':',itoa(http.mServerPort)")
    gHttpImpl[httpId].mHtmlPrefix = prefix
    gHttpImpl[httpId].mHtmlSuffix = "innerSuffix,
		 ' HTTP/1.0',crlf,
		 'Host: ',http.mServerIpAddress,':',itoa(http.mServerPort),crlf,
		 'Connection: Keep-Alive',crlf,crlf"
    gHttpImpl[httpId].mRecvBuf = ''
    gHttpLocalDv[httpId] = http.mDevLocal
}

DEFINE_EVENT

DATA_EVENT[gHttpLocalDv]
{
    ONLINE: { debug (DBG_MODULE, 9, "'HTTP connection ',itoa(get_last(gHttpLocalDv)),' OK'")  }
    STRING:
    {
	integer httpId
	httpId = get_last(gHttpLocalDv)
	debug (DBG_MODULE, 9, "'received string from HTTP server ',itoa(httpId),': ',
	      		      gHttpImpl[httpId].mRecvBuf")
	handleHttpResponse (gHttpImpl[httpId].mRecvBuf)
	gHttpImpl[httpId].mRecvBuf = ''
	clear_buffer gHttpImpl[httpId].mRecvBuf
    }
    OFFLINE:
    {
	debug (DBG_MODULE, 7, "'HTTP connection ',itoa(get_last(gHttpLocalDv)),' closed'")
    }
    ONERROR:
    {
	debug (DBG_MODULE, 1, "'HTTP connection ',itoa(get_last(gHttpLocalDv)),' error: ',itoa(data.number)")
    }
}



#end_if // __HTTP_IMPL__
