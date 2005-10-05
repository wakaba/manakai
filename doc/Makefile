MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

DIS_SUFFIX = .dis
DAC_SUFFIX = .dae
DAEM_SUFFIX = .daem

RM = rm -f

JAVA = java
JAVA_JAR = $(JAVA) -jar

XALAN_PATH = d:/Program_Files/xalan/xalan.jar
XALAN = $(JAVA) -cp $(XALAN_PATH) org.apache.xalan.xslt.Process

PERL_OPTIONS =
PERL = perl
PERL_ = $(PERL) $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
  --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
  --dis-file-suffix="$(DIS_SUFFIX)" \
  --daem-file-suffix="$(DAEM_SUFFIX)"

MKDISDUMP_PL = $(MANAKAI_BIN_DIR)mkdisdump.pl
MKDISDUMP_OPTIONS = --with-implementators-note
MKDISDUMP = $(PERL_) $(MKDISDUMP_PL) $(MKDISDUMP_OPTIONS) $(DIS_OPTIONS_ALL)

DUMP_STYLESHEET_PATH = template/disdump.ja.xsl
DDLIST_STYLESHEET_PATH = template/ddlist.ja.xsl

MODULES_FILE_PATH_PREFIX = NAME-modules
HTML_CSS_STYLE_SHEET_URI = style/disdump-style.css

NS_DIS = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#
NS_DISLIB = http://suika.fam.cx/~wakaba/archive/2004/dis/
NS_DX = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException\#
NS_ERROR = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/
NS_MARKUP = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#
NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_UTIL = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/

ALL_HTML = dom.html util.html error.html dis.html

DOM_DAC_FILE = $(MANAKAI_LIB_DIR)Message/DOM/core$(DAC_SUFFIX)
MINIMPL_DAC_FILE = $(MANAKAI_LIB_DIR)Message/DOM/feature-spec$(DAC_SUFFIX)
UTIL_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Util/core$(DAC_SUFFIX)
DIS_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Util/disdoc$(DAC_SUFFIX)

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
	  --module-uri="$(NS_MDOM)GenericLS" \
	  --with-implementators-note > $@

util.xml: $(UTIL_DAC_FILE)
	$(MKDISDUMP) $< \
	  --module-uri="$(NS_DISLIB)DISCore" \
	  --module-uri="$(NS_DISLIB)DISRDF" \
	  --module-uri="$(NS_DISLIB)DISIDL" \
	  --module-uri="$(NS_DISLIB)DISLang" \
	  --module-uri="$(NS_DISLIB)DISPerl" \
	  --module-uri="$(NS_DISLIB)DISMarkup" \
	  --module-uri="$(NS_DISLIB)XML" \
	  --module-uri="$(NS_DISLIB)NaturalLanguage" \
	  --module-uri="$(NS_DISLIB)Java" \
	  --module-uri="$(NS_DISLIB)ECMAScript" \
	  --module-uri="$(NS_DISLIB)Document" \
	  --module-uri="$(NS_UTIL)ManakaiNode" \
	  --with-implementators-note > $@

error.xml: $(UTIL_DAC_FILE)
	$(MKDISDUMP) $< \
	  --resource-uri="$(NS_DX)ManakaiErrorModules" \
	  > $@

minimpl.xml: $(MINIMPL_DAC_FILE)
	$(MKDISDUMP) $< \
	  --resource-uri="http://suika.fam.cx/~wakaba/archive/2004/dom/feature#spec.Document $(NS_MANAKAIDOM)ForSpecLatest" \
	  > $@

dis.xml: $(DIS_DAC_FILE)
	$(MKDISDUMP) $< \
	  --module-uri="$(NS_MARKUP)SuikaWikiConfig21" \
	  --module-uri="$(NS_UTIL)PerlCode" \
	  --module-uri="$(NS_UTIL)DIS" \
	  --module-uri="$(NS_DIS)Perl" \
	  --module-uri="$(NS_DIS)Value" \
	  --module-uri="$(NS_DIS)DNLite" \
	  --module-uri="$(NS_DIS)DISDoc" \
	  --module-uri="$(NS_DIS)DISDump" \
	  --with-implementators-note > $@

clean:
	$(RM) $(ALL_HTML:.html=-list.pl.tmp) $(ALL_HTML:.html=-list.xml.tmp) \
	  $(ALL_HTML:.html=.xml)
	$(RM) *~ .*~ *.BAK .*.BAK

distclean: clean
	$(RMR) ./Message ./http

## $Date: 2005/10/05 11:50:35 $
## License: Public Domain
