#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  d => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
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
  $s =~ s[<Q:([^<>]+)>|\b(null|true|false)\b][
    my ($q, $l) = ($1, $2);
    if (defined $q) {
      if ($q =~ /\}/) {
        valid_warn qq<QName "$q" has a "}" - it might be a typo>;
      }
      perl_literal (dis_qname_to_uri ($q, %opt));
    } else {
      {true => 1, false => 0, null => 'undef'}->{$l};
    }
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
    if ($name eq 'XCLASS' or      ## Manakai DOM Class
        $name eq 'XSUPER' or      ## Manakai DOM Class (internal)
        $name eq 'XIIF' or        ## DOM Interface + Internal interface & prop
        $name eq 'XIF') {         ## DOM Interface
      #local $Status->{condition} = $Status->{condition};
      if ($data =~ s/::([^:]*)$//) {
        #$Status->{condition} = $1;
      }
      #$r = perl_package_name {qw/CLASS name SUPER name IIF iif IF if/}->{$name}
      #                                   => $data,
      #                       is_internal => {qw/SUPER 1/}->{$name},
                             #condition => $Status->{condition};
    } elsif ($name eq 'XINT') {    ## Internal Method / Attr Name
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
      } elsif ($data =~ s/^<([^<>]+)>\s*(?::\s*|$)//) {
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
  my $key = $opt{ExpandedURI q<dis2pm:DefKeyName>} || ExpandedURI q<d:Def>;
  my $n = dis_get_attr_node (%opt, parent => $opt{resource}->{src},
                             name => {uri => $key},
                             ContentType => ExpandedURI q<lang:Perl>);
  if ($n) {
    return perl_code_source
             perl_code ($n->value,
                        %opt, node => $n),
             %opt,
             node => $n;
  }
  return undef;
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
      $type = ExpandedURI q<DOMMain:any>;  ## ISSUE: Is this appropriate type?
    }
    valid_err (qq<Type <$type> is not defined>, node => $t || $n)
      unless defined $State->{Type}->{$type}->{Name};
    
    if (dis_uri_ctype_match (ExpandedURI q<lang:Perl>, $type, %opt)) {
      ## ISSUE: Is some pre-process required?
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

for my $pack (values %{$State->{Module}->{$State->{module}}
                             ->{ExpandedURI q<dis2pm:package>}||{}}) {
  next unless defined $pack->{Name};
  if ({
       ExpandedURI q<ManakaiDOM:Class> => 1,
       ExpandedURI q<ManakaiDOM:IF> => 1,
       ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
       ExpandedURI q<ManakaiDOM:ExceptionIF> => 1,
       ExpandedURI q<ManakaiDOM:WarningIF> => 1,
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
          my $code = dispm_get_code
                       (resource => $method->{ExpandedURI q<dis2pm:return>});
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
            my $for = [keys %{$method->{For}}]->[0];
            unless (dis_uri_for_match (ExpandedURI q<ManakaiDOM:ManakaiDOM1>,
                                       $for, node => $method->{src})) {
              $for = ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>;
            }
            $code = perl_statement
                      dispm_perl_throws
                        class => ExpandedURI q<DOMCore:ManakaiDOMException>,
                        class_for => $for,
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
          my $setter = defined $method->{ExpandedURI q<dis2pm:setter>}->{Name}
                         ? $method->{ExpandedURI q<dis2pm:setter>} : undef;
          my $for = [keys %{$method->{For}}]->[0];
          unless (dis_uri_for_match (ExpandedURI q<ManakaiDOM:ManakaiDOM1>,
                                     $for, node => $method->{src})) {
            $for = ExpandedURI q<ManakaiDOM:ManakaiDOMLatest>;
          }
          my $get_code = dispm_get_code (resource => $getter);
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
                        class_for => $for,
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
            my $set_code = dispm_get_code (resource => $setter);
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
                        class_for => $for,
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
      ## TODO: Const
    }    
  ## TODO: Const
  } # root object
}

## Export
if (keys %{$State->{perl_primary_module}->{perl_export_ok}||{}}) {
  $result .= perl_change_package
               full_name => $State->{perl_primary_module}->{perl_package_name};
  $result .= perl_statement 'require Exporter';
  $result .= perl_inherit ['Exporter'];
  $result .= perl_statement
               perl_assign
                    perl_var (type => '@', scope => 'our',
                              local_name => 'EXPORT_OK')
                 => '(' . perl_list (keys %{$State->{perl_primary_module}
                                                  ->{perl_export_ok}}) . ')';
  if (keys %{$State->{perl_primary_module}->{perl_export_tags}||{}}) {
    $result .= perl_statement
                 perl_assign
                       perl_var (type => '%', scope => 'our',
                                 local_name => 'EXPORT_TAGS')
                   => '(' . perl_list (map {
                         $_ => [keys %{$State->{perl_primary_module}
                                             ->{perl_export_tags}->{$_}}]
                      } keys %{$State->{perl_primary_module}
                                     ->{perl_export_tags}}) . ')';
  }
}

$result .= perl_statement 1;

output_result $result;

1;
