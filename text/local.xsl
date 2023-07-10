<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:p5="http://www.tei-c.org/ns/1.0"
		xmlns:xh="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		version="1.0">

  <xsl:import href="../../../lib/xslt/p5_to_html.xsl"/>

  <xsl:output encoding="us-ascii"/>

  <xsl:variable name="siteroot" select="'..'"/>
  
  <xsl:template name="inject-css-link">
    <xsl:element name="link" namespace="{$xhtmlns}">
      <xsl:attribute name="rel">stylesheet</xsl:attribute>
      <xsl:attribute name="href">local.css</xsl:attribute>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="p5:div[@type='abstract']">
    <xsl:apply-imports/>
    <xsl:element name="hr" namespace="{$xhtmlns}"/>
  </xsl:template>
  
  <xsl:template match="p5:div[starts-with(@n, '§') and not(p5:head)]">
    <xsl:element name="div" namespace="{$xhtmlns}">    
      <xsl:element name="h4" namespace="{$xhtmlns}">
        <xsl:value-of select="@n"/>
      </xsl:element>
      <xsl:apply-imports/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="p5:front[not(p5:divGen[@type='toc'])]">
    <xsl:apply-imports/>
    <xsl:call-template name="generate-toc"/>
    <xsl:element name="hr" namespace="{$xhtmlns}"/>
  </xsl:template>

  <xsl:template match="p5:note[@type='block']" priority="1" >
    <xsl:element name="div">
      <xsl:attribute name="class">
	<xsl:value-of select=" 'blocknote' "/>
      </xsl:attribute>
      <xsl:attribute name="style">
	<xsl:text>margin: 1em 2em; padding: 1em;
	background-color: #DEDEDE;
	border: 2px solid navy;
	</xsl:text>
      </xsl:attribute>
   <xsl:apply-templates/>
  </xsl:element>  
  </xsl:template>

  <xsl:template match="p5:epigraph" priority="1" >
    <xsl:element name="div">
      <xsl:attribute name="class">
	<xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:attribute name="style">
	<xsl:text>margin-top: 12 pt; text-align:left; margin-left: 30%</xsl:text>
      </xsl:attribute>
   <xsl:apply-templates/>
  </xsl:element>  
  </xsl:template>
  
 <xsl:template match="p5:epigraph/p5:q">
  <xsl:element name="div">
   <xsl:attribute name="class">epiquote</xsl:attribute>
   <xsl:apply-templates/>
  </xsl:element>  
 </xsl:template>
  
 <xsl:template match="p5:epigraph/p5:q/p5:p">
  <xsl:element name="div">
   <xsl:attribute name="class">epipara</xsl:attribute>
   <xsl:apply-templates/>
  </xsl:element>  
 </xsl:template>
  
 <xsl:template match="p5:epigraph/p5:bibl" priority="1"  name="epigraph-bibl">
  <xsl:element name="div">
   <xsl:attribute name="style">
    <xsl:text>margin-top: 12 pt; text-align:right; margin-left: 10%; margin-right: 10%; font-size: 80%;</xsl:text>
   </xsl:attribute>
   <xsl:apply-templates/>
  </xsl:element>  
 </xsl:template>

  <xsl:template match="p5:list[@type='simple']">
    <xsl:call-template name="bulleted-list"/>
  </xsl:template>

  <xsl:template match="p5:item/p5:p">
    <xsl:element name="p" namespace="{$xhtmlns}">
      <xsl:attribute name="class">p</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="p5:listBibl/p5:bibl">
    <xsl:element name="div" namespace="{$xhtmlns}">
      <xsl:attribute name="class">bibitem</xsl:attribute>
      <xsl:attribute name="id"
		     ><xsl:value-of
		     select="@xml:id"
		     /></xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>


  <!--* superscripts *-->
  <xsl:template match="p5:hi[@rend='sup']">
    <xsl:element name="sup" namespace="{$xhtmlns}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
    
  <xsl:template match="p5:gi">
    <xsl:element name="code" namespace="{$xhtmlns}">
      <xsl:attribute name="class">gi</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="p5:figDesc"/>

  <!-- Formulas -->
  <xsl:template match="p5:formula">
    <xsl:choose>
      <xsl:when test="@xml:id and contains(string(), 'we infer:')">
        <xsl:call-template name="inference-chain"/>        
      </xsl:when>
      <xsl:when test="@xml:id">
        <xsl:element name="img" namespace="{$xhtmlns}">
          <xsl:attribute name="src">
            <xsl:value-of select="concat('formulas/', @xml:id, '_01.svg')"/>
          </xsl:attribute>
          <xsl:attribute name="class">
            <xsl:value-of select=" 'block' "/>
          </xsl:attribute>
          <xsl:attribute name="alt">
            <xsl:value-of select=" 'As described below.' "/>
          </xsl:attribute>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
    <xsl:element name="blockquote" namespace="{$xhtmlns}">
      <xsl:attribute name="class">
        <xsl:value-of select="name()"/>
      </xsl:attribute>
      <xsl:element name="pre" namespace="{$xhtmlns}">
        <xsl:apply-templates/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="p5:formula[@rend='inline']">
    <xsl:element name="img" namespace="{$xhtmlns}">
      <xsl:attribute name="src">
        <xsl:value-of select="concat('formulas/', @xml:id, '_01.svg')"/>
      </xsl:attribute>
      <xsl:attribute name="class">
        <xsl:value-of select=" 'inline' "/>
      </xsl:attribute>
      <xsl:attribute name="alt">
        <xsl:value-of select=" 'As described below.' "/>
      </xsl:attribute>
    </xsl:element>    
    <xsl:element name="span" namespace="{$xhtmlns}">
      <xsl:attribute name="class">
        <xsl:value-of select="name()"/>
      </xsl:attribute>
      <xsl:text> [</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>] </xsl:text>
    </xsl:element>
  </xsl:template>

  <!-- inference chain -->
  <xsl:template name="inference-chain">

    <xsl:choose>
      <xsl:when test="true()">
        <xsl:variable name="url">
          <xsl:value-of select="concat('formulas/', @xml:id, '.xhtml')"/>
        </xsl:variable>
        <xsl:variable name="inf"
                      select="document($url)//xh:div[@class='inference']"/>
        <xsl:apply-templates mode="xhtml-copy" select="$inf"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- original stop-gap -->
        <xsl:element name="p" namespace="{$xhtmlns}">
          <xsl:element name="em" namespace="{$xhtmlns}">
            <xsl:text>For display version, see </xsl:text>
            <xsl:element name="a" namespace="{$xhtmlns}">
              <xsl:attribute name="href">
                <xsl:value-of select="concat('formulas/', @xml:id, '.xhtml')"/>
              </xsl:attribute>
              <xsl:attribute name="target">
                <xsl:value-of select=" 'inferences' "/>
              </xsl:attribute>
              <xsl:text>temporary external file</xsl:text>
            </xsl:element>
            <xsl:text>.</xsl:text>
          </xsl:element>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
        
  </xsl:template>

  <!-- For the record:  the initial forms, marked here v0 -->
  <!-- Temporary; later we will want to inject the XML
       representation and lay it out in SVG -->
  <xsl:template match="p5:formula" mode="v0">
    <xsl:element name="blockquote" namespace="{$xhtmlns}">
      <xsl:attribute name="class">
        <xsl:value-of select="name()"/>
      </xsl:attribute>
      <xsl:element name="pre" namespace="{$xhtmlns}">
        <xsl:apply-templates/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="p5:formula[@rend='inline']" mode="v0">
    <xsl:element name="span" namespace="{$xhtmlns}">
      <xsl:attribute name="class">
        <xsl:value-of select="name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- quotation marks -->
  <xsl:template match="p5:q[not(@type='block')]
                       | p5:gloss
                       | p5:mentioned">
    <xsl:element name="span">
      <xsl:attribute name="class">q</xsl:attribute>
      <xsl:text>&#x201E;</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>&#x201D;</xsl:text>
    </xsl:element>  
  </xsl:template>

  <xsl:template match="processing-instruction()
                       [name() = 'typog']
                       [normalize-space() = 'hr']">
    <xsl:element name="hr" namespace="{$xhtmlns}"/>
    <xsl:message>hr found</xsl:message>
  </xsl:template>

  <!--****************************************************************
      * xhtml copy mode
      ****************************************************************
      *-->
  <xsl:template match="*" mode="xhtml-copy">
    <xsl:copy>
      <xsl:apply-templates select="@*|child::node()" mode="xhtml-copy"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*" mode="xhtml-copy">
    <xsl:copy/>
  </xsl:template>
  <xsl:template match="text()" mode="xhtml-copy">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="xh:img" mode="xhtml-copy">
    <xsl:copy>      
      <xsl:apply-templates select="@*|child::node()" mode="xhtml-copy"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="xh:img/@src" mode="xhtml-copy">
    <xsl:attribute name="src">
      <xsl:value-of select="concat('formulas/', string())"/>
    </xsl:attribute>
  </xsl:template>
  
</xsl:stylesheet>
