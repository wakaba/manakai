
=head1 NAME

Message::Header Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 message C<header>.

=cut

package Message::Header;
use strict;
use vars qw($VERSION %REG %DEFAULT);
$VERSION = '1.00';

use overload '@{}' => sub {shift->_delete_empty_field()->{field}},
             '""' => sub {shift->stringify};

$REG{WSP}     = qr/[\x09\x20]/;
$REG{FWS}     = qr/[\x09\x20]*/;
$REG{M_field} = qr/^([^\x3A]+):$REG{FWS}([\x00-\xFF]*)$/;
$REG{M_fromline} = qr/^\x3E?From$REG{WSP}+([\x00-\xFF]*)$/;
$REG{UNSAFE_field_name} = qr/[\x00-\x20\x3A\x7F-\xFF]/;

=head2 options

These options can be getten/set by C<get_option>/C<set_option>
method.

=head3 capitalize = 0/1

(First character of) C<field-name> is capitalized
when C<stringify>.  (Default = 1)

=head3 fold_length = numeric value

Length of line used to fold.  (Default = 70)

=head3 mail_from = 0/1

Outputs "From " line (known as Un*x From, Mail-From, and so on)
when C<stringify>.  (Default = 0)

=cut

%DEFAULT = (
  capitalize	=> 1,
  fold_length	=> 70,
  mail_from	=> 0,
  field_type	=> {_DEFAULT => 'Message::Field::Unstructured'},
);
my @field_type_Structured = qw(cancel-lock content-language
  content-transfer-encoding
  encrypted followup-to importance mime-version newsgroups 
  path precedence user-agent x-cite
  x-face x-mail-count
  x-msmail-priority x-priority x-uidl xref);
for (@field_type_Structured)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Structured'}
my @field_type_Address = qw(approved bcc cc delivered-to envelope-to
  errors-to from mail-followup-to reply-to resent-bcc
  resent-cc resent-to resent-from resent-sender return-path
  return-receipt-to sender to x-approved x-beenthere
  x-complaints-to x-envelope-from x-envelope-sender
  x-envelope-to x-ml-address x-ml-command x-ml-to);
for (@field_type_Address)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Address'}
my @field_type_Date = qw(date date-received delivery-date expires
  expire-date nntp-posting-date posted reply-by resent-date x-tcup-date);
for (@field_type_Date)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Date'}
my @field_type_MsgID = qw(content-id in-reply-to message-id
  references resent-message-id see-also supersedes);
for (@field_type_MsgID)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::MsgID'}
my @field_type_Received = qw(received x-received);
for (@field_type_Received)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Received'}
my @field_type_Param = qw(content-disposition content-type
  x-brother x-daughter x-face-type x-respect x-moe
  x-syster x-wife);
for (@field_type_Param)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Structured'}
my @field_type_URI = qw(list-archive list-help list-owner
  list-post list-subscribe list-unsubscribe uri url x-home-page x-http_referer
  x-info x-pgp-key x-ml-url x-uri x-url x-web);
for (@field_type_URI)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Structured'}
my @field_type_ListID = qw(list-id);
for (@field_type_ListID)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Structured'}
my @field_type_Subject = qw(content-description subject title);
for (@field_type_Subject)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Subject'}

=head2 Message::Header->new ([%option])

Returns new Message::Header instance.  Some options can be
specified as hash.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Header->parse ($header, [%option])

Parses given C<header> and return a new Message::Header
object.  Some options can be specified as hash.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $header = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $header =~ s/\x0D?\x0A$REG{WSP}+/\x20/gos;	## unfold
  for my $field (split /\x0D?\x0A/, $header) {
    if ($field =~ /$REG{M_fromline}/) {
      push @{$self->{field}}, {name => 'mail-from', body => $1};
    } elsif ($field =~ /$REG{M_field}/) {
      my ($name, $body) = ($1, $2);
      $name =~ s/$REG{WSP}+$//;
      $body =~ s/$REG{WSP}+$//;
      push @{$self->{field}}, {name => lc $name, body => $body};
    }
  }
  $self;
}

=head2 $self->field ($field_name)

Returns C<field-body> of given C<field-name>.
When there are two or more C<field>s whose name is C<field-name>,
this method return all C<field-body>s as array.  (On scalar
context, only first one is returned.)

=cut

sub field ($$) {
  my $self = shift;
  my $name = lc shift;
  my @ret;
  for my $field (@{$self->{field}}) {
    if ($field->{name} eq $name) {
      unless (wantarray) {
        $field->{body} = $self->_field_body ($field->{body}, $name);
        return $field->{body};
      } else {
        $field->{body} = $self->_field_body ($field->{body}, $name);
        push @ret, $field->{body};
      }
    }
  }
  @ret;
}

=head2 $self->field_name ($index)

Returns C<field-name> of $index'th C<field>.

=head2 $self->field_body ($index)

Returns C<field-body> of $index'th C<field>.

=cut

sub field_name ($$) {
  my $self = shift;
  $self->{field}->[shift]->{name};
}
sub field_body ($$) {
  my $self = shift;
  my $i = shift;
  $self->{field}->[$i]->{body}
   = $self->_field_body ($self->{field}->[$i]->{body}, $self->{field}->[$i]->{name});
  $self->{field}->[$i]->{body};
}

sub _field_body ($$$) {
  my $self = shift;
  my ($body, $name) = @_;
  unless (ref $body) {
    my $type = $self->{option}->{field_type}->{$name}
            || $self->{option}->{field_type}->{_DEFAULT};
    eval "require $type";
    unless ($body) {
      $body = $type->new (field_name => $name);
    } else {
      $body = $type->parse ($body, field_name => $name);
    }
  }
  $body;
}

=head2 $self->field_name_list ()

Returns list of all C<field-name>s.  (Even if there are two
or more C<field>s which have same C<field-name>,  this method
returns ALL names.)

=cut

sub field_name_list ($) {
  my $self = shift;
  $self->_delete_empty_field ();
  map {$_->{name}} @{$self->{field}};
}

=head2 $self->add ($field_name, $field_body)

Adds an new C<field>.  It is not checked whether
the field which named $field_body is already exist or not.
If you don't want duplicated C<field>s, use C<replace> method.

=cut

sub add ($$$) {
  my $self = shift;
  my ($name, $body) = (lc shift, shift);
  return 0 if $name =~ /$REG{UNSAFE_field_name}/;
  $body = $self->_field_body ($body, $name);
  push @{$self->{field}}, {name => $name, body => $body};
  $body;
}

=head2 $self->relace ($field_name, $field_body)

Set the C<field-body> named C<field-name> as $field_body.
If $field_name C<field> is already exists, it is replaced
by new $field_body value.  If not, new C<field> is inserted.
(If there are some C<field> named as $field_name,
first one is used and the others are not changed.)

=cut

sub replace ($$$) {
  my $self = shift;
  my ($name, $body) = (lc shift, shift);
  return 0 if $name =~ /$REG{UNSAFE_field_name}/;
  for my $field (@{$self->{field}}) {
    if ($field->{name} eq $name) {
      $field->{body} = $body;
      return $self;
    }
  }
  push @{$self->{field}}, {name => $name, body => $body};
  $self;
}

=head2 $self->delete ($field_name, [$index])

Deletes C<field> named as $field_name.
If $index is specified, only $index'th C<field> is deleted.
If not, ($index == 0), all C<field>s that have the C<field-name>
$field_name are deleted.

=cut

sub delete ($$;$) {
  my $self = shift;
  my ($name, $index) = (lc shift, shift);
  my $i = 0;
  for my $field (@{$self->{field}}) {
    if ($field->{name} eq $name) {
      $i++;
      if ($index == 0 || $i == $index) {
        undef $field;
        return $self if $i == $index;
      }
    }
  }
  $self;
}

=head2 $self->count ([$field_name])

Returns the number of times the given C<field> appears.
If no $field_name is given, returns the number
of fields.  (Same as $#$self+1)

=cut

sub count ($;$) {
  my $self = shift;
  my ($name) = (lc shift);
  unless ($name) {
    $self->_delete_empty_field ();
    return $#{$self->{field}}+1;
  }
  my $count = 0;
  for my $field (@{$self->{field}}) {
    if ($field->{name} eq $name) {
      $count++;
    }
  }
  $count;
}

=head2 $self->stringify ([%option])

Returns the C<header> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %OPT = @_;
  my @ret;
  $OPT{capitalize} ||= $self->{option}->{capitalize};
  $OPT{mail_from} ||= $self->{option}->{mail_from};
  push @ret, 'From '.$self->field ('mail-from') if $OPT{mail_from};
  for my $field (@{$self->{field}}) {
    my $name = $field->{name};
    next unless $field->{name};
    next if !$OPT{mail_from} && $name eq 'mail-from';
    my $fbody = scalar $field->{body};
    next unless $fbody;
    $name =~ s/((?:^|-)[a-z])/uc($1)/ge if $OPT{capitalize};
    push @ret, $name.': '.$self->fold ($fbody);
  }
  my $ret = join ("\n", @ret);
  $ret? $ret."\n": "";
}

=head2 $self->get_option ($option_name)

Returns value of the option.

=head2 $self->set_option ($option_name, $option_value)

Set new value of the option.

=cut

sub get_option ($$) {
  my $self = shift;
  my ($name) = @_;
  $self->{option}->{$name};
}
sub set_option ($$$) {
  my $self = shift;
  my ($name, $value) = @_;
  $self->{option}->{$name} = $value;
  $self;
}

sub field_type ($$;$) {
  my $self = shift;
  my $field_name = shift;
  my $new_field_type = shift;
  if ($new_field_type) {
    $self->{option}->{field_type}->{$field_name} = $new_field_type;
  }
  $self->{option}->{field_type}->{$field_name}
  || $self->{option}->{field_type}->{_DEFAULT};
}

sub _delete_empty_field ($) {
  my $self = shift;
  my @ret;
  for my $field (@{$self->{field}}) {
    push @ret, $field if $field->{name};
  }
  $self->{field} = \@ret;
  $self;
}

sub fold ($$;$) {
  my $self = shift;
  my $string = shift;
  my $len = shift || $self->{option}->{fold_length};
  $len = 60 if $len < 60;
  
  ## This code is taken from Mail::Header 1.43 in MailTools,
  ## by Graham Barr (Maintained by Mark Overmeer <mailtools@overmeer.net>).
  my $max = int($len - 5);         # 4 for leading spcs + 1 for [\,\;]
  my $min = int($len * 4 / 5) - 4;
  my $ml = $len;
  
  if (length($string) > $ml) {
     #Split the line up
     # first bias towards splitting at a , or a ; >4/5 along the line
     # next split a whitespace
     # else we are looking at a single word and probably don't want to split
     my $x = "";
     $x .= "$1\n    "
       while($string =~ s/^$REG{WSP}*(
                          [^"]{$min,$max}?[\,\;]
                          |[^"]{1,$max}$REG{WSP}
                          |[^\s"]*(?:"[^"]*"[^\s"]*)+$REG{WSP}
                          |[^\s"]+$REG{WSP}
                          )
                        //x);
     $x .= $string;
     $string = $x;
     $string =~ s/(\A$REG{WSP}+|$REG{WSP}+\Z)//sog;
     $string =~ s/\s+\n/\n/sog;
  }
  $string;
}

=head1 EXAMPLE

  ## Print field list
  
  use Message::Header;
  my $header = Message::Header->parse ($header);
  
  ## Next sample is better.
  #for my $field (@$header) {
  #  print $field->{name}, "\t=> ", $field->{body}, "\n";
  #}
  
  for my $i (0..$#$header) {
    print $header->field_name ($i), "\t=> ", $header->field_body ($i), "\n";
  }
  
  
  ## Make simple header
  
  use Message::Header;
  use Message::Field::Address;
  my $header = new Message::Header;
  
  my $from = new Message::Field::Address;
     $from->add ('foo@foo.example', name => 'F. Foo');
  my $to = new Message::Field::Address;
     $to->add ('bar@bar.example', name => 'Mr. Bar');
     $to->add ('hoge@foo.example', name => 'Hoge-san');
  $header->add ('From' => $from);
  $header->add ('To' => $to);
  $header->add ('Subject' => 'Re: Meeting');
  $header->add ('References' => '<hoge.msgid%foo@foo.example>');
  print $header;

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
$Date: 2002/03/20 11:41:58 $

=cut

1;
