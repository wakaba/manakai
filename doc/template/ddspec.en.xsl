<?xml version="1.0" encoding="iso-2022-jp"?>
<!DOCTYPE t:stylesheet [
  <!ENTITY ddoc "http://suika.fam.cx/~wakaba/archive/2004/dis/Document#">
  <!ENTITY f "http://suika.fam.cx/~wakaba/archive/2004/dom/feature#">
  
  <!ENTITY referent.variable '
    <t:variable name="referent"
        select="($rootDocument | $allDataType | $anyIDLType | $allIDLInterface |
                 $allModules)
                [child::dump:uri/@dump:uri = current ()/@dump:ref]"/>
  '>
]>
<t:stylesheet xmlns:t="http://www.w3.org/1999/XSL/Transform"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:def="http://suika.fam.cx/~wakaba/archive/2004/dom/feature#spec."
    xmlns:doc="http://suika.fam.cx/~wakaba/archive/2005/7/tutorial#"
    xmlns:ddoc="http://suika.fam.cx/~wakaba/archive/2004/dis/Document#"
    xmlns:f="http://suika.fam.cx/~wakaba/archive/2004/dom/feature#"
    xmlns:tree="http://pc5.2ch.net/test/read.cgi/hp/1101043958/564"
    xmlns:xhtml1="http://www.w3.org/1999/xhtml"
    xmlns:xhtml2="http://www.w3.org/2002/06/xhtml2/"
    xmlns:html3="urn:x-suika-fam-cx:markup:ietf:html:3:draft:00:"
    xmlns:html5="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:dump="http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#DISDump/"
    xmlns:ddel="http://suika.fam.cx/~wakaba/archive/2005/disdoc#"
    xmlns:idl="http://suika.fam.cx/~wakaba/archive/2004/dis/IDL#"
    xmlns:j="http://suika.fam.cx/~wakaba/archive/2004/dis/Java#"
    xmlns:js="http://suika.fam.cx/~wakaba/archive/2004/dis/ECMAScript#"
    xmlns:p="http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#"
    xmlns:script="http://suika.fam.cx/~wakaba/archive/2005/5/script#"
    xmlns:sw010="urn:x-suika-fam-cx:markup:suikawiki:0:10:"
    xmlns:ddoct="http://suika.fam.cx/~wakaba/archive/2005/8/disdump-xslt#"
    xmlns:rfc2119="http://suika.fam.cx/~wakaba/archive/2005/rfc2119/"
    xmlns:dis="http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis--"
    version="1.0">
  <t:import href="disdump.ja.xsl"/>
  
  <t:param name="referencer-uri"/>

  <t:variable name="rootDocument" select="/child::dump:moduleSet
                                          /child::dump:document"/>
  <t:variable name="allIDLInterface" select="$allModules/child::dump:interface"/>
  <t:variable name="anyIDLType" select="$allIDLInterface | $allDataType"/>

<!-- Modes -->
  
  <t:template match="/">
    <t:choose>
    <t:when test="string ($mode) = 'dom-document'">
      <t:apply-templates select="$rootDocument
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="dom-document"/>
    </t:when>
    <t:when test="string ($mode) = 'dom-chapter'">
      <t:variable name="chapter" select="$rootDocument
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]"/>
      <t:variable name="referencer"
                select="$rootDocument
                        [child::dump:uri/@dump:uri = string ($referencer-uri)]/
                        child::*[@dump:ref = $chapter/child::dump:uri/@dump:uri]"/>
      <t:apply-templates select="$chapter" mode="dom-chapter">
        <t:with-param name="number">
          <t:if test="$referencer-uri">
            <t:apply-templates select="$referencer" mode="number"/>
          </t:if>
        </t:with-param>
        <t:with-param name="referencer" select="$referencer"/>
      </t:apply-templates>
    </t:when>
    <t:when test="string ($mode) = 'idl-file'">
      <idl:File>
        <t:attribute name="xml:space">preserve</t:attribute>
        <t:variable name="a">
          <t:apply-templates select="$allModules
                                     [
                                       child::dump:uri/@dump:uri = string ($uri)
                                     ]" mode="idl-file"/>
        </t:variable>
        <t:value-of select="$a"/>
      </idl:File>
    </t:when>
    <t:when test="string ($mode) = 'java-file'">
      <idl:File>
        <t:attribute name="xml:space">preserve</t:attribute>
        <t:variable name="a">
          <t:apply-templates select="$allIDLInterface
                                     [
                                       child::dump:uri/@dump:uri = string ($uri)
                                     ]" mode="java-file"/>
        </t:variable>
        <t:value-of select="$a"/>
      </idl:File>
    </t:when>
    <t:when test="string ($mode) = 'list'">
      <t:apply-templates select="self::node ()" mode="list"/>
    </t:when>
    <t:otherwise>
      <p xml:lang="en" lang="en">Mode <code>
        <t:value-of select="$mode"/>
      </code> not supported.
      (Resource: <code class="uri">
        <t:value-of select="$uri"/>
      </code>)</p>
    </t:otherwise>
    </t:choose>
  </t:template>

<!-- File List -->
  
  <t:template match="dump:moduleSet" mode="list">
    <t:apply-templates select="child::dump:document
                               [child::ddoc:rel/@dump:uri = '&ddoc;Document']"
        mode="list"/>
    <t:for-each select="$allModules">
      <t:if test="$rootDocument/child::dump:document
                  [(child::ddoc:as/@dump:uri =
                    'http://suika.fam.cx/~wakaba/archive/2004/dis/IDL#File') and
                   (@dump:ref = current ()/child::dump:uri/@dump:uri)]">
        <t:apply-templates select="self::node ()" mode="list"/>
      </t:if>
    </t:for-each>
  </t:template>

  <t:template match="dump:document[child::ddoc:rel/@dump:uri = '&ddoc;Document']"
      mode="list">
    <ddoct:item ddoct:mode="dom-document">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name"/>
      </t:attribute>
    </ddoct:item>
    <t:apply-templates
        select="parent::node ()/
                child::dump:document
                [child::dump:uri/@dump:uri =
                 current ()/
                 child::dump:document
                 [child::ddoc:rel/@dump:uri = '&f;Chapter']/
                 @dump:ref]"
        mode="list-dom-chapter">
      <t:with-param name="referencer" select="self::node ()"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="dump:document" mode="list-dom-chapter">
    <t:param name="referencer" select="/parent::node ()"/>
    <ddoct:item ddoct:mode="dom-chapter"
        ddoct:referencer-uri="{$referencer/child::dump:uri/@dump:uri}">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name"/>
      </t:attribute>
    </ddoct:item>
  </t:template>
  
  <t:template match="dump:module" mode="list">
    <ddoct:item ddoct:mode="idl-file">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:variable name="fileName">
          <t:apply-templates select="self::node ()" mode="idl-file-name-dir"/>
          <t:apply-templates select="self::node ()" mode="idl-file-name-name"/>
        </t:variable>
        <t:value-of select="$fileName"/>
      </t:attribute>
    </ddoct:item>
    <t:apply-templates select="child::dump:interface" mode="list"/>
  </t:template>

  <t:template match="dump:interface" mode="list">
    <ddoct:item ddoct:mode="java-file">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:variable name="fileName">
          <t:apply-templates select="self::node ()" mode="java-file-name-dir"/>
          <t:apply-templates select="self::node ()" mode="java-file-name-name"/>
        </t:variable>
        <t:value-of select="$fileName"/>
      </t:attribute>
    </ddoct:item>
  </t:template>

<!-- Root Documents -->

  <t:template match="dump:document[child::ddoc:rel/@dump:uri = '&ddoc;Document']"
      mode="dom-document">
    <html class="formal-specification spec-root">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:apply-templates select="self::node ()" mode="title-attr"/>
        </title>
      </head>
      <body>
        <div class="header">
          <h1>
            <t:apply-templates select="self::node ()" mode="title-text"/>
          </h1>
          <h2>
            @@Specification@@ @@Today@@
          </h2>
          <dl class="versions-uri">
            @@ this version @@
          </dl>
          <dl class="authors">
            @@ authors @@
          </dl>
          <p>&#xA6; @@2005 ...@@@</p>
          <t:apply-templates
              select="child::dump:document
                      [not (child::ddoc:rel/@dump:uri = '&f;Chapter')]">
            <t:with-param name="rank" select="2"/>
          </t:apply-templates>
        </div>
      </body>
    </html>
  </t:template>

<!-- Chapters -->

  <t:template match="dump:document" mode="dom-chapter">
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="referencer" select="/parent::node ()"/>
    <html class="formal-specification spec-chapter">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:apply-templates select="self::node ()" mode="title-attr"/>
        </title>
      </head>
      <body>
        <h1>
          <t:apply-templates select="self::node ()" mode="heading-content">
            <t:with-param name="number" select="$number"/>
            <t:with-param name="docType"
                select="$referencer/child::ddoc:rel/@dump:uri"/>
          </t:apply-templates>
        </h1>
        <t:apply-templates select="self::node ()" mode="hb">
          <t:with-param name="rank" select="1"/>
          <t:with-param name="number" select="$number"/>
          <t:with-param name="docType"
              select="$referencer/child::ddoc:rel/@dump:uri"/>
        </t:apply-templates>
      </body>
    </html>
  </t:template>

<!-- Titles -->

  <t:template match="dump:document | dump:dataType" mode="title-text">
    <t:param name="short" select="false ()"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:choose>
    <t:when test="$short and child::ddoc:shortTitle">
      <t:apply-templates select="child::ddoc:shortTitle" mode="title-text"/>
    </t:when>
    <t:when test="$short and child::ddoc:title">
      <t:apply-templates select="child::ddoc:title" mode="title-text"/>
    </t:when>
    <t:when test="child::ddoc:longTitle">
      <t:apply-templates select="child::ddoc:longTitle" mode="title-text"/>
    </t:when>
    <t:when test="child::ddoc:title">
      <t:apply-templates select="child::ddoc:title" mode="title-text"/>
    </t:when>
    <t:when test="child::ddoc:shortTitle">
      <t:apply-templates select="child::ddoc:shortTitle" mode="title-text"/>
    </t:when>
    <t:when test="$docType = '&ddoc;abstract'">
      <t:call-template name="name-abstract"/>
    </t:when>
    <t:when test="$docType = '&f;ECMAScriptBinding'">
      <t:call-template name="name-ecma-script-binding"/>
    </t:when>
    <t:when test="$docType = '&f;JavaBinding'">
      <t:call-template name="name-java-binding"/>
    </t:when>
    <t:when test="$docType = '&f;PerlBinding'">
      <t:call-template name="name-perl-binding"/>
    </t:when>
    <t:when test="$docType = '&f;IDLDefinitions'">
      <t:call-template name="name-idl-definitions"/>
    </t:when>
    <t:when test="$docType = '&ddoc;index'">
      <t:call-template name="name-index"/>
    </t:when>
    <t:when test="$docType = '&ddoc;references'">
      <t:call-template name="name-references"/>
    </t:when>
    <t:when test="$docType = '&ddoc;informativeReferences'">
      <t:call-template name="name-informative-references"/>
    </t:when>
    <t:when test="$docType = '&ddoc;normativeReferences'">
      <t:call-template name="name-normative-references"/>
    </t:when>
    <t:when test="$docType = '&ddoc;status'">
      <t:call-template name="name-status"/>
    </t:when>
    <t:when test="$docType = '&ddoc;shortTOC'">
      <t:call-template name="name-toc"/>
    </t:when>
    <t:when test="$docType = '&ddoc;longTOC'">
      <t:call-template name="name-expanded-toc"/>
    </t:when>
    <t:when test="@dump:localName">
      <code><t:value-of select="@dump:localName"/></code>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:document | dump:dataType" mode="title-attr">
    <t:param name="short" select="false ()"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:choose>
    <t:when test="$short and child::ddoc:shortTitle">
      <t:apply-templates select="child::ddoc:shortTitle" mode="title-attr"/>
    </t:when>
    <t:when test="$short and child::ddoc:title">
      <t:apply-templates select="child::ddoc:title" mode="title-attr"/>
    </t:when>
    <t:when test="child::ddoc:longTitle">
      <t:apply-templates select="child::ddoc:longTitle" mode="title-attr"/>
    </t:when>
    <t:when test="child::ddoc:title">
      <t:apply-templates select="child::ddoc:title" mode="title-attr"/>
    </t:when>
    <t:when test="child::ddoc:shortTitle">
      <t:apply-templates select="child::ddoc:shortTitle" mode="title-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;abstract'">
      <t:call-template name="name-abstract-attr"/>
    </t:when>
    <t:when test="$docType = '&f;ECMAScriptBinding'">
      <t:call-template name="name-ecma-script-binding-attr"/>
    </t:when>
    <t:when test="$docType = '&f;JavaBinding'">
      <t:call-template name="name-java-binding-attr"/>
    </t:when>
    <t:when test="$docType = '&f;PerlBinding'">
      <t:call-template name="name-perl-binding-attr"/>
    </t:when>
    <t:when test="$docType = '&f;IDLDefinitions'">
      <t:call-template name="name-idl-definitions-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;index'">
      <t:call-template name="name-index-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;references'">
      <t:call-template name="name-references-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;informativeReferences'">
      <t:call-template name="name-informative-references-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;normativeReferences'">
      <t:call-template name="name-normative-references-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;status'">
      <t:call-template name="name-status-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;shortTOC'">
      <t:call-template name="name-toc-attr"/>
    </t:when>
    <t:when test="$docType = '&ddoc;longTOC'">
      <t:call-template name="name-expanded-toc-attr"/>
    </t:when>
    <t:when test="@dump:localName"><t:value-of select="@dump:localName"/></t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous-attr"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:interface" mode="title-text">
    <t:call-template name="name-the-interface">
      <t:with-param name="name">
        <t:apply-templates select="self::node ()" mode="idl-name"/>
      </t:with-param>
    </t:call-template>
  </t:template>
  
  <t:template match="dump:interface" mode="title-attr">
    <t:call-template name="name-the-interface">
      <t:with-param name="name" select="@dump:localName"/>
    </t:call-template>
  </t:template>
  
  <t:template match="dump:document | dump:dataType | dump:interface |
                     dump:module"
      mode="heading-content">
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="value" select="/parent::node ()"/>
    <t:if test="$number">
      <t:copy-of select="$number"/>
      <t:text> </t:text>
    </t:if>
    <t:choose>
    <t:when test="string-length ($value)">
      <t:copy-of select="$value"/>
    </t:when>
    <t:otherwise>
      <t:apply-templates select="self::node ()" mode="title-text">
        <t:with-param name="docType" select="$docType"/>
      </t:apply-templates>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddoc:title" mode="title-text">
    <t:apply-templates/>
  </t:template>
  <t:template match="ddoc:shortTitle" mode="title-text">
    <t:apply-templates/>
  </t:template>
  <t:template match="ddoc:longTitle" mode="title-text">
    <t:apply-templates/>
  </t:template>
  
  <t:template match="ddoc:title" mode="title-attr">
    <t:apply-templates mode="attr"/>
  </t:template>
  <t:template match="ddoc:shortTitle" mode="title-attr">
    <t:apply-templates mode="attr"/>
  </t:template>
  <t:template match="ddoc:longTitle" mode="title-attr">
    <t:apply-templates mode="attr"/>
  </t:template>

  <t:template match="dump:document | dump:dataType | dump:interface" mode="id">
    <t:value-of select="@dump:localName"/>
  </t:template>
  
  <t:template match="dump:document" mode="file-name">
    <t:if test="@dump:filePathStem">
      <t:value-of select="@dump:filePathStem"/>
      <t:value-of select="$lang-suffix"/>
      <t:value-of select="$html-type-suffix"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:document
                     [child::ddoc:rel/@dump:uri = '&ddoc;Document']" mode="doc-uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name"/>
  </t:template>
  
  <t:template match="dump:document
                     [child::ddoc:rel/@dump:uri = '&ddoc;Document']" mode="uri">
    <t:apply-templates select="self::node ()" mode="doc-uri"/>
  </t:template>
  
  <t:template match="dump:document |
                     dump:dataType | dump:interface" mode="doc-uri">
    <t:param name="reference"
        select="$rootDocument/child::*[@dump:ref = current ()/dump:uri/@dump:uri]"/>
    <t:choose>
    <t:when test="$reference/child::ddoc:rel/@dump:uri = '&f;Chapter'">
      <t:apply-templates select="self::node ()" mode="file-name"/>
    </t:when>
    <t:otherwise>
      <t:apply-templates select="$reference/parent::node ()" mode="doc-uri"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:document |
                     dump:dataType | dump:interface" mode="uri">
    <t:param name="reference"
        select="$rootDocument/child::*[@dump:ref = current ()/dump:uri/@dump:uri]"/>
    <t:choose>
    <t:when test="$reference/child::ddoc:rel/@dump:uri = '&f;Chapter'">
      <t:apply-templates select="self::node ()" mode="file-name"/>
    </t:when>
    <t:otherwise>
      <t:variable name="doc-uri">
        <t:apply-templates select="$reference/parent::node ()" mode="doc-uri"/>
      </t:variable>
      <t:if test="string-length ($doc-uri)">
        <t:copy-of select="$doc-uri"/>
        <t:text>#</t:text>
        <t:apply-templates select="self::node ()" mode="id"/>
      </t:if>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]" mode="number">
    <t:param name="number" select="/parent::node ()"/>
    <t:choose>
    <t:when test="child::ddoc:rel/@dump:uri = '&ddoc;appendix'">
      <t:number
          count="dump:document
                 [child::ddoc:rel/@dump:uri = '&ddoc;appendix']"
          format="A."/>
    </t:when>
    <t:when test="not (child::ddoc:rel/@dump:uri = '&ddoc;additionalSection')">
      <t:copy-of select="$number"/>
      <t:number
          count="dump:document
                 [not (child::ddoc:rel/@dump:uri = '&ddoc;additionalSection') and
                  not (child::ddoc:rel/@dump:uri = '&ddoc;appendix')]"
          format="1."/>
    </t:when>
    </t:choose>
  </t:template>
  
  <t:template match="dump:interface" mode="number">
    <t:param name="number" select="/parent::node ()"/>
    <t:copy-of select="$number"/>
    <t:number
          count="dump:interface"
          format="1."/>
  </t:template>

  <t:template match="dump:dataType | dump:document" mode="ref">
    <t:param name="docType" select="/parent::node ()"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="as-section" select="false ()"/>
    &referent.variable;
    <t:variable name="uri">
      <t:apply-templates select="self::node ()" mode="uri">
        <t:with-param name="docType" select="$docType"/>
      </t:apply-templates>
    </t:variable>
    <t:choose>
    <t:when test="not ($as-section) and string-length ($uri)">
      <a href="{$uri}">
        <t:apply-templates select="self::node ()" mode="idl-name"/>
      </a>
    </t:when>
    <t:when test="not ($as-section)">
      <t:apply-templates select="self::node ()" mode="idl-name"/>
    </t:when>
    <t:when test="string-length ($uri)">
      <a href="{$uri}">
        <t:if test="$number">
          <t:copy-of select="$number"/>
          <t:text> </t:text>
        </t:if>
        <t:apply-templates select="self::node ()" mode="title-text">
          <t:with-param name="docType" select="$docType"/>
        </t:apply-templates>
      </a>
    </t:when>
    <t:otherwise>
      <t:if test="$number">
        <t:copy-of select="$number"/>
        <t:text> </t:text>
      </t:if>
      <t:apply-templates select="self::node ()" mode="title-text">
        <t:with-param name="docType" select="$docType"/>
      </t:apply-templates>
    </t:otherwise>
    </t:choose>
  </t:template>

  <t:template match="dump:interface" mode="ref">
    <t:param name="docType" select="/parent::node ()"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="as-section" select="false ()"/>
    &referent.variable;
    <a>
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="docType" select="$docType"/>
        </t:apply-templates>
      </t:attribute>
      <t:if test="not ($as-section)">
        <t:apply-templates select="self::node ()" mode="idl-name"/>
      </t:if>
      <t:if test="$as-section">
        <t:if test="$number and $as-section">
          <t:copy-of select="$number"/>
          <t:text> </t:text>
        </t:if>
        <t:apply-templates select="self::node ()" mode="title-text">
          <t:with-param name="docType" select="$docType"/>
        </t:apply-templates>
      </t:if>
    </a>
  </t:template>
  
  <t:template match="dump:attribute | dump:method | dump:constGroup" mode="uri">
    <t:apply-templates select="parent::node ()" mode="doc-uri"/>
    <t:text>#</t:text>
    <t:apply-templates select="self::node ()" mode="id"/>
  </t:template>
  <t:template match="dump:attribute | dump:method | dump:constGroup" mode="doc-uri">
    <t:apply-templates select="parent::node ()" mode="doc-uri"/>
  </t:template>
  
  <t:template match="dump:attribute" mode="id">
    <t:apply-templates select="parent::node ()" mode="id"/>
    <t:text>-attr-</t:text>
    <t:value-of select="@dump:localName"/>
  </t:template>
  
  <t:template match="dump:method" mode="id">
    <t:apply-templates select="parent::node ()" mode="id"/>
    <t:text>-method-</t:text>
    <t:value-of select="@dump:localName"/>
  </t:template>
  
  <t:template match="dump:param" mode="id">
    <t:apply-templates select="parent::node ()" mode="id"/>
    <t:text>-param-</t:text>
    <t:value-of select="@dump:localName"/>
  </t:template>

  <t:template match="dump:method | dump:attribute | dump:param" mode="ref">
    <t:param name="short" select="false ()"/>
    <a>
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri"/>
      </t:attribute>
      <t:if test="not ($short)">
        <code>
          <t:apply-templates select="parent::node ()" mode="idl-name"/>
          <t:text>.</t:text>
          <t:apply-templates select="self::node ()" mode="idl-name"/>
        </code>
      </t:if>
      <t:if test="$short">
        <t:apply-templates select="self::node ()" mode="idl-name"/>
      </t:if>
    </a>
  </t:template>

  <t:template match="dump:param" mode="ref">
    <t:param name="short" select="false ()"/>
    <a>
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri"/>
      </t:attribute>
      <var>
        <t:apply-templates select="self::node ()" mode="idl-name"/>
      </var>
    </a>
  </t:template>

<!-- Contents -->

  <t:template match="dump:document | dump:dataType | dump:interface">
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:param name="number" select="/parent::node ()"/>
    <div class="section">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <t:apply-templates select="self::node ()" mode="heading">
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="number" select="$number"/>
      </t:apply-templates>
      <t:apply-templates select="self::node ()" mode="hb">
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="number" select="$number"/>
      </t:apply-templates>
    </div>
  </t:template>
  
  <t:template match="dump:document" mode="hb">
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:apply-templates select="child::ddoc:content">
      <t:with-param name="rank" select="$rank + 1"/>
      <t:with-param name="docType" select="$docType"/>
      <t:with-param name="number" select="$number"/>
    </t:apply-templates>
    <t:apply-templates select="child::dump:document">
      <t:with-param name="rank" select="$rank + 1"/>
      <t:with-param name="docType" select="$docType"/>
      <t:with-param name="number" select="$number"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="dump:dataType" mode="hb">
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:apply-templates select="child::dump:description">
      <t:with-param name="rank" select="$rank + 1"/>
      <t:with-param name="docType" select="$docType"/>
      <t:with-param name="number" select="$number"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="dump:interface" mode="hb">
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:apply-templates select="child::dump:description">
      <t:with-param name="rank" select="$rank + 1"/>
      <t:with-param name="docType" select="$docType"/>
      <t:with-param name="number" select="$number"/>
    </t:apply-templates>
    <dl class="dump-info dump-info-interface">
      <dt><t:call-template name="label-idl-definition"/></dt>
      <dd><t:apply-templates select="self::node ()" mode="idl"/></dd>
      <dt><t:call-template name="label-bindings"/></dt>
      <dd>
        <a>
          <t:attribute name="href">
            <t:apply-templates select="self::node ()" mode="uri-java"/>
          </t:attribute>
          <t:call-template name="label-java-binding"/>
        </a>
        <t:call-template name="label-sep"/>
        <a>
          <t:attribute name="href">
            <t:apply-templates select="self::node ()" mode="uri-es"/>
          </t:attribute>
          <t:call-template name="label-ecma-script-binding"/>
        </a>
        <t:call-template name="label-sep"/>
        <a>
          <t:attribute name="href">
            <t:apply-templates select="self::node ()" mode="uri-pl"/>
          </t:attribute>
          <t:call-template name="label-perl-binding"/>
        </a>
      </dd>
      <t:apply-templates select="child::dump:constGroup" mode="dl"/>
      <t:if test="child::dump:attribute[not (@dump:ref)]">
        <dt><t:call-template name="label-attributes"/></dt>
        <dd>
          <dl>
            <t:apply-templates select="dump:attribute[not (@dump:ref)]" mode="dl"/>
          </dl>
        </dd>
      </t:if>
      <t:if test="child::dump:method[not (@dump:ref)]">
        <dt><t:call-template name="label-methods"/></dt>
        <dd>
          <dl>
            <t:apply-templates select="dump:method[not (@dump:ref)]" mode="dl"/>
          </dl>
        </dd>
      </t:if>
    </dl>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]">
    <t:param name="rank" select="1"/>
    <t:param name="number" select="/parent::node ()"/>
    &referent.variable;
    <t:apply-templates select="$referent" mode="hb">
      <t:with-param name="rank" select="$rank"/>
      <t:with-param name="docType" select="child::ddoc:rel/@dump:uri"/>
      <t:with-param name="number">
        <t:apply-templates select="self::node ()" mode="number">
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </t:with-param>
    </t:apply-templates>
    <t:if test="not ($referent)">
      <t:apply-templates select="self::node ()" mode="unknown"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]
                     [child::ddoc:rel/@dump:uri = '&ddoc;subsection']">
    <t:param name="rank" select="1"/>
    <t:param name="number" select="/parent::node ()"/>
    &referent.variable;
    <t:apply-templates select="$referent">
      <t:with-param name="rank" select="$rank"/>
      <t:with-param name="docType" select="child::ddoc:rel/@dump:uri"/>
      <t:with-param name="number">
        <t:apply-templates select="self::node ()" mode="number">
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </t:with-param>
    </t:apply-templates>
    <t:if test="not ($referent)">
      <t:apply-templates select="self::node ()" mode="unknown"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]
                     [child::ddoc:as/@dump:uri =
                      'http://suika.fam.cx/~wakaba/archive/2004/dis/IDL#File']">
    <t:param name="rank" select="1"/>
    <t:param name="number" select="/parent::node ()"/>
    &referent.variable;
    <t:apply-templates select="$referent" mode="idl">
      <t:with-param name="rank" select="$rank"/>
      <t:with-param name="docType" select="child::ddoc:rel/@dump:uri"/>
      <t:with-param name="number">
        <t:apply-templates select="self::node ()" mode="number">
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </t:with-param>
    </t:apply-templates>
    <t:if test="not ($referent)">
      <t:apply-templates select="self::node ()" mode="unknown"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]
                     [child::ddoc:as/@dump:uri =
                      'http://suika.fam.cx/~wakaba/archive/2004/dis/Java#Package']">
    <t:param name="rank" select="1"/>
    <t:param name="number" select="/parent::node ()"/>
    &referent.variable;
    <t:apply-templates select="$referent" mode="java">
      <t:with-param name="rank" select="$rank"/>
      <t:with-param name="docType" select="child::ddoc:rel/@dump:uri"/>
      <t:with-param name="number">
        <t:apply-templates select="self::node ()" mode="number">
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </t:with-param>
    </t:apply-templates>
    <t:if test="not ($referent)">
      <t:apply-templates select="self::node ()" mode="unknown"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]
                     [child::ddoc:as/@dump:uri = '&f;ECMAScriptBindingDefinition']">
    <t:param name="rank" select="1"/>
    <t:param name="number" select="/parent::node ()"/>
    &referent.variable;
    <t:apply-templates select="$referent" mode="es">
      <t:with-param name="rank" select="$rank"/>
      <t:with-param name="docType" select="child::ddoc:rel/@dump:uri"/>
      <t:with-param name="number">
        <t:apply-templates select="self::node ()" mode="number">
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </t:with-param>
    </t:apply-templates>
    <t:if test="not ($referent)">
      <t:apply-templates select="self::node ()" mode="unknown"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]
                     [child::ddoc:as/@dump:uri = '&f;PerlBindingDefinition']">
    <t:param name="rank" select="1"/>
    <t:param name="number" select="/parent::node ()"/>
    &referent.variable;
    <t:apply-templates select="$referent" mode="pl">
      <t:with-param name="rank" select="$rank"/>
      <t:with-param name="docType" select="child::ddoc:rel/@dump:uri"/>
      <t:with-param name="number">
        <t:apply-templates select="self::node ()" mode="number">
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </t:with-param>
    </t:apply-templates>
    <t:if test="not ($referent)">
      <t:apply-templates select="self::node ()" mode="unknown"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:document[@dump:ref]" mode="hb">
    <t:param name="rank" select="1"/>
    <t:apply-templates
        select="$rootDocument[child::dump:uri/@dump:uri = current ()/@dump:ref]"
        mode="hb">
      <t:with-param name="rank" select="$rank"/>
      <t:with-param name="docType" select="child::ddoc:rel/@dump:uri"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="dump:document/child::ddoc:rel"/>
  <t:template match="dump:document/child::ddoc:rel/@dump:uri"/>
  <t:template match="dump:document/@dump:filePathStem"/>
  <t:template match="dump:dataType/@dump:filePathStem"/>
  <t:template match="dump:interface/@dump:filePathStem"/>
  <t:template match="dump:document/@ddoct:basePath"/>
  <t:template match="dump:dataType/@ddoct:basePath"/>
  <t:template match="dump:interface/@ddoct:basePath"/>
  <t:template match="dump:document/@dump:localName"/>
  <t:template match="dump:dataType/@dump:localName"/>
  <t:template match="dump:interface/@dump:localName"/>
  <t:template match="dump:document/@dump:namespaceURI"/>
  <t:template match="dump:dataType/@dump:namespaceURI"/>
  <t:template match="dump:interface/@dump:namespaceURI"/>
  <t:template match="dump:document/@dump:ref"/>
  
  <t:template match="dump:dataType[child::idl:sequenceOf]">
    <div class="paragraphs">
      <div class="caption">
        <t:call-template name="label-type-definition"/>
        <t:text> </t:text>
        <t:apply-templates select="self::node ()" mode="idl-name"/>
      </div>
    </div>
    <t:apply-templates select="self::node ()" mode="value-description"/>
    <dl class="dump-info dump-info-data-type">
      <dt><t:call-template name="label-idl-definition"/></dt>
      <dd><t:apply-templates select="self::node ()" mode="idl"/></dd>
    </dl>
  </t:template>
  
  <t:template match="dump:attribute" mode="dl">
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <dfn><t:apply-templates select="self::node ()" mode="idl-name"/></dfn>
      <t:call-template name="label-sep"/>
      <t:call-template name="prefix-datatype"/>
      <t:apply-templates select="self::node ()" mode="idl-type"/>
      <t:if test="@dump:isReadOnly">
        <t:call-template name="label-sep"/>
        <t:call-template name="label-read-only"/>
      </t:if>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <!-- exception -->
    </dd>
  </t:template>
  
  <t:template match="dump:method" mode="dl">
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <dfn><t:apply-templates select="self::node ()" mode="idl-name"/></dfn>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <dl class="dump-info dump-info-method">
        <t:choose>
        <t:when test="child::dump:param">
          <dt><t:call-template name="label-parameters"/></dt>
          <dd>
            <dl class="dump-children dump-children-param">
              <t:apply-templates select="child::dump:param" mode="dl"/>
            </dl>
          </dd>
        </t:when>
        <t:otherwise>
          <dt><t:call-template name="label-no-parameter"/></dt>
        </t:otherwise>
        </t:choose>
        <t:choose>
        <t:when test="child::dump:return/@dump:dataType">
          <dt><t:call-template name="label-return-value"/></dt>
          <dd>
            <dl class="dump-children dump-children-return">
              <dt>
                <t:apply-templates select="self::node ()" mode="idl-type"/>
              </dt>
              <dd><t:apply-templates select="child::dump:return"
                  mode="value-description"/></dd>
            </dl>
          </dd>
        </t:when>
        <t:otherwise>
          <dt><t:call-template name="label-no-return-value"/></dt>
        </t:otherwise>
        </t:choose>
        <!-- exceptions -->
      </dl>
    </dd>
  </t:template>
  
  <t:template match="dump:param" mode="dl">
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <dfn><t:apply-templates select="self::node ()" mode="idl-name"/></dfn>
      <t:call-template name="label-sep"/>
      <t:call-template name="prefix-datatype"/>
      <t:apply-templates select="self::node ()" mode="idl-type"/>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
    </dd>
  </t:template>

  <t:template match="ddoc:content">
    <t:param name="rank" select="1"/>
    <t:apply-templates/>
  </t:template>
  
  <t:template match="ddel:IF[@dump:uri]">
    <t:variable name="referent"
        select="$allIDLInterface[child::dump:uri/@dump:uri = current ()/@dump:uri]"/>
    <t:choose>
    <t:when test="$referent">
      <t:apply-templates select="$referent" mode="ref"/>
    </t:when>
    <t:otherwise>
      <t:value-of select="@dump:uri"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:TYPE[@dump:uri]">
    <t:variable name="referent"
        select="$anyIDLType
                [child::dump:uri/@dump:uri = current ()/@dump:uri]"/>
    <t:choose>
    <t:when test="$referent">
      <t:apply-templates select="$referent" mode="ref"/>
    </t:when>
    <t:otherwise>
      <t:value-of select="@dump:uri"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:IF/@dump:uri |
                     ddel:TYPE/@dump:uri"/>
  
  <t:template match="ddel:Class[@dump:uri]">
    <t:variable name="referent"
        select="$rootDocument[child::dump:uri/@dump:uri = current ()/@dump:uri]"/>
    <t:choose>
    <t:when test="$referent">
      <t:apply-templates select="$referent" mode="ref">
        <t:with-param name="as-section" select="false ()"/>
      </t:apply-templates>
    </t:when>
    <t:otherwise>
      <t:value-of select="@dump:uri"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:M[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="def"
        select="$allIDLInterface/child::dump:method
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:choose>
    <t:when test="$def">
      <t:apply-templates select="$def[position () = 1]" mode="ref">
        <t:with-param name="ddoct:basePath">
          <t:choose>
          <t:when test="$ddoct:basePath">
            <t:copy-of select="$ddoct:basePath"/>
          </t:when>
          <t:otherwise>
            <t:apply-templates select="self::node ()" mode="base-path"/>
          </t:otherwise>
          </t:choose>
        </t:with-param>
      </t:apply-templates>
    </t:when>
    <t:otherwise>
      <code lang="en" xml:lang="en"><t:apply-templates/></code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:A[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="def"
        select="$allIDLInterface/child::dump:attribute
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:choose>
    <t:when test="$def">
      <t:apply-templates select="$def[position () = 1]" mode="ref">
        <t:with-param name="ddoct:basePath">
          <t:choose>
          <t:when test="$ddoct:basePath">
            <t:copy-of select="$ddoct:basePath"/>
          </t:when>
          <t:otherwise>
            <t:apply-templates select="self::node ()" mode="base-path"/>
          </t:otherwise>
          </t:choose>
        </t:with-param>
      </t:apply-templates>
    </t:when>
    <t:otherwise>
      <code lang="en" xml:lang="en"><t:apply-templates/></code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:P[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="def"
        select="$allIDLInterface/child::dump:method/child::dump:param
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:choose>
    <t:when test="$def">
      <t:apply-templates select="$def[position () = 1]" mode="ref">
        <t:with-param name="ddoct:basePath">
          <t:choose>
          <t:when test="$ddoct:basePath">
            <t:copy-of select="$ddoct:basePath"/>
          </t:when>
          <t:otherwise>
            <t:apply-templates select="self::node ()" mode="base-path"/>
          </t:otherwise>
          </t:choose>
        </t:with-param>
      </t:apply-templates>
    </t:when>
    <t:otherwise>
      <var lang="en" xml:lang="en"><t:apply-templates/></var>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:DOM[string (self::node ()) = 'null']">
    <code class="DOM" lang="en" xml:lang="en">null</code>
  </t:template>
  
  <t:template match="ddel:DOM[string (self::node ()) = 'true']">
    <code class="DOM" lang="en" xml:lang="en">true</code>
  </t:template>
  
  <t:template match="ddel:DOM[string (self::node ()) = 'false']">
    <code class="DOM" lang="en" xml:lang="en">false</code>
  </t:template>

<!-- Special Contents -->

  <t:template match="dump:document[@dump:ref = '&f;ShortTOC' or
                                   @dump:ref = '&f;LongTOC']">
    <t:param name="rank" select="1"/>
    <ol class="xoxo">
      <t:variable name="p"
          select="$rootDocument[child::ddoc:rel/@dump:uri = '&ddoc;Document']"/>
      <t:apply-templates
          select="$p/child::dump:document
                  [not (child::ddoc:rel/@dump:uri = '&ddoc;abstract') and
                   not (child::ddoc:rel/@dump:uri = '&ddoc;status') and
                   not (child::ddoc:rel/@dump:uri = '&ddoc;shortTOC') and
                   ((child::ddoc:rel/@dump:uri = '&ddoc;section') or
                    (child::ddoc:rel/@dump:uri = '&ddoc;mainSection') or
                    (child::ddoc:rel/@dump:uri = '&ddoc;additionalSection') or
                    (child::ddoc:rel/@dump:uri = '&ddoc;appendix'))] |
                  $p/child::dump:dataType"
          mode="toc-li">
        <t:with-param name="recursive" select="boolean (@dump:ref = '&f;LongTOC')"/>
      </t:apply-templates>
    </ol>
  </t:template>
  
  <t:template match="dump:document | dump:dataType" mode="toc-li"><!-- @dump:ref -->
    <t:param name="recursive" select="false ()"/>
    <t:param name="docType" select="child::ddoc:rel/@dump:uri"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:variable name="this-number">
      <t:apply-templates select="self::node ()" mode="number">
        <t:with-param name="number" select="$number"/>
      </t:apply-templates>
    </t:variable>
    &referent.variable;
    <t:choose>
    <t:when test="$referent/child::idl:sequenceOf"/>
    <t:otherwise>
      <li>
        <t:attribute name="class" xml:space="preserve">
          <t:if test="$docType = '&ddoc;appendix'">appendix</t:if>
          <t:if test="$docType = '&ddoc;additionalSection'">ddspec-add-sect</t:if>
          <t:if test="$docType = '&ddoc;mainSection'">ddspec-main-sect</t:if>
        </t:attribute>
        <t:apply-templates select="$referent" mode="ref">
          <t:with-param name="docType" select="$docType"/>
          <t:with-param name="number" select="$this-number"/>
          <t:with-param name="as-section" select="true ()"/>
        </t:apply-templates>
        <t:if test="$recursive">
          <t:variable name="q">
            <t:apply-templates select="$referent/child::dump:document
                   [(child::ddoc:rel/@dump:uri = '&ddoc;subsection') or
                    (child::ddoc:rel/@dump:uri = '&ddoc;section')] |
                        $referent/child::dump:dataType" mode="toc-li">
              <t:with-param name="recursive" select="true ()"/>
              <t:with-param name="number" select="$this-number"/>
            </t:apply-templates>
          </t:variable>
          <t:if test="string-length ($q)">
            <ol><t:copy-of select="$q"/></ol>
          </t:if>
        </t:if>
      </li>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:document[@dump:ref = '&f;ShortTOC' or
                                   @dump:ref = '&f;LongTOC']" mode="toc-li"/>

<!-- IDL Definition -->

  <t:template match="dump:module" mode="idl">
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="/parent::node ()"/>
    <t:variable name="moduleName">
      <t:apply-templates select="self::node ()" mode="idl-name"/>
    </t:variable>
    <t:variable name="fileDirectory">
      <t:apply-templates select="self::node ()" mode="idl-file-name-dir"/>
    </t:variable>
    <t:variable name="fileName">
      <t:apply-templates select="self::node ()" mode="idl-file-name-name">
        <t:with-param name="moduleName" select="$moduleName"/>
      </t:apply-templates>
    </t:variable>
    
    <div class="section" id="{concat ('idl-', $fileName)}">
      <t:apply-templates select="self::node ()" mode="heading">
        <t:with-param name="number" select="$number"/>
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="value">
          <a href="{$fileDirectory}{$fileName}"><t:copy-of select="$fileName"/></a>
        </t:with-param>
      </t:apply-templates>
    
      <pre class="idl idl-file" lang="en" xml:lang="en">
        <t:apply-templates select="self::node ()" mode="idl-file">
          <t:with-param name="moduleName" select="$moduleName"/>
          <t:with-param name="fileName" select="$fileName"/>
        </t:apply-templates>
      </pre>
    </div>
  </t:template>
  
  <t:template match="dump:interface" mode="idl">
    <pre class="idl idl-interface" lang="en" xml:lang="en">
      <t:apply-templates select="self::node ()" mode="idl-file"/>
    </pre>
  </t:template>
  
  <t:template match="dump:dataType" mode="idl">
    <pre class="idl idl-data-type" lang="en" xml:lang="en">
      <t:apply-templates select="self::node ()" mode="idl-file"/>
    </pre>
  </t:template>
  
  <t:template match="dump:module" mode="idl-file">
    <t:param name="moduleName">
      <t:apply-templates select="self::node ()" mode="idl-name"/>
    </t:param>
    <t:param name="fileName">
      <t:apply-templates select="self::node ()" mode="idl-file-name-name">
        <t:with-param name="moduleName" select="$moduleName"/>
      </t:apply-templates>
    </t:param>
    <t:variable name="const">
      <t:apply-templates select="self::node ()" mode="idl-const-name">
        <t:with-param name="fileName" select="$fileName"/>
      </t:apply-templates>
    </t:variable>
      <t:text>// File: </t:text><t:copy-of select="$fileName"/><t:text>&#xA;</t:text>
      <t:text>&#xA;</t:text>
      <t:text>#ifndef </t:text><t:copy-of select="$const"/><t:text>&#xA;</t:text>
      <t:text>#define </t:text><t:copy-of select="$const"/><t:text>&#xA;</t:text>
      <t:text>&#xA;</t:text>
      <!-- include -->
      <t:text>#pragma prefix "</t:text>
      <t:value-of select="child::idl:prefix"/>
      <t:text>"&#xA;</t:text>
      <t:text>module </t:text><t:copy-of select="$moduleName"/><t:text>&#xA;</t:text>
      <t:text>{&#xA;&#xA;</t:text>
      <t:for-each select="child::dump:dataType[child::idl:sequenceOf]">
        <t:apply-templates select="self::node ()" mode="idl-file">
          <t:with-param name="indent" select="'  '"/>
        </t:apply-templates>
        <t:text>&#xA;</t:text>
      </t:for-each>
      <!-- typedef -->
      <t:for-each select="child::dump:interface[not (@dump:isException)]">
        <t:if test="(preceding-sibling::dump:interface/child::dump:method/
                       child::dump:return/@dump:dataType =
                     current ()/child::dump:uri/@dump:uri) or
                    (preceding-sibling::dump:interface/child::dump:attribute/
                       child::dump:*/@dump:dataType =
                     current ()/child::dump:uri/@dump:uri)">
          <t:text>  interface </t:text>
          <t:apply-templates select="self::node ()" mode="idl-name"/>
          <t:text>;&#xA;</t:text>
        </t:if>
      </t:for-each>
      <t:for-each select="child::dump:interface[@dump:isException]">
        <t:text>&#xA;</t:text>
        <t:apply-templates select="self::node ()" mode="idl-file">
          <t:with-param name="indent" select="'  '"/>
        </t:apply-templates>
      </t:for-each>
      <t:for-each select="child::dump:interface[not (@dump:isException)]">
        <t:text>&#xA;</t:text>
        <t:apply-templates select="self::node ()" mode="idl-file">
          <t:with-param name="indent" select="'  '"/>
        </t:apply-templates>
      </t:for-each>
      <t:text>};&#xA;</t:text>
      <t:text>&#xA;</t:text>
      <t:text>#endif // </t:text><t:copy-of select="$const"/><t:text>&#xA;</t:text>
  </t:template>
  
  <t:template match="dump:interface" mode="idl-file">
    <t:param name="indent" select="''"/>
    
    <t:copy-of select="$indent"/>
    <t:text>interface </t:text>
    <t:apply-templates select="self::node ()" mode="ref"/>
    <t:apply-templates select="child::dump:extends" mode="idl-file"/>
    <t:text> {&#xA;</t:text>
    
    <t:apply-templates select="child::dump:method[not (@dump:ref)] |
                               child::dump:attribute[not (@dump:ref)] |
                               child::dump:constGroup[not (@dump:ref)]"
        mode="idl-file">
      <t:with-param name="indent" select="concat ($indent, '  ')"/>
    </t:apply-templates>
    
    <t:copy-of select="$indent"/>
    <t:text>}&#xA;</t:text>
  </t:template>
  
  <t:template match="dump:dataType[child::idl:sequenceOf]" mode="idl-file">
    <t:param name="indent" select="''"/>
    
    <t:copy-of select="$indent"/>
    <t:text>valuetype </t:text>
    <t:apply-templates select="self::node ()" mode="ref"/>
    <t:text> sequence&lt;</t:text>
    <t:apply-templates select="child::idl:sequenceOf" mode="idl-file"/>
    <t:text>>;&#xA;</t:text>
  </t:template>
  
  <t:template match="dump:method" mode="idl-file">
    <t:param name="indent" select="''"/>
    <t:variable name="method-name">
      <t:apply-templates select="self::node ()" mode="ref">
        <t:with-param name="short" select="true ()"/>
      </t:apply-templates>
    </t:variable>
    <t:variable name="type">
      <t:apply-templates select="self::node ()" mode="idl-type"/>
    </t:variable>
    
    <t:copy-of select="$indent"/>
    <t:copy-of select="$type"/>
    <t:call-template name="space">
      <t:with-param name="length" select="18 - string-length ($type)"/>
    </t:call-template>
    <t:text> </t:text>
    <t:copy-of select="$method-name"/>
    <t:text>(</t:text>
    <t:apply-templates select="child::dump:param" mode="idl-file">
      <t:with-param name="method-name" select="$method-name"/>
      <t:with-param name="indent" select="$indent"/>
    </t:apply-templates>
    <t:text>);&#xA;</t:text>
  </t:template>
  
  <t:template match="dump:param[position () = 1]" mode="idl-file">
    <t:param name="method-name"/>
    <t:text>in </t:text>
    <t:apply-templates select="self::node ()" mode="idl-type"/>
    <t:text> </t:text>
    <t:apply-templates select="self::node ()" mode="ref">
      <t:with-param name="short" select="true ()"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="dump:param[position () != 1]" mode="idl-file">
    <t:param name="method-name"/>
    <t:param name="indent" select="''"/>
    
    <t:text>,&#xA;</t:text>
    
    <t:copy-of select="$indent"/>
    <t:text>                    </t:text>
    <t:call-template name="space">
      <t:with-param name="length" select="string-length ($method-name)"/>
    </t:call-template>
    <t:text>in </t:text>
    <t:apply-templates select="self::node ()" mode="idl-type"/>
    <t:text> </t:text>
    <t:apply-templates select="self::node ()" mode="ref">
      <t:with-param name="short" select="true ()"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="dump:attribute" mode="idl-file">
    <t:param name="indent" select="''"/>
    <t:variable name="type">
      <t:apply-templates select="self::node ()" mode="idl-type"/>
    </t:variable>
    
    <t:copy-of select="$indent"/>
    <t:choose>
    <t:when test="@dump:isReadOnly">readonly attribute </t:when>
    <t:otherwise>         attribute </t:otherwise>
    </t:choose>
    <t:copy-of select="$type"/>
    <t:call-template name="space">
      <t:with-param name="length" select="15 - string-length ($type)"/>
    </t:call-template>
    <t:text> </t:text>
    <t:apply-templates select="self::node ()" mode="ref">
      <t:with-param name="short" select="true ()"/>
    </t:apply-templates>
    <t:text>;&#xA;</t:text>
  </t:template>
  
  <t:template match="dump:module" mode="idl-file-name-name">
    <t:param name="moduleName">
      <t:apply-templates select="self::node ()" mode="idl-name"/>
    </t:param>
    <code class="file" lang="en" xml:lang="en">
      <t:value-of select="$moduleName"/>
      <t:text>.idl</t:text>
    </code>
  </t:template>
  <t:template match="dump:module" mode="idl-file-name-dir">
    <code class="file" lang="en" xml:lang="en">
      <t:text>idl/</t:text>
    </code>
  </t:template>
  
  <t:template match="dump:module" mode="idl-name">
    <code class="idl" lang="en" xml:lang="en">
      <t:choose>
      <t:when test="child::idl:moduleName">
        <t:value-of select="child::idl:moduleName"/>
      </t:when>
      <t:otherwise>
        <t:value-of select="@dump:localName"/>
      </t:otherwise>
      </t:choose>
    </code>
  </t:template>
  
  <t:template match="dump:module" mode="idl-const-name">
    <t:param name="fileName">
      <t:apply-templates select="self::node ()" mode="idl-file-name-name"/>
    </t:param>
    <t:text>_</t:text>
    <t:value-of select="translate ($fileName,
                                   'abcdefghijklmnopqrstuvwxyz-.',
                                   'ABCDEFGHIJKLMNOPQRSTUVWXYZ__')"/>
    <t:text>_</t:text>
  </t:template>
  
  <t:template match="dump:interface" mode="idl-name">
    <code class="idl DOMi" lang="en" xml:lang="en">
      <t:value-of select="@dump:localName"/>
    </code>
  </t:template>
  
  <t:template match="dump:interface/dump:extends" mode="idl-file">
    <t:text> extends </t:text>
    <t:variable name="type"
        select="$allIDLInterface
                [child::dump:uri/@dump:uri = current ()/@dump:uri]"/>
    <t:apply-templates select="$type" mode="ref"/>
    <t:if test="not ($type)">
      <t:value-of select="@dump:uri"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:method" mode="idl-name">
    <code class="idl DOMm" lang="en" xml:lang="en">
      <t:value-of select="@dump:localName"/>
    </code>
  </t:template>
  
  <t:template match="dump:attribute" mode="idl-name">
    <code class="idl DOMa" lang="en" xml:lang="en">
      <t:value-of select="@dump:localName"/>
    </code>
  </t:template>
  
  <t:template match="dump:param" mode="idl-name">
    <code class="idl DOMp" lang="en" xml:lang="en">
      <t:value-of select="@dump:localName"/>
    </code>
  </t:template>
  
  <t:template match="dump:method" mode="idl-type">
    <t:variable name="uri">
      <t:choose>
      <t:when test="child::dump:return/@dump:dataType">
        <t:value-of select="child::dump:return/@dump:dataType"/>
      </t:when>
      <t:otherwise
      >http://suika.fam.cx/~wakaba/archive/2004/dis/IDL#void</t:otherwise>
      </t:choose>
    </t:variable>
    <t:variable name="type"
        select="$anyIDLType[child::dump:uri/@dump:uri = $uri]"/>
    <t:choose>
    <t:when test="$type">
      <t:apply-templates select="$type" mode="ref"/>
    </t:when>
    <t:otherwise>
      <t:value-of select="child::dump:return/@dump:dataType"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:attribute" mode="idl-type">
    <t:variable name="type"
        select="$anyIDLType
                [child::dump:uri/@dump:uri =
                 current ()/child::dump:get/@dump:dataType]"/>
    <t:apply-templates select="$type" mode="ref"/>
    <t:if test="not ($type)">
      <t:value-of select="child::dump:get/@dump:dataType"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:param" mode="idl-type">
    <t:variable name="type"
        select="$anyIDLType
                [child::dump:uri/@dump:uri = current ()/@dump:dataType]"/>
    <t:apply-templates select="$type" mode="ref"/>
    <t:if test="not ($type)">
      <t:value-of select="@dump:dataType"/>
    </t:if>
  </t:template>
  
  <t:template match="idl:sequenceOf" mode="idl-file">
    <t:variable name="type"
        select="$anyIDLType
                [child::dump:uri/@dump:uri = string (current ())]"/>
    <t:apply-templates select="$type" mode="ref"/>
    <t:if test="not ($type)">
      <t:value-of select="self::node ()"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:dataType | dump:document" mode="idl-name">
    <code class="idl" lang="en" xml:lang="en">
      <t:choose>
      <t:when test="child::idl:typeName">
        <t:value-of select="child::idl:typeName"/>
      </t:when>
      <t:otherwise>
        <t:value-of select="@dump:localName"/>
      </t:otherwise>
      </t:choose>
    </code>
  </t:template>

<!-- Java Binding -->

  <t:template match="dump:module" mode="java">
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="/parent::node ()"/>
    <t:variable name="packageName">
      <t:apply-templates select="self::node ()" mode="java-name"/>
    </t:variable>
    <t:variable name="fileDirectory">
      <t:apply-templates select="self::node ()" mode="java-file-name-dir"/>
    </t:variable>
    
    <div class="section" id="{$packageName}">
      <t:apply-templates select="self::node ()" mode="heading">
        <t:with-param name="number" select="$number"/>
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="value">
          <t:call-template name="prefix-package"/>
          <t:copy-of select="$packageName"/>
        </t:with-param>
      </t:apply-templates>
      
      <t:apply-templates select="child::dump:interface" mode="java">
        <t:with-param name="number" select="$number"/>
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="packageName" select="$packageName"/>
        <t:with-param name="fileDirectory" select="$fileDirectory"/>
      </t:apply-templates>
    </div>
  </t:template>
  
  <t:template match="dump:interface" mode="java">
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="/parent::node ()"/>
    <t:param name="packageName">
      <t:apply-templates select="parent::node ()" mode="java-name"/>
    </t:param>
    <t:param name="interfaceName">
      <t:apply-templates select="self::node ()" mode="java-name"/>
    </t:param>
    <t:param name="fileDirectory">
      <t:apply-templates select="parent::node ()" mode="java-file-name-dir"/>
    </t:param>
    <t:variable name="fileName">
      <t:apply-templates select="self::node ()" mode="java-file-name-name">
        <t:with-param name="interfaceName" select="$interfaceName"/>
      </t:apply-templates>
    </t:variable>
    
    <div class="section" id="{$packageName}.{$interfaceName}">
      <t:apply-templates select="self::node ()" mode="heading">
        <t:with-param name="number">
          <t:apply-templates select="self::node ()" mode="number">
            <t:with-param name="number" select="$number"/>
          </t:apply-templates>
        </t:with-param>
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="value">
          <a href="{$fileDirectory}{$fileName}"><t:copy-of select="$fileName"/></a>
        </t:with-param>
      </t:apply-templates>
    
      <t:apply-templates select="self::node ()" mode="java-file">
        <t:with-param name="packageName" select="$packageName"/>
        <t:with-param name="interfaceName" select="$interfaceName"/>
      </t:apply-templates>
    </div>
  </t:template>
  
  <t:template match="dump:interface" mode="id-java">
    <t:variable name="v">
      <t:apply-templates select="parent::node ()" mode="java-name"/>
      <t:text>.</t:text>
      <t:apply-templates select="self::node ()" mode="java-name"/>
    </t:variable>
    <t:value-of select="$v"/>
  </t:template>
  
  <t:template match="dump:interface" mode="java-file">
    <t:param name="packageName">
      <t:apply-templates select="parent::node ()" mode="java-name"/>
    </t:param>
    <t:param name="interfaceName">
      <t:apply-templates select="self::node ()" mode="java-name"/>
    </t:param>
    
      <pre class="Java Java-file" lang="en" xml:lang="en">
        <t:text>package </t:text>
        <t:copy-of select="$packageName"/>
        <t:text>;&#xA;&#xA;</t:text>
        
        <t:text>public interface </t:text>
        <t:copy-of select="$interfaceName"/>
        <t:if test="child::dump:extends">
          <t:text> extends </t:text>
          <t:apply-templates select="child::dump:extends[position () = 1]"
              mode="java-name"/>
          <t:if test="child::dump:extends[position () = 2]">
            <t:for-each select="child::dump:extends[position () != 1]">
              <t:text>, </t:text>
              <t:apply-templates select="self::node ()" mode="java-name"/>
            </t:for-each>
          </t:if>
        </t:if>
        <t:text> {&#xA;</t:text>
        
        <t:apply-templates select="child::dump:method[not (@dump:ref)] |
                                   child::dump:attribute[not (@dump:ref)] |
                                   child::dump:constGroup[not (@dump:ref)]"
            mode="java-file">
          <t:with-param name="indent" select="'    '"/>
        </t:apply-templates>
        <t:text>}&#xA;</t:text>
      </pre>
  </t:template>
  
  <t:template match="dump:method" mode="java-file">
    <t:param name="indent" select="''"/>
    
    <t:variable name="v">
      <t:copy-of select="$indent"/>
      <t:text>public </t:text>
      <t:apply-templates select="self::node ()" mode="java-type"/>
      <t:text> </t:text>
      <t:apply-templates select="self::node ()" mode="java-name"/>
      <t:text>(</t:text>
    </t:variable>
    <t:copy-of select="$v"/>
    <t:if test="child::dump:param">
      <t:variable name="s">
        <t:call-template name="space">
          <t:with-param name="length" select="string-length ($v)"/>
        </t:call-template>
      </t:variable>
      <t:apply-templates select="child::dump:param" mode="java-file">
        <t:with-param name="indent" select="$s"/>
      </t:apply-templates>
    </t:if>
    <t:text>);&#xA;&#xA;</t:text>
  </t:template>
  
  <t:template match="dump:attribute" mode="java-file">
    <t:param name="indent" select="''"/>
    
    <t:copy-of select="$indent"/>
    <t:text>public </t:text>
    <t:apply-templates select="self::node ()" mode="java-type">
      <t:with-param name="set" select="false ()"/>
    </t:apply-templates>
    <t:text> </t:text>
    <t:apply-templates select="self::node ()" mode="java-name">
      <t:with-param name="set" select="false ()"/>
    </t:apply-templates>
    <t:text>();&#xA;</t:text>
    
    <t:if test="not (@dump:isReadOnly)">
      <t:copy-of select="$indent"/>
      <t:text>public </t:text>
      <t:apply-templates select="self::node ()" mode="java-type">
        <t:with-param name="set" select="true ()"/>
      </t:apply-templates>
      <t:text> </t:text>
      <t:apply-templates select="self::node ()" mode="java-name">
        <t:with-param name="set" select="true ()"/>
      </t:apply-templates>
      <t:text>(</t:text>
      <t:apply-templates select="self::node ()" mode="java-type">
        <t:with-param name="set" select="'param'"/>
      </t:apply-templates>
      <t:text> </t:text>
      <t:apply-templates select="self::node ()" mode="java-name">
        <t:with-param name="set" select="'param'"/>
      </t:apply-templates>
      <t:text>);&#xA;</t:text>
    </t:if>
    <t:text>&#xA;</t:text>
  </t:template>
  
  <t:template match="dump:param[position () = 1]" mode="java-file">
    <t:param name="indent" select="''"/>
    <t:apply-templates select="self::node ()" mode="java-type"/>
    <t:text> </t:text>
    <t:apply-templates select="self::node ()" mode="java-name"/>
  </t:template>
  
  <t:template match="dump:param[position () != 1]" mode="java-file">
    <t:param name="indent" select="''"/>
    <t:text>,&#xA;</t:text>
    <t:copy-of select="$indent"/>
    <t:apply-templates select="self::node ()" mode="java-type"/>
    <t:text> </t:text>
    <t:apply-templates select="self::node ()" mode="java-name"/>
  </t:template>
  
  <t:template match="dump:module" mode="java-name">
    <t:choose>
    <t:when test="child::j:packageQualifiedName">
      <code class="Java" lang="en" xml:lang="en">
        <t:value-of select="child::j:packageQualifiedName"/>
      </code>
    </t:when>
    <t:otherwise>
      <code class="Java" lang="en" xml:lang="en">
        <t:value-of select="@dump:localName"/>
      </code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:module" mode="java-file-name-dir">
    <t:variable name="name">
      <t:choose>
      <t:when test="child::j:packageQualifiedName">
        <t:value-of select="child::j:packageQualifiedName"/>
      </t:when>
      <t:otherwise>
        <t:value-of select="@dump:localName"/>
      </t:otherwise>
      </t:choose>
    </t:variable>
    <code class="file" lang="en" xml:lang="en">
      <t:value-of select="translate ($name, '.', '/')"/>
      <t:text>/</t:text>
    </code>
  </t:template>
  
  <t:template match="dump:interface" mode="java-file-name-dir">
    <t:apply-templates select="parent::node ()" mode="java-file-name-dir"/>
  </t:template>
  
  <t:template match="dump:interface | dump:dataType" mode="java-name">
    <t:choose>
    <t:when test="child::j:interfaceName">
      <code class="Java" lang="en" xml:lang="en">
        <t:value-of select="child::j:interfaceName"/>
      </code>
    </t:when>
    <t:when test="child::j:className">
      <code class="Java" lang="en" xml:lang="en">
        <t:value-of select="child::j:interfaceName"/>
      </code>
    </t:when>
    <t:otherwise>
      <code class="Java" lang="en" xml:lang="en">
        <t:value-of select="@dump:localName"/>
      </code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:class" mode="java-name">
    <t:choose>
    <t:when test="child::j:className">
      <code class="Java" lang="en" xml:lang="en">
        <t:value-of select="child::j:interfaceName"/>
      </code>
    </t:when>
    <t:otherwise>
      <code class="Java" lang="en" xml:lang="en">
        <t:value-of select="@dump:localName"/>
      </code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:dataType[child::idl:java]" mode="java-name">
    <t:variable name="v" select="string (child::idl:java/@dump:ref)"/>
    <t:variable name="type" select="($anyIDLType | $allClass)[not (child::idl:java)]
                                               [child::dump:uri/@dump:uri = $v]"/>
    <t:apply-templates select="$type" mode="java-name"/>
    <t:if test="not ($type)">
      <t:value-of select="$v"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:interface" mode="java-file-name-name">
    <t:variable name="a">
      <t:apply-templates select="self::node ()" mode="java-name"/>
    </t:variable>
    <code class="file" lang="en" xml:lang="en">
      <t:value-of select="$a"/>
      <t:text>.java</t:text>
    </code>
  </t:template>
  
  <t:template match="dump:method" mode="java-name">
    <code class="Java" lang="en" xml:lang="en">
      <t:value-of select="@dump:localName"/>
    </code>
  </t:template>
  
  <t:template match="dump:param" mode="java-name">
    <code class="Java" lang="en" xml:lang="en">
      <t:value-of select="@dump:localName"/>
    </code>
  </t:template>
  
  <t:template match="dump:attribute" mode="java-name">
    <t:param name="set" select="false ()"/>
    <code class="Java" lang="en" xml:lang="en">
      <t:variable name="name" select="string (@dump:localName)"/>
      <t:choose>
      <t:when test="$set = 'param' or
                    (substring ($name, 0, 2) = 'is' and $name != 'isMap')">
        <t:value-of select="@dump:localName"/>
      </t:when>
      <t:otherwise>
        <t:choose>
        <t:when test="$set">set</t:when>
        <t:otherwise>get</t:otherwise>
        </t:choose>
        <t:value-of select="translate (substring ($name, 1, 1),
                                       'abcdefghijklmnopqrstuvwxyz',
                                       'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
        <t:value-of select="substring ($name, 2)"/>
      </t:otherwise>
      </t:choose>
    </code>
  </t:template>
  
  <t:template match="dump:method" mode="java-type">
    <t:variable name="typeName">
      <t:choose>
      <t:when test="child::dump:return/@dump:dataType">
        <t:value-of select="child::dump:return/@dump:dataType"/>
      </t:when>
      <t:otherwise
      >http://suika.fam.cx/~wakaba/archive/2004/dis/IDL#void</t:otherwise>
      </t:choose>
    </t:variable>
    <t:apply-templates select="$anyIDLType[child::dump:uri/@dump:uri = $typeName]"
        mode="java-name"/>
  </t:template>
  
  <t:template match="dump:attribute" mode="java-type">
    <t:param name="set" select="false ()"/>
    <t:variable name="typeName">
      <t:choose>
      <t:when
          test="$set">http://suika.fam.cx/~wakaba/archive/2004/dis/IDL#void</t:when>
      <t:otherwise>
        <t:value-of select="child::dump:get/@dump:dataType"/>
      </t:otherwise>
      </t:choose>
    </t:variable>
    <t:apply-templates select="$anyIDLType[child::dump:uri/@dump:uri = $typeName]"
        mode="java-name"/>
  </t:template>
  
  <t:template match="dump:param" mode="java-type">
    <t:variable name="typeName">
      <t:value-of select="@dump:dataType"/>
    </t:variable>
    <t:apply-templates select="$anyIDLType[child::dump:uri/@dump:uri = $typeName]"
        mode="java-name"/>
  </t:template>
  
  <t:template match="dump:extends" mode="java-name">
    <t:variable name="u" select="string (@dump:uri)"/>
    <t:variable name="v"
        select="($allIDLInterface | $allClass)[child::dump:uri/@dump:uri = $u]"/>
    <t:apply-templates select="$v" mode="java-name"/>
    <t:if test="not ($v)">
      <t:value-of select="$u"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:module" mode="uri-java">
    <t:apply-templates
        select="$rootDocument/child::dump:document
          [@dump:ref = current ()/child::dump:uri/@dump:uri]
          [child::ddoc:as/@dump:uri =
              'http://suika.fam.cx/~wakaba/archive/2004/dis/Java#Package']/
          parent::node ()"
        mode="doc-uri"/>
  </t:template>
  
  <t:template match="dump:interface" mode="uri-java">
    <t:apply-templates select="parent::node ()" mode="uri-java"/>
    <t:text>#</t:text>
    <t:apply-templates select="self::node ()" mode="id-java"/>
  </t:template>

<!-- ECMAScript Binding -->

  <t:template match="dump:module" mode="es">
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="/parent::node ()"/>
    
    <div class="section" id="interfaces">
      <t:apply-templates select="self::node ()" mode="heading">
        <t:with-param name="number" select="$number"/>
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="value">
          <t:call-template name="label-interfaces"/>
        </t:with-param>
      </t:apply-templates>
      
      <dl class="ecmascript-binding">
        <t:apply-templates select="child::dump:interface" mode="es"/>
      </dl>
    </div>
  </t:template>
  
  <t:template match="dump:interface" mode="es">
    <t:variable name="name">
      <t:apply-templates select="self::node ()" mode="es-name"/>
    </t:variable>
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr-es"/>
      <t:call-template name="label-objects-of-interface">
        <t:with-param name="interface" select="$name"/>
      </t:call-template>
    </dt>
    <dd>
      <dl>
        <t:apply-templates select="child::dump:extends" mode="es">
          <t:with-param name="interface" select="$name"/>
        </t:apply-templates>
        <t:if test="child::dump:attribute[not (@dump:ref)]">
          <dt>
            <t:call-template name="label-properties-of-objects-of-interface">
              <t:with-param name="interface" select="$name"/>
            </t:call-template>
          </dt>
          <t:apply-templates select="child::dump:attribute[not (@dump:ref)]"
              mode="es"/>
        </t:if>
        <t:if test="child::dump:method[not (@dump:ref)]">
          <dt>
            <t:call-template name="label-functions-of-objects-of-interface">
              <t:with-param name="interface" select="$name"/>
            </t:call-template>
          </dt>
          <t:apply-templates select="child::dump:method[not (@dump:ref)]" mode="es"/>
        </t:if>
      </dl>
    </dd>
  </t:template>
  
  <t:template match="child::dump:extends" mode="es">
    <t:param name="interface">
      <t:apply-templates select="parent::node ()" mode="es-name"/>
    </t:param>
    <dd>
      <t:call-template name="desc-properties-functions-of-super-interface">
        <t:with-param name="interface" select="$interface"/>
        <t:with-param name="superInterface">
          <t:variable name="siURI" select="string (@dump:uri)"/>
          <t:variable name="siNode"
              select="$allIDLInterface[child::dump:uri/@dump:uri = $siURI]"/>
          <t:apply-templates select="$siNode" mode="es-name"/>
          <t:if test="not ($siNode)">
            <t:value-of select="$siURI"/>
          </t:if>
        </t:with-param>
        <t:with-param name="hasOtherMember"
            select="boolean (parent::node ()/
                               child::dump:attribute[not (@dump:ref)] or
                             parent::node ()/child::dump:method[not (@dump:ref)])"/>
      </t:call-template>
    </dd>
  </t:template>
  
  <t:template match="dump:attribute" mode="es">
    <dd>
      <dl class="ecmascript-binding-attribute">
        <dt>
          <dfn>
            <t:apply-templates select="self::node ()" mode="es-name"/>
          </dfn>
        </dt>
        <dd>
          <t:call-template name="desc-property-value-type-is">
            <t:with-param name="isReadOnly" select="boolean (@dump:isReadOnly)"/>
            <t:with-param name="valueDesc">
              <t:apply-templates select="self::node ()" mode="es-type"/>
            </t:with-param>
          </t:call-template>
        </dd>
      </dl>
    </dd>
  </t:template>
  
  <t:template match="dump:method" mode="es">
    <t:variable name="methodName">
      <t:apply-templates select="self::node ()" mode="es-name"/>
    </t:variable>
    <dd>
      <dl class="ecmaescript-binding-method">
        <dt>
          <dfn>
            <code class="JS">
              <t:copy-of select="$methodName"/>
              <t:text>(</t:text>
              <t:apply-templates select="child::dump:param[position () = 1]"
                  mode="es-name"/>
              <t:for-each select="child::dump:param[position () != 1]">
                <t:text>, </t:text>
                <t:apply-templates select="self::node ()" mode="es-name"/>
              </t:for-each>
              <t:text>)</t:text>
            </code>
          </dfn>
        </dt>
        <dd>
          <t:call-template name="desc-function-return-type-is">
            <t:with-param name="valueDesc">
              <t:apply-templates select="self::node ()" mode="es-type"/>
            </t:with-param>
          </t:call-template>
        </dd>
        <t:apply-templates select="child::dump:param" mode="es"/>
        <t:if test="child::dis:Operator/@dump:ref =
                    'http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#ArrayGet'">
          <dd>
            <div class="note memo">
              <t:call-template name="desc-array-dereference-method">
                <t:with-param name="methodName">
                  <t:copy-of select="$methodName"/>
                </t:with-param>
                <t:with-param name="paramName">
                  <t:apply-templates select="child::dump:param[position () = 1]"
                      mode="es-name"/>
                </t:with-param>
              </t:call-template>
            </div>
          </dd>
        </t:if>
      </dl>
    </dd>
  </t:template>
  
  <t:template match="dump:param" mode="es">
    <dd>
      <t:call-template name="desc-param-type-is">
        <t:with-param name="name">
          <t:apply-templates select="self::node ()" mode="es-name"/>
        </t:with-param>
        <t:with-param name="valueDesc">
          <t:apply-templates select="self::node ()" mode="es-type"/>
        </t:with-param>
      </t:call-template>
    </dd>
  </t:template>
  
  <t:template match="dump:interface | dump:dataType" mode="es-name">
    <t:choose>
    <t:when test="child::js:typeName">
      <code class="JS" lang="en" xml:lang="en">
        <t:value-of select="child::js:typeName"/>
      </code>
    </t:when>
    <t:otherwise>
      <code class="JS" lang="en" xml:lang="en">
        <t:value-of select="@dump:localName"/>
      </code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:dataType[child::idl:ecmascript]" mode="es-name">
    <t:variable name="v" select="string (child::idl:ecmascript/@dump:ref)"/>
    <t:variable name="type" select="$anyIDLType[not (child::idl:ecmascript)]
                                               [child::dump:uri/@dump:uri = $v]"/>
    <t:apply-templates select="$type" mode="es-name"/>
    <t:if test="not ($type)">
      <t:value-of select="$v"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:method | dump:attribute | dump:param" mode="es-name">
    <code class="JS" lang="en" xml:lang="en">
      <t:value-of select="@dump:localName"/>
    </code>
  </t:template>
  
  <t:template match="dump:method | dump:attribute | dump:param" mode="es-type">
    <t:variable name="typeName">
      <t:value-of select="@dump:dataType |
                          child::dump:return/@dump:dataType |
                          child::dump:get/@dump:dataType"/>
    </t:variable>
    <t:variable name="type"
        select="$anyIDLType[child::dump:uri/@dump:uri = $typeName]"/>
    <t:choose>
    <t:when test="$type/self::dump:interface">
      <t:call-template name="label-object-of-interface">
        <t:with-param name="interface">
          <t:apply-templates select="$type" mode="es-name"/>
        </t:with-param>
      </t:call-template>
    </t:when>
    <t:when test="$type/self::dump:dataType">
      <t:call-template name="label-type-is">
        <t:with-param name="type">
          <t:apply-templates select="$type" mode="es-name"/>
        </t:with-param>
      </t:call-template>
    </t:when>
    <t:when test="$type">
      <t:value-of select="$type"/>
    </t:when>
    <t:otherwise/>
    </t:choose>
  </t:template>
  
  <t:template match="dump:module" mode="uri-es">
    <t:apply-templates
        select="$rootDocument/child::dump:document
          [@dump:ref = current ()/child::dump:uri/@dump:uri]
          [child::ddoc:as/@dump:uri = '&f;ECMAScriptBindingDefinition']/
          parent::node ()"
        mode="doc-uri"/>
  </t:template>
  
  <t:template match="dump:interface" mode="uri-es">
    <t:apply-templates select="parent::node ()" mode="uri-es"/>
    <t:text>#</t:text>
    <t:apply-templates select="self::node ()" mode="id-es"/>
  </t:template>
  
  <t:template match="dump:*" mode="id-attr-es">
    <t:attribute name="id">
      <t:apply-templates select="self::node ()" mode="id-es"/>
    </t:attribute>
  </t:template>
  
  <t:template match="dump:interface" mode="id-es">
    <t:text>ecmascript-binding-</t:text>
    <t:variable name="v">
      <t:apply-templates select="self::node ()" mode="es-name"/>
    </t:variable>
    <t:value-of select="$v"/>
  </t:template>
  
<!-- Perl Binding -->

  <t:template match="dump:module" mode="pl">
    <t:param name="number" select="/parent::node ()"/>
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="/parent::node ()"/>
    
    <div class="section" id="interfaces">
      <t:apply-templates select="self::node ()" mode="heading">
        <t:with-param name="number" select="$number"/>
        <t:with-param name="rank" select="$rank"/>
        <t:with-param name="docType" select="$docType"/>
        <t:with-param name="value">
          <t:call-template name="label-interfaces"/>
        </t:with-param>
      </t:apply-templates>

      <dl class="perl-binding">
        <t:apply-templates select="child::dump:interface" mode="pl"/>
      </dl>
    </div>
  </t:template>
  
  <t:template match="dump:interface" mode="pl">
    <t:variable name="name">
      <t:apply-templates select="self::node ()" mode="pl-name"/>
    </t:variable>
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr-pl"/>
      <t:call-template name="prefix-interface"/>
      <dfn>
        <t:copy-of select="$name"/>
      </dfn>
    </dt>
    <t:apply-templates select="child::dump:extends" mode="pl">
      <t:with-param name="interface" select="$name"/>
    </t:apply-templates>
    <dd>
      <t:if test="child::dump:method[not (@dump:ref)] or
                  child::dump:attribute[not (@dump:ref)]">
        <dl class="perl-binding-methods">
          <t:apply-templates
              select="child::dump:method[not (@dump:ref)] |
                      child::dump:attribute[not (@dump:ref)]" mode="pl"/>
        </dl>
      </t:if>
    </dd>
  </t:template>
  
  <t:template match="dump:method" mode="pl">
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr-pl"/>
      <t:call-template name="prefix-method"/>
      <dfn>
        <code class="perl">
          <t:apply-templates select="self::node ()" mode="pl-name"/>
          <t:text> (</t:text>
          <t:apply-templates select="child::dump:param[position () = 1]"
              mode="pl-name"/>
          <t:for-each select="child::dump:param[position () != 1]">
            <t:text>, </t:text>
            <t:apply-templates select="self::node ()" mode="pl-name"/>
          </t:for-each>
          <t:text>)</t:text>
        </code>
      </dfn>
    </dt>
    <dd>
      <t:call-template name="desc-method-return-type-is">
        <t:with-param name="valueDesc">
          <t:apply-templates select="self::node ()" mode="pl-type"/>
        </t:with-param>
      </t:call-template>
    </dd>
    <t:apply-templates select="child::dump:param" mode="pl"/>
  </t:template>
  
  <t:template match="dump:param" mode="pl">
    <dd>
      <t:apply-templates select="self::node ()" mode="id-attr-pl"/>
      <t:call-template name="desc-param-type-is">
        <t:with-param name="name">
          <t:apply-templates select="self::node ()" mode="pl-name"/>
        </t:with-param>
        <t:with-param name="valueDesc">
          <t:apply-templates select="self::node ()" mode="pl-type"/>
        </t:with-param>
      </t:call-template>
      <t:if test="@dump:isNullable and
                  not (following-sibling::dump:param[not (@dump:isNullable)])">
        <t:call-template name="desc-param-is-optional"/>
      </t:if>
    </dd>
  </t:template>
  
  <t:template match="dump:attribute" mode="pl">
    <t:variable name="name">
      <t:apply-templates select="self::node ()" mode="pl-name"/>
    </t:variable>
    <t:variable name="valueDesc">
      <t:apply-templates select="self::node ()" mode="pl-type"/>
    </t:variable>
    <t:variable name="newValueParam">
    <t:if test="not (@dump:isReadOnly)">
      <var lang="en" xml:lang="en">
        <t:text>$</t:text>
        <t:value-of select="$name"/>
      </var>
    </t:if>
    </t:variable>
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr-pl"/>
      <t:call-template name="prefix-method"/>
      <dfn>
        <code class="perl">
          <t:copy-of select="$name"/>
          <t:text> (</t:text>
          <t:copy-of select="$newValueParam"/>
          <t:text>)</t:text>
        </code>
      </dfn>
    </dt>
    <dd>
      <t:call-template name="desc-attribute-return-type-is">
        <t:with-param name="valueDesc" select="$valueDesc"/>
        <t:with-param name="newValueParam" select="$newValueParam"/>
      </t:call-template>
    </dd>
    <t:if test="not (@dump:isReadOnly)">
      <dd>
        <t:attribute name="id">
          <t:apply-templates select="self::node ()" mode="id-pl"/>
          <t:text>-param-</t:text>
          <t:value-of select="translate ($newValueParam, '$', '_')"/>
        </t:attribute>
        <t:call-template name="desc-param-type-is">
          <t:with-param name="name" select="$newValueParam"/>
          <t:with-param name="valueDesc" select="$valueDesc"/>
        </t:call-template>
        <t:call-template name="desc-param-is-optional"/>
      </dd>
    </t:if>
  </t:template>
  
  <t:template match="dump:interface | dump:method |
                     dump:attribute | dump:constGroup |
                     dump:const | dump:dataType" mode="pl-name">
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <code class="perl" lang="en" xml:lang="en">
        <t:value-of select="child::dump:perlPackageName"/>
      </code>
    </t:when>
    <t:when test="child::dump:perlName">
      <code class="perl" lang="en" xml:lang="en">
        <t:value-of select="child::dump:perlName"/>
      </code>
    </t:when>
    <t:otherwise>
      <code class="perl" lang="en" xml:lang="en">
        <t:value-of select="@dump:localName"/>
      </code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:interface | dump:dataType" mode="id-pl">
    <t:text>perl-binding-</t:text>
    <t:variable name="v">
      <t:apply-templates select="self::node ()" mode="pl-name"/>
    </t:variable>
    <t:value-of select="translate ($v, ':', '_')"/>
  </t:template>
  
  <t:template match="dump:method | dump:attribute | dump:constGroup |
                     dump:const" mode="id-pl">
    <t:apply-templates select="parent::node ()" mode="id-pl"/>
    <t:text>-</t:text>
    <t:variable name="v">
      <t:apply-templates select="self::node ()" mode="pl-name"/>
    </t:variable>
    <t:value-of select="$v"/>
  </t:template>
  
  <t:template match="dump:param" mode="id-pl">
    <t:apply-templates select="parent::node ()" mode="id-pl"/>
    <t:text>-</t:text>
    <t:variable name="v">
      <t:apply-templates select="self::node ()" mode="pl-name"/>
    </t:variable>
    <t:value-of select="translate ($v, '$@%:', '____')"/>
  </t:template>
  
  <t:template match="dump:*" mode="id-attr-pl">
    <t:attribute name="id">
      <t:apply-templates select="self::node ()" mode="id-pl"/>
    </t:attribute>
  </t:template>
  
  <t:template match="dump:dataType[child::idl:perl]" mode="pl-name">
    <t:variable name="v" select="string (child::idl:perl/@dump:ref)"/>
    <t:variable name="type" select="$anyIDLType[not (child::idl:perl)]
                                               [child::dump:uri/@dump:uri = $v]"/>
    <t:apply-templates select="$type" mode="pl-name"/>
    <t:if test="not ($type)">
      <t:value-of select="$v"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:dataType
                     [child::dump:uri/@dump:uri =
                     'http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#Number']"
      mode="pl-name">
    <t:call-template name="desc-perl-number"/>
  </t:template>
  
  <t:template match="dump:dataType
             [child::dump:uri/@dump:uri =
             'http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#CharacterString']"
      mode="pl-name">
    <t:call-template name="desc-perl-character-string"/>
  </t:template>
  
  <t:template match="dump:dataType
             [child::dump:uri/@dump:uri =
             'http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#Object']"
      mode="pl-name">
    <t:call-template name="desc-perl-object"/>
  </t:template>
  
  <t:template match="dump:dataType
             [child::dump:uri/@dump:uri =
             'http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#Boolean']"
      mode="pl-name">
    <t:call-template name="desc-perl-boolean"/>
  </t:template>
  
  <t:template match="dump:param" mode="pl-name">
    <t:choose>
    <t:when test="child::dump:perlName">
      <var class="perl" lang="en" xml:lang="en">
        <t:value-of select="@dump:prefix"/>
        <t:value-of select="child::dump:perlName"/>
      </var>
    </t:when>
    <t:otherwise>
      <var class="perl" lang="en" xml:lang="en">
        <t:value-of select="@dump:prefix"/>
        <t:value-of select="@dump:localName"/>
      </var>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:method | dump:attribute | dump:param" mode="pl-type">
    <t:variable name="typeName">
      <t:value-of select="@dump:dataType |
                          child::dump:return/@dump:dataType |
                          child::dump:get/@dump:dataType"/>
    </t:variable>
    <t:variable name="type"
        select="$anyIDLType[child::dump:uri/@dump:uri = $typeName]"/>
    <t:choose>
    <t:when test="$type/self::dump:interface">
      <t:call-template name="label-object-of-interface">
        <t:with-param name="interface">
          <t:apply-templates select="$type" mode="pl-name"/>
        </t:with-param>
      </t:call-template>
    </t:when>
    <t:when test="$type/self::dump:dataType">
      <t:apply-templates select="$type" mode="pl-name"/>
    </t:when>
    <t:when test="$type">
      <t:value-of select="$type"/>
    </t:when>
    <t:otherwise/>
    </t:choose>
  </t:template>
  
  <t:template match="child::dump:extends" mode="pl">
    <t:param name="interface">
      <t:apply-templates select="parent::node ()" mode="pl-name"/>
    </t:param>
    <dd>
      <t:call-template name="desc-methods-of-super-interface">
        <t:with-param name="interface" select="$interface"/>
        <t:with-param name="superInterface">
          <t:variable name="siURI" select="string (@dump:uri)"/>
          <t:variable name="siNode"
              select="$allIDLInterface[child::dump:uri/@dump:uri = $siURI]"/>
          <t:apply-templates select="$siNode" mode="pl-name"/>
          <t:if test="not ($siNode)">
            <t:value-of select="$siURI"/>
          </t:if>
        </t:with-param>
        <t:with-param name="hasOtherMember"
            select="boolean (parent::node ()/
                               child::dump:attribute[not (@dump:ref)] or
                             parent::node ()/child::dump:method[not (@dump:ref)])"/>
      </t:call-template>
    </dd>
  </t:template>
  
  <t:template match="dump:module" mode="uri-pl">
    <t:apply-templates
        select="$rootDocument/child::dump:document
          [@dump:ref = current ()/child::dump:uri/@dump:uri]
          [child::ddoc:as/@dump:uri = '&f;PerlBindingDefinition']/parent::node ()"
        mode="doc-uri"/>
  </t:template>
  
  <t:template match="dump:interface" mode="uri-pl">
    <t:apply-templates select="parent::node ()" mode="uri-pl"/>
    <t:text>#</t:text>
    <t:apply-templates select="self::node ()" mode="id-pl"/>
  </t:template>

<!-- Unknowns -->

  <t:template match="child::*" mode="dom-document">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="dom-chapter">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="number">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="title">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="title-text">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="title-attr">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="toc-li">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="idl">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="idl-file">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="idl-file-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="idl-file-dir">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="idl-const-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="idl-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="idl-type">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="doc-uri">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="java">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="java-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="java-file-name-dir">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="java-file-name-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="java-file">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="java-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="java-type">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="es">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="es-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="es-type">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="pl">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="pl-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="pl-type">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="uri-java">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="uri-es">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="uri-pl">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="id-java">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="id-attr-java">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="id-es">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="id-attr-es">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="id-pl">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="*" mode="id-attr-pl">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>

</t:stylesheet>

<!-- Revision: $Date: 2005/10/05 11:38:26 $ -->

<!-- ***** BEGIN LICENSE BLOCK *****
   - Copyright 2005 Wakaba <w@suika.fam.cx>.  All rights reserved.
   -
   - This program is free software; you can redistribute it and/or 
   - modify it under the same terms as Perl itself.
   -
   - Alternatively, the contents of this file may be used 
   - under the following terms (the "MPL/GPL/LGPL"), 
   - in which case the provisions of the MPL/GPL/LGPL are applicable instead
   - of those above. If you wish to allow use of your version of this file only
   - under the terms of the MPL/GPL/LGPL, and not to allow others to
   - use your version of this file under the terms of the Perl, indicate your
   - decision by deleting the provisions above and replace them with the notice
   - and other provisions required by the MPL/GPL/LGPL. If you do not delete
   - the provisions above, a recipient may use your version of this file under
   - the terms of any one of the Perl or the MPL/GPL/LGPL.
   -
   - "MPL/GPL/LGPL":
   -
   - The contents of this file are subject to the Mozilla Public License Version
   - 1.1 (the "License"); you may not use this file except in compliance with
   - the License. You may obtain a copy of the License at
   - http://www.mozilla.org/MPL/
   -
   - Software distributed under the License is distributed on an "AS IS" basis,
   - WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
   - for the specific language governing rights and limitations under the
   - License.
   -
   - The Original Code is manakai disdump.
   -
   - The Initial Developer of the Original Code is
   - Wakaba <w@suika.fam.cx>.
   - Portions created by the Initial Developer are Copyright (C) 2005
   - the Initial Developer. All Rights Reserved.
   -
   - Contributor(s):
   -   Wakaba <w@suika.fam.cx>
   -
   - Alternatively, the contents of this file may be used under the terms of
   - either the GNU General Public License Version 2 or later (the "GPL"), or
   - the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
   - in which case the provisions of the GPL or the LGPL are applicable instead
   - of those above. If you wish to allow use of your version of this file only
   - under the terms of either the GPL or the LGPL, and not to allow others to
   - use your version of this file under the terms of the MPL, indicate your
   - decision by deleting the provisions above and replace them with the notice
   - and other provisions required by the LGPL or the GPL. If you do not delete
   - the provisions above, a recipient may use your version of this file under
   - the terms of any one of the MPL, the GPL or the LGPL.
   -
   - ***** END LICENSE BLOCK ***** -->