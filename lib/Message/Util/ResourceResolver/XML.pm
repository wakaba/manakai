=head1 NAME

Message::Util::ResourceResolver::XML - Resource Resolver for XML Parser

=head1 DESCRIPTION

Resource resolver for XML parser modules.

This module is part of manakai.

=cut

package Message::Util::ResourceResolver::XML;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1.2.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Message::Util::ResourceResolver::Base;
push our @ISA, 'Message::Util::ResourceResolver::Base';

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/archive/2004/6/27/ResourceResolver/XML#>
}
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   rr => Message::Util::ResourceResolver::Base::URI_CONFIG (),
   rrx => URI_CONFIG,
   infoset => q<http://www.w3.org/2001/04/infoset#>,
  };

=head1 METHODS

=over 4

=item $res = I<ClassName>->new

Generates a new instance of I<ClassName>

=cut

# Inherited

=item $result = $res->get_resource (options)

Gets resource specified as parameter and returns it.
Returned value C<$result> is a hash reference that
has resources and parameters retrived.

=cut

# Inherited

=item $res->reset

Removes all "state" or configuration information stores on the resource resolver.

=cut

# Inherited

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/07/04 07:05:54 $
