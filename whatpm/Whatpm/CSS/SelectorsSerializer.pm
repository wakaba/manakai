package Whatpm::CSS::SelectorsSerializer;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

use Whatpm::CSS::SelectorsParser qw(:selector :combinator :match);

sub serialize_test ($$;$) {
  my (undef, $selectors, $lookup_prefix) = @_;
  my $i = 0;
  my $ident = sub {
    my $s = shift;
    $s =~ s{([^A-Za-z_0-9\x80-\x{D7FF}\x{E000}-\x{10FFFF}-])}{
      my $v = ord $1;
      sprintf '\\%06X',$v > 0x10FFFF ? 0xFFFFFF : $v;
    }ge;
    $s =~ s/^([0-9])/\\00003$1/g;
    $s =~ s/^-([^A-Za-z\x80-\x{D7FF}\x{E000}-\x{10FFFF}_])/\\00002D$1/g;
    $s = '\\00002D' if $s eq '-';
    return $s;
  }; # $ident
  my $str = sub {
    my $s = shift;
    $s =~ s{([^\x20\x21\x23-\x5B\x5D-\x{D7FF}\x{E000}-\x{10FFFF}])}{
      my $v = ord $1;
      sprintf '\\%06X',$v > 0x10FFFF ? 0xFFFFFF : $v;
    }ge;
    return '"'.$s.'"';
  }; # $str

  my $lp = $lookup_prefix ? sub {
    my $v = $lookup_prefix->($_[0]);
    return $ident->(defined $v ? $v : $_[0]);
  } : $ident; # $lp

  my $r = join ",\n", map {
    join "", map {
      if (ref $_) {
        my $ss = [];
        $ss->[LOCAL_NAME_SELECTOR] = [LOCAL_NAME_SELECTOR, undef];
        for my $s (@$_) {
          if ($s->[0] == NAMESPACE_SELECTOR or
              $s->[0] == LOCAL_NAME_SELECTOR) {
            $ss->[$s->[0]] = $s;
          } else {
            push @{$ss->[$s->[0]] ||= []}, $s;
          }
        }
        
        my $v = '';
        if (not defined $ss->[NAMESPACE_SELECTOR]) {
          $v .= '*|';
        } elsif (defined $ss->[NAMESPACE_SELECTOR]->[1]) {
          $v .= $lp->($ss->[NAMESPACE_SELECTOR]->[1]) . '|';
        } else {
          $v .= '|';
        }

        if (defined $ss->[LOCAL_NAME_SELECTOR]->[1]) {
          $v .= $ident->($ss->[LOCAL_NAME_SELECTOR]->[1]);
        } else {
          $v .= '*';
        }

        $v .= join '', sort {$a cmp $b} map {
          '[' .
          (defined $_->[1] ?
            $_->[1] eq '' ? '' : $lp->($_->[1]) : '*') .
          '|' .
          $ident->($_->[2]) .
          ($_->[3] != EXISTS_MATCH ?
            {EQUALS_MATCH, '=',
             INCLUDES_MATCH, '~=',
             DASH_MATCH, '|=',
             PREFIX_MATCH, '^=',
             SUFFIX_MATCH, '$=',
             SUBSTRING_MATCH, '*='}->{$_->[3]} .
            $str->($_->[4])
          : '') .
          ']';
        } @{$ss->[ATTRIBUTE_SELECTOR] || []};

        $v .= join '', sort {$a cmp $b} map {
          '.' . $ident->($_->[1]);
        } @{$ss->[CLASS_SELECTOR] || []};

        $v .= join '', sort {$a cmp $b} map {
          '#' . $ident->($_->[1]);
        } @{$ss->[ID_SELECTOR] || []};

        $v .= join '', sort {$a cmp $b} map {
          my $v = $_;
          if ($v->[1] eq 'lang') {
            ':lang(' . $ident->($v->[2]) . ')';
          } elsif ($v->[1] eq 'not') {
            my $v = Whatpm::CSS::SelectorsSerializer->serialize_test
                ([[DESCENDANT_COMBINATOR, [@{$v}[2..$#{$v}]]]]);
            $v =~ s/^    \*\|\*(?!$)/    /;
            ":not(\n    " . $v . "    )";
          } elsif ({'nth-child' => 1,
                    'nth-last-child' => 1,
                    'nth-of-type' => 1,
                    'nth-last-of-type' => 1}->{$v->[1]}) {
            ':' . $ident->($v->[1]) . '(' .
            ($v->[2] . 'n' . ($v->[3] < 0 ? $v->[3] : '+' . $v->[3])) . ')';
          } elsif ($v->[1] eq '-manakai-contains') {
            ':-manakai-contains(' . $str->($v->[2]) . ')';
          } else {
            ':' . $ident->($v->[1]);
          }
        } @{$ss->[PSEUDO_CLASS_SELECTOR] || []};

        $v .= join '', sort {$a cmp $b} map {
          '::' . $ident->($_->[1]);
        } @{$ss->[PSEUDO_ELEMENT_SELECTOR] || []};

        $v . "\n";
      } else {
        "  " . {
          DESCENDANT_COMBINATOR, ' ',
          CHILD_COMBINATOR, '>',
          ADJACENT_SIBLING_COMBINATOR, '+',
          GENERAL_SIBLING_COMBINATOR, '~',
        }->{$_} . " ";
      }
    } @$_;
  } @$selectors;  

  return $r;
} # serialize_test

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2007/12/23 15:47:09 $
