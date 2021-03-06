#!/usr/bin/perl 
use strict;

my $TokenizerDebug = $ENV{TOKENIZER_DEBUG};
my $ParserDebug = $ENV{PARSER_DEBUG};

while (<>) {
  s{!!!emit\b}{
    ($TokenizerDebug ? q{
      (warn "EMIT " . (join ' ', %$_) . "\n" and
       return $_)
        for
    } : q{return })
  }e;
  s{!!!next-input-character;}{q{
    $self->_set_nc;
  }}ge;
  s{!!!nack\s*\(\s*'([^']+)'\s*\)\s*;}{
    ($TokenizerDebug ? qq{
      if (\$self->{self_closing}) {
        !!!cp ('$1.2');
      } else {
        !!!cp ('$1.3');
      }
    } : '')
  }ge;
  s{!!!ack\s*(?>\([^)]*\)\s*)?;}{q{delete $self->{self_closing};}}ge;
  s{!!!ack-later\s*(?>\([^)]*\)\s*)?;}{}ge;
  s{!!!insert-element-f\s*\(([^(),]+),([^(),]+),([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2, $3, $4);
      \$insert->(\$self, \$el, \$open_tables);
      push \@{\$self->{open_elements}}, [\$el, (\$el_category_f->{$1}->{$2} || 0) | FOREIGN_EL | (($1) eq SVG_NS ? SVG_EL : ($1) eq MML_NS ? MML_EL : 0)];

      if ($3\->{xmlns} and $3\->{xmlns}->{value} ne ($1)) {
        !!!parse-error (type => 'bad namespace', token => $4);
## TODO: Error type documentation
      }
      if ($3\->{'xmlns:xlink'} and
          $3\->{'xmlns:xlink'}->{value} ne q<http://www.w3.org/1999/xlink>) {
        !!!parse-error (type => 'bad namespace', token => $4);
      }
    }
  }}ge;
  s{!!!insert-element-t\s*\(([^(),]+),([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, HTML_NS, $1, $2, $3);
      \$insert->(\$self, \$el, \$open_tables);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),\s*,([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, HTML_NS, $1,, $2);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, HTML_NS, $1, $2, $3);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!create-element\s*\(([^(),]+),\s*([^(),]+),([^(),]+)(?:,([^(),]*)(?>,([^(),]+))?)?\)\s*;}{
    my ($l_var, $nsuri, $lname, $attrs, $token_var) = ($1, $2, $3, $4, $5);
    $nsuri =~ s/^\s+//;
    $nsuri =~ s/\s+\z//;
    my $r = qq{
      $l_var = \$self->{document}->create_element_ns
        ($nsuri, [undef, $lname]);
    };
    if (defined $attrs and length $attrs) {
      my $attr_xname;
      if ($nsuri eq q<HTML_NS>) {
        $attr_xname = q[undef, [undef, $attr_name]];
      } else {
        ## NOTE: "Adjust SVG attributes" (SVG only),
        ## "adjust MathML attributes" (MathML only), and
        ## "adjust foreign attributes".
        $attr_xname = qq[
          \@{
            \$foreign_attr_xname->{\$attr_name} ||
            [undef, [undef,
                     ($nsuri) eq SVG_NS ?
                         (\$svg_attr_name->{\$attr_name} || \$attr_name) :
                     ($nsuri) eq MML_NS ?
                         (\$mml_attr_name->{\$attr_name} || \$attr_name) :
                         \$attr_name]]
          }
        ];
      }
      $r .= qq{
        for my \$attr_name (keys %{$attrs}) {
          my \$attr_t = $attrs\->{\$attr_name};
          my \$attr = \$self->{document}->create_attribute_ns ($attr_xname);
          \$attr->value (\$attr_t->{value});
          \$attr->set_user_data (manakai_source_line => \$attr_t->{line});
          \$attr->set_user_data (manakai_source_column => \$attr_t->{column});
          $l_var->set_attribute_node_ns (\$attr);
        }
      };
    }
    if (defined $token_var) {
      $token_var =~ s/^\s+//;
      $token_var =~ s/\s+$//;
      $r .= qq{
        $l_var->set_user_data (manakai_source_line => $token_var\->{line})
            if defined $token_var\->{line};
        $l_var->set_user_data (manakai_source_column => $token_var\->{column})
            if defined $token_var\->{column};
      };
      ## TODO: In future version, it should be allowed for an application
      ## developer to choose whether these information should be kept
      ## for tracking or not for performance by some means.
    }
    $r;
  }ge; # MUST
  s{!!!parse-error;}{q{$self->{parse_error}->();}}ge;
  s{!!!parse-error\s*\(}{
    q{$self->{parse_error}->(level => $self->{level}->{must}, }
  }ge;
  s{!!!next-token;}{q{$self->{t} = $self->_get_next_token;}}ge;
  s{!!!back-token;}{
    q{
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
    }
  }ge;
  s{!!!back-token\s*\(}{q{unshift @{$self->{token}}, (}}ge;
  s{!!!cp\s*\(\s*(\S+)\s*\)\s*;}{
    $TokenizerDebug ? qq{
      #print STDERR "$1, ";
      \$Whatpm::HTML::Debug::cp_pass->($1) if \$Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        \$Whatpm::HTML::Debug::cp->{$1} = 1;
      }
    } : ''
  }ge;
  s{!!!tdebug\s*(\{.*\})\s*;}{
    $TokenizerDebug ? $1 : ''
  }ge;
  s{!!!pdebug\s*(\{.*\})\s*;}{
    $ParserDebug ? $1 : ''
  }ge;
  print;
}
