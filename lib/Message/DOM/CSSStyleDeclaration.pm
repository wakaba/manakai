package Message::DOM::CSSStyleDeclaration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.10 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSStyleDeclaration';

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
    *{ $method_name } = sub {
      ## TODO: setter

      my $self = $_[0];
      my $value = $$self->{$prop_def->{key}};
      if ($value) {
        return $prop_def->{serialize}->($self, $prop_def->{css}, $value->[0]);
      } else {
        return "";
      }
      ## ISSUE: If one of shorthand component properties is !important?
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

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
  for (grep {$$self->{$_}} keys %$$self) {
    my $prop_def = $Whatpm::CSS::Parser::Key->{$_};
    next unless $prop_def;

    if ($prop_def->{serialize_multiple}) {
      unless ($serialized{$prop_def->{serialize_multiple}}) {
        $serialized{$prop_def->{serialize_multiple}} = 1;
        my $v = $prop_def->{serialize_multiple}->($self);
        for my $prop_name (sort {$a cmp $b} keys %$v) {
          $r .= '  ' . $prop_name . ': ' . $v->{$prop_name} . ";\n"
        }
      }
    } else {
      my $value = $$self->{$_};
      my $s = $prop_def->{serialize}->($self, $prop_def->{css}, $value->[0]);
      if (length $s) {
        $r .= '  ' . $prop_def->{css} . ': ' . $s;
        $r .= ' ! ' . $value->[1] if length $value->[1];
        $r .= ";\n";
      }
    }
  }
  return $r;
} # css_text

sub parent_rule ($) {
  return ${$_[0]}->{parent_rule};
} # parent_rule

## |CSSStyleDeclaration| methods

sub get_property_priority ($$) {
  my $prop_name = ''.$_[1];

  require Whatpm::CSS::Parser;
  my $prop_def = $Whatpm::CSS::Parser::Prop->{$prop_name};
  return '' unless defined $prop_def;

  my $v = ${$_[0]}->{$prop_def->{key}};
  return $v ? $v->[1] : '';
} # get_property_priority

## TODO: Implement other methods and attributes

package Message::DOM::CSSComputedStyleDeclaration;
push our @ISA, 'Message::IF::CSSStyleDeclaration';

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
    *{ $method_name } = sub {
      ## TODO: setter

      my $self = $_[0];
      my $value = $$self->{cascade}->get_computed_value
          ($$self->{element}, $prop_def->{css});
      if ($value) {
        return $prop_def->{serialize}->($self, $prop_def->{css}, $value);
      } else {
        return "";
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

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
          $r .= '  ' . $prop_name . ': ' . $v->{$prop_name} . ";\n"
        }
      }
    } else {
      my $prop_value = $$self->{cascade}->get_computed_value
          ($$self->{element}, $prop_def->{css});
      my $s = $prop_def->{serialize}->($self, $prop_def->{css}, $prop_value);
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

## |CSSStyleDeclaration| methods

sub get_property_priority ($$) { '' }

## TODO: members

package Message::IF::CSSStyleDeclaration;

1;
## $Date: 2008/01/14 10:04:40 $
