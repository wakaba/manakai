
=head1 NAME

Message::Header --- A Perl Module for Internet Message Headers

=cut

package Message::Header;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.34 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;	## This may seem silly:-)
push @ISA, qw(Message::Field::Structured);

%REG = %Message::Util::REG;
	$REG{M_field} = qr/^([^\x3A]+):$REG{FWS}([\x00-\xFF]*)$/;
	$REG{M_fromline} = qr/^\x3E?From$REG{WSP}+([\x00-\xFF]*)$/;
	$REG{ftext} = qr/[\x21-\x39\x3B-\x7E]+/;	## [2]822
	$REG{NON_ftext} = qr/[^\x21-\x39\x3B-\x7E]/;	## [2]822
	$REG{NON_ftext_usefor} = qr/[^0-9A-Za-z-]/;	## name-character
	$REG{NON_ftext_http} = $REG{NON_http_token};

## Namespace support
	our %NS_phname2uri;	## PH-namespace name -> namespace URI
	our %NS_uri2package;	## namespace URI -> Package name
	our %NS_uri2phpackage;	## namespace URI -> PH-Package name
	require Message::Header::Default;	## Default namespace

## Initialize of this class -- called by constructors
%DEFAULT = (
    -_HASH_NAME	=> 'value',
    -_METHODS	=> [qw|field field_exist field_type add replace count delete subject id is|],
    -_MEMBERS	=> [qw|value|],
    -_VALTYPE_DEFAULT	=> ':default',
    -by	=> 'name',
    -field_format_pattern	=> '%s: %s',
    -field_name_case_sensible	=> 0,
    -field_name_unsafe_rule	=> 'NON_ftext',
    -field_name_validation	=> 0,
    -field_sort	=> 0,
    -format	=> 'mail-rfc2822',
    -header_default_charset	=> 'iso-2022-int-1',
    -header_default_charset_input	=> 'iso-2022-int-1',
    -linebreak_strict	=> 0,
    -line_length_max	=> 60,	## For folding
    #ns_default_phuri
    -output_bcc	=> 0,
    -output_folding	=> 1,
    -output_mail_from	=> 0,
    #parse_all
    -translate_underscore	=> 1,
    #uri_mailto_safe
    -uri_mailto_safe_level	=> 4,
    -use_folding	=> 1,
    #value_type
);

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

=head1 CONSTRUCTORS

The following methods construct new C<Message::Header> objects:

=over 4

=cut

sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %options);
  $self->{value} = [];
  $self->_ns_load_ph ('default');
  $self->_ns_load_ph ('x-rfc822');
  $self->_ns_load_ph ('x-http');
  $self->{option}->{ns_default_phuri} = $self->{ns}->{phname2uri}->{'x-rfc822'}
    unless $self->{option}->{ns_default_phuri};
  
  ## For text/rfc822-headers
  if (ref $options{entity_header}) {
    $self->{entity_header} = $options{entity_header};
    delete $options{entity_header};
  }
  my @new_fields = ();
  for my $name (keys %options) {
    unless (substr ($name, 0, 1) eq '-') {
      push @new_fields, ($name => $options{$name});
    }
  }
  $self->_init_by_format ($self->{option}->{format}, $self->{option});
  # Make alternative representations of @header_order.  This is used
  # for sorting.
  my $i = 1;
  for (@header_order) {
      $header_order{$_} = $i++ unless $header_order{$_};
  }
  
  $self->add (@new_fields, -parse => $self->{option}->{parse_all})
    if $#new_fields > -1;
}

sub _init_by_format ($$\%) {
  my $self = shift;
  my ($format, $option) = @_;
  return if $format eq $option->{format};
  if ($format =~ /http/) {
    $option->{ns_default_phuri} = $self->{ns}->{phname2uri}->{'x-http'};
    if ($format =~ /cgi/) {
      unshift @header_order, qw(content-type location);
      $option->{field_sort} = 'good-practice';
      $option->{use_folding} = 0;
    } else {
      $option->{field_sort} = 'good-practice';
    }
  } elsif ($format =~ /mail|news/) {	## RFC 822
    $option->{ns_default_phuri} = $self->{ns}->{phname2uri}->{'x-rfc822'};
  }
  if ($format =~ /uri-url-mailto/) {
    $option->{output_bcc} = 0;
    $option->{field_format_pattern} = '%s=%s';
    $option->{output_folding} = sub {
      $_[1] =~ s/([^:@+\$A-Za-z0-9\-_.!~*])/sprintf('%%%02X', ord $1)/ge;
      $_[1];
    };	## Yes, this is not folding!
  }
}

=item $msg = Message::Header->new ([%initial-fields/options])

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

## Inherited

=item $msg = Message::Header->parse ($header, [%initial-fields/options])

Parses given C<header> and constructs a new C<Message::Headers> 
object.  You might pass some additional C<field-name>-C<field-body> pairs 
or/and initial options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $header = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  if ($self->{option}->{linebreak_strict}) {
    $header =~ s/\x0D\x0A$REG{WSP}/\x20/gos if $self->{option}->{use_folding};
  } else {
    $header =~ s/\x0D?\x0A$REG{WSP}/\x20/gos if $self->{option}->{use_folding};
  }
  my %option = (%{ $self->{option} });
  $option{parse_all} = 0;
  for my $field (split /\x0D?\x0A/, $header) {
    if ($field =~ /$REG{M_fromline}/) {
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ('mail-from' => $1, \%option);
      push @{$self->{value}}, $value if $s;
    } elsif ($field =~ /$REG{M_field}/) {
      my ($name, $body) = ($1, $2);
      $body =~ s/$REG{WSP}+$//;
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ($name => $body, \%option);
      push @{$self->{value}}, $value if $s;
    } elsif (length $field) {
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ('x-unknown' => $field, \%option);
      push @{$self->{value}}, $value if $s;
    }
  }
  $self->_ns_associate_numerical_prefix;	## RFC 2774 namespace
  for (@{ $self->{value} }) {
    no strict 'refs';
    $_->{name}
      = &{ ${ &_NS_uri2package ($_->{ns}).'::OPTION' }{n11n_name} }
      ($self, &_NS_uri2package ($_->{ns}), $_->{name});
    $_->{body} = $self->_parse_value ($_->{name} => $_->{body}, ns => $_->{ns})
      if $self->{option}->{parse_all};
  }
  $self;
}

=item $msg = Message::Header->parse_array (\@header, [%initial-fields/options])

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
    if ($self->{option}->{use_folding}) {
      while (1) {
        if ($$header[0] =~ /^$REG{WSP}/) {
          $field .= shift @$header;
        } else {last}
      }
    }
    if ($self->{option}->{linebreak_strict}) {
      $field =~ s/\x0D\x0A//g;
    } else {
      $field =~ tr/\x0D\x0A//d;
    }
    local $self->{option}->{parse} = $self->{option}->{parse_all};
    if ($field =~ /$REG{M_fromline}/) {
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ('mail-from' => $1, $self->{option});
      push @{$self->{value}}, $value if $s;
    } elsif ($field =~ /$REG{M_field}/) {
      my ($name, $body) = ($self->_n11n_field_name ($1), $2);
      $body =~ s/$REG{WSP}+$//;
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ($name => $body, $self->{option});
      push @{$self->{value}}, $value if $s;
    } elsif (length $field) {
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ('x-unknown' => $field, $self->{option});
      push @{$self->{value}}, $value if $s;
    }
    last if $#$header < 0;
  }
  $self->_ns_associate_numerical_prefix;	## RFC 2774 namespace
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

sub field ($@) {shift->SUPER::item (@_)}
sub field_exist ($@) {shift->SUPER::item_exist (@_)}

## item-by?, \$checked-item, {item-key => 1}, \%option
sub _item_match ($$\$\%\%) {
  my $self = shift;
  my ($by, $i, $list, $option) = @_;
  return 0 unless ref $$i;  ## Already removed
  if ($by eq 'name') {
    my %o = %$option; #$o{parse} = 0;
    my %l;
    for (keys %$list) {
      my ($s, undef, $v) = $self->_value_to_arrayitem ($_, '', \%o);
      if ($s) {
        $l{$v->{name} . ':' . ( $option->{ns} || $v->{ns} ) } = 1;
      } else {
        $l{$v->{name} .':'. ( $option->{ns} || $self->{option}->{ns_default_phuri} ) } = 1;
      }
    }
    return 1 if $l{$$i->{name} . ':' . $$i->{ns}};
  } elsif ($by eq 'ns') {
    return 1 if $list->{ $$i->{ns} };
  } elsif ($by eq 'http-ns-define') {
    if ($$i->{ns} eq $self->{ns}->{phname2uri}->{'x-http'}
     || $$i->{ns} eq $self->{ns}->{phname2uri}->{'x-http-c'}) {
      my $n = $$i->{name};
      if ($n eq 'opt' || $n eq 'c-opt' || $n eq 'man' || $n eq 'c-man') {
        $option->{parse} = 0;
        $$i->{body} = $self->_parse_value ($$i->{name} => $$i->{body}, ns => $$i->{ns});
        for my $j (0..$$i->{body}->count-1) {
          return 1 if $list->{ ($$i->{body}->value ($j))[0]->value };
        }
      }
    }
  }
  0;
}
*_delete_match = \&_item_match;

## Returns returned item value    \$item-value, \%option
sub _item_return_value ($\$\%) {
  if (ref ${$_[1]}->{body}) {
    ${$_[1]}->{body};
  } else {
    ${$_[1]}->{body} = $_[0]->_parse_value (${$_[1]}->{name} => ${$_[1]}->{body},
      ns => ${$_[1]}->{ns});
    ${$_[1]}->{body};
  }
}
*_add_return_value = \&_item_return_value;
*_replace_return_value = \&_item_return_value;

## Returns returned (new created) item value    $name, \%option
sub _item_new_value ($$\%) {
  my $self = shift;
  my ($name, $option) = @_;
  if ($option->{by} eq 'http-ns-define') {
    my $value = $self->_parse_value (opt => '', ns => $self->{ns}->{phname2uri}->{'x-http'});
    ($value->value (0))[0]->value ($name);
    {name => 'opt', body => $value, ns => $self->{ns}->{phname2uri}->{'x-http'}};
  } else {
    my ($s,undef,$value) = $self->_value_to_arrayitem
        ($name => '', $option);
    $s? $value: undef;
  }
}



## $self->_parse_value ($type, $value, %options);
sub _parse_value ($$$;%) {
  my $self = shift;
  my $name = shift ;#|| $self->{option}->{_VALTYPE_DEFAULT};
  my $value = shift;  return $value if ref $value;
  my %option = @_;
  my $vtype; { no strict 'refs';
    my $vt = ${&_NS_uri2package ($option{ns}).'::OPTION'}{value_type};
    if (ref $vt) {
      $vtype = $vt->{$name} || $vt->{$self->{option}->{_VALTYPE_DEFAULT}};
    }
    ## For compatiblity.
    unless (ref $vtype) { $vtype = $self->{option}->{value_type}->{$name}
      || $self->{option}->{value_type}->{$self->{option}->{_VALTYPE_DEFAULT}} }
  }
  my $vpackage = $vtype->[0];
  my %vopt = %{$vtype->[1]} if ref $vtype->[1];
  if ($vpackage eq ':none:') {
    return $value;
  } elsif (defined $value) {
    eval "require $vpackage" or Carp::croak qq{<parse>: $vpackage: Can't load package: $@};
    return $vpackage->parse ($value,
      -format	=> $self->{option}->{format},
      -field_ns	=> $option{ns},
      -field_name	=> $name,
    -header_default_charset	=> $self->{option}->{header_default_charset},
    -header_default_charset_input	=> $self->{option}->{header_default_charset_input},
      -parse_all	=> $self->{option}->{parse_all},
    %vopt);
  } else {
    eval "require $vpackage" or Carp::croak qq{<parse>: $vpackage: Can't load package: $@};
    return $vpackage->new (
      -format	=> $self->{option}->{format},
      -field_ns	=> $option{ns},
      -field_name	=> $name,
    -header_default_charset	=> $self->{option}->{header_default_charset},
    -header_default_charset_input	=> $self->{option}->{header_default_charset_input},
      -parse_all	=> $self->{option}->{parse_all},
    %vopt);
  }
}

## Defined for text/rfc822-headers
sub entity_header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{header} = $new_header;
  }
  $self->{header};
}

=head2 $self->field_name_list ()

Returns list of all C<field-name>s.  (Even if there are two
or more C<field>s which have same C<field-name>,  this method
returns ALL names.)

=cut

sub field_name_list ($) {
  my $self = shift;
  $self->_delete_empty ();
  map { $_->{name} . ':' . $_->{ns} } @{$self->{value}};
}

sub namespace_ph_default ($;$) {
  my $self = shift;
  if (defined $_[0]) {
    no strict 'refs';
    $self->{option}->{ns_default_phuri} = $_[0];
    $self->_ns_load_ph (${&_NS_uri2package ($self->{option}->{ns_default_phuri}).'::OPTION'}{namespace_phname});
  }
  $self->{option}->{ns_default_phuri};
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

## [Name: Value] pair -> internal array item
## $self->_value_to_arrayitem ($name => $value, {%options})
## or
## $self->_value_to_arrayitem ($name => [$value, %value_options], {%options})
## 
## Return: ((1 = success / 0 = failue), $full_name, $arrayitem)
sub _value_to_arrayitem ($$$\%) {
  my $self = shift;
  my ($name, $value, $option) = @_;
  my $value_option = {};
  if (ref $value eq 'ARRAY') {
    ($value, %$value_option) = @$value;
  }
  my $default_ns = $option->{ns_default_phuri};
  my $nsuri = $default_ns;
  $name =~ s/^$REG{WSP}+//;  $name =~ s/$REG{WSP}+$//;
  
  no strict 'refs';
  if ($value_option->{ns}) {
    $nsuri = $value_option->{ns};
  } elsif ($option->{ns}) {
    $nsuri = $option->{ns};
  } elsif (($default_ns eq $self->{ns}->{uri2phname}->{'x-http'}
       && $name =~ s/^([0-9]+)-//)
    || ($name =~ s/^x-http-([0-9]+)-//i)) {	## Numric namespace prefix, RFC 2774
    my $prefix = 0+$1;
    $nsuri = $self->{ns}->{number2uri}->{ $prefix };
    unless ($nsuri) {
      $self->{ns}->{number2uri}->{ $prefix } = 'urn:x-suika-fam-cx:msgpm:header:x-temp:'.$prefix;
      $nsuri = $self->{ns}->{number2uri}->{ $prefix };
    }
  } elsif (
    ${ &_NS_uri2package ($default_ns).'::OPTION' }{use_ph_namespace}
    && (
       ($name =~ s/^([Xx]-[A-Za-z0-9]+|[A-Za-z]*[A-WYZa-wyz0-9][A-Za-z0-9]*)-
                    ([Xx]-[A-Za-z0-9]+|[A-Za-z0-9]*[A-WYZa-wyz0-9][A-Za-z0-9]*)-//x)
     || $name =~ s/^([Xx]-[A-Za-z0-9]+|[A-Za-z0-9]*[A-WYZa-wyz0-9][A-Za-z0-9]*)-//
    )) {
    my ($prefix1, $prefix2) = ($1, $2);
    my $original_prefix = $&;  my $one_prefix = 0;
    unless ($prefix2) {
      $prefix2 = $prefix1;
      $prefix1 = $self->{ns}->{uri2phname}->{ $default_ns };
      $one_prefix = 1;
    }
    my $prefix
      = &{ ${ &_NS_uri2package ($nsuri).'::OPTION' }{n11n_prefix} }
        ($self, &_NS_uri2package ($nsuri), $prefix1.'-'.$prefix2);
    $self->_ns_load_ph ($prefix);
    $nsuri = $self->{ns}->{phname2uri}->{ $prefix };
    unless ($nsuri) {
      $nsuri = $default_ns;
      $prefix
        = &{ ${ &_NS_uri2package ($nsuri).'::OPTION' }{n11n_prefix} }
          ($self, &_NS_uri2package ($nsuri), $one_prefix? $prefix2: $prefix1);
      $self->_ns_load_ph ($prefix);
      $nsuri = $self->{ns}->{phname2uri}->{ $prefix };
      if ($nsuri) {
        $name = $prefix2 . '-' . $name unless $one_prefix;
      } else {
        $name = $original_prefix . $name;
        $nsuri = $default_ns;
      }
    }
  }
  $name
    = &{ ${ &_NS_uri2package ($nsuri).'::OPTION' }{n11n_name} }
      ($self, &_NS_uri2package ($nsuri), $name);
  Carp::croak "$name: invalid field-name"
    if $option->{field_name_validation}
      && $name =~ /$REG{ $option->{field_name_unsafe_rule} }/;
  $value = $self->_parse_value ($name => $value, ns => $nsuri)
    if $option->{parse} || $option->{parse_all};
  $option->{parse} = 0;
  (1, $name.':'.$nsuri => {name => $name, body => $value, ns => $nsuri});
}
*_add_hash_check = \&_value_to_arrayitem;
*_replace_hash_check = \&_value_to_arrayitem;

=head2 $self->relace ($field_name, $field_body)

Set the C<field-body> named C<field-name> as $field_body.
If $field_name C<field> is already exists, it is replaced
by new $field_body value.  If not, new C<field> is inserted.
(If there are some C<field> named as $field_name,
first one is used and the others are not changed.)

=cut

sub _replace_hash_shift ($\%$\%) {
  shift; my $r = shift;  my $n = $_[0]->{name} . ':' . $_[0]->{ns};
  if ($$r{$n}) {
    my $d = $$r{$n};
    delete $$r{$n};
    return $d;
  }
  undef;
}

=head2 $self->delete ($field-name, [$name, ...])

Deletes C<field> named as $field_name.

=cut


=head2 $self->count ([$field_name])

Returns the number of times the given C<field> appears.
If no $field_name is given, returns the number
of fields.  (Same as $#$self+1)

=cut

sub _count_by_name ($$\%) {
  my $self = shift;
  my ($array, $option) = @_;
  my $name = $self->_n11n_field_name ($$option{-name});
  my @a = grep {$_->{name} eq $name} @{$self->{$array}};
  $#a + 1;
}

## Delete empty items
sub _delete_empty ($) {
  my $self = shift;
  my $array = $self->{option}->{_HASH_NAME};
  $self->{$array} = [grep {ref $_ && length $_->{name}} @{$self->{$array}}];
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
    my ($old => $new)
      = ($self->_n11n_field_name ($_) => $self->_n11n_field_name ($params{$_}));
    $old =~ tr/_/-/ if $option{translate_underscore};
    $new =~ tr/_/-/ if $option{translate_underscore};
    Carp::croak "rename: $new: invalid field-name"
      if $option{field_name_validation}
        && $new =~ /$REG{$option{field_name_unsafe_rule}}/;
    $new_name{$old} = $new;
  }
  for my $field (@{$self->{value}}) {
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

sub _scan_sort ($\@\%) {
  my $self = shift;
  my ($array, $option) = @_;
  my $sort;
  $sort = \&_header_cmp if $option->{field_sort} eq 'good-practice';
  $sort = {$a cmp $b} if $option->{field_sort} eq 'alphabetic';
  return ( sort $sort @$array ) if ref $sort;
  @$array;
}

sub _n11n_field_name ($$) {
  no strict 'refs';
  my $self = shift;
  my $s = shift;
  $s =~ s/^$REG{WSP}+//; $s =~ s/$REG{WSP}+$//;
  $s = lc $s unless ${&_NS_uri2package ($self->{option}->{ns_default_phuri}).'::OPTION'}{case_sensible};
  $s;
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
  $option{format} = $params{-format} if $params{-format};
  $self->_init_by_format ($option{format}, \%option);
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my @ret;
  ## RFC 2774 numerical field name prefix
  my %nprefix;
  {no strict 'refs';
    %nprefix = reverse %{ $self->{ns}->{number2uri} };
    my $i = (sort { $a <=> $b } keys %{ $self->{ns}->{number2uri} })[-1] + 1;
    $i = 10 if $i < 10;
    my $hprefix = ${ &_NS_uri2package
                       ($self->{ns}->{phname2uri}->{'x-http'})
                       .'::OPTION' } {namespace_phname_goodcase};
    for my $uri (keys %nprefix) {
      if ($nprefix{ $uri } < 10) {
        $nprefix{ $uri } = $i++;
      }
      my $nsfs = $self->item ($uri, -by => 'http-ns-define');
      for my $i (0..$nsfs->count-1) {
        my $nsf = ($nsfs->value ($i))[0];
        if ($nsf->value eq $uri) {
          $nsf->replace (ns => $nprefix{ $uri });
          $nprefix{ $uri } = $hprefix . '-' . $nprefix{ $uri };
          last;
        }
      }
    }
  }
  my $_stringify = sub {
    no strict 'refs';
      my ($name, $body, $nsuri) = ($_[1]->{name}, $_[1]->{body}, $_[1]->{ns});
      return unless length $name;
      return if $option{output_mail_from} && $name eq 'mail-from';
      $body = '' if !$option{output_bcc} && $name eq 'bcc';
      my $nspackage = &_NS_uri2package ($nsuri);
      my $oname;	## Outputed field-name
      my $prefix = $nprefix{ $nsuri }
                || ${$nspackage.'::OPTION'} {namespace_phname_goodcase}
                || $self->{ns}->{uri2phname}->{ $nsuri };
      my $default_prefix = ${ &_NS_uri2package ($option{ns_default_phuri})
                              .'::OPTION'} {namespace_phname_goodcase};
      $prefix = '' if $prefix eq $default_prefix;
      $prefix =~ s/^\Q$default_prefix\E-//;
      my $gc = ${$nspackage.'::OPTION'} {to_be_goodcase};
      if (ref $gc) { $oname = &$gc ($self, $nspackage, $name, \%option) }
      else { $oname = $name }
      if ($prefix) { $oname = $prefix . '-' . $oname }
      if ($option{format} =~ /uri-url-mailto/) {
        return if (( ${$nspackage.'::OPTION'} {uri_mailto_safe}->{$name}
                  || ${$nspackage.'::OPTION'} {uri_mailto_safe}->{':default'})
                  < $option{uri_mailto_safe_level});
        if ($name eq 'to') {
          $body = $self->field ('to', -new_item_unless_exist => 0);
          if (ref $body && $body->have_group) {
            # 
          } elsif (ref $body && $body->count > 1) {
            $body = $body->clone;
            $body->delete ({-by => 'index'}, 0);
          }
        }
      }
      my $fbody;
      if (ref $body) {
        $fbody = $body->stringify (-format => $option{format});
      } else {
        $fbody = $body;
      }
      unless (${$nspackage.'::OPTION'} {field}->{$name}->{empty_body}) {
        return unless length $fbody;
      }
      unless ($option{linebreak_strict}) {
        ## bare \x0D and bare \x0A are unsafe
        $fbody =~ s/\x0D(?=[^\x09\x0A\x20])/\x0D\x20/g;
        $fbody =~ s/\x0A(?=[^\x09\x20])/\x0A\x20/g;
      } else {
        $fbody =~ s/\x0D\x0A(?=[^\x09\x20])/\x0D\x0A\x20/g;
      }
      if ($option{use_folding}) {
        if (ref $option{output_folding}) {
          $fbody = &{$option{output_folding}} ($self, $fbody,
            -initial_length => length ($oname) +2);
        } elsif ($option{output_folding}) {
          $fbody = $self->_fold ($fbody, -initial_length => length ($oname) +2);
        }
      }
      push @ret, sprintf $option{field_format_pattern}, $oname, $fbody;
    };
  if ($option{format} =~ /uri-url-mailto/) {
    if ($option{format} =~ /uri-url-mailto-to/) {
      my $to = $self->field ('to', -new_item_unless_exist => 0);
      if ($to) {
        unless ($to->have_group) {
          my $fbody = $to->stringify (-format => $option{format}, -max => 1);
          return &{$option{output_folding}} ($self, $fbody);
        }
      }
      '';
    } elsif ($option{format} =~ /uri-url-mailto-rfc1738/) {
      my $to = $self->field ('to', -new_item_unless_exist => 0);
      if ($to) {
        my $fbody = $to->addr_spec (-format => $option{format});
        return &{$option{output_folding}} ($self, $fbody);
      }
      '';
    } else {
      $self->scan ($_stringify);
      my $ret = join ('&', @ret);
      $ret;
    }
  } else {
    if ($option{output_mail_from}) {
      my $fromline = $self->field ('mail-from', -new_item_unless_exist => 0);
      push @ret, 'From '.$fromline if $fromline;
    }
    $self->scan ($_stringify);
    my $ret = join ("\x0D\x0A", @ret);
    $ret? $ret."\x0D\x0A": '';
  }
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

sub field_type ($@) {shift->SUPER::value_type (@_)}

## $self->_fold ($string, %option = (-max, -initial_length(for field-name)) )
sub _fold ($$;%) {
  my $self = shift;
  my $string = shift;
  my %option = @_;
  my $max = $self->{option}->{line_length_max};
  $max = 20 if $max < 20;
  
  my $l = $option{-initial_length} || 0;
  $l += length $1 if $string =~ /^([^\x09\x20]+)/;
  $string =~ s{([\x09\x20][^\x09\x20]+)}{
    my $s = $1;
    if (($l + length $s) > $max) {
      $s = "\x0D\x0A\x20" . $s;
      $l = 1 + length $s;
    } else { $l += length $s }
    $s;
  }gex;
  $string;
}

sub _ns_load_ph ($$) {
  my $self = shift;
  my $name = shift;	## normalized prefix (without HYPHEN-MINUS)
  return if $self->{ns}->{phname2uri}->{$name};
  $self->{ns}->{phname2uri}->{$name} = $NS_phname2uri{$name};
  return unless $self->{ns}->{phname2uri}->{$name};
  $self->{ns}->{uri2phname}->{$self->{ns}->{phname2uri}->{$name}} = $name;
}

sub _ns_associate_numerical_prefix ($) {
  my $self = shift;
  $self->scan (sub {shift;
    my $f = shift;  return unless $f->{name};
    if ($f->{ns} eq $self->{ns}->{phname2uri}->{'x-http'}
     || $f->{ns} eq $self->{ns}->{phname2uri}->{'x-http-c'}) {
      my $fn = $f->{name};
      if ($fn eq 'opt' || $fn eq 'man') {
        $f->{body} = $self->_parse_value ($fn => $f->{body}, ns => $f->{ns});
        for ($f->{body}->value (0..$f->{body}->count-1)) {
          my ($nsuri, $number) = ($_->value, $_->item ('ns'));
          if ($number && $nsuri) {
            $self->{ns}->{number2uri}->{ $number } = $nsuri;
          }
        }
      }
    }
  });
  $self->scan (sub {shift;
    my $f = shift;
    if ($f->{ns} =~ /urn:x-suika-fam-cx:msgpm:header:x-temp:([0-9]+)$/ && $self->{ns}->{number2uri}->{ $1 }) {
      $f->{ns} = $self->{ns}->{number2uri}->{ $1 };
    }
  });
}

## $package_name = Message::Header::_NS_uri2phpackage ($nsuri)
## (For internal use of Message::* modules)
sub _NS_uri2phpackage ($) {
  $NS_uri2phpackage{$_[0]}
  || $NS_uri2phpackage{$Message::Header::Default::OPTION{namespace_uri}};
}
sub _NS_uri2package ($) {
  $NS_uri2package{$_[0]}
  || $NS_uri2phpackage{$_[0]}
  || $NS_uri2phpackage{$Message::Header::Default::OPTION{namespace_uri}};
}

=head2 $self->clone ()

Returns a copy of Message::Header object.

=cut

## Inhreited

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
$Date: 2002/07/08 11:49:18 $

=cut

1;
