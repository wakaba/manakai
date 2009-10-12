#!/usr/bin/perl
use strict;

use lib qw[../];
my $EntitiesFileName = 'Entities.html';
my $Entity = {};

require Whatpm::NanoDOM;
require Whatpm::HTML;
my $doc = Whatpm::NanoDOM::Document->new;
{
  open my $file, '<:encoding(utf8)', $EntitiesFileName
    or die "$0: $EntitiesFileName: $!";
  local $/ = undef;
  Whatpm::HTML->parse_string (scalar <$file> => $doc);
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
  warn "$0: No <table> in $EntitiesFileName\n";
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

my $n = sub { my $s = shift; $s =~ s/\s+/ /g; $s =~ s/^ //; $s =~ s/ $//; $s };
for my $tr (@row) {
  my @td = grep {
    $_->node_type == 1 and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
        $_->manakai_local_name eq 'td'
  } @{$tr->child_nodes};
  my $name = $n->($td[0]->text_content);
  my $value = $n->($td[1]->text_content);
  $Entity->{$name} = chr hex substr $value, 2; # U+HHHH
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useqq = 1;
my $value = Dumper $Entity;
$value =~ s/\$VAR1\b/\$Whatpm::HTML::EntityChar/;

print $value;
print "1;\n";
print '__DATA__

=head1 NAME

mkentitylist.pl - Generate a named entity list for HTML parser

_NamedEntityList.pm - A named entity list for HTML parser

=head1 DESCRIPTION

The C<_NamedEntityList.pm> file contains a list of named entities
used in HTML documents, both conforming and non-conforming.
It is referenced by C<ContentHTML.pm>.  For more
information, see L<Whatpm::HTML>.

The C<mkentitylist.pl> script is used to generate
the C<_NamedEntityList.pm> file from the table in the HTML5
specification.

=head1 SEE ALSO

L<Whatpm::HTML>.

HTML 5 - Entities
<http://www.whatwg.org/specs/web-apps/current-work/#entities>

=head1 LICENSE

(C) Copyright 2004-2007 Apple Computer, Inc., Mozilla Foundation,
and Opera Software ASA.

Copyright 2007 Wakaba <w@suika.fam.cx>.

You are granted a license to use, reproduce and create derivative works 
of this document.

=cut

';
