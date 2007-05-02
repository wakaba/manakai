WGET = wget
MKDIR = mkdir

all: tokenizer-files tree-construction-files

tokenizer-files: tokenizer \
  tokenizer/test1.test tokenizer/test2.test tokenizer/contentModelFlags.test \
  tokenizer-result.txt

tokenizer:
	$(MKDIR) $@

tokenizer/%.test:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/tests/$@

tokenizer-result.txt: always
	cd .. && perl t/HTML-tokenizer.t &> t/$@

tree-construction-files: tree-construction \
  tree-construction/tests1.dat \
  tree-construction/tests2.dat \
  tree-construction/tests3.dat \
  tree-construction/tests4.dat \
  tree-construction-result.txt

tree-construction:
	$(MKDIR) $@

tree-construction/%.dat:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/tests/$@

tree-construction-result.txt: always
	cd .. && perl t/HTML-tree.t &> t/$@

always:

## License: Public Domain.
## $Date: 2007/05/02 13:44:35 $
