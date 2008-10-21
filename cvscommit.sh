#!/bin/sh
find -name ChangeLog | xargs cvs diff | grep "^\+" | sed -e "s/^\+//; s/^\+\+ .\//++ manakai\//" > .cvslog.tmp
cvs commit -F .cvslog.tmp $1 $2 $3 $4 $5 $6 $7 $8 $9 
## TODO: Don't use -I here
perl \
    -Ilib/ \
    -I/home/httpd/html/www/markup/html/whatpm/ \
    mkcommitfeed.pl --file-name doc/web/manakai-commit.en.atom.u8 \
    --feed-url http://suika.fam.cx/www/manakai-core/doc/web/manakai-commit \
    --feed-title "manakai ChangeLog diffs" \
    --feed-lang en \
    --feed-related-url "http://suika.fam.cx/www/manakai-core/doc/web/" \
    --feed-license-url "http://suika.fam.cx/www/manakai-core/doc/web/#license" \
    --feed-rights "This feed is free software; you can redistribute it and/or modify it under the same terms as Perl itself." \
    < .cvslog.tmp
rm .cvslog.tmp

## $Date: 2008/10/21 07:52:49 $
## License: Public Domain
