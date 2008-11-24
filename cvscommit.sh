#!/bin/sh
find -name ChangeLog | xargs cvs diff | grep "^\+" | sed -e "s/^\+//; s/^\+\+ .\//++ manakai\//" > .cvslog.tmp
cvs commit -F .cvslog.tmp $1 $2 $3 $4 $5 $6 $7 $8 $9 
mkcommitfeed \
    --file-name doc/web/manakai-commit.en.atom.u8 \
    --feed-url http://suika.fam.cx/www/manakai-core/doc/web/manakai-commit \
    --feed-title "manakai ChangeLog diffs" \
    --feed-lang en \
    --feed-related-url "http://suika.fam.cx/www/manakai-core/doc/web/" \
    --feed-license-url "http://suika.fam.cx/www/manakai-core/doc/web/#license" \
    --feed-rights "This feed is free software; you can redistribute it and/or modify it under the same terms as Perl itself." \
    < .cvslog.tmp
cvs commit -m "" doc/web/manakai-commit.en.atom.u8
rm .cvslog.tmp

## $Date: 2008/11/24 06:41:23 $
## License: Public Domain
