#!/usr/bin/perl -w 
use strict;

use lib qw<lib ../lib>;

use Message::Util::QName::Filter {
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
};

use Getopt::Long;
use Pod::Usage;
use Storable;
my %Opt;
GetOptions (
  'help' => \$Opt{help},
  'verbose!' => $Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};

BEGIN {
require 'manakai/genlib.pl';
require 'manakai/dis.pl';
}
our $State = retrieve ($Opt{file_name})
     or die "$0: $Opt{file_name}: Cannot load";

eval q{
  sub impl_msg ($;%) {
    warn shift () . "\n";
  }
} unless $Opt{verbose};


my $Method;
my $Attr;

for my $res (values %{$State->{Type}}) {
  next unless defined $res->{ExpandedURI q<dis2pm:type>};
  next unless length $res->{Name};
  if ({
        ExpandedURI q<ManakaiDOM:IF> => 1,
        ExpandedURI q<ManakaiDOM:ExceptionIF> => 1,
       }->{$res->{ExpandedURI q<dis2pm:type>}}) {
    for my $mtd (values %{$res->{ExpandedURI q<dis2pm:method>}||{}}) {
      next unless defined $mtd->{ExpandedURI q<dis2pm:type>};
      next unless length $mtd->{Name};
      if ($mtd->{ExpandedURI q<dis2pm:type>} eq
          ExpandedURI q<ManakaiDOM:DOMMethod>) {
        $Method->{$res->{Name}}->{$mtd->{Name}} = my $param = [];
        for my $prm (@{$mtd->{ExpandedURI q<dis2pm:param>}||[]}) {
          next unless defined $prm->{Name};
          push @$param, $prm->{Name}
            if $prm->{ExpandedURI q<dis2pm:type>} eq
               ExpandedURI q<ManakaiDOM:DOMMethodParameter>;
        }
      } elsif ($mtd->{ExpandedURI q<dis2pm:type>} eq
               ExpandedURI q<ManakaiDOM:DOMAttribute>) {
        $Attr->{$res->{Name}}->{$mtd->{Name}} = 1;
      }
    }
  }
}

our $result = '';
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

mkdommemlist.pl - DOM Method and Attribute List Generator

=head1 SYNOPSIS

  perl mkdommemlist.pl source.cdis > list.pl

=head1 DESCRIPTION

The DOM Test Suite by W3C stores its test codes in the abstract programming 
language based on XML and they do not have information on what is method, 
what is attribute, in what order parameters should be 
passed to methods, and so on.

The C<mkdommemlist.pl> generates lists of method, attributes and 
parameters for methods from the "cdis" files and write it 
out as a Perl script, so that other script, such as 
L<domtest2perl.pl>, can use this information.

=head1 SEE ALSO

I<Document Object Model (DOM) Conformance Test Suites>,
<http://www.w3.org/DOM/Test/>.

L<domtest2perl.pl>.

C<Makefile>.

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# $Date: 2004/12/31 12:03:39 $
