
=head1 NAME

Message::Util::Error --- manakai: Common error handler wrapper

=head1 DESCRIPTION

This module provides common error handler (error reporting wrapper
module).  With this module, flexible error reporting method
can be easily implemented.

This module is part of manakai.

=cut

package Message::Util::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

=head1 METHODS

=over 4

=item $err = Message::Util::Error->new ({error definitions})

Constructs new error reporting object.   Hash reference to error definition list must be specified as an argument.

=cut

sub new ($$) {
  my $class = shift;
  my $self = bless shift, $class;
  $self->{UNKNOWN} ||= {
    description => 'Unknown error',
    level => 'fatal',
  };
  $self;
}

=item $err->raise (%detail)

Raises an error (or a warning, if defined so)

=cut

sub raise ($%) {
  my ($self, %err) = @_;
  my $error_type = $self->{$err{type}} || $self->{UNKNOWN};
  my $error_msg = ref ($error_type->{description})
    ? &{$error_type->{description}} (\%err)
    : $error_type->{description};
  my @err_msg;
  ref ($err{t}) eq 'ARRAY'
    ? @err_msg = @{$err{t}}
    : defined $err{t} ? (@err_msg = $err{t}) : undef;
  $error_msg .= ' (%s)' if scalar (@err_msg) && ($error_msg !~ /%s/);
  $error_msg = sprintf $error_msg, @err_msg;
  
  my $resolver = $self->{-error_handler};
  if (ref $resolver) {
    $resolver = &$resolver ($self, $error_type, $error_msg, \%err);
                        ## If returned false,
    $self->_default_error_handler ($error_type, $error_msg, \%err)
      if $resolver;	## don't call this.
  } else {
    $self->_default_error_handler ($error_type, $error_msg, \%err);
  }
}

sub _default_error_handler ($$$$) {
  my ($self, $error_type, $error_msg, $err) = @_;
  require Carp;
  if ({qw/fatal 1/}->{$error_type->{level}}) {
    Carp::croak ($error_msg);
  } else {
    Carp::carp ($error_msg);
  }
}

=back

=head1 EXAMPLE

  require Message::Util::Error;
  my $err = new Message::Util::Error ({
    OPEN_DB => {
      level => 'fatal',
      description => q(%s: Can't open database (%s)),
    },
    CLOSE_DB => {
      level => 'warn',
      description => q(%s: Can't close database (%s)),
    },
    UNKNOWN => {
      level => 'fatal',
      description => 'Unknown error happend',
    },
    -error_handler => sub {
      my ($self, $err_def, $err_msg, $err_argv) = @_;
      if ($err_def->{level} eq 'fatal') {
        die $err_msg;
      } else {
        warn $err_msg;
      }
    },
  );
    
  open DB, $db_name or $err->raise (type => 'OPEN_DB', t => [$db_name, $!]);

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/08/05 07:30:14 $
