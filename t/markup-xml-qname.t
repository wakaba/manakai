#!/usr/bin/perl
use strict;
require Test::Simple;
require Message::Markup::XML;
use Message::Markup::XML::QName qw/UNDEF_URI NULL_URI DEFAULT_PFX/;
sub ok ($;$);
my $e = new Message::Markup::XML (type => '#element', local_name => 'test',
	                          namespace_uri => 'http://something.test/');

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
              prefix => q"",
              lname  => q"bar",
              result => 0,
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
);

Test::Simple->import (tests => scalar (@reg_p2n)
                             + scalar (@get_p2n) * 2
                             + scalar (@qname) * 2);

for (@reg_p2n) {
  my $chk = Message::Markup::XML::QName::register_prefix_to_name
    ($e, $_->{prefix} => $_->{name}, %{$_->{opt}||{}});
  ok ($chk->{success} == $_->{result}, $chk->{reason});
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
      "$chk->{prefix}:$chk->{local_name}($chk->{local_name_star})";
  } else {
    ok $chk->{success} == $_->{result},
      "$chk->{prefix}:$chk->{local_name}($chk->{local_name_star})";
  }
  
  $chk = Message::Markup::XML::QName::join_qname
    ($_->{prefix}, $_->{lname}, %{$_->{opt}||{}});
  if ($_->{result}) {
    ok $chk->{qname} eq $_->{qname}, $chk->{qname};
  } else {
    ok $chk->{success} == $_->{result}, $chk->{qname};
  }
}

print $e;
