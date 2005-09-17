MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

RM = rm -f

JAVA = java
JAVA_JAR = $(JAVA) -jar

XALAN_PATH = d:/Program_Files/xalan/xalan.jar
XALAN = $(JAVA) -cp $(XALAN_PATH) org.apache.xalan.xslt.Process

PERL_OPTIONS = -I$(MANAKAI_LIB_DIR)
PERL = perl
MKDISDUMP_PL = $(MANAKAI_BIN_DIR)mkdisdump.pl
MKDISDUMP = $(PERL) $(PERL_OPTIONS) $(MKDISDUMP_PL)

DUMP_STYLESHEET_PATH = template/disdump.ja.xsl
DDLIST_STYLESHEET_PATH = template/ddlist.ja.xsl

MODULES_FILE_PATH_PREFIX = NAME-modules
HTML_CSS_STYLE_SHEET_URI = style/disdump-style.css

NS_DIS = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#
NS_DISLIB = http://suika.fam.cx/~wakaba/archive/2004/dis/
NS_ERROR = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/
NS_MARKUP = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#
NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_UTIL = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/

ALL_HTML = dom.html util.html

DOM_DAC_FILE = $(MANAKAI_LIB_DIR)Message/DOM/core.dac
#UTIL_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Util/disdoc.dac
UTIL_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Util/discore.dac

all: $(ALL_HTML)

$(ALL_HTML): %.html: %-list.pl.tmp $(DUMP_STYLESHEET_PATH)
	$(PERL) $<

$(ALL_HTML:.html=-list.pl.tmp): %.pl.tmp: %.xml.tmp $(DDLIST_STYLESHEET_PATH)
	$(XALAN) -in $< -xsl $(DDLIST_STYLESHEET_PATH) -out $@ -text \
	  -param mode perl-script \
	  -param xalan-command "$(XALAN)" \
	  -param modules-file-path-prefix \
                 $(MODULES_FILE_PATH_PREFIX:NAME-%=$(<:-list.xml.tmp=)-%) \
	  -param html-style-sheet-uri $(HTML_CSS_STYLE_SHEET_URI) \
          -param source-file-path $(<:-list.xml.tmp=.xml) \
	  -param disdump-stylesheet-file-path $(DUMP_STYLESHEET_PATH)

$(ALL_HTML:.html=-list.xml.tmp): %-list.xml.tmp: %.xml $(DUMP_STYLESHEET_PATH)
	$(XALAN) -in $< -xsl $(DUMP_STYLESHEET_PATH) -out $@ -param mode list \
	  -param modules-file-path-prefix \
                 $(MODULES_FILE_PATH_PREFIX:NAME-%=$(<:.xml=)-%)

dom.xml: $(DOM_DAC_FILE)
	$(MKDISDUMP) $< \
	  --module-uri="$(NS_MDOM)DOMFeature" \
	  --module-uri="$(NS_MDOM)DOMMain" \
	  --module-uri="$(NS_MDOM)DOMCore" \
	  --module-uri="$(NS_MDOM)DOMXML" \
	  --module-uri="$(NS_MDOM)DOMLS" \
	  --with-implementators-note > $@

util.xml: $(UTIL_DAC_FILE)
	$(MKDISDUMP) $< \
	  --module-uri="$(NS_DISLIB)DISCore" \
	  --module-uri="$(NS_DISLIB)DISRDF" \
	  --module-uri="$(NS_DISLIB)DISIDL" \
	  --module-uri="$(NS_DISLIB)DISLang" \
	  --module-uri="$(NS_DISLIB)DISPerl" \
	  --module-uri="$(NS_UTIL)ManakaiNode" \
	  --module-uri="$(NS_ERROR)Core" \
	  --module-uri="$(NS_ERROR)DOMException" \
	  --module-uri="$(NS_MARKUP)SuikaWikiConfig21" \
	  --module-uri="$(NS_UTIL)PerlCode" \
	  --module-uri="$(NS_UTIL)DIS" \
	  --module-uri="$(NS_DIS)Perl" \
	  --module-uri="$(NS_DIS)Value" \
	  --with-implementators-note > $@
#	  --module-uri="$(NS_DIS)DISDoc" \
#	  --module-uri="$(NS_DIS)DISDump" \

clean:
	$(RM) $(ALL_HTML:.html=-list.pl.tmp) $(ALL_HTML:.html=-list.xml.tmp) \
	  $(ALL_HTML:.html=.xml)
	$(RM) *~ .*~ *.BAK .*.BAK

distclean: clean
	$(RMR) ./Message ./http

## License: Public Domain
