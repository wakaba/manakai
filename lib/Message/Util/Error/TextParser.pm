
=head1 NAME

Message::Util::Error::TextParser --- manakai: Common error handler wrapper for formatted-text parser

=head1 DESCRIPTION

This module provides common error handler (error reporting wrapper
module) for formatted-text parser.  With this module, flexible error 
reporting method can be easily implemented.  In addition to the base
module of Message::Util::Error, this module implements line/position
counting method so that error occured position in the parsed plain-text
based data can be reported.

This module is part of manakai.

=cut

package Message::Util::Error::TextParser;
use base Message::Util::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

=head1 METHODS

=over 4

=item $err = Message::Util::Error::TextParser->new ({error definitions})

Constructs new error reporting object.   Hash reference to error definition list must be specified as an argument.

=cut

# Inherited

=item $err->raise (%detail)

Raises an error (or a warning, if defined so)

=cut

sub raise ($%) {
  my ($self, %err) = @_;
  if ($err{position}) {
    $err{position_data} = $self->{pos}->{$err{position}};
    $err{position_msg} = sprintf 'Line %d position %d',
      $err{position_data}->{line}, $err{position_data}->{pos};
  }
  $self->SUPER::raise (%err);
}

=item $self->count_position ($position_set, $text)

Counts lines/characters and adds to current position of C<$position_set>.

=cut

sub count_position ($$$) {
  my ($self, $set, $text) = @_;
  $text =~ s/[^\x0A\x0D]*(?:\x0D\x0A?|\x0A)/$self->{pos}->{$set}->{line}++;
                                            $self->{pos}->{$set}->{pos} = 0; 
                                            ''/ges;
  $self->{pos}->{$set}->{pos} += length $text;
}

=item $self->reset_position ($position_set)

Resets current position of C<$position_set> to "Line 0 position 0".

=cut

sub reset_position ($$) {
  my ($self, $set) = @_;
  $self->{pos}->{$set}->{line} = 0;
  $self->{pos}->{$set}->{pos} = 0;
}                 

=back

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/08/05 07:30:14 $
