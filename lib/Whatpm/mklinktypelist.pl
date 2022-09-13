#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->stringify;

my $RelExtFileName = 'RelExtensions.html';

## Standard link types defined in HTML5
my $LinkTypes = {
  alternate => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'], # link, a/area
  },
  archive => {
    status => 'synonym', # archives
    effect => ['hyperlink', 'hyperlink'],
  },
  archives => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  author => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  begin => {
    status => 'synonym', # first
    effect => ['hyperlink', 'hyperlink'],
  },
  bookmark => {
    status => 'accepted',
    effect => [undef, 'hyperlink'],
  },
#  contact => {
#    status => 'accepted',
#    effect => ['hyperlink', 'hyperlink'],
#  },
  contents => {
    status => 'synonym', # index
    effect => ['hyperlink', 'hyperlink'],
  },
  copyright => {
    status => 'synonym', # license
    effect => ['hyperlink', 'hyperlink'],
  },
  end => {
    status => 'synonym', # last
    effect => ['hyperlink', 'hyperlink'],
  },
  external => {
    status => 'accepted',
    effect => [undef, 'hyperlink'],
  },
## Dropped
#  feed => {
#    status => 'accepted',
#    effect => ['hyperlink', 'hyperlink'],
#  },
  first => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  help => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  icon => {
    status => 'accepted',
    effect => ['external resource', undef],
  },
  index => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  # rev=made (synonym, hyperlink/hyperlink)
  last => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  license => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  next => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  nofollow => {
    status => 'accepted',
    effect => [undef, 'annotation'],
  },
  noreferrer => {
    status => 'accepted',
    effect => [undef, 'annotation'],
  },
  pingback => {
    status => 'accepted',
    effect => ['external resource', undef],
    unique => 1,
  },
  prefetch => {
    status => 'accepted',
    effect => ['external resource', undef],
  },
  prev => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  previous => {
    status => 'synonym', # prev
    effect => ['hyperlink', 'hyperlink'],
  },
  search => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  start => {
    status => 'synonym', # first
    effect => ['hyperlink', 'hyperlink'],
  },
  stylesheet => {
    status => 'accepted',
    effect => ['external resource', undef],
  },
  sidebar => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
  tag => {
    status => 'accepted',
    effect => [undef, 'hyperlink'],
  },
  toc => {
    status => 'synonym', # index
    effect => ['hyperlink', 'hyperlink'],
  },
  top => {
    status => 'synonym', # index
    effect => ['hyperlink', 'hyperlink'],
  },
  up => {
    status => 'accepted',
    effect => ['hyperlink', 'hyperlink'],
  },
};

require Whatpm::NanoDOM;
require Whatpm::HTML;
my $doc = Whatpm::NanoDOM::Document->new;
{
  open my $rel_ext, '<:encoding(utf8)', $RelExtFileName
    or die "$0: $RelExtFileName: $!";
  local $/ = undef;
  Whatpm::HTML->parse_string (scalar <$rel_ext> => $doc);
}

my $table;
my @node = @{$doc->child_nodes};
while (@node) {
  my $node = shift @node;
  if ($node->node_type == 1 and
      $node->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      $node->manakai_local_name eq 'table') {
    $table = $node;
    last;
  } else {
    push @node, @{$node->child_nodes};
  }
}
unless (defined $table) {
  warn "$0: No <table> in $RelExtFileName\n";
}

my @row;
@node = @{$table->child_nodes};
while (@node) {
  my $node = shift @node;
  if ($node->node_type == 1) {
    if ($node->namespace_uri eq q<http://www.w3.org/1999/xhtml>) {
      if ($node->manakai_local_name eq 'tr') {
        push @row, $node;
      } elsif ({thead => 1, tbody => 1, tfoot => 1}
               ->{$node->manakai_local_name}) {
        unshift @node, @{$node->child_nodes};
      }
    }
  }
}
shift @row; # heading rows
#shift @row;

## Keyword, Effect on link, Effect on a/area, Desc, Detail link, Synonyms, Status
my $n = sub { my $s = shift; $s =~ s/\s+/ /g; $s =~ s/^ //; $s =~ s/ $//; $s };
for my $tr (@row) {
  my @td = grep {
    $_->node_type == 1 and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
        $_->manakai_local_name eq 'td'
  } @{$tr->child_nodes};
  my $keyword = $n->($td[0]->text_content);
  $keyword =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
  next if $keyword =~ /[\[\]]/; ## This is a willful violation.
  my $effect_link = lc $n->($td[1]->text_content);
  next if $effect_link =~ /see html5/;
  if ($LinkTypes->{$keyword}) {
    warn "$0: Link type $keyword is already defined\n";
    next;
  }
  undef $effect_link if $effect_link eq 'not allowed';
  my $effect_a = lc $n->($td[2]->text_content);
  undef $effect_a if $effect_a eq 'not allowed';
  my @synonyms = grep {
    not /[()<>]/ ## This is a willful violation.
  } split / ?, ?/, $n->($td[5]->text_content);
  my $status = lc $n->($td[6]->text_content);
  $LinkTypes->{$keyword} = {
    status => $status,
    effect => [$effect_link, $effect_a],
  };
  for (@synonyms) {
    if ($LinkTypes->{$_}) {
      warn "$0: Link type $_ is already defined\n";
      next;
    }
    $LinkTypes->{$_} = {
      status => 'synonym',
      effect => [$effect_link, $effect_a],
    };
  }
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
my $value = Dumper $LinkTypes;
$value =~ s/\$VAR1\b/\$Whatpm::ContentChecker::LinkType/;

print "## This file is automatically generated by $0;
## Don't edit by hand.\n\n";
print $value;
print "1;\n";

my $year = [gmtime]->[5] + 1900;
print sprintf '__DATA__

=head1 NAME

mklinktypelist.pl - The link type list generator for the Whatpm conformance checker

_LinkTypeList.pm - The link type list for the Whatpm conformance checker

=head1 SYNOPSIS

Generation:

  $ make update-_LinkTypeList.pm _LinkTypeList.pm

=head1 DESCRIPTION

The C<_LinkTypeList.pm> Perl module file contains a list of link types
that might be used formally in HTML C<rel> attributes, conforming or
non-conforming, according to the Web Applications 1.0 specification.
This Perl module is referenced from the Whatpm DOM conformance
checker, i.e. L<Whatpm::ContentChecker>.

The C<mklinktypelist.pl> script is the script that is used to generate
the C<_LinkTypeList.pm> from the list of available link C<rel>
extensions in the WHATWG Wiki.  The script can be invoked by using the
C<make> command as mentioned in the L</"SYNOPSIS"> section.

=head1 WILLFUL VIOLATIONS

As the WHATWG Wiki is freely editable by any interested party, it
might sometimes include broken or incorrect data that are
inappropriate for the conformance checker implementation.  Rather than
complying with the spec literally, we choose to willfully violate such
broken data from the wiki page.  Specifically,

=over 4

=item Table rows whose "Keyword" cell contains "[" or "]" are ignored.

=item Keywords in the "Synonyms" cell that contain "(", ")", "<", or ">" are ignored.

=back

=head1 SEE ALSO

C<Makefile>.

L<Whatpm::ContentChecker>.

Web Applications 1.0 - Link types
<http://www.whatwg.org/specs/web-apps/current-work/complete.html#linkTypes>.

RelExtensions - WHATWG Wiki
<http://wiki.whatwg.org/wiki/RelExtensions>.

=head1 AUTHORS

The author of C<mklinktypelist.pl> is Wakaba <wakaba@suikawiki.org>.

Authors of the "RelExtensions" page in the WHATWG Wiki, from which the
C<_LinkTypeList.pm> Perl module is generated, are WHATWG contributors.
For the revision history of the wiki pgae, see
<http://wiki.whatwg.org/index.php?title=RelExtensions&action=history>.

=head1 LICENSE

Copyright (C) 2006 The WHATWG Contributors

Copyright 2007-%s Wakaba <wakaba@suikawiki.org>.

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE. 

(So-called "MIT license".  Source: "WHATWG Wiki:Copyrights"
<http://wiki.whatwg.org/wiki/WHATWG_Wiki:Copyrights>)

=cut

', $year;
