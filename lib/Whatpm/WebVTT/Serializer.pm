package Whatpm::WebVTT::Serializer;
use strict;
use warnings;
our $VERSION = '1.0';

sub track_to_char_string ($$) {
  my $track = $_[1];

  my $result = "WEBVTT\x0A";

  unless ($track->manakai_all_cues->length) {
    $result .= "\x0A";
  }

  for my $cue (@{$track->manakai_all_cues}) {
    $result .= "\x0A";

    my $id = $cue->id;
    if (length $id) {
      $id =~ s/-->/--&gt;/g;
      $id =~ s/[\x0D\x0A]+/ /g;
      $result .= $id . "\x0A";
    }
    
    my $start_time = $cue->start_time;
    $start_time = sprintf '%02d:%02d:%02d.%03d',
        int ($start_time / 60 / 60),
        int ($start_time / 60 % 60),
        int ($start_time % 60),
        int ($start_time * 1000 % 1000);
    my $end_time = $cue->end_time;
    $end_time = sprintf '%02d:%02d:%02d.%03d',
        int ($end_time / 60 / 60),
        int ($end_time / 60 % 60),
        int ($end_time % 60),
        int ($end_time * 1000 % 1000);
    $result .= "$start_time --> $end_time";

    if (length $cue->vertical) {
      $result .= " vertical:" . $cue->vertical;
    }

    if ($cue->line != -1) {
      $result .= " line:" . $cue->line;
      unless ($cue->snap_to_lines) {
        $result .= "%";
      }
    }

    if ($cue->position != 50) {
      $result .= " position:" . $cue->position . "%";
    }

    if ($cue->size != 100) {
      $result .= " size:" . $cue->size . "%";
    }

    if ($cue->align ne 'middle') {
      $result .= " align:" . $cue->align;
    }

    $result .= "\x0A";

    my $text = $cue->text;
    $text =~ s/[\x0D\x0A]+/\x0A/g;
    $text =~ s/\A\x0A//;
    $text =~ s/\x0A\z//;
    $text =~ s/-->/--&gt;/;
    $result .= $text . "\x0A";
  }
  
  return $result;
} # track_to_char_string

sub _classes ($) {
  return join '',
      map { '.' . $_ }
      grep { length and not /[<>&.]/ }
      split /[\x0D\x0A\x09\x0C\x20]+/, $_[0];
} # _classes

sub dom_to_text ($$) {
  my $result = '';

  my @node = ($_[1]);
  my $in_ruby = 0;
  while (@node) {
    my $node = shift @node;
    if (not ref $node) {
      $result .= $node;
      if ($node eq '</ruby>') {
        $in_ruby--;
      }
      next;
    }

    if ($node->node_type == $node->ELEMENT_NODE) {
      my $ns = $node->namespace_uri || '';
      if ($ns eq q<http://www.w3.org/1999/xhtml>) {
        my $ln = $node->manakai_local_name;
        my $class = $node->get_attribute ('class');
        $class = '' unless defined $class;
        if ($ln eq 'b' or $ln eq 'i' or $ln eq 'u') {
          $result .= '<' . $ln . (_classes $class) . '>';
          unshift @node, @{$node->child_nodes}, '</' . $ln . '>';
        } elsif ($ln eq 'ruby') {
          $result .= '<ruby' . (_classes $class) . '>';
          unshift @node, @{$node->child_nodes}, '</ruby>';
          $in_ruby++;
        } elsif ($ln eq 'span') {
          if ($node->has_attribute ('title')) {
            my $title = $node->title;
            $title =~ s{([<>&])}{
              {'<' => '&lt;', '>' => '&gt;', '&' => '&amp;'}->{$1}
            }ge;
            $result .= '<v' . (_classes $class) . ' ' . $title . '>';
            unshift @node, @{$node->child_nodes}, '</v>';
          } else {
            $result .= '<c' . (_classes $class) . '>';
            unshift @node, @{$node->child_nodes}, '</c>';
          }
        } elsif ($ln eq 'rt') {
          $result .= '<rt' . (_classes $class) . '>';
          unshift @node, @{$node->child_nodes}, '</rt>';
        } else {
          unshift @node, @{$node->child_nodes};
        }
      } else {
        unshift @node, @{$node->child_nodes};
      }
    } elsif ($node->node_type == $node->PROCESSING_INSTRUCTION_NODE) {
      if ($node->target eq 'timestamp') {
        if ($node->data =~ /\A([0-9]{2,}:[0-9]{2}:[0-9]{2}\.[0-9]{3})\z/) {
          $result .= '<' . $1 . '>';
        }
      }
    } elsif ($node->node_type == $node->TEXT_NODE or
             $node->node_type == $node->CDATA_SECTION_NODE) {
      my $data = $node->data;
      $data =~ s{([<>&])}{
        {'<' => '&lt;', '>' => '&gt;', '&' => '&amp;'}->{$1}
      }ge;
      $result .= $data;
    } else {
      unshift @node, @{$node->child_nodes};
    }
  }

  return $result;
} # dom_to_text

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
