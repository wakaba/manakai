
=head1 NAME

Message::Body::MessageDeliveryStatus --- Perl module
for "message/delivery-status" Internet Media Types

=cut

package Message::Body::MessageDeliveryStatus;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Body::Text;
push @ISA, qw(Message::Body::Text);

%DEFAULT = (
  -_ARRAY_NAME	=> 'value',
  -_METHODS	=> [qw|entity_header add delete count item per_message per_recipient|],
  -_MEMBERS	=> [qw|per_message|],
  -linebreak_strict	=> 0,
  -media_type	=> 'message',
  -media_subtype	=> 'delivery-status',
  -parse_all	=> 0,
  #use_normalization	=> 0,
  -value_type	=> {},
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  my %option = @_;
  $self->SUPER::_init (%$DEFAULT, %option);
  $self->{value} = [];
  require Message::Header::Message;
  $self->{option}->{value_type}->{per_message} = ['Message::Header',{
  	-format => 'message-delivery-status-per-message',
  	-ns_default_phuri	=> $Message::Header::Message::DeliveryStatus::OPTION{namespace_uri},
  	-hook_init_fill_options	=> \&_fill_init_pm,
  	-hook_stringify_fill_fields	=> \&_fill_fields_pm,
  }];
  $self->{option}->{value_type}->{per_recipient} = ['Message::Header',{
  	-format => 'message-delivery-status-per-recipient',
  	-ns_default_phuri	=> $Message::Header::Message::DeliveryStatus::OPTION{namespace_uri},
  	-hook_init_fill_options	=> \&_fill_init_pr,
  	-hook_stringify_fill_fields	=> \&_fill_fields_pr,
  }];
}

=item $body = Message::Body::Multipart->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $body = Message::Body::Multipart->parse ($body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  my $nl = "\x0D\x0A";
  unless ($self->{option}->{linebreak_strict}) {
    $nl = Message::Util::decide_newline ($body);
  }
  
  my @v;
  @v = map { $_ . $nl } split (/$nl$nl/, $body);
  $self->{per_message} = shift @v;
  
  if ($self->{option}->{parse_all}) {
    $self->{per_message} = $self->_parse_value (per_message => $self->{per_message});
    @v = map {
        $self->_parse_value (per_recipient => $_);
    } @v;
  }
  $self->{value} = \@v;
  $self;
}

=back

=cut

## add, item, delete, count

## item-by?, \$checked-item, {item-key => 1}, \%option
sub _item_match ($$\$\%\%) {
  my $self = shift;
  my ($by, $i, $list, $option) = @_;
  return 0 unless ref $$i;  ## Already removed
  if ($by eq 'action') {
    $$i = $self->_parse_value (per_recipient => $$i);
    return 1 if ref $$i && $list->{ lc $$i->field ('action')->value };
  } elsif ($by eq 'recipient') {
    $$i = $self->_parse_value (per_recipient => $$i);
    return 0 unless ref $$i;
    return 1 if $list->{ $$i->field ('final-recipient')->value };
    my $r = $$i->field ('original-recipient', -new_item_unless_exist => 0);
    return 1 if ref $r && $list->{ $r->value };
    $r = $$i->field ('x-actual-recipient', -new_item_unless_exist => 0);
    return 1 if ref $r && $list->{ $r->value };
  }
  0;
}
*_delete_match = \&_item_match;

## Returns returned item value    \$item-value, \%option
sub _item_return_value ($\$\%) {
  unless (ref ${$_[1]}) {
    ${$_[1]} = $_[0]->_parse_value (body_part => ${$_[1]})
      if $_[2]->{parse};
  }
  ${$_[1]};
}
*_add_return_value = \&_item_return_value;

## Returns returned (new created) item value    $name, \%option
sub _item_new_value ($$\%) {
  my $v = shift->_parse_value (per_recipient => '');
  my ($key, $option) = @_;
  if ($option->{by} eq 'action') {
    $v->header->field ('action')->value ($key);
  } elsif ($option->{by} eq 'recipient') {
    $v->header->add ('final-recipient' => $key);
  }
  $v;
}

sub _add_array_check ($$\%) {
  my $self = shift;
  my ($value, $option) = @_;
  my $value_option = {};
  if (ref $value eq 'ARRAY') {
    ($value, %$value_option) = @$value;
  }
  $value = $self->_parse_value (per_recipient => $value) if $$option{parse};
  $$option{parse} = 0;
  (1, value => $value);
}

## entity_header: Inherited

sub per_message ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $np = $self->_parse_value (per_message => $np) if $self->{option}->{parse_all};
    $self->{per_message} = $np;
  }
  $self->{per_message};
}

sub per_recipient { shift->item (@_) }

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  $self->_delete_empty;
  $self->add ({-parse => 1}, '') unless $#{ $self->{value} } + 1;
  join ("\x0D\x0A", $self->{per_message}, @{ $self->{value} }) . "\x0D\x0A";
}
*as_string = \&stringify;

sub _fill_init_pm ($\%) {
  my ($hdr, $option) = @_;
  unless (defined $option->{fill_reporting_mta}) {
    $option->{fill_reporting_mta} = 1;
    $option->{fill_reporting_mta_name} = 'reporting-mta';
  }
}
sub _fill_init_pr ($\%) {
  my ($hdr, $option) = @_;
  unless (defined $option->{fill_action}) {
    $option->{fill_action} = 1;
  }
  unless (defined $option->{fill_final_recipient}) {
    $option->{fill_final_recipient} = 1;
  }
  unless (defined $option->{fill_status}) {
    $option->{fill_status} = 1;
  }
}

sub _fill_fields_pm ($\%\%) {
  my ($hdr, $exist, $option) = @_;
  my $ns = ':'.$option->{ns_default_phuri};
  if ($option->{fill_reporting_mta}
    && !$exist->{ $option->{fill_reporting_mta_name}.$ns  }) {
    my $rmta = $hdr->field ($option->{fill_reporting_mta_name});
    $rmta->type ('dns');
    $rmta->value ('localhost');
  }
}
sub _fill_fields_pr ($\%\%) {
  my ($hdr, $exist, $option) = @_;
  my $ns = ':'.$option->{ns_default_phuri};
  if ($option->{fill_action} && !$exist->{ 'action'.$ns }) {
    my $act = $hdr->field ('action');
    $act->value ('failed');
  }
  if ($option->{fill_final_recipient} && !$exist->{ 'final-recipient'.$ns }) {
    my $fr = $hdr->field ('final-recipient');
    $fr->type ('rfc822');
    $fr->value ('foo@bar.invalid');
  }
  if ($option->{fill_status} && !$exist->{ 'status'.$ns }) {
    my $fr = $hdr->add (status => '4.0.0');
  }
}

## Inherited: option, clone

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  for (@{$self->{value}}) {
    $_->option (%$o) if ref $_;
  }
  $self->{per_message}->option (%$o) if ref $self->{per_message};
}

=head1 SEE ALSO

RFC 1894 <urn:ietf:rfc:1894>

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
$Date: 2002/07/08 12:39:39 $

=cut

1;
