package Message::DOM::DOMImplementation;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMImplementation';

sub ____new ($) {
  my $self = bless {}, shift;
  return $self;
} # ____new

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  my $module_name = {
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
## DOMImplementation
sub create_document ($;$$$);
sub create_document_type ($$;$$);
## MCImplementation
sub create_mc_decode_handler;
sub get_charset_name_from_uri;
sub get_uri_from_charset_name;
## URIImplementation
sub create_uri_reference ($$);

#our $HasFeature;

## TODO: getFeature
## TODO: hasFeature

## NOTE: createDocumentType will be defined in DocumentType.pm

package Message::IF::DOMImplementation;

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/21 14:57:53 $
