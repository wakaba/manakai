package Whatpm::HTML::Defs;
use strict;
use warnings;
our $VERSION = '1.0';
use Exporter::Lite;

our @EXPORT;

## ------ Special character-like constants ------

push @EXPORT, qw(EOF_CHAR NEVER_CHAR ABORT_CHAR);

## The "EOF" pseudo-character in the HTML parsing algorithm.
sub EOF_CHAR () { -1 }

## A pseudo-character code that can never appear in the input stream.
sub NEVER_CHAR () { -2 }

## Pause tokenization (and parsing) because of the end of the
## currently available characters (that could be different from EOF).
sub ABORT_CHAR () { -3 }

## ------ HTML/XML Tokens ------

push @EXPORT, qw(
  DOCTYPE_TOKEN COMMENT_TOKEN START_TAG_TOKEN END_TAG_TOKEN
  END_OF_FILE_TOKEN CHARACTER_TOKEN PI_TOKEN ABORT_TOKEN
  END_OF_DOCTYPE_TOKEN ATTLIST_TOKEN ELEMENT_TOKEN 
  GENERAL_ENTITY_TOKEN PARAMETER_ENTITY_TOKEN NOTATION_TOKEN
);

sub DOCTYPE_TOKEN () { 1 } ## XML5: No DOCTYPE token.
sub COMMENT_TOKEN () { 2 }
sub START_TAG_TOKEN () { 3 }
sub END_TAG_TOKEN () { 4 }
sub END_OF_FILE_TOKEN () { 5 }
sub CHARACTER_TOKEN () { 6 }
sub PI_TOKEN () { 7 } ## NOTE: XML only.
sub ABORT_TOKEN () { 8 } ## NOTE: For internal processing.
sub END_OF_DOCTYPE_TOKEN () { 9 } ## NOTE: XML only.
sub ATTLIST_TOKEN () { 10 } ## NOTE: XML only.
sub ELEMENT_TOKEN () { 11 } ## NOTE: XML only.
sub GENERAL_ENTITY_TOKEN () { 12 } ## NOTE: XML only.
sub PARAMETER_ENTITY_TOKEN () { 13 } ## NOTE: XML only.
sub NOTATION_TOKEN () { 14 } ## NOTE: XML only.

## ------ Tree constructor state constants ------

## Whether the parsed string is in the foreign island or not affect
## how tokenization is done, unfortunately.  These are a copy of some
## of tokenization state constants.  See Whatpm::HTML for the full
## list and the descriptions for constants.

push @EXPORT, qw(FOREIGN_EL);

sub FOREIGN_EL () { 0b1_00000000000 }

## ------ Error handling ------

our $DefaultErrorHandler = sub {
  my (%opt) = @_;
  my $line = $opt{token} ? $opt{token}->{line} : $opt{line};
  my $column = $opt{token} ? $opt{token}->{column} : $opt{column};
  warn "Parse error ($opt{type}) at line $line column $column\n";
}; # $DefaultErrorHandler

1;

=head1 LICENSE

Copyright 2007-2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
