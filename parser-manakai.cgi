#!/usr/bin/perl
use strict;

use lib qw[/home/httpd/html/www/markup/html/whatpm
           /home/wakaba/work/manakai/lib
           /home/wakaba/public_html/-temp/wiki/lib];
use CGI::Carp qw[fatalsToBrowser];
use Time::HiRes qw/time/;

use SuikaWiki::Input::HTTP; ## TODO: Use some better CGI module

my $http = SuikaWiki::Input::HTTP->new;

## TODO: _charset_

my $mode = $http->meta_variable ('PATH_INFO');
## TODO: decode unreserved characters

  my $s = $http->parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }
  my $char_length = length $s;
  my %time;
  my $time1;
  my $time2;

  require Message::DOM::DOMImplementation;
  my $dom = Message::DOM::DOMImplementation->____new;
  $| = 1;
  my $doc;

if ($mode eq '/html/html' or $mode eq '/html/test') {
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  require Encode;
  require Whatpm::HTML;

  $time1 = time;
  $s = Encode::decode ('utf-8', $s);
  $time2 = time;
  $time{decode} = $time2 - $time1;
  

  print STDOUT "#errors\n";

  my $onerror = sub {
    my (%opt) = @_;
    print STDOUT "$opt{line},$opt{column},$opt{type}\n";
  };

  $time1 = time;
  $doc = Whatpm::HTML->parse_string ($s => $dom->create_document, $onerror);
  $time2 = time;
  $time{parse} = $time2 - $time1;

  print "#document\n";

  my $out;
  $time1 = time;
  if ($mode eq '/html/html') {
    $out = Whatpm::HTML->get_inner_html ($doc);
  } else { # test
    $out = test_serialize ($doc);
  }
  $time2 = time;
  $time{serialize} = $time2 - $time1;
  print STDOUT Encode::encode ('utf-8', $$out);
  print STDOUT "\n";
} elsif ($mode eq '/xhtml/html' or $mode eq '/xhtml/test') {
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  require Message::DOM::XMLParserTemp;
  print STDOUT "#errors\n";

  my $onerror = sub {
    my $err = shift;
    print STDOUT $err->location->line_number, ",";
    print STDOUT $err->location->column_number, " ";
    print STDOUT $err->text, "\n";
    return 1;
  };

  open my $fh, '<', \$s;
  my $time1 = time;
  $doc = Message::DOM::XMLParserTemp->parse_byte_stream
      ($fh => $dom, $onerror, charset => 'utf-8');
  my $time2 = time;
  $time{parse_xml} = $time2 - $time1;

  print "#document\n";

  my $out;
  if ($mode eq '/xhtml/html') {
    ## TODO: Use XHTML serializer
    #$out = Whatpm::HTML->get_inner_html ($doc);
  } else { # test
    $time1 = time;
    $out = test_serialize ($doc);
    $time2 = time;
    $time{serialize_test} = $time2 - $time1;
  }
  print STDOUT Encode::encode ('utf-8', $$out);
  print STDOUT "\n";
} else {
  print STDOUT "Status: 404 Not Found\nContent-Type: text/plain; charset=us-ascii\n\n404";
  exit;
}

  if ($http->parameter ('dom5')) {
    require Whatpm::ContentChecker;
    print STDOUT "#domerrors\n";
    $time1 = time;
    Whatpm::ContentChecker->check_document ($doc, sub {
      my %opt = @_;
      print STDOUT get_node_path ($opt{node}) . ';' . $opt{type} . "\n";
    });
    $time2 = time;
    $time{check} = $time2 - $time1;
  }

  print STDOUT "#log\n";
  for (qw/decode parse parse_xml serialize_html serialize_xml serialize_test
          check/) {
    next unless defined $time{$_};
    print STDOUT {
      decode => 'bytes->chars',
      parse => 'html5(chars)->dom5',
      parse_xml => 'xml1(chars)->dom5',
      serialize_html => 'dom5->html5',
      serialize_xml => 'dom5->xml',
      serialize_test => 'dom5->test',
      check => 'dom5 check',
    }->{$_};
    print STDOUT "\t", $time{$_}, "s\n";
    open my $file, '>>', ".manakai-$_.txt" or die ".manakai-$_.txt: $!";
    print $file $char_length, "\t", $time{$_}, "\n";
  }

exit;

sub test_serialize ($) {
  my $node = shift;
  my $r = '';

  my @node = map { [$_, ''] } @{$node->child_nodes};
  while (@node) {
    my $child = shift @node;
    my $nt = $child->[0]->node_type;
    if ($nt == $child->[0]->ELEMENT_NODE) {
      $r .= '| ' . $child->[1] . '<' . $child->[0]->tag_name . ">\x0A"; ## ISSUE: case?

      for my $attr (sort {$a->[0] cmp $b->[0]} map { [$_->name, $_->value] }
                    @{$child->[0]->attributes}) {
        $r .= '| ' . $child->[1] . '  ' . $attr->[0] . '="'; ## ISSUE: case?
        $r .= $attr->[1] . '"' . "\x0A";
      }
      
      unshift @node,
        map { [$_, $child->[1] . '  '] } @{$child->[0]->child_nodes};
    } elsif ($nt == $child->[0]->TEXT_NODE) {
      $r .= '| ' . $child->[1] . '"' . $child->[0]->data . '"' . "\x0A";
    } elsif ($nt == $child->[0]->CDATA_SECTION_NODE) {
      $r .= '| ' . $child->[1] . '<![CDATA[' . $child->[0]->data . "]]>\x0A";
    } elsif ($nt == $child->[0]->COMMENT_NODE) {
      $r .= '| ' . $child->[1] . '<!-- ' . $child->[0]->data . " -->\x0A";
    } elsif ($nt == $child->[0]->DOCUMENT_TYPE_NODE) {
      $r .= '| ' . $child->[1] . '<!DOCTYPE ' . $child->[0]->name . ">\x0A";
    } elsif ($nt == $child->[0]->PROCESSING_INSTRUCTION_NODE) {
      $r .= '| ' . $child->[1] . '<?' . $child->[0]->target . ' ' .
          $child->[0]->data . "?>\x0A";
    } else {
      $r .= '| ' . $child->[1] . $child->[0]->node_type . "\x0A"; # error
    }
  }
  
  return \$r;
} # test_serialize

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

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/21 14:54:14 $
