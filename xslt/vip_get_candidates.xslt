<?xml version="1.0" encoding="ISO-8859-1"?>
<!-- Edited by XMLSpy® -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/vip_object">
		<vip_object schemaVersion="2.1">
		<xsl:copy-of select="/vip_object/ballot"/>
		<xsl:copy-of select="/vip_object/candidate"/>
		<xsl:copy-of select="/vip_object/contest"/>
		<xsl:copy-of select="/vip_object/referendum"/>
	</vip_object>
	</xsl:template>
</xsl:stylesheet>
