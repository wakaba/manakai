
=head1 NAME

Message::Markup::SuikaWikiConfig20::Parser: manakai --- SuikaWikiConfig/2.0 parser

=head1 DESCRIPTION

SuikaWikiConfig/2.0 is a general configuration description format.
This module can be used to parse such configuration and to
generate node tree for it.

This module is part of manakai.

=cut

package Message::Markup::SuikaWikiConfig20::Parser;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Markup::SuikaWikiConfig20::Node;

=head1 METHODS

=over 4

=item $x = Message::Markup::SuikaWikiConfig20::Parser->new (%options)

Returns new instance of parser

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self;
}

sub parse_text ($$) {
  my ($self, $s) = @_;
  my $root = SuikaWiki::Markup::SuikaWikiConfig20->new
    (type => '#document');
  my $current = $root;
  my $current_element = $root;
  my $is_new_element = 0;
  my $is_list_element = 0;
  for my $line (split /\x0D?\x0A/, $s) {
    if ($line =~ /^([^#\s].*):\s*([^\s:][^:]*)?$/) {
      my ($name, $val) = ($1, $2);
      substr ($name, 0, 1) = '' if substr ($name, 0, 1) eq '\\';
      substr ($val, 0, 1) = '' if substr ($val, 0, 1) eq '\\';
      if (substr ($name, -6) eq '[list]') {
        substr ($name, -6) = '';
        $val = length ($val) ? [$val] : [];
        $is_list_element = 1;
      } else {
        $is_list_element = 0;
      }
      $current_element = $root->append_new_node (type => '#element',
                                                 local_name => $name,
                                                 value => $val);
      if (defined $2) {  ## Foo: bar
        $current = $root;
        $current_element = $root;
      } else {           ## Foo:\n  bar\n  baz
        $current = $current_element;
        $is_new_element = 1;
      }
    } elsif ($line =~ /^\s+(\@+)(.*):\s*([^\s:][^:]*)?$/) {
      my ($nest, $name, $val) = (length $1, $2, $3);
      substr ($name, 0, 1) = '' if substr ($name, 0, 1) eq '\\';
      substr ($val, 0, 1) = '' if substr ($val, 0, 1) eq '\\';
      if (substr ($name, -6) eq '[list]') {
        substr ($name, -6) = '';
        $val = length ($val) ? [$val] : [];
        $is_list_element = 1;
      } else {
        $is_list_element = 0;
      }
      my $ce;
      if (length ($name)) {
        while ($current_element->flag ('p__nest_level') >= $nest) {
          $current_element = $current_element->parent_node;
        }
        $ce = $current_element->append_new_node (type => '#element',
                                                 local_name => $name,
                                                 value => $val);
        $ce->flag (p__nest_level
                   => $current_element->flag ('p__nest_level') + 1);
        unless (defined $3) {  ##  @foo: \nbar
          $current_element = $ce;
          $current = $ce;
          $is_new_element = 1;
        }
      } else {
        while ($current_element->flag ('p__nest_level') > $nest - 1) {
          $current_element = $current_element->parent_node;
        }
        $current_element->append_text ($val);
        $current = $current_element;
        unless (defined $3) {  ##  @@: \nbar
          $is_new_element = 1;
        }
      }
    } elsif ($line =~ /^\s+([^\s#].*)$/) {
      my $val = $1;
      substr ($val, 0, 1) = '' if substr ($val, 0, 1) eq '\\';
      if ($is_new_element || $is_list_element) {
        $current_element->append_text ($val);
        $is_new_element = 0;
      } else {
        $current_element->append_text ("\x0A" . $val);
      }
    } elsif ($line =~ /^\s+$/) {
      # skip
    } elsif ($line =~ /^\s*\#(.*)$/) {
      if ($current->node_type eq '#comment') {
        $current->append_text ("\x0A" . $1);
      } else {
        $current = $root->append_new_node (type => '#comment', value => $1);
      }
    } else {
      $current = $root;
      #print STDERR qq(**$line**\n); 
    }
  }
  $root;
}

sub flag ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  $self->{flag}->{$name};
}

sub option ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  $self->{option}->{$name};
}

=back

=head1 EXAMPLE

  use Message::Markup::SuikaWikiConfig20::Parser;
  my $parser = new Message::Markup::SuikaWikiConfig20::Parser;
  
  my $conf = $parser->parse_text ($config);
  print $conf->get_attribute ('Some Configuration Item');

=head1 SEE ALSO

Message::Markup::SuikaWikiConfig20::Node,
SuikaWiki <http://suika.fam.cx/~wakaba/-temp/wiki/wiki?SuikaWiki>,
<http://suika.fam.cx/~wakaba/-temp/wiki/wiki?SuikaWikiConfig/2.0>

=head1 HISTORY

This module was part of SuikaWiki 2, with the name of 
C<SuikaWiki::Markup::SuikaWikiConfig20::Parser>.

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/11/15 07:42:34 $
