
=head1 NAME

Message::Field::Domain --- A perl module for an Internet
domain name which is part of Internet Messages

=cut

package Message::Field::Domain;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

%REG = %Message::Util::REG;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_ARRAY_NAME	=> 'value',
    -_MEMBERS	=> [qw|type port|],
    -_METHODS	=> [qw|reverse type port value|],
    -allow_special_name	=> 1,	## not implemented yet
    -allow_special_ipv4	=> 1,	##
    -allow_special_ipv6	=> 1,	##
    -encoding_after_encode	=> 'unknown-8bit',
    -encoding_before_decode	=> 'unknown-8bit',
    #field_param_name
    #field_name
    -fill_default_name	=> 1,	## host / "1" / perl-false
    -fill_default_port	=> 0,
    -fill_default_value	=> 0,
    #format
    -format_ipv4	=> '[%vd]',
    -format_ipv6	=> '[IPv6:%s]',
    -format_name	=> '%s',
    -format_name_literal	=> '[%s]',
    #hook_encode_string
    #hook_decode_string
    -output_comment	=> 0,
    -output_port	=> 0,
    -separator	=> '.',
    -use_comment	=> 0,
    -use_domain_literal	=> 1,
    -use_ipv4_address	=> 1,
    -use_ipv6_address	=> 1,
    -use_port	=> 0,
  );
sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, @_);
}

=item $addr = Message::Field::Domain->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $addr = Message::Field::Domain->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  ($body, @{$self->{comment}})
    = $self->Message::Util::delete_comment_to_array ($body)
    if $self->{option}->{use_comment};
  my @d;
  $body =~ s{ $REG{FWS} : $REG{FWS} ([0-9]+) $ $REG{FWS} }{
    $self->{port} = $1;
  ''}ex if $self->{option}->{use_port};
  $body =~ s{($REG{domain_literal}|[^\x5B\x2E])+}{
    my ($d, $isd) = ($&, 0);
    $d =~ s/^$REG{WSP}+//;  $d =~ s/$REG{WSP}+$//;
    ($d, $isd) = Message::Util::unquote_if_domain_literal ($d);
    my %s = &{$self->{option}->{hook_decode_string}}
        ($self, $d, type => 'domain'.($isd?'/literal':''));
    push @d, $s{value};
  }gex;
  if ($self->{option}->{use_ipv4_address} && @d == 1 && $d[0] =~ /^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/) {
    $d[0] = pack 'C4', $1, $2, $3, $4;
    $self->{type} = 'ipv4';
  } elsif ($self->{option}->{use_ipv6_address} && @d == 1 && $d[0] =~ s/^IPv6://i) {
    $self->{type} = 'ipv6';
  } elsif ($self->{option}->{use_ipv6_address} && @d == 1 && $d[0] !~ /[^0-9:.]/) {
    $self->{type} = 'ipv6';
  } elsif ($self->{option}->{use_ipv4_address} && @d == 4) {
    if  ($d[0] !~ /[^0-9]/ && 0 <= $d[0] && $d[0] < 256
     &&  $d[1] !~ /[^0-9]/ && 0 <= $d[1] && $d[1] < 256
     &&  $d[2] !~ /[^0-9]/ && 0 <= $d[2] && $d[2] < 256
     &&  $d[3] !~ /[^0-9]/ && 0 <= $d[3] && $d[3] < 256) {
      $self->{type} = 'ipv4';
      @d = (pack ('C4', @d));
    }
  }
  $self->{type} ||= 'name';
  $self->{value} = \@d;
  $self;
}

sub reverse ($) {$_[0]->{value} = [reverse @{$_[0]->{value}}];$_[0]}
sub type ($;$) {
  my $self = shift;
  my $newtype = shift;
  if ($newtype) {
    $self->{type} = $newtype;
  }
  $self->{type};
}

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $s = '';
  if ($option{use_ipv6_address} && $self->{type} eq 'ipv6') {
    $s = sprintf $option{format_ipv6}, $self->{value}->[0];
  } elsif ($option{use_ipv4_address} && $self->{type} eq 'ipv4') {
    $s = sprintf $option{format_ipv4}, $self->{value}->[0];
  } else {
    my $dl = 0;
    my $d = join $option{separator}, map {
      my %s = &{$option{hook_encode_string}} ($self, 
          $_, type => 'domain');
      if ($option{use_domain_literal} && $s{value} =~ /$REG{NON_atext}/) {
        $s{value} =~ s/[\x5B-\x5D]/\x5C$&/g;
        $s{value} = sprintf $option{format_name_literal}, $s{value};
      }
      $s{value};
    } @{$self->{value}};
    if ($option{fill_default_value} && !length $d) {
      if ($option{fill_default_name} == 1) {
        $d = Message::Util::get_host_fqdn;
      } else {
        $d = $option{fill_default_name};
      }
    }
    $s = sprintf $option{format_name}, $d;
  }
  if ($option{use_port} && $option{output_port}) { 
    my $port = $self->{port};
    $port = $option{fill_default_port} if !$port && $option{fill_default_value};
    $s .= ':' . (0+$self->{port}) if $port;
  }
  if ($option{use_comment} && $option{output_comment}) {
    my $c = $self->_comment_stringify;
    $s .= ' ' . $c if $c;
  }
  $s;
}

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
$Date: 2002/08/05 09:33:18 $

=cut

1;
