<?xml version="1.0" encoding="iso-2022-jp"?>
<t:stylesheet xmlns:t="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml1="http://www.w3.org/1999/xhtml"
    xmlns:xhtml2="http://www.w3.org/2002/06/xhtml2/"
    xmlns:html5="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:dump="http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#DISDump/"
    xmlns:ddel="http://suika.fam.cx/~wakaba/archive/2005/disdoc#"
    xmlns:script="http://suika.fam.cx/~wakaba/archive/2005/5/script#"
    xmlns:sw010="urn:x-suika-fam-cx:markup:suikawiki:0:10:"
    xmlns:ddoct="http://suika.fam.cx/~wakaba/archive/2005/8/disdump-xslt#"
    version="1.0">
  
  <t:param name="mode" select="'html-list'"/>
  <t:param name="xalan-command" select="'java org.apache.xalan.xslt.Process'"/>
  <t:param name="modules-file-path-prefix" select="'modules'"/>
  <t:param name="source-file-path" select="'doc.xml'"/>
  <t:param name="source-uri" select="'doc.xml'"/>
  <t:param name="disdump-stylesheet-file-path" select="'disdump.ja.xsl'"/>
  <t:param name="disdump-stylesheet-uri" select="'disdump.ja.xsl'"/>
  <t:param name="html-style-sheet-uri"
      select="'http://suika.fam.cx/www/style/html/xhtml'"/>
  
  <t:template match="/">
    <t:choose>
    <t:when test="string ($mode) = 'perl-script'">
      <t:apply-templates mode="perl-script"/>
    </t:when>
    <t:when test="string ($mode) = 'html-script'">
      <t:apply-templates mode="html-script"/>
    </t:when>
    <t:otherwise>
      <t:apply-templates/>
    </t:otherwise>
    </t:choose>
  </t:template>
  
  <t:template match="ddoct:list">
    <ul>
      <t:apply-templates/>
    </ul>
  </t:template>

  <t:template match="ddoct:item">
    <li><a xml:lang="ja" lang="ja" onclick="javascript:t (this)"
        ddoct:mode="{@ddoct:mode}" ddoct:uri="{@ddoct:uri}"
        title="&lt;{@ddoct:uri}>">
      モード <code><t:value-of select="@ddoct:mode"/></code>,
      URI ...,
      生成ファイル名 <code class="file"><t:value-of select="@ddoct:fileName"/></code>
    </a></li>
  </t:template>
  
  <t:template match="ddoct:list" mode="html-script">
    <fieldset>
      <legend>変換</legend>
      <button onclick="transform ()">変換実行</button>
      <button onclick="clearScheduledJob ()">中断の方向で</button>
      <div>
        <span id="status-current">0</span>
        /
        <span id="status-all">0</span>
      </div>
      <script type="text/javascript">
        function transform () {
          var result = document.getElementById ('result-textarea');
          const ddoct = 'http://suika.fam.cx/~wakaba/archive/2005/8/disdump-xslt#';
          var xs = new SimpleXMLSerializer ();
          var sourceDocumentURI
            = '<t:value-of select="$source-uri"/>';
          var stylesheetDocumentURI
            = '<t:value-of select="$disdump-stylesheet-uri"/>';
          document.getElementById ('status-all').textContent
            = '<t:value-of select="count (child::ddoct:item)"/>';
          var currentNumber = 0;
          var statusCurrent = document.getElementById ('status-current');
          <t:apply-templates mode="html-script"/>
          doNextScheduledJob ();
        }
      </script>
      <textarea id="result-textarea" rows="15"/>
    </fieldset>
  </t:template>
  
  <t:template match="ddoct:item" mode="html-script">
    scheduleJob (function () {
      loadDocument (sourceDocumentURI, function (srcDoc) {
        loadDocument (stylesheetDocumentURI, function (doc) {
          var xp3 = new XSLTProcessor ();
          xp3.setParameter (null, 'mode', "<t:value-of select="@ddoct:mode"/>");
          xp3.setParameter (null, 'uri', "<t:value-of select="@ddoct:uri"/>");
          xp3.setParameter (null, 'lang', "ja");
          xp3.importStylesheet (doc);
          var tfra = xp3.transformToDocument (srcDoc);
          tfra.documentElement.setAttributeNS
            ('http://www.w3.org/2000/xmlns/', 'xmlns',
             'http://www.w3.org/1999/xhtml');
          result.value += <![CDATA['\n<![[<![[<><??>--<??><>]]']]> + '>]]' + '>\n';
          result.value += '&lt;>Name: <t:value-of select="@ddoct:fileName"/>\n';
          result.value += '&lt;>Lang: ja\n&lt;>Type: text/html\n\n';
          result.value += xs.writeToString (tfra);
          statusCurrent.textContent = ++currentNumber;
          doNextScheduledJob ();
        });
      });
    });
  </t:template>
  
  <t:template match="ddoct:list" mode="perl-script"
    >#!/usr/bin/perl 
    use strict;
    use File::Path;
    
    my $source_document_path = '<t:value-of select="$source-file-path"/>';
    my $stylesheet_path = '<t:value-of select="$disdump-stylesheet-file-path"/>';
    my $xalan_cmd = [qw!<t:value-of select="$xalan-command"/>!];
    
    my %common_param = (
      'modules-file-path-prefix' => "<t:value-of
          select="$modules-file-path-prefix"/>",
      'html-style-sheet-uri' => "<t:value-of
          select="$html-style-sheet-uri"/>",
    );
    unless ($common_param{'html-style-sheet-uri'} =~ /^[\w+.%-]+:/) {
      $common_param{'is-html-style-sheet-uri-relative'} = 1;
    }
    
    <!-- Creates a directory and its ancestors if necessary -->
    sub pdir ($) {
      my @dir = split m#/#, shift;
      pop @dir;
      mkpath ([join '/', @dir], 1, 0711) if @dir;
    }
    
    <!-- Transforms a document and outputs the result tree -->
    sub transform_and_output (%) {
      my %opt = @_;
      print STDERR 'Generating "', $opt{result_path}, '"...';
      pdir $opt{result_path};
      system (@$xalan_cmd, -in => $opt{source_path},
              -xsl => $opt{stylesheet_path}, -out => $opt{result_path},
              #$opt{method} ? '-' . $opt{method} : '-xml',
              map {
                -param => $_ => $opt{param}->{$_}
              } keys %{$opt{param}});
      die "$@" if $@;
      print STDERR 'done', "\n";
    }
    <t:apply-templates mode="perl-script"/>
  </t:template>
  
  <t:template match="ddoct:item" mode="perl-script">
    {
      my %param = (
        %common_param,
        mode => "<t:value-of select="@ddoct:mode"/>",
        uri => "<t:value-of select="@ddoct:uri"/>",
        lang => "ja",
      );
      my $output_path = "<t:value-of select="@ddoct:fileName"/>";
      transform_and_output (
        source_path => $source_document_path,
        stylesheet_path => $stylesheet_path,
        param => \%param,
        result_path => $output_path,
        method => 'html',
      );
    }
  </t:template>
  
</t:stylesheet>

<!-- Revision: $Date: 2005/09/05 15:09:58 $ -->

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