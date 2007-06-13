package Message::DOM::DOMImplementation;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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
    create_uri_reference => 'Message::URI::URIReference',  
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
## URIImplementation
sub create_uri_reference ($$);

#our $HasFeature;

## TODO: getFeature
## TODO: hasFeature

## NOTE: createDocumentType will be defined in DocumentType.pm

package Message::IF::DOMImplementation;

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/13 12:04:50 $
