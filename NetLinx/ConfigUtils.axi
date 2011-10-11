PROGRAM_NAME='ConfigUtils'

#if_not_defined __CONFIG_UTILS__
#define __CONFIG_UTILS__


DEFINE_FUNCTION parseDev (dev result, char str[])
{
    integer  colon1, colon2
    colon1 = find_string (str, ':',1)
    if (colon1)
    {
	colon2 = find_string (str, ':', colon1+1)
	if (colon2)
	{
	    result.Number = atoi(str)
	    result.Port   = atoi(right_string(str,length_array(str)-colon1+1))
	    result.System = atoi(right_string(str,length_array(str)-colon2+1))
	    return
	}
    }
    debug ('ConfigUtils', 1, "'Error processing DEV string: ',str")
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

DEFINE_FUNCTION parseIntegerList (integer result[], char str[])
{
    // Parse a list of positive integers (no zeros!)
    integer anInt, count
    for (anInt = atoi(str), count = 0;
         (anInt > 0) && (str != "");
	 anInt = atoi(str))
    {
	count++
	set_length_array (result, count)
	result[count] = anInt
	if (remove_string(str,',',1) = '')
	    break
    }
}

#end_if // __CONFIG_UTILS__
