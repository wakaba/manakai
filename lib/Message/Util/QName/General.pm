package Message::Util::QName::General;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Carp;

sub import ($$$) {
  my ($self, $name, $map) = @_;
  Carp::croak (__PACKAGE__.": Importing operator names must be specified")
      unless ref $name;
  $map ||= {};
  my $caller = caller ($Exporter::ExportLevel);
  no strict 'refs';
  for (@$name) {
    if ($_ eq 'ExpandedURI') {
      *{ $caller . '::' . $_ } = sub ($) {
        my ($prefix, $lname) = split /:/, shift, 2;
        if (defined $lname) {
          if (defined $map->{$prefix}) {
            return $map->{$prefix} . $lname;
          } else {
            Carp::croak (__PACKAGE__.": $prefix: Namespace prefix not declared");
          }
        } else {  ## Default namespace (bound to empty URI)
          return $prefix;
        }
      };
    } else {
      Carp::croak (__PACKAGE__.": $_: Function not found");
    }
  }
} # import

1; # $Date: 2004/11/20 11:12:50 $
__END__

=head1 NAME

Message::Util::QName::General - manakai: QName utilities

=head1 SYNOPSIS

  use Message::Util::QName::General [qw/ExpandedURI/], {
    prefix1 => q<URI reference 1>,
    prefix2 => q<URI reference 2>,
    ...
  };

  my $uri = ExpandedURI q<prefix1:local-name>;

=head1 DESCRIPTION

C<Message::Util::QName::General> module provides the C<ExpandedURI> 
operator that expands a qualified name (QName) into URI reference. 

NOTE:  In this module, the term "QName" is defined roughly than that 
of XML Namespaces - a QName is simply a pair of optional 
no-COLON string (namespace prefix) and no-COLON string (local name) 
separated by a COLON, i.e. 

  QName            := [namespace-prefix ":"] local-name.
  namespace-prefix := NCName.
  local-name       := NCName.
  NCName           := 0*<any Perl "character">.

This module is part of manakai.

=head1 USING PARARAMETERS

First argument for C<use> operator is the name of this module,
i.e. C<Message::Util::QName::General>.
Second required argument is an array reference that represents
function names to be exported from this module (import to C<use>ing package).
Currenly only C<ExpandedURI> is the valid function name.

Third argument declares namespace bindings (namespace prefix to namespace URI 
associations). 

Note that unlike XML Namespaces, no namespace prefix nor no namespace URI 
is reserved in this module - e.g. you can bound C<xml> prefix to 
C<http://foo.example/> if you want.  Even when you wish to bind 
that prefix to the standard URI reference, you must explicitly associate 
them by the third argument.

=head1 FUNCTION

The only function (operator) defined in this module is 
C<ExpandedURI>. 

=over 4

=item $uri = ExpandedURI q<QName>

Expands a QName into URI reference.  Namespace prefix of the QName, 
if any, is expanded to a URI reference bound to it and 
that URI reference is inserted in place of namespace prefix and 
delimiting COLON character.  

Default namespace is always bound 
to empty string.  For example, QName C<foo> is always expanded 
to C<foo>.  Don't confuse default namespace and empty prefix; 
QName C<:foo> is expanded to C<http://foo.example/foo> if 
the empty prefix is bound to C<http://foo.example/>.

=back

=head1 EXAMPLE

  use Message::Util::QName::General
      [qw(ExpandedURI)], ## Function to import
      {                  ## Namespace bindings
        prefix1 => q<http://www.prefix.example/1#>,
        prefix2 => q<http://www.prefix.example/2#>,
      };

  $uri = ExpandedURI q<prefix1:local-name>;
    # q<http://www.prefix.example/1#local-name>

=head1 SEE ALSO

L<Message::Util::QName::Filter>.

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
