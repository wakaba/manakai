
=head1 NAME

Message::Field::Subject -- Perl module for Internet
message header C<Subject:> field body

=cut

package Message::Field::Subject;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.10 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, q(Message::Field::Structured);

%REG = %Message::Util::REG;
	$REG{news_control} = qr/^cmsg$REG{WSP}+/;
	$REG{prefix_fwd} = qr/(?i)Fwd?/;
	$REG{prefix_list} = qr/[(\[][A-Za-z0-9._-]+[\x20:-]\d+[)\]]/;
	$REG{M_prefix_list} = qr/[(\[]([A-Za-z0-9._-]+)[\x20:-](\d+)[)\]]/;
	$REG{M_was_subject} = qr/\([Ww][Aa][Ss][:\x09\x20]$REG{FWS}(.+?)$REG{FWS}\)$REG{FWS}$/;
	$REG{message_from_subject} = qr/^$REG{FWS}(?i)Message from \S+$REG{FWS}$/;
	if (defined $^V) {
	  $REG{prefix_re} = qr/(?i)Re|Sv|Odp
	    |\x{8FD4}	## Hen
	  /x;
	  $REG{prefix_advertisement} = qr/
	    (?i)ADV?:
	    |[!\x{FF01}] $REG{FWS} \x{5E83}[\x{543F}\x{544A}] $REG{FWS} [!\x{FF01}]
	    	## ! kou koku !
	    |[!\x{FF01}] $REG{FWS} [\x{9023}\x{F99A}]\x{7D61}\x{65B9}\x{6CD5}\x{7121}\x{3057}? $REG{FWS} [!\x{FF01}]
	    	## ! ren raku hou hou nashi !
	    |\x{672A}\x{627F}\x{8AFE}\x{5E83}[\x{543F}\x{544A}][\x{203B}\x{0FBF}]
	    	## mi shou daku kou koku *
	  /x;
	} else {
	  $REG{prefix_re} = qr/(?i)Re|Sv/;
	  $REG{prefix_advertisement} = qr/(?i)ADV?:/;
	}
	$REG{prefix_general} = qr/((?:$REG{prefix_re}|$REG{prefix_fwd})\^?[\[\(]?\d*[\]\)]?[:>]$REG{FWS})+/x;
	$REG{prefix_general_list} = qr/($REG{prefix_general}|$REG{FWS}$REG{prefix_list}$REG{FWS})+/x;

%DEFAULT = (
	-_MEMBERS	=> [qw/is list_count list_name news_control was_subject/],
	-_METHODS	=> [qw/as_plain_string is list_count list_name 
	         	       news_control was_subject value value_type/],
	#encoding_after_encode
	#encoding_before_decode
	-format_news_control	=> 'cmsg %s',
	-format_prefix_fwd	=> 'Fwd: %s',
	-format_prefix_list	=> '[%s:%05d] %s',
	-format_prefix_re	=> 'Re: %s',
	-format_was_subject	=> '%s (was: %s)',
	#field_param_name
	#field_name
	#field_ns
	#format
	#header_default_charset
	#header_default_charset_input
	#hook_encode_string
	#hook_decode_string
	-output_general_prefix	=> 1,
	-output_list_prefix	=> 0,
	-output_news_control	=> 1,
	-output_was_subject	=> 1,	## ["-"] 1*DIGIT
	#parse_all
	-parse_was_subject	=> 1,
	-use_general_prefix	=> 1,
	-use_list_prefix	=> 1,
	-use_message_from_subject	=> 0,
	-use_news_control	=> 1,
	-use_was_subject	=> 1,
	#value_type
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->SUPER::_init (%DEFAULT, %options);
  
  my $fname = $self->{option}->{field_name};
  if ($fname =~ /^x-.subject$/) {
    $self->{option}->{use_list_prefix} = 0 unless defined $options{-use_list_prefix};
    $self->{option}->{use_news_control} = 0 unless defined $options{-use_news_control};
    $self->{option}->{use_message_from_subject} = 0 unless defined $options{-use_message_from_subject};
  }
  
  #$self->{option}->{value_type}->{news_control} = ['Message::Field::UsenetControl',{}, [qw//]];
  $self->{option}->{value_type}->{was_subject} = ['Message::Field::Subject',{},
    [qw/format_news_control format_prefix_fwd format_prefix_re
    format_was_subject output_general_prefix output_list_prefix
    output_news_control output_was_subject parse_was_subject
    use_general_prefix use_list_prefix use_news_control use_was_subject/]];
}

=item $subject = Message::Field::Subject->new ([%options])

Constructs a new C<Message::Field::Subject> object.  You might pass some 
options as parameters to the constructor.

=cut

## Inherited

=item $subject = Message::Field::Subject->parse ($field-body, [%options])

Constructs a new C<Message::Field::Subject> object with
given field body.  You might pass some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  my $option = $self->{option};
  if ($option->{use_news_control} && $body =~ s/$REG{news_control}//) {
    $self->{news_control} = $body;
    return $self;
  }
  my $value = '';
    my %s = &{$self->{option}->{hook_decode_string}} ($self,
      $body,
      type => 'text',
      charset	=> $option->{encoding_before_decode},
    );
    if ($s{charset}) {	## Convertion failed
      $self->{_charset} = $s{charset};
      $self->{value} = $s{value};
      return $self;
    } elsif (!$s{success}) {
      $self->{_charset} = $self->{option}->{header_default_charset_input};
      $self->{value} = $s{value};
      return $self;
    }
    $value = $s{value};
  #if (!$option->{parse_all}) {
  #  $self->{value} = $value;
  #  return $self;
  #}
  if ($option->{use_general_prefix}) {
    if ($option->{use_list_prefix} && $value =~ s/^($REG{prefix_general_list})//x) {
      my $prefix = $1;
      $self->{is}->{reply} = 1 if $prefix =~ /$REG{prefix_re}/x;
      $self->{is}->{foward} = 1 if $prefix =~ /$REG{prefix_fwd}/x;
      ($self->{list_name}, $self->{list_count}) = ($1, $2)
        if $prefix =~ /$REG{M_prefix_list}/x;
    } elsif ($value =~ s/^($REG{prefix_general})//x) {
      my $prefix = $1;
      $self->{is}->{reply} = 1 if $prefix =~ /$REG{prefix_re}/x;
      $self->{is}->{foward} = 1 if $prefix =~ /$REG{prefix_fwd}/x;
    }
  } elsif ($option->{use_list_prefix} && $value =~ s/^$REG{FWS}$REG{M_prefix_list}(?:$REG{FWS}$REG{prefix_list})*$REG{FWS}//x) {
    ($self->{list_name}, $self->{list_count}) = ($1, $2);
  }
  if ($option->{use_was_subject} && $value =~ s/$REG{M_was_subject}//) {
    my $was = $1;
    if ($option->{parse_was_subject}) {
      my %option;
      for (keys %$option) {
        $option{ '-'.$_ } = Message::Util::make_clone ($option->{ $_ });
      }
      $self->{was_subject} = ref ($self)->parse ($was, 
        -hook_decode_string => sub { shift; (value => shift, @_) },
        %option);
    } else {
      $self->{was_subject} = $was;
    }
  }
  if ($option->{use_message_from_subject} && $value =~ s/$REG{message_from_subject}//) {
    $self->{is}->{message_from_subject} = 1;
  }
  $self->{value} = $value;
  $self;
}

=back

=head1 METHODS

=over 4

=cut

sub value ($;$) {
  my $self = shift;
  my $v = shift;
  if (defined $v) {
    $self->{value} = $v;
  }
  $self->{value};
}

sub list_name ($) { $_[0]->{list_name} }
sub list_count ($) { $_[0]->{list_count} }

=item $body = $subject->stringify

Retruns subject field body as string.  String is encoded
for message if necessary.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  if ($option{use_news_control} && $option{output_news_control}
      && $self->{news_control}) {
    my $c = $self->{news_control};
    return '' unless length $c;
    return sprintf $option{format_news_control}, $c;
  }
  if ($self->{_charset}) {
    return $self->{value};
  } else {
    my $value = $self->{value};
    if ($option{use_general_prefix} && $option{output_general_prefix}) {
      $value = sprintf $option{format_prefix_re}, $value if $self->{is}->{reply};
      $value = sprintf $option{format_prefix_fwd}, $value if $self->{is}->{foward};
    }
    if ($option{use_list_prefix} && $option{output_list_prefix}) {
      $value = sprintf $option{format_prefix_list},
        $self->{list_name}, $self->{list_count}, $value
        if length $self->{list_name} && defined $self->{list_count};
    }
    if ($option{use_was_subject} && $option{output_was_subject} > 0) {
      my $was;
      if (ref $self->{was_subject}) {
        my %opt = @_;
        $opt{-output_was_subject} = $opt{output_was_subject}
          unless defined $opt{-output_was_subject};
        $opt{-output_was_subject}--;
        $was = $self->{was_subject}->as_plain_string (%opt);
      } elsif (length $self->{was_subject}) {
        $was = $self->{was_subject};
      }
      $value = sprintf $option{format_was_subject}, $value, $was if defined $was;
    }
      my (%e) = &{$option{hook_encode_string}} ($self,
        $value,
        charset => $option{encoding_after_encode},
        current_charset => $option{internal_charset},
        type => 'text',
      );
      return $e{value};
  }
}
*as_string = \&stringify;

=item $body = $subject->as_plain_string

Returns subject field body as string.  Unlike C<stringify>,
retrun string of this method is not encoded (i.e. returned
in internal code).

=cut

sub as_plain_string ($;%) {
  my $self = shift;
  $self->stringify (
    -hook_encode_string => sub { shift; (value => shift, @_) },
    @_,
  );
}



=item $bool = $subject->is ($attribute [=> $bool])

Set/gets attribute value.

Example:

  $isreply = $subject->is ('re');
  	## Strictly, this checks whether start with "Re: " or not.

  $subject->is (foward => 1, re => 0);

=cut

sub is ($@) {
  my $self = shift;
  if (@_ == 1) {
    my $query = shift;
    if ($query eq 'advertisement') {
      return $self->{value} =~ /$REG{prefix_advertisement}/x? 1:0;
    } else {
      return $self->{is}->{ $_[0] };
    }
  }
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $self->{is}->{ $name } = $value;
  }
}

=item $old_subject = $subject->was_subject

Returns I<was: > subject.

=cut

sub was_subject ($) {
  my $self = shift;
  $self->{was_subject} = $self->_parse_all (was => $self->{was_subject})
    if $self->{option}->{parse_all};
  $self->{was_subject};
}

sub news_control ($) {
  my $self = shift;
  $self->{news_control} = $self->_parse_all (was => $self->{news_control})
    if $self->{option}->{parse_all};
  $self->{news_control};
}

=item $clone = $subject->clone ()

Returns a copy of the object.

=cut

## Inherited

=head1 LICENSE

Copyright 2002 wakaba E<lt>w@suika.fam.cxE<gt>.

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

=head1 CHANGE

See F<ChangeLog>.
$Date: 2002/08/01 09:19:46 $

=cut

1;
