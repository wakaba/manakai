package Message::Util::QName::Filter;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Carp;
use Filter::Util::Call;
our $DEBUG;

sub import ($$) {
  my ($self, $map) = @_;
  filter_add (bless (($map ||= {}), $self));
}

sub filter ($) {
  my ($self) = @_;
  my $status;
  if (($status = filter_read) > 0) {
    s{\bExpandedURI\s+q<([^<>]*)>}{
      my ($prefix, $lname) = split /:/, $1, 2;
      my $r;
      if (defined $lname) {
        if (defined $self->{$prefix}) {
          $r = $self->{$prefix} . $lname;
        } else {
          Carp::croak (__PACKAGE__.": $prefix: Namespace prefix not declared");
        }
      } else {  ## Default namespace (bound to empty URI)
        $r = $prefix;
      }
      $r =~ s/([<>\\])/\\$1/g;
      $r = q[ q<] . $r . q[> ];
      print STDERR "MUQNameFilter: $r\n" if $DEBUG;
      $r;
    }ge;
  }
  $status;
} # filter

1; # $Date: 2004/11/22 12:54:48 $
__END__

=head1 NAME

Message::Util::QName::Filter - QName source code filter

=head1 SYNOPSIS

  use Message::Util::QName::Filter {
    prefix1 => q<URI reference 1>,
    prefix2 => q<URI reference 2>,
    ...
  };

  my $uri = ExpandedURI q<prefix1:local-name>;

=head1 DESCRIPTION

C<Message::Util::QName::Filter> is a source code filter that 
expands C<Message::Util::QName::General> style QName specification 
like C<< ExpandedURI q<prefix:local-name> >>.

To enable the filter, use the C<use> statement with a hash reference 
binding namespace prefixes with namespace URI references.

Note.  Take care when a QName is written in some delimited structure 
such as regex.  For example, C<< s/rdf:/ExpandedURI q<rdf:>/g >> 
would make syntax errors reported because C<< ExpandedURI q<rdf:> >> 
is expanded to the namespace URI and it includes C</> (SOLIDUS)
characters so that it is treated as a terminator by Perl parser. 
Use non-URI characters to delimit, e.g.: 

  s{rdf:}{ExpandedURi q<rdf:>}g

=head1 SEE ALSO

L<Message::Util::QName::General>.

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
