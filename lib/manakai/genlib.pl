#!/usr/bin/perl -w
use strict;

=head1 NAME

genlib.pl - Source code generation utilities

=head1 DESCRIPTION

This Perl library provides a number of functions useful to 
generate source code fragment, including Perl code, in the 
C<main> namespace.

This library is part of manakai. 

=head1 FUNCTIONS

This library provides a lot of utility functions, most of 
their names are prefixed to identity their functionality. 

=over 4

=item Global Variable C<$result>

If the global variable C<$result> has its value, 
it is printed when a C<valid_err> is reported. 

=cut

our $result;

=item output_result ($s)

Outputs the argument as an output to the default output (usually 
the standard output).  Applications of this library can redefine 
this function in their own code so that they customize the output 
if they want.  Otherwise, it is simply C<print>ed. 

=item Global Variable C<$ResultOutput> (default: C<STDOUT>)

The file handle to which the result is outputed. 

=cut

our $ResultOutput ||= \*STDOUT;
sub output_result ($) {
  print $ResultOutput shift;
}

=item Global Variable C<$NodePathKey> = [I<name1>, I<name2>,,,,]

This variable contains zero or more SuikaWikiConfig/2.0 element type 
name that should be considered as "element identifier" - when 
a C<valid_err> is reported with a node, its node path is also 
reported with values of these element if exists. 

=cut

our $NodePathKey = [qw/Name QName Label/];

=item valid_err $msg, node => $node

Reports that the source data is something wrong (validness error) 
and that the script is unable to continue the operation, and dies. 
If the optional C<$node> argument is specified, its node path 
is outputed as the position at which the error occurs. 

=cut

sub valid_err ($;%) {
  my ($s, %opt) = @_;
  require Carp;
  output_result $result;
  if ($opt{node}) {
    if ($opt{node}->isa ('Message::Markup::SuikaWikiConfig20::Node')) {
      $s = $opt{node}->node_path (key => $NodePathKey) . ': ' . $s;
    } elsif ($opt{node}->isa ('Message::DOM::IF::Node')) {
      $s = 'dom:nodeName ("'.$opt{node}->node_name . '"): ' . $s;
    }
  }
  Carp::croak ($s);
}

=item valid_warn $msg, node => $node

Warns a non-fatal validness problem, as C<valid_err> does, but dying. 

=cut

sub valid_warn ($;%) {
  my ($s, %opt) = @_;
  require Carp;
  if ($opt{node}) {
    $s = $opt{node}->node_path (key => 'Name') . ': ' . $s;
  }
  Carp::carp ($s);
}

=item impl_err $msg

Reports an implementation error and dies.  It is intended to be 
called when something unbelivale has happened.

=cut

sub impl_err ($;%) {
  require Carp;
  output_result $result;
  die shift ().Carp::longmess ();
}

=item impl_warn $msg

Warns some non-fatal implementation matter. 

=cut

sub impl_warn ($;%) {
  require Carp;
  Carp::carp (shift);
}

=item impl_msg $msg

Shows a message from the implementation.  Unlike C<impl_err> and 
C<impl_warn> it does not mean something broken. 

=cut

sub impl_msg ($;%) {
  require Carp;
  Carp::carp (shift);
}



=item \@uniqed = array_uniq \@array

Removes duplicated string from an array.

=cut

sub array_uniq ($) {
  my $a = shift;
  my @a;
  my %a;
  no warnings 'uninitialized';
  for (@$a) {
    push @a, $_ unless $a{$_}++;
  }
  \@a;
}


sub english_number ($;%) {
  my ($num, %opt) = @_;
  if ($num == 0) {
    qq<no $opt{singular}>;
  } elsif ($num == 1) {
    qq<a $opt{singular}>;
  } elsif ($num < 0) {
    qq<$num $opt{plural}>;
  } elsif ($num < 10) {
    [qw/0 1 two three four five seven six seven eight nine/]->[$num] . ' ' .
    $opt{plural};
  } else {
    qq<$num $opt{plural}>;
  }
} # english_number

sub english_list ($;%) {
  my ($list, %opt) = @_;
  if (@$list > 1) {
    $opt{connector} = defined $opt{connector}
                          ? qq< $opt{connector} > : qq<, >;
    join (', ', @$list[0..($#$list-1)]).$opt{connector}.
    $list->[-1];
  } else {
    $list->[0];
  }
} # english_list


sub perl_comment ($) {
  my $s = shift;
  $s =~ s/\n/\n## /g;
  $s =~ s/\n## $/\n/s;
  $s .= "\n" unless $s =~ /\n$/;
  $s = q<## > . $s;
  $s;
}

sub perl_statement ($) {
  my $s = shift;
  $s . ";\n";
}

sub perl_assign ($@) {
  my ($left, @right) = @_;
  $left . ' = ' . (@right > 1 ? '(' . join (', ', @right) . ')' : $right[0]);
}

sub perl_name ($;%) {
  my ($s, %opt) = @_;
  valid_err q<Uninitialized value in name>, node => $opt{node}
    unless defined $s;
  $s =~ s/[- ](.|$)/uc $1/ge;
  $s = ucfirst $s if $opt{ucfirst};
  $s = uc $s if $opt{uc};
  $s;
}

sub perl_internal_name ($) {
  my $s = shift;
  '_' . perl_name $s;
}

sub perl_inherit ($;$) {
  my ($isa, $mod) = @_;
  return '' unless @$isa;
  $isa = array_uniq $isa;

  if ($mod) {
    perl_statement 'push ' . perl_var (type => '@',
                                       local_name => 'ISA',
                                       package => {full_name => $mod}) .
                   ', ' . perl_list (@$isa);
  } else {
    perl_statement 'push our @ISA, ' . perl_list (@$isa);
  }
}

sub perl_sub (%) {
  my %opt = @_;
  my $r = 'sub ';
  $r .= $opt{name} . ' ' if $opt{name};
  $r .= '(' . $opt{prototype} . ') ' if defined $opt{prototype};
  $r .= "{\n";
  $r .= $opt{code};
  $r .= "}\n";
  $r;
}

sub perl_cases (@) {
  my $r = '';
  while (my ($when, $code) = splice @_, 0, 2) {
    $r .= $when ne 'else' ? qq<} elsif ($when) {\n$code\n>
                          : qq<} else {\n$code\n>;
  }
  $r =~ s/^\} els//;
  $r .= qq<}\n> if $r;
  $r = "\n" . $r if $r;
  $r;
}

sub perl_var (%) {
  my %opt = @_;
  my $r = $opt{type} || '';                   # $, @, *, &, $# or empty
  $r = $opt{scope} . ' ' . $r if $opt{scope}; # my, our or local
  my $pack = ref $opt{package} ? $opt{package}->{full_name} : $opt{package};
  $r .= $pack . '::' if $pack;
  impl_err q<Local name of variable must be specified>, %opt
    unless defined $opt{local_name};
  $r .= $opt{local_name};
  $r;
}

{
use re 'eval';
my $RegBlockContent;
$RegBlockContent = qr/(?>[^{}\\]*)(?>(?>[^{}\\]+|\\.|\{(??{$RegBlockContent})\})*)/s;
sub perl_code ($;%);
sub perl_code ($;%) {
  my ($s, %opt) = @_;
  valid_err q<Uninitialized value in perl_code>,
    node => $opt{node} unless defined $s;
  $s =~ s[<Q:([^<>]+)>|\b(null|true|false)\b][
    my ($q, $l) = ($1, $2);
    if (defined $q) {
      if ($q =~ /\}/) {
        valid_warn qq<Possible typo in the QName: "$q">;
      }
      perl_literal (expanded_uri ($q));
    } else {
      {true => 1, false => 0, null => 'undef'}->{$l};
    }
  ]ge;
## TODO: Ensure Message::Util::Error imported if try.
## ISSUE: __FILE__ & __LINE__ will break if multiline substition happens.
  $s =~ s{
    \b__([A-Z]+)
    (?:\{($RegBlockContent)\})?
    __\b
  }{
    my ($name, $data) = ($1, $2);
    my $r;
    if ($name eq 'DEEP') {   ## Deep Method Call
      $r = 'do { local $Error::Depth = $Error::Depth + 1;' . perl_code ($data) .
           '}';
    } elsif ($name eq 'FILE' or $name eq 'LINE' or $name eq 'PACKAGE') {
      $r = qq<__${name}__>;
    } else {
      valid_err qq<Preprocessing macro "$name" not supported>;
    }
    $r;
  }goex;
  $s;
}
}

{my $f = 0;
sub perl_code_source ($%) {
  my ($s, %opt) = @_;
  sprintf qq<\n#line %d "File <%s> Node <%s>"\n%s\n> .
          qq<#line 1 "File <%s> Chunk #%d"\n>,
    $opt{line} || 1, $opt{file} || '',
    $opt{path} || 'x:unknown ()', $s, 
    $opt{file} || '', ++$f;
}}

sub perl_code_literal ($) {
  my $s = shift;
  bless \$s, '__code';
}

sub perl_literal ($) {
  my $s = shift;
  unless (defined $s) {
    impl_warn q<Undefined value is passed to perl_literal ()>;
    return q<undef>;
  } elsif (ref $s eq 'ARRAY') {
    return q<[> . perl_list (@$s) . q<]>;
  } elsif (ref $s eq 'HASH') {
    return q<{> . perl_list (%$s) . q<}>;
  } elsif (ref $s eq 'CODE') {
    impl_err q<CODE reference cannot be serialized>;
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

sub perl_if ($$;$) {
  my ($condition, $true, $false) = @_;
  my $if = q<if>;
  unless (defined $true) {
    $if = q<unless>;
    $true = $false;
    $false = undef;
  }
  for ($true, $false) {
    $_ = "\n" . $_ if $_ and /\A#\w+/;
  }
  my $r = qq<\n$if ($condition) {\n>.
          qq<  $true>.
          qq<}>;
  if (defined $false) {
     $r .=  qq< else {\n>.
           qq<  $false>.
           qq<}>;
  }
  $r .= qq<\n>;
  $r;
} # perl_if


sub pod_comment (@) {
  (q<=begin comment>, @_, q<=end comment>);
}

sub pod_block (@) {
  my @v = grep ((defined and length), @_);
  join "\n\n", '', ($v[0] =~ /^=/ ? () : '=pod'), @v, '=cut', '';
}

sub pod_head ($$) {
  my ($level, $s) = @_;
  $s =~ s/\s+/ /g;
  if ($level < 5) {
    '=head' . $level . ' ' . $s;  ## pod has only head1-head4.
  } else {
    'B<' . $s . '>';
  }
}

sub pod_list ($@) {
  my $m = shift;
  ('=over ' . $m, @_, '=back');
}

sub pod_item ($) {
  my ($s) = @_;
  valid_err q<Uninitialized value in pod_item> unless defined $s;
  $s =~ s/\s+/ /g;
  '=item ' . $s;
}

sub pod_pre ($) {
  my $s = shift;
  return '' unless defined $s;
  $s =~ s/\n/\n  /g;
  '  ' . $s;
}

sub pod_para ($) {
  my $s = shift;
  return '' unless defined $s;
  $s =~ s/\n\s+/\n/g;
  $s;
}

sub pod_paras ($) {
  shift;
}

sub pod_cdata ($) {
  my $s = shift;
  $s =~ s/([<>])/{'<' => 'E<lt>', '>' => 'E<gt>'}->{$1}/ge;
  $s;
}

sub pod_code ($) {
  my $s = shift;
  $s =~ s/([<>])/{'<' => 'E<lt>', '>' => 'E<gt>'}->{$1}/ge;
  qq<C<$s>>;
}

sub pod_em ($) {
  my $s = shift;
  $s =~ s/([<>])/{'<' => 'E<lt>', '>' => 'E<gt>'}->{$1}/ge;
  qq<I<$s>>;
}

sub pod_dfn ($) {
  my $s = shift;
  $s =~ s/([<>])/{'<' => 'E<lt>', '>' => 'E<gt>'}->{$1}/ge;
  qq<I<$s>X<$s>>;
}

sub pod_char (%) {
  my %opt = @_;
  if ($opt{name}) {
    if ($opt{name} eq 'copy') {
      qq<E<169>>;
    } else {
      qq<E<$opt{name}>>;
    }
  } else {
    impl_err q<Bad parameter for "pod_char">;
  }
} # pod_char

sub pod_uri ($) {
  my $uri = shift;
  qq<E<lt>${uri}E<gt>>;
} # pod_uri

sub pod_mail ($) {
  my $mail = shift;
  qq<E<lt>${mail}E<gt>>;
} # pod_mail

sub pod_link (%) {
  my %opt = @_;
  if ($opt{label}) {
    $opt{label} .= '|';
  } else {
    $opt{label} = '';
  }
  if ($opt{section}) {
    qq<L<$opt{label}/"$opt{section}">>;
  } elsif ($opt{module}) {
    qq<L<$opt{label}$opt{module}>>;
  } else {
    impl_err q<Bad parameter for "pod_link">;
  }
}


sub muf_template ($) {
  my $s = shift;
  $s =~ s{<Q:([^<>]+)>}{           ## QName
    expanded_uri ($1)
  }ge;
  $s;
}

sub section (@) {
  my @r;
  while (my ($t, $s) = splice @_, 0, 2) {
    if ($t eq 'req' and (not defined $s or not length $s)) {
      return ();
    } elsif (defined $s and length $s) {
      push @r, $s;
    }
  }
  return @r;
}


sub rfc3339_date ($) {
  my @time = gmtime shift;
  sprintf q<%04d-%02d-%02dT%02d:%02d:%02d+00:00>,
          $time[5] + 1900, $time[4] + 1, @time[3,2,1,0];
}

sub version_date ($) {
  my @time = gmtime shift;
  sprintf q<%04d%02d%02d.%02d%02d>,
          $time[5] + 1900, $time[4] + 1, @time[3,2,1];
}

=back

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/10/06 10:53:39 $
