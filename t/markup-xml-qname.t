#!/usr/bin/perl
use strict;
require Test::Simple;
require Message::Markup::XML;
use Message::Markup::XML::QName qw/UNDEF_URI NULL_URI DEFAULT_PFX/;
sub ok ($;$);
my $e = new Message::Markup::XML (type => '#element', local_name => 'test',
	                          namespace_uri => 'http://something.test/');
use Carp q(verbose);
my @reg_p2n = (
               {
                prefix => q(test1),
                name   => q(http://test1.example/),
                result => 1,
               },
               {
                prefix => q(test1),
                name   => q(http://test1.example/),
                result => 1,
               },
               {
                prefix => q(test1),
                name   => q(http://test1.example/),
                opt    => {check_registered => 1},
                result => 1,
               },
               {
                prefix => q(test1),
                name   => q(http://test2.example/),
                opt    => {check_registered => 1},
                result => 0,
               },
               {
                prefix => q(test1),
                name   => q(http://test2.example/),
                result => 1,
               },
               {
                prefix => q(test1),
                name   => q(),
                result => 0,
               },
               {
                prefix => q(test1),
                name   => NULL_URI,
                result => 0,
               },
               {
                prefix => q(#default),
                name   => q(http://test2.example/),
                result => 1,
               },
               {
                prefix => DEFAULT_PFX,
                name   => q(http://test2.example/),
                result => 1,
               },
               {
                prefix => DEFAULT_PFX,
                name   => NULL_URI,
                result => 1,
               },
               {
                prefix => q:some-prefix:,
                name   => UNDEF_URI,
                result => 0,
               },
               {
                prefix => q:some-prefix:,
                name   => q<http://uri.test/>,
                opt    => {check_prefix => 1},
                result => 1,
               },
               {
                prefix => q:some invalid prefix:,
                name   => q<http://uri.test/>,
                opt    => {check_prefix => 1},
                result => 0,
               },
               {
                prefix => q:some-prefix-11:,
                name   => q<http://uri.test/>,
                opt    => {check_name => 1},
                result => 1,
               },
               {
                prefix => q:some-prefix-21:,
                name   => q<relative-uri>,
                opt    => {check_name => 1, check_name_uri_relative => 1},
                result => 0,
               },
               {
                prefix => q:some-prefix-31:,
                name   => q<relative-uri>,
                opt    => {check_name => 1, resolve_name_uri_relative => 1},
                result => 1,
               },
);

my @get_p2n = (
               {
                prefix => q:prefix-1.:,
                name   => q<http://foo.test/>,
                result => 1,
               },
               {
                prefix => q:prefix-2.:,
                name   => q<http://foo2.test/>,
                opt    => {___dont_register => 1},
                result => 0,
               },
               {
                prefix => q:prefix-2.:,
                name   => NULL_URI,
                opt    => {___dont_register => 1},
                result => 0,
               },
               {
                prefix => q:prefix-2.:,
                name   => UNDEF_URI,
                opt    => {___dont_register => 1},
                result => 0,
               },
               {
                prefix => DEFAULT_PFX,
                name   => UNDEF_URI,
                opt    => {___dont_register => 1},
                result => 0,
               },
               {
                prefix => DEFAULT_PFX,
                name   => NULL_URI,
                result => 0,
               },
               {
                prefix => DEFAULT_PFX,
                name   => NULL_URI,
                opt    => {use_name_null => 1, use_prefix_default => 1},
                result => 1,
               },
               {
                prefix => DEFAULT_PFX,
                name   => NULL_URI,
                opt    => {___dont_register => 1},
                result => 0,
               },
               {
                prefix => DEFAULT_PFX,
                name   => NULL_URI,
                opt    => {use_name_null => 1, use_prefix_default => 1,
                           ___dont_register => 1},
                result => 1,
               },
);

my @qname = (
             {
              qname  => q"foo",
              prefix => DEFAULT_PFX,
              lname  => q"foo",
              result => 1,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1},
             },
             {
              qname  => q"foo:bar",
              prefix => q"foo",
              lname  => q"bar",
              result => 1,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1},
             },
             {
              qname  => q"foo:0",
              prefix => q"foo",
              lname  => q"0",
              result => 0,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1},
             },
             {
              qname  => q"0:bar",
              prefix => q"0",
              lname  => q"bar",
              result => 0,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1},
             },
             {
              qname  => q"foo:",
              prefix => q"foo",
              lname  => q"",
              result => 0,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1},
             },
             {
              qname  => q":bar",
              join_qname => q"bar",
              prefix => DEFAULT_PFX,
              lname  => q"bar",
              result => 0,
              join_result => 1,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1},
             },
             {
              qname  => q"*",
              prefix => DEFAULT_PFX,
              lname  => q"*",
              result => 1,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1, use_local_name_star => 1},
             },
             {
              qname  => q"foo:*",
              prefix => q"foo",
              lname  => q"*",
              result => 1,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1, use_local_name_star => 1},
             },
             {
              qname  => q"foo|bar",
              prefix => q:foo:,
              lname  => q:bar:,
              result => 1,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1, qname_separator => '|'},
             },
             {
              qname  => q"foo|*",
              prefix => q:foo:,
              lname  => q:*:,
              result => 1,
              opt    => {check_qname => 1, check_prefix => 1,
                         check_local_name => 1, qname_separator => '|',
                         use_local_name_star => 1},
             },
);

my @gen_pfx = (
	       {
                reset  => 1,
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => DEFAULT_PFX,
                opt    => {use_prefix_default => 1},
	       },
               {
                reset  => 0,
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:h:,
                n2p    => DEFAULT_PFX,
                opt    => {use_prefix_default => 1},
               },
               {
                reset  => 1,
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:h:,
                opt    => {use_prefix_default => 0},
               },
               {
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:h1:,
                n2p    => q:h:,
               },
               {
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:xhtml:,
                n2p    => q:h:,
               },
               {
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:xhtml1:,
                n2p    => q:h:,
               },
               {
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:www.w3.org:,
                n2p    => q:h:,
               },
               {
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:http:,
                n2p    => q:h:,
               },
               {
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:ns0:,
                n2p    => q:h:,
               },
               {
                name   => q<http://www.w3.org/1999/xhtml>,
                prefix => q:ns1:,
                n2p    => q:h:,
               },
               {
                name   => q<http://uri.example/b>,
                prefix => q:b:,
               },
               {
                name   => q<http://uri.example/bc>,
                prefix => q:bc:,
               },
               {
                name   => q<http://uri.example/01w>,
                prefix => q:w:,
               },
               {
                name   => q<test/0name/xmlns>,
                prefix => q:name:,
               },
               {
                name   => q<test/0name/xmlns>,
                prefix => q:test:,
                n2p    => q:name:,
               },
               {
                reset  => 1,
                name   => q<:///:04465612@&>,
                prefix => q:ns0:,
               },
               {
                reset  => 1,
                name   => NULL_URI,
                prefix => DEFAULT_PFX,
                opt    => {use_prefix_default => 1},
               },
               {
                reset  => 0,
                name   => NULL_URI,
                prefix => DEFAULT_PFX,
                opt    => {use_prefix_default => 1},
               },
               {
                reset  => 1,
                name   => NULL_URI,
                prefix => DEFAULT_PFX,
                opt    => {use_prefix_default => 0},
               },
              );

my @expand = (
              {
               reset   => 1,
               ns      => {foo => q<http://foo.test/>},
               qname   => q"foo:bar",
               xname   => [q<http://foo.test/> => q:bar:],
              },
              {
               reset   => 0,
               qname   => q"foo:bar",
               xname   => [q<http://foo.test/> => q:bar:],
              },
              {
               reset   => 0,
               qname   => q"bar",
               xname   => [NULL_URI, q:bar:],
               opt     => {use_prefix_default => 1, use_name_null => 1},
              },
);

Test::Simple->import (tests => scalar (@reg_p2n)
                             + scalar (@get_p2n) * 2
                             + scalar (@qname) * 2
                             + scalar (@gen_pfx) * 2
                             + scalar (@expand) * 2);
eval q{
sub ok ($;$) {
  my ($cond, $desc) = @_;
  if ($cond) {
    Test::Simple::ok (1);
  } else {
    Test::Simple::ok (0, $desc);
  }
}};

for (@reg_p2n) {
  my $chk = Message::Markup::XML::QName::register_prefix_to_name
    ($e, $_->{prefix} => $_->{name}, %{$_->{opt}||{}});
  ok ($chk->{success} == $_->{result}, 'Register pfx->URI: '.$chk->{reason});
}
               
for (@get_p2n) {
  $e->{ns} = {};
  my $chk = Message::Markup::XML::QName::register_prefix_to_name
    ($e, $_->{prefix} => $_->{name}, %{$_->{opt}||{}})
      unless $_->{opt}->{___dont_register};
  ok (Message::Markup::XML::QName::prefix_to_name ($e, $_->{prefix},
                                                   %{$_->{opt}||{}})
      ->{name}
      eq ($_->{result} ? ($_->{result_name} || $_->{name}) : undef),
      ":$_->{prefix}: => <@{[$_->{result} ? ($_->{result_name} || $_->{name}) : undef]}>");
  ok (Message::Markup::XML::QName::name_to_prefix ($e, $_->{name},
                                                   %{$_->{opt}||{}})
      ->{prefix}
      eq ($_->{result} ? ($_->{result_prefix} || $_->{prefix}) : undef),
      "<$_->{name}> => :@{[$_->{result} ? ($_->{result_prefix} || $_->{prefix}) : undef]}:");
}

               
for (@qname) {
  my $chk = Message::Markup::XML::QName::split_qname ($_->{qname},
                                                      %{$_->{opt}||{}});
  if ($_->{result}) {
    ok $chk->{prefix}.':'.($chk->{local_name_star} ? '*' : $chk->{local_name})
    eq $_->{prefix} . ':' . $_->{lname},
      "Split 1: $_->{qname} => $chk->{prefix}:$chk->{local_name}($chk->{local_name_star})";
  } else {
    ok $chk->{success} == $_->{result},
      "Split 0: $_->{qname} => $chk->{prefix}:$chk->{local_name}($chk->{local_name_star})";
  }
  
  $chk = Message::Markup::XML::QName::join_qname
    ($_->{prefix}, $_->{lname}, %{$_->{opt}||{}});
  if (defined $_->{join_result} ? $_->{join_result} : $_->{result}) {
    ok $chk->{qname} eq ($_->{join_qname} || $_->{qname}), qq(Join 1: "$_->{prefix}":"$_->{lname}" => "$chk->{qname}" ("@{[$_->{join_qname} || $_->{qname}]}" expected));
  } else {
    ok $chk->{success} == ((defined $_->{join_result} and $_->{join_result}) or $_->{result}),
       "Join 0: $chk->{success}; $_->{prefix}, $_->{lname} => $chk->{qname}";
  }
}

for (@gen_pfx) {
  $e->{ns} = {} if $_->{reset};
  my $pfx = Message::Markup::XML::QName::generate_prefix ($e, $_->{name},
                                                          %{$_->{opt}||{}});
  if ($pfx eq $_->{prefix}) {
    my $chk = Message::Markup::XML::QName::register_prefix_to_name
                ($e, $pfx => $_->{name});
    ok $chk->{success}, 'Generate pfx: '.$chk->{reason};
  } else {
    ok $pfx eq $_->{prefix}, "Generate pfx: :$pfx: (expected :$_->{prefix}:";
  }
}

for (@gen_pfx) {
  $e->{ns} = {} if $_->{reset};
  my $chk = Message::Markup::XML::QName::name_to_prefix ($e, $_->{name},
                                                         %{$_->{opt}||{}},
                                                         make_new_prefix => 1);
  ok $chk->{success} && ($chk->{prefix} eq ($_->{n2p} || $_->{prefix})),
     "URI->Pfx: $chk->{prefix} (@{[$_->{n2p} || $_->{prefix}]} is expected; $chk->{reason})";
}

for (@expand) {
  $e->{ns} = {} if $_->{reset};
  for my $pfx (keys %{$_->{ns}||{}}) {
    Message::Markup::XML::QName::register_prefix_to_name
        ($e, $pfx => $_->{ns}->{$pfx}, %{$_->{opt}||{}});
  }
  my $chk = Message::Markup::XML::QName::qname_to_expanded_name 
              ($e, $_->{qname}, %{$_->{opt}||{}});
  ok $chk->{success} && ($_->{xname}->[0] eq $chk->{name}
                     && $_->{xname}->[1] eq $chk->{local_name}),
     qq(QName->expand: <$chk->{name}> (should be <$_->{xname}->[0]>), "$chk->{local_name}" (should be "$_->{xname}->[1]") (prefix "$chk->{prefix}"; $chk->{reason}));
}

for (@expand) {
  $e->{ns} = {} if $_->{reset};
  for my $pfx (keys %{$_->{ns}||{}}) {
    Message::Markup::XML::QName::register_prefix_to_name
        ($e, $pfx => $_->{ns}->{$pfx}, %{$_->{opt}||{}});
  }
  my $chk = Message::Markup::XML::QName::expanded_name_to_qname
              ($e, $_->{xname}->[0], $_->{xname}->[1], %{$_->{opt}||{}});
  ok $chk->{success} && ($_->{qname} eq $chk->{qname}), 'Expand->QName: '.$chk->{reason};
}

print $e;
