#!/usr/bin/perl -w
use strict;

our $result;

sub output_result ($) {
  print shift;
}

## Source file might be broken
sub valid_err ($;%) {
  my ($s, %opt) = @_;
  require Carp;
  output_result $result;
  if ($opt{node}) {
    if ($opt{node}->isa ('Message::Markup::SuikaWikiConfig20::Node')) {
      $s = $opt{node}->node_path (key => 'Name') . ': ' . $s;
    } elsif ($opt{node}->isa ('Message::DOM::IF::Node')) {
      $s = 'dom:nodeName ("'.$opt{node}->nodeName . '"): ' . $s;
    }
  }
  Carp::croak ($s);
}
sub valid_warn ($;%) {
  my ($s, %opt) = @_;
  require Carp;
  if ($opt{node}) {
    $s = $opt{node}->node_path (key => 'Name') . ': ' . $s;
  }
  Carp::carp ($s);
}

## Implementation (this script) might be broken
sub impl_err ($;%) {
  require Carp;
  Carp::croak (shift);
}
sub impl_warn ($;%) {
  require Carp;
  Carp::carp (shift);
}
sub impl_msg ($;%) {
  require Carp;
  Carp::carp (shift);
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
  $r .= perl_package_name (%{$opt{package}}) . '::' if $opt{package};
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



1;
