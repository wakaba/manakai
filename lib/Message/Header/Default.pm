
=head1 NAME

Message::Header::Default --- Internet Messages -- Definition
for Default Namespace of Header Fields

=cut

package Message::Header::Default;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Header;

our %OPTION;

## Case sensibility of field name
$OPTION{case_sensible} = 1;
#$OPTION{to_be_goodcase} = \&...;
$OPTION{n11n_name} = \&_name_n11n;
$OPTION{n11n_prefix} = \&_name_n11n;

## Namespace URI of this namespace
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:default';

## Force & hyphened prefix name of this namespace (ex. "prefix-name")
$OPTION{use_ph_namespace} = 1;
$OPTION{namespace_phname} = 'default';
$OPTION{namespace_phname_goodcase} = 'default';

## `Good' & dotted prefix name of this namespace (ex. "prefix.name", "prefix2.name")
$OPTION{namespace_good_prefix} = 'DEFAULT';

## Sort fields (0 / 'alphabetic' / ref(CODE)
$OPTION{field_sort} = 0;

## Field body data type (specified by package name)
$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
};

## mailto: URL safe level
$OPTION{uri_mailto_safe}	= {
  ## 1 all (no check)	2 no trace & bcc & from
  ## 3 no sender's info	4 (default) (currently not used)
  ## 5 only a few
	':default'	=> 1,
};

## 

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

## $self->_goodcase ($namespace_package_name, $field_name, \%option)
sub _goodcase ($$$\%) {
  no strict 'refs';
  my $self = shift;
  my ($nspack, $name, $option) = @_;
  if (${$nspack.'::OPTION'}{goodcase}->{$name}) {
    return ${$nspack.'::OPTION'}{goodcase}->{$name};
  }
  $name =~ s/(?:^|-)[a-z]/uc $&/ge;
  $name;
}

sub _name_n11n ($$$) {
  no strict 'refs';
  my $self = shift;
  my $nspack = shift;
  my $name = shift;
  unless (${$nspack.'::OPTION'}{case_sensible}) {
    lc $name;
  } else {
    $name;
  }
}

sub sort_good_practice ($$\@\%) {
  my ($hdr, $array, $nspack, $option) = @_;
  if ($option->{field_sort} eq 'good-practice') {
    no strict 'refs';
    my $order = ${ $nspack.'::OPTION' }{field_sort_good_practice_order};
    my $mynsuri = ${ $nspack.'::OPTION' }{namespace_uri};
    my $mynsprefix = ${ $nspack.'::OPTION' }{namespace_phname};
    return sort {
      if ($a->{ns} eq $b->{ns}) {
        if ($a->{ns} eq $mynsuri) {
          $order->{ $a->{name} } ||= 999;
          $order->{ $b->{name} } ||= 999;
          
          $order->{ $a->{name} } <=> $order->{ $b->{name} }
          || $a->{name} cmp $b->{name};
        } else { #($a->{ns} eq $b->{ns})
          my $nspack = Message::Header::_NS_uri2package ($a->{ns});
          my $sort = ${ $nspack.'::OPTION' }{field_sort};
          if ($sort->{'good-practice'}) {
            my $order = ${ $nspack.'::OPTION' }{field_sort_good_practice_order};
            $order->{ $a->{name} } ||= 999;
            $order->{ $b->{name} } ||= 999;
            
            $order->{ $a->{name} } <=> $order->{ $b->{name} }
            || $a->{name} cmp $b->{name};
          } elsif ($sort->{alphabetic}) {
            $a->{name} cmp $b->{name};
          } else {
            1;	## Isn't supported
          }
        }
      } else {	## $a->{ns} ne $b->{ns}
        if ($a->{ns} eq $mynsuri) {
          my $bp = ($hdr->{ns}->{uri2phname}->{ $b->{ns} } || '~'.$b->{ns}).'-';
          $bp =~ s/^\Q$mynsprefix\E-//;
          $order->{ $a->{name} } ||= 999;
          $order->{ $bp } ||= 999;
          
          $order->{ $a->{name} } <=> $order->{ $bp }
          || $a->{name} cmp $bp;
        } elsif ($b->{ns} eq $mynsuri) {
          my $ap = ($hdr->{ns}->{uri2phname}->{ $a->{ns} } || '~'.$a->{ns}).'-';
          $ap =~ s/^\Q$mynsprefix\E-//;
          $order->{ $ap } ||= 999;
          $order->{ $b->{name} } ||= 999;
          
          $order->{ $ap } <=> $order->{ $b->{name} }
          || $ap cmp $b->{name};
        } else {
          my $ap = ($hdr->{ns}->{uri2phname}->{ $a->{ns} } || '~'.$a->{ns}).'-';
          my $bp = ($hdr->{ns}->{uri2phname}->{ $b->{ns} } || '~'.$b->{ns}).'-';
          $ap =~ s/^\Q$mynsprefix\E-//;
          $bp =~ s/^\Q$mynsprefix\E-//;
          
          $order->{ $ap } ||= 999;
          $order->{ $bp } ||= 999;
          
          $order->{ $ap } <=> $order->{ $bp }
          || $ap cmp $bp;
        }
      }
    } @$array;
  }
  @$array;
}

package Message::Header::XCGI;
our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:http:cgi:x';
$OPTION{namespace_phname} = 'x-cgi';
$OPTION{namespace_phname_goodcase} = 'X-CGI';

$OPTION{case_sensible} = 0;
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;


## 

require Message::Header::RFC822;
require Message::Header::HTTP;
require Message::Header::Message;

=head1 LICENSE

Copyright 2002 wakaba E<lt>w@suika.fam.cxE<gt>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=head1 CHANGE

See F<ChangeLog>.
$Date: 2002/07/28 00:31:38 $

=cut

1;
