package Whatpm::WebVTT::Checker;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '1.0';

my $DefaultErrorHandler = sub {
  my %args = @_;
  warn sprintf "%s: %s at Line %d Column %d\n",
      $args{level},
      $args{type}
          . (defined $args{text} ? $args{text} : '')
          . (defined $args{value} ? $args{value} : ''),
      $args{line}, $args{column};
}; # $DefaultErrorHandler

sub new ($) {
  return bless {
    onerror => $DefaultErrorHandler,
  }, $_[0];
} # new

sub onerror ($;$) {
  if (@_ > 1) {
    $_[0]->{onerror} = $_[1] || $DefaultErrorHandler;
  } 
  return $_[0]->{onerror};
} # onerror

sub check_track ($$) {
  my ($self, $track) = @_;

  require Whatpm::WebVTT::Parser;
  require Message::DOM::DOMImplementation;
  my $parser = Whatpm::WebVTT::Parser->new;
  $parser->onerror ($self->{onerror});
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  my $last_start_time = 0;
  for my $cue (@{$track->manakai_all_cues}) {
    my $time = $cue->start_time;
    if ($time < $last_start_time) {
      ## <http://dev.w3.org/html5/webvtt/#webvtt-cue-timings>.
      $self->{onerror}->(type => 'webvtt:start time order',
                         level => 'm',
                         line => $cue->manakai_line,
                         column => $cue->manakai_column);
    } else {
      $last_start_time = $time;
    }

    if ($cue->end_time < $time) {
      ## <http://dev.w3.org/html5/webvtt/#webvtt-cue-timings>.
      $self->{onerror}->(type => 'webvtt:end time < start time',
                         level => 'm',
                         line => $cue->manakai_line,
                         column => $cue->manakai_column);
    }

    my $id = $cue->id;
    if ($id =~ /-->/ or $id =~ /[\x0D\x0A]/) {
      ## <http://dev.w3.org/html5/webvtt/#webvtt-cue-identifier>.
      $self->{onerror}->(type => 'webvtt:id:syntax',
                         level => 'm',
                         line => $cue->manakai_line,
                         column => $cue->manakai_column);
    }
    
    if ($cue->text =~ /\x0A\x0A|\x0D\x0D|\x0D\x0A[\x0D\x0A]|\x0A\x0D/) {
      $self->{onerror}->(type => 'double newline not allowed',
                         level => 'm',
                         line => $cue->manakai_line,
                         column => $cue->manakai_column);
    }

    my $df = $parser->text_to_dom ($cue->text => $doc);
    $self->check_text_document_fragment ($df);
  }
} # check_track

sub check_text_document_fragment ($$) {
  my ($self, $df) = @_;

  my @node = ($df);
  while (@node) {
    my $node = shift @node;
    if ($node->node_type == $node->ELEMENT_NODE and
        $node->manakai_local_name eq 'span') {
      if ($node->has_attribute ('title')) {
        ## <http://dev.w3.org/html5/webvtt/#webvtt-cue-span-start-tag-annotation-text>.
        unless ($node->title =~ /[^\x09\x0A\x0C\x0D\x20]/) {
          $self->{onerror}->(type => 'webvtt:empty annotation',
                             level => 'm',
                             line => $node->get_user_data
                                 ('manakai_source_line'),
                             column => $node->get_user_data
                                 ('manakai_source_column'));
        }
      }
    }
    push @node, @{$node->child_nodes};
  }
} # check_text_document_fragment

1;
