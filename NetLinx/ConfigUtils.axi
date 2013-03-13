#if_not_defined __CONFIG_UTILS__
#define __CONFIG_UTILS__


DEFINE_FUNCTION integer parseDev (dev result, char str[])
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
	    return 1
	}
    }
    debug ('ConfigUtils', 1, "'Error processing DEV string: ',str")
    return 0
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
    // Parse a list of positive integers
    integer anInt, count
    for (anInt = atoi(str), count = 0; str != ""; anInt = atoi(str))
    {
	count++
	set_length_array (result, count)
	result[count] = anInt
	if (remove_string(str,',',1) = '')
	    break
    }
}

DEFINE_FUNCTION parseDevList (dev result[], char str[])
{
    // Parse a list of devices
    integer success, count
    dev aDev
    for (success = parseDev(aDev,str), count = 0;
         str != '';
	 success = parseDev(aDev,str))
    {
	count++
	set_length_array (result, count)
	result[count] = aDev
	if (find_string(str,',',1))
	    remove_string(str,',',1)
	else
	    str = ''
    }
}

#end_if // __CONFIG_UTILS__
