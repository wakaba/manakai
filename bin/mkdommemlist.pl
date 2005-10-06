#!/usr/bin/perl -w 
use strict;

use lib qw<lib ../lib>;

use strict;
use Message::Util::QName::Filter {
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  DISLang => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
};

use Getopt::Long;
use Pod::Usage;
my %Opt;
GetOptions (
  'dis-file-suffix=s' => \$Opt{dis_suffix},
  'daem-file-suffix=s' => \$Opt{daem_suffix},
  'debug' => \$Opt{debug},
  'help' => \$Opt{help},
  'output-file-path=s' => \$Opt{output_file_name},
  'search-path|I=s' => sub {
    shift;
    my @value = split /\s+/, shift;
    while (my ($ns, $path) = splice @value, 0, 2, ()) {
      unless (defined $path) {
        die qq[$0: Search-path parameter without path: "$ns"];
      }
      push @{$Opt{input_search_path}->{$ns} ||= []}, $path;
    }
  },
  'search-path-catalog-file-name=s' => sub {
    shift;
    require File::Spec;
    my $path = my $path_base = shift;
    $path_base =~ s#[^/]+$##;
    $Opt{search_path_base} = $path_base;
    open my $file, '<', $path or die "$0: $path: $!";
    while (<$file>) {
      if (s/^\s*\@//) {     ## Processing instruction
        my ($target, $data) = split /\s+/;
        if ($target eq 'base') {
          $Opt{search_path_base} = File::Spec->rel2abs ($data, $path_base);
        } else {
          die "$0: $target: Unknown target";
        }
      } elsif (/^\s*\#/) {  ## Comment
        #
      } elsif (/\S/) {      ## Catalog entry
        s/^\s+//;
        my ($ns, $path) = split /\s+/;
        push @{$Opt{input_search_path}->{$ns} ||= []},
             File::Spec->rel2abs ($path, $Opt{search_path_base});
      }
    }
    ## NOTE: File paths with SPACEs are not supported
    ## NOTE: Future version might use file: URI instead of file path.
  },
  'verbose!' => \$Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
$Opt{daem_suffix} = '.daem' unless defined $Opt{daem_suffix};
$Opt{dis_suffix} = '.dis' unless defined $Opt{dis_suffix};

sub status_msg ($) {
  my $s = shift;
  $s .= "\n" unless $s =~ /\n$/;
  print STDERR $s;
}

sub status_msg_ ($) {
  my $s = shift;
  print STDERR $s;
}

sub verbose_msg ($) {
  my $s = shift;
  $s .= "\n" unless $s =~ /\n$/;
  print STDERR $s if $Opt{verbose};
}

sub verbose_msg_ ($) {
  my $s = shift;
  print STDERR $s if $Opt{verbose};
}

use Message::Util::DIS;

my $impl = $Message::DOM::ImplementationRegistry->get_implementation
               ({
                 ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                 '+' . ExpandedURI q<DIS:Core> => '1.0',
                });
my $di = $impl->get_feature (ExpandedURI q<DIS:Core> => '1.0');

  status_msg_ qq<Loading the database "$Opt{file_name}"...>;
  my $db = $di->pl_load_dis_database ($Opt{file_name}, sub ($$) {
    my ($db, $mod) = @_;
    my $ns = $mod->namespace_uri;
    my $ln = $mod->local_name;
    verbose_msg qq<Database module <$ns$ln> is requested>;
    my $name = dac_search_file_path_stem ($ns, $ln, $Opt{daem_suffix});
    if (defined $name) {
      return $name.$Opt{daem_suffix};
    } else {
      return $ln.$Opt{daem_suffix};
    }
  });
  status_msg q<done>;

my $Method;
my $Attr;

for my $res (map {$db->get_any_resource ($_)}
             @{$db->get_any_resource_uri_list}) {
  next unless defined $res->local_name;
  if ($res->is_type_uri (ExpandedURI q<DISLang:Interface>)) {
    verbose_msg_ qq[Interface <@{[$res->uri]}>...];
    for my $mtd (@{$res->get_child_resource_list_by_type
                     (ExpandedURI q<DISLang:AnyMethod>)}) {
      if ($mtd->is_type_uri (ExpandedURI q<DISLang:Method>)) {
        $Method->{$res->local_name}->{$mtd->local_name} = my $param = [];
        push @$param, $mtd->pl_name;
        for my $prm (@{$mtd->get_child_resource_list_by_type
                         (ExpandedURI q<DISLang:MethodParameter>)}) {
          push @$param, $prm->local_name;
        }
      } elsif ($mtd->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
        $Attr->{$res->local_name}->{$mtd->local_name} = $mtd->pl_name;
      }
    }
    verbose_msg q<done>;
  }
}


sub perl_statement ($) {
  my $s = shift;
  $s . ";\n";
}

sub perl_assign ($@) {
  my ($left, @right) = @_;
  $left . ' = ' . (@right > 1 ? '(' . join (', ', @right) . ')' : $right[0]);
}


sub perl_literal ($) {
  my $s = shift;
  unless (defined $s) {
    verbose_msg q<Undefined value is passed to perl_literal ()>;
    return q<undef>;
  } elsif (ref $s eq 'ARRAY') {
    return q<[> . perl_list (@$s) . q<]>;
  } elsif (ref $s eq 'HASH') {
    return q<{> . perl_list (%$s) . q<}>;
  } elsif (ref $s eq 'CODE') {
    die q<CODE reference cannot be serialized>;
  } elsif (ref $s eq '__code') {
    return $$s;
  } else {
    ## NOTE: Don't change quote char - perl_code depends this quote.
    $s =~ s/(['\\])/\\$1/g;
    return q<'> . $s . q<'>;
  }
}

sub perl_list (@) {
  join ', ', map perl_literal $_, @_;
}

sub perl_var (%) {
  my %opt = @_;
  my $r = $opt{type} || '';                   # $, @, *, &, $# or empty
  $r = $opt{scope} . ' ' . $r if $opt{scope}; # my, our or local
  my $pack = ref $opt{package} ? $opt{package}->{full_name} : $opt{package};
  $r .= $pack . '::' if $pack;
  die q<Local name of variable must be specified>, %opt
    unless defined $opt{local_name};
  $r .= $opt{local_name};
  $r;
}

my $result = '';
$result .= perl_statement
             perl_assign
               perl_var
                 (type => '$',
                  local_name => 'Method')
             => perl_literal {
                  map {
                    %{$Method->{$_}}
                  } keys %$Method
                };
$result .= perl_statement
             perl_assign
               perl_var
                 (type => '$',
                  local_name => 'IFMethod')
             => perl_literal {
                  map {
                    $_ => $Method->{$_}
                  } keys %$Method
                };
$result .= perl_statement
             perl_assign
               perl_var
                 (type => '$',
                  local_name => 'Attr')
             => perl_literal {
                  map {
                    my $v = $_;
                    map {$_ => $Attr->{$v}->{$_}} keys %{$Attr->{$v}}
                  } keys %$Attr
                };
$result .= perl_statement 1;

  my $out_file_path = $Opt{output_file_name};
  my $output;
  defined $out_file_path
      ? (open $output, '>', $out_file_path or die "$0: $out_file_path: $!")
      : ($output = \*STDOUT);
  
  status_msg_ sprintf qq<Writing Perl script %s...>,
                      defined $out_file_path
                        ? q<">.$out_file_path.q<">
                        : 'to stdout';
  print $output $result;
  close $output;
  status_msg q<done>;


sub dac_search_file_path_stem ($$$) {
  my ($ns, $ln, $suffix) = @_;
  require Cwd;
  require File::Spec;
  for my $dir ('.', @{$Opt{input_search_path}->{$ns}||[]}) {
    my $name = Cwd::abs_path
        (File::Spec->canonpath
         (File::Spec->catfile ($dir, $ln)));
    if (-f $name.$suffix) {
      return $name;
    }
  }
  return undef;
} # dac_search_file_path_stem;


=head1 NAME

mkdommemlist.pl - DOM Method and Attribute List Generator

=head1 SYNOPSIS

  perl mkdommemlist.pl source.cdis > list.pl

=head1 DESCRIPTION

The DOM Test Suite by W3C stores its test codes in the abstract programming 
language based on XML and they do not have information on what is method, 
what is attribute, in what order parameters should be 
passed to methods, and so on.

The C<mkdommemlist.pl> generates lists of method, attributes and 
parameters for methods from the "cdis" files and write it 
out as a Perl script, so that other script, such as 
L<domtest2perl.pl>, can use this information.

=head1 SEE ALSO

I<Document Object Model (DOM) Conformance Test Suites>,
<http://www.w3.org/DOM/Test/>.

L<domtest2perl.pl>.

C<Makefile>.

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# $Date: 2005/10/06 10:53:34 $
