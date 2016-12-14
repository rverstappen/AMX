#if_not_defined __AV_MATRIX_UTIL__
#define __AV_MATRIX_UTIL__

DEFINE_CONSTANT

AV_MATRIX_MAX_INPUTS	= 32
AV_MATRIX_MAX_OUTPUTS	= 64


DEFINE_TYPE
structure AvMatrixMapping
{
    integer	mInput
    integer	mOutputs[AV_MATRIX_MAX_OUTPUTS]
}


DEFINE_FUNCTION
createMatrixMappingSingle (AvMatrixMapping mappings[], integer input, integer output)
{
    set_length_array(mappings,1)
    set_length_array(mappings[1].mOutputs,1)
    debug (DBG_MODULE, 10, "'createMatrixMappingSingle: ',itoa(input),'>',itoa(output)")
    mappings[1].mInput = input
    mappings[1].mOutputs[1] = output

}

DEFINE_FUNCTION
createMatrixMappingMultiple (AvMatrixMapping mappings[], integer input, integer outputs[])
{
    set_length_array(mappings,1)
    set_length_array(mappings[1].mOutputs,length_array(outputs))
    mappings[1].mInput = input
    mappings[1].mOutputs = outputs
}

DEFINE_FUNCTION
encodeMatrixMappingSingle (char msg[], integer input, integer output)
{
    AvMatrixMapping mappings[1]
    createMatrixMappingSingle (mappings, input, output)
    debug (DBG_MODULE, 10, "'encoding matrix mappings with ',itoa(length_array(mappings)),' mappings'")
    debugMatrix (mappings)
    encodeMatrixMappings(msg, mappings)
}

DEFINE_FUNCTION
encodeMatrixMappingMultiple (char msg[], integer input, integer outputs[])
{
    AvMatrixMapping mappings[1]
    createMatrixMappingMultiple (mappings, input, outputs)
    encodeMatrixMappings(msg, mappings)
}

DEFINE_FUNCTION
encodeMatrixMappings (char msg[], AvMatrixMapping mappings[])
{
    if (variable_to_xml (mappings,msg,1,0) != 0)
    {
	debug (DBG_MODULE, 1, "'Error encoding matrix mapping: ',msg")
	msg = ""
    }
}

DEFINE_FUNCTION
decodeMatrixMappings (char msg[], AvMatrixMapping mappings[])
{
    if (xml_to_variable (mappings,msg,1,0) != 0)
    {
	debug (DBG_MODULE, 1, "'Error decoding matrix mappings: ',msg")
	set_length_array(mappings,0)
    }
}

DEFINE_FUNCTION
encodeOutputOffSingle(char msg[], integer output)
{
    msg = "'POWER-OFF:O', itoa(output)"
}

DEFINE_FUNCTION
encodeOutputAbsoluteVolume(char msg[], integer output, sinteger vol)
{
    msg = "'SET-VOLUME:O', itoa(output), '>', itoa(vol)"
}

DEFINE_FUNCTION
encodeOutputRelativeVolume(char msg[], integer output, sinteger vol)
{
    msg = "'ADJ-VOLUME:O', itoa(output), '>', itoa(vol)"
}

DEFINE_FUNCTION debugMatrix(AvMatrixMapping mappings[])
{
    integer i, numInputs
    numInputs = length_array(mappings)
    debug (DBG_MODULE, 9, "'Dumping matrix with ',itoa(numInputs),' inputs:'")
    for (i = 1; i <= numInputs; i++)
    {
	integer o, numOutputs
	numOutputs = length_array(mappings[i].mOutputs)
	for (o = 1; o <= numOutputs; o++)
	{
	    debug (DBG_MODULE, 9, "'  ',itoa(mappings[i].mOutputs[o]),' => ',itoa(mappings[i].mInput)")
	}
    }
}

#end_if // __AV_MATRIX_UTIL__
