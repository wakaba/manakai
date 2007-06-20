package Message::DOM::DOMException;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::Util::Error', 'Message::IF::DOMException';
require Message::Util::Error;

sub ___error_def () {+{
  WRONG_DOCUMENT_ERR => {
    -code => 4,
    -description => q(Can't insert into different document),
  },
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
  NOT_SUPPORTED_ERR => {
    -code => 9,
    -subtype => {
      CLONE_NODE_TYPE_NOT_SUPPORTED_ERR => {
        -description => q(Can't clone specified type of node),
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
## $Date: 2007/06/20 13:41:16 $
