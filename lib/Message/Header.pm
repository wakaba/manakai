
=head1 NAME

Message::Header Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 message C<header>.

=cut

package Message::Header;
use strict;
use vars qw($VERSION %REG %DEFAULT);
$VERSION = '1.00';
use Carp;
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
  field_type	=> {':DEFAULT' => 'Message::Field::Unstructured'},
  format	=> 'rfc2822',	## rfc2822, usefor, http
  mail_from	=> -1,
  output_bcc	=> -1,
  parse_all	=> -1,
);
my @field_type_Structured = qw(cancel-lock
  importance path precedence
  x-face x-mail-count x-msmail-priority x-priority xref);
for (@field_type_Structured)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Structured'}
my @field_type_Address = qw(approved bcc cc delivered-to disposition-notification-to 
  envelope-to
  errors-to fcc from mail-followup-to mail-followup-cc mail-from reply-to resent-bcc
  resent-cc resent-to resent-from resent-sender return-path
  return-receipt-to sender to x-approved x-beenthere
  x-complaints-to x-envelope-from x-envelope-sender
  x-envelope-to x-ml-address x-ml-command x-ml-to x-nfrom x-nto);
for (@field_type_Address)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Address'}
my @field_type_Date = qw(date date-received delivery-date expires
  expire-date nntp-posting-date posted reply-by resent-date x-tcup-date);
for (@field_type_Date)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Date'}
my @field_type_MsgID = qw(article-updates content-id in-reply-to message-id
  references resent-message-id see-also supersedes);
for (@field_type_MsgID)
  {$DEFAULT{field_type}->{$_} = 'Message::Field::MsgID'}
for (qw(received x-received))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Received'}
$DEFAULT{field_type}->{'content-type'} = 'Message::Field::ContentType';
$DEFAULT{field_type}->{'content-disposition'} = 'Message::Field::ContentDisposition';
for (qw(archive link x-face-type))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::ValueParams'}
for (qw(accept accept-charset accept-encoding accept-language
  content-language 
  content-transfer-encoding encrypted followup-to keywords 
  list-archive list-digest list-help list-owner
  list-post list-subscribe list-unsubscribe list-url uri newsgroups
  x-brother x-daughter x-respect x-moe x-syster x-wife))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::CSV'}
for (qw(content-alias content-base content-location location referer
  url x-home-page x-http_referer
  x-info x-pgp-key x-ml-url x-uri x-url x-web))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::URI'}
for (qw(list-id))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Structured'}
for (qw(subject title x-nsubject))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Subject'}
for (qw(list-software user-agent server))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::UA'}
for (qw(content-length lines max-forwards mime-version))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Numval'}

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
      my $body = $1;
      $body = $self->_field_body ($body, 'mail-from')
        if $self->{option}->{parse_all}>0;
      push @{$self->{field}}, {name => 'mail-from', body => $body};
    } elsif ($field =~ /$REG{M_field}/) {
      my ($name, $body) = (lc $1, $2);
      $name =~ s/$REG{WSP}+$//;
      $body =~ s/$REG{WSP}+$//;
      $body = $self->_field_body ($body, $name) if $self->{option}->{parse_all}>0;
      push @{$self->{field}}, {name => $name, body => $body};
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
  if ($#ret < 0) {
    return $self->add ($name);
  }
  @ret;
}

sub field_exist ($$) {
  my $self = shift;
  my $name = lc shift;
  my @ret;
  for my $field (@{$self->{field}}) {
    return 1 if ($field->{name} eq $name);
  }
  0;
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
            || $self->{option}->{field_type}->{':DEFAULT'};
    eval "require $type";
    unless ($body) {
      $body = $type->new (field_name => $name, format => $self->{option}->{format});
    } else {
      $body = $type->parse ($body, field_name => $name,
        format => $self->{option}->{format});
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

sub add ($$;$%) {
  my $self = shift;
  my ($name, $body) = (lc shift, shift);
  my %option = @_;
  return 0 if $name =~ /$REG{UNSAFE_field_name}/;
  $body = $self->_field_body ($body, $name);
  if ($option{prepend}) {
    unshift @{$self->{field}}, {name => $name, body => $body};
  } else {
    push @{$self->{field}}, {name => $name, body => $body};
  }
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
  $body = $self->_field_body ($body, $name);
  for my $field (@{$self->{field}}) {
    if ($field->{name} eq $name) {
      $field->{body} = $body;
      return $body;
    }
  }
  push @{$self->{field}}, {name => $name, body => $body};
  $body;
}

=head2 $self->delete ($field_name, [$index])

Deletes C<field> named as $field_name.
If $index is specified, only $index'th C<field> is deleted.
($index of first field is C<1>, not C<0>.)
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

=head2 $self->rename ($field_name, [$index])

Renames C<field> named as $field_name.
If $index is specified, only $index'th C<field> is renamed.
($index of first field is C<1>, not C<0>.)
If not, ($index == 0), all C<field>s that have the C<field-name>
$field_name are renamed.

=cut

sub rename ($$$;$) {
  my $self = shift;
  my ($name, $newname, $index) = (lc shift, lc shift, shift);
  my $i = 0;
  croak "rename: new field-name contains of unsafe character: $newname"
    if !$newname || $newname =~ /$REG{UNSAFE_field_name}/;
  for my $field (@{$self->{field}}) {
    if ($field->{name} eq $name) {
      $i++;
      if ($index == 0 || $i == $index) {
        $field->{name} = $newname;
        return $self if $i == $index;
      }
    }
  }
  $self;
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
  $OPT{output_bcc} ||= $self->{option}->{output_bcc};
  $OPT{format} ||= $self->{option}->{format};
  push @ret, 'From '.$self->field ('mail-from') if $OPT{mail_from}>0;
  for my $field (@{$self->{field}}) {
    my $name = $field->{name};
    next unless $name;
    next if $OPT{mail_from}<0 && $name eq 'mail-from';
    next if $OPT{output_bcc}<0 && ($name eq 'bcc' || $name eq 'resent-bcc');
    my $fbody;
    if (ref $field->{body}) {
      $fbody = $field->{body}->stringify (format => $OPT{format});
    } else {
      $fbody = $field->{body};
    }
    next unless $fbody;
    $fbody =~ s/\x0D([^\x09\x0A\x20])/\x0D\x20$1/g;
    $fbody =~ s/\x0A([^\x09\x20])/\x0A\x20$1/g;
    $name =~ s/((?:^|-)[a-z])/uc($1)/ge if $OPT{capitalize};
    push @ret, $name.': '.$self->fold ($fbody);
  }
  my $ret = join ("\n", @ret);
  $ret? $ret."\n": "";
}

=head2 $self->option ($option_name, [$option_value])

Set/gets new value of the option.

=cut

sub option ($$;$) {
  my $self = shift;
  my ($name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
    if ($name eq 'format') {
      for my $f (@{$self->{field}}) {
        if (ref $f) {
          $f->option (format => $value);
        }
      }
    }
  }
  $self->{option}->{$name};
}

sub field_type ($$;$) {
  my $self = shift;
  my $field_name = shift;
  my $new_field_type = shift;
  if ($new_field_type) {
    $self->{option}->{field_type}->{$field_name} = $new_field_type;
  }
  $self->{option}->{field_type}->{$field_name}
  || $self->{option}->{field_type}->{':DEFAULT'};
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
     $x .= "$1\n "
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
$Date: 2002/04/01 05:32:37 $

=cut

1;
