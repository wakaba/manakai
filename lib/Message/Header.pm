
=head1 NAME

Message::Header Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 message C<header>.

=cut

package Message::Header;
use strict;
use vars qw($VERSION %REG);
$VERSION = '1.00';
use Carp ();
use overload '@{}' => sub { shift->_delete_empty_field->{field} },
             '""' => sub { shift->stringify },
             fallback => 1;

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

=head1 CONSTRUCTORS

The following methods construct new C<Message::Header> objects:

=over 4

=cut

## Initialize
my %DEFAULT = (
  capitalize	=> 1,
  fold	=> 1,
  fold_length	=> 70,
  field_format_pattern	=> '%s: %s',
  #field_type	=> {},
  format	=> 'mail-rfc2822',
  mail_from	=> 0,
  output_bcc	=> 0,
  parse_all	=> 0,
  sort	=> 'none',
  translate_underscore	=> 1,
  validate	=> 1,
);
$DEFAULT{field_type} = {
	':DEFAULT'	=> 'Message::Field::Unstructured',
	
	received	=> 'Message::Field::Received',
	'x-received'	=> 'Message::Field::Received',
	
	'content-type'	=> 'Message::Field::ContentType',
	'auto-submitted'	=> 'Message::Field::ValueParams',
	'content-disposition'	=> 'Message::Field::ValueParams',
	link	=> 'Message::Field::ValueParams',
	archive	=> 'Message::Field::ValueParams',
	'x-face-type'	=> 'Message::Field::ValueParams',
	
	subject	=> 'Message::Field::Subject',
	'x-nsubject'	=> 'Message::Field::Subject',
	
	'list-software'	=> 'Message::Field::UA',
	'user-agent'	=> 'Message::Field::UA',
	server	=> 'Message::Field::UA',
	
	## Numeric value
	'content-length'	=> 'Message::Field::Numval',
	lines	=> 'Message::Field::Numval',
	'max-forwards'	=> 'Message::Field::Numval',
	'mime-version'	=> 'Message::Field::Numval',
	'x-jsmail-priority'	=> 'Message::Field::Numval',
	'x-mail-count'	=> 'Message::Field::Numval',
	'x-ml-count'	=> 'Message::Field::Numval',
	'x-priority'	=> 'Message::Field::Numval',
	
	path	=> 'Message::Field::Path',
};
for (qw(archive cancel-lock content-features content-md5
  disposition-notification-options encoding 
  importance injector-info 
  pics-label posted-and-mailed precedence list-id message-type 
  original-recipient priority
  sensitivity status x-face x-msmail-priority xref))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Structured'}
  	## Not supported yet, but to be supported...
for (qw(abuse-reports-to apparently-to approved approved-by bcc cc complaints-to
  delivered-to disposition-notification-to envelope-to
  errors-to  from mail-copies-to mail-followup-to mail-reply-to
  notice-requested-upon-delivery-to read-receipt-to register-mail-reply-requested-by 
  reply-to resent-bcc
  resent-cc resent-to resent-from resent-sender return-path
  return-receipt-to return-receipt-requested-to sender to x-abuse-reports-to 
  x-admin x-approved 
  x-beenthere
  x-confirm-reading-to
  x-complaints-to x-envelope-from x-envelope-sender
  x-envelope-to x-ml-address x-ml-command x-ml-to x-nfrom x-nto
  x-rcpt-to x-sender x-x-sender))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Address'}
for (qw(date date-received delivery-date expires
  expire-date nntp-posting-date posted posted-date reply-by resent-date 
  x-originalarrivaltime x-tcup-date))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::Date'}
for (qw(article-updates client-date content-id in-reply-to message-id
  obsoletes references replaces resent-message-id see-also supersedes))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::MsgID'}
for (qw(accept accept-charset accept-encoding accept-language
  content-language 
  content-transfer-encoding encrypted followup-to keywords 
  list-archive list-digest list-help list-owner
  list-post list-subscribe list-unsubscribe list-url uri newsgroups
  posted-to
  x-brother x-daughter x-respect x-moe x-syster x-wife))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::CSV'}
for (qw(content-alias content-base content-location location referer
  url x-home-page x-http_referer
  x-info x-pgp-key x-ml-url x-uri x-url x-web))
  {$DEFAULT{field_type}->{$_} = 'Message::Field::URI'}

## taken from L<HTTP::Header>
# "Good Practice" order of HTTP message headers:
#    - General-Headers
#    - Request-Headers
#    - Response-Headers
#    - Entity-Headers
# (From draft-ietf-http-v11-spec-rev-01, Nov 21, 1997)
my @header_order = qw(
  mail-from x-envelope-from relay-version path status

   cache-control connection date pragma transfer-encoding upgrade trailer via

   accept accept-charset accept-encoding accept-language
   authorization expect from host
   if-modified-since if-match if-none-match if-range if-unmodified-since
   max-forwards proxy-authorization range referer te user-agent

   accept-ranges age location proxy-authenticate retry-after server vary
   warning www-authenticate

   mime-version
   allow content-base content-encoding content-language content-length
   content-location content-md5 content-range content-type
   etag expires last-modified content-style-type content-script-type
   link

  xref
);
my %header_order;

sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{field} = [];
  $self->{option} = \%DEFAULT;
  my @new_fields = ();
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } else {
      push @new_fields, ($name => $options{$name});
    }
  }
  $self->add (@new_fields, -parse => $self->{option}->{parse_all})
    if $#new_fields > -1;
  
  my $format = $self->{option}->{format};
  if ($format =~ /cgi/) {
    unshift @header_order, qw(content-type location);
    $self->{option}->{sort} = 'good-practice';
    $self->{option}->{fold} = 0;
  } elsif ($format =~ /^http/) {
    $self->{option}->{sort} = 'good-practice';
  }
  
  # Make alternative representations of @header_order.  This is used
  # for sorting.
  my $i = 1;
  for (@header_order) {
      $header_order{$_} = $i++ unless $header_order{$_};
  }
}

=item Message::Header->new ([%initial-fields/options])

Constructs a new C<Message::Headers> object.  You might pass some initial
C<field-name>-C<field-body> pairs and/or options as parameters to the constructor.

Example:

 $hdr = new Message::Headers
        Date         => 'Thu, 03 Feb 1994 00:00:00 +0000',
        Content_Type => 'text/html',
        Content_Location => 'http://www.foo.example/',
        -format => 'mail-rfc2822'	## not to be header field
        ;

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  $self;
}

=item Message::Header->parse ($header, [%initial-fields/options])

Parses given C<header> and constructs a new C<Message::Headers> 
object.  You might pass some additional C<field-name>-C<field-body> pairs 
or/and initial options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $header = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  $header =~ s/\x0D?\x0A$REG{WSP}/\x20/gos;	## unfold
  for my $field (split /\x0D?\x0A/, $header) {
    if ($field =~ /$REG{M_fromline}/) {
      my $body = $1;
      $body = $self->_field_body ($body, 'mail-from')
        if $self->{option}->{parse_all};
      push @{$self->{field}}, {name => 'mail-from', body => $body};
    } elsif ($field =~ /$REG{M_field}/) {
      my ($name, $body) = (lc $1, $2);
      $name =~ s/$REG{WSP}+$//;
      $body =~ s/$REG{WSP}+$//;
      $body = $self->_field_body ($body, $name) if $self->{option}->{parse_all};
      push @{$self->{field}}, {name => $name, body => $body};
    }
  }
  $self;
}

=item Message::Header->parse_array (\@header, [%initial-fields/options])

Parses given C<header> and constructs a new C<Message::Headers> 
object.  Same as C<Message::Header-E<lt>parse> but this method
is given an array reference.  You might pass some additional 
C<field-name>-C<field-body> pairs or/and initial options 
as parameters to the constructor.

=cut

sub parse_array ($\@;%) {
  my $class = shift;
  my $header = shift;
  Carp::croak "parse_array: first argument is not an array reference"
    unless ref $header eq 'ARRAY';
  my $self = bless {}, $class;
  $self->_init (@_);
  while (1) {
    my $field = shift @$header;
    while (1) {
      if ($$header[0] =~ /^$REG{WSP}/) {
        $field .= shift @$header;
      } else {last}
    }
    $field =~ tr/\x0D\x0A//d;	## BUG: not safe for bar CR/LF
    if ($field =~ /$REG{M_fromline}/) {
      my $body = $1;
      $body = $self->_field_body ($body, 'mail-from')
        if $self->{option}->{parse_all};
      push @{$self->{field}}, {name => 'mail-from', body => $body};
    } elsif ($field =~ /$REG{M_field}/) {
      my ($name, $body) = (lc $1, $2);
      $name =~ s/$REG{WSP}+$//;
      $body =~ s/$REG{WSP}+$//;
      $body = $self->_field_body ($body, $name) if $self->{option}->{parse_all};
      push @{$self->{field}}, {name => $name, body => $body};
    }
    last if $#$header < 0;
  }
  $self;
}

=back

=head1 METHODS

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
    eval "require $type" or Carp::croak ("_field_body: $type: $@");
    unless ($body) {
      $body = $type->new (-field_name => $name,
        -format => $self->{option}->{format}
        , field_name => $name, format => $self->{option}->{format});
    } else {
      $body = $type->parse ($body, -field_name => $name,
        -format => $self->{option}->{format},
         field_name => $name,format => $self->{option}->{format});
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

=item $hdr->add ($field-name, $field-body, [$name, $body, ...])

Adds some field name/body pairs.  Even if there are
one or more fields named given C<$field-name>,
given name/body pairs are ADDed.  Use C<replace>
to remove same-name-fields.

Instead of field name-body pair, you might pass some options.
Four options are available for this method.

C<-parse>: Parses and validates C<field-body>, and returns
C<field-body> object.  (When multiple C<field-body>s are
added, returns only last one.)  (Default: C<defined wantarray>)

C<-prepend>: New fields are not appended,
but prepended to current fields.  (Default: C<0>)

C<-translate-underscore>: Do C<field-name> =~ tr/_/-/.  (Default: C<1>)

C<-validate>: Checks whether C<field-name> is valid or not.

=cut

sub add ($%) {
  my $self = shift;
  my %fields = @_;
  my %option = %{$self->{option}};
  $option{parse} = defined wantarray unless defined $option{parse};
  for (grep {/^-/} keys %fields) {$option{substr ($_, 1)} = $fields{$_}}
  my $body;
  for (grep {/^[^-]/} keys %fields) {
    my $name = lc $_;  $body = $fields{$_};
    $name =~ tr/_/-/ if $option{translate_underscore};
    Carp::croak "add: $name: invalid field-name"
      if $option{validate} && $name =~ /$REG{UNSAFE_field_name}/;
    $body = $self->_field_body ($body, $name) if $option{parse};
    if ($option{prepend}) {
      unshift @{$self->{field}}, {name => $name, body => $body};
    } else {
      push @{$self->{field}}, {name => $name, body => $body};
    }
  }
  $body if $option{parse};
}

=head2 $self->relace ($field_name, $field_body)

Set the C<field-body> named C<field-name> as $field_body.
If $field_name C<field> is already exists, it is replaced
by new $field_body value.  If not, new C<field> is inserted.
(If there are some C<field> named as $field_name,
first one is used and the others are not changed.)

=cut

sub replace ($%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  $option{parse} = defined wantarray unless defined $option{parse};
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my (%new_field);
  for (grep {/^[^-]/} keys %params) {
    my $name = lc $_;
    $name =~ tr/_/-/ if $option{translate_underscore};
    Carp::croak "replace: $name: invalid field-name"
      if $option{validate} && $name =~ /$REG{UNSAFE_field_name}/;
    $params{$_} = $self->_field_body ($params{$_}, $name) if $option{parse};
    $new_field{$name} = $params{$_};
  }
  my $body = (%new_field)[-1];
  for my $field (@{$self->{field}}) {
    if (defined $new_field{$field->{name}}) {
      $field->{body} = $new_field {$field->{name}};
      $new_field{$field->{name}} = undef;
    }
  }
  for (keys %new_field) {
    push @{$self->{field}}, {name => $_, body => $new_field{$_}};
  }
  $body if $option{parse};
}

=head2 $self->delete ($field-name, [$name, ...])

Deletes C<field> named as $field_name.

=cut

sub delete ($@) {
  my $self = shift;
  my %delete;  for (@_) {$delete{lc $_} = 1}
  for my $field (@{$self->{field}}) {
    undef $field if $delete{$field->{name}};
  }
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

=head2 $self->rename ($field-name, $new-name, [$old, $new,...])

Renames C<$field-name> as C<$new-name>.

=cut

sub rename ($%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my %new_name;
  for (grep {/^[^-]/} keys %params) {
    my ($old => $new) = (lc $_ => lc $params{$_});
    $new =~ tr/_/-/ if $option{translate_underscore};
    Carp::croak "rename: $new: invalid field-name"
      if $option{validate} && $new =~ /$REG{UNSAFE_field_name}/;
    $new_name{$old} = $new;
  }
  for my $field (@{$self->{field}}) {
    if (length $new_name{$field->{name}}) {
      $field->{name} = $new_name{$field->{name}};
    }
  }
  $self if defined wantarray;
}


=item $self->scan(\&doit)

Apply a subroutine to each header field in turn.  The callback routine is
called with two parameters; the name of the field and a single value.
If the header has more than one value, then the routine is called once
for each value.

=cut

sub scan ($&) {
  my ($self, $sub) = @_;
  my $sort;
  $sort = \&_header_cmp if $self->{option}->{sort} eq 'good-practice';
  $sort = {$a cmp $b} if $self->{option}->{sort} eq 'alphabetic';
  my @field = @{$self->{field}};
  if (ref $sort) {
    @field = sort $sort @{$self->{field}};
  }
  for my $field (@field) {
    next if $field->{name} =~ /^_/;
    &$sub($field->{name} => $field->{body});
  }
}

# Compare function which makes it easy to sort headers in the
# recommended "Good Practice" order.
## taken from HTTP::Header
sub _header_cmp
{
  my ($na, $nb) = ($a->{name}, $b->{name});
    # Unknown headers are assign a large value so that they are
    # sorted last.  This also helps avoiding a warning from -w
    # about comparing undefined values.
    $header_order{$na} = 999 unless defined $header_order{$na};
    $header_order{$nb} = 999 unless defined $header_order{$nb};

    $header_order{$na} <=> $header_order{$nb} || $na cmp $nb;
}

=head2 $self->stringify ([%option])

Returns the C<header> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my @ret;
  if ($option{mail_from}) {
    my $fromline = $self->field ('mail-from');
    push @ret, 'From '.$fromline if $fromline;
  }
  $self->scan (sub {
    my ($name, $body) = (@_);
    return unless length $name;
    return if $option{mail_from} && $name eq 'mail-from';
    return if !$option{output_bcc} && ($name eq 'bcc' || $name eq 'resent-bcc');
    my $fbody;
    if (ref $body) {
      $fbody = $body->stringify (-format => $option{format});
    } else {
      $fbody = $body;
    }
    return unless length $fbody;
    $fbody =~ s/\x0D(?=[^\x09\x0A\x20])/\x0D\x20/g;
    $fbody =~ s/\x0A(?=[^\x09\x20])/\x0A\x20/g;
    $name =~ s/((?:^|-)[a-z])/uc($1)/ge if $option{capitalize};
    $fbody = $self->_fold ($fbody) if $self->{option}->{fold};
    push @ret, sprintf $self->{option}->{field_format_pattern}, $name, $fbody;
  });
  my $ret = join ("\n", @ret);
  $ret? $ret."\n": '';
}
*as_string = \&stringify;

=head2 $self->option ($option_name, [$option_value])

Set/gets new value of the option.

=cut

sub option ($@) {
  my $self = shift;
  if (@_ == 1) {
    return $self->{option}->{ shift (@_) };
  }
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $name =~ s/^-//;
    $self->{option}->{$name} = $value;
    if ($name eq 'format') {
      for my $f (@{$self->{field}}) {
        if (ref $f->{body}) {
          $f->{body}->option (-format => $value);
        }
      }
    }
  }
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

sub _fold ($$;$) {
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

=head2 $self->clone ()

Returns a copy of Message::Header object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = new Message::Header;
  for my $name (%{$self->{option}}) {
    if (ref $self->{option}->{$name} eq 'HASH') {
      $clone->{option}->{$name} = {%{$self->{option}->{$name}}};
    } elsif (ref $self->{option}->{$name} eq 'ARRAY') {
      $clone->{option}->{$name} = [@{$self->{option}->{$name}}];
    } else {
      $clone->{option}->{$name} = $self->{option}->{$name};
    }
  }
  for (@{$self->{field}}) {
    $clone->add ($_->{name}, scalar $_->{body});
  }
  $clone;
}

=head1 NOTE

=head2 C<field-name>

The header field name is not case sensitive.  To make the life 
easier for perl users who wants to avoid quoting before the => operator, 
you can use '_' as a synonym for '-' in header field names 
(this behaviour can be suppressed by setting
C<translate_underscore> option to C<0> value).

=head1 EXAMPLE

  ## Print field list
  
  use Message::Header;
  my $header = Message::Header->parse ($header);
  
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

=head1 ACKNOWLEDGEMENTS

Some of codes are taken from other modules such as
HTTP::Header, Mail::Header.

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
$Date: 2002/04/21 04:28:46 $

=cut

1;
