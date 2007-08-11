package Message::URI::URIReference;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::IF::URIImplementation;
package Message::DOM::DOMImplementation;
push our @ISA, 'Message::IF::URIImplementation';

sub create_uri_reference ($$) {
  if (UNIVERSAL::isa ($_[1], 'Message::IF::URIReference')) {
    local $Error::Depth = $Error::Depth + 1;
    my $uri = $_[1]->uri_reference;
    return bless \$uri, 'Message::URI::URIReference';
  } elsif (ref $_[1] eq 'SCALAR') {
    my $uri = ''.${$_[1]};
    return bless \$uri, 'Message::URI::URIReference';
  } else {
    my $uri = ''.$_[1];
    return bless \$uri, 'Message::URI::URIReference';
  }
} # create_uri_reference

package Message::IF::URIReference;
package Message::URI::URIReference;
push our @ISA, 'Message::IF::URIReference';

sub uri_reference ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


$r = $$self;


}
$r;
} else {my ($self, $given) = @_;

{


$$self = $given;


{

local $Error::Depth = $Error::Depth + 1;

{



  $self->
_on_scheme_changed
;



}


;}

;


}
}
}
sub stringify ($) {
my ($self) = @_;
my $r = '';

{


$r = $$self;


}
$r}
sub _on_scheme_changed ($) {
my ($self) = @_;


}
sub _on_authority_changed ($) {
my ($self) = @_;


}
sub _on_path_changed ($) {
my ($self) = @_;


}
sub _on_query_changed ($) {
my ($self) = @_;


}
sub _on_fragment_changed ($) {
my ($self) = @_;


}
sub uri_scheme ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

if 
($$self =~ m!^([^/?#:]+):!) {
  $r = $1;
} else {
  $r = 
undef
;
}


}
$r;
} else {my ($self, $given) = @_;

{

if 
(defined $given) {
  if (length $given and $given !~ m![/?#:]!) {
    unless ($$self =~ s!^[^/?#:]+:!$given:!) {
      $$self = $given . ':' . $$self;
      

{

local $Error::Depth = $Error::Depth + 1;

{



        $self->
_on_scheme_changed
;
      


}


;}

;
    }
  }
} else {
  $$self =~ s!^[^/?#:]+:!!;
  

{

local $Error::Depth = $Error::Depth + 1;

{



    $self->
_on_scheme_changed
;
  


}


;}

;
}


}
}
}
sub uri_authority ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

if 
($$self =~ m!^(?:[^:/?#]+:)?(?://([^/?#]*))?!) {
  $r = $1;
} else {
  $r = 
undef
;
}


}
$r;
} else {my ($self, $given) = @_;

{

if 
(defined $given) {
  unless ($given =~ m![/?#]!) {
    unless ($$self =~ s!^((?:[^:/?#]+:)?)(?://[^/?#]*)?!$1//$given!) {
      $$self = '//' . $given;
      

{

local $Error::Depth = $Error::Depth + 1;

{



        $self->
_on_authority_changed
;
      


}


;}

;
    }
  }
} else {
  if ($$self =~ s!^((?:[^:/?#]+:)?)(?://[^/?#]*)?!$1!) {
    

{

local $Error::Depth = $Error::Depth + 1;

{



      $self->
_on_authority_changed
;
    


}


;}

;
  }
}


}
}
}
sub uri_userinfo ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$v = $self->
uri_authority
;
  if (defined $v and $v =~ /^([^@\[\]]*)\@/) {
    $r = $1;
  } else {
    $r = 
undef
;
  }



}


;}

;


}
$r;
} else {my ($self, $given) = @_;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$auth = $self->
uri_authority
;
  if (defined $auth) {
    if (defined $given) {
      unless ($auth =~ s/^[^\@\[\]]*\@/$given\@/) {
        $auth = $given . '@' . $auth;
      }
    } else {
      $auth =~ s/^[^\@\[\]]*\@//;
    }
    $self->
uri_authority
 ($auth);
  } else {
    if (defined $given and $given !~ /[\/#?\@\[\]]/) {
      $self->
uri_authority
 ($given.'@');
    }
  }



}


;}

;


}
}
}
sub uri_host ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$v = $self->
uri_authority
;
  if (defined $v) {
    $v =~ s/^[^@\[\]]*\@//;
    $v =~ s/:[0-9]*\z//;
    $r = $v;
  } else {
    $r = 
undef
;
  }



}


;}

;


}
$r;
} else {my ($self, $given) = @_;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$auth = $self->
uri_authority
;
  if (defined $auth) {
    my $v = '';
    if ($auth =~ /^([^\@\[\]]*\@)/) {
      $v .= $1;
    }
    $v .= $given;
    if ($auth =~ /(:[0-9]*)\z/) {
      $v .= $1;
    }
    $self->
uri_authority
 ($v);
  } elsif ($given !~ /[\/\@:#?]/) {
    $self->
uri_authority
 ($given);
  }



}


;}

;


}
}
}
sub uri_port ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$v = $self->
uri_authority
;
  if (defined $v and $v =~ /:([0-9]*)\z/) {
    $r = $1;
  } else {
    $r = 
undef
;
  }



}


;}

;


}
$r;
} else {my ($self, $given) = @_;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$auth = $self->
uri_authority
;
  if (defined $auth) {
    if (defined $given) {
      unless ($auth =~ s/:[0-9]*\z/:$given/) {
        $auth = $auth . ':' . $given;
      }
    } else {
      $auth =~ s/:[0-9]*\z//;
    }
    $self->
uri_authority
 ($auth);
  } else {
    if (defined $given and $given =~ /\A[0-9]*\z/) {
      $self->
uri_authority
 (':'.$given);
    }
  }



}


;}

;


}
}
}
sub uri_path ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

if 
($$self =~ m!\A(?:[^:/?#]+:)?(?://[^/?#]*)?([^?#]*)!) {
  $r = $1;
}


}
$r;
} else {my ($self, $given) = @_;

{

if 
($given !~ /[?#]/ and
    $$self =~ m!^((?:[^:/?#]+:)?(?://[^/?#]*)?)[^?#]*((?:\?[^#]*)?(?:#.*)?)!s) {
  $$self = $1.$given.$2;
  

{

local $Error::Depth = $Error::Depth + 1;

{



    $self->
_on_path_changed
;
  


}


;}

;
}


}
}
}
sub uri_query ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

if 
($$self =~ m!^(?:[^:/?#]+:)?(?://[^/?#]*)?[^?#]*(?:\?([^#]*))?!s) {
  $r = $1;
} else {
  $r = 
undef
;
}


}
$r;
} else {my ($self, $given) = @_;

{

if 
((not defined $given or $given !~ /#/) and
    $$self =~ m!^((?:[^:/?#]+:)?(?://[^/?#]*)?[^?#]*)(?:\?[^#]*)?((?:#.*)?)!s) {
  $$self = defined $given ? $1.'?'.$given.$2 : $1.$2;
  

{

local $Error::Depth = $Error::Depth + 1;

{



    $self->
_on_query_changed
;
  


}


;}

;
}


}
}
}
sub uri_fragment ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

if 
($$self =~ m!^(?:[^:/?#]+:)?(?://[^/?#]*)?[^?#]*(?:\?[^#]*)?(?:#(.*))?!s) {
  $r = $1;
} else {
  $r = 
undef
;
}


}
$r;
} else {my ($self, $given) = @_;

{

if 
($$self =~ m!^((?:[^:/?#]+:)?(?://[^/?#]*)?[^?#]*(?:\?[^#]*)?)(?:#.*)?!s) {
  $$self = defined $given ? $1 . '#' . $given : $1;
  

{

local $Error::Depth = $Error::Depth + 1;

{



    $self->
_on_fragment_changed
;
  


}


;}

;
}


}
}
}
sub get_uri_path_segment ($$) {
my ($self, $index) = @_;
my $r = '';

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = [split m!/!, $self->
uri_path
, -1]->[$index];
  $r = '' if not defined $r and
             ($index == 0 or $index == -1); # If path is empty



}


;}

;


}
$r}
sub set_uri_path_segment ($$;$) {
my ($self, $index, $newValue) = @_;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
@p = split m!/!, $self->
uri_path
, -1;
  if (defined $newValue) {
    $p[$index] = $newValue;
  } else {
    splice @p, $index, 1;
  }
  no warnings 'uninitialized';
  $self->
uri_path
 (join '/', @p);



}


;}

;


}
}

## TODO: An attribute that returns the number of path segments is necessary.

*is_uri = \&is_uri_3986;

sub is_uri_3986 ($) {
  my $self = $_[0];
  my $r = 0;

{

my 
$v = $$self;
V: {
  ## -- Scheme
  unless ($v =~ s/^[A-Za-z][A-Za-z0-9+.-]*://s) {
    last V;
  }

  ## -- Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}) {
      last V;
    }
  }

  ## -- Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}) {
      last V;
    }
  }

  ## -- Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//;
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        

{

my 
$ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
my $h16 = qr/[0-9A-Fa-f]{1,4}/;
if ($x =~ s/(?:$ipv4|$h16)\z//o) {
  if ($x =~ /\A(?>$h16:){6}\z/o or
      $x =~ /\A::(?>$h16:){0,5}\z/o or
      $x =~ /\A${h16}::(?>$h16:){4}\z/o or
      $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
      $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
      $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
      $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/$h16\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/::\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
    $isv6 = 
1
;
  }
}


}

;
        last V unless $isv6;
      }
    } else {
      unless ($w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/) {
        last V;
      }
    }
  }

  ## -- Path
  unless ($v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}s) {
    last V;
  }

  $r = 
1
;
} # V


}
$r;
} # is_uri_3986

*is_relative_reference = \&is_relative_reference_3986;

sub is_relative_reference_3986 ($) {
  my $self = $_[0];
my $r = 0;

{

my 
$v = $$self;
V: {
  ## -- No scheme
  if ($v =~ s!^[^/?#]*:!!s) {
    last V;
  }

  ## -- Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}) {
      last V;
    }
  }

  ## -- Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}) {
      last V;
    }
  }

  ## -- Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//;
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        

{

my 
$ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
my $h16 = qr/[0-9A-Fa-f]{1,4}/;
if ($x =~ s/(?:$ipv4|$h16)\z//o) {
  if ($x =~ /\A(?>$h16:){6}\z/o or
      $x =~ /\A::(?>$h16:){0,5}\z/o or
      $x =~ /\A${h16}::(?>$h16:){4}\z/o or
      $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
      $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
      $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
      $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/$h16\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/::\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
    $isv6 = 
1
;
  }
}


}

;
        last V unless $isv6;
      }
    } else {
      unless ($w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/) {
        last V;
      }
    }
  }

  ## -- Path
  unless ($v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}s) {
    last V;
  }

  $r = 
1
;
} # V


}
$r;
} # is_relative_reference_3986

*is_uri_reference = \&is_uri_reference_3986;

sub is_uri_reference_3986 ($) {
  my $self = $_[0];
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
is_uri_3986
 ||
       $self->
is_relative_reference_3986
;



}


;}

;


}
$r;
} # is_uri_reference_3986

*is_absolute_uri = \&is_absolute_uri_3986;

sub is_absolute_uri_3986 ($) {
  my $self = $_[0];
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $$self !~ /#/ && $self->
is_uri_3986
;



}


;}

;


}
$r;
} # is_uri_reference_3986

sub is_empty_reference ($) {
  return ${$_[0]} eq '';
} # is_empty_reference

*is_iri = \&is_iri_3987;

sub is_iri_3987 ($) {
  my $self = $_[0];
my $r = 0;

{

my 
$v = $$self;
V: {
  ## LRM, RLM, LRE, RLE, LRO, RLO, PDF
  ## U+200E, U+200F, U+202A - U+202E
  my $ucschar = q{\x{00A0}-\x{200D}\x{2010}-\x{2029}\x{202F}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}};

  ## -- Scheme
  unless ($v =~ s/^[A-Za-z][A-Za-z0-9+.-]*://s) {
    last V;
  }

  ## -- Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o) {
      last V;
    }
  }

  ## -- Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar\x{E000}-\x{F8FF}\x{F0000}-\x{FFFFD}\x{100000}-\x{10FFFD}-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o) {
      last V;
    }
  }

  ## -- Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//; 
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        

{

my 
$ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
my $h16 = qr/[0-9A-Fa-f]{1,4}/;
if ($x =~ s/(?:$ipv4|$h16)\z//o) {
  if ($x =~ /\A(?>$h16:){6}\z/o or
      $x =~ /\A::(?>$h16:){0,5}\z/o or
      $x =~ /\A${h16}::(?>$h16:){4}\z/o or
      $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
      $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
      $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
      $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/$h16\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/::\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
    $isv6 = 
1
;
  }
}


}

;
        last V unless $isv6;
      }
    } else {
      unless ($w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/o) {
        last V;
      }
    }
  }

  ## -- Path
  unless ($v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}os) {
    last V;
  }

  $r = 
1
;
} # V


}
$r;
} # is_iri_3987

*is_relative_iri_reference = \&is_relative_iri_reference_3987;

sub is_relative_iri_reference_3987 ($) {
  my $self = $_[0];
my $r = 0;

{

my 
$v = $$self;
V: {
  ## LRM, RLM, LRE, RLE, LRO, RLO, PDF
  ## U+200E, U+200F, U+202A - U+202E
  my $ucschar = q{\x{00A0}-\x{200D}\x{2010}-\x{2029}\x{202F}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}};

  ## -- No scheme
  if ($v =~ s!^[^/?#]*:!!s) {
    last V;
  }

  ## -- Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o) {
      last V;
    }
  }

  ## -- Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    unless ($w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar\x{E000}-\x{F8FF}\x{F0000}-\x{FFFFD}\x{100000}-\x{10FFFD}-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o) {
      last V;
    }
  }

  ## -- Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//;
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        

{

my 
$ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
my $h16 = qr/[0-9A-Fa-f]{1,4}/;
if ($x =~ s/(?:$ipv4|$h16)\z//o) {
  if ($x =~ /\A(?>$h16:){6}\z/o or
      $x =~ /\A::(?>$h16:){0,5}\z/o or
      $x =~ /\A${h16}::(?>$h16:){4}\z/o or
      $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
      $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
      $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
      $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/$h16\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
    $isv6 = 
1
;
  }
} elsif ($x =~ s/::\z//o) {
  if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
    $isv6 = 
1
;
  }
}


}

;
        last V unless $isv6;
      }
    } else {
      unless ($w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/o) {
        last V;
      }
    }
  }

  ## -- Path
  unless ($v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}os) {
    last V;
  }

  $r = 
1
;
} # V


}
$r;
} # is_relative_iri_reference_3987

*is_iri_reference = \&is_iri_reference_3987;

sub is_iri_reference_3987 ($) {
  my $self = $_[0];
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
is_iri_3987
 ||
       $self->
is_relative_iri_reference_3987
;



}


;}

;


}
$r;
} # is_iri_reference_3987

*is_absolute_iri = \&is_absolute_iri_3987;

sub is_absolute_iri_3987 ($) {
  my $self = $_[0];
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $$self !~ /#/ && $self->
is_iri_3987
;



}


;}

;


}
$r;
} # is_absolute_iri_3987

sub get_uri_reference ($) {
my ($self) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
get_uri_reference_3986
;



}


;}

;


}
$r}
sub get_uri_reference_3986 ($) {
my ($self) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  require 
Encode;
  my $v = Encode::encode ('utf8', $$self);
  $v =~ s/([<>"{}|\\\^`\x00-\x20\x7E-\xFF])/sprintf '%%%02X', ord $1/ge;
  $r = bless \$v, 'Message::URI::URIReference';
}


;}

;


}
$r}
sub get_iri_reference ($) {
my ($self) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
get_iri_reference_3987
;



}


;}

;


}
$r}
sub get_iri_reference_3987 ($) {
my ($self) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  require 
Encode;
  my $v = Encode::encode ('utf8', $$self);
  $v =~ s{%([2-9A-Fa-f][0-9A-Fa-f])}
         {
           my $ch = hex $1;
           if ([
         # 0x0    0x1    0x2    0x3    0x4    0x5    0x6    0x7
         # 0x8    0x9    0xA    0xB    0xC    0xD    0xE    0xF
           
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
, # 0x00
           
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
, # 0x08
           
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
, # 0x10
           
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
, # 0x18
           
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
, # 0x20
           
1
,  
1
,  
1
,  
1
,  
1
, 
0
, 
0
,  
1
, # 0x28
          
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, # 0x30
          
0
, 
0
,  
1
,  
1
,  
1
,  
1
,  
1
,  
1
, # 0x38
           
1
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, # 0x40
          
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, # 0x48
          
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, # 0x50
          
0
, 
0
, 
0
,  
1
,  
1
,  
1
,  
1
, 
0
, # 0x58
           
1
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, # 0x60
          
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, # 0x68
          
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, 
0
, # 0x70
          
0
, 
0
, 
0
,  
1
,  
1
,  
1
, 
0
,  
1
, # 0x78
         # 0x0    0x1    0x2    0x3    0x4    0x5    0x6    0x7
         # 0x8    0x9    0xA    0xB    0xC    0xD    0xE    0xF
           ]->[$ch]) {
             # PERCENT SIGN, reserved, not-allowed in ASCII
             '%'.$1;
           } else {
             pack 'C', $ch;
           }
         }ge;
  $v =~ s{(
    [\xC2-\xDF][\x80-\xBF] |                          # UTF8-2
    [\xE0][\xA0-\xBF][\x80-\xBF] |
    [\xE1-\xEC][\x80-\xBF][\x80-\xBF] |
    [\xED][\x80-\x9F][\x80-\xBF] |
    [\xEE\xEF][\x80-\xBF][\x80-\xBF] |                # UTF8-3
    [\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |           # UTF8-4
    [\x80-\xFF]
  )}{
    my $c = $1;
    if (length ($c) == 1) {
      $c =~ s/(.)/sprintf '%%%02X', ord $1/ge;
      $c;
    } else {
      my $ch = Encode::decode ('utf8', $c);
      if ($ch =~ /^[\x{00A0}-\x{200D}\x{2010}-\x{2029}\x{202F}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}]/) {
        $c;
      } else {
        $c =~ s/([\x80-\xFF])/sprintf '%%%02X', ord $1/ge;
        $c;
      }
    }
  }gex;
  $v =~ s/([<>"{}|\\\^`\x00-\x20\x7F])/sprintf '%%%02X', ord $1/ge;
  $v = Encode::decode ('utf8', $v);
  $r = bless \$v, 'Message::URI::URIReference';
}


;}

;


}
$r}
sub get_absolute_reference ($$;%) {
my ($self, $base, %opt) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
get_absolute_reference_3986

                ($base, non_strict => $opt{non_strict});



}


;}

;


}
$r}
sub get_absolute_reference_3986 ($$%) {
my ($self, $base, %opt) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  ## -- Decomposition
  my ($b_scheme, $b_auth, $b_path, $b_query, $b_frag);
  my ($r_scheme, $r_auth, $r_path, $r_query, $r_frag);

  if ($$self =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!s) {
    ($r_scheme, $r_auth, $r_path, $r_query, $r_frag)
      = ($1, $2, $3, $4, $5);
  } else { # unlikely happen
    ($r_scheme, $r_auth, $r_path, $r_query, $r_frag)
      = (
undef
, 
undef
, '', 
undef
, 
undef
);
  }
  my $ba = ref $base eq 'SCALAR'
             ? $base
             : ref $base eq 'Message::URI::URIReference'
                 ? $base
                 : ref $base
                     ? \"$base"
                     : \$base;
  if ($$ba =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!s) {
    ($b_scheme, $b_auth, $b_path, $b_query, $b_frag)
      = (defined $1 ? $1 : '', $2, $3, $4, $5);
  } else { # unlikely happen
    ($b_scheme, $b_auth, $b_path, $b_query, $b_frag)
      = ('', 
undef
, '', 
undef
, 
undef
);
  }

  ## -- Merge
  my $path_merge = sub ($$) {
    my ($bpath, $rpath) = @_;
    if ($bpath eq '') {
      return '/'.$rpath;
    }
    $bpath =~ s/[^\/]*\z//;
    return $bpath . $rpath;
  }; # merge

  ## -- Removing Dot Segments
  my $remove_dot_segments = sub ($) {
    local $_ = shift;
    my $buf = '';
    L: while (length $_) {
      next L if s/^\.\.?\///;
      next L if s/^\/\.(?:\/|\z)/\//;
      if (s/^\/\.\.(\/|\z)/\//) {
        $buf =~ s/\/?[^\/]*$//;
        next L;
      }
      last Z if s/^\.\.?\z//;
      s/^(\/?[^\/]*)//;
      $buf .= $1;
    }
    return $buf;
  }; # remove_dot_segments

  ## -- Transformation
  my ($t_scheme, $t_auth, $t_path, $t_query, $t_frag);

  if ($opt{non_strict} and $r_scheme eq $b_scheme) {
    undef $r_scheme;
  }

  if (defined $r_scheme) {
    $t_scheme = $r_scheme;
    $t_auth   = $r_auth;
    $t_path   = $remove_dot_segments->($r_path);
    $t_query  = $r_query;
  } else {
    if (defined $r_auth) {
      $t_auth  = $r_auth;
      $t_path  = $remove_dot_segments->($r_path);
      $t_query = $r_query;
    } else {
      if ($r_path =~ /\A\z/) {
        $t_path = $b_path;
        if (defined $r_query) {
          $t_query = $r_query;
        } else {
          $t_query = $b_query;
        }
      } elsif ($r_path =~ /^\//) {
        $t_path  = $remove_dot_segments->($r_path);
        $t_query = $r_query;
      } else {
        $t_path  = $path_merge->($b_path, $r_path);
        $t_path  = $remove_dot_segments->($t_path);
        $t_query = $r_query;
      }
      $t_auth = $b_auth;
    }
    $t_scheme = $b_scheme;
  }
  $t_frag = $r_frag;

  ## -- Recomposition
  my $result  = ''                                      ;
  $result .=        $t_scheme . ':' if defined $t_scheme;
  $result .= '//' . $t_auth         if defined $t_auth  ;
  $result .=        $t_path                             ;
  $result .= '?'  . $t_query        if defined $t_query ;
  $result .= '#'  . $t_frag         if defined $t_frag  ;

  $r = bless \$result, 'Message::URI::URIReference'; 

}


;}

;


}
$r}
sub get_absolute_reference_3987 ($$;%) {
my ($self, $base, %opt) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
get_absolute_reference_3986

                ($base, non_strict => $opt{non_strict});



}


;}

;


}
$r}
sub is_same_document_reference ($$) {
my ($self, $base) = @_;
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = $self->
is_same_document_reference_3986
 ($base);



}


;}

;


}
$r}
sub is_same_document_reference_3986 ($$;%) {
my ($self, $base, %opt) = @_;
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  if 
(substr ($$self, 0, 1) eq '#') {
    $r = 
1
;
  } else {
    my $target = $self->
get_absolute_reference_3986

                          ($base, non_strict => $opt{non_strict})
                      ->
uri_reference
;
    $target =~ s/#.*\z//;
    my $ba = ref $base eq 'SCALAR'
               ? $$base
               : ref $base eq 'Message::URI::URIReference'
                   ? $$base
                   : ref $base
                       ? "$base"
                       : $base;
    $ba =~ s/#.*\z//;
    $r = ($target eq $ba);
  }



}


;}

;


}
$r}
sub get_relative_reference ($$) {
my ($self, $base) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
@base;
  my $ba = ref $base eq 'SCALAR'
             ? $base
             : ref $base eq 'Message::URI::URIReference'
                 ? $base
                 : ref $base
                     ? \"$base"
                     : \$base;
  if ($$ba =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!) {
    (@base) = (defined $1 ? $1 : '', $2, $3, $4, $5);
  } else { # unlikeley happen
    (@base) = ('', 
undef
, '', 
undef
, 
undef
);
  }
  my @t;
  my $t = $self->
get_absolute_reference
 ($base);
  if ("$t" =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!) {
    (@t) = (defined $1 ? $1 : '', $2, $3, $4, $5);
  } else { # unlikeley happen
    (@t) = ('', 
undef
, '', 
undef
, 
undef
);
  }

  my @ref;
  R: {
    ## Scheme
    if ($base[0] ne $t[0]) {
      (@ref) = @t;
      last R;
    }

    ## Authority
    if (not defined $base[1] and not defined $t[1]) {
      (@ref) = @t;
      last R;
    } elsif (not defined $t[1]) {
      (@ref) = @t;
      last R;
    } elsif (not defined $base[1]) {
      (@ref) = @t;
      last R;
    } elsif ($base[1] ne $t[1]) {
      (@ref) = @t;
      last R;
    }
    ## NOTE: Avoid uncommon references.

    if (defined $t[4] and                                # fragment
        $t[2] eq $base[2] and                            # path
        ((not defined $t[3] and not defined $base[3]) or # query
         (defined $t[3] and defined $base[3] and $t[3] eq $base[3]))) {
      (@ref) = (
undef
, 
undef
, '', 
undef
, $t[4]);
      last R;
    }

    ## Path
    my @tpath = split m!/!, $t[2], -1;
    my @bpath = split m!/!, $base[2], -1;
    if (@tpath < 1 or @bpath < 1) {  ## No |/|
      (@ref) = @t;
      last R;
    }
    my $bpl;

    ## Removes common segments
    while (@tpath and @bpath and $tpath[0] eq $bpath[0]) {
      shift @tpath;
      $bpl = shift @bpath;
    }

    if (@tpath == 0) {
      if (@bpath == 0) { ## Avoid empty path for backward compatibility
        unshift @tpath, $bpl;
      } else {
        unshift @tpath, '..', $bpl;
      }
    } elsif (@bpath == 0) {
      unshift @tpath, $bpl;
    }

    unshift @tpath, ('..') x (@bpath - 1) if @bpath > 1;

    unshift @tpath, '.' if $tpath[0] eq '' or
                           $tpath[0] =~ /:/;

    (@ref) = (
undef
, 
undef
, (join '/', @tpath), $t[3], $t[4]);
  } # R

  ## -- Recomposition
  my $result = ''                                   ;
  $result .=        $ref[0] . ':' if defined $ref[0];  # scheme;
  $result .= '//' . $ref[1]       if defined $ref[1];  # authority
  $result .=        $ref[2]                         ;  # path
  $result .= '?'  . $ref[3]       if defined $ref[3];  # query
  $result .= '#'  . $ref[4]       if defined $ref[4];  # fragment

  $r = bless \$result, 'Message::URI::URIReference';



}


;}

;


}
$r}

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

sub clone ($) {
  my $self = shift;
  my $v = $$self;
  return bless \$v, ref $self;
} # clone

*clone_uri_reference = \&clone;

use overload 
bool => sub () {1}, 
'""' => 'stringify', 
'eq' => sub ($$) {
my ($self, $v) = @_;
my $r = 0;

{

if 
(defined $v) {
  

{

local $Error::Depth = $Error::Depth + 1;

{



    $r = $v eq $$self;
  


}


;}

;
}


}
$r}
, 
fallback => 1;

#      Portions of the Perl implementation contained in the module
#      are derived from the example parser (April 7, 2004) available at
#      <URI::http://www.gbiv.com/protocols/uri/rev-2002/uri_test.pl>
#      that is placed in the Public Domain by Roy T. Fielding
#      and Day Software, Inc.

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/08/11 13:06:39 $
