#!/usr/bin/perl
use strict;

use lib qw[/home/httpd/html/www/markup/html/whatpm
           /home/wakaba/public_html/-temp/wiki/lib];
use CGI::Carp qw[fatalsToBrowser];

use SuikaWiki::Input::HTTP; ## TODO: Use some better CGI module

my $http = SuikaWiki::Input::HTTP->new;

## TODO: _charset_

my $mode = $http->meta_variable ('PATH_INFO');
## TODO: decode unreserved characters

if ($mode eq '/table') {
  require Encode;
  require Whatpm::HTML;
  require Whatpm::NanoDOM;

  my $s = $http->parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }

  $s = Encode::decode ('utf-8', $s);
  my $doc = Whatpm::HTML->parse_string
      ($s => Whatpm::NanoDOM::Document->new);

  my @table_el;
  my @node = @{$doc->child_nodes};
  while (@node) {
    my $node = shift @node;
    if ($node->node_type == 1) {
      if ($node->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
          $node->manakai_local_name eq 'table') {
        push @table_el, $node;
      }
    }
    push @node, @{$node->child_nodes};
  }
  
  print STDOUT "Content-Type: text/html; charset=utf-8\n\n";
  
  use JSON;
  require Whatpm::HTMLTable;

  print STDOUT '<!DOCTYPE html>
<html lang="en">
<head>
<title>HTML5 Table Structure Viewer</title>
<script src="../table-script.js" type="text/javascript"></script>
</head>
<body>
<noscript><p>How great the world without any script were!</p></noscript>
';

  my $i = 0;
  for my $table_el (@table_el) {
    $i++; print STDOUT "<h1>Table $i</h1>\n";

    my $table = Whatpm::HTMLTable->form_table ($table_el);

    for (@{$table->{column_group}}, @{$table->{column}}) {
      next unless $_;
      delete $_->{element};
    }
    
    for (@{$table->{row_group}}) {
      next unless $_;
      next unless $_->{element};
      $_->{type} = $_->{element}->manakai_local_name;
      delete $_->{element};
    }
    
    for (@{$table->{cell}}) {
      next unless $_;
      for (@{$_}) {
        next unless $_;
        for (@$_) {
          delete $_->{element};
        }
      }
    }

    print STDOUT '<script type="text/javascript">
  tableToCanvas (
';
    print STDOUT objToJson ($table);
    print STDOUT ');
</script>';
  }

  print STDOUT '</body></html>';
} else {
  print STDOUT "Status: 404 Not Found\nContent-Type: text/plain; charset=us-ascii\n\n404";
}

exit;

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

## $Date: 2007/05/27 06:37:05 $
