use strict;
use Message::Util::QName::Filter {
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  mv => q<http://suika.fam.cx/www/2006/05/mv/>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
};

use Message::DOM::XDP;
use Message::DOM::GenericLS;

our $impl; # Assigned in the main script
our $db;

sub daf_dtd_modules ($$$) {
  my ($mg_uri, $out_dir_path, $mg_for) = @_;

  unless (defined $mg_for) {
    $mg_for = $db->get_module ($mg_uri)
                 ->get_property_text (ExpandedURI q<dis:DefaultFor>,
                                      ExpandedURI q<ManakaiDOM:all>);
  }
  my $mg = $db->get_resource ($mg_uri, for_arg => $mg_for);

  status_msg qq<DTD module group <$mg_uri> for <$mg_for>...>;

  my $mg_name = daf_dm_get_name ($mg);
  my $mg_id = daf_dm_get_id ($mg);

  for my $mgc (@{daf_dm_get_components ($mg)}) {
    if ($mgc->is_type_uri (ExpandedURI q<mv:XMLDTDModule>)) {
      my $mgc_name = daf_dm_get_name ($mgc);
      my $mgc_id = daf_dm_get_id ($mgc);
      
      warn "$out_dir_path/$mg_id-$mgc_id";
    }
  }

} # daf_dtd_modules

sub daf_dm_get_name ($) {
  my ($res) = @_;
  my $r = $res->get_property_text (ExpandedURI q<mv:longName>);
  $r = $res->get_property_text (ExpandedURI q<dis:FullName>) unless defined $r;
  $r = $res->local_name unless defined $r;
  ## TODO: m12n support
  $r;
} # daf_dm_get_name

sub daf_dm_get_id ($) {
  my ($res) = @_;
  my $r = $res->get_property_text (ExpandedURI q<mv:id>);
  $r = $res->local_name unless defined $r;
  ## TODO: m12n support
  $r;
} # daf_dm_get_name

sub daf_dm_get_components ($) {
  my ($res) = @_;
  my $r = $res->get_property_resource_list (ExpandedURI q<mv:contains>);
  $r;
} # daf_dm_get_components

1;

__END__

=head1 NAME

daf-dtd-modules.pl - A daf module to generate DTD modukes

=head1 DESCRIPTION

This script, C<daf-dtd-modules.pl>, is dynamically loaded by
C<daf.pl> to create DTD modules.

=head1 SEE ALSO

L<bin/daf.pl> - daf main script

=head1 LICENSE

Copyright 2006 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
