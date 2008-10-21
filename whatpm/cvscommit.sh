#!/bin/sh
find -name ChangeLog | xargs cvs diff | grep "^\+" | sed -e "s/^\+//; s/^\+\+ .\//++ whatpm\//" > .cvslog.tmp
cvs commit -F .cvslog.tmp $1 $2 $3 $4 $5 $6 $7 $8 $9 
perl mkcommitfeed.pl --file-name whatpm-commit.en.atom.u8 \
    --feed-url http://suika.fam.cx/www/markup/html/whatpm/whatpm-commit \
    --feed-lang en \
    < .cvslog.tmp
rm .cvslog.tmp

## $Date: 2008/10/21 05:03:24 $
## License: Public Domain
