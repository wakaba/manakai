#!/usr/bin/perl
use strict;
require Test::Simple; sub ok ($;$);
use Message::Markup::XML::XPath;
use Message::Markup::XML;

my $e = Message::Markup::XML->new (type => '#element',
	                           namespace_uri => q<http://e.test/>,
	                           local_name => 'e');

my $XPath = q"Message::Markup::XML::XPath";

my @s = (
         {
          g  => sub {
            my $x = $XPath->new (type => '#expression');
            $x->append_new_node (type => '#path')
              ->append_new_node
                (type => '#step',
                 axis => 'ancestor',
                 namespace_uri => q<http://xpath.test/>,
                 local_name => '*');
            
            ok $x->stringify eq q<ancestor::xpath.test:*>;
          },
         },
         {
          g => sub {
            my $p = $XPath->new (type => '#path');
            $p->append_new_node (type => '#step', axis => '::root');
            my $s = $p->append_new_node
              (type => '#step',
               axis => 'child',
               namespace_uri => q<http://xpath.test/>,
               local_name => 'bar');
            $p->append_new_node
              (type => '#step',
               axis => 'child',
               namespace_uri => q<http://e.test/>,
               local_name => 'ba');
            my $predict = $s->append_new_predict (type => '#expression');
            $predict->option (operator => '=');
            $predict->append_new_node (type => '#step', axis => 'attribute',
                                       local_name => 'attr');
            $predict->append_new_node (type => '#literal', value => 'foo');
            
            my $xpr = q</child::xpath.test:bar[attribute::attr = 'foo']/child::e.test:ba>;
            my $expr = $p->stringify;
            ok $expr eq $xpr, $expr;
            
            $e->{ns} = {};
            $e->define_new_namespace ('' => q<http://e.test/>);
            $e->set_attribute (expr => $p);
            my $el = $e . '';
            ok $el eq qq<<e expr="$xpr" xmlns="http://e.test/" xmlns:xpath.test="http://xpath.test/"></e>>, $el;
          },1,
         },
        );



=pod

$p->append_new_node (type => '#literal', value => q<don't>);
$p->append_new_node (type => '#literal', value => q<you said "hello!">);
		     

$p->append_new_node (type => '#literal', value => q<you said "don't worry">);
$p->append_new_node (type => '#expression')
  ->append_new_node (type => '#step', namespace_uri => 'ftp://test.example');
$p->append_new_node (type => '#number');
$p->append_new_node (type => '#number', value => '-0');
$p->append_new_node (type => '#number', value => 3.1415);
my $f = $p->append_new_node (type => '#function', local_name => 'current',
                            namespace_uri => q<urn:x-suika-fam-cx:markup:xslt:>);
$f->append_new_node (type => '#number', value => '.124');
$f->append_new_node (type => '#expression')
  ->append_new_node (type => '#step', local_name => 'foo');

$f->option (is_context_function_library => {q<urn:x-suika-fam-cx:markup:xslt:> => 1, q<urn:x-suika-fam-cx:markup:xpath:> => 1});

$p->append_new_node (type => '#function', namespace_uri => q<urn:x-suika-fam-cx:markup:xpath:>, local_name => 'node');

$f->append_new_node (type => '#function', namespace_uri => q<urn:x-suika-fam-cx:markup:xpath:>, local_name => 'lang');

my $exp2 = $x->append_new_node (type => '#expression');
$exp2->option (operator => '|');
$exp2->append_new_node (type => '#step', local_name => 'n1');
$exp2->append_new_node (type => '#step', local_name => 'n2');

my $attr = $e->set_attribute (expression => $x);

$x->stringify;

print $e;

=cut

         
Test::Simple->import (tests => scalar @s);

                              
for (@s) {
  &{$_->{g}};
}
