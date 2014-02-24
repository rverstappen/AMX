#if_not_defined __HTTP_IMPL__
#define __HTTP_IMPL__

// Common HTTP module implementation. Handles HTTP message construction and reply events.
//
// Real modules must provide:
// - a definition of char DBG_MODULE[] = 'ModuleName' before including this file.
// - a definition of the function handleHttpResponse(char msg[]) anywhere in the module.


#include 'HttpConfig.axi'
#include 'Base64.axi'

DEFINE_CONSTANT
integer	MAX_HTTP_LOCAL_PORTS = 20
integer	MAX_HTTP_MSG_LEN = 1024
char	crlf[] = {$0D,$0A}


DEFINE_TYPE
    
structure HttpImpl
{
    char	mHtmlPrefix[512]
    char	mHtmlSuffix[512]
}

structure HttpRequest
{
    integer	mHttpId
    char	mServer[128]
    integer	mPort
    char	mMsg[MAX_HTTP_MSG_LEN]
}

DEFINE_VARIABLE

volatile integer	USE_HTTP_QUEUE
volatile long		HTTP_QUEUE_DELAY
volatile HttpImpl	gHttpImpl[MAX_HTTP_SERVERS]
//volatile dev		gHttpLocalDvPool[]
volatile char		gHttpRecvBuf[MAX_HTTP_SERVERS][1024]
volatile integer	gHttpPoolMap[MAX_HTTP_SERVERS]
volatile HttpRequest	gHttpRequestQueue[MAX_HTTP_LOCAL_PORTS]
volatile char		gHttpMsgSpool[MAX_HTTP_LOCAL_PORTS][MAX_HTTP_MSG_LEN]

DEFINE_FUNCTION sendHttp (HttpConfig http, integer httpId, char enclMsg[])
{
    char msg[MAX_HTTP_MSG_LEN]
    msg = "gHttpImpl[httpId].mHtmlPrefix,enclMsg,gHttpImpl[httpId].mHtmlSuffix"
    debug (DBG_MODULE, 9, "msg")
    debug (DBG_MODULE, 9, "'Check HTTP message length: ',itoa(length_array(msg))")
    if (USE_HTTP_QUEUE)
    {
	enqueueHttp (httpId, http.mServerIpAddress, http.mServerPort, msg)
    }
    else
    {
	sendHttpExec (httpId, http.mServerIpAddress, http.mServerPort, msg)
    }
}

DEFINE_FUNCTION initHttpImpl (integer httpId, HttpConfig http, char prefix[], char innerSuffix[])
{
    char authStr[256]
    debug (DBG_MODULE, 1, 
    	   "'Initializing HTTP interface: ',http.mServerIpAddress,':',itoa(http.mServerPort)")
    if (http.mServerUsername)
    {
	if (http.mServerPassword)
	{
	    authStr = "'Authorization: Basic ',
	    	       sEncodeBase64("http.mServerUsername,':',http.mServerPassword"),crlf"
	}
	else
	{
	    authStr = "'Authorization: Basic ', sEncodeBase64(http.mServerUsername),crlf"
	}
    }
    gHttpImpl[httpId].mHtmlPrefix = prefix
    gHttpImpl[httpId].mHtmlSuffix = "innerSuffix,
		 ' HTTP/1.1',crlf,
		 'Host: ',http.mServerIpAddress,':',itoa(http.mServerPort),crlf,
		 'Connection: close',crlf,
		 authStr,
		 crlf"
}

DEFINE_EVENT

DATA_EVENT[gHttpLocalDvPool]
{
    ONLINE:
    {
	integer poolId
	poolId = get_last(gHttpLocalDvPool)
	debug (DBG_MODULE, 9, "'HTTP connection poolId=',itoa(poolId),' OK'")
	debug (DBG_MODULE, 8, "'sending HTTP message: ', gHttpMsgSpool[poolId]")
	send_string gHttpLocalDvPool[poolId], gHttpMsgSpool[poolId]
    }
    STRING:
    {
	integer poolId, httpId
	poolId = get_last(gHttpLocalDvPool)
	httpId = getHttpId(poolId)
	debug (DBG_MODULE, 9, "'received string from HTTP server ',itoa(httpId),': ',
	      		      gHttpRecvBuf[poolId]")
	handleHttpResponse (httpId, gHttpRecvBuf[poolId])
	gHttpRecvBuf[poolId] = ''
	clear_buffer gHttpRecvBuf[poolId]
	ip_client_close (gHttpLocalDvPool[poolId].port)
    }
    OFFLINE:
    {
        integer poolId
	poolId = get_last(gHttpLocalDvPool)
	debug (DBG_MODULE, 7, "'HTTP connection ',itoa(poolId),' closed'")
	freePoolId(poolId)
    }
    ONERROR:
    {
        integer poolId, httpId
	poolId = get_last(gHttpLocalDvPool)
	debug (DBG_MODULE, 1, "'HTTP connection ',itoa(poolId),' error: ',itoa(data.number)")
	httpId = getHttpId(poolId)
	if (httpId > 0)
	{
	    ip_client_close(gHttpLocalDvPool[poolId].port)
	    freePoolId(poolId)
	}
    }
}

// Use a pool of local sockets for requests so that we can make multiple requests to the same
// server simultaneously.

DEFINE_FUNCTION sendHttpExec (integer httpId, char destServer[], integer destPort, char msg[])
{
    integer poolId
    poolId = getNextPoolId(httpId)
    if (poolId > 0)
    {
	debug (DBG_MODULE, 8, 
	       "'opening HTTP connection to ',destServer,':',itoa(destPort),'[',itoa(httpId),']'")
	ip_client_open (gHttpLocalDvPool[poolId].port, destServer, destPort, IP_TCP)
	gHttpMsgSpool[poolId] = msg
    }
    else
    {
	debug (DBG_MODULE, 3, "'Error: cannot send HTTP message to ',destServer,
	      		       ' because local socket pool is exhausted'")
    }
}

DEFINE_FUNCTION integer getNextPoolId (integer httpId)
{
    integer i
    for (i = length_array(gHttpPoolMap); i > 0; i--)
    {
	if (gHttpPoolMap[i] = 0)
	{
	    gHttpPoolMap[i] = httpId
	    return i
	}
    }
    return 0
}

DEFINE_FUNCTION integer getHttpId (integer poolId)
{
    return gHttpPoolMap[poolId]
}

DEFINE_FUNCTION freePoolId (integer poolId)
{
    gHttpPoolMap[poolId] = 0
}

DEFINE_CONSTANT
TL_HTTP_REQUESTS = 19		// For HTTP msg queue timeline

DEFINE_VARIABLE
integer gQueuePos
long    gTlArray[1] = { 1 }	// Overridden in DEFINE_START, below

DEFINE_FUNCTION enqueueHttp (integer httpId, char destServer[], integer destPort, char msg[])
{
    // Simple queue with NO looping around from back to front. Only when the
    // queue is cleared do we reset to the front.
    integer pos, success
    if (gQueuePos = 0)
    {
	gQueuePos = 1
	pos = 1
	success = 1
    }
    else
    {
	for (pos = gQueuePos + 1; pos <= length_array(gHttpLocalDvPool); pos++)
	{
	    if (gHttpRequestQueue[pos].mHttpId = 0)
	    {
		success = 1
		break
	    }
	}
    }
    if (!success)
    {
	debug (DBG_MODULE, 2,
	       "'Unable to enqueue HTTP message to ',destServer,':',itoa(destPort)")
    }
    else
    {
	gHttpRequestQueue[pos].mHttpId = httpId
	gHttpRequestQueue[pos].mServer = destServer
	gHttpRequestQueue[pos].mPort   = destPort
	gHttpRequestQueue[pos].mMsg    = msg
	debug (DBG_MODULE, 7,
	       "'Successful enqueue of HTTP message to ',destServer,':',itoa(destPort),
	        ' (pos=',itoa(pos),')'")
	if (!timeline_active(TL_HTTP_REQUESTS))
	    timeline_create (TL_HTTP_REQUESTS, gTlArray, 1, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
    }
}

DEFINE_EVENT
TIMELINE_EVENT[TL_HTTP_REQUESTS]
{
    debug (DBG_MODULE, 9, "'Checking HTTP queue for requests'")
    select
    {
    active (gQueuePos > length_array(gHttpRequestQueue)):
    {
	debug (DBG_MODULE, 7,"'Error: TL_HTTP_REQUESTS timeline is active but queue is exhausted!'")
	timeline_kill (TL_HTTP_REQUESTS)
    }	
    active (gQueuePos > 0):
    {
	debug (DBG_MODULE, 8, "'Dequeuing message to ',gHttpRequestQueue[gQueuePos].mServer,
	      		      ' (pos=',itoa(gQueuePos),')'")
	sendHttpExec (gHttpRequestQueue[gQueuePos].mHttpId,
		      gHttpRequestQueue[gQueuePos].mServer,
		      gHttpRequestQueue[gQueuePos].mPort,
		      gHttpRequestQueue[gQueuePos].mMsg)
	gHttpRequestQueue[gQueuePos].mHttpId = 0
	if ((gQueuePos = length_array(gHttpRequestQueue)) || 
	    (gHttpRequestQueue[gQueuePos+1].mHttpId = 0))
	{
	    // Queue is empty; stop timline
	    gQueuePos = 0
	    timeline_kill (TL_HTTP_REQUESTS)
	}
	else
	{
	    // Set up for next TL event
	    gQueuePos++
	}
    }
    active (1):
    {
	debug (DBG_MODULE, 7,"'Error: TL_HTTP_REQUESTS timeline is active but queue is empty!'")
	timeline_kill (TL_HTTP_REQUESTS)
    }
    } // select
}


DEFINE_START
USE_HTTP_QUEUE = 0
HTTP_QUEUE_DELAY = 111  // milliseconds; can be overridden
wait 33 { gTlArray[1] = HTTP_QUEUE_DELAY }
set_length_array(gHttpPoolMap,		length_array(gHttpLocalDvPool))
set_length_array(gHttpRecvBuf,		length_array(gHttpLocalDvPool))
set_length_array(gHttpRequestQueue,	length_array(gHttpLocalDvPool))
{
    integer poolId
    for (poolId = 1; poolId <= length_array(gHttpLocalDvPool); poolId++)
    {
    	create_buffer gHttpLocalDvPool[poolId], gHttpRecvBuf[poolId]
    }
}

#end_if // __HTTP_IMPL__
