#!/usr/bin/perl
use strict;

my $subtags;

my $langreg_source_file_name = shift;
{
  open my $langreg_source_file, '<', $langreg_source_file_name or
      die "$0: $langreg_source_file_name: $!";
  local $/ = undef;

  ## NOTE: Based on RFC 4646 3.1.'s syntax, but more error-torelant.
  for (split /\x0D?+\x0A%%\x0D?+\x0A/, <$langreg_source_file>) {
    my $fields = [['' => '']];
    for (split /\x0D?+\x0A/, $_) {
      if (/^\s/) { ## Part of continuous line
        $fields->[-1]->[1] .= $_;
      } elsif (s/^([^:\s]++)\s*+:\s*+//) { ## The first line of a |field|
        push @$fields, [$1 => $_];
      } else { ## An errorneous line
        push @$fields, ['' => $_];
      }
    }
    my $subtag;
    shift @$fields if $fields->[0]->[1] eq ''; # remove dummy if unused
    for (@$fields) {
      $subtag->{$_->[0]} ||= [];
      my $v = $_->[1];
      $v =~ s/&#x([0-9A-Fa-f]++);/chr hex $1/ge;
      push @{$subtag->{$_->[0]}}, $v;
    }
    if ($subtags) {
      my $tag_name_start = $subtag->{Subtag}->[0] || $subtag->{Tag}->[0];
      if ($tag_name_start =~ /^[A-Z][a-z]++(?>\.\.[A-Z][a-z]++)?+$/) {
        $subtag->{_canon} = '_titlecase';
      } elsif ($tag_name_start =~ /^[A-Z]++(?>\.\.[A-Z]++)?+$/) {
        $subtag->{_canon} = '_uppercase';
      } elsif ($tag_name_start =~ /^[a-z]++(?>\.\.[a-z]++)?+$/) {
        $subtag->{_canon} = '_lowercase';
      } else {
        $subtag->{_canon} = $tag_name_start;
      }
      $tag_name_start =~ tr/A-Z/a-z/;
      my $tag_name_end;
      if ($tag_name_start =~ /^(.+)\.\.(.+)$/) {
        $tag_name_start = $1;
        $tag_name_end = $2;
      } else {
        $tag_name_end = $tag_name_start;
      }
      for my $tag_name ($tag_name_start .. $tag_name_end) {
        if ($subtags->{$subtag->{Type}->[0]}->{$tag_name}) {
          warn "Duplicate tag: $tag_name\n";
        } else {
          $subtags->{$subtag->{Type}->[0]}->{$tag_name} = $subtag;
        }
      }
    } else { ## The first record
      $subtags->{header} = $subtag;
    }
  }
}

## Remove unused data

$subtags->{_file_date} = $subtags->{header}->{'File-Date'}->[0];
delete $subtags->{header};

for my $type (grep {!/^_/} keys %{$subtags}) {
  for my $tag (keys %{$subtags->{$type}}) {
    my $subtag = $subtags->{$type}->{$tag};
    delete $subtag->{Comments};
    delete $subtag->{Description};
    delete $subtag->{Added};
    delete $subtag->{Tag};
    delete $subtag->{Subtag};
    delete $subtag->{Type};
    
    $subtag->{_deprecated} = 1 if $subtag->{Deprecated};
    delete $subtag->{Deprecated};

    $subtag->{_preferred} = $subtag->{'Preferred-Value'}->[0]
        if defined $subtag->{'Preferred-Value'}->[0];
    delete $subtag->{'Preferred-Value'};

    if (defined $subtag->{'Suppress-Script'}->[0]) {
      $subtag->{_suppress} = $subtag->{'Suppress-Script'}->[0];
      $subtag->{_suppress} =~ tr/A-Z/a-z/;
    }
    delete $subtag->{'Suppress-Script'};

    for (@{$subtag->{Prefix} or []}) {
      tr/A-Z/a-z/;
    }
  }
}

## Resolve transitive relationship of Preferred-Value field
## NOTE: Although noted in RFC 4646, urrently no tag has such relationship.

for my $type (grep {!/^_/} keys %{$subtags}) {
  for my $tag (keys %{$subtags->{$type}}) {
    my $subtag = $subtags->{$type}->{$tag};
    my $new_subtag = $subtag;
    while (1) {
      my $preferred = $new_subtag->{_preferred};
      last unless defined $preferred;
      $preferred =~ tr/A-Z/a-z/;
      $new_subtag = $subtags->{$type}->{$preferred};
      last unless $new_subtag;
    }
  }
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
my $value = Dumper $subtags;
$value =~ s/\$VAR1\b/\$Whatpm::LangTag::Registry/g;

print $value;
print "1;\n";
print '__DATA__

=head1 NAME

mklangreg.pl - Generate language subtag registry object for langauge
tag validation

_LangTagReg.pm - A language subtag registry data module for language
tag validation

=head1 DESCRIPTION

The C<_LangTagReg.pm> file contains a list of registered language
subtags.  It is used by L<Whatpm::LangTag> for the purpose of language
tag validation.

The C<mklangreg.pl> script is used to generate the C<_LangTagReg.pm>
file from the IANA registry.

=head1 SEE ALSO

L<Whatpm::LangTag>.

RFC 4646 (BCP 47) Tags for Identifying Languages <urn:ietf:rfc:4646>.

IANA Language Subtag Registry
<http://www.iana.org/assignments/language-subtag-registry>.

=head1 LICENSE

The C<mklangreg.pl> is in the Public Domain.

=cut

';
