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
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
};
my $ManakaiDOMModulePrefix = q<Message::DOM>;

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
  output_result $result;
  die @_;
}
sub valid_warn (@) {
  warn @_;
}

## Implementation (this script) might be broken
sub impl_err (@) {
  die @_;
}
sub impl_warn (@) {
  warn @_;
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
  shift () . ' = ' . join ', ', @_;
}

sub perl_name ($;%) {
  my ($s, %opt) = @_;
  $s =~ s/[- ](.|$)/uc $1/ge;
  $s = ucfirst $s if $opt{ucfirst};
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
  } elsif ($opt{full_name}) {
    $r = $opt{full_name};
  } else {
    valid_err q<$opt{name} is false>;
  }
  if ($opt{condition}) {
    $r = $r . '::' . perl_name $opt{condition};
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

sub perl_sub (%) {
  my %opt = @_;
  my $r = 'sub ';
  $r .= $opt{name} . ' ' if $opt{name};
  $r .= '(' . $opt{prototype} . ') ' if $opt{prototype};
  $r .= "{\n";
  $r .= $opt{code};
  $r .= "}\n";
}

sub perl_var (%) {
  my %opt = @_;
  my $r = $opt{type} || '';
  $r .= perl_package_name %{$opt{package}} if $opt{package};
  $r .= '::' . $opt{local_name};
  $r;
}

{
use re 'eval';
my $RegBlockContent;
$RegBlockContent = qr/(?>[^{}\\]*)(?>(?>[^{}\\]+|\\.|\{(??{$RegBlockContent})\})*)/s;
sub perl_code ($;%);
sub perl_code ($;%) {
  my ($s, %opt) = @_;
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
    } elsif ($name eq 'IF') {     ## DOM Interface Name
      $r = perl_package_name if => $data;
    } elsif ($name eq 'INT') {    ## Internal Method / Attr Name
      if (defined $data) {
        $r = perl_internal_name $data;
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
    } elsif ($name eq 'FILE' or $name eq 'LINE' or $name eq 'PACKAGE') {
      $r = qq<__${name}__>;
    } else {
      valid_err qq<Preprocessing macro $name not supported>;
    }
    $r;
  }goex;
  $s;
}
}

sub perl_code_source ($%) {
  my ($s, %opt) = @_;
  sprintf qq<#line %d "File <%s> Node <%s>"\n%s\n> .
          qq<#line 1 "File <%s> Generated fragment #%d"\n>,
    $opt{line} || 1, $opt{file} || $Info->{source_filename},
    $opt{path} || 'x:unknown ()', $s, 
    $opt{file} || $Info->{source_filename}, ++$Status->{generated_fragment};
}

sub perl_literal ($) {
  my $s = shift;
  if (ref $s eq 'ARRAY') {
    return q<[> . perl_list (@$s) . q<]>;
  } elsif (ref $s eq 'HASH') {
    return q<{> . perl_list (%$s) . q<}>;
  } elsif (ref $s eq 'CODE') {
    impl_err q<CODE reference cannot be serialized>;
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
  $opt{level} ||= 'EXCEPTION';
  perl_statement q<report > . $opt{class} . q< > .
                 perl_list (level => $opt{level},
                            -type => $opt{type}) . ', ' . $opt{param};
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
  '=head' . $level . ' ' . $s;
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
  if ($s =~ /[<>]/) {
    return qq<C<<< $s >>>>;
  } else {
    return qq<C<$s>>;
  }
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

sub type_label ($) {
  my $uri = shift;
  if ($uri =~ /([\w_-]+)$/) {
    return $1;
  } else {
    return "<$uri>";
  }
}

sub expanded_uri ($) {
  my $lname = shift || '';
  my $pfx = '#default';
  if ($lname =~ s/^([^:]*)://) {
    $pfx = $1;
  }
  if ($Info->{Namespace}->{$pfx}) {
    return $Info->{Namespace}->{$pfx} . $lname;
  } else {
    valid_err qq<Namespace "$pfx" not declared>;
  }
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


sub get_perl_definition_node ($%) {
  my ($node, %opt) = @_;
  my $ln = $opt{name} || 'Def';
  my $def = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    expanded_uri $you->get_attribute_value ('Type', default => '')
      eq ExpandedURI q<lang:Perl>;
  }) || $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    not $you->get_attribute_value ('Type', default => '');
  });
  $def;
}

sub get_perl_definition ($%) {
  my ($node, %opt) = @_;
  my $def = get_perl_definition_node $node, %opt;
  $def ? $def->value : $opt{default};
}

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
  my $l = $node->get_attribute_value ('Level', default => []);
  $l = [$l] unless ref $l;
  unless (@$l) {
    my $min = $opt{level}->[0] || 1;
    for ($min..3) {
      if ($Info->{Condition}->{'DOM' . $_}) {
        unshift @$l, $_;
        last;
      }
    }
  }
  return q<> unless @$l;
  @$l = sort {$a <=> $b} @$l;
  @{$opt{level}} = @$l;
  my $r = q<introduced in DOM Level > . (0 + shift @$l);
  if (@$l > 1) {
    my $s = 0 + pop @$l;
    $r .= q< and modified in DOM Levels > . join ', ', @$l;
    $r .= qq< and $s>;
  } elsif (@$l == 1) {
    $r .= q< and modified in DOM Level > . (0 + $l->[0]);
  }
  $r;
}


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
  local $Status->{IF} = $if_name;

  my @level;
  my $mod = get_level_description $node, level => \@level;
  $mod = ', that has been ' . $mod if $mod;
  my $result = pod_block
               pod_head ($Status->{depth}, 'Interface ' . pod_code $if_name),
               pod_para (pod_code ($pack_name) .
                         q< implements the DOM interface > .
                         pod_code ($if_name) . $mod . q<.>),
               pod_paras (get_description ($node));

  my $version = perl_statement perl_assign 'our $VERSION', version_date time;
  my $isa = $node->get_attribute_value ('ISA', default => []);
  $isa = [$isa] unless ref $isa;
  @$isa = map {perl_package_name name_with_condition => $_} @$isa;
  for my $condition ((sort keys %{$Info->{Condition}}), '') {
    if ($condition =~ /^DOM(\d+)$/) {
      next if @level and $level[0] > $1;
    }
    my $if_pack = perl_package_name if => $if_name,
                                    condition => $condition;
    $result .= perl_package full_name => $pack_name, condition => $condition;
    if ($condition) {
      my @isa = map {perl_package_name name_with_condition => $_}
                    @{$Info->{Condition}->{$condition} or
                      valid_err qq<Condition $condition not defined>}
           if $condition;
      @isa = @$isa unless @isa;
      $result .= perl_statement 'push our @ISA, ' . perl_list $if_pack, @isa;
      $result .= perl_statement 'push ' .
                                perl_var (type => '@',
                                          package => {full_name => $if_pack},
                                          local_name => 'ISA') .
                                ', ' . perl_literal perl_package_name
                                                      if => $if_name;
      $Info->{DefaultCondition} ||= $if_pack;
    } else {
      $result .= perl_statement 'push our @ISA, ' .
                      perl_literal perl_package_name
                                     if => $if_name,
                                     condition => $Info->{DefaultCondition}
        if $Info->{DefaultCondition};
    }
    $result .= $version;

    for (@{$node->child_nodes}) {
      if ($_->get_attribute_value ('Condition', default => '') ne $condition) {
        if ($condition =~ /^DOM(\d+)$/) {
          my $level = $_->get_attribute_value ('Level', default => \@level);
          next unless array_contains $level, 0+$1;
        } else {
          next;
        }
      }
      
      if ($_->local_name eq 'Method' or
          $_->local_name eq 'IntMethod' or
          $_->local_name eq 'ReMethod') {
        $result .= method2perl ($_, level => \@level, condition => $condition);
      } elsif ($_->local_name eq 'Attr' or
               $_->local_name eq 'IntAttr' or
               $_->local_name eq 'ReAttr') {
        
      } elsif ($_->local_name eq 'ConstGroup') {
        
      } elsif ($_->local_name eq 'Const') {

      } elsif ({qw/Name 1 Spec 1 ISA 1 Description 1
                   Level 1/}->{$_->local_name}) {
        #
      } else {
        valid_warn qq{Element @{[$_->local_name]} not supported};
      }
    }
  }

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
  if ($node->get_attribute ('Param')) {
    for (@{$node->child_nodes}) {
      if ($_->local_name eq 'Param') {
        my $name = perl_name $_->get_attribute_value ('Name');
        push @param_list, '$' . $name;
        push @param_desc, pod_item (pod_code '$' . $name),
                          pod_para get_description $_;
        $param_prototype .= '$';
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
               $level ? pod_para ('Method ' . pod_code ($m_name) .
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
  my $code_node = get_perl_definition_node $return;
  my $int_code_node = get_perl_definition_node $return, name => 'IntDef';
  my $code = '';
  my $int_code = '';
  if ($code_node) {
    $code = perl_code_source (perl_code ($code_node->value,
                                         internal => sub {
                                           if ($int_code_node) {
                                             $int_code_node->value;
                                           } else {
                                             valid_err "<IntDef> for $m_name" .
                                                       " required";
                                           }
                                         }),
                              path => $code_node->node_path (key => 'Name'));
    $code = perl_statement (perl_assign 'my $r' => perl_literal '') .
            $code .
            perl_statement ('$r')
      if $has_return;
    $code = perl_statement (perl_assign 'my (' .
                                        join (', ', '$self', @param_list) .
                                        ')' => '@_') .
            $code;
    if ($int_code_node) {
      $int_code = perl_code_source (perl_code ($int_code_node->value),
                                    path => $int_code_node->node_path
                                              (key => 'Name'));
      $int_code = perl_statement (perl_assign 'my $r' => perl_literal '') .
                  $int_code .
                  perl_statement ('$r')
        if $has_return;
      $int_code = perl_statement (perl_assign 'my (' .
                                        join (', ', '$self', @param_list) .
                                        ')' => '@_') .
                  $int_code;
    }

    if ($has_return) {
      push @return, pod_item ('Returned Value: ' .
                              type_label expanded_uri
                                           $return->get_attribute_value
                                                      ('Type', default => '')),
                    pod_para (get_description $return);
    }
    for (@{$return->child_nodes}) {
      next unless $_->local_name eq 'Result';
      my $label = $_->get_attribute_value ('Label', default => '');
      unless (length $label) {
        $label = $_->get_attribute_value ('Value', default => '');
        if (length $label) {
          $label = pod_code $label;
        } else {
          $label = type_label expanded_uri $_->get_attribute_value
                                                 ('Type', default => '');
        }
      }
      push @return, pod_item ('Returned Value: ' . $label),
                    pod_para (get_description $_);
      $has_return++;
    }
  } else {
    $int_code = $code
              = perl_exception
                  level => 'EXCEPTION',
                  class => 'DOMException',
                  type => 'NOT_SUPPORTED_ERR',
                  param => {
                    if => $Status->{IF},
                    method => $Status->{Method},
                  };
    @return = ();
    push @return, pod_item ('Exception ' . pod_code ('DOMException') . '.' .
                            pod_code ('NOT_SUPPORTED_ERR')),
                  pod_para ('Call of this method allways result in
                             this exception raisen, since this
                             method is not implemented yet.');
    $has_return = 1;
  }
  if (@return) {
    if ($has_return) {
      push @desc, pod_para q<This method results in > .
                           ($has_return == 1 ? q<the value:>
                                             : q<either:>);
    } else {
      push @desc, pod_para q<This method does not return value,
                             but it might raise > .
                           ($has_return == 1 ? q<an exception:>
                                             : q<one of exceptions from:>);
    }
    push @desc, pod_list 4, @return;
  } else {
    push @desc, pod_para q<This method results in neither value returned
                           nor exceptions.>;
  }

  if ($node->local_name eq 'IntMethod') {
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

  $result;
} # method2perl

=head2 DataType element

=cut

sub datatype2perl ($) {
  my $node = shift;
  local $Status->{depth} = $Status->{depth} + 1;
  my $pack_name = perl_package_name
                    name => my $if_name
                                 = perl_name $node->get_attribute_value ('Name'),
                                             ucfirst => 1;
  local $Status->{IF} = $if_name;
  my $result = perl_package full_name => $pack_name;
  $result .= perl_statement perl_assign 'our $VERSION', version_date time;
  $result .= perl_statement 'push our @ISA, ' .
                            perl_list perl_package_name (if => $if_name);
  my @level;
  my $mod = get_level_description $node, level => \@level;
  $mod = ', that has been ' . $mod if $mod;
  $result .= pod_block
               pod_head ($Status->{depth}, 'Type ' . pod_code $if_name),
               pod_paras (get_description ($node));

  for (@{$node->child_nodes}) {
    if ($_->local_name eq 'Method' or
        $_->local_name eq 'IntMethod' or
        $_->local_name eq 'ReMethod') {
      $result .= method2perl ($_, level => \@level);
    } elsif ($_->local_name eq 'Attr' or
             $_->local_name eq 'IntAttr' or
             $_->local_name eq 'ReAttr') {
      
    } elsif ($_->local_name eq 'ConstGroup') {
      
    } elsif ($_->local_name eq 'Const') {

    }
  }

  $result;
} # datatype2perl

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
  my $result = '';
  for (@{$node->get_attribute ('Require', make_new_node => 1)->child_nodes}) {
    if ($_->local_name eq 'Module') {
      my $m_name = perl_name $_->get_attribute_value ('Name',
                                                      default => '<anon>'),
                             ucfirst => 1;
      my $desc = get_description $_;
      $result .= perl_comment (($m_name ne '<anon>' ? $m_name : '') .
                               ($desc ? ' - ' . $desc : ''))
        if $desc or $m_name ne '<anon>';
      my $def = get_perl_definition_node $_, name => 'Def';
      if ($def) {
        my $s;
        my $req;
        if ($req = $def->get_attribute ('require')) {
          $s = 'require ' . perl_code $req->value;
        } elsif ($req = $def->get_attribute ('use')) {
          $s = 'use ' . perl_code $req->value;
        } elsif (defined ($s = $def->value)) {
          # 
        } else {
          valid_warn qq<Required module definition for $m_name is empty>;
        }
        if ($req and my $list = $req->get_attribute_value ('Import')) {
          $s .= ' ' . perl_list ref $list ? @$list : $list;
        }
        $result .= perl_statement $s;
      } else {
        $result .= perl_statement 'require ' .
                     perl_code "__CLASS{$m_name}__";
      }
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

register_namespace_declaration ($source);

my $Module = $source->get_attribute ('Module', make_new_node => 1);
$Info->{Name} = perl_name $Module->get_attribute_value ('Name'), ucfirst => 1
  or valid_err q<Module name (/Module/Name) MUST be specified>;
$Info->{Package} = perl_code (get_perl_definition $Module, name => 'Package')
                || perl_package_name name => $Info->{Name};
$Info->{Namespace}->{(DEFAULT_PFX)}
  = $Module->get_attribute_value ('Namespace')
  or valid_err q<Module namespace URI (/Module/Namespace) MUST be specified>;

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
    $isa = [$isa] unless ref $isa;
    if ($name =~ /^DOM(\d+)$/) {
      $isa = ["DOM" . ($1 - 1)] if not @$isa and $1 > 1;
      $defcond = $1 if $1 > $defcond;
    }
    $Info->{Condition}->{$name} = $isa;
  }
  if (keys %{$Info->{Condition}}) {
    $Info->{DefaultCondition} = $Module->get_attribute_value
                                            ('DefaultCondition') ||
                                $defcond ? 'DOM' . $defcond :
                                valid_err q<Module/DefaultCondition required>;
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
  } elsif (not $req->get_element_by (sub {$reqModule->('DOMMain', @_)})) {
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
  } elsif ($node->local_name eq 'Exception') {

  } elsif ($node->local_name eq 'Warning') {
    
  } elsif ($node->local_name eq 'DataType') {
    $result .= datatype2perl $node;
  } elsif ($node->local_name eq 'DataTypeAlias') {
    
  } elsif ($node->local_name eq 'ConstGroup') {

  } elsif ($node->local_name eq 'Const') {

  } elsif ($node->local_name eq 'Module' or $node->local_name eq 'Namespace') {
    #
  } else {
    valid_warn qq{Top-level element type "@{[$node->local_name]}" not supported};
  }
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

# $Date: 2004/08/29 13:34:38 $


