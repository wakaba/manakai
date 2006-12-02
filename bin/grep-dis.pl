#!/usr/bin/perl
(my $v = $0) =~ s#[^/]+$##;
chdir $v or die "$0: $v: $!";
chdir '..' or die "$0: $v/..: $!";
die "$0: Pattern is not specified\n" unless @ARGV;
exec 'grep "' . join ('" "', map {quotemeta} @ARGV) .
    q#" bin/*.pl lib/manakai/*.dis lib/manakai/*.pl lib/Message/DOM/*.dis \
    lib/Message/Markup/*.dis lib/Message/Util/*.dis lib/Message/Util/DIS/*.dis \
    lib/Message/Util/Error/*.dis lib/Message/Util/Formatter/*.dis \
    lib/Message/Charset/*.dis lib/Message/URI/*.dis#;

## License: Public Domain.
## $Date: 2006/12/02 12:46:18 $
