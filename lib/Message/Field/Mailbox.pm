
=head1 NAME

Message::Field::Mailbox --- A perl module for an Internet
mail address (mailbox) which is part of Internet Messages

=cut

package Message::Field::Mailbox;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::AngleQuoted;
push @ISA, qw(Message::Field::AngleQuoted);

%REG = %Message::Util::REG;
	$REG{sub_domain} = qr/$REG{atext}|$REG{domain_literal}/;
	$REG{domain} = qr/$REG{sub_domain}(?:$REG{FWS}\.$REG{FWS}$REG{sub_domain})*/;
	$REG{route} = qr/\x40$REG{FWS}$REG{domain}(?:[\x09\x20,]*\x40$REG{FWS}$REG{domain})*$REG{FWS}:/;

%DEFAULT = (
    -_ARRAY_NAME	=> 'route',
    -_ARRAY_VALTYPE	=> 'domain',
    -_MEMBERS	=> [qw|display_name route local_part domain keyword|],
    -_METHODS	=> [qw|addr_spec display_name local_part domain keyword
                       have_group comment_add comment_delete comment_item
                       comment_count route_add route_count route_delete
                       route_item|],
    -allow_empty	=> 0,
    -by	=> 'domain',
    -comment_to_display_name	=> 1,
    -default_domain	=> 'localhost',
    #encoding_after_encode
    #encoding_before_decode
    #-encoding_after_encode_domain	=> 'unknown-8bit',
    #-encoding_before_decode_domain	=> 'unknown-8bit',
    -encoding_after_encode_local_part	=> 'unknown-8bit',
    -encoding_before_decode_local_part	=> 'unknown-8bit',
    #field_param_name
    #field_name
    -fill_domain	=> 1,
    #format
    #hook_encode_string
    #hook_decode_string
    -must_have_addr_spec	=> 1,
    #output_angle_bracket	=> 1,
    #output_comment	=> 1,
    #output_display_name	=> 1,
    #output_keyword	=> 0,
    -output_route	=> 0,
    #parse_all	=> 0,	## = parse_domain + parse_local_part
    -parse_domain	=> 0,
    -parse_local_part	=> 0,	## not implemented.
    #unsafe_rule_of_display_name	=> 'NON_http_attribute_char_wsp',
    -unsafe_rule_of_local_part	=> 'NON_http_attribute_char_wsp',
    #unsafe_rule_of_keyword	=> 'NON_atext',
    -use_comment_in_angle	=> 1,
    #use_keyword	=> 0,
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## $self->_init (%options); Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %options);
  $self->{option}->{value_type}->{domain} = ['Message::Field::Domain', {
      #-encoding_after_encode => $self->{option}->{encoding_after_encode_domain},
      #-encoding_before_decode => $self->{option}->{encoding_before_decode_domain},
  },];
  
  my $format = $self->{option}->{format};
  my $field = $self->{option}->{field_name};
  if ($format =~ /mail-rfc822/) {
    $self->{option}->{output_route} = 1
      if $field eq 'from' || $field eq 'resent-from'
      || $field eq 'sender' || $field eq 'resent-sender'
      || $field eq 'to' || $field eq 'cc' || $field eq 'bcc'
      || $field eq 'resent-to' || $field eq 'resent-cc'
      || $field eq 'resent-bcc' || $field eq 'reply-to'
      || $field eq 'resent-reply-to' || $field eq 'return-path';
  }
  if ($field eq 'mail-copies-to') {
    $self->{option}->{use_keyword} = 1;
    $self->{option}->{output_keyword} = 1;
  }
  if ($field eq 'return-path') {
    $self->{option}->{allow_empty} = 1;
    $self->{option}->{allow_empty} = 0
      if $format =~ /rfc822/ && $format !~ /rfc1123/;
    $self->{option}->{output_display_name} = 0;
    $self->{option}->{output_comment} = 0
      if $format =~ /smtp/;
    	## RFC [2]822 allows CFWS, but [2]821 does NOT.
  }
  #if ($format =~ /http/) {
  #  $self->{option}->{unsafe_rule_local_part} = 'NON_http_attribute_char_wsp';
  #}
}

=item $m = Message::Field::Mailbox->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $m = Message::Field::Mailbox->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

## $self->_save_value ($value, $display_name, \@comment)
sub _save_value ($$\@%) {
  my $self = shift;
  my ($v, $dn, $comment, %misc) = @_;
  my $parse_lp = $self->{option}->{parse_local_part}
              || $self->{option}->{parse_all};
  my $parse_dm = $self->{option}->{parse_domain}
              || $self->{option}->{parse_all};
  $v = Message::Util::remove_meaningless_wsp ($v);
  if ($v =~ /^($REG{route})?((?:$REG{quoted_string}|[^\x22])+?)\x40((?:$REG{domain_literal}|[^\x5B\x40])+)$/) {
    my $route = $1;
    $self->{local_part} = $2; $self->{domain} = $3;
    $self->{domain} = $self->_parse_value ('domain' => $self->{domain})
      if $parse_dm;
    $route =~ s{\x40$REG{FWS}($REG{domain})}{
      my $d = $1;
      $d = $self->_parse_value (domain => $d) if $parse_dm;
      push @{$self->{route}}, $d;
    }gex;
  } elsif (length $v) {
    $self->{local_part} = $v;
  }
  $self->{local_part}
    = $self->Message::Util::decode_quoted_string ($self->{local_part}, 
      type => 'word',
      charset => $self->{option}->{encoding_before_decode_local_part});
  $self->{comment} = $comment;
  $self->{display_name} = $dn;
  $self->{keyword} = $misc{keyword};
}

## display_name: Inherited

sub local_part ($;$) {
  my $self = shift;
  my $newlp = shift;
  $self->{local_part} = $newlp if defined $newlp;
  $self->{local_part};
}

sub domain ($;$) {
  my $self = shift;
  my $newdomain = shift;
  if (defined $newdomain) {
    $newdomain = $self->_parse_value (domain => $newdomain)
      if $self->{option}->{parse_domain} || $self->{option}->{parse_all};
    $self->{domain} = $newdomain;
  }
  $self->{domain};
}

sub keyword ($;$) {
  my $self = shift;
  return unless $self->{option}->{use_keyword};
  my $newkey = shift;
  $self->{keyword} = $newkey if defined $newkey;
  $self->{keyword};
}

sub value ($;$) {
  my $self = shift;
  my $v = shift;
  if ($v =~ /^((?:$REG{quoted_string}|[^\x22])+?)\x40((?:$REG{domain_literal}|[^\x5B\x40])+)$/) {
    $self->{local_part} = $1; $self->{domain} = $2;
    $self->{domain} = $self->_parse_value (domain => $self->{domain})
      if $self->{option}->{parse_domain} || $self->{option}->{parse_all};
    $self->{local_part}
      = $self->Message::Util::decode_quoted_string ($self->{local_part}, 
        type => 'word',
        charset => $self->{option}->{encoding_before_decode_local_part});
  }
  defined wantarray? $self->addr_spec:'';
}

sub route_add ($@) { shift->SUPER::add (@_) }
sub route_count ($@) { shift->SUPER::count (@_) }
sub route_delete ($@) { shift->SUPER::delete (@_) }
sub route_item ($@) { shift->SUPER::item (@_) }

sub _delete_match ($$$\%\%) {
  my $self = shift;
  my ($by, $i, $list, $option) = @_;
  return 0 unless ref $$i;	## Already removed
  return 0 if $$option{type} && $$i->{type} ne $$option{type};
  if ($by eq 'domain') {
    $$i = $self->_parse_value (domain => $$i);
    return 1 if $list->{$$i};
  }
  0;
}
*_item_match = \&_delete_match;

## Returns returned item value    \$item-value, \%option
sub _item_return_value ($\$\%) {
  if (ref ${$_[1]}) {
    ${$_[1]};
  } else {
    ${$_[1]} = $_[0]->_parse_value (domain => ${$_[1]});
    ${$_[1]};
  }
}
sub _item_new_value ($$\%) {
  $_[0]->_parse_value (domain => ($_[2]->{by} eq 'domain'? $_[1]: ''));
}

sub have_group ($) { 0 }

sub addr_spec ($;%) {
  my $self = shift;
  my %o = (
    -output_angle_bracket	=> 0,
    -output_comment	=> 0,
    -output_display_name	=> 0,
    -output_keyword	=> 0,
    -output_route	=> 0,
  );
  $self->stringify (%o, @_);
}
#*value = \&addr_spec;

## $self->_stringify_value (\%option)
sub _stringify_value ($\%) {
  my $self = shift;
  my $option = shift;
  my %r;
    my %s = &{$option->{hook_encode_string}} ($self, 
          $self->{local_part}, type => 'word',
          charset => $option->{encoding_after_encode_local_part});
    my $as = Message::Util::quote_unsafe_string ($s{value}, 
            unsafe => $option->{unsafe_rule_local_part});
    my $d = '' . $self->{domain};
    $d ||= $option->{default_domain} if $option->{fill_domain};
    $as .= '@' . $d if length $d && length $as;
      if ($option->{output_angle_bracket}) {
        if ($option->{output_route}) {
          my $route = join ',', grep {$_ ne '@'}
            map {'@'.$_} @{$self->{route}};
          $as = $route . ':' . $as if $route;
        }
      }
  $r{value} = $as;
  $r{display_name} = $self->{display_name};
  $r{comment} = $self->{comment};
  $r{keyword} = $self->{keyword};
  %r;
}

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  for (@{$self->{route}}) {
    $_->option (%$o) if ref $_;
  }
  $self->{local_part}->option (%$o) if ref $self->{local_part};
  $self->{domain}->option (%$o) if ref $self->{domain};
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
$Date: 2002/06/23 12:10:16 $

=cut

1;
