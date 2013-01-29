<?xml version="1.0"?>
<xsl:stylesheet xmlns:indivodoc="http://indivo.org/vocab/xml/documents#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0">
  <xsl:template match="indivodoc:Wellness">
    <Models>
      <Model name="Wellness">
<Field name="measurementDate"><xsl:value-of select="indivodoc:measurementDate/text()"/></Field>
<Field name="reportedBy"><xsl:value-of select="indivodoc:reportedBy/text()"/></Field>
<Field name="dateReported"><xsl:value-of select="indivodoc:dateReported/text()"/></Field>
<Field name="numberOfStepsTaken"><xsl:value-of select="indivodoc:numberOfStepsTaken/text()"/></Field>
<Field name="numberOfHoursSlept"><xsl:value-of select="indivodoc:numberOfHoursSlept/text()"/></Field>
<Field name="numberOfTimesAwakened"><xsl:value-of select="indivodoc:numberOfTimesAwakened/text()"/></Field>
</Model>
    </Models>
  </xsl:template>
</xsl:stylesheet>
