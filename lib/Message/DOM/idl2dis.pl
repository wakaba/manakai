#!/usr/bin/perl -w
use strict;
use Message::Markup::SuikaWikiConfig20::Node;

my $LastCategory = '';
my $LastComment = '';
my $LastAttr;
my $NAME = qr/[\w:]+/;
sub err ($);
sub level ($);
sub raises ($$$);

my $tree = Message::Markup::SuikaWikiConfig20::Node->new (type => '#document');

sub fws ($) {
  my $s = shift;
  while ($$s =~ m{\G(?=[#\s]|//)}gc) {
    if ($$s =~ /\G\s+/gc) {
      #
    } elsif ($$s =~ /\G\#(.+)(?:\n|$)/gc) {
      my $l = $1;
      my $m = $tree->get_attribute ('Module');
      if ($l =~ /^include\s+"([^"]+)"/) {
        my $f = $1; $f =~ s/\.idl$//;
        my $c = $m->get_attribute ('Require', make_new_node => 1)
                  ->append_new_node (type => '#element',
                                     local_name => 'Module');
        $c->set_attribute ('Name' => $f);
      } elsif ($l =~ /^pragma\s+prefix\s+"([^"]+)"/) {
        $m->get_attribute ('Name', make_new_node => 1)
          ->set_attribute (Prefix => $1);
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
  }
  return $type;
}

my $CONST = qr/^Constants|Types$|[oe]rs$|Values$|Options$/;

sub const ($$) {
  my ($s, $parent) = @_;
  if ($LastCategory or $LastComment =~ /$CONST/) {
    if ($parent->child_nodes->[-1] and
        $parent->child_nodes->[-1]->local_name eq 'ConstGroup' and
       ($parent->child_nodes->[-1]->get_attribute_value ('Name', default => ' ')
          eq $LastCategory or
        $parent->child_nodes->[-1]->get_attribute_value ('Description', default => ' ')
          eq $LastComment)) {
      $parent = $parent->child_nodes->[-1];
    } elsif ($parent->child_nodes->[-1] and
             $parent->child_nodes->[-1]->local_name eq 'Exception') {
      $parent = $parent->child_nodes->[-1];
      if ($parent->child_nodes->[-1] and
          $parent->child_nodes->[-1]->local_name eq 'ConstGroup' and
         ($parent->child_nodes->[-1]->get_attribute_value ('Name', default => ' ')
            eq $LastCategory or
          $parent->child_nodes->[-1]->get_attribute_value ('Description', default => ' ')
            eq $LastComment)) {
        $parent = $parent->child_nodes->[-1];
      } else {
        $parent = $parent->append_new_node (type => '#element', local_name => 'ConstGroup');
        if ($LastCategory) {
          $parent->set_attribute (Name => $LastCategory);
        } else {
          $parent->set_attribute (Description => $LastComment)
                 ->set_attribute (lang => 'en');
        }
      }
    } else {
      $parent = $parent->append_new_node (type => '#element', local_name => 'ConstGroup');
      if ($LastCategory) {
        $parent->set_attribute (Name => $LastCategory);
      } else {
        $parent->set_attribute (Description => $LastComment)
               ->set_attribute (lang => 'en');
      }
    }
  }
    my $const = $parent->append_new_node (type => '#element', local_name => 'Const');
    fws $s;
    my $type = type $s or err $s;
    fws $s;
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
    $n->set_attribute (SpecLevel => [@$p, $l]);
  } elsif ($LastComment =~ /Modified in DOM Level (\d+)/) {
    my $l = $1;
    my $p = $n->get_attribute_value ('Level', default => [':: TBD ::'],
                                     as_array => 1);
    $n->set_attribute (Level => [@$p, $l]);
    $n->set_attribute (SpecLevel => [@$p, $l]);
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
    if ($name =~ /^([^:]+):/) {
      register_required_module (Name => $1);
    }
    $p->append_new_node (type => '#element',
                         local_name => 'Exception')
      ->set_attribute (Type => $name);
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
  $mod->set_attribute (Namespace => $opt{Namespace} || q<:: TBD ::>);
  if ($opt{PerlRequire}) {
    unless ($mod->get_element_by (sub {
               my ($me, $you) = @_;
               $you->local_name eq 'Def' and
               $you->get_attribute_value ('Type', default => '') eq q<lang:Perl>;
             })) {
      for ($mod->append_new_node (type => '#element', local_name => 'Def')) {
        $_->set_attribute (Type => q<lang:Perl>);
        $_->set_attribute (require => $opt{PerlRequire});
      }
    }
  }
}

my $s;
{
local $/ = undef;
$s = \<>;
}

pos $$s = 0;

for my $ns ($tree->get_attribute ('Namespace', make_new_node => 1)) {
  $ns->set_attribute (lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>);
  $ns->set_attribute (license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>);
}

for my $module ($tree->append_new_node (type => '#element',
                                        local_name => 'Module')) {
  $module->set_attribute (Name => q<## TBD ##>);
  $module->set_attribute (Namespace => q<:: TBD ::>);
  $module->set_attribute (License => q<license:Perl>);
  $module->set_attribute ('Date.RCS' => q<$Date: 2004/09/17 07:44:11 $>);
}

fws $s;
if ($$s =~ /\Gmodule\b/gc) {
  fws $s;
  $$s =~ /\G($NAME)/gc or err $s;
  $tree->get_attribute ('Module')->set_attribute (Name => $1);
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
      $if->set_attribute (Name => $name);
      for (@isa) {
        $if->append_new_node (type => '#element',
                              local_name => 'ISA',
                              value => $_);
      }
      level $if;
      clear_comment;
      fws $s;
      while (my $type = type $s) {
        fws $s;
        if ($type eq 'attribute' or $type eq 'readonly') {
          my $attr = $LastAttr = $if->append_new_node (type => '#element', local_name => 'Attr');
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
          level $attr;
        } elsif ($type eq 'const') {
          const $s => $if;
          fws $s;
        } else {
          my $method = $if->append_new_node (type => '#element', local_name => 'Method');
          if ($$s =~ /\G($NAME)/gc) {
            $method->set_attribute (Name => idlname2name $1);
            unless ($type eq 'void') {
              $method->get_attribute ('Return', make_new_node => 1)
                     ->set_attribute (Type => $type);
            }
          } else {
            $method->set_attribute (Name => idlname2name $type);
          }
          fws $s;
          $$s =~ /\G\(/gc or err $s;
          {
            fws $s;
            my $type = type $s or last;
            fws $s;
            my $in;
            if ($type eq 'in') {
              $in = 1;
              $type = type $s or err $s;
              fws $s;
            }
            my $p = $method->append_new_node (type => '#element', local_name => 'Param');
            $$s =~ /\G($NAME)/gc or err $s;
            $p->set_attribute (Name => idlname2name $1);
            $p->set_attribute (Type => $type);
            $p->set_attribute (Write => 0) unless $in;
            fws $s;
            $$s =~ /\G,/gc or last;
            redo;
          }
          $$s =~ /\G\)/gc or err $s;
          fws $s;
          
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
    my $except = $r->append_new_node (type => '#element', local_name => 'Exception');
    fws $s;
    $$s =~ /\G($NAME)/gc or err $s;
    $except->set_attribute (Name => $1);
    level $except;
    fws $s;
    $$s =~ /\G\{/gc or err $s;
    clear_comment;
    fws $s;
    while (my $type = type $s) {
      fws $s;
      my $attr = $except->append_new_node (type => '#element', local_name => 'Attr');
      $$s =~ /\G($NAME)/gc or err $s;
      $attr->set_attribute (Name => idlname2name $1);
      $attr->get_attribute ('Get', make_new_node => 1)
           ->set_attribute (Type => $type);
      fws $s;
      semicolon $s or err $s;
      fws $s;
    }
    $$s =~ /\G\}/gc or err $s;
    fws $s;
  } elsif ($$s =~ /\Gvaluetype\b/gc) {
    fws $s;
    my $valtype = $r->append_new_node (type => '#element',
                                       local_name => 'DataType');
    my $type = type $s or err $s;
    $valtype->set_attribute (Name => $type);
    fws $s;
    $$s =~ /\G([^;]+)/gc or err $s;
    $valtype->set_attribute (Def => $1)
            ->set_attribute (Type => q<lang:IDL-DOM>);
    fws $s;
  } elsif ($$s =~ /\Gtypedef\b/gc) {
    fws $s;
    my $type = type $s or err $s;
    fws $s;
    my $valtype = $r->append_new_node (type => '#element', 
                                       local_name => 'DataTypeAlias');
    my $name = type $s or err $s;
    $valtype->set_attribute (Name => $name);
    $valtype->set_attribute (Type => $type);
    fws $s;
  } else {
    last;
  }
  semicolon $s or err $s;
  fws $s;
}

$$s =~ /\G\}/gc; # module name {...}
fws $s;
semicolon $s;
fws $s;

$$s =~ /\G./gc and err $s;

print $tree->stringify;
