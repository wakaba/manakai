package Message::DOM::DOMError;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::Util::Error', 'Message::IF::DOMError';
require Message::Util::Error;

## |DOMError| constants

## ErrorSeveriry
sub SEVERITY_WARNING () { 1 }
sub SEVERITY_ERROR () { 2 }
sub SEVERITY_FATAL_ERROR () { 3 }

sub ___error_def () {+{
}} # ___error_def

# sub _FORMATTER_PACKAGE_ { $_[0]->{-def}->{manakai_formatter_package} }

## |DOMError| attributes

sub location ($) {
  require Message::DOM::DOMLocator;
  return bless $_[0]->{location} ||= {}, 'Message::DOM::DOMLocator';
} # location

## NOTE: In manakai, this attribute returns an error message
## string written in the |i-default| language.  Note that 
## it is same as |text| attribute.
sub message ($) {
  goto &{$_[0]->can ('text')};
} # message

sub related_data ($) {
  return $_[0]->{related_data};
} # related_data

sub related_exception ($) {
  return $_[0]->{related_exception};
} # related_exception

sub severity ($) {
  return $_[0]->{-def}->{severity};
} # severity

## type - defined in |Message::Util::Error|.

## |DOMError| manakai's Perl Binding method

## ISSUE: Document this in the spec.

use overload
    '""' => 'stringify',
    fallback => 1;

sub stringify ($) {
  local $Error::Depth = $Error::Depth + 1;
  my $r = '';

  my $loc = $_[0]->location;
  my $uri = $loc->uri;
  $r .= " <$uri>" if defined $uri;

  my $line = $loc->line_number;
  $r .= " Line $line " if $line >= 0;

  my $column = $loc->column_number;
  $r .= " Column $column " if $column >= 0;

  substr ($r, 0, 1) = '';
  $r .= ': ' if length $r;
  
  $r .= $_[0]->SUPER::stringify;
  return $r;
} # stringify

## ISSUE: Document that a |DOMErrorHandler| MUST be a CODE reference
## in the Perl DOM Binding spec.

package Message::IF::DOMError;
push our @ISA, 'Message::Util::Error';

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/06/21 11:59:36 $
