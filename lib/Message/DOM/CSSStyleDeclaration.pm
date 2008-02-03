package Message::DOM::CSSStyleDeclaration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.16 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSStyleDeclaration',
    'Message::IF::CSS2Properties';

my $serialize_value = sub ($$$) {
  my ($self, $prop_name, $value) = @_;
  if ($value->[0] eq 'NUMBER' or $value->[0] eq 'WEIGHT') {
    ## TODO: What we currently do for 'font-weight' is different from
    ## any browser for lighter/bolder cases.  We need to fix this, but
    ## how?
    return $value->[1]; ## TODO: big or small number cases?
  } elsif ($value->[0] eq 'DIMENSION') {
    return $value->[1] . $value->[2]; ## NOTE: This is what browsers do.
  } elsif ($value->[0] eq 'PERCENTAGE') {
    return $value->[1] . '%';
  } elsif ($value->[0] eq 'KEYWORD' or $value->[0] eq 'PAGE') {
    return $value->[1];
  } elsif ($value->[0] eq 'URI') {
    ## NOTE: This is what browsers do.
    return 'url('.$value->[1].')';
  } elsif ($value->[0] eq 'RGBA') {
    if ($value->[4] == 1) {
      return 'rgb('.$value->[1].', '.$value->[2].', '.$value->[3].')';
    } elsif ($value->[4] == 0) {
      ## TODO: check what browsers do...
      return 'transparent';
    } else {
      return 'rgba('.$value->[1].', '.$value->[2].', '.$value->[3].', '
          .$value->[4].')';
    }
  } elsif ($value->[0] eq 'INHERIT') {
    return 'inherit';
  } elsif ($value->[0] eq 'DECORATION') {
    my @v = ();
    push @v, 'underline' if $value->[1];
    push @v, 'overline' if $value->[2];
    push @v, 'line-through' if $value->[3];
    push @v, 'blink' if $value->[4];
    return 'none' unless @v;
    return join ' ', @v;
  } elsif ($value->[0] eq 'QUOTES') {
    return join ' ', map {'"'.$_.'"'} map {$_->[0], $_->[1]} @{$value->[1]};
    ## NOTE: The result string might not be a <'quotes'> if it contains
    ## e.g. '"'.  In addition, it might not be a <'quotes'> if 
    ## @{$value->[1]} is empty (which is unlikely as long as the implementation
    ## is not broken).
  } elsif ($value->[0] eq 'CONTENT') {
    return join ' ', map {
      $_->[0] eq 'KEYWORD' ? $_->[1] :
      $_->[0] eq 'STRING' ? '"' . $_->[1] . '"' :
      $_->[0] eq 'URI' ? 'url(' . $_->[1] . ')' :
      $_->[0] eq 'ATTR' ? 'attr(' . $_->[2] . ')' : ## TODO: prefix
      $_->[0] eq 'COUNTER' ? 'counter(' . $_->[1] . ', ' . $_->[3] . ')' :
      $_->[0] eq 'COUNTERS' ? 'counters(' . $_->[1] . ', "' . $_->[2] . '", ' . $_->[3] . ')' :
      ''
    } @{$value}[1..$#$value];
  } elsif ($value->[0] eq 'RECT') {
    ## NOTE: Four components are DIMENSIONs.
    return 'rect(' . $value->[1]->[1].$value->[1]->[2] . ', '
          . $value->[2]->[1].$value->[2]->[2] . ', '
          . $value->[3]->[1].$value->[3]->[2] . ', '
          . $value->[4]->[1].$value->[4]->[2] . ')';
  } elsif ($value->[0] eq 'SETCOUNTER' or $value->[0] eq 'ADDCOUNTER') {
    return join ' ', map {$_->[0], $_->[1]} @$value[1..$#$value];
  } elsif ($value->[0] eq 'FONT') {
    return join ', ', map {
      if ($_->[0] eq 'STRING') {
        '"'.$_->[1].'"'; ## NOTE: This is what Firefox does.
      } elsif ($_->[0] eq 'KEYWORD') {
        $_->[1]; ## NOTE: This is what Firefox does.
      } else {
        ## NOTE: This should be an error.
        '""';
      }
    } @$value[1..$#$value];
  } elsif ($value->[0] eq 'CURSOR') {
    return join ', ', map {
      if ($_->[0] eq 'URI') {
        'url('.$_->[1].')'; ## NOTE: This is what Firefox does.
      } elsif ($_->[0] eq 'KEYWORD') {
        $_->[1];
      } else {
        ## NOTE: This should be an error.
        '""';
      }
    } @$value[1..$#$value];
  } elsif ($value->[0] eq 'MARKS') {
    if ($value->[1]) {
      if ($value->[2]) {
        return 'crop cross';
      } else {
        return 'crop';
      }
    } elsif ($value->[2]) {
      return 'cross';
    } else {
      return 'none';
    }
  } elsif ($value->[0] eq 'SIZE') {
    my $s1 = $value->[1]->[1] . $value->[1]->[2]; ## NOTE: They should be 
    my $s2 = $value->[2]->[1] . $value->[2]->[2]; ## 'DIMENSION's.
    if ($s1 eq $s2) {
      return $s1;
    } else {
      return $s1 . ' ' . $s2;
    }
  } else {
    return '';
  }
}; # $serialize_value

sub ____new ($) {
  return bless \{}, $_[0];
} # ____new

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  require Whatpm::CSS::Parser;
  my $prop_def = $Whatpm::CSS::Parser::Attr->{$method_name};

  if ($prop_def) {
    no strict 'refs';
    if (defined $prop_def->{key}) {
      *{ $method_name } = sub {
        ## TODO: setter
  
        my $self = $_[0];
        my $value = $$self->{$prop_def->{key}};
        if ($value) {
          return $serialize_value->($self, $prop_def->{css}, $value->[0]);
        } else {
          return '';
        }
      };
    } elsif ($prop_def->{serialize_shorthand} or
             $prop_def->{serialize_multiple}) {
      *{ $method_name } = sub {
        ## TODO: setter
  
        my $self = $_[0];
        my $v = ($prop_def->{serialize_shorthand} or
                 $prop_def->{serialize_multiple})->($self);
        if (defined $v->{$prop_def->{css}}) {
          return $v->{$prop_def->{css}}->[0];
        } else {
          return '';
        }
        ## ISSUE: If one of shorthand component properties is !important?
      };
    } else {
      die qq<Implementation error: Can't load serializer for "$AUTOLOAD">;
    }
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

use overload
    '@{}' => sub {
      tie my @list, ref $_[0], $_[0];
      return \@list;
    },
    fallback => 1;

sub TIEARRAY ($$) { $_[1] }

## |CSSStyleDeclaration| attributes

sub css_text ($;$) {
  ## TODO: setter

  ## NOTE: Where and how white space characters are inserted are 
  ## intentionally changed from those in browsers so that properties are
  ## more prettily printed.
  ## See <http://suika.fam.cx/gate/2005/sw/cssText> for what browsers do.
  ## TODO: Ordering issue.
  require Whatpm::CSS::Parser;
  my $self = $_[0];
  my $r = '';
  my %serialized;
  for (sort {$a cmp $b} grep {$$self->{$_}} keys %$$self) {
    my $prop_def = $Whatpm::CSS::Parser::Key->{$_};
    next unless $prop_def;

    if ($prop_def->{serialize_multiple}) {
      unless ($serialized{$prop_def->{serialize_multiple}}) {
        $serialized{$prop_def->{serialize_multiple}} = 1;
        my $v = $prop_def->{serialize_multiple}->($self);
        for my $prop_name (sort {$a cmp $b} keys %$v) {
          $r .= '  ' . $prop_name . ': ' . $v->{$prop_name}->[0];
          $r .= ' ! ' . $v->{$prop_name}->[1] if length $v->{$prop_name}->[1];
          $r .= ";\n";
        }
      }
    } else {
      my $value = $$self->{$_};
      my $s = $serialize_value->($self, $prop_def->{css}, $value->[0]);
      if (length $s) {
        $r .= '  ' . $prop_def->{css} . ': ' . $s;
        $r .= ' ! ' . $value->[1] if length $value->[1];
        $r .= ";\n";
      }
    }
  }
  return $r;
} # css_text

sub length ($) {
  require Whatpm::CSS::Parser;
  return scalar @{[grep {$_}
                   map { $Whatpm::CSS::Parser::Key->{$_} }
                   keys %${$_[0]}]->[$_[1]]};
} # length
*FETCHSIZE = \&length;

## TODO: STORESIZE

sub parent_rule ($) {
  return ${$_[0]}->{parent_rule};
} # parent_rule

## |CSSStyleDeclaration| methods

sub get_property_priority ($$) {
  my $prop_name = ''.$_[1];

  require Whatpm::CSS::Parser;
  my $prop_def = $Whatpm::CSS::Parser::Prop->{$prop_name};
  return '' unless defined $prop_def;

  if (defined $prop_def->{key}) {
    my $v = ${$_[0]}->{$prop_def->{key}};
    return $v ? $v->[1] : '';
  } elsif ($prop_def->{serialize_shorthand} or
           $prop_def->{serialize_multiple}) {
    my $v = ($prop_def->{serialize_shorthand} or
             $prop_def->{serialize_multiple})->($_[0]);
    if (defined $v->{$prop_def->{css}}) {
      return $v->{$prop_def->{css}}->[1];
    } else {
      return '';
    }
  } else {
    die "Implementation error: No serializer for property '$prop_name'";
  }
} # get_property_priority

sub item ($$) {
  require Whatpm::CSS::Parser;
  return '' if $_[1] < 0;
  ## TODO: ordering (should be same as that in |css_text|.
  my $v = [map {$_->{key}}
           grep {$_}
           map { $Whatpm::CSS::Parser::Key->{$_} }
           keys %${$_[0]}]->[$_[1]];
  return defined $v ? $v : '';
} # item
*FETCH = \&item;

## TODO: STORE, DELETE

sub EXISTS ($$) {
  return length $_[0]->item;
} # EXISTS

## TODO: Implement other methods and attributes

package Message::DOM::CSSComputedStyleDeclaration;
push our @ISA, 'Message::IF::CSSStyleDeclaration',
    'Message::IF::CSS2Properties';

sub ____new ($$$) {
  my $self = bless \{}, shift;
  $$self->{cascade} = shift; # Whatpm::CSS::Cascade object.
  $$self->{element} = shift; ## TODO: This link should be weaken?
  return $self;
} # ____new

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  require Whatpm::CSS::Parser;
  my $prop_def = $Whatpm::CSS::Parser::Attr->{$method_name};

  if ($prop_def) {
    no strict 'refs';
    if ($prop_def->{compute} or $prop_def->{compute_multiple}) {
      *{ $method_name } = sub {
        ## TODO: setter
  
        my $self = $_[0];
        my $value = $$self->{cascade}->get_computed_value
            ($$self->{element}, $prop_def->{css});
        if ($value) {
          return $serialize_value->($self, $prop_def->{css}, $value);
        } else {
          return '';
        }
      };
    } elsif ($prop_def->{serialize_shorthand} or
             $prop_def->{serialize_multiple}) {
      *{ $method_name } = sub {
        ## TODO: setter
        my $self = shift;

        my $v = ($prop_def->{serialize_shorthand} or
                 $prop_def->{serialize_multiple})->($self);
        if (defined $v->{$prop_def->{css}}) {
          return $v->{$prop_def->{css}}->[0];
        } else {
          return '';
        }
      };
    } else {
      ## TODO: This should be an error of the implementation.
      ## However, currently some shorthand properties does not have
      ## serializer.
      ## TODO: Remove {serialize} from shorthand properties, since
      ## they have no effect.
      warn "$0: No computed value function for $method_name";
      #die "$0: No computed value function for $method_name";
      *{ $method_name } = sub { };
    }
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

use overload
    '@{}' => sub {
      tie my @list, ref $_[0], $_[0];
      return \@list;
    },
    fallback => 1;

sub TIEARRAY ($$) { $_[1] }

## |CSSStyleDeclaration| attributes

sub css_text ($;$) {
  ## TODO: error if modified

  my $self = shift;
  require Whatpm::CSS::Parser;

  ## NOTE: Where and how white space characters are inserted are 
  ## intentionally changed from those in browsers so that properties are
  ## more prettily printed.
  ## See <http://suika.fam.cx/gate/2005/sw/cssText> for what browsers do.
  ## TODO: ordering
  ## TODO: any spec?
  my $r = '';
  my %serialized;
  for my $prop_def (sort {$a->{css} cmp $b->{css}}
                    grep {$_->{compute} or
                          $_->{compute_multiple} or
                          $_->{serialize_multiple}}
                    values %$Whatpm::CSS::Parser::Prop) {
    if ($prop_def->{serialize_multiple}) {
      unless ($serialized{$prop_def->{serialize_multiple}}) {
        $serialized{$prop_def->{serialize_multiple}} = 1;
        my $v = $prop_def->{serialize_multiple}->($self);
        for my $prop_name (sort {$a cmp $b} keys %$v) {
          $r .= '  ' . $prop_name . ': ' . $v->{$prop_name}->[0];
          $r .= ' ! ' . $v->{$prop_name}->[1] if length $v->{$prop_name}->[1];
          $r .= ";\n";
        }
      }
    } else {
      my $prop_value = $$self->{cascade}->get_computed_value
          ($$self->{element}, $prop_def->{css});
      my $s = $serialize_value->($self, $prop_def->{css}, $prop_value);
      if (length $s) {
        $r .= '  ' . $prop_def->{css} . ': ' . $s;
        $r .= ";\n";
      } else {
        ## NOTE: This should be an error of the implementation.
        $r .= "  /* $prop_def->{css}: ???; */\n";
      }
    }
  }

  ## ISSUE: Should we include CSS properties that are not supported?

  return $r;
} # css_text

## TODO: What should we enumerate is unclear.
sub length ($) {
  require Whatpm::CSS::Parser;
  return scalar @{[grep {$_}
                   values %$Whatpm::CSS::Parser::Key]};
} # length
*FETCHSIZE = \&length;

## TODO: STORESIZE

## |CSSStyleDeclaration| methods

sub get_property_priority ($$) { '' }

sub item ($$) {
  require Whatpm::CSS::Parser;
  return '' if $_[1] < 0;
  ## TODO: ordering (should be same as that in |css_text|.
  my $v = [sort {$a cmp $b}
           map {$_->{css}}
           grep {$_}
           values %$Whatpm::CSS::Parser::Key]->[$_[1]];
  return defined $v ? $v : '';
} # item
*FETCH = \&item;

## TODO: STORE, DELETE

sub EXISTS ($$) {
  return length $_[0]->item;
} # EXISTS

## TODO: members

package Message::IF::CSSStyleDeclaration;
package Message::IF::CSS2Properties;

1;
## $Date: 2008/02/03 06:01:20 $
