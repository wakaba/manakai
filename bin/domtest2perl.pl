#!/usr/bin/perl -w 
use lib q<../lib>;
use strict;
BEGIN { require 'genlib.pl' }

use Message::Util::QName::General [qw/ExpandedURI/], {
  ManakaiDOMLS2003
    => q<http://suika.fam.cx/~wakaba/archive/2004/9/27/mdom-old-ls#>,
};
use Message::DOM::ManakaiDOMLS2003;
use Message::DOM::DOMLS qw/MODE_SYNCHRONOUS/;

my $Method = {
  qw/createEntityReference 1
     createTextNode 1
     getAttributeNode 1
     getElementsByTagName 1
     getNamedItem 1
     removeChild 1
     replaceChild 1/
};
my $Attr = {
  qw/attributes 1
     firstChild 1
     item 1
     nodeName 1
     specified 1/
};
my $Assert = {
  qw/assertDOMException 1
     assertNotNull 1
     assertTrue 1/
};
my $Misc = {
  qw/var 1/
};

my $Status;
our $result = '';

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

sub node2code ($) {
  my $node = shift;
  my $result = '';
  my $ln = $node->localName;

  if ($ln eq 'var') {
      $result .= perl_statement
                   perl_var
                     local_name => $node->getAttributeNS (undef, 'name'),
                     scope => 'my',
                     type => '$';
      if ($node->getAttributeNS (undef, 'value')) {
        valid_err q<Attribute "value" not supported>, node => $node;
      }
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
      $result .= perl_var (type => '$',
                           local_name => $node->getAttributeNS (undef, 'obj')).
              '->'.$ln.' ('.
                ## TODO: parameters
              ");\n";
    } elsif ($Attr->{$ln}) {
      if ($node->hasAttributeNS (undef, 'var')) {
        $result .= perl_var (type => '$',
                             local_name => $node->getAttributeNS (undef, 'var')).
                   ' = ';
      } else {
        impl_err q<Attr set>;
      }
      $result .= perl_var (type => '$',
                           local_name => $node->getAttributeNS (undef, 'obj')).
              '->'.$ln;
      if ($node->hasAttributeNS (undef, 'var')) {
        $result .= ";\n";
      }
    } elsif ($ln eq 'assertTrue') {
      if ($node->hasAttributeNS (undef, 'actual')) {
        $result .= perl_statement $ln . ' ('.
                     perl_literal ($node->getAttributeNS (undef, 'id')).', '.
                     perl_var (type => '$',
                               local_name => $node->getAttributeNS
                                                       (undef, 'actual')).
                     ')';
        if ($node->hasChildNodes) {
          valid_err q<Child of $ln found but not supported>,
            node => $node;
        }
      } else {
        valid_err q<assertTrue w/o @actual not supported>,
          node => $node;
      }
    } elsif ($ln eq 'assertNotNull') {
      $result .= perl_statement $ln . ' (' .
                 perl_literal ($node->getAttributeNS (undef, 'id')).', '.
                 perl_var (type => '$',
                           local_name => $node->getAttributeNS (undef, 'actual')).
                 ')';
      if ($node->hasChildNodes) {
        valid_err q<Child of $ln found but not supported>,
          node => $node;
      }
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
        }
        assertTrue (].perl_literal ($node->getAttributeNS (undef, 'id')).
        q[, $success);
      }
    ];
  } else {
    valid_err q<Unknown element type: >.$ln;
  }
  $result;
}

my $input;
{
  local $/ = undef;
  $input = <>;
}

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
          if ($ln eq '...') {
            
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


output_result $result;
