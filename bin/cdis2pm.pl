#!/usr/bin/perl -w 
use strict;

=head1 NAME

cdis2pm - Generating Perl Module from a Compiled "dis"

=head1 SYNOPSIS

  perl path/to/cdis2pm.pl input.cdis \
            {--module-name=ModuleName | --module-uri=module-uri} \
            [--for=for-uri] [options] > ModuleName.pm
  perl path/to/cdis2pm.pl --help

=head1 DESCRIPTION

The C<cdis2pm> script generates a Perl module from a compiled "dis"
("cdis") file.  It is intended to be used to generate a manakai 
DOM Perl module files, although it might be useful for other purpose. 

This script is part of manakai. 

=cut

use Message::Util::QName::Filter {
  d => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  DISCore => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Core#>,
  DISLang => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#>,
  DISPerl => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#>,
  disPerl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis--Perl-->,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DOMEvents => q<http://suika.fam.cx/~wakaba/archive/2004/dom/events#>,
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>,
  DOMXML => q<http://suika.fam.cx/~wakaba/archive/2004/dom/xml#>,
  DX => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  MDOMX => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>,
  owl => q<http://www.w3.org/2002/07/owl#>,
  rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
  rdfs => q<http://www.w3.org/2000/01/rdf-schema#>,
  swcfg21 => q<http://suika.fam.cx/~wakaba/archive/2005/swcfg21#>,
  TreeCore => q<>,
};

=head1 OPTIONS

=over 4

=item --enable-assertion / --noenable-assertion (default)

Whether assertion codes should be outputed or not. 

=item --for=I<for-uri> (Optional)

Specifies the "For" URI reference for which the outputed module is. 
If this parameter is ommitted, the default "For" URI reference 
for the module, if any, or the C<ManakaiDOM:all> is assumed. 

=item --help

Shows the help message. 

=item --module-name=I<ModuleName>

The name of module to output.  It is the local name part of 
the C<Module> C<QName> in the source "dis" file.  Either 
C<--module-name> or C<--module-uri> is required. 

=item --module-uri=I<module-uri>

A URI reference that identifies a module to output.  Either 
C<--module-name> or C<--module-uri> is required. 

=item --output-module-version (default) / --nooutput-module-version

Whether the C<$VERSION> special variable should be generated or not. 

=item --verbose / --noverbose (default)

Whether a verbose message mode should be selected or not. 

=back

=cut

use Getopt::Long;
use Pod::Usage;
use Storable;
my %Opt;
GetOptions (
  'enable-assertion!' => \$Opt{outputAssertion},
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'module-name=s' => \$Opt{module_name},
  'module-uri=s' => \$Opt{module_uri},
  'output-module-version!' => \$Opt{outputModuleVersion},
  'verbose!' => $Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage (2) if not $Opt{module_uri} and not $Opt{module_name};
$Opt{outputModuleVersion} = 1 unless defined $Opt{outputModuleVersion};

BEGIN {
require 'manakai/genlib.pl';
require 'manakai/dis.pl';
}
our $State = retrieve ($Opt{file_name})
     or die "$0: $Opt{file_name}: Cannot load";

eval q{
  sub impl_msg ($;%) {
    warn shift () . "\n";
  }
} unless $Opt{verbose};

=head1 FUNCTIONS

This section describes utility functions defined in this script
for the sake of developer. 

=over 4

=item $result = perl_change_package (full_name => I<fully qualified Perl package name>)

Changes the current Perl package in the output Perl code. 
C<dispm_package_declarations> is also called in this function. 

=cut

sub perl_change_package (%) {
  my %opt = @_;
  my $fn = $opt{full_name};
  impl_err (qq<$fn: Bad package name>) unless $fn;
  unless ($fn eq $State->{ExpandedURI q<dis2pm:currentPackage>}) {
    my $r = dispm_package_declarations (%opt);
    $State->{ExpandedURI q<dis2pm:currentPackage>} = $fn;
    $State->{ExpandedURI q<dis2pm:referredPackage>}->{$fn} = -1;
    return $r . perl_statement qq<package $fn>;
  } else {
    return '';
  }
} # perl_change_package

=item $code = dispm_package_declarations (%opt)

Generates a code fragment that declares what is required 
in the current package, including import statements for 
character classes.

=cut

sub dispm_package_declarations (%) {
  my %opt = @_;
  my $pack_name = $State->{ExpandedURI q<dis2pm:currentPackage>};
  my $pack = $State->{ExpandedURI q<dis2pm:Package>}->{$pack_name};
  my $r = '';
  my @xml_class;
  for (keys %{$pack->{ExpandedURI q<dis2pm:requiredCharClass>}||{}}) {
    my $val = $pack->{ExpandedURI q<dis2pm:requiredCharClass>}->{$_};
    next if not ref $val and $val <= 0;
    if (/^InXML/) {
      push @xml_class, $_;
      $pack->{ExpandedURI q<dis2pm:requiredCharClass>}->{$_} = -1;
    } else {
      valid_err (qq<"$_": Unknown character class>,
                 node => ref $val ? $val : $opt{node});
    }
  }
  if (@xml_class) {
    $State->{Module}->{$State->{module}}
          ->{ExpandedURI q<dis2pm:requiredModule>}
          ->{'Char::Class::XML'} = 1;
    $r .= perl_statement 'Char::Class::XML->import ('.
                         perl_list (@xml_class).')';
  }
  $r;
} # dispm_package_declarations

=item $code = dispm_perl_throws (%opt)

Generates a code to throw an exception.

=cut

sub dispm_perl_throws (%) {
  my %opt = @_;
  my $x = $opt{class_resource} || $State->{Type}->{$opt{class}};
  my $r = 'report ';
  unless (defined $x->{Name}) {
    $opt{class} = dis_typeforuris_to_uri ($opt{class}, $opt{class_for}, %opt);
    $x = $State->{Type}->{$opt{class}};
  }
  valid_err (qq<Exception class <$opt{class}> is not defined>,
             node => $opt{node}) unless defined $x->{Name};
  if ($x->{ExpandedURI q<dis2pm:type>} and
      {
        ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
        ExpandedURI q<DOMMain:ErrorClass> => 1,
        ExpandedURI q<ManakaiDOM:WarningClass> => 1,
      }->{$x->{ExpandedURI q<dis2pm:type>}}) {
    $opt{type} = $opt{type_resource}->{Name} unless defined $opt{type};
    valid_err qq{Exception code must be specified},
              node => $opt{type_resource}->{src} || $opt{node}
      unless defined $opt{type};
    $opt{subtype} = $opt{subtype_resource}->{NameURI} ||
                    $opt{subtype_resource}->{URI} unless defined $opt{subtype};
    $opt{xparam}->{ExpandedURI q<MDOMX:subtype>} = $opt{subtype}
      if defined $opt{subtype};
    $r .= $x->{ExpandedURI q<dis2pm:packageName>} . ' ' .
          perl_list -type => $opt{type},
                    -object => perl_code_literal ('$self'),
                    %{$opt{xparam} || {}};
  } else {
    no warnings 'uninitialized';
    valid_err (qq{Resource <$opt{class}> [<$x->{ExpandedURI q<dis2pm:type>}>] }.
               q<is neither an exception class nor >.
               q<a warning class>, node => $opt{node});
  }
  return $r;
} # dispm_perl_throw

=item Lexical Variable $RegQNameChar

The regular expression pattern for a QName character. 

=item Lexical Variable $RegBlockContent

The regular expression pattern for a "block", i.e. a nestable section
of "{" ... "}". 

=cut

my $RegQNameChar = qr/[^\s<>"'\\\[\]\{\},=]/;
use re 'eval';
my $RegBlockContent;
$RegBlockContent = qr/(?>[^{}\\]*)(?>(?>[^{}\\]+|\\.|\{(??{$RegBlockContent})\})*)/s;

=item $result = perl_code ($code, %opt)

Converts preprocessing instructions in the <$code> and returns it. 

Note that this function is also defined in F<genlib.pl> but 
redefined here for the purpose of this script. 

=cut

sub perl_code ($;%) {
  my ($s, %opt) = @_;
  valid_err q<Uninitialized value in perl_code>,
    node => $opt{node} unless defined $s;
  $s = $$s if ref $s eq '__code';
  local $State->{Namespace}
    = $State->{Module}->{$opt{resource}->{parentModule}}->{nsBinding};
  $s =~ s[(?<![qwr])<($RegQNameChar[^<>]+)>|\b(null|true|false)\b][
    my ($q, $l) = ($1, $2);
    my $r;
    if (defined $q) {
      if ($q =~ /\}/) {
        valid_warn qq<Inline element "<$q>" has a "}" - it might be a typo>;
      }
      if ($q =~ /=$/) {
        valid_warn qq<Inline element "<$q>" ends with a "=" - >.
                   q{should "=" be used place of "=>"?};
      }
      if ($q =~ s/^(.+?):://) {
        my $et = dis_qname_to_uri
                     ($1, %opt,
                      use_default_namespace => ExpandedURI q<disPerl:>);
        if ($et eq ExpandedURI q<disPerl:Q>) {          ## QName constant
          $r = perl_literal (dis_qname_to_uri ($q, use_default_namespace => 1,
                                               %opt));
        } elsif ({
                  ExpandedURI q<disPerl:M> => 1,
                  ExpandedURI q<disPerl:ClassM> => 1,
                  ExpandedURI q<disPerl:AG> => 1,
                  ExpandedURI q<disPerl:AS> => 1,
                 }->{$et}) {     ## Method call
          my ($clsq, $mtdq) = split /\s*\.\s*/, $q, 2;
          my $clsu = dis_typeforqnames_to_uri ($clsq,
                                               use_default_namespace => 1, %opt);
          my $cls = $State->{Type}->{$clsu};
          my $clsp = $cls->{ExpandedURI q<dis2pm:packageName>};
          if ($cls->{ExpandedURI q<dis2pm:type>} and
              {
                ExpandedURI q<ManakaiDOM:IF> => 1,
                ExpandedURI q<ManakaiDOM:ExceptionIF> => 1,
              }->{$cls->{ExpandedURI q<dis2pm:type>}}) {
            valid_err q<"disPerl:ClassM" cannot be used for interface methods>,
                      node => $opt{node} if $et eq ExpandedURI q<disPerl:ClassM>;
            $clsp = '';
          } else {
            valid_err qq<Package name of class <$clsu> must be defined>,
                      node => $opt{node} unless defined $clsp;
            $State->{Module}->{$State->{module}}
                  ->{ExpandedURI q<dis2pm:requiredModule>}
                  ->{$State->{Module}->{$cls->{parentModule}}
                           ->{ExpandedURI q<dis2pm:packageName>}} = 1;
          }
          if ($mtdq =~ /:/) {
            valid_err qq<$mtdq: Prefixed method name not supported>,
                      node => $opt{node};
          } else {
            my $mtd;
            for (values %{$cls->{ExpandedURI q<dis2pm:method>}}) {
              if (defined $_->{Name} and $_->{Name} eq $mtdq) {
                $mtd = $_;
                last;
              }
            }
            valid_err qq<Perl method name for method "$clsp.$mtdq" must >.
                      q<be defined>, node => $mtd->{src} || $opt{node}
                   if not defined $mtd or
                      not defined $mtd->{ExpandedURI q<dis2pm:methodName>};
            $r = ' ' . ($clsp ? $clsp .
                                {
                                 ExpandedURI q<disPerl:M> => '::',
                                 ExpandedURI q<disPerl:AG> => '::',
                                 ExpandedURI q<disPerl:AS> => '::',
                                 ExpandedURI q<disPerl:ClassM> => '->',
                                }->{$et}
                              : '') .
                 $mtd->{ExpandedURI q<dis2pm:methodName>} . ' ';
          }
        } elsif ({
                  ExpandedURI q<disPerl:Class> => 1,
                  ExpandedURI q<disPerl:IF> => 1,
                  ExpandedURI q<disPerl:ClassName> => 1,
                  ExpandedURI q<disPerl:IFName> => 1,
                 }->{$et}) {                            ## Perl package name
          my $uri = dis_typeforqnames_to_uri ($q, 
                                              use_default_namespace => 1, %opt);
          if (defined $State->{Type}->{$uri}->{Name} and
              defined $State->{Type}->{$uri}
                            ->{ExpandedURI q<dis2pm:packageName>}) {
            $r = $State->{Type}->{$uri}->{ExpandedURI q<dis2pm:packageName>};
            if ({
                  ExpandedURI q<disPerl:ClassName> => 1,
                  ExpandedURI q<disPerl:IFName> => 1,
                }->{$et}) {
              $r = perl_literal $r;
            }
          } else {
            valid_err qq<Package name of class <$uri> must be defined>,
              node => $opt{node};
          }
        } elsif ($et eq ExpandedURI q<disPerl:Code>) {  ## CODE constant
          my ($nm);
          $q =~ s/^\s+//;
          if ($q =~ s/^((?>(?!::).)+)//) {
            $nm = $1;
          } else {
            valid_err qq<"$q": Code name required>, node => $opt{node};
          }
          $q =~ s/^::\s*//;
          my $param = dispm_parse_param (\$q, %opt,
                                         ExpandedURI q<dis2pm:endOrErr> => 1,
                                         use_default_namespace => '');
          my $uri = dis_typeforqnames_to_uri
                               ($nm, use_default_namespace => 1,
                                %opt);
          if (defined $State->{Type}->{$uri}->{Name} and
              dis_resource_ctype_match (ExpandedURI q<dis2pm:InlineCode>,
                                        $State->{Type}->{$uri}, %opt)) {
            local $State->{ExpandedURI q<dis2pm:blockCodeParam>} = $param;
            ## ISSUE: It might be required to check loop referring
            $r = dispm_get_code (%opt, resource => $State->{Type}->{$uri},
                                 For => [keys %{$State->{Type}->{$uri}
                                                      ->{For}}]->[0],
                                 'For+' => [keys %{$State->{Type}->{$uri}
                                                      ->{'For+'}||{}}],
                                 is_inline => 1,
                                 ExpandedURI q<dis2pm:selParent> => $param,
                                 ExpandedURI q<dis2pm:DefKeyName>
                                   => ExpandedURI q<d:Def>);
            for (grep {/^\$/} keys %$param) {
              $r =~ s/\Q$_\E\b/$param->{$_}/g;
            }
          } else {
            valid_err qq<Inline code constant <$uri> must be defined>,
              node => $opt{node};
          }
        } elsif ($et eq ExpandedURI q<disPerl:C>) {
          if ($q =~ /^((?>(?!\.)$RegQNameChar)*)\.($RegQNameChar+)$/o) {
            my ($cls, $constn) = ($1, $2);
            if (length $cls) {
              my $clsu = dis_typeforqnames_to_uri ($cls, %opt,
                                                   use_default_namespace => 1,
                                                   node => $_);
              $cls = $State->{Type}->{$clsu};
              valid_err qq<Class/IF <$clsu> must be defined>, node => $_
                unless defined $cls->{Name};
            } else {
              $cls = $State->{ExpandedURI q<dis2pm:thisClass>};
              valid_err q<Class/IF name required in this context>, node => $_
                unless defined $cls->{Name};
            }
            
            my $const = $cls->{ExpandedURI q<dis2pm:const>}->{$constn};
            valid_err qq<Constant value "$constn" not defined in class/IF >.
                      qq{"$cls->{Name}" (<$cls->{URI}>)}, node => $_
                        unless defined $const->{Name};
            $r = dispm_const_value (resource => $const);
          } else {
            valid_err qq<"$q": Syntax error>, node => $opt{node};
          }
        } else {
          valid_err qq<"$et": Unknown element type>, node => $opt{node};
        }
      } else {
        valid_err qq<"<$q>": Element type must be specified>, node => $opt{node};
      }
    } else {
      $r = {true => 1, false => 0, null => 'undef'}->{$l};
    }
    $r;
  ]ge;
  ## TODO: Ensure Message::Util::Error imported if "try"ing.
  ## ISSUE: __FILE__ & __LINE__ will break if multiline substition happens.
  $s =~ s{
    \b__($RegQNameChar+)
    (?:\{($RegBlockContent)\})?
    __\b
  }{
    my ($name, $data) = ($1, $2);
    my $r;
    my $et = dis_qname_to_uri
                     ($name, %opt,
                      use_default_namespace => ExpandedURI q<disPerl:>);
    if ($et eq ExpandedURI q<disPerl:DEEP>) {   ## Deep Method Call
      $r = '{'.perl_statement ('local $Error::Depth = $Error::Depth + 1').
              perl_code ($data) .
           '}';
    } elsif ({
              ExpandedURI q<disPerl:EXCEPTION> => 1,
              ExpandedURI q<disPerl:WARNING> => 1,
             }->{$et}) {
                                  ## Raising an Exception or Warning
      if ($data =~ s/^         \s* ((?>(?! ::|\.)$RegQNameChar)+) \s*
                     (?:    \. \s* ((?>(?! ::|\.)$RegQNameChar)+) \s*
                        (?: \. \s* ((?>(>! ::|\.)$RegQNameChar)+) \s*
                        )?
                     )?
                     (?: ::\s* | $)//ox) {
        my ($q, $constq, $subtypeq) = ($1, $2, $3);
        s/\|/:/g for $q, $constq, $subtypeq;
        my ($cls, $const, $subtype) = dispm_xcref_to_resources
                                         ([$q, $constq, $subtypeq], %opt);

        ## Parameter
        my %xparam;
        while ($data =~ s/^\s*($RegQNameChar+)\s*//) {
          my $pnameuri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt);
          if (defined $xparam{$pnameuri}) {
            valid_err qq<Exception parameter <$pnameuri> is already specified>,
                      node => $opt{node};
          }
          if ($data =~ s/^=>\s*'([^']*)'\s*//) {  ## String
            $xparam{$pnameuri} = $1;
          } elsif ($data =~ s/^=>\s*\{($RegBlockContent)\}\s*//) {  ## Code
            $xparam{$pnameuri} = perl_code_literal ($1);
          } elsif ($data =~ /^,|$/) {  ## Boolean
            $xparam{$pnameuri} = 1;
          } else {
            valid_err qq<<$pnameuri>: Parameter value is expected>,
                      node => $opt{node};
          }
          $data =~ s/^\,\s*// or last;
        }
        valid_err qq<"$data": Broken exception parameter specification>,
                  node => $opt{node} if length $data;
        for (
          ExpandedURI q<MDOMX:class>,
          ExpandedURI q<MDOMX:method>,
          ExpandedURI q<MDOMX:attr>,
          ExpandedURI q<MDOMX:on>,
        ) {
          $xparam{$_} = $opt{$_} if defined $opt{$_};
        }

        $r = dispm_perl_throws
                (%opt, 
                 class_resource => $cls,
                 type_resource => $const,
                 subtype_resource => $subtype,
                 xparam => \%xparam);
      } else {
        valid_err qq<Exception type and name required: "$data">,
          node => $opt{node};
      }      
    } elsif ($et eq ExpandedURI q<disPerl:CODE>) {
      my ($nm);
      $data =~ s/^\s+//;
      if ($data =~ s/^((?>(?!::).)+)//) {
        $nm = $1;
      } else {
        valid_err q<Code name required>, node => $opt{node};
      }
      $data =~ s/^::\s*//; 
      my $param = dispm_parse_param (\$data, %opt,
                                     use_default_namespace => '',
                                     ExpandedURI q<dis2pm:endOrErr> => 1);      
      my $uri = dis_typeforqnames_to_uri ($nm, use_default_namespace => 1,
                                          %opt);
      if (defined $State->{Type}->{$uri}->{Name} and
          dis_resource_ctype_match (ExpandedURI q<dis2pm:BlockCode>,
                                    $State->{Type}->{$uri}, %opt)) {
        local $State->{ExpandedURI q<dis2pm:blockCodeParam>} = $param;
        ## ISSUE: It might be required to detect a loop
        $r = dispm_get_code (%opt, resource => $State->{Type}->{$uri},
                             For => [keys %{$State->{Type}->{$uri}
                                                  ->{For}}]->[0],
                             'For+' => [keys %{$State->{Type}->{$uri}
                                                     ->{'For+'}||{}}],
                             ExpandedURI q<dis2pm:selParent> => $param,
                             ExpandedURI q<dis2pm:DefKeyName>
                               => ExpandedURI q<d:Def>);
        for (grep {/^\$/} keys %$param) {
          $r =~ s/\Q$_\E\b/$param->{$_}/g;
        }
        valid_err qq<Block code <$uri> is empty>, node => $opt{node}
          unless length $r;
        $r = "\n{\n$r\n}\n";
      } else {
        valid_err qq<Block code constant <$uri> must be defined>,
                  node => $opt{node};
      }
    } elsif ($et eq ExpandedURI q<ManakaiDOM:InputNormalize>) {
      my $method = $opt{ExpandedURI q<dis2pm:currentMethodResource>};
      valid_err q<Element <ManakaiDOM:InputNroamlize> cannot be used here>,
            node => $opt{node} unless defined $method->{Name};
      PARAM: {
        for my $param (@{$method->{ExpandedURI q<dis2pm:param>}||[]}) {
          if ($data eq $param->{ExpandedURI q<dis2pm:paramName>}) {
            ## NOTE: <ManakaiDOM:noInputNormalize> property is not
            ##       checked for this element.
            my $nm = dispm_get_code 
                        (%opt, resource => $State->{Type}
                              ->{$param->{ExpandedURI q<d:actualType>}},
                         ExpandedURI q<dis2pm:DefKeyName>
                             => ExpandedURI q<ManakaiDOM:inputNormalizer>,
                         ExpandedURI q<dis2pm:getCodeNoTypeCheck> => 1,
                         ExpandedURI q<dis2pm:selParent>
                             => $param->{ExpandedURI q<dis2pm:actualTypeNode>});
            if (defined $nm) {
              $nm =~ s[\$INPUT\b][\$$param->{ExpandedURI q<dis2pm:paramName>} ]g;
              $r = $nm;
            } else {
              $r = '';
            }
            last PARAM;
          }
        }
        valid_err q<Parameter "$data" is not found>, node => $opt{node};
      }
    } elsif ($et eq ExpandedURI q<disPerl:WHEN>) {
      if ($data =~ s/^\s*IS\s*\{($RegBlockContent)\}::\s*//o) {
        my $v = dis_qname_to_uri ($1, use_default_namespace => 1, %opt);
        if ($State->{ExpandedURI q<dis2pm:blockCodeParam>}->{$v}) {
          $r = perl_code ($data, %opt);
        }
      } else {
        valid_err qq<Syntax for preprocessing macro "WHEN" is invalid>,
          node => $opt{node};
      }
    } elsif ($et eq ExpandedURI q<disPerl:FOR>) {
      if ($data =~ s/^((?>(?!::).)*)::\s*//) {
        my @For = ($opt{For} || ExpandedURI q<ManakaiDOM:all>,
                   @{$opt{'For+'} || []});
        V: for (split /\s*\|\s*/, $1) {
          my $for = dis_qname_to_uri ($_, %opt, use_default_namespace => 1,
                                      node => $opt{node});
          for (@For) {
            if (dis_uri_for_match ($for, $_, %opt)) {
              $r = perl_code ($data, %opt);
              last V;
            }
          }
        }
      } else {
        valid_err (qq<Broken <$et> block: "$data">, node => $opt{node});
      }
    } elsif ($et eq ExpandedURI q<disPerl:ASSERT>) {
      my $atype;
      if ($data =~ s/^\s*($RegQNameChar+)\s*::\s*//) {
        $atype = dis_qname_to_uri ($1, %opt, use_default_namespace => 1);
      } else {
        valid_err (qq<"$data": Assertion type QName is required>,
                   node => $opt{node});
      }
      my $param = dispm_parse_param (\$data, %opt,
                                     use_default_namespace => '',
                                     ExpandedURI q<dis2pm:endOrErr> => 1);      
      my %xparam;
      my $cond;
      my $pre = '';
      my $post = '';
      if ($atype eq ExpandedURI q<DISPerl:isPositive>) {
        $pre = perl_statement
                 perl_assign
                   'my $asActual' =>
                          '('.perl_code ($param->{actual}, %opt).')';
        $cond = '$asActual > 0';
        $xparam{ExpandedURI q<DOMMain:expectedLabel>} = 'a positive value';
        $xparam{ExpandedURI q<DOMMain:actualValue>}
                                 = perl_code_literal q<$asActual>;
      } elsif ($atype eq ExpandedURI q<DISPerl:invariant>) {
        $cond = '0';
        $xparam{ExpandedURI q<DOMMain:expectedLabel>} = $param->{msg};
        $xparam{ExpandedURI q<DOMMain:actualValue>} = '(invariant)';
      } else {
        valid_err (qq<Assertion type <$atype> is not supported>,
                   node => $opt{node});
      }
      if (defined $param->{pre}) {
        $pre = perl_code ($param->{pre}, %opt) . $pre;
      }
      if (defined $param->{post}) {
        $post .= perl_code ($param->{post}, %opt);
      }

        for (
          ExpandedURI q<MDOMX:class>,
          ExpandedURI q<MDOMX:method>,
          ExpandedURI q<MDOMX:attr>,
          ExpandedURI q<MDOMX:on>,
        ) {
          $xparam{$_} = $opt{$_} if defined $opt{$_};
        }
      if ($Opt{outputAssertion}) {
        $r = $pre . perl_if
               $cond,
               undef,
               perl_statement
                 dispm_perl_throws
                   class =>
                     ExpandedURI q<DX:CoreException>,
                   class_for => ExpandedURI q<ManakaiDOM:all>,
                   type => 'MDOM_DEBUG_BUG',
                   subtype => ExpandedURI q<DOMMain:ASSERTION_ERR>,
                   xparam => {
                      ExpandedURI q<DOMMain:assertionType> => $atype,
                      ExpandedURI q<DOMMain:traceText>
                                 => perl_code_literal
                                      q<(sprintf 'at %s line %s%s%s',
                                               __FILE__, __LINE__, "\n\t",
                                               Carp::longmess ())>,
                      %xparam,
                   };
        $r .= $post;
        $r = "{$r}";
      } else {
        $r = '';
      }
    } elsif ({
              ExpandedURI q<disPerl:FILE> => 1,
              ExpandedURI q<disPerl:LINE> => 1,
              ExpandedURI q<disPerl:PACKAGE> => 1,
             }->{$et}) {
      $r = qq<__${name}__>;
      valid_err (q<Block element content cannot be specified for >.
                 qq<element type <$et>>, node => $opt{node})
        if length $data;
    } else {
      valid_err qq<Preprocessing macro <$et> not supported>, node => $opt{node};
    }
    $r;
  }goex;

  ## Checks \p character classes
  while ($s =~ /\\p{([^{}]+)}/gs) {
    my $name = $1;
    $State->{ExpandedURI q<dis2pm:Package>}
          ->{$State->{ExpandedURI q<dis2pm:currentPackage>}}
          ->{ExpandedURI q<dis2pm:requiredCharClass>}
          ->{$name} ||= $opt{node} || 1;
  }

  $s;
}

=item {%param} = dispm_parse_param (\$paramspec, %opt)

Parses parameter specification and returns it as a reference
to hash.

=cut

sub dispm_parse_param ($%) {
  my ($src, %opt) = @_;
  my %param;
  while ($$src =~ s/^
    ## Parameter name
      (\$? $RegQNameChar+)\s*

    (?: =>? \s*

    ## Parameter value
      (
         ## Bare string
           $RegQNameChar+
         |
         ## Quoted string
           '(?>[^'\\]*)' ## ISSUE: escape mechanism required?
         |
         ## Code
           \{$RegBlockContent\}

      )

    \s*)?

  (?:,\s*|$)//ox) {
    my ($n, $v) = ($1, $2);
    if (defined $v) {
      if ($v =~ /^'/) {
        $v = substr ($v, 1, length ($v) - 2);
      } elsif ($v =~ /^\{/) {
        $v = perl_code_literal substr ($v, 1, length ($v) - 2);
      } else {
        # 
      }
    } else {
      $v = 1;
    }
    
    if ($n =~ /^\$/) {
      $param{$n} = $v;
    } else {
      $param{dis_qname_to_uri ($n, %opt)} = $v;
    }
  }
  if ($opt{ExpandedURI q<dis2pm:endOrErr>} and length $$src) {
    valid_err qq<Broken parameter specification: "$$src">, node => $opt{node};
  }
  \%param;
} # dispm_parse_param

=item $result = perl_code_source ($code, %opt)

Attaches the source file information to a Perl code fragment. 

Note that the same name function is defined in F<genlib.pl> 
but redefined here for the purpose of this script. 

TODO: Non-debug purpose output should remove source information; otherwise 
it is too verbose. 

=cut

sub perl_code_source ($%) {
  my ($s, %opt) = @_;
  my $npk = [qw/Name QName Label/];
  my $f1 = sprintf q<File <%s> Node <%s> [Chunk #%d]>,
    $opt{file} || $State->{Module}->{$opt{resource}->{parentModule}}->{FileName},
    $opt{path} || ($opt{resource}->{src}
                     ? $opt{resource}->{src}->node_path (key => $npk)
                     : $opt{node} ? $opt{node}->node_path (key => $npk)
                                  : 'x:unknown ()'),
    ++($State->{ExpandedURI q<dis2pm:generatedChunk>} ||= 0);
  my $f2 = sprintf q<Module <%s> [Chunk #%d]>,
    $opt{file} || $State->{Module}->{$State->{module}}->{URI},
    ++($State->{ExpandedURI q<dis2pm:generatedChunk>} ||= 0);
  $f1 =~ s/"/\"/g; $f2 =~ s/"/\"/g;
  sprintf qq<\n#line %d "%s"\n%s\n#line 1 "%s"\n>,
                 $opt{line} || 1, $f1, $s, $f2;
} # perl_code_source




=item $code = dispm_get_code (resource => $res, %opt)

Generates a Perl code fragment from resource(s).

=cut

sub dispm_get_code (%) {
  my %opt = @_;
  if (($opt{ExpandedURI q<dis2pm:getCodeNoTypeCheck>} and
       defined $opt{resource}->{Name}) or
      ($opt{resource}->{ExpandedURI q<dis2pm:type>} and
       {
         ExpandedURI q<DISLang:MethodReturn> => 1,
         ExpandedURI q<DISLang:AttributeGet> => 1,
         ExpandedURI q<DISLang:AttributeSet> => 1,
       }->{$opt{resource}->{ExpandedURI q<dis2pm:type>}}) or
      (dis_resource_ctype_match ([ExpandedURI q<dis2pm:InlineCode>,
                                  ExpandedURI q<dis2pm:BlockCode>],
                                 $opt{resource}, %opt,
                                 node => $opt{resource}->{src}))) {
    local $State->{Namespace}
      = $State->{Module}->{$opt{resource}->{parentModule}}->{nsBinding}
        if defined $opt{resource}->{Name};
    my $key = $opt{ExpandedURI q<dis2pm:DefKeyName>} || ExpandedURI q<d:Def>;

    my $n = dis_get_attr_node (%opt, parent => $opt{resource}->{src},
                               name => {uri => $key},
                               ContentType => ExpandedURI q<d:Perl>) ||
            dis_get_attr_node (%opt, parent => $opt{resource}->{src},
                               name => {uri => $key},
                               ContentType => ExpandedURI q<lang:dis>);
    if ($n) {
      return disperl_to_perl (%opt, node => $n);
    }

    $n = dis_get_attr_node (%opt, parent => $opt{resource}->{src},
                               name => {uri => $key},
                               ContentType => ExpandedURI q<lang:Perl>);
    if ($n) {
      my $code = '';
      for (@{dis_get_elements_nodes (%opt, parent => $n,
                                     name => 'require')}) {
        $code .= perl_statement 'require ' . $_->value;
      }
      my $v = $n->value;
      valid_err q<Perl code is required>, node => $n unless defined $v;
      $code .= perl_code ($v, %opt, node => $n);
      if ($opt{is_inline} and
          dis_resource_ctype_match ([ExpandedURI q<dis2pm:InlineCode>],
                                    $opt{resource}, %opt,
                                    node => $opt{resource}->{src})) {
        $code =~ s/\n/\x20/g;
        return $code;
      } else {
        return perl_code_source ($code, %opt, node => $n);
      }
    }
    return undef;
  } else {
    impl_err ("Bad resource for dispm_get_code: ".
              $opt{resource}->{ExpandedURI q<dis2pm:type>},
              node => $opt{resource}->{src});
  }
} # dispm_get_code

=item $code = dispm_get_value (%opt)

Gets value property and returns it as a Perl code fragment.

=cut

sub dispm_get_value (%) {
  my %opt = @_;
  my $key = $opt{ExpandedURI q<dis2pm:ValueKeyName>} || ExpandedURI q<d:Value>;
  my $vt = $opt{ExpandedURI q<dis2pm:valueType>} || ExpandedURI q<DOMMain:any>;
  local $State->{Namespace}
      = $State->{Module}->{$opt{resource}->{parentModule}}->{nsBinding}
        if defined $opt{resource}->{Name};
  local $opt{For} = [keys %{$opt{resource}->{For}}]->[0]
        if defined $opt{resource}->{Name};
  local $opt{'For+'} = [keys %{$opt{resource}->{'For+'}||{}}]
        if defined $opt{resource}->{Name};
  my $n = $opt{node} ? [$opt{node}]
                     : dis_get_elements_nodes
                                 (%opt, parent => $opt{resource}->{src},
                                  name => {uri => $key});
  for my $n (@$n) {
    my $t = dis_get_attr_node (%opt, parent => $n, name => 'ContentType');
    my $type;
    if ($t) {
      $type = dis_qname_to_uri ($t->value, %opt, node => $t);
    } elsif ($opt{resource}->{ExpandedURI q<d:actualType>}) {
      $type = $opt{resource}->{ExpandedURI q<d:actualType>};
    } else {
      $type = ExpandedURI q<lang:dis>;
    }
    valid_err (qq<Type <$type> is not defined>, node => $t || $n)
      unless defined $State->{Type}->{$type}->{Name};
    
    if (dis_uri_ctype_match (ExpandedURI q<lang:Perl>, $type, %opt)) {
      return perl_code ($n->value, %opt, node => $n);
    } elsif (dis_uri_ctype_match (ExpandedURI q<DISCore:String>, $type, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:DOMString>, $type, %opt)) {
      return perl_literal $n->value;
    } elsif (dis_uri_ctype_match (ExpandedURI q<DOMMain:unsigned-short>, $type, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:unsigned-long>, $type, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:short>, $type, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:long>, $type, %opt)) {
      return $n->value;
    } elsif (dis_uri_ctype_match (ExpandedURI q<DOMMain:boolean>, $type, %opt)) {
      return ($n->value and ($n->value eq 'true' or $n->value eq '1')) ? 1 : 0;
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:Boolean>, $type, %opt)) {
      return $n->value ? 1 : 0;
    } elsif (dis_uri_ctype_match (ExpandedURI q<lang:dis>, $type, %opt)) {
      return perl_literal $n->value;
    }
  }

  ## No explicit value specified
  if ($opt{ExpandedURI q<dis2pm:useDefaultValue>}) {
    if (dis_uri_ctype_match (ExpandedURI q<DOMMain:DOMString>, $vt, %opt)) {
      return q<"">;
    } elsif (dis_uri_ctype_match (ExpandedURI q<DOMMain:unsigned-short>, $vt, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:unsigned-long>, $vt, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:short>, $vt, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:long>, $vt, %opt) or
             dis_uri_ctype_match (ExpandedURI q<DOMMain:boolean>, $vt, %opt)) {
      return q<0>;
    } elsif (dis_uri_ctype_match (ExpandedURI q<Perl:ARRAY>, $vt, %opt)) {
      return q<[]>;
    } elsif (dis_uri_ctype_match (ExpandedURI q<Perl:hash>, $vt, %opt)) {
      return q<{}>;
    }
  }
  return undef;
} # dispm_get_value



=item $code = dispm_const_value (resource => $const, %opt)

Returns a code fragment corresponding to the vaue of C<$const>.

=cut

sub dispm_const_value (%) {
  my %opt = @_; 
  my $for = [keys %{$opt{resource}->{For}}]->[0];
  local $opt{'For+'} = [keys %{$opt{resource}->{'For+'}||{}}];
  my $value = dispm_get_value
                        (%opt,
                         ExpandedURI q<dis2pm:ValueKeyName>
                                 => ExpandedURI q<d:Value>,
                         ExpandedURI q<dis2pm:valueType>
                                 => $opt{resource}
                                        ->{ExpandedURI q<dis2pm:actualType>},
                         For => $for);
  valid_err q<Constant value must be specified>, node => $opt{resource}->{src}
    unless defined $value;
  return $value;
} # dispm_const_value

=item $code = dispm_const_value_sub (resource => $const, %opt)

Returns a code fragment to declare and define a constant function 
corresponding to the definition of C<$const>.

=cut

sub dispm_const_value_sub (%) {
  my %opt = @_;
  my $value = dispm_const_value (%opt);
  my $name = $opt{resource}->{ExpandedURI q<dis2pm:constName>};
  my $pc = $State->{ExpandedURI q<dis2pm:Package>}
                 ->{$State->{Module}->{$State->{module}}
                          ->{ExpandedURI q<dis2pm:packageName>}}
                 ->{ExpandedURI q<dis2pm:const>} ||= {};
  valid_err qq<Constant value "$name" is already defined in the same module>,
    node => $opt{resource}->{src} if defined $pc->{$name}->{resource}->{Name};
  $pc->{$name} = {
    name => $name, resource => $opt{resource},
    package => $State->{ExpandedURI q<dis2pm:currentPackage>},
  };
  return perl_sub
            (name => $name,
             prototype => '',
             code => $value);
} # dispm_const_value_sub

=item $code = dispm_const_group (resource => $const_group, %opt)

Returns a code fragment to define a constant value group.

=cut

sub dispm_const_group (%) {
  my %opt = @_;
  my $name = $opt{resource}->{ExpandedURI q<dis2pm:constGroupName>};
  for my $cg (values %{$opt{resource}->{ExpandedURI q<dis2pm:constGroup>}}) {
    if (defined $cg->{ExpandedURI q<dis2pm:constGroupName>}) {
      valid_err (qq{"$name"."$cg->{ExpandedURI q<dis2pm:constGroupName>}": }.
                 qq{Nesting constant group not supported}, 
                 node => $cg->{src});
    }
  }

  my $result = '';
  my @cname;
  if (length $name) {
    if (defined $opt{ExpandedURI q<dis2pm:constGroupParentPackage>}->{$name}) {
      valid_err qq<Const group "$name" is already defined>, 
                node => $opt{resource}->{src};
    }
    $opt{ExpandedURI q<dis2pm:constGroupParentPackage>}->{$name} = \@cname;
  }

  my $pc = $State->{ExpandedURI q<dis2pm:Package>}
                 ->{$State->{Module}->{$State->{module}}
                          ->{ExpandedURI q<dis2pm:packageName>}}
                 ->{ExpandedURI q<dis2pm:constGroup>} ||= {};
  valid_err qq<Constant group "$name" is already defined in the same module>,
    node => $opt{resource}->{src} if defined $pc->{$name}->{resource}->{Name};
  $pc->{$name} = {
    name => $name, resource => $opt{resource},
    member => \@cname,
  };

  for my $cv (values %{$opt{resource}->{ExpandedURI q<dis2pm:const>}}) {
    next unless defined $cv->{ExpandedURI q<dis2pm:constName>};
    #$result .= dispm_const_value_sub (%opt, resource => $cv);
    push @cname, $cv->{ExpandedURI q<dis2pm:constName>};
  }
  return $result;
} # dispm_const_group

=item $desc = dispm_muf_description (%opt, resource => $res)

Gets a <IF::Message::Util::Formatter> template for a resource.

=cut

sub dispm_muf_description (%) {
  my %opt = @_;
  my $key = $opt{ExpandedURI q<dis2pm:DefKeyName>} || ExpandedURI q<d:Def>;

  local $State->{Namespace}
      = $State->{Module}->{$opt{resource}->{parentModule}}->{nsBinding};
  local $opt{For} = [keys %{$opt{resource}->{For}}]->[0];
  local $opt{'For+'} = [keys %{$opt{resource}->{'For+'}||{}}];
  
  my $def = dis_get_attr_node (%opt, parent => $opt{resource}->{src},
                               name => {uri => $key}, 
                               ContentType => ExpandedURI q<lang:muf>);
  if ($def) {
    my $template = $def->value;
    $template =~ s/<Q::([^<>]+)>/dis_qname_to_uri ($1, %opt,
                                                   node => $opt{resource}
                                                             ->{src})/ge;
    $template =~ s/\s+/ /g;
    $template =~ s/^ //;
    $template =~ s/ $//;
    return $template;
  }

  $key = $opt{ExpandedURI q<dis2pm:DescriptionKeyName>} ||
         ExpandedURI q<d:Description>;

  my $template = '';
  for $def (@{dis_get_elements_nodes
                (%opt, parent => $opt{resource}->{src},
                 name => {uri => $key},
                 ContentType => ExpandedURI q<lang:disdoc>,
                 defaultContentType => ExpandedURI q<lang:disdoc>)}) {
    $template .= disdoc2text ($def->value, %opt, node => $def);
  }
  $template =~ s/\s+/ /g;
  $template =~ s/^ //;
  $template =~ s/ $//;
  return $template;
} # dispm_muf_description

=item $code = disperl_to_perl (node => $node, %opt)

Converts a C<d:Perl> node to a Perl code fragment.

=cut

sub disperl_to_perl (%) {
  my %opt = @_;
  my $code = '';
  for (@{$opt{node}->child_nodes}) {
    next unless $_->node_type eq '#element';
    next unless dis_node_for_match ($_, $opt{For}, %opt);
    my $et = dis_element_type_to_uri ($_->local_name, %opt, node => $_);
    if ($et eq ExpandedURI q<DISLang:constValue>) {
      my $cn = $_->value;
      if ($cn =~ /^((?>(?!\.)$RegQNameChar)*)\.($RegQNameChar+)$/o) {
        my ($cls, $constn) = ($1, $2);
        if (length $cls) {
          my $clsu = dis_typeforqnames_to_uri ($cls, %opt,
                                               use_default_namespace => 1,
                                               node => $_);
          $cls = $State->{Type}->{$clsu};
          valid_err qq<Class/IF <$clsu> must be defined>, node => $_
            unless defined $cls->{Name};
        } else {
          $cls = $State->{ExpandedURI q<dis2pm:thisClass>};
          valid_err q<Class/IF name required in this context>, node => $_
            unless defined $cls->{Name};
        }
        
        my $const = $cls->{ExpandedURI q<dis2pm:const>}->{$constn};
        valid_err qq<Constant value "$constn" not defined in class/IF >.
                  qq{"$cls->{Name}" (<$cls->{URI}>)}, node => $_
                    unless defined $const->{Name};
        $code .= perl_statement
                   perl_assign
                        perl_var (type => '$', local_name => 'r')
                     => dispm_const_value (resource => $const);
      } else {
        valid_err q<Syntax error>, node => $_;
      }
    } elsif ($et eq ExpandedURI q<DISLang:value>) {
      my $v = dispm_get_value (%opt, node => $_);
      $code .= perl_statement
                   perl_assign
                        perl_var (type => '$', local_name => 'r') => $v;
    } elsif ($et eq ExpandedURI q<d:GetProp> or
             $et eq ExpandedURI q<d:GetPropNode> or
             $et eq ExpandedURI q<swcfg21:GetPropNode>) {
      my $uri = dis_qname_to_uri ($_->value, %opt, node => $_,
                                  use_default_namespace => 1);
      $code .= perl_statement
                   perl_assign
                        perl_var (type => '$', local_name => 'r')
                     => '$self->{'.(ExpandedURI q<TreeCore:node>).
                        '}->{'.(perl_literal $uri).'}';
      if ($et eq ExpandedURI q<d:GetPropNode>) {
        $code .= perl_if
                   'defined $r',
                   perl_code (q{$r = <ClassM::DOMCore:ManakaiDOMNode
                                                   .getNodeReference> ($r)},
                              %opt, node => $_);
      } elsif ($et eq ExpandedURI q<swcfg21:GetPropNode>) {
        $code .= perl_if
                   'defined $r',
                   perl_code (q{$r = <ClassM::swcfg21:ManakaiSWCFGNode
                                                   .getNodeReference> ($r)},
                              %opt, node => $_);
      }
    } elsif ($et eq ExpandedURI q<d:SetProp>) {
      my $uri = dis_qname_to_uri ($_->value, %opt, node => $_,
                                  use_default_namespace => 1);
      my $chk = dis_get_attr_node (%opt, parent => $_, name => 'CheckReadOnly');
      if ($chk and $chk->value) {
        my $for1 = $opt{For} || ExpandedURI q<ManakaiDOM:all>;
        unless (dis_uri_for_match (ExpandedURI q<ManakaiDOM:ManakaiDOM1>,
                                   $for1, node => $_)) {
          $for1 = ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>;
        }
        $code .= perl_if
                   q[$self->{].(perl_literal ExpandedURI q<TreeCore:node>).
                   q[}->{].(perl_literal ExpandedURI q<DOMCore:read-only>).
                   q[}],
                   perl_statement
                     dispm_perl_throws
                       (%opt, class_for => $for1,
                        class => ExpandedURI q<DOMCore:ManakaiDOMException>,
                        type => 'NO_MODIFICATION_ALLOWED_ERR',
                        subtype => ExpandedURI q<MDOMX:NOMOD_THIS>);
      }
      $code .= perl_statement
                   perl_assign
                        '$self->{'.(ExpandedURI q<TreeCore:node>).
                        '}->{'.(perl_literal $uri).'}'
                     => perl_var (type => '$', local_name => 'given');
    } elsif ($et eq ExpandedURI q<DISPerl:cloneCode>) {
      my $memref = $_->value;
      my $mem = dispm_memref_to_resource
                    ($memref, %opt, node => $_,
                     return_method_returner => 1,
                     use_default_type_resource =>
                       $State->{ExpandedURI q<dis2pm:thisClass>},
                       ## ISSUE: Reference in a resource that is 
                       ##        referred from another resource might
                       ##        not be interpreted correctly.
                    );
      ## ISSUE: It might be required to detect a loop
      $code .= dispm_get_code (%opt, resource => $mem,
                               For => [keys %{$mem->{For}}]->[0],
                               'For+' => [keys %{$mem->{'For+'}||{}}],
                               ExpandedURI q<dis2pm:DefKeyName>
                                 => ExpandedURI q<d:Def>);
    } elsif ($et eq ExpandedURI q<DOMMain:raiseException>) {
      my ($cls, $type, $subtype) = dispm_xcref_to_resources
                                     ($_->value, %opt, node => $_);
      ## TODO: Parameter
      my %xparam;
      
      for (
           ExpandedURI q<MDOMX:class>,
           ExpandedURI q<MDOMX:method>,
           ExpandedURI q<MDOMX:attr>,
           ExpandedURI q<MDOMX:on>,
          ) {
        $xparam{$_} = $opt{$_} if defined $opt{$_};
      }

      $code .= perl_statement dispm_perl_throws
                (%opt, 
                 class_resource => $cls,
                 type_resource => $type,
                 subtype_resource => $subtype,
                 xparam => \%xparam);
    } elsif ($et eq ExpandedURI q<DISPerl:selectByProp>) {
      my $cprop = dis_get_attr_node
                       (%opt, parent => $_,
                        name => {uri => ExpandedURI q<DISPerl:propName>});
      my $propvalue;
      if ($cprop) {
        my $cpropuri = dis_qname_to_uri ($cprop->value,
                                         use_default_namespace => 1,
                                         %opt, node => $cprop);
        my $prop;
        if ($opt{ExpandedURI q<dis2pm:selParent>}) {
          if (ref $opt{ExpandedURI q<dis2pm:selParent>} eq 'HASH') {
            $prop = $opt{ExpandedURI q<dis2pm:selParent>};
            if (defined $prop->{$cpropuri}) {
              $propvalue = $prop->{$cpropuri};
            } else {
              $propvalue = '';
            }
          } else {
            $prop = dis_get_attr_node
                         (%opt, parent => $opt{ExpandedURI q<dis2pm:selParent>},
                          name => {uri => $cpropuri});
            if ($prop) {
              $propvalue = $prop->value;
            } else {
              $propvalue = '';
            }
          }
        } else {
          valid_err q<Element "DISPerl:selectByProp" cannot be used here>,
              node => $_;
        }
      } else {
        valid_err q<Attribute "DISPerl:propName" required>,
          node => $_;
      }
      my $selcase;
      for my $case (@{$_->child_nodes}) {
        next unless $case->node_type eq '#element';
        next unless dis_node_for_match ($case, $opt{For}, %opt);
        my $et = dis_element_type_to_uri ($case->local_name,
                                          %opt, node => $case);
        if ($et eq ExpandedURI q<DISPerl:case>) {
          my $val = dis_get_attr_node
                           (%opt, parent => $case,
                            name => 'Value',
                            ContentType => ExpandedURI q<lang:dis>,
                            defaultContentType => ExpandedURI q<lang:dis>);
          if ($val and $val->value eq $propvalue) {
            $selcase = $case; last;
          } elsif ($propvalue eq '' and (not $val or not $val->value)) {
            $selcase = $case; last;
          }
        } elsif ($et eq ExpandedURI q<DISPerl:else>) {
          $selcase = $case; last;
        } elsif ({
                  ExpandedURI q<DISPerl:propName> => 1,
                 }->{$et}) {
          # 
        } else {
          valid_err qq<Element type <$et> not allowed here>,
                    node => $case;
        }
      }
      if ($selcase) {
        my $lcode = perl_code ($selcase->value, %opt, node => $selcase);
        if ($opt{is_inline}) {
          $code .= $lcode;
        } else {
          $code .= perl_code_source ($lcode, %opt, node => $selcase);
        }
      }
    } elsif ({
              ExpandedURI q<d:ContentType> => 1,
              ExpandedURI q<d:For> => 1,
              ExpandedURI q<d:ForCheck> => 1,
              ExpandedURI q<d:ImplNote> => 1,
              ExpandedURI q<DISLang:nop> => 1,
             }->{$et}) {
      # 
    } else {
      valid_err qq<Element type <$et> not supported>,
                node => $opt{node};
    }
  }
  
  my $val = $opt{node}->value;
  if (defined $val and length $val) {
    my $lcode = perl_code ($val, %opt);
    if ($opt{is_inline}) {
      $code .= $lcode;
    } else {
      $code .= perl_code_source ($lcode, %opt);
    }
  }
  return $code;
} # disperl_to_perl

=item $res = dispm_memref_to_resource ($memref, %opt)

Converts a C<DISPerl:MemRef> (a reference to a class member,
i.e. either method, attribute, attribute getter or attribute
setter) to a resource.

=cut

sub dispm_memref_to_resource ($%) {
  my ($memref, %opt) = @_;
  my ($clsq, $memq) = split /\./, $memref, 2;
  unless (defined $memq) {
    valid_err qq<"$memref": Member name required>. node => $opt{node};
  } elsif ($memq =~ /:/) {
    valid_err qq<"$memref": Prefixed member name not supported>,
              node => $opt{node};
  }

  ## Class
  my $cls;
  my $clsuri;
  if ($clsq eq '') {
    if (defined $opt{use_default_type_resource}->{Name}) {
      $cls = $opt{use_default_type_resource};
      $clsuri = $cls->{URI};
    } elsif ($opt{use_default_type}) {
      $clsuri = $opt{use_default_type};
    } else {
      $clsuri = dis_typeforqnames_to_uri
                     ($clsq, use_default_namespace => 1, %opt);
    }
  } else {
    $clsuri = dis_typeforqnames_to_uri
                     ($clsq, use_default_namespace => 1, %opt);
  }
  unless ($cls) {
    $cls = $State->{Type}->{$clsuri};
    valid_err qq<Class <$clsuri> must be defined>, node => $opt{node}
      unless defined $cls->{Name};
  }

  ## Method or attribute
  my $memname = $memq;
  my $mem;
  for (values %{$cls->{ExpandedURI q<dis2pm:method>}||{}}) {
    if (defined $_->{Name} and $_->{Name} eq $memname) {
      $mem = $_;
      last;
    }
  }
  if ($mem) {
    if ($opt{return_method_returner}) {
      if (defined $mem->{ExpandedURI q<dis2pm:return>}->{Name}) {
        $mem = $mem->{ExpandedURI q<dis2pm:return>};
      } elsif (defined $mem->{ExpandedURI q<dis2pm:getter>}->{Name}) {
        $mem = $mem->{ExpandedURI q<dis2pm:getter>};
      } else {
        valid_err qq{Neither "return" nor "getter" is defined for }.
                  qq{the class "$cls->{Name}" <$cls->{URI}>},
                    node => $opt{node};
      }
    }
  } elsif ($memname =~ s/^([gs]et)(?=.)//) {
    my $gs = $1;
    $memname = lcfirst $memname;
    my $memp;
    for (values %{$cls->{ExpandedURI q<dis2pm:method>}||{}}) {
      if (defined $_->{Name} and $_->{Name} eq $memname) {
        $memp = $_;
        last;
      }
    }
    if ($memp) {
      if ($gs eq 'set') {
        $mem = $memp->{ExpandedURI q<dis2pm:setter>};
        unless (defined $mem->{Name}) {
          valid_err qq{Setter for "$memp->{Name}" <$memp->{URI}> is not defined},
            node => $opt{node};
        }
      } else {
        $mem = $memp->{ExpandedURI q<dis2pm:getter>};
        unless (defined $mem->{Name}) {
          valid_err qq{Getter for "$memp->{Name}" <$memp->{URI}> is not defined},
            node => $opt{node};
        }
      }
    }
  }
  valid_err qq<Member "$memq" for class <$clsuri> is not defined>,
    node => $opt{node} unless defined $mem->{Name};
  return $mem;
} # dispm_memref_to_resource

=item ($clsres, $coderef, $subcoderef) = dispm_xcref_to_resources ($xcref, %opt)

Converts a "DOMMain:XCodeRef" (exception or warning code reference) 
to its "resource" objects. 

=over 4

=item $clsres

The resource object for the exception or warning class or interface identified 
by the XCodeRef.

=item $coderef

The resource object for the exception or warning code identified 
by the XCodeRef.

=item $subcoderef

The resource object for the exception or warning code idnetified by 
the XCodeRef, if any.  If the XCodeRef identifies no subtype resource, 
an C<undef> is returned as C<$subcodref>. 

=back

=cut

sub dispm_xcref_to_resources ($%) {
  my ($xcref, %opt) = @_;
  my $q;
  my $constq;
  my $subtypeq;
  if (ref $xcref) {
    ($q, $constq, $subtypeq) = @$xcref;
  } else {
    ($q, $constq, $subtypeq) = split /\./, $xcref, 3;
  }
        my $clsuri;
        my $cls;
        my $consturi;
        my $const;
        my $subtypeuri;
        my $subtype;
        if (defined $constq and not defined $subtypeq) {
          $clsuri = dis_typeforqnames_to_uri ($q, 
                                              use_default_namespace => 1,
                                              %opt);
          $cls = $State->{Type}->{$clsuri};
          valid_err qq{Exception/warning class definition for }.
                    qq{<$clsuri> is required}, node => $opt{node}
                      unless defined $cls->{Name};
          my ($consttq, $constfq) = split /\|\|/, $constq, 2;
          if (defined $constfq) {
            if ($consttq !~ /:/) {
              valid_err qq<"$constq": Unprefixed exception code QName must >.
                        q<not be followed by a "For" QName>,
                        node => $opt{node};
            } else {
              $consturi = dis_typeforqnames_to_uri ($consttq.'::'.$constfq,
                                                    use_default_namespace => 1,
                                                    %opt);
            }
          } else {
            if ($consttq !~ /:/) {
              $consturi = $consttq;
              CONSTCLS: {
                for (values %{$cls->{ExpandedURI q<dis2pm:xConst>}}) {
                  if (defined $_->{Name} and $_->{Name} eq $consturi) {
                    $const = $_;
                    last CONSTCLS;
                  }
                }
                valid_err qq{Exception/warning code "$consturi" must be }.
                          qq{defined in the exception/warning class }.
                          qq{<$clsuri>}, node => $opt{node};
              }
            } else {
              $consturi = dis_typeforqnames_to_uri ($consttq.'::'.$constfq,
                                                    use_default_namespace => 1,
                                                    %opt);
            }
          }
          unless ($const) {
            CONSTCLS: {
              for (values %{$cls->{ExpandedURI q<dis2pm:xConst>}}) {
                if (defined $_->{Name} and $_->{URI} and
                    $_->{URI} eq $consturi) {
                  $const = $_;
                  last CONSTCLS;
                }
              }
              valid_err qq{Exception/warning code <$consturi> must be }.
                        qq{defined in the exception/warning class }.
                        qq{<$clsuri>}, node => $opt{node};
            }
          }
        } else { ## By code/subtype QName
          $subtypeq = $q unless defined $constq;
          $subtypeuri = dis_typeforqnames_to_uri ($subtypeq,
                                                  use_default_namespace => 1,
                                                  %opt);
          $subtype = $State->{Type}->{$subtypeuri};
          valid_err qq{Exception/warning code/subtype <$subtypeuri> must }.
                    qq{be defined}, node => $opt{node}
                  unless defined $subtype->{Name} and
                         defined $subtype->{ExpandedURI q<dis2pm:type>};
          if ($subtype->{ExpandedURI q<dis2pm:type>} eq
                ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType>) {
            $const = $subtype->{ExpandedURI q<dis2pm:parentResource>};
            $cls = $subtype->{ExpandedURI q<dis2pm:grandGrandParentResource>};
          } elsif ($subtype->{ExpandedURI q<dis2pm:type>} eq
                     ExpandedURI q<ManakaiDOM:Const>) {
            $const = $subtype;
            $subtype = undef;
            $cls = $const->{ExpandedURI q<dis2pm:grandParentResource>};
          } else {
            valid_err qq{Type of <$subtypeuri> must be either }.
                      q{"ManakaiDOM:Const" or }.
                      q{"ManakaiDOM:ExceptionOrWarningSubType"},
                      node => $opt{node};
          }
        }
  return ($cls, $const, $subtype);
} # dispm_xcref_to_resources

=item $hash = dispm_collect_hash_prop_value ($resource, $propuri, %opt)

Get property values from a resource and its superclasses 
(C<dis:ISA>s - C<dis:Implement>s are not checked).

=cut

## TODO: Loop test might be required
sub dispm_collect_hash_prop_value ($$%) {
  my ($res, $propu, %opt) = @_;
  my %r;
  for (@{$res->{ISA}||[]}) {
    %r = (%{dispm_collect_hash_prop_value ($State->{Type}->{$_}, $propu, %opt)},
          %r);
  }
  %r = (%r, %{$res->{$propu}||{}});
  \%r;
} # dispm_collect_hash_prop_value

=back

=cut

## Outputed module and "For"
my $mf = dis_get_module_uri (module_name => $Opt{module_name},
                             module_uri => $Opt{module_uri},
                             For => $Opt{For});
$State->{DefaultFor} = $mf->{For};
$State->{module} = $mf->{module};
our $result = '';

valid_err
 (qq{Perl module <$State->{module}> not defined for <$State->{DefaultFor}>},
  node => $State->{Module}->{$State->{module}}->{src})
    unless $State->{Module}->{$State->{module}}
                 ->{ExpandedURI q<dis2pm:packageName>};

$State->{ExpandedURI q<dis2pm:currentPackage>} = 'main';
my $header = "#!/usr/bin/perl \n";
$header .= perl_comment q<This file is automatically generated from> . "\n" .
                        q<"> . $Opt{file_name} . q<" at > .
                        rfc3339_date (time) . qq<.\n> .
                        q<Don't edit by hand!>;
$header .= perl_comment qq{Module <$State->{module}>};
$header .= perl_comment qq{For <$State->{DefaultFor}>};
$header .= perl_statement q<use strict>;
$header .= perl_change_package
                  (full_name => $State->{Module}->{$State->{module}}
                                      ->{ExpandedURI q<dis2pm:packageName>});
$header .= perl_statement
                 perl_assign
                      perl_var (type => '$', local_name => 'VERSION',
                                scope => 'our')
                   => perl_literal version_date time
  if $Opt{outputModuleVersion};

## -- Classes
my %opt;
for my $pack (values %{$State->{Module}->{$State->{module}}
                             ->{ExpandedURI q<dis2pm:package>}||{}}) {
  next unless defined $pack->{Name};
  if ({
       ExpandedURI q<ManakaiDOM:Class> => 1,
       ExpandedURI q<ManakaiDOM:IF> => 1,
       ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
       ExpandedURI q<DOMMain:ErrorClass> => 1,
       ExpandedURI q<ManakaiDOM:ExceptionIF> => 1,
       ExpandedURI q<ManakaiDOM:WarningClass> => 1,
      }->{$pack->{ExpandedURI q<dis2pm:type>}}) {
    ## Package name and version
    $result .= perl_change_package
                  (full_name => $pack->{ExpandedURI q<dis2pm:packageName>});
    $result .= perl_statement
                 perl_assign
                      perl_var (type => '$', local_name => 'VERSION',
                                scope => 'our')
                   => perl_literal version_date time;
    ## Inheritance
    ## TODO: IF "isa" should be expanded
    my $isa = $pack->{ExpandedURI q<dis2pm:AppISA>} || [];
    for (@$isa) {
      $State->{Module}->{$State->{module}}
            ->{ExpandedURI q<dis2pm:requiredModule>}->{$_} ||= 1;
    }
    $State->{ExpandedURI q<dis2pm:xifReferred>}
          ->{$pack->{ExpandedURI q<dis2pm:packageName>}} = -1;
    for my $uri (@{$pack->{ISA}||[]}, 
                 @{$pack->{Implement}||[]}) {
      my $pack = $State->{Type}->{$uri};
      if (defined $pack->{ExpandedURI q<dis2pm:packageName>}) {
        push @$isa, $pack->{ExpandedURI q<dis2pm:packageName>};
        if ($pack->{ExpandedURI q<dis2pm:type>} eq 
            ExpandedURI q<ManakaiDOM:ExceptionIF>) {
          $State->{ExpandedURI q<dis2pm:xifReferred>}
                ->{$pack->{ExpandedURI q<dis2pm:packageName>}} ||= 1;
        }
      } else {
        impl_msg ("Inheriting package name for <$uri> not defined",
                  node => $pack->{src}) if $Opt{verbose};
      }
    }
    $isa = array_uniq $isa;
    $result .= perl_inherit $isa;
    $State->{ExpandedURI q<dis2pm:referredPackage>}->{$_} ||= $pack->{src} || 1
      for @$isa;
    
    ## Role
    my $role = dispm_collect_hash_prop_value
                 ($pack, ExpandedURI q<d:Role>, %opt);
    my $feature;
    for (values %$role) {
      my $roleres = $State->{Type}->{$_->{Role}};
      my $compatres;
      $compatres = $State->{Type}->{$_->{compat}} if defined $_->{compat};
      valid_err qq{Perl package name for interface <$_->{Role}> must be defined},
        node => $roleres->{src}
          unless defined $roleres->{ExpandedURI q<dis2pm:packageName>};
      valid_err qq{Perl package name for class <$_->{compat}> must be defined},
        node => $compatres->{src}
          if $compatres and 
             not defined $compatres->{ExpandedURI q<dis2pm:packageName>};
      if ({
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:DOMImplementation>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOM>, %opt) => 1,
           
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:ManakaiDOMNode>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:ManakaiDOMAttr>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMXML:ManakaiDOMCDATASection>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:ManakaiDOMComment>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:ManakaiDOMDocument>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:ManakaiDOMDocumentFragment>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMXML:ManakaiDOMDocumentType>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:ManakaiDOMElement>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMXML:ManakaiDOMEntity>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMXML:ManakaiDOMEntityReference>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMXML:ManakaiDOMNotation>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMXML:ManakaiDOMProcessingInstruction>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,
           dis_typeforuris_to_uri
                (ExpandedURI q<DOMCore:ManakaiDOMText>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt) => 1,

           (my $ev = dis_typeforuris_to_uri
                (ExpandedURI q<DOMEvents:ManakaiDOMEvent>,
                 ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>, %opt)) => 1,
          }->{$_->{Role}}) {
        unless ($feature) {
          $feature = {};
          for (keys %{dispm_collect_hash_prop_value
                   ($pack, ExpandedURI q<DOMMain:implementFeature>, %opt)}) {
            my @f = ([$State->{Type}->{$_}, [], 1]);
            while (defined (my $f = shift @f)) {
              my $version = $f->[0]->{ExpandedURI q<d:Version>};
              $version = '' unless defined $version;
              $f->[0]->{ExpandedURI q<dis2pm:notImplemented>}
                  = length $version
                      ? $f->[0]->{ExpandedURI q<dis2pm:notImplemented>}
                        ? 1 : 0
                      : 0;
              for my $fname (keys %{$f->[0]
                                      ->{ExpandedURI q<dis2pm:featureName>}}) {
                $feature->{$fname}->{$version}
                  = $f->[0]->{ExpandedURI q<dis2pm:notImplemented>} ? 0 : 1
                    if $f->[2];
                unless ($feature->{$fname}->{$version}) {
                  $feature->{$_->[0]}->{$_->[1]} = 0 for @{$f->[1]};
                }
              }
              push @f,
                map {[$State->{Type}->{$_},
                      ($f->[2]
                        ? [@{$f->[1]},
                           map {[$_, $version]}
                           keys %{$f->[0]
                                    ->{ExpandedURI q<dis2pm:featureName>}}]
                        : $f->[1]),
                      $f->[2]]}
                    @{$f->[0]->{ISA}||[]};
              push @f,
                map {[$State->{Type}->{$_},
                      ($f->[2]
                        ? [@{$f->[1]},
                           map {[$_, $version]}
                           keys %{$f->[0]
                                    ->{ExpandedURI q<dis2pm:featureName>}}]
                        : $f->[1]), 0]}
                    keys %{$f->[0]->{ExpandedURI q<dis2pm:requireFeature>}||{}}
                      if not $f->[0]->{ExpandedURI q<dis2pm:notImplemented>};
            }
          }
        }
        my %f = (
           packageName => $pack->{ExpandedURI q<dis2pm:packageName>},
           feature => $feature,
        );

        if ($_->{Role} eq $ev) {
          my @p = ($pack);
          my %pu;
          while (defined (my $p = shift @p)) {
            if ($p->{ExpandedURI q<dis2pm:type>} eq
                ExpandedURI q<ManakaiDOM:IF>) {
              $f{eventType}->{$p->{Name}} = 1;
            }
            $f{eventType}->{$_} = 1
              for keys %{$p->{ExpandedURI q<DOMEvents:createEventType>}||{}};
            $pu{defined $p->{URI} ? $p->{URI} : ''} = 1;
            push @p, grep {!$pu{defined $_->{URI} ? $_->{URI} : ''}}
                     map {$State->{Type}->{$_}}
                     (@{$p->{ISA}||[]}, @{$p->{Implement}||[]});
          }
        }
        
        $result .= perl_statement
                     (($compatres
                          ? perl_var (type => '$',
                                      package => $compatres
                                           ->{ExpandedURI q<dis2pm:packageName>},
                                      local_name => 'Class').
                            '{'.(perl_literal ($f{packageName})).'} = '
                          : '').
                       perl_var (type => '$',
                                 package => $roleres
                                           ->{ExpandedURI q<dis2pm:packageName>},
                                 local_name => 'Class').
                       '{'.(perl_literal ($f{packageName})).'} = '.
                       perl_literal \%f);
      } elsif ({
                dis_typeforuris_to_uri
                  (ExpandedURI q<DOMCore:DOMImplementationSource>,
                   ExpandedURI q<ManakaiDOM:ManakaiDOM>, %opt) => 1,
               }->{$_->{Role}}) {
        $result .= perl_statement
                     'push @org::w3c::dom::DOMImplementationSourceList, '.
                     perl_literal ($pack->{ExpandedURI q<dis2pm:packageName>});
      } else {
        valid_err qq{Role <$_->{Role}> not supported}, $_->{node};
      }
    }

    ## Members
    if ({
         ExpandedURI q<ManakaiDOM:Class> => 1,
         ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
         ExpandedURI q<DOMMain:ErrorClass> => 1,
         ExpandedURI q<ManakaiDOM:WarningClass> => 1,
        }->{$pack->{ExpandedURI q<dis2pm:type>}}) {
      local $State->{ExpandedURI q<dis2pm:thisClass>} = $pack;
      local $opt{ExpandedURI q<MDOMX:class>}
        = $pack->{ExpandedURI q<dis2pm:packageName>};
      for my $method (values %{$pack->{ExpandedURI q<dis2pm:method>}}) {
        next unless defined $method->{Name};
        if ($method->{ExpandedURI q<dis2pm:type>} eq
            ExpandedURI q<DISLang:Method>) {
          local $opt{ExpandedURI q<MDOMX:method>}
            = $method->{ExpandedURI q<dis2pm:methodName+>};
          local $opt{ExpandedURI q<dis2pm:currentMethodResource>} = $method;
          my $proto = '$';
          my @param = ('$self');
          my $param_norm = '';
          my $param_opt = 0;
          my $for = [keys %{$method->{For}}]->[0];
          local $opt{'For+'} = [keys %{$method->{'For+'}||{}}];
          for my $param (@{$method->{ExpandedURI q<dis2pm:param>}||[]}) {
            my $atype = $param->{ExpandedURI q<d:actualType>};
            if ($param->{ExpandedURI q<dis2pm:nullable>}) {
              $proto .= ';' unless $param_opt;
              $param_opt++;
            }
            if (dis_uri_ctype_match (ExpandedURI q<Perl:Array>, $atype, %opt)) {
              $proto .= '@';
              push @param, '@'.$param->{ExpandedURI q<dis2pm:paramName>};
            } elsif (dis_uri_ctype_match (ExpandedURI q<Perl:Hash>, $atype,
                                          %opt)) {
              $proto .= '%';
              push @param, '%'.$param->{ExpandedURI q<dis2pm:paramName>};
            } else {
              $proto .= '$';
              push @param, '$'.$param->{ExpandedURI q<dis2pm:paramName>};
            }
            my $nin = dis_get_attr_node
                         (%opt,
                          parent =>
                            $param->{ExpandedURI q<dis2pm:actualTypeNode>},
                          name => {uri =>
                                     ExpandedURI q<ManakaiDOM:noInputNormalize>},
                         );
            if ($nin and $nin->value) {
              ## No input normalizing
            } else {
              my $nm = dispm_get_code 
                        (%opt, resource => $State->{Type}->{$atype},
                         ExpandedURI q<dis2pm:DefKeyName>
                             => ExpandedURI q<ManakaiDOM:inputNormalizer>,
                         For => $for,
                         ExpandedURI q<dis2pm:getCodeNoTypeCheck> => 1,
                         ExpandedURI q<dis2pm:selParent>
                             => $param->{ExpandedURI q<dis2pm:actualTypeNode>});
              if (defined $nm) {
                $nm =~ s/\$INPUT\b/$param[-1]/g;
                ## NOTE: "Perl:Array" or "Perl:Hash" is not supported.
                $param_norm .= $nm;
              }
            }
          }
          my $code = dispm_get_code
                       (%opt, 
                        resource => $method->{ExpandedURI q<dis2pm:return>},
                        For => $for,
                        ExpandedURI q<dis2pm:DefKeyName>
                          => ExpandedURI q<d:Def>);
          if (defined $code) {
            my $my = perl_statement ('my ('.join (", ", @param).
                                     ') = @_');
            my $return = defined $method->{ExpandedURI q<dis2pm:return>}->{Name}
                            ? $method->{ExpandedURI q<dis2pm:return>} : undef;
            if ($return->{ExpandedURI q<d:actualType>} ? 1 : 0) {
              my $default = dispm_get_value
                           (%opt, resource => $return,
                            ExpandedURI q<dis2pm:ValueKeyName>
                                => ExpandedURI q<d:DefaultValue>,
                            ExpandedURI q<dis2pm:useDefaultValue> => 1,
                            ExpandedURI q<dis2pm:valueType>
                              => $return->{ExpandedURI q<d:actualType>});
              $code = $my . $param_norm . 
                      perl_statement
                        (defined $default ? 'my $r = '.$default : 'my $r').
                      $code . "\n" .
                      perl_statement ('$r');
            } else {
              $code = $my . $code;
            }
          } else { ## Code not defined
            my $for1 = $for;
            unless (dis_uri_for_match (ExpandedURI q<ManakaiDOM:ManakaiDOM1>,
                                       $for, node => $method->{src})) {
              $for1 = ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>;
            }
            $code = perl_statement 'my $self = shift;';
            $code .= perl_statement
                      dispm_perl_throws
                        class => ExpandedURI q<DX:CoreException>,
                        class_for => $for1,
                        type => 'NOT_SUPPORTED_ERR',
                        subtype =>
                          ExpandedURI q<MDOMX:MDOM_IMPL_METHOD_NOT_IMPLEMENTED>,
                        xparam => {
                          ExpandedURI q<MDOMX:class>
                                 => $pack->{ExpandedURI q<dis2pm:packageName>},
                          ExpandedURI q<MDOMX:method>
                                 => $method->{ExpandedURI q<dis2pm:methodName+>},
                        };
          }
          if (length $method->{ExpandedURI q<dis2pm:methodName>}) {
            $result .= perl_sub
                         (name => $method->{ExpandedURI q<dis2pm:methodName>},
                          code => $code, prototype => $proto);
          } else {
            $method->{ExpandedURI q<dis2pm:methodCodeRef>}
                     = perl_sub (name => '', code => $code, prototype => $proto);
          }
        } elsif ($method->{ExpandedURI q<dis2pm:type>} eq
                 ExpandedURI q<DISLang:Attribute>) {
          local $opt{ExpandedURI q<MDOMX:attr>}
            = $method->{ExpandedURI q<dis2pm:methodName+>};
          my $getter = $method->{ExpandedURI q<dis2pm:getter>};
          valid_err qq{Getter for attribute "$method->{Name}" must be }.
                    q{defined}, node => $method->{src} unless $getter;
          my $setter = defined $method->{ExpandedURI q<dis2pm:setter>}->{Name}
                         ? $method->{ExpandedURI q<dis2pm:setter>} : undef;
          my $for = [keys %{$method->{For}}]->[0];
          local $opt{'For+'} = [keys %{$method->{'For+'}||{}}];
          my $for1 = $for;
          unless (dis_uri_for_match (ExpandedURI q<ManakaiDOM:ManakaiDOM1>,
                                     $for, node => $method->{src})) {
            $for1 = ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>;
          }
          local $opt{ExpandedURI q<MDOMX:on>} = 'get';
          my $get_code = dispm_get_code (%opt, resource => $getter, For => $for,
                                         ExpandedURI q<dis2pm:DefKeyName>
                                           => ExpandedURI q<d:Def>);
          if (defined $get_code) {
            my $default = dispm_get_value
                           (%opt, resource => $getter,
                            ExpandedURI q<dis2pm:ValueKeyName>
                                => ExpandedURI q<d:DefaultValue>,
                            ExpandedURI q<dis2pm:useDefaultValue> => 1,
                            ExpandedURI q<dis2pm:valueType>
                              => $getter->{ExpandedURI q<d:actualType>});
            $get_code = perl_statement
                          (defined $default ? 'my $r = '.$default : 'my $r').
                        $get_code. "\n" .
                        perl_statement ('$r');
          } else { ## Get code not defined
            $get_code = perl_statement
                      dispm_perl_throws
                        class => ExpandedURI q<DX:CoreException>,
                        class_for => $for1,
                        type => 'NOT_SUPPORTED_ERR',
                        subtype =>
                          ExpandedURI q<MDOMX:MDOM_IMPL_ATTR_NOT_IMPLEMENTED>,
                        xparam => {
                          ExpandedURI q<MDOMX:class>
                                 => $pack->{ExpandedURI q<dis2pm:packageName>},
                          ExpandedURI q<MDOMX:attr>
                                 => $method->{ExpandedURI q<dis2pm:methodName+>},
                          ExpandedURI q<MDOMX:on> => 'get',
                        };
          }
          if ($setter) {
            local $opt{ExpandedURI q<MDOMX:on>} = 'set';
            my $set_code = dispm_get_code
                              (%opt, resource => $setter, For => $for,
                               ExpandedURI q<dis2pm:DefKeyName>
                                  => ExpandedURI q<d:Def>);
            if (defined $set_code) {
              my $nm = dispm_get_code 
                        (%opt, resource => $State->{Type}
                              ->{$setter->{ExpandedURI q<d:actualType>}},
                         ExpandedURI q<dis2pm:DefKeyName>
                             => ExpandedURI q<ManakaiDOM:inputNormalizer>,
                         For => $for,
                         ExpandedURI q<dis2pm:getCodeNoTypeCheck> => 1);
              if (defined $nm) {
                $nm =~ s/\$INPUT\b/\$given/g;
              } else {
                $nm = '';
              }
              $set_code = $nm .
                          $set_code. "\n";
            } else { ## Set code not defined
              $set_code = perl_statement
                      dispm_perl_throws
                        class => ExpandedURI q<DX:CoreException>,
                        class_for => $for1,
                        type => 'NOT_SUPPORTED_ERR',
                        subtype =>
                          ExpandedURI q<MDOMX:MDOM_IMPL_ATTR_NOT_IMPLEMENTED>,
                        xparam => {
                          ExpandedURI q<MDOMX:class>
                                 => $pack->{ExpandedURI q<dis2pm:packageName>},
                          ExpandedURI q<MDOMX:attr>
                                 => $method->{ExpandedURI q<dis2pm:methodName+>},
                          ExpandedURI q<MDOMX:on> => 'set',
                      };
            }
            $get_code = perl_if '@_ == 2',
                                perl_statement ('my ($self, $given) = @_').
                                $set_code,
                                perl_statement ('my ($self) = @_').
                                $get_code;
          } else {
            $get_code = perl_statement ('my ($self) = @_').
                        $get_code;
          }
          if (length $method->{ExpandedURI q<dis2pm:methodName>}) {
            $result .= perl_sub
                         (name => $method->{ExpandedURI q<dis2pm:methodName>},
                          prototype => $setter ? '$;$' : '$',
                          code => $get_code);
          } else {
            $method->{ExpandedURI q<dis2pm:methodCodeRef>}
                     = perl_sub (name => '', code => $get_code,
                                 prototype => $setter ? '$;$' : '$');
          }
        }
      } # package method

      ## -- Constants
      for my $cg (values %{$pack->{ExpandedURI q<dis2pm:constGroup>}}) {
        next unless defined $cg->{Name};
        $result .= dispm_const_group (resource => $cg);
      } # package const group
      for my $cv (values %{$pack->{ExpandedURI q<dis2pm:const>}}) {
        next unless defined $cv->{Name};
        $result .= dispm_const_value_sub (resource => $cv);
      } # package const value

      ## -- Error codes
      if ({
           ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
           ExpandedURI q<DOMMain:ErrorClass> => 1,
           ExpandedURI q<ManakaiDOM:WarningClass> => 1,
          }->{$pack->{ExpandedURI q<dis2pm:type>}}) {
        $result .= perl_sub
                     name => '___error_def',
                     prototype => '',
                     code => perl_list {
                       map {
                         $_->{Name} => {
                           ExpandedURI q<DOMCore:code>
                                => perl_code_literal
                                      dispm_const_value (%opt, resource => $_),
                           description => dispm_muf_description
                                                     (%opt, resource => $_),
                           ($_->{ExpandedURI q<DOMCore:severity>}
                              ? (ExpandedURI q<DOMCore:severity>
                                       => $_->{ExpandedURI q<DOMCore:severity>},
                                 ExpandedURI q<DOMCore:type>
                                       => $_->{ExpandedURI q<DOMCore:type>})
                                    : ()),
                           ExpandedURI q<MDOMX:subtype> => {
                             map {
                               $_->{NameURI} => {
                                 description => dispm_muf_description
                                                     (%opt, resource => $_),
                                 ($_->{ExpandedURI q<DOMCore:severity>}
                                    ? (ExpandedURI q<DOMCore:severity>
                                       => $_->{ExpandedURI q<DOMCore:severity>},
                                       ExpandedURI q<DOMCore:type>
                                       => $_->{ExpandedURI q<DOMCore:type>})
                                    : ()),
                               },
                             } grep {defined $_->{Name}}
                             values %{$_->{ExpandedURI q<dis2pm:xSubType>}||{}}
                           },
                         },
                       } grep {defined $_->{Name}}
                         values %{$pack->{ExpandedURI q<dis2pm:xConst>}||{}}
                     };
      }

      ## -- Operators
      my %ol;
      my %mtd;
      for (values %{$pack->{ExpandedURI q<dis2pm:overload>}||{}}) {
        next unless defined $_->{resource}->{Name};
        if ($_->{resource}->{ExpandedURI q<dis2pm:methodName+>} =~ /^\#/) {
          if ($_->{operator} =~ /^[A-Z]+$/) {
            my $code = $_->{resource}->{ExpandedURI q<dis2pm:methodCodeRef>};
            $code =~ s/\bsub /sub $_->{operator} /;
            $result .= $code;
            $mtd{$_->{operator}} = 1;
          } else {
            $ol{$_->{operator}} = perl_code_literal $_->{resource}
                                    ->{ExpandedURI q<dis2pm:methodCodeRef>};
          }
        } else {
          if ($_->{operator} =~ /^[A-Z]+$/) {
            $mtd{$_->{operator}} = 1;
            $result .= perl_statement
                         perl_assign
                              perl_var (type => '*',
                                        local_name => $_->{operator})
                           => perl_var (type => '\&',
                                        local_name => $_->{resource}
                                          ->{ExpandedURI q<dis2pm:methodName>});
          } else {
            $ol{$_->{operator}}
              = $_->{resource}->{ExpandedURI q<dis2pm:methodName>};
          }
        }
      }
      if (keys %ol) {
        $ol{fallback} = 1;
        $result .= perl_statement 'use overload '.perl_list %ol;
      }
      my $op2perl = {
        ExpandedURI q<ManakaiDOM:MUErrorHandler> => {
          method_name => '___report_error',
        },
        ExpandedURI q<DISPerl:AsStringMethod> => {
          method_name => 'as_string',
        },
        ExpandedURI q<DISPerl:NewMethod> => {
          method_name => 'new',
        },
        ExpandedURI q<DISPerl:CloneMethod> => {
          method_name => 'clone',
        },
      };
      for (values %{$pack->{ExpandedURI q<d:Operator>}||{}}) {
        next unless defined $_->{resource}->{Name};
        if ($op2perl->{$_->{operator}}) {
          if ($_->{resource}->{ExpandedURI q<dis2pm:methodName+>} =~ /^\#/) {
            my $code = $_->{resource}->{ExpandedURI q<dis2pm:methodCodeRef>};
            $code =~ s/\bsub /sub $op2perl->{$_->{operator}}->{method_name} /;
            $result .= $code;
          } else {
            $result .= perl_statement
                         perl_assign
                              perl_var (type => '*',
                                        local_name => $op2perl->{$_->{operator}}
                                                              ->{method_name})
                           => perl_var (type => '\&',
                                        local_name => $_->{resource}
                                          ->{ExpandedURI q<dis2pm:methodName>});
          }
          if ($_->{operator} eq ExpandedURI q<DISPerl:AsStringMethod>) {
            $result .= perl_statement
                         perl_assign
                              perl_var (type => '*',
                                        local_name => 'stringify')
                           => perl_var (type => '\&',
                                        local_name => $op2perl->{$_->{operator}}
                                                              ->{method_name});
          }
        } else {
          valid_err qq{Operator <$_->{operator}> is not supported},
                    node => $_->{resource}->{src};
        }
      }
    }
  } # root object
}


## -- Variables
for my $var (values %{$State->{Module}->{$State->{module}}
                            ->{ExpandedURI q<dis2pm:variable>}}) {
  next unless defined $var->{Name};
  my $default = dispm_get_value
                           (%opt, resource => $var,
                            ExpandedURI q<dis2pm:ValueKeyName>
                                => ExpandedURI q<d:DefaultValue>,
                            ExpandedURI q<dis2pm:useDefaultValue> => 1,
                            ExpandedURI q<dis2pm:valueType>
                              => $var->{ExpandedURI q<d:actualType>});

  ## ISSUE: scope

  my $v = perl_var
               (type => $var->{ExpandedURI q<dis2pm:variableType>},
                local_name => $var->{ExpandedURI q<dis2pm:variableName>});
  if (defined $default and length $default) {
    $result .= perl_statement
                       perl_assign $v => $default;
  } else {
    $result .= perl_statement $v;
  }

  if ($var->{ExpandedURI q<DISPerl:isExportOK>}) {
    $State->{ExpandedURI q<dis2pm:Package>}
                 ->{$State->{Module}->{$State->{module}}
                          ->{ExpandedURI q<dis2pm:packageName>}}
                 ->{ExpandedURI q<dis2pm:variable>}->{$v} = 1;
    ## NOTE: Variable name uniqueness is assured in dis.pl.
  }
}

## Constant exportion
{
  my @xok;
  my $xr = '';
  my $cg = $State->{ExpandedURI q<dis2pm:Package>}
                 ->{$State->{Module}->{$State->{module}}
                          ->{ExpandedURI q<dis2pm:packageName>}}
                 ->{ExpandedURI q<dis2pm:constGroup>};
  my %etag;
  for (keys %$cg) {
    $etag{$_} = $cg->{$_}->{member};
  }
  $xr .= perl_statement
           perl_assign
                perl_var (type => '%', local_name => 'EXPORT_TAG', 
                          scope => 'our')
             => '('.(perl_list %etag).')'
     if keys %etag;
  
  my $c = $State->{ExpandedURI q<dis2pm:Package>}
                 ->{$State->{Module}->{$State->{module}}
                          ->{ExpandedURI q<dis2pm:packageName>}}
                 ->{ExpandedURI q<dis2pm:const>};
  if (keys %$c) {
    push @xok, keys %$c;
    $xr .= join '', map {perl_statement "sub $_ ()"} keys %$c;
    my $al = perl_literal {map {$_ =>
                                $c->{$_}->{package}.'::'.$_} keys %$c};
    my $AL = '$al';
    my $ALD = '$AUTOLOAD';
    my $XL = '$Exporter::ExportLevel';
    my $SELF = '$self';
    my $ARGS = '@_';
    my $IT = '$_';
    my $REF = '\\';
    my $NONAME = '\W';
    $xr .= qq{
      sub AUTOLOAD {
        my $AL = our $ALD;
        $AL =~ s/.+:://;
        if ($al -> {$AL}) {
          no strict 'refs';
          *{$ALD} = $REF &{$al -> {$AL}};
          goto &{$ALD};
        } else {
          require Carp;
          Carp::croak (qq<Can't locate method "$ALD">);
        }
      }
      sub import {
        my $SELF = shift;
        if ($ARGS) {
          local $XL = $XL + 1;
          $SELF->SUPER::import ($ARGS);
          for (grep {not /$NONAME/} $ARGS) {
            eval qq{$IT};
          }
        }
      }
    };
  }

  for (keys %{$State->{ExpandedURI q<dis2pm:Package>}
                 ->{$State->{Module}->{$State->{module}}
                          ->{ExpandedURI q<dis2pm:packageName>}}
                 ->{ExpandedURI q<dis2pm:variable>}}) {
    push @xok, $_;
  }

  if (@xok) {
    $xr .= perl_statement
             perl_assign
                  perl_var (type => '@', local_name => 'EXPORT_OK',
                            scope => 'our')
               => '('.(perl_list @xok).')';
  }

  if ($xr) {
    $result .= perl_change_package (full_name => $State->{Module}
                                          ->{$State->{module}}
                                          ->{ExpandedURI q<dis2pm:packageName>});
    $result .= $xr;
    $result .= perl_statement 'use Exporter';
    $result .= perl_statement 'push our @ISA, "Exporter"';
  }
}

## Required modules
$result .= dispm_package_declarations;
my $begin = '';
for (keys %{$State->{Module}->{$State->{module}}
                  ->{ExpandedURI q<dis2pm:requiredModule>}||{}}) {
  next if $_ eq $State->{Module}->{$State->{module}}
                      ->{ExpandedURI q<dis2pm:packageName>};
  $begin .= perl_statement ('require ' . $_);
  $State->{ExpandedURI q<dis2pm:referredPackage>}->{$_} = -1;
}
$result = $begin . $result if $begin;

## Exception interfaces
for my $p (keys %{$State->{ExpandedURI q<dis2pm:xifReferred>}||{}}) {
  my $v = $State->{ExpandedURI q<dis2pm:xifReferred>}->{$p};
  if (ref $v or $v > 0) {
    $result .= perl_inherit ['Message::Util::Error'], $p;
    $State->{ExpandedURI q<dis2pm:referredPackage>}->{$p} = -1;
  }
}

my @ref;
for (keys %{$State->{ExpandedURI q<dis2pm:referredPackage>}||{}}) {
  my $v = $State->{ExpandedURI q<dis2pm:referredPackage>}->{$_};
  if (ref $v or $v > 0) {
    push @ref, $_;
  }
}
$result .= "for (" . join (", ", map {'$'.$_.'::'} @ref) . ") {}"
  if @ref;

$result = $header . $result . perl_statement 1;

output_result $result;

=head1 BUGS

Dynamic change for namespace binding, current "For", ... is poorly 
supported - it a code or element refers another code or element 
in the same or different source file, then their own bindings, not the former 
code or element's, should be used for resolution.  The current 
implementation does not do so perfectly.  So authors of 
"dis" files are encouraged not to bind the same namespace prefix
to different namespace URIs and to prefer prefixed QName. 

=head1 SEE ALSO

L<lib/manakai/dis.pl> - "dis" common utility. 

L<lib/manakai/DISCore.dis> - The definition for the "dis" format. 

L<lib/manakai/DISPerl.dis> - The definition for the "dis" Perl-specific 
vocabulary. 

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/02/18 06:13:52 $
