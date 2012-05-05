package Whatpm::HTML; # -*- Perl -*-
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '3.0';
use Encode;
use Whatpm::HTML::Defs;
use Whatpm::HTML::Parser;
push our @ISA, qw(Whatpm::HTML::Parser);

## DEPRECATED - Use Whatpm::HTML::Parser.

## DEPRECATED
sub parse_byte_stream ($$$$;$$) {
  #my ($self, $charset_name, $stream, $doc, $onerror, $get_wrapper) = @_;
  my $self = ref $_[0] ? $_[0] : $_[0]->new;
  my $doc = $self->{document} = $_[3];

  my $handle = $_[2];
  my $embedded_encoding_name;
  $self->{chars} = [];
  $self->{chars_pos} = 0;
  my $bytes = '';
  my $orig_bytes = '';
  {
    my $i = 0;
    while ($handle->read ($bytes, 1, length $bytes)) {
      $orig_bytes .= substr ($bytes, -1);
      last if $i++ == 1024;
    }
  }
  $self->{chars_pull_next} = sub {
    $self->{chars} = [];
    $self->{chars_pos} = 0;
    my $i = 0;
    while ($handle->read ($bytes, 1, length $bytes)) {
      $orig_bytes .= substr ($bytes, -1) unless $embedded_encoding_name;
      last if $i++ == 1024;
    }
    my @added = split //,
        decode $self->{input_encoding}, $bytes, Encode::FB_QUIET;
    if (6 < length $bytes or (length $bytes and $i <= 1024)) { # shit!
      push @added, "\x{FFFD}";
      substr ($bytes, 0, 1) = '';
    }
    push @{$self->{chars}}, @added;
    return @added > 0;
  };
  delete $self->{chars_was_cr};

  PARSER: {
    @{$self->{document}->child_nodes} = ();

    $self->_encoding_sniffing
        (transport_encoding_name => $_[1],
         embedded_encoding_name => $embedded_encoding_name,
         read_head => sub {
           return \$bytes;
         });
    $self->{document}->input_encoding ($self->{input_encoding});

    $self->{line_prev} = $self->{line} = 1;
    $self->{column_prev} = -1;
    $self->{column} = 0;
    
    $self->{restart_parser} = sub {
      $embedded_encoding_name = $_[0];
      $bytes = $orig_bytes;
      $self->{chars} = [];
      $self->{chars_pos} = 0;
      die bless {}, 'Whatpm::HTML::InputStream::RestartParser';
    };

    my $onerror = $_[4] || $self->onerror;
    $self->{parse_error} = sub {
      $onerror->(line => $self->{line}, column => $self->{column}, @_);
    };

    $self->_initialize_tokenizer;
    $self->_initialize_tree_constructor;
    $self->{t} = $self->_get_next_token;
    {
      my $error;
      {
        local $@;
        eval { $self->_construct_tree; 1 } or $error = $@;
      }
      if ($error) {
        if (ref $error eq 'Whatpm::HTML::InputStream::RestartParser') {
          redo PARSER;
        }
        die $error;
      }
      redo if $self->{nc} != EOF_CHAR;
    }
    $self->_terminate_tree_constructor;
    $self->_clear_refs;
  } # PARSER

  return $doc;
} # parse_byte_stream

## DEPRECATED - for backward compatibility
sub parse_string {
  return shift->parse_char_string (@_);
} # parse_string

## DEPRECATED
sub parse_char_stream ($$$;$$) {
  #my ($self, $handle, $document, $onerror, $get_wrapper) = @_;
  my $self = ref $_[0] ? $_[0] : $_[0]->new;
  my $doc = $self->{document} = $_[2];
  @{$self->{document}->child_nodes} = ();

  ## Confidence: irrelevant.
  $self->{confident} = 1 unless exists $self->{confident};
  $self->{document}->input_encoding ($self->{input_encoding})
      if defined $self->{input_encoding};

  $self->{line_prev} = $self->{line} = 1;
  $self->{column_prev} = -1;
  $self->{column} = 0;

  my $handle = $_[1];
  $self->{chars} = [];
  $self->{chars_pos} = 0;
  $self->{chars_pull_next} = sub {
    $self->{chars} = [];
    $self->{chars_pos} = 0;
    my $i = 0;
    my $char = '';
    while ($handle->read ($char, 1, 0)) {
      push @{$self->{chars}}, $char;
      last if $i++ == 1024;
    }
    return $i > 0;
  };
  delete $self->{chars_was_cr};

  my $onerror = $_[3] || $self->onerror;
  $self->{parse_error} = sub {
    $onerror->(line => $self->{line}, column => $self->{column}, @_);
  };

  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;
  $self->{t} = $self->_get_next_token;
  {
    $self->_construct_tree;
    redo if $self->{nc} != EOF_CHAR;
  }
  $self->_terminate_tree_constructor;
  $self->_clear_refs;

  return $doc;
} # parse_char_stream

1;

=head1 LICENSE

Copyright 2007-2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
