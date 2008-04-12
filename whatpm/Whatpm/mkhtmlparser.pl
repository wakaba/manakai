#!/usr/bin/perl 
use strict;

my $DEBUG = $ENV{DEBUG};

while (<>) {
  s/!!!emit\b/return /;
  s{!!!next-input-character;}{q{
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  }}ge;
  s{!!!back-next-input-character\b}{q{unshift @{$self->{char}}, }}ge;
  s{!!!nack\s*\(\s*'([^']+)'\s*\)\s*;}{
    ($DEBUG ? qq{
      if (\$self->{self_closing}) {
        !!!cp ('$1.2');
      } else {
        !!!cp ('$1.3');
      }
    } : '')
  }ge;
  s{!!!ack\s*(?>\([^)]*\)\s*)?;}{q{delete $self->{self_closing};}}ge;
  s{!!!ack-later\s*(?>\([^)]*\)\s*)?;}{}ge;
  s{!!!parse-error;}{q{$self->{parse_error}->();}}ge;
  s{!!!parse-error\s*\(}{
    q{$self->{parse_error}->(level => $self->{must_level}, }
  }ge;
  s{!!!insert-element-f\s*\(([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2\->{tag_name}, $2\->{attributes}, $2);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, (\$el_category_f->{$1}->{$2\->{tag_name}} || 0) | FOREIGN_EL];
    }
  }}ge;
  s{!!!insert-element-t\s*\(([^(),]+),([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, \$HTML_NS, $1, $2, $3);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),\s*,([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, \$HTML_NS, $1,, $2);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, \$HTML_NS, $1, $2, $3);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!create-element\s*\(([^(),]+),([^(),]+),([^(),]+)(?:,([^(),]*)(?>,([^(),]+))?)?\)\s*;}{
    my $l_var = $1;
    my $r = qq{
      $l_var = \$self->{document}->create_element_ns
        ($2, [undef, $3]);
    };
    if (defined $4 and length $4) {
      $r .= qq{
        for my \$attr_name (keys %{$4}) {
          my \$attr_t = $4\->{\$attr_name};
          my \$attr = \$self->{document}->create_attribute_ns
              (undef, [undef, \$attr_name]);
          \$attr->value (\$attr_t->{value});
          \$attr->set_user_data (manakai_source_line => \$attr_t->{line});
          \$attr->set_user_data (manakai_source_column => \$attr_t->{column});
          $l_var->set_attribute_node_ns (\$attr);
        }
      };
    }
    if (defined $5) {
      my $token_var = $5;
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
  s{!!!next-token;}{q{$token = $self->_get_next_token;}}ge;
  s{!!!back-token;}{
    q{
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
    }
  }ge;
  s{!!!back-token\s*\(}{q{unshift @{$self->{token}}, (}}ge;
  s{!!!cp\s*\(\s*(\S+)\s*\)\s*;}{
    $DEBUG ? qq{
      #print STDERR "$1, ";
      \$Whatpm::HTML::Debug::cp_pass->($1) if \$Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        \$Whatpm::HTML::Debug::cp->{$1} = 1;
      }
    } : ''
  }ge;
  print;
}
