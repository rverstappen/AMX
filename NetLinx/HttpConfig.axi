// Think of this as a reusable 'base class' for any HTTP interface. 
// Examples include:
// - Plex Media Server
// - DirecTV


#if_not_defined __HTTP_CONFIG__
#define __HTTP_CONFIG__

DEFINE_CONSTANT

MAX_HTTP_SERVERS = 16	// Max for any given type of HTTP module; total can be more


DEFINE_TYPE

structure HttpConfig
{
    dev		mDevControl		// Device for AMX internal control
    dev		mDevLocal		// For socket connection
    char	mServerIpAddress[16]
    integer	mServerPort
}

DEFINE_FUNCTION setHttpDeviceList (dev dvControls[], HttpConfig httpCfgs[])
{
    integer count
    count = length_array(httpCfgs)
    set_length_array (dvControls, count)
debug('HTTP',9,"'count=',itoa(count)")
    for (; count > 0; count--)
    {
	dvControls[count] = httpCfgs[count].mDevControl
debug('HTTP',9,"'set dev=',devtoa(dvControls[count])")
    }
}


#end_if // __HTTP_CONFIG__
