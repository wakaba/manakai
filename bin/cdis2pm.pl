#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  d => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  disPerl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis--Perl-->,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  MDOMX => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>,
  owl => q<http://www.w3.org/2002/07/owl#>,
  rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
  rdfs => q<http://www.w3.org/2000/01/rdf-schema#>,
};

use Getopt::Long;
use Pod::Usage;
use Storable;
my %Opt;
GetOptions (
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'module-name=s' => \$Opt{module_name},
  'module-uri=s' => \$Opt{module_uri},
  'verbose!' => $Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage (2) if not $Opt{module_uri} and not $Opt{module_name};

BEGIN {
require 'manakai/genlib.pl';
require 'manakai/dis.pl';
}
our $State = retrieve ($Opt{file_name})
     or die "$0: $Opt{file_name}: Cannot load";
our $result = '';

eval q{
  sub impl_msg ($;%) {
    warn shift () . "\n";
  }
} unless $Opt{verbose};

sub perl_change_package (%) {
  my %opt = @_;
  my $fn = $opt{full_name};
  impl_err (qq<$fn: Bad package name>) unless $fn;
  unless ($fn eq $State->{ExpandedURI q<dis2pm:currentPackage>}) {
    $State->{ExpandedURI q<dis2pm:currentPackage>} = $fn;
    return perl_statement qq<package $fn>;
  } else {
    return '';
  }
} # perl_change_package

=item $code = dispm_perl_throws (%opt)

Generates a code to throw an exception.

=cut

sub dispm_perl_throws (%) {
  my %opt = @_;
  my $x = $State->{Type}->{$opt{class}};
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
        ExpandedURI q<ManakaiDOM:WarningClass> => 1,
      }->{$x->{ExpandedURI q<dis2pm:type>}}) {
    $r .= $x->{ExpandedURI q<dis2pm:packageName>} . ' ' .
          perl_list -type => $opt{type},
                    -object => perl_code_literal ('$self'),
                    %{$opt{xparam} || {}};
  } else {
    no warnings 'uninitialized';
    valid_err (qq{Resource <$opt{class}> (<$x->{ExpandedURI q<dis2pm:type>}>) }.
               q<is neither exception class nor >.
               q<warning class>, node => $opt{node});
  }
  return $r;
} # dispm_perl_throw

{
use re 'eval';
my $RegBlockContent;
$RegBlockContent = qr/(?>[^{}\\]*)(?>(?>[^{}\\]+|\\.|\{(??{$RegBlockContent})\})*)/s;
## Defined by genlib.pl but overridden.
sub perl_code ($;%) {
  my ($s, %opt) = @_;
  valid_err q<Uninitialized value in perl_code>,
    node => $opt{node} unless defined $s;
  local $State->{Namespace}
    = $State->{Module}->{$opt{resource}->{parentModule}}->{nsBinding};
  $s =~ s[<(\w[^<>]+)>|\b(null|true|false)\b][
    my ($q, $l) = ($1, $2);
    my $r;
    if (defined $q) {
      if ($q =~ /\}/) {
        valid_warn qq<"<$q>" has a "}" - it might be a typo>;
      }
      if ($q =~ s/^(.+?):://) {
        my $et = dis_qname_to_uri
                     ($1, %opt,
                      use_default_namespace => ExpandedURI q<disPerl:>);
        if ($et eq ExpandedURI q<disPerl:Q>) {          ## QName constant
          $r = perl_literal (dis_qname_to_uri ($q, use_default_namespace => 1,
                                               %opt));
        } elsif ($et eq ExpandedURI q<disPerl:M>) {     ## Method call
          my ($clsq, $mtdq) = split /\s*\.\s*/, $q;
          my $clsu = dis_typeforqnames_to_uri ($clsq,
                                               use_default_namespace => 1, %opt);
          my $cls = $State->{Type}->{$clsu};
          my $clsp = $cls->{ExpandedURI q<dis2pm:packageName>};
          valid_err qq<Package name of class <$clsu> must be defined>,
                    node => $opt{node} unless defined $clsp;
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
            $r = ' ' . $clsp . '::' .
                 $mtd->{ExpandedURI q<dis2pm:methodName>} . ' ';
          }
        } elsif ($et eq ExpandedURI q<disPerl:ClassName>) {
                                                        ## Perl package name
          my $uri = dis_typeforqnames_to_uri ($q, 
                                              use_default_namespace => 1, %opt);
          if (defined $State->{Type}->{$uri}->{Name} and
              defined $State->{Type}->{$uri}
                            ->{ExpandedURI q<dis2pm:packageName>}) {
            $r = perl_literal ($State->{Type}->{$uri}
                                     ->{ExpandedURI q<dis2pm:packageName>});
          } else {
            valid_err qq<Package name of class <$uri> must be defined>,
              node => $opt{node};
          }
        } elsif ($et eq ExpandedURI q<disPerl:CODE>) {  ## CODE constant
          my $uri = dis_typeforqnames_to_uri ($q, use_default_namespace => 1,
                                              %opt);
          if (defined $State->{Type}->{$uri}->{Name} and
              dis_resource_ctype_match (ExpandedURI q<dis2pm:InlineCode>,
                                        $State->{Type}->{$uri}, %opt)) {
            ## ISSUE: It might be required to check loop referring
            $r = dispm_get_code (%opt, resource => $State->{Type}->{$uri},
                                 For => [keys %{$State->{Type}->{$uri}
                                                      ->{For}}]->[0],
                                 is_inline => 1);
          } else {
            valid_err qq<Inline code constant <$uri> must be defined>,
              node => $opt{node};
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
    \b__([A-Z]+)
    (?:\{($RegBlockContent)\})?
    __\b
  }{
    my ($name, $data) = ($1, $2);
    my $r;
    if ($name eq 'XINT') {    ## Inserting point of the for-internal code
      if (defined $data) {
        if ($data =~ /^{($RegBlockContent)}$/o) {
          $data = $1;
          my $name = $1 if $data =~ s/^\s*(\w+)\s*(?:$|:\s*)// or
            valid_err qq<Syntax of preprocessing macro "INT" is invalid>,
            node => $opt{node};
          #local $Status->{preprocess_variable}
          #                 = {%{$Status->{preprocess_variable}||{}}};
          while ($data =~ /\G(\S+)\s*(?:=>\s*(\S+)\s*)?(?:,\s*|$)/g) {
            my ($n, $v) = ($1, defined $2 ? $2 : 1);
            for ($n, $v) {
              s/^'([^']+)'$/$1/; ## ISSUE: Doesn't support quoted-'
            }
            #$Status->{preprocess_variable}->{$n} = $v;
          }
          valid_err q<Preprocessing macro INT{} cannot be used here>
            unless $opt{internal};
          $r = perl_comment ("INT: $name").
               $opt{internal}->($name);
        } elsif ($data =~ s/^SP://) {
          $r = '___'.$data;
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
    } elsif ($name eq 'XEXCEPTION' or $name eq 'XWARNING') {
                                  ## Raising an Exception or Warning
      if ($data =~ s/^\s*(\w+)\s*\.\s*(\w+)\s*(?:\.\s*([\w:]+)\s*)?(?:::\s*|$)//) {
        $r = perl_exception (level => $name,
                             class => $1,
                             type => $2,
                             subtype => $3,
                             param => perl_code $data);
      } else {
        valid_err qq<Exception type and name required: "$data">,
          node => $opt{node};
      }      
    } elsif ($name eq 'XCODE') { # Built-in code
      my ($nm, %param);
      if ($data =~ s/^(\w+)\s*(?::\s*|$)//) {
        $nm = $1;
      } elsif ($data =~ s/^<(\w[^<>]+)>\s*(?::\s*|$)//) {
        $nm = $1;
      } else {
        valid_err q<Built-in code name required>;
      }
      while ($data =~ /\G(\S+)\s*=>\s*(\S+)\s*(?:,\s*|$)/g) {
        $param{$1} = $2;
      }
      $r = perl_builtin_code ($nm, condition => $opt{condition}, %param);
    } elsif ($name eq 'XPACKAGE' and $data) {
      if ($data eq 'Global') {
        #$r = $ManakaiDOMModulePrefix;
      } else {
        valid_err qq<PACKAGE "$data" not supported>;
      }
    } elsif ($name eq 'XREQUIRE') {
      #$r = perl_statement (q<require >. perl_package_name name => $data);
    } elsif ($name eq 'XWHEN') {
      if ($data =~ s/^\s*IS\s*\{($RegBlockContent)\}::\s*//o) {
        my $v = $1;
        if ($v =~ /^\s*'([^']+)'\s*$/) { ## ISSUE: Doesn't support quoted-'
          if ($State->{preprocess_variable}->{$1}) {
            $r = perl_code ($data, %opt);
          } else {
            $r = perl_comment ($data);
          }
        } else {
          valid_err qq<WHEN-IS condition "$v" is invalid>,
            node => $opt{node};
        }
      } else {
        valid_err qq<Syntax for preprocessing macro "WHEN" is invalid>,
          node => $opt{node};
      }
    } elsif ($name eq 'FILE' or $name eq 'LINE' or $name eq 'PACKAGE') {
      $r = qq<__${name}__>;
    } else {
      $r = $&;
      #valid_err qq<Preprocessing macro "$name" not supported>;
    }
    $r;
  }goex;
  $s;
}
}

## Defined in genlib.pl but overridden.
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
}




=item $code = dispm_get_code (resource => $res, %opt)

Generates a Perl code fragment from resource(s).

=cut

sub dispm_get_code (%) {
  my %opt = @_;
  if (($opt{resource}->{ExpandedURI q<dis2pm:type>} and
       {
         ExpandedURI q<ManakaiDOM:DOMMethodReturn> => 1,
         ExpandedURI q<ManakaiDOM:DOMAttrGet> => 1,
         ExpandedURI q<ManakaiDOM:DOMAttrSet> => 1,
       }->{$opt{resource}->{ExpandedURI q<dis2pm:type>}}) or
      (dis_resource_ctype_match ([ExpandedURI q<dis2pm:InlineCode>,
                                  ExpandedURI q<dis2pm:BlockCode>],
                                 $opt{resource}, %opt,
                                 node => $opt{resource}->{src}))) {
    my $key = $opt{ExpandedURI q<dis2pm:DefKeyName>} || ExpandedURI q<d:Def>;
    my $n = dis_get_attr_node (%opt, parent => $opt{resource}->{src},
                               name => {uri => $key},
                               ContentType => ExpandedURI q<lang:Perl>);
    if ($n) {
      my $code = perl_code ($n->value, %opt, node => $n);
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
  my $key = $opt{ExpandedURI q<dis2pm:DefKeyName>} || ExpandedURI q<d:Value>;
  my $vt = $opt{ExpandedURI q<dis2pm:valueType>} || ExpandedURI q<DOMMain:any>;
  my $n = dis_get_elements_nodes (%opt, parent => $opt{resource}->{src},
                                  name => {uri => $key});
  for my $n (@$n) {
    my $t = dis_get_attr_node (%opt, parent => $n, name => 'ContentType');
    my $type;
    if ($t) {
      $type = dis_qname_to_uri ($t->value, %opt, node => $t);
    } else {
      $type = ExpandedURI q<lang:dis>;
    }
    valid_err (qq<Type <$type> is not defined>, node => $t || $n)
      unless defined $State->{Type}->{$type}->{Name};
    
    if (dis_uri_ctype_match (ExpandedURI q<lang:Perl>, $type, %opt)) {
      ## ISSUE: Is some pre-process required?
      return $n->value;
    } elsif (dis_uri_ctype_match (ExpandedURI q<lang:dis>, $type, %opt)) {
      ## NOTE: This might not be a valid Perl code fragment.
      return $n->value;
    }
  }

  ## No explicit value specified
  if ($opt{ExpandedURI q<dis2pm:useDefaultValue>}) {
    if (dis_uri_ctype_match (ExpandedURI q<DOMMain:DOMString>, $vt, %opt)) {
      return q<"">;
    }
  }
  return undef;
} # dispm_get_value



=item $code = dispm_const_value (resource => $const, %opt)

Returns a code fragment to declare and define a constant function 
corresponding to the definition of C<$const>.

=cut

sub dispm_const_value (%) {
  my %opt = @_;
  my $for = [keys %{$opt{resource}->{For}}]->[0];
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
  return perl_sub
            (name => $opt{resource}->{ExpandedURI q<dis2pm:constName>},
             prototype => '',
             code => $value);
} # dispm_const_value

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
  for my $cv (values %{$opt{resource}->{ExpandedURI q<dis2pm:const>}}) {
    next unless defined $cv->{ExpandedURI q<dis2pm:constName>};
    $result .= dispm_const_value (%opt, resource => $cv);
    push @cname, $cv->{ExpandedURI q<dis2pm:constName>};
  }
  return $result;
} # dispm_const_group


## Outputed module and "For"
my $mf = dis_get_module_uri (module_name => $Opt{module_name},
                             module_uri => $Opt{module_uri},
                             For => $Opt{For});
$State->{DefaultFor} = $mf->{For};
$State->{module} = $mf->{module};

valid_err
 (qq{Perl module <$State->{module}> not defined for <$State->{DefaultFor}>},
  node => $State->{Module}->{$State->{module}}->{src})
    unless $State->{Module}->{$State->{module}}
                 ->{ExpandedURI q<dis2pm:packageName>};

$State->{ExpandedURI q<dis2pm:currentPackage>} = 'main';
$result .= "#!/usr/bin/perl \n";
$result .= perl_comment q<This file is automatically generated from> . "\n" .
                        q<"> . $Opt{file_name} . q<" at > .
                        rfc3339_date (time) . qq<.\n> .
                        q<Don't edit by hand!>;
$result .= perl_comment qq{Module <$State->{module}>};
$result .= perl_comment qq{For <$State->{DefaultFor}>};
$result .= perl_statement q<use strict>;
$result .= perl_change_package
                  (full_name => $State->{Module}->{$State->{module}}
                                      ->{ExpandedURI q<dis2pm:packageName>});
$result .= perl_statement
                 perl_assign
                      perl_var (type => '$', local_name => 'VERSION',
                                scope => 'our')
                   => perl_literal version_date time;

## -- Classes
for my $pack (values %{$State->{Module}->{$State->{module}}
                             ->{ExpandedURI q<dis2pm:package>}||{}}) {
  next unless defined $pack->{Name};
  if ({
       ExpandedURI q<ManakaiDOM:Class> => 1,
       ExpandedURI q<ManakaiDOM:IF> => 1,
       ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
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
    my $isa = [];
    for my $uri (@{$pack->{ISA}||[]}, @{$pack->{Implement}||[]}) {
      my $pack = $State->{Type}->{$uri};
      if (defined $pack->{ExpandedURI q<dis2pm:packageName>}) {
        push @$isa, $pack->{ExpandedURI q<dis2pm:packageName>};
      } else {
        impl_msg ("Inheriting package name for <$uri> not defined",
                  node => $pack->{src}) if $Opt{verbose};
      }
    }
    $isa = array_uniq $isa;
    $result .= perl_inherit $isa;
    $result .= '$' . $_ . "::;\n" for @$isa;
    ## Members
    if ({
         ExpandedURI q<ManakaiDOM:Class> => 1,
         ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
         ExpandedURI q<ManakaiDOM:WarningClass> => 1,
        }->{$pack->{ExpandedURI q<dis2pm:type>}}) {
      for my $method (values %{$pack->{ExpandedURI q<dis2pm:method>}}) {
        next unless defined $method->{Name};
        if ($method->{ExpandedURI q<dis2pm:type>} eq
            ExpandedURI q<ManakaiDOM:DOMMethod>) {
          my $proto = '$';
          my @param = ('self');
          my $param_opt = 0;
          for my $param (@{$method->{ExpandedURI q<dis2pm:param>}||[]}) {
            if ($param->{ExpandedURI q<dis2pm:nullable>}) {
              $proto .= ';' unless $param_opt;
              $param_opt++;
            }
            $proto .= '$';
            push @param, $param->{ExpandedURI q<dis2pm:paramName>};
          }
          my $for = [keys %{$method->{For}}]->[0];
          my $code = dispm_get_code
                       (resource => $method->{ExpandedURI q<dis2pm:return>},
                        For => $for);
          if (defined $code) {
            my $my = perl_statement ('my ('.join (", ", map {"\$$_"} @param).
                                     ') = @_');
            my $return = defined $method->{ExpandedURI q<dis2pm:return>}->{Name}
                            ? $method->{ExpandedURI q<dis2pm:return>} : undef;
            if ($return->{ExpandedURI q<d:actualType>} ? 1 : 0) {
              my $default = dispm_get_value
                           (resource => $return,
                            ExpandedURI q<dis2pm:ValueKeyName>
                                => ExpandedURI q<d:DefaultValue>,
                            ExpandedURI q<dis2pm:useDefaultValue> => 1,
                            ExpandedURI q<dis2pm:valueType>
                              => $return->{ExpandedURI q<d:actualType>});
              $code = $my . 
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
            $code = perl_statement
                      dispm_perl_throws
                        class => ExpandedURI q<DOMCore:ManakaiDOMException>,
                        class_for => $for1,
                        type => 'NOT_SUPPORTED_ERR',
                        subtype =>
                          ExpandedURI q<MDOMX:MDOM_IMPL_METHOD_NOT_IMPLEMENTED>,
                        xparam => {
                          ExpandedURI q<MDOMX:class>
                                 => $pack->{ExpandedURI q<dis2pm:packageName>},
                          ExpandedURI q<MDOMX:method>
                                 => $method->{ExpandedURI q<dis2pm:methodName>},
                        };
          }
          $result .= perl_sub
                       (name => $method->{ExpandedURI q<dis2pm:methodName>},
                        code => $code, prototype => $proto);
        } elsif ($method->{ExpandedURI q<dis2pm:type>} eq
                 ExpandedURI q<ManakaiDOM:DOMAttribute>) {
          my $getter = $method->{ExpandedURI q<dis2pm:getter>};
          valid_err qq{Getter for attribute "$method->{Name}" must be }.
                    q{defined}, node => $method->{src} unless $getter;
          my $setter = defined $method->{ExpandedURI q<dis2pm:setter>}->{Name}
                         ? $method->{ExpandedURI q<dis2pm:setter>} : undef;
          my $for = [keys %{$method->{For}}]->[0];
          my $for1 = $for;
          unless (dis_uri_for_match (ExpandedURI q<ManakaiDOM:ManakaiDOM1>,
                                     $for, node => $method->{src})) {
            $for1 = ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>;
          }
          my $get_code = dispm_get_code (resource => $getter, For => $for);
          if (defined $get_code) {
            my $default = dispm_get_value
                           (resource => $getter,
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
                        class => ExpandedURI q<DOMCore:ManakaiDOMException>,
                        class_for => $for1,
                        type => 'NOT_SUPPORTED_ERR',
                        subtype =>
                          ExpandedURI q<MDOMX:MDOM_IMPL_ATTR_NOT_IMPLEMENTED>,
                        xparam => {
                          ExpandedURI q<MDOMX:class>
                                 => $pack->{ExpandedURI q<dis2pm:packageName>},
                          ExpandedURI q<MDOMX:attr>
                                 => $method->{ExpandedURI q<dis2pm:methodName>},
                          ExpandedURI q<MDOMX:on> => 'get',
                        };
          }
          if ($setter) {
            my $set_code = dispm_get_code (resource => $setter, For => $for);
            if (defined $set_code) {
              my $default = dispm_get_value
                           (resource => $setter,
                            ExpandedURI q<dis2pm:ValueKeyName>
                                => ExpandedURI q<d:DefaultValue>,
                            ExpandedURI q<dis2pm:useDefaultValue> => 1,
                            ExpandedURI q<dis2pm:valueType>
                              => $getter->{ExpandedURI q<d:actualType>});
              $set_code = perl_statement
                          (defined $default ? 'my $r = '.$default : 'my $r').
                          $set_code. "\n" .
                          perl_statement ('$r');
            } else { ## Set code not defined
              $set_code = perl_statement
                      dispm_perl_throws
                        class => ExpandedURI q<DOMCore:ManakaiDOMException>,
                        class_for => $for1,
                        type => 'NOT_SUPPORTED_ERR',
                        subtype =>
                          ExpandedURI q<MDOMX:MDOM_IMPL_ATTR_NOT_IMPLEMENTED>,
                        xparam => {
                          ExpandedURI q<MDOMX:class>
                                 => $pack->{ExpandedURI q<dis2pm:packageName>},
                          ExpandedURI q<MDOMX:attr>
                                 => $method->{ExpandedURI q<dis2pm:methodName>},
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
          $result .= perl_sub
                       (name => $method->{ExpandedURI q<dis2pm:methodName>},
                        prototype => $setter ? '$;$' : '$',
                        code => $get_code);
        }
      } # package method
      for my $cg (values %{$pack->{ExpandedURI q<dis2pm:constGroup>}}) {
        next unless defined $cg->{Name};
        $result .= dispm_const_group (resource => $cg);
      } # package const group
      for my $cv (values %{$pack->{ExpandedURI q<dis2pm:const>}}) {
        next unless defined $cv->{Name};
        $result .= dispm_const_value (resource => $cv);
      } # package const value
    }
  } # root object
}

$result .= perl_statement 1;

output_result $result;

1;
