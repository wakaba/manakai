#!/usr/bin/perl
use Message::Util::Formatter::Base;
use Test::Simple tests => 10;

sub OK ($$) {
  ok $_[0] eq $_[1], $_[0] eq $_[1] ? undef : qq("$_[0]" ("$_[1]" expected));
}

my $f = Message::Util::Formatter::Base->new
  (rule => {
            bar => {
                    pre => sub {
                      my ($f, $name, $p, $o) = @_;
                      $p->{-result} = '<:bar:>';
                    },
                    post => sub {
                      my ($f, $name, $p, $o) = @_;
                      $p->{-result} .= '</:bar:>';
                    },
                   },
            -default => {
                    pre => sub {
                      my ($f, $name, $p, $o) = @_;
                      $p->{-result} = "<$name>";
                    },
                    post => sub {
                      my ($f, $name, $p, $o) = @_;
                      $p->{-result} .= "</$name>";
                    },
                    attr => sub {
                      my ($f, $name, $p, $o, $key => $val, %opt) = @_;
                      $key = "$key\[$opt{-name_flag}]" if $opt{-name_flag};
                      $val = "$val\[$opt{-value_flag}]" if $opt{-value_flag};
                      $p->{-result} .= "{$key=$val}";
                    },
                   },
            -entire => {
                    pre => sub {
                      my ($f, $name, $p, $o) = @_;
                      $p->{-result} = '<<';
                    },
                    post => sub {
                      my ($f, $name, $p, $o) = @_;
                      $p->{-result} .= '>>';
                    },
                    attr => sub {
                      my ($f, $name, $p, $o, $key => $val) = @_;
                      $p->{-result} .= "[[$key:$val->{-result}]]";
                    },
                   },
           });

OK $f->replace ("foo%bar;%baz;foo&%  %  \n%% foo"), qq<<<[[-bare_text:<-bare_text>{-bare_text=foo}</-bare_text>]][[bar:<:bar:></:bar:>]][[baz:<baz></baz>]][[-bare_text:<-bare_text>{-bare_text=foo&%  %  \n%% foo}</-bare_text>]]>>>;

OK $f->replace (q(%foo({attr3}=>{value3});)),
   q<<<[[foo:<foo>{attr3=value3}</foo>]]>>>;

OK $f->replace (q(%foo(attr1=>value1,"attr2"=>"value2",{attr3}=>{value3});)),
   q<<<[[foo:<foo>{attr1=value1}{attr2=value2}{attr3=value3}</foo>]]>>>;

OK $f->replace (q(%foo(attr1,"\\\\attr\2"=>"\\\\value\2");)),
   q<<<[[foo:<foo>{-boolean=attr1}{\\attr2=\\value2}</foo>]]>>>;

OK $f->replace (q(%foo({{attr{1}}}=>{{value{1}}});)),
   q<<<[[foo:<foo>{{attr{1}}={value{1}}}</foo>]]>>>;

OK $f->replace (q(%foo 
                  ( ,  attr1  =>       value1
 ,               ,) ;)),
   q<<<[[foo:<foo>{attr1=value1}</foo>]]>>>;

OK $f->replace (q(%foo({{attr{1}}} flag =>{{value{1}}} flag);)),
   q<<<[[foo:<foo>{{attr{1}}[flag]={value{1}}[flag]}</foo>]]>>>;

use Message::Util::Error;
try {
  $f->replace (q(%invalid));
  OK 0, 1;
} catch Message::Util::Formatter::Base::error with {
  my $err = shift;
  OK $err->text, qq(Semicolon (";") expected at "%invalid"**here**"<empty>");
};

try {
  $f->replace (q(Something, Something%invalid! Syntax error! Syntax error!));
  OK 0, 2;
} catch Message::Util::Formatter::Base::error with {
  my $err = shift;
  OK $err->text, q(Semicolon (";") expected at "g, Something%invalid"**here**"! Syntax error! Synt");
};

try {
  $f->replace (q(%invalid(a=>b!);));
  OK 0, 3;
} catch Message::Util::Formatter::error with {
  my $err = shift;
  OK $err->text, q[Separator ("," or ")") expected at "%invalid(a=>b"**here**"!);"];
};
