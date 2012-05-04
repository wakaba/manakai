HG = hg

all: htmlparser-data htmlparser-data-manakai.diff

htmlparser-data:
	mkdir -p tmp html-tokenizer html-tree
	$(HG) clone https://code.google.com/p/html5lib/ tmp/html5lib || \
	    (cd tmp/html5lib && $(HG) pull -u)
	cp -R tmp/html5lib/testdata/tokenizer/* html-tokenizer/
	cp -R tmp/html5lib/testdata/tree-construction/* html-tree/

htmlparser-data-manakai.diff: html-tokenizer html-tree
	git diff 9cfd78bb2d -- html-tokenizer html-tree > $@
