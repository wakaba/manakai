#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-04-01T11:27:56+00:00,
## 	from file "GenericLS.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.GenericLS>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::DOM::DOMFeature;
package Message::DOM::GenericLS;
our $VERSION = 20060401.1127;
package Message::DOM::IFLatest::GLSImplementation;
our $VERSION = 20060401.1127;
package Message::DOM::GenericLS::ManakaiGLSImplementation;
our $VERSION = 20060401.1127;
push our @ISA, 'Message::DOM::DOMFeature::ManakaiMinimumImplementation',
'Message::DOM::IFLatest::GLSImplementation',
'Message::DOM::IFLatest::GetFeature',
'Message::DOM::IFLatest::MinimumImplementation';
sub create_gls_parser ($$) {
my ($self, $features) = @_;

{


{

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $__new = {};
    for my $__fname (keys %{$features}) {
      if (CORE::ref ($features->{$__fname}) eq 'HASH') {
        my $__lfname = lc $__fname;
        for my $__fver (keys %{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = $features->{$__fname}->{$__fver};
        }
      } elsif (CORE::ref ($features->{$__fname}) eq 'ARRAY') {
        my $__lfname = lc $__fname;
        for my $__fver (@{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = 
1
;
        }
      } else {
        $__new->{lc $__fname} = {(CORE::defined $features->{$__fname}
                                ? $features->{$__fname} : '') => 
1
};
      }
    }
    $features = $__new;
  } else {
    my @__f = split /\s+/, $features;
    my $__new = {};
    while (@__f) {
      my $__name = lc shift @__f;
      if (@__f and $__f[0] =~ /^[\d\.]+$/) {
        $__new->{$__name}->{shift @__f} = 1;
      } else {
        $__new->{$__name}->{''} = 1;
      }
    }
    $features = $__new;
  }
} else {
  $features = {};
}


;}

;


;}
my $r;

{

CLS: 
for my $class (grep {
  $Message::DOM::DOMLS::ParserClass{$_}
} keys %Message::DOM::DOMLS::ParserClass) {
  for my $fname (keys %$features) {
    my $fkey = $fname;
    #my $plus = $fname =~ s/^\+// ? t rue : f alse;
    FVER: for my $fver (grep {$features->{$fkey}->{$_}}
                           keys %{$features->{$fkey}}) {
      if ($Message::DOM::DOMFeature::ClassInfo->{$class}
              ->{has_feature}->{$fname}->{$fver}) {
        next FVER; # Feature/version found
      }
      next CLS; # Not found
    } # FVER
  } # FNAME

  ## Class found
  $r = $class->new ($self, $features);
  last CLS;    ## NOTE: Method name directly written
} # CLS


;}
$r}
sub create_gls_serializer ($$) {
my ($self, $features) = @_;

{


{

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $__new = {};
    for my $__fname (keys %{$features}) {
      if (CORE::ref ($features->{$__fname}) eq 'HASH') {
        my $__lfname = lc $__fname;
        for my $__fver (keys %{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = $features->{$__fname}->{$__fver};
        }
      } elsif (CORE::ref ($features->{$__fname}) eq 'ARRAY') {
        my $__lfname = lc $__fname;
        for my $__fver (@{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = 
1
;
        }
      } else {
        $__new->{lc $__fname} = {(CORE::defined $features->{$__fname}
                                ? $features->{$__fname} : '') => 
1
};
      }
    }
    $features = $__new;
  } else {
    my @__f = split /\s+/, $features;
    my $__new = {};
    while (@__f) {
      my $__name = lc shift @__f;
      if (@__f and $__f[0] =~ /^[\d\.]+$/) {
        $__new->{$__name}->{shift @__f} = 1;
      } else {
        $__new->{$__name}->{''} = 1;
      }
    }
    $features = $__new;
  }
} else {
  $features = {};
}


;}

;


;}
my $r;

{

CLS: 
for my $class (grep {
  $Message::DOM::DOMLS::SerializerClass{$_}
} keys %Message::DOM::DOMLS::SerializerClass) {
  for my $fname (keys %$features) {
    my $fkey = $fname;
    #my $plus = $fname =~ s/^\+// ? t rue : f alse;
    FVER: for my $fver (grep {$features->{$fkey}->{$_}}
                           keys %{$features->{$fkey}}) {
      if ($Message::DOM::DOMFeature::ClassInfo->{$class}
              ->{has_feature}->{$fname}->{$fver}) {
        next FVER; # Feature/version found
      }
      next CLS; # Not found
    } # FVER
  } # FNAME

  ## Class found
  $r = $class->new ($self, $features);
  last CLS;    ## NOTE: Method name directly written
} # CLS


;}
$r}
$Message::DOM::ImplFeature{q<Message::DOM::GenericLS::ManakaiGLSImplementation>}->{q<http://suika.fam.cx/www/2006/feature/genericls>}->{q<3.0>} ||= 1;
$Message::DOM::ImplFeature{q<Message::DOM::GenericLS::ManakaiGLSImplementation>}->{q<http://suika.fam.cx/www/2006/feature/genericls>}->{q<>} = 1;
$Message::DOM::ImplFeature{q<Message::DOM::GenericLS::ManakaiGLSImplementation>}->{q<http://suika.fam.cx/~wakaba/archive/2004/dom/ls#generic>}->{q<3.0>} ||= 1;
$Message::DOM::ImplFeature{q<Message::DOM::GenericLS::ManakaiGLSImplementation>}->{q<http://suika.fam.cx/~wakaba/archive/2004/dom/ls#generic>}->{q<>} = 1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::GenericLS::ManakaiGLSImplementation>}->{has_feature} = {'http://suika.fam.cx/www/2006/feature/genericls',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/www/2006/feature/min',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#generic',
{'',
'1',
'3.0',
'1'}};
$Message::DOM::ClassPoint{q<Message::DOM::GenericLS::ManakaiGLSImplementation>} = 6;
$Message::DOM::ManakaiDOMImplementationSource::SourceClass{q<Message::DOM::GenericLS::ManakaiGLSImplementation>} = 1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{compat_class}->{q<Message::DOM::GenericLS::ManakaiGLSImplementation>} = 1;
$Message::Util::Grove::ClassProp{q<Message::DOM::GenericLS::ManakaiGLSImplementation>} = {'v1h',
['lpmi']};
for ($Message::DOM::IFLatest::GetFeature::, $Message::DOM::IFLatest::MinimumImplementation::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;