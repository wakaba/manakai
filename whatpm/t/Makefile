WGET = wget
MKDIR = mkdir
RM = rm
RMALL = $(RM) -frv

all: \
  content-type-files \
  tokenizer-files \
  tree-construction-files \
  content-checker-files

update: clean-remote-files \
  tokenizer-remote-files \
  tree-construction-remote-files

content-type-files: content-type-result.txt

content-type-result.txt: always
	cd .. && perl t/ContentType.t &> t/$@

tokenizer-files: tokenizer-remote-files tokenizer-result.txt

tokenizer-remote-files: tokenizer \
  tokenizer/test1.test tokenizer/test2.test tokenizer/contentModelFlags.test \
  tokenizer/escapeFlag.test \
  tokenizer/test3.test \
  tokenizer/test4.test \
  tokenizer/LICENSE

tokenizer:
	$(MKDIR) $@

tokenizer/%.test:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/testdata/$@

tokenizer/LICENSE:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/LICENSE

tokenizer-result.txt: always
	cd .. && perl t/HTML-tokenizer.t &> t/$@

tree-construction-files: tree-construction-remote-files \
  tree-construction-result.txt

tree-construction-remote-files: tree-construction \
  tree-construction/tests1.dat \
  tree-construction/tests2.dat \
  tree-construction/tests3.dat \
  tree-construction/tests4.dat \
  tree-construction/tests5.dat \
  tree-construction/tests6.dat \
  tree-construction/LICENSE

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

clean-remote-files:
	$(RMALL) tokenizer/*.test tokenizer/LICENSE
	$(RMALL) tree-construction/*.dat tree-construction/LICENSE

always:

## License: Public Domain.
## $Date: 2007/09/30 11:38:18 $
