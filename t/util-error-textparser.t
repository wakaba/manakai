use strict;

require Test::Simple;
my $case = 0;

require Message::Util::Error::TextParser;
my $err;

my @test = (
  sub {
    $err = new Message::Util::Error::TextParser ({
      ERR_1 => {
        level => 'fatal',
        description => 'error 1',
      },                           
      ERR_2 => {
        level => 'normal',
        description => 'error 2',
      },                       
    });
    ok (1);
  },
  sub {
    ok (!eval q{$err->raise (type => 'ERR_1'); 'success'});
  },
  sub {
    ok (eval q{$err->raise (type => 'ERR_2'); 'success'});
  },
  sub {
    $err->{-error_handler} = sub {
      my ($self, $err_type, $err_msg, $err) = @_;
      if ($err_type->{level} eq 'fatal') {
        die $err_msg;
      } else {
        warn $err_msg;
      }
      return 0;
    },
    ok (1);
  },
  sub {
    ok (!eval q{$err->raise (type => 'ERR_1'); 'success'});
  },
  sub {
    ok (eval q{$err->raise (type => 'ERR_2'); 'success'});
  },
  sub {
    $err->{-error_handler} = sub {
      my ($self, $err_type, $err_msg, $err) = @_;
      die $err->{position_msg},keys %$err;
    },
    ok (1);
  },
  sub {
    $err->reset_position (1);
    eval q{$err->raise (type => 'ERR_1', position => 1)};
    ok ($@ =~ /Line 0 position 0/);
  },
  sub {
    $err->reset_position (1);
    $err->count_position (1, '01234567890123456');
    eval q{$err->raise (type => 'ERR_1', position => 1)};
    ok ($@ =~ /Line 0 position 17/);
  },          
  sub {
    $err->reset_position (1);
    $err->count_position (1, qq'0123456789\n0123456');
    eval q{$err->raise (type => 'ERR_1', position => 1)};
    ok ($@ =~ /Line 1 position 7/);
  },
  sub {
    $err->reset_position (1);
    $err->count_position (1, qq'0123456789\n0123456');
    $err->count_position (1, qq'0123456789\n0123456');
    eval q{$err->raise (type => 'ERR_1', position => 1)};
    ok ($@ =~ /Line 2 position 7/);
  },          
  sub {
    $err->reset_position (1);
    $err->reset_position (2);
    $err->count_position (1, qq'0123456789\n01234');
    $err->count_position (2, qq'0123456789\n0123456');
    eval q{$err->raise (type => 'ERR_1', position => 1)};
    ok ($@ =~ /Line 1 position 5/);
  },
  sub {
    $err->reset_position (1);
    $err->count_position (1, qq'0123456789\n01234');
    $err->reset_position (1);
    $err->count_position (1, qq'0123456789\n0123456');
    eval q{$err->raise (type => 'ERR_1', position => 1)};
    ok ($@ =~ /Line 1 position 7/);
  },
);
$case += @test;
$case += @test;

Test::Simple->import (tests => $case);

for (1,2) {
for (@test) {&$_}
}


=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/10/31 08:39:27 $
