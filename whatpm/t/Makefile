WGET = wget

all: tokenizer-test

tokenizer-test: tokenizer-files
	

tokenizer:
	mkdir $@

tokenizer-files: tokenizer \
  tokenizer/test1.test tokenizer/test2.test tokenizer/contentModelFlags.test

tokenizer/%.test:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/tests/$@
