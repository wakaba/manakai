#!/usr/bin/perl -w 
use strict;
use Message::Markup::SuikaWikiConfig20::Parser;
use Message::Util::QName::General [qw/ExpandedURI/], {
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
};

my $s;
{
  local $/ = undef;
  $s = <>;
}
my $source = Message::Markup::SuikaWikiConfig20::Parser->parse_text ($s);
my $Info = {};
my $Status = {package => 'main', depth => 0};
my $result = '';

sub valid_err (@) {
  die @_;
}

sub valid_warn (@) {
  warn @_;
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

sub perl_package_name (%) {
  my %opt = @_;
  $opt{name} = $opt{prefix} . '::' . $opt{name} if $opt{prefix};
  $opt{full_name} || q<Message::Markup::XML::DOM::> . $opt{name};
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
$RegBlockContent = qr/(?>[^{}\\]*)(?>(?>[^{}\\]*|\\.|\{(??{$RegBlockContent})\})*)/s;
sub perl_code ($) {
  my $s = shift;
  $s =~ s{
    \b__([A-Z]+)
    (?:\{($RegBlockContent)\})?
    __\b
  }{
    my ($name, $data) = ($1, $2);
    my $r = defined $data ? "__${name}{$data}__" : "__${name}__";
    if ($name eq 'CLASS') {
      $r = perl_package_name name => $data;
    }
    $r;
  }goex;
  $s;
}
}

sub perl_literal ($) {
  my $s = shift;
  $s =~ s/(['\\])/\\$1/g;
  q<'> . $s . q<'>;
}

sub perl_list (@) {
  join ', ', map perl_literal $_, @_;
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

sub get_perl_definition_node ($%) {
  my ($node, %opt) = @_;
  my $ln = $opt{name} || 'Def';
  my $def = $node->get_element_by (sub {
    my ($me, $you) = @_;
    $you->local_name eq $ln and
    expanded_uri $you->get_attribute_value ('Type')
      eq ExpandedURI q<lang:Perl>;
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
  return q<> unless @$l;
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



sub if2perl ($) {
  my $node = shift;
  local $Status->{depth} = $Status->{depth} + 1;
  my $pack_name = perl_package_name
                    name => my $if_name = $node->get_attribute_value ('Name');
  my $result = perl_package full_name => $pack_name;
  $result .= perl_statement perl_assign 'our $VERSION', version_date time;
  my $mod = get_level_description $node;
  $mod = ', that has been ' . $mod;
  $result .= pod_block
               pod_head ($Status->{depth}, 'Interface ' . $if_name),
               pod_para (pod_code ($pack_name) .
                         q< implements the DOM interface > .
                         pod_code ($if_name) . $mod . q<.>),
               pod_paras (get_description ($node));

  for (@{$node->child_nodes}) {
    if ($_->local_name eq 'Method' or
        $_->local_name eq 'IntMethod' or
        $_->local_name eq 'ReAttr') {
      $result .= method2perl ($_);
    } elsif ($_->local_name eq 'Attr' or
             $_->local_name eq 'IntAttr' or
             $_->local_name eq 'ReAttr') {
      
    } elsif ($_->local_name eq 'ConstGroup') {
      
    } elsif ($_->local_name eq 'Const') {

    }
  }

  $result;
}

sub method2perl ($) {
  my $node = shift;
  local $Status->{depth} = $Status->{depth} + 1;
  my $m_name = $node->get_attribute_value ('Name');
  my $result = '';
  my $level = get_level_description $node;
  
  my @param_list;
  my $param_prototype = '$';
  my @param_desc;
  if ($node->get_attribute ('Param')) {
    for (@{$node->child_nodes}) {
      if ($_->local_name eq 'Param') {
        my $name = $_->get_attribute_value ('Name');
        push @param_list, '$' . $name;
        push @param_desc, pod_item (pod_code '$' . $name),
                          pod_para get_description $_;
        $param_prototype .= '$';
      }
    }
  }
  my $has_return = $node->get_attribute ('Return') ? 1 : 0;
  
  push my @desc,
               pod_head ($Status->{depth}, 'Method ' . 
                         ($has_return ? '$return = ' : '') .
                         '$obj->' . $m_name .
                         ' (' . join (', ', @param_list) . ')'),
               pod_paras (get_description ($node)),
               $level ? pod_para ('Method ' . pod_code ($m_name) .
                           q< has been > . $level) : ();

  if (@param_list) {
    push @desc, pod_para ('This method requires ' . 
                          (@param_list == 1 ?
                                            'one parameter' :
                                            @param_list . ' parameters') . ':'),
                pod_list (4, @param_desc);                           
  } else {
    push @desc, pod_para (q<This method has no parameter.>);
  }

  if ($has_return) {

  } else {
    push @desc, pod_para (q<This method does not return value.>);
  }

  $result .= pod_block @desc;

  $result .= perl_sub name => $m_name,
                      prototype => $param_prototype;

  $result;
}

sub req2perl ($) {
  my $node = shift;
  for (@{$node->get_attribute ('Require', make_new_node => 1)->child_nodes}) {
    if ($_->local_name eq 'Module') {
      my $m_name = $_->get_attribute_value ('Name', default => '<anon>');
      my $def = get_perl_definition_node $_, name => 'Def';
      if ($def) {
        my $s;
        my $req;
        if ($req = $def->get_attribute ('require')) {
          $s = 'require ' . perl_code $req->value;
        } elsif ($req = $def->get_attribute ('use')) {
          $s = 'use ' . perl_code $req->value;
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
}

## Get general information
$Info->{source_filename} = $ARGV;

register_namespace_declaration ($source);

my $Module = $source->get_attribute ('Module', make_new_node => 1);
$Info->{Name} = get_perl_definition $Module, name => 'Package',
                  default => $Module->get_attribute_value ('Name');

## Make source
$result .= perl_comment q<This file is automatically generated from> . "\n" .
                        q<"> . $Info->{source_filename} . q<" at > .
                        rfc3339_date (time) . qq<.\n> .
                        q<Don't edit by hand!>;

$result .= perl_statement q<use strict>;

local $Status->{depth} = $Status->{depth} + 1;
$result .= perl_package name => $Info->{Name};
$result .= perl_statement perl_assign 'our $VERSION' => version_date time;

$result .= pod_block
             pod_head (1, 'NAME'),
             pod_para (perl_package_name (name => $Info->{Name}) .
                       ' - ' . get_description ($Module, name => 'FullName')),
             section (
               opt => pod_head (1, 'DESCRIPTION'),
               req => pod_para (get_description ($Module)),
             ),
             pod_head (1, 'DOM INTERFACES');

$result .= req2perl $Module;

for my $node (@{$source->child_nodes}) {
  if ($node->node_type ne '#element') {
    ##
  } elsif ($node->local_name eq 'IF') {
    $result .= if2perl $node;
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

print $result;
