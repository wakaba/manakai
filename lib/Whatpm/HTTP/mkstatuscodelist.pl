use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->parent->stringify;
use Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

local $/ = undef;
$doc->inner_html (scalar <>);

my $Predefined = {
  0 => {
    text => '',
  },
  103 => {
    text => 'Checkpoint',
    #text => Access denied while creating Web Service
  },
  104 => {
    text => 'File Format or Program Error',
  },
  122 => {
    text => 'Request-URI too long',
  },
  306 => {
    text => 'Switch Proxy',
  },
  308 => {
    text => 'Resume Incomplete',
  },
  418 => {
    text => "I'm a teapot",
  },
  419 => {
    text => 'Expectation Failed',
  },
  420 => {
    text => 'Enhance Your Calm',
    #text => 'Policy Not Fulfilled',
  },
  421 => {
    text => 'Bad Mapping',
  },
  425 => {
    text => 'Unordered Collection',
  },
  427 => {
    text => 'SOAPAction',
  },
  430 => {
    text => 'WOULD BLOCK',
  },
  444 => {
    text => 'No Response',
  },
  449 => {
    text => 'Retry With',
  },
  450 => {
    text => 'Blocked by Parental Controls',
  },
  499 => {
    text => 'Client Closed Request',
  },
  508 => {
    text => 'Cross Server Binding Forbidden',
  },
  509 => {
    text => 'Bandwidth Limit Exceeded',
  },
  598 => {
    text => 'Network read timeout error',
  },
  599 => {
    text => 'Network connect timeout error',
  },
};

my $List = {%$Predefined};

my $records = $doc->query_selector_all ('record');
for (@$records) {
  my $value = $_->get_elements_by_tag_name ('value')->[0]->text_content;
  next if $value =~ /-/;
  my $desc = $_->get_elements_by_tag_name ('description')->[0]->text_content;
  next if $desc eq 'Unassigned';
  
  if ($desc =~ /^Reserved for / and $Predefined->{$value}) {
    $List->{$value}->{reserved} = 1;
  } else {
    $List->{$value}->{registered} = 1;
    $List->{$value}->{experimental} = 1
        if $desc =~ s/\s*\(Experimental\)\s*$//g;
    $List->{$value}->{text} = $desc;
  }
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
my $text = Dumper $List;
$text =~ s/^\$VAR1/\$Whatpm::HTTP::StatusCodes/;

my $now = [gmtime];
printf qq{\$Whatpm::HTTP::_StatusCodes::VERSION = %04d%02d%02d;\n},
    $now->[5] + 1900, $now->[4] + 1, $now->[3];
print $text;

__END__

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
