#!/usr/bin/perl -w 

=head1 NAME

dis2pm.pl - Manakai DOM Perl Module Generator

=head1 SYNOPSIS

  perl dis2pm.pl Foo.dis > Foo.pm

=head1 DESCRIPTION

B<dis2pm> generates a Perl module file (*.pm) that implements
DOM (Document Object Model) interfaces from a "dis" 
(DOM implementation source) file.

This script is part of manakai.

=cut

use strict;
use Message::Markup::SuikaWikiConfig20::Parser;
use Message::Markup::XML::QName qw/DEFAULT_PFX/;
use Message::Util::QName::General [qw/ExpandedURI/], {
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  MDOM_EXCEPTION => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>,
};
my $ManakaiDOMModulePrefix = q<Message::DOM>;
my $MAX_DOM_LEVEL = 3;

my $s;
{
  local $/ = undef;
  $s = <>;
}
my $source = Message::Markup::SuikaWikiConfig20::Parser->parse_text ($s);
my $Info = {};
my $Status = {package => 'main', depth => 0, generated_fragment => 0};
my $result = '';

sub output_result ($) {
  print shift;
}

## Source file might be broken
sub valid_err (@) {
  require Carp;
  output_result $result;
  Carp::croak (@_);
}
sub valid_warn (@) {
  require Carp;
  Carp::carp (@_);
}

## Implementation (this script) might be broken
sub impl_err (@) {
  require Carp;
  Carp::croak (@_);
}
sub impl_warn (@) {
  require Carp;
  Carp::carp (@_);
}


sub english_number ($;%) {
  my ($num, %opt) = @_;
  if ($num == 0) {
    qq<no $opt{singular}>;
  } elsif ($num == 1) {
    qq<a $opt{singular}>;
  } elsif ($num < 0) {
    qq<$num $opt{plural}>;
  } elsif ($num < 10) {
    [qw/0 1 two three four five seven six seven eight nine/]->[$num] . ' ' .
    $opt{plural};
  } else {
    qq<$num $opt{plural}>;
  }
}


sub perl_comment ($) {
  my $s = shift;
  $s =~ s/\n/\n## /g;
  $s =~ s/\n## $/\n/s;
  $s .= "\n" unless $s =~ /\n$/;
  $s = q<## > . $s;
  $s;
}

sub perl_statement ($) {
  my $s = shift;
  $s . ";\n";
}

sub perl_assign ($@) {
  my ($left, @right) = @_;
  $left . ' = ' . (@right > 1 ? '(' . join (', ', @right) . ')' : $right[0]);
}

sub perl_name ($;%) {
  my ($s, %opt) = @_;
  $s =~ s/[- ](.|$)/uc $1/ge;
  $s = ucfirst $s if $opt{ucfirst};
  $s = uc $s if $opt{uc};
  $s;
}

sub perl_internal_name ($) {
  my $s = shift;
  '_' . perl_name $s;
}

sub perl_package_name (%) {
  my %opt = @_;
  my $r;
  if ($opt{if}) {
    $r = $ManakaiDOMModulePrefix . q<::IF::> . perl_name $opt{if};
  } elsif ($opt{name} or $opt{name_with_condition}) {
    if ($opt{name_with_condition}) {
      if ($opt{name_with_condition} =~ /^([^:]+)::([^:]+)$/) {
        $opt{name} = $1;
        $opt{condition} = $2;
      } else {
        $opt{name} = $opt{name_with_condition};
      }
    } 
    $opt{name} = perl_name $opt{name};
    $opt{name} = $opt{prefix} . '::' . $opt{name} if $opt{prefix};
    $r = $ManakaiDOMModulePrefix . q<::> . $opt{name};
  } elsif ($opt{qname} or $opt{qname_with_condition}) {
    if ($opt{qname_with_condition}) {
      if ($opt{qname_with_condition} =~ /^(.+)::(.+)$/) {
        $opt{qname} = $1;
        $opt{condition} = $2;
      } else {
        $opt{qname} = $opt{qname_with_condition};
      }
    }
    if ($opt{qname} =~ /^([^:]*):(.*)$/) {
      $opt{ns_prefix} = $1;
      $opt{name} = $2;
    } else {
      $opt{ns_prefix} = DEFAULT_PFX;
      $opt{name} = $opt{qname};
    }
    ## ISSUE: Prefix to ...
    #$r = ns_uri_to_perl_package_name (ns_prefix_to_uri ($opt{ns_prefix})) .
    #     '::' . $opt{name};
    $r = $ManakaiDOMModulePrefix . '::' . $opt{name};
  } elsif ($opt{full_name}) {
    $r = $opt{full_name};
  } else {
    valid_err q<$opt{name} is false>;
  }
  if ($opt{condition}) {
    $r = $r . '::' . perl_name $opt{condition};
  }
  if ($opt{is_internal}) {
    $r = $r . '::_internal';
  }
  $r;
}

sub perl_package (%) {
  my $fn = perl_package_name @_;
  unless ($fn eq $Status->{package}) {
    $Status->{package} = $fn;
    return perl_statement qq<package $fn>;
  } else {
    return '';
  }
}

sub perl_inherit ($;$) {
  my ($isa, $mod) = @_;
  if ($mod) {
    perl_statement 'push ' . perl_var (type => '@',
                                       local_name => 'ISA',
                                       package => {full_name => $mod}) .
                   ', ' . perl_list (@$isa);
  } else {
    perl_statement 'push our @ISA, ' . perl_list (@$isa);
  }
}

sub perl_sub (%) {
  my %opt = @_;
  my $r = 'sub ';
  $r .= $opt{name} . ' ' if $opt{name};
  $r .= '(' . $opt{prototype} . ') ' if defined $opt{prototype};
  $r .= "{\n";
  $r .= $opt{code};
  $r .= "}\n";
}

sub perl_var (%) {
  my %opt = @_;
  my $r = $opt{type} || '';                   # $, @, *, &, $# or empty
  $r = $opt{scope} . ' ' . $r if $opt{scope}; # my, our or local
  $r .= perl_package_name (%{$opt{package}}) . '::' if $opt{package};
  $r .= $opt{local_name};
  $r;
}

{
use re 'eval';
my $RegBlockContent;
$RegBlockContent = qr/(?>[^{}\\]*)(?>(?>[^{}\\]+|\\.|\{(??{$RegBlockContent})\})*)/s;
sub perl_code ($;%);
sub perl_code ($;%) {
  my ($s, %opt) = @_;
  $s =~ s/\bnull\b/undef/g;
  $s =~ s/\btrue\b/1/g;
  $s =~ s/\bfalse\b/0/g;
  $s =~ s{<Q:([^>]+)>}{           ## QName
    perl_literal (expanded_uri ($1));
  }ge;
## TODO: Ensure Message::Util::Error imported if try.
## ISSUE: __FILE__ & __LINE__ will break if multiline substition happens.
  $s =~ s{
    \b__([A-Z]+)
    (?:\{($RegBlockContent)\})?
    __\b
  }{
    my ($name, $data) = ($1, $2);
    my $r;
    if ($name eq 'CLASS') {       ## Manakai DOM Class Name
      $r = perl_package_name name => $data;
    } elsif ($name eq 'SUPER') {  ## Manakai DOM Class Name
      local $Status->{condition} = $Status->{condition};
      if ($data =~ s/::([^:]+)$//) {
        $Status->{condition} = $1;
      }
      $r = perl_package_name name => $data,
                             is_internal => 1,
                             condition => $Status->{condition};
    } elsif ($name eq 'IF') {     ## DOM Interface Name
      $r = perl_package_name if => $data;
    } elsif ($name eq 'INT') {    ## Internal Method / Attr Name
      if (defined $data) {
        if ($data =~ /^{(\w+)}$/) {
          valid_err q<Preprocessing macro INT{} cannot be used here>
            unless $opt{internal};
          $r = $opt{internal}->($1);
        } else {
          $r = perl_internal_name $data;
        }
      } else {
        valid_err q<Preprocessing macro INT cannot be used here>
          unless $opt{internal};
        $r = $opt{internal}->();
      }
    } elsif ($name eq 'DEEP') {   ## Deep Method Call
      $r = 'do { local $Error::Depth = $Error::Depth + 1;' . perl_code ($data) .
           '}';
    } elsif ($name eq 'EXCEPTION' or $name eq 'WARNING') {
                                  ## Raising an Exception or Warning
      if ($data =~ s/^\s*(\w+)\s*\.\s*(\w+)\s*(?::\s*|$)//) {
        $r = perl_exception (level => $name,
                             class => $1,
                             type => $2,
                             param => perl_code $data);
      } else {
        valid_err qq<Exception type and name required>;
      }      
    } elsif ($name eq 'CODE') { # Built-in code
      my ($nm, %param);
      if ($data =~ s/^(\w+)\s*(?::\s*|$)//) {
        $nm = $1;
      } elsif ($data =~ s/^<([^<>]+)>\s*(?::\s*|$)//) {
        $nm = $1;
      } else {
        valid_err q<Built-in code name required>;
      }
      while ($data =~ /\G(\S+)\s*=>\s*(\S+)\s*(,\s*|$)/g) {
        $param{$1} = $2;
      }
      $r = perl_builtin_code ($nm, condition => $opt{condition}, %param);
    } elsif ($name eq 'PACKAGE' and $data) {
      if ($data eq 'Global') {
        $r = $ManakaiDOMModulePrefix;
      } else {
        valid_err qq<PACKAGE "$data" not supported>;
      }
    } elsif ($name eq 'FILE' or $name eq 'LINE' or $name eq 'PACKAGE') {
      $r = qq<__${name}__>;
    } else {
      valid_err qq<Preprocessing macro "$name" not supported>;
    }
    $r;
  }goex;
  $s;
}
}

sub perl_builtin_code ($%) {
  my ($name, %opt) = @_;
  $opt{condition} ||= $Status->{condition};
  my $r;
  if ($name eq 'DOMString' or
      $name eq 'ManakaiDOMNamespaceURI' or
      type_isa ($name, ExpandedURI q<DOMMain:DOMString>)) {
    $name = $1 if $name =~ /(\w+)$/;
    $r = q{
          if (defined $arg) {
            if (ref $arg) {
              if (ref $arg eq 'SCALAR') {
                $r = bless {value => $$arg}, $self;
              } elsif ($arg->isa ('IF')) {
                $r = $arg;
              } else {
                $r = bless {value => ''.$arg}, $self;
              }
            } else {
              $r = bless {value => $arg}, $self;
            }
            ##IFEMPTY
          } else {
            $r = undef; # null
          }
    };
    $r =~ s/'IF'/perl_literal (perl_package_name (if => $name))/ge;
    $r =~ s/\$self\b/perl_literal (perl_package_name (name => $name))/ge;
    $opt{s} or valid_err q<Built-in code parameter "s" required>;
    if ($name eq 'ManakaiDOMNamespaceURI') {
      my $t = perl_statement perl_exception
                (level => 'WARNING',
                 class => 'ManakaiDOMImplementationWarning',
                 type => 'MDOM_NS_EMPTY_URI',
                 param => {
                   ExpandedURI q<MDOM_EXCEPTION:param-name> => $opt{s},
                 });
      if ($opt{condition} and $opt{condition} ne 'DOM2') {
        $t .= perl_statement q<$r = undef>;
      }
      $r =~ s/##IFEMPTY/q<if ($r eq '') {>.$t.q<}>/ge;
    } else {
      $r =~ s/##IFEMPTY//g;
    }
    $r =~ s/\$arg\b/\$$opt{s}/g;
    $opt{r} or valid_err q<Built-in code parameter "r" required>;
    $r =~ s/\$r\b/\$$opt{r}/g;
    $r =~ s/\$$opt{r} = \$$opt{s};/#/g if $opt{r} eq $opt{s};
  } elsif ($name eq 'UniqueID') {
    $r = q{(
      sprintf 'mid:%d.%d.%s.dom.manakai@suika.fam.cx',
              time, $$,
              ['A'..'Z', 'a'..'z', '0'..'9']->[rand 62] .
              ['A'..'Z', 'a'..'z', '0'..'9']->[rand 62] .
              ['A'..'Z', 'a'..'z', '0'..'9']->[rand 62] .
              ['A'..'Z', 'a'..'z', '0'..'9']->[rand 62] .
              ['A'..'Z', 'a'..'z', '0'..'9']->[rand 62]
    )};
  } elsif ($name eq 'CheckQName') {
    $opt{version} = '1.0' if $opt{condition} and $opt{condition} eq 'DOM2';
    my $chk = perl_if
                (qq<##CHKNAME##>, undef,
                  (perl_statement
                    perl_exception 
                      (class => 'DOMException',
                       type => 'INVALID_CHARACTER_ERR',
                       param => {
                         ExpandedURI q<MDOM_EXCEPTION:subtype>
                             => ExpandedURI q<MDOM_EXCEPTION:CHAR_INVALID_NAME>,
                         ExpandedURI q<MDOM_EXCEPTION:name>
                             => perl_code_literal
                                  (perl_var type => '$', local_name => 'qname'),
                       }))) .
              perl_if
                (qq<##CHKQNAME##>, undef,
                  (perl_statement
                    perl_exception
                      (class => 'DOMException',
                       type => 'NAMESPACE_ERR',
                       param => {
                         ExpandedURI q<MDOM_EXCEPTION:subtype>
                             => ExpandedURI q<MDOM_EXCEPTION:NS_INVALID_QNAME>,
                         ExpandedURI q<MDOM_EXCEPTION:name>
                             => perl_code_literal
                                  (perl_var type => '$', local_name => 'qname'),
                       })));
    my $chk10 = $chk;
    $chk10 =~ s{##CHKNAME##}
               {q<$qname =~ /\A\p{InXML_NameStartChar10}>.
                q<\p{InXMLNameChar10}*\z/>}ge;
    $chk10 =~ s{##CHKQNAME##}
               {q<$qname =~ /\A\p{InXML_NCNameStartChar10}>.
                q<\p{InXMLNCNameChar10}*>.
                q<(?::\p{InXML_NCNameStartChar10}>.
                q<\p{InXMLNCNameChar10}*)?\z/>}ge;
    my $chk11 = $chk;
    $chk11 =~ s{##CHKNAME##}
               {q<$qname =~ /\A\p{InXMLNameStartChar11}>.
                q<\p{InXMLNameChar11}*\z/>}ge;
    $chk11 =~ s{##CHKQNAME##}
               {q<$qname =~ /\A\p{InXMLNCNameStartChar11}>.
                q<\p{InXMLNCNameChar11}*>.
                q<(?::\p{InXMLNCNameStartChar11}>.
                q<\p{InXMLNCNameChar11}*)?\z/>}ge;
    my %class;
    if ($opt{version} and $opt{version} eq '1.0') {
      $r = $chk10;
      %class = (qw/InXML_NameStartChar10 InXMLNameChar10
                   InXML_NCNameStartChar10 InXMLNameChar10/);
    } elsif ($opt{version} and $opt{version} eq '1.1') {
      $r = $chk11;
      %class = (qw/InXMLNameStartChar11 InXMLNameChar11
                   InXMLNCNameStartChar11 InXMLNameChar11/);
    } elsif ($opt{version}) {
      $r = perl_if (perl_var (type => '$', local_name => $opt{version}) .
                    q< eq '1.1'>, $chk11, $chk10);
    } else {
      valid_err q<Built-in code parameter "version" required>;
    }
    $opt{qname} or valid_err q<Built-in code parameter "qname" required>;
    $r =~ s/\$qname\b/\$$opt{qname}/g;
    $Info->{Require_perl_package_use}->{'Char::Class::XML'} or
      valid_err q<"Char::Class::XML" must be "Require"d>;
    for (%class) {
      $Info->{Require_perl_package_use}->{'Char::Class::XML::::Import'}->{$_} or
        valid_err qq<"$_" must be exported from "Char::Class::XML">;
    }
  } elsif ($name eq 'CheckNCName') {
    $opt{version} = '1.0' if $opt{condition} and $opt{condition} eq 'DOM2';
    my $chk = perl_if
                (qq<##CHKNAME##>, undef,
                  (perl_statement
                    perl_exception 
                      (class => 'DOMException',
                       type => 'INVALID_CHARACTER_ERR',
                       param => {
                         ExpandedURI q<MDOM_EXCEPTION:subtype>
                             => ExpandedURI q<MDOM_EXCEPTION:CHAR_INVALID_NAME>,
                         ExpandedURI q<MDOM_EXCEPTION:name>
                             => perl_code_literal
                                  (perl_var type => '$', local_name => 'qname'),
                       }))) .
              perl_if
                (qq<##CHKNCNAME##>, undef,
                  (perl_statement
                    perl_exception
                      (class => 'DOMException',
                       type => 'NAMESPACE_ERR',
                       param => {
                         ExpandedURI q<MDOM_EXCEPTION:subtype>
                             => ExpandedURI q<MDOM_EXCEPTION:NS_INVALID_NCNAME>,
                         ExpandedURI q<MDOM_EXCEPTION:name>
                             => perl_code_literal
                                  (perl_var type => '$', local_name => 'qname'),
                       })));
    my $chk10 = $chk;
    $chk10 =~ s{##CHKNAME##}
               {q<$qname =~ /\A\p{InXML_NameStartChar10}>.
                q<\p{InXMLNameChar10}*\z/>}ge;
    $chk10 =~ s{##CHKNCNAME##}
               {q<$qname =~ /:/>}ge;
    my $chk11 = $chk;
    $chk11 =~ s{##CHKNAME##}
               {q<$qname =~ /\A\p{InXMLNameStartChar11}>.
                q<\p{InXMLNameChar11}*\z/>}ge;
    $chk11 =~ s{##CHKNCNAME##}
               {q<$qname =~ /:/>}ge;
    my $t = ($opt{empty} and $opt{empty} eq 'warn3' and
             (not $opt{condition} or $opt{condition} ne 'DOM2')) ?
            perl_if 
              (q<defined $qname and $qname eq q<>>,
               perl_statement (perl_exception
                 (level => 'WARNING',
                  class => 'ManakaiDOMImplementationWarning',
                  type => 'MDOM_NS_EMPTY_PREFIX',
                  param => {
                    ExpandedURI q<MDOM_EXCEPTION:param-name> => $opt{ncname},
                  })).
               perl_statement (q<$qname = undef>)) : '';
    my %class;
    if ($opt{version} and $opt{version} eq '1.0') {
      $r = $chk10;
      %class = (qw/InXML_NameStartChar10 InXMLNameChar10/);
    } elsif ($opt{version} and $opt{version} eq '1.1') {
      $r = $chk11;
      %class = (qw/InXMLNameStartChar11 InXMLNameChar11/);
    } elsif ($opt{version}) {
      $r = perl_if (perl_var (type => '$', local_name => $opt{version}) .
                    q< eq '1.1'>, $chk11, $chk10);
    } else {
      valid_err q<Built-in code parameter "version" required>;
    }
    $r = $t . $r;
    $opt{ncname} or valid_err q<Built-in code parameter "ncname" required>;
    $r =~ s/\$qname\b/\$$opt{ncname}/g;
    $Info->{Require_perl_package_use}->{'Char::Class::XML'} or
      valid_err q<"Char::Class::XML" must be "Require"d>;
    for (%class) {
      $Info->{Require_perl_package_use}->{'Char::Class::XML::::Import'}->{$_} or
        valid_err qq<"$_" must be exported from "Char::Class::XML">;
    }
  } elsif ($name eq 'CheckNull') {
    $r = perl_code q{
      __EXCEPTION{
        ManakaiDOMImplementationException.PARAM_NULL_POINTER:
          <Q:MDOM_EXCEPTION:param-name> => 'arg',
      }__ unless defined $arg;
    };
    $opt{s} or valid_err q<Built-in code parameter "s" required>;
    $r =~ s/\$arg\b/\$$opt{s}/g;
    $r =~ s/'arg'/perl_literal ($opt{s})/ge;
  } else {
    valid_err qq<Built-in code "$name" not defined>;
  }
  $r;
}

sub perl_code_source ($%) {
  my ($s, %opt) = @_;
  sprintf qq<\n#line %d "File <%s> Node <%s>"\n%s\n> .
          qq<#line 1 "File <%s> Chunk #%d"\n>,
    $opt{line} || 1, $opt{file} || $Info->{source_filename},
    $opt{path} || 'x:unknown ()', $s, 
    $opt{file} || $Info->{source_filename}, ++$Status->{generated_fragment};
}

sub perl_code_literal ($) {
  my $s = shift;
  bless \$s, '__code';
}

sub perl_literal ($) {
  my $s = shift;
  unless (defined $s) {
    impl_warn q<Undefined value is passed to perl_literal ()>;
    return q<undef>;
  } elsif (ref $s eq 'ARRAY') {
    return q<[> . perl_list (@$s) . q<]>;
  } elsif (ref $s eq 'HASH') {
    return q<{> . perl_list (%$s) . q<}>;
  } elsif (ref $s eq 'CODE') {
    impl_err q<CODE reference cannot be serialized>;
  } elsif (ref $s eq '__code') {
    return $$s;
  } else {
    $s =~ s/(['\\])/\\$1/g;
    return q<'> . $s . q<'>;
  }
}

sub perl_list (@) {
  join ', ', map perl_literal $_, @_;
}

sub perl_exception (@) {
  my %opt = @_;
  if ($opt{class} !~ /:/) {
    $opt{class} = perl_package_name name => $opt{class};
  } else {
    $opt{class} = perl_package_name full_name => $opt{class};
  }
  if (ref $opt{param}) {
    $opt{param} = perl_list %{$opt{param}};
  }
  q<report > . $opt{class} . q< > .
                 perl_list (-type => $opt{type},
                            -object => perl_code_literal
                                           (perl_var (type => '$',
                                                      local_name => 'self')),
                            ($opt{param} ? perl_code_literal $opt{param} : ()));
}

sub perl_if ($$;$) {
  my ($condition, $true, $false) = @_;
  my $if = q<if>;
  unless (defined $true) {
    $if = q<unless>;
    $true = $false;
    $false = undef;
  }
  for ($true, $false) {
    $_ = "\n" . $_ if $_ and /\A#\w+/;
  }
  my $r = qq<$if ($condition) {\n>.
          qq<  $true>.
          qq<}>;
  if (defined $false) {
     $r .=  qq< else {\n>.
           qq<  $false>.
           qq<}>;
  }
  $r .= qq<\n>;
  $r;
} # perl_if

sub ops2perl () {
  my $result = '';
  if ($Status->{Operator}->{DESTROY}) {
    $result .= perl_statement
                 perl_assign
                      perl_var (type => '*', local_name => 'DESTROY')
                   => $Status->{Operator}->{DESTROY};
    delete $Status->{Operator}->{DESTROY};
  }
  if (keys %{$Status->{Operator}}) {
    $result .= perl_statement 'use overload ' .
                   perl_list map ({($_,
                                   perl_code_literal $Status->{Operator}->{$_})}
                                  keys %{$Status->{Operator}}),
                             fallback => 1;
  }
  $result;
}


sub pod_comment (@) {
  (q<=begin comment>, @_, q<=end comment>);
}

sub pod_block (@) {
  my @v = grep ((defined and length), @_);
  join "\n\n", '', ($v[0] =~ /^=/ ? () : '=pod'), @v, '=cut', '';
}

sub pod_head ($$) {
  my ($level, $s) = @_;
  $s =~ s/\s+/ /g;
  if ($level < 5) {
    '=head' . $level . ' ' . $s;  ## pod has only head1-head4.
  } else {
    'B<' . $s . '>';
  }
}

sub pod_list ($@) {
  my $m = shift;
  ('=over ' . $m, @_, '=back');
}

sub pod_item ($) {
  my ($s) = @_;
  $s =~ s/\s+/ /g;
  '=item ' . $s;
}

sub pod_pre ($) {
  my $s = shift;
  return '' unless defined $s;
  $s =~ s/\n/\n  /g;
  '  ' . $s;
}

sub pod_para ($) {
  my $s = shift;
  return '' unless defined $s;
  $s =~ s/\n\s+/\n/g;
  $s;
}

sub pod_paras ($) {
  shift;
}

sub pod_code ($) {
  my $s = shift;
  $s =~ s/([<>])/{'<' => 'E<lt>', '>' => 'E<gt>'}->{$1}/ge;
  qq<C<$s>>;
}


sub muf_template ($) {
  my $s = shift;
  $s =~ s{<Q:([^>]+)>}{           ## QName
    expanded_uri ($1)
  }ge;
  $s;
}

sub section (@) {
  my @r;
  while (my ($t, $s) = splice @_, 0, 2) {
    if ($t eq 'req' and (not defined $s or not length $s)) {
      return ();
    } elsif (defined $s and length $s) {
      push @r, $s;
    }
  }
  return @r;
}


sub rfc3339_date ($) {
  my @time = gmtime shift;
  sprintf q<%04d-%02d-%02dT%02d:%02d:%02d+00:00>,
          $time[5] + 1900, $time[4] + 1, @time[3,2,1,0];
}

sub version_date ($) {
  my @time = gmtime shift;
  sprintf q<%04d%02d%02d.%02d%02d>,
          $time[5] + 1900, $time[4] + 1, @time[3,2,1];
}

{
my $nest = 0;
sub type_normalize ($);
sub type_normalize ($) {
  my ($uri) = @_;
  $nest++ == 100 and valid_err q<Possible loop for DataTypeAlias of <$uri>>;
  if ($Info->{DataTypeAlias}->{$uri}->{canon_uri}) {
    $uri = type_normalize ($Info->{DataTypeAlias}->{$uri}->{canon_uri});
  }
  $nest--;
  $uri;
}
}

{
my $nest = 0;
sub type_isa ($$);
sub type_isa ($$) {
  my ($uri, $uri2) = @_;
  $nest++ == 100 and valid_err qq<Possible loop for <DataType/ISA> of <$uri>>;
  my $r = 0;
  if ($uri eq $uri2) {
    $r = 1;
  } else {
    for (@{$Info->{DataTypeAlias}->{$uri}->{isa_uri}||[]}) {
      if (type_isa $_, $uri2) {
        $r = 1;
        last;
      }
    }
  }
  $nest--;
  $r;
}
}

sub type_label ($) {
  my $uri = type_normalize shift;
  my $r = {
    ExpandedURI q<ManakaiDOM:ManakaiDOMURI>
      => q<DOMString (DOM URI)>,
    ExpandedURI q<ManakaiDOM:ManakaiDOMNamespaceURI>
      => q<DOMString (Namespace URI)>,
    ExpandedURI q<ManakaiDOM:ManakaiDOMFeatureName>
      => q<DOMString (DOM Feature name)>,
    ExpandedURI q<ManakaiDOM:ManakaiDOMFeatureVersion>
      => q<DOMString (DOM Feature version)>,
    ExpandedURI q<ManakaiDOM:ManakaiDOMFeatures>
      => q<DOMString (DOM features)>,
  }->{$uri};
  unless ($r) {
    if ($uri =~ /([\w_-]+)$/) {
      my $label = $1;
      $label =~ s/--+/ /g;
      $label =~ s/__+/ /g;
      $r = $label;
    } else {
      $r = "<$uri>";
    }
  }
  $r;
}

sub type_package_name ($) {
  my $qname = shift;
  if ($qname =~ /^([^:]*):([^:]*)$/) {
    perl_package_name name => perl_name $2, ucfirst => 1;
  } else {
    perl_package_name name => perl_name $qname, ucfirst => 1;
  }
}

sub ns_uri_to_perl_package_name ($) {
  my $uri = shift;
  if ($Info->{uri_to_perl_package}->{$uri}) {
    return $Info->{uri_to_perl_package}->{$uri};
  } else {
    return qq<Perl package name for namespace <$uri> not defined>;
  }
}

sub ns_prefix_to_uri ($) {
  my $pfx = shift;
  if (exists $Info->{Namespace}->{$pfx}) {
    if (not defined $Info->{Namespace}->{$pfx}) {
      valid_err qq<Namespace name for "$pfx" not defined>;
    } else {
      return $Info->{Namespace}->{$pfx};
    }
  } else {
    valid_err qq<Namespace prefix "$pfx" not declared>;
  }  
}

sub type_expanded_uri ($) {
  my $qname = shift || '';
  if ($qname =~ /^[a-z-]+$/ or $qname eq 'Object') {
    expanded_uri ("DOMMain:$qname");
  } else {
    expanded_uri ($qname);
  }
}

sub expanded_uri ($) {
  my $lname = shift || '';
  my $pfx = DEFAULT_PFX;
  if ($lname =~ s/^([^:]*)://) {
    $pfx = $1;
  }
  ns_prefix_to_uri ($pfx) . $lname;
}

sub array_contains ($$) {
  my ($array, $val) = @_;
  if (ref $array eq 'ARRAY') {
    for (@$array) {
      return 1 if $_ eq $val;
    }
  } else {
    return $array eq $val;
  }
  return 0;
}


sub get_warning_perl_code ($) {
  my $pnode = shift;
  my $r = '';
  for my $node (@{$pnode->child_nodes}) {
    next unless $node->node_type eq '#element' and
                $node->local_name eq 'Warning';
    my %param;
    for (@{$node->child_nodes}) {
      next unless $_->node_type eq '#element' and
                  $_->local_name eq 'Param';
      $param{expanded_uri $_->get_attribute_value ('QName')}
        = perl_code_literal get_value_literal ($_, name => 'Value',
                                               type_name => 'Type');
    }
    $r .= perl_statement 
              perl_exception
                class => type_package_name $node->get_attribute_value
                                                    ('Type',
                                                     default => 'DOMMain:any'),
                type => $node->get_attribute_value ('Name'),
                param => \%param;
  }
  $r;
} # get_warning_perl_code

sub get_perl_definition_node ($%) {
  my ($node, %opt) = @_;
  my $ln = $opt{name} || 'Def';
  my $def = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    type_expanded_uri $you->get_attribute_value ('Type', default => '')
      eq ExpandedURI q<lang:Perl> and
    condition_match ($you, %opt);
  }) || ($opt{use_dis} and $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    $you->get_attribute_value ('Type', default => '')
      eq ExpandedURI q<lang:dis> and
    condition_match ($you, %opt);
  })) || $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    not $you->get_attribute_value ('Type', default => '') and
    condition_match ($you, %opt);
  }) || $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    type_expanded_uri $you->get_attribute_value ('Type', default => '')
      eq ExpandedURI q<lang:Perl> and
    condition_match ($you); # no condition specified
  }) || ($opt{use_dis} and $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    type_expanded_uri $you->get_attribute_value ('Type', default => '')
      eq ExpandedURI q<lang:dis> and
    condition_match ($you); # no condition specified
  })) || $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    not $you->get_attribute_value ('Type', default => '') and
    condition_match ($you); # no condition specified
  });
  $def;
}

sub get_perl_definition ($%) {
  my ($node, %opt) = @_;
  my $def = get_perl_definition_node $node, %opt;
  $def ? $def->value : $opt{default};
}

sub dis2perl ($) {
  my $node = shift;
  my $r = '';
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    if ($_->local_name eq 'GetProp') {
      $r .= perl_statement perl_assign
              perl_var (type => '$', local_name => 'r')
              => '$self->{node}->{' .
                 perl_literal (expanded_uri ($_->value)) . '}';
    } elsif ($_->local_name eq 'GetPropNode') {
      $r .= perl_statement perl_assign
              perl_var (type => '$', local_name => 'r')
              => '$self->{node}->{' .
                 perl_literal (expanded_uri ($_->value)) . '}->'.
                 perl_code q{__CLASS{ManakaiDOMNodeObject}__->__INT{newReference}__};
    } elsif ($_->local_name eq 'SetProp') {
      $r .= perl_statement perl_assign
              '$self->{node}->{' .
                 perl_literal (expanded_uri ($_->value)) . '}'
              => perl_var (type => '$', local_name => 'given');
    } elsif ($_->local_name eq 'Type') {
      #
    } else {
      valid_err qq{Element type "@{[$_->local_name]}" not supported};
    }
  }
  $r;
} # dis2perl

sub get_description ($%) {
  my ($node, %opt) = @_;
  my $ln = $opt{name} || 'Description';
  my $lang = $opt{lang} || q<en> || q<i-default>;
  my $script = $opt{script} || q<>;
  my $def = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    $you->get_attribute_value ('lang', default => 'i-default') eq $lang;
  }) || $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    $you->get_attribute_value ('lang', default => 'i-default') eq 'i-default';
  });
  $def ? $def->value : $opt{default};
}

sub get_level_description ($%) {
  my ($node, %opt) = @_;
  my @l = @{$node->get_attribute_value ('Level', default => [], as_array => 1)};
  unless (@l) {
    my $min = $opt{level}->[0] || 1;
    for ($min..$MAX_DOM_LEVEL) {
      if ($Info->{Condition}->{'DOM' . $_}) {
        unshift @l, $_;
        last;
      }
    }
  }
  return q<> unless @l;
  @l = sort {$a <=> $b} @l;
  @{$opt{level}} = @l;
  my $r = q<introduced in DOM Level > . (0 + shift @l);
  if (@l > 1) {
    my $s = 0 + pop @l;
    $r .= q< and modified in DOM Levels > . join ', ', @l;
    $r .= qq< and $s>;
  } elsif (@l == 1) {
    $r .= q< and modified in DOM Level > . (0 + $l[0]);
  }
  $r;
}

sub get_incase_label ($;%) {
  my ($node, %opt) = @_;
  my $label = $node->get_attribute_value ('Label', default => '');
  unless (length $label) {
    $label = $node->get_attribute ('Value'); 
    my $type = type_normalize
                 type_expanded_uri
                    ($node->get_attribute_value ('Type') ||
                     $node->parent_node->get_attribute_value
                                                ('Type',
                                                 default => q<DOMMain:any>));
    if ($label) {
      if ($label->get_attribute_value ('is-null', default => 0)) {
        $label = 'null';
      } elsif (type_isa $type, ExpandedURI q<DOMMain:DOMString>) {
        $label = perl_literal $label->value;
      } else {
        $label = $label->value;
      }
      $label = $opt{is_pod} ? pod_code $label : $label;
    } else {
      $label = type_label $type;
    }
  }
  $label;
}

sub get_value_literal ($%) {
  my ($node, %opt) = @_;
  my $value = get_perl_definition_node $node, %opt;
  my $type = type_normalize type_expanded_uri
               $node->get_attribute_value ($opt{type_name} || 'Type',
                                           default => q<DOMMain:any>);
  my $r;
  if ($type eq ExpandedURI q<DOMMain:boolean>) {
    if ($value) {
      $r = ($value->value and $value->value eq 'true') ? 1 : 0;
    } else {
      $r = $opt{default} ? 1 : 0;
    }
  } elsif ($type eq ExpandedURI q<DOMMain:unsigned-long> or
           $type eq ExpandedURI q<DOMMain:unsigned-long-long> or
           $type eq ExpandedURI q<DOMMain:long> or
           $type eq ExpandedURI q<DOMMain:float> or
           $type eq ExpandedURI q<DOMMain:unsigned-short>) {
    if ($value) {
      $r = $value->value;
    } else {
      $r = defined $opt{default} ? $opt{default} : 0;
    }
  } elsif (type_isa $type, ExpandedURI q<DOMMain:DOMString>) {
    if ($value) {
      if ($value->get_attribute_value ('is-null', default => 0)) {
        $r = 'undef';
      } else {
        $r = perl_literal $value->value;
      }
    } else {
      if (exists $opt{default}) {
        $r = defined $opt{default} ? perl_literal $opt{default} : 'undef';
      } else {
        $r = perl_literal '';
      }
    }
  } elsif ($type eq ExpandedURI q<Perl:ARRAY>) {
    if ($value) {
      $r = perl_literal $value->value (as_array => 1);
    } else {
      $r = perl_literal (defined $opt{default} ? $opt{default} : []);
    }
  } elsif ($type eq ExpandedURI q<Perl:HASH>) {
    if ($value) {
      $r = perl_literal $value->value;
    } else {
      $r = perl_literal (defined $opt{default} ? $opt{default} : {});
    }
  } else {
    if ($value) {
      if ($value->get_attribute_value ('is-null', default => 0)) {
        $r = 'undef';
      } else {
        $r = perl_literal $value->value;
      }
    } else {
      if (exists $opt{default}) {
        $r = defined $opt{default} ? perl_literal $opt{default} : 'undef';
      } else {
        $r = perl_literal '';
      }
    }
  }
  $r;
}

sub get_internal_code ($$;%) {
  my ($node, $name, %opt) = @_;
  $node = $node->parent_node;
  my $m;
  my $def;
  if ($m = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->node_type eq '#element' and
    ($you->local_name eq 'Method' or
     $you->local_name eq 'ReMethod') and
    $you->get_attribute_value ('Name') eq $name
  })) {
    $def = $m->get_attribute ('Return');
    $def = (get_perl_definition_node $def, name => 'IntDef' or
            get_perl_definition_node $def, name => 'Def') if $def;
  } elsif ($m = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->node_type eq '#element' and
    ($you->local_name eq 'Attr' or
     $you->local_name eq 'ReAttr') and
    $you->get_attribute_value ('Name') eq $name
  })) {
    $def = $m->get_attribute ('Get');
    $def = (get_perl_definition_node $def, name => 'IntDef' or
            get_perl_definition_node $def, name => 'Def') if $def;
  } elsif ($m = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->node_type eq '#element' and
    $you->local_name eq 'IntMethod' and
    $you->get_attribute_value ('Name') eq $name
  })) {
    $def = $m->get_attribute ('Return');
    $def = get_perl_definition_node $def, name => 'Def' if $def;
  } elsif ($m = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->node_type eq '#element' and
    $you->local_name eq 'IntAttr' and
    $you->get_attribute_value ('Name') eq $name
  })) {
    $def = $m->get_attribute ('Get');
    $def = get_perl_definition_node $def, name => 'Def' if $def;
  }
  if ($def) {
    return perl_code $def->value;
  } else {
    valid_warn qq<Internal method "$name" not defined>;
    is_implemented (if => $Status->{IF}, method => $name, set => 0);
    $Status->{is_implemented} = 0;
    return perl_statement perl_exception
                  level => 'EXCEPTION',
                  class => 'DOMException',
                  type => 'NOT_SUPPORTED_ERR',
                  param => {
                    ExpandedURI q<MDOM_EXCEPTION:if> => $Status->{IF},
                    ExpandedURI q<MDOM_EXCEPTION:method> => $name,
                  };
  }
} # get_internal_code

sub register_namespace_declaration ($) {
  my $node = shift;
  for (@{$node->child_nodes}) {
    if ($_->node_type eq '#element' and
        $_->local_name eq 'Namespace') {
      for (@{$_->child_nodes}) {
        $Info->{Namespace}->{$_->local_name} = $_->value;
      }
    }
  }
}

{
my $nest = 0;
sub is_implemented (%);
sub is_implemented (%) {
  my (%opt) = @_;
  my $r = 0;
  $nest++ == 100 and valid_err q<Condition loop detected>;
  my $member = ($Info->{is_implemented}->{$opt{if}}->{$opt{method} ||
                                                     $opt{attr} . '.' . $opt{on}}
            ||= {});
  if (exists $opt{set}) {
    $r = ($member->{$opt{condition} || ''} = $opt{set});
  } else {
    if (defined $member->{$opt{condition} || ''}) {
      $r = $member->{$opt{condition} || ''};
    } else {
      for (@{$Info->{Condition}->{$opt{condition} || ''}->{ISA} || []}) {
        if (is_implemented (%opt, condition => $_)) {
          $r = 1;
          last;
        }
      }
    }
  }
  $nest--;
  $r;
}
}

sub condition_match ($%) {
  my ($node, %opt) = @_;
  my $conds = $node->get_attribute_value ('Condition', default => [],
                                          as_array => 1);
  my $level = $node->get_attribute_value
                        ('Level',
                         default_list => @$conds ? []
                                                 : ($opt{level_default} || []),
                         as_array => 1);
  if (not $opt{condition}) {
    if (@$conds == 0 and @$level == 0) {
      return 1;
    } elsif (array_contains $conds, '$normal') {
      return 1;
    } elsif ($opt{ge} and not @$conds) {
      return 1;
    } elsif ($opt{any_unless_condition}) {
      return 1;
    } else {
      return 0;
    }
  } else {
    if (array_contains $conds, $opt{condition}) {
      return 1;
    } elsif ($opt{condition} =~ /^DOM(\d+)$/) {
      if ($opt{ge}) {
        for (my $i = $1; $i; $i--) {
          if (array_contains $level, $i) {
            return 1;
          }
        }
      } else {
        if ($1 and array_contains $level, $1) {
          return 1;
        }
      }
    }
    ## 'default_any': Match to 'any' condition (no condition specified)
    if ($opt{default_any} and @$conds == 0 and @$level == 0) {
      return 1;
    }
    return 0;
  }
}

=head1 SOURCE FORMAT

"Dis" (DOM implementation source) file is written in
SuikaWikiConfig/2.0 text format.

=head2 IF element

C<IF> element defines a DOM interface with its descriptions
and implementations.

Children elements:

=over 4

=item IF/Name = name (1 - 1)

Interface name.  It should be taken from DOM specification.

=item IF/Description = text (0 - infinite)

Description for the interface.

=item IF/ISA[list] = list of names (0 - 1)

Names of interfaces that this interface inherits.

=item IF/Method, IF/IntMethod, IF/ReMethod

Method definition.

=item IF/Attr, IF/IntAttr, IF/ReAttr

Attribute definition.

=item IF/ConstGroup

Constant value group definition.

=item IF/Const

Constant value definition.

=back

=cut

sub if2perl ($) {
  my $node = shift;
  local $Status->{depth} = $Status->{depth} + 1;
  my $pack_name = perl_package_name
                    name => my $if_name
                               = perl_name $node->get_attribute_value ('Name'),
                                           ucfirst => 1;
  my $if_pack_name = perl_package_name if => $if_name;
  local $Status->{IF} = $if_name;
  local $Status->{if} = {}; ## Temporary data
  local $Info->{Namespace} = {%{$Info->{Namespace}}};
  local $Info->{Require_perl_package} = {%{$Info->{Require_perl_package}}};
  local $Info->{Require_perl_package_use} = {};
  local $Status->{Operator} = {};
  local $Status->{is_implemented} = 1;

  my @level;
  my $mod = get_level_description $node, level => \@level;
  $mod = ', that has been ' . $mod if $mod;
  my $result = pod_block
               pod_head ($Status->{depth}, 'Interface ' . pod_code $if_name),
               pod_paras (get_description ($node)),
               pod_para ('The package ' . pod_code ($pack_name) .
                         q< implements the DOM interface > .
                         pod_code ($if_name) . $mod . q<.>);
  
  for my $condition ((sort keys %{$Info->{Condition}}), '') {
    if ($condition =~ /^DOM(\d+)$/) {
      next if @level and $level[0] > $1;
    }
    local $Status->{condition} = $condition;
    my $cond_if_pack_name = perl_package_name if => $if_name,
                                    condition => $condition;
    my $cond_pack_name = perl_package_name name => $if_name,
                                    condition => $condition;
    my $cond_int_pack_name = perl_package_name name => $if_name,
                                    condition => $condition,
                                    is_internal => 1;
    $result .= perl_package full_name => $cond_int_pack_name;
    my @isa;
    for (@{$node->child_nodes}) {
      next unless $_->node_type eq '#element' and
                  $_->local_name eq 'ISA' and
                  condition_match $_, condition => $condition,
                                      default_any => 1, ge => 1;
      push @isa, perl_package_name qname_with_condition => $_->value,
                                   condition => $condition,
                                   is_internal => 1;
    }
    push @isa, perl_package_name (name => 'ManakaiDOMObject')
      unless $if_name eq 'ManakaiDOMObject';
    $result .= perl_inherit [$cond_int_pack_name, @isa] => $cond_pack_name;
    if ($condition) {
      my @isaa;
      for (@{$Info->{Condition}->{$condition}->{ISA}}) {
        push @isaa, perl_package_name name => $if_name,
                                     condition => $_,
                                     is_internal => 1;
      }
      $result .= perl_inherit [@isaa, $cond_if_pack_name] => $cond_int_pack_name;
      $result .= perl_inherit [$if_pack_name] => $cond_if_pack_name;
    } else { ## No condition specified
      if ($Info->{NormalCondition}) {
        $result .= perl_inherit [perl_package_name name => $if_name,
                                     condition => $Info->{NormalCondition},
                                     is_internal => 1]
                              => $cond_int_pack_name;
      } else {  ## Condition not used
        $result .= perl_inherit [$if_pack_name] => $cond_int_pack_name;
      }
    }
    for my $pack ($cond_pack_name, $cond_int_pack_name,
                  $cond_if_pack_name) {
      $result .= perl_statement perl_assign
                   perl_var (type => '$',
                             package => {full_name => $pack},
                             local_name => 'VERSION')
                   => version_date time;
    }

    for (@{$node->child_nodes}) {
      my $gt = 0;
      unless (condition_match $_, level_default => \@level,
                                  condition => $condition) {
        if (condition_match $_, level_default => \@level,
                                condition => $condition, ge => 1) {
          $gt = 1;
        } else {
          next;
        }
      }
      
      if ($_->local_name eq 'Method' or
          $_->local_name eq 'IntMethod' or
          $_->local_name eq 'ReMethod') {
        $result .= method2perl ($_, level => \@level, condition => $condition)
          unless $gt;
      } elsif ($_->local_name eq 'Attr' or
               $_->local_name eq 'IntAttr' or
               $_->local_name eq 'ReAttr') {
        $result .= attr2perl ($_, level => \@level, condition => $condition)
          unless $gt;
      } elsif ($_->local_name eq 'ConstGroup') {
        $result .= constgroup2perl ($_, level => \@level,
                                    condition => $condition,
                                    without_document => $gt,
                                    package => $cond_int_pack_name);
      } elsif ($_->local_name eq 'Const') {
        $result .= const2perl ($_, level => \@level, condition => $condition,
                               package => $cond_int_pack_name)
          unless $gt;
      } elsif ($_->local_name eq 'Require') {
        $result .= req2perl ($_, level => \@level, condition => $condition);
      } elsif ({qw/Name 1 Spec 1 ISA 1 Description 1
                   Level 1 ImplNote 1/}->{$_->local_name}) {
        #
      } else {
        valid_warn qq{Element @{[$_->local_name]} not supported};
      }
    }
  }

  $result .= ops2perl;

  $result;
} # if2perl

=head2 Method, IntMethod and ReMethod elements

C<Method>, C<IntMethod> and C<ReMethod> element defines a method.
Methods defined by C<Method> are ones as defined in the DOM
specification.  Methods defined by C<IntMethod> are only for
internal use and usually not defined by the specifications.
Methods defined by C<ReMethod> do actually not belong
to this interface but to ancestor interface in the specification
but overriddenly re-defined for this type of descendant interfaces
(for example, some methods defined in Node interface of the DOM
Core Module are re-defined in Element, Attr or other node-type
interfaces, since those methods work differently by type of
the node).

Children elements:

=over 4

=item Name = name (1 - 1)

Method name.  It should be taken from DOM specification
if element type is C<Method> or C<ReMethod>.  Method name
for C<ReMethod> must be used as the name of the C<Method>
defined in ancestor interface.  Method name for C<IntMethod>
must be different with any other C<Method>, C<IntMethod>
or C<ReMethod> (including those defined by ancestor interfaces).

=item Description = text (0 - infinite)

Description for the method.

=back

=cut

sub method2perl ($;%) {
  my ($node, %opt) = @_;
  local $Status->{depth} = $Status->{depth} + 1;
  my $m_name = perl_name $node->get_attribute_value ('Name');
  my $level;
  my @level = @{$opt{level} || []};
  local $Status->{Method} = $m_name;
  local $Status->{is_implemented} = 1;
  my $result = '';
  if ($node->local_name eq 'IntMethod') {
    $m_name = perl_internal_name $m_name;
    $level = '';
  } else {
    $level = get_level_description $node, level => \@level;
  }
  
  my @param_list;
  my $param_prototype = '$';
  my @param_desc;
  my @param_domstring;
  if ($node->get_attribute ('Param')) {
    for (@{$node->child_nodes}) {
      if ($_->local_name eq 'Param') {
        my $name = perl_name $_->get_attribute_value ('Name');
        my $type = type_expanded_uri $_->get_attribute_value
                                            ('Type',
                                             default => 'DOMMain:any');
        push @param_list, '$' . $name;
        push @param_desc, pod_item (pod_code '$' . $name);
        if (type_isa $type, ExpandedURI q<DOMMain:DOMString>) {
          push @param_domstring, [$name, $type];
        }
        push my @param_desc_val,
                          pod_item (type_label $type),
                          pod_para get_description $_;
        $param_prototype .= '$';
        for (@{$_->child_nodes}) {
          next unless $_->local_name eq 'InCase';
          push @param_desc_val, pod_item (get_incase_label $_, is_pod => 1),
                                pod_para (get_description $_);
        }
        push @param_desc, pod_list 4, @param_desc_val;
      }
    }
  }
  
  my $return = $node->get_attribute ('Return', make_new_node => 1);
  my $has_return = $return->get_attribute_value ('Type', default => 0) ? 1 : 0;
  push my @desc,
               pod_head ($Status->{depth}, 'Method ' . 
                         pod_code (($has_return ? '$return = ' : '') .
                         '$obj->' . $m_name .
                         ' (' . join (', ', @param_list) . ')')),
               pod_paras (get_description ($node)),
               $level ? pod_para ('The method ' . pod_code ($m_name) .
                           q< has been > . $level . '.') : ();

  if (@param_list) {
    push @desc, pod_para ('This method requires ' .
                          english_number (@param_list + 0,
                                          singular => q<parameter>,
                                          plural => q<parameters>) . ':'),
                pod_list (4, @param_desc);                           
  } else {
    push @desc, pod_para (q<This method has no parameter.>);
  }

  my @return;
  my @exception;
  my $has_exception = 0;
  my $code_node = get_perl_definition_node $return,
                              condition => $opt{condition},
                              level_default => $opt{level_default};
  my $int_code_node = get_perl_definition_node $return, name => 'IntDef',
                              condition => $opt{condition},
                              level_default => $opt{level_default};
  my $code = '';
  my $int_code = '';
  if ($code_node) {
    $code = perl_code_source (perl_code ($code_node->value,
                                         internal => sub {
                                           return get_internal_code ($node, 
                                                                     $_[0])
                                             if $_[0];
                                           if ($int_code_node) {
                                             perl_code $int_code_node->value,
                                               internal => sub {
                                                 $_[0]?get_internal_code
                                                         ($node, $_[0]) :
                                                 valid_err q<Preprocessing >.
                                                   q<macro INT cannot be used >.
                                                   q<here>;
                                               };
                                           } else {
                                             valid_err "<IntDef> for $m_name" .
                                                       " required";
                                           }
                                         }),
                              path => $code_node->node_path (key => 'Name'));
    if ($has_return) {
      $code = perl_statement (perl_assign 'my $r' => get_value_literal $return,
                                                        name => 'DefaultValue',
                                                        type_name => 'Type') .
              $code;
      if ($code_node->get_attribute_value ('cast-output', default => 1)) {
        my $type = type_normalize
              type_expanded_uri $return->get_attribute_value
                                         ('Type',
                                          default => q<DOMMain:any>);
        if (type_isa $type, ExpandedURI q<DOMMain:DOMString>) {
          $code .= perl_builtin_code $type,
                                     s => 'r', r => 'r',
                                     condition => $opt{condition};
        }
      }
      $code .= perl_statement ('$r');
    }
    if ($code_node->get_attribute_value ('auto-argument', default => 1)) {
      if ($code_node->get_attribute_value ('cast-input', default => 1)) {
        for (@param_domstring) {
          $code = perl_builtin_code ($_->[1],
                                     s => $_->[0], r => $_->[0],
                                     condition => $opt{condition}) . $code;
        }
      }
      $code = perl_statement (perl_assign 'my (' .
                                          join (', ', '$self', @param_list) .
                                          ')' => '@_') .
              $code;
    }
    if ($int_code_node) {
      $int_code = perl_code_source (perl_code ($int_code_node->value,
                                               internal => sub {
                $_[0] ? get_internal_code $node, $_[0] :
                valid_err q<Preprocessing macro INT cannot be used here>;
                                               }),
                                    path => $int_code_node->node_path
                                              (key => 'Name'));
      $int_code = perl_statement (perl_assign 'my $r' => perl_literal '') .
                  $int_code .
                  perl_statement ('$r')
        if $has_return;
      $int_code = perl_statement (perl_assign 'my (' .
                                        join (', ', '$self', @param_list) .
                                        ')' => '@_') .
                  $int_code
         if $int_code_node->get_attribute_value ('auto-argument', default => 1);
    }

    if ($has_return) {
      push @return, pod_item (type_label type_expanded_uri
                                     $return->get_attribute_value
                                                ('Type',
                                                 default => 'DOMMain:any')),
                    pod_para (get_description $return);
    }
    for (@{$return->child_nodes}) {
      if ($_->local_name eq 'InCase') {
        push @return, pod_item ( get_incase_label $_, is_pod => 1),
                      pod_para (get_description $_);
        $has_return++;
      } elsif ($_->local_name eq 'Exception') {
        push @exception, pod_item ('Exception: ' .
                                pod_code (type_label ($_->get_attribute_value
                                                   ('Type',
                                                    default => 'DOMMain:any'))) .
                                '.' . pod_code $_->get_attribute_value
                                                   ('Name',
                                                    default => '<unknown>')),
                      pod_para (get_description $_);
        $has_exception++;
      }
    }
  } else {
    $int_code = $code
              = perl_statement ('my $self = shift').
                perl_statement perl_exception
                  level => 'EXCEPTION',
                  class => 'DOMException',
                  type => 'NOT_SUPPORTED_ERR',
                  param => {
                    ExpandedURI q<MDOM_EXCEPTION:if> => $Status->{IF},
                    ExpandedURI q<MDOM_EXCEPTION:method> => $Status->{Method},
                  };
    @return = ();
    push @exception, pod_item ('Exception: ' . pod_code ('DOMException') . '.' .
                            pod_code ('NOT_SUPPORTED_ERR')),
                  pod_para ('Call of this method allways result in
                             this exception raisen, since this
                             method is not implemented yet.');
    $has_return = 0;
    $has_exception = 1;
  }
  is_implemented if => $Status->{IF}, method => $Status->{Method},
                 condition => $opt{condition}, set => $Status->{is_implemented};
  if ($has_return or $has_exception) {
    if ($has_return) {
      push @desc, pod_para (q<This method results in > .
                           ($has_return == 1 ? q<the value:>
                                             : q<either:>)),
                  pod_list 4, pod_item (pod_code q<$return>),
                              pod_list (4, @return),
                              @exception;
    } elsif ($has_exception) {
      push @desc, pod_para (q<This method does not return any value,
                              but it might raise > .
                            ($has_exception == 1 ? q<an exception:>
                                                 : q<one of exceptions from:>)),
                  pod_list 4, @exception;
    }
  } else {
    push @desc, pod_para q<This method does not return any value
                           nor does raise any exceptions.>;
  }

  if ($node->local_name eq 'IntMethod' or
      $Status->{if}->{method_documented}->{$m_name}++) {
    $result .= pod_block pod_comment @desc;
  } else {
    $result .= pod_block @desc;
  }
  
  $result .= perl_sub name => $m_name,
                      prototype => $param_prototype,
                      code => $code;
  $result .= perl_sub name => perl_internal_name $m_name,
                      prototype => $param_prototype,
                      code => $int_code
     if $int_code_node;

  if (my $op = get_perl_definition_node $node, name => 'Operator') {
    $Status->{Operator}->{$op->value} = '\\' . perl_var type => '&', 
                                                        local_name => $m_name;
  }

  $result;
} # method2perl

sub attr2perl ($;%) {
  my ($node, %opt) = @_;
  local $Status->{depth} = $Status->{depth} + 1;
  my $m_name = perl_name $node->get_attribute_value ('Name');
  my $level;
  my @level = @{$opt{level} || []};
  local $Status->{Method} = $m_name;
  local $Status->{is_implemented} = 1;
  my $result = '';
  if ($node->local_name eq 'IntAttr') {
    $m_name = perl_internal_name $m_name;
    $level = '';
  } else {
    $level = get_level_description $node, level => \@level;
  }
  
  my $return = $node->get_attribute ('Get', make_new_node => 1);
  my $set = $node->get_attribute ('Set');
  my $has_set = defined $set ? 1 : 0;
  push my @desc,
               pod_head ($Status->{depth}, 'Attribute ' . 
                         pod_code ('$obj->' . $m_name)),
               pod_paras (get_description ($node)),
               $level ? pod_para ('The method ' . pod_code ($m_name) .
                           q< has been > . $level . '.') : ();

  my @return;
  my $code_node = get_perl_definition_node $return,
                              condition => $opt{condition},
                              level_default => $opt{level_default},
                              use_dis => 1;
  my $int_code_node = get_perl_definition_node $return, name => 'IntDef',
                              condition => $opt{condition},
                              level_default => $opt{level_default},
                              use_dis => 1;
  my ($set_code_node, $int_set_code_node);
  if ($has_set) {
    $set_code_node = get_perl_definition_node $set,
                              condition => $opt{condition},
                              level_default => $opt{level_default},
                              use_dis => 1;
    $int_set_code_node = get_perl_definition_node $set, name => 'IntDef',
                              condition => $opt{condition},
                              level_default => $opt{level_default},
                              use_dis => 1;
  }
  my $code = '';
  my $int_code = '';
  my $set_code = '';
  my $int_set_code = '';
  for ({code => \$code, code_node => $code_node,
        internal => sub {
          return get_internal_code $node, $_[0] if $_[0];
          if ($int_code_node) {
            perl_code $int_code_node->value,
              internal => sub {
                $_[0] ? get_internal_code $node, $_[0] :
                valid_err q<Preprocessing macro INT cannot be used here>;
              };
          } else {
            valid_err "<IF[Name = $Status->{IF}]/Attr[Name = $m_name]/" .
                      "Get/IntDef> required";
          }
        }},
       {code => \$int_code, code_node => $int_code_node,
        internal => sub {$_[0]?get_internal_code $node,$_[0]:
                         valid_err q<Preprocessing macro INT cannot be> .
                                   q<used here>}},
       {code => \$set_code, code_node => $set_code_node,
        internal => sub {
          return get_internal_code $node, $_[0] if $_[0];
          if ($int_set_code_node) {
            perl_code $int_set_code_node->value,
              internal => sub {
                $_[0] ? get_internal_code $node, $_[0] :
                valid_err q<Preprocessing macro INT cannot be used here>;
              };
          } else {
            valid_err "<IF[Name = $Status->{IF}]/Attr[Name = $m_name]/" .
                      "Set/IntDef> required";
          }
        }},
       {code => \$int_set_code, code_node => $int_set_code_node,
        internal => sub {$_[0]?get_internal_code $node,$_[0]:
                         valid_err q<Preprocessing macro INT cannot be> .
                                   q<used here>}}) {
    if ($_->{code_node}) {
      my $mcode;
      if (type_expanded_uri ($_->{code_node}->get_attribute_value
                                                  ('Type', default => ''))
            eq ExpandedURI q<lang:dis>) {
        $mcode = dis2perl $_->{code_node};
      } else {
        $mcode = perl_code $_->{code_node}->value,
                           internal => $_->{internal};
      }
      if ($mcode =~ /^\s*$/) {
        ${$_->{code}} = '';
      } else {
        ${$_->{code}} = perl_code_source ($mcode,
                                          path => $_->{code_node}->node_path
                                                              (key => 'Name'));
      }
    }
  }

  if ($code_node) {
    is_implemented if => $Status->{IF}, attr => $Status->{Method},
                   condition => $opt{condition}, set => 1, on => 'get';
    my $co = $code_node->get_attribute_value ('cast-output',
                                              default => $code eq '' ? 0 : 1);
    if ($code eq '' and not $co) {
      $code = perl_statement get_value_literal $return,
                                               name => 'DefaultValue',
                                               type_name => 'Type';
    } else {
      $code = perl_statement (perl_assign 'my $r' => get_value_literal $return,
                                                        name => 'DefaultValue',
                                                        type_name => 'Type') .
              $code;
      if ($co) {
        my $type = type_normalize
              type_expanded_uri $return->get_attribute_value
                                         ('Type',
                                          default => q<DOMMain:any>);
        if (type_isa $type, ExpandedURI q<DOMMain:DOMString>) {
          $code .= perl_builtin_code $type,
                                     s => 'r', r => 'r',
                                     condition => $opt{condition};
        }
      }
      $code .= perl_statement ('$r');
    }
    $code = get_warning_perl_code ($return) . $code;
    if ($int_code_node) {
      $int_code = perl_statement (perl_assign 'my $r' => perl_literal '') .
                  $int_code .
                  perl_statement ('$r');
      $int_code = perl_statement (perl_assign 'my ($self)' => '@_') . $int_code
         if $int_code_node->get_attribute_value ('auto-argument', default => 1);
    }

    push @return, pod_item ('Return Value: ' .
                              type_label type_expanded_uri
                                     $return->get_attribute_value
                                                ('Type',
                                                 default => 'DOMMain:any')),
                    pod_para (get_description $return);
    for (@{$return->child_nodes}) {
      if ($_->local_name eq 'InCase') {
        push @return, pod_item ('Return Value: ' . get_incase_label $_,
                                                                    is_pod => 1),
                      pod_para (get_description $_);
      } elsif ($_->local_name eq 'Exception') {
        push @return, pod_item ('Exception: ' .
                                pod_code (type_label ($_->get_attribute_value
                                                   ('Type',
                                                    default => 'DOMMain:any'))) .
                                '.' . pod_code $_->get_attribute_value
                                                   ('Name',
                                                    default => '<unknown>')),
                      pod_para (get_description $_);
      }
    }
  } else {
    is_implemented if => $Status->{IF}, attr => $Status->{Method},
                   condition => $opt{condition}, set => 0, on => 'get';
    $Status->{is_implemented} = 0;
    $int_code = $code
              = perl_statement perl_exception
                  level => 'EXCEPTION',
                  class => 'DOMException',
                  type => 'NOT_SUPPORTED_ERR',
                  param => {
                    ExpandedURI q<MDOM_EXCEPTION:if> => $Status->{IF},
                    ExpandedURI q<MDOM_EXCEPTION:attr> => $Status->{Method},
                    ExpandedURI q<MDOM_EXCEPTION:on> => 'get',
                  };
    @return = ();
    push @return, pod_item ('Exception: ' . pod_code ('DOMException') . '.' .
                            pod_code ('NOT_SUPPORTED_ERR')),
                  pod_para ('Getting of this attribute allways result in
                             this exception raisen, since this
                             attribute is not implemented yet.');
  }

  my @set_desc;
  my @set_xcept;
  if ($set_code_node) {
    is_implemented if => $Status->{IF}, attr => $Status->{Method},
                   condition => $opt{condition}, set => 1, on => 'set';
    if ($code_node->get_attribute_value ('cast-input',
                                         default => $set_code eq '' ? 0 : 1)) {
      my $type = type_normalize
              type_expanded_uri $set->get_attribute_value
                                         ('Type',
                                          default => q<DOMMain:any>);
      if (type_isa $type, ExpandedURI q<DOMMain:DOMString>) {
        $set_code = perl_builtin_code ($type,
                                       s => 'given', r => 'given',
                                       condition => $opt{condition})
                  . $set_code;
      }
    }
    $set_code = get_warning_perl_code ($set) . $set_code;

    push @set_desc, pod_item ('Setting Value: ' .
                              type_label type_expanded_uri
                                     $set->get_attribute_value
                                                ('Type',
                                                 default => 'DOMMain:any')),
                    pod_para (get_description $set);
    for (@{$set->child_nodes}) {
      if ($_->local_name eq 'InCase') {
        push @set_desc, pod_item ('Setting Value: ' . get_incase_label $_,
                                                                  is_pod => 1),
                        pod_para (get_description $_);
      } elsif ($_->local_name eq 'Exception') {
        push @set_xcept, pod_item ('Exception: ' .
                                pod_code (type_label ($_->get_attribute_value
                                                   ('Type',
                                                    default => 'DOMMain:any'))) .
                                '.' . pod_code $_->get_attribute_value
                                                   ('Name',
                                                    default => '<unknown>')),
                      pod_para (get_description $_);
      }
    }
  } elsif ($has_set) {
    is_implemented if => $Status->{IF}, attr => $Status->{Method},
                   condition => $opt{condition}, set => 0, on => 'set';
    $Status->{is_implemented} = 0;
    $int_set_code = $set_code
              = perl_statement perl_exception
                  level => 'EXCEPTION',
                  class => 'DOMException',
                  type => 'NOT_SUPPORTED_ERR',
                  param => {
                    ExpandedURI q<MDOM_EXCEPTION:if> => $Status->{IF},
                    ExpandedURI q<MDOM_EXCEPTION:attr> => $Status->{Method},
                    ExpandedURI q<MDOM_EXCEPTION:on> => 'set',
                  };
    @set_xcept = ();
    push @set_xcept, pod_item ('Exception: ' . pod_code ('DOMException') . '.' .
                            pod_code ('NOT_SUPPORTED_ERR')),
                  pod_para ('Setting of this attribute allways result in
                             this exception raisen, since this
                             attribute is not implemented yet.');
  }
  
  if ($has_set) {
    push @desc, pod_para ('This attribute can be set the value by:'),
                pod_pre (qq{\$obj->$m_name (\$given)}),
                pod_para ('Value to set to this attribute:'),
                pod_list 4, @set_desc;
  } else {
    push @desc, pod_para ('This attribute is read-only.');
  }
  is_implemented if => $Status->{IF}, method => $Status->{Method},
                 condition => $opt{condition}, set => $Status->{is_implemented};

  push @desc, pod_list 4,
                  pod_item (q<Result on getting:>),
                  pod_list (4, @return),
                  (@set_xcept ?
                    (pod_item (q<Exception on setting:>),
                     pod_list (4, @set_xcept)) : ());

  if ($node->local_name eq 'IntAttr' or
      $Status->{if}->{method_documented}->{$m_name}++) {
    $result .= pod_block pod_comment @desc;
  } else {
    $result .= pod_block @desc;
  }
  
  my $warn = get_warning_perl_code ($node);
  my $proto;
  if ($has_set) {
    $code = perl_statement (perl_assign
              perl_var (scope => 'my', type => '$', local_name => 'self')
               => 'shift').
            $warn.
            perl_if
              q<exists $_[0]>,
              ($set_code =~/\bgiven\b/ ?
                    perl_statement (q<my $given = shift>) : '') . $set_code,
              $code;
    $int_code = perl_statement (perl_assign
              perl_var (scope => 'my', type => '$', local_name => 'self')
               => 'shift').
            perl_if
              q<exists $_[0]>,
              perl_statement (q<my $given = shift>) . $int_set_code,
              $int_code;
    $proto = '$;$';
  } else {
    $code = q<my $self = shift; > . $warn . $code;
    $int_code = q<my $self = shift; > . $int_code;
    $proto = '$';
  }
  $result .= perl_sub name => $m_name,
                      prototype => $proto,
                      code => $code;
  $result .= perl_sub name => perl_internal_name $m_name,
                      prototype => $proto,
                      code => $int_code
     if $int_code_node;

  if (my $op = get_perl_definition_node $node, name => 'Operator') {
    $Status->{Operator}->{$op->value} = '\\' . perl_var type => '&', 
                                                        local_name => $m_name;
  }

  $result;
} # attr2perl

=head2 DataType element

The C<DataType> element defines a datatype.

=cut

sub datatype2perl ($;%) {
  my ($node, %opt) = @_;
  local $Status->{depth} = $Status->{depth} + 1;
  my $pack_name = perl_package_name
                    name => my $if_name
                                 = perl_name $node->get_attribute_value ('Name'),
                                             ucfirst => 1;
  local $Status->{IF} = $if_name;
  local $Status->{if} = {}; ## Temporary data
  local $Info->{Namespace} = {%{$Info->{Namespace}}};
  local $Info->{Require_perl_package} = {%{$Info->{Require_perl_package}}};
  local $Info->{Require_perl_package_use} = {};
  local $Status->{Operator} = {};
  my $result = perl_package full_name => $pack_name;
  my @isa;
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element' and
                $_->local_name eq 'ISA' and
                condition_match $_, condition => $opt{condition},
                                    default_any => 1, ge => 1;
    push @isa, perl_package_name qname_with_condition => $_->value,
                                 condition => $opt{condition};
  }
  $result .= perl_inherit [@isa, perl_package_name (name => 'ManakaiDOMObject'),
                           perl_package_name (if => $if_name)];
  for my $pack ({full_name => $pack_name}, {if => $if_name}) {
    $result .= perl_statement perl_assign
                 perl_var (type => '$',
                           package => $pack,
                           local_name => 'VERSION')
                 => version_date time;
  }
  
  my @level = @{$opt{level} || []};
  my $mod = get_level_description $node, level => \@level;
  $result .= pod_block
               pod_head ($Status->{depth}, 'Type ' . pod_code $if_name),
               pod_paras (get_description ($node)),
               ($mod ? pod_para ('This type is ' . $mod) : ());

  for (@{$node->child_nodes}) {
    if ($_->local_name eq 'Method' or
        $_->local_name eq 'IntMethod') {
      $result .= method2perl ($_, level => \@level, 
                              condition => $opt{condition});
    } elsif ($_->local_name eq 'Attr' or
             $_->local_name eq 'IntAttr') {
      $result .= attr2perl ($_, level => \@level, condition => $opt{condition});
    } elsif ($_->local_name eq 'ConstGroup') {
      $result .= constgroup2perl ($_, level => \@level, 
                                  condition => $opt{condition},
                                  package => $pack_name);
    } elsif ($_->local_name eq 'Const') {
      $result .= const2perl ($_, level => \@level,
                             condition => $opt{condition},
                             package => $pack_name);
    } elsif ($_->local_name eq 'ISA') {
      push @{$Info->{DataTypeAlias}->{type_expanded_uri $if_name}
                  ->{isa_uri}||=[]},
           type_expanded_uri $_->value;
    } elsif ({qw/Name 1 Spec 1 Description 1
                 Level 1 Def 1 ImplNote 1/}->{$_->local_name}) {
      #
    } else {
      valid_warn qq{Element @{[$_->local_name]} not supported};
    }
  }

  $result .= ops2perl;

  $result;
} # datatype2perl

sub datatypealias2perl ($;%) {
  my ($node, %opt) = @_;
  local $Status->{depth} = $Status->{depth} + 1;
  my $if_name = $node->get_attribute_value ('Name');
  my $long_name = expanded_uri $if_name;
  my $real_long_name = type_expanded_uri
                         (my $real_name = $node->get_attribute_value
                                             ('Type', default => 'DOMMain:any'));
  if (type_label $real_long_name eq type_label $long_name) {
    $Info->{DataTypeAlias}->{$long_name}->{canon_uri} = $real_long_name;
    return perl_comment sprintf '%s <%s> := %s <%s>',
                                type_label $long_name, $long_name,
                                type_label $real_long_name, $real_long_name;
  }
  $Info->{DataTypeAlias}->{$long_name}->{canon_uri} = $real_long_name;
  
  $if_name = perl_name $if_name, ucfirst => 1;
  $real_name = type_package_name $real_name;
  my $pack_name = perl_package_name name => $if_name;
  local $Status->{IF} = $if_name;
  local $Status->{if} = {}; ## Temporary data
  local $Info->{Namespace} = {%{$Info->{Namespace}}};
  local $Info->{Require_perl_package} = {%{$Info->{Require_perl_package}}};
  local $Info->{Require_perl_package_use} = {};
  my $result = perl_package full_name => $pack_name;
  $result .= perl_inherit [perl_package_name (full_name => $real_name),
                           perl_package_name (if => $if_name)];
  for my $pack ({if => $if_name}) {
    $result .= perl_statement perl_assign
                 perl_var (type => '$',
                           package => $pack,
                           local_name => 'VERSION')
                 => version_date time;
  }
  
  my @level = @{$opt{level} || []};
  my $mod = get_level_description $node, level => \@level;
  $result .= pod_block
               pod_head ($Status->{depth}, 'Type ' . pod_code $if_name),
               pod_paras (get_description ($node)),
               pod_para ('This type is an alias of the type ' .
                         pod_code (type_label $real_long_name) . '.'),
               ($mod ? pod_para ('This type is ' . $mod) : ());

  for (@{$node->child_nodes}) {
    if ({qw/Name 1 Spec 1 Type 1 Description 1
            Level 1 Condition 1 ImplNote 1/}->{$_->local_name}) {
      #
    } else {
      valid_warn qq{Element @{[$_->local_name]} not supported};
    }
  }

  $result;
} # datatypealias2perl

=item Exception top-level element

=item Warning top-level element

=cut

sub exception2perl ($;%) {
  my ($node, %opt) = @_;
  local $Status->{depth} = $Status->{depth} + 1;
  local $Status->{const} = {};
  local $Status->{if} = {}; ## Temporary data
  local $Info->{Namespace} = {%{$Info->{Namespace}}};
  local $Info->{Require_perl_package} = {%{$Info->{Require_perl_package}}};
  local $Info->{Require_perl_package_use} = {};
  my $pack_name = perl_package_name
                    name => my $if_name
                                 = perl_name $node->get_attribute_value ('Name'),
                                             ucfirst => 1;
  my $type = $node->local_name eq 'Exception' ? 'Exception' : 'Warning';
  local $Status->{IF} = $if_name;
  my $result = perl_package full_name => $pack_name;
  $result .= perl_statement perl_assign 'our $VERSION', version_date time;
  $result .= perl_statement 'push our @ISA, ' .
                            perl_list 'Message::Util::Error',
                                      perl_package_name (if => $if_name),
                                      $ManakaiDOMModulePrefix . '::' . $type;
  my @level = @{$opt{level} || []};
  my $mod = get_level_description $node, level => \@level;
  $result .= pod_block
               pod_head ($Status->{depth}, $type . ' ' . pod_code $if_name),
               pod_paras (get_description ($node)),
               ($mod ? pod_para ('This ' . lc ($type) . ' is introduced in ' .
                                 $mod . '.') : ()),
               ($type eq 'Exception' ? 
                 (pod_para ('To catch this class of exceptions:'),
                  pod_pre (join "\n",
                           q|try {                                 |,
                           q|  ...                                 |,
                           q|} catch | . $pack_name . q| with {    |,
                           q|  my $err = shift;                    |,
                           q|  if ($err->{type} eq 'ERROR_NAME') { |,
                           q|    ... # Recover from some error,    |,
                           q|  } else {                            |,
                           q|    $err->throw; # rethrow if other   |,
                           q|  }                                   |,
                           q|}; # Don't forget semicolon!          |))
               : ());  

  for (@{$node->child_nodes}) {
    if ($_->local_name eq 'Method' or
        $_->local_name eq 'IntMethod') {
      $result .= method2perl ($_, level => \@level, 
                              condition => $opt{condition},
                              any_unless_condition => 1);
    } elsif ($_->local_name eq 'Attr' or
             $_->local_name eq 'IntAttr') {
      my $get;
      if ($_->local_name eq 'Attr' and
          $_->get_attribute_value ('Name') eq 'code' and
          $get = $_->get_attribute ('Get') and
          not get_perl_definition_node $get, name => 'Def') {
        for ($get->append_new_node (type => '#element',
                                    local_name => 'Def',
                                    value => q{
                                      $r = $self->{<Q:ManakaiDOM:code>};
                                    })) {
          $_->set_attribute (type => 'lang:Perl'); ## ISSUE: NS prefix assoc.
        }
      }
      $result .= attr2perl ($_, level => \@level, condition => $opt{condition},
                            any_unless_condition => 1);
    } elsif ($_->local_name eq 'ConstGroup') {
      $result .= constgroup2perl ($_, level => \@level, 
                                  condition => $opt{condition},
                                  package => $pack_name,
                                  any_unless_condition => 1);
    } elsif ($_->local_name eq 'Const') {
      $result .= const2perl ($_, level => \@level,
                             condition => $opt{condition},
                             package => $pack_name,
                             any_unless_condition => 1);
    } elsif ({qw/Name 1 Spec 1 Description 1
                 Level 1 Condition 1 ImplNote 1/}->{$_->local_name}) {
      #
    } else {
      valid_warn qq{Element @{[$_->local_name]} not supported};
    }
  }

  $result .= perl_sub
               name => '___error_def', prototype => '',
               code => perl_list {
                 map {
                   $_ => {
                     ExpandedURI q<ManakaiDOM:code> => perl_code_literal
                               ($Status->{const}->{$_}->{code_literal}),
                     ExpandedURI q<ManakaiDOM:description>
                            => $Status->{const}->{$_}->{description},
                   }
                 } sort keys %{$Status->{const}}
               };

  $result;
} # exception2perl

sub constgroup2perl ($;%);
sub constgroup2perl ($;%) {
  my ($node, %opt) = @_;
  local $Status->{depth} = $Status->{depth} + 1;
  my $name = perl_name $node->get_attribute_value ('Name');
  local $Status->{IF} = $name;
  my @level = @{$opt{level} || []};
  my $mod = get_level_description $node, level => \@level;
  my $result = '';
  my $consts = {};

  my $i = 0;
  {
    local $Status->{EXPORT_OK} = $consts;
    for (@{$node->child_nodes}) {
      my $only_document = $opt{only_document} || 0;
      unless ($_->node_type eq '#element' and
              condition_match $_, level_default => \@level,
                                  condition => $opt{condition},
                                  any_unless_condition
                                            => $opt{any_unless_condition}) {
        $only_document = 1;
      }
      
      if ($_->local_name eq 'ConstGroup') {
        $result .= constgroup2perl ($_, level => \@level, 
                                    condition => $opt{condition},
                                    without_document => $opt{without_document},
                                    only_document => $only_document,
                                    package => $opt{package},
                                    any_unless_condition
                                            => $opt{any_unless_condition});
        $i++;
      } elsif ($_->local_name eq 'Const') {
        $result .= const2perl ($_, level => \@level,
                               condition => $opt{condition},
                               without_document => $opt{without_document},
                               only_document => $only_document,
                               package => $opt{package},
                               any_unless_condition
                                       => $opt{any_unless_condition});
        $i++;
      } elsif ({qw/Name 1 Spec 1 ISA 1 Description 1
                   Level 1 Def 1 ImplNote 1/}->{$_->local_name}) {
        #
      } else {
        valid_warn qq{Element @{[$_->local_name]} not supported};
      }
    }
  }
  
  for (keys %$consts) {
    $Status->{EXPORT_OK}->{$_} = 1;
    $Status->{EXPORT_TAGS}->{$name}->{$_} = 1;
  }
    
  return $result if $opt{without_document};

  $result = pod_block
              (pod_head ($Status->{depth}, 'Constant Group ' . pod_code $name),
               pod_paras (get_description ($node)),
               ($mod ? pod_para ('This constant group has been ' . $mod . '.')
                    : ()),
               pod_para ('This constant group has ' .
                         english_number $i, singular => q<value.>,
                                            plural => q<values.>),
               pod_para ('To export all constant values in this group:'),
               pod_pre (perl_statement "use $Info->{Package} qw/:$name/")
              ) .
            $result;

  $result;
} # constgroup2perl

sub const2perl ($;%) {
  my ($node, %opt) = @_;
  local $Status->{depth} = $Status->{depth} + 1;
  my $name = perl_name $node->get_attribute_value ('Name');
  my $longname = perl_var local_name => $name,
                          package => {full_name => $opt{package} ||
                                                   $Info->{Package}};
  local $Status->{IF} = $name;
  my @level = @{$opt{level} || []};
  my $mod = get_level_description $node, level => \@level;
  my @desc =  (pod_head ($Status->{depth}, 'Constant Value ' . pod_code $name),
               pod_paras (get_description ($node)),
               ($mod ? pod_para ('This constant value has been ' . $mod . '.')
                     : ()));

  push @desc, pod_para ('To export this constant value:'),
              pod_pre (perl_statement "use $Info->{Package} qw/$name/");
  
  my $result = '';
  unless ($opt{only_document}) {
    $result = perl_sub name => $longname, prototype => '',
                       code => my $code = get_value_literal
                                                $node, name => 'Value';
    $result .= perl_statement
                 perl_assign
                      perl_var (type => '*',
                                package => {full_name => $Info->{Package}},
                                local_name => $name)
                   => '\&' . $longname
       if $opt{package} and $Info->{Package} ne $opt{package};
    my $desc_template = get_perl_definition_node ($node);
    if ($desc_template) {
      $desc_template = muf_template get_description $desc_template;
    } else {
      $desc_template = get_description ($node, default => $name);
    }
    $Status->{const}->{$name} = {
      description => $desc_template,
      code_literal => $code,
    };
  }

  $Status->{EXPORT_OK}->{$name} = 1;

  unless ($opt{without_document}) {
    $result = pod_block (@desc) . $result;
  }

  $result;
} # const2perl

=head2 Require element

The C<Require> element indicates that some external modules
are required.  Both DOM-implementing modules and language-specific 
library modules are allowed.

Children:

=over 4

=item Require/Module (0 - infinite)

A required module.

Children:

=over 4

=item Require/Module/Name = name (0 - 1)

The DOM module name.  Iif it is a DOM-implementing module,
this attribute MUST be specified.

=item Require/Module/Namespace = namespace-uri (0 - 1)

The namespace URI for the module, if any.  Namespace prefix
C<Name> is to be binded with C<Namespace> if both
C<Name> and C<Namespace> are available.

=item Require/Module/Def = Type-dependent (0 - infinite)

Language-depending definition of loading of the required module.
If no appropriate C<Type> of C<Def> element is available,
loading code is generated from C<Name> attribute.

=back

=back

=cut

sub req2perl ($) {
  my $node = shift;
  my $reqnode = $node->local_name eq 'Require' ? $node :
                  $node->get_attribute ('Require', make_new_node => 1);
  my $result = '';
  for (@{$reqnode->child_nodes}) {
    if ($_->local_name eq 'Module') {
      my $m_name = $_->get_attribute_value ('Name', default => '<anon>');
      my $ns_uri = $_->get_attribute_value ('Namespace');
      $Info->{Namespace}->{$m_name} = $ns_uri;
      $m_name = perl_name $m_name, ucfirst => 1;
      my $desc = get_description $_;
      $result .= perl_comment (($m_name ne '<anon>' ? $m_name : '') .
                               ($desc ? ' - ' . $desc : ''))
        if $desc or $m_name ne '<anon>';
      my $def = get_perl_definition_node $_, name => 'Def';
      if ($def) {
        my $s;
        my $req;
        my $pack_name;
        if ($req = $def->get_attribute ('require')) {
          $s = 'require ' . ($pack_name = perl_code $req->value);
          $Info->{uri_to_perl_package}->{$ns_uri} = $pack_name if $ns_uri;
          $Info->{Require_perl_package}->{$pack_name} = 1;
        } elsif ($req = $def->get_attribute ('use')) {
          $s = 'use ' . ($pack_name = perl_code $req->value);
          $Info->{uri_to_perl_package}->{$ns_uri} = $pack_name if $ns_uri;
          $Info->{Require_perl_package}->{$pack_name} = 1;
          $Info->{Require_perl_package_use}->{$pack_name} = 1;
        } elsif (defined ($s = $def->value)) {
          # 
        } else {
          valid_warn qq<Required module definition for $m_name is empty>;
        }
        if ($req and my $list = $req->get_attribute_value ('Import',
                                                           as_array => 1)) {
          if (@$list) {
            $s .= ' ' . perl_list @$list;
            $Info->{Require_perl_package_use}
                 ->{$pack_name . '::::Import'}->{$_} = 1 for @$list;
          }
        }
        $result .= perl_statement $s;
      } else {
        $result .= perl_statement 'require ' .
                     perl_code "__CLASS{$m_name}__";
      }
    } elsif ($_->local_name eq 'Condition') {
    } else {
      valid_warn qq[Requiredness type @{[$_->local_name]} not supported];
    }
  }
  $result;
}

=head2 Module element

A "dis" file requires one (and only one) C<Module> top-level element.
Other elements, such as C<Require>, may include C<Module> elements
as their children.

Children:

=over 4

=item Module/Name = name (0 - 1)

The module name.  Usually DOM IDL module name is used.

This attribute is required when C<Module> element is used as
a top-level element.  It is optional if C<Module> is a child
of other element.

=item Module/Package = Type-dependent (0 - infinite)

The module package name.  For example,

  Module:
    @Name: module1
    @Package:
      @@@: Module1
      @@Type:
        lang:Perl

means that general module name is C<module1> and Perl-specific
module name is C<Module1>.

=item Module/Namespace = namespace (1 - 1)

The namespace URI (an absolute URI with optional fragment identifier)
that is assigned to this module.  Datatypes defined by this module
(such as C<DataType> or C<Interface>) are considered to belong to
this namespace.

In addition, the default namespace is binding to this namespace name
(in other word, special namespace prefix C<#default> is associated
with the URI reference).

=item Module/FullName = text (0 - infinite)

A human-readable module name.

=item Module/Description = text (0 - infinite)

A human-readable module description.

=item Module/License = qname (1 - 1)

A qname that identify the license term.

=item Module/Date.RCS = <rcs date> (1 - 1)

The last-modified date-time of this module,
represented in RCS format (text C<Date:> with date and time, 
enclosed by C<$>s).

=item Module/Require (0 - infinite)

A list of modules (DOM modules or other liburary modules)
that is required by entire module.

=back

=cut

## Get general information
$Info->{source_filename} = $ARGV;

## Initial DataType aliasing and inheritance
for (ExpandedURI q<ManakaiDOM:ManakaiDOMURI>,
     ExpandedURI q<ManakaiDOM:ManakaiDOMNamespaceURI>,
     ExpandedURI q<ManakaiDOM:ManakaiDOMFeatureName>,
     ExpandedURI q<ManakaiDOM:ManakaiDOMFeatureVersion>,
     ExpandedURI q<ManakaiDOM:ManakaiDOMFeatures>) {
  $Info->{DataTypeAlias}->{$_}
       ->{isa_uri} = [ExpandedURI q<DOMMain:DOMString>];
}

register_namespace_declaration ($source);

my $Module = $source->get_attribute ('Module', make_new_node => 1);
$Info->{Name} = perl_name $Module->get_attribute_value ('Name'), ucfirst => 1
  or valid_err q<Module name (/Module/Name) MUST be specified>;
$Info->{Package} = perl_code (get_perl_definition $Module, name => 'Package')
                || perl_package_name name => $Info->{Name};
$Info->{Namespace}->{(DEFAULT_PFX)}
  = $Module->get_attribute_value ('Namespace')
  or valid_err q<Module namespace URI (/Module/Namespace) MUST be specified>;
$Info->{uri_to_perl_package}->{$Info->{Namespace}->{(DEFAULT_PFX)}}
  = $Info->{Package};
$Info->{Require_perl_package} = {};
$Info->{Require_perl_package_use} = {};

## Make source code
$result .= perl_comment q<This file is automatically generated from> . "\n" .
                        q<"> . $Info->{source_filename} . q<" at > .
                        rfc3339_date (time) . qq<.\n> .
                        q<Don't edit by hand!>;

$result .= perl_statement q<use strict>;

local $Status->{depth} = $Status->{depth} + 1;
$result .= perl_package full_name => $Info->{Package};
$result .= perl_statement perl_assign 'our $VERSION' => version_date time;

$result .= pod_block
             pod_head (1, 'NAME'),
             pod_para ($Info->{Package} .
                       ' - ' . get_description ($Module, name => 'FullName')),
             section (
               opt => pod_head (1, 'DESCRIPTION'),
               req => pod_para (get_description ($Module)),
             ),
             pod_head (1, 'DOM INTERFACES');

## Conditions
  my $defcond = 0;
  for my $cond (@{$Module->child_nodes}) {
    next unless $cond->node_type eq '#element' and
                $cond->local_name eq 'ConditionDef';
    my $name = $cond->get_attribute_value ('Name', default => '');
    my $isa = $cond->get_attribute_value ('ISA', default => []);
    my $fullname = get_description $cond, name => 'FullName';
    $isa = [$isa] unless ref $isa;
    if ($name =~ /^DOM(\d+)$/) {
      $isa = ["DOM" . ($1 - 1)] if not @$isa and $1 > 1;
      $defcond = $1 if $1 > $defcond;
      $fullname ||= "DOM Level " . (0 + $1);
    }
    $Info->{Condition}->{$name}->{ISA} = $isa;
    $Info->{Condition}->{$name}->{FullName} = $fullname || $name;
  }
  if (keys %{$Info->{Condition}}) {
    $Info->{NormalCondition} = $Module->get_attribute_value
                                            ('NormalCondition') ||
                                $defcond ? 'DOM' . $defcond :
                                valid_err q<Module/NormalCondition required>;
  }

## 'require'ing external modules
{
  my $req = $Module->get_attribute ('Require', make_new_node => 1);
  my $reqModule = sub {
    my ($name, $me, $you) = @_;
    if ($you->get_attribute_value ('Name', default => '') eq $name) {
      return 1;
    } else {
      return 0;
    }
  };
  if (not $req->get_element_by (sub {$reqModule->('ManakaiDOM', @_)})) {
    for ($req->append_new_node (type => '#element',
                                local_name => 'Module')) {
      $_->set_attribute (Name => 'ManakaiDOM');
      $_->set_attribute (Namespace => ExpandedURI q<ManakaiDOM:>);
    }
  }
  if (not $req->get_element_by (sub {$reqModule->('DOMMain', @_)})) {
    for ($req->append_new_node (type => '#element',
                                local_name => 'Module')) {
      $_->set_attribute (Name => 'DOMMain');
      $_->set_attribute (Namespace => ExpandedURI q<DOMMain:>);
    }
  }
  $result .= req2perl $Module;
}

for my $node (@{$source->child_nodes}) {
  if ($node->node_type ne '#element') {
    ##
  } elsif ($node->local_name eq 'IF') {
    $result .= if2perl $node;
  } elsif ($node->local_name eq 'Exception' or
           $node->local_name eq 'Warning') {
    $result .= exception2perl $node;
  } elsif ($node->local_name eq 'DataType') {
    $result .= datatype2perl $node;
  } elsif ($node->local_name eq 'DataTypeAlias') {
    $result .= datatypealias2perl $node;
  } elsif ($node->local_name eq 'ConstGroup') {
    $result .= constgroup2perl $node;
  } elsif ($node->local_name eq 'Const') {
    $result .= const2perl $node;
  } elsif ($node->local_name eq 'Module' or $node->local_name eq 'Namespace') {
    #
  } else {
    valid_warn qq{Top-level element type "@{[$node->local_name]}" not supported};
  }
}

## Export
if (keys %{$Status->{EXPORT_OK}||{}}) {
  $result .= perl_package full_name => $Info->{Package};
  $result .= perl_statement 'require Exporter';
  $result .= perl_inherit ['Exporter'];
  $result .= perl_statement
               perl_assign
                    perl_var (type => '@', scope => 'our',
                              local_name => 'EXPORT_OK')
                 => '(' . perl_list (keys %{$Status->{EXPORT_OK}}) . ')';
  if (keys %{$Status->{EXPORT_TAGS}||{}}) {
    $result .= perl_statement
                 perl_assign
                       perl_var (type => '%', scope => 'our',
                                 local_name => 'EXPORT_TAGS')
                   => '(' . perl_list (map {
                         $_ => [keys %{$Status->{EXPORT_TAGS}->{$_}}]
                      } keys %{$Status->{EXPORT_TAGS}}) . ')';
  }
}

## Feature
my @feature_desc;
for my $condition (sort keys %{$Info->{Condition}}, '') {
  for my $Feature (@{$Module->child_nodes}) {
    next unless $Feature->node_type eq '#element' and
                $Feature->local_name eq 'Feature' and
                condition_match $Feature, condition => $condition;
    my $not_implemented;
    IF: for my $if (keys %{$Info->{is_implemented}}) {
      for my $mem (keys %{$Info->{is_implemented}->{$if}}) {
        ## Note: In fact, this checks whether the method is NOT implemented
        ##       rather than the method IS implemented.
        if (exists $Info->{is_implemented}->{$if}->{$mem}->{$condition} and
            not $Info->{is_implemented}->{$if}->{$mem}->{$condition}) {
          $not_implemented = [$if, $mem, $condition];
          last IF;
        }
      }
    }
    
    my $f_name = $Feature->get_attribute_value ('Name', default => '');
    unless (length $f_name) {
      $f_name = expanded_uri $Feature->get_attribute_value ('QName');
    }
    my $f_ver = $Feature->get_attribute_value ('Version');
    
    push @feature_desc, pod_item ('Feature ' . pod_code ($f_name) .
                                  ' version ' . pod_code ($f_ver) .
                                  ($Info->{Condition}->{$condition}->{FullName} ?
                                  ' [' . $Info->{Condition}->{$condition}
                                              ->{FullName} . ']' : '')),
                        pod_paras (get_description $Feature);

    if ($not_implemented) {
      push @feature_desc, pod_para ('This module supports the interfaces '.
                                    'in this feature but not yet fully ' .
                                    'implemented.');
      $result .= perl_comment "$f_name, $f_ver: $not_implemented->[0]." .
                              "$not_implemented->[1]<$not_implemented->[2]>" .
                              " not implemented.";
    } else {
      push @feature_desc, pod_para ('This module implements this feature, ' .
                                    'so that the method calls ' .
                                    pod_code ('$DOMImplementation' .
                                              '->hasFeature (' .
                                              perl_literal ($f_name) .
                                              ', ' . perl_literal ($f_ver) .
                                              ')') . ' and ' .
                                    pod_code ('$DOMImplementation' .
                                              '->hasFeature (' .
                                              perl_literal ($f_name) .
                                              ', null)') .
                                    ' will return ' . pod_code ('true') . '.');
      $result .= perl_statement 
                   perl_assign 
                     '$' . $ManakaiDOMModulePrefix.'::FeatureImplemented{' .
                       perl_literal (lc $f_name) . '}->{' .
                                    ## Feature name is case-insensitive.
                       perl_literal ($f_ver) . '}'
                     => 1;
    }
  }
}
if (@feature_desc) {
  $result .= pod_block 
               pod_head (1, 'DOM FEATURES'),
               pod_list 4, @feature_desc;
}

my @desc = pod_head (1, 'LICENSE');
my $license = expanded_uri
                $Module->get_attribute_value ('License', default => '');
if ($license eq ExpandedURI q<license:Perl>) {
  push @desc, 
    pod_para (q<Copyright 2004 AUTHORS.  All rights reserved.>),
    pod_para q<This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.>;
} elsif ($license) {
  push @desc,
    pod_para (q<Copyright 2004 AUTHORS.  All rights reserved.>),
    pod_para (qq<License: <$license>.>);
} else {
  valid_err q<License specification required>;
}
$result .= pod_block @desc;
             

$result .= perl_statement 1;

output_result $result;


__END__

=head1 SEE ALSO

W3C DOM Specifications <http://www.w3.org/DOM/DOMTR>

SuikaWiki:DOM <http://suika.fam.cx/~wakaba/-temp/wiki/wiki?DOM>

C<idl2dis.pl>: This script generates "dis" files,
that can be used as a template for the DOM implementation,
from DOM IDL files.

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Note that copyright holder(s) of this script does not claim 
any rights for materials outputed by this script, although it will
contain some fragments from this script.  License terms for them should be 
defined by the copyright holder of the source document.

=cut

# $Date: 2004/09/15 04:05:39 $


