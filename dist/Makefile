## Available from <https://github.com/wakaba/generate-pm-package>.
GENERATEPM = generate-pm-package

all: dist

dist: langtag css-tokenizer css-selectors

langtag:
	cd .. && $(GENERATEPM) config/dist/whatpm-langtag.pi dist/

css-tokenizer:
	cd .. && $(GENERATEPM) config/dist/whatpm-css-tokenizer.pi dist/

css-selectors:
	cd .. && $(GENERATEPM) config/dist/whatpm-css-selectors.pi dist/

## License: Public Domain.
