#!/usr/bin/perl -w
use strict;
use Message::Markup::SuikaWikiConfig20::Node;

my $LastCategory = '';
my $LastComment = '';
my $LastAttr;
my $NAME = qr/[\w:.]+/;
my $Status;
sub err ($);
sub level ($);
sub raises ($$$);

my $tree = Message::Markup::SuikaWikiConfig20::Node->new (type => '#document');
my $etUsed;

sub fws ($) {
  my $s = shift;
  while ($$s =~ m{\G(?=[#\s]|/[/\*])}gc) {
    if ($$s =~ /\G\s+/gc) {
      #
    } elsif ($$s =~ /\G\#(.+)(?:\n|$)/gc) {
      my $l = $1;
      my $m = $tree->get_attribute ('Module');
      if ($l =~ /^include\s+"([^"]+)"/) {
        my $f = $1;
        my $c = $m->get_attribute ('Require', make_new_node => 1)
                  ->append_new_node (type => '#element',
                                     local_name => 'Module');
        $f =~ s/\.idl$//;
        $c->set_attribute (Name => $f);
      } elsif ($l =~ /^pragma\s+prefix\s+"([^"]+)"/) {
        $m->get_element_by (sub {
                              my ($me, $you) = @_;
                              $you->local_name eq 'AppName' and
                              $you->get_attribute_value ('ContentType',
                                                         default => '')
                                eq 'lang:IDL-DOM'
                            }, make_new_node => sub {
                              my ($me, $you) = @_;
                              $you->local_name ('AppName');
                              $you->set_attribute (ContentType =>'lang:IDL-DOM');
                            })
          ->set_attribute (prefix => $1);
      } else {
        $tree->append_new_node (type => '#comment', value => ' #'.$l);
      }
    } elsif ($$s =~ m#\G//\s*(\w+)\s*\n#gc) {
      $LastComment = $LastCategory = $1;
    } elsif ($$s =~ m#\G//(.+\n(?:\s*//.+\n)*)#gc) {
      $LastComment = $1;
      $LastComment =~ s#\n\s*//\s*# #g;
      $LastComment =~ s/^\s+//;
      $LastComment =~ s/\s+$//;
      if ($LastComment =~ /raises\s*(\([^()]+\)|[^()\s]+)\s+on\s+setting/) {
        my ($x, $t) = ($1, $2);
        if ($LastAttr) {
          raises \$x => $LastAttr, 'Set';
        } else {
          warn "Unassociated attribute exception comment found: $LastComment";
        }
      }
      if ($LastComment =~ /raises\s*(\([^()]+\)|[^()\s]+)\s+on\s+retrieval/) {
        my ($x, $t) = ($1, $2);
        if ($LastAttr) {
          raises \$x => $LastAttr, 'Get';
        } else {
          warn "Unassociated attribute exception comment found: $LastComment";
        }
      }
    } elsif ($$s =~ m#\G(/\*(?>(?!\*/).)*\*/)#gcs) {
      $tree->append_new_node (type => '#comment', value => $1);
    } else {
      err $s;
    }
  }
}

sub type ($) {
  my $s = shift;
  $$s =~ /\G($NAME)/gc or return 0;
  my $type = $1;
  if ($type eq 'unsigned' or $type eq 'signed') {
    fws $s;
    $$s =~ /\G($NAME)/gc or err $s;
    $type .= '-' . $1;
    if ($1 eq 'long' and $$s =~ /\G\s+long\b/gc) {
      $type .= '-long';
    }
  }
  if ($type =~ /:/) {
    $type =~ s/::/:/;
    if ($type =~ /^([^:]+):/) {
      register_required_module (Name => $1);
    }
  }
  if ($type !~ /[^a-z-]/ and
      not {qw/attribute 1 readonly 1 in 1 const 1 void 1/}->{$type}) {
    $type = 'DOMMain:' . $type;
  } elsif ({DOMString => 1, Object => 1}->{$type}) {
    unless ($Status->{datatype_defined}->{$type}) {
      $type = 'DOMMain:' . $type;
    }
  }
  return $type;
}

my $CONST = qr/^Constants|Types$|[oe]rs$|Values$|Options$|^Exception/;

sub const ($$) {
  my ($s, $parent) = @_;
  if ($LastCategory or $LastComment =~ /$CONST/) {
    if ($parent->child_nodes->[-1] and
        $parent->child_nodes->[-1]->local_name eq 'ConstGroup' and
       ($parent->child_nodes->[-1]->get_attribute_value ('QName', default => ' ')
          eq $LastCategory or
        $parent->child_nodes->[-1]->get_attribute_value ('FullName',
                                                         default => ' ')
          eq $LastComment)) {
      $parent = $parent->child_nodes->[-1];
    } elsif ($parent->child_nodes->[-1] and
             $parent->child_nodes->[-1]->local_name eq 'Exception') {
      $parent = $parent->child_nodes->[-1];
      if ($parent->child_nodes->[-1] and
          $parent->child_nodes->[-1]->local_name eq 'ConstGroup' and
         ($parent->child_nodes->[-1]->get_attribute_value ('QName',
                                                           default => ' ')
            eq $LastCategory or
          $parent->child_nodes->[-1]->get_attribute_value ('FullName',
                                                           default => ' ')
            eq $LastComment)) {
        $parent = $parent->child_nodes->[-1];
      } else {
        $parent = $parent->append_new_node (type => '#element',
                                            local_name => 'ConstGroup');
        if ($LastCategory) {
          $parent->append_new_node (type => '#element', local_name => 'QName',
                                    value => $LastCategory)
                 ->set_attribute (ForCheck => q<ManakaiDOM:ForIF>);
          $parent->append_new_node (type => '#element', local_name => 'QName',
                                    value => "** $LastCategory")
                 ->set_attribute (ForCheck => q<ManakaiDOM:ForClass>);
        } else {
          $parent->set_attribute (FullName => $LastComment)
                 ->set_attribute (lang => 'en');
        }
      }
    } else {
      $parent = $parent->append_new_node (type => '#element',
                                          local_name => 'ConstGroup');
      if ($LastCategory) {
        $parent->append_new_node (type => '#element', local_name => 'QName',
                                  value => $LastCategory)
               ->set_attribute (ForCheck => q<ManakaiDOM:ForIF>);
        $parent->append_new_node (type => '#element', local_name => 'QName',
                                  value => "** $LastCategory")
               ->set_attribute (ForCheck => q<ManakaiDOM:ForClass>);
      } else {
        $parent->set_attribute (FullName => $LastComment)
               ->set_attribute (lang => 'en');
      }
    }
  }

  fws $s;
  my $type = type $s or err $s;
  fws $s;
  if ($parent->node_type eq '#element' and
      $parent->local_name eq 'ConstGroup' and
      not $parent->get_attribute ('Type')) {
    $parent->set_attribute (Type => $type);
    $parent->set_attribute (ISA => $type)
           ->set_attribute (ForCheck => q<ManakaiDOM:ForClass>);
  }
  
  my $const = $parent->append_new_node (type => '#element',
                                        local_name => 'Const');
    $$s =~ /\G($NAME)/gc or err $s;
    $const->set_attribute (Name => $1);
    $const->set_attribute (Type => $type);
    fws $s;
    $$s =~ /\G=/gc or err $s;
    fws $s;
    $$s =~ /\G([^\s;]+)/gc or err $s;
    $const->set_attribute (Value => $1);
  level $const;
}

sub idlname2name ($) {
  my $s = shift;
  $s =~ s/^_//;
  $s;
}

sub semicolon ($) {
  my $s = shift;
  $$s =~ /\G;/gc or return 0;
  $LastComment = '' unless $LastComment =~ /$CONST/;
  return 1;
}

sub clear_comment () {
  $LastComment = '';
  $LastCategory = '';
}

sub level ($) {
  my $n = shift;
  if ($LastComment =~ /Introduced in DOM Level (\d+)/) {
    my $l = $1;
    my $p = $n->get_attribute_value ('Level', default => [], as_array => 1);
    $n->set_attribute (Level => [@$p, $l]);
    $n->set_attribute (For => q<ManakaiDOM:DOM>.$l);
  } elsif ($LastComment =~ /Modified in DOM Level (\d+)/) {
    my $l = $1;
    my $p = $n->get_attribute_value ('Level', default => [':: TBD ::'],
                                     as_array => 1);
    $n->set_attribute (Level => [@$p, $l]);
  }
}

sub raises ($$$) {
  my ($s, $n, $nm) = @_;
  $$s =~ /\G\(/gc;
  fws $s;
  my $p = $n->get_attribute ($nm, make_new_node => 1);
  while ($$s =~ /\G($NAME)/gc) {
    my $name = $1;
    $name =~ s/::/:/g;
    $name = 'DOMMain:'.$name if $name eq 'DOMException' and
                                not $Status->{datatype_defined}->{$name};
    if ($name =~ /^([^:]+):/) {
      register_required_module (Name => $1);
    }
    for my $except ($p->append_new_node (type => '#element',
                                         local_name => 'Exception')) {
      $except->set_attribute (Name => '** TBD **');
      $except->set_attribute (Type => $name);
    }
    fws $s;
    $$s =~ /\G,/gc;
    fws $s;
  }
  $$s =~ /\G\)/gc;
  return 1;
}

sub err ($) {
  use Carp;
  my $s = shift;
  print $tree->stringify;
  Carp::croak "Invalid input (either input is broken or struct not implemented found): ",
      substr $$s, pos $$s, 100;
}

sub register_required_module (%) {
  my %opt = @_;
  my $mod = $tree->get_attribute ('Module')
           ->get_attribute ('Require', make_new_node => 1)
           ->get_element_by (sub {
               my ($me, $you) = @_;
               $you->local_name eq 'Module' and
               $you->get_attribute_value ('Name', default => '') eq $opt{Name};
             }, make_new_node => sub {
               my ($me, $you) = @_;
               $you->local_name ('Module');
               $you->set_attribute (Name => $opt{Name});
             });
}

sub supply_incase ($$) {
  my ($type, $node) = @_;
  if ($type eq 'DOMMain:boolean') {
    for my $b ('true', 'false') {
      for ($node->append_new_node (type => '#element',
                                   local_name => 'InCase')) {
        $_->set_attribute (Value => $b);
      }
    }
    $etUsed->{InCase} = 1;
  }
} # supply_incase

my $s;
{
local $/ = undef;
$s = \(<> or die "$0: $ARGV: $!");
}

pos $$s = 0;

## -- Module attribute
for my $module ($tree->append_new_node (type => '#element',
                                        local_name => 'Module')) {
  $module->set_attribute (QName => q<:: TBD:TBD ::>);
  for ($module->set_attribute (AppName => q<** TBD **>)) {
    $_->set_attribute (ContentType => q<lang:IDL-DOM>);
    $_->set_attribute (For => q<ManakaiDOM:IDL>);
  }
  for ($module->set_attribute (FullName => q<:: TBD Module ::>)) {
    $_->set_attribute (lang => q<en>);
  }
  $module->set_attribute (Namespace => q<:: TBD ::>);

  $module->set_attribute (Description => q<This module is :::>)
         ->set_attribute (lang => q<en>);

  for ($module->set_attribute (Author => undef)) {
    $_->set_attribute (FullName => q<** TBD **>);
    $_->set_attribute (Mail => q<** TBD@TBD **>);
  }
  $module->set_attribute (License => q<license:Perl+MPL>);
  $module->set_attribute (Date => q<$Date: 2005/01/05 12:19:38 $>)
         ->set_attribute (ContentType => 'dis:Date.RCS');

  $module->set_attribute (DefaultFor => q<ManakaiDOM:ManakaiDOMLatest>);
  
  for ($module->set_attribute (Require => undef)) {
    $_->append_new_node (type => '#element',
                         local_name => 'Module')
      ->set_attribute (Name => 'DOMCore');
    for ($_->append_new_node (type => '#element',
                              local_name => 'Module')) {
      $_->set_attribute (Name => '** MYSELF **');
      $_->set_attribute (WithFor => q<ManakaiDOM:ManakaiDOM>);
    }
    for ($_->append_new_node (type => '#element',
                              local_name => 'Module')) {
      $_->set_attribute (Name => '** MYSELF **');
      $_->set_attribute (WithFor => q<ManakaiDOM:ManakaiDOM1>);
    }
    for ($_->append_new_node (type => '#element',
                              local_name => 'Module')) {
      $_->set_attribute (Name => '** MYSELF **');
      $_->set_attribute (WithFor => q<ManakaiDOM:ManakaiDOM2>);
    }
    for ($_->append_new_node (type => '#element',
                              local_name => 'Module')) {
      $_->set_attribute (Name => '** MYSELF **');
      $_->set_attribute (WithFor => q<ManakaiDOM:ManakaiDOM3>);
    }
    for ($_->append_new_node (type => '#element',
                              local_name => 'Module')) {
      $_->set_attribute (Name => '** MYSELF **');
      $_->set_attribute (WithFor => q<ManakaiDOM:ManakaiDOMLatest>);
    }
  }
}

## -- Namespace attribute
for my $ns ($tree->get_attribute ('Namespace', make_new_node => 1)) {
  for (
       [dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->],
       [DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>],
       [infoset => q<http://www.w3.org/2001/04/infoset#>],
       [lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>],
       [license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>],
       [ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>],
       [MDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.>],
       [MDOMX => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>],
       [Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->],
       [rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>],
       [rdfs => q<http://www.w3.org/2000/01/rdf-schema#>],
       [TreeCore => q<>],
      ) {
    $ns->set_attribute ($_->[0] => $_->[1]);
  }
}


fws $s;
if ($$s =~ /\Gpragma\s+prefix\s+"([^"]+)"\s*/gc) {
  for ($tree->get_attribute ('Module')
            ->get_element_by (sub {
           my ($me, $you) = @_;
           $you->local_name eq 'AppName' and
           $you->get_attribute_value ('ContentType', default => '') eq
             'lang:IDL-DOM';
         }, make_new_node => sub {
           my ($me, $you) = @_;
           $you->local_name ('AppName');
           $you->set_attribute (ContentType => 'lang:IDL-DOM');
           $you->set_attribute (For => 'ManakaiDOM:IDL');
         })) {
    $_->set_attribute (prefix => $1);
  }
}
if ($$s =~ /\Gmodule\b/gc) {
  fws $s;
  $$s =~ /\G($NAME)/gc or err $s;
  for ($tree->get_attribute ('Module')) {
    $_->get_element_by (sub {
           my ($me, $you) = @_;
           $you->local_name eq 'AppName' and
           $you->get_attribute_value ('ContentType', default => '') eq
             'lang:IDL-DOM';
         }, make_new_node => sub {
           my ($me, $you) = @_;
           $you->local_name ('AppName');
           $you->set_attribute (ContentType => 'lang:IDL-DOM');
           $you->set_attribute (For => 'ManakaiDOM:IDL');
         })->inner_text (new_value => $1);
    $_->set_attribute (Name => $1);
  }
  fws $s;
  $$s =~ /\G\{/gc;
  fws $s;
}


while (pos $$s < length $$s) {
  my $r = $tree;
  if ($$s =~ /\Ginterface\b/gc) {
    fws $s;
    $$s =~ /\G($NAME)/gc or err $s;
    my $name = $1;
    my @isa;
    fws $s;
    if ($$s =~ /\G:/gc) {
      fws $s;
      while ($$s =~ /\G($NAME)/gc) {
        my $name = $1;
        $name =~ s/::/:/g;
        if ($name =~ /^([^:]+):/) {
          register_required_module (Name => $1);
        }
        push @isa, $name;
        fws $s;
        $$s =~ /\G,/gc or last;
        fws $s;
      }
    }
    if ($$s =~ /\G\{/gc) {
      my $if = $r->append_new_node (type => '#element', local_name => 'IF');
      $etUsed->{IF} = 1;
      $if->append_new_node (type => '#element', local_name => 'QName',
                            value => $name)
         ->set_attribute (ForCheck => q<ManakaiDOM:ForIF>);
      for (@isa) {
        $if->append_new_node (type => '#element',
                              local_name => 'ISA',
                              value => $_)
           ->set_attribute (ForCheck => q<ManakaiDOM:ForIF>);
      }
      $if->append_new_node (type => '#element', local_name => 'QName',
                            value => "** $name")
         ->set_attribute (ForCheck => q<ManakaiDOM:ForClass>);
      for (@isa) {
        $if->append_new_node (type => '#element',
                              local_name => 'ISA',
                              value => ":: $_")
           ->set_attribute (ForCheck => q<ManakaiDOM:ForClass>);
      }
      level $if;
      clear_comment;
      fws $s;
      while (my $type = type $s) {
        fws $s;
        if ($type eq 'attribute' or $type eq 'readonly') {
          my $attr = $LastAttr = $if->append_new_node (type => '#element',
                                                       local_name => 'Attr');
          $etUsed->{Attr} = 1;
          my $readonly;
          if ($type eq 'readonly') {
            $$s =~ /\Gattribute\b/gc or err $s;
            fws $s;
            $readonly = 1;
          }
          $type = type $s or err $s;
          fws $s;
          $$s =~ /\G($NAME)/gc or err $s;
          $attr->set_attribute (Name => idlname2name $1);
          fws $s;
          $attr->get_attribute ('Get', make_new_node => 1)
               ->set_attribute (Type => $type);
          $attr->get_attribute ('Set', make_new_node => 1)
               ->set_attribute (Type => $type) unless $readonly;
          supply_incase ($type => $attr->get_attribute ('Get'));
          supply_incase ($type => $attr->get_attribute ('Set'))
              unless $readonly;
          level $attr;
        } elsif ($type eq 'const') {
          const $s => $if;
          fws $s;
        } else {
          my $method = $if->append_new_node (type => '#element',
                                             local_name => 'Method');
          $etUsed->{Method} = 1;
          if ($$s =~ /\G($NAME)/gc) {
            $method->set_attribute (Name => idlname2name $1);
          } else {
            $method->set_attribute (Name => idlname2name $type);
            undef $type;
          }
          fws $s;
          $$s =~ /\G\(/gc or err $s;
          {
            fws $s;
            my $type = type $s or last;
            fws $s;
            my $in;
            my $out;
            if ($type eq 'in') {
              $in = 1;
              $type = type $s or err $s;
              fws $s;
            } elsif ($type eq 'out') {
              $out = 1;
              $type = type $s or err $s;
              fws $s;
            } elsif ($type eq 'inout') {
              $in = 1; $out = 1;
              $type = type $s or err $s;
              fws $s;
            }
            my $p = $method->append_new_node (type => '#element',
                                              local_name => 'Param');
            $$s =~ /\G($NAME)/gc or err $s;
            $p->set_attribute (Name => idlname2name $1);
            $p->set_attribute (Type => $type);
            $p->set_attribute (Write => 0) unless $in; 
            $p->set_attribute (Read => 1) if $out;
            supply_incase ($type => $p);
            fws $s;
            $$s =~ /\G,/gc or last;
            redo;
          }
          $$s =~ /\G\)/gc or err $s;
          fws $s;
           
          my $return = $method->get_attribute ('Return', make_new_node => 1);
          if ($type and $type ne 'void') {
            $return->set_attribute (Type => $type);
            supply_incase ($type => $return);
          }
          if ($$s =~ /\Graises\b/gc) {
            raises $s => $method, 'Return' or err $s;
            fws $s;
          }
          level $method;
        } # attr or method
        semicolon $s or err $s;
        fws $s;
      }
      $$s =~ /\G\}/gc or err $s;
    } # definition
    fws $s;
  } elsif ($$s =~ /\Gconst\b/gc) {
    const $s => $r;
    fws $s;
  } elsif ($$s =~ /\Gexception\b/gc) {
    my $except = $r->append_new_node (type => '#element',
                                      local_name => 'ExceptionDef');
    $etUsed->{ExceptionDef} = 1;
    fws $s;
    $$s =~ /\G($NAME)/gc or err $s;
    $except->append_new_node (type => '#element', local_name => 'QName',
                              value => $1)
           ->set_attribute (For => q<ManakaiDOM:ForIF>);
    $except->append_new_node (type => '#element', local_name => 'QName',
                              value => "** $1")
           ->set_attribute (For => q<ManakaiDOM:ForClass>);
    level $except;
    fws $s;
    $$s =~ /\G\{/gc or err $s;
    clear_comment;
    fws $s;
    while (my $type = type $s) {
      fws $s;
      my $attr = $except->append_new_node
                             (type => '#element', local_name => 'Attr');
      $etUsed->{Attr} = 1;
      $$s =~ /\G($NAME)/gc or err $s;
      $attr->set_attribute (Name => idlname2name $1);
      $attr->get_attribute ('Get', make_new_node => 1)
           ->set_attribute (Type => $type);
      $etUsed->{Get} = 1;
      fws $s;
      semicolon $s or err $s;
      fws $s;
    }
    $$s =~ /\G\}/gc or err $s;
    fws $s;
  } elsif ($$s =~ /\Gvaluetype\b/gc) {
    fws $s;
    my $valtype = $r->append_new_node (type => '#element',
                                       local_name => 'DataTypeDef');
    $etUsed->{DataTypeDef} = 1;
    my $type = type $s or err $s;
    $valtype->set_attribute (QName => $type);
    fws $s;
    $$s =~ /\G([^;]+)/gc or err $s;
    $valtype->set_attribute (Def => $1)
            ->set_attribute (ContentType => q<lang:IDL-DOM>);
    fws $s;
  } elsif ($$s =~ /\Gtypedef\b/gc) {
    fws $s;
    my $type = type $s or err $s;
    fws $s;
    my $valtype = $r->append_new_node (type => '#element', 
                                       local_name => 'DataTypeDef');
    $etUsed->{DataTypeDef} = 1;
    my $name = $$s =~ /\G($NAME)/gc ? $1 : err $s;
    $valtype->set_attribute (QName => $name);
    $valtype->set_attribute (AliasFor => $type)
            ->set_attribute (For => q<!ManakaiDOM:IDL>);
    for ($valtype->set_attribute (Def => undef)) {
      $_->set_attribute ('DISLang:dataTypeAliasFor' => $type);
      $_->set_attribute (For => q<ManakaiDOM:IDL>);
    }
    $Status->{datatype_defined}->{$name} = 1;
    fws $s;
  } else {
    last;
  }
  semicolon $s ;#or err $s;
  fws $s;
}

$$s =~ /\G\}/gc; # module name {...}
fws $s;
semicolon $s;
fws $s;

$$s =~ /\G./gc and err $s;

if ($etUsed->{IF}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'IF');
  $etb->set_attribute (ElementType => 'dis:ResourceDef');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->append_new_node (type => '#element',
                        local_name => 'rdf:type',
                        value => q<dis:MultipleResource>)
     ->set_attribute (ForCheck => q<!ManakaiDOM:ForIF !ManakaiDOM:ForClass>);
  $sc->set_attribute (ForCheck => q<ManakaiDOM:DOM>);
  
  $sc->append_new_node (type => '#element',
                        local_name => 'resourceFor',
                        value => q<ManakaiDOM:ForIF>);
  $sc->append_new_node (type => '#element',
                        local_name => 'rdf:type',
                        value => 'ManakaiDOM:IF')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForIF');
  $sc->append_new_node (type => '#element',
                        local_name => 'ISA',
                        value => '::ManakaiDOM:ManakaiDOM')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForIF ManakaiDOM:ManakaiDOM '.
                                  '!=ManakaiDOM:ManakaiDOM');
  
  $sc->append_new_node (type => '#element',
                        local_name => 'resourceFor',
                        value => q<ManakaiDOM:ForClass>)
     ->set_attribute (FprCheck => q<ManakaiDOM:ManakaiDOM >.
                                  q<!=ManakaiDOM:ManakaiDOM>);
  $sc->append_new_node (type => '#element',
                        local_name => 'rdf:type',
                        value => 'ManakaiDOM:Class')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForClass');
  $sc->append_new_node (type => '#element',
                        local_name => 'ISA',
                        value => 'ManakaiDOM:ManakaiDOMObject')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForIF ManakaiDOM:ManakaiDOM '.
                                  '!=ManakaiDOM:ManakaiDOM');
}

if ($etUsed->{ExceptionDef}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'ExceptionDef');
  $etb->set_attribute (ElementType => 'dis:ResourceDef');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->append_new_node (type => '#element',
                        local_name => 'rdf:type',
                        value => q<dis:MultipleResource>)
     ->set_attribute (ForCheck => q<!ManakaiDOM:ForIF !ManakaiDOM:ForClass>);
  $sc->set_attribute (ForCheck => q<ManakaiDOM:DOM>);
  
  $sc->append_new_node (type => '#element',
                        local_name => 'resourceFor',
                        value => q<ManakaiDOM:ForIF>);
  $sc->append_new_node (type => '#element',
                        local_name => 'rdf:type',
                        value => 'ManakaiDOM:ExceptionIF')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForIF');
  $sc->append_new_node (type => '#element',
                        local_name => 'ISA',
                        value => '::ManakaiDOM:ManakaiDOM')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForIF ManakaiDOM:ManakaiDOM '.
                                  '!=ManakaiDOM:ManakaiDOM');
  
  $sc->append_new_node (type => '#element',
                        local_name => 'resourceFor',
                        value => q<ManakaiDOM:ForClass>)
     ->set_attribute (FprCheck => q<ManakaiDOM:ManakaiDOM >.
                                  q<!=ManakaiDOM:ManakaiDOM>);
  $sc->append_new_node (type => '#element',
                        local_name => 'rdf:type',
                        value => 'ManakaiDOM:ExceptionClass')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForClass');
  $sc->append_new_node (type => '#element',
                        local_name => 'ISA',
                        value => 'ManakaiDOM:ManakaiDOMException')
     ->set_attribute (ForCheck => 'ManakaiDOM:ForIF ManakaiDOM:ManakaiDOM '.
                                  '!=ManakaiDOM:ManakaiDOM');
}

if ($etUsed->{Method}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'Method');
  $etb->set_attribute (ElementType => 'dis:ResourceDef');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->set_attribute ('rdf:type' => q<ManakaiDOM:DOMMethod>);
  $sc->set_attribute (ForCheck => q<ManakaiDOM:DOM !=ManakaiDOM:ManakaiDOM>);

  {
    my $etb = $tree->append_new_node (type => '#element',
                                      local_name => 'ElementTypeBinding');
    $etb->set_attribute (Name => 'Param');
    $etb->set_attribute (ElementType => 'dis:ResourceDef');
    my $sc = $etb->set_attribute (ShadowContent => undef);
    $sc->set_attribute ('rdf:type' => q<ManakaiDOM:DOMMethodParameter>);
  }

  {
    my $etb = $tree->append_new_node (type => '#element',
                                      local_name => 'ElementTypeBinding');
    $etb->set_attribute (Name => 'Return');
    $etb->set_attribute (ElementType => 'dis:ResourceDef');
    my $sc = $etb->set_attribute (ShadowContent => undef);
    $sc->set_attribute ('rdf:type' => q<ManakaiDOM:DOMMethodReturn>);
  }
}

if ($etUsed->{Attr}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'Attr');
  $etb->set_attribute (ElementType => 'dis:ResourceDef');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->set_attribute ('rdf:type' => q<ManakaiDOM:DOMAttribute>);
  $sc->set_attribute (ForCheck => q<ManakaiDOM:DOM !=ManakaiDOM:ManakaiDOM>);

  {
    my $etb = $tree->append_new_node (type => '#element',
                                      local_name => 'ElementTypeBinding');
    $etb->set_attribute (Name => 'Get');
    $etb->set_attribute (ElementType => 'dis:ResourceDef');
    my $sc = $etb->set_attribute (ShadowContent => undef);
    $sc->set_attribute ('rdf:type' => q<ManakaiDOM:DOMAttrGet>);
  }

  {
    my $etb = $tree->append_new_node (type => '#element',
                                      local_name => 'ElementTypeBinding');
    $etb->set_attribute (Name => 'Set');
    $etb->set_attribute (ElementType => 'dis:ResourceDef');
    my $sc = $etb->set_attribute (ShadowContent => undef);
    $sc->set_attribute ('rdf:type' => q<ManakaiDOM:DOMAttrSet>);
  }
}

if ($etUsed->{Exception}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'Exception');
  $etb->set_attribute (ElementType => 'ManakaiDOM:raises');
}

if ($etUsed->{Exception} or $etUsed->{ConstGroup}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'ConstGroup');
  $etb->set_attribute (ElementType => 'dis:ResourceDef');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->set_attribute ('rdf:type' => q<ManakaiDOM:ConstGroup>);
  $sc->set_attribute (ForCheck => q<ManakaiDOM:DOM !=ManakaiDOM:ManakaiDOM>);
  $etb->clone->set_attribute (Name => 'XConstGroup')
    if $etUsed->{Exception};

  {
    my $etb = $tree->append_new_node (type => '#element',
                                      local_name => 'ElementTypeBinding');
    $etb->set_attribute (Name => 'Const');
    $etb->set_attribute (ElementType => 'dis:ResourceDef');
    my $sc = $etb->set_attribute (ShadowContent => undef);
    $sc->set_attribute ('rdf:type' => q<ManakaiDOM:Const>);
  }

  {
    my $etb = $tree->append_new_node (type => '#element',
                                      local_name => 'ElementTypeBinding');
    $etb->set_attribute (Name => 'XParam');
    $etb->set_attribute (ElementType =>
                           'ManakaiDOM:exceptionOrWarningParameter');
    my $sc = $etb->set_attribute (ShadowContent => undef);
    $sc->set_attribute (ForCheck => q<ManakaiDOM:ManakaiDOM>);
  }
}

{
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'PerlDef');
  $etb->set_attribute (ElementType => 'dis:Def');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->set_attribute (ContentType => q<lang:Perl>);
}

if ($etUsed->{InCase}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'InCase');
  $etb->set_attribute (ElementType => 'dis:ResourceDef');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->set_attribute ('rdf:type' => q<ManakaiDOM:InCase>);
}

if ($etUsed->{DataTypeDef}) {
  my $etb = $tree->append_new_node (type => '#element',
                                    local_name => 'ElementTypeBinding');
  $etb->set_attribute (Name => 'DataTypeDef');
  $etb->set_attribute (ElementType => 'dis:ResourceDef');
  my $sc = $etb->set_attribute (ShadowContent => undef);
  $sc->set_attribute ('rdf:type' => q<ManakaiDOM:DataType>);
}

print $tree->stringify;
