package Whatpm::CSS::MediaQueryParser;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

use Whatpm::CSS::Tokenizer qw(:token);

sub new ($) {
  my $self = bless {onerror => sub { },
                    must_level => 'm', unsupported_level => 'u'}, shift;
  #$self->{href} = \(uri in which the MQ appears);
  return $self;
} # new

sub parse_char_string ($$) {
  my $self = $_[0];

  my $s = $_[1];
  pos ($s) = 0;

  my $tt = Whatpm::CSS::Tokenizer->new;
  $tt->{onerror} = $self->{onerror};
  $tt->{line} = 1;
  $tt->{column} = 1;
  $tt->{get_char} = sub {
    if (pos $s < length $s) {
      $tt->{column} = 1 + pos $s;
      return ord substr $s, pos ($s)++, 1;
    } else {
      return -1;
    }
  }; # $tt->{get_char}
  $tt->init;

  my $t = $tt->get_next_token;
  $t = $tt->get_next_token while $t->{type} == S_TOKEN;

  my $r;
  ($t, $r) = $self->_parse_mq_with_tokenizer ($t, $tt);
  return undef unless defined $r;

  if ($t->{type} != EOF_TOKEN) {
    $self->{onerror}->(type => 'mq syntax error',
                       level => $self->{must_level},
                       uri => \$self->{href},
                       token => $t);
    return undef;
  }

  return $r;
} # parse_char_string

sub _parse_mq_with_tokenizer ($$$) {
  my ($self, $t, $tt) = @_;

  my $r = [];

  A: {
    ## NOTE: Unknown media types are converted into 'unknown', since
    ## Opera and WinIE do so and our implementation of the CSS
    ## tokenizer currently normalizes numbers in NUMBER or DIMENSION tokens
    ## so that the original representation cannot be preserved (e.g. '03d'
    ## is covnerted to '3' with unit 'd').

    if ($t->{type} == IDENT_TOKEN) {
      my $type = lc $t->{value}; ## TODO: case
      if ({
        all => 1, braille => 1, embossed => 1, handheld => 1, print => 1,
        projection => 1, screen => 1, tty => 1, tv => 1,
        speech => 1, aural => 1,
        'atsc-tv' => 1, 'dde-tv' => 1, 'dvb-tv' => 1,
        dark => 1, emacs => 1, light => 1, xemacs => 1,
      }->{$type}) {
        push @$r, [['#type', $type]];
      } else {
        push @$r, [['#type', 'unknown']];
        $self->{onerror}->(type => 'unknown media type',
                           level => $self->{unsupported_level},
                           uri => \$self->{href},
                           token => $t);
      }
      $t = $tt->get_next_token;
    } elsif ($t->{type} == NUMBER_TOKEN or $t->{type} == DIMENSION_TOKEN) {
      push @$r, [['#type', 'unknown']];
      $self->{onerror}->(type => 'unknown media type',
                         level => $self->{unsupported_level},
                         uri => \$self->{href},
                         token => $t);
      $t = $tt->get_next_token;
    } else {
      $self->{onerror}->(type => 'mq syntax error',
                         level => $self->{must_level},
                         uri => \$self->{href},
                         token => $t);    
      return ($t, undef);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ($t->{type} == COMMA_TOKEN) {
      $t = $tt->get_next_token;
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      redo A;
    }
  } # A

  return ($t, $r);
} # _parse_mq_with_tokenizer

1;
