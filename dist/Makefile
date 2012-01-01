## Available from <https://github.com/wakaba/generate-pm-package>.
GENERATEPM = generate-pm-package

all: dist

dist: langtag css-tokenizer

langtag:
	cd .. && $(GENERATEPM) config/packages/langtag.pi dist/

css-tokenizer:
	cd .. && $(GENERATEPM) config/dist/whatpm-css-tokenizer.pi dist/

## License: Public Domain.
