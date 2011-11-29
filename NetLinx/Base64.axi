PROGRAM_NAME='Encrypt'
(***********************************************************)
(*  FILE CREATED ON: 02/12/2008  AT: 09:05:49              *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 02/12/2008  AT: 09:19:33        *)
(***********************************************************)

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)

#IF_NOT_DEFINED ENCRYPTION_LIBRARY
#DEFINE ENCRYPTION_LIBRARY

DEFINE_VARIABLE

CONSTANT CHAR cBase64Lookup[64] = {'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'} ;

// swiped and modified from the AMX i!-Equipment Monitor module
DEFINE_FUNCTION CHAR[1024] sEncodeBase64(CHAR cDecStr[])	
{
    STACK_VAR CHAR cDecodeStr[1024] ;
    STACK_VAR CHAR cEncodeStr[1024] ;
    STACK_VAR INTEGER nLoop ;
    STACK_VAR CHAR cIdx[4] ;
    STACK_VAR CHAR cByte[3] ;
    STACK_VAR CHAR cChar[4] ;
    
    // Copy string and pad
    cDecodeStr = cDecStr
    IF ((LENGTH_STRING(cDecodeStr) % 3) <> 0)
    {
	cDecodeStr[LENGTH_STRING(cDecodeStr)+1] = 0 ;
	cDecodeStr[LENGTH_STRING(cDecodeStr)+2] = 0 ;
	cDecodeStr[LENGTH_STRING(cDecodeStr)+3] = 0 ;
    }

    // Encode
    FOR (cEncodeStr = "", nLoop = 1; nLoop <= LENGTH_STRING(cDecodeStr); nLoop = nLoop + 3)
    {

	// Get bytes 
	cByte[1] = cDecodeStr[nLoop] ;
	cByte[2] = cDecodeStr[nLoop+1] ;
	cByte[3] = cDecodeStr[nLoop+2] ;
	
	// Get index
	cIdx[1]  =  TYPE_CAST( ((cByte[1] & $FC) >> 2) + 1) ;
	cIdx[2]  =  TYPE_CAST((((cByte[2] & $F0) >> 4) | ((cByte[1] & $03) << 4)) + 1) ;
	cIdx[3]  =  TYPE_CAST((((cByte[3] & $C0) >> 6) | ((cByte[2] & $0F) << 2)) + 1) ;
	cIdx[4]  =  TYPE_CAST(  (cByte[3] & $3F) + 1) ;
	
	// Get chars
	cChar[1] = cBase64Lookup[cIdx[1]] ;
	cChar[2] = cBase64Lookup[cIdx[2]] ;
	cChar[3] = cBase64Lookup[cIdx[3]] ;
	cChar[4] = cBase64Lookup[cIdx[4]] ;

	// Pad?
	IF (LENGTH_STRING(cDecodeStr) < (nLoop+1))
	  cChar[3] = $3D // '=' ;
	IF (LENGTH_STRING(cDecodeStr) < (nLoop+2))
	  cChar[4] = $3D // '=' ;
	
	SET_LENGTH_STRING(cChar, 4) ;
	
	// Build string
	cEncodeStr = "cEncodeStr, cChar" ;
    }
    
    RETURN cEncodeStr ;
}

DEFINE_FUNCTION CHAR[1024] sDecodeBase64(CHAR base64String[])
{
    STACK_VAR CHAR sInput[1024] ;
    STACK_VAR INTEGER nGroupStart ;
    STACK_VAR CHAR sGroup[4] ;
    STACK_VAR CHAR sOut[1024] ;
        
    sInput = base64String ;
    
    // The source must consists of groups with Len of 4 chars
    IF ((LENGTH_STRING(sInput) % 4) <> 0)
    {
	SEND_STRING 0, "'Bad Base64 string.'"
	RETURN "''" ;
    }
    
    FOR(nGroupStart = 1; (nGroupStart + 3) <= LENGTH_STRING(sInput) ; nGroupStart = nGroupStart + 4)
    {
	STACK_VAR CHAR nIdx[4] ;
	STACK_VAR LONG n24Bit ;
	STACK_VAR CHAR cByte[3] ;
	STACK_VAR CHAR nLen ;
	
	// Get group
	sGroup = MID_STRING(sInput, nGroupStart, 4) ;
	
	// Find indexes
	nIdx[1] = FIND_STRING(cBase64Lookup, "sGroup[1]", 1) - 1 ;
	nIdx[2] = FIND_STRING(cBase64Lookup, "sGroup[2]", 1) - 1 ;
	nIdx[3] = FIND_STRING(cBase64Lookup, "sGroup[3]", 1) - 1 ;
	nIdx[4] = FIND_STRING(cBase64Lookup, "sGroup[4]", 1) - 1 ;

	// Concatenate indexes as 6-bit values together in single LONG - calling this 24-bit because that is all we are actually using
	n24Bit = nIdx[1] ;
	n24Bit = (n24Bit << 6) ;
	n24Bit = n24Bit + nIdx[2] ;
	n24Bit = (n24Bit << 6) ;
	n24Bit = n24Bit + nIdx[3] ;
	n24Bit = (n24Bit << 6) ;
	n24Bit = n24Bit + nIdx[4] ;
	
	// break apart into 8-bit values
	cByte[3] = TYPE_CAST(n24Bit) ;
	n24Bit = n24Bit >> 8 ;
	cByte[2] = TYPE_CAST(n24Bit) ;
	n24Bit = n24Bit >> 8 ;
	cByte[1] = TYPE_CAST(n24Bit) ;
	
	// remove pad character bits
	nLen = 3 ;
	IF(sGroup[4] == '=')
	{
	    nLen -- ;
	    IF(sGroup[3] == '=')
		nLen -- ;
	}
	SET_LENGTH_STRING(cByte, nLen) ;
	
	// Add to output string
	sOut = "sOut, cByte" ;
    }         
    
    RETURN sOut;
}

#END_IF