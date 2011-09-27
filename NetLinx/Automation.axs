MODULE_NAME='Automation' (char configFile[])

#include 'Debug.axi'
#include 'AutomationConfig.axi'


DEFINE_VARIABLE

char DBG_MODULE[] = 'Automation'

AutomationInput	gInput


DEFINE_FUNCTION double calcGmtOffset ()
{
    double	result
    char	gmtOffset[10]
    gmtOffset = clkmgr_get_timezone()
    debug (DBG_MODULE, 9, "'GMT timezone offset: ',gmtOffset")
    select
    {
    active (find_string (gmtOffset,'-',1)):
    {
	remove_string (gmtOffset,'-',1)
	result = -(time_to_hour(gmtOffset) + time_to_minute(gmtOffset)/60.0)
    }
    active (find_string (gmtOffset,'+',1)):
    {
	remove_string (gmtOffset,'+',1)
	result = time_to_hour(gmtOffset) + time_to_minute(gmtOffset)/60.0
    }
    active (1):
    {
	debug (DBG_MODULE, 1, "'Error determining GMT timezone offset: ',gmtOffset")
	return 0.0
    }
    } // select
    if (clkmgr_is_daylightsavings_on())
    {
	result = result + 1.0
    }
    return result
}

DEFINE_FUNCTION recalcAstro()
{
    local_var sinteger astroResult
    astroResult = astro_clock (gMainConfig.mLongitude, gMainConfig.mLatitude, calcGmtOffset(), date, 
    		  	       gInput.mSunrise, gInput.mSunset)
    debug (DBG_MODULE, 1, "'astro_clock(',itoa(astroResult),
    	  	           ') Sunrise: ',gInput.mSunrise,'; Sunset: ',gInput.mSunset")
}

DEFINE_START

{
    readConfigFile (DBG_MODULE, configFile)
    rebuild_event()
}
wait 571  // 57.1 seconds
{
    recalcAstro()
}


DEFINE_PROGRAM

wait 35673   // approx once an hour
{
    recalcAstro()
}