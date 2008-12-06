use strict;

## ISSUE: Currently we require manakai XML parser to test arbitrary XML tree.
use lib qw[/home/wakaba/work/manakai2/lib];

use Test;

require Whatpm::ContentChecker;
require Whatpm::XML::Parser;
require Whatpm::HTML;
require Whatpm::NanoDOM;
require Message::URI::URIReference;
require Message::DOM::Atom::AtomElement;
*Whatpm::NanoDOM::Element::rel
    = \&Message::DOM::Atom::AtomElement::AtomLinkElement::rel;

sub test_files (@) {
  my @FILES = @_;

  require 't/testfiles.pl';
  execute_test ($_, {
    errors => {is_list => 1},
  }, \&test) for @FILES;
} # test_files

sub test ($) {
  my $test = shift;

  $test->{parse_as} = 'xml';
  $test->{parse_as} = 'html'
      if $test->{data}->[1] and $test->{data}->[1]->[0] eq 'html';

  unless ($test->{data}) {
    warn "No #data field\n";
  } elsif (not $test->{errors}) {
    warn "No #errors field ($test->{data}->[0])\n";
  }

  my $doc;
  if ($test->{parse_as} eq 'xml') {
    $doc = Whatpm::NanoDOM::Document->new;
    Whatpm::XML::Parser->parse_char_string ($test->{data}->[0] => $doc);
    ## NOTE: There should be no well-formedness error; if there is,
    ## then it is an error of the test case itself.
  } else {
    $doc = Whatpm::NanoDOM::Document->new;
    Whatpm::HTML->parse_char_string ($test->{data}->[0] => $doc);
  }
  $doc->document_uri (q<thismessage:/>);

  my @error;
  Whatpm::ContentChecker->check_element
    ($doc->document_element, sub {
       my %opt = @_;
       if ($opt{type} =~ /^status:/ and $opt{level} eq 'i') {
         #
       } else {
         push @error, get_node_path ($opt{node}) . ';' . $opt{type} .
             (defined $opt{text} ? ';' . $opt{text} : '') .
             (defined $opt{level} ? ';'.$opt{level} : '');
       }
     }, sub {
       my $opt = shift;
       push @error, get_node_path ($opt->{container_node}) . ';SUBDOC';
     });
  
  ok join ("\n", sort {$a cmp $b} @error),
    join ("\n", sort {$a cmp $b} @{$test->{errors}->[0]}), $test->{data}->[0];
} # test

sub get_node_path ($) {
  my $node = shift;
  my @r;
  while (defined $node) {
    my $rs;
    if ($node->node_type == 1) {
      $rs = $node->manakai_local_name;
      $node = $node->parent_node;
    } elsif ($node->node_type == 2) {
      $rs = '@' . $node->manakai_local_name;
      $node = $node->owner_element;
    } elsif ($node->node_type == 3) {
      $rs = '"' . $node->data . '"';
      $node = $node->parent_node;
    } elsif ($node->node_type == 9) {
      $rs = '';
      $node = $node->parent_node;
    } else {
      $rs = '#' . $node->node_type;
      $node = $node->parent_node;
    }
    unshift @r, $rs;
  }
  return join '/', @r;
} # get_node_path

=head1 NAME

content-checker.pl - Test engine for document conformance checking

=head1 DESCRIPTION

The C<content-checker.pl> script implements a test engine for the
conformance checking modules, directly or indirectly referenced from
L<Whatpm::ContentChecker>.

This script is C<require>d by various test scripts, including
C<ContentCheker.t>, C<ContentChecker-Atom.t>, and C<LangTag.t>.

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Public Domain.

=cut

1; ## $Date: 2008/12/06 10:00:58 $
