package Message::DOM::DOMConfiguration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMConfiguration';
require Message::DOM::DOMException;

use overload
    '%{}' => sub {
      tie my %list, ref $_[0], $_[0];
      return \%list;
    },
    eq => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::DOM::DOMConfiguration');
      return $${$_[0]} eq $${$_[1]};
    },
    ne => sub {
      return not ($_[0] eq $_[1]);
    },
    fallback => 1;

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

sub TIEHASH ($$) { $_[1] }

## TODO: Define Perl binding

## |DOMConfiguration| attribute

my %names = (
             'error-handler' => 1,
             q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1,
             q<http://suika.fam.cx/www/2006/dom-config/dtd-attribute-type> => 1,
             q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 1,
             q<http://suika.fam.cx/www/2006/dom-config/strict-document-children> => 1,
);
  ## http://suika.fam.cx/www/2006/dom-config/xml-id
  ## xml-dtd

sub parameter_names ($) {
  require Message::DOM::DOMStringList;
  return bless [sort {$a cmp $b} keys %names],
      'Message::DOM::DOMStringList::StaticList';
} # parameter_names

## |DOMConfiguration| methods

sub can_set_parameter ($$;$) {
  my $name = ''.$_[1];
  if ({
       q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1,
       q<http://suika.fam.cx/www/2006/dom-config/dtd-attribute-type> => 1,
       q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 1,
       q<http://suika.fam.cx/www/2006/dom-config/strict-document-children> => 1,
      }->{$name}) {
    return 1;
  } elsif ($name eq 'error-handler') {
    return 1 unless defined $_[2];
    return ref $_[2] eq 'CODE';
  } else {
    return 0;
  }
} # can_set_parameter

sub get_parameter ($$) {
  my $name = ''.$_[1];
  if ({
       q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1,
       q<http://suika.fam.cx/www/2006/dom-config/dtd-attribute-type> => 1,
       q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 1,
       q<http://suika.fam.cx/www/2006/dom-config/strict-document-children> => 1,
       'error-handler' => 1,
      }->{$name}) {
    return ${$${$_[0]}}->{$name};    
  } else {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'UNRECOGNIZED_CONFIGURATION_PARAMETER_ERR';
  }
} # get_parameter
*FETCH = \&get_parameter;

## TODO: Should we allow $cfg->{error_handler}?

sub set_parameter ($$;$) {
  my $name = ''.$_[1];
  if (defined $_[2]) {
    if ({
         q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1,
         q<http://suika.fam.cx/www/2006/dom-config/dtd-attribute-type> => 1,
         q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 1,
         q<http://suika.fam.cx/www/2006/dom-config/strict-document-children> => 1,
        }->{$name}) {
      if ($_[2]) {
        ${$${$_[0]}}->{$name} = 1;
      } else {
        delete ${$${$_[0]}}->{$name};
      }
    } elsif ($name eq 'error-handler') {
      if (ref $_[2] eq 'CODE') {
        ${$${$_[0]}}->{$name} = $_[2];
      } else {
        report Message::DOM::DOMException
            -object => $_[0],
            -type => 'TYPE_MISMATCH_ERR',
            -subtype => 'CONFIGURATION_PARAMETER_TYPE_ERR';
      }
    } else {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NOT_FOUND_ERR',
          -subtype => 'UNRECOGNIZED_CONFIGURATION_PARAMETER_ERR';
    }
  } else {
    if ({
         q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1,
         q<http://suika.fam.cx/www/2006/dom-config/dtd-attribute-type> => 1,
         q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 1,
         q<http://suika.fam.cx/www/2006/dom-config/strict-document-children> => 1,
        }->{$name}) {
      ${$${$_[0]}}->{$name} = 1;
    } elsif ($_[1] eq 'error-handler') {
      ${$${$_[0]}}->{$name} = sub ($) {
        ## NOTE: Same as one set by |Document| constructor.
        warn $_[0];
        return $_[0]->severity != 3; # SEVERITY_FATAL_ERROR
      };
    } else {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NOT_FOUND_ERR',
          -subtype => 'UNRECOGNIZED_CONFIGURATION_PARAMETER_ERR';
    }
  }
  return undef;
} # set_parameter
*STORE = \&set_parameter;

sub DELETE ($$) {
  local $Error::Depth = $Error::Depth + 1;
  $_[0]->set_parameter ($_[1] => undef);
} # DELETE

sub EXISTS ($$) { exists $names{$_[1]} }

sub FIRSTKEY ($) {
  my $a = keys %names;
  return each %names;
} # FIRSTKEY
              
sub NEXTKEY ($) {
  return each %names;
} # NEXTKEY

package Message::IF::DOMConfiguration;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/14 09:19:11 $
