#!/usr/bin/perl -w 
use strict;

use lib qw<lib ../lib>;
use Message::Markup::SuikaWikiConfig20::Parser;

our $result = '';

BEGIN {
  require 'manakai/genlib.pl';
}

my $Method;
my $Attr;

for (@ARGV) {
  my $s;
  {
    open my $file, '<', $_;
    local $/ = undef;
    $s = <$file>;
    close $file;
  }
  my $source = Message::Markup::SuikaWikiConfig20::Parser->parse_text ($s);
  
  for (@{$source->child_nodes}) {
    if ($_->node_type eq '#element' and
        $_->local_name eq 'IF') {
      my $if = $_->get_attribute_value ('Name');
      for (@{$_->child_nodes}) {
        if ($_->node_type eq '#element') {
          if ($_->local_name eq 'Method') {
            $Method->{$if}->{$_->get_attribute_value ('Name')} = (my $a = []);
            for (@{$_->child_nodes}) {
              if ($_->node_type eq '#element' and
                  $_->local_name eq 'Param') {
                push @$a, $_->get_attribute_value ('Name');
              }
            }
          } elsif ($_->local_name eq 'Attr') {
            $Attr->{$if}->{$_->get_attribute_value ('Name')} = 1;
          }
        }
      }
    }
  }
}

$result .= perl_statement
             perl_assign
               perl_var
                 (type => '$',
                  local_name => 'Method')
             => perl_literal {
                  map {
                    %{$Method->{$_}}
                  } keys %$Method
                };
$result .= perl_statement
             perl_assign
               perl_var
                 (type => '$',
                  local_name => 'IFMethod')
             => perl_literal {
                  map {
                    $_ => $Method->{$_}
                  } keys %$Method
                };
$result .= perl_statement
             perl_assign
               perl_var
                 (type => '$',
                  local_name => 'Attr')
             => perl_literal {
                  map {$_ => 1}
                  map {
                    keys %{$Attr->{$_}}
                  } keys %$Attr
                };
$result .= perl_statement 1;

output_result $result;

=head1 NAME

mkdommemlist.pl - DOM Method & Attribute List Generator

=head1 SYNOPSIS

  perl mkdommemlist.pl file1.dis [file2.dis...] > list.pl

=head1 DESCRIPTION

The DOM Test Suite by W3C stores its test codes in the abstract 
format based on XML and they by themselves do not have information 
on what is method and what is attribute, nor the order of 
parameters to a method.

The C<mkdommemlist.pl> generates lists of method, attributes and 
parameters for methods from the "dis" files and write it 
out as a Perl script, so that other script, such as 
L<domtest2perl.pl>, can use this information.

=head1 SEE ALSO

I<Document Object Model (DOM) Conformance Test Suites>,
<http://www.w3.org/DOM/Test/>.

L<domtest2perl.pl>.

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# $Date: 2004/10/16 13:34:56 $
