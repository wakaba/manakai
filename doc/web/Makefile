MANAKAI_DIR = ../../
MANAKAI_LIB_DIR = $(MANAKAI_DIR)lib/

WHATPM_DIR = ../../../markup/html/whatpm/
WHATPM_LIB_DIR = $(WHATPM_DIR)

HARUSAME = $(MANAKAI_DIR)/local/harusame

PERL_ = perl
PERL_LIB_OPTIONS = -I$(MANAKAI_LIB_DIR) -I$(WHATPM_LIB_DIR)
PERL = $(PERL_) $(PERL_LIB_OPTIONS)

all: build

build: cover.ja.html cover.en.html features.en.html features.ja.html

%.en.html: %.html.src $(HARUSAME)
	$(HARUSAME) --lang=en < $< > $@

%.ja.html: %.html.src $(HARUSAME)
	$(HARUSAME) --lang=ja < $< > $@

## License: Public Domain.
