
=head1 NAME

Message::Body::TextMessageRFC1153 --- Perl module
for digest message format defined by RFC 1153

=cut

## TODO: 
##   - Select and sort enclosed message header fields (See RFC 1153)

package Message::Body::TextMessageRFC1153;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Body::Multipart;
push @ISA, qw(Message::Body::Multipart);

%DEFAULT = (
	## "#i" : only inherited from parent Entity and inherits to child Entity
  -_ARRAY_NAME	=> 'value',
  -_METHODS	=> [qw|entity_header add delete count item preamble list_name digest_info|],
  -_MEMBERS	=> [qw|preamble list_name digest_info|],
  #i accept_cte
  #i body_default_charset
  #i body_default_charset_input
  #i cte_default
  #linebreak_strict	=> 0,
  -media_type	=> 'text',
  -media_subtype	=> 'x-message-rfc1153',
  #parse_all	=> 0,
  #parts_min	=> 1,
  #parts_max	=> 0,
  #i text_coderange
  #use_normalization	=> 0,
  -use_param_charset	=> 0,
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
  $self->{option}->{value_type}->{body_part}
    = [@{ $Message::MIME::MediaType::type{message}->{rfc822}->{handler} }];
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
  ## Split the body
    $body = $nl . $body if $body =~ /^-{70,70}$nl/s;
    ($self->{preamble}, $body) = split /(?<=$nl)-{70,70}$nl$nl/s, $body, 2;
    $body = $nl . $body if $body =~ /^-{30,30}$nl/s;
    $self->{value} = [ split /(?!=$nl)$nl-{30,30}$nl$nl/, $body ];
    if ($self->{value}->[-1] =~ /^End of(.+?)Digest(.*?)$nl\*+(?:$nl)*$/is) {
      ($self->{list_name}, $self->{digest_info}) = ($1, $2);
      $self->{list_name} =~ s/^\s+//;  $self->{list_name} =~ s/\s+$//;
      $self->{digest_info} =~ s/^\s+//;  $self->{digest_info} =~ s/\s+$//;
      pop @{ $self->{value} };
    }
  
  if ($self->{option}->{parse_all}) {
    $self->{value} = [ map {
      $self->_parse_value (body_part => $_);
    } @{ $self->{value} } ];
    $self->{preamble} = $self->_parse_value (preamble => $self->{preamble});
  }
  $self;
}

=back

=cut

## add, item, delete, count

## entity_header: Inherited

sub preamble ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $np = $self->_parse_value (preamble => $np) if $self->{option}->{parse_all};
    $self->{preamble} = $np;
  }
  $self->{preamble};
}
sub list_name ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $self->{list_name} = $np;
  }
  $self->{list_name};
}
sub digest_info ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $self->{digest_info} = $np;
  }
  $self->{digest_info};
}

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  $self->_delete_empty;
  ## Check the number of parts
    my $min = $option{parts_min} || 1;  $min--;
    $#{ $self->{value} } = $min unless $min <= $#{ $self->{value} };
    my $max = $option{parts_max} || $#{$self->{value}}+1;  $max--;
    $max = $#{$self->{value}} if $max > $#{$self->{value}};
  ## Make trailer
    my $trailer = sprintf 'End of %s Digest%s',
      (length $self->{list_name}? $self->{list_name}: 'list'),
      (length $self->{digest_info}? ' '.$self->{digest_info}:'');
    $trailer .= "\x0D\x0A" . ('*' x length $trailer) . "\x0D\x0A";
  ## Preparates parts
    my @parts = map { ''. $_ } @{ $self->{value} }[0..$max];
    push @parts, $trailer;
    my $preamble = ''.$self->{preamble};
  
    if (ref $self->{header}) {
      my $ct = $self->{header}->field ('content-type');
      if (ref $self->{preamble}) {
        unless (ref $self->{preamble}->entity_header) {
          $self->{preamble}->entity_header (new Message::Header -format => 'mail-rfc822');
        }
        my $pct = $self->{preamble}->entity_header->field ('content-type', -new_item_unless_exist => 0);
        $ct->replace ('x-preamble-type' => $pct)
          if $pct && $pct ne 'text/plain; charset=us-ascii';
      }
    }
  
  $preamble =~ s/^-{70,70}\x0D?$/"\x20".('-' x 69)/gem;
  $preamble .= "\x0D\x0A" unless $preamble =~ /\x0D\x0A$/s;
  
  $preamble
  ."----------------------------------------------------------------------\x0D\x0A"
  ."\x0D\x0A"
  .join "\x0D\x0A------------------------------\x0D\x0A\x0D\x0A",
    map { s/^-{30,30}\x0D?$/"\x20".('-' x 29)/gem; 
          $_ .= "\x0D\x0A" unless /\x0D\x0A$/s; $_ } @parts;
}
*as_string = \&stringify;

## Inherited: option, clone


=head1 SEE ALSO

RFC 1153 E<lt>urn:ietf:rfc:1153>

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
$Date: 2002/07/20 03:09:29 $

=cut

1;
