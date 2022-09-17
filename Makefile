PERL = perl
PERL_VERSION = latest
PERL_PATH = $(abspath local/perlbrew/perls/perl-$(PERL_VERSION)/bin)
PROVE = prove
WGET = wget
CURL = curl

all: build

## ------ Deps ------

P2H = local/p2h

Makefile-setupenv: Makefile.setupenv
	$(MAKE) --makefile Makefile.setupenv setupenv-update \
            SETUPENV_MIN_REVISION=20120331

Makefile.setupenv:
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/Makefile.setupenv

local-perl generatepm \
perl-exec perl-version \
pmb-update pmb-install \
: %: Makefile-setupenv
	$(MAKE) --makefile Makefile.setupenv $@

build: $(P2H) $(HARUSAME)
	cd lib && $(MAKE) build
	cd doc && $(MAKE) build

local:
	mkdir -p local

HARUSAME = local/harusame

$(HARUSAME): local
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/harusame/master/harusame > $@
	chmod u+x $@

$(P2H): local
	$(CURL) -sSfL https://raw.githubusercontent.com/manakai/manakai.github.io/master/p2h > $@
	chmod u+x $@

## ------ Tests ------

PERL_ENV = PATH=$(PERL_PATH):$(PATH) PERL5LIB=$(shell cat config/perl/libs.txt)

test: safetest

test-deps: pmb-install

safetest: test-deps safetest-main

safetest-main:
	cd t && $(PERL_ENV) $(MAKE) test

## ------ Distribution ------

GENERATEPM = local/generatepm/bin/generate-pm-package
GENERATEPM_ = $(GENERATEPM) --generate-json

dist: generatepm
	mkdir -p dist
	$(GENERATEPM_) config/dist/manakai.pi dist

dist-wakaba-packages: local/wakaba-packages dist
	cp dist/*.json local/wakaba-packages/data/perl/
	cp dist/*.tar.gz local/wakaba-packages/perl/
	cd local/wakaba-packages && $(MAKE) all

local/wakaba-packages: always
	git clone "git@github.com:wakaba/packages.git" $@ || (cd $@ && git pull)
	cd $@ && git submodule update --init

always:

## License: Public Domain.
