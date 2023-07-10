<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:svg="http://www.w3.org/2000/svg"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:kb="http://blackmesatech.com/nss/2023/kb"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xh="http://www.w3.org/1999/xhtml"
                version="3.0"
                >
  
  <!-- svg-x-kb.xsl:  make SVG from kB (keyboardable Frege) description
       of a formula -->

  <!-- Revisions:
       2023-05-12 : CMSMcQ : support 'mention' element
       2023-03, 2023-04, 2023-05 : CMSMcQ : many additions
       2023-03-28 : CMSMcQ : made this stylesheet
  -->

  <!-- The input document is either a formula or an inference.  (This is
       subject to adjustment.)  Either way, we set up an SVG document
       which defines a lot of svg:g elements which refer to each other
       and then uses the top one.  -->

  <!-- To do and questions:

       To do:  
       . inherited()
       . follows-in-seq, follows-or-same
       . unambiguous

       Q. Simplify by assigning identifiers in a preliminary pass?

  -->

  <!--****************************************************************
      * 0 Preliminaries
      ****************************************************************
      *-->
  <!--* format: html, svg, tei *-->
  <!--* It may be simpler always to produce both an XHTML driver
      * and one or more SVG images. *-->
  <xsl:param name="format" as="xs:string"
             select="('html', 'svg', 'tei')[1]"/>
  
  <!--* filepath:  pathname of input, minus filename *-->
  <xsl:param name="filepath" as="xs:string"
             select="replace(base-uri(/), '^(.*/)([^/]*)$', '$1')"/>
  
  <!--* filestem:  filename of input, minus suffix *-->
  <xsl:param name="filestem" as="xs:string"
             select="replace(base-uri(/), '^(.*/)([^/]+)\.xml$', '$2')"/>
  
  <!--* For 1879 style, set opwidth=12, affstroke=2
      * For 1893 style, set opwidth=4, affstroke=0.5.
      * Both assume a half-point stroke.
      *-->
  <!-- to do:  work on negation in 1893 (and generally) -->
  
  <!-- lineheight:  baseline to baseline, body size + leading -->
  <xsl:variable name="lineheight" as="xs:integer" select="12"/>

  <!-- bodysize:  point size of font, descender to ascender -->
  <xsl:variable name="bodysize" as="xs:integer" select="10"/>

  <!-- opwidth:  distance op to op -->
  <xsl:variable name="opwidth" as="xs:integer" select="12"/>

  <!-- padding: how much distance to put between the text of the 
       basic expressions and the content stroke. ca 20% of bodysize -->
  <xsl:variable name="padding" as="xs:integer" select="2"/>

  <!--* Sink is how far to lower the baseline.  (Should be replaced
      * by putting alignment-baseline="central" on the text element.)
      * ca 30% of bodysize -->
  <xsl:variable name="sink" as="xs:integer" select="3"/>

  <!-- strokewidth:  how thick should the stroke be (points) -->
  <xsl:variable name="strokewidth" as="xs:decimal" select="0.5"/>

  <!-- affstroke: how thick should the affirmation stroke be? -->
  <xsl:variable name="affstroke" as="xs:decimal" select="2.0"/>

  <!-- offset: how far do we offset the overall image as a margin? -->
  <xsl:variable name="offset" as="xs:decimal" select="5"/>

  <!-- pxfactor: how many screen pixels should one SVG px unit fill?
       For debugging, 4 works.  For display, 3 or 2. -->
  <xsl:variable name="pxfactor" as="xs:decimal" select="2"/>
  
  <!-- nwidth: width between a negation and adjacent operators.
       In 1879 style, = $opwidth div 2.  For 1893, = $opwidth. -->
  <xsl:variable name="nwidth" as="xs:decimal" select="$opwidth div 2"/>
  
  <!-- bowlwidth: width of a universal quantifier's concavity 
       (Höhlung). -->
  <xsl:variable name="bowlwidth" as="xs:decimal" select="$bodysize * 0.8"/>
  
  <xsl:variable name="nsxhtml" as="xs:string"
                select=" 'http://www.w3.org/1999/xhtml' "/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml"
              indent="yes"/>

  <!--****************************************************************
      * 1 Document-level processing and 'top-level' elements
      ****************************************************************
      *-->

  <!-- ................................................................
       1.1 Document node
  -->
  <xsl:template match="/"><!--
    <xsl:message>filepath = "<xsl:value-of select="$filepath"/>"</xsl:message>
    <xsl:message>filestem = "<xsl:value-of select="$filestem"/>"</xsl:message> -->
    <xsl:choose>
      <xsl:when test="$format eq 'svg'">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <html xmlns="http://www.w3.org/1999/xhtml"
              xmlns:svg="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink">
          <head>
            <title>
              <xsl:choose>
                <xsl:when test="child::inference">
                  <xsl:text>Inference in concept notation</xsl:text>
                </xsl:when>
                <xsl:when test="child::formula">
                  <xsl:text>Formula in concept notation</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>Watch this space.</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </title>
            <style type="text/css">
              div.inference { display: table; width: 100%;
                  text-align: center;
              }

              div.premise { display: table-row; }
              div.premise-label { display: table-cell; width: 48%;
                                  padding-left: 1em; padding-top: 1em; 
                                  text-align: left; vertical-align: top; }
              div.left-label { padding-left: 2.0em; }
              div.premise-formula { display: table-cell; width: 4%;
                                  padding-right: 1em; padding-top: 0em; 
                                  text-align: right; vertical-align: top; }
              div.premise-rhs { display: table-cell; width: 48%; }

              div.inference-step { display: table-row; }
              div.premise-ref { display: table-cell; width: 48%;
                                text-align: left; padding-left: 2.5em; }
              div.inference-line-wrap { display: table-cell; 
                                        text-align: center; }
              hr.inference-line {
                  display: inline-block;
                  width: 100%;
                  vertical-align: sub;
              }
              hr.double {
                  border: none;
                  height: 0.2em;
                  border-top: 0.1em solid black;
                  border-bottom: 0.1em solid black;
              }

              div.conclusion { display: table-row; }
              div.premise-subs { display: table-cell; width: 48%;
                                  padding-left: 1em; padding-top: 0em; 
                                  text-align: left; vertical-align: top; }
              div.conclusion-formula { display: table-cell; width: 4%;
                                  padding-right: 1em; padding-top: 0em; 
                                  text-align: right; vertical-align: top; }
              div.conclusion-label { display: table-cell; width: 48%; 
                                  padding-right: 1em; padding-bottom: 2em;
                                  text-align: right; vertical-align: bottom; }
              
            </style>
          </head>
          <body>
            <p>
              <xsl:text>This document shows </xsl:text>
              <xsl:choose>
                <xsl:when test="child::inference">
                  <xsl:text>an inference </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>a formula </xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text>&#xA;written out in Frege's &#x2018;concept </xsl:text>
              <xsl:text>notation&#x2019;.  The input was:</xsl:text>
            </p>
            <pre>
              <xsl:apply-templates select="child::*" mode="serialized"/>
            </pre>
            <hr/>
            <xsl:apply-templates/>
            <hr/>
            <p>End of demo.</p>
            <p xsl:expand-text="yes">Generated {current-dateTime()} by svg-x-kb.xsl.</p>
          </body>
        </html>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- ................................................................
       1.2 Formula element: top-level (but also nested, be careful)
       -->
  <!-- formula.  Generate an SVG element for the formula. -->
  <!-- N.B. The formula element can also appear as non-root
       element. -->
  <xsl:template match="formula" name="formula">

    <!-- The main work of the stylesheet is making a list of
         definitions -->
    <xsl:variable name="defs" as="element(svg:g)*">
      <xsl:apply-templates select="* except substitutions"/>
    </xsl:variable>

    <!-- The 'top' definition should be the first one.
         If it's not, fix the stylesheet. -->
    <xsl:variable name="top-g" as="element(svg:g)"
                  select="$defs[1]"/>

    <!-- Each definition will have an embedded processing instruction
         with the information we need to identify and place things
         correctly: ID, north, south, east, west. -->
    <xsl:variable name="pi" as="processing-instruction()"
                  select="$top-g/processing-instruction(kb)"/>

    <!-- Parse the PI -->
    <xsl:variable name="INSEW" as="xs:string*"
                  select="tokenize(normalize-space($pi), '\s+')"/>
    <xsl:variable name="child-ID" as="xs:string" select="$INSEW[1]"/>
    <xsl:variable name="N" as="xs:decimal" select="xs:decimal($INSEW[2])"/>
    <xsl:variable name="S" as="xs:decimal" select="xs:decimal($INSEW[3])"/>
    <xsl:variable name="E" as="xs:decimal" select="xs:decimal($INSEW[4])"/>
    <xsl:variable name="W" as="xs:decimal" select="xs:decimal($INSEW[5])"/>

    <!-- Calculate overall width and height. -->
    <xsl:variable name="h" as="xs:decimal" select="$N + $S + $offset"/>
    <xsl:variable name="w" as="xs:decimal" select="$E + $W + $offset"/>

    <!-- Calculate offset for top-level graphic. -->
    <xsl:variable name="x" as="xs:decimal" select="$offset"/>
    <xsl:variable name="y" as="xs:decimal" select="$N + $offset"/>

    <!-- We write the SVG to a separate file.  Where do we want it? -->
    <xsl:variable name="filename" as="xs:string"
                  select="concat(
                          $filestem, 
                          '_', 
                          format-number(1 + count(preceding::formula), '00'),
                          '.svg'
                          )"/>
    <xsl:element name="img" namespace="{$nsxhtml}">
      <xsl:attribute name="src" select="$filename"/>
      <xsl:attribute name="alt">        
        <xsl:apply-templates mode="serialized" select="."/>
      </xsl:attribute>
    </xsl:element>
    
    <xsl:result-document href="{concat($filepath, $filename)}">
      <svg:svg xmlns:xx-svg="http://www.w3.org/2000/svg"
               xmlns:xx-xlink="http://www.w3.org/1999/xlink"
               width="{1.1 * $pxfactor * $w}"
               height="{$pxfactor * $h}"
               viewBox="0,0 {$w},{$h}">
        <svg:desc>
          <xsl:text>SVG rendering of </xsl:text>
          <xsl:text>Begriffsschrift notation for the </xsl:text>
          <xsl:text>&#xA;  expression:</xsl:text>
          <xsl:text>&#xA;&#xA;  </xsl:text>
          <xsl:apply-templates mode="serialized" select="."/>
          <xsl:text>&#xA;&#xA;  </xsl:text>
          <xsl:text>SVG generated by svg-x-kb.xsl</xsl:text>
          <xsl:text>&#xA;  </xsl:text>
          <xsl:value-of
              select="adjust-dateTime-to-timezone(
                      current-dateTime(), 
                      ())"/>
        </svg:desc>

        <svg:style type="text/css" xsl:expand-text="yes">
          line, path {{ 
          stroke: black;
          stroke-width: {$strokewidth};
          }}
          path {{ 
          fill: none;
          }}
          text {{ 
          font-size: {$bodysize}px;
          }}
        </svg:style>
        <svg:defs>
          <xsl:sequence select="$defs"/>
        </svg:defs>
        <svg:g>
          <svg:use xlink:href="#{$child-ID}" transform="translate({$x},{$y})"/>
        </svg:g>
      </svg:svg>
    </xsl:result-document>
 
  </xsl:template>

  <!-- 1.2a formula number -->
  <xsl:template match="premise/formula/@n">
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'left-label' "/>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="conclusion/formula/@n">
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'right-label' "/>
      <xsl:value-of select="concat('(', ., '.')"/>
    </xsl:element>
  </xsl:template>

  <!-- ................................................................
       1.3 Inference element: top-level container.
       -->  
  <!-- inference.  Because these can break over pages, we would like
       to avoid putting an entire inference chain into a single SVG
       image.  Instead, we generate an XHTML document. -->
  <xsl:template match="inference">
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'inference' "/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!--................................................................
      1.4 yes element (affirmation).  
      -->
  <!-- yes.  Calculate g for child (there should be exactly one),
       add affirmation stroke.  Appears only at the top of a
       formula.
  -->
  <xsl:template match="yes" as="element(svg:g)+">

    <!-- We need an id for this element, and the id of its child. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>

    <xsl:variable name="descendants" as="element(svg:g)*">
      <xsl:apply-templates/>
    </xsl:variable>

    <!-- The definition of the child will be the first one in the
         sequence.  (Make that a rule.) -->
    <xsl:variable name="child-g" as="element(svg:g)"
                  select="$descendants[1]"/>
    <xsl:variable name="child-ID" as="xs:string"
                  select="$child-g/@id/string()"/>

    <!-- Fetch its description -->
    <xsl:variable name="pi" as="processing-instruction()"
                  select="$child-g/processing-instruction(kb)"/>

    <!-- Parse the PI -->
    <xsl:variable name="INSEW" as="xs:string*"
                  select="tokenize(normalize-space($pi), '\s+')"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:apply-templates mode="serialized" select="."/>
        </svg:title>

        <!-- ad hoc rule:  if the proposition being affirmed
             is just one leaf, add more length to the content
             stroke. -->
        <xsl:choose>
          <xsl:when test="child::leaf">
            <!--* N S E values are the same as for the child,
                * W is child.W + opwidth *-->
            <xsl:processing-instruction name="kb">
              <xsl:sequence select="$ID, $INSEW[2], $INSEW[3], 
                                    $INSEW[4], $opwidth+xs:decimal($INSEW[5])"/>
            </xsl:processing-instruction>
            <svg:g>
              <!-- Extend the content stroke -->
              <svg:line x1="0" y1="0"
                        x2="{$opwidth}" y2="0"/>
              <!-- Draw the affirmation stroke -->
              <svg:line x1="0" y1="-{$lineheight div 2}"
                        x2="0" y2="{$lineheight div 2}"
                        style="stroke-width: {$affstroke}"/>
              <!-- Position the child leaf -->
              <svg:use xlink:href="#{$child-ID}"
                       transform="translate({$opwidth}, 0)"/>
            </svg:g>
          </xsl:when>
          <xsl:otherwise>
            
            <!--* N S E W values are the same as for the child *-->
            <xsl:processing-instruction name="kb">
              <xsl:sequence select="$ID, $INSEW[position() gt 1]"/>
            </xsl:processing-instruction>
            <svg:g>
              <svg:line x1="0" y1="-{$lineheight div 2}"
                        x2="0" y2="{$lineheight div 2}"
                        style="stroke-width: {$affstroke}"/>
              <svg:use xlink:href="#{$child-ID}"/>
            </svg:g>
          </xsl:otherwise>
        </xsl:choose>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g, $descendants"/>
  </xsl:template>

  <!--................................................................
      1.5 maybe
      -->
  <!-- maybe.  Calculate g for child (there should be exactly one),
       return it.  Only at the top of a formula. -->
  <xsl:template match="maybe" as="element(svg:g)+">
    <xsl:apply-templates/>
  </xsl:template>


  <!--****************************************************************
      * 2 Compound constructs
      ****************************************************************
      *-->

  <!--................................................................
      2.1 not
  -->
  <!-- For single negation, we don't need to extend the content 
       stroke.  For multiple negation, we do.  But almost all of the
       work is the same, so we use a single template. -->

  <xsl:template match="not">
    <!-- We need an id for this element. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>
    
    <xsl:variable name="child-etal" as="element(svg:g)*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>

    <!-- Extract the definition of the child. -->
    <xsl:variable name="child-g" as="element(svg:g)"
                  select="$child-etal[1]"/>

    <!-- Fetch its description -->
    <xsl:variable name="child-pi" as="processing-instruction()"
                  select="$child-g/processing-instruction(kb)"/>

    <!-- Parse the PI -->
    <xsl:variable name="ch-INSEW" as="xs:string*"
                  select="tokenize(normalize-space($child-pi), '\s+')"/>
    <xsl:variable name="ch-ID" as="xs:string" select="$ch-INSEW[1]"/>
    <xsl:variable name="ch-N" as="xs:decimal" select="xs:decimal($ch-INSEW[2])"/>
    <xsl:variable name="ch-S" as="xs:decimal" select="xs:decimal($ch-INSEW[3])"/>
    <xsl:variable name="ch-E" as="xs:decimal" select="xs:decimal($ch-INSEW[4])"/>
    <xsl:variable name="ch-W" as="xs:decimal" select="xs:decimal($ch-INSEW[5])"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:apply-templates select="." mode="serialized"/>
        </svg:title>
        <!--* Set N S E W values:  N S E as for child, W adds half an opwidth *-->
        <xsl:variable name="N" as="xs:decimal" select="$ch-N"/>
        <xsl:variable name="S" as="xs:decimal" select="$ch-S"/>
        <xsl:variable name="E" as="xs:decimal" select="$ch-E"/>

        <!-- Draw! -->
        <xsl:choose>
          <xsl:when test="child::not">
            <xsl:variable name="W" as="xs:decimal" select="$ch-W + $nwidth"/>
            <xsl:processing-instruction name="kb">
              <xsl:sequence select="$ID, $N, $S, $E, $W"/>
            </xsl:processing-instruction>
            <svg:g>
              <!-- Place the child -->
              <svg:use xlink:href="#{$ch-ID}"
                       transform="translate({$nwidth}, 0)"/>
              <!-- Extend content stroke. -->
              <svg:line x1="0" y1="0"
                        x2="{$opwidth}" y2="0"/>
              <!-- Draw negation stroke. -->
              <svg:line x1="{$nwidth}" y1="0"
                        x2="{$nwidth}" y2="{$lineheight div 3}"/>
            </svg:g>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="W" as="xs:decimal" select="$ch-W"/>
            <xsl:processing-instruction name="kb">
              <xsl:sequence select="$ID, $N, $S, $E, $W"/>
            </xsl:processing-instruction>
            <svg:g>
              <!-- Place the child -->
              <svg:use xlink:href="#{$ch-ID}"/>
              <!-- Draw negation stroke. -->
              <svg:line x1="{$nwidth}" y1="0"
                        x2="{$nwidth}" y2="{$lineheight div 3}"/>
            </svg:g>
          </xsl:otherwise>
        </xsl:choose>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g, $child-etal"/>
  </xsl:template>
  
  <!--................................................................
      2.2 Conditional (and its constituents)
      ................................................................
      (Actually, at the moment its constituents don't have templates
      of their own; we reach through them.)
      -->
  <!-- conditional.  Calculate the g for each child, then compose -->
  <xsl:template match="conditional" as="element(svg:g)+">

    <!-- We need an id for this element. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>

    <xsl:variable name="consequent-etal" as="element(svg:g)*">
      <xsl:apply-templates select="consequent/*"/>
    </xsl:variable>
    
    <xsl:variable name="antecedent-etal" as="element(svg:g)*">
      <xsl:apply-templates select="antecedent/*"/>
    </xsl:variable>

    <!-- Extract the definitions of the two children. -->
    <xsl:variable name="cons-g" as="element(svg:g)"
                  select="$consequent-etal[1]"/>
    <xsl:variable name="ante-g" as="element(svg:g)"
                  select="$antecedent-etal[1]"/>

    <!-- Fetch their descriptions -->
    <xsl:variable name="cons-pi" as="processing-instruction()"
                  select="$cons-g/processing-instruction(kb)"/>
    <xsl:variable name="ante-pi" as="processing-instruction()"
                  select="$ante-g/processing-instruction(kb)"/>

    <!-- Parse the PIs -->
    <xsl:variable name="cons-INSEW" as="xs:string*"
                  select="tokenize(normalize-space($cons-pi), '\s+')"/>
    <xsl:variable name="cons-ID" as="xs:string" select="$cons-INSEW[1]"/>
    <xsl:variable name="cons-N" as="xs:decimal" select="xs:decimal($cons-INSEW[2])"/>
    <xsl:variable name="cons-S" as="xs:decimal" select="xs:decimal($cons-INSEW[3])"/>
    <xsl:variable name="cons-E" as="xs:decimal" select="xs:decimal($cons-INSEW[4])"/>
    <xsl:variable name="cons-W" as="xs:decimal" select="xs:decimal($cons-INSEW[5])"/>
    
    <xsl:variable name="ante-INSEW" as="xs:string*"
                  select="tokenize(normalize-space($ante-pi), '\s+')"/>
    <xsl:variable name="ante-ID" as="xs:string" select="$ante-INSEW[1]"/>
    <xsl:variable name="ante-N" as="xs:decimal" select="xs:decimal($ante-INSEW[2])"/>
    <xsl:variable name="ante-S" as="xs:decimal" select="xs:decimal($ante-INSEW[3])"/>
    <xsl:variable name="ante-E" as="xs:decimal" select="xs:decimal($ante-INSEW[4])"/>
    <xsl:variable name="ante-W" as="xs:decimal" select="xs:decimal($ante-INSEW[5])"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:apply-templates select="." mode="serialized"/>
        </svg:title>
        <!--* Set N S E W values *-->
        <xsl:variable name="N" as="xs:decimal"
                      select="$cons-N"/>
        <xsl:variable name="S" as="xs:decimal"
                      select="$cons-S + $ante-N + $ante-S"/>
        <xsl:variable name="E" as="xs:decimal"
                      select="max( ($cons-E, $ante-E) )"/>
        <xsl:variable name="W" as="xs:decimal"
                      select="$opwidth + max( ($cons-W, $ante-W) )"/>
        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $N, $S, $E, $W"/>
        </xsl:processing-instruction>
        
        <!-- Calculate locations of various points -->
        <!-- AP:  attachment point of conditional -->
        <xsl:variable name="APx" as="xs:decimal" select="0"/>
        <xsl:variable name="APy" as="xs:decimal" select="0"/>
        <!-- OP:  operator point (location of tee joint -->
        <xsl:variable name="OPx" as="xs:decimal" select="$opwidth"/>
        <xsl:variable name="OPy" as="xs:decimal" select="0"/>
        <!-- cons-AP:  attachment point of consequent -->
        <xsl:variable name="cons-APx" as="xs:decimal"
                      select="$W - $cons-W"/>
        <xsl:variable name="cons-APy" as="xs:decimal"
                      select="0"/>
        <!-- ante-AP:  attachment point of antecedent -->
        <xsl:variable name="ante-APx" as="xs:decimal"
                      select="$W - $ante-W"/>
        <xsl:variable name="ante-APy" as="xs:decimal"
                      select="$cons-S + $ante-N"/>

        <!-- Draw! -->
        <svg:g>
          <!-- Place the children -->
          <svg:use xlink:href="#{$cons-ID}"
                   transform="translate({$cons-APx}, {$cons-APy})"/>
          <svg:use xlink:href="#{$ante-ID}"
                   transform="translate({$ante-APx}, {$ante-APy})"/>
          <!-- Draw line from attachment point of conditional (origin)
               to attachment point of consequent. -->
          <svg:line x1="{$APx}" y1="{$APy}"
                    x2="{$cons-APx}" y2="{$cons-APy}"/>
          <!-- Draw path from operator point vertically to corner, then
               horizontally to attachment point of antecedent. -->
          <svg:path d="M{$OPx},{$OPy} V{$ante-APy} H{$ante-APx + ($opwidth div 2)}"
                    />
        </svg:g>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g, $consequent-etal, $antecedent-etal"/>
  </xsl:template>

  <!--................................................................
      2.3 Parts of an inference (premise, infstep, conclusion, ...)
      ................................................................
      -->

  <!--................................................................
      2.3.1 premise.  
      Contains one formula; just pass it through. 
      -->
  <xsl:template match="premise">
    <!-- First row of 3x3 table:  premise -->
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'premise' "/>
      
      <!-- left column, with label and subsitution table,
           if any -->
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'premise-label' "/>
        <xsl:apply-templates
            select="formula/@n, formula/substitutions"/>
      </xsl:element>

      <!-- middle column, premise -->
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'premise-formula' "/>
        <xsl:apply-templates select="formula"/>
      </xsl:element>

      <!-- right-hand column (if we were to need it) -->
      <!--
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'premise-rhs "/>
      </xsl:element>
      -->
      
    </xsl:element>
  </xsl:template>

  <!--................................................................
      2.3.2 inference step
      -->
  <xsl:template match="infstep">
    <!-- Second row of 3x3 table:  premise ref and separator -->
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'inference-step' "/>

      <!-- left column:  reference to premise -->
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'premise-ref' "/>
        <xsl:apply-templates
            select="premise-ref-con | premise-ref-ant"/>
      </xsl:element>

      <!-- middle column:  inference line, just a horizontal rule -->
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'inference-line-wrap' "/>
        <xsl:element name="hr" namespace="{$nsxhtml}">
          <xsl:attribute name="class"
                       select="if (count(.//ref) lt 2)
                               then 'inference-line'
                               else 'inference-line double'
                               "/>
        </xsl:element>
      </xsl:element>

      <!-- right column (should we need it) -->
      <!--
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'inference-line-rhs "/>
      </xsl:element>
      -->
    </xsl:element>

    <!-- Third row of 3x3 table:  substitutions and separator -->
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'conclusion' "/>

      <!-- Left column:  substitutions -->
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'premise-subs' "/>
        <xsl:apply-templates select="*[1]/ref/substitutions"/>
      </xsl:element>

      <!-- Middle column:  conclusion itself -->
      <xsl:apply-templates select="conclusion"/>

      <!-- Right column:  formula number -->
      <xsl:element name="div" namespace="{$nsxhtml}">
        <xsl:attribute name="class" select=" 'conclusion-label' "/>
        <xsl:apply-templates select="conclusion/formula/@n"/>
      </xsl:element>
      
    </xsl:element>
  </xsl:template>

  <!--................................................................
      2.3.3 premise-ref (to conditional premise or antecedent premise)
      -->
  <xsl:template match="premise-ref-con | premise-ref-ant">
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'premise-reference' "/>
      <xsl:text>(</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>):</xsl:text>
      <xsl:if test="self::premise-ref-ant">
        <xsl:text>:</xsl:text>
      </xsl:if>
      <xsl:text> </xsl:text>
    </xsl:element>
  </xsl:template>

  <!--................................................................
      2.3.4 ref (the hyperlink itself)
      -->
  <xsl:template match="ref">
    <xsl:if test="preceding-sibling::ref">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:element name="span" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'f-num' "/>
      <xsl:sequence select="(@n/string(), string())[1]"/>
      <!-- <xsl:apply-templates select="substitutions"/> -->
    </xsl:element>
  </xsl:template>

  <!--................................................................
      2.3.5 conclusion
      -->
  <xsl:template match="conclusion" as="element()">    
    <xsl:element name="div" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select=" 'conclusion-formula' "/>
      <xsl:apply-templates select="formula"/>
    </xsl:element>
  </xsl:template>

  <!--................................................................
      2.3.6 substitution table
      -->
  <!-- for a table of substitutions, we generate (a) an SVG
       file displaying the table, and (b) an img element pointing
       to that file. -->
  <xsl:template match="substitutions" as="element(xh:img)">
    
    <!-- First, gather definitions for the subst elements -->
    <xsl:variable name="defs" as="element(svg:g)*">
      <xsl:apply-templates select="subst"/>
    </xsl:variable>
    
    <xsl:variable name="substs" as="element(svg:g)*"
                  select="$defs[starts-with(
                          normalize-space(processing-instruction(kb)), 
                          'subst')]"/>

    <!-- Next, make an ID for the table element -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>
    
    <!-- Next, make a title for the table element -->
    <xsl:variable name="title" as="xs:string">
      <xsl:apply-templates select="." mode="serialized"/>
    </xsl:variable>

    <!-- Calculate size of this table: N S E W -->
    <!-- Extract the size information for each pair -->
    <xsl:variable name="lpiSubs" as="processing-instruction()*"
                  select="for $e in $substs
                          return $e/processing-instruction(kb)"/>

    <!-- North is N of the first pair, plus padding --> 
    <xsl:variable name="szN0" as="xs:decimal"
                  select="xs:decimal(
                          tokenize(
                          normalize-space($lpiSubs[1]), 
                          '\s+')[2])" />
    <xsl:variable name="szN" as="xs:decimal"
                  select="($lineheight div 2) + $szN0"/>
    <!-- South is sum of all height, - N of the first pair, 
         plus padding -->    
    <xsl:variable name="szS" as="xs:decimal"
                  select="sum(
                          for $s in $lpiSubs
                          return 
                          for $t in tokenize(
                                 normalize-space($s), 
                                 '\s+')[position() = (2, 3)]
                          return xs:decimal($t)
                          )
                          - $szN0
                          + $padding
                          "/>    
    <!-- East is the maximum width of any E value -->    
    <xsl:variable name="szE" as="xs:decimal"
                  select="($bodysize div 2) + max(
                          for $s in $lpiSubs
                          return xs:decimal(tokenize(
                                 normalize-space($s), 
                                 '\s+')[4])
                          )"/>
    <!-- West is the maximum width of any W value -->
    <xsl:variable name="szW" as="xs:decimal"
                  select="max(
                          for $s in $lpiSubs
                          return xs:decimal(tokenize(
                                 normalize-space($s), 
                                 '\s+')[5])
                          )"/>
    
    <!-- Next, make an svg:g element for the table itself -->
    <xsl:variable name="table" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title><xsl:value-of select="$title"/></svg:title>
        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $szN, $szS, $szE, $szW"/>
        </xsl:processing-instruction>
        <svg:g>
          <!-- Lay out the children -->
          <xsl:for-each select="$substs">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="piCur" as="processing-instruction()"
                          select="./processing-instruction(kb)"/>
            <xsl:variable name="idCur" as="xs:string"
                          select="tokenize(
                                  normalize-space($piCur), 
                                  '\s+'
                                  )[1]"/>
            <xsl:variable name="szWCur" as="xs:decimal"
                          select="xs:decimal(tokenize(
                                  normalize-space($piCur), 
                                  '\s+'
                                  )[5])"/>
            <xsl:variable name="yCur" as="xs:decimal"
                          select="sum(
                                  for $pi in $lpiSubs[position() lt $pos]
                                  return 
                                  for $t in tokenize(normalize-space($pi), '\s+')
                                  [position() = (2, 3)]
                                  return xs:decimal($t)
                                  ) 
                                  - $szN0
                                  "/>
                                  
            <svg:use xlink:href="#{$idCur}"
                     transform="translate({$szW - $szWCur}, {$yCur})"/>
          </xsl:for-each>

          <!-- Draw the line -->
          <xsl:variable name="xpos" select="$szW + ($bodysize div 2)"/>
          <svg:line x1="{$xpos}" y1="{-1 * $szN}" x2="{$xpos}" y2="{$szS}"
                    style="stroke-width: {2 * $strokewidth}"/>
        </svg:g>
      </svg:g>
    </xsl:variable>

    <!-- Calculate overall width and height. -->
    <xsl:variable name="h" as="xs:decimal" select="$szN + $szS + $offset"/>
    <xsl:variable name="w" as="xs:decimal" select="($szE + $szW + $offset)"/>

    <!-- Calculate offset for top-level graphic. -->
    <xsl:variable name="x" as="xs:decimal" select="$offset"/>
    <xsl:variable name="y" as="xs:decimal" select="$szN + $offset"/>

    <!-- Calculate the filename for the SVG file -->
    <xsl:variable name="filename" as="xs:string"
                  select="concat(
                          $filestem,
                          '_st',
                          format-number(
                            1+count(preceding::substitutions), 
                            '00'),
                          '.svg'
                          )"/>
    
    <!-- Make the SVG file -->
    <xsl:result-document href="{concat($filepath, $filename)}">
      <svg:svg xmlns:svg="http://www.w3.org/2000/svg"
               xmlns:xlink="http://www.w3.org/1999/xlink"
               width="{$pxfactor * $w}"
               height="{$pxfactor * $h}"
               viewBox="0,0 {$w}, {$h}">
        <svg:desc>
          <xsl:text>SVG rendering of substitution table:&#xA;</xsl:text>
          <xsl:sequence select="$title"/>
          <xsl:text>&#xA;&#xA;  </xsl:text>
          <xsl:text>SVG generated by svg-x-kb.xsl</xsl:text>
          <xsl:text>&#xA;  </xsl:text>
          <xsl:value-of
              select="adjust-dateTime-to-timezone(
                      current-dateTime(), 
                      ())"/>
        </svg:desc>

        <svg:style type="text/css" xsl:expand-text="yes">
          line, path {{ 
          stroke: black;
          stroke-width: {$strokewidth};
          }}
          path {{ 
          fill: none;
          }}
          text {{ 
          font-size: {$bodysize}px;
          }}
        </svg:style>

        <svg:defs>
          <xsl:sequence select="$table, $defs"/>
        </svg:defs>

        <svg:g>
          <svg:use xlink:href="#{$ID}"
                   transform="translate({$x}, {$y})"/>
        </svg:g>
      </svg:svg>
    </xsl:result-document>

    <!-- Emit the img element -->
    <xsl:element name="img" namespace="{$nsxhtml}">
      <xsl:attribute name="src" select="$filename"/>
      <xsl:attribute name="alt" select="normalize-space($title)"/>
    </xsl:element>
  </xsl:template>

  <!--................................................................
      subst: one entry in a substitution table 
      -->
  <xsl:template match="subst" as="element(svg:g)+">
    
    <!-- First, gather definitions for the taken (the left-hand side)
         and the given (the right-hand side) -->
    <xsl:variable name="taken-et-al" as="element(svg:g)+">
      <xsl:apply-templates select="taken/*"/>
    </xsl:variable>   
    <xsl:variable name="given-et-al" as="element(svg:g)+">
      <xsl:apply-templates select="given/*"/>
    </xsl:variable>   
    <xsl:variable name="taken" as="element(svg:g)"
                  select="$taken-et-al[1]"/>
    <xsl:variable name="given" as="element(svg:g)"
                  select="$given-et-al[1]"/>

    <!-- Next, make an ID for this subst element -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>
    
    <!-- Next, make a title for this element -->
    <xsl:variable name="title" as="xs:string">
      <xsl:apply-templates select="." mode="serialized"/>
    </xsl:variable>

    <!-- Extract size data from children: -->
    <xsl:variable name="insewTaken" as="xs:string+"
                  select="tokenize(
                          normalize-space(
                          $taken/processing-instruction(kb)
                          ), '\s+')"/>
    <xsl:variable name="insewGiven" as="xs:string+"
                  select="tokenize(
                          normalize-space(
                          $given/processing-instruction(kb)
                          ), '\s+')"/>
    
    <!-- Calculate size of this row: N S E W -->
    <!-- North is the larger of the N values --> 
    <xsl:variable name="szN" as="xs:decimal"
                  select="max( (
                          xs:decimal($insewTaken[2]),
                          xs:decimal($insewGiven[2]) 
                          ) )" />
    <!-- South is the larger of the S values -->    
    <xsl:variable name="szS" as="xs:decimal"
                  select="max( (
                          xs:decimal($insewTaken[3]),
                          xs:decimal($insewGiven[3]) 
                          ) )" />    
    <!-- East is the total width of given -->    
    <xsl:variable name="szE" as="xs:decimal"
                  select="xs:decimal($insewGiven[4]) 
                          + 
                          xs:decimal($insewGiven[5]) "/>
    <!-- West is the total width of taken.  Tried a fixed value,
         did not work well. -->
    <xsl:variable name="szW" as="xs:decimal"
                  select="xs:decimal($insewTaken[4]) 
                          + 
                          xs:decimal($insewTaken[5]) "/>
    <!-- <xsl:variable name="szW" as="xs:decimal"
                  select="$padding + $lineheight"/> -->
    
    <!-- Next, make an svg:g element for the row itself -->
    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title><xsl:value-of select="$title"/></svg:title>
        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $szN, $szS, $szE, $szW"/>
        </xsl:processing-instruction>
        <svg:g>
          <!-- Lay out the children -->
          <svg:use xlink:href="#{$insewTaken[1]}"
                   transform="translate({$padding}, 0)"/>
          <svg:use xlink:href="#{$insewGiven[1]}"
                   transform="translate({$szW + (3 * $bodysize div 4)}, 0)"/> 
        </svg:g>
      </svg:g>
    </xsl:variable>
    
    <xsl:sequence select="$this-g, $taken-et-al, $given-et-al"/>
  </xsl:template>

  <!--................................................................
      2.4 Universal quantification
      ................................................................
      -->

  <!-- Universal quantification:  binds one proposition.

       Make and place a box for the proposition, draw a content stroke
       and a bowl and connect with the proposition's attachment point.
       Then place the bound variable in the bowl.
       -->
  <xsl:template match="univ" as="element(svg:g)*">

    <!-- We need an id for this element. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>

    <!-- Make boxes for descendants. -->
    <xsl:variable name="descendants" as="element(svg:g)+">
      <xsl:apply-templates/>
    </xsl:variable>

    <!-- Find the child of this quantification -->
    <xsl:variable name="child-g" as="element(svg:g)"
                  select="$descendants[1]"/>

    <!-- Fetch its description -->
    <xsl:variable name="pi" as="processing-instruction()"
                  select="$child-g/processing-instruction(kb)"/>

    <!-- Parse the PI -->
    <xsl:variable name="INSEW" as="xs:string*"
                  select="tokenize(normalize-space($pi), '\s+')"/>
    <xsl:variable name="child-ID" as="xs:string" select="$INSEW[1]"/>
    <xsl:variable name="N0" as="xs:decimal" select="xs:decimal($INSEW[2])"/>
    <xsl:variable name="S0" as="xs:decimal" select="xs:decimal($INSEW[3])"/>
    <xsl:variable name="E0" as="xs:decimal" select="xs:decimal($INSEW[4])"/>
    <xsl:variable name="W0" as="xs:decimal" select="xs:decimal($INSEW[5])"/>    

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:sequence select="string()"/>
        </svg:title>
        <!--* Calculate new W value *-->
        <xsl:variable name="W" as="xs:decimal"
                      select="$W0 + ($opwidth + $bowlwidth)"/> 

        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $N0, $S0, $E0, $W"/>
        </xsl:processing-instruction>
        <svg:g>
          <!-- Place the child. -->
          <svg:use xlink:href="#{$child-ID}"
                   transform="translate({$opwidth + $bowlwidth}, 0)"/>
          <!-- Draw the path -->
          <xsl:variable name="b3" as="xs:decimal"
                        select="$bowlwidth div 3"/>
          <svg:path d="M 0,0 
                       h {$opwidth} 
                       a {$b3},{$b3} 0 0 0 {$b3},{$b3}
                       h {$b3} 
                       a {$b3},{0 - $b3} 0 0 0 {$b3},{0 - $b3}
                       h {$padding}
                       "/>
          <!-- That is:
                  M 0,0   // start at attachment point
                  h {$opwidth}   // draw content stroke
                  a {$b3},{$b3} 0 0 0 {$b3},{$b3}   // curve down
                  h {$b3}   // draw flat bottom of the bowl
                  a {$b3},{0 - $b3} 0 0 0 {$b3},{0 - $b3}   // curve up
                  h {$padding}  // draw into the content stroke of 
                                // proposition (to get the joint correct)
          -->

          <!-- Place the bound variable at $opwidth plus a little -->
          <xsl:variable name="uqpad" as="xs:decimal"
                        select="$bowlwidth div 5"/>
          <svg:text style="font-size: {$bodysize * 0.7}"
                    transform="translate({$opwidth + $uqpad}, 0)">
            <xsl:sequence select="string(@bound-var)"/>
          </svg:text>

        </svg:g>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g, $descendants"/>
  </xsl:template>


  <!--****************************************************************
      * 3 Leaves and their contents
      ****************************************************************
      *-->

  <!--................................................................
      3.1 leaf element
      Possibly unnecessary, but kept for now as reliable signal of
      a basic statement.  (Or equivalently:  the bit to be aligned
      at the right.)
      -->
  <!--* A leaf generates its basic statement and then a content stroke
      * of length $opwidth.  There should be one child.
      *-->
  <xsl:template match="leaf" as="element(svg:g)+">

    <!-- We need an id for this element, and the id of its child. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>
    <xsl:variable name="child-ID" as="xs:string"
                  select="kb:id(*)"/>

    <xsl:variable name="descendants" as="element(svg:g)*">
      <xsl:apply-templates/>
    </xsl:variable>

    <!-- The definition of the child will be the first one in the
         sequence.  (Make that a rule.) -->
    <xsl:variable name="child-g" as="element(svg:g)"
                  select="$descendants[1]"/>

    <!-- Fetch its description -->
    <xsl:variable name="pi" as="processing-instruction()"
                  select="$child-g/processing-instruction(kb)"/>

    <!-- Parse the PI -->
    <xsl:variable name="INSEW" as="xs:string*"
                  select="tokenize(normalize-space($pi), '\s+')"/>
    <xsl:variable name="N0" as="xs:decimal" select="xs:decimal($INSEW[2])"/>
    <xsl:variable name="S0" as="xs:decimal" select="xs:decimal($INSEW[3])"/>
    <xsl:variable name="E0" as="xs:decimal" select="xs:decimal($INSEW[4])"/>
    <xsl:variable name="W0" as="xs:decimal" select="xs:decimal($INSEW[5])"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <xsl:choose>
        <xsl:when test="parent::mention">
          <svg:g id="{$ID}">
            <svg:title>
              <xsl:apply-templates mode="serialized" select=".."/>
            </svg:title>

            <xsl:processing-instruction name="kb">
              <xsl:sequence select="$ID, $N0, $S0, $E0, $W0"/>
            </xsl:processing-instruction>
            <svg:g>
              <svg:use xlink:href="#{$child-ID}"
                       transform="translate(0, 0)"/>
            </svg:g>
          </svg:g>
        </xsl:when>
        <xsl:otherwise>
          <!-- normal case -->
          <svg:g id="{$ID}">
            <svg:title>
              <xsl:apply-templates mode="serialized"/>
            </svg:title>
            <!--* Calculate new N S E W values from those of the child *-->
            <xsl:variable name="N" as="xs:decimal" select="$N0"/>
            <xsl:variable name="S" as="xs:decimal" select="$S0"/>
            <xsl:variable name="E" as="xs:decimal" select="$E0"/>
            <xsl:variable name="W" as="xs:decimal" select="$W0 + $opwidth"/>

            <xsl:processing-instruction name="kb">
              <xsl:sequence select="$ID, $N, $S, $E, $W"/>
            </xsl:processing-instruction>
            <svg:g>
              <!-- For debugging, color the area we think is
                   occupied by this leaf. -->
              <!-- <svg:rect x="{$W}" y="-{$N}" width="{$E}" height="{$N+$S}"
                   style="fill: yellow;"/> -->
              <svg:line x1="0" y1="0"
                        x2="{$opwidth}" y2="0"/>
              <svg:use xlink:href="#{$child-ID}"
                       transform="translate({$opwidth}, 0)"/>
            </svg:g>
          </svg:g>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="if (parent::given) 
                          then $descendants 
                          else ($this-g, $descendants)"/>
  </xsl:template>


  <!--................................................................
      3.2 var
      -->
  <!--* A var generates a bare text node, in italic.  We estimate
      * the width using the 'unit system' for calculating lengths
      * of headlines, see 
      * https://www.ndsu.edu/pubweb/~rcollins/313editing/onlineclass/lecturetwelve.htm
      * 1 unit for each lowercase letter, but 0.5 for [fijl], 1.5 for [mw]
      * 1.5 for each uppercase but 1 for [I], 2 for [MW].
      * (Then, I guess, multiply by bodysize.)
      *-->
  <xsl:template match="var" as="element(svg:g)+">

    <!-- We need an id for this element. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:sequence select="string()"/>
        </svg:title>
        <!--* Calculate new N S E W values from scratch *-->
        <xsl:variable name="N" as="xs:decimal" select="$bodysize div 2"/>
        <xsl:variable name="S" as="xs:decimal" select="$lineheight - $N"/>
        <xsl:variable name="E" as="xs:decimal" select="$bodysize * 0.8 * kb:textwidth(string())"/>
        <xsl:variable name="W" as="xs:decimal" select="0"/> <!-- not $padding ? why not? -->

        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $N, $S, $E, $W"/>
        </xsl:processing-instruction>
        <svg:g>
          <svg:text transform="translate({$padding}, {$sink})"
                    style="font-style: italic;">
            <xsl:value-of select="string()"/>
          </svg:text>
          <!-- In principle, vertical-align="central" ought
               to be better than using $sink, but it appears
               to have no effect. -->
          <!-- For debugging:  make a small mark at what we think
               is the eastern boundary -->

          <!-- <svg:line x1="{$W+$E}" y1="-{$N}"
                    x2="{$W+$E}" y2="{$S}"
                    style="stroke: red; stroke-width: 0.25"/> -->

          <!-- end debugging -->
        </svg:g>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g"/>
  </xsl:template>

  <!--................................................................
      3.3 et seq. Leaves with internal structure
      -->
  <!--................................................................
      3.3 Equivalence
      -->
  <xsl:template match="equivalence" as="element(svg:g)*">

    <!-- We need an id for this element. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>

    <!-- Quick and dirty approach:  this will work for now. -->
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates select="*" mode="serialized"/>
    </xsl:variable>
    <!-- string-value will work in the short term.  In the long term,
         you will need to generate g elements for each side of the
         equivalence, position them, and add equivalence symbol and
         brackets. -->
    <xsl:variable name="string-value" as="xs:string"
                  select="normalize-space(string-join( 
                          ( '(', $ss, ')' )
                          ))"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:sequence select="string()"/>
        </svg:title>
        <!--* Calculate new N S E W values from scratch *-->
        <xsl:variable name="N" as="xs:decimal" select="$bodysize div 2"/>
        <xsl:variable name="S" as="xs:decimal" select="$lineheight - $N"/>
        <xsl:variable name="E" as="xs:decimal" select="$bodysize * 0.85 * kb:textwidth($string-value)"/>
        <xsl:variable name="W" as="xs:decimal" select="0"/> 

        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $N, $S, $E, $W"/>
        </xsl:processing-instruction>
        <svg:g>
          <!-- debugging: color bg -->
          <!-- <svg:rect x="0" y="-{$N}" width="{$W + $E}" height="{$N + $S}"
                    style="fill: yellow;"/> -->
          <svg:text transform="translate({$padding}, {$sink})"
                    style="font-style: italic;">
            <xsl:sequence select="$string-value"/>
          </svg:text>
          <!-- In principle, vertical-align="central" ought
               to be better than using $sink, but it appears
               to have no effect. -->
          <!-- For debugging:  make a small mark at what we think
               is the eastern boundary -->

          <!-- <svg:line x1="{$W+$E}" y1="-{$N}"
                    x2="{$W+$E}" y2="{$S}"
                    style="stroke: red; stroke-width: 0.25"/> -->

          <!-- end debugging -->
        </svg:g>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g"/>
  </xsl:template>

  <!--................................................................
      3.4 Function application
      -->
  
  <!-- 3.4.1 Function application:  in general, some parts of function
       applications may need to be italicized (e.g. lowercase
       roman letters) and some parts must not be (Fraktur letters
       for bound variables).  Since my rough and ready text width
       calculations are not suitable for this kind of composition,
       we escape to an HTML fragment with 'i' tags. -->
  <xsl:template match="fa" as="element(svg:g)*">

    <!-- We need an id for this element. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>

    <!-- We generate a serialized form of the function application,
         to get a rough estimate of width.  It would be nice to 
         have something more accurate; this will work for now. -->
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates select="*" mode="serialized"/>
    </xsl:variable>
    <xsl:variable name="string-value" as="xs:string"
                  select="normalize-space(string-join( 
                          ( '(', $ss, ')' )
                          ))"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:sequence select="string()"/>
        </svg:title>
        <!--* Calculate new N S E W values from scratch *-->
        <xsl:variable name="N" as="xs:decimal" select="$bodysize div 2"/>
        <xsl:variable name="S" as="xs:decimal" select="$lineheight - $N"/>
        <xsl:variable name="E" as="xs:decimal"
                      select="$bodysize * 0.85 
                              * kb:textwidth(
                              concat($string-value,
                              '()', 
                              substring(
                              ',&#x200A;,&#x200A;,&#x200A;,&#x200A;',
                              1,
                              2 * (count(arg) - 1))
                              ))"/>
        <!-- string value will do in the cases we currently have -->
        <xsl:variable name="W" as="xs:decimal" select="0"/> 

        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $N, $S, $E, $W"/>
        </xsl:processing-instruction>
        <svg:g>
          <!-- debugging: color bg -->
          <!-- <svg:rect x="0" y="-{$N}" width="{$W + $E}" height="{$N + $S}"
                    style="fill: yellow;"/> -->

          <svg:text transform="translate({$padding}, {$sink})" xml:space="preserve"
              ><xsl:apply-templates select="functor"
              /><svg:tspan>(</svg:tspan
              ><xsl:apply-templates select="arg"
              /><svg:tspan>)</svg:tspan
          ></svg:text>
          
          <!-- older version:  do it in XHTML.  Works in some SVG engines,
               but not in Batik (no HTML renderer handy). So, abandoned
               when the solution above was found. -->
          <!--
          <svg:foreignObject x="{$padding}" y="-{$N}" 
                             width="{$W + $E}" height="{$N + $S}"
                             style="font-size: {$bodysize}px;">
            <xsl:element name="div" namespace="{$nsxhtml}">
              <xsl:attribute name="style">
                <xsl:text expand-text="yes">
                font-size: {$bodysize}px;
                </xsl:text>
              </xsl:attribute>
              <xsl:apply-templates select="." mode="xhtml"/>
            </xsl:element>
          </svg:foreignObject>
          -->
          
          <!-- For debugging:  make a small mark at what we think
               is the eastern boundary -->

          <!-- <svg:line x1="{$W+$E}" y1="-{$N}"
                    x2="{$W+$E}" y2="{$S}"
                    style="stroke: red; stroke-width: 0.25"/> -->

          <!-- end debugging -->
        </svg:g>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g"/>
  </xsl:template>

  <!-- The functor just returns a tspan -->
  <xsl:template match="functor" as="element(svg:tspan)">
    <xsl:choose>
      <xsl:when test="exists(@bound-var)">
        <svg:tspan>
          <xsl:value-of select="string(@bound-var)"/>
        </svg:tspan>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- functor/var returns italic tspan for italicized variable.
       Ditto arg/var -->
  <xsl:template match="functor/var | arg/var" as="element(svg:tspan)">
    <svg:tspan style="font-style: italic;">
      <xsl:value-of select="normalize-space(.)"/>
    </svg:tspan>
  </xsl:template>
  
  <!-- functor/@bound-var returns roman tspan for fraktur variable -->
  <!-- Fraktur F (𝔉) is used as a functor in Part III. -->
  
  <!-- Each arg returns one tspan, or two -->
  <xsl:template match="arg" as="element(svg:tspan)+">
    <xsl:if test="preceding-sibling::arg">
      <!-- U+200A is a HAIR SPACE ( ), looks better -->
      <svg:tspan>,&#x200A;</svg:tspan>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="exists(@bound-var)">
        <svg:tspan>
          <xsl:value-of select="string(@bound-var)"/>
        </svg:tspan>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- N.B.
       The grammar allows function applications to appear as arguments,
       but Frege appears not to do that, so I am not going to write
       code for it at the moment.
       -->

  <!--................................................................
      3.5 ad-hoc/nil 
      -->
  <!-- 3.5.1 ad-hoc -->
  <xsl:template match="ad-hoc" as="element(svg:g)+">
    <xsl:apply-templates select="nil"/>
  </xsl:template>
  
  <!-- 3.5.2 nil -->
  <xsl:template match="nil" as="element(svg:g)+">

    <!-- We need an id for this element. -->
    <xsl:variable name="ID" as="xs:string"
                  select="kb:id(.)"/>

    <xsl:variable name="this-g" as="element(svg:g)">
      <svg:g id="{$ID}">
        <svg:title>
          <xsl:sequence select="string()"/>
        </svg:title>
        <!--* Calculate new N S E W values from scratch *-->
        <xsl:variable name="N" as="xs:decimal" select="$bodysize div 2"/>
        <xsl:variable name="S" as="xs:decimal" select="$lineheight - $N"/>
        <xsl:variable name="E" as="xs:decimal" select="$bodysize * 0.8 * kb:textwidth(string())"/>
        <xsl:variable name="W" as="xs:decimal" select="0"/> <!-- not $padding ? why not? -->

        <xsl:processing-instruction name="kb">
          <xsl:sequence select="$ID, $N, $S, $E, $W"/>
        </xsl:processing-instruction>
        <svg:g>
          <svg:text transform="translate({$padding}, {$sink})"
                    style="font-style: italic;">
            <xsl:value-of select=" '&#xFEFF;' "/>
          </svg:text>
          <!-- In principle, vertical-align="central" ought
               to be better than using $sink, but it appears
               to have no effect. -->
          <!-- For debugging:  make a small mark at what we think
               is the eastern boundary -->

          <!-- <svg:line x1="{$W+$E}" y1="-{$N}"
                    x2="{$W+$E}" y2="{$S}"
                    style="stroke: red; stroke-width: 0.25"/> -->

          <!-- end debugging -->
        </svg:g>
      </svg:g>
    </xsl:variable>

    <!-- Return the definition for this element and those for its
         descendants -->
    <xsl:sequence select="$this-g"/>
  </xsl:template>

  <!--................................................................
      3.6 mention
      -->
  <!--* The only things that can be mentioned (and displayed without
      * any content stroke) are leaves.  So just pass through to
      * the leaf template to get the template.  But we need to 
      * generate an SVG document.
      *-->
  <xsl:template match="mention">
    <xsl:call-template name="formula"/>
    <!-- 
    <xsl:variable name="defs" as="element(svg:g)+">
      <xsl:apply-templates/>
    </xsl:variable>
    
    <xsl:variable name="top-g" as="element(svg:g)"
                  select="$defs[1]"/>
     -->
  </xsl:template>  

  <!--................................................................
      text() 
      -->
  <xsl:template match="text()[normalize-space() = '']"/>  

  <!--****************************************************************
      * 7 Mode 'xhtml'
      ****************************************************************
      *-->
  <!--* Used inside some leaves, e.g. fa *-->
  <xsl:template match="fa" mode="xhtml">
    <!--* remember that fa can appear as an argument of a
        * parent fa *-->
    <xsl:apply-templates select="functor | @functor" mode="xhtml"/>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="arg" mode="xhtml"/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="functor" mode="xhtml">
    <xsl:apply-templates mode="xhtml"/>
  </xsl:template>

  <!-- In some old XML functor may be an attribute. 
       In that case, guess at whether to italicize it.
       -->
  <xsl:template match="@functor" mode="xhtml">
    <xsl:choose>
      <xsl:when test="matches(., '^[a-z&#x0391;-&#x03A9;]$')">
        <xsl:element name="i" namespace="{$nsxhtml}">
          <xsl:sequence select="string()"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="span" namespace="{$nsxhtml}">
          <xsl:sequence select="string()"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="arg" mode="xhtml">
    <xsl:if test="preceding-sibling::arg">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="child::*">
        <xsl:apply-templates mode="xhtml"/>
      </xsl:when>
      <xsl:when test="attribute::bound-var">
        <xsl:sequence select="string(@bound-var)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Empty arg, I know not what I do.</xsl:message>
        <xsl:text>‽</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="var" mode="xhtml">
    <xsl:element name="i" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select="name()"/>
      <xsl:sequence select="string()"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="bound-var" mode="xhtml">
    <xsl:element name="span" namespace="{$nsxhtml}">
      <xsl:attribute name="class" select="name()"/>
      <xsl:sequence select="string()"/>
    </xsl:element>
  </xsl:template>
  
  <!--****************************************************************
      * 8 Mode 'serialized'
      ****************************************************************
      *-->
  <xsl:template match="text()" mode="serialized"/>

  <!--................................................................
      8.1 Top-level elements (mode='serialized')
  -->
  
  <xsl:template match="formula" mode="serialized" as="xs:string">
    <xsl:variable name="num" as="xs:string?">
      <xsl:apply-templates mode="serialized" select="@n"/>
    </xsl:variable>
    <xsl:variable name="body" as="xs:string">
      <xsl:apply-templates mode="serialized"
                           select="* except substitutions"/>
    </xsl:variable>
    <xsl:sequence
        select="if (parent::premise)
                then concat($num, $body)
                else concat($body, $num)"/>
  </xsl:template>
  
  <xsl:template match="inference" mode="serialized" as="xs:string">
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="string-join($ss, '')"/>
  </xsl:template>
  
  <xsl:template match="yes" mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string" select="'yes '"/>
    <xsl:variable name="s2" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($s1, $s2)"/>
  </xsl:template>
  
  <xsl:template match="maybe" mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string" select="'maybe '"/>
    <xsl:variable name="s2" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($s1, $s2)"/>
  </xsl:template>

  <!--................................................................
      8.2 Compound constructs (mode='serialized')
      -->
  <!-- N.B. Each compound construct must check to see if its
       argument(s) need parentheses. -->

  <!-- 8.2.1 not and not/not -->
  <xsl:template match="not[not(conditional)]"
                mode="serialized" as="xs:string">    
    <xsl:variable name="s1" as="xs:string" select="'not '"/>
    <xsl:variable name="s2" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($s1, $s2)"/>
  </xsl:template>
  
  <xsl:template match="not[conditional]"
                mode="serialized" as="xs:string">    
    <xsl:variable name="s1" as="xs:string" select="'not ('"/>
    <xsl:variable name="s2" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:variable name="s3" as="xs:string" select=" ')' "/>
    <xsl:sequence select="concat($s1, $s2, $s3)"/>
  </xsl:template>

  <!-- 8.2.2 conditional -->  
  <xsl:template match="conditional" mode="serialized" as="xs:string">
    <xsl:variable name="sc" as="xs:string">
      <xsl:apply-templates select="consequent" mode="serialized"/>
    </xsl:variable>
    <xsl:variable name="s" as="xs:string" select="' if '"/>    
    <xsl:variable name="sa" as="xs:string">
      <xsl:apply-templates select="antecedent" mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($sc, $s, $sa)"/>
  </xsl:template>
  
  <xsl:template match="antecedent" mode="serialized" as="xs:string">
    <xsl:variable name="lp" as="xs:string"
                  select="if (child::conditional) then '(' else ''"/>
    <xsl:variable name="rp" as="xs:string"
                  select="if (child::conditional) then ')' else ''"/>    
    <xsl:variable name="sa" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($lp, $sa, $rp)"/>
  </xsl:template>
  
  <xsl:template match="consequent" mode="serialized" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
  </xsl:template>

  <!-- 8.2.3 inferences -->  
  <!-- 8.2.3.1 premise -->   
  <xsl:template match="premise" mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string"
                  select="if (not(preceding-sibling::premise))
                          then 'we have: &#xA;'
                          else ', and:&#xA;'"/>
    <xsl:variable name="s2" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($s1, $s2)"/>
  </xsl:template>
  
  <!-- 8.2.3.2 infstep -->   
  <xsl:template match="infstep" mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string"
                  select="',&#xA;&#xA;from which '"/>
    <xsl:variable name="s2" as="xs:string*">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="string-join(($s1, $s2), '')"/>
  </xsl:template>
  
  <!-- 8.2.3.3 premise reference -->   
  <xsl:template match="premise-ref-con | premise-ref-ant"
                mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string" select="'via ('"/>
    <xsl:variable name="s3" as="xs:string"
                  select="if (self::premise-ref-con)
                          then '): '
                          else '):: '"/>
    <xsl:variable name="s2" as="xs:string+">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="string-join( ($s1, $s2, $s3), '')"/>
  </xsl:template>

  <!-- 8.2.3.4 conclusion -->     
  <xsl:template match="conclusion" mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string"
                 select=" 'we infer:&#xA;&#xA;' "/>
    <xsl:variable name="s2" as="xs:string">
      <xsl:apply-templates select="*" mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($s1, $s2)"/>
  </xsl:template>

  <!-- 8.2.3.5 substitution tables (in left-label of a premise,
       or in ref (premise reference of an inference step). --> 
  <xsl:template match="substitutions" mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string"
                  select=" '&#xA;[replacing: ' "/>
    <xsl:variable name="subs" as="xs:string+">
      <xsl:apply-templates select="subst" mode="serialized"/>
    </xsl:variable>
    <xsl:variable name="s9" as="xs:string" select=" '&#xA;]' "/>
    <xsl:sequence select="string-join( ($s1, $subs, $s9), '' )"/>
  </xsl:template>

  <!-- subst:  one taken/given pair -->
  <xsl:template match="subst" mode="serialized" as="xs:string">
    <xsl:variable name="taken" as="xs:string">
      <xsl:apply-templates select="taken" mode="serialized"/>
    </xsl:variable>
    <xsl:variable name="given" as="xs:string">
      <xsl:apply-templates select="given" mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat( 
                          '&#xA;    (', 
                          $taken, 
                          ' with ', 
                          $given, 
                          ')'
                          )"/>
  </xsl:template>

  <!-- taken:  old term to be removed -->
  <!-- given:  new term to be inserted -->
  <xsl:template match="taken | given"
                mode="serialized"
                as="xs:string">
    <xsl:apply-templates mode="serialized"/>
  </xsl:template>

  <!-- 8.2.4 universal quantification -->       
  <xsl:template match="univ" mode="serialized" as="xs:string">
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="if (child::conditional)
                          then string-join(
                          ( 'all ', string(@bound-var),
                            ' satisfy (', $ss, ')'
                          ), 
                          '')

                          else string-join(
                          ( 'all ', string(@bound-var),
                            ' satisfy ', $ss
                          ), 
                          '')

                          "/>
  </xsl:template>

  <!--................................................................
      8.3 Leaves and lower constructs (mode='serialized')
  -->
  <!-- If the formula has a number, emit it -->
  <xsl:template match="formula/@n" mode="serialized" as="xs:string">
    <xsl:variable name="subs" as="xs:string?">
      <xsl:apply-templates mode="serialized"
                           select="substitutions"/>
    </xsl:variable>
    <xsl:sequence
        select="if (parent::formula/parent::premise)
                then concat('(', string(.), $subs, '=) ')
                else concat(' (=', string(.), $subs, ')')
                "/>
  </xsl:template>
  
  <xsl:template match="leaf" mode="serialized" as="xs:string">
    <xsl:apply-templates mode="serialized"/>
  </xsl:template>
  
  <xsl:template match="var" mode="serialized" as="xs:string">
    <xsl:sequence select="(@bound-var/string(), ./string())[1]"/>
  </xsl:template>
  
  <xsl:template match="ref" mode="serialized" as="xs:string">
    <xsl:variable name="s1" as="xs:string"
                  select="if (preceding-sibling::ref) then ', ' else '' "/>
    <xsl:variable name="s2" as="xs:string"
                  select="(@n/string(), string(.))[1]"/>
    <xsl:variable name="s3" as="xs:string?">
      <xsl:apply-templates select="substitutions" mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="concat($s1, $s2, $s3)"/>
  </xsl:template>

  <!--................................................................
      Leaves with internal structure
      -->
  <xsl:template match="equivalence" mode="serialized" as="xs:string">
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates select="*" mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="string-join( 
      ( '(', $ss, ')' )
      )"/>
  </xsl:template>
  
  <xsl:template match="equiv-sign" mode="serialized" as="xs:string">
    <xsl:sequence select=" '≡' "/>
  </xsl:template>

  <!-- function applications -->
  <xsl:template match="fa[functor]" mode="serialized" as="xs:string">
    <xsl:variable name="sfun" as="xs:string*">
      <xsl:apply-templates select="functor" mode="serialized"/>
    </xsl:variable>
    <xsl:variable name="sarg" as="xs:string*">
      <xsl:apply-templates select="arg" mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="string-join( 
      ( $sfun, '(', $sarg, ')' )
      )"/>
  </xsl:template>
  
  <!-- @functor is out of date but retained for a while for 
       compatibility -->
  <xsl:template match="fa[@functor]" mode="serialized" as="xs:string">
    <xsl:variable name="ss" as="xs:string*">
      <xsl:apply-templates select="*" mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="string-join( 
      ( string(@functor), '(', $ss, ')' )
      )"/>
  </xsl:template>
  
  
  <xsl:template match="arg" mode="serialized" as="xs:string">
    <xsl:variable name="comma" as="xs:string"
                  select="if (preceding-sibling::arg) 
                          then ', '
                          else '' "/>
    <xsl:variable name="ss" as="xs:string*">
      <xsl:choose>
        <xsl:when test="@bound-var">
          <xsl:sequence select="string(@bound-var)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="*" mode="serialized"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="string-join( ($comma, $ss) )"/>
  </xsl:template>

  <!-- ad-hoc/nil -->
  <xsl:template match="ad-hoc" mode="serialized" as="xs:string">
    <xsl:choose>
      <xsl:when test="nil">
        <xsl:sequence select=" 'nil' "/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- mention -->  
  <xsl:template match="mention" mode="serialized" as="xs:string">
    <xsl:variable name="ss" as="xs:string">
      <xsl:apply-templates mode="serialized"/>
    </xsl:variable>
    <xsl:sequence select="string-join( ('expr ', $ss) )"/>
  </xsl:template>

  <!--****************************************************************
      * 9 Functions
      ****************************************************************
      *-->
  <!-- 9.1 kb:id(e)  generate identifier for element e -->
  <xsl:function name="kb:id" as="xs:string">
    <xsl:param name="e" as="element()"/>

    <xsl:value-of select="concat(local-name($e), 
                          '-', 
                          1 + count($e/preceding::* | $e/ancestor::*)
                          )"/>
  </xsl:function>

  <!-- 9.2 textwidth() -->
  <xsl:function name="kb:textwidth" as="xs:decimal">
    <xsl:param name="s" as="xs:string"/>
    <!-- We handle only what Frege uses -->   
    <xsl:choose>
      <xsl:when test="string-length($s) gt 1">
        <xsl:value-of
            select="kb:textwidth(substring($s, 1, 1))
                    +
                    kb:textwidth(substring($s, 2))"/>
      </xsl:when>
      <xsl:when test="string-length($s) eq 1">
        <xsl:value-of
            select="if (matches($s, '^[fijlt ]$'))
                    then 0.5
                    else if (matches($s, '^[\(\)\[\],]$'))
                    then 0.25
                    else if (matches($s, '^[mw]$'))
                    then 1.5
                    else if ($s eq lower-case($s))
                    then 1
                    else if ($s eq 'I')
                    then 1
                    else if (matches($s, '^[≡]$'))
                    then 1.2
                    else if (matches($s, '^[MWΜ]$'))
                    then 2
                    else if ($s eq upper-case($s))
                    then 1.5
                    else 1 (: guess :)
                    "/>
      </xsl:when>
      <xsl:when test="string-length($s) eq 0">
        <xsl:sequence select="0"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
