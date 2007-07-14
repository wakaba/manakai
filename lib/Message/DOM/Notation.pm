package Message::DOM::Notation;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.9 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Notation';
require Message::DOM::Node;

sub ____new ($$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{node_name} = $_[0];
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    node_name => 1,
    owner_document_type_definition => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        return \${\$_[0]}->{$method_name}; 
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ({
    ## Read-write attributes (DOMString, trivial accessors)
    public_id => 1,
    system_id => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\$_[0]}->{strict_error_checking} and
              \${\$_[0]}->{manakai_read_only}) {
            report Message::DOM::DOMException
                -object => \$_[0],
                -type => 'NO_MODIFICATION_ALLOWED_ERR',
                -subtype => 'READ_ONLY_NODE_ERR';
          }
          if (defined \$_[1]) {
            \${\$_[0]}->{$method_name} = ''.\$_[1];
          } else {
            delete \${\$_[0]}->{$method_name};
          }
        }
        return \${\$_[0]}->{$method_name};
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## |Node| attributes

sub child_nodes ($) {
  require Message::DOM::NodeList;
  return bless \\($_[0]), 'Message::DOM::NodeList::EmptyNodeList';
} # child_nodes

sub node_name ($);

sub node_type () { 12 } # NOTATION_NODE

sub text_content () { undef }

## |Node| methods

sub append_child ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # append_child

sub manakai_append_text () { }

sub insert_before ($;$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # insert_before

sub replace_child ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # replace_child

## |Notation| attributes

sub manakai_declaration_base_uri ($;$) {
  ## NOTE: Same as |Notation|'s.

  if (@_ > 1) {
    if (${${$_[0]}->{owner_document}}->{strict_error_checking} and 
        ${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    if (defined $_[1]) {
      ${$_[0]}->{manakai_declaration_base_uri} = ''.$_[1];
    } else {
      delete ${$_[0]}->{manakai_declaration_base_uri};
    }
  }
  
  if (defined wantarray) {
    if (defined ${$_[0]}->{manakai_declaration_base_uri}) {
      return ${$_[0]}->{manakai_declaration_base_uri};
    } else {
      local $Error::Depth = $Error::Depth + 1;
      return $_[0]->base_uri;
    }  
  }
} # manakai_declaration_base_uri

## NOTE: A manakai extension.
sub owner_document_type_definition ($);

## NOTE: Setter is a manakai extension.
sub public_id ($;$);

## NOTE: Setter is a manakai extension.
sub system_id ($;$);

package Message::IF::Notation;

package Message::DOM::Document;

sub create_notation ($$) {
  if (${$_[0]}->{strict_error_checking}) {
    my $xv = $_[0]->xml_version;
    if (defined $xv) {
      if ($xv eq '1.0' and
          $_[1] =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/) {
        #
      } elsif ($xv eq '1.1' and
               $_[1] =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/) {
        #
      } else {
        report Message::DOM::DOMException
            -object => $_[0],
            -type => 'INVALID_CHARACTER_ERR',
            -subtype => 'MALFORMED_NAME_ERR';
      }
    }
  }

  return Message::DOM::Notation->____new (@_[0, 1]);
} # create_notation

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/14 16:32:28 $
