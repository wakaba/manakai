package Whatpm::CSS::Cascade;

require Whatpm::CSS::Parser; ## NOTE: For property definitions.
require Whatpm::CSS::SelectorsSerializer;
use Scalar::Util qw/refaddr/;

## Cascading and value computations

sub new ($$) {
  my $self = bless {style_sheets => []}, shift;
  $self->{document} = shift;
  return $self;
} # new

## NOTE: This version does not support dynamic addition --- style
## sheets must be added before any other operation.
## NOTE: The $ss argument must be a value that can be interpreted as
## an array reference of CSSStyleSheet objects.
## NOTE: |type| and |media| attributes are not accounted by this
## method (and any others in the class); CSSStyleSheet objects must
## be filtered before they are passed to this method.
sub add_style_sheets ($$) {
  my ($self, $ss) = @_;

  push @{$self->{style_sheets}}, @$ss;
} # add_style_sheets

## TODO: non-CSS presentation hints
## TODO: style=""

sub ___associate_rules ($) {
  my $self = shift;

  my $selectors_to_elements;

  for my $sheet (@{$self->{style_sheets}}) {
    ## TODO: @media
    ## TODO: @import
    ## TODO: style sheet sources

    for my $rule (@{$sheet->css_rules}) {
      next if $rule->type != 1; # STYLE_RULE

      my $elements_to_specificity = {};

      for my $selector (@{$$rule->{_selectors}}) {
        my $selector_str = Whatpm::CSS::SelectorsSerializer->serialize_test
            ([$selector]);
        unless ($selectors_to_elements->{$selector_str}) {
          $selectors_to_elements->{$selector_str}
              = $self->{document}->___query_selector_all ([$selector]);
        }
        next unless @{$selectors_to_elements->{$selector_str}};

        my $selector_specificity
            = Whatpm::CSS::SelectorsParser->get_selector_specificity
                ($selector);
        for (@{$selectors_to_elements->{$selector_str}}) {
          my $current_specificity = $elements_to_specificity->{refaddr $_};
          if ($selector_specificity->[0] > $current_specificity->[0] or
              $selector_specificity->[1] > $current_specificity->[1] or
              $selector_specificity->[2] > $current_specificity->[2] or
              $selector_specificity->[3] > $current_specificity->[3]) {
            $elements_to_specificity->{refaddr $_} = $selector_specificity;
          }
        }
      }

      my $sd = $rule->style;
      for (keys %$elements_to_specificity) {
        push @{$self->{element_to_sds}->{$_} ||= []},
            [$sd, $elements_to_specificity->{$_}];
      }
    }
  }

  for my $eid (keys %{$self->{element_to_sds} or {}}) {
    $self->{element_to_sds}->{$eid} = [sort {
      $a->[1]->[0] <=> $b->[1]->[0] or
      $a->[1]->[1] <=> $b->[1]->[1] or
      $a->[1]->[2] <=> $b->[1]->[2] or 
      $a->[1]->[3] <=> $b->[1]->[3]
      ## NOTE: Perl |sort| is stable.
    } @{$self->{element_to_sds}->{$eid} or []}];
  }
} # associate_rules

sub get_cascaded_value ($$$) {
  my ($self, $element, $prop_name) = @_;
  return undef unless $Whatpm::CSS::Parser::Prop->{$prop_name};

  my $key = $Whatpm::CSS::Parser::Prop->{$prop_name}->{key};

  my $value;
  for my $sds (reverse @{$self->{element_to_sds}->{refaddr $element} or []}) {
    my $vp = ${$sds->[0]}->{$key};
    if (defined $vp->[1] and $vp->[1] eq 'important') {
      return $vp->[0];
    } else {
      $value = $vp->[0] unless defined $value;
    }
  }

  return $value; # might be |undef|.
} # get_cascaded_value


1;
## $Date: 2008/01/01 02:54:35 $
