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

      my $selectors_str = Whatpm::CSS::SelectorsSerializer->serialize_test
          ($$rule->{_selectors});
      unless ($selectors_to_elements->{$selectors_str}) {
        $selectors_to_elements->{$selectors_str}
            = $self->{document}->___query_selector_all ($$rule->{_selectors});
      }
      
      push @{$self->{element_to_sd}->{refaddr $_} ||= []}, $rule->style
          for @{$selectors_to_elements->{$selectors_str}};
      ## TODO: specificity
    }
  }

} # associate_rules

sub get_cascaded_value ($$$) {
  my ($self, $element, $prop_name) = @_;
  return undef unless $Whatpm::CSS::Parser::Prop->{$prop_name};

  my $key = $Whatpm::CSS::Parser::Prop->{$prop_name}->{key};

  ## TODO: cascading order
  for my $sd (reverse @{$self->{element_to_sd}->{refaddr $element} or []}) {
    my $vp = $$sd->{$key};
    return $vp->[0] if defined $vp;
  }

  return undef;
} # get_cascaded_value


1;
## $Date: 2007/12/31 13:47:49 $
