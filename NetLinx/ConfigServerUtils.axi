PROGRAM_NAME='ConfigServerUtils'

// This file is common to all configuration file readers.  Each reader must define
// the functions: handleHeading(), handleProperty().

#if_not_defined __CONFIG_SERVER_UTILS__
#define __CONFIG_SERVER_UTILS__

DEFINE_CONSTANT
CFG_MAX_BUF_LEN = 1024


DEFINE_FUNCTION readConfigFile (char moduleName[], char filename[])
{
    slong	fd
    slong	bytes
    char	line[CFG_MAX_BUF_LEN]
    char	heading[CFG_MAX_BUF_LEN]
    char	propName[CFG_MAX_BUF_LEN]
    char	propValue[CFG_MAX_BUF_LEN]
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

    // Set array lengths to max for easier indexing when reading configs
    lines = 0
    for (bytes = file_read_line (fd, line, CFG_MAX_BUF_LEN);
	 bytes >= 0;
	 bytes = file_read_line (fd, line, CFG_MAX_BUF_LEN))
    {
	lines++
	debug (moduleName, 6, "'read config line: ',line")
	if (bytes > 0)
	{
	    for (skip = 1; (line[skip] = ' ') || (line[skip] = '	'); skip++) {}  // skip whitespace
	    // A valid line either starts with a '[' or has a '='
	    pos = find_string (line, '=', 1)
	    select
	    {
	    active (line[skip] = '#' || line[skip] = ';'):
	    {
	        // Skip comments
		//debug (moduleName, 9, "'skipping comment: ',line")
	    }
	    active (pos):
	    {
		// Found a property
		propName = right_string (line, length_string(line)-skip+1)
		set_length_string (propName, pos-skip)
		propValue = right_string (line, length_string(line)-pos)
		handleProperty (moduleName, propName, propValue)
	    }
	    active ((line[skip] = '[') && (line[length_string(line)] = ']')):
	    {
		// Found a heading
		heading = right_string (line, length_string(line)-skip)
		set_length_string (heading, length_string(heading)-1)
		handleHeading (moduleName, heading)
	    }
	    active (skip < length_string(line)):
	    {
		debug (moduleName, 0, "'erroroneous line in config file: ',line")
	    }
	    } // select
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

DEFINE_FUNCTION
integer getBooleanProp (char propValue[])
{
    lower_string (propValue)
    return (propValue = 'true' || propValue = 't' || propValue = 1)
}

#end_if // __CONFIG_SERVER_UTILS__
