#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-03-31T13:54:43+00:00,
## 	from file "DOMFeature.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.DOMFeature>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::Util::Error::DOMException;
package Message::DOM::DOMFeature;
our $VERSION = 20060331.1354;
$Message::DOM::ImplementationRegistry = 'Message::DOM::DOMFeature::ImplementationRegistry';
package Message::DOM::DOMFeature::ImplementationRegistry;
our $VERSION = 20060331.1354;
push our @ISA, 'Message::DOM::IFLatest::ImplementationSource',
'Message::DOM::IFLevel3::ImplementationSource';
sub get_implementation ($$) {
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


{

my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname;
    push @out, $fver if length $fver;
  }
}
$features = join ' ', @out;


;}

;


{

local $Error::Depth = $Error::Depth + 1;

{


  C: 
for my $class (
    keys %Message::DOM::ManakaiDOMImplementationRegistry::SourceClass
  ) {
    if ($class->isa (
'Message::DOM::IFLatest::ImplementationSource'
)) {
      $r = $class->
get_implementation
 ($features);
    } else {
      $r = $class->
get_dom_implementation
 ($features);
    }
    last C if defined $r;
  }



;}


;}

;


;}
$r}
sub get_dom_implementation ($$) {
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


$features->{core}->{'3.0'} = 
1
;


{

my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname;
    push @out, $fver if length $fver;
  }
}
$features = join ' ', @out;


;}

;


{

local $Error::Depth = $Error::Depth + 1;

{


  C: 
for my $class (
    keys %Message::DOM::ManakaiDOMImplementationRegistry::SourceClass
  ) {
    $r = $class->
get_dom_implementation
 ($features);
    last C if defined $r;
  }



;}


;}

;


;}
$r}
sub get_implementation_list ($$) {
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


{

my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname;
    push @out, $fver if length $fver;
  }
}
$features = join ' ', @out;


;}

;


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = 
Message::DOM::DOMFeature::ManakaiImplementationList
->new;
  for my $class (
    keys %Message::DOM::ManakaiDOMImplementationRegistry::SourceClass
  ) {
    if ($class->isa (
'Message::DOM::IFLatest::ImplementationSource'
)) {
      $r->
append_items

              ($class->
get_implementation_list
 ($features));
    } else {
      $r->
append_items

              ($class->
get_dom_implementation_list
 ($features));
    }
  }



;}


;}

;


;}
$r}
sub get_dom_implementation_list ($$) {
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


$features->{core}->{'3.0'} = 
1
;


{

my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname;
    push @out, $fver if length $fver;
  }
}
$features = join ' ', @out;


;}

;


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = 
Message::DOM::DOMFeature::ManakaiImplementationList
->new;
  for my $class (
    keys %Message::DOM::ManakaiDOMImplementationRegistry::SourceClass
  ) {
    $r->
append_items

              ($class->
get_dom_implementation_list
 ($features));
  }



;}


;}

;


;}
$r}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ImplementationRegistry>}->{has_feature} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ImplementationRegistry>} = 0;
package Message::DOM::IFLatest::ImplementationList;
our $VERSION = 20060331.1354;
package Message::DOM::DOMFeature::ManakaiImplementationList;
our $VERSION = 20060331.1354;
push our @ISA, 'Message::DOM::IF::ImplementationList',
'Message::DOM::IFLatest::ImplementationList',
'Message::DOM::IFLevel3::ImplementationList';
sub FETCH ($$) {
my ($self, $index) = @_;
my $r;

{

if 
(not defined $index or
    $index < 0 or
    $index > $#$self) {
  $r = 
undef
;
} else {
  $r = $self->[$index];
}


;}
$r}
*item = \&FETCH;
sub length ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = 0;

{


$r = @$self;


;}
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMFeature::ManakaiImplementationList', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'length';
}
}
sub new ($) {
my ($self) = @_;
my $r;

{


$r = bless [], ref $self ? ref $self : $self;


;}
$r}
sub append_items ($$) {
my ($self, $list) = @_;

{

if 
($list->isa (
'Message::DOM::IFLatest::ImplementationList'
)) {
  push @$self, @$list;
} else {
  push @$self, $list;
}


;}
}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ManakaiImplementationList>}->{has_feature} = {'http://suika.fam.cx/www/2006/feature/min',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum',
{'',
'1',
'3.0',
'1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiImplementationList>} = 3;
package Message::DOM::IFLatest::ImplementationSource;
our $VERSION = 20060331.1354;
package Message::DOM::DOMFeature::ManakaiImplementationSource;
our $VERSION = 20060331.1354;
push our @ISA, 'Message::DOM::IF::ImplementationSource',
'Message::DOM::IFLatest::ImplementationSource',
'Message::DOM::IFLevel3::ImplementationSource';
sub get_implementation ($$) {
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

my 
$debug = $Message::DOM::DOMFeature::DEBUG
          ? sub ($@) { print STDERR (('  ' x shift), @_) }
          : sub ($@) {};
CLS: for my $class (grep {
  $Message::DOM::ManakaiDOMImplementationSource::SourceClass{$_}
} keys %Message::DOM::ManakaiDOMImplementationSource::SourceClass) {
  $debug->(1, qq<Class "$class"...\n>);
  

{

unless 
($Message::DOM::ClassISA{$class}) {
  no strict 'refs';
  my %__class;
  my @__chk = ($class);
  while (my $__chk = shift @__chk) {
    $__class{$__chk} = 
1
;
    for my $__isa (@{$__chk . '::ISA'}) {
      if ($__isa !~ /::IF(?:Level.|Latest)?::/ and 
          not $__class{$__isa}) {
        push @__chk, $__isa;
      }
    }
  }
  $Message::DOM::ClassISA{$class} = [keys %__class];
}


;}

;
  for my $fname (keys %$features) {
    my $fkey = $fname;
    my $plus = $fname =~ s/^\+// ? 
1 : 

0
;
    $debug->(2, qq<Feature "$fname">, ($plus?'+':''), qq<,\n>);
    FVER: for my $fver (grep {$features->{$fkey}->{$_}}
                           keys %{$features->{$fkey}}) {
      $debug->(3, qq<version "$fver"...\n>);
      for my $cls ($class, @{$Message::DOM::ClassISA{$class}}) {
        if ($Message::DOM::ImplFeature{$class}->{$fname}->{$fver} ||=
               ## (Caching)
            $Message::DOM::ImplFeature{$cls}->{$fname}->{$fver}) {
          $debug->(4, qq<found in "$cls"\n>);
          next FVER; # Feature/version found
        }
      }

      if ($plus) {
        if ($Message::DOM::ManakaiDOMImplementation::CompatClass{
              $class}) {
          my %compat_cls;
          for my $cls (grep {
            $Message::DOM::ManakaiDOMImplementation::CompatClass{
            $_}
          } keys
          %Message::DOM::ManakaiDOMImplementation::CompatClass) {
            next if $compat_cls{$cls};
            

{

unless 
($Message::DOM::ClassISA{$cls}) {
  no strict 'refs';
  my %__class;
  my @__chk = ($cls);
  while (my $__chk = shift @__chk) {
    $__class{$__chk} = 
1
;
    for my $__isa (@{$__chk . '::ISA'}) {
      if ($__isa !~ /::IF(?:Level.|Latest)?::/ and 
          not $__class{$__isa}) {
        push @__chk, $__isa;
      }
    }
  }
  $Message::DOM::ClassISA{$cls} = [keys %__class];
}


;}

;
            for my $c (@{$Message::DOM::ClassISA{$cls}}) {
              $compat_cls{$c} = 
1
;
            }                 
          }
          for my $cls (keys %compat_cls) {
            if ($Message::DOM::ImplFeature{$cls}
                  ->{$fname}->{$fver}) {
              $debug->(4, qq<found+ in "$cls"\n>);
              next FVER; # +Feature/ver found
            }
          }
        }
      }
      $debug->(2, qq<not found\n>);
      next CLS; # Not found
    } # FVER
  } # FNAME

  ## Class found
  $r = $class->_new;
  last CLS;    ## NOTE: Method name directly written
} # CLS


;}
$r}
sub get_dom_implementation ($$) {
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


$features->{'core'}->{'3.0'} = 
1
;


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
get_implementation
 ($features);



;}


;}

;


;}
$r}
sub get_implementation_list ($$) {
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


$r = 
'Message::DOM::DOMFeature::ManakaiImplementationList'
->new;
CLS: for my $class (grep {
  $Message::DOM::ManakaiDOMImplementationSource::SourceClass{$_}
} keys %Message::DOM::ManakaiDOMImplementationSource::SourceClass) {
  

{

unless 
($Message::DOM::ClassISA{$class}) {
  no strict 'refs';
  my %__class;
  my @__chk = ($class);
  while (my $__chk = shift @__chk) {
    $__class{$__chk} = 
1
;
    for my $__isa (@{$__chk . '::ISA'}) {
      if ($__isa !~ /::IF(?:Level.|Latest)?::/ and 
          not $__class{$__isa}) {
        push @__chk, $__isa;
      }
    }
  }
  $Message::DOM::ClassISA{$class} = [keys %__class];
}


;}

;
  for my $fname (keys %$features) {
    my $fkey = $fname;
    my $plus = $fname =~ s/^\+// ? 
1 : 

0
;
    FVER: for my $fver (grep {$features->{$fkey}->{$_}}
                           keys %{$features->{$fkey}}) {
      for my $cls ($class, @{$Message::DOM::ClassISA{$class}}) {
        if ($Message::DOM::ImplFeature{$class}->{$fname}->{$fver} ||=
               ## (Caching)
            $Message::DOM::ImplFeature{$cls}->{$fname}->{$fver}) {
          next FVER; # Feature/version found
        }
      }

      if ($plus) {
        if ($Message::DOM::ManakaiDOMImplementation::CompatClass{
              $class}) {
          my %compat_cls;
          for my $cls (grep {
            $Message::DOM::ManakaiDOMImplementation::CompatClass{
            $_}
          } keys
          %Message::DOM::ManakaiDOMImplementation::CompatClass) {
            next if $compat_cls{$cls};
            

{

unless 
($Message::DOM::ClassISA{$cls}) {
  no strict 'refs';
  my %__class;
  my @__chk = ($cls);
  while (my $__chk = shift @__chk) {
    $__class{$__chk} = 
1
;
    for my $__isa (@{$__chk . '::ISA'}) {
      if ($__isa !~ /::IF(?:Level.|Latest)?::/ and 
          not $__class{$__isa}) {
        push @__chk, $__isa;
      }
    }
  }
  $Message::DOM::ClassISA{$cls} = [keys %__class];
}


;}

;
            for my $c (@{$Message::DOM::ClassISA{$cls}}) {
              $compat_cls{$c} = 
1
;
            }                 
          }
          for my $cls (keys %compat_cls) {
            if ($Message::DOM::ImplFeature{$cls}
                  ->{$fname}->{$fver}) {
              next FVER; # +Feature/ver found
            }
          }
        }
      }
      next CLS; # Not found
    } # FVER
  } # FNAME

  ## Class found
  push @$r, $class->_new;
  last CLS;                 ## NOTE: Method name directly written
} # CLS


;}
$r}
sub get_dom_implementation_list ($$) {
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


{

local $Error::Depth = $Error::Depth + 1;

{



  $features->{core}->{'3.0'} = 
1
;
  $r = $self->
get_implementation_list
 ($features);



;}


;}

;


;}
$r}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ManakaiImplementationSource>}->{has_feature} = {'http://suika.fam.cx/www/2006/feature/min',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum',
{'',
'1',
'3.0',
'1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiImplementationSource>} = 3;
$Message::DOM::ManakaiDOMImplementationRegistry::SourceClass{q<Message::DOM::DOMFeature::ManakaiImplementationSource>} = 1;
package Message::DOM::IFLatest::MinimumImplementation;
our $VERSION = 20060331.1354;
package Message::DOM::DOMFeature::ManakaiMinimumImplementation;
our $VERSION = 20060331.1354;
push our @ISA, 'Message::DOM::IF::GetFeature',
'Message::DOM::IF::MinimumImplementation',
'Message::DOM::IFLatest::GetFeature',
'Message::DOM::IFLatest::MinimumImplementation',
'Message::DOM::IFLevel3::GetFeature',
'Message::DOM::IFLevel3::MinimumImplementation';
sub ___create_node_stem ($$$) {
my ($self, $bag, $obj) = @_;
my $r;

{


$obj->{
'lpmi'
} = {};
$r = $obj;


;}
$r}
sub ___create_node_ref ($$) {
my ($self, $obj) = @_;
my $r;

{


$r = bless $obj, $self;


;}
$r}
sub _new ($) {
my ($self) = @_;
my $r;

{

my 
$bag;


{


$bag = {
  
'm'
 => [],
};


;}

;
my $stem;


{


$stem = $self->___create_node_stem ($bag, {
  
'rc'
 => 0,
  
'id'
 => \
(
  'tag:suika.fam.cx,2005-09:' . time . ':' . $$ . ':' .
  ($Message::Util::ManakaiNode::UniqueIDR ||=
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62]) .
  (++$Message::Util::ManakaiNode::UniqueIDN)
)
,
}, {});


{

if 
(defined $self) {
  if (ref $self eq 'SCALAR') {
    $stem->{'cls'} = $self;
  } elsif (defined $Message::Util::ManakaiStringRef::Value{$self}) {
    $stem->{'cls'} = $Message::Util::ManakaiStringRef::Value{$self};
  } else {
    require Scalar::Util;
    $stem->{'cls'} = $Message::Util::ManakaiStringRef::Value{$self} = \($self);
    Scalar::Util::weaken ($Message::Util::ManakaiStringRef::Value{$self});
  }
} else {
  CORE::delete $stem->{'cls'};
}


;}

;
$bag->{${$stem->{
'id'
}}} = $stem;


;}

;


{


$r = ${$stem->{
'cls'
}}->___create_node_ref ({
  
'id'
 => $stem->{
'id'
},
  
'b'
 => $bag,
}, {});
$stem->{
'rc'
}++;


;}

;


;}
$r}
sub DESTROY ($) {
my ($self) = @_;

{

my 
$id = $self->{
'id'
};
my $bag = $self->{
'b'
};
if (--$bag->{$$id}->{
'rc'
} < 1) {
  push @{$bag->{
'm'
}}, $id;
  if (@{$bag->{
'm'
}}
          > ($Message::Util::Grove::GCLatency or 0)) {
    

{

my 
$bag = $self->{
'b'
};
my @target = @{$bag->{
'm'
}};
my %done;
my %has_xref;
TARGET: while (@target) {
  my $target = shift @target;

  next TARGET if $has_xref{$$target} or $done{$$target};

  unless (defined $bag->{$$target}) {
    $done{$$target} = 
1
;
    next TARGET;
  }

  my %grove;
  my @gtarget = ($target);
  my @gwreferred;
  GTARGET: while (@gtarget) {
    my $gtarget = shift @gtarget;
    next GTARGET if $grove{$$gtarget};

    my $gtstem = $bag->{$$gtarget};
    unless (defined $gtstem) {
      $done{$$gtarget} = 
1
;
      next GTARGET;
    }

    if ($has_xref{$$gtarget} or $gtstem->{
'rc'
}) {
      $has_xref{$$gtarget} = 
1
;
      $has_xref{$_} = 
1 for 
keys %grove;
      for (@gtarget) {
        $has_xref{$$_} = defined $bag->{$$_};
        $done{$$_} = 
1
;
      }
      next TARGET;
    } elsif ($done{$$gtarget}) {
      next GTARGET;
    }

    my $clsprop = $Message::Util::Grove::ClassProp{
                    ${$gtstem->{
'cls'
}}
                  };

    for my $key (@{$clsprop->{
'o0'
}}) {
      push @gtarget, $gtstem->{$key} if ref $gtstem->{$key};
    }

    A: for my $key ((@{$clsprop->{
'v1h'
}}),
                    (@{$clsprop->{
's1h'
}})) {
      next A unless ref $gtstem->{$key};
      push @gtarget, grep {ref $_} values %{$gtstem->{$key}};
    }

    A: for my $key (@{$clsprop->{
's1a'
}}) {
      next A unless ref $gtstem->{$key};
      push @gtarget, grep {ref $_} @{$gtstem->{$key}};
    }

    A: for my $key (@{$clsprop->{
's2hh'
}}) {
      next A unless ref $gtstem->{$key};
      B: for my $key2 (keys %{$gtstem->{$key}}) {
        next B unless ref $gtstem->{$key}->{$key2};
        push @gtarget, grep {ref $_} values %{$gtstem->{$key}->{$key2}};
      }
    }

    for my $key (@{$clsprop->{
'w0'
}}) {
      push @gwreferred, $gtstem->{$key} if ref $gtstem->{$key};
    }

    $grove{$$gtarget} = 
1
;
  } # GTARGET

  for (keys %grove) {
    $done{$_} = 
1
;
    if (defined $bag->{$_}->{
'beforefree'
}) {
      $bag->{$_}->{
'beforefree'
}->($bag, $_);
    }
    delete $bag->{$_};
  }
  push @target, @gwreferred;
} # TARGET
$bag->{
'm'
} = [];


;}

;
  }
}


;}
}
sub has_feature ($$$) {
my ($self, $feature, $version) = @_;

{


$feature = lc $feature;


;}

{


$version = '' unless defined $version;


;}
my $r = 0;

{

my 
$plus = $feature =~ s/^\+// ? 1 : 0;
my $class = ref $self;
A: {
  if ($Message::DOM::DOMFeature::ClassInfo->{$class}
          ->{has_feature}->{$feature}->{$version}) {
    $r = 
1
;
    last A;
  } 
  

{

unless 
($Message::DOM::ClassISA{$class}) {
  no strict 'refs';
  my %__class;
  my @__chk = ($class);
  while (my $__chk = shift @__chk) {
    $__class{$__chk} = 
1
;
    for my $__isa (@{$__chk . '::ISA'}) {
      if ($__isa !~ /::IF(?:Level.|Latest)?::/ and 
          not $__class{$__isa}) {
        push @__chk, $__isa;
      }
    }
  }
  $Message::DOM::ClassISA{$class} = [keys %__class];
}


;}

;
  for my $cls ($class, @{$Message::DOM::ClassISA{$class}}) {
    if ($Message::DOM::ImplFeature{$class}->{$feature}->{$version}) {
      $r = 
1
;
       last A;
    }
  }

  if ($plus) {
    CLASS: for my $class (grep {
      $Message::DOM::DOMFeature::ClassInfo
          ->{
'Message::DOM::DOMFeature::ManakaiMinimumImplementation'
}
          ->{compat_class}->{$_}
    } keys %{$Message::DOM::DOMFeature::ClassInfo
                 ->{
'Message::DOM::DOMFeature::ManakaiMinimumImplementation'
}
                 ->{compat_class} or {}}) {
      for my $cls ($class, @{$Message::DOM::ClassISA{$class}}) {
        if ($Message::DOM::DOMFeature::ClassInfo->{$cls}
                ->{has_feature}->{$feature}->{$version}) {
          $r = 
1
;
          last A;
        } elsif ($Message::DOM::ImplFeature{$cls}
                     ->{$feature}->{$version}) {
          $r = 
1
;
          last A;
        }
      }
    }
  } # plus
} # A


;}
$r}
sub get_feature ($$$) {
my ($self, $feature, $version) = @_;

{


$feature = lc $feature;


;}

{


$version = '' unless defined $version;


;}
my $r;

{


$feature =~ s/^\+//;
if ($Message::DOM::DOMFeature::ClassInfo->{ref $self}
      ->{has_feature}->{$feature}->{$version}) {
  $r = $self;
} else {
  CLASS: for my $__class (sort {
    $Message::DOM::ClassPoint{$b} <=> $Message::DOM::ClassPoint{$a}
  } grep {
    $Message::DOM::DOMFeature::ClassInfo
        ->{
'Message::DOM::DOMFeature::ManakaiMinimumImplementation'
}
        ->{compat_class}->{$_}
  } keys %{$Message::DOM::DOMFeature::ClassInfo
               ->{
'Message::DOM::DOMFeature::ManakaiMinimumImplementation'
}
               ->{compat_class} or {}}) {
    ## Static
    if ($Message::DOM::DOMFeature::ClassInfo->{$__class}
            ->{has_feature}->{$feature}->{$version}) {
      

{


$r = ${($self->{'b'})->{${($self->{'id'})}}->{
'cls'
}}->___create_node_ref ({
  
'id'
 => ($self->{'id'}),
  
'b'
 => ($self->{'b'}),
}, {
          'nrcls' => \$__class,
        });
($self->{'b'})->{${($self->{'id'})}}->{
'rc'
}++;


;}

;
      last CLASS;
    } else {
      ## Dynamic
      

{

unless 
($Message::DOM::ClassISA{$__class}) {
  no strict 'refs';
  my %__class;
  my @__chk = ($__class);
  while (my $__chk = shift @__chk) {
    $__class{$__chk} = 
1
;
    for my $__isa (@{$__chk . '::ISA'}) {
      if ($__isa !~ /::IF(?:Level.|Latest)?::/ and 
          not $__class{$__isa}) {
        push @__chk, $__isa;
      }
    }
  }
  $Message::DOM::ClassISA{$__class} = [keys %__class];
}


;}

;
      for my $cls ($__class, @{$Message::DOM::ClassISA{$__class}}) {
        if ($Message::DOM::ImplFeature{$cls}->{$feature}->{$version}) {
          

{


$r = ${($self->{'b'})->{${($self->{'id'})}}->{
'cls'
}}->___create_node_ref ({
  
'id'
 => ($self->{'id'}),
  
'b'
 => ($self->{'b'}),
}, {
              'nrcls' => \$cls,
            });
($self->{'b'})->{${($self->{'id'})}}->{
'rc'
}++;


;}

;
          last CLASS;
        }
      }
    }
  } # CLASS
}


;}
$r}
use overload 
bool => sub () {1}, 
'eq' => sub ($;$) {
my ($self, $other) = @_;
my $r = 0;

{

if 
(UNIVERSAL::isa
      ($other,
       
'Message::DOM::IF::MinimumImplementation'
) and
    $other->isa ('HASH') and
    exists $other->{
'id'
}) {
  $r = ($other->{
'id'
}
            eq $self->{
'id'
});
}


;}
$r}
, 
fallback => 1;
$Message::DOM::ImplFeature{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{q<http://suika.fam.cx/www/2006/feature/min>}->{q<3.0>} ||= 1;
$Message::DOM::ImplFeature{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{q<http://suika.fam.cx/www/2006/feature/min>}->{q<>} = 1;
$Message::DOM::ImplFeature{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum>}->{q<3.0>} ||= 1;
$Message::DOM::ImplFeature{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum>}->{q<>} = 1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{has_feature} = {'http://suika.fam.cx/www/2006/feature/min',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum',
{'',
'1',
'3.0',
'1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = 3;
$Message::DOM::ManakaiDOMImplementationSource::SourceClass{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = 1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{compat_class}->{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = 1;
$Message::Util::Grove::ClassProp{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = {'v1h',
['lpmi']};
package Message::DOM::IFLatest::GetFeature;
our $VERSION = 20060331.1354;
package Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature;
our $VERSION = 20060331.1354;
push our @ISA, 'Message::DOM::IFLatest::GetFeature';
sub has_feature ($$;$) {
my ($self, $feature, $version) = @_;

{


$feature = lc $feature;


;}

{


$version = '' unless defined $version;


;}
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



;}


;}

;


;}
$r}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature>}->{has_feature} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature>} = 0;
for ($Message::DOM::IF::GetFeature::, $Message::DOM::IF::ImplementationList::, $Message::DOM::IF::ImplementationSource::, $Message::DOM::IF::MinimumImplementation::, $Message::DOM::IFLevel3::GetFeature::, $Message::DOM::IFLevel3::ImplementationList::, $Message::DOM::IFLevel3::ImplementationSource::, $Message::DOM::IFLevel3::MinimumImplementation::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
