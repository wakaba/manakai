#!/bin/sh
find -name ChangeLog | xargs cvs diff | grep "^\+" | sed -e "s/^\+//; s/^\+\+ .\//++ whatpm\//" > .cvslog.tmp
cvs commit -F .cvslog.tmp $1 $2 $3 $4 $5 $6 $7 $8 $9 
## TODO: Don't use -I here
perl \
    -I/home/wakaba/work/manakai2/lib/ \
    mkcommitfeed.pl --file-name whatpm-commit.en.atom.u8 \
    --feed-url http://suika.fam.cx/www/markup/html/whatpm/whatpm-commit \
    --feed-lang en \
    < .cvslog.tmp
rm .cvslog.tmp

## $Date: 2008/10/21 05:04:36 $
## License: Public Domain
