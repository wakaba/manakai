MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

DIS_SUFFIX = .dis
DAEM_SUFFIX = .dafm
DAFX_SUFFIX = .dafx
PM_SUFFIX = .pm

CD = cd
MKDIR = mkdir
MAKE = make
RM = rm
RMALL = $(RM) -fv
RMDIRALL = $(RMALL) -r
PERL = perl
PERL_OPTIONS =
PERL_OPTIONS_ALL = $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_ = $(PERL) $(PERL_OPTIONS_ALL)
PERLC = $(PERL) -c -w
PERLC_OPTIONS = 
PERLC_OPTIONS_ALL = $(PERLC_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS_ALL)
TOUCH = touch
WGET = wget
GREP = grep
GREPV = $(GREP) -v
PERL_INPLACE = $(PERL_) -n -i
ECHO = echo
CP = cp

ENC2XS_PATH = /usr/local/bin/
ENC2XS = $(ENC2XS_PATH)enc2xs

NS_CHARSET = http://suika.fam.cx/~wakaba/archive/2005/manakai/Charset/

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)" \
      --dafx-file-suffix="$(DAFX_SUFFIX)"

DAF_OPTIONS =
DAF_PL = $(MANAKAI_BIN_DIR)daf.pl
DAF = $(PERL_) $(DAF_PL) $(DAF_OPTIONS) $(DIS_OPTIONS_ALL)

TBR2TBL_PL = tbr2tbl.pl
TBR2TBL = $(PERL_) $(TBR2TBL_PL)

TBL2UCM_PL = tbl2ucm.pl
TBL2UCM = $(PERL_) $(TBL2UCM_PL)

DIS_FILES = Encode$(DIS_SUFFIX)

PM_FILES = Encode$(PM_SUFFIX)

GL_JIS_TBR_FILES = gl-jisx0208-common.tbr gl-cjk-hiragana.tbr \
  gl-cjk-katakana.tbr gl-cjk-greek.tbr gl-cjk-cyrillic.tbr \
  gl-iso-646-alphanumeric.tbr gl-cjk-box-drawing.tbr
GENERATED_TBR_FILES = euc-jp-1997.tbr shift-jis-1997.tbr \
  gl-jis-1978.tbr gl-jis-1983.tbr gl-jis-1997.tbr
TBR_FILES = $(GL_JIS_TBR_FILES) $(GENERATED_TBR_FILES) \
  gl-iso-646-alphanumeric-fw.tbr gl-iso-646-symbol.tbr \
  gl-jisx0212-common.tbr jisx0208_1997.tbr

TBL_FILES = $(GENERATED_TBR_FILES:.tbr=.tbl)

UCM_FILES = $(GENERATED_TBR_FILES:.tbr=.ucm)

ENCODE_DIRECTORIES = GLJIS1978 GLJIS1983 GLJIS1997 EUCJP1997 ShiftJIS1997

GENERATED_FILES = $(PM_FILES)

all: $(PM_FILES) $(ENCODE_DIRECTORIES)

$(PM_FILES): %$(PM_SUFFIX): %$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-module="$(NS_CHARSET)$* $@"
	$(PERL_CHK) $@

$(TBR2TBL_PL):
	$(WGET) http://suika.fam.cx/gate/cvs/*checkout*/perl/lib/Encode/Table/tool/tbr2tbl.pl

$(TBL2UCM_PL):
	$(WGET) http://suika.fam.cx/gate/cvs/*checkout*/perl/lib/Encode/Table/tool/tbl2ucm.pl

jisx0208_1997.tbr $(GL_JIS_TBR_FILES) gl-iso-646-symbol.tbr \
  gl-iso-646-alphanumeric-fw.tbr gl-jisx0212-common.tbr:
	$(WGET) -O $@ http://suika.fam.cx/gate/cvs/*checkout*/perl/lib/Encode/Table/$@

gl-jis-1997.tbl: jisx0208_1997.tbr $(GL_JIS_TBR_FILES) \
  gl-iso-646-symbol.tbr $(TBR2TBL_PL)
	$(TBR2TBL) $< > $@
	$(PERL_INPLACE) -e 'print unless /^#(?!\?PETBL)/' $@
	$(ECHO) '#?o name="gl-jis-1997"' >> $@
	$(ECHO) '#?o <-ucs-substition="0x30FB"' >> $@
	$(ECHO) '#?o ucm:mb_cur_max="2"' >> $@
	$(ECHO) '#?o license="Public Domain"' >> $@

gl-jis-1983.tbl: gl-jis-1997.tbl
	$(CP) $< $@
	$(PERL_INPLACE) -e 'print unless /^#(?!\?PETBL)/' $@
	$(PERL_INPLACE) -e 'print unless /^0x742[56]/' $@
	$(ECHO) '#?o name="gl-jis-1983"' >> $@
	$(ECHO) '#?o <-ucs-substition="0x30FB"' >> $@
	$(ECHO) '#?o ucm:mb_cur_max="2"' >> $@
	$(ECHO) '#?o license="Public Domain"' >> $@

gl-jis-1978.tbl: gl-jis-1983.tbl
	$(CP) $< $@
	$(PERL_INPLACE) -e 'print unless /^#(?!\?PETBL)/' $@
	$(PERL_INPLACE) -e 'print unless /^0x(?:2(?:2[3-7]|8)|3022|316B|322A|337A|3622|366D|3834|396D|3C48|3D2B|3E5[5F]|4066|415F|424D|433D|444F|453[6F]|4578|4642|4739|482E|4830|4B4B|4C4D|4D69|4F39|5A39|74)/' $@
	## 29 characters from JIS X 0208:1997 6.3.4
	$(ECHO) '0x3022	U+555E		# <cjk>' >> $@
	$(ECHO) '0x316B	U+7130		# <cjk>' >> $@
	$(ECHO) '0x322A	U+9DD7		# <cjk>' >> $@
	$(ECHO) '0x337A	U+5699		# <cjk>' >> $@
	$(ECHO) '0x3622	U+4FE0		# <cjk>' >> $@
	$(ECHO) '0x366D	U+8ED0		# <cjk>' >> $@
	$(ECHO) '0x3834	U+9E7C		# <cjk>' >> $@
	$(ECHO) '0x396D	U+9EB4		# <cjk>' >> $@
	$(ECHO) '0x3C48	U+5C62		# <cjk>' >> $@
	$(ECHO) '0x3D2B	U+7E61		# <cjk>' >> $@
	$(ECHO) '0x3E55	U+8523		# <cjk>' >> $@
	$(ECHO) '0x3E5F	U+91AC		# <cjk>' >> $@
	$(ECHO) '0x4066	U+87EC		# <cjk>' >> $@
	$(ECHO) '0x415F	U+6414		# <cjk>' >> $@
	$(ECHO) '0x424D	U+9A52		# <cjk>' >> $@
	$(ECHO) '0x433D	U+7C1E		# <cjk>' >> $@
	$(ECHO) '0x444F	U+6451		# <cjk>' >> $@
	$(ECHO) '0x4536	U+5861		# <cjk>' >> $@
	$(ECHO) '0x453F	U+985A		# <cjk>' >> $@
	$(ECHO) '0x4578	U+79B1		# <cjk>' >> $@
	$(ECHO) '0x4642	U+7006		# <cjk>' >> $@
	$(ECHO) '0x4739	U+56CA		# <cjk>' >> $@
	$(ECHO) '0x482E	U+6F51		# <cjk>' >> $@
	$(ECHO) '0x4830	U+91B1		# <cjk>' >> $@
	$(ECHO) '0x4B4B	U+9830		# <cjk>' >> $@
	$(ECHO) '0x4C4D	U+9EB5		# <cjk>' >> $@
	$(ECHO) '0x4D69	U+840A		# <cjk>' >> $@
	$(ECHO) '0x4F39	U+881F		# <cjk>' >> $@
	$(ECHO) '0x5A39	U+6522		# <cjk>' >> $@
	$(ECHO) '#?o name="gl-jis-1978"' >> $@
	$(ECHO) '#?o <-ucs-substition="0x30FB"' >> $@
	$(ECHO) '#?o ucm:mb_cur_max="2"' >> $@
	$(ECHO) '#?o license="Public Domain"' >> $@

.euc-jp-1997-gr-left.tbr.tmp: $(TBR2TBL_PL)
	$(ECHO) '#?PETBL/1.0 SOURCE' > $@.tmp
	$(ECHO) '#?import src="gl-jisx0208-common.tbr" mode="standard,fullwidth,isoiec646irv,NOT-SIGN,LARGE-CIRCLE,nonhan-1983-add,han-1978-revised,han-1983-revised,han-1983-swapped,han-1983-add,han-1990-revised,han-1990-add"' >> $@.tmp
	$(TBR2TBL) $@.tmp > $@
	$(RM) $@.tmp

euc-jp-1997.tbr:
	$(ECHO) '#?PETBL/1.0 SOURCE' > $@
	$(ECHO) '#?o name="euc-jp-1997"' >> $@
	$(ECHO) '#?o <-ucs-substition="0x30FB"' >> $@
	$(ECHO) '#?o ucm:mb_cur_max="3"' >> $@
	$(ECHO) '#?o license="Public Domain"' >> $@
	$(ECHO) '#?import std-cl' >> $@
	$(ECHO) '#?import std-0x20' >> $@
	$(ECHO) '#?import src="gl-iso-646-alphanumeric.tbr"' >> $@
	$(ECHO) '#?import src="gl-iso-646-symbol.tbr"' >> $@
	$(ECHO) '#?import std-0x7F' >> $@
	$(ECHO) '0x80	U+0080		# <control>' >> $@
	$(ECHO) '0x81	U+0081		# <control>' >> $@
	$(ECHO) '0x82	U+0082		# <control>' >> $@
	$(ECHO) '0x83	U+0083		# <control>' >> $@
	$(ECHO) '0x84	U+0084		# <control>' >> $@
	$(ECHO) '0x85	U+0085		# <control>' >> $@
	$(ECHO) '0x86	U+0086		# <control>' >> $@
	$(ECHO) '0x87	U+0087		# <control>' >> $@
	$(ECHO) '0x88	U+0088		# <control>' >> $@
	$(ECHO) '0x89	U+0089		# <control>' >> $@
	$(ECHO) '0x8A	U+008A		# <control>' >> $@
	$(ECHO) '0x8B	U+008B		# <control>' >> $@
	$(ECHO) '0x8C	U+008C		# <control>' >> $@
	$(ECHO) '0x8D	U+008D		# <control>' >> $@
	$(ECHO) '0x90	U+0090		# <control>' >> $@
	$(ECHO) '0x91	U+0091		# <control>' >> $@
	$(ECHO) '0x92	U+0092		# <control>' >> $@
	$(ECHO) '0x93	U+0093		# <control>' >> $@
	$(ECHO) '0x94	U+0094		# <control>' >> $@
	$(ECHO) '0x95	U+0095		# <control>' >> $@
	$(ECHO) '0x96	U+0096		# <control>' >> $@
	$(ECHO) '0x97	U+0097		# <control>' >> $@
	$(ECHO) '0x98	U+0098		# <control>' >> $@
	$(ECHO) '0x99	U+0099		# <control>' >> $@
	$(ECHO) '0x9A	U+009A		# <control>' >> $@
	$(ECHO) '0x9B	U+009B		# <control>' >> $@
	$(ECHO) '0x9C	U+009C		# <control>' >> $@
	$(ECHO) '0x9D	U+009D		# <control>' >> $@
	$(ECHO) '0x9E	U+009E		# <control>' >> $@
	$(ECHO) '0x9F	U+009F		# <control>' >> $@
	$(PERL_INPLACE) -e 'print unless /^0x8[EF]/' $@
	$(ECHO) '#?import std-0xA0' >> $@
	$(ECHO) '#?import std-0xFF' >> $@
	$(ECHO) '#?import src=".euc-jp-1997-gr-left.tbr.tmp" right' >> $@
	$(ECHO) '0x8EA1	U+FF61		# HALFWIDTH IDEOGRAPHIC FULL STOP' >> $@
	$(ECHO) '0x8EA2	U+FF62		# HALFWIDTH LEFT CORNER BRACKET' >> $@
	$(ECHO) '0x8EA3	U+FF63		# HALFWIDTH RIGHT CORNER BRACKET' >> $@
	$(ECHO) '0x8EA4	U+FF64		# HALFWIDTH IDEOGRAPHIC COMMA' >> $@
	$(ECHO) '0x8EA5	U+FF65		# HALFWIDTH KATAKANA MIDDLE DOT' >> $@
	$(ECHO) '0x8EA6	U+FF66		# HALFWIDTH KATAKANA LETTER WO' >> $@
	$(ECHO) '0x8EA7	U+FF67		# HALFWIDTH KATAKANA LETTER SMALL A' >> $@
	$(ECHO) '0x8EA8	U+FF68		# HALFWIDTH KATAKANA LETTER SMALL I' >> $@
	$(ECHO) '0x8EA9	U+FF69		# HALFWIDTH KATAKANA LETTER SMALL U' >> $@
	$(ECHO) '0x8EAA	U+FF6A		# HALFWIDTH KATAKANA LETTER SMALL E' >> $@
	$(ECHO) '0x8EAB	U+FF6B		# HALFWIDTH KATAKANA LETTER SMALL O' >> $@
	$(ECHO) '0x8EAC	U+FF6C		# HALFWIDTH KATAKANA LETTER SMALL YA' >> $@
	$(ECHO) '0x8EAD	U+FF6D		# HALFWIDTH KATAKANA LETTER SMALL YU' >> $@
	$(ECHO) '0x8EAE	U+FF6E		# HALFWIDTH KATAKANA LETTER SMALL YO' >> $@
	$(ECHO) '0x8EAF	U+FF6F		# HALFWIDTH KATAKANA LETTER SMALL TU' >> $@
	$(ECHO) '0x8EB0	U+FF70		# HALFWIDTH KATAKANA-HIRAGANA PROLONGED SOUND MARK' >> $@
	$(ECHO) '0x8EB1	U+FF71		# HALFWIDTH KATAKANA LETTER A' >> $@
	$(ECHO) '0x8EB2	U+FF72		# HALFWIDTH KATAKANA LETTER I' >> $@
	$(ECHO) '0x8EB3	U+FF73		# HALFWIDTH KATAKANA LETTER U' >> $@
	$(ECHO) '0x8EB4	U+FF74		# HALFWIDTH KATAKANA LETTER E' >> $@
	$(ECHO) '0x8EB5	U+FF75		# HALFWIDTH KATAKANA LETTER O' >> $@
	$(ECHO) '0x8EB6	U+FF76		# HALFWIDTH KATAKANA LETTER KA' >> $@
	$(ECHO) '0x8EB7	U+FF77		# HALFWIDTH KATAKANA LETTER KI' >> $@
	$(ECHO) '0x8EB8	U+FF78		# HALFWIDTH KATAKANA LETTER KU' >> $@
	$(ECHO) '0x8EB9	U+FF79		# HALFWIDTH KATAKANA LETTER KE' >> $@
	$(ECHO) '0x8EBA	U+FF7A		# HALFWIDTH KATAKANA LETTER KO' >> $@
	$(ECHO) '0x8EBB	U+FF7B		# HALFWIDTH KATAKANA LETTER SA' >> $@
	$(ECHO) '0x8EBC	U+FF7C		# HALFWIDTH KATAKANA LETTER SI' >> $@
	$(ECHO) '0x8EBD	U+FF7D		# HALFWIDTH KATAKANA LETTER SU' >> $@
	$(ECHO) '0x8EBE	U+FF7E		# HALFWIDTH KATAKANA LETTER SE' >> $@
	$(ECHO) '0x8EBF	U+FF7F		# HALFWIDTH KATAKANA LETTER SO' >> $@
	$(ECHO) '0x8EC0	U+FF80		# HALFWIDTH KATAKANA LETTER TA' >> $@
	$(ECHO) '0x8EC1	U+FF81		# HALFWIDTH KATAKANA LETTER TI' >> $@
	$(ECHO) '0x8EC2	U+FF82		# HALFWIDTH KATAKANA LETTER TU' >> $@
	$(ECHO) '0x8EC3	U+FF83		# HALFWIDTH KATAKANA LETTER TE' >> $@
	$(ECHO) '0x8EC4	U+FF84		# HALFWIDTH KATAKANA LETTER TO' >> $@
	$(ECHO) '0x8EC5	U+FF85		# HALFWIDTH KATAKANA LETTER NA' >> $@
	$(ECHO) '0x8EC6	U+FF86		# HALFWIDTH KATAKANA LETTER NI' >> $@
	$(ECHO) '0x8EC7	U+FF87		# HALFWIDTH KATAKANA LETTER NU' >> $@
	$(ECHO) '0x8EC8	U+FF88		# HALFWIDTH KATAKANA LETTER NE' >> $@
	$(ECHO) '0x8EC9	U+FF89		# HALFWIDTH KATAKANA LETTER NO' >> $@
	$(ECHO) '0x8ECA	U+FF8A		# HALFWIDTH KATAKANA LETTER HA' >> $@
	$(ECHO) '0x8ECB	U+FF8B		# HALFWIDTH KATAKANA LETTER HI' >> $@
	$(ECHO) '0x8ECC	U+FF8C		# HALFWIDTH KATAKANA LETTER HU' >> $@
	$(ECHO) '0x8ECD	U+FF8D		# HALFWIDTH KATAKANA LETTER HE' >> $@
	$(ECHO) '0x8ECE	U+FF8E		# HALFWIDTH KATAKANA LETTER HO' >> $@
	$(ECHO) '0x8ECF	U+FF8F		# HALFWIDTH KATAKANA LETTER MA' >> $@
	$(ECHO) '0x8ED0	U+FF90		# HALFWIDTH KATAKANA LETTER MI' >> $@
	$(ECHO) '0x8ED1	U+FF91		# HALFWIDTH KATAKANA LETTER MU' >> $@
	$(ECHO) '0x8ED2	U+FF92		# HALFWIDTH KATAKANA LETTER ME' >> $@
	$(ECHO) '0x8ED3	U+FF93		# HALFWIDTH KATAKANA LETTER MO' >> $@
	$(ECHO) '0x8ED4	U+FF94		# HALFWIDTH KATAKANA LETTER YA' >> $@
	$(ECHO) '0x8ED5	U+FF95		# HALFWIDTH KATAKANA LETTER YU' >> $@
	$(ECHO) '0x8ED6	U+FF96		# HALFWIDTH KATAKANA LETTER YO' >> $@
	$(ECHO) '0x8ED7	U+FF97		# HALFWIDTH KATAKANA LETTER RA' >> $@
	$(ECHO) '0x8ED8	U+FF98		# HALFWIDTH KATAKANA LETTER RI' >> $@
	$(ECHO) '0x8ED9	U+FF99		# HALFWIDTH KATAKANA LETTER RU' >> $@
	$(ECHO) '0x8EDA	U+FF9A		# HALFWIDTH KATAKANA LETTER RE' >> $@
	$(ECHO) '0x8EDB	U+FF9B		# HALFWIDTH KATAKANA LETTER RO' >> $@
	$(ECHO) '0x8EDC	U+FF9C		# HALFWIDTH KATAKANA LETTER WA' >> $@
	$(ECHO) '0x8EDD	U+FF9D		# HALFWIDTH KATAKANA LETTER N' >> $@
	$(ECHO) '0x8EDE	U+FF9E		# HALFWIDTH KATAKANA VOICED SOUND MARK' >> $@
	$(ECHO) '0x8EDF	U+FF9F		# HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK' >> $@
	$(ECHO) '#?import src="gl-jisx0212-common.tbr" mode="fullwidth,isoiec646irv,BROKEN-BAR,han" offset="0x8F8080"' >> $@

shift-jis-1997.tbr:
	$(WGET) -O $@ http://suika.fam.cx/gate/cvs/*checkout*/perl/lib/Encode/Table/cp/cp932-ms.tbr
	$(PERL_INPLACE) -e 'print unless /^0x(?:5C|7E|8(?:[07]|1(?:5[CF]|6[01]|7C|9[12]|CA))|A0|F)|<-|->/' $@
	$(ECHO) '0x5C	U+00A5		# YEN SIGN' >> $@
	$(ECHO) '0x7E	U+203E		# OVERLINE' >> $@
	$(ECHO) '0x815C	U+2014		# EM DASH' >> $@
	$(ECHO) '0x815F	U+005C		# REVERSE SOLIDUS' >> $@
	$(ECHO) '0x8160	U+301C		# WAVE DASH' >> $@
	$(ECHO) '0x8161	U+2016		# DOUBLE VERTICAL LINE' >> $@
	$(ECHO) '0x817C	U+2212		# MINUS SIGN' >> $@
	$(ECHO) '0x8191	U+00A2		# CENT SIGN' >> $@
	$(ECHO) '0x8192	U+00A3		# POUND SIGN' >> $@
	$(ECHO) '0x81CA	U+00AC		# NOT SIGN' >> $@
	$(ECHO) '#?o name="shift-jis-1997"' >> $@
	$(ECHO) '#?o <-ucs-substition="0x30FB"' >> $@
	$(ECHO) '#?o ucm:mb_cur_max="2"' >> $@
	$(ECHO) '#?o license="Public Domain"' >> $@

euc-jp-1997.tbl: %.tbl: %.tbr \
  gl-iso-646-alphanumeric.tbr gl-iso-646-symbol.tbr \
  gl-iso-646-alphanumeric-fw.tbr gl-jisx0212-common.tbr \
  .euc-jp-1997-gr-left.tbr.tmp $(TBR2TBL_PL)
	$(TBR2TBL) $< > $@

shift-jis-1997.tbl: %.tbl: %.tbr $(TBR2TBL_PL)
	$(TBR2TBL) $< > $@

gl-jis-1978.ucm gl-jis-1983.ucm gl-jis-1997.ucm \
  euc-jp-1997.ucm shift-jis-1997.ucm: %.ucm: %.tbl $(TBL2UCM_PL)
	$(TBL2UCM) $< > $@

GLJIS1978 GLJIS1983 GLJIS1997: GLJIS%: gl-jis-%.ucm
	$(MKDIR) -p $@
	$(CD) $@ && $(ENC2XS) -M $@ ../$<
	$(CD) $@ && $(PERL_) ./Makefile.PL
	$(CD) $@ && $(MAKE)
EUCJP1997: euc-jp-1997.ucm
	$(MKDIR) -p $@
	$(CD) $@ && $(ENC2XS) -M $@ ../$<
	$(CD) $@ && $(PERL_) ./Makefile.PL
	$(CD) $@ && $(MAKE)
ShiftJIS1997: shift-jis-1997.ucm
	$(MKDIR) -p $@
	$(CD) $@ && $(ENC2XS) -M $@ ../$<
	$(CD) $@ && $(PERL_) ./Makefile.PL
	$(CD) $@ && $(MAKE)

install-GLJIS1978 install-GLJIS1983 install-GLJIS1997 \
  install-EUCJP1997 install-ShiftJIS1997: install-%: %
	$(CD) $< && $(MAKE) install

install: install-GLJIS1978 install-GLJIS1983 install-GLJIS1997 \
  install-EUCJP1997 install-ShiftJIS1997

clean:
	$(RMALL) $(GENERATED_FILES)
	$(RMALL) .*.tmp *~ .*~ *.BAK .*.BAK
	$(RMALL) $(TBR2TBL_PL) $(TBL2UCM_PL)
	$(RMALL) $(TBR_FILES) $(TBL_FILES) $(UCM_FILES)
	$(RMDIRALL) $(ENCODE_DIRECTORIES)

distclean: clean
	$(RMALL) *$(DAEM_SUFFIX) *$(DAFX_SUFFIX)

## $Date: 2006/03/14 06:47:15 $
## License: Public Domain.
