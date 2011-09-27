PROGRAM_NAME='ConfigUtils'

#if_not_defined __CONFIG_UTILS__
#define __CONFIG_UTILS__


DEFINE_FUNCTION parseDev (dev result, char propValue[])
{
    integer  colon1, colon2
    colon1 = find_string (propValue, ':',1)
    if (colon1)
    {
	colon2 = find_string (propValue, ':', colon1+1)
	if (colon2)
	{
	    result.Number = atoi(propValue)
	    result.Port   = atoi(right_string(propValue,length_array(propValue)-colon1+1))
	    result.System = atoi(right_string(propValue,length_array(propValue)-colon2+1))
	    return
	}
    }
    debug ('ConfigUtils', 1, "'Error processing DEV string: ',propValue")
}

DEFINE_FUNCTION integer parseBoolean (char str[])
{
    lower_string(str)
    switch (str)
    {
    case 'true':	return 1
    case 't':		return 1
    case '1':		return 1
    default:		return 0
    }
}

#end_if // __CONFIG_UTILS__
