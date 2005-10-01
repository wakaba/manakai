<?xml version="1.0" encoding="iso-2022-jp"?>
<t:stylesheet xmlns:t="http://www.w3.org/1999/XSL/Transform"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:doc="http://suika.fam.cx/~wakaba/archive/2005/7/tutorial#"
    xmlns:tree="http://pc5.2ch.net/test/read.cgi/hp/1101043958/564"
    xmlns:xhtml1="http://www.w3.org/1999/xhtml"
    xmlns:xhtml2="http://www.w3.org/2002/06/xhtml2/"
    xmlns:html3="urn:x-suika-fam-cx:markup:ietf:html:3:draft:00:"
    xmlns:html5="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:dump="http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#DISDump/"
    xmlns:ddel="http://suika.fam.cx/~wakaba/archive/2005/disdoc#"
    xmlns:script="http://suika.fam.cx/~wakaba/archive/2005/5/script#"
    xmlns:sw010="urn:x-suika-fam-cx:markup:suikawiki:0:10:"
    xmlns:ddoct="http://suika.fam.cx/~wakaba/archive/2005/8/disdump-xslt#"
    xmlns:rfc2119="http://suika.fam.cx/~wakaba/archive/2005/rfc2119/"
    xmlns:dis="http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis--"
    version="1.0">

  <t:param name="mode" select="'module'"/>
  <t:param name="uri" select="string (/child::dump:moduleSet/child::dump:module
                                      /child::dump:uri/@dump:uri)"/>
  <t:param name="lang" select="'ja'"/>
  <t:param name="lang-suffix" select="'.ja'"/>
  <t:param name="html-type-suffix" select="'.html'"/>
  <t:param name="modules-file-path-prefix" select="'modules'"/>
  <t:param name="html-style-sheet-uri"
      select="'http://suika.fam.cx/www/style/html/xhtml'"/>
  <t:param name="is-html-style-sheet-uri-relative" select="false ()"/>
  
  <t:variable name="allClass"
        select="/child::dump:moduleSet/child::dump:module/child::dump:class"/>
  <t:variable name="anyClass"
        select="$allClass |
                /child::dump:moduleSet/child::dump:module/child::dump:interface"/>
  <t:variable name="allDataType"
        select="/child::dump:moduleSet/child::dump:module/child::dump:dataType"/>

  <t:template name="global-lang-attr">
    <t:attribute name="lang">ja</t:attribute>
    <t:attribute name="xml:lang">ja</t:attribute>
  </t:template>
  
  <t:template name="name-abstract">
    <span lang="ja" xml:lang="ja">概要</span>
  </t:template>
  
  <t:template name="name-abstract-attr">概要</t:template>
  
  <t:template name="name-anonymous">
    <span lang="ja" xml:lang="ja">(匿名)</span>
  </t:template>
  
  <t:template name="name-anonymous-attr">(匿名)</t:template>
  
  <t:template name="name-ecma-script-binding">
    <span lang="en" xml:lang="en">ECMAScript</span>
    <t:text> </t:text>
    <span lang="ja" xml:lang="ja">束縛</span>
  </t:template>
  <t:template name="name-ecma-script-binding-attr">ECMAScript 束縛</t:template>
  
  <t:template name="name-java-binding">
    <span lang="en" xml:lang="en">Java</span>
    <t:text> </t:text>
    <span lang="ja" xml:lang="ja">束縛</span>
  </t:template>
  <t:template name="name-java-binding-attr">Java 束縛</t:template>
  
  <t:template name="name-perl-binding">
    <span lang="en" xml:lang="en">Perl</span>
    <t:text> </t:text>
    <span lang="ja" xml:lang="ja">束縛</span>
  </t:template>
  <t:template name="name-perl-binding-attr">Perl 束縛</t:template>
  
  <t:template name="name-idl-definitions">
    <abbr lang="en" xml:lang="en">IDL</abbr>
    <t:text> </t:text>
    <span lang="ja" xml:lang="ja">定義</span>
  </t:template>
  <t:template name="name-idl-definitions-attr">IDL 定義</t:template>
  
  <t:template name="name-index">
    <span lang="ja" xml:lang="ja">索引</span>
  </t:template>
  <t:template name="name-index-attr">索引</t:template>
  
  <t:template name="name-the-interface">
    <t:param name="name" select="/parent::node ()"/>
    <span lang="ja" xml:lang="ja">界面</span>
    <t:text> </t:text>
    <t:copy-of select="$name"/>
  </t:template>
  <t:template name="name-the-interface-attr">
    <t:param name="name" select="/parent::node ()"/>
    <t:text>界面 </t:text>
    <t:value-of select="$name"/>
  </t:template>
  
  <t:template name="name-references">
    <span lang="ja" xml:lang="ja">参考文献</span>
  </t:template>
  <t:template name="name-references-attr">参考文献</t:template>
  
  <t:template name="name-normative-references">
    <span lang="ja" xml:lang="ja">引用規格 (規定)</span>
  </t:template>
  <t:template name="name-normative-references-attr">引用規格 (規定)</t:template>
  
  <t:template name="name-informative-references">
    <span lang="ja" xml:lang="ja">参考文献 (参考)</span>
  </t:template>
  <t:template name="name-informative-references-attr">参考文献 (参考)</t:template>
  
  <t:template name="name-status">
    <span lang="ja" xml:lang="ja">この文書の状態</span>
  </t:template>
  <t:template name="name-status-attr">この文書の状態</t:template>
  
  <t:template name="name-toc">
    <span lang="ja" xml:lang="ja">目次</span>
  </t:template>
  <t:template name="name-toc-attr">目次</t:template>
  
  <t:template name="name-expanded-toc">
    <span lang="ja" xml:lang="ja">詳細目次</span>
  </t:template>
  <t:template name="name-expanded-toc-attr">詳細目次</t:template>
  
  <t:template name="prefix-attribute">
    <span lang="ja" xml:lang="ja">属性</span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-class">
    <span lang="ja" xml:lang="ja">クラス</span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-class-attr">クラス </t:template>
  
  <t:template name="prefix-const">
    <span lang="ja" xml:lang="ja">定数</span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-const-group">
    <span lang="ja" xml:lang="ja">輸出可能定数札</span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-datatype">
    <span lang="ja" xml:lang="ja" class="dump-prefix-datatype">型</span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-datatype-attr">型 </t:template>
  
  <t:template name="prefix-interface">
    <t:param name="is-exception" select="false ()"/>
    <span lang="ja" xml:lang="ja">
      <t:choose>
      <t:when test="$is-exception">例外</t:when>
      <t:otherwise>界面</t:otherwise>
      </t:choose>
    </span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-interface-attr">
    <t:param name="is-exception" select="false ()"/>
    <t:choose>
    <t:when test="$is-exception">例外 </t:when>
    <t:otherwise>界面 </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template name="prefix-method">
    <span lang="ja" xml:lang="ja">メソッド</span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-module">
    <span lang="ja" xml:lang="ja">モジュール</span>
    <t:value-of select="' '"/>
  </t:template>
  
  <t:template name="prefix-module-attr">モジュール </t:template>
  
  <t:template name="suffix-attr">
    <t:value-of select="' '"/>
    <span lang="ja" xml:lang="ja" class="weak">(属性)</span>
  </t:template>
  
  <t:template name="suffix-empty-string">
    <t:value-of select="' '"/>
    <span lang="ja" xml:lang="ja" class="weak">(空文字列)</span>
  </t:template>
  
  <t:template name="suffix-inherited">
    <t:value-of select="' '"/>
    <span lang="ja" xml:lang="ja" class="weak">(継承)</span>
  </t:template>
  
  <t:template name="suffix-inherited-private">
    <t:value-of select="' '"/>
    <span lang="ja" xml:lang="ja" class="weak">(継承、内部用)</span>
  </t:template>
  
  <t:template name="suffix-private">
    <t:value-of select="' '"/>
    <span lang="ja" xml:lang="ja" class="weak">(内部用)</span>
  </t:template>
  
  <t:template name="suffix-read-only">
    <t:value-of select="' '"/>
    <span lang="ja" xml:lang="ja" class="weak">(読取専用)</span>
  </t:template>
  
  <t:template name="suffix-read-only-attr">
    <t:value-of select="' '"/>
    <span lang="ja" xml:lang="ja" class="weak">(読取専用属性)</span>
  </t:template>
  
  <t:template name="label-attributes">
    <span lang="ja" xml:lang="ja">属性</span>
  </t:template>
  
  <t:template name="label-const-groups">
    <span lang="ja" xml:lang="ja">輸出可能定数札</span>
  </t:template>
  
  <t:template name="label-exception-sub-code">
    <span lang="ja" xml:lang="ja" class="dump-label-sub-code"
    >例外の詳細</span>
  </t:template>
  
  <t:template name="label-exports-const-group">
    <span lang="ja" xml:lang="ja">この定数群をすべて輸出する</span>
  </t:template>
  
  <t:template name="label-consts">
    <span lang="ja" xml:lang="ja">定数</span>
  </t:template>
  
  <t:template name="label-exports-const">
    <span lang="ja" xml:lang="ja">この定数を輸出する</span>
  </t:template>
  
  <t:template name="label-classes">
    <span lang="ja" xml:lang="ja">クラス</span>
  </t:template>
  
  <t:template name="label-datatypes">
    <span lang="ja" xml:lang="ja">型</span>
  </t:template>
  
  <t:template name="label-overall-description">
    <span lang="ja" xml:lang="ja">概観</span>
  </t:template>
  
  <t:template name="label-documents">
    <span lang="ja" xml:lang="ja">文書</span>
  </t:template>
  
  <t:template name="label-examples">
    <span lang="ja" xml:lang="ja">例</span>
  </t:template>
  
  <t:template name="label-exceptions">
    <span lang="ja" xml:lang="ja">例外</span>
  </t:template>
  
  <t:template name="label-no-exception">
    <span lang="ja" xml:lang="ja">例外なし</span>
  </t:template>
  
  <t:template name="label-extends">
    <span lang="ja" xml:lang="ja">継承</span>
  </t:template>
  
  <t:template name="label-full-name">
    <span lang="ja" xml:lang="ja">名前</span>
  </t:template>
  
  <t:template name="label-idl-definition">
    <abbr lang="en" xml:lang="en">IDL</abbr>
    <t:text> </t:text>
    <span lang="ja" xml:lang="ja">定義</span>
  </t:template>
  
  <t:template name="label-implements">
    <span lang="ja" xml:lang="ja">実装する界面</span>
  </t:template>
  
  <t:template name="label-check-implements">
    <span lang="ja" xml:lang="ja">この界面を実装しているか確認する</span>
  </t:template>
  
  <t:template name="label-implemented-by">
    <span lang="ja" xml:lang="ja">既知の実装クラス</span>
  </t:template>
  
  <t:template name="label-member-implements">
    <span lang="ja" xml:lang="ja">定義されている界面</span>
  </t:template>
  
  <t:template name="label-inherited-by">
    <span lang="ja" xml:lang="ja">既知の継承クラス</span>
  </t:template>
  
  <t:template name="label-interfaces">
    <span lang="ja" xml:lang="ja">界面</span>
  </t:template>
  
  <t:template name="label-is-interface-implemented">
    <span lang="ja" xml:lang="ja">実装されています</span>
  </t:template>
  
  <t:template name="label-is-interface-not-implemented">
    <span lang="ja" xml:lang="ja">実装されていません</span>
  </t:template>
  
  <t:template name="label-label">
    <span lang="ja" xml:lang="ja">名前</span>
  </t:template>
  
  
  <t:template name="label-methods">
    <span lang="ja" xml:lang="ja">メソッド</span>
  </t:template>
  
  <t:template name="label-module">
    <span lang="ja" xml:lang="ja">モジュール</span>
  </t:template>
  
  <t:template name="label-modules">
    <span lang="ja" xml:lang="ja">モジュール</span>
  </t:template>
  <t:template name="label-modules-attr">モジュール</t:template>
  
  <t:template name="label-in-modules">
    <span lang="ja" xml:lang="ja">クラス, 界面, 型</span>
  </t:template>
  <t:template name="label-in-modules-attr">クラス, 界面, 型</t:template>
  
  <t:template name="label-load-module">
    <span lang="ja" xml:lang="ja">このモジュールを読込む</span>
  </t:template>
  
  <t:template name="label-load-module-for-class">
    <span lang="ja" xml:lang="ja"
    >このクラスを使うために必要なモジュールを読込む</span>
  </t:template>
  
  <t:template name="label-member-overrides">
    <span lang="ja" xml:lang="ja">上書きされている定義</span>
  </t:template>
  
  <t:template name="label-parameters">
    <span lang="ja" xml:lang="ja">引数</span>
  </t:template>
  
  <t:template name="label-no-parameter">
    <span lang="ja" xml:lang="ja">引数なし</span>
  </t:template>
  
  <t:template name="label-param-is-named">
    <span lang="ja" xml:lang="ja">名前付き引数</span>
  </t:template>
  
  <t:template name="label-param-is-optional">
    <span lang="ja" xml:lang="ja">省略可能</span>
  </t:template>
  
  <t:template name="label-read-only">
    <span lang="ja" xml:lang="ja">読取専用</span>
  </t:template>
  
  <t:template name="label-return-value">
    <span lang="ja" xml:lang="ja">返し値</span>
  </t:template>
  
  <t:template name="label-no-return-value">
    <span lang="ja" xml:lang="ja">返し値なし</span>
  </t:template>
  
  <t:template name="label-tfuri-f">
    <span lang="ja" xml:lang="ja">対象</span>
  </t:template>
  
  <t:template name="label-tfuri-t">
    <span lang="ja" xml:lang="ja">名前</span>
  </t:template>
  
  <t:template name="label-no-return-value-short">
    <span lang="ja" xml:lang="ja">なし</span>
  </t:template>
  
  <t:template name="label-type-definition">
    <span lang="ja" xml:lang="ja">型定義</span>
  </t:template>
  
  <t:template name="label-uri">
    <abbr lang="en" xml:lang="en" title="Uniform Resource Identifiers">URI</abbr>
  </t:template>
  
  <t:template name="label-perl-module-name">
    <span lang="ja" xml:lang="ja"><span lang="en" xml:lang="en">Perl</span>
    モジュール名</span>
  </t:template>
  
  <t:template name="label-perl-package-name">
    <span lang="ja" xml:lang="ja"><span lang="en" xml:lang="en">Perl</span>
    パッケージ名</span>
  </t:template>
  
  <t:template name="label-perl-name">
    <span lang="ja" xml:lang="ja"><span lang="en" xml:lang="en">Perl</span>
    名</span>
  </t:template>

  <t:template name="label-sep">
    <t:value-of select="', '"/>
  </t:template>

  <t:template name="if-is-specified">
    <t:param name="param"/>
    <t:copy-of select="$param"/>
    <t:value-of select="' が指定されている場合。'"/>
  </t:template>

  <t:template name="if-is-not-specified">
    <t:param name="param"/>
    <t:copy-of select="$param"/>
    <t:value-of select="' が指定されていない場合。'"/>
  </t:template>
  
  <t:template name="space">
    <t:param name="length" select="1"/>
    <t:if test="$length > 0">
      <t:if test="$length > 1">
        <t:call-template name="space">
          <t:with-param name="length" select="$length - 1"/>
        </t:call-template>
      </t:if>
      <t:text> </t:text>
    </t:if>
  </t:template>
  
  <t:template match="/">
    <t:choose>
    <t:when test="string ($mode) = 'list'">
      <t:apply-templates select="self::node ()" mode="list"/>
    </t:when>
    <t:when test="$mode = 'modules'">
      <t:apply-templates select="/child::dump:moduleSet" mode="doc"/>
    </t:when>
    <t:when test="$mode = 'modules-menu'">
      <t:apply-templates select="/child::dump:moduleSet" mode="doc-menu"/>
    </t:when>
    <t:when test="$mode = 'modules-menu-frame'">
      <t:apply-templates select="/child::dump:moduleSet" mode="doc-menu-frame"/>
    </t:when>
    <t:when test="$mode = 'module-group'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:moduleGroup
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc"/>
    </t:when>
    <t:when test="$mode = 'module-group-menu'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:moduleGroup
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc-menu"/>
    </t:when>
    <t:when test="$mode = 'module-group-menu-frame'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:moduleGroup
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc-menu-frame"/>
    </t:when>
    <t:when test="$mode = 'module'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:module
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc"/>
    </t:when>
    <t:when test="$mode = 'module-menu'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:module
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc-menu"/>
    </t:when>
    <t:when test="$mode = 'module-menu-frame'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:module
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc-menu-frame"/>
    </t:when>
    <t:when test="$mode = 'class'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:module
                                 /child::dump:class
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc"/>
    </t:when>
    <t:when test="$mode = 'interface'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:module
                                 /child::dump:interface
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc"/>
    </t:when>
    <t:when test="$mode = 'datatype'">
      <t:apply-templates select="/child::dump:moduleSet
                                 /child::dump:module
                                 /child::dump:dataType
                                 [
                                   child::dump:uri/@dump:uri = string ($uri)
                                 ]" mode="doc"/>
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
  
  <t:template match="dump:moduleSet" mode="h2">
    <t:apply-templates mode="h2"/>
  </t:template>
  
  <t:template match="dump:moduleSet" mode="doc">
    <html class="dump-module-set-doc">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="label-modules-attr"/>
        </title>
      </head>
      <body>
        <t:apply-templates select="self::node ()" mode="h1b"/>
      </body>
    </html>
  </t:template>
  <t:template match="dump:moduleSet" mode="doc-menu">
    <html class="dump-module-set-doc-menu">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="label-in-modules-attr"/>
        </title>
        <base target="maindocument"/>
      </head>
      <body>
        <h1><t:call-template name="label-in-modules"/></h1>
        <ul>
          <t:variable name="module"
              select="child::dump:module[not (@dump:isPartial)]"/>
          <t:apply-templates select="$module/child::dump:class |
                                     $module/child::dump:interface |
                                     $module/child::dump:dataType" mode="li">
            <t:with-param name="short" select="true ()"/>
            <t:with-param name="ddoct:basePath">
              <t:apply-templates select="self::node ()" mode="base-path"/>
            </t:with-param>
            <t:sort select="child::dump:perlName |
                            child::dump:label |
                            child::dump:fullName"/>
          </t:apply-templates>
        </ul>
      </body>
    </html>
  </t:template>
  <t:template match="dump:moduleSet" mode="doc-menu-frame">
    <t:param name="ddoct:basePath" select="''"/>
    <html class="dump-module-set-doc-menu-frame">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="label-modules-attr"/>
        </title>
      </head>
      <frameset cols="20%,*">
        <frame name="menu">
          <t:attribute name="src">
            <t:apply-templates select="self::node ()" mode="uri-menu">
              <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            </t:apply-templates>
          </t:attribute>
        </frame>
        <frame name="maindocument">
          <t:attribute name="src">
            <t:apply-templates select="self::node ()" mode="uri">
              <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            </t:apply-templates>
          </t:attribute>
        </frame>
        <noframes>
          <body>
            <h1>
              <t:call-template name="label-modules"/>
            </h1>
            <p>
              <t:apply-templates select="self::node ()" mode="ref">
                <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
              </t:apply-templates>
            </p>
          </body>
        </noframes>
      </frameset>
    </html>
  </t:template>
  <t:template match="dump:moduleSet" mode="h1b">
    <t:apply-templates select="self::node ()" mode="h1-heading"/>
    <ul>
      <t:apply-templates select="child::dump:module[not (@dump:isPartial)]"
          mode="li">
        <t:sort select="child::dump:perlPackageName"/>
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
      </t:apply-templates>
    </ul>
  </t:template>
  <t:template match="dump:moduleSet" mode="heading-content">
    <t:call-template name="label-modules"/>
  </t:template>
  <t:template match="dump:moduleSet" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name"/>
  </t:template>
  <t:template match="dump:moduleSet" mode="uri-menu">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name-menu"/>
  </t:template>
  <t:template match="dump:moduleSet" mode="uri-menu-frame">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name-menu-frame"/>
  </t:template>
  <t:template match="dump:moduleSet" mode="file-name-stem">
    <t:value-of select="$modules-file-path-prefix"/>
  </t:template>
  <t:template match="dump:moduleSet" mode="file-name">
    <t:apply-templates select="self::node ()" mode="file-name-stem"/>
    <t:value-of select="$lang-suffix"/>
    <t:value-of select="$html-type-suffix"/>
  </t:template>
  <t:template match="dump:moduleSet" mode="file-name-menu">
    <t:apply-templates select="self::node ()" mode="file-name-stem"/>
    <t:value-of select="'-menu'"/>
    <t:value-of select="$lang-suffix"/>
    <t:value-of select="$html-type-suffix"/>
  </t:template>
  <t:template match="dump:moduleSet" mode="file-name-menu-frame">
    <t:apply-templates select="self::node ()" mode="file-name-stem"/>
    <t:value-of select="'-with-menu'"/>
    <t:value-of select="$lang-suffix"/>
    <t:value-of select="$html-type-suffix"/>
  </t:template>
  
<!-- Module Groups -->
  
  <t:template match="dump:moduleGroup" mode="h1b">
    <t:apply-templates select="self::node ()" mode="h1-heading"/>
    <t:apply-templates select="child::dump:description"/>
    <dl class="dump-info dump-info-module">
      <t:choose>
      <t:when test="child::dump:fullName">
        <t:apply-templates select="child::dump:fullName" mode="dl"/>
      </t:when>
      <t:otherwise>
        <t:apply-templates select="child::dump:label" mode="dl"/>
      </t:otherwise>
      </t:choose>
      <t:apply-templates select="self::node ()" mode="dl-modules"/>
      <t:apply-templates select="self::node ()" mode="dl-documents"/>
      <t:apply-templates select="self::node ()" mode="dl-examples"/>
    </dl>
  </t:template>
  <t:template match="dump:moduleGroup" mode="heading-content">
    <t:apply-templates select="self::node ()" mode="human-module-name"/>
  </t:template>
  <t:template match="dump:moduleGroup" mode="file-name-stem">
    <t:if test="@dump:filePathStem">
      <t:value-of select="@dump:filePathStem"/>
    </t:if>
  </t:template>
  <t:template match="dump:moduleGroup" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <a class="dump-ref dump-ref-module-group">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </a>
  </t:template>
  
  <t:template match="dump:moduleGroup" mode="dl-modules">
    <t:if test="child::dump:module">
      <dt><t:call-template name="label-modules"/></dt>
      <t:apply-templates select="child::dump:module" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
        <t:sort select="child::dump:perlPackageName"/>
      </t:apply-templates>
    </t:if>
  </t:template>
  
  <t:template match="dump:moduleGroup" mode="dl-documents">
    <t:if test="child::dump:document">
      <dt><t:call-template name="label-documents"/></dt>
      <t:apply-templates select="child::dump:document" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
      </t:apply-templates>
    </t:if>
  </t:template>
  
  <t:template match="dump:moduleGroup" mode="doc">
    <html class="dump-module-group-doc">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
      </head>
      <body>
        <t:apply-templates select="self::node ()" mode="h1b"/>
      </body>
    </html>
  </t:template>
  <t:template match="dump:moduleGroup" mode="doc-menu">
    <html class="dump-module-group-doc-menu">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
        <base target="maindocument"/>
      </head>
      <body>
        <h1>
          <t:apply-templates select="self::node ()" mode="human-module-name"/>
        </h1>
        <ul>
          <li>
            <a>
              <t:attribute name="href">
                <t:apply-templates select="self::node ()" mode="uri-menu"/>
              </t:attribute>
              <t:call-template name="label-overall-description"/>
            </a>
          </li>
          <t:variable name="mod" select="/child::dump:moduleSet
                                         /child::dump:module
                                         [child::dump:uri/@dump:uri =
                                          current ()/child::dump:module/@dump:ref]"/>
          <t:apply-templates select="$mod/child::dump:class |
                                     $mod/child::dump:interface |
                                     $mod/child::dump:dataType" mode="li">
            <t:with-param name="short" select="true ()"/>
            <t:with-param name="ddoct:basePath">
              <t:apply-templates select="self::node ()" mode="base-path"/>
            </t:with-param>
            <t:sort select="child::dump:perlName |
                            child::dump:label |
                            child::dump:dataType"/>
          </t:apply-templates>
        </ul>
      </body>
    </html>
  </t:template>
  <t:template match="dump:moduleGroup" mode="doc-menu-frame">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <html class="dump-module-group-doc-menu-frame">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
      </head>
      <frameset cols="20%,*">
        <frame name="menu">
          <t:attribute name="src">
            <t:apply-templates select="self::node ()" mode="uri-menu">
              <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            </t:apply-templates>
          </t:attribute>
        </frame>
        <frame name="maindocument">
          <t:attribute name="src">
            <t:apply-templates select="self::node ()" mode="uri">
              <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            </t:apply-templates>
          </t:attribute>
        </frame>
        <noframes>
          <body>
            <h1>
              <t:call-template name="prefix-module"/>
              <t:apply-templates select="self::node ()" mode="human-module-name"/>
            </h1>
            <p>
              <t:apply-templates select="self::node ()" mode="ref">
                <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
              </t:apply-templates>
            </p>
          </body>
        </noframes>
      </frameset>
    </html>
  </t:template>
  
  <t:template match="dump:module" mode="h1b">
    <t:apply-templates select="self::node ()" mode="h1-heading"/>
    <t:apply-templates select="child::dump:description"/>
    <dl class="dump-info dump-info-module">
      <t:apply-templates select="child::dump:perlPackageName" mode="dl"/>
      <t:apply-templates select="self::node ()" mode="dl-datatypes"/>
      <t:apply-templates select="self::node ()" mode="dl-interfaces"/>
      <t:apply-templates select="self::node ()" mode="dl-classes"/>
      <t:apply-templates select="self::node ()" mode="dl-examples"/>
    </dl>
  </t:template>
  <t:template match="dump:module" mode="h2">
    <div>
      <t:attribute name="class">
        <t:text>section</t:text>
        <t:if test="string (@dump:access) = 'private'"> dump-access-private</t:if>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="h2-heading"/>
      <t:apply-templates select="child::dump:description"/>
      <dl class="dump-info dump-info-module">
        <t:apply-templates select="child::dump:perlPackageName" mode="dl"/>
        <t:apply-templates select="self::node ()" mode="dl-datatypes"/>
        <t:apply-templates select="self::node ()" mode="dl-interfaces"/>
        <t:apply-templates select="self::node ()" mode="dl-classes"/>
      </dl>
      <t:apply-templates select="child::dump:dataType" mode="h3"/>
      <t:apply-templates select="child::dump:interface" mode="h3"/>
      <t:apply-templates select="child::dump:class" mode="h3"/>
    </div>
  </t:template>
  <t:template match="dump:module" mode="h1-heading">
    <h1><t:apply-templates select="self::node ()" mode="heading-content"/></h1>
  </t:template>
  <t:template match="dump:module" mode="h2-heading">
    <h2><t:apply-templates select="self::node ()" mode="heading-content"/></h2>
  </t:template>
  <t:template match="dump:module" mode="heading-content">
    <t:call-template name="prefix-module"/>
    <t:apply-templates select="self::node ()" mode="human-module-name"/>
  </t:template>
  <t:template match="dump:module" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:apply-templates select="child::dump:perlPackageName"
          mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:module" mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:apply-templates select="child::dump:perlPackageName"
          mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:module" mode="human-module-name-attr">
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:apply-templates select="child::dump:perlPackageName"
          mode="human-module-name-attr"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-attr"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous-attr"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:module" mode="file-name-stem">
    <t:if test="@dump:filePathStem">
      <t:value-of select="@dump:filePathStem"/>
      <t:value-of select="'/'"/>
    </t:if>
    <t:value-of select="'module'"/>
  </t:template>
  <t:template match="dump:module | dump:moduleGroup" mode="file-name">
    <t:apply-templates select="self::node ()" mode="file-name-stem"/>
    <t:value-of select="$lang-suffix"/>
    <t:value-of select="$html-type-suffix"/>
  </t:template>
  <t:template match="dump:module | dump:moduleGroup" mode="file-name-menu">
    <t:apply-templates select="self::node ()" mode="file-name-stem"/>
    <t:value-of select="'-menu'"/>
    <t:value-of select="$lang-suffix"/>
    <t:value-of select="$html-type-suffix"/>
  </t:template>
  <t:template match="dump:module | dump:moduleGroup" mode="file-name-menu-frame">
    <t:apply-templates select="self::node ()" mode="file-name-stem"/>
    <t:value-of select="'-with-menu'"/>
    <t:value-of select="$lang-suffix"/>
    <t:value-of select="$html-type-suffix"/>
  </t:template>
  <t:template match="dump:module | dump:moduleGroup" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name"/>
  </t:template>
  <t:template match="dump:module | dump:moduleGroup" mode="uri-menu">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name-menu"/>
  </t:template>
  <t:template match="dump:module | dump:moduleGroup" mode="uri-menu-frame">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name-menu-frame"/>
  </t:template>
  <t:template match="dump:module" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <a class="dump-ref dump-ref-module">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </a>
  </t:template>
  
  <t:template match="dump:module" mode="dl-classes">
    <t:if test="child::dump:class">
      <dt><t:call-template name="label-classes"/></dt>
      <t:apply-templates select="child::dump:class" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
        <t:sort select="child::dump:perlName"/>
      </t:apply-templates>
    </t:if>
  </t:template>
  
  <t:template match="dump:module" mode="dl-datatypes">
    <t:if test="child::dump:dataType">
      <dt><t:call-template name="label-datatypes"/></dt>
      <t:apply-templates select="child::dump:dataType" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
        <t:sort select="child::dump:perlName"/>
      </t:apply-templates>
    </t:if>
  </t:template>
  
  <t:template match="dump:module" mode="dl-interfaces">
    <t:if test="child::dump:interface">
      <dt><t:call-template name="label-interfaces"/></dt>
      <t:apply-templates select="child::dump:interface" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
        <t:sort select="child::dump:perlName"/>
      </t:apply-templates>
    </t:if>
  </t:template>
  
  <t:template match="dump:module" mode="doc">
    <html class="dump-module-doc">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="prefix-module-attr"/>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
      </head>
      <body>
        <t:apply-templates select="self::node ()" mode="h1b"/>
      </body>
    </html>
  </t:template>
  <t:template match="dump:module" mode="doc-menu">
    <html class="dump-module-doc-menu">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="prefix-module-attr"/>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
        <base target="maindocument"/>
      </head>
      <body>
        <h1>
          <t:apply-templates select="self::node ()" mode="human-module-name"/>
        </h1>
        <ul>
          <t:apply-templates select="child::dump:class |
                                     child::dump:interface |
                                     child::dump:dataType" mode="li">
            <t:with-param name="short" select="true ()"/>
            <t:with-param name="ddoct:basePath">
              <t:apply-templates select="self::node ()" mode="base-path"/>
            </t:with-param>
            <t:sort select="child::dump:perlName |
                            child::dump:label |
                            child::dump:dataType"/>
          </t:apply-templates>
        </ul>
      </body>
    </html>
  </t:template>
  <t:template match="dump:module" mode="doc-menu-frame">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <html class="dump-module-doc-menu-frame">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="prefix-module-attr"/>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
      </head>
      <frameset cols="20%,*">
        <frame name="menu">
          <t:attribute name="src">
            <t:apply-templates select="self::node ()" mode="uri-menu">
              <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            </t:apply-templates>
          </t:attribute>
        </frame>
        <frame name="maindocument">
          <t:attribute name="src">
            <t:apply-templates select="self::node ()" mode="uri">
              <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            </t:apply-templates>
          </t:attribute>
        </frame>
        <noframes>
          <body>
            <h1>
              <t:call-template name="prefix-module"/>
              <t:apply-templates select="self::node ()" mode="human-module-name"/>
            </h1>
            <p>
              <t:apply-templates select="self::node ()" mode="ref">
                <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
              </t:apply-templates>
            </p>
          </body>
        </noframes>
      </frameset>
    </html>
  </t:template>
  
  <t:template match="dump:module" mode="dl-examples">
    <dt><t:call-template name="label-examples"/></dt>
    <dd>
      <div class="example has-caption">
        <div class="caption"><t:call-template name="label-load-module"/></div>
        <pre><code class="perl" lang="en" xml:lang="en">require <t:apply-templates
        select="child::dump:perlPackageName" mode="human-module-name"/>;</code></pre>
      </div>
    </dd>
  </t:template>
  
  <t:template match="dump:module[@dump:ref]" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <t:apply-templates select="/child::dump:moduleSet/child::dump:module
                               [child::dump:uri/@dump:uri = current ()/@dump:ref]"
        mode="dd">
      <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      <t:with-param name="short" select="$short"/>
    </t:apply-templates>
  </t:template>
  <t:template match="dump:module[@dump:ref]" mode="li">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <t:apply-templates select="/child::dump:moduleSet/child::dump:module
                               [child::dump:uri/@dump:uri = current ()/@dump:ref]"
        mode="li">
      <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      <t:with-param name="short" select="$short"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="dump:class" mode="h1b">
    <t:apply-templates select="self::node ()" mode="h1-heading"/>
    <t:apply-templates select="child::dump:description"/>
    <dl class="dump-info dump-info-class">
      <t:apply-templates select="child::dump:perlPackageName" mode="dl"/>
      <dt><t:call-template name="label-module"/></dt>
      <t:apply-templates select="parent::dump:module" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
      </t:apply-templates>
      <t:apply-templates select="self::node ()" mode="dl-inheritance"/>
      <t:apply-templates select="self::node ()" mode="dl-interfaces"/>
      <t:apply-templates select="self::node ()" mode="dl-inherited"/>
      <t:apply-templates select="self::node ()" mode="dl-constants"/>
      <t:apply-templates select="self::node ()" mode="dl-methods"/>
      <t:apply-templates select="self::node ()" mode="dl-examples"/>
    </dl>
  </t:template>
  <t:template match="dump:class" mode="h3">
    <div>
      <t:attribute name="class">
        <t:text>section</t:text>
        <t:if test="string (@dump:access) = 'private'"> dump-access-private</t:if>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="h3-heading"/>
      <t:apply-templates select="child::dump:description"/>
      <dl class="dump-info dump-info-class">
        <t:apply-templates select="child::dump:perlPackageName" mode="dl"/>
        <dt><t:call-template name="label-module"/></dt>
          <dd>
            <t:apply-templates select="parent::dump:*" mode="ref">
              <t:with-param name="ddoct:basePath">
                <t:apply-templates select="self::node ()" mode="base-path"/>
              </t:with-param>
            </t:apply-templates>
          </dd>
        <t:apply-templates select="self::node ()" mode="dl-inheritance"/>
        <t:apply-templates select="self::node ()" mode="dl-interfaces"/>
        <t:apply-templates select="self::node ()" mode="dl-constants"/>
        <t:apply-templates select="self::node ()" mode="dl-methods"/>
      </dl>
      <t:apply-templates select="(child::dump:constGroup |
                                  child::dump:attribute |
                                  child::dump:method)
                                 [not (@dump:ref)]" mode="h4"/>
    </div>
  </t:template>
  <t:template match="dump:class" mode="h1-heading">
    <h1><t:apply-templates select="self::node ()" mode="heading-content"/></h1>
  </t:template>
  <t:template match="dump:class" mode="h3-heading">
    <h3><t:apply-templates select="self::node ()" mode="heading-content"/></h3>
  </t:template>
  <t:template match="dump:class" mode="heading-content">
    <t:call-template name="prefix-class"/>
    <t:apply-templates select="self::node ()" mode="human-module-name"/>
  </t:template>
  <t:template match="dump:class" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:apply-templates select="child::dump:perlPackageName"
          mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:class" mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:choose>
      <t:when test="$short">
        <t:apply-templates select="child::dump:perlName"
            mode="human-module-name-text"/>
      </t:when>
      <t:otherwise>
        <t:apply-templates select="child::dump:perlPackageName"
            mode="human-module-name-text"/>
      </t:otherwise>
      </t:choose>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:class" mode="human-module-name-attr">
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:apply-templates select="child::dump:perlPackageName"
          mode="human-module-name-attr"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-attr"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous-attr"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:module | dump:class" mode="li">
    <t:param name="short" select="false ()"/>
    <t:param name="ddoct:basePath" select="''"/>
    <li>
      <t:apply-templates select="self::node ()" mode="ref">
        <t:with-param name="short" select="$short"/>
        <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      </t:apply-templates>
      <t:if test="@dump:access = 'private'">
        <t:call-template name="suffix-private"/>
      </t:if>
    </li>
  </t:template>
  <t:template match="dump:module | dump:class" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
      <t:if test="@dump:access = 'private'">
        <t:call-template name="suffix-private"/>
      </t:if>
    </dd>
  </t:template>
  <t:template match="dump:class" mode="ref">
    <t:param name="short" select="false ()"/>
    <t:param name="ddoct:basePath" select="''"/>
    <a class="dump-ref dump-ref-class">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </a>
  </t:template>
  
  <t:template match="dump:class" mode="dl-constants">
    <t:if test="child::dump:constGroup">
      <dt><t:call-template name="label-const-groups"/></dt>
      <t:apply-templates select="child::dump:constGroup" mode="dd"/>
    </t:if>
  </t:template>
  <t:template match="dump:class" mode="dl-methods">
    <t:if test="child::dump:method | child::dump:attribute">
      <dt><t:call-template name="label-methods"/></dt>
      <t:apply-templates select="child::dump:method | child::dump:attribute"
          mode="dd">
        <t:sort select="child::dump:perlName | child::dump:uri/@dump:uri"/>
      </t:apply-templates>
    </t:if>
  </t:template>
  
  <t:template match="dump:class" mode="doc">
    <html class="dump-class-doc">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="prefix-class-attr"/>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
      </head>
      <body>
        <t:apply-templates select="self::node ()" mode="h1b"/>
        <t:apply-templates select="(child::dump:constGroup |
                                    child::dump:attribute |
                                    child::dump:method)
                                   [not (@dump:ref)]" mode="h2"/>
      </body>
    </html>
  </t:template>
  <t:template match="dump:class" mode="file-name">
    <t:if test="@dump:filePathStem">
      <t:value-of select="@dump:filePathStem"/>
      <t:value-of select="$lang-suffix"/>
      <t:value-of select="$html-type-suffix"/>
    </t:if>
  </t:template>
  <t:template match="dump:class" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name"/>
  </t:template>
  <t:template match="dump:class" mode="dl-inheritance">
    <t:if test="child::dump:extends">
      <dt class="dump-extends"><t:call-template name="label-extends"/></dt>
        <dd class="dump-extends">
          <ol class="xoxo dump-extends">
            <li class="dump-extends">
              <t:apply-templates select="self::node ()" mode="ref">
                <t:with-param name="ddoct:basePath">
                  <t:apply-templates select="self::node ()" mode="base-path"/>
                </t:with-param>
              </t:apply-templates>
              <ol class="dump-extends">
                <t:apply-templates select="child::dump:extends"
                      mode="li">
                  <t:with-param name="ddoct:basePath">
                    <t:apply-templates select="self::node ()" mode="base-path"/>
                  </t:with-param>
                </t:apply-templates>
              </ol>
            </li>
          </ol>
        </dd>
    </t:if>
  </t:template>
  <t:template match="dump:class" mode="dl-interfaces">
    <t:if test="child::dump:implements">
      <dt><t:call-template name="label-implements"/></dt>
      <t:for-each select="child::dump:implements">
        <t:apply-templates select="self::node ()
                  [not (preceding-sibling::dump:implements
                        /descendant-or-self::*
                          [string (@dump:uri) = string (current ()/@dump:uri)] or
                        following-sibling::dump:implements
                        /descendant-or-self::*
                          [string (@dump:uri) = string (current ()/@dump:uri)])]"
            mode="dd"/>
      </t:for-each>
    </t:if>
  </t:template>
  <t:template match="dump:class" mode="dl-inherited">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <t:variable name="subclass" select="$allClass
        [child::dump:extends/descendant-or-self::dump:extends/@dump:uri
          = current ()/child::dump:uri/@dump:uri]"/>
    <t:if test="$subclass">
      <dt><t:call-template name="label-inherited-by"/></dt>
      <dd>
        <t:apply-templates select="$subclass[position () = 1]" mode="ref">
          <t:with-param name="short" select="true ()"/>
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
        <t:for-each select="$subclass[position () != 1]">
          <t:call-template name="label-sep"/>
          <t:apply-templates select="self::node ()" mode="ref">
            <t:with-param name="short" select="true ()"/>
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
          </t:apply-templates>
        </t:for-each>
      </dd>
    </t:if>
  </t:template>
  
  <t:template match="dump:class" mode="dl-examples">
    <dt><t:call-template name="label-examples"/></dt>
    <dd>
      <div class="example has-caption">
        <div class="caption">
          <t:call-template name="label-load-module-for-class"/>
        </div>
        <pre><code class="perl" lang="en" xml:lang="en">require <t:apply-templates
        select="parent::dump:module" mode="human-module-name"/>;</code></pre>
      </div>
    </dd>
  </t:template>
  
  <t:template match="dump:interface" mode="h1b">
    <t:apply-templates select="self::node ()" mode="h1-heading"/>
    <t:apply-templates select="child::dump:description"/>
    <dl class="dump-info dump-info-interface">
      <t:apply-templates select="child::dump:perlPackageName" mode="dl"/>
      <dt><t:call-template name="label-module"/></dt>
      <t:apply-templates select="parent::dump:module" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
      </t:apply-templates>
      <t:apply-templates select="self::node ()" mode="dl-inheritance"/>
      <t:apply-templates select="self::node ()" mode="dl-implemented"/>
      <t:apply-templates select="self::node ()" mode="dl-constants"/>
      <t:apply-templates select="self::node ()" mode="dl-methods"/>
      <t:apply-templates select="self::node ()" mode="dl-examples"/>
    </dl>
  </t:template>
  <t:template match="dump:interface" mode="heading-content">
    <t:call-template name="prefix-interface">
      <t:with-param name="is-exception" select="boolean (@dump:isException)"/>
    </t:call-template>
    <t:apply-templates select="self::node ()" mode="human-module-name"/>
  </t:template>
  <t:template match="dump:interface" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:apply-templates select="child::dump:perlPackageName"
          mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:interface" mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:choose>
      <t:when test="$short">
        <t:apply-templates select="child::dump:perlName"
            mode="human-module-name-text"/>
      </t:when>
      <t:otherwise>
        <t:apply-templates select="child::dump:perlPackageName"
            mode="human-module-name-text"/>
      </t:otherwise>
      </t:choose>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:interface" mode="human-module-name-attr">
    <t:choose>
    <t:when test="child::dump:perlPackageName">
      <t:apply-templates select="child::dump:perlPackageName"
          mode="human-module-name-attr"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-attr"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous-attr"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:interface" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
    </dd>
  </t:template>
  <t:template match="dump:interface" mode="li">
    <t:param name="short" select="false ()"/>
    <t:param name="ddoct:basePath" select="''"/>
    <li>
      <t:apply-templates select="self::node ()" mode="ref">
        <t:with-param name="short" select="$short"/>
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
    </li>
  </t:template>
  <t:template match="dump:interface" mode="ref">
    <t:param name="short" select="false ()"/>
    <t:param name="ddoct:basePath" select="''"/>
    <a class="dump-ref dump-ref-interface">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </a>
  </t:template>
  <t:template match="dump:interface" mode="dl-constants">
    <t:if test="child::dump:constGroup">
      <dt><t:call-template name="label-const-groups"/></dt>
      <t:apply-templates select="child::dump:constGroup" mode="dd"/>
    </t:if>
  </t:template>
  <t:template match="dump:interface" mode="dl-methods">
    <t:if test="child::dump:method | child::dump:attribute">
      <dt><t:call-template name="label-methods"/></dt>
      <t:apply-templates select="child::dump:method | child::dump:attribute"
          mode="dd">
        <t:sort select="child::dump:perlName | child::dump:uri/@dump:uri"/>
      </t:apply-templates>
    </t:if>
  </t:template>
  
  <t:template match="dump:interface" mode="doc">
    <html class="dump-interface-doc">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="prefix-interface-attr">
            <t:with-param name="is-exception" select="boolean (@dump:isException)"/>
          </t:call-template>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
      </head>
      <body>
        <t:apply-templates select="self::node ()" mode="h1b"/>
        <t:apply-templates select="(child::dump:constGroup |
                                    child::dump:attribute |
                                    child::dump:method)
                                   [not (@dump:ref)]" mode="h2"/>
      </body>
    </html>
  </t:template>
  <t:template match="dump:interface" mode="file-name">
    <t:if test="@dump:filePathStem">
      <t:value-of select="@dump:filePathStem"/>
      <t:value-of select="$lang-suffix"/>
      <t:value-of select="$html-type-suffix"/>
    </t:if>
  </t:template>
  <t:template match="dump:interface" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name"/>
  </t:template>
    
  <t:template match="dump:interface" mode="dl-inheritance">
    <t:if test="child::dump:extends">
      <dt class="dump-extends"><t:call-template name="label-extends"/></dt>
        <dd class="dump-extends">
          <ol class="xoxo dump-extends">
            <li class="dump-extends">
              <t:apply-templates select="self::node ()" mode="ref">
                <t:with-param name="ddoct:basePath">
                  <t:apply-templates select="self::node ()" mode="base-path"/>
                </t:with-param>
              </t:apply-templates>
              <ol class="dump-extends">
                <t:apply-templates select="child::dump:extends" mode="li">
                  <t:with-param name="ddoct:basePath">
                    <t:apply-templates select="self::node ()" mode="base-path"/>
                  </t:with-param>
                </t:apply-templates>
              </ol>
            </li>
          </ol>
        </dd>
    </t:if>
  </t:template>
  
  <t:template match="dump:interface" mode="dl-examples">
    <dt><t:call-template name="label-examples"/></dt>
    <dd>
      <div class="example has-caption">
        <div class="caption"><t:call-template name="label-check-implements"/></div>
        <pre><code class="perl" lang="en" xml:lang="en"
        >if (<var>$object</var>->isa ("<t:apply-templates
        select="child::dump:perlPackageName" mode="human-module-name"
        />")) {
<!-- -->  ## <t:call-template name="label-is-interface-implemented"/>
<!-- -->} else {
<!-- -->  ## <t:call-template name="label-is-interface-not-implemented"/>
<!-- -->}</code></pre>
      </div>
    </dd>
  </t:template>

  <t:template match="dump:interface" mode="dl-implemented">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <t:variable name="subclass" select="$allClass
        [child::dump:implements/descendant-or-self::dump:*/@dump:uri
          = current ()/child::dump:uri/@dump:uri]"/>
    <t:if test="$subclass">
      <dt><t:call-template name="label-implemented-by"/></dt>
      <dd>
        <t:apply-templates select="$subclass[position () = 1]" mode="ref">
          <t:with-param name="short" select="true ()"/>
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
        <t:for-each select="$subclass[position () != 1]">
          <t:call-template name="label-sep"/>
          <t:apply-templates select="self::node ()" mode="ref">
            <t:with-param name="short" select="true ()"/>
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
          </t:apply-templates>
        </t:for-each>
      </dd>
    </t:if>
  </t:template>

  <t:template match="dump:dataType" mode="h1b">
    <t:apply-templates select="self::node ()" mode="h1-heading"/>
    <t:apply-templates select="child::dump:description"/>
    <dl class="dump-info dump-info-data-type">
      <t:choose>
      <t:when test="child::dump:fullName">
        <t:apply-templates select="child::dump:fullName" mode="dl"/>
      </t:when>
      <t:otherwise>
        <t:apply-templates select="child::dump:label" mode="dl"/>
      </t:otherwise>
      </t:choose>
      <dt><t:call-template name="label-module"/></dt>
      <t:apply-templates select="parent::dump:module" mode="dd">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
      </t:apply-templates>
      <t:apply-templates select="self::node ()" mode="dl-superclasses"/>
      <t:apply-templates select="self::node ()" mode="dl-examples"/>
    </dl>
  </t:template>
  <t:template match="dump:dataType" mode="heading-content">
    <t:call-template name="prefix-datatype"/>
    <t:apply-templates select="self::node ()" mode="human-module-name"/>
  </t:template>
  <t:template match="dump:dataType | dump:moduleGroup" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:label">
      <t:apply-templates select="child::dump:label" mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:fullName">
      <t:apply-templates select="child::dump:fullName" mode="human-module-name"/>
    </t:when>
    <t:when test="@dump:localName">
      <t:apply-templates select="@dump:localName" mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:dataType | dump:moduleGroup" mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <t:choose>
    <t:when test="child::dump:label">
      <t:apply-templates select="child::dump:label" mode="human-module-name-text"/>
    </t:when>
    <t:when test="child::dump:fullName">
      <t:apply-templates select="child::dump:fullName"
          mode="human-module-name-text"/>
    </t:when>
    <t:when test="@dump:localName">
      <t:apply-templates select="@dump:localName" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:dataType | dump:moduleGroup" mode="human-module-name-attr">
    <t:choose>
    <t:when test="child::dump:label">
      <t:apply-templates select="child::dump:label"
          mode="human-module-name-attr"/>
    </t:when>
    <t:when test="child::dump:fullName">
      <t:apply-templates select="child::dump:fullName"
          mode="human-module-name-attr"/>
    </t:when>
    <t:when test="@dump:localName">
      <t:apply-templates select="@dump:localName" mode="human-module-name-attr"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-attr"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous-attr"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:dataType" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
    </dd>
  </t:template>
  <t:template match="dump:dataType" mode="li">
    <t:param name="short" select="false ()"/>
    <t:param name="ddoct:basePath" select="''"/>
    <li>
      <t:apply-templates select="self::node ()" mode="ref">
        <t:with-param name="short" select="$short"/>
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
    </li>
  </t:template>
  <t:template match="dump:dataType" mode="ref">
    <t:param name="short" select="false ()"/>
    <t:param name="ddoct:basePath" select="''"/>
    <a class="dump-ref dump-ref-data-type">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </a>
  </t:template>
  
  <t:template match="dump:dataType" mode="doc">
    <html class="dump-data-type-doc">
      <t:call-template name="global-lang-attr"/>
      <head>
        <t:apply-templates select="self::node ()" mode="doc-head-common"/>
        <title>
          <t:call-template name="prefix-datatype-attr"/>
          <t:apply-templates select="self::node ()" mode="human-module-name-attr"/>
        </title>
      </head>
      <body>
        <t:apply-templates select="self::node ()" mode="h1b"/>
      </body>
    </html>
  </t:template>
  <t:template match="dump:dataType" mode="file-name">
    <t:if test="@dump:filePathStem">
      <t:value-of select="@dump:filePathStem"/>
      <t:value-of select="$lang-suffix"/>
      <t:value-of select="$html-type-suffix"/>
    </t:if>
  </t:template>
  <t:template match="dump:dataType" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="self::node ()" mode="file-name"/>
  </t:template>
  
  <t:template match="*" mode="dl-superclasses">
    <!-- todo -->
  </t:template>
  
  <t:template match="dump:constGroup" mode="h2">
    <div>
      <t:attribute name="class">
        <t:text>section</t:text>
        <t:if test="string (@dump:access) = 'private'"> dump-access-private</t:if>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <t:apply-templates select="self::node ()" mode="h2-heading"/>
      <t:apply-templates select="child::dump:description"/>
      <dl class="dump-info dump-info-const-group">
        <t:apply-templates select="child::dump:perlName" mode="dl"/>
        <t:apply-templates select="self::node ()" mode="dl-examples"/>
        <t:if test="child::dump:const">
          <dt><t:call-template name="label-consts"/></dt>
          <dd>
            <dl class="dump-children dump-children-const">
              <t:apply-templates select="child::dump:const" mode="dl"/>
            </dl>
          </dd>
        </t:if>
      </dl>
    </div>
  </t:template>
  <t:template match="dump:constGroup" mode="heading-content">
    <t:call-template name="prefix-const-group"/>
    <t:apply-templates select="self::node ()" mode="human-module-title"/>
  </t:template>
  
  <t:template match="dump:constGroup" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <a class="dump-ref dump-ref-const-group">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </a>
  </t:template>
  <t:template match="dump:constGroup" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
      <t:if test="@dump:ref">
        <t:call-template name="suffix-inherited"/>
      </t:if>
    </dd>
  </t:template>
  <t:template match="dump:constGroup" mode="human-module-title">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName" mode="human-module-title"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-title"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:constGroup" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName" mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:constGroup" mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName"
          mode="human-module-name-text"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:constGroup" mode="id">
    <t:if test="child::dump:perlName">
      <t:value-of select="'const-group-'"/>
      <t:value-of select="child::dump:perlName"/>
    </t:if>
  </t:template>
  <t:template match="dump:constGroup" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="parent::dump:*" mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="id"/>
  </t:template>
  
  <t:template match="dump:class/dump:constGroup" mode="dl-examples">
    <dt><t:call-template name="label-examples"/></dt>
    <dd>
      <div class="example has-caption">
        <div class="caption">
          <t:call-template name="label-exports-const-group"/>
        </div>
        <pre><code class="perl" lang="en" xml:lang="en">use <t:apply-templates
        select="parent::*/parent::dump:module/child::dump:perlPackageName"
        mode="human-module-name"/> qw/:<t:apply-templates
        select="child::dump:perlName"
        mode="human-module-name"/>/;</code></pre>
      </div>
    </dd>
  </t:template>
  
  <t:template match="dump:const" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <a class="dump-ref dump-ref-const">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text"/>
    </a>
  </t:template>
  <t:template match="dump:const" mode="human-module-name-text">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName"
          mode="human-module-name-text"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:const" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName"
          mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:const" mode="id">
    <t:if test="child::dump:perlName">
      <t:value-of select="'const-'"/>
      <t:value-of select="child::dump:perlName"/>
    </t:if>
  </t:template>
  <t:template match="dump:const" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="parent::dump:constGroup/parent::dump:*" mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="id"/>
  </t:template>
  <t:template match="dump:const" mode="dl">
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <dfn>
        <t:apply-templates select="self::node ()" mode="human-module-name"/>
      </dfn>
      <t:call-template name="label-sep"/>
      <t:apply-templates select="self::node ()" mode="human-datatype-name">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
      </t:apply-templates>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <t:apply-templates select="self::node ()" mode="examples"/>
      <t:apply-templates select="self::node ()" mode="xsubcodes"/>
    </dd>
  </t:template>
  
  <t:template match="dump:class/dump:constGroup/dump:const" mode="examples">
    <div class="example has-caption">
      <div class="caption">
        <t:call-template name="label-exports-const"/>
      </div>
      <pre><code class="perl" lang="en" xml:lang="en">use <t:apply-templates
        select="parent::dump:constGroup/parent::*/parent::dump:module
                /child::dump:perlPackageName"
        mode="human-module-name"/> qw/<t:apply-templates select="child::dump:perlName"
        mode="human-module-name"/>/;</code></pre>
    </div>
  </t:template>
  
  <t:template match="dump:const" mode="xsubcodes">
    <t:if test="child::dump:exceptionSubCode">
      <dl class="dump-children dump-children-exception-sub-code">
        <dt><t:call-template name="label-exception-sub-code"/></dt>
        <dd>
          <dl>
            <t:apply-templates select="child::dump:exceptionSubCode" mode="dl"/>
          </dl>
        </dd>
      </dl>
    </t:if>
  </t:template>
  
  <t:template match="dump:exceptionSubCode" mode="dl">
    <dt>
      <dfn>
        <t:apply-templates select="self::node ()" mode="human-module-name"/>
      </dfn>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <t:apply-templates select="self::node ()" mode="examples"/>
    </dd>
  </t:template>
  <t:template match="dump:exceptionSubCode" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <a class="dump-ref dump-ref-exception-sub-code">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </a>
  </t:template>
  <t:template match="dump:exceptionSubCode" mode="human-module-name">
    <t:choose>
    <t:when test="@dump:localName">
      <t:apply-templates select="@dump:localName" mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:exceptionSubCode" mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <t:choose>
    <t:when test="@dump:localName">
      <t:apply-templates select="@dump:localName" mode="human-module-name-text">
        <t:with-param name="short" select="$short"/>
      </t:apply-templates>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:exceptionSubCode" mode="id">
    <t:if test="@dump:localName">
      <t:value-of select="'xsubtype-'"/>
      <t:value-of select="@dump:localName"/>
    </t:if>
  </t:template>
  <t:template match="dump:exceptionSubCode" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates
        select="parent::dump:const/parent::dump:constGroup/parent::dump:*"
        mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="id"/>
  </t:template>
  
  <t:template match="dump:method" mode="h2">
    <div>
      <t:attribute name="class">
        <t:text>section</t:text>
        <t:if test="string (@dump:access) = 'private'"> dump-access-private</t:if>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <t:apply-templates select="self::node ()" mode="h2-heading"/>
      <t:apply-templates select="child::dump:description"/>
      <dl class="dump-info dump-info-method">
        <t:apply-templates select="child::dump:perlName" mode="dl"/>
        <t:apply-templates select="self::node ()" mode="dl-parameters"/>
        <t:apply-templates select="self::node ()" mode="dl-return-value"/>
        <t:apply-templates select="self::node ()" mode="dl-exceptions"/>
        <t:apply-templates select="self::node ()" mode="dl-overrides-implements"/>
        <t:apply-templates select="self::node ()" mode="dl-examples"/>
      </dl>
    </div>
  </t:template>
  <t:template match="dump:method" mode="h4">
    <div>
      <t:attribute name="class">
        <t:text>section</t:text>
        <t:if test="string (@dump:access) = 'private'"> dump-access-private</t:if>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="h4-heading"/>
      <t:apply-templates select="child::dump:description"/>
      <dl class="dump-info dump-info-method">
        <t:apply-templates select="child::dump:perlName" mode="dl"/>
        <t:apply-templates select="self::node ()" mode="dl-parameters"/>
        <t:apply-templates select="self::node ()" mode="dl-return-value"/>
        <t:apply-templates select="self::node ()" mode="dl-exceptions"/>
        <t:apply-templates select="self::node ()" mode="dl-overrides-implements"/>
        <t:apply-templates select="self::node ()" mode="dl-examples"/>
      </dl>
    </div>
  </t:template>
  <t:template match="dump:method" mode="heading-content">
    <t:call-template name="prefix-method"/>
    <t:apply-templates select="self::node ()" mode="human-module-title"/>
  </t:template>
  <t:template match="dump:method" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <t:param name="with-class" select="false ()"/>
    <a class="dump-ref dump-ref-method">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <code class="perl">
        <t:if test="$with-class">
          <var>
            <t:apply-templates select="parent::dump:*" mode="human-module-name-text">
              <t:with-param name="short" select="$short"/>
            </t:apply-templates>
            <t:value-of select="'->'"/>
          </var>
        </t:if>
        <t:apply-templates select="self::node ()" mode="human-module-name-text"/>
      </code>
    </a>
  </t:template>
  <t:template match="dump:method[@dump:ref] | dump:attribute[@dump:ref] |
                     dump:constGroup[@dump:ref]" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <t:param name="with-class" select="false ()"/>
    <t:param name="def"
        select="$anyClass/child::dump:*[local-name () = local-name (current ())]
                [child::dump:uri/@dump:uri = string (current ()/@dump:ref)]"/>
    <t:apply-templates select="$def" mode="ref">
      <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      <t:with-param name="short" select="$short"/>
      <t:with-param name="with-class" select="$with-class"/>
    </t:apply-templates>
  </t:template>
  <t:template match="dump:method" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
      <t:if test="@dump:access = 'private'">
        <t:call-template name="suffix-private"/>
      </t:if>
    </dd>
  </t:template>
  <t:template match="dump:method[@dump:ref]" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="def"
        select="$anyClass/child::dump:*[local-name () = local-name (current ())]
                [child::dump:uri/@dump:uri = string (current ()/@dump:ref)]"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
        <t:with-param name="def" select="$def"/>
      </t:apply-templates>
      <t:choose>
      <t:when test="$def/@dump:access = 'private'">
        <t:call-template name="suffix-inherited-private"/>
      </t:when>
      <t:otherwise>
        <t:call-template name="suffix-inherited"/>
      </t:otherwise>
      </t:choose>
    </dd>
  </t:template>
  <t:template match="dump:method" mode="human-module-title">
    <t:choose>
    <t:when test="child::dump:perlName">
      <code class="perl">
        <t:apply-templates select="child::dump:perlName" mode="human-module-title"/>
        <t:value-of select="' ('"/>
        <t:choose>
        <t:when test="child::dump:param[position () = 1][@dump:isNamedParameter]">
          <t:apply-templates select="self::node ()" mode="named-params-param"/>
        </t:when>
        <t:otherwise>
          <t:apply-templates select="child::dump:param[position () = 1]"
              mode="human-module-title"/>
          <t:for-each select="child::dump:param[position () != 1]
                                               [not (@dump:isNamedParameter)]">
            <t:value-of select="', '"/>
            <t:apply-templates select="self::node ()" mode="human-module-title"/>
          </t:for-each>
          <t:if test="child::dump:param/@dump:isNamedParameter">
            <t:value-of select="', '"/>
            <t:apply-templates select="self::node ()" mode="named-params-param"/>
          </t:if>
        </t:otherwise>
        </t:choose>
        <t:value-of select="')'"/>
      </code>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-title"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:method" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName" mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:method" mode="human-module-name-text">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName"
          mode="human-module-name-text"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:method" mode="dl-parameters">
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
  </t:template>
  <t:template match="dump:method" mode="dl-return-value">
    <t:choose>
    <t:when test="child::dump:return/@dump:dataType">
      <dt><t:call-template name="label-return-value"/></dt>
      <dd>
        <dl class="dump-children dump-children-return">
          <dt>
            <t:apply-templates select="child::dump:return"
                mode="human-datatype-name">
              <t:with-param name="ddoct:basePath">
                <t:apply-templates select="self::node ()" mode="base-path"/>
              </t:with-param>
            </t:apply-templates>
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
  </t:template>
  <t:template match="dump:method" mode="dl-exceptions">
    <t:choose>
    <t:when test="child::dump:return/child::dump:raises">
      <dt><t:call-template name="label-exceptions"/></dt>
      <dd>
        <dl class="dump-children dump-children-raises">
          <t:apply-templates select="child::dump:return/child::dump:raises"
              mode="dl"/>
        </dl>
      </dd>
    </t:when>
    <t:otherwise>
      <dt><t:call-template name="label-no-exception"/></dt>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:method" mode="id">
    <t:if test="child::dump:perlName">
      <t:value-of select="'method-'"/>
      <t:value-of select="child::dump:perlName"/>
    </t:if>
  </t:template>
  <t:template match="dump:method" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="parent::dump:*" mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="id"/>
  </t:template>
  <t:template match="dump:method | dump:attribute" mode="dl-overrides-implements">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <t:if test="child::dump:overrides">
      <dt><t:call-template name="label-member-overrides"/></dt>
      <dd class="dump-member-overrides">
        <t:apply-templates select="child::dump:overrides[position () = 1]">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
        <t:for-each select="child::dump:overrides[position () != 1]">
          <t:call-template name="label-sep"/>
          <t:apply-templates select="self::node ()">
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
          </t:apply-templates>
        </t:for-each>
      </dd>
    </t:if>
    <t:if test="child::dump:implements">
      <dt><t:call-template name="label-member-implements"/></dt>
      <dd class="dump-member-implements">
        <t:apply-templates select="child::dump:implements[position () = 1]">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
        <t:for-each select="child::dump:implements[position () != 1]">
          <t:call-template name="label-sep"/>
          <t:apply-templates select="self::node ()">
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
          </t:apply-templates>
        </t:for-each>
      </dd>
    </t:if>
  </t:template>
  <t:template match="dump:method" mode="named-params-param">
    <code class="perl" lang="en" xml:lang="en">%named_params</code>
  </t:template>
  <t:template match="dump:method" mode="named-params-param-ref">
    <t:param name="ddoct:basePath" select="''"/>
    <a>
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="named-params-param-uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="named-params-param"/>
    </a>
  </t:template>
  <t:template match="dump:method" mode="named-params-param-id">
    <t:if test="child::dump:perlName">
      <t:apply-templates select="self::node ()" mode="id"/>
      <t:value-of select="'-param-named_params'"/>
    </t:if>
  </t:template>
  <t:template match="dump:method" mode="named-params-param-id-attr">
    <t:attribute name="id">
      <t:apply-templates select="self::node ()" mode="named-params-param-id"/>
    </t:attribute>
  </t:template>
  <t:template match="dump:method" mode="named-params-param-uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="parent::dump:*" mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="named-params-param-id"/>
  </t:template>
  
  <t:template match="dump:attribute" mode="h2">
    <div>
      <t:attribute name="class">
        <t:text>section</t:text>
        <t:if test="string (@dump:access) = 'private'"> dump-access-private</t:if>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <t:apply-templates select="self::node ()" mode="h2-heading"/>
      <t:apply-templates select="self::node ()" mode="hb"/>
    </div>
  </t:template>
  <t:template match="dump:attribute" mode="h4">
    <div>
      <t:attribute name="class">
        <t:text>section</t:text>
        <t:if test="string (@dump:access) = 'private'"> dump-access-private</t:if>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="h4-heading"/>
      <t:apply-templates select="self::node ()" mode="hb"/>
    </div>
  </t:template>
  
  <t:template match="dump:attribute" mode="hb">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <t:apply-templates select="child::dump:description"/>
    <dl class="dump-info dump-info-attribute">
      <t:apply-templates select="child::dump:perlName" mode="dl"/>
      <t:choose>
      <t:when test="@dump:isReadOnly">
        <dt><t:call-template name="label-no-parameter"/></dt>
        <dt><t:call-template name="label-return-value"/></dt>
          <dd>
            <dl class="dump-children dump-children-return">
              <dt>
                <t:apply-templates select="child::dump:get"
                    mode="human-datatype-name">
                  <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
                </t:apply-templates>
              </dt>
              <dd><t:apply-templates select="child::dump:get"
                  mode="value-description"/></dd>
            </dl>
          </dd>
      </t:when>
      <t:otherwise>
        <dt><t:call-template name="label-parameters"/></dt>
          <dd>
            <dl class="dump-children dump-children-param">
              <dt>
                <t:apply-templates select="self::node ()"
                    mode="new-value-param-id-attr"/>
                <t:apply-templates select="self::node ()" mode="new-value-param"/>
                <t:call-template name="label-sep"/>
                <t:apply-templates select="child::dump:set"
                    mode="human-datatype-name">
                  <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
                </t:apply-templates>
                <t:call-template name="label-sep"/>
                <t:call-template name="label-param-is-optional"/>
              </dt>
              <dd><t:apply-templates select="child::dump:set"
                  mode="value-description"/></dd>
            </dl>
          </dd>
        <dt><t:call-template name="label-return-value"/></dt>
          <dd>
            <dl class="dump-children dump-children-return">
              <dt>
                <t:apply-templates select="child::dump:get"
                    mode="human-datatype-name">
                  <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
                </t:apply-templates>
              </dt>
              <dd>
                <p>
                  <t:call-template name="if-is-not-specified">
                    <t:with-param name="param">
                      <t:apply-templates select="self::node ()"
                        mode="new-value-param-ref">
                        <t:with-param name="ddoct:basePath"
                            select="$ddoct:basePath"/>
                      </t:apply-templates>
                    </t:with-param>
                  </t:call-template>
                  <t:apply-templates select="child::dump:get"
                      mode="value-description"/>
                </p>
              </dd>
              <dt><t:call-template name="label-no-return-value-short"/></dt>
              <dd>
                <p>
                  <t:call-template name="if-is-specified">
                    <t:with-param name="param">
                      <t:apply-templates select="self::node ()"
                          mode="new-value-param-ref">
                        <t:with-param name="ddoct:basePath"
                            select="$ddoct:basePath"/>
                      </t:apply-templates>
                    </t:with-param>
                  </t:call-template>
                </p>
              </dd>
            </dl>
          </dd>
      </t:otherwise>
      </t:choose>
      <t:apply-templates select="self::node ()" mode="dl-exceptions"/>
      <t:apply-templates select="self::node ()" mode="dl-overrides-implements"/>
      <t:apply-templates select="self::node ()" mode="dl-examples"/>
    </dl>
  </t:template>
  <t:template match="dump:attribute" mode="h2-heading">
    <h2><t:apply-templates select="self::node ()" mode="heading-content"/></h2>
  </t:template>
  <t:template match="dump:attribute" mode="h4-heading">
    <h4><t:apply-templates select="self::node ()" mode="heading-content"/></h4>
  </t:template>
  <t:template match="dump:attribute" mode="heading-content">
    <t:call-template name="prefix-attribute"/>
    <t:apply-templates select="self::node ()" mode="human-module-title"/>
  </t:template>
  <t:template match="dump:attribute" mode="human-module-title">
    <t:choose>
    <t:when test="child::dump:perlName">
      <code class="perl">
        <t:apply-templates select="child::dump:perlName" mode="human-module-title"/>
        <t:value-of select="' ('"/>
        <t:if test="not (@dump:isReadOnly)">
          <code class="perl" lang="en" xml:lang="en">$new_value</code>
        </t:if>
        <t:value-of select="')'"/>
      </code>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-title"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:attribute" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName" mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:attribute" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="with-class" select="false ()"/>
    <t:param name="short" select="false ()"/>
    <a class="dump-ref dump-ref-attribute">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <code class="perl">
        <t:if test="$with-class">
          <var>
            <t:apply-templates select="parent::dump:*" mode="human-module-name-text">
              <t:with-param name="short" select="$short"/>
            </t:apply-templates>
          </var>
          <t:value-of select="'->'"/>
        </t:if>
        <t:apply-templates select="self::node ()" mode="human-module-name-text"/>
      </code>
    </a>
  </t:template>
  <t:template match="dump:attribute" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
      <t:choose>
      <t:when test="@dump:isReadOnly">
        <t:call-template name="suffix-read-only-attr"/>
      </t:when>
      <t:otherwise>
        <t:call-template name="suffix-attr"/>
      </t:otherwise>
      </t:choose>
      <t:if test="@dump:ref">
        <t:call-template name="suffix-inherited"/>
      </t:if>
      <t:if test="@dump:access = 'private'">
        <t:call-template name="suffix-private"/>
      </t:if>
    </dd>
  </t:template>
  <t:template match="dump:attribute[@dump:ref]" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="def"
        select="$anyClass/child::dump:*[local-name () = local-name (current ())]
                [child::dump:uri/@dump:uri = string (current ()/@dump:ref)]"/>
    <dd>
      <t:apply-templates select="self::node ()" mode="ref">
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
        <t:with-param name="def" select="$def"/>
      </t:apply-templates>
      <t:choose>
      <t:when test="$def/@dump:isReadOnly">
        <t:call-template name="suffix-read-only-attr"/>
      </t:when>
      <t:otherwise>
        <t:call-template name="suffix-attr"/>
      </t:otherwise>
      </t:choose>
      <t:choose>
      <t:when test="$def/@dump:access = 'private'">
        <t:call-template name="suffix-inherited-private"/>
      </t:when>
      <t:otherwise>
        <t:call-template name="suffix-inherited"/>
      </t:otherwise>
      </t:choose>
    </dd>
  </t:template>
  <t:template match="dump:attribute" mode="human-module-name-text">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName"
          mode="human-module-name-text"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:attribute" mode="dl-exceptions">
    <t:choose>
    <t:when test="child::dump:get/child::dump:raises or
                  child::dump:set/child::dump:raises">
      <dt><t:call-template name="label-exceptions"/></dt>
      <dd>
        <dl class="dump-children dump-children-raises">
          <t:apply-templates
              select="child::dump:get/child::dump:raises |
                      child::dump:set/child::dump:raises" mode="dl"/>
        </dl>
      </dd>
    </t:when>
    <t:otherwise>
      <dt><t:call-template name="label-no-exception"/></dt>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:attribute" mode="id">
    <t:if test="child::dump:perlName">
      <t:value-of select="'attr-'"/>
      <t:value-of select="child::dump:perlName"/>
    </t:if>
  </t:template>
  <t:template match="dump:attribute" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="parent::dump:*" mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="id"/>
  </t:template>
  <t:template match="dump:attribute" mode="new-value-param">
    <code class="perl" lang="en" xml:lang="en">$new_value</code>
  </t:template>
  <t:template match="dump:attribute" mode="new-value-param-ref">
    <t:param name="ddoct:basePath" select="''"/>
    <a>
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="new-value-param-uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="new-value-param"/>
    </a>
  </t:template>
  <t:template match="dump:attribute" mode="new-value-param-id">
    <t:if test="child::dump:perlName">
      <t:apply-templates select="self::node ()" mode="id"/>
      <t:value-of select="'-param-new_value'"/>
    </t:if>
  </t:template>
  <t:template match="dump:attribute" mode="new-value-param-id-attr">
    <t:attribute name="id">
      <t:apply-templates select="self::node ()" mode="new-value-param-id"/>
    </t:attribute>
  </t:template>
  <t:template match="dump:attribute" mode="new-value-param-uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="parent::dump:*" mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="new-value-param-id"/>
  </t:template>
  
  <t:template match="dump:param" mode="dl">
    <dt>
      <t:apply-templates select="self::node ()" mode="id-attr"/>
      <dfn>
        <t:apply-templates select="self::node ()" mode="human-module-name"/>
      </dfn>
      <t:call-template name="label-sep"/>
      <t:apply-templates select="self::node ()" mode="human-datatype-name">
        <t:with-param name="ddoct:basePath">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:with-param>
      </t:apply-templates>
      <t:if test="@dump:isNamedParameter">
        <t:call-template name="label-sep"/>
        <t:call-template name="label-param-is-named"/>
      </t:if>
      <t:if test="@dump:isNullable and
                  not (following-sibling::dump:param[not (@dump:isNullable)])">
        <t:call-template name="label-sep"/>
        <t:call-template name="label-param-is-optional"/>
      </t:if>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <t:apply-templates select="self::node ()" mode="examples"/>
    </dd>
  </t:template>
  <t:template match="dump:param" mode="human-module-name">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName" mode="human-module-name"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:param" mode="human-module-name-text">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName"
          mode="human-module-name-text"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-name-text"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:param" mode="human-module-title">
    <t:choose>
    <t:when test="child::dump:perlName">
      <t:apply-templates select="child::dump:perlName" mode="human-module-title"/>
    </t:when>
    <t:when test="child::dump:uri">
      <t:apply-templates select="child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-title"/>
    </t:when>
    <t:otherwise>
      <t:call-template name="name-anonymous"/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:param/@dump:prefix" mode="human-module-title">
    <t:value-of select="self::node ()"/>
  </t:template>
  <t:template match="dump:param/@dump:prefix" mode="human-module-name">
    <t:value-of select="self::node ()"/>
  </t:template>
  
  <t:template match="dump:param/@dump:isNamedParameter" mode="human-module-title"/>
  
  <t:template match="dump:param" mode="id">
    <t:if test="child::dump:perlName">
      <t:apply-templates select="parent::dump:method" mode="id"/>
      <t:value-of select="'-param-'"/>
      <t:value-of select="child::dump:perlName"/>
    </t:if>
  </t:template>
  <t:template match="dump:param" mode="uri">
    <t:param name="ddoct:basePath" select="''"/>
    <t:copy-of select="$ddoct:basePath"/>
    <t:apply-templates select="parent::dump:method/parent::dump:*" mode="uri"/>
    <t:value-of select="'#'"/>
    <t:apply-templates select="self::node ()" mode="id"/>
  </t:template>
  <t:template match="dump:param" mode="ref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="short" select="false ()"/>
    <a class="dump-ref dump-ref-param">
      <t:attribute name="href">
        <t:apply-templates select="self::node ()" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:apply-templates select="self::node ()" mode="human-module-name-text"/>
    </a>
  </t:template>
  
  <t:template match="dump:raises" mode="dl">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <t:variable name="def"
        select="$anyClass
                [child::dump:uri/@dump:uri = string (current ()/@dump:ref)]"/>
    <dt>
      <t:apply-templates select="$def" mode="ref">
        <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        <t:with-param name="short" select="true ()"/>
      </t:apply-templates>
    </dt>
    <dd>
      <t:choose>
      <t:when test="parent::dump:get and parent::*
                    /parent::dump:attribute/@dump:isReadOnly">
        <p>
          <t:call-template name="if-is-not-specified">
            <t:with-param name="param">
              <t:apply-templates select="parent::node ()/parent::node ()"
                  mode="new-value-param-ref">
                <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
              </t:apply-templates>
            </t:with-param>
          </t:call-template>
        </p>
      </t:when>
      <t:when test="parent::dump:set">
        <p>
          <t:call-template name="if-is-specified">
            <t:with-param name="param">
              <t:apply-templates select="parent::node ()/parent::node ()"
                  mode="new-value-param-ref">
                <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
              </t:apply-templates>
            </t:with-param>
          </t:call-template>
        </p>
      </t:when>
      </t:choose>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <t:apply-templates select="self::node ()" mode="examples"/>
      <t:if test="child::dump:raisesCode">
        <dl class="dump-children dump-children-raises-code">
          <t:apply-templates select="child::dump:raisesCode" mode="dl">
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            <t:with-param name="exception" select="$def"/>
          </t:apply-templates>
        </dl>
      </t:if>
    </dd>
  </t:template>
  
  <t:template match="dump:raisesCode" mode="dl">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <t:param name="exception" select="$anyClass"/>
    <t:variable name="def"
        select="$exception/child::dump:constGroup/child::dump:const
                    [child::dump:uri/@dump:uri = string (current ()/@dump:ref)]"/>
    <dt>
      <t:apply-templates select="$def" mode="ref">
        <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        <t:with-param name="short" select="true ()"/>
      </t:apply-templates>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <t:apply-templates select="self::node ()" mode="examples"/>
      <t:if test="child::dump:raisesSubCode">
        <dl class="dump-children dump-children-raises-sub-code">
          <t:apply-templates select="child::dump:raisesSubCode" mode="dl">
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
            <t:with-param name="exceptionCode" select="$def"/>
          </t:apply-templates>
        </dl>
      </t:if>
    </dd>
  </t:template>
  
  <t:template match="dump:raisesSubCode" mode="dl">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <t:param name="exceptionCode"
        select="$anyClass/child::dump:constGroup/child::dump:const"/>
    <t:variable name="def"
        select="$exceptionCode/child::dump:exceptionSubCode
                    [child::dump:uri/@dump:uri = string (current ()/@dump:ref)]"/>
    <dt>
      <t:apply-templates select="$def" mode="ref">
        <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        <t:with-param name="short" select="true ()"/>
      </t:apply-templates>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
      <t:apply-templates select="self::node ()" mode="examples"/>
    </dd>
  </t:template>
  
  <t:template match="dump:*" mode="human-datatype-name">
    <t:param name="ddoct:basePath" select="''"/>
    <t:call-template name="prefix-datatype"/>
    <t:apply-templates select="@dump:dataType" mode="human-datatype-name">
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
    <t:if test="string (@dump:dataType) != string (@dump:actualDataType)">
      <t:value-of select="' ('"/>
      <t:apply-templates select="@dump:actualDataType" mode="human-datatype-name">
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
      <t:value-of select="')'"/>
    </t:if>
  </t:template>
  
  <t:template match="@dump:dataType | @dump:actualDataType | ddel:*/@dump:uri"
      mode="human-datatype-name">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="dataTypeDefParentA"
        select="/child::dump:moduleSet/child::dump:module"/>
    <t:variable name="dataTypeDefParentB"
        select="$dataTypeDefParentA/child::dump:class |
                $dataTypeDefParentA/child::dump:interface"/>
    <t:variable name="dataTypeDef"
        select="($dataTypeDefParentA/child::dump:class |
                 $dataTypeDefParentA/child::dump:interface |
                 $dataTypeDefParentA/child::dump:dataType |
                 $dataTypeDefParentB/child::dump:constGroup)[
          child::dump:uri/@dump:uri = string (current ())
        ]"/>
    <t:choose>
    <t:when test="$dataTypeDef">
      <t:apply-templates select="$dataTypeDef[position () = 1]" mode="ref">
        <t:with-param name="short" select="true ()"/>
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
    <t:when test="$dataTypeDef/child::dump:uri">
      <t:apply-templates select="$dataTypeDef/child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-title"/>
    </t:when>
    <t:otherwise>
      <code class="uri" lang="en" xml:lang="en"
      >&lt;<a href="{string (self::node ())}">
        <t:value-of select="string (self::node ())"/>
      </a>&gt;</code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="dump:*" mode="doc-head-common">
    <link rel="stylesheet" media="all">
      <t:attribute name="href">
        <t:if test="$is-html-style-sheet-uri-relative">
          <t:apply-templates select="self::node ()" mode="base-path"/>
        </t:if>
        <t:value-of select="$html-style-sheet-uri"/>
      </t:attribute>
    </link>
  </t:template>
  
  <t:template match="dump:*" mode="heading">
    <t:param name="rank" select="1"/>
    <t:param name="docType" select="/parent::node ()"/>
    <t:param name="number" select="/parent::node ()"/>
    <t:choose>
    <t:when test="$rank = 1">
      <h1>
        <t:apply-templates select="self::node ()" mode="heading-content">
          <t:with-param name="rank" select="$rank"/>
          <t:with-param name="docType" select="$docType"/>
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </h1>
    </t:when>
    <t:when test="$rank = 2">
      <h2>
        <t:apply-templates select="self::node ()" mode="heading-content">
          <t:with-param name="rank" select="$rank"/>
          <t:with-param name="docType" select="$docType"/>
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </h2>
    </t:when>
    <t:when test="$rank = 3">
      <h3>
        <t:apply-templates select="self::node ()" mode="heading-content">
          <t:with-param name="rank" select="$rank"/>
          <t:with-param name="docType" select="$docType"/>
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </h3>
    </t:when>
    <t:when test="$rank = 4">
      <h4>
        <t:apply-templates select="self::node ()" mode="heading-content">
          <t:with-param name="rank" select="$rank"/>
          <t:with-param name="docType" select="$docType"/>
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </h4>
    </t:when>
    <t:when test="$rank = 5">
      <h5>
        <t:apply-templates select="self::node ()" mode="heading-content">
          <t:with-param name="rank" select="$rank"/>
          <t:with-param name="docType" select="$docType"/>
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </h5>
    </t:when>
    <t:otherwise>
      <h6>
        <t:apply-templates select="self::node ()" mode="heading-content">
          <t:with-param name="rank" select="$rank"/>
          <t:with-param name="docType" select="$docType"/>
          <t:with-param name="number" select="$number"/>
        </t:apply-templates>
      </h6>
    </t:otherwise>
    </t:choose>
  </t:template>
  <t:template match="dump:*" mode="h1-heading">
    <h1><t:apply-templates select="self::node ()" mode="heading-content"/></h1>
  </t:template>
  <t:template match="dump:*" mode="h2-heading">
    <h2><t:apply-templates select="self::node ()" mode="heading-content"/></h2>
  </t:template>
  <t:template match="dump:*" mode="h3-heading">
    <h3><t:apply-templates select="self::node ()" mode="heading-content"/></h3>
  </t:template>
  <t:template match="dump:*" mode="h4-heading">
    <h4><t:apply-templates select="self::node ()" mode="heading-content"/></h4>
  </t:template>

  <t:template match="dump:*" mode="value-description">
    <t:apply-templates select="child::dump:description"/>
    <t:if test="child::dump:case">
      <dl class="dump-children dump-children-case">
        <t:apply-templates select="child::dump:case" mode="dl"/>
      </dl>
    </t:if>
  </t:template>
  
  <t:template match="dump:case" mode="dl">
    <t:param name="ddoct:basePath">
      <t:apply-templates select="self::node ()" mode="base-path"/>
    </t:param>
    <dt>
      <t:choose>
      <t:when test="child::dump:label">
        <t:apply-templates select="child::dump:label"/>
      </t:when>
      <t:when test="child::dump:fullName">
        <t:apply-templates select="child::dump:fullName"/>
      </t:when>
      <t:when test="child::dump:value">
        <t:apply-templates select="child::dump:value"/>
      </t:when>
      </t:choose>
      <t:if test="string (@dump:dataType) !=
                  string (parent::node ()/@dump:dataType) or
                  string (@dump:actualDataType) !=
                  string (parent::node ()/@dump:actualDataType) or
                  not (child::dump:label | child::dump:value |
                       child::dump:fullName)">
        <t:if test="child::dump:label | child::dump:value | child::dump:fullName">
          <t:call-template name="label-sep"/>
        </t:if>
        <t:choose>
        <t:when test="string (@dump:dataType) =
                      string (parent::node ()/@dump:dataType)">
          <t:apply-templates select="@actualDataType" mode="human-datatype-name">
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
          </t:apply-templates>
        </t:when>
        <t:otherwise>
          <t:apply-templates select="self::node ()" mode="human-datatype-name">
            <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
          </t:apply-templates>
        </t:otherwise>
        </t:choose>
      </t:if>
    </dt>
    <dd>
      <t:apply-templates select="self::node ()" mode="value-description"/>
    </dd>
  </t:template>
  
  <t:template match="dump:value">
    <code class="perl" lang="en" xml:lang="en">
      <t:apply-templates/>
    </code>
  </t:template>

  <t:template match="dump:uri" mode="dl">
    <dt><t:call-template name="label-uri"/></dt>
    <dd><t:apply-templates select="self::node ()" mode="human-module-name"/></dd>
  </t:template>
  <t:template match="dump:uri[preceding-sibling::dump:uri]" mode="dl">
    <dd><t:apply-templates select="self::node ()" mode="human-module-name"/></dd>
  </t:template>
  
  <t:template match="dump:uri" mode="human-module-title">
    <code class="uri" lang="en" xml:lang="en">&lt;<a
    href="{string (@dump:uri)}"><t:value-of select="@dump:uri"/></a>&gt;</code>
  </t:template>
  
  <t:template match="dump:uri | dump:turi | dump:furi | dump:puri"
      mode="human-module-name">
    <code class="uri" lang="en" xml:lang="en">&lt;<a
    href="{string (@dump:uri)}"><t:value-of select="@dump:uri"/></a>&gt;</code>
  </t:template>
  
  <t:template match="dump:uri | dump:turi | dump:furi | dump:puri"
      mode="human-module-name-text">
    <code class="uri" lang="en" xml:lang="en">&lt;<t:value-of
    select="@dump:uri"/>&gt;</code>
  </t:template>
  <t:template match="dump:uri[@dump:uriType = 'tf']" mode="human-module-name-text">
    <t:value-of select="' ('"/>
    <t:apply-templates select="child::dump:turi"
            mode="human-module-name-text"/>
    <t:value-of select="', '"/>
    <t:apply-templates select="child::dump:furi"
            mode="human-module-name-text"/>
    <t:value-of select="') '"/>
  </t:template>
  
  <t:template match="dump:uri" mode="human-module-name-attr"
    >&lt;<t:apply-templates mode="attr"/>&gt;</t:template
  >
  
  <t:template match="dump:perlPackageName" mode="dl">
    <dt><t:call-template name="label-perl-package-name"/></dt>
    <dd><t:apply-templates select="self::node ()" mode="human-module-name"/></dd>
  </t:template>
  <t:template match="dump:module/dump:perlPackageName" mode="dl">
    <dt><t:call-template name="label-perl-module-name"/></dt>
    <dd><t:apply-templates select="self::node ()" mode="human-module-name"/></dd>
  </t:template>
  
  <t:template match="dump:perlPackageName" mode="human-module-name">
    <code class="perl" lang="en" xml:lang="en"><t:apply-templates/></code>
  </t:template>
  <t:template match="dump:perlPackageName" mode="human-module-name-text">
    <code class="perl" lang="en" xml:lang="en"><t:apply-templates/></code>
  </t:template>
  <t:template match="dump:perlPackageName" mode="human-module-name-attr">
    <t:apply-templates mode="attr"/>
  </t:template>
  
  
  <t:template match="dump:perlName" mode="dl">
    <dt><t:call-template name="label-perl-name"/></dt>
    <dd><t:apply-templates select="self::node ()" mode="human-module-name"/></dd>
  </t:template>
  
  <t:template match="dump:perlName" mode="human-module-title">
    <code class="perl" lang="en" xml:lang="en">
      <t:if test="parent::node ()/child::dump:perlPackageName">
        <t:attribute name="title">
          <t:apply-templates select="parent::node ()/child::dump:perlPackageName"
              mode="human-module-name-attr"/>
        </t:attribute>
      </t:if>
      <t:apply-templates/>
    </code>
  </t:template>
  <t:template match="dump:perlName" mode="human-module-name">
    <code class="perl" lang="en" xml:lang="en"><t:apply-templates/></code>
  </t:template>
  <t:template match="dump:perlName" mode="human-module-name-text">
    <code class="perl" lang="en" xml:lang="en">
      <t:if test="parent::node ()/child::dump:perlPackageName">
        <t:attribute name="title">
          <t:apply-templates select="parent::node ()/child::dump:perlPackageName"
              mode="human-module-name-attr"/>
        </t:attribute>
      </t:if>
      <t:apply-templates/>
    </code>
  </t:template>
  
  <t:template match="dump:method/dump:perlName |
                     dump:attribute/dump:perlName" mode="human-module-title">
    <code class="perl" lang="en" xml:lang="en"><var>$object</var
    >-><t:apply-templates/></code>
  </t:template>
  <t:template match="dump:method/dump:perlName |
                     dump:attribute/dump:perlName" mode="human-module-name-text">
    <code class="perl" lang="en" xml:lang="en">
      <t:attribute name="title">
        <t:apply-templates select="parent::node ()/parent::node ()"
            mode="human-module-name-text"/>
        <t:text>::</t:text>
        <t:value-of select="self::node ()"/>
      </t:attribute>
      <t:apply-templates/>
    </code>
  </t:template>
  
  <t:template match="dump:constGroup/dump:perlName" mode="human-module-title">
    <code class="perl" lang="en" xml:lang="en">:<t:apply-templates/></code>
  </t:template>
  
  <t:template match="dump:param/dump:perlName" mode="human-module-title">
    <code class="perl" lang="en" xml:lang="en"><var>
      <t:if test="not (parent::node ()/@dump:isNamedParameter)">
        <t:apply-templates select="parent::node ()/@dump:prefix"
            mode="human-module-title"/>
      </t:if>
      <t:apply-templates/>
    </var></code>
  </t:template>
  <t:template match="dump:param/dump:perlName" mode="human-module-name">
    <code class="perl" lang="en" xml:lang="en"><var>
      <t:if test="not (parent::node ()/@dump:isNamedParameter)">
        <t:apply-templates select="parent::node ()/@dump:prefix"
            mode="human-module-name"/>
      </t:if>
      <t:apply-templates/>
    </var></code>
  </t:template>
  <t:template match="dump:param/dump:perlName" mode="human-module-name-text">
    <code class="perl" lang="en" xml:lang="en"><var>
      <t:if test="not (parent::node ()/@dump:isNamedParameter)">
        <t:apply-templates select="parent::node ()/@dump:prefix"
            mode="human-module-name"/>
      </t:if>
      <t:apply-templates/>
    </var></code>
  </t:template>
  
  <t:template match="@dump:localName" mode="human-module-name">
    <code lang="en" xml:lang="en">
      <t:if test="parent::node ()/@dump:namespaceURI">
        <code class="uri">&lt;<a href="{parent::node ()/@dump:namespaceURI}">
          <t:value-of select="parent::node ()/@dump:namespaceURI"/>
        </a>&gt;</code>
      </t:if>
      <t:value-of select="self::node ()"/>
    </code>
  </t:template>
  <t:template match="@dump:localName" mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <code lang="en" xml:lang="en">
      <t:if test="parent::node ()/@dump:namespaceURI">
        <t:choose>
        <t:when test="$short">
          <t:attribute name="title">&lt;<t:value-of
              select="parent::node ()/@dump:namespaceURI"/>&gt;</t:attribute>
        </t:when>
        <t:otherwise>
          <code class="uri">&lt;<t:value-of
              select="parent::node ()/@dump:namespaceURI"/>&gt;</code>
        </t:otherwise>
        </t:choose>
      </t:if>
      <t:value-of select="self::node ()"/>
    </code>
  </t:template>
  <t:template match="@dump:localName" mode="human-module-name-attr">
    <t:if test="parent::node ()/@dump:namespaceURI">&lt;<t:value-of
        select="parent::node ()/@dump:namespaceURI"/>&gt;</t:if>
    <t:value-of select="self::node ()"/>
  </t:template>

  <t:template match="dump:exceptionSubCode/@dump:localName" mode="human-module-name">
    <code lang="en" xml:lang="en">
      <t:choose>
      <t:when test="parent::node ()/@dump:namespaceURI">
        <t:attribute name="class">uri</t:attribute>
        <t:text>&lt;</t:text>
        <a href="{parent::node ()/@dump:namespaceURI}{string (self::node ())}">
          <t:value-of select="parent::node ()/@dump:namespaceURI"/>
          <t:value-of select="self::node ()"/>
        </a>
        <t:text>&gt;</t:text>
      </t:when>
      <t:otherwise>
        <t:attribute name="class">DOM</t:attribute>
        <t:value-of select="self::node ()"/>
      </t:otherwise>
      </t:choose>
    </code>
  </t:template>
  <t:template match="dump:exceptionSubCode/@dump:localName"
      mode="human-module-name-text">
    <t:param name="short" select="false ()"/>
    <code lang="en" xml:lang="en">
      <t:choose>
      <t:when test="parent::node ()/@dump:namespaceURI">
        <t:choose>
        <t:when test="$short">
          <t:attribute name="class">DOM</t:attribute>
          <t:attribute name="title">&lt;<t:value-of
              select="parent::node ()/@dump:namespaceURI"
              /><t:value-of select="self::node ()"/>&gt;</t:attribute>
        </t:when>
        <t:otherwise>
          <t:attribute name="class">uri</t:attribute>
          <t:text>&lt;</t:text>
          <t:value-of select="parent::node ()/@dump:namespaceURI"/>
          <t:value-of select="self::node ()"/>
          <t:text>&gt;</t:text>
        </t:otherwise>
        </t:choose>
      </t:when>
      </t:choose>
      <t:value-of select="self::node ()"/>
    </code>
  </t:template>
  <t:template match="dump:exceptionSubCode/@dump:localName"
      mode="human-module-name-attr">
    <t:if test="parent::node ()/@dump:namespaceURI">&lt;<t:value-of
        select="parent::node ()/@dump:namespaceURI"/></t:if>
    <t:value-of select="self::node ()"/>
    <t:if test="parent::node ()/@dump:namespaceURI">&gt;</t:if>
  </t:template>
  
  <t:template match="dump:extends" mode="li">
    <t:param name="ddoct:basePath" select="''"/>
    <li class="dump-extends">
      <t:variable name="referent" select="
        (/child::dump:moduleSet/child::dump:module/child::dump:class |
         /child::dump:moduleSet/child::dump:module/child::dump:interface |
         /child::dump:moduleSet/child::dump:module/child::dump:dataType)
        [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]
      "/>
      <t:choose>
      <t:when test="$referent">
        <t:apply-templates select="$referent[position () = 1]" mode="ref">
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
        <t:if test="child::dump:extends">
          <ol class="xoxo dump-extends">
            <t:apply-templates select="child::dump:extends" mode="li">
              <t:with-param name="ddoct:basePath">
                <t:apply-templates select="self::node ()" mode="base-path"/>
              </t:with-param>
            </t:apply-templates>
          </ol>
        </t:if>
      </t:when>
      <t:otherwise>
        <code class="uri">&lt;<a href="{string (@dump:uri)}">
          <t:value-of select="string (@dump:uri)"/>
        </a>&gt;</code>
      </t:otherwise>
      </t:choose>
    </li>
  </t:template>
  
  <t:template match="dump:implements" mode="dd">
    <t:param name="ddoct:basePath" select="''"/>
    <dd class="dump-implements">
      <t:variable name="referent" select="
        /child::dump:moduleSet/child::dump:module/child::dump:interface
        [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]
      "/>
      <t:choose>
      <t:when test="$referent">
        <t:apply-templates select="$referent[position () = 1]" mode="ref">
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
        <t:if test="child::dump:extends">
          <ol class="xoxo dump-extends">
            <t:apply-templates select="child::dump:extends" mode="li">
              <t:with-param name="ddoct:basePath">
                <t:apply-templates select="self::node ()" mode="base-path"/>
              </t:with-param>
            </t:apply-templates>
          </ol>
        </t:if>
      </t:when>
      <t:otherwise>
        <code class="uri">&lt;<a href="{string (@dump:uri)}">
          <t:value-of select="string (@dump:uri)"/>
        </a>&gt;</code>
      </t:otherwise>
      </t:choose>
    </dd>
  </t:template>
  
  <t:template match="dump:overrides |
                     dump:method/dump:implements |
                     dump:attribute/dump:implements |
                     dump:constGroup/dump:implements">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="def"
        select="$anyClass/child::dump:*
                [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]
                [position () = 1]"/>
    <a href="dump-{local-name ()}-ref">
      <t:attribute name="href">
        <t:apply-templates select="$def" mode="uri">
          <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
        </t:apply-templates>
      </t:attribute>
      <t:attribute name="title">
        <t:apply-templates select="$def" mode="human-module-name-attr"/>
      </t:attribute>
      <t:apply-templates select="$def/parent::dump:*" mode="human-module-name-text">
        <t:with-param name="short" select="true ()"/>
      </t:apply-templates>
    </a>
  </t:template>
  
  <t:template match="*" mode="base-path">
    <t:variable name="base" select="ancestor-or-self::*[@ddoct:basePath]
                                       [position () = 1]"/>
    <t:value-of select="$base/@ddoct:basePath"/>
    <t:if test="$base/self::dump:module and $base/@dump:filePathStem">
      <t:value-of select="'../'"/>
    </t:if>
  </t:template>
  
  <t:template match="dump:description">
    <div class="dump-description">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  <t:template match="dump:description[not (child::node ())]"/>
  
  <t:template match="dump:label">
    <span class="dump-label">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </span>
  </t:template>
  <t:template match="dump:label" mode="human-module-title">
    <t:apply-templates select="self::node ()"/>
  </t:template>
  <t:template match="dump:label" mode="human-module-name">
    <t:apply-templates select="self::node ()"/>
  </t:template>
  <t:template match="dump:label" mode="human-module-name-text">
    <t:apply-templates select="self::node ()"/>
  </t:template>
  <t:template match="dump:label" mode="human-module-name-attr">
    <t:apply-templates mode="attr"/>
  </t:template>
  <t:template match="dump:label[not (child::node ())]"/>
  
  <t:template match="dump:fullName">
    <span class="dump-full-name">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </span>
  </t:template>
  <t:template match="dump:fullName" mode="human-module-title">
    <t:apply-templates select="self::node ()"/>
  </t:template>
  <t:template match="dump:fullName" mode="human-module-name">
    <t:apply-templates select="self::node ()"/>
  </t:template>
  <t:template match="dump:fullName" mode="human-module-name-text">
    <t:apply-templates select="self::node ()"/>
  </t:template>
  <t:template match="dump:fullName" mode="human-module-name-attr">
    <t:apply-templates mode="attr"/>
  </t:template>
  <t:template match="dump:fullName[not (child::node ())]"/>
  
  <t:template match="dump:fullName" mode="dl">
    <dt><t:call-template name="label-full-name"/></dt>
    <dd class="dump-full-name">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </dd>
  </t:template>
  
  <t:template match="dump:label" mode="dl">
    <dt><t:call-template name="label-label"/></dt>
    <dd class="dump-label">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </dd>
  </t:template>
  
  <t:template match="ddel:disdocBlocks">
    <div>
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="ddel:disdocBlocks/@dump:isImplNote">
    <t:attribute name="class">ed</t:attribute>
  </t:template>
  
  <t:template match="ddel:disdocInline">
    <span>
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </span>
  </t:template>
  <t:template match="ddel:disdocInline" mode="attr">
    <t:apply-templates mode="attr"/>
  </t:template>
  
  <t:template match="dis:ImplNote">
    <div class="ed">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="@ddel:tag"/>
  <t:template match="@ddel:mmParsed"/>
  
  <t:template match="html5:p | html5:ul | html5:ol | html5:li |
                     html5:em | html5:dfn | html5:code | html5:var |
                     html5:q | html5:cite">
    <t:element name="{local-name ()}">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </t:element>
  </t:template>
  
  <t:template match="html5:ol/html5:li/@ddel:ordered"/>
  
  <t:template match="html5:ul[child::*/ddel:listMarker] |
                     html5:ol[child::*/ddel:listMarker]">
    <t:element name="{local-name ()}">
      <t:apply-templates select="@*"/>
      <t:attribute name="class">has-marker</t:attribute>
      <t:apply-templates select="child::node ()"/>
    </t:element>
  </t:template>
  
  <t:template match="html3:note">
    <div class="{local-name ()} memo">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </div>
  </t:template>
  
  <t:template match="ddel:TODO">
    <div class="todo ed memo">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </div>
  </t:template>
  
  <t:template match="ddel:ISSUE">
    <div class="issue ed memo">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </div>
  </t:template>
  
  <t:template match="ddel:listMarker">
    <span class="marker">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </span>
  </t:template>
  <t:template match="ddel:listContent">
    <span class="list-content">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </span>
  </t:template>
  
  <t:template match="ddel:InfoItem">
    <span class="{local-name ()}">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </span>
  </t:template>
  
  <t:template match="ddel:DOM | ddel:SGML | ddel:XML | ddel:InfoItem">
    <code class="{local-name ()}">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
  </t:template>
  
  <t:template match="ddel:DOM | ddel:SGML | ddel:XML" mode="attr">
    <t:text>|</t:text>
    <t:apply-templates select="child::node ()"/>
    <t:text>|</t:text>
  </t:template>
  
  <t:template match="ddel:DOM[string (self::node ()) = 'null']">
    <code class="perl" lang="en" xml:lang="en" title="null">undef</code>
  </t:template>
  
  <t:template match="ddel:DOM[string (self::node ()) = 'null']" mode="attr"
  >undef</t:template>
  
  <t:template match="ddel:DOM[string (self::node ()) = 'true']">
    <code class="perl" lang="en" xml:lang="en" title="true">1</code>
  </t:template>
  
  <t:template match="ddel:DOM[string (self::node ()) = 'false']">
    <code class="perl" lang="en" xml:lang="en" title="false">0</code>
  </t:template>
  
  <t:template match="ddel:CHAR">
    <code class="charname">
      <t:apply-templates select="@*"/>
      <t:if test="not (@xml:lang)">
        <t:attribute name="lang">en</t:attribute>
        <t:attribute name="xml:lang">en</t:attribute>
      </t:if>
      <t:apply-templates select="child::node ()"/>
    </code>
    
    <t:variable name="name" select="string (self::node ())"/>
    <t:choose>
    <t:when test="$name = 'COLON'">
      <t:text> </t:text>
      (<code class="char">:</code>)
    </t:when>
    <t:when test="$name = 'PLUS SIGN'">
      <t:text> </t:text>
      (<code class="char">+</code>)
    </t:when>
    <t:when test="$name = 'SPACE'">
      <t:text> </t:text>
      (<code class="char" xml:space="preserve"> </code>)
    </t:when>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:Perl | ddel:PerlModule">
    <code class="perl">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
  </t:template>
  
  <t:template match="ddel:Perl[string (self::node ()) = &quot;''&quot;] |
                     dump:value[string (self::node ()) = &quot;''&quot;]">
    <code class="perl">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
    <t:call-template name="suffix-empty-string"/>
  </t:template>
  
  <t:template match="ddel:HE">
    <code class="HTMLe" lang="en" xml:lang="en">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
  </t:template>
  
  <t:template match="ddel:HA">
    <code class="HTMLa" lang="en" xml:lang="en">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
  </t:template>
  
  <t:template match="ddel:URI">
    <code class="uri" lang="en" xml:lang="en">
      <t:apply-templates select="@*"/>
      <t:text>&lt;</t:text>
      <a href="{string (self::node ())}">
        <t:apply-templates select="child::node ()"/>
      </a>
      <t:text>&gt;</t:text>
    </code>
  </t:template>
  
  <t:template match="ddel:InfosetP">
    <code class="InfoProp">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
  </t:template>
  
  <t:template match="ddel:IF[@dump:uri] |
                     ddel:Class[@dump:uri] |
                     ddel:TYPE[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:apply-templates select="@dump:uri" mode="human-datatype-name">
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
  </t:template>
  
  <t:template match="ddel:Module[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="def" select="/child::dump:moduleSet/child::dump:module
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:choose>
    <t:when test="$def">
      <t:apply-templates select="$def[position () = 1]" mode="ref">
        <t:with-param name="short" select="true ()"/>
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
    <t:when test="$def/child::dump:uri">
      <t:apply-templates select="$def/child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-title"/>
    </t:when>
    <t:otherwise>
      <code class="uri" lang="en" xml:lang="en"
      >&lt;<a href="{string (@dump:uri)}">
        <t:value-of select="string (@dump:uri)"/>
      </a>&gt;</code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:M[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="defParent"
        select="/child::dump:moduleSet/child::dump:module/child::dump:class |
                /child::dump:moduleSet/child::dump:module/child::dump:interface"/>
    <t:variable name="def" select="$defParent/child::dump:method
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:apply-templates select="self::node ()" mode="memref">
      <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      <t:with-param name="def" select="$def"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="ddel:A[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="def" select="$anyClass/child::dump:attribute
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:apply-templates select="self::node ()" mode="memref">
      <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      <t:with-param name="def" select="$def"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="*" mode="memref">
    <t:param name="ddoct:basePath" select="''"/>
    <t:param name="def" select="/parent::node ()"/>
    <t:choose>
    <t:when test="$def">
      <t:apply-templates select="$def[position () = 1]" mode="ref">
        <t:with-param name="with-class" select="true ()"/>
        <t:with-param name="short" select="true ()"/>
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
    <t:when test="$def/child::dump:uri">
      <t:apply-templates select="$def/child::dump:uri[not (@dump:isAlias)]"
          mode="human-module-title"/>
    </t:when>
    <t:otherwise>
      <code class="uri" lang="en" xml:lang="en"
      >&lt;<a href="{string (@dump:uri)}">
        <t:value-of select="string (@dump:uri)"/>
      </a>&gt;</code>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddel:P[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="defGrandparent"
        select="/child::dump:moduleSet/child::dump:module/child::dump:class |
                /child::dump:moduleSet/child::dump:module/child::dump:interface"/>
    <t:variable name="def"
        select="$defGrandparent/child::dump:method/child::dump:param
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
  
  <t:template match="ddel:C[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="defParent"
        select="/child::dump:moduleSet/child::dump:module/child::dump:class |
                /child::dump:moduleSet/child::dump:module/child::dump:interface"/>
    <t:variable name="def"
        select="$defParent/child::dump:constGroup/child::dump:const
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:apply-templates select="self::node ()" mode="memref">
      <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      <t:with-param name="def" select="$def"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="ddel:X[@dump:uri]">
    <t:param name="ddoct:basePath" select="''"/>
    <t:variable name="defGParent"
        select="/child::dump:moduleSet/child::dump:module/child::dump:class |
                /child::dump:moduleSet/child::dump:module/child::dump:interface"/>
    <t:variable name="defParent"
        select="$defGParent/child::dump:constGroup/child::dump:const"/>
    <t:variable name="def"
        select="($defParent | $defParent/child::dump:exceptionSubCode)
                       [child::dump:uri/@dump:uri = string (current ()/@dump:uri)]"/>
    <t:apply-templates select="self::node ()" mode="memref">
      <t:with-param name="ddoct:basePath" select="$ddoct:basePath"/>
      <t:with-param name="def" select="$def"/>
    </t:apply-templates>
  </t:template>
  
  <t:template match="ddel:XE[@ddel:lexType =
              'http://suika.fam.cx/~wakaba/archive/2004/dis/Core#QName' or
              @ddel:lexType =
              'http://suika.fam.cx/~wakaba/archive/2004/dis/Core#NCNameOrQName'] |
              ddel:XA[@ddel:lexType =
              'http://suika.fam.cx/~wakaba/archive/2004/dis/Core#QName' or
              @ddel:lexType =
              'http://suika.fam.cx/~wakaba/archive/2004/dis/Core#NCNameOrQName']">
    <code>
      <t:attribute name="class">
        <t:text>qname </t:text>
        <t:choose>
        <t:when test="self::ddel:XE">XMLe</t:when>
        <t:when test="self::ddel:XA">XMLa</t:when>
        </t:choose>
      </t:attribute>
      <t:apply-templates select="@*"/>
      <t:if test="child::ddel:prefix">
        <t:apply-templates select="child::ddel:prefix"/>
        <t:text>:</t:text>
      </t:if>
      <t:apply-templates select="child::ddel:localName"/>
    </code>
  </t:template>
  <t:template match="ddel:XE/@ddel:lexType"/>
  <t:template match="ddel:XE/@ddel:lexTypeImplied"/>
  <t:template match="ddel:XA/@ddel:lexType"/>
  <t:template match="ddel:XA/@ddel:lexTypeImplied"/>
  
  <t:template match="ddel:Q[@ddel:lexType =
              'http://suika.fam.cx/~wakaba/archive/2004/dis/Core#QName']">
    <code class="qname">
      <t:apply-templates select="@*"/>
      <t:if test="child::ddel:prefix">
        <t:apply-templates select="child::ddel:prefix"/>
        <t:text>:</t:text>
      </t:if>
      <t:apply-templates select="child::ddel:localName"/>
    </code>
  </t:template>
  <t:template match="ddel:Q/@ddel:lexType"/>
  <t:template match="ddel:Q/@ddel:lexTypeImplied"/>
  <t:template match="ddel:Q/@dump:namespaceURI |
                     ddel:XE/@dump:namespaceURI |
                     ddel:XA/@dump:namespaceURI">
    <t:attribute name="title">
      <t:text>&lt;</t:text>
      <t:value-of select="self::node ()"/>
      <t:text>&gt;</t:text>
    </t:attribute>
  </t:template>
  <t:template match="ddel:prefix">
    <code class="qname-prefix">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
  </t:template>
  <t:template match="ddel:localName">
    <code class="qname-local-name">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </code>
  </t:template>
  
  <t:template match="ddel:Feature[@dump:namespaceURI]
      [@ddel:lexType =
         'http://suika.fam.cx/~wakaba/archive/2004/dis/Core#NCNameOrQName']">
    <t:variable name="uri"
        select="concat (@dump:namespaceURI, child::ddel:localName)"/>
    <code class="uri dump-feature-name" lang="en" xml:lang="en">
      <t:text>&lt;</t:text>
      <a href="{$uri}">
        <t:value-of select="$uri"/>
      </a>
      <t:text>&gt;</t:text>
    </code>
  </t:template>
  
  <t:template match="ddel:Feature[not (@dump:namespaceURI)]
      [@ddel:lexType =
         'http://suika.fam.cx/~wakaba/archive/2004/dis/Core#NCNameOrQName']">
    <code class="dump-feature-name" lang="en" xml:lang="en">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </code>
  </t:template>
  
  <t:template match="ddel:FeatureVer">
    <code class="dump-feature-version">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </code>
  </t:template>
  
  <t:template match="child::ddel:ps">
    <div class="paragraphs">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="child::ddel:eg">
    <div class="example">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="child::doc:fig">
    <div class="fig">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="child::doc:example">
    <div class="fig example">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="child::doc:figBody">
    <div class="fig-body">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="child::doc:caption">
    <div class="caption">
      <t:apply-templates select="@*"/>
      <t:apply-templates/>
    </div>
  </t:template>
  
  <t:template match="sw010:src">
    <cite class="bibref">
      <t:apply-templates select="@*"/>
      <t:value-of select="'['"/>
      <t:apply-templates select="child::node ()"/>
      <t:value-of select="']'"/>
    </cite>
  </t:template>
  
  <t:template match="sw010:csection">
    <cite class="section">
      <t:apply-templates select="@*"/>
      <t:apply-templates select="child::node ()"/>
    </cite>
  </t:template>
  
  <t:template match="rfc2119:*[string-length () = 0]">
    <em class="rfc2119" lang="en" xml:lang="en">
      <t:value-of select="local-name ()"/>
    </em>
  </t:template>
  <t:template match="rfc2119:MUST-NOT[string-length () = 0]">
    <em class="rfc2119" lang="en" xml:lang="en">MUST NOT</em>
  </t:template>
  <t:template match="rfc2119:SHOULD-NOT[string-length () = 0]">
    <em class="rfc2119" lang="en" xml:lang="en">SHOULD NOT</em>
  </t:template>
  <t:template match="rfc2119:MAY-NOT[string-length () = 0]">
    <em class="rfc2119" lang="en" xml:lang="en">MAY NOT</em>
  </t:template>
  <t:template match="rfc2119:SHALL-NOT[string-length () = 0]">
    <em class="rfc2119" lang="en" xml:lang="en">SHALL NOT</em>
  </t:template>
  
  <t:template match="@xml:lang">
    <t:apply-templates select="parent::*" mode="lang"/>
  </t:template>
  
  <t:template match="child::*" mode="lang">
    <t:choose>
    <t:when test="@xml:lang">
      <t:attribute name="lang"><t:value-of select="@xml:lang"/></t:attribute>
      <t:attribute name="xml:lang"><t:value-of select="@xml:lang"/></t:attribute>
    </t:when>
    <t:otherwise>
      <t:attribute name="lang">
        <t:value-of select="ancestor::*[@xml:lang]/@xml:lang"/>
      </t:attribute>
      <t:attribute name="xml:lang">
        <t:value-of select="ancestor::*[@xml:lang]/@xml:lang"/>
      </t:attribute>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="html5:*/@class">
    <t:attribute name="class"><t:value-of select="self::node ()"/></t:attribute>
  </t:template>
  
  <t:template match="@xml:id">
    <t:attribute name="id"><t:value-of select="self::node ()"/></t:attribute>
  </t:template>
  
  <t:template match="@xml:space">
    <t:attribute name="xml:space"><t:value-of select="self::node ()"/></t:attribute>
  </t:template>
  
  <t:template match="text ()" mode="attr">
    <t:value-of select="normalize-space (self::node ())"/>
  </t:template>
  
  <t:template match="/" mode="list">
    <ddoct:list>
      <t:apply-templates select="child::dump:moduleSet" mode="list"/>
    </ddoct:list>
  </t:template>
  
  <t:template match="dump:moduleSet" mode="list">
    <t:choose>
    <t:when test="child::dump:moduleGroup[not (@dump:isPartial)]">
      <t:apply-templates select="child::dump:moduleGroup
                                 [not (@dump:isPartial)]" mode="list"/>
    </t:when>
    <t:otherwise>
      <ddoct:item ddoct:mode="modules">
        <t:attribute name="ddoct:fileName">
          <t:apply-templates select="self::node ()" mode="file-name"/>
        </t:attribute>
      </ddoct:item>
      <ddoct:item ddoct:mode="modules-menu">
        <t:attribute name="ddoct:fileName">
          <t:apply-templates select="self::node ()" mode="file-name-menu"/>
        </t:attribute>
      </ddoct:item>
      <ddoct:item ddoct:mode="modules-menu-frame">
        <t:attribute name="ddoct:fileName">
          <t:apply-templates select="self::node ()" mode="file-name-menu-frame"/>
        </t:attribute>
      </ddoct:item>
    </t:otherwise>
    </t:choose>
    <t:apply-templates select="child::dump:module
                               [not (@dump:isPartial)]" mode="list"/>
  </t:template>
  
  <t:template match="dump:moduleGroup" mode="list">
    <ddoct:item ddoct:mode="module-group">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name"/>
      </t:attribute>
    </ddoct:item>
    <ddoct:item ddoct:mode="module-group-menu">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name-menu"/>
      </t:attribute>
    </ddoct:item>
    <ddoct:item ddoct:mode="module-group-menu-frame">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name-menu-frame"/>
      </t:attribute>
    </ddoct:item>
    <t:apply-templates select="(child::dump:document)
                               [not (@dump:isPartial)]"
        mode="list"/>
  </t:template>
  
  <t:template match="dump:module" mode="list">
    <ddoct:item ddoct:mode="module">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name"/>
      </t:attribute>
    </ddoct:item>
    <ddoct:item ddoct:mode="module-menu">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name-menu"/>
      </t:attribute>
    </ddoct:item>
    <ddoct:item ddoct:mode="module-menu-frame">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name-menu-frame"/>
      </t:attribute>
    </ddoct:item>
    <t:apply-templates select="(child::dump:class | child::dump:interface |
                                child::dump:dataType)
                               [not (@dump:isPartial)]"
        mode="list"/>
  </t:template>
  
  <t:template match="dump:class" mode="list">
    <ddoct:item ddoct:mode="class">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name"/>
      </t:attribute>
    </ddoct:item>
  </t:template>
  
  <t:template match="dump:interface" mode="list">
    <ddoct:item ddoct:mode="interface">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name"/>
      </t:attribute>
    </ddoct:item>
  </t:template>
  
  <t:template match="dump:dataType" mode="list">
    <ddoct:item ddoct:mode="datatype">
      <t:attribute name="ddoct:uri">
        <t:apply-templates select="self::node ()" mode="list-uri"/>
      </t:attribute>
      <t:attribute name="ddoct:fileName">
        <t:apply-templates select="self::node ()" mode="file-name"/>
      </t:attribute>
    </ddoct:item>
  </t:template>
  
  <t:template match="dump:*" mode="list-uri">
    <t:value-of select="child::dump:uri[position () = 1]/@dump:uri"/>
  </t:template>
  
  <t:template match="dump:*" mode="id-attr">
    <t:attribute name="id">
      <t:apply-templates select="self::node ()" mode="id"/>
    </t:attribute>
  </t:template>
  
  <t:template match="child::*" mode="unknown">
    <span>
      <code>
        <t:text>{</t:text>
        <code class="uri">
          <t:value-of select="concat ('&lt;', namespace-uri (), '&gt;')"/>
        </code>
        <t:value-of select="concat (':', local-name (), '}')"/>
      </code>
      <t:apply-templates select="@*" mode="unknown"/>
      <t:apply-templates/>
      <code>
        <t:value-of select="'{/}'"/>
      </code>
    </span>
  </t:template>
  <t:template match="child::*">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="h">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="heading">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="hb">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="h1">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="h1b">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="h2">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="h3">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="h4">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="human-module-title">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="human-module-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="human-module-name-text">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="human-module-name-attr">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="li">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="dl">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="dd">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="dl-classes">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="list">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="list-uri">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="doc">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="doc-menu">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="doc-frame">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="attr">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="text">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="file-name">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="uri">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="id">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="child::*" mode="id-attr">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  
  <t:template match="*" mode="dl-examples"/>
  <t:template match="*" mode="examples"/>
  
  <t:template match="@*" mode="unknown">
    <span>
      <code>
        <t:value-of select="concat ('{@&lt;', namespace-uri (), '>:',
                                    local-name (), '=')"/>
      </code>
      <t:value-of select="string (self::node ())"/>
      <code>
        <t:value-of select="'/}'"/>
      </code>
    </span>
  </t:template>
  <t:template match="@*">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
  <t:template match="@*" mode="text">
    <t:apply-templates select="self::node ()" mode="unknown"/>
  </t:template>
</t:stylesheet>

<!-- Revision: $Date: 2005/10/01 12:17:37 $ -->

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