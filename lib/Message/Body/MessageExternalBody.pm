
=head1 NAME

Message::Body::MessageExternalBody --- Perl module
for "message/external-body" Internet Media Types

=cut

package Message::Body::MessageExternalBody;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Body::Text;
push @ISA, qw(Message::Body::Text);

%DEFAULT = (
	## "#i" : only inherited from parent Entity and inherits to child Entity
  -_METHODS	=> [qw|entity_header encapsulated_header phantom_body|],
  -_MEMBERS	=> [qw|encapsulated_header phantom_body|],
  #i body_default_charset
  #i body_default_charset_input
  -fill_cid	=> 1,
  -fill_cte	=> 1,
  -linebreak_strict	=> 1,
  -media_type	=> 'message',
  -media_subtype	=> 'external-body',
  -output_phantom_body	=> 1,
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
  
  $self->{option}->{value_type}->{body_part}->[1]->{-format}
    = 
  my @ilist = qw/body_default_charset body_default_charset_input/;
  $self->{option}->{value_type}->{phantom_body} = ['Message::Body::TextPlain',
    {-media_type => 'text', -media_subtype => '/external_phantom_body'},
    \@ilist];
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
  my $message = shift;
  $self->_init (@_);
  my $nl = "\x0D\x0A";
  unless ($self->{option}->{strict_linebreak}) {
    unless ($message =~ /\x0D\x0A/s) {
      my $lfcr = $message =~ s/\x0A\x0D/\x0A\x0D/gs;
      my $cr = $message =~ s/\x0D(?!\x0A)/\x0D/gs;
      my $lf = $message =~ s/(?<!\x0D)\x0A/\x0A/gs;
      if ($lfcr >= $cr && $lfcr >= $lf) { $nl = "\x0A\x0D" }
      elsif ($cr >= $lf) { $nl = "\x0D" }
      else { $nl = "\x0A" }
    }
  }
  my @header = (); my @body = split /$nl/, $message;
  while (my $line = shift @body) {
    unless (length($line)) { last }
    else { push @header, $line }
  }
  $self->{encapsulated_header} = parse_array Message::Header \@header,
    -parse_all => $self->{option}->{parse_all},
    -format => 'mime-entity-external-body';
  $self->{body} = join $nl, @body;
  $self->{body} = $self->_parse_value (phantom_body => $self->{body})
    if $self->{option}->{parse_all};
  $self;
}

=back

=cut


## entity_header: Inherited

sub encapsulated_header ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $self->{encapsulated_header} = parse Message::Header $np,
      -parse_all => $self->{option}->{parse_all},
      -format => 'mime-entity-external-body';
  }
  $self->{encapsulated_header};
}

sub phantom_body ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $np = $self->_parse_value (phantom_body => $np) if $self->{option}->{parse_all};
    $self->{phantom_body} = $np;
  }
  $self->{phantom_body};
}

sub set_reference ($$%) {
  my $self = shift;
  my $atype = lc shift;
  my %p = @_;
  Carp::croak "set_reference: Access-type is not specified" unless $atype;
  Carp::croak "set_reference: Entity header is not assosiated" unless ref $self->{header};
  my $ct = $self->{header}->field ('content-type');
  $ct->parameter ('access-type' => $atype);
  if ($atype eq 'uri') {
    $self->{phantom_body} = $p{url} if $p{url};
    $self->{phantom_body} = $p{uri} if $p{uri};
    delete $p{url}; delete $p{uri};
  } elsif ($p{body}) {
    $self->{phantom_body} = $p{body};
    delete $p{body};
  }
  if ($p{ct}) {
    $self->{encapsulated_header}->replace ('content-type' => $p{ct}, -parse => 1);
    delete $p{ct};
  }
  if ($p{cid}) {
    $self->{encapsulated_header}->replace ('content-id' => $p{cid}, -parse => 1);
    $self->{header}->replace ('content-id' => $p{cid}, -parse => 1)
      if $atype eq 'content-id';
    delete $p{cid};
  }
  if ($p{cte}) {
    $self->{encapsulated_header}->replace ('content-transfer-encoding' => $p{cte}, -parse => 1);
    delete $p{cte};
  }
  if (defined $p{dir} && !defined $p{directory}) {
    $p{directory} = $p{dir}; delete $p{dir};
  }
  $ct->parameter (%p);
  $self;
}

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  
  my $ct = $self->{header}->field ('content-type');
  my $atype = $ct->parameter ('access-type');
  
  my $ihdr = $self->{encapsulated_header};
  my $icte = $ihdr->field ('content-transfer-encoding');
  if ($option{fill_cte} && !$icte->value) {
    if ($atype eq 'mail-server' || $atype eq 'content-id') {
      $icte->value ('7bit');
    } else {
      $icte->value ('binary');
    }
  }
  my $icid = $ihdr->field ('content-id', -new_item_unless_exist => 0);
  if ($option{fill_cid} && !$icid) {
    my $pcid = $self->{header}->field ('content-id', -new_item_unless_exist => 0);
    if ($pcid) {
      $ihdr->replace ('content-id' => $pcid);
    } else {
      require Message::Field::MsgID;
      my $as = $option{msg_id_from}.'';
      $as = $self->{header}->field ('resent-from', -new_item_unless_exist => 0)
         || $self->{header}->field ('from', -new_item_unless_exist => 0) unless $as;
      $as = $as->addr_spec if ref $as;
      $as ||= 'meb@external.body.message.pm.invalid';
      my $cid = new Message::Field::MsgID
        addr_spec	=> $as,
        -field_name	=> 'content-id',
      ;
      $ihdr->replace ('content-id' => $cid);
    }
  }
  
  $ihdr.
  "\x0D\x0A".
  ($option{output_phantom_body}? $self->{phantom_body}: '');
}
*as_string = \&stringify;

## Inherited: option, clone

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  $self->{encapsulated_header}->option (%$o) if ref $self->{encapsulated_header};
  $self->{phantom_body}->option (%$o) if ref $self->{phantom_body};
}

=head1 SEE ALSO

RFC 2046 <urn:ietf:rfc:2046>

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
$Date: 2002/06/14 11:35:11 $

=cut

1;
