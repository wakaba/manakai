#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-12-30T08:05:51+00:00,
## 	from file "DOMFeature.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.DOMFeature>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#all>.
## Don't edit by hand!
use strict;
package Message::DOM::DOMFeature;
our $VERSION = 20061230.0805;
package Message::DOM::IF::GetFeature;
our $VERSION = 20061230.0805;
package Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature;
our $VERSION = 20061230.0805;
push our @ISA, 'Message::DOM::IF::GetFeature';
sub has_feature ($$;$) {
my ($self, $feature, $version) = @_;

{


$feature = lc $feature;


}

{


$version = '' unless defined $version;


}
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$gf = $self->
get_feature
 ($feature, $version);
  if ($feature =~ /^\+/) {
    $r = defined $gf;
  } else {
    $r = ref $gf eq ref $self;
  }



}


;}

;


}
$r}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature>}->{has_feature} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature>} = 0;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
