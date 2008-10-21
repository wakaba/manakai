HARUSAME_DIR = ../../../harusame/
HARUSAME_BIN_DIR = $(HARUSAME_DIR)bin/

MANAKAI_DIR = ../../
MANAKAI_LIB_DIR = $(MANAKAI_DIR)lib/

WHATPM_DIR = ../../../markup/html/whatpm/
WHATPM_LIB_DIR = $(WHATPM_DIR)

HARUSAME = $(HARUSAME_BIN_DIR)harusame.pl

PERL_ = perl
PERL_LIB_OPTIONS = -I$(MANAKAI_LIB_DIR) -I$(WHATPM_LIB_DIR)
PERL = $(PERL_) $(PERL_LIB_OPTIONS)

all: cover.ja.html cover.en.html

%.en.html: %.html.src
	$(PERL) $(HARUSAME) --lang=en < $< > $@

%.ja.html: %.html.src
	$(PERL) $(HARUSAME) --lang=ja < $< > $@
