#!/usr/bin/perl
use strict;
require Test::Simple; sub ok ($;$);
use Message::Markup::XML::Node;
use Message::Markup::XML::QName qw:DEFAULT_PFX UNDEF_URI NULL_URI:;
                              
sub OK ($$) {
  my ($result, $expect) = @_;
  if ($result eq $expect) {
    ok 1;
  } else {
    ok 0, $result;
  }
}

my $e = Message::Markup::XML::Node->new (type => '#element',
	                           namespace_uri => q<http://e.test/>,
	                           local_name => 'e');

my @s = (
         {
          g  => sub {
          },
          reset => 1,
          result => q<<e.test:e xmlns:e.test="http://e.test/"></e.test:e>>,
         },
         {
          g => sub {
            $e->define_new_namespace ('' => q<http://e.test/>);
          },
          reset => 1,
          result => q<<e xmlns="http://e.test/"></e>>,
         },
         {
          g => sub {
            $e->define_new_namespace (e => q<http://e.test/>);
          },
          reset => 1,
          result => q<<e:e xmlns:e="http://e.test/"></e:e>>,
         },
         {
          g  => sub {
            $e->define_new_namespace (e => q<http://f.test/>);
          },
          reset => 1,
          result => q<<e.test:e xmlns:e="http://f.test/" xmlns:e.test="http://e.test/"></e.test:e>>,
         },
         {
          g  => sub {
            $e->set_attribute (foo => 'bar', namespace_uri => q<http://a.test/>);
          },
          reset => 1,
          result => q<<e.test:e a.test:foo="bar" xmlns:a.test="http://a.test/" xmlns:e.test="http://e.test/"></e.test:e>>,
         },
        );

my @f = (
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el, q<<foo:bar xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el, q<<bar xmlns="http://foo.test/"></bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<>);
            OK $el, q<<bar xmlns=""></bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => NULL_URI);
            OK $el, q<<bar xmlns=""></bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            $el->set_attribute (foo => 'bar', 
                                namespace_uri => q<http://foo.test/>);
            OK $el, q<<foo:bar foo:foo="bar" xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => q<http://foo.test/>);
            $el->set_attribute (foo => 'bar',
                                namespace_uri => q<http://foo.test/>);
            ok ($el eq q<<bar foo.test:foo="bar" xmlns="http://foo.test/" xmlns:foo.test="http://foo.test/"></bar>>
             || $el eq q<<foo.test:bar foo.test:foo="bar" xmlns="http://foo.test/" xmlns:foo.test="http://foo.test/"></foo.test:bar>>), $el;
          },
         },

         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el->namespace_prefix, DEFAULT_PFX;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el->namespace_prefix, q:foo:;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               local_name => q<bar>,
               namespace_uri => q<http://foo.test/>);
            $el->namespace_prefix (q:foo:);
            OK $el, q<<foo:bar xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               local_name => q<bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (q:foo: => q<http://foo.test/>);
            OK $el, q<<foo:bar xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (q:bar: => q<http://bar.test/>);
            OK $el, q<<foo:bar xmlns:bar="http://bar.test/" xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (q:bar: => NULL_URI);
            OK $el, q<<foo:bar xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (DEFAULT_PFX, q<http://bar.test/>);
            OK $el, q<<foo:bar xmlns="http://bar.test/" xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (DEFAULT_PFX, NULL_URI);
            OK $el, q<<foo:bar xmlns="" xmlns:foo="http://foo.test/"></foo:bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el->defined_namespace_prefix (q:foo:), q<http://foo.test/>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>);
            OK $el->defined_namespace_prefix (DEFAULT_PFX), NULL_URI;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el->defined_namespace_prefix (DEFAULT_PFX), q<http://foo.test/>;
          },
         },

         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el->qname, q<bar>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            OK $el->qname, q<foo:bar>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => NULL_URI);
            OK $el->qname, q<bar>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (foo => q<http://bar.test/>);
            OK $el->qname, q<foo.test:bar>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<foo:bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (foo => q<http://bar.test/>);
            $el->define_new_namespace ('foo.test' => q<http://baz.test/>);
            $el->define_new_namespace (http => q<http://bar.test/>);
            OK $el->qname, q<ns0:bar>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => q<http://foo.test/>);
            $el->define_new_namespace (DEFAULT_PFX, q<http://bar.test/>);
            OK $el->qname, q<foo.test:bar>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => NULL_URI);
            $el->define_new_namespace (DEFAULT_PFX, q<http://bar.test/>);
            OK $el->qname, q<bar>;
            OK $el, q<<bar xmlns=""></bar>>;
          },
         },1,
         
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => NULL_URI);
            $el->append_new_node 
              (type => '#element',
               qname => q<baz>,
               namespace_uri => NULL_URI);
            OK $el, q<<bar xmlns=""><baz></baz></bar>>;
          },
         },
         {
          g => sub {
            my $el = Message::Markup::XML::Node->new
              (type => '#element',
               qname => q<bar>,
               namespace_uri => q<http://foo.test/>);
            $el->append_new_node
              (type => '#element',
               qname => q<baz>,
               namespace_uri => q<http://foo.test/>);
            OK $el, q<<bar xmlns="http://foo.test/"><baz></baz></bar>>;
          },
         },
);

Test::Simple->import (tests => scalar @s
                             + scalar @f);
                              
for (@s) {
  if (ref $_) {
    $e->{ns} = {} if $_->{reset};
    $e->{node} = [] if $_->{reset};
    &{$_->{g}};
    my $result = $e . '';
    ok $result eq $_->{result}, $result ne $_->{result} ? $result : undef;
  }
}

                              
for (@f) {
  &{$_->{g}} if ref;
}
