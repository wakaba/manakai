package Message::DOM::CSSStyleDeclaration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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

package Message::IF::CSSStyleDeclaration;

1;
## $Date: 2007/12/31 03:02:29 $
