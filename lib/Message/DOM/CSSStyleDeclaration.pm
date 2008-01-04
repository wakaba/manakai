package Message::DOM::CSSStyleDeclaration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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
        return undef;
      }
      ## TODO: null? ""? ... if not set?
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

  require Whatpm::CSS::Parser;
  my $self = $_[0];
  my $r = '';
  for (grep {$$self->{$_}} keys %$$self) {
    my $prop_def = $Whatpm::CSS::Parser::Key->{$_};
    next unless $prop_def;
    my $value = $$self->{$_};
    my $s = $prop_def->{serialize}->($self, $prop_def->{css}, $value->[0]);
    if (defined $s) {
      $r .= '  ' . $prop_def->{css} . ': ' . $s;
      $r .= ' !' . $value->[1] if defined $value->[1];
      $r .= ";\n";
    }
  }
  ## TODO: shorthands
  return $r;
} # css_text

sub parent_rule ($) {
  return ${$_[0]}->{parent_rule};
} # parent_rule

## TODO: Implement other methods and attributes

package Message::DOM::CSSComputedStyleDeclaration;
push our @ISA, 'Message::IF::CSSStyleDeclaration';

sub ____new ($$$) {
  my $self = bless \{}, shift;
  $$self->{cascade} = shift; # Whatpm::CSS::Cascade object.
  $$self->{element} = shift; ## TODO: This link should be weaken?
  return $self;
} # ____new

sub css_text ($;$) {
  ## TODO: error if modified

  my $self = shift;
  require Whatpm::CSS::Parser;

  ## TODO: ordering
  ## TODO: any spec?
  my $r = '';
  for my $prop_def (sort {$a->{css} cmp $b->{css}}
                    grep {$_->{compute} or $_->{compute_multiple}}
                    values %$Whatpm::CSS::Parser::Prop) {
    my $prop_value = $$self->{cascade}->get_computed_value
        ($$self->{element}, $prop_def->{css});
    my $s = $prop_def->{serialize}->($self, $prop_def->{css}, $prop_value);
    if (defined $s) {
      $r .= '  ' . $prop_def->{css} . ': ' . $s;
      $r .= ";\n";
    } else {
      ## NOTE: This should be an error of the implementation.
      $r .= "  /* $prop_def->{css}: ???; */\n";
    }
  }

  ## ISSUE: Should we include CSS properties that are not supported?

  return $r;
} # css_text

## TODO: members

package Message::IF::CSSStyleDeclaration;

1;
## $Date: 2008/01/04 14:45:29 $
