package Message::DOM::DOMImplementation;
use strict;
use warnings;
our $VERSION = '1.14';
push our @ISA, 'Message::IF::DOMImplementation',
    'Message::IF::AtomDOMImplementation',
    'Message::IF::URIImplementation',
    'Message::IF::IMTImplementation';

sub ____new ($) {
  my $self = bless {}, shift;
  return $self;
} # ____new
*new = \&____new;

my $MethodToModule = {
  create_atom_entry_document => 'Message::DOM::Atom::AtomElement',
  create_atom_feed_document => 'Message::DOM::Atom::AtomElement',
  create_document => 'Message::DOM::Document',
  create_document_type => 'Message::DOM::DocumentType',
  create_uri_reference => 'Message::URI::URIReference',
  create_internet_media_type => 'Message::IMT::InternetMediaType',
};

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  my $module_name = $MethodToModule->{$method_name};
  if ($module_name) {
    eval qq{ require $module_name } or die $@;
    no strict 'refs';
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

our $HasFeature;
$HasFeature->{core}->{''} = 1;
$HasFeature->{core}->{'1.0'} = 1;
$HasFeature->{core}->{'2.0'} = 1;
$HasFeature->{core}->{'3.0'} = 1;
$HasFeature->{events}->{''} = 1;
$HasFeature->{events}->{'3.0'} = 1; ## TODO: 2.0?
$HasFeature->{html}->{''} = 1;
$HasFeature->{html}->{'5.0'} = 1; ## TODO: 1.0, 2.0
$HasFeature->{xhtml}->{''} = 1;
$HasFeature->{xhtml}->{'5.0'} = 1; ## TODO: 2.0
$HasFeature->{traversal}->{''} = 1;
$HasFeature->{traversal}->{'2.0'} = 1;
$HasFeature->{xml}->{''} = 1;
$HasFeature->{xml}->{'1.0'} = 1;
$HasFeature->{xml}->{'2.0'} = 1;
$HasFeature->{xml}->{'3.0'} = 1;
$HasFeature->{xmlversion}->{''} = 1;
$HasFeature->{xmlversion}->{'1.0'} = 1;
$HasFeature->{xmlversion}->{'1.1'} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/atom>}->{''} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/atom>}->{'1.0'} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/atomthreading>}->{''} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/atomthreading>}->{'1.0'} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/min>}->{''} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/min>}->{'3.0'} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/uri>}->{''} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/uri>}->{'4.0'} = 1;
$HasFeature->{q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum>}->{''} = 1;
$HasFeature->{q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum>}->{'3.0'} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/xdoctype>}->{''} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/xdoctype>}->{'3.0'} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/xdoctypedeclaration>}->{''} = 1;
$HasFeature->{q<http://suika.fam.cx/www/2006/feature/xdoctypedeclaration>}->{'3.0'} = 1;

sub ___report_error { $_[1]->throw }

## |DOMImplementation| methods

sub create_document ($;$$$);

sub create_document_type ($$$$);

sub get_feature ($$;$) {
  my $feature = lc $_[1]; ## TODO: What |lc|?
  $feature =~ s/^\+//;
  
  if ($HasFeature->{$feature}->{defined $_[2] ? $_[2] : ''}) {
    return $_[0];
  } else {
    return undef;
  }
} # get_feature

sub has_feature ($$;$) {
  my $feature = lc $_[1];
  my $plus = $feature =~ s/^\+// ? 1 : 0;
  return $HasFeature->{$feature}->{defined $_[2] ? $_[2] : ''};
} # has_feature

## |AtomDOMImplementation| methods

sub create_atom_entry_document ($$;$$);

sub create_atom_feed_document ($$;$$);

## |URIImplementation| method

sub create_uri_reference ($$);

## |InternetMediaType| method

sub create_internet_media_type ($$$);

package Message::IF::DOMImplementation;
package Message::IF::AtomDOMImplementation;
package Message::IF::URIImplementation;
package Message::IF::IMTImplementation;

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
