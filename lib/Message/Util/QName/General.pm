
=head1 NAME

Message::Util::QName::General - manakai: QName utilities

=head1 DESCRIPTION

C<Message::Util::QName::General> module provides some utility functions
to handle QNames and URI references in Perl scripts.  These functions
might be useful in some kind of Perl scripts, whilst this module does
not intend to be used by scripts that does not use manakai.

This module is part of manakai.

=cut

package Message::Util::QName::General;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1.2.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Carp;
use Message::Markup::XML::QName;

=head1 SYNOPSIS

  use Message::Util::QName::General
      [I<function1>, I<function2>,...],  ## Functions to be exported
      {I<prefix1> => I<name1>,           ## Namespace bindings
       I<prefix2> => I<name2>,
       ...};

  $uri = ExpandedURI $qname;
  ($name, $local_name) = ExpandedName $qname;

First argument for C<use> operator is, off cource, name of this module.
Second required argument is an array reference that represents
function names to be exported from this module (imported to C<use>d package).
Each name must be of function provided by this module.

Third argument declares namespace bindings (namespace prefix to namespace name
associations).  Although this argument is optional, you would wish to specify it
in most case, since no binding other than C<DEFAULT_PFX> to C<NULL_URI>
is assumed in lack of the argument.

You might also wish to C<use> C<Message::Markup::XML::QName> to
use constant functions to specify namespace prefixs and/or namespace names.
For example:

  use Message::Markup::XML::QName qw(DEFAULT_PFX NS_xml_URI);
  use Message::Util::QName::General [qw/ExpandedURI/], {
    (DEFAULT_PFX) => q<http://foo.example/>,
    xml => NS_xml_URI,
  };

=cut

sub import ($$;$) {
  my $self = bless {}, shift;
  my ($name, $map) = @_;
  Carp::croak "Imported operators must be specified"
    unless ref $name;
  Carp::croak "Namespace map must be specified" unless ref $map;
  $self->{ns} = $map;
  my $caller = caller ($Exporter::ExportLevel);
  no strict 'refs';
  for (@$name) {
    if ($_ eq 'ExpandedURI') {
      *{ $caller . '::' . $_ } = sub ($) {
        scalar $self->expanded_name (@_);
      };
    } elsif ($_ eq 'ExpandedName') {
      *{ $caller . '::' . $_ } = sub ($) {
        $self->expanded_name (@_);
      };
    } else {
      Carp::croak "$_: Function not found";
    }
  }
}

=head1 FUNCTIONS

This module can export two functions:

=over 4

=item $uri = ExpandedURI $qname

Resolves given QName and returns as a URI reference.
Like RDF/N3, empty string is also allowed as namespace prefix
and it is resolved with C<EMPTY_PFX>.  (For example, QName C<:foo>
is expanded to (I<Namespace name for C<EMPTY_PFX>>, C<foo>).)

Local name part of QName SHOULD contain only US-ASCII characters so
that result URI reference would be valid, whilst validness of the URI 
reference is not checked by this function.

=item I<result> = ExpandedName $qname

Resolves given QName and returns as an expanded name.
In list context, a C<($name, $local_name)> pair is returned,
whilst a URI reference is returned (ie. same effect as C<ExpandedURI>) 
in scalar context.

=back

=cut

sub expanded_name ($$) {
  my ($self, $qname) = @_;
  my $chk = $self->{cache}->{$qname}
        ||= Message::Markup::XML::QName::qname_to_expanded_name (
              $self,
              $qname,
              use_prefix_empty => 1,
            );
  if ($chk->{success}) {
    wantarray ?
      ($chk->{name}, $chk->{local_name})
        : 
      $chk->{name} . $chk->{local_name};
  } else {
    Carp::croak "Bad QName: ".$chk->{reason};
  }
}

=head1 EXAMPLE

  use Message::Util::QName::General
      [qw(ExpandedName ExpandedURI)], ## Functions to be exported
      {                               ## Namespace bindings
        prefix1 => q<http://www.prefix.example/1#>,
        prefix2 => q<http://www.prefix.example/2#>,
      };

  $uri = ExpandedURI q<prefix1:local-name>;
    # q<http://www.prefix.example/1#local-name>
  
  ($name, $local_name) = ExpandedName q<prefix2:local-name>;
    # (q<http://www.prefix.example/2#>, q<local-name>)

=head1 SEE ALSO

C<Message::Markup::XML::QName>

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/05/23 04:02:48 $
