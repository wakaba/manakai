WGET = wget
MKDIR = mkdir

all: \
  content-type-files \
  tokenizer-files \
  tree-construction-files \
  content-checker-files

content-type-files: content-type-result.txt

content-type-result.txt: always
	cd .. && perl t/ContentType.t &> t/$@

tokenizer-files: tokenizer \
  tokenizer/test1.test tokenizer/test2.test tokenizer/contentModelFlags.test \
  tokenizer/escapeFlag.test \
  tokenizer/test3.test \
  tokenizer/test4.test \
  tokenizer/LICENSE \
  tokenizer-result.txt

tokenizer:
	$(MKDIR) $@

tokenizer/%.test:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/testdata/$@

tokenizer/LICENSE:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/LICENSE

tokenizer-result.txt: always
	cd .. && perl t/HTML-tokenizer.t &> t/$@

tree-construction-files: tree-construction \
  tree-construction/tests1.dat \
  tree-construction/tests2.dat \
  tree-construction/tests3.dat \
  tree-construction/tests4.dat \
  tree-construction/tests5.dat \
  tree-construction/tests6.dat \
  tree-construction/LICENSE \
  tree-construction-result.txt

tree-construction:
	$(MKDIR) $@

tree-construction/%.dat:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/testdata/$@

tree-construction/LICENSE:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/LICENSE

tree-construction-result.txt: always
	cd .. && perl t/HTML-tree.t &> t/$@

content-checker-files: content-checker-result.txt

content-checker-result.txt: always
	cd .. && perl t/ContentChecker.t &> t/$@

always:

## License: Public Domain.
## $Date: 2007/07/16 07:03:09 $
