package Message::DOM::DOMImplementationRegistry;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMImplementationSource';
require Message::DOM::DOMImplementationSource;

$Message::DOM::DOMImplementationRegistry = __PACKAGE__;

## |DOMImplementationRegistry| methods

sub get_dom_implementation ($$) {
  local $Error::Depth = $Error::Depth + 1;
  for my $class (keys %$Message::DOM::DOMImplementationRegistry::SourceClass) {
    my $r = $class->get_dom_implementation ($_[1]);
    return $r if defined $r;
  }
} # get_dom_implementation

sub get_dom_implementation_list ($$) {
  local $Error::Depth = $Error::Depth + 1;
  require Message::DOM::DOMImplementationList;
  my $list = bless [], 'Message::DOM::DOMImplementationList';
  for my $class (keys %$Message::DOM::DOMImplementationRegistry::SourceClass) {
    push @$list, @{$class->get_dom_implementation_list ($_[1])};
  }
  return $list;
} # get_dom_implementation_list

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/07 05:58:11 $
