=head1 NAME

lib/manakai/mndebug - C<ManakaiNode> Debugging Utility

=cut

package manakai::mndebug;
use strict;
use Scalar::Util qw/refaddr/;

my %Printed; # key = addr
my %ID2Num;
my %Addr2Num;
my $NextNum = 1;

sub _print_noderef ($$$);
sub _print_nodestem ($$$);
sub _print_any ($$$);

sub _get_number ($$) {
  my ($addr, $id) = @_;
  if (defined $addr) {
    if ($Addr2Num{$addr}) {
      if (defined $id and not $ID2Num{$id}) {
        $ID2Num{$id} = $Addr2Num{$addr};
      } elsif (defined $id and $Addr2Num{$addr} != $ID2Num{$id}) {
        warn sprintf "Addr 0x%X is ##%d while id <$id> is ##%d\n",
               $addr, $Addr2Num{$addr}, $id, $ID2Num{$id};
      }
      return $Addr2Num{$addr};
    } elsif (defined $id) {
      if ($ID2Num{$id}) {
        $Addr2Num{$addr} = $ID2Num{$addr};
        return $ID2Num{$addr};
      }
      $Addr2Num{$addr} = $ID2Num{$addr} = $NextNum++;
      return $ID2Num{$addr};
    } else {
      $Addr2Num{$addr} = $NextNum++;
      return $Addr2Num{$addr};
    }
  } elsif (defined $id) {
    if ($ID2Num{$id}) {
      return $ID2Num{$id};
    } else {
      $ID2Num{$id} = $NextNum++;
      return $ID2Num{$id};
    }
  } else {
    require Carp;
    warn "No addr, no id", Carp::longmess ();
    return 0;
  }
} # _get_number

sub _get_ref_text ($$) {
  my ($addr, $id) = @_;
  '##' . _get_number ($addr, $id);
} # _get_ref_text

sub _get_obj_name ($) {
  my $obj = shift;
  _get_ref_text (refaddr $obj, undef);
}

sub _get_obj_ref ($) {
  my $obj = shift;
  _get_ref_text (refaddr $obj, undef);
}

sub _print_any ($$$) {
  my ($out, $indent, $obj) = @_;
  if (defined $obj) {
    if (UNIVERSAL::isa ($obj, 'Message::Util::ManakaiNode::ManakaiNodeStem')) {
      _print_nodestem ($out, $indent, $obj);
    } elsif (UNIVERSAL::isa ($obj,
                             'Message::Util::ManakaiNode::ManakaiNodeRef')) {
      _print_noderef ($out, $indent, $obj);
    } elsif (ref $obj eq 'ARRAY') {
      if ($Printed{refaddr $obj}) {
        print $out $indent, 'ARRAY ', _get_obj_ref $obj, ";\n";
        return;
      } elsif (@$obj == 0) {
        print $out $indent, 'ARRAY ', _get_obj_name $obj, " empty;\n";
        $Printed{refaddr $obj} = 1;
        return;
      } else {
        print $out $indent, 'ARRAY ', _get_obj_name $obj, " {\n";
        $Printed{refaddr $obj} = 1;
      }
      for my $i (0..$#$obj) {
        print $out $indent, $i, ":\n";
        _print_any ($out, $indent . '  ', $obj->[$i]);
      }
      print $out $indent, "}\n";
    } elsif (ref $obj eq 'HASH') {
      if ($Printed{refaddr $obj}) {
        print $out $indent, 'HASH ', _get_obj_ref $obj, ";\n";
        return;
      } elsif (0 == keys %$obj) {
        print $out $indent, 'HASH ', _get_obj_name $obj, " empty;\n";
        $Printed{refaddr $obj} = 1;
        return;
      } else {
        print $out $indent, 'HASH ', _get_obj_name $obj, " {\n";
        $Printed{refaddr $obj} = 1;
      }
      for my $key (sort {$a cmp $b} keys %$obj) {
        print $out $indent, '"', $key, '":', "\n";
        _print_any ($out, $indent . '  ', $obj->{$key});
      }
      print $out $indent, "}\n";
    } elsif (UNIVERSAL::isa ($obj, 'SCALAR') or
             UNIVERSAL::isa ($obj, 'REF')) {
      if ($Printed{refaddr $obj}) {
        print $out $indent, ref $obj, ' ', _get_obj_ref $obj, ";\n";
        return;
      } else {
        print $out $indent, ref $obj, ' ', _get_obj_name $obj, "\n";
        $Printed{refaddr $obj} = 1;
        _print_any ($out, $indent . '  ', $$obj);
      }
    } else {
      print $out $indent . '"' . $obj . '"';
      print $out ';' unless ref $obj;
      print $out "\n";
      print $out $indent . '  ', ref $obj, ";\n" if ref $obj;
    }
  } else {
    print $out $indent . "undef\n";
  }
} # _print_any

sub _print_noderef ($$$) {
  my ($out, $indent, $noderef) = @_;
  if ($Printed{refaddr $noderef}) {
    print $out $indent, 'ref ', _get_obj_ref $noderef, ";\n";
    return;
  } else {
    $Printed{refaddr $noderef} = 1;
  }
  my $np = $Message::Util::ManakaiNode::ManakaiNodeRef::Prop{ref $noderef};
  print $out $indent, 'ref ', _get_obj_ref $noderef, ' : ', ref $noderef, " {\n";
  if (UNIVERSAL::isa ($noderef->{node}, # mn:node
                      'Message::Util::ManakaiNode::ManakaiNodeStem')) {
    _print_nodestem $out, $indent . '  ', $noderef->{node};
  } else {
    if (exists $noderef->{node}) {
      print $out $indent, "  mn:node\n";
      _print_any ($out, $indent . '  ', $noderef->{node});
    } else {
      print $out $indent . "  no mn:node\n";
    }
  }
  print $out $indent, "}\n";
} # _print_noderef

sub _print_nodestem ($$$) {
  my ($out, $indent, $nodestem) = @_;
  if ($Printed{$nodestem->{nid}}) {
    print $out $indent, 'stem ',
                        _get_ref_text (refaddr $nodestem, $nodestem->{nid}),
                        ";\n";
    return;
  } else {
    $Printed{$nodestem->{nid}} = 1;
  }
                                                                # mn:type
  my $np = $Message::Util::ManakaiNode::ManakaiNodeRef::Prop{$nodestem->{t}};
  print $out $indent, 'stem ',                                  # mn:nodeID
                      _get_ref_text (refaddr $nodestem, $nodestem->{nid}),
                      ' : ', ref $nodestem, "\n";
  print $out $indent, '[', $nodestem->{t}, "] {\n";
                           #  mn:rc mn:groveReferenceCounter
  print $out $indent, '  rc ', $nodestem->{rc},
                      ' grc ', ${$nodestem->{grc}||\''}, ' (',
                      _get_obj_ref ($nodestem->{grc}), ")\n"; # mn:treeID
  print $out $indent, '  Grove: ', _get_ref_text (undef, ${$nodestem->{tid}}),
                      ";\n";
  for my $prop_type (
    's0', # subnode0
    's',  # subnode1
    's2', # subnode2
    'o',  # origin0
    'i',  # irefnode0
    'x',  # xrefnode0
    'a0', # anydata0
    'a1', # anydata1
    'a2', # anydata2
  ) {
    for my $prop_name (@{$np->{$prop_type} || []}) {
      if (exists $nodestem->{$prop_name}) {
        print $out $indent, '  ', $prop_name, ' [', $prop_type, "]\n";
        _print_any ($out, $indent . '    ', $nodestem->{$prop_name});
      }
    }
  }
  print $out $indent, "}\n";
} # _print_nodestem

=head1 SYNOPSIS

  require 'lib/manakai/mndebug.pl';

  manakai::mndebug::dump ($object);

=cut

sub dump ($) {
  my $obj = shift;
  %Printed = ();
  _print_any \*STDOUT, '', $obj;
} # dump

=head1 LICENSE

***** BEGIN LICENSE BLOCK *****

Copyright 2006 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

Alternatively, the contents of this file may be used 
under the following terms (the "MPL/GPL/LGPL"), 
in which case the provisions of the MPL/GPL/LGPL are applicable instead
of those above. If you wish to allow use of your version of this file only
under the terms of the MPL/GPL/LGPL, and not to allow others to
use your version of this file under the terms of the Perl, indicate your
decision by deleting the provisions above and replace them with the notice
and other provisions required by the MPL/GPL/LGPL. If you do not delete
the provisions above, a recipient may use your version of this file under
the terms of any one of the Perl or the MPL/GPL/LGPL.

=head2 MPL/GPL/LGPL

Version: MPL 1.1/GPL 2.0/LGPL 2.1

The contents of this file are subject to the Mozilla Public License Version
1.1 (the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at
<http://www.mozilla.org/MPL/>.

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the
License.

The Original Code is manakai code.

The Initial Developer of the Original Code is Wakaba.
Portions created by the Initial Developer are Copyright (C) 2006
the Initial Developer. All Rights Reserved.

Contributor(s):

=over 4

=item Wakaba <w@suika.fam.cx>

=back

Alternatively, the contents of this file may be used under the terms of
either the GNU General Public License Version 2 or later (the "GPL"), or
the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
in which case the provisions of the GPL or the LGPL are applicable instead
of those above. If you wish to allow use of your version of this file only
under the terms of either the GPL or the LGPL, and not to allow others to
use your version of this file under the terms of the MPL, indicate your
decision by deleting the provisions above and replace them with the notice
and other provisions required by the LGPL or the GPL. If you do not delete
the provisions above, a recipient may use your version of this file under
the terms of any one of the MPL, the GPL or the LGPL.

***** END LICENSE BLOCK *****

=cut

1; # $Date: 2006/01/23 12:43:36 $
