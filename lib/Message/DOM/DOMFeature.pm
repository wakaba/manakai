#!/usr/bin/perl 
## This file is automatically generated
## 	at 2005-11-13T06:01:13+00:00,
## 	from file "lib/Message/DOM/DOMFeature.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.DOMFeature>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::Util::ManakaiNode;
package Message::DOM::DOMFeature;
our $VERSION = 20051113.0601;
$Message::DOM::ImplementationRegistry = 'Message::DOM::DOMFeature::ImplementationRegistry';
package Message::DOM::DOMFeature::ImplementationRegistry;
our $VERSION = 20051113.0601;
push our @ISA, 'Message::DOM::IFLatest::ImplementationSource', 'Message::DOM::IFLevel3::ImplementationSource';
sub get_implementation ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;


my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname . ' ' . $fver . ' ' if $features->{$fname}->{$fver};
  }
}
$features = join ' ', @out;


;


local $Error::Depth = $Error::Depth + 1;


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




;

$r}
sub get_dom_implementation ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;


$features->{core}->{'3.0'} = 
1
;


my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname . ' ' . $fver . ' ' if $features->{$fname}->{$fver};
  }
}
$features = join ' ', @out;


;


local $Error::Depth = $Error::Depth + 1;


  C: 
for my $class (
    keys %Message::DOM::ManakaiDOMImplementationRegistry::SourceClass
  ) {
    $r = $class->
get_dom_implementation
 ($features);
    last C if defined $r;
  }




;

$r}
sub get_implementation_list ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;


my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname . ' ' . $fver . ' ' if $features->{$fname}->{$fver};
  }
}
$features = join ' ', @out;


;


local $Error::Depth = $Error::Depth + 1;



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




;

$r}
sub get_dom_implementation_list ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;


$features->{core}->{'3.0'} = 
1
;


my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname . ' ' . $fver . ' ' if $features->{$fname}->{$fver};
  }
}
$features = join ' ', @out;


;


local $Error::Depth = $Error::Depth + 1;



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




;

$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMFeature::ImplementationRegistry>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ImplementationRegistry>} = 0;
package Message::DOM::IFLatest::ImplementationList;
our $VERSION = 20051113.0601;
package Message::DOM::DOMFeature::ManakaiImplementationList;
our $VERSION = 20051113.0601;
push our @ISA, 'Message::DOM::IF::ImplementationList', 'Message::DOM::IFLatest::ImplementationList', 'Message::DOM::IFLevel3::ImplementationList';
sub FETCH ($$) {
my ($self, $index) = @_;
my $r;

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

$r}
*item = \&FETCH;
sub length ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = 0;


$r = @$self;

$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMFeature::ManakaiImplementationList', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'length';
}
}
sub new ($) {
my ($self) = @_;
my $r;


$r = bless [], ref $self ? ref $self : $self;

$r}
sub append_items ($$) {
my ($self, $list) = @_;

if 
($list->isa (
'Message::DOM::IFLatest::ImplementationList'
)) {
  push @$self, @$list;
} else {
  push @$self, $list;
}

}
$Message::DOM::ClassFeature{q<Message::DOM::DOMFeature::ManakaiImplementationList>} = {'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum', {'', '1', '3.0', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiImplementationList>} = 3;
package Message::DOM::IFLatest::ImplementationSource;
our $VERSION = 20051113.0601;
package Message::DOM::DOMFeature::ManakaiImplementationSource;
our $VERSION = 20051113.0601;
push our @ISA, 'Message::DOM::IF::ImplementationSource', 'Message::DOM::IFLatest::ImplementationSource', 'Message::DOM::IFLevel3::ImplementationSource';
sub get_implementation ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;

my 
$debug = $Message::DOM::DOMFeature::DEBUG
          ? sub ($@) { print STDERR (('  ' x shift), @_) }
          : sub ($@) {};
CLS: for my $class (grep {
  $Message::DOM::ManakaiDOMImplementationSource::SourceClass{$_}
} keys %Message::DOM::ManakaiDOMImplementationSource::SourceClass) {
  $debug->(1, qq<Class "$class"...\n>);
  

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

$r}
sub get_dom_implementation ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;


$features->{'core'}->{'3.0'} = 
1
;


local $Error::Depth = $Error::Depth + 1;



  $r = $self->
get_implementation
 ($features);




;

$r}
sub get_implementation_list ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;


$r = 
'Message::DOM::DOMFeature::ManakaiImplementationList'
->new;
CLS: for my $class (grep {
  $Message::DOM::ManakaiDOMImplementationSource::SourceClass{$_}
} keys %Message::DOM::ManakaiDOMImplementationSource::SourceClass) {
  

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

$r}
sub get_dom_implementation_list ($$) {
my ($self, $features) = @_;

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}

my $r;


local $Error::Depth = $Error::Depth + 1;



  $features->{core}->{'3.0'} = 
1
;
  $r = $self->
get_implementation_list
 ($features);




;

$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMFeature::ManakaiImplementationSource>} = {'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum', {'', '1', '3.0', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiImplementationSource>} = 3;
$Message::DOM::ManakaiDOMImplementationRegistry::SourceClass{q<Message::DOM::DOMFeature::ManakaiImplementationSource>} = 1;
package Message::DOM::IFLatest::MinimumImplementation;
our $VERSION = 20051113.0601;
package Message::DOM::DOMFeature::ManakaiMinimumImplementation;
our $VERSION = 20051113.0601;
push our @ISA, 'Message::Util::ManakaiNode::ManakaiNodeRef', 'Message::DOM::IF::GetFeature', 'Message::DOM::IF::MinimumImplementation', 'Message::DOM::IFLatest::GetFeature', 'Message::DOM::IFLatest::MinimumImplementation', 'Message::DOM::IFLevel3::GetFeature', 'Message::DOM::IFLevel3::MinimumImplementation';
sub has_feature ($$$) {
my ($self, $feature, $version) = @_;


$feature = lc $feature;



$version = '' unless defined $version;

my $r = 0;

my 
$plus = $feature =~ s/^\+// ? 1 : 0;
my $class = ref $self;


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


;
if (defined $Message::DOM::ImplFeature{$class}
                    ->{$feature}->{$version}) {
  $r = $Message::DOM::ImplFeature{$class}
                    ->{$feature}->{$version};
} elsif ($plus) {
  CLASS: for my $class (grep {
    $Message::DOM::ManakaiDOMImplementation::CompatClass{$_}
  } keys %Message::DOM::ManakaiDOMImplementation::CompatClass) {
    for my $cls ($class, @{$Message::DOM::ClassISA{$class}}) {
      if ($Message::DOM::ImplFeature{$class}
                       ->{$feature}->{$version}) {
        $r = 
1
;
        last CLASS;
      }
    }
  }
}

$r}
sub get_feature ($$$) {
my ($self, $feature, $version) = @_;


$feature = lc $feature;



$version = '' unless defined $version;

my $r;


$feature =~ s/^\+//;
CLASS: for my $class (grep {
  $Message::DOM::ManakaiDOMImplementation::CompatClass{$_}
} keys %Message::DOM::ManakaiDOMImplementation::CompatClass) {
  

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


;
  for my $cls ($class, @{$Message::DOM::ClassISA{$class}}) {
    if ($Message::DOM::ImplFeature{$class}->{$feature}->{$version}) {
      


$self->{'node'}->{
'rc'
}++;
${$self->{'node'}->{
'grc'
}}++;
$r = bless {
  
'node'
 => $self->{'node'},
}, $class;


;
      last CLASS;
    }
  }
}

$r}
sub _new ($) {
my ($self) = @_;
my $r;

my 
$node = 
Message::Util::ManakaiNode::ManakaiNodeStem->_new

               ($self);



$node->{
'rc'
}++;
${$node->{
'grc'
}}++;
$r = bless {
  
'node'
 => $node,
}, $self;


;
$node->{
'implid'
} = $node->{
'nid'
};

$r}
$Message::DOM::ImplFeature{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum>}->{q<3.0>} ||= 1;
$Message::DOM::ImplFeature{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>}->{q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum>}->{q<>} = 1;
$Message::DOM::ClassFeature{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = {'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum', {'', '1', '3.0', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = 3;
$Message::DOM::ManakaiDOMImplementationSource::SourceClass{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = 1;
$Message::DOM::ManakaiDOMImplementation::CompatClass{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = 1;
$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{q<Message::DOM::DOMFeature::ManakaiMinimumImplementation>} = {};
package Message::DOM::IFLatest::GetFeature;
our $VERSION = 20051113.0601;
package Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature;
our $VERSION = 20051113.0601;
sub has_feature ($$;$) {
my ($self, $feature, $version) = @_;


$feature = lc $feature;



$version = '' unless defined $version;

my $r = 0;


local $Error::Depth = $Error::Depth + 1;



  $r = defined $self->
get_feature
 ($feature, $version)
       ? 
1 : 

0
;




;

$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMFeature::ManakaiHasFeatureByGetFeature>} = 0;
for ($Message::DOM::IF::GetFeature::, $Message::DOM::IF::ImplementationList::, $Message::DOM::IF::ImplementationSource::, $Message::DOM::IF::MinimumImplementation::, $Message::DOM::IFLevel3::GetFeature::, $Message::DOM::IFLevel3::ImplementationList::, $Message::DOM::IFLevel3::ImplementationSource::, $Message::DOM::IFLevel3::MinimumImplementation::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
