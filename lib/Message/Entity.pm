
=head1 NAME

Message::Entity Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 C<message>.
MIME multipart will be also supported (but not implemented yet).

=cut

package Message::Entity;
use strict;
use vars qw($VERSION %DEFAULT);
$VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

use Message::Header;
use overload '""' => sub {shift->stringify};

%DEFAULT = (
  add_ua	=> 1,
  body_class	=> {'/DEFAULT' => 'Message::Body::TextPlain'},
  fill_date	=> 1,
  fill_msgid	=> 1,
  parse_all	=> -1,
  ua_field_name	=> 'user-agent',
  ua_use_config	=> 1,
);

=head2 Message::Entity->new ([%option])

Returns new Message::Entity instance.  Some options can be
specified as hash.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->{header} = new Message::Header;
  #$self->_add_ua_field;
  $self;
}

=head2 Message::Entity->parse ($message, [%option])

Parses given C<message> and return a new Message::Entity
object.  Some options can be specified as hash.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $message = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  my ($isheader, @header, @body) = 1;
  for my $line (split /\x0D?\x0A/, $message) {
    if ($isheader && !length($line)) {
      $isheader = 0;
    } elsif ($isheader) {
      push @header, $line
    } else {
      push @body, $line;
    }
  }
  $self->{header} = Message::Header->parse (join ("\n", @header),
    parse_all => $self->{option}->{parse_all});
  $self->{body} = join "\n", @body;
  $self->{body} = $self->_body ($self->{body}, $self->content_type)
    if $self->{option}->{parse_all}>0;
  #$self->_add_ua_field;
  $self;
}

=head2 $self->header ([$new_header])

Returns Message::Header unless $new_header.
Set $new_header instead of current C<header>.
If !ref $new_header, Message::Header->parse is automatically
called.

=cut

sub header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{header} = $new_header;
  } elsif ($new_header) {
    $self->{header} = Message::Header->parse ($new_header,
      parse_all => $self->{option}->{parse_all});
  }
  unless ($self->{header}) {
    $self->{header} = new Message::Header ();
  }
  $self->{header};
}

=head2 $self->body ([$new_body])

Returns C<body> as string unless $new_body.
Set $new_body instead of current C<body>.

=cut

sub body ($;$) {
  my $self = shift;
  my $new_body = shift;
  if ($new_body) {
    $self->{body} = $new_body;
  }
  $self->{body} = $self->_body ($self->{body}, $self->content_type)
    unless ref $self->{body};
  $self->{body};
}

sub _body ($;$$) {
  my $self = shift;
  my $body = shift;
  my $ct = shift;
  $ct = $self->{option}->{body_class}->{$ct}
     || $self->{option}->{body_class}->{'/DEFAULT'};
  eval "require $ct";
  if (ref $body) {
    return $body;
  } elsif ($body) {
    return $ct->parse ($body,
      parse_all => $self->{option}->{parse_all});
  } else {
    return $ct->new ($body);
  }
}

=head2 $self->stringify ([%option])

Returns the C<message> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %OPT = @_;
  if (($OPT{fill_date} || $self->{option}->{fill_date})>0
    && !$self->{header}->field_exist ('date')) {
    $self->{header}->field ('date')->unix_time (time);
  }
  if (($OPT{fill_msgid} || $self->{option}->{fill_msgid})>0
    && !$self->{header}->field_exist ('message-id')) {
    my $from = $self->{header}->field ('from')->addr_spec (0);
    $self->{header}->field ('message-id')->add_new (addr_spec => $from)
      if $from;
  }
  $self->_add_ua_field;
  my ($header, $body) = ($self->{header}, $self->{body});
  $header .= "\n" if $header && $header !~ /\n$/;
  $header."\n".$body;
}
sub as_string ($;%) {shift->stringify}

=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

sub option ($$;$) {
  my $self = shift;
  my ($name, $newval) = @_;
  if ($newval) {
    $self->{option}->{$name} = $newval;
  }
  $self->{option}->{$name};
}

=head2 $self->content_type ([%options])

Returns C<body>'s content-type (Internet Media Type).
This method is not implemented yet so always returns
C<text/plain>.

=cut

sub content_type ($;%) {
  'text/plain';
}

sub id ($) {
  my $self = shift;
  return scalar $self->{header}->field ('message-id')->id
    if $self->{header}->field_exist ('message-id');
  '';0
}

sub _add_ua_field ($) {
  my $self = shift;
  if ($self->{option}->{add_ua}>0) {
    my $ua = $self->{header}->field ($self->{option}->{ua_field_name});
    $ua->replace (name => 'Message-pm', version => $VERSION, add_prepend => -1);
    my @os;
    my @perl_comment;
    if ($self->{option}->{ua_use_config}>0) {
      eval q{use Config;
        @os = (name => $^O, version => $Config{osvers}, add_prepend => -1);
        push @perl_comment, $Config{archname};
      };
    } else {
      push @perl_comment, $^O;
    }
    if ($^V) {	## 5.6 or later
      $ua->replace (name => 'Perl', version => sprintf ('%vd', $^V,
        add_prepend => -1),
                    comment => [@perl_comment]);
    } elsif ($]) {	## Before 5.005
      $ua->replace (name => 'Perl', version => $],
                    comment => [@perl_comment], add_prepend => -1);
    }
    $ua->replace (@os) if $self->{option}->{ua_use_config}>0;
  }
  $self;
}


=head1 EXAMPLE

  use Message::Entity;
  my $msg = new Message::Entity;
  $msg->header ($header);
  $msg->body ($body);
  print $msg;

=head1 SEE ALSO

Message::* Perl modules
<http://suika.fam.cx/~wakaba/Message-pm/>

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
$Date: 2002/03/26 05:41:16 $

=cut

1;
