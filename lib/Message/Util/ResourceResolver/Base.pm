=head1 NAME

Message::Util::ResourceResolver::Base - Base Resource Resolver

=head1 DESCRIPTION

Some messaging or marking-up format, eg. XML, provides some mechanisms
to refer external resources.  Parsing document written in such formats,
in some case, requires retriving external resource.

Class C<Message::Util::ResourceResolver::Base> provides a common
interface with which parsers can retrive external document.

This module is part of manakai.

=cut

package Message::Util::ResourceResolver::Base;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1.2.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

use Message::Markup::XML::QName qw/DEFAULT_PFX/;
sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/archive/2004/6/27/ResourceResolver/>
}
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => URI_CONFIG,
  };

=head1 METHODS

=over 4

=item $res = I<ClassName>->new

Generates a new instance of I<ClassName>

=cut

sub new ($;%) {
  my $self = bless {}, shift;
  $self;
}

=item $result = $res->get_resource (options)

Gets resource specified as parameter and returns it.
Returned value C<$result> is a hash reference that
has resources and parameters retrived.

=cut

sub get_resource ($;%) {
  my ($self, %opt) = @_;
  
  return {ExpandedURI q<success> => 0};
}

=item $res->reset

Removes all "state" or configuration information stores on the resource resolver.

=cut

sub reset ($;%) {
  my $self = shift;
  for (keys %$self) {
    delete $self->{$_};
  }
}

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/06/27 06:34:07 $
