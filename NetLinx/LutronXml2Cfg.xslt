<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/Graphics/SVG/SVG-19990812.dtd">

<xsl:output method="text" encoding="UTF-8"/>

<!--
  * This XSLT is intended to be used to process the "small" XML file available 
  * from the Lutron controller or from the Homeworks Illumination GUI 
  * (File Menu... Create XML File... iPhone). The output is a file that can be
  * used with the Lutron_Comm.axs module and should be called LutronAuto.cfg.
  *
  * Various utilities can apply XSLTs. On a Mac, one such utility is 'xsltproc'.
  *
  * For example: To apply the transformation to a Lutron exported file called
  * Eagle_minimum.xml:
  *   xsltproc ../NetLinx/LutronXml2Cfg.xslt Eagle_minimum.xml > LutronAuto.cfg
  -->

<xsl:template match="/">
    <xsl:apply-templates select="HWProject/Area"/>
    <xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="Area">
    <xsl:apply-templates select="Room"/>

[area]
    id=<xsl:value-of select="Id"/>
    name=<xsl:value-of select="Name"/>
    rooms=<xsl:for-each select="Room"><xsl:if test="position()>1">,</xsl:if><xsl:value-of select="Id"/></xsl:for-each>
</xsl:template>

<xsl:template match="Room">
    <xsl:apply-templates select="Outputs/Output"/>
    <xsl:apply-templates select="Inputs/ControlStation"/>

[room]
    id=<xsl:value-of select="Id"/>
    name=<xsl:value-of select="Name"/>
    outputs=<xsl:for-each select="Outputs/Output"><xsl:if test="position()>1">,</xsl:if><xsl:value-of select="Id"/></xsl:for-each>
    inputs=<xsl:for-each select="Inputs/ControlStation"><xsl:if test="position()>1">,</xsl:if><xsl:value-of select="Id"/></xsl:for-each>
</xsl:template>

<xsl:template match="Inputs/ControlStation">

[input]
    id=<xsl:value-of select="Id"/>
    name=<xsl:value-of select="Name"/>
    address=<xsl:value-of select="Devices/Device/Address"/>
   <xsl:choose>
      <xsl:when test="Devices/Device/Type='KEYPAD'">
    type=keypad<xsl:apply-templates select="Devices/Device/Buttons/Button"/></xsl:when>
      <xsl:otherwise>
    type=other</xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:template match="Buttons/Button">
   <xsl:if test="Type!='Not Programmed'">
    button-name-<xsl:value-of select="Number"/>=<xsl:value-of select="Name"/>
   </xsl:if>
</xsl:template>

<xsl:template match="Outputs/Output">

[output]
    id=<xsl:value-of select="Id"/>
    name=<xsl:value-of select="Name"/>
    address=<xsl:value-of select="Address"/>
</xsl:template>

<xsl:template match="*|"/>

</xsl:stylesheet>
