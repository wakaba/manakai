use strict;
use warnings;
use JSPL;
use lib qw[lib];

my $js = JSPL->stock_context;
$js->set_version ('1.8');
warn $js->get_version;
$js->{ConvertRegExp} = 0;
$js->{AutoTie} = 0;
$js->{RaiseExceptions} = 01;
$js->bind_class (
  name => 'MyPerlClass',
  constructor => sub {
    warn "Constructed";
    return bless {}, 'MyPerlClass::impl';
  },
  package => 'MyPerlClass::impl::class',
  properties => {
    prop => {
      getter => sub { warn "getter " . ref $_[0]; return $_[0]->{prop} },
      setter => sub { warn "setter " . ref $_[0]; $_[0]->{prop} = $_[1] },
    },
  },
  methods => {
    toStringX => sub {
      return "Prop: " . shift->{prop};
    },
  },
  static_methods => {
    foo => sub {
      warn "foo";
    },
  },
);

$js->bind_class (
  name => 'DOMImplementation',
  constructor => sub {
    require Message::DOM::DOMImplementation;
    return Message::DOM::DOMImplementation->new;
  },
  methods => {
    createDocument => \&Message::DOM::DOMImplementation::create_document,
    createDocumentType => \&Message::DOM::DOMImplementation::create_document_type,
  },
);
sub read_only_attr ($) {
  my $method = $_[0];
  return {getter => sub {
    warn "$_[0]'s $method";
    return $_[0]->$method;
  }};
}
$js->bind_class (
  name => 'Document',
  package => 'Message::DOM::Document',
  methods => {
    
  },
  properties => {
    nodeType => read_only_attr ('node_type'),
    localName => read_only_attr ('local_name'),
  },
);

sub MyPerlClass::impl::method1 { warn "method1" }

my $ctl = $js->get_controller;
$ctl->install ('Foo' => 'FooBar');
my $return = eval { $js->eval (q{
  var dom = new DOMImplementation;
  var doc = dom.createDocument ();
  doc[-1];
}) };

use Data::Dumper;
warn "\$\@: " . Dumper $@;
warn $@ . '';

warn "Return: " . Dumper $return;
warn $return . '';
#warn Dumper $return->[-2];
#warn Dumper $return->[-2]->FETCH ('__proto__');

package FooBar;

sub FOO () { 4 }

sub new {
  return bless {value => $_[1], abc => 124}, $_[0];
}

sub toString {
  return $_[0]->{value} * 2;
}

sub baz {
  warn "baz";
}
