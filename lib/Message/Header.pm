
=head1 NAME

Message::Header --- A Perl Module for Internet Message Headers

=cut

package Message::Header;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.23 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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
	our %NS_uri2phpackage;	## namespace URI -> PH-package name
	require Message::Header::Default;	## Default namespace

## Initialize of this class -- called by constructors
%DEFAULT = (
    -_HASH_NAME	=> 'value',
    -_METHODS	=> [qw|field field_exist field_type add replace count delete subject id is|],
    -_MEMBERS	=> [qw|value|],
    -M_namsepace_prefix_regex => qr/(?!)/,
    -_VALTYPE_DEFAULT	=> ':default',
    -by	=> 'name',	## (Reserved for method level option)
    -field_format_pattern	=> '%s: %s',
    -field_name_case_sensible	=> 0,
    -field_name_unsafe_rule	=> 'NON_ftext',
    -field_name_validation	=> 1,	## Method level option.
    -field_sort	=> 0,
    #-format	=> 'mail-rfc2822',
    -linebreak_strict	=> 0,	## Not implemented completely
    -line_length_max	=> 60,	## For folding
    -ns_default_uri	=> $Message::Header::Default::OPTION{namespace_uri},
    -output_bcc	=> 0,
    -output_folding	=> 1,
    -output_mail_from	=> 0,
    #-parse_all	=> 0,
    -translate_underscore	=> 1,
    #-uri_mailto_safe
    -uri_mailto_safe_level	=> 4,
    -use_folding	=> 1,
    #-value_type
);

$DEFAULT{-value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
	
	p3p	=> ['Message::Field::Params'],
	link	=> ['Message::Field::ValueParams'],
	
	'list-software'	=> ['Message::Field::UA'],
	'user-agent'	=> ['Message::Field::UA'],
	server	=> ['Message::Field::UA'],
};
for (qw(pics-label list-id status))
  {$DEFAULT{-value_type}->{$_} = ['Message::Field::Structured']}
  	## Not supported yet, but to be supported...
  	# x-list: unstructured, ml name
for (qw(date expires))
  {$DEFAULT{-value_type}->{$_} = ['Message::Field::Date']}
for (qw(accept accept-charset accept-encoding accept-language uri))
  {$DEFAULT{-value_type}->{$_} = ['Message::Field::CSV']}
for (qw(location referer))
  {$DEFAULT{-value_type}->{$_} = ['Message::Field::URI']}

my %header_goodcase = (
	'article-i.d.'	=> 'Article-I.D.',
	etag	=> 'ETag',
	'pics-label'	=> 'PICS-Label',
	te	=> 'TE',
	url	=> 'URL',
	'www-authenticate'	=> 'WWW-Authenticate',
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
  $self->{ns}->{default_phuri} = $self->{ns}->{phname2uri}->{'default'};
  $self->_ns_load_ph ('rfc822');
  $self->{ns}->{default_phuri} = $self->{ns}->{phname2uri}->{'rfc822'};
  
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
  if ($format =~ /cgi/) {
    unshift @header_order, qw(content-type location);
    $option->{field_sort} = 'good-practice';
    $option->{use_folding} = 0;
  } elsif ($format =~ /http/) {
    $option->{field_sort} = 'good-practice';
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
  $self->_init (@_);	## BUG: don't check linebreak_strict
  $header =~ s/\x0D?\x0A$REG{WSP}/\x20/gos if $self->{option}->{use_folding};
  for my $field (split /\x0D?\x0A/, $header) {
    if ($field =~ /$REG{M_fromline}/) {
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ('mail-from' => $1, $self->{option});
      push @{$self->{value}}, $value if $s;
    } elsif ($field =~ /$REG{M_field}/) {
      my ($name, $body) = ($1, $2);
      $body =~ s/$REG{WSP}+$//;
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ($name => $body, $self->{option});
      push @{$self->{value}}, $value if $s;
    } elsif (length $field) {
      my ($s,undef,$value) = $self->_value_to_arrayitem
        ('x-unknown' => $field, $self->{option});
      push @{$self->{value}}, $value if $s;
    }
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
    my %o = %$option; $o{parse} = 0;
    my %l;
    for (keys %$list) {
      my ($s, undef, $v) = $self->_value_to_arrayitem ($_, '', %o);
      if ($s) {
        $l{$v->{name} . ':' . ( $option->{ns} || $v->{ns} ) } = 1;
      } else {
        $l{$v->{name} .':'. ( $option->{ns} || $self->{ns}->{default_phuri} ) } = 1;
      }
    }
    return 1 if $l{$$i->{name} . ':' . $$i->{ns}};
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

## Returns returned (new created) item value    $name, \%option
sub _item_new_value ($$\%) {
    my ($s,undef,$value) = $_[0]->_value_to_arrayitem
        ($_[1] => '', $_[2]);
    $s? $value: undef;
}



## $self->_parse_value ($type, $value, %options);
sub _parse_value ($$$;%) {
  my $self = shift;
  my $name = shift ;#|| $self->{option}->{_VALTYPE_DEFAULT};
  my $value = shift;  return $value if ref $value;
  my %option = @_;
  my $vtype; { no strict 'refs';
    $vtype = ${&_NS_uri2phpackage ($option{ns}).'::OPTION'}{value_type};
    if (ref $vtype) { $vtype = $vtype->{$name} }
    unless (ref $vtype) { $vtype = $vtype->{$self->{option}->{_VALTYPE_DEFAULT}} }
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
      -parse_all	=> $self->{option}->{parse_all},
    %vopt);
  } else {
    eval "require $vpackage" or Carp::croak qq{<parse>: $vpackage: Can't load package: $@};
    return $vpackage->new (
      -format	=> $self->{option}->{format},
      -field_ns	=> $option{ns},
      -field_name	=> $name,
      -parse_all	=> $self->{option}->{parse_all},
    %vopt);
  }
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
    $self->{ns}->{default_phuri} = $_[0];
    $self->_ns_load_ph (${&_NS_uri2phpackage ($self->{ns}->{default_phuri}).'::OPTION'}{namespace_phname});
  }
  $self->{ns}->{default_phuri};
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
  my $nsuri = $self->{ns}->{default_phuri};
  no strict 'refs';
  if ($option->{ns}) {
    $nsuri = $option->{ns};
  } elsif ($name =~ s/^([Xx]-[A-Za-z]+|[A-Za-z]+)-//) {
    my $oprefix = $1;
    my $prefix
      = &{${&_NS_uri2phpackage ($nsuri).'::OPTION'}{n11n_prefix}}
        ($self, &_NS_uri2phpackage ($nsuri), $oprefix);
    $self->_ns_load_ph ($prefix);
    $nsuri = $self->{ns}->{phname2uri}->{$prefix};
    unless ($nsuri) {
      $name = $oprefix . '-' . $name;
      $nsuri = $self->{ns}->{default_phuri};
    }
  }
  $name
    = &{${&_NS_uri2phpackage ($nsuri).'::OPTION'}{n11n_name}}
      ($self, &_NS_uri2phpackage ($nsuri), $name);
  Carp::croak "$name: invalid field-name"
    if $option->{field_name_validation}
      && $name =~ /$REG{$option->{field_name_unsafe_rule}}/;
  $value = $self->_parse_value ($name => $value, ns => $nsuri) if $$option{parse};
  $$option{parse} = 0;
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
  my $self = shift;
  my $s = shift;
  $s =~ s/^$REG{WSP}+//; $s =~ s/$REG{WSP}+$//;
  $s = lc $s ;#unless $self->{option}->{field_name_case_sensible};
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
  my $_stringify = sub {
    no strict 'refs';
      my ($name, $body, $nsuri) = ($_[1]->{name}, $_[1]->{body}, $_[1]->{ns});
      return unless length $name;
      return if $option{output_mail_from} && $name eq 'mail-from';
      return if !$option{output_bcc} && ($name eq 'bcc' || $name eq 'resent-bcc');
      my $nspackage = &_NS_uri2phpackage ($nsuri);
      my $oname;	## Outputed field-name
      my $prefix = ${$nspackage.'::OPTION'} {namespace_phname_goodcase}
                || $self->{ns}->{uri2phname}->{$nsuri};
      $prefix = undef if $nsuri eq $self->{ns}->{default_phuri};
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
      return unless length $fbody;
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
  $string =~ s{([\x09\x20][^\x09\x20]+)}{
    my $s = $1;
    if ($l + length $s > $max) {
      $s = "\x0D\x0A\x20" . $s;
      $l = length ($s) - 2;
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

sub _NS_uri2phpackage ($) {
  $NS_uri2phpackage{$_[0]}
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
$Date: 2002/06/09 11:20:24 $

=cut

1;
