<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="3.0">

  <!-- fopc-x-kb:  given XML representation of Frege's Begriffsschrift
       as it comes from ixml parser, generate conventional FOPC. 
       The syntax used by default is the one Claus Huitfeldt and I
       have used in papers:  &lArr;
  -->

  <!--****************************************************************
      * Preliminaries
      ****************************************************************
      *-->
  <!--/wedge /land B: =logical and-->
  <xsl:variable name="and" as="xs:string" select="'&#x2227;'" />

  <!--/exists =at least one exists-->
  <xsl:variable name="exist" as="xs:string" select="'&#x2203;'" />

  <!--/exists-1 =exactly one exists-->
  <xsl:variable name="exist-1" as="xs:string"
                select="'&#x2203;&#x2081;'" />
  
  <!--/forall =for all-->
  <xsl:variable name="forall" as="xs:string" select="'&#x2200;'" />

  <!--/iff =if and only if-->
  <xsl:variable name="iff" as="xs:string" select="'&#x21D4;'" />

  <xsl:variable name="implies" as="xs:string" select="'&#x21D2;'" />
  
  <!--/ne /neq R: =not equal-->
  <xsl:variable name="ne" as="xs:string" select="'&#x2260;'" />

  <!--/ne /neq R: =not equal-->
  <xsl:variable name="neq" as="xs:string" select="'&#x2260;'" />

  <!--/neg /lnot =not sign-->
  <xsl:variable name="not" as="xs:string" select="'&#xAC;'" />
  
  <!--/in R: =set membership-->
  <xsl:variable name="isin" as="xs:string" select="'&#x2208;'" />
  <xsl:output method="text"
              indent="no"/>
  <xsl:strip-space elements="*"/>


  <xsl:template match="text()"/>

  <!--................................................................
      Top-level elements
  -->
  <!-- formula, inference -->

  <!--................................................................
      Compound constructs
      -->
  <!-- N.B. Each compound construct must check to see if its
       argument(s) need parentheses. -->
  <!-- No.  Each compound construct should check to see if it
       itself requires parentheses, based on its parent. -->

  <!-- negation binds tightly and never needs parens. -->
  <xsl:template match="not">
    <xsl:value-of select="$not"/>   
    <xsl:apply-templates/>
  </xsl:template>

  <!-- implication needs parens if it is contained
       in an implication or a not or a forall. -->
  <xsl:template match="conditional">
    <xsl:if test="parent::antecedent
                  or parent::consequent
                  or parent::not
                  or parent::univ">
      <xsl:text>(</xsl:text>
    </xsl:if>
    
    <xsl:apply-templates select="antecedent"/>
    <xsl:value-of select="concat(' ', $implies, ' ')"/>
    <xsl:apply-templates select="consequent"/>
    
    <xsl:if test="parent::antecedent
                  or parent::consequent
                  or parent::not
                  or parent::univ">
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- For universal quantification, we look the
       other direction:  if it governs a very simple
       predicate, or another universal quantification,
       no parens. -->
  <xsl:template match="univ">
    <xsl:text>(</xsl:text>
    <xsl:value-of select="$forall"/>
    <xsl:value-of select="@bound-var"/>
    <xsl:text>)</xsl:text>
    <xsl:if test="not(child::leaf) and not(child::univ)">
      <xsl:text>(</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="not(child::leaf) and not(child::univ)">
      <xsl:text>)</xsl:text>
    </xsl:if>

  </xsl:template>

  <!--................................................................
      Leaves and lower constructs 
  -->
  
  <xsl:template match="var">
    <xsl:sequence select="(@bound-var/string(), ./string())[1]"/>
  </xsl:template>


  <!--................................................................
      Leaves with internal structure
      -->
  <xsl:template match="equivalence">
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>
    <xsl:sequence select="string-join( 
      ( '(', $ss, ')' )
      )"/>
  </xsl:template>
  
  <xsl:template match="equiv-sign">
    <xsl:sequence select=" '≡' "/>
  </xsl:template>

  <!-- function applications -->
  <xsl:template match="fa[functor]">
    <xsl:variable name="sfun" as="xs:string*">
      <xsl:apply-templates select="functor"/>
    </xsl:variable>
    <xsl:variable name="sarg" as="xs:string*">
      <xsl:apply-templates select="arg"/>
    </xsl:variable>
    <xsl:sequence select="string-join( 
      ( $sfun, '(', $sarg, ')' )
      )"/>
  </xsl:template>
  
  <!-- @functor is out of date but retained for a while for 
       compatibility -->
  <xsl:template match="fa[@functor]">
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>
    <xsl:sequence select="string-join( 
      ( string(@functor), '(', $ss, ')' )
      )"/>
  </xsl:template>
  
  
  <xsl:template match="arg">
    <xsl:variable name="comma"
                  select="if (preceding-sibling::arg) 
                          then ', '
                          else '' "/>
    <xsl:variable name="ss" as="xs:string*">
      <xsl:choose>
        <xsl:when test="@bound-var">
          <xsl:sequence select="string(@bound-var)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="*"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="string-join( ($comma, $ss) )"/>
  </xsl:template>
  
</xsl:stylesheet>
