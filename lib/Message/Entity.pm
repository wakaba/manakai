
=head1 NAME

Message::Entity Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 C<message>.
MIME multipart will be also supported (but not implemented yet).

=cut

package Message::Entity;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Header;
require Message::Util;
use overload '""' => sub {shift->stringify};

sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{option} = {
    add_ua	=> 1,
    body_class	=> {'/DEFAULT' => 'Message::Body::TextPlain'},
    #fill_date	=> 1,
    #fill_msgid	=> 1,
    format	=> 'mail-rfc2822',
    parse_all	=> 0,
    #ua_field_name	=> 'user-agent',
    ua_use_config	=> 1,
  };
  my @new_fields = ();
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } else {
      push @new_fields, (lc $name => $options{$name});
    }
  }
  my $format = $self->{option}->{format};
  unless (defined $self->{option}->{fill_date}) {
    $self->{option}->{fill_date} = $format !~ /^cgi/;
  }
  unless (defined $self->{option}->{fill_msgid}) {
    $self->{option}->{fill_msgid} = $format !~ /^(?:cgi|http)/;
  }
  unless (defined $self->{option}->{fill_mimever}) {
    $self->{option}->{fill_mimever} = $format !~ /^(?:cgi|http)/;
  }
  unless (length $self->{option}->{ua_field_name}) {
    $self->{option}->{ua_field_name} = $format =~ /^(?:http-response|cgi)/?
      'server': 'user-agent';
  }
  @new_fields;
}

=head1 CONSTRUCTORS

The following methods construct new C<Message::Entity> objects:

=over 4

=item Message::Entity->new ([%option])

Returns new Message::Entity instance.  Some options can be
specified as hash.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my %new_field = $self->_init (@_);
  if (length $new_field{body}) {
    $self->{body} = $new_field{body};  $new_field{body} = undef;
    $self->{body} = $self->_body ($self->{body}, $self->content_type)
      if $self->{option}->{parse_all};
  }
  $self->{header} = new Message::Header -format => $self->{option}->{format},
    -parse_all => $self->{option}->{parse_all}, %new_field;
  $self;
}

=item Message::Entity->parse ($message, [%option])

Parses given C<message> and return a new Message::Entity
object.  Some options can be specified as hash.

=back

=cut

sub parse ($$;%) {
  my $class = shift;
  my $message = shift;
  my $self = bless {}, $class;
  my %new_field = $self->_init (@_);
  my @header = ();
  my @body = split /\x0D?\x0A/, $message;	## BUG: not binary-clean...
  while (1) {
    my $line = shift @body;
    unless (length($line)) {
      last;
    } else {
      push @header, $line;
    }
  }
  $new_field{body} = undef if $new_field{body};
  $self->{header} = parse_array Message::Header \@header,
    -parse_all => $self->{option}->{parse_all},
    -format => $self->{option}->{format}, %new_field;
  $self->{body} = join "\n", @body;
  $self->{body} = $self->_body ($self->{body}, $self->content_type)
    if $self->{option}->{parse_all};
  $self;
}

=head1 METHODS

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
      -parse_all => $self->{option}->{parse_all},
      -format => $self->{option}->{format});
  }
  unless ($self->{header}) {
    $self->{header} = new Message::Header (-format => $self->{option}->{format});
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
      -parse_all => $self->{option}->{parse_all});
  } else {
    return $ct->new ($body);
  }
}

=head2 $self->stringify ([%option])

Returns the C<message> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
    my ($header, $body);
    if (ref $self->{header}) {
      my %exist;
      for ($self->{header}->field_name_list) {$exist{$_} = 1}
      if ($option{fill_date} && !$exist{'date'}) {
        $self->{header}->field ('date')->unix_time (time);
      }
    if ($option{fill_msgid} && !$exist{'message-id'}) {
      my $from = $self->{header}->field ('from')->addr_spec (1);
      $self->{header}->field ('message-id')->add_new (addr_spec => $from)
        if $from;
    }
    if ($option{fill_mimever} && !$exist{'mime-version'}) {
      ## BUG: rfc1049...
      my $ismime = 0;
      for (keys %exist) {if (/^content-/) {$ismime = 1; last}}
      if ($ismime) {
        $self->{header}->add ('mime-version' => '1.0', -parse => 0);
      }
    }
    $self->_add_ua_field;
    $header = $self->{header}->stringify (-format => $option{format});
  } else {
    $header = $self->{header};
    $header =~ s/\x0D(?=[^\x09\x0A\x20])/\x0D\x20-/g;
    $header =~ s/\x0A(?=[^\x09\x20])/\x0A\x20-/g;
  }
  if (ref $self->{body}) {
    $body = $self->{body}->stringify (-format => $option{format});
  } else {
    $body = $self->{body};
  }
  $header .= "\n" if $header && $header !~ /\n$/;
  $header."\n".$body;
}
*as_string = \&stringify;

=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

sub option ($@) {
  my $self = shift;
  if (@_ == 1) {
    return $self->{option}->{ shift (@_) };
  }
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $name =~ s/^-//;
    $self->{option}->{$name} = $value;
    if ($name eq 'format') {
      $self->header->option (-format => $value);
    }
  }
}

=head2 $self->content_type ([%options])

Returns C<body>'s content-type (Internet Media Type).
This method is not implemented yet so always returns
C<text/plain>.

=cut

sub content_type ($;%) {
  my $self = shift;
  return scalar $self->{header}->field ('content-type')->media_type
    if $self->{header}->field_exist ('content-type');
  'text/plain';
}

sub id ($) {
  my $self = shift;
  return scalar $self->{header}->field ('message-id')->id
    if $self->{header}->field_exist ('message-id');
  '';
}

sub _add_ua_field ($) {
  my $self = shift;
  if ($self->{option}->{add_ua}) {
    my $ua = $self->{header}->field ($self->{option}->{ua_field_name});
    $ua->replace (name => 'Message-pm', version => $VERSION, add_prepend => -1);
    my @os;
    my @perl_comment;
    if ($self->{option}->{ua_use_config}) {
      eval q{use Config;
        @os = (name => $^O, version => $Config{osvers}, add_prepend => -1);
        push @perl_comment, $Config{archname};
      };
    } else {
      push @perl_comment, $^O;
    }
    if ($^V) {	## 5.6 or later
      $ua->replace (name => 'Perl', version => sprintf ('%vd', $^V),
                    comment => [@perl_comment], add_prepend => -1);
    } elsif ($]) {	## Before 5.005
      $ua->replace (name => 'Perl', version => $],
                    comment => [@perl_comment], add_prepend => -1);
    }
    $ua->replace (@os) if $self->{option}->{ua_use_config};
  }
  $self;
}

=head2 $self->clone ()

Returns a copy of Message::Entity object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = new Message::Entity;
  for my $name (%{$self->{option}}) {
    if (ref $self->{option}->{$name} eq 'HASH') {
      $clone->{option}->{$name} = {%{$self->{option}->{$name}}};
    } elsif (ref $self->{option}->{$name} eq 'ARRAY') {
      $clone->{option}->{$name} = [@{$self->{option}->{$name}}];
    } else {
      $clone->{option}->{$name} = $self->{option}->{$name};
    }
  }
  $clone->{header} = ref $self->{header}? $self->{header}->clone: $self->{header};
  $clone->{body} = ref $self->{body}? $self->{body}->clone: $self->{body};
  $clone;
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
$Date: 2002/04/03 13:31:36 $

=cut

1;
