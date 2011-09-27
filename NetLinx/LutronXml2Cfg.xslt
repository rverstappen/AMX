<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/Graphics/SVG/SVG-19990812.dtd">

<xsl:output method="text" encoding="UTF-8"/>

<xsl:template match="/">
    <xsl:apply-templates select="HWProject/Area"/>
    <xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="Area">
    <xsl:apply-templates select="Room"/>

[area]
    name=<xsl:value-of select="Name"/>
    id=<xsl:value-of select="Id"/>
    rooms=<xsl:for-each select="Room"><xsl:if test="position()>1">,</xsl:if><xsl:value-of select="Id"/></xsl:for-each>
</xsl:template>

<xsl:template match="Room">
    <xsl:apply-templates select="Outputs/Output"/>
    <xsl:apply-templates select="Inputs/ControlStation"/>

[room]
    name=<xsl:value-of select="Name"/>
    id=<xsl:value-of select="Id"/>
    outputs=<xsl:for-each select="Outputs/Output"><xsl:if test="position()>1">,</xsl:if><xsl:value-of select="Id"/></xsl:for-each>
    inputs=<xsl:for-each select="Inputs/ControlStation"><xsl:if test="position()>1">,</xsl:if><xsl:value-of select="Id"/></xsl:for-each>
</xsl:template>

<xsl:template match="Inputs/ControlStation">

[input]
    name=<xsl:value-of select="Name"/>
    id=<xsl:value-of select="Id"/>
    address=<xsl:value-of select="Devices/Device/Address"/>
   <xsl:choose>
      <xsl:when test="Devices/Device/Type='KEYPAD'">
    type=keypad
    keypad-buttons=<xsl:apply-templates select="Devices/Device/Buttons/Button"/></xsl:when>
      <xsl:otherwise>
    type=other</xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:template match="Buttons/Button">
   <xsl:if test="Type!='Not Programmed'">
      <xsl:if test="position()>1">,</xsl:if>
      <xsl:value-of select="Name"/>
   </xsl:if>
</xsl:template>

<xsl:template match="Outputs/Output">

[output]
    name=<xsl:value-of select="Name"/>
    id=<xsl:value-of select="Id"/>
    address=<xsl:value-of select="Address"/>
</xsl:template>

<xsl:template match="*|"/>

</xsl:stylesheet>
