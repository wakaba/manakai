#!/usr/bin/perl
use strict;
use Carp q(verbose);
select STDERR;$| = 1;
select STDOUT;$| = 1;

my $s = <<EOH;
<?xml version="1.0"?>
<!DOCTYPE r [
<!ELEMENT r %model;>
<!ATTLIST r xmlns CDATA #IMPLIED>
<!ELEMENT foo1 EMPTY><!ELEMENT foo2 EMPTY><!ELEMENT foo3 EMPTY><!ELEMENT foo4 EMPTY>
<!ELEMENT bar1 EMPTY><!ELEMENT bar2 EMPTY><!ELEMENT bar3 EMPTY><!ELEMENT bar4 EMPTY>
]>
<r xmlns="http://foo.test/">&content;</r>
EOH

my @testdata = (
	## Note: Checking of ambigiousity of content model is not implemented.
	##       When ambigious content model is given, validator try to match
	##       by first possible pattern.  I.e., in current implementation,
	##         0) (foo1|(foo1,foo2))
	##         1) <foo1/>
	##         2) <foo1/><foo2/>
	##       no error is reported about 0) and case 1) is reported as valid while
	##       2) is as invalid.
	{
		model	=> q{(bar1)},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(bar1)},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1)},
		content	=> q{<bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|bar3)},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(bar1|bar3)},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|bar3)},
		content	=> q{<bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|bar3)},
		content	=> q{<bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|bar3)},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar3|bar1)},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar3)},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar3)},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar3)},
		content	=> q{<bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar3)},
		content	=> q{<bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar3,bar1)},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,(bar2|bar3))},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(bar1,(bar2|bar3))},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,(bar2|bar3))},
		content	=> q{<bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,(bar2|bar3))},
		content	=> q{<bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,(bar2|bar3))},
		content	=> q{<bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,(bar2|bar3))},
		content	=> q{<bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,(bar2|bar3))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2),bar3)},
		content	=> q{<bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2),bar3)},
		content	=> q{<bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2),bar3)},
		content	=> q{<bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2),bar3)},
		content	=> q{<bar3/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2),bar3)},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2)|bar3)},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2)|bar3)},
		content	=> q{<bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2)|bar3)},
		content	=> q{<bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2)|bar3)},
		content	=> q{<bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2)|bar3)},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2)|bar3)},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar2/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,bar3))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar2/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar1/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,bar3)|bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar2/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/><bar2/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3|bar4)))},
		content	=> q{<bar1/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3,bar4)))},
		content	=> q{<bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3,bar4)))},
		content	=> q{<bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3,bar4)))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|(bar2,(bar3,bar4)))},
		content	=> q{<bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,(bar3,bar4)))},
		content	=> q{<bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|(bar2,(bar3,bar4)))},
		content	=> q{<bar1/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|((bar2,bar3),bar4))},
		content	=> q{<bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1|((bar2,bar3),bar4))},
		content	=> q{<bar1/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1|((bar2,bar3),bar4))},
		content	=> q{<bar2/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(((bar1|bar2),bar3),bar4)},
		content	=> q{<bar1/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(((bar1|bar2),bar3),bar4)},
		content	=> q{<bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(((bar1|bar2),bar3),bar4)},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(((bar1|bar2),bar3),bar4)},
		content	=> q{<bar1/><bar2/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(((bar1|bar2),bar3),bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2),(bar3,bar4))},
		content	=> q{<bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2),(bar3,bar4))},
		content	=> q{<bar1/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2),(bar3,bar4))},
		content	=> q{<bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar1/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1|bar2)|(bar3|bar4))},
		content	=> q{<bar1/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2),(bar3,bar4))},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2),(bar3,bar4))},
		content	=> q{<bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,bar3),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,(bar3|bar4),foo3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/><foo3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,(bar3|bar4)),(foo3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/><foo3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,(bar3|bar4)),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar3/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,(bar3|bar4)),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar4/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,(bar3|bar4)),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2,((bar3|bar2)|bar4)),(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,((bar3|(bar2))|bar4))|(foo3,foo4))},
		content	=> q{<bar1/><bar2/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,((bar3|(bar2))|bar4))|(foo3,foo4))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,((bar3|(bar2))|bar4))|(foo3,foo4))},
		content	=> q{<bar1/><bar2/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,((bar3|(bar2))|bar4))|(foo3,foo4))},
		content	=> q{<bar1/><foo3/><foo4/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2,((bar3|(bar2))|bar4))|(foo3,foo4))},
		content	=> q{<foo3/><foo4/>},
		result	=> 1,
	},
	{
		model	=> q{((bar1,bar2,((bar3|(bar2))|bar4))|(foo3,foo4))},
		content	=> q{<bar/><foo3/>},
		result	=> 0,
	},
	{
		model	=> q{((bar1,bar2,((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		name	=> q((Ambigious content model)),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		name	=> q((Ambigious content model)),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar2/>},
		result	=> 1,
	},
	{
		name	=> q((Ambigious content model) : Valid but ambigious),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar3/>},
		result	=> 1,
	},
	{
		name	=> q((Ambigious content model)),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar4/>},
		result	=> 1,
	},
	{
		name	=> q((Ambigious content model)),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar1/><bar2/>},
		result	=> 1,
	},
	{
		name	=> q((Ambigious content model) : Valid if unambigious),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar3/><bar4/>},
		result	=> 0,	# since ambigious content model!
	},
	{
		name	=> q((Ambigious content model)),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		name	=> q((Ambigious content model)),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar3/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		name	=> q((Ambigious content model)),
		model	=> q{(((bar1,bar2)|((bar3|(bar2))|bar4))|(bar3,bar4))},
		content	=> q{<bar1/><bar2/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		name	=> q((Ambigious content model) : ambigious but valid),
		model	=> q{(foo1|(foo1,foo2))},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		name	=> q((Ambigious content model) : valid if unambigious),
		model	=> q{(foo1|(foo1,foo2))},
		content	=> q{<foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*)},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(bar1*)},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*)},
		content	=> q{<bar1/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*)},
		content	=> q{<bar1/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*)},
		content	=> q{<bar1/><bar1/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2)},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,bar2)},
		content	=> q{<bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2)},
		content	=> q{<bar1/><bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2)},
		content	=> q{<bar1/><bar1/><bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2)},
		content	=> q{<bar1/><bar1/><bar2/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar2*)},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,bar2*)},
		content	=> q{<bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar2*)},
		content	=> q{<bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,bar2*)},
		content	=> q{<bar1/><bar2/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,bar2*)},
		content	=> q{<bar1/><bar2/><bar2/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,bar2*)},
		content	=> q{<bar1/><bar1/><bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar2*,bar3)},
		content	=> q{<bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar2*,bar3)},
		content	=> q{<bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,bar2*,bar3)},
		content	=> q{<bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1,bar2*,bar3)},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,bar2*,bar3)},
		content	=> q{<bar1/><bar2/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1,bar2*,bar3)},
		content	=> q{<bar1/><bar2/><bar2/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar1/><bar2/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar1/><bar3/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar2/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar1/><bar2/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar2/><bar2/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3)},
		content	=> q{<bar1/><bar2/><bar2/><bar2/><bar3/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar3/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar3/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar1/><bar1/><bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,bar2*,bar3*)},
		content	=> q{<bar1/><bar2/><bar2/><bar2/><bar3/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3))},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2,bar3))},
		content	=> q{<bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3))},
		content	=> q{<bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2,bar3))},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3))},
		content	=> q{<bar1/><bar2/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2,bar3))},
		content	=> q{<bar1/><bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3))},
		content	=> q{<bar1/><bar2/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*)},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*)},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*)},
		content	=> q{<bar1/><bar2/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*)},
		content	=> q{<bar1/><bar2/><bar3/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*,bar4)},
		content	=> q{<bar1/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*,bar4)},
		content	=> q{<bar1/><bar2/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*,bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*,bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2,bar3)*,bar4)},
		content	=> q{<bar1/><bar2/><bar2/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2|bar3)*,bar4)},
		content	=> q{<bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2|bar3)*,bar4)},
		content	=> q{<bar2/><bar2/><bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2|bar3)*,bar4)},
		content	=> q{<bar2/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2|bar3)*,bar4)},
		content	=> q{<bar2/><bar3/><bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2|bar3)*,bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar2/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2|(bar3,bar3))*,bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2|(bar3,bar3))*,bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar3/><bar2/><bar3/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{(bar1*,(bar2|(bar3,bar3))*,bar4)},
		content	=> q{<bar1/><bar2/><bar3/><bar3/><bar2/><bar3/><bar3/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2*|(bar3,bar3))*,bar4)},
		content	=> q{<bar1/><bar2/><bar2/><bar3/><bar3/><bar2/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2*|(bar3,bar3)*)*,bar4)},
		content	=> q{<bar1/><bar2/><bar2/><bar3/><bar3/><bar3/><bar3/><bar2/><bar4/>},
		result	=> 1,
	},
	{
		model	=> q{(bar1*,(bar2*|(bar3,bar3)*)*,bar4)},
		content	=> q{<bar1/><bar2/><bar2/><bar3/><bar3/><bar3/><bar2/><bar4/>},
		result	=> 0,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar3/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar2/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar3/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar2/><bar1/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar2/><bar3/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar3/><bar1/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar3/><bar2/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*|bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar1/><bar2/><bar3/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*,bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar2/><bar3/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((((bar3*,bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar2/><bar3/><bar1/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{((((bar3*,bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar2/><bar3/><bar3/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{((((bar3*,bar1)*|(bar2*)*)*)*)*},
		content	=> q{<bar1/><bar2/><bar3/><bar1/><bar3/><bar1/>},
		result	=> 1,
	},
	{
		model	=> q{(((((bar3*,bar1)*|(bar2*)*)*)*)*,bar1)},
		content	=> q{<bar1/><bar2/><bar3/><bar3/><bar1/>},
		result	=> 0,
	},
	{
		name	=> q{repeating is stronger than sequence},
		model	=> q{(((((bar3*,bar1)*|(bar2*)*)*)*)*,bar1)},
		content	=> q{<bar1/><bar2/><bar3/><bar3/><bar1/><bar1/>},
		result	=> 0,
	},
	{
		name	=> q{repeating is stronger than sequence},
		model	=> q{(((((bar3*,bar1)*|(bar2*)*)*)*)*,bar1)},
		content	=> q{<bar1/>},
		result	=> 0,
	},
	{
		name	=> q{repeating is stronger than sequence},
		model	=> q{(((((bar3*,bar1)*|(bar2*)*)*)*)*,bar1)},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(foo1+)},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(foo1+)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+)},
		content	=> q{<foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+)},
		content	=> q{<foo1/><foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+)},
		content	=> q{<foo1/><foo1/><foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+)},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1+)},
		content	=> q{<foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1)+},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(foo1)+},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1)+},
		content	=> q{<foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1)+},
		content	=> q{<foo1/><foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1)+},
		content	=> q{<foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1)+},
		content	=> q{<foo2/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1+|foo2)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+|foo2)},
		content	=> q{<foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+|foo2)},
		content	=> q{<foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+|foo2)},
		content	=> q{<foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1+|foo2)},
		content	=> q{<foo2/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1+|foo2)},
		content	=> q{<foo1/><foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1+|foo2)},
		content	=> q{<foo1/><foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1|foo2)+},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(foo1|foo2)+},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1|foo2)+},
		content	=> q{<foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1|foo2)+},
		content	=> q{<foo1/><foo1/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1|foo2)+},
		content	=> q{<foo1/><foo2/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1|foo2)+},
		content	=> q{<foo1/><foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1|foo2)+},
		content	=> q{<foo1/><foo1/><foo2/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{((foo1|foo2)+)},
		content	=> q{<foo1/><foo1/><foo2/><foo1/>},
		result	=> 1,
	},
	{
		name	=> q{repeat is stronger than sequence},
		model	=> q{((foo1|foo2)+,foo1)},
		content	=> q{<foo1/><foo1/><foo2/><foo1/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo1|foo2)+)},
		content	=> q{<foo1/><foo1/><foo2/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo1|foo2)+)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo1|foo2)+)},
		content	=> q{<foo1/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo1|foo2)+)},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1|(foo1|foo2)+)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1|(foo1|foo2)+)},
		content	=> q{<foo2/>},
		result	=> 1,
	},
	{
		name	=> q{valid if unambigious},
		model	=> q{(foo1|(foo1|foo2)+)},
		content	=> q{<foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1|(foo1|foo2)+)},
		content	=> q{<foo2/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1|(foo1|foo2)+)},
		content	=> q{<foo2/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1*|(foo1|foo2)+)},
		content	=> q{<foo2/><foo2/>},
		result	=> 1,
	},
	{
		name	=> q{valid if unambigious},
		model	=> q{(foo1*|(foo1|foo2)+)},
		content	=> q{<foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1*|(foo1|foo2)+)},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(foo3*|(foo1|foo2)+)},
		content	=> q{<foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo3*|(foo1|foo2)+)},
		content	=> q{<foo3/><foo1/>},
		result	=> 0,
	},
	{
		model	=> q{(foo3*|(foo1|foo2)+)+},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(foo3*|(foo1|foo2)+)+},
		content	=> q{<foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo3*|(foo1|foo2)+)+},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo3*|(foo1|foo2)+)+},
		content	=> q{<foo1/><foo2/><foo3/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{((foo1,foo2)*|(foo1|foo2)+)+},
		content	=> q{<foo1/><foo2/><foo1/><foo2/>},
		result	=> 1,
	},
	{
		name	=> q{ambigious},
		model	=> q{((foo1,foo2)*|(foo1|foo2)+)+},
		content	=> q{<foo1/><foo2/><foo1/><foo1/>},
		result	=> 0,
	},
	{
		model	=> q{((foo1,foo2)*|(foo1|foo2)+)+},
		content	=> q{<foo1/><foo2/><foo2/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?)},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(foo1?)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?)},
		content	=> q{<foo1/><foo1/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1)?},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(foo1)?},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1)?},
		content	=> q{<foo1/><foo1/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1?,foo2)},
		content	=> q{<foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,foo2)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,foo2?)},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(foo1,foo2?)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,foo2?)},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,foo2?)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,foo2)?},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(foo1,foo2)?},
		content	=> q{<foo1/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,foo2)?},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,foo2)?},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,foo2)?},
		content	=> q{<foo1/><foo2/><foo1/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2)?)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2)?)},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2)?)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,foo2?)},
		content	=> q{},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,foo2?)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,foo2?)},
		content	=> q{<foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,foo2?)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2|foo3)?)},
		content	=> q{},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2|foo3)?)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2|foo3)?)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2|foo3)?)},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2|foo3)?)},
		content	=> q{<foo1/><foo2/><foo3/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2|foo3)?)},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2|foo3)?)},
		content	=> q{<foo3/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1?,(foo2|foo3)?)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,(foo2|foo3)?)},
		content	=> q{<foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,(foo2|foo3)?)},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2?|foo3)?)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2?|foo3)?)},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2?|foo3)?)},
		content	=> q{<foo3/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2?|foo3)?)},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2?|foo3)?)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2?|foo3)?)},
		content	=> q{<foo1/><foo2/><foo3/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2?|foo3))},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2?|foo3))},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2?|foo3))},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2?|foo3))},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2?|foo3))},
		content	=> q{<foo1/><foo2/><foo3/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2*|foo3))},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3))},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2*|foo3))},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3))},
		content	=> q{<foo1/><foo2/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3))},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3))},
		content	=> q{<foo1/><foo3/><foo3/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo1/><foo2/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo1/><foo3/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo1/><foo2/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo1/><foo3/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3)+)},
		content	=> q{<foo2/><foo3/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2*|foo3?)+)},
		content	=> q{<foo1/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1,(foo2*|foo3?)+)},
		content	=> q{<foo2/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1,(foo2*|foo3?)+)},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		name	=> q{Real world example: "html:head" (XHTML 1.0 Strict) (foo1 == html:title, foo2 == html:base)},
		model	=> q{((foo3|foo4|bar1|bar2|bar3)*,((foo1,(foo3|foo4|bar1|bar2|bar3)*,(foo2,(foo3|foo4|bar1|bar2|bar3)*)?)|(foo2,(foo3|foo4|bar1|bar2|bar3)*,(foo1,(foo3|foo4|bar1|bar2|bar3)*))))},
		content	=> q{<foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{((foo3|foo4|bar1|bar2|bar3)*,((foo1,(foo3|foo4|bar1|bar2|bar3)*,(foo2,(foo3|foo4|bar1|bar2|bar3)*)?)|(foo2,(foo3|foo4|bar1|bar2|bar3)*,(foo1,(foo3|foo4|bar1|bar2|bar3)*))))},
		content	=> q{<foo1/><foo2/>},
		result	=> 1,
	},
	{
		model	=> q{((foo3|foo4|bar1|bar2|bar3)*,((foo1,(foo3|foo4|bar1|bar2|bar3)*,(foo2,(foo3|foo4|bar1|bar2|bar3)*)?)|(foo2,(foo3|foo4|bar1|bar2|bar3)*,(foo1,(foo3|foo4|bar1|bar2|bar3)*))))},
		content	=> q{<foo3/><foo2/>},
		result	=> 0,
	},
	{
		model	=> q{((foo3|foo4|bar1|bar2|bar3)*,((foo1,(foo3|foo4|bar1|bar2|bar3)*,(foo2,(foo3|foo4|bar1|bar2|bar3)*)?)|(foo2,(foo3|foo4|bar1|bar2|bar3)*,(foo1,(foo3|foo4|bar1|bar2|bar3)*))))},
		content	=> q{<foo3/><foo2/><foo1/>},
		result	=> 1,
	},
	{
		model	=> q{((foo3|foo4|bar1|bar2|bar3)*,((foo1,(foo3|foo4|bar1|bar2|bar3)*,(foo2,(foo3|foo4|bar1|bar2|bar3)*)?)|(foo2,(foo3|foo4|bar1|bar2|bar3)*,(foo1,(foo3|foo4|bar1|bar2|bar3)*))))},
		content	=> q{<foo3/><foo2/><foo1/><foo3/>},
		result	=> 1,
	},
	{
		model	=> q{((foo3|foo4|bar1|bar2|bar3)*,((foo1,(foo3|foo4|bar1|bar2|bar3)*,(foo2,(foo3|foo4|bar1|bar2|bar3)*)?)|(foo2,(foo3|foo4|bar1|bar2|bar3)*,(foo1,(foo3|foo4|bar1|bar2|bar3)*))))},
		content	=> q{<foo2/><foo2/><foo1/><foo3/>},
		result	=> 0,
	},
	{
		model	=> q{((foo3|foo4|bar1|bar2|bar3)*,((foo1,(foo3|foo4|bar1|bar2|bar3)*,(foo2,(foo3|foo4|bar1|bar2|bar3)*)?)|(foo2,(foo3|foo4|bar1|bar2|bar3)*,(foo1,(foo3|foo4|bar1|bar2|bar3)*))))},
		content	=> q{<foo2/><bar2/><foo1/><foo1/>},
		result	=> 0,
	},
	{
		name	=> q{Real world example: html:table (XHTML 1.0 Strict) (foo1 == html:caption, foo2 == html:col, foo3 == html:colgroup, foo4 == html:thead, bar1 == html:tfoot, bar2 == html:tbody, bar3 == html:tr)},
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{<foo1/><foo2/><foo2/><foo2/><foo4/><bar1/><bar2/><bar2/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{<foo2/><foo2/><foo2/><foo4/><bar1/><bar2/><bar2/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{<foo2/><foo2/><bar1/><bar2/><bar2/><bar2/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{<foo2/><foo3/><bar1/><bar2/><bar2/><bar2/><bar3/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{<foo2/><foo2/><bar1/><bar3/><bar3/><bar3/><bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{<foo2/><foo3/><bar1/><bar3/><bar3/><bar3/><foo4/>},
		result	=> 0,
	},
	{
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{<bar3/>},
		result	=> 1,
	},
	{
		model	=> q{(foo1?,(foo2*|foo3*),foo4?,bar1?,(bar2+|bar3+))},
		content	=> q{},
		result	=> 0,
	},
);

my $error_text = '';
require Message::Markup::XML::Parser;
require Message::Markup::XML::Validate;
my $p = Message::Markup::XML::Parser->new (option => {
  error_handler => sub {
  	my ($caller, $o, $error_type, $error_msg) = @_;
  	$error_text .= ('{'.$error_type->{level}.'} '.$error_msg) . "\n";
  	return 0;
  },
});
my $validator = Message::Markup::XML::Validate->new (option => {
  error_handler => sub {
  	my ($self, $node, $error_type, $error_msg, $err) = @_;
  	$error_text .= ('{'.$error_type->{level}.'} '.$error_msg) . "\n";
  	return 0;
  },
});

require Test::Simple;
Test::Simple->import (tests => scalar @testdata);
for (@testdata) {
  my $ts = $s;
  $ts =~ s/%model;/$_->{model}/g;
  $ts =~ s/&content;/$_->{content}/g;
  my $r = $p->parse_text ($ts);
  my $valid = $validator->validate ($r);
  ok ($_->{result} == $valid, sprintf '"%s" : %s', ($_->{name} || $_->{model}), ($valid ? 'Valid' : 'Invalid'));
  unless ($_->{result} == $valid) {
    $r->remove_references;
    print $error_text,"\n";
    print $r,"\n";
  }
  $error_text = '';
}
