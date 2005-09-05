MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

RM = rm -f

JAVA = java
JAVA_JAR = $(JAVA) -jar

XALAN_PATH = d:/Program_Files/xalan/xalan.jar
XALAN = $(JAVA) -cp $(XALAN_PATH) org.apache.xalan.xslt.Process

PERL = perl
MKDISDUMP_PL = $(MANAKAI_BIN_DIR)mkdisdump.pl
MKDISDUMP = $(PERL) -I$(MANAKAI_LIB_DIR) $(MKDISDUMP_PL)

DUMP_STYLESHEET_PATH = template/disdump.ja.xsl
DDLIST_STYLESHEET_PATH = template/ddlist.ja.xsl

MODULES_FILE_PATH_PREFIX = core-modules
HTML_CSS_STYLE_SHEET_URI = style/disdump-style.css

NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.

all: doc-filelist.pl.tmp doc.xml $(DUMP_STYLESHEET_PATH)
	$(PERL) doc-filelist.pl.tmp

doc.xml:
	$(MKDISDUMP) $(MANAKAI_LIB_DIR)Message/DOM/core.dac \
	  --module-uri="$(NS_MDOM)DOMCore" \
	  --module-uri="$(NS_MDOM)DOMMain" \
	  --module-uri="$(NS_MDOM)DOMFeature" \
	  --with-implementators-note

doc-filelist.xml.tmp: doc.xml $(DUMP_STYLESHEET_PATH)
	$(XALAN) -in $< -xsl $(DUMP_STYLESHEET_PATH) -out $@ -param mode list \
	  -param modules-file-path-prefix $(MODULES_FILE_PATH_PREFIX)

doc-filelist.pl.tmp: doc-filelist.xml.tmp $(DDLIST_STYLESHEET_PATH)
	$(XALAN) -in $< -xsl $(DDLIST_STYLESHEET_PATH) -out $@ -text \
	  -param mode perl-script \
	  -param xalan-command "$(XALAN)" \
	  -param modules-file-path-prefix $(MODULES_FILE_PATH_PREFIX) \
	  -param html-style-sheet-uri $(HTML_CSS_STYLE_SHEET_URI) \
	  -param source-file-path doc.xml \
	  -param disdump-stylesheet-file-path $(DUMP_STYLESHEET_PATH)

clean:
	$(RM) doc-filelist.pl.tmp doc-filelist.xml.tmp
	$(RM) *~ .*~ *.BAK .*.BAK

distclean: clean
	$(RMR) ./Message ./http

## License: Public Domain
