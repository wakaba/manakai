#!/usr/bin/perl -w 
use lib q<../lib>;
use strict;
BEGIN { require 'manakai/genlib.pl' }

use Message::Util::QName::General [qw/ExpandedURI/], {
  ManakaiDOMLS2003
    => q<http://suika.fam.cx/~wakaba/archive/2004/9/27/mdom-old-ls#>,
};
use Message::DOM::ManakaiDOMLS2003;
use Message::DOM::DOMLS qw/MODE_SYNCHRONOUS/;
use Getopt::Long;

require 'dommemlist.pl.tmp'; ## Generated by mkdommemlist.pl

my $output_filename;
my $output_file;
GetOptions (
  'output-file=s' => \$output_filename,
);
if (defined $output_filename) {
  open $output_file, '>', $output_filename or die "$0: $output_filename: $!";
} else {
  $output_file = \*STDOUT;
}

our $Method;
our $IFMethod;
our $Attr;
my $Assert = {
  qw/assertDOMException 1
     assertEquals 1
     assertFalse 1
     assertInstanceOf 1
     assertNotNull 1
     assertNull 1
     assertSame 1
     assertSize 1
     assertTrue 1
     assertURIEquals 1/
};
my $Misc = {
  qw/append 1
     assign 1
     decrement 1
     fail 1
     if 1
     implementationAttribute 1
     increment 1
     for 1
     plus 1
     var 1
     while 1/
};
my $Condition = {
  qw/condition 1
     contains 1
     contentType 1
     equals 1
     greater 1
     greaterOrEquals 1
     hasSize 1
     implementationAttribute 1
     instanceOf 1
     isNull 1
     less 1
     lessOrEquals 1
     not 1
     notEquals 1
     notNull 1
     or 1/
};

my $Status = {Number => 0, our => {Info => 1}};

## Defined in genlib.pl but redefined.
sub output_result ($) {
  print $output_file shift;
}

sub to_perl_value ($;%) {
  my ($s, %opt) = @_;
  if (defined $s) {
    if ($s =~ /^(?!\d)\w+$/) {
      if ({true => 1, false => 1}->{$s}) {
        return {true => '1', false => '0'}->{$s};
      } else {
        return perl_var (type => '$', local_name => $s);
      }
    } else {
      return $s;
    }
  } elsif (defined $opt{default}) {
    return $opt{default};
  } else {
    return '';
  }
}

sub body2code ($) {
  my $parent = shift;
  my $result = '';
  my $children = $parent->childNodes;
  for (my $i = 0; $i < $children->length; $i++) {
    my $child = $children->item ($i);
    if ($child->nodeType == $child->ELEMENT_NODE) {
      my $ln = $child->localName;
      if ($Method->{$ln} or $Attr->{$ln} or
          $Assert->{$ln} or $Misc->{$ln}) {
        $result .= node2code ($child);
      } else {
        valid_err q<Unknown element type: >.$child->localName,
          node => $child;
      }
    } elsif ($child->nodeType == $child->COMMENT_NODE) {
      $result .= perl_comment $child->data;
    } elsif ($child->nodeType == $child->TEXT_NODE) {
      if ($child->data =~ /\S/) {
        valid_err q<Unknown character data: >.$child->data,
          node => $child;
      }
    } else {
      valid_err q<Unknown type of node: >.$child->nodeType,
        node => $child;
    }
  }
  $result;
}

sub condition2code ($;%) {
  my ($parent, %opt) = @_;
  my $result = '';
  my @result;
  my $children = $parent->childNodes;
  for (my $i = 0; $i < $children->length; $i++) {
    my $child = $children->item ($i);
    if ($child->nodeType == $child->ELEMENT_NODE) {
      my $ln = $child->localName;
      if ($Condition->{$ln}) {
        push @result, node2code ($child);
      } else {
        valid_err q<Unknown element type: >.$child->localName,
          node => $child;
      }
    } elsif ($child->nodeType == $child->COMMENT_NODE) {
      $result .= perl_comment $child->data;
    } elsif ($child->nodeType == $child->TEXT_NODE) {
      if ($child->data =~ /\S/) {
        valid_err q<Unknown character data: >.$child->data,
          node => $child;
      }
    } else {
      valid_err q<Unknown type of node: >.$child->nodeType,
        node => $child;
    }
  }
  $result .= join (($opt{join}||='or' eq 'or' ? ' || ' : 
                    $opt{join} eq 'and' ? ' && ' : 
                    valid_err q<Multiple condition not supported>,
                      node => $parent),
                   map {"($_)"} @result);
  $result;
} #condition2code

sub node2code ($);
sub node2code ($) {
  my $node = shift;
  my $result = '';
  if ($node->nodeType != $node->ELEMENT_NODE) {
    if ($node->nodeType == $node->COMMENT_NODE) {
      $result .= perl_comment $node->data;
    } elsif ($node->nodeType == $node->TEXT_NODE) {
      if ($node->data =~ /\S/) {
        valid_err q<Unknown character data: >.$node->data,
          node => $node;
      }
    } else {
      valid_err q<Unknown type of node: >.$node->nodeType,
        node => $node;
    } 
    return $result;
  }
  my $ln = $node->localName;

  if ($ln eq 'var') {
    my $name = $node->getAttributeNS (undef, 'name');
    my $var = perl_var
                     local_name => $name,
                     scope => 'my',
                     type => '$';
    my $type = $node->getAttributeNS (undef, 'type');
    $result .= perl_comment $type;
    if ($node->hasAttributeNS (undef, 'isNull') and
        $node->getAttributeNS (undef, 'isNull') eq 'true') {
      $result .= perl_statement perl_assign $var => 'undef';
    } elsif ($node->hasAttributeNS (undef, 'value')) {
      $result .= perl_statement
                   perl_assign
                        $var
                     => to_perl_value ($node->getAttributeNS (undef, 'value'));
    } else {
      if ($type eq 'List' or $type eq 'Collection') {
        my @member;
        my $children = $node->childNodes;
        for (my $i = 0; $i < $children->length; $i++) {
          my $child = $children->item ($i);
          if ($child->nodeType == $child->ELEMENT_NODE) {
            if ($child->localName eq 'member') {
              push @member, perl_code_literal 
                              (to_perl_value ($child->textContent));
            } else {
              valid_err q<Unsupported element type>, node => $child;
            }
          } elsif ($child->nodeType == $child->COMMENT_NODE) {
            $result .= perl_comment $child->data;
          }
        }
        $result .= perl_statement
                     perl_assign
                          $var
                       => perl_list \@member;
      } elsif ($type =~ /Monitor/) {
        valid_err qq<Type $type not supported>, node => $node;
      } elsif ($node->hasChildNodes) {
        valid_err q<Children not supported>, node => $node;
      } else {
        $result .= perl_statement $var;
      }
    }
    $Status->{var}->{$name}->{type} = $node->getAttributeNS (undef, 'type');
  } elsif ($ln eq 'load') {
      $result .= perl_statement
                   perl_assign
                     perl_var 
                       (type => '$',
                        local_name => $node->getAttributeNS (undef, 'var'))
                   => 'load (' . 
                      perl_literal ($node->getAttributeNS (undef, 'href')).
                      ')';
    } elsif ($Method->{$ln}) {
      $result .= perl_var (type => '$',
                           local_name => $node->getAttributeNS (undef, 'var')).
                 ' = '
        if $node->hasAttributeNS (undef, 'var');
      my $param;
      if ($node->hasAttributeNS (undef, 'interface')) {
        my $if = $node->getAttributeNS (undef, 'interface');
        $param = $IFMethod->{$if}->{$ln};
        unless ($param) {
          valid_err "Method $if.$ln not supported", node => $node;
        }
        if ($if eq 'Element' and $ln eq 'getElementsByTagName' and
            not $node->hasAttributeNS (undef, 'name') and
            $node->hasAttributeNS (undef, 'tagname')) {
          $node->setAttributeNS (undef, 'name'
                                 => $node->getAttributeNS (undef, 'tagname'));
        }
      } else {
        $param = $Method->{$ln};
      }
      $result .= perl_var (type => '$',
                           local_name => $node->getAttributeNS (undef, 'obj')).
              '->'.$ln.' ('.
                join (', ',
                     map {
                       to_perl_value ($node->getAttributeNS (undef, $_),
                                      default => 'undef')
                     } @$param).
              ");\n";
    } elsif ($Attr->{$ln}) {
      if ($node->hasAttributeNS (undef, 'var')) {
        $result .= perl_var (type => '$',
                             local_name => $node->getAttributeNS (undef, 'var')).
                   ' = ';
      } elsif ($node->hasAttributeNS (undef, 'value')) {
        #
      } else {
        valid_err q<Unknown operation to an attribute>, node => $node;
      }
      my $obj = perl_var (type => '$',
                          local_name => $node->getAttributeNS (undef, 'obj'));
      my $if = $node->getAttributeNS (undef, 'interface');
      if (defined $if and $if eq 'DOMString') {
        if ($ln eq 'length') {
          $result .= 'length '.$obj;
        } else {
          valid_err q<$if.$ln not supported>, node => $node;
        }
      } else {
        $result .= $obj.'->'.$ln;
      }
      if ($node->hasAttributeNS (undef, 'var')) {
        $result .= ";\n";
      } elsif ($node->hasAttributeNS (undef, 'value')) {
        $result .= " (".to_perl_value ($node->getAttributeNS (undef, 'value')).
                   ");\n";
      }
    } elsif ($ln eq 'assertEquals') {
      my $expected = $node->getAttributeNS (undef, 'expected');
      my $expectedType = $Status->{var}->{$expected}->{type} || '';
      $result .= 'assertEquals'.
                 ({Collection => 'Collection',
                   List => 'List'}->{$expectedType}||'');
      my $ignoreCase = $node->getAttributeNS (undef, 'ignoreCase') || 'false';
      if ($ignoreCase eq 'auto') {
        $result .= 'AutoCase ('.
                   perl_literal ($node->getAttributeNS (undef, 'context') ||
                                 'element').
                   ', ';
      } else {
        $result .= ' (';
      }
      $result .= perl_literal ($node->getAttributeNS (undef, 'id')).', ';
      $result .= join ", ", map {
                   $ignoreCase eq 'true'
                     ? ($expectedType eq 'Collection' or
                        $expectedType eq 'List')
                         ? "toLowerArray ($_)" : "lc ($_)"
                     : $_
                 } map {
                   to_perl_value ($_)
                 } (
                   $expected,
                   $node->getAttributeNS (undef, 'actual'),
                 );
      $result .= ");\n";
    $Status->{Number}++;
  } elsif ($ln eq 'assertInstanceOf') {
    my $obj = perl_code_literal
                (to_perl_value ($node->getAttributeNS (undef, 'obj')));
    $result .= perl_statement 'assertInstanceOf ('.
                 perl_list 
                   ($node->getAttributeNS (undef, 'id'),
                    $node->getAttributeNS (undef, 'type'),
                    $obj).
               ')';
    if ($node->hasChildNodes) {
      $result .= perl_if
                   'isInstanceOf ('.
                   perl_list
                     ($node->getAttributeNS (undef, 'type'),
                      $obj) . ')',
                   body2code ($node);
    }
    $Status->{Number}++;
  } elsif ($ln eq 'assertSame') {
    my $expected = to_perl_value ($node->getAttributeNS (undef, 'expected'));
    my $actual = to_perl_value ($node->getAttributeNS (undef, 'actual'));
    $result .= perl_statement 'assertSame ('.
                 perl_list 
                   ($node->getAttributeNS (undef, 'id'),
                    $expected, $actual).
               ')';
    if ($node->hasChildNodes) {
      $result .= perl_if
                   'same ('.(perl_list $expected, $actual).')',
                   body2code ($node);
    }
    $Status->{Number}++;
  } elsif ($ln eq 'assertSize') {
    my $size = to_perl_value ($node->getAttributeNS (undef, 'size'));
    my $coll = to_perl_value ($node->getAttributeNS (undef, 'collection'));
    $result .= perl_statement 'assertSize ('.
                 perl_list 
                   ($node->getAttributeNS (undef, 'id'),
                    perl_code_literal $size, perl_code_literal $coll).
               ')';
    if ($node->hasChildNodes) {
      $result .= perl_if
                   qq<$size == size ($coll)>,
                   body2code ($node);
    }
    $Status->{Number}++;
  } elsif ($ln eq 'assertTrue' or $ln eq 'assertFalse') {
      my $condition;
      if ($node->hasAttributeNS (undef, 'actual')) {
        $condition = perl_var (type => '$',
                               local_name => $node->getAttributeNS
                                                       (undef, 'actual'));
        if ($node->hasChildNodes) {
          valid_err q<Child of $ln found but not supported>,
            node => $node;
        }
      } elsif ($node->hasChildNodes) {
        $condition = condition2code ($node);
      } else {
      valid_err $ln.q< w/o @actual not supported>, node => $node;
      }
      $result .= perl_statement $ln . ' ('.
                     perl_literal ($node->getAttributeNS (undef, 'id')).', '.
                     $condition. ')';
    $Status->{Number}++;
  } elsif ($ln eq 'assertNotNull' or $ln eq 'assertNull') {
    $result .= perl_statement $ln . ' (' .
                 perl_literal ($node->getAttributeNS (undef, 'id')).', '.
                 perl_var (type => '$',
                           local_name => $node->getAttributeNS (undef, 'actual')).
                 ')';
    if ($node->hasChildNodes) {
      valid_err q<Child of $ln found but not supported>,
          node => $node;
    }
    $Status->{Number}++;
  } elsif ($ln eq 'assertURIEquals') {
    $result .= perl_statement 'assertURIEquals ('.
                 perl_list
                   ($node->getAttributeNS (undef, 'id'),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'scheme'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'path'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'host'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'file'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'name'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'query'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'fragment'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'isAbsolute'),
                                      default => 'undef')),
                    perl_code_literal
                      (to_perl_value ($node->getAttributeNS (undef, 'actual')))).
               ')';
    $Status->{Number}++;
  } elsif ($ln eq 'assertDOMException') {
    $Status->{use}->{'Message::Util::Error'} = 1;
    $result .= q[
      {
        my $success = 0;
        try {
    ];
    my $children = $node->childNodes;
    my $errname;
    for (my $i = 0; $i < $children->length; $i++) {
      my $child = $children->item ($i);
      $errname = $child->localName if $child->nodeType == $child->ELEMENT_NODE;
      $result .= body2code ($child);
    }
    $result .= q[
        } catch Message::DOM::DOMException with {
          my $err = shift;
          $success = 1 if $err->{-type} eq ].perl_literal ($errname).q[;
        };
        assertTrue (].perl_literal ($node->getAttributeNS (undef, 'id')).
        q[, $success);
      }
    ];
    $Status->{Number}++;
  } elsif ($ln eq 'contentType') {
    $result .= '$builder->{contentType} eq '.
               perl_literal ($node->getAttributeNS (undef, 'type'));
    $Status->{our}->{builder} = 1;
  } elsif ($ln eq 'for-each') {
    my $collection = $node->getAttributeNS (undef, 'collection');
    my $collType = $Status->{var}->{$collection}->{type};
    my $coll = to_perl_value ($collection);
    $result .= 'for (my $i = 0; $i < '.
               ({'Collection'=>1,'List'=>1}->{$collType}
                  ? '@{'.$coll.'}' : $coll.'->length').
               '; $i++) {'.
                 perl_statement
                   (perl_assign
                       to_perl_value ($node->getAttributeNS (undef, 'member'))
                    => $coll . ({'Collection'=>1,'List'=>1}->{$collType}
                                  ? '->[$i]' : '->item ($i)')).
                 body2code ($node).
               '}';
  } elsif ($ln eq 'try') {
    my $children = $node->childNodes;
    my $true = '';
    my $false = '';
    for (my $i = 0; $i < $children->length; $i++) {
      my $child = $children->item ($i);
      if ($child->nodeType == $child->ELEMENT_NODE) {
        if ($child->localName eq 'catch') {
          valid_err q<Multiple 'catch'es found>, node => $child
            if $false;
          my @case;
          my $children2 = $child->childNodes;
          for (my $j = 0; $j < $children2->length; $j++) {
            my $child2 = $children2->item ($j);
            if ($child2->nodeType == $child2->ELEMENT_NODE) {
              if ($child2->localName eq 'ImplementationException') {
                valid_err q<Element type not supported>, node => $child2;
              } else {
                push @case, '$err->{-type} eq '.
                          perl_literal ($child2->getAttributeNS (undef, 'code'))
                            => body2code ($child2);
              }
            } else {
              $false .= node2code ($child2);
            }
          }
          $false .= perl_cases @case, else => perl_statement '$err->throw';
        } else {
          $true .= node2code ($child);
        }
      } else {
        $true .= node2code ($child);
      }
    }
    $result = "try {
                 $true
               } catch Message::DOM::ManakaiDOMException with {
                 my \$err = shift;
                 $false
               };";
    $Status->{use}->{'Message::Util::Error'} = 1;
  } elsif ($ln eq 'if') {
    my $children = $node->childNodes;
    my $condition;
    my $true = '';
    my $false = '';
    my $assert_true = 0;
    my $assert_false = 0;
    for (my $i = 0; $i < $children->length; $i++) {
      my $child = $children->item ($i);
      if ($child->nodeType == $child->ELEMENT_NODE) {
        if (not $condition) {
          $condition = node2code ($child);
        } elsif ($child->localName eq 'else') {
          valid_err q<Multiple 'else's found>, node => $child
            if $false;
          local $Status->{Number} = 0;
          $false = body2code ($child);
          $assert_false = $Status->{Number};
        } else {
          local $Status->{Number} = 0;
          $true .= node2code ($child);
          $assert_true += $Status->{Number};
        }
      } else {
        $true .= node2code ($child);
      }
    }
    if ($assert_true == $assert_false) {
      $Status->{Number} += $assert_true;
    } elsif ($assert_true > $assert_false) {
      $false .= perl_statement ('is_ok ()') x ($assert_true - $assert_false);
      $Status->{Number} += $assert_true;
    } else {
      $true .= perl_statement ('is_ok ()') x ($assert_false - $assert_true);
      $Status->{Number} += $assert_false;
    }
    $result = perl_if
                $condition,
                $true,
                $false ? $false : undef;
  } elsif ($ln eq 'while') {
    my $children = $node->childNodes;
    my $condition;
    my $true = '';
    my $assert = 0;
    {
      local $Status->{Number} = 0;
      for (my $i = 0; $i < $children->length; $i++) {
        my $child = $children->item ($i);
        if ($child->nodeType == $child->ELEMENT_NODE) {
          if (not $condition) {
            $condition = node2code ($child);
          } else {
            $true .= node2code ($child);
          }
        } else {
          $true .= node2code ($child);
        }
      }
      $assert = $Status->{Number};
    }
    $Status->{Number} += $assert;
    $result .= "while ($condition) {
                  $true
                }";
  } elsif ($ln eq 'or') {
    $result .= condition2code ($node, join => 'or');
  } elsif ($ln eq 'not') {
    $result .= 'not '.condition2code ($node, join => 'nosupport');
  } elsif ($ln eq 'notNull' or $ln eq 'isNull') {
    $result .= 'defined '.
               perl_var (type => '$',
                         local_name => $node->getAttributeNS (undef, 'obj'));
    $result = 'not ' . $result if $ln eq 'isNull';
  } elsif ({less => 1, lessOrEquals => 1,
            greater => 1, greaterOrEquals => 1}->{$ln}) {
    $result .= to_perl_value ($node->getAttributeNS (undef, 'actual')).
               {less => '<', lessOrEquals => '<=',
                greater => '>', greaterOrEquals => '>='}->{$ln}.
               to_perl_value ($node->getAttributeNS (undef, 'expected'));
  } elsif ($ln eq 'equals' or $ln eq 'notEquals') {
    my $case = $node->getAttributeNS (undef, 'ignoreCase');
    if ($case and $case eq 'auto') {
      $result .= 'equalsAutoCase (' .
                   perl_list
                     ($node->getAttributeNS (undef, 'context') || 'element',
                      to_perl_value
                        ($node->getAttributeNS (undef, 'expected')),
                      to_perl_value
                        ($node->getAttributeNS (undef, 'actual'))) . ')';
    } else {
      my $expected = to_perl_value
                        ($node->getAttributeNS (undef, 'expected'));
      my $actual = to_perl_value
                        ($node->getAttributeNS (undef, 'actual'));
      if ($case eq 'true') {
        $result = "(uc ($expected) eq uc ($actual))";
      } elsif ($node->hasAttributeNS (undef, 'bitmask')) {
        my $bm = ' & ' . to_perl_value
                          ($node->getAttributeNS (undef, 'bitmask'));
        $result = "($expected$bm == $actual$bm)";
      } else {
        $result = "($expected eq $actual)";
      }
    }
    $result = "(not $result)" if $ln eq 'notEquals';
  } elsif ($ln eq 'increment' or $ln eq 'decrement') {
    $result .= perl_statement
                 to_perl_value ($node->getAttributeNS (undef, 'var')).
                 {increment => ' += ', decrement => ' -= '}->{$ln}.
                 to_perl_value ($node->getAttributeNS (undef, 'value'));
  } elsif ({qw/plus 1 subtract 1 mult 1 divide 1/}->{$ln}) {
    $result .= perl_statement
                 (perl_assign
                     to_perl_value ($node->getAttributeNS (undef, 'var'))
                  => to_perl_value ($node->getAttributeNS (undef, 'op1')).
                     {qw<plus + subtract - mult * divide />}->{$ln}.
                     to_perl_value ($node->getAttributeNS (undef, 'op2')));
  } elsif ($ln eq 'append') {
    $result .= perl_statement
                 'push @{'.
                    to_perl_value ($node->getAttributeNS (undef, 'collection')).
                    '}, '.
                    to_perl_value ($node->getAttributeNS (undef, 'item'));
  } elsif ($ln eq 'instanceOf') {
    $result .= 'isInstanceOf ('.
               perl_list ($node->getAttributeNS (undef, 'type'),
                          perl_code_literal to_perl_value
                            ($node->getAttributeNS (undef, 'obj'))).
               ')';
  } elsif ($ln eq 'assign') {
    $result .= perl_statement
                 perl_assign
                      to_perl_value ($node->getAttributeNS (undef, 'var'))
                   => to_perl_value ($node->getAttributeNS (undef, 'value'));
  } elsif ($ln eq 'fail') {
    $result .= perl_statement 'fail ('.
                 perl_literal ($node->getAttributeNS (undef, 'id')). ')';
  } else {
    valid_err q<Unknown element type: >.$ln;
  }
  $result;
}

our $result = '';

my $input;
{
  local $/ = undef;
  $input = <>;
}

{
my $dom = Message::DOM::DOMImplementationRegistry
            ->getDOMImplementation
                 ({Core => undef,
                   XML => undef,
                   ExpandedURI q<ManakaiDOMLS2003:LS> => '1.0'});

my $parser = $dom->createLSParser (MODE_SYNCHRONOUS);
my $in = $dom->createLSInput;
$in->stringData ($input);

my $src = $parser->parse ($in)->documentElement;

{
my $children = $src->ownerDocument->childNodes;
for (my $i = 0; $i < $children->length; $i++) {
  my $node = $children->item ($i);
  if ($node->nodeType == $node->COMMENT_NODE) {
    if ($node->data =~ /Copyright/) {
      $result .= perl_comment 
                   qq<This script was generated by "$0"\n>.
                   qq<and is a derived work from the source document.\n>.
                   qq<The source document contained the following notice:\n>.
                   $node->data;
    } else {
      $result .= perl_comment $node->data;
    }
  }
}
}

my $child = $src->childNodes;

for (my $i = 0; $i < $child->length; $i++) {
  my $node = $child->item ($i);
  if ($node->nodeType == $node->ELEMENT_NODE) {
    my $ln = $node->localName;
    if ($ln eq 'metadata') {
      my $md = $node->childNodes;
      for (my $j = 0; $j < $md->length; $j++) {
        my $node = $md->item ($j);
        if ($node->nodeType == $node->ELEMENT_NODE) {
          my $ln = $node->localName;
          if ($ln eq 'title') {
            $result .= perl_statement
                         perl_assign
                           '$Info->{Name}'
                         => perl_literal $node->textContent;
          } elsif ($ln eq 'description') {
            $result .= perl_statement
                         perl_assign
                           '$Info->{Description}'
                         => perl_literal $node->textContent;
          } else {
          #  valid_err q<Unknown element type: >.$ln,
          #    node => $node;
          }
        } elsif ($node->nodeType == $node->TEXT_NODE) {
          if ($node->data =~ /\S/) {
            valid_err q<Unknown character data: >.$node->data,
              node => $node;
          }
        } elsif ($node->nodeType == $node->COMMENT_NODE) {
          $result .= perl_comment $node->data;
        } else {
          valid_err q<Unknown node type: >.$node->nodeType,
            node => $node;
        }
      }
    } elsif ($ln eq 'implementationAttribute') {
      $result .= perl_comment
                     sprintf 'Implementation attribute: @name=%s, @value=%s',
                             $node->getAttributeNS (undef, 'name'),
                             $node->getAttributeNS (undef, 'value');
    } else {
      $result .= node2code ($node);
    } 
  } elsif ($node->nodeType == $node->COMMENT_NODE) {
    $result .= perl_comment $node->data;
  } elsif ($node->nodeType == $node->TEXT_NODE) {
    if ($node->data =~ /\S/) {
      valid_err q<Unknown character data: >.$node->data,
        node => $node;
    }
  } else {
    valid_err q<Unknown type of node: >.$node->nodeType,
      node => $node;
  }
}
}

my $pre = "#!/usr/bin/perl -w\nuse strict;\n";
$pre .= perl_statement ('require '.perl_literal 'manakai/domtest.pl');
$pre .= perl_statement
            ('use Message::Util::Error')
  if $Status->{use}->{'Message::Util::Error'};
for (keys %{$Status->{our}}) {
  $pre .= perl_statement perl_var type => '$', local_name => $_,
                                  scope => 'our';
}
$pre .= perl_statement q<plan (>.(0+$Status->{Number}).q<)>;

output_result $pre.$result;
