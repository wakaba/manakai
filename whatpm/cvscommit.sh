#!/bin/sh
find -name ChangeLog | xargs cvs diff | grep "^\+" | sed -e "s/^\+//; s/^\+\+ .\//++ whatpm\//" > .cvslog.tmp
cvs commit -F .cvslog.tmp $1 $2 $3 $4 $5 $6 $7 $8 $9 
## TODO: Don't use -I here
perl \
    -I/home/wakaba/work/manakai2/lib/ \
    mkcommitfeed.pl --file-name whatpm-commit.en.atom.u8 \
    --feed-url http://suika.fam.cx/www/markup/html/whatpm/whatpm-commit \
    --feed-title "Whatpm ChangeLog diffs" \
    --feed-lang en \
    --feed-related-url "http://suika.fam.cx/www/markup/html/whatpm/readme" \
    --feed-license-url "http://suika.fam.cx/www/markup/html/whatpm/readme#license" \
    --feed-rights "This feed is free software; you can redistribute it and/or modify it under the same terms as Perl itself." \
    < .cvslog.tmp
rm .cvslog.tmp

## $Date: 2008/10/21 05:17:48 $
## License: Public Domain
