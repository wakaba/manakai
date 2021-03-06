
=head1 NAME

Message::Field::Structured --- A Perl Module for Internet
Message Structured Header Field Bodies

=cut

package Message::Field::Structured;
use strict;
use vars qw(%DEFAULT $VERSION);
$VERSION=do{my @r=(q$Revision: 1.21 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
use overload '""' => sub { $_[0]->stringify },
             '.=' => sub { $_[0]->value_append ($_[1]) },
             #'eq' => sub { $_[0]->{field_body} eq $_[1] },
             #'ne' => sub { $_[0]->{field_body} ne $_[1] },
             fallback => 1;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    _ARRAY_NAME	=> '',
    _ARRAY_VALTYPE	=> '*default',
    _HASH_NAME	=> '',
    _METHODS	=> [qw|as_plain_string value_append|],
    _MEMBERS	=> [qw|field_body|],
    _VALTYPE_DEFAULT	=> '*default',
    by	=> 'index',	## (Reserved for method level option)
    dont_croak	=> 0,	## Don't die unless very very fatal error
    encoding_after_encode	=> '*default',
    encoding_before_decode	=> '*default',
    field_param_name	=> '',
    field_name	=> 'x-structured',
    #field_ns	=> '',
    format	=> 'mail-rfc2822',
    ## MIME charset name of '*default' charset
      header_default_charset	=> 'iso-2022-int-1',
      header_default_charset_input	=> 'iso-2022-int-1',
    hook_encode_string	=> #sub {shift; (value => shift, @_)},
    	\&Message::Util::encode_header_string,
    hook_decode_string	=> #sub {shift; (value => shift, @_)},
    	\&Message::Util::decode_header_string,
    internal_charset_name	=> 'utf-8',
    #name	## Reserved for method level option
    #parse	## Reserved for method level option
    parse_all	=> 0,
    prepend	=> 0,	## (Reserved for method level option)
    value_type	=> {'*default'	=> [':none:']},
  );
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{option} = Message::Util::make_clone (\%DEFAULT);
  $self->{field_body} = '';
  
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } elsif ($name eq 'body') {
      $self->{field_body} = $options{$name};
    }
  }
  $self->{comment} = [];
}

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Unstructured> objects:

=over 4

=item Message::Field::Structured->new ([%options])

Constructs a new C<Message::Field::Structured> object.  You might pass some 
options as parameters to the constructor.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  $self;
}

=item Message::Field::Structured->parse ($field-body, [%options])

Constructs a new C<Message::Field::Structured> object with
given field body.  You might pass some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  #my $field_body = $self->Message::Util::decode_qcontent (shift);
  $self->{field_body} = shift; #$field_body;
  $self;
}

=back

=cut

## Template procedures for array/hash fields
## (As bare Message::Field::Structured module,
##  these shall not be used.)

sub add ($$$%) {
  my $self = shift;
  
  my $array = $self->{option}->{_ARRAY_NAME};
  if ($array) {
  
  ## --- field is non-named value list (i.e. not hash)
    
    ## Options
    my %option = %{$self->{option}};
    if (ref $_[0] eq 'HASH') {
      my $option = shift (@_);
      for (keys %$option) {my $n = $_; $n =~ s/^-//; $option{$n} = $$option{$_}}
    }
    $option{parse} = 1 if defined wantarray && !defined $option{parse};
    $option{parse} = 1 if $option{parse_all} && !defined $option{parse};
    
    ## Additional items
    my $avalue;
    for (@_) {
      local $option{parse} = $option{parse};
      my $ok;
      ($ok, undef, $avalue) = $self->_add_array_check ($_, \%option);
      if ($ok) {
        $avalue = $self->_parse_value
          ($option{_ARRAY_VALTYPE} => $avalue) if $option{parse};
        if ($option{prepend}) {
          unshift @{$self->{$array}}, $avalue;
        } else {
          push @{$self->{$array}}, $avalue;
        }
      }
    }
    $self->_add_return_value (\$avalue, \%option);
    	## Return last added value if necessary.
    
  } else {
    $array = $self->{option}->{_HASH_NAME};
  
  ## --- field is not list
  
    unless ($array) {
      my %option = @_;
      return if $option{-dont_croak};
      Carp::croak (q{add: Method not available for this module});
    }
    
  ## --- field is named value list (i.e. hash)
    
    ## Options
    my %p = @_; my %option = %{$self->{option}};
    for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
    $option{parse} = 1 if defined wantarray && !defined $option{parse};
    $option{parse} = 1 if $option{parse_all} && !defined $option{parse};
    
    ## Additional items
    my $avalue;
    while (my ($name => $value) = splice (@_, 0, 2)) {
      next if $name =~ /^-/; $name =~ s/^\\//;
      $name =~ tr/_/-/ if $option{translate_underscore};
      
      my $ok;
      local $option{parse} = $option{parse};
      ($ok, $name, $avalue) = $self->_add_hash_check ($name => $value, \%option);
      if ($ok) {
        $avalue = $self->_parse_value ($name => $avalue) if $option{parse};
        if ($option{prepend}) {
          unshift @{$self->{$array}}, $avalue;
        } else {
          push @{$self->{$array}}, $avalue;
        }
      }
    }
    $self->_add_return_value (\$avalue, \%option);
    	## Return last added value if necessary.
  }
}

sub _add_array_check ($$\%) {
  shift; 1, $_[0] => $_[0];
}
sub _add_hash_check ($$$\%) {
  shift; 1, $_[0] => [@_[0,1]];
}
## Returns returned item value    \$item-value, \%option
sub _add_return_value ($\$\%) {
  $_[1];
}

sub replace ($$$%) {
  my $self = shift;
  
  $self->_replace_cleaning;
  my $array = $self->{option}->{_ARRAY_NAME};
  if ($array) {
  
  ## --- field is non-named value list (i.e. not hash)
    
    ## Options
    my %option = %{$self->{option}};
    if (ref $_[0] eq 'HASH') {
      my $option = shift (@_);
      for (keys %$option) {my $n = $_; $n =~ s/^-//; $option{$n} = $$option{$_}}
    }
    $option{parse} = 1 if defined wantarray && !defined $option{parse};
    $option{parse} = 1 if $option{parse_all} && !defined $option{parse};
    
    ## Additional items
    my ($avalue, %replace);
    for (@_) {
      local $option{parse} = $option{parse};
      my ($ok, $aname);
      ($ok, $aname => $avalue)
        = $self->_replace_array_check ($_, \%option);
      if ($ok) {
        $avalue = $self->_parse_value
          ($option{_ARRAY_VALTYPE} => $avalue) if $option{parse};
        $replace{$aname} = $avalue;
      }
    }
    for (@{$self->{$array}}) {
      my ($v) = $self->_replace_array_shift (\%replace => $_, \%option);
      if (defined $v) {
        $_ = $v;
      }
    }
    for (keys %replace) {
      if ($option{prepend}) {
        unshift @{$self->{$array}}, $replace{$_};
      } else {
        push @{$self->{$array}}, $replace{$_};
      }
    }
    $self->_replace_return_value (\$avalue, \%option);
    	## Return last added value if necessary.
    
  } else {
    $array = $self->{option}->{_HASH_NAME};
  
  ## --- field is not list
  
    unless ($array) {
      my %option = @_;
      return if $option{-dont_croak};
      Carp::croak (q{replace: Method not available for this module});
    }
    
  ## --- field is named value list (i.e. hash)
    
    ## Options
    my %p = @_; my %option = %{$self->{option}};
    for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
    $option{parse} = 1 if defined wantarray && !defined $option{parse};
    $option{parse} = 1 if $option{parse_all} && !defined $option{parse};
    
    ## Additional items
    my ($avalue, %replace);
    while (my ($name => $value) = splice (@_, 0, 2)) {
      next if $name =~ /^-/; $name =~ s/^\\//;
      $name =~ tr/_/-/ if $option{translate_underscore};
      
      my ($ok, $aname);
      local $option{parse} = $option{parse};
      ($ok, $aname => $avalue)
        = $self->_replace_hash_check ($name => $value, \%option);
      if ($ok) {
        $avalue = $self->_parse_value ($name => $avalue) if $option{parse};
        $replace{$aname} = $avalue;
      }
    }
    for (@{$self->{$array}}) {
      last unless keys %replace;
      my ($v) = $self->_replace_hash_shift (\%replace => $_, \%option);
      if (defined $v) {
        $_ = $v;
      }
    }
    for (keys %replace) {
      if ($option{prepend}) {
        unshift @{$self->{$array}}, $replace{$_};
      } else {
        push @{$self->{$array}}, $replace{$_};
      }
    }
    $self->_replace_return_value (\$avalue, \%option);
    	## Return last added value if necessary.
  }
}

## $self->_replace_cleaning
## -- Cleans the array/hash before replacing
sub _replace_cleaning ($) {
  $_[0]->_delete_empty;
}
#*_replace_cleaning = \&_delete_empty;
	## Be not aliasing for inheriting class

## (1/0, $name => $value) = $self->_replace_array_check ($value, \%option)
## -- Checks given value and prepares saving value (array version)
##    Note that $name of return value is used as key for _replace_array_shift.
##    Usually, it is same as $value.
## Note: In many case, same code as _add_array_check can be used.
sub _replace_array_check ($$\%) {
  shift; 1, $_[0] => $_[0];
}

## $value = $self->_replace_array_shift (\%values, $name, $option)
## -- Returns a value (from %values, with key of $name) and deletes 
##    it from %values (like CORE::shift for array) (array version)
sub _replace_array_shift ($\%$\%) {
  shift; my $r = shift;  my $n = $_[0]->[0];
  if ($$r{$n}) {
    my $d = $$r{$n};
    $$r{$n} = undef;
    return $d;
  }
  undef;
}

## (1/0, $name => $value) = $self->_replace_hash_check ($name => $value, \%option)
## -- Checks given value and prepares saving value (hash version)
## Note: In many case, same code as _add_hash_check can be used.
sub _replace_hash_check ($$$\%) {
  shift; 1, $_[0] => [@_[0,1]];
}

## $value = $self->_replace_hash_shift (\%values, $name, $option)
## -- Returns a value (from %values, with key of $name) and 
##    deletes it from %values (like CORE::shift for array) (hash version)
sub _replace_hash_shift ($\%$\%) {
  shift; my $r = shift;  my $n = $_[0]->[0];
  if ($$r{$n}) {
    my $d = $$r{$n};
    $$r{$n} = undef;
    return $d;
  }
  undef;
}

## $value = $self->_replace_return_value (\$item, \%option)
## -- Returns returning value of replace method
## Note: Usually this can share code with _item_return_value.
sub _replace_return_value ($\$\%) {
  $_[1];
}

## TODO: Implement count by any and merge with item_exist
sub count ($;%) {
  my $self = shift; my %option = @_;
  my $array = $self->{option}->{_ARRAY_NAME}
           || $self->{option}->{_HASH_NAME};
  unless ($array) {
    return if $option{-dont_croak};
    Carp::croak (q{count: Method not available for this module});
  }
  $self->_count_cleaning;
  return $self->_count_by_name ($array => \%option) if defined $option{-name};
  $#{$self->{$array}} + 1;
}

## $self->_count_cleaning
## -- Cleans the array/hash before counting
sub _count_cleaning ($) {
  $_[0]->_delete_empty;
}

sub _count_by_name ($$\%) {
  # my $self = shift;
  # my ($array, $option) = @_;
  # my $name = $self->_n11n_*name* ($$option{-name});
  # my @a = grep {$_->[0] eq $name} @{$self->{$array}};
  # $#a + 1;
}

sub delete ($@) {
  my $self = shift;
  my %p; %p = %{shift (@_)} if ref $_[0] eq 'HASH';
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  my $array = $option{_ARRAY_NAME} || $option{_HASH_NAME};
  unless ($array) {
    return if $option{dont_croak};
    Carp::croak (q{delete: Method not available for this module});
  }
  if ($option{by} && $option{by} ne 'index') {
    my %name; for (@_) {$name{$_} = 1}
    for (@{$self->{$array}}) {
      if ($self->_delete_match ($option{by}, \$_, \%name, \%option)) {
        $_ = undef;
      }
    }
  } else {	## by index
    for (@_) {
      $self->{$array}->[$_] = undef;
    }
  }
  $self->_delete_cleaning;
}

## 1/0 = $self->_delete_match ($by, \$item, \%delete_list, \%option)
## -- Checks and returns whether given item is matched with
##    deleting item list
## Note: Usually this code can be shared with _item_match.
## Note: $by eq 'index' is already defined in delete method
##       itself, so in this function it need not be checked.
sub _delete_match ($$\$\%\%) {
  my $self = shift;
  my ($by, $item, $list, $option) = @_;
  return 0 unless ref $$item;	## Already removed
  ## An example definition
  if ($by eq 'name') {
    $$item->{value} = $self->_parse_value ($$item->{type}, $$item->{value});
    return 1 if ref $$item->{value} && $$list{ $$item->{value}->{name} };
  }
  0;
}

sub _delete_cleaning ($) {
  $_[0]->_delete_empty;
}

## Delete empty items
sub _delete_empty ($) {
  my $self = shift;
  my $array = $self->{option}->{_ARRAY_NAME} || $self->{option}->{_HASH_NAME};
  $self->{$array} = [grep {length $_} @{$self->{$array}}] if $array;
}

sub item ($$;%) {
  my $self = shift;
  my ($name, %p) = (shift, @_);
  ## BUG: don't support -by
  return $self->replace ($name => $p{-value}, @_) if defined $p{-value};
  my %option = %{$self->{option}};
  $option{new_item_unless_exist} = 1;
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  my $array = $option{_ARRAY_NAME} || $option{_HASH_NAME};
  unless ($array) {
    return if $option{dont_croak};
    Carp::croak (q{item: Method not available for this module});
  }
  $option{parse} = 1 unless defined $option{parse};
  $option{parse} = 1 if $option{parse_all} && !defined $option{parse};
  my @r;
  if ($option{by} eq 'index') {
    for ($self->{$array}->[$name]) {
      return $self->_item_return_value (\$_, \%option);
    }
  } else {
    for (@{$self->{$array}}) {
      if ($self->_item_match ($option{by}, \$_, {$name => 1}, \%option)) {
        if (wantarray) {
          push @r, $self->_item_return_value (\$_, \%option);
        } else {
          return $self->_item_return_value (\$_, \%option);
        }
      }
    }
  }
  if (@r == 0 && $option{new_item_unless_exist}) {
    my $v = $self->_item_new_value ($name, \%option);
    if (defined $v) {
      if ($option{prepend}) {
        unshift @{$self->{$array}}, $v;
      } else {
        push @{$self->{$array}}, $v;
      }
      return $self->_item_return_value (\$v, \%option);
    }
  }
  return undef unless wantarray;
  @r;
}

sub item_exist ($$;%) {
  my $self = shift;
  my ($name, %p) = (shift, @_);
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  my $array = $option{_ARRAY_NAME} || $option{_HASH_NAME};
  unless ($array) {
    return if $option{dont_croak};
    Carp::croak (q{item-exist: Method not available for this module});
  }
  my @r;
  if ($option{by} eq 'index') {
    return 1 if ref $self->{$array}->[$name];
  } else {
    for (@{$self->{$array}}) {
      if ($self->_item_match ($option{by}, \$_, {$name => 1}, \%option)) {
        return 1;
      }
    }
  }
  0;
}

## 1/0 = $self->_item_match ($by, \$item, \%delete_list, \%option)
## -- Checks and returns whether given item is matched with
##    returning item list
## Note: $by eq 'index' is already defined in delete method
##       itself, so in this function it need not be checked.
sub _item_match ($$\$\%\%) {
  my $self = shift;
  my ($by, $item, $list, $option) = @_;
  return 0 unless ref $$item;	## Removed
  ## An example definition
  if ($by eq 'name') {
    $$item->{value} = $self->_parse_value ($$item->{type}, $$item->{value});
    return 1 if ref $$item->{value} && $$list{ $$item->{value}->{name} };
  }
  0;
}

## $value = $self->_item_return_value (\$item, \%option)
## -- Returns returning value of item method
sub _item_return_value ($\$\%) {
  $_[1];
}

## $item = $self->_item_new_value ($name, \%option)
## -- Returns new item with key of $name (called when
##    no returned value is found and -new_value_unless_exist
##    option is true)
##    (Note that the kind of key ('by' option) can be getten
##    from $option->{by})
##    Return undef when new value can't be generated.
sub _item_new_value ($$\%) {
  $_[1];
}

## $self->_parse_value ($type, $value);
sub _parse_value ($$$) {
  my $self = shift;
  my $name = shift;
  my $value = shift;
  return $value if ref $value;
  my $handler = $self->{option}->{value_type}->{$name}
    || $self->{option}->{value_type}->{$self->{option}->{_VALTYPE_DEFAULT}};
  if (ref $handler eq 'CODE') {
    $handler = &$handler ($self);
  }
  my $vtype = $handler->[0];
  my %vopt = (
    -body_default_charset	=> $self->{option}->{body_default_charset},
    -body_default_charset_input	=> $self->{option}->{body_default_charset_input},
    -format	=> $self->{option}->{format},
    -field_ns	=> $self->{option}->{field_ns},
    -field_name	=> $self->{option}->{field_name},
    -field_param_name	=> $name,
    -header_default_charset	=> $self->{option}->{header_default_charset},
    -header_default_charset_input	=> $self->{option}->{header_default_charset_input},
    -internal_charset_name	=> $self->{option}->{internal_charset_name},
    -parse_all	=> $self->{option}->{parse_all},
  );
  ## Media type specified option/parameters
  if (ref $handler->[1] eq 'HASH') {
    for (keys %{$handler->[1]}) {
      $vopt{$_} = ${$handler->[1]}{$_};
    }
  }
  ## Inherited options
  if (ref $handler->[2] eq 'ARRAY') {
    for (@{$handler->[2]}) {
      $vopt{'-'.$_} = $self->{option}->{$_};
    }
  }
  
  if ($vtype eq ':none:') {
    return $value;
  } elsif (defined $value) {
    eval "require $vtype" or Carp::croak (qq{<parse>: $vtype: Can't load package: $@});
    return $vtype->parse ($value, %vopt);
  } else {
    eval "require $vtype" or Carp::croak (qq{<parse>: $vtype: Can't load package: $@});
    return $vtype->new (%vopt);
  }
}

## comments


sub comment_add ($@) {
  my $self = shift;
  my $array = 'comment';
    ## Options
    my %option = %{$self->{option}};
    if (ref $_[0] eq 'HASH') {
      my $option = shift (@_);
      for (keys %$option) {my $n = $_; $n =~ s/^-//; $option{$n} = $$option{$_}}
    }
    
    ## Additional items
        if ($option{prepend}) {
          unshift @{$self->{$array}}, reverse @_;
        } else {
          push @{$self->{$array}}, @_;
        }
}

sub comment_count ($) {
  my $self = shift;
  $self->_comment_cleaning;
  $#{$self->{comment}} + 1;
}

sub comment_delete ($@) {
  my $self = shift;
  #my %p; %p = %{shift (@_)} if ref $_[0] eq 'HASH';
  #my %option = %{$self->{option}};
  #for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
    for (@_) {
      $self->{comment}->[$_] = undef;
    }
  $self->_comment_cleaning;
}

sub comment_item ($$) {
  $_[0]->{comment}->[$_[1]];
}

sub _comment_cleaning ($) {
  my $self = shift;
  $self->{comment} = [grep {length $_} @{$self->{comment}}];
}

sub _comment_stringify ($\%) {
  my $self = shift;
  my $option = shift;
  $option->{_comment_min} ||= 0;
  $option->{_comment_max} = $#{$self->{comment}} unless defined $option->{_comment_max};
  my @v;
  for (@{$self->{comment}}[$option->{_comment_min}..$option->{_comment_max}]) {
    push @v, '('. $self->Message::Util::encode_ccontent ($_) .')';
  }
  join ' ', @v;
}

sub scan ($&;%) {
  my $self = shift;
  my $sub = shift;
  my %p = @_;  my %option;
  if (ref $p{options} eq 'HASH') {
    %option = %{$p{options}};
  } else {
    %option = %{$self->{option}};
    for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  }
  my $array = $option{_ARRAY_NAME} || $option{_HASH_NAME};
  my @param = $self->_scan_sort (\@{$self->{$array}}, \%option);
  #my $sort = $option{sort};
  #@param = sort $sort @param if ref $sort;
  for my $param (@param) {
    &$sub($self, $param, \%option);
  }
}

sub _scan_sort ($\@) {
  #my $self = shift;
  @{$_[1]};
}

=head1 METHODS

=over 4

=item $self->stringify ([%options])

Returns field body as a string.  Returned string is encoded,
quoted if necessary (by C<hook_encode_string>).

=cut

sub stringify ($;%) {
  my $self = shift;
  #$self->Message::Util::encode_qcontent ($self->{field_body});
  $self->{field_body};
}
*as_string = \&stringify;

=item $self->as_plain_string

Returns field body as a string.  Returned string is not encoded
or quoted, i.e. internal/bare coded string.  This string
may be unable to use as field body content.  (Its I<structures>
such as C<comment> and C<quoted-string> are lost.)

=cut

sub as_plain_string ($) {
  my $self = shift;
  my $s = $self->Message::Util::decode_qcontent ($self->{field_body});
  Message::Util::unquote_quoted_string (Message::Util::unquote_ccontent ($s));
}

=item $self->option ( $option-name / $option-name, $option-value, ...)

If @_ == 1, returns option value.  Else...

Set option value.  You can pass multiple option name-value pair
as parameter.  Example:

  $msg->option (format => 'mail-rfc822',
                capitalize => 0);
  print $msg->option ('format');	## mail-rfc822

=cut

sub option ($@) {
  my $self = shift;
  if (@_ == 1) {
    return $self->{option}->{ $_[0] };
  }
  my %option = @_;
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $self->{option}->{$name} = $value;
  }
  if ($option{-recursive}) {
    $self->_option_recursive (\%option);
  }
  $self;
}

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {}

## TODO: multiple value-type support
sub value_type ($;$$%) {
  my $self = shift;
  my $name = shift || $self->{option}->{_VALTYPE_DEFAULT};
  my $new_value_type = shift;
  if ($new_value_type) {
    $self->{option}->{value_type}->{$name} = []
      unless ref $self->{option}->{value_type}->{$name};
    $self->{option}->{value_type}->{$name}->[0] = $new_value_type;
  }
  if (ref $self->{option}->{value_type}->{$name}) {
    $self->{option}->{value_type}->{$name}->[0]
      || $self->{option}->{value_type}->{$self->{option}->{_VALTYPE_DEFAULT}}->[0];
  } else {
    $self->{option}->{value_type}->{$self->{option}->{_VALTYPE_DEFAULT}}->[0];
  }
}

=item $self->clone ()

Returns a copy of Message::Field::Structured object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = ref($self)->new;
  $clone->{option} = Message::Util::make_clone ($self->{option});
  ## Common hash value (not used in this module)
    $self->_delete_empty;
    $self->_comment_cleaning;
    $clone->{value} = Message::Util::make_clone ($self->{value});
    $clone->{comment} = Message::Util::make_clone ($self->{comment});
  for (@{$self->{option}->{_MEMBERS}}) {
    $clone->{$_} = Message::Util::make_clone ($self->{$_});
  }
  $clone;
}


my %_method_default_list = qw(new 1 parse 1 stringify 1 option 1 clone 1 method_available 1);
sub method_available ($$) {
  my $self = shift;
  my $name = shift;
  return 1 if $_method_default_list{$name};
  for (@{$self->{option}->{_METHODS}}) {
    return 1 if $_ eq $name;
  }
  0;
}

=head1 EXAMPLE

  use Message::Field::Structured;
  
  my $field_body = '"This is an example of <\"> (quotation mark)."
                    (Comment within \q\u\o\t\e\d\-\p\a\i\r\(\s\))';
  my $field = Message::Field::Structured->parse ($field_body);
  
  print $field->as_plain_string;

=head1 SEE ALSO

=over 4

=item L<Message::Entity>, L<Message::Header>

=item L<Message::Field::Unstructured>

=item RFC 2822 E<lt>urn:ietf:rfc:2822E<gt>, usefor-article, HTTP/1.0, HTTP/1.1

=back

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
$Date: 2002/11/13 08:08:52 $

=cut

1;
