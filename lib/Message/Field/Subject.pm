
=head1 NAME

Message::Field::Subject -- Perl module for Internet
message header C<Subject:> field body

=cut

package Message::Field::Subject;
use strict;
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Unstructured;
push @ISA, q(Message::Field::Unstructured);
use overload '""' => sub {shift->stringify};

*REG = \%Message::Util::REG;
$REG{re} = qr/(?:[Rr][Ee]|[Ss][Vv])\^?\[?[0-9]*\]?:/;
$REG{fwd} = qr/[Ff][Ww][Dd]?:/;
$REG{ml} = qr/[(\[][A-Za-z0-9._-]+[\x20:-][0-9]+[)\]]/;
$REG{M_ml} = qr/[(\[]([A-Za-z0-9._-]+)[\x20:-]([0-9]+)[)\]]/;
$REG{prefix} = qr/(?:$REG{re}|$REG{fwd}|$REG{ml})(?:$REG{FWS}(?:$REG{re}|$REG{fwd}|$REG{ml}))*/;
$REG{M_control} = qr/^cmsg$REG{FWS}([\x00-\xFF]*)$/;
$REG{M_was} = qr/\([Ww][Aa][Ss]:? ([\x00-\xFF]+)\)$REG{FWS}$/;

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Subject> objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    #encoding_after_encode	## Inherited
    #encoding_before_decode	## Inherited
    -format_adv	=> 'ADV: %s',
    -format_fwd	=> 'Fwd: %s',
    -format_re	=> 'Re: %s',
    -format_was	=> '%s (was: %s)',
    #hook_encode_string	## Inherited
    #hook_decode_string	## Inherited
    -prefix_cmsg	=> 'cmsg ',
    -regex_adv	=> qr/(?i)ADV:/,
    -regex_adv_check	=> qr/^ADV:/,
    -remove_ml_prefix	=> 1,
  );
  $self->SUPER::_init (%DEFAULT, %options);
  
  unless ($self->{option}->{remove_ml_prefix}) {
    $REG{prefix} = qr/(?:$REG{re}|$REG{fwd})(?:$REG{FWS}(?:$REG{re}|$REG{fwd}))*/;
  }
}

=item $subject = Message::Field::Subject->new ([%options])

Constructs a new C<Message::Field::Subject> object.  You might pass some 
options as parameters to the constructor.

=cut

## Inherited

=item $subject = Message::Field::Subject->parse ($field-body, [%options])

Constructs a new C<Message::Field::Subject> object with
given field body.  You might pass some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $field_body = shift;
  $self->_init (@_);
  if ($field_body =~ /$REG{M_control}/) {
    $self->{is_control} = 1;	## Obsoleted control message
    $self->{field_body} = $1;	## TODO: passes to Message::Field::Control
    return $self;
  }
  my %s = &{$self->{option}->{hook_decode_string}} ($self, $field_body,
    type => 'text');  $field_body = $s{value};
  $field_body =~ s{^$REG{FWS}($REG{prefix})$REG{FWS}}{
    my $prefix = $1;
    $self->{is_reply} = 1 if $prefix =~ /$REG{re}/;
    $self->{is_foward} = 1 if $prefix =~ /$REG{fwd}/;
    if ($prefix =~ /$REG{M_ml}/) {
      ($self->{ml_name}, $self->{ml_count}) = ($1, $2);
    }
    ''
  }ex;
  $self->{is_adv} = 1 if $field_body =~ /$self->{option}->{regex_adv}/;
  $field_body =~ s{$REG{FWS}$REG{M_was}}{
    my $was = $1;
    if ($self->{option}->{parse_was}) {
      $self->{was} = Message::Field::Subject->parse ($was);
      $self->{was}->{option} = {%{$self->{option}}};
      	## WARNING: this does not support the cases that some of option
      	## values are reference to something.
    } else {
      $self->{was} = $was;
    }
    ''
  }ex;
  $self->{field_body} = $field_body;
  $self;
}

=back

=head1 METHODS

=over 4

=item $body = $subject->stringify

Retruns subject field body as string.  String is encoded
for message if necessary.

=cut

sub stringify ($;%) {
  my $self = shift;  my %o = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  if ($self->{is_control}) {
    my $s = $self->{field_body};
    $s = $option{prefix_cmsg}.$s if $s;
    return $s;
  }
  my %e = (value => $self->{field_body});
  my $was = (ref $self->{was}? $self->{was}->as_plain_string: $self->{was});
  if ($self->{is_reply}) {
    $e{value} = sprintf $option{format_re}, $e{value};
  }
  if ($self->{is_foward}) {
    $e{value} = sprintf $option{format_fwd}, $e{value};
  }
  if (length $was) {
    $e{value} = sprintf $option{format_was}, $e{value} => $was;
  }
  if ($self->{is_adv}
   && $self->{field_body} !~ /$option{regex_adv_check}/) {
    $e{value} = sprintf $option{format_adv}, $e{value};
  }
  %e = &{$option{hook_encode_string}} ($self, $e{value}, type => 'text');
  $e{value};
}
*as_string = \&stringify;

=item $body = $subject->as_plain_string

Returns subject field body as string.  Unlike C<stringify>,
retrun string of this method is not encoded (i.e. returned
in internal code).

=cut

sub as_plain_string ($;%) {
  my $self = shift;
  $self->stringify (-hook_encode_string => sub {shift; (value => shift, @_)}, @_);
}

=item $text = $subject->text ([$new-text])

Returns or set subject text (without prefixes such as "Re: ").

=item $text = $subject->value

An alias for C<text> method.

=cut

## value: Inherited
*text = \&value;

=item $subject->change ($new-subject)

Changes subject to new text.  Current subject is
moved to I<was: >, and current I<was: > subject, if any,
is removed.

=cut

sub change ($$;%) {
  my $self = shift;
  my $new_string = shift;
  my %option = @_;  $option{-no_was} = 1 unless defined $option{-no_was};
  $self->{was} = $self->clone (%option);
  $self->{field_body} = $new_string;
  $self->{is_adv} = 0;
  $self->{is_control} = 0;
  $self->{is_foward} = 0;
  $self->{is_reply} = 0;
  $self;
}

=item $bool = $subject->is ($attribute [=> $bool])

Set/gets attribute value.

Example:

  $isreply = $subject->is ('re');
  	## Strictly, this checks whether start with "Re: " or not.

  $subject->is (foward => 1, re => 0);

=cut

sub is ($@) {
  my $self = shift;
  if (@_ == 1) {
    return $self->{ 'is_' . $_[0] };
  }
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $self->{ 'is_' . $name } = $value;
  }
}

=item $old_subject = $subject->was

Returns I<was: > subject.

=cut

sub was ($) {
  my $self = shift;
  if (ref $self->{was}) {
    #
  } elsif ($self->{was}) {
    $self->{was} = Message::Field::Subject->parse ($self->{was});
    $self->{was}->{option} = {%{$self->{option}}};
  } else {
    $self->{was} = new Message::Field::Subject;
    $self->{was}->{option} = {%{$self->{option}}};
  }
  $self->{was};
}

=item $clone = $subject->clone ()

Returns a copy of the object.

=cut

sub clone ($;%) {
  my $self = shift;  my %option = @_;
  my $clone = $self->SUPER::clone;
  for (grep {/^is_/} keys %{$self}) {
    $clone->{$_} = $self->{$_};
  }
  if (!$option{-no_was} && $self->{was}) {
    if (ref $self->{was}) {
      $clone->{was} = $self->{was}->clone;
    } else {
      $clone->{was} = $self->{was};
    }
  }
  $clone;
}

=head1 EXAMPLE

  my $subject = parse Message::Field::Subject 'Re: cool message';
  $subject->change (q{What's "cool"?});
  print $subject;	# What's "cool"? (was: Re: cool message)

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
$Date: 2002/04/13 01:33:54 $

=cut

1;
