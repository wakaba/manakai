
=head1 NAME

Message::Markup::XML::Serialize::HTML - HTML Serializer

=head1 DESCRIPTION

C<Message::Markup::XML::Serialize::HTML> provides a function
that serizlizes a node (C<Message::Markup::XML::Node> object)
as a (fragment of) HTML document.

This module is part of manakai.

=cut

package Message::Markup::XML::Serialize::HTML;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

=head1 METHODS

=over 4

=item $html = Message::Markup::XML::Serizlize::HTML::html_simple ($node, [%option])

Serialize C<$node> as an HTML tree and return it.

This serializer does not check:

=over 2

=item whether element type names, attribute names, attribute values or entity names are valid as HTML

=item XML namespace to which C<$node> belongs

=item whether C<$node> occurs in valid context

=item uniqueness of attribute name

=back

And this serializer does not output processing instructions whose
first three characters is 'xml'.  It neither does output any markup declaration
(except comment declaration), including DOCTYPE declaration.
Marked section is not implemented and its content is barely included
as regular data.

This serializer does not output end tag for some element types,
such as C<link> or C<base>.  Element types C<style> and C<script>
is treated as C<CDATA> content.

=cut

sub html_simple ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  for my $node_type ($node->node_type) {
    if ($node_type eq '#element') {
      my $element_type = $node->local_name;
      if ({qw/img 1 link 1 base 1 meta 1 area 1 br 1 hr 1
              param 1 input 1 basefont 1 wbr 1 isindex 1 nextid 1
             /}->{$element_type}) {
        $r .= ____start_tag ($node, %opt, local_name => $element_type);
      } elsif ({qw/style 1 script 1/}->{$element_type}) {
        my $content = $node->inner_text;
        $content =~ s!</!&lt;/!g;
        $r .= ____start_tag ($node, %opt, local_name => $element_type)
            . $content
            . '</' . $element_type . '>';
      } else {
        $r .= ____start_tag ($node, %opt, local_name => $element_type);
        for (@{$node->child_nodes}) {
          my $nt = $_->node_type;
          if ($nt eq '#text') {
            $r .= ____escape ($_->value);
          } elsif ($nt ne '#attribute') {
            $r .= html_simple ($_, %opt);
          }
        }
        $r .= '</' . $element_type . '>';
      }
    } elsif ($node_type eq '#text') {
      $r .= ____escape ($node->value);
    } elsif ($node_type eq '#attribute') {
    } elsif ($node_type eq '#comment') {
      my $content = $node->value;
      $content =~ s!--!- - !g;
      $content =~ s!-$!- !;
      $r .= '<!--' . $content . '-->';
    } elsif ($node_type eq '#pi') {
      my $name = $node->local_name;
      unless (substr ($name, 0, 3) eq 'xml') {
        my $content = $node->inner_xml;
        $content =~ s!\?>!?&gt;!g;
        $r .= '<?' . $name . ' ' . $content . '?>';
      }
    } elsif ($node_type eq '#reference') {
      $r .= $node->stringify;
    } elsif ($node_type eq '#declaration') {
    } else {
      for (@{$node->child_nodes}) {
        $r .= html_simple ($_, %opt) unless $_->node_type eq '#attribute';
      }
    }
  }
  $r;
}

sub ____start_tag ($;%) {
  my ($node, %opt) = @_;
  my $r = '<' . $opt{local_name};
  for (grep {$_->node_type eq '#attribute'} @{$node->child_nodes}) {
    $r .= ' ' . $_->local_name . '="' . ____escape ($_->inner_text) . '"';
  }
  $r . '>';
}

sub ____escape ($;%) {
  my $s = shift;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  $s;
}

=back

=head1 SEE ALSO

C<Message::Markup::XML::Node>

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/06/03 06:41:18 $
