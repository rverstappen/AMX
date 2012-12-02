#if_not_defined __LIGHTING_COMMON__
#define __LIGHTING_COMMON__

DEFINE_CONSTANT

LIGHTING_MAX_OUTPUTS	= 300
LIGHTING_MAX_INPUTS	= 300
LIGHTING_MAX_BUTTONS	= 32

DEFINE_TYPE

structure LightingControlButton
{
    integer	mId
    char	mName[32]
    char	mShortName[16]
}

structure LightingControl
{
    integer		mId
    char		mName[32]
    char		mShortName[16]
    LightingControlButton	mButtons[LIGHTING_MAX_BUTTONS]
}


#end_if // __LIGHTING_COMMON__
