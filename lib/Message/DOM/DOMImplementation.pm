package Message::DOM::DOMImplementation;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.9 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMImplementation',
    'Message::IF::AtomDOMImplementation';

sub ____new ($) {
  my $self = bless {}, shift;
  return $self;
} # ____new
*new = \&____new;

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  my $module_name = {
    create_atom_entry_document => 'Message::DOM::Atom::AtomElement',
    create_atom_feed_document => 'Message::DOM::Atom::AtomElement',
    create_document => 'Message::DOM::DOMDocument', ## TODO: New module name
    create_document_type => 'Message::DOM::DocumentType',
    create_mc_decode_handler => 'Message::Charset::Encode',
    create_uri_reference => 'Message::URI::URIReference',  
    get_charset_name_from_uri => 'Message::Charset::Encode',
    get_uri_from_charset_name => 'Message::Charset::Encode',
  }->{$method_name};
  if ($module_name) {
    eval qq{ require $module_name } or die $@;
    no strict 'refs';
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## MCImplementation
sub create_mc_decode_handler;
sub get_charset_name_from_uri;
sub get_uri_from_charset_name;
## URIImplementation
sub create_uri_reference ($$);

our $HasFeature;
$HasFeature->{core}->{''} = 1;
$HasFeature->{core}->{'1.0'} = 1;
$HasFeature->{core}->{'2.0'} = 1;
$HasFeature->{core}->{'3.0'} = 1;
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

package Message::IF::DOMImplementation;
package Message::IF::AtomDOMImplementation;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/15 05:18:46 $
