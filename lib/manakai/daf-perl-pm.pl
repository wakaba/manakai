use strict;
use Message::Util::QName::Filter {
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
};

use Message::Util::PerlCode;

our $impl; # Assigned in the main script
our $db;

sub daf_perl_pm ($$$) {
  my ($mod_uri, $out_file_path, $mod_for) = @_;

  unless (defined $mod_for) {
    $mod_for = $db->get_module ($mod_uri)
                  ->get_property_text (ExpandedURI q<dis:DefaultFor>,
                                       ExpandedURI q<ManakaiDOM:all>);
  }
  my $mod = $db->get_module ($mod_uri, for_arg => $mod_for);

    status_msg_ qq<Generating Perl module from <$mod_uri> for <$mod_for>...>;
    local $Message::Util::DIS::Perl::Implementation
        = $impl->get_feature (ExpandedURI q<Util:PerlCode> => '1.0');
    my $pl = $mod->pl_generate_perl_module_document
                    ($impl->get_feature (ExpandedURI q<Util:PerlCode> => '1.0'));
    status_msg qq<done>;

    my $output;
    defined $out_file_path
        ? (open $output, '>', $out_file_path or die "$0: $out_file_path: $!")
        : ($output = \*STDOUT);

    status_msg_ sprintf qq<Writing Perl module %s...>,
                          defined $out_file_path
                            ? q<">.$out_file_path.q<">
                            : 'to stdout';
    print $output $pl->document_element->stringify;
    close $output;
    status_msg q<done>;

  require Message::Util::AutoLoad::Config;
  my $alconf = Message::Util::AutoLoad::Config->new;
  $alconf->register_all ($pl->get_autoload_definition_list);
  $alconf->save;
} # daf_perl_pm

1;

__END__

=head1 NAME

daf-perl-pm.pl - A daf module to generate Perl modules

=head1 DESCRIPTION

This script, C<daf-perl-pm.pl>, is dynamically loaded by
C<daf.pl> to create Perl modules.

=head1 SEE ALSO

L<bin/daf.pl> - daf main script

=head1 LICENSE

Copyright 2004-2006 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
