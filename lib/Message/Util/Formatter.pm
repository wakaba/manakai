
=head1 NAME

Message::Util::Formatter --- Manakai: General format text to composed text converter

=head1 DESCRIPTION

This module can be used to convert small template text to
complted one with filling variables with embeded formatting
text.  It is similar to C<printf>, but syntax is different.

Formatting rule is extensible.  Application program can
define its local formatting rule by only writing simple
perl code.

This module requires L<Message::Util::Formatter>.

This module is part of Manakai.

=cut

package Message::Util::Formatter;
use strict;
use vars qw(%FMT2STR $VERSION);
$VERSION=do{my @r=(q$Revision: 1.12 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;

=head1 INITIAL FORMATTING RULES

For convinience, some formatting rules are already defined.
These are only examples and you can override these rule in
your script.

=over 4

=cut

#=item %char(ucs=>0xHHHH);
#
#Replaced to a character with given perl's internal representation.
#With pre-utfized perl (before 5.6), 0x00-0xFF can be specified.
#
#Code position value in coding system other than perl internal is
#currently not supported.

## %char; is commented out in default, because of unsecureness.

=item %percent;

Represents C<%> itself.  Note that in Message::Util::Formatter's
format rule, not all bare C<%> are required to be escaped, but
only unambigious ones are.

Example:

  qq(%percent;hash; %another_hash)

=item -bare_text

This rule is special and is not able to be embeded in template text.
This rule is used to "format" bare text (ie. out-of-%-format).

You can override this rule, for example, to escape C<&> and other
special letters in (to-be-) fragment of HTML document.

=back

=cut

## Initial formatting rules
%FMT2STR = (
#	char	=> sub {
#	  my $p = $_[0];
#	  if ($p->{ucs} =~ /^0[xob][0-9A-Fa-f]+$/) {
#	    return pack 'U', oct $p->{ucs};
#	  } elsif (defined $p->{ucs}) {
#	    return pack 'U', $p->{ucs};
#	  } else {
#	    return "\x{FFFD}";
#	  }
#	},
	percent	=> '%',
	    -bare_text => sub { $_[0]->{-bare_text} },
);

=head1 METHODS

=over 4

=item $fmt = Message::Util::Formatter->new

Returns new instance of Message::Util::Formatter.

=cut

sub new ($) {
  my $self = bless Message::Util::make_clone (\%FMT2STR), shift;
  $self->{-option}->{return_class} ||= 'Message::Util::Formatter::returned';
  $self;
}

=item $replaced_text = $fmt->replace ($source_text, [$parameter])

Replaces $source_text with given (= $fmt) format rules
and returns as $replaced_text.

An optional argument $parameter is passed to format rules
as the second argument of those.  (Its type is usually, but not limited
to hash reference. C<replace> method itself does not check this
value so you can give any data.)

=cut

sub replace ($$;$$) {
  my ($self, $format, $gparam, $option) = @_;
  my $R = $self->{-option}->{return_class}->new (type => '#fragment');
  $format = $format->inner_text if ref ($format) && ref ($format) eq $self->{-option}->{return_class};
  use re 'eval';
  our $BLOCK = qr/\{(?:[^\{\}]|(??{$BLOCK}))*\}/;
                                        #[\x09\x0A\x0D\x200-9A-Za-z._=>,-]
  $format =~ s{%([A-Za-z0-9_-]+)(?:\(((?:[^{}"()]|$BLOCK|"(?:[^"\\]|\\.)*")*)\))?;|(%|[^%]+)}{
      my ($f, $a, $t) = ($1, $2, $3);
      $f =~ tr/-/_/;
      $f = '-bare_text' if length $t;
      my $function = $gparam->{fmt2str}->{$f} || $self->{$f};
      if (ref $function) {
	  my %a = (-bare_text => ($a || $t), -rule_name => $f);
	  $a =~ s(((?:[^",\{\}]|$BLOCK|"(?:[^"\\]|\\.)*")+)){
	      my $s = $1; $s =~ s/^[\x09\x0A\x0D\x20]+//; $s =~ s/[\x09\x0A\x0D\x20]+$//;
	      if ($s =~ /^([^=]*[^\x09\x0A\x0D\x20=])[\x09\x0A\x0D\x20]*=>[\x09\x0A\x0D\x20]*([^\x09\x0A\x0D\x20].*)$/s) {
	        my ($n, $v) = ($1, $2);
	        $n =~ tr/-/_/;
	          $n = Message::Util::Wide::unquote_if_quoted_string ($n);
	          if ($v =~ /^\{((?:[^\{\}]|(??{$BLOCK}))*)\}([a-z]*)$/s) {
	            $v = $1;
	            my $p = $2;
	            if (index ($p, 'p') > -1 && ref $option->{formatter}) {
	              $v = $option->{formatter}->replace ($v, 
	                ($option->{formatter_o} || $gparam),
	                ($option->{formatter_option} || {formatter => $option->{formatter}})
	              );
	              $v->flag (parsed => 1);
	            }
	          } elsif ($v =~ /^"((?:[^"\\]|\\.)+)"([a-z]*)$/s) {
	            $v = $1;
	            my $p = $2;
	            $v =~ s/\\(.)/$1/g;
	            if (index ($p, 'p') > -1 && ref $option->{formatter}) {
	              my $f = (index ($p, 's') > -1 && $option->{formatter_s})
	                      ? $option->{formatter_s} : $option->{formatter};
	              $v = $f->replace ($v, ($option->{formatter_o} || $gparam), ($option->{formatter_option} || {formatter => $f}));
	              $v->flag (parsed => 1);
	            }
	            $a{-option}->{$n} = $p;
	          }
	          $a{ $n } = $v;
	      } else {
	          $s =~ tr/-/_/;
		  $a{ Message::Util::Wide::unquote_if_quoted_string ($s) } = 1;
	      }
	    '';
	  }ges;
	  my $r = &$function (\%a, $gparam);
	  if (ref $r) {
	    if ($r->node_type ne '#fragment' || $r->count) {
	      $R->append_text ($a{prefix}) if length $a{prefix};
	      $R->append_node ($r);
	      $R->append_text ($a{suffix}) if length $a{suffix};
	    }
	  } elsif (length $r) {
	    $R->append_text ($a{prefix}) if length $a{prefix};
	    $R->append_baretext ($r);
	    $R->append_text ($a{suffix}) if length $a{suffix};
	  }
	  #$r;
	  '';
      } elsif (length $function) {
	  $R->append_text ($function);
	  #$function;
	  '';
      } else {
	  $R->append_text (qq([$f: undef]));
	  #qq([$f: undef]);
	  '';
      }
  }gesx;  
  #$format;
  $R;
}

sub option ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{-option}->{$name} = $value;
  }
  $self->{-option}->{$name};
}

package Message::Util::Formatter::returned;
our $VERSION = $Message::Util::Formatter::VERSION;
use overload '""' => \&stringify,
             fallback => 1;

sub new ($;%) {
  my $self = bless {
  	node	=> [],
  	type	=> '#fragment',
  }, shift;
  my %o = @_;
  $self->{value} = $o{value};
  $self;
}
sub append_node ($$) {
  my ($self, $node) = @_;
  if (ref $node && $node->{type}) {
    push @{$self->{node}}, $node;
    $node->{parent} = $self;
    $node;
  } else {
    undef;
  }
}
sub append_text ($$) {
  my ($self, $s) = @_;
  my $node = __PACKAGE__->new (value => $s);
  $node->{type} = '#text';
  push @{$self->{node}}, $node;
  $node->{parent} = $self;
  $node;
}
sub node_type ($) { shift->{type} }
sub inner_text ($) {
  my $self = shift;
  my $r = $self->{value};
  for (@{$self->{node}}) {
    $r .= $_->inner_text;
  }
  $r;
}
{no warnings;
  *stringify = \&inner_text;
  *append_baretext = \&append_text;
}
sub flag ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  $self->{flag}->{$name};
}
sub count ($;%) {
  my $self = shift;
  (defined $self->{value} ? 1 : 0) + scalar @{$self->{node}};
}

=back

=head1 EXAMPLE

  require Message::Util::Formatter;
  my $fmt = new Message::Util::Formatter;
  $fmt->{rule1} = sub {
      my ($attribute, $parameter) = @_;
      $parameter->{param1} = $attribute->{attr2};
      $attribute->{attr1};
  };
  
  my ($t, $param) = (q/Attr1: %rule1(attr1=>Value1,attr2=>Value2);/, {});
  print $fmt->replace ($t, $param), "\n";
  print "Attr2: ", $param->{param1}, "\n";

For more practical examples, see L<Message::Field::Date> and
SuikaWiki <http://suika.fam.cx/~wakaba/-temp/wiki/wiki?SuikaWiki>.

=head1 LICENSE

Copyright 2002-2003 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=cut

1;
# $Date: 2003/07/17 23:57:32 $
