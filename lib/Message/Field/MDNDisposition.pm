
=head1 NAME

Message::Field::MDNDisposition --- A perl module for
MDN Disposition: field body [RFC2298]

=cut

package Message::Field::MDNDisposition;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

%REG = %Message::Util::REG;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_MEMBERS	=> [qw||],
    -_METHODS	=> [qw|value|],
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #field_ns
    #format
    #hook_encode_string
    #hook_decode_string
    -output_comment	=> 1,
    -use_comment	=> 1,
  );


=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, @_);
  
  $self->{option}->{value_type}->{disposition_modifier} = [
    'Message::Field::CSV',{
      -use_comment	=> 0,
      -value_unsafe_rule	=> 'NON_atext',
  }];
  $self->{value} = {};
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
  $body =~ s{
    ## disposition-mode
      ($REG{atext}+)	## action-mode
      $REG{FWS} / $REG{FWS}
      ($REG{atext}+)	## sending-mode
      $REG{FWS} ; $REG{FWS}
    ## disposition-type
      ($REG{atext}+)
    ## disposition-modifier
      (?: $REG{FWS} / $REG{FWS}
          ([\x00-\xFF]*)$
      )?
  }{
    my ($am, $sm, $dt, $dm) = ($1, $2, $3, $4);
    $self->{value}->{action_mode} = $am;
    $self->{value}->{sending_mode} = $sm;
    $self->{value}->{disposition_type} = $dt;
    $self->{value}->{disposition_modifier} = $self->_parse_value
      (disposition_modifier => $dm);
  }gex;
  $self;
}

sub value ($$;$) {
  my $self = shift;
  my ($type, $newvalue) = @_;
  if ($newvalue) {
    if ($type eq 'disposition_modifier') {
      $self->{value}->{ $type } = $self->_parse_value
        ($type => $newvalue);
    } else {
      $self->{value}->{ $type } = $newvalue;
    }
  }
  if (defined wantarray && $type eq 'disposition_modifier') {
    $self->{value}->{ $type } = $self->_parse_value
        ($type => $self->{value}->{ $type });
    return $self->{value}->{ $type };
  }
  $self->{value}->{ $type };
}

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $s = '';
  my ($at, $st, $dt, $dm) = @{ $self->{value} }{qw/action_type sending_type disposition_type disposition_modifier/};
  $at ||= 'manual-action';
  $st ||= 'MDN-sent-manually';
  $dt ||= 'displayed';
  $s = sprintf '%s/%s; %s%s', $at, $st, $dt, $dm? '/'.$dm: '';
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
$Date: 2002/07/13 09:27:35 $

=cut

1;
