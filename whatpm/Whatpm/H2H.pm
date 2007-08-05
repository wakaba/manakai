package Whatpm::H2H;
use strict;

sub H2H_NS () { q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup/H2H/> }
sub HTML_NS () { q<http://www.w3.org/1999/xhtml> }
sub HTML3_NS () { q<urn:x-suika-fam-cx:markup:ietf:html:3:draft:00:> }
sub SW09_NS () { q<urn:x-suika-fam-cx:markup:suikawiki:0:9:> }
sub XHTML2_NS () { q<http://www.w3.org/2002/06/xhtml2/> }

sub parse_string ($$$) {
  my $self = bless {
    token => [],
    location => {},
    doc => $_[2],
  }, $_[0];
  
  my $s = ''.$_[1];
  $s =~ s/\x0D\x0A/\x0A/g;
  $s =~ tr/\x0D/\x0A/;
  $self->{line} = [split /\x0A/, $s];

  local $Error::Depth = $Error::Depth + 1;
  $self->{doc}->strict_error_checking (0);
  my $doc_el = $self->{doc}->create_element_ns (HTML_NS, 'html');
  $doc_el->set_attribute_ns (q<http://www.w3.org/2000/xmlns/>, 'xmlns', HTML_NS);
  $self->{doc}->append_child ($doc_el);

  $self->_construct_tree;

  return $self->{doc};
} # parse_string

sub _shift_token ($) {
  my $self = $_[0];

  if (@{$self->{token}}) {
    return shift @{$self->{token}};
  }

  my $attrvalue = sub {
    my $v = shift;
    $v =~ s/&quot;/"/g;
    $v =~ s/&lt;/</g;
    $v =~ s/&gt;/>/g;
    $v =~ s/&reg;/\x{00AE}/g;
    $v =~ s/&hearts;/\x{2661}/g;
    $v =~ s/&amp;/&/g;
    return $v;
  };

  my $uriv = sub {
    my $v = $attrvalue->(shift);
    $v =~ s/^\{/(/;
    $v =~ s/\}$/)/;
    $v =~ s/^\#([0-9si]+)$/($1)/;
    $v =~ s/^\(([0-9]{4})([0-9]{2})([0-9]{2})([^)]*)\)$/($1, $2, $3$4)/;
    $v =~ s/[si]/, /g if $v =~ /^\(/ and $v =~ /\)$/;
    return $v;
  };

  my $r = {type => '#EOF'};
  L: while (defined (my $line = shift @{$self->{line}})) {
    if ($line =~ s/^([A-Z]+|T[0-9])(\*?\+?\*?)(?:\s+|$)//) {
      my $command = $1;
      my $flag = $2;
      $r = {type => 'start', value => $command};

      my $uri;
      if ($flag =~ /\*/ and $line =~ s/^([^{\s]\S*)\s*//) {
        $uri = $1;
      }

      my $attr = '';
      if ($line =~ s/^\{(\s*(?:[A-Za-z][^{}]*)?)\}\s*//) {
        $attr = $1;
      }

      if (not defined $uri and
          $flag =~ /\*/ and $line =~ s/^([^{\s]\S*)\s*//) {
        $uri = $1;
      }

      my @token;
      my $info = {
                # val# val#(*)
                ABBR => [2, 2],
                ACRONYM => [2, 2],
                CITE => [2, 1],
                LDIARY => [4, 4],
                LIMG => [4, 4],
                LINK => [2, 1],
                LMG => [2, 2],
                LNEW => [2, 2],
                PERSON => [2, 2],
                RIBU => [2, 2],
                RUBY => [2, 2],
                SEE => [2, 2],
      }->{$command};
      my @value = split /\s+/, $line,
          ($flag =~ /\*/ ? $info->[1] : $info->[0]) || 1;

      push @token, {type => 'uri', value => $uriv->($uri)} if defined $uri;

      my %attr;
      while ($attr =~ /([A-Za-z0-9_-]+)\s*(?:=>?|:)\s*([^";,]+|"[^"]+")/gc) {
        my $name = lc $1;
        my $value = $2;
        $value =~ tr/"//d;
        $attr{$name} = $value;
      }
      delete $attr{'content-type'};

      if ({
           ABBR => 1, ACRONYM => 1,
           RUBY => 1, RIBU => 1,
          }->{$command}) {
        if (@value == 1 and $attr{title}) {
          push @value, $attr{title};
          delete $attr{title};
        }
        if (@value == 2) {
          unshift @{$self->{line}},
            'RB',
              'DATA {} >>'.$value[1],
            '/RB',
            'RT',
              'DATA {} >>'.$value[0],
            '/RT',
          '/'.$command;
        } else {
          unshift @{$self->{line}}, 'DATA {} >>'.$value[0], '/'.$command;
        }
      } elsif ($command eq 'CITE') {
        if (@value == 2) {
          if (defined $uri or $value[0] !~ /^[a-z-]+:/) {
            unshift @{$self->{line}},
              'SRC',
                'DATA {} >>'.$value[0].' '.$value[1],
              '/SRC', 'BODYTEXT';
          } else {
            push @token, {type => 'uri', value => $uriv->($value[0])};
            unshift @{$self->{line}},
              'SRC',
                'DATA {} >>'.$value[1],
              '/SRC', 'BODYTEXT';
          }
        } elsif (@value == 1) {
          if (defined $uri or $value[0] !~ /^[a-z-]+:/) {
            unshift @{$self->{line}},
              'SRC',
                'DATA {} >>'.$value[0],
              '/SRC', 'BODYTEXT';
          } else {
            push @token, {type => 'uri', value => $uriv->($value[0])};
            unshift @{$self->{line}}, 'BODYTEXT';
          }
        } else {
          unshift @{$self->{line}}, 'BODYTEXT';
        }
      } elsif ($command eq 'DATA') {
        my @token;
        $line =~ s/^>>//;
        while (length $line) {
          if ($line =~ s/^<([a-z0-9]+)\s*//) {
            my $tagname = $1;
            push @token, {type => 'start', value => $tagname};
            while ($line =~ s/^([a-z-]+)\s*=\s*"([^"]*)"\s*//) {
              push @token, {type => $1, value => $attrvalue->($2)};
            }
            $line =~ s#^/?\s*>##;
            push @token, {type => 'end', value => $tagname}
                if $tagname eq 'img' or $tagname eq 'input' or
                    $tagname eq 'br';
          } elsif ($line =~ s#^</([a-z0-9]+)\s*>##) {
            push @token, {type => 'end', value => $1};
          } elsif ($line =~ s/^<!--(.*?)-->//) {
            push @token, {type => 'html-comment', value => $1};
          } elsif ($line =~ s/^&([a-z]+);//) {
            my $name = $1;
            if ($name eq 'amp') {
              push @token, {type => 'text', value => '&'};
            } elsif ($name eq 'lt') {
              push @token, {type => 'text', value => '<'};
            } elsif ($name eq 'gt') {
              push @token, {type => 'text', value => '>'};
            } elsif ($name eq 'quot') {
              push @token, {type => 'text', value => '"'};
            } elsif ($name eq 'reg') {
              push @token, {type => 'text', value => "\x{00AE}"};
            } elsif ($name eq 'hearts') {
              push @token, {type => 'text', value => "\x{2661}"};
            } else {
              push @token, {type => 'char', value => $name};
            }
          } elsif ($line =~ s/^&#([0-9]+);//) {
            push @token, {type => 'text', value => ord $1};
          } elsif ($line =~ s/^&#x([0-9A-Fa-f]+);//) {
            push @token, {type => 'text', value => ord hex $1};
          } elsif ($line =~ s/^([^<&]+)//) {
            push @token, {type => 'text', value => $1};
          } else {
            push @token, {type => 'text', value => substr ($line, 0, 1)};
            substr ($line, 0, 1) = '';
          }
        }
        push @token, {type => 'eol'};

        $r = shift @token;
        push @{$self->{token}}, @token;
        last L;
      } elsif ({
                DD => 1, DT => 1,
                DEL => 1, INS => 1,
                LI => 1,
                RB => 1, RT => 1,
                STRONG => 1,
                YAMI => 1,
                EM => 1,
                HOUR => 1, KION => 1, LUNCH => 1,
                TAION => 1, TENKI => 1, THEME => 1,
                T1 => 1, T2 => 1, T3 => 1, T4 => 1,
                T5 => 1, T6 => 1, T7 => 1, SP => 1,
      }->{$command}) {
        if (@value) {
          unshift @{$self->{line}}, 'DATA {} >>'.$value[0], '/'.$command;
        }
      } elsif ($command eq 'DIV') {
        if (@value) {
          $r = {type => 'class', value => $value[0]};
        }
      } elsif ($command eq 'LDIARY') {
        $value[0] =~ s/^([0-9]{4})([0-9]{2})([0-9]{2})/$1, $2, $3/;
        $value[0] =~ s/[is]/, /;
        $r = {type => 'start', value => 'LINK'};
        push @token, {type => 'uri', value => "($value[0])"};
        unshift @{$self->{line}}, 'DATA {} >>'.$value[1], '/LINK';
      } elsif ($command eq 'LIMG') {
        $r = {type => 'start', value => 'IMG'};
        push @token, {type => 'uri', value => $uriv->($value[0])};
        unshift @{$self->{line}}, 'DATA {} >>'.$value[3], '/IMG';
      } elsif ($command eq 'LMG') {
        $r = {type => 'start', value => 'IMG'};
        push @token, {type => 'uri', value => $uriv->($value[0])};
        unshift @{$self->{line}}, 'DATA {} >>'.$value[1], '/IMG';
      } elsif ($command eq 'LINK') {
        if (@value == 2) {
          push @token, {type => 'uri', value => $uriv->($value[0])};
          unshift @{$self->{line}}, 'DATA {} >>'.$value[1], '/LINK';
        } elsif ($flag =~ /\+/) {
          push @token, {type => 'uri', value => $uriv->($value[0])};
        } else {
          unshift @{$self->{line}}, 'DATA {} >>'.$value[0], '/LINK';
        }
      } elsif ($command eq 'NEW') {
        $r = {type => 'start', value => 'SECTION'};
        unshift @{$self->{line}}, 'H', 'DATA {} >>'.$value[0], '/H';
      } elsif ($command eq 'LNEW') {
        $r = {type => 'start', value => 'SECTION'};
        push @token, {type => 'uri', value => $uriv->($value[0])};
        unshift @{$self->{line}}, 'H', 'DATA {} >>'.$value[1], '/H';
      } elsif ($command eq 'SUB') {
        $r = {type => 'start', value => 'SUB'};
        unshift @{$self->{line}}, 'H', 'DATA {} >>'.$value[0], '/H';
      } elsif ($command eq 'PERSON') {
        push @token, {type => 'key', value => $attrvalue->($value[0])};
        unshift @{$self->{line}}, 'DATA {} >>'.$value[1], '/PERSON';
      } elsif ($command eq 'SEE') {
        if (@value == 2) {
          push @token, {type => 'key', value => $attrvalue->($value[0])};
          unshift @{$self->{line}}, 'DATA {} >>'.$value[1], '/SEE';
        } else {
          unshift @{$self->{line}}, 'DATA {} >>'.$value[0], '/SEE';
        }
      } elsif ($command eq 'SPAN') {
        if (@value == 2) {
          push @token, {type => 'class',
                        value => $attrvalue->($value[0])};
          unshift @{$self->{line}}, 'DATA {} >>'.$value[1], '/SPAN';
        } else {
          unshift @{$self->{line}}, 'DATA {} >>'.$value[0], '/SPAN';
        }
      } elsif ($command eq 'OK') {
        $r = {type => '#EOF'};
        next L;
      } elsif ($command eq 'XML') {
        unshift @{$self->{line}}, 'DATA {} >>XML '.$line;
        next L;
      }
        
      for (keys %attr) {
        push @token, {type => $_, value => $attrvalue->($attr{$_})};
      }
        
      push @{$self->{token}}, @token;
      last L;
    } elsif ($line eq 'H2H/1.0') {
      $r = {type => 'magic', value => 'H2H/1.0'};
      last L;
    } elsif ($line =~ m#^/([A-Z]+)\s*$#) {
      $r = {type => 'end', value => $1};
      last L;
    } elsif ($line =~ s/^!#//) {
      $r = {type => 'hnf-comment', value => $line};
      last L;
    } elsif ($line =~ s/^!//) {
      $r = {type => 'html-comment', value => $line};
      last L;
    } else {
      unshift @{$self->{line}}, 'DATA {} >>'.$line;
      next L;
    }
  } # L

  return $r;
} # _shift_token

sub _construct_tree ($) {
  my $self = $_[0];

  my $doc_el = $self->{doc}->document_element;
  my $head_el = $self->{doc}->create_element_ns (HTML_NS, 'head');
  my $body_el = $self->{doc}->create_element_ns (HTML_NS, 'body');
  $doc_el->append_child ($head_el);
  $doc_el->append_child ($body_el);
  $doc_el->set_user_data ('command-name' => '#html');
  $head_el->set_user_data ('command-name' => '#head');
  $body_el->set_user_data ('command-name' => '#body');
  $doc_el->set_attribute_ns (SW09_NS, 'sw9:Name' => 'H2H');
  $doc_el->set_attribute_ns (SW09_NS, 'sw9:Version' => '0.9');

  my $parent = {
                subsection => $body_el,
                attr => $body_el,
                text => $body_el,
               };
  my $state = 'data';
          ## data - normal
          ## list - UL or OL
          ## br   - after br start tag token
          ## eol  - after eol token

  T: while (my $token = $self->_shift_token) {
    last T if $token->{type} eq '#EOF';
    
    if ($token->{type} eq 'text') {
      if ($state eq 'list') {
        my $li_el = $self->{doc}->create_element_ns (HTML_NS, 'li');
        $li_el->manakai_append_text ($token->{value});
        $parent->{text}->append_child ($li_el);
      } else {
        $parent->{text}->manakai_append_text ("\x0A") if $state eq 'eol';
        $parent->{text}->manakai_append_text ($token->{value});
        $state = 'data';
      }
    } elsif ($token->{type} eq 'eol') {
      if ($state eq 'eol') {
        $parent->{text}->manakai_append_text ("\x0A");
      } else {
        $state = $state eq 'br' ? 'data' : 'eol';
      }
    } elsif ($token->{type} eq 'start') {
      my $info = {
                      # nsuri, qname, parent, state
              ABBR => [HTML_NS, 'abbr', $parent->{text}, 'data'],
              ACRONYM => [HTML_NS, 'abbr', $parent->{text}, 'data'],
              BODYTEXT => [HTML3_NS, 'bodytext', $parent->{text}, 'data'],
              CITE => [HTML_NS, 'blockquote', $parent->{text}, 'data',
                       {PRE => 1}],
              DD => [HTML_NS, 'dd', $parent->{text}, 'data'],
              DEL => [HTML_NS, 'del', $parent->{text}, 'data'],
              DIV => [HTML_NS, 'div', $parent->{text}, 'data', {P => 1}],
              DL => [HTML_NS, 'dl', $parent->{text}, 'data'],
              DT => [HTML_NS, 'dt', $parent->{text}, 'data'],
              EM => [HTML_NS, 'em', $parent->{text}, 'data'],
              FN => [H2H_NS, 'fn', $parent->{text}, 'data'],
              H => [XHTML2_NS, 'h', $parent->{text}, 'data'],
              HOUR => [H2H_NS, 'hour', $head_el, 'data'],
              IMG => [HTML_NS, 'img', $parent->{text}, 'data'],
              INS => [HTML_NS, 'ins', $parent->{text}, 'data'],
              KION => [H2H_NS, 'kion', $head_el, 'data'],
              LI => [HTML_NS, 'li', $parent->{text}, 'data'],
              LINK => [HTML_NS, 'a', $parent->{text}, 'data'],
              LUNCH => [H2H_NS, 'lunch', $head_el, 'data'],
              OL => [HTML_NS, 'ol', $parent->{text}, 'list', {PRE => 1}],
              P => [HTML_NS, 'p', $parent->{text}, 'data',
                    {P => 1, PRE => 1}],
              PERSON => [HTML3_NS, 'person', $parent->{text}, 'data'],
              PRE => [HTML_NS, 'pre', $parent->{text}, 'data', 
                      {P => 1}],
              RB => [HTML_NS, 'rb', $parent->{text}, 'data'],
              RIBU => [HTML_NS, 'ruby', $parent->{text}, 'data'],
              RT => [HTML_NS, 'rt', $parent->{text}, 'data'],
              RUBY => [HTML_NS, 'ruby', $parent->{text}, 'data'],
              SECTION => [HTML_NS, 'section', $body_el, 'data'],
              SEE => [HTML_NS, 'i', $parent->{text}, 'data'],
              SP => [H2H_NS, 'sp', $head_el, 'data'],
              SPAN => [HTML_NS, 'span', $parent->{text}, 'data'],
              SRC => [HTML3_NS, 'credit', $parent->{text}, 'data'],
              STRONG => [HTML_NS, 'strong', $parent->{text}, 'data'],
              SUBSECTION => [HTML_NS, 'section', $parent->{subsection}, 'data'],
              T1 => [H2H_NS, 't1', $head_el, 'data'],
              T2 => [H2H_NS, 't2', $head_el, 'data'],
              T3 => [H2H_NS, 't3', $head_el, 'data'],
              T4 => [H2H_NS, 't4', $head_el, 'data'],
              T5 => [H2H_NS, 't5', $head_el, 'data'],
              T6 => [H2H_NS, 't6', $head_el, 'data'],
              T7 => [H2H_NS, 't7', $head_el, 'data'],
              TAION => [H2H_NS, 'taion', $head_el, 'data'],
              TENKI => [H2H_NS, 'tenki', $head_el, 'data'],
              THEME => [H2H_NS, 'theme', $head_el, 'data'],
              UL => [HTML_NS, 'ul', $parent->{text}, 'list', {PRE => 1}],
              YAMI => [H2H_NS, 'yami', $parent->{text}, 'data'],
              a => [HTML_NS, 'a', $parent->{text}, 'data'],
              abbr => [HTML_NS, 'abbr', $parent->{text}, 'data'],
              acronym => [HTML_NS, 'abbr', $parent->{text}, 'data'],
              blockquote => [HTML_NS, 'blockquote', $parent->{text}, 'data'],
              br => [HTML_NS, 'br', $parent->{text}, 'br'],
              caption => [HTML_NS, 'caption', $parent->{text}, 'data'],
              code => [HTML_NS, 'code', $parent->{text}, 'data'],
              dd => [HTML_NS, 'dd', $parent->{text}, 'data'],
              del => [HTML_NS, 'del', $parent->{text}, 'data'],
              dfn => [HTML_NS, 'dfn', $parent->{text}, 'data'],
              div => [HTML_NS, 'div', $parent->{text}, 'data'],
              dl => [HTML_NS, 'dl', $parent->{text}, 'data'],
              dt => [HTML_NS, 'dt', $parent->{text}, 'data'],
              em => [HTML_NS, 'em', $parent->{text}, 'data'],
              form => [HTML_NS, 'form', $parent->{text}, 'data'],
              h1 => [HTML_NS, 'h1', $parent->{text}, 'data'],
              h2 => [HTML_NS, 'h2', $parent->{text}, 'data'],
              h3 => [HTML_NS, 'h3', $parent->{text}, 'data'],
              h4 => [HTML_NS, 'h4', $parent->{text}, 'data'],
              img => [HTML_NS, 'img', $parent->{text}, 'data'],
              input => [HTML_NS, 'input', $parent->{text}, 'data'],
              ins => [HTML_NS, 'ins', $parent->{text}, 'data'],
              kbd => [HTML_NS, 'kbd', $parent->{text}, 'data'],
              label => [HTML_NS, 'label', $parent->{text}, 'data'],
              li => [HTML_NS, 'li', $parent->{text}, 'data'],
              ol => [HTML_NS, 'ol', $parent->{text}, 'data'],
              p => [HTML_NS, 'p', $parent->{text}, 'data'],
              pre => [HTML_NS, 'pre', $parent->{text}, 'data'],
              q => [HTML_NS, 'q', $parent->{text}, 'data'],
              rb => [HTML_NS, 'rb', $parent->{text}, 'data'],
              rp => [HTML_NS, 'rp', $parent->{text}, 'data'],
              rt => [HTML_NS, 'rt', $parent->{text}, 'data'],
              ruby => [HTML_NS, 'ruby', $parent->{text}, 'data'],
              samp => [HTML_NS, 'samp', $parent->{text}, 'data'],
              span => [HTML_NS, 'span', $parent->{text}, 'data'],
              strong => [HTML_NS, 'strong', $parent->{text}, 'data'],
              sup => [HTML_NS, 'sup', $parent->{text}, 'data'],
              table => [HTML_NS, 'table', $parent->{text}, 'data'],
              tbody => [HTML_NS, 'tbody', $parent->{text}, 'data'],
              td => [HTML_NS, 'td', $parent->{text}, 'data'],
              th => [HTML_NS, 'th', $parent->{text}, 'data'],
              thead => [HTML_NS, 'thead', $parent->{text}, 'data'],
              tr => [HTML_NS, 'tr', $parent->{text}, 'data'],
              ul => [HTML_NS, 'ul', $parent->{text}, 'data'],
              var => [HTML_NS, 'var', $parent->{text}, 'data'],
           }->{$token->{value}}
           || [H2H_NS, $token->{value}, $parent->{text}, 'data'];
      while ($info->[4]->{$info->[2]->get_user_data ('command-name')}) {
        $info->[2] = $info->[2]->parent_node;
      }
      my $el = $self->{doc}->create_element_ns ($info->[0], $info->[1]);
      $el->set_user_data ('command-name', $token->{value});
      $info->[2]->append_child ($el);
      $parent->{text} = $el;
      $parent->{attr} = $el;
      $parent->{subsection} = $el if $token->{value} eq 'SECTION';
      $state = $info->[3];
    } elsif ($token->{type} eq 'end') {
      E: while (my $et = $parent->{text}->get_user_data ('command-name')) {
        $parent->{text} = $parent->{text}->parent_node;
        last E if $et eq $token->{value};
        last E if $et eq '#body';
      }
        $parent->{attr} = $parent->{text};
        $state = {
                  UL => 'list',
                  OL => 'list',
                 }->{$parent->{text}->get_user_data ('command-name')}
                   || $state eq 'br' ? 'br' : 'data';
      } elsif ($token->{type} eq 'char') {
        my $el = $self->{doc}->create_element_ns (H2H_NS, 'char');
        $el->manakai_append_text ($token->{value});
        $parent->{text}->append_child ($el);
        $state = 'data' if $state eq 'br';
      } elsif ($token->{type} eq 'magic') {
        my ($name, $version) = split m#/#, $token->{value}, 2;
        $doc_el->set_attribute_ns (SW09_NS, 'sw9:Name', $name);
        $doc_el->set_attribute_ns (SW09_NS, 'sw9:Version', $version);
      } elsif ($token->{type} eq 'hnf-comment') {
        my $com = $self->{doc}->create_element_ns
            (H2H_NS, 'hnf-comment');
        $com->text_content ($token->{value});
        $parent->{text}->append_child ($com);
      } elsif ($token->{type} eq 'html-comment') {
        my $com = $self->{doc}->create_element_ns
            (H2H_NS, 'html-comment');
        $com->text_content ($token->{value});
        $parent->{text}->append_child ($com);
      } elsif ($token->{type} eq 'source') {
        my $src = $self->{doc}->create_element_ns (HTML3_NS, 'credit');
        $src->manakai_append_text ($token->{value});
        $parent->{text}->append_child ($src);
      } elsif ($token->{type} eq 'uri') {
        my $v = $token->{value};
        if ($v =~ /^\(([^()]+)\)$/) {
          my @v = split /\s*,\s*/, $1;
          $parent->{attr}->set_attribute_ns
              (H2H_NS, 'href-year' => $v[0]+0);
          $parent->{attr}->set_attribute_ns
              (H2H_NS, 'href-month' => $v[1]+0);
          $parent->{attr}->set_attribute_ns
              (H2H_NS, 'href-day' => $v[2]+0);
          $parent->{attr}->set_attribute_ns
              (H2H_NS, 'href-section' => $v[3]+0) if $v[3];
          $parent->{attr}->set_attribute_ns
              (H2H_NS, 'href-subsection' => $v[4]+0)
                  if $v[4];
        } else {
          my $xuri = $parent->{attr}->manakai_expanded_uri;
          if ($xuri eq HTML_NS . 'a') {
            $parent->{attr}->set_attribute_ns
                (undef, href => $token->{value});
          } elsif ($xuri eq HTML_NS . 'blockquote') {
            $parent->{attr}->set_attribute_ns
                (undef, cite => $token->{value});
          } else {
            $parent->{attr}->set_attribute_ns
                (XHTML2_NS, href => $token->{value});
          }
        }
      } elsif ({
            title => 1, style => 1,
            class => 1, href => 1, 'accept-charset' => 1,
            action => 1, method => 1, alt => 1, src => 1,
            type => 1, value => 1, name => 1, accesskey => 1,
            for => 1, cite => 1, onclick => 1, colspan => 1,
            scope => 1, summary => 1,
               }->{$token->{type}}) {
        $parent->{attr}->set_attribute_ns
            (undef, $token->{type}, $token->{value});
      } elsif ($token->{type} eq 'cat') {
        for (split /\s*,\s*/, $token->{value}) {
          my $el = $self->{doc}->create_element_ns (H2H_NS, 'cat');
          $el->manakai_append_text ($_);
          $parent->{attr}->append_child ($el);
        }
      } elsif ($token->{type} eq 'lang' or $token->{type} eq 'xml:lang') {
        $parent->{attr}->set_attribute_ns
            (q<http://www.w3.org/XML/1998/namespace>,
             'xml:lang' => $token->{value});
      } elsif ($token->{type} eq 'id') {
        $parent->{attr}->set_attribute_ns
            (q<http://www.w3.org/XML/1998/namespace>,
             'xml:id' => $token->{value});
      } elsif ($token->{type} eq 'wbradded') {
        # ignore
      } else {
        # key, level, place, position, time
        $parent->{attr}->set_attribute_ns
            (H2H_NS, $token->{type}, $token->{value});
      }
    }
} # _construct_tree

1;
## $Date: 2007/08/05 07:12:45 $
