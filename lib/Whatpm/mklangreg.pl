#!/usr/bin/perl
use strict;
use warnings;

my $full = $ENV{MKLANGREG_FULL};
my $subtags;

{
  my $langreg_source_file_name = shift;
  open my $langreg_source_file, '<', $langreg_source_file_name or
      die "$0: $langreg_source_file_name: $!";
  local $/ = undef;

  ## NOTE: Based on RFC 4646 3.1.'s syntax, but more error-tolerant.
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
      } elsif ($tag_name_start =~ /^[a-z]++(?>\.\.[a-z-]++)?+$/) {
        #$subtag->{_canon} = '_lowercase';
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
      for my $tag_name (
        $tag_name_start eq $tag_name_end
          ? ($tag_name_start) # for 'nan'
          : ($tag_name_start .. $tag_name_end)
      ) {
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

## Extensions
if ($full) {
  my $langreg_source_file_name = shift;
  open my $langreg_source_file, '<', $langreg_source_file_name or
      die "$0: $langreg_source_file_name: $!";
  local $/ = undef;

  ## NOTE: Based on RFC 4646 3.1.'s syntax, but more error-tolerant.
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
    if ($subtags->{extension}) {
      my $tag_name = $subtag->{Identifier}->[0];
      #$subtag->{_canon} = '_lowercase';
      if ($subtags->{extension}->{$tag_name}) {
        warn "Duplicate tag: $tag_name\n";
      } else {
        $subtags->{extension}->{$tag_name} = $subtag;
      }
    } else { ## The first record
      $subtags->{extheader} = $subtag;
      $subtags->{extension} = {};
    }
  }
}

## Remove unused data

$subtags->{_file_date} = $subtags->{header}->{'File-Date'}->[0];
delete $subtags->{header};
if ($full) {
  $subtags->{_ext_file_date} = $subtags->{extheader}->{'File-Date'}->[0];
  delete $subtags->{extheader};
}

for my $type (grep {!/^_/} keys %{$subtags}) {
  for my $tag (keys %{$subtags->{$type}}) {
    my $subtag = $subtags->{$type}->{$tag};

    if ($full) {
      $subtag->{_added} = $subtag->{Added}->[0];
      $subtag->{_macro} = $subtag->{Macrolanguage}->[0]
          if $subtag->{Macrolanguage};
    } else {
      delete $subtag->{Comments};
      delete $subtag->{Description};
      delete $subtag->{Scope};
    }
    delete $subtag->{Added};
    delete $subtag->{Tag};
    delete $subtag->{Subtag};
    delete $subtag->{Type};
    delete $subtag->{Macrolanguage};
    delete $subtag->{Identifier};
    delete $subtag->{RFC};
    delete $subtag->{Authority};
    delete $subtag->{Contact_Email};
    delete $subtag->{Mailing_List};
    delete $subtag->{URL};

    $subtag->{_deprecated} = 1 if $subtag->{Deprecated};
    delete $subtag->{Deprecated};

    if (defined $subtag->{'Preferred-Value'}->[0]) {
      $subtag->{_preferred} = $subtag->{'Preferred-Value'}->[0];
      #$subtag->{_preferred} =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
    }
    delete $subtag->{'Preferred-Value'};

    if (defined $subtag->{'Suppress-Script'}->[0]) {
      $subtag->{_suppress} = $subtag->{'Suppress-Script'}->[0];
      $subtag->{_suppress} =~ tr/A-Z/a-z/;
    }
    delete $subtag->{'Suppress-Script'};

    for (@{$subtag->{Prefix} or []}) {
      tr/A-Z/a-z/;
    }

    ## Sort for the ease of validation process
    $subtag->{Prefix} = [sort {length $b <=> length $a or $a cmp $b}
                             @{$subtag->{Prefix}}] if $subtag->{Prefix};
  }
}

## Resolve transitive relationship of Preferred-Value field

for my $type (grep {!/^_/} keys %{$subtags}) {
  for my $tag (keys %{$subtags->{$type}}) {
    my $subtag = $subtags->{$type}->{$tag};
    my $preferred_subtag = $subtag;
    my $preferred = $tag;
    while (1) {
      $preferred = $preferred_subtag->{_preferred} || $tag;
      $preferred =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
      last if $preferred eq $tag;
      $preferred_subtag = $subtags->{$type}->{$preferred};
    }
    $subtag->{_preferred} = $preferred if $preferred ne $tag;
  }
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Purity = 1;
my $value = Dumper $subtags;
if ($full) {
  $value =~ s/\$VAR1\b/\$Whatpm::LangTag::RegistryFull/g;
} else {
  $value =~ s/\$VAR1\b/\$Whatpm::LangTag::Registry/g;
}

print $value;
print "1;\n";
print '__DATA__

=head1 NAME

mklangreg.pl - Generate language subtag registry object for langauge tag validation

_LangTagReg.pm - A language subtag registry data module for language tag validation

_LangTagReg_Full.pm - A language subtag registry data module for language tag validation (including descriptions and additional data)

=head1 DESCRIPTION

The C<_LangTagReg.pm> file contains a list of registered language
subtags.  It is used by L<Whatpm::LangTag> for the purpose of language
tag validation.

The C<_LangTagReg_Full.pm> file contains, in addition to the contents
of C<_LangTagReg.pm>, descriptions and comments in the registry.

The C<mklangreg.pl> script is used to generate the C<_LangTagReg.pm>
file from the IANA registry.

=head1 SEE ALSO

L<Whatpm::LangTag>.

RFC 4646 <http://tools.ietf.org/html/rfc4646>.

RFC 5646 <http://tools.ietf.org/html/rfc5646>.

IANA Language Subtag Registry
<http://www.iana.org/assignments/language-subtag-registry>.

=head1 LICENSE

The C<mklangreg.pl> is in the Public Domain.

=cut

';
