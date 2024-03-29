
=head1 NAME

Message::Util::Formatter::Base - Formatting Template Text Replacement Engine

=head1 DESCRIPTION

C<Message::Util::Formatter::Base> is a base class to implement specific
application of "formatting."

This module is part of manakai.

=cut

package Message::Util::Formatter::Base;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub ___rule_def () {+{
  -bare_text => {
                 
  },
  -undef     => {
             
  },
  -default   => {
    pre => sub { },
    post => sub { },
    attr => sub { },                 
  },
  -entire    => {
    
  },
}}

sub ___get_rule_def ($$) {
  my ($self, $name) = @_;
  my $def;
  $def = $self->___rule_def->{$name} if $self->can ('___rule_def');
  return $def if $def;
  no strict 'refs';
  for my $SUPER (@{(ref ($self) || $self).'::ISA'}) {
    if ($SUPER->can ('___get_rule_def')) {
      $def = $SUPER->___get_rule_def ($name);
      return $def if $def;
    }
  }  
  return undef;
}

sub new ($;%) {
  my ($class, %opt) = @_;
  my $self = bless \%opt, $class;
  if (ref $self->{rule}) {
    if (ref $self->{rule} eq 'HASH') {
      my $rules = $self->{rule};
      $self->{rule} = sub { $rules->{$_[1]} };
    }
  } else {
    $self->{rule} = sub { $_[0]->___get_rule_def ($_[1]) };
  }
  $self;
}

{
our $__QuoteBlockContent;
$__QuoteBlockContent = qr/(?>[^{}]*)(?>(?>[^{}]+|{(??{$__QuoteBlockContent})})*)/;
our $Token ||= qr/[\w_.+-]+/;
my $WordM = qr(
                          ($Token)                    ## Bare
                       | {($__QuoteBlockContent)}     ## {Quoted}
                       | "([^"\\]*(?>[^"\\]+|\\.)*)"  ## "Quoted"
)x;

sub replace_option () {+{}}

sub replace ($$;%) {
  my ($self, $format) = (shift, shift);
  my (%opt) = (%{$self->replace_option}, @_);
  my $defrule = $self->{rule}->($self, '-default');
  my $textrule = $self->{rule}->($self, '-bare_text');
  my $entirerule = $self->{rule}->($self, '-entire');
  local $opt{param}->{-formatter};
  local $opt{param}->{-result};
  ($entirerule->{pre}||=$defrule->{pre})->($self, '-entire',
                                          $opt{param}, $opt{param},
                                          option => \%opt);
  pos ($format) = 0;
  while (pos ($format) < length ($format)) {
    if ($format =~ /\G%([\w-]+)\s*/gc) { # ":" is reserved for QName
      my $name = $1;
      $name =~ tr/-/_/;
      my $rule = $self->{rule}->($self, $name)
              || $self->{rule}->($self, '-undef');
      my %attr;
      ($rule->{pre}||=$defrule->{pre})->($self, $name, \%attr, $opt{param},
                                         option => \%opt);
      $format =~ /\G\s+/gc;
      
      if ($format =~ /\G\(\s*/gc) {
        while (1) {
          if ($format =~ /\G$WordM\s*/gco) {
            my $attr_name = $+;
            $attr_name =~ s/\\(.)/$1/gs if defined $3; # "quoted"
            $attr_name =~ tr/-/_/;
            my $nflag;
            $nflag = $1 if $format =~ /\G($Token)\s*/goc;
            if ($format =~ /\G=>\s*$WordM\s*/gco) {
              my $attr_val = $+;
              $attr_val =~ s/\\(.)/$1/gs if defined $3; # "quoted"
              my $vflag;
              $vflag = $1 if $format =~ /\G(\w+)\s*/gc;
              ($rule->{attr}||=$defrule->{attr})->($self, $name,
                                                  \%attr, $opt{param},
                                                  $attr_name => $attr_val,
                                                  -name_flag => $nflag,
                                                  -value_flag => $vflag,
                                                  option => \%opt);
            } else {
              ($rule->{attr}||=$defrule->{attr})->($self, $name,
                                                  \%attr, $opt{param},
                                                  -boolean => $attr_name,
                                                  -name_flag => $nflag,
                                                  option => \%opt);
            }
          } # An attribute specification
          if ($format =~ /\G,\s*/gc) {
            next;
          } elsif ($format =~ /\G\)\s*/gc) {
            last;
          } else {
            throw Message::Util::Formatter::Base::error
              -type => 'ATTR_SEPARATOR_NOT_FOUND',
              context_before => (pos ($format) > 20 ?
                                 substr ($format, pos ($format) - 20, 20):
                                 substr ($format, 0, pos ($format))),
              context_after => substr ($format, pos ($format), 20),
              -object => $self, method => 'replace',
              option => \%opt;
          }
        } # Attributes
      } # Attribute specification list
      if ($format =~ /\G;/gc) {
        ($rule->{post}||=$defrule->{post})->($self, $name,
                                            \%attr,
                                            $opt{param},
                                            option => \%opt);
      } else {
        throw Message::Util::Formatter::Base::error
          -type => 'SEMICOLON_NOT_FOUND',
          context_before => (pos ($format) > 20 ?
                             substr ($format, pos ($format) - 20, 20):
                             substr ($format, 0, pos ($format))),
          context_after => substr ($format, pos ($format), 20),
          -object => $self, method => 'replace',
          option => \%opt;
      }
      ($entirerule->{attr}||=$defrule->{attr})->($self, '-entire',
                                                $opt{param}, $opt{param},
                                                $name => \%attr,
                                                option => \%opt);
    } elsif ($format =~ /\G(?>[^%]+|%(?![\w-]))+/gc) {
      my %attr;
      ($textrule->{pre}||=$defrule->{pre})->($self, '-bare_text',
                                            \%attr, $opt{param},
                                            option => \%opt);
      ($textrule->{attr}||=$defrule->{attr})->($self, '-bare_text',
                                              \%attr, $opt{param},
                       -bare_text => substr ($format, $-[0], $+[0]-$-[0]),
                                              option => \%opt);
      ($textrule->{post}||=$defrule->{post})->($self, '-bare_text',
                                              \%attr, $opt{param},
                                              option => \%opt);
      ($entirerule->{attr}||=$defrule->{attr})->($self, '-entire',
                                                $opt{param}, $opt{param},
                                                -bare_text => \%attr,
                                                option => \%opt);
    }
  }
  ($entirerule->{post}||=$defrule->{post})->($self, '-entire',
                                            $opt{param}, $opt{param},
                                            option => \%opt);
  return $opt{param}->{-result} if defined wantarray;
}
}

sub call ($$;@) {
  my ($self, $name, $function) = (@_[0,1,2]);
  ( ($self->{rule}->($self, $name) or $self->{rule}->($self, '-undef') )
    ->{$function}
  or $self->{rule}->($self, '-default')->{$function})
  ->($self, $name, @_[3..$#_]);
}

package Message::Util::Formatter::error;
require Message::Util::Error;
push our @ISA, 'Message::Util::Error';

package Message::Util::Formatter::Base::error;
push our @ISA, 'Message::Util::Formatter::error';
sub ___error_def () {+{
  ATTR_SEPARATOR_NOT_FOUND => {
    -description => q[Separator ("," or ")") expected at "%t(name=>context-before);"**here**"%t(name=>context-after);"],  
  },
  SEMICOLON_NOT_FOUND => {
    -description => q(Semicolon (";") expected at "%t(name=>context-before);"**here**"%t(name=>context-after);"),
  },
}}

=head1 LICENSE

Copyright 2003, 2007 Wakaba <wakaba@suikawiki.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2007/09/21 08:11:37 $
