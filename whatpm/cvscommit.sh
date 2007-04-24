#!/bin/sh
find -name ChangeLog | xargs cvs diff | grep "^\+" | sed -e "s/^\+//; s/^\+\+ .\//++ whatpm\//" > .cvslog.tmp
cvs commit -F .cvslog.tmp $1 $2 $3 $4 $5 $6 $7 $8 $9 
rm .cvslog.tmp

## $Date: 2007/04/24 13:35:21 $
## License: Public Domain
