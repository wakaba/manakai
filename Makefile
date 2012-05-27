PERL = perl
PERL_VERSION = latest
PERL_PATH = $(abspath local/perlbrew/perls/perl-$(PERL_VERSION)/bin)
PROVE = prove
WGET = wget

all: config/perl/libs.txt

## ------ Deps ------

Makefile-setupenv: Makefile.setupenv
	make --makefile Makefile.setupenv setupenv-update \
            SETUPENV_MIN_REVISION=20120330

Makefile.setupenv:
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/Makefile.setupenv

config/perl/libs.txt local-perl generatepm \
perl-exec perl-version \
carton-install carton-update carton-install-module \
: %: Makefile-setupenv
	make --makefile Makefile.setupenv pmbundler-repo-update $@ \
            PMBUNDLER_REPO_URL=$(PMBUNDLER_REPO_URL)

## ------ Tests ------

PERL_ENV = PATH=$(PERL_PATH):$(PATH) PERL5LIB=$(shell cat config/perl/libs.txt)

test: safetest

test-deps: carton-install config/perl/libs.txt

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
