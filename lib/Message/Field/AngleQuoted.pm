
=head1 NAME

Message::Field::AngleQuoted --- A Perl Module for Internet Message
Header Field Bodies filled with a URI

=cut

package Message::Field::AngleQuoted;
use strict;
require 5.6.0;
use re 'eval';
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

%REG = %Message::Util::REG;
	$REG{angle_qcontent} = qr/(?:$REG{quoted_string}|$REG{domain_literal}|[^\x3C\x3E\x22\x5B])+/;
	$REG{M_angle_quoted} = qr/<($REG{angle_qcontent})>|<>/;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

%DEFAULT = (
    -_MEMBERS	=> [qw|display_name keyword|],
    -_METHODS	=> [qw|display_name value
                       comment_add comment_delete comment_item
                       comment_count|],
    -allow_empty	=> 0,
    -comment_to_display_name	=> 0,
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #hook_encode_string
    #hook_decode_string
    -output_angle_bracket	=> 1,
    -output_comment	=> 1,
    -output_display_name	=> 1,
    -output_keyword	=> 0,
    #parse_all
    -unsafe_rule_of_display_name	=> 'NON_http_attribute_char_wsp',
    -unsafe_rule_of_keyword	=> 'NON_http_attribute_char_wsp',
    -use_comment	=> 1,
    -use_comment_in_angle	=> 0,
    -use_display_name	=> 1,
    -use_keyword	=> 0,
);

sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %options);
}

=item $uri = Message::Field::URI->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $uri = Message::Field::URI->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  my ($value, $dname, @comment, $keyword);
  ($body, @comment)
    = $self->Message::Util::delete_comment_to_array ($body,
      -use_angle_quoted => $self->{option}->{use_comment_in_angle}? 0: 1,
    )
    if $self->{option}->{use_comment};
  if ($body =~ /($REG{angle_qcontent})?$REG{M_angle_quoted}/) {
    ($dname, $value) = ($1, $2);
    $dname =~ s/^$REG{WSP}+//;  $dname =~ s/$REG{WSP}+$//;
    $dname = $self->Message::Util::decode_quoted_string ($dname);
  } elsif ($self->{option}->{use_keyword}
    && $body =~ /^$REG{FWS}($REG{atext_dot})$REG{FWS}$/) {
    #$keyword = Message::Util::remove_meaningless_wsp ($1);
    $keyword = $1; $keyword =~ tr/\x09\x20//d;
  } else {
    $value = $body;
  }
  $self->_save_value ($value, $dname, \@comment, keyword => $keyword);
  $self;
}

## $self->_save_value ($value, $display_name, \@comment)
sub _save_value ($$\@%) {
  my $self = shift;
  my ($v, $dn, $comment, %misc) = @_;
  $self->{comment} = $comment;
  $self->{value} = $v;
  $self->{display_name} = $dn;
  $self->{keyword} = $misc{keyword};
}

sub value ($;$%) {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{value} = $value;
  }
  $self->{value};
}

sub display_name ($;$%) {
  my $self = shift;
  my $dname = shift;
  if (defined $dname) {
    $self->{display_name} = $dname;
  }
  $self->{display_name};
}


sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my %v = $self->_stringify_value (\%option);
  my ($dn, $as, $cm) = ('', '', '');
  if (length $v{keyword}) {
    if ($option{output_keyword}) {
      my %s = &{$option{hook_encode_string}} ($self, $v{keyword}, type => 'phrase');
      $as = Message::Util::quote_unsafe_string
          ($s{value}, unsafe => $option{unsafe_rule_of_keyword});
    } else {
      $as = '('. $self->Message::Util::encode_ccontent ($v{keyword}) .')';
    }
  } else {
    if (length ($v{value}) == 0 && !$option{allow_empty}) {
      return '';
    }
    if (length $v{display_name}) {
      if ($option{use_display_name} && $option{output_display_name}) {
          my %s = &{$option{hook_encode_string}} ($self, 
              $v{display_name}, type => 'phrase');
          $dn = Message::Util::quote_unsafe_string
              ($s{value}, unsafe => $option{unsafe_rule_of_display_name}) . ' ';
      } elsif ($option{use_comment} && $option{output_comment}) {
        $dn = ' ('. $self->Message::Util::encode_ccontent ($v{display_name}) .')';
      }
    } elsif ($option{comment_to_display_name}
          && $option{use_display_name} && $option{output_display_name}) {
      my $fullname = ${$v{comment}}[0];  $option{_comment_min} = 1;
      if (length $fullname) {
        my %s = &{$option{hook_encode_string}} ($self, $fullname, type => 'phrase');
        $dn = Message::Util::quote_unsafe_string
          ($s{value}, unsafe => $option{unsafe_rule_of_display_name}) . ' ';
      }
    }
    
    if ($option{output_angle_bracket}) {
      $as = '<' . $v{value} . '>';
    } else {
      $as = $v{value};
    }
  }
  if ($option{use_comment} && $option{output_comment}) {
    $cm = $self->_comment_stringify (\%option);
    $cm = ' ' . $cm if $cm;
    if ($dn && !($option{use_display_name} && $option{output_display_name})) {
      $cm = $dn . $cm;  $dn = '';
    }
  }
  $dn . $as . $cm;
}
*as_string = \&stringify;

## $self->_stringify_value (\%option)
sub _stringify_value ($\%) {
  my $self = shift;
  my $option = shift;
  my %r;
  $r{value} = ''.$self->{value};
  $r{display_name} = $self->{display_name};
  $r{comment} = $self->{comment};
  $r{keyword} = $self->{keyword};
  %r;
}

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  eval { $self->{value}->option (%$o) if ref $self->{value} };
}

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
$Date: 2002/06/15 07:15:59 $

=cut

1;
