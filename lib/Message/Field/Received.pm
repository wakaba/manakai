
=head1 NAME

Message::Field::Received --- Perl module for C<Received:>
Internet message header field body

=cut

## TODO: reimplemention by using Message::Field::Params

package Message::Field::Received;
use strict;
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

require Message::Field::Date;
use overload '@{}' => sub {shift->_delete_empty_item->{item}},
             '""' => sub { $_[0]->stringify };

*REG = \%Message::Util::REG;
## Inherited: comment, quoted_string, domain_literal
	## WSP, FWS, atext
	## domain, addr_spec, msg_id
	## date_time, asctime

	$REG{item_name} = qr/[A-Za-z][0-9A-Za-z-]*[0-9A-Za-z]/;
		## strictly, item-name = ALPHA *(["-"] (ALPHA / DIGIT))
	$REG{M_name_val_pair} = qr/($REG{item_name})$REG{FWS}($REG{msg_id}|$REG{addr_spec}|$REG{domain}|$REG{atext})/;


=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    -field_name	=> 'received',
    #format	## Inherited
    -parse_all	=> 0,
    -value_type	=> {'*default'	=> [':none:']},
  );
  $self->SUPER::_init (%DEFAULT, %options);
}


=item $r = Message::Field::Received->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

sub new ($;%) {
  my $self = shift->SUPER::new (@_);
  $self->{date_time} = new Message::Field::Date
      -field_name => $self->{option}->{field_name},
      -field_param_name => 'date-time',
      -format => $self->{option}->{format};
  $self;
}

=item $r = Message::Field::Received->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $field_body = shift;
  $self->_init (@_);
  $field_body = Message::Util::delete_comment ($field_body);
  $field_body =~ s{;$REG{FWS}($REG{date_time})$REG{FWS}$}{
    $self->{date_time} = parse Message::Field::Date $1,
      -field_name => $self->{option}->{field_name},
      -field_param_name => 'date-time',
      -format => $self->{option}->{format};
    '';
  }ex;
  unless ($self->{date_time}) {
    if ($field_body =~ /($REG{asctime})/) {	## old USENET format
      $self->{date_time} = parse Message::Field::Date $1,
        -field_name => $self->{option}->{field_name},
        -field_param_name => 'date-time',
        -format => $self->{option}->{format};
      return $self;
    } else {	## broken!
      $field_body =~ s/;[^;]+$//;
      $self->{date_time} = new Message::Field::Date
        -time_is_unknown => 1,
        -field_name => $self->{option}->{field_name},
        -field_param_name => 'date-time',
        -format => $self->{option}->{format};
    }
  }
  $field_body =~ s{$REG{M_name_val_pair}$REG{FWS}}{
    my ($name, $value) = (lc $1, $2);
    $name =~ tr/-/_/;
    push @{$self->{item}}, [$name => $value];
    ''
  }goex;
  $self;
}

=back

=head1 METHODS

=over 4

=head2 $self->items ()

Return item list hash that contains of C<name-val-list>
array references.

=cut

sub items ($) {@{shift->{item}}}

sub item_name ($$) {
  my $self = shift;
  my $i = shift;
  $self->{item}->[$i]->[0];
}

sub item_value ($$) {
  my $self = shift;
  my $i = shift;
  $self->{item}->[$i]->[1];
}

sub item ($$) {
  my $self = shift;
  my $name = lc shift;
  my @ret;
  for my $item (@{$self->{item}}) {
    if ($item->[0] eq $name) {
      unless (wantarray) {
        return $item->[1];
      } else {
        push @ret, $item->[1];
      }
    }
  }
  @ret;
}

sub date_time ($) {
  my $self = shift;
  $self->{date_time};
}

=head2 $self->add ($item_name, $item_value)

Add an C<nama-val-pair>.

Note that this method (and other methods) does not check
C<item-val-pair> is valid as RFC (2)82[12] definition or not.
(But only C<item-name> is changed when C<stringify>.)

=cut

sub add ($%) {
  my $self = shift;
  my %gp = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %gp) {$option{substr ($_, 1)} = $gp{$_}}
  $option{parse} = 1 if defined wantarray;
  my $p;
  for (grep {/^[^-]/} keys %gp) {
    my ($name => $value) = (lc $_ => $gp{$_});
    $value = $self->_item_value ($name => $value) if $option{parse};
    if ($option{prepend}) {
      unshift @{$self->{item}}, [$name => $value];
    } else {
      push @{$self->{item}}, [$name => $value];
    }
  }
  $p;
}

sub replace ($%) {
  my $self = shift;
  my %gp = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %gp) {$option{substr ($_, 1)} = $gp{$_}}
  $option{parse} = 1 if defined wantarray;
  my $p;
  for (grep {/^[^-]/} keys %gp) {
    my ($name => $value) = (lc $_ => $gp{$_});
    my $f = 0;
    for my $item (@{$self->{item}}) {
      if ($item->[0] eq $name) {$item = [$name => $value]; $f = 1}
    }
    push @{$self->{item}}, [$name => $value] unless $f == 1;
  }
  $p;
}

sub delete ($@) {
  my $self = shift;
  my %delete;
  for (@_) {$delete{lc $_} = 1}
  $self->{item} = [grep {!$delete{$_->[0]}} @{$self->{item}}];
}

=head2 $self->count ([$item_name])

Returns the number of times the given C<item-name>'ed 
C<name-val-pair> appears.
If no $item_name is given, returns the number
of fields.  (Same as $#$self+1)

=cut

sub count ($;$) {
  my $self = shift;
  my ($name) = (lc shift);
  unless ($name) {
    $self->_delete_empty;
    return $#{$self->{item}}+1;
  }
  my @c = grep {$_->[0] eq $name} @{$self->{item}};
  scalar @c;
}

sub _delete_empty ($) {
  my $self = shift;
  $self->{item} = [grep {ref $_ && length $_->[0]} @{$self->{item}}];
  $self;
}


sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  my @return;
  $self->_delete_empty;
  for my $item (@{$self->{item}}) {
    push @return, $item->[0], $item->[1] if $item->[0] =~ /^$REG{item_name}$/;
  }
  join (' ', @return).'; '.$self->{date_time}->as_rfc2822_time;
}
*as_string = \&stringify;

=item $option-value = $r->option ($option-name)

Gets option value.

=item $r->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited

## TODO: $r->value_type

=item $clone = $r->clone ()

Returns a copy of the object.

=cut

sub clone ($) {
  my $self = shift;
  $self->_delete_empty;
  my $clone = $self->SUPER::clone;
  $clone->{item} = Message::Util::make_clone ($self->{item});
  $clone->{value_type} = Message::Util::make_clone ($self->{value_type});
  $clone;
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
$Date: 2002/04/22 08:28:20 $

=cut

1;
