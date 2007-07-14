package Message::DOM::DOMException;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.13 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::Util::Error', 'Message::IF::DOMException';
require Message::Util::Error;

sub ___error_def () {+{
  INDEX_SIZE_ERR => {
    -code => 1,
    -subtype => {
      INDEX_OUT_OF_BOUND_ERR => {
        -description => q(Specified index is outside of the bounds),
      },
    },
  },
  # DOMSTRING_SIZE_ERR == 2
  HIERARCHY_REQUEST_ERR => {
    -code => 3,
    -subtype => {
      ANCESTOR_NODE_ERR => {
        -description => q(Specified node is an ancestor of the node or the node itself),
      },
      CHILD_NODE_TYPE_ERR => {
        -description => q(This type of node cannot be inserted to this point),
      },
      INUSE_DEFINITION_ERR => {
        -description => q(The node is already in use),
      },
    },
  },
  WRONG_DOCUMENT_ERR => {
    -code => 4,
    -subtype => {
      EXTERNAL_OBJECT_ERR => {
        -description => q(Can't insert into different document),
      },
      INUSE_DOCTYPE_ERR => {
        -description => q(Document type is already in use),
      },
    },
  },
  INVALID_CHARACTER_ERR => {
    -code => 5,
    -subtype => {
      MALFORMED_NAME_ERR => {
        -description => q(Not a legal XML |Name|),
      },
    },
  },
  # NO_DATA_ALLOWED_ERR == 6
  NO_MODIFICATION_ALLOWED_ERR => {
    -code => 7,
    -subtype => {
      READ_ONLY_NODE_ERR => {
        -description => q(Can't modify read-only node),
      },
      READ_ONLY_NODE_LIST_ERR => {
        -description => q(Can't modify read-only node list),
      },
    },
  },
  NOT_FOUND_ERR => {
    -code => 8,
    -subtype => {
      NOT_CHILD_ERR => {
        -description => q(Not a child of this node),
      },
      UNRECOGNIZED_CONFIGURATION_PARAMETER_ERR => {
        -description => q(Unrecognized configuration parameter is specified),
      },
    },
  },
  NOT_SUPPORTED_ERR => {
    -code => 9,
    -subtype => {
      ADOPT_NODE_TYPE_NOT_SUPPORTED_ERR => {
        -description => q(Can't adopt specified type of node),
      },
      CLONE_NODE_TYPE_NOT_SUPPORTED_ERR => {
        -description => q(Can't clone specified type of node),
      },
      CONFIGURATION_PARAMETER_VALUE_ERR => { ## TODO: Necessary?
        -description => q(Can't set the value to the configuration parameter),
      },
      NON_HTML_OPERATION_ERR => {
        -description => q(Can't apply to HTML document),
      },
      UNKNOWN_XML_VERSION_ERR => {
        -description => q(Specified version of XML is not supported),
      },
    },
  },
  INUSE_ATTRIBUTE_ERR => {
    -code => 10,
    -description => q(Attribute is already in use),
  },
  # INVALID_STATE_ERR == 11
  # SYNTAX_ERR == 12
  # INVALID_MODIFICATION_ERR == 13
  NAMESPACE_ERR => {
    -code => 14,
    -subtype => {
      MALFORMED_QNAME_ERR => {
        -description => q(Malformed XML qualified name),
      },
      NONXMLNSPREFIX_XMLNSNS_ERR => {
        -description => q(Namespace prefix "xmlns" must be used for namespace URI <http://www.w3.org/2000/xmlns/>),
      },
      PREFIXED_NULLNS_ERR => {
        -description => q(A namespace prefix is specified while namespace URI is null),
      },
      QNAME_NULLNS_ERR => {
        -description => q(Qualified name is not specified),
      },
      XMLNS_NONXMLNSNS_ERR => {
        -description => q(Qualified name "xmlns" can only be used with namespace URI <http://www.w3.org/2000/xmlns/>),
      },
      XMLNSPREFIX_NONXMLNSNS_ERR => {
        -description => q(Namespace prefix "xmlns" cannot be used for namespace URI other than <http://www.w3.org/2000/xmlns/>),
      },
      XMLPREFIX_NONXMLNS_ERR => {
        -description => q(Namespace prefix "xml" cannot be used for namespace URI other than <http://www.w3.org/XML/1998/namespace>),
      },
    },
  },
  # INVALID_ACCESS_ERR == 15
  # VALIDATION_ERR == 16
  TYPE_MISMATCH_ERR => {
    -code => 17,
    -subtype => {
      CONFIGURATION_PARAMETER_TYPE_ERR => {
        -description => q(The value type for this configuration parameter is incompatible with the specified value),
      },
    },
  },
}} # ___error_def

package Message::IF::DOMException;
push our @ISA, 'Message::Util::Error';

## DOM1
sub INDEX_SIZE_ERR () { 1 }
sub DOMSTRING_SIZE_ERR () { 2 }
sub HIERARCHY_REQUEST_ERR () { 3 }
sub WRONG_DOCUMENT_ERR () { 4 }
sub INVALID_CHARACTER_ERR () { 5 }
sub NO_DATA_ALLOWED_ERR () { 6 }
sub NO_MODIFICATION_ALLOWED_ERR () { 7 }
sub NOT_FOUND_ERR () { 8 }
sub NOT_SUPPORTED_ERR () { 9 }
sub INUSE_ATTRIBUTE_ERR () { 10 }
## DOM2
sub INVALID_STATE_ERR () { 11 }
sub SYNTAX_ERR () { 12 }
sub INVALID_MODIFICATION_ERR () { 13 }
sub NAMESPACE_ERR () { 14 }
sub INVALID_ACCESS_ERR () { 15 }
## DOM3
sub VALIDATION_ERR () { 16 }
sub TYPE_MISMATCH_ERR () { 17 }

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/14 09:19:11 $
