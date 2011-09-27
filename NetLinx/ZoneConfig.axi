PROGRAM_NAME='ZoneConfig'

// Zone input and output zone config definitions.
//
// These are used by several modules but must be served up to each module using 
// serialization over TCP. The ZoneConfigServer module will listen for requests 
// for the Zone configuration data.

#if_not_defined __ZONE_CONFIG__
#define __ZONE_CONFIG__

#include 'Debug.axi'
#include 'ConfigServerUtils.axi'

DEFINE_CONSTANT

ZCFG_MAX_ZONES			= 32

// The following are 'per zone'
ZCFG_MAX_AV_OUTPUTS		= 20
ZCFG_MAX_LIGHTING_ZONES		= 20
ZCFG_MAX_HEATING_ZONES		= 5
ZCFG_MAX_BLIND_ZONES		= 10

DEFINE_VARIABLE

volatile integer ZCFG_ZONE_SELECT[] = {
     1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32 }
    // ...should be filled to ZCFG_MAX_ZONES

constant integer ZCFG_ZONE_SELECT_PREV		= 202
constant integer ZCFG_ZONE_SELECT_NEXT		= 203
constant integer ZCFG_ADDRESS_ZONE_SELECT	= 201
constant integer ZCFG_ADDRESS_ZONE_SELECT_PREV	= 202
constant integer ZCFG_ADDRESS_ZONE_SELECT_NEXT	= 203
constant integer ZCFG_ADDRESS_ZONE_NAME		= 211
constant integer ZCFG_ADDRESS_ZONE_SHORT_NAME	= 212

DEFINE_TYPE

structure Zone
{
    integer	mId			// ID for referencing by other objects
    char	mName[32]		// Name for this zone
    char	mShortName[16]		// Short name for this zone
    integer	mOutputIds[ZCFG_MAX_AV_OUTPUTS]  // List of A/V output IDs
    integer	mLightZoneIds[ZCFG_MAX_LIGHTING_ZONES] // List of lighting zone IDs
    integer	mHeatZoneIds[ZCFG_MAX_HEATING_ZONES] // List of heating zone IDs
    integer	mBlindZoneIds[ZCFG_MAX_BLIND_ZONES] // List of blind zone IDs
}

DEFINE_VARIABLE

volatile Zone		gAllZones[ZCFG_MAX_ZONES]
constant integer	READING_NONE = 0
constant integer 	READING_ZONE = 1
volatile integer	gReadMode = READING_NONE
volatile integer	gThisItem = 0


DEFINE_FUNCTION handleHeading (char moduleName[], char heading[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'zone':
    {
	gReadMode = READING_ZONE
	gThisItem = 0
	break
    }
    default:
    {
	debug (moduleName, 0, "'unknown config heading: ',heading")
    }
    }
}

DEFINE_FUNCTION handleProperty (char moduleName[], char propName[], char propValue[])
{    
    debug (moduleName, 8, "'read config property (',propName,'): <',propValue,'>'")
    switch (gReadMode)
    {
    case READING_ZONE:
    {
	switch (propName)
	{
	case 'id':
	{
	    gThisItem = atoi(propValue)
	    if (length_array(gAllZones) < gThisItem)
	    {
		set_length_array(gAllZones, gThisItem)
	    }
	    gAllZones[gThisItem].mId = gThisItem
	    break
	}
	case 'name':
	{
	    gAllZones[gThisItem].mName = propValue
	    if (gAllZones[gThisItem].mShortName = '')
	    {
		// Copy to the short name (may be overridden)
		gAllZones[gThisItem].mShortName = propValue
	    }
	    break
	}
	case 'short-name':
	{
	    gAllZones[gThisItem].mShortName = propValue
	    break
	}
	case 'av-output-ids':
	{
	    stack_var integer outputId
	    stack_var integer count

	    for (outputId = atoi(propValue); 
		 outputId != 0; 
		 outputId = atoi(propValue))
	    {
		count++
		set_length_array (gAllZones[gThisItem].mOutputIds, count)
		gAllZones[gThisItem].mOutputIds[count] = outputId
		if (remove_string (propValue, ',', 1) == '')
		{
		    propValue = ''
		}
	    }
	    break
	}
	case 'lighting-zone-ids':
	{
	    stack_var integer lightZoneId
	    stack_var integer count

	    for (lightZoneId = atoi(propValue); 
		 lightZoneId != 0; 
		 lightZoneId = atoi(propValue))
	    {
		count++
		set_length_array (gAllZones[gThisItem].mLightZoneIds, count)
		gAllZones[gThisItem].mLightZoneIds[count] = lightZoneId
		if (remove_string (propValue, ',', 1) == '')
		{
		    propValue = ''
		}
	    }
	    break
	}
	case 'heating-zone-ids':
	{
	    stack_var integer heatZoneId
	    stack_var integer count

	    for (heatZoneId = atoi(propValue); 
		 heatZoneId != 0; 
		 heatZoneId = atoi(propValue))
	    {
		count++
		set_length_array (gAllZones[gThisItem].mHeatZoneIds, count)
		gAllZones[gThisItem].mHeatZoneIds[count] = heatZoneId
		if (remove_string (propValue, ',', 1) == '')
		{
		    propValue = ''
		}
	    }
	    break
	}
	case 'blind-zone-ids':
	{
	    stack_var integer blindZoneId
	    stack_var integer count

	    for (blindZoneId = atoi(propValue); 
		 blindZoneId != 0; 
		 blindZoneId = atoi(propValue))
	    {
		count++
		set_length_array (gAllZones[gThisItem].mBlindZoneIds, count)
		gAllZones[gThisItem].mBlindZoneIds[count] = blindZoneId
		if (remove_string (propValue, ',', 1) == '')
		{
		    propValue = ''
		}
	    }
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_ZONE
    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}

(*
DEFINE_FUNCTION requestZoneConfig (dev vdvServer, dev vdvClient, char modName[64])
{
    wait 1
    {
	debug ('ZoneConfig', 0, "modName,': Sending request for Zones to ZoneConfigServer'")
	send_command vdvServer, "'?ZONES-',itoa(vdvClient.Port)"
    }
}

DEFINE_FUNCTION unpackZoneConfig (Zone zones[], char buf[], char modName[64])
{
    stack_var long bytes
    stack_var integer size
    
    if (find_string (buf, 'ZONES-', 1))
    {
	remove_string (buf, 'ZONES-', 1)
	size = atoi (buf)
	remove_string (buf, '-', 1)
	bytes = 1
	if (string_to_variable (zones, buf, bytes) = 0)
	{
	    set_length_array (zones, size)
	    debug ('ZoneConfig', 1, "'Successfully unpacked ',itoa(length_array(zones)),' Zones in ',itoa(bytes-1),' bytes'")
	}
	else
	{
	    debug ('ZoneConfig', 0, 'Error unpacking Zones')
	    return
	}
    }
}
*)

#end_if // __ZONE_CONFIG__
