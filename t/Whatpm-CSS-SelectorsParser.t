package test::Whatpm::CSS::SelectorsParser;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->parent->subdir ('modules', 'testdataparser', 'lib')->stringify;
use base qw(Test::Class);
use Test::Differences;
use Test::HTCT::Parser;
use Whatpm::CSS::SelectorsParser qw(:selector :combinator :match);

my $data_d = file (__FILE__)->dir;

sub serialize_selector_object ($) {
  my $selectors = shift;
  my $result = '';
  my $i = 0;
  ## A group of selectors
  for (@$selectors) {
    $result .= "------\n" if $i++;
    ## A selector
    my @sel = @$_;
    while (@sel) {
      my ($combinator, $sss) = (shift @sel, shift @sel);

      ## A combinator
      if ($combinator != DESCENDANT_COMBINATOR) {
        $result .= {
          CHILD_COMBINATOR, '>',
          ADJACENT_SIBLING_COMBINATOR, '+',
          GENERAL_SIBLING_COMBINATOR, '~',
        }->{$combinator} || $combinator;
        $result .= "\n";
      }

      ## A simple selector sequence
      for (@$sss) {
        ## A simple selector
        if ($_->[0] == LOCAL_NAME_SELECTOR) {
          $result .= "<" . $_->[1] . ">\n";
        } elsif ($_->[0] == ATTRIBUTE_SELECTOR) {
          $result .= "{" . $_->[1] . "}\n" if defined $_->[1] and length $_->[1]; # XXX
          $result .= "[" . $_->[2] . "]\n";
          if (defined $_->[3]) {
            $result .= {
              EQUALS_MATCH, '=',
              INCLUDES_MATCH, '~=',
              DASH_MATCH, '|=',
              PREFIX_MATCH, '^=',
              SUFFIX_MATCH, '$=',
              SUBSTRING_MATCH, '*=',
            }->{$_->[3]} || $_->[3];
            $result .= $_->[4] . "\n";
          }
        } elsif ($_->[0] == NAMESPACE_SELECTOR) {
          $result .= "{" . (defined $_->[1] ? $_->[1] : '') . "}\n"; # XXX
        } else {
          $result .= {
            ID_SELECTOR, '#',
            CLASS_SELECTOR, '.',
            PSEUDO_CLASS_SELECTOR, ':',
            PSEUDO_ELEMENT_SELECTOR, '::',
          }->{$_->[0]} || $_->[0];
          if (exists $_->[1]) {
            $result .= $_->[1];
          }
          $result .= "\n";
        }
      }
    }
  }
  $result =~ s/\n$//g;
  return $result;
} # serialize_selector_object

sub _parse_string : Tests {
  for_each_test ($_, {
    data => {is_prefixed => 1},
    errors => {is_list => 1},
    parsed => {is_prefixed => 1},
  }, sub {
    my $test = shift;

    my @error;

    my $parser = Whatpm::CSS::SelectorsParser->new;
    $parser->{onerror} = sub {
      my %args = @_;
      push @error, join ';', map { defined $_ ? $_ : '' }
          $args{token}->{line}, $args{token}->{column},
          $args{type},
          $args{text},
          $args{value},
          $args{level};
    }; # onerror
    my $selectors = $parser->parse_string ($test->{data}->[0]);

    my $serialized_selectors = serialize_selector_object $selectors;
    eq_or_diff $serialized_selectors, $test->{parsed}->[0];

    my $aerrors = join "\n", sort { $a cmp $b } @error;
    my $xerrors = join "\n", sort { $a cmp $b } @{$test->{errors}->[0]};
    eq_or_diff $aerrors, $xerrors;
  }) for map { $data_d->subdir ('selectors')->file ($_)->stringify } qw(
    parse-1.dat
  );
} # _parse_string

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2011 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
