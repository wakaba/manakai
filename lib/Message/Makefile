CD = cd
MAKE = make
RM = rm
RMALL = $(RM) -fv

PM_SUFFIX = .pm

all: build

build:
	cd Util && $(MAKE) build
	cd Markup && $(MAKE) build
	cd DOM && $(MAKE) build
	cd MIME && $(MAKE) build
	cd URI && $(MAKE) build
	cd CGI && $(MAKE) build

clean:
	$(RMALL) *.BAK .*.BAK *~ .*~
	$(CD) Body && $(MAKE) clean
	$(CD) Field && $(MAKE) clean
	$(CD) MIME && $(MAKE) clean
	$(CD) Util && $(MAKE) clean
	$(CD) Markup && $(MAKE) clean
	$(CD) DOM && $(MAKE) clean
	$(CD) URI && $(MAKE) clean
	$(CD) CGI && $(MAKE) clean

distclean:
	$(RMALL) *.BAK .*.BAK *~ .*~
	$(CD) Body && $(MAKE) distclean
	$(CD) Field && $(MAKE) distclean
	$(CD) MIME && $(MAKE) distclean
	$(CD) Util && $(MAKE) distclean
	$(CD) Markup && $(MAKE) distclean
	$(CD) DOM && $(MAKE) distclean
	$(CD) URI && $(MAKE) distclean
	$(CD) CGI && $(MAKE) distclean

## License: Public Domain.
