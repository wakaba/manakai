#!/usr/bin/perl -w
use strict;

use Message::Util::Formatter::Boolean;
use Test;

my $fmt = new Message::Util::Formatter::Boolean;

plan tests => 69;

ok $fmt->replace (q{}), undef, q(Empty format);
ok $fmt->replace (q{1}), 1, q(Bare text (true));
ok $fmt->replace (q{0}), 0, q(Bare text (false));
ok $fmt->replace (q{00}), 1, q(Bare text (true));
ok $fmt->replace (q{-0}), 1, q(Bare text (true));
ok $fmt->replace (q{ }), 1, q(Bare text (true));

ok $fmt->replace (q{%and;}), undef, q(Empty %and);
ok $fmt->replace (q{%and; }), undef, q(Empty %and with bare text (true));
ok $fmt->replace (q{%and (1);}), 1, q(One item %and);
ok $fmt->replace (q{%and (0);}), 0, q(One item %and);
ok $fmt->replace (q{%and (1); }), 1, q(One item %and w/ bare text);
ok $fmt->replace (q{%and (0); }), 0, q(One item %and w/ bare text);
ok $fmt->replace (q{ %and (1);}), 1, q(One item %and w/ bare text);
ok $fmt->replace (q{ %and (0);}), 0, q(One item %and w/ bare text);
ok $fmt->replace (q{ %and (1); }), 1, q(One item %and w/ bare text);
ok $fmt->replace (q{ %and (0); }), 0, q(One item %and w/ bare text);
ok $fmt->replace (q{%and (1, 2);}), 1, q(%and w/ two items);
ok $fmt->replace (q{%and (1, 0);}), 0, q(%and w/ two items);
ok $fmt->replace (q{%and (0, 2);}), 0, q(%and w/ two items);
ok $fmt->replace (q{%and (0, 0);}), 0, q(%and w/ two items);
ok $fmt->replace (q{%and (-1, 2, 1);}), 1, q(%and w/ three items);
ok $fmt->replace (q{%and (1, 2, 0);}), 0, q(%and w/ three items);
ok $fmt->replace (q{%and (-1, 0, 1);}), 0, q(%and w/ three items);
ok $fmt->replace (q{%and (-1, 0, 0);}), 0, q(%and w/ three items);
ok $fmt->replace (q{%and (0, 2, 1);}), 0, q(%and w/ three items);
ok $fmt->replace (q{%and (0, 2, 0);}), 0, q(%and w/ three items);
ok $fmt->replace (q{%and (0, 0, 1);}), 0, q(%and w/ three items);
ok $fmt->replace (q{%and (0, 0, 0);}), 0, q(%and w/ three items);

ok $fmt->replace (q{%or;}), undef, q(Empty %or);
ok $fmt->replace (q{%or (1);}), 1, q(One item %or);
ok $fmt->replace (q{%or (0);}), 0, q(One item %or);
ok $fmt->replace (q{%or (1); }), 1, q(One item %or w/ bare text);
ok $fmt->replace (q{%or (0); }), 0, q(One item %or w/ bare text);
ok $fmt->replace (q{ %or (1);}), 1, q(One item %or w/ bare text);
ok $fmt->replace (q{ %or (0);}), 0, q(One item %or w/ bare text);
ok $fmt->replace (q{ %or (1); }), 1, q(One item %or w/ bare text);
ok $fmt->replace (q{ %or (0); }), 0, q(One item %or w/ bare text);
ok $fmt->replace (q{%or (1, 2);}), 1, q(%and w/ two items);
ok $fmt->replace (q{%or (1, 0);}), 1, q(%or w/ two items);
ok $fmt->replace (q{%or (0, 2);}), 1, q(%or w/ two items);
ok $fmt->replace (q{%or (0, 0);}), 0, q(%or w/ two items);
ok $fmt->replace (q{%or (-1, 2, 1);}), 1, q(%or w/ three items);
ok $fmt->replace (q{%or (1, 2, 0);}), 1, q(%or w/ three items);
ok $fmt->replace (q{%or (-1, 0, 1);}), 1, q(%or w/ three items);
ok $fmt->replace (q{%or (-1, 0, 0);}), 1, q(%or w/ three items);
ok $fmt->replace (q{%or (0, 2, 1);}), 1, q(%or w/ three items);
ok $fmt->replace (q{%or (0, 2, 0);}), 1, q(%or w/ three items);
ok $fmt->replace (q{%or (0, 0, 1);}), 1, q(%or w/ three items);
ok $fmt->replace (q{%or (0, 0, 0);}), 0, q(%or w/ three items);


ok $fmt->replace (q{%or ({%and (1);}p, 1);}), 1;
ok $fmt->replace (q{%or ({%and (1);}p, {%and (1);}p);}), 1;
ok $fmt->replace (q{%or ({%and (1);}p, {%and (0);}p);}), 1;
ok $fmt->replace (q{%or ({%and (0);}p, {%and (1);}p);}), 1;
ok $fmt->replace (q{%or ({%and (0);}p, {%and (0);}p);}), 0;
ok $fmt->replace (q{%and ({%or (1);}p, 1);}), 1;
ok $fmt->replace (q{%and ({%or (1);}p, {%or (1);}p);}), 1;
ok $fmt->replace (q{%and ({%or (1);}p, {%or (0);}p);}), 0;
ok $fmt->replace (q{%and ({%or (0);}p, {%or (1);}p);}), 0;
ok $fmt->replace (q{%and ({%or (0);}p, {%or (0);}p);}), 0;
ok $fmt->replace (q{%and ({%or ({%and (1, 1);}p);}p, {%or (1);}p);}), 1;
ok $fmt->replace (q{%and ({%or ({%and (1, 0);}p);}p, {%or (1);}p);}), 0;

ok $fmt->replace (q{%not;}), undef;
ok $fmt->replace (q{%not (1);}), 0;
ok $fmt->replace (q{%not (0);}), 1;
ok $fmt->replace (q{%not ({ });}), 0;
ok $fmt->replace (q{%not ({%and (1, 1);}p);}), 0;
ok $fmt->replace (q{%not ({%and (1, 0);}p);}), 1;
ok $fmt->replace (q{%not ({%or (1, 0);}p);}), 0;
ok $fmt->replace (q{%not ({%or (0, 0);}p);}), 1;




