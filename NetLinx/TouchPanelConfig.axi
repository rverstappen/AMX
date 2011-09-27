PROGRAM_NAME='TouchPanelConfig'

#if_not_defined __TOUCH_PANEL_CONFIG__
#define __TOUCH_PANEL_CONFIG__

#include 'Debug.axi'
#include 'ConfigUtils.axi'
#include 'ConfigServerUtils.axi'


DEFINE_CONSTANT

TP_MAX_PANELS		= 64

TP_STATUS_OFF		= 0
TP_STATUS_ON		= 1

// The following are really for the implementation
TP_CFG_MAX_BUF_LEN	= 1000
TP_READING_NONE		= 0
TP_READING_PANEL	= 1


DEFINE_TYPE

structure TouchPanel
{
    integer	mId		// AMX Touch Panel ID (e.g. 10001)
    char	mName[32]	// TP device name
    integer	mIsIridium	// Whether the TP is an Iridium app running on iPhone/iPod/iPad
}

DEFINE_VARIABLE

volatile integer gTpReadMode = TP_READING_NONE

DEFINE_FUNCTION tpMakeLocalDevArray (dev result[], TouchPanel panels[], integer port)
{
    integer i
    set_length_array (result, length_array(panels))
    for (i = length_array(panels); i > 0; i--)
    {
	result[i] = panels[i].mId:port:0
    }
}

DEFINE_FUNCTION integer tpIsIridium (TouchPanel panels[], integer tpId)
{
    return panels[tpId].mIsIridium
}

DEFINE_FUNCTION tpReadConfigFile (char moduleName[], char filename[], TouchPanel panels[])
{
    slong	fd
    slong	bytes
    char	line[TP_CFG_MAX_BUF_LEN]
    char	heading[TP_CFG_MAX_BUF_LEN]
    char	propName[TP_CFG_MAX_BUF_LEN]
    char	propValue[TP_CFG_MAX_BUF_LEN]
    integer	lines
    integer	skip
    integer	pos

    fd = file_open (filename, FILE_READ_ONLY)
    if (fd < 0)
    {
	debug (moduleName, 1, "'error opening config file (',filename,'): ',itoa(fd)")
	return
    }
    debug (moduleName, 3, "'sucessfully opened config file (',filename,')'")
    set_length_array (panels, 0)

    // Set array lengths to max for easier indexing when reading configs
    lines = 0
    for (bytes = file_read_line (fd, line, TP_CFG_MAX_BUF_LEN);
	 bytes >= 0;
	 bytes = file_read_line (fd, line, TP_CFG_MAX_BUF_LEN))
    {
	lines++
	debug (moduleName, 6, "'read config line: ',line")
	if (bytes > 0)
	{
	    for (skip = 1; (line[skip] = ' ') || (line[skip] = '	'); skip++) {}  // skip whitespace
	    // A valid line either starts with a '[' or has a '='
	    pos = find_string (line, '=', 1)
	    if (pos)
	    {
		// Found a property
		propName = right_string (line, length_string(line)-skip+1)
		set_length_string (propName, pos-skip)
		propValue = right_string (line, length_string(line)-pos)
		tpHandleProperty (moduleName, propName, propValue, panels)
	    }
	    else if ((line[skip] = '[') && (line[length_string(line)] = ']'))
	    {
		// Found a heading
		heading = right_string (line, length_string(line)-skip)
		set_length_string (heading, length_string(heading)-1)
		tpHandleHeading (moduleName, heading, panels)
	    }
	    else if (skip < length_string(line))
	    {
		debug (moduleName, 0, "'erroroneous line in config file: ',line")
	    }
	}
    }
    if (bytes == -9) // EOF
    {
	debug (moduleName, 4, "'sucessfully read ',itoa(lines),' lines of config file (',filename,')'")
	file_close (fd)
    }
    else
    {
	debug (moduleName, 1, "'error reading config file (',filename,'): ',itoa(bytes)")
	return
    }
}


DEFINE_FUNCTION tpHandleHeading (char moduleName[], char heading[], TouchPanel panels[])
{
    debug (moduleName, 8, "'read config heading: <',heading,'>'")
    switch (heading)
    {
    case 'touch-panel':
    {
	gTpReadMode = TP_READING_PANEL
    	set_length_array (panels, length_array(panels)+1)
	break
    }
    default:
    {
	debug (moduleName, 0, "'unknown config heading: ',heading")
	gTpReadMode = TP_READING_NONE
    }
    }
}

DEFINE_FUNCTION tpHandleProperty (char moduleName[], char propName[], char propValue[], TouchPanel panels[])
{    
    debug (moduleName, 8, "'read config property (',propName,'): <',propValue,'>'")
    switch (gTpReadMode)
    {
    case TP_READING_PANEL:
    {
	switch (propName)
	{
	case 'id':
	{
	    panels[length_array(panels)].mId = atoi(propValue)
	    break
	}
	case 'name':
	{
	    panels[length_array(panels)].mName = propValue
	    break
	}
	case 'iridium':
	{
	    panels[length_array(panels)].mIsIridium = parseBoolean(propValue)
	    break
	}
	default:
	{
	    debug (moduleName, 0, "'Unhandled property: ',propName")
	    break
	}
	break
	} // inner switch
    } // case READING_OUTPUT
    default:
    {
	debug (moduleName, 1, "'error: property with no heading (',propName,'): <',propValue,'>'")
    }
    }
}


#end_if // __TOUCH_PANEL_CONFIG__
