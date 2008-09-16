package Whatpm::WebIDL;
use strict;

package Whatpm::WebIDL::Parser;

my $integer = qr/-?0([Xx][0-9A-Fa-f]+|[0-7]*)|[1-9][0-9]*/;
  ## ISSUE: Spec's pattern is wrong as a Perl5 regular expression.
my $float = qr/-?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+-]?[0-9]+)?|[0-9]+[Ee][+-]?[0-9]+/;
my $identifier = qr/[A-Z_a-z][0-9A-Z_a-z]*/;
my $whitespace = qr<[\t\n\r ]+|[\t\n\r ]*((//.*|/\*.*?\*/)[\t\n\r ]*)+>;

my $default_levels = {
                      must => 'm',
                      should => 's',
                      warn => 'w',
                      fact => 'w',
                      undefined => 'w',
                      info => 'i',
                      uncertain => 'u',
                     };

sub new ($) {
  my $self = bless {
    must_level => 'm',
    should_level => 's',
    warn_level => 'w',
    info_level => 'i',
    level => $default_levels,
  }, $_[0];
  return $self;
} # new

sub parse_char_string ($$;$) {
  my $self = shift;
  my $s = ref $_[0] ? $_[0] : \($_[0]);

  my $defs = Whatpm::WebIDL::Definitions->new;
  $defs->set_user_data (manakai_source_line => 1);
  $defs->set_user_data (manakai_source_column => 1);

  pos ($$s) = 0;
  my $line = 1;
  my $column = 0;

  my $get_next_token = sub {
    if (length $$s <= pos $$s) {
      return {type => 'eof'};
    }

    while ($$s =~ /\G($whitespace)/gc) {
      my $v = $1;
      while ($v =~ s/^[^\x0D\x0A]*(?>\x0D\x0A?|\x0A)//) {
        $line++;
        $column = 0;
      }
      $column += length $v;
    }

    if (length $$s <= pos $$s) {
      return {type => 'eof'};
    }

    ## ISSUE: "must"s in "A. IDL grammer" are not "MUST"s.

    if ($$s =~ /\G($identifier)/gc) {
      my $v = $1;
      $column += length $v;
      if ({
        module => 1, interface => 1, exception => 1, typedef => 1,
        valuetype => 1, DOMString => 1, sequence => 1, unsigned => 1,
        short => 1, const => 1, TRUE => 1, FALSE => 1, readonly => 1,
        attribute => 1, getraises => 1, setraises => 1, raises => 1, in => 1,
        any => 1, boolean => 1, octet => 1, float => 1, Object => 1,
        short => 1, long => 1, void => 1,
      }->{$v}) {
        return {type => $v};
      } else {
        return {type => 'identifier', value => $v};
      }
    } elsif ($$s =~ /\G($float)/gc) { ## ISSUE: negative number
      $column += length $1;
      return {type => 'float', value => $1};
    } elsif ($$s =~ /\G($integer)/gc) { ## ISSUE: negative nmber
      $column += length $1;
      return {type => 'integer', value => $1};
    } elsif ($$s =~ /\G::/gcs) {
      $column += 2;
      return {type => '::'};
    } elsif ($$s =~ /\G(.)/gcs) { ## NOTE: Should never be a newline char.
      $column++;
      return {type => $1};
    } else {
      die "get_next_token: non-possible case: " . substr ($$s, pos $$s, 20);
    }
  }; # $get_next_token

  my $state = 'before definitions';
  my $token = $get_next_token->();
  my $nest_level = 0;
  my $next_state;
  my $xattrs;
  my $prev_xattrs = [];
  my $last_xattr;
  my $read_only;
  my $current_type;
  my @current = ($defs);

  my $_onerror = $_[1] || sub {
    my %opt = @_;
    my $r = 'Line ' . $opt{line} . ' column ' . $opt{column} . ': ';

    if ($opt{token}) {
      $r .= 'Token ' . (defined $opt{token}->{value} ? $opt{token}->{value} : $opt{token}->{type}) . ': ';
    }

    $r .= $opt{type} . ';' . $opt{level};
    
    warn $r . "\n";
  }; # $_onerror
  my $onerror = sub {
    $_onerror->(line => $line, column => $column, token => $token, @_);
  }; # $onerror

  my $get_scoped_name = sub {
    ## NOTE: Convert a |ScopedName| into a "scoped name".

    my $name = [];

    ## NOTE: "DOMString" is not a scoped name, while "::DOMString"
    ## and "x::DOMString" are.

    if ($token->{type} eq 'identifier') {
      my $identifier = $token->{value};
      $identifier =~ s/^_//;
      push @$name, $identifier;
      $token = $get_next_token->();
      while ($token->{type} eq '::') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          my $identifier = $token->{value};
          $identifier =~ s/^_//;
          push @$name, $identifier;
          $token = $get_next_token->();
        } elsif ($token->{type} eq 'DOMString') {
          push @$name, 'DOMString', '', '';
          $token = $get_next_token->();
          last;
        }
      }
    } elsif ($token->{type} eq '::') {
      push @$name, '';
      while ($token->{type} eq '::') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          my $identifier = $token->{value};
          $identifier =~ s/^_//;
          push @$name, $identifier;
          $token = $get_next_token->();
        } elsif ($token->{type} eq 'DOMString') {
          push @$name, 'DOMString', '', '';
          $token = $get_next_token->();
          last;
        } else {
          last;
        }
      }

      if (@$name == 1) {
        return undef;
      }
    } else {
      # reconsume
      return undef;
    }
    return join '::', @$name;
  }; # $get_scoped_name

  my $get_type;
  $get_type = sub {
    my $r;
    if ({
      void => 1, any => 1, boolean => 1, octet => 1, float => 1,
      DOMString => 1, Object => 1, short => 1,
    }->{$token->{type}}) {
      $r = '::'.$token->{type}.'::';
      $token = $get_next_token->();
    } elsif ($token->{type} eq 'unsigned') {
      $token = $get_next_token->();
      if ($token->{type} eq 'short') {
        $r = '::unsigned '.$token->{type}.'::';
        $token = $get_next_token->();
      } elsif ($token->{type} eq 'long') {
        $token = $get_next_token->();
        if ($token->{type} eq 'long') {
          $r = '::unsigned long long::';
          $token = $get_next_token->();
        } else {
          $r = '::unsigned long::';
          # reconsume
        }
      } else {
        $onerror->(type => 'unsigned', level => $self->{must_level});
        return undef;
      }
    } elsif ($token->{type} eq 'long') {
      $token = $get_next_token->();
      if ($token->{type} eq 'long') {
        $r = '::long long::';
        $token = $get_next_token->();
      } else {
        $r = '::long::';
        # reconsume
      }
    } elsif ($token->{type} eq '::' or $token->{type} eq 'identifier') {
      $r = $get_scoped_name->();
      if (defined $r) {
        # next token
      } else { # "::" not followed by identifier or "DOMString"
        $onerror->(type => 'scoped name', level => $self->{must_level});
        return undef;
      }
    } elsif ($token->{type} eq 'sequence') {
      $token = $get_next_token->();
      if ($token->{type} eq '<') {
        $token = $get_next_token->();
        if ({
          void => 1, any => 1, boolean => 1, octet => 1, float => 1,
          DOMString => 1, Object => 1, short => 1, long => 1, unsigned => 1,
          sequence => 1, '::' => 1, identifier => 1,
        }->{$token->{type}}) {
          my $type = $get_type->();
          if (defined $type) {
            if ($token->{type} eq '>') {
              $r = '::::sequence::::' . $type;
              $token = $get_next_token->();
            } else {
              $onerror->(type => 'sequence gt', level => $self->{must_level});
              return undef;
            }
          } else {
            # error reported
            return undef;
          }
        } else {
          $onerror->(type => 'sequence type', level => $self->{must_level});
          return undef;
        }
      } else {
        $onerror->(type => 'sequence lt', level => $self->{must_level});
        return undef;
      }
    } else {
      die "get_type: bad token: $token->{type}";
    }

    return $r;
  }; # $get_type

  while (1) {
    if ($state eq 'before definitions') {
      $xattrs = [];
      if ($token->{type} eq '[') {
        $token = $get_next_token->();
        $state = 'before xattr';
        $next_state = 'before def';
      } elsif ({module => 1, interface => 1, exception => 1,
               typedef => 1, valuetype => 1, const => 1}->{$token->{type}}) {
        # reconsume
        $state = 'before def';
      } elsif ($token->{type} eq '}' and @current > 1) {
        $token = $get_next_token->();
        $state = 'before block semicolon';
      } elsif ($token->{type} eq 'eof') {
        last;
      } else {
        $onerror->(type => 'before definitions', level => 'm',
                   token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'before xattr') {
      if ($token->{type} eq 'identifier') {
        my $id = $token->{value};
        $id =~ s/^_//;
        push @current, Whatpm::WebIDL::ExtendedAttribute->new ($id);
        $current[-1]->set_user_data (manakai_source_line => $line);
        $current[-1]->set_user_data (manakai_source_column => $column);
        push @$xattrs, $current[-1];
        $token = $get_next_token->();
        $state = 'after xattr';
      } else {
        $onerror->(type => 'before xattr', level => 'm', token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions'; ## TODO:
      }
    } elsif ($state eq 'after xattr') {
      if ($token->{type} eq '=') {
        $token = $get_next_token->();
        $state = 'before xattrarg';
      } elsif ($token->{type} eq '(') {
        $current[-1]->has_argument_list (1);
        $token = $get_next_token->();
        if ($token->{type} eq ')') {
          $token = $get_next_token->();
          push @$prev_xattrs, $xattrs;
          $state = 'after xattrarg';
        } else {
          push @$prev_xattrs, $xattrs;
          # reconsume
          $state = 'before argument';
        }
      } else {
        push @$prev_xattrs, $xattrs;
        # reconsume
        $state = 'after xattrarg';
      }
    } elsif ($state eq 'before xattrarg') {
      if ($token->{type} eq 'identifier') {
        my $identifier = $token->{value};
        $identifier =~ s/^_//;
        $current[-1]->value ($identifier);
        $token = $get_next_token->();
        if ($token->{type} eq '(') {
          $current[-1]->has_argument_list (1);
          $token = $get_next_token->();
          if ($token->{type} eq ')') {
            push @$prev_xattrs, $xattrs;
            $token = $get_next_token->();
            $state = 'after xattrarg';
          } else {
            push @$prev_xattrs, $xattrs;
            # reconsume
            $state = 'before argument';
          }
        } else {
          push @$prev_xattrs, $xattrs;
          # reconsume
          $state = 'after xattrarg';
        }
      } else {
        $onerror->(type => 'after xattrarg', level => 'm', token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';        
      }
    } elsif ($state eq 'after xattrarg') {
      pop @current; # xattr
      $xattrs = pop @$prev_xattrs;
      if ($token->{type} eq ',') {
        $token = $get_next_token->();
        $state = 'before xattr';
      } elsif ($token->{type} eq ']') {
        $token = $get_next_token->();
        if ($current[-1]->isa ('Whatpm::WebIDL::Definitions') or
            $current[-1]->isa ('Whatpm::WebIDL::Module')) {
          $state = 'before def';
        } elsif ($current[-1]->isa ('Whatpm::WebIDL::Interface')) {
          $state = 'before interface member';
        } elsif ($current[-1]->isa ('Whatpm::WebIDL::Exception')) {
          $state = 'before exception member';
        } elsif ($current[-1]->isa ('Whatpm::WebIDL::Operation') or
                 $current[-1]->isa ('Whatpm::WebIDL::ExtendedAttribute')) {
          $state = 'before argument in';
        } else {
          die "$0: Unknown xattr context: " . ref $current[-1];
        }
      } else {
        $onerror->(type => 'after xattr', level => 'm', token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions'; ## TODO:
      }
    } elsif ($state eq 'before def') {
      if ($token->{type} eq 'module') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          my $identifier = $token->{value};
          $identifier =~ s/^_//;
          push @current, Whatpm::WebIDL::Module->new ($identifier);
          $current[-1]->set_user_data (manakai_source_line => $line);
          $current[-1]->set_user_data (manakai_source_column => $column);
          $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
          $token = $get_next_token->();
          $state = 'before module block';
          next;
        } else {
          $onerror->(type => 'module identifier',
                     level => $self->{must_level});
          #
        }        
      } elsif ($token->{type} eq 'interface') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          my $identifier = $token->{value};
          $identifier =~ s/^_//;
          push @current, Whatpm::WebIDL::Interface->new ($identifier);
          $current[-1]->set_user_data (manakai_source_line => $line);
          $current[-1]->set_user_data (manakai_source_column => $column);
          $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
          $token = $get_next_token->();
          $state = 'before interface inheritance';
          next;
        } else {
          $onerror->(type => 'interface identifier',
                     level => $self->{must_level});
          #
        }        
      } elsif ($token->{type} eq 'exception') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          my $identifier = $token->{value};
          $identifier =~ s/^_//;
          push @current, Whatpm::WebIDL::Exception->new ($identifier);
          $current[-1]->set_user_data (manakai_source_line => $line);
          $current[-1]->set_user_data (manakai_source_column => $column);
          $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
          $token = $get_next_token->();
          $state = 'before exception block';
          next;
        } else {
          $onerror->(type => 'exception identifier',
                     level => $self->{must_level});
          #
        }        
      } elsif ($token->{type} eq 'typedef') {
        $token = $get_next_token->();
        $state = 'before typedef type';
        next;
      } elsif ($token->{type} eq 'valuetype') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          my $identifier = $token->{value};
          $identifier =~ s/^_//;
          push @current, Whatpm::WebIDL::Valuetype->new ($identifier);
          $current[-1]->set_user_data (manakai_source_line => $line);
          $current[-1]->set_user_data (manakai_source_column => $column);
          $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
          $token = $get_next_token->();
          $state = 'before boxed type';
          next;
        } elsif ($token->{type} eq 'DOMString') {
          push @current, Whatpm::WebIDL::Valuetype->new ('::DOMString::');
          $current[-1]->set_user_data (manakai_source_line => $line);
          $current[-1]->set_user_data (manakai_source_column => $column);
          $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
          $token = $get_next_token->();
          if ($token->{type} eq 'sequence') {
            $token = $get_next_token->();
            if ($token->{type} eq '<') {
              $token = $get_next_token->();
              if ($token->{type} eq 'unsigned') {
                $token = $get_next_token->();
                if ($token->{type} eq 'short') {
                  $token = $get_next_token->();
                  if ($token->{type} eq '>') {
                    $current[-1]->type ('::::sequence::::::unsigned short::');
                    $token = $get_next_token->();
                    $state = 'before semicolon';
                    $next_state = 'before definitions';
                    next;
                  } else {
                    #                
                  }
                } else {
                  #                
                }
              } else {
                #
              }
            } else {
              #
            }
          } else {
            #
          }
          $onerror->(type => 'valuetype DOMString',
                     level => $self->{must_level});
          pop @current; # valuetype
          #
        } else {
          $onerror->(type => 'valuetype identifier',
                     level => $self->{must_level});
          #
        }        
      } elsif ($token->{type} eq 'const') {
        $token = $get_next_token->();
        $state = 'before const type';
        $next_state = 'before definitions';
        next;
      } else {
        $onerror->(type => 'before definition', level => 'm',
                   token => $token);
        # reconsume
        #
      }
      $state = 'ignore';
      $nest_level = 0;
      $next_state = 'before definitions';
    } elsif ($state eq 'before module block') {
      if ($token->{type} eq '{') {
        $token = $get_next_token->();
        $state = 'before definitions';
      } else {
        $onerror->(type => 'before module block', level => 'm',
                   token => $token);
        pop @current; # module
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'before interface inheritance') {
      if ($token->{type} eq ':') {
        $token = $get_next_token->();
        $state = 'before parent interface name';
      } elsif ($token->{type} eq ';') {
        $current[-1]->is_forward_declaration (1);
        # reconsume
        $state = 'before semicolon';
        $next_state = 'before interface member';
      } else {
        # reconsume
        $state = 'before interface block';
      }
    } elsif ($state eq 'before parent interface name') {
      my $name = $get_scoped_name->();
      if (defined $name) {
        $current[-1]->append_inheritance ($name);

        if ($token->{type} eq ',') {
          $token = $get_next_token->();
          # stay in the state
        } else {
          # reconsume
          $state = 'before interface block';
        }
      } else {
        $onerror->(type => 'scoped name', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before exception name') {
      my $name = $get_scoped_name->();
      if (defined $name) {
        my $method = $next_state eq '*raises' ? 'append_raises' :
              $next_state eq '*getraises' ? 'append_getraises' :
              'append_setraises';
        $current[-1]->$method ($name);

        if ($token->{type} eq ',') {
          $token = $get_next_token->();
          # stay in the state
        } elsif ($token->{type} eq ')') {
          $token = $get_next_token->();
          if ($next_state eq '*getraises' and $token->{type} eq 'setraises') {
            $token = $get_next_token->();
            $state = 'after raises';
            $next_state = '*setraises';
          } else {
            # reprocess
            $state = 'before semicolon';
            $next_state = 'before interface member';
          }
        } else {
          $onerror->(type => 'after exception name',
                     level => $self->{must_level});
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
        }
      } else {
        $onerror->(type => 'scoped name', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before interface block') {
      if ($token->{type} eq '{') {
        $token = $get_next_token->();
        $state = 'before members';
        $next_state = 'before interface member';
      } else {
        $onerror->(type => 'before interface block',
                   level => $self->{must_level});
        pop @current; # interface
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before exception block') {
      if ($token->{type} eq '{') {
        $token = $get_next_token->();
        $state = 'before members';
        $next_state = 'before exception member';
      } else {
        $onerror->(type => 'before exception block',
                   level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before members') {
      $xattrs = [];
      if ($token->{type} eq '[') {
        $token = $get_next_token->();
        $state = 'before xattr';
        #$next_state = $next_state; # 'before interface member' or ...
      } elsif ($token->{type} eq '}') {
        $token = $get_next_token->();
        $state = 'before block semicolon';
      } else {
        # reconsume
        $state = $next_state; # ... 'before exception member'
      }
    } elsif ($state eq 'before interface member') {
      if ($token->{type} eq 'const') {
        $token = $get_next_token->();
        $state = 'before const type';
        $next_state = 'before definitions';
      } elsif ($token->{type} eq 'readonly') {
        $read_only = 1;
        $token = $get_next_token->();
        if ($token->{type} eq 'attribute') {
          $token = $get_next_token->();
          $state = 'after attribute';
        } else {
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before interface member';
        }
      } elsif ($token->{type} eq 'attribute') {
        $read_only = 0;
        $token = $get_next_token->();
        $state = 'after attribute';
      } elsif ({
        void => 1, any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, unsigned => 1, short => 1, long => 1,
        '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        # reconsume
        $state = 'before operation type';
      } elsif ($token->{type} eq '}') {
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before definitions';
      } elsif ($token->{type} eq 'eof') {
        last;
      } else {
        $onerror->(type => 'before interface member',
                   level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before exception member') {
      if ({
        void => 1, any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, unsigned => 1, short => 1, long => 1,
        '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        # reconsume
        $state = 'before exception member type';
      } elsif ($token->{type} eq '}') {
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before definitions';
      } elsif ($token->{type} eq 'eof') {
        last;
      } else {
        $onerror->(type => 'before exception member',
                   level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before typedef type') {
      if ({
        void => 1, any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, short => 1, long => 1, unsigned => 1,
        sequence => 1, '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        $current_type = $get_type->();
        if (defined $current_type) {
          # next token
          $state = 'before typedef rest';
        } else {
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before definitions';
        }
      } else {
        $onerror->(type => 'before type', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'before boxed type') {
      if ({
        boolean => 1, octet => 1, float => 1,
        short => 1, long => 1, unsigned => 1,
        sequence => 1, '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        $current_type = $get_type->();
        if (defined $current_type) {
          $current[-1]->type ($current_type);
          # next token
          $state = 'before semicolon';
          $next_state = 'before definitions';
        } else {
          pop @current; # valuetype
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before definitions';
        }
      } else {
        $onerror->(type => 'before boxed type', level => $self->{must_level});
        pop @current; # valuetype
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'before const type') {
      if ({
        any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, short => 1, long => 1, unsigned => 1,
        '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        $current_type = $get_type->();
        if (defined $current_type) {
          # next token
          $state = 'before const identifier';
        } else {
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          #$next_state = $next_state;
        }
      } else {
        $onerror->(type => 'before type', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        #$next_state = $next_state;
      }
    } elsif ($state eq 'before typedef rest') {
      if ($token->{type} eq 'identifier') {
        ## TODO: unescape
        push @current, Whatpm::WebIDL::Typedef->new ($token->{value});
        $current[-1]->set_user_data (manakai_source_line => $line);
        $current[-1]->set_user_data (manakai_source_column => $column);
        $current[-1]->type ($current_type);
        $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before definitions';
      } elsif ($token->{type} eq 'DOMString') {
        push @current, Whatpm::WebIDL::Typedef->new ('::DOMString::');
        $current[-1]->type ($current_type);
        $current[-1]->set_user_data (manakai_source_line => $line);
        $current[-1]->set_user_data (manakai_source_column => $column);
        $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before defnitions';
      } else {
        $onerror->(type => 'before typedef rest', 
                   level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'before const identifier') {
      if ($token->{type} eq 'identifier') {
        my $identifier = $token->{value};
        $identifier =~ s/^_//;
        push @current, Whatpm::WebIDL::Const->new ($identifier);
        $current[-1]->set_user_data (manakai_source_line => $line);
        $current[-1]->set_user_data (manakai_source_column => $column);
        $current[-1]->type ($current_type);
        $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
        $token = $get_next_token->();
        if ($token->{type} eq '=') {
          $token = $get_next_token->();
          $state = 'before const expr';
          next;
        } else {
          $onerror->(type => 'const eq', level => $self->{must_level});
          #
        }
      } else {
        $onerror->(type => 'const identifier', level => $self->{must_level});
        #
      }
      # reconsume
      $state = 'ignore';
      $nest_level = 0;
      #$next_state = $next_state;
    } elsif ($state eq 'before const expr') {
      if ($token->{type} eq 'TRUE' or $token->{type} eq 'FALSE') {
        $current[-1]->value ([$token->{type}]);
        #
      } elsif ($token->{type} eq 'integer') {
        if ($token->{value} =~ /^0[Xx]/) {
          $current[-1]->value ([$token->{type}, hex substr $token->{value},2]);
        } elsif ($token->{value} =~ /^-0[Xx]/) {
          $current[-1]->value ([$token->{type},-hex substr $token->{value},3]);
        } elsif ($token->{value} =~ /^0/) {
          $current[-1]->value ([$token->{type}, oct $token->{value}]);
        } elsif ($token->{value} =~ /^-0/) {
          $current[-1]->value ([$token->{type},-oct substr $token->{value},1]);
        } else {
          $current[-1]->value ([$token->{type}, 0+$token->{value}]);
        }
        #
      } elsif ($token->{type} eq 'float') {
        $current[-1]->value ([$token->{type}, 0+$token->{value}]);
        #
      } else {
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        #$next_state = $next_state;
        next;
      }
      
      $token = $get_next_token->();
      $state = 'before semicolon';
      #$next_state = $next_state;
    } elsif ($state eq 'after attribute') {
      if ({
        any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, short => 1, long => 1, unsigned => 1,
        '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        $current_type = $get_type->();
        if (defined $current_type) {
          # next token
          $state = 'before attribute identifier';
        } else {
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before interface member';
        }
      } else {
        $onerror->(type => 'before type', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before interface member';
      }
    } elsif ($state eq 'before exception member type') {
      if ({
        any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, short => 1, long => 1, unsigned => 1,
        '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        $current_type = $get_type->();
        if (defined $current_type) {
          # next token
          $state = 'before exception member identifier';
        } else {
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before exception member';
        }
      } else {
        $onerror->(type => 'before type', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before exception member';
      }
    } elsif ($state eq 'before operation type') {
      if ({
        any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, short => 1, long => 1, unsigned => 1,
        '::' => 1, identifier => 1,
        void => 1,
      }->{$token->{type}}) {
        $current_type = $get_type->();
        if (defined $current_type) {
          # next token
          $state = 'before operation identifier';
        } else {
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before interface member';
        }
      } else {
        $onerror->(type => 'before type', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before interface member';
      }
    } elsif ($state eq 'before argument type') {
      if ({
        any => 1, boolean => 1, octet => 1, float => 1,
        DOMString => 1, Object => 1, short => 1, long => 1, unsigned => 1,
        '::' => 1, identifier => 1,
      }->{$token->{type}}) {
        $current_type = $get_type->();
        if (defined $current_type) {
          # next token
          $state = 'before argument identifier';
        } else {
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
        }
      } else {
        $onerror->(type => 'before type', level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before attribute identifier') {
      if ($token->{type} eq 'identifier') {
        my $identifier = $token->{value};
        $identifier =~ s/^_//;
        push @current, Whatpm::WebIDL::Attribute->new ($identifier);
        $current[-1]->set_user_data (manakai_source_line => $line);
        $current[-1]->set_user_data (manakai_source_column => $column);
        $current[-1]->readonly ($read_only);
        $current[-1]->type ($current_type);
        $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
        $token = $get_next_token->();
        if ($token->{type} eq 'getraises') {
          $token = $get_next_token->();
          $state = 'after raises';
          $next_state = '*getraises';
          next;
        } elsif ($token->{type} eq 'setraises') {
          $token = $get_next_token->();
          $state = 'after raises';
          $next_state = '*setraises';
          next;
        } else {
          # reconsume
          $state = 'before semicolon';
          $next_state = 'before interface member';
          next;
        }
      } else {
        $onerror->(type => 'attribute identifier',
                   level => $self->{must_level});
        #
      }
      # reconsume
      $state = 'ignore';
      $nest_level = 0;
      $next_state = 'before interface member';
    } elsif ($state eq 'before exception member identifier') {
      if ($token->{type} eq 'identifier') {
        my $identifier = $token->{value};
        $identifier =~ s/^_//;
        push @current, Whatpm::WebIDL::ExceptionMember->new ($identifier);
        $current[-1]->set_user_data (manakai_source_line => $line);
        $current[-1]->set_user_data (manakai_source_column => $column);
        $current[-1]->type ($current_type);
        $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before exception member';
      } else {
        $onerror->(type => 'exception member identifier',
                   level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before operation identifier') {
      if ($token->{type} eq 'identifier') {
        ## TODO: unescape
        push @current, Whatpm::WebIDL::Operation->new ($token->{value});
        $current[-1]->set_user_data (manakai_source_line => $line);
        $current[-1]->set_user_data (manakai_source_column => $column);
        $current[-1]->type ($current_type);
        $current[-1]->set_extended_attribute_node ($_) for @$xattrs;
        $token = $get_next_token->();
        if ($token->{type} eq '(') {
          $token = $get_next_token->();
          if ($token->{type} eq ')') {
            $token = $get_next_token->();
            $state = 'before raises';
            $next_state = '*raises';
            next;
          } else {
            # reconsume
            $state = 'before argument';
            next;
          }
        } else {
          $onerror->(type => 'arguments lparen',
                     level => $self->{must_level});
          #
        }
      } else {
        $onerror->(type => 'operation identifier',
                   level => $self->{must_level});
        #
      }
      # reconsume
      $state = 'ignore';
      $nest_level = 0;
      $next_state = 'before interface member';
    } elsif ($state eq 'before argument identifier') {
      if ($token->{type} eq 'identifier') {
        my $id = $token->{value};
        $id =~ s/^_//;
        my $arg = Whatpm::WebIDL::Argument->new ($id);
        $arg->set_user_data (manakai_source_line => $line);
        $arg->set_user_data (manakai_source_column => $column);
        $arg->type ($current_type);
        $arg->set_extended_attribute_node ($_) for @$xattrs;
        $current[-1]->append_child ($arg);
        $token = $get_next_token->();
        if ($token->{type} eq ')') {
          $token = $get_next_token->();
          if ($current[-1]->isa ('Whatpm::WebIDL::Operation')) {
            $state = 'before raises';
          } else {
            $state = 'after xattrarg';
          }
          next;
        } elsif ($token->{type} eq ',') {
          $token = $get_next_token->();
          $state = 'before argument';
          next;
        } else {
          $onerror->(type => 'after argument',
                     level => $self->{must_level});
          #
        }
      } else {
        $onerror->(type => 'argument identifier',
                   level => $self->{must_level});
        #
      }
      # reconsume
      $state = 'ignore';
      $nest_level = 0;
    } elsif ($state eq 'before argument') {
      $xattrs = [];
      if ($token->{type} eq '[') {
        $token = $get_next_token->();
        $state = 'before xattr';
        $next_state = 'before argument in';
      } else {
        # reconsume
        $state = 'before argument in';
      }
    } elsif ($state eq 'before argument in') {
      if ($token->{type} eq 'in') {
        $token = $get_next_token->();
        $state = 'before argument type';
      } else {
        $onerror->(type => 'argument in',
                   level => $self->{must_level});
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before raises') {
      if ($token->{type} eq 'raises') {
        $token = $get_next_token->();
        $state = 'after raises';
        $next_state = '*raises';
      } else {
        # reconsume
        $state = 'before semicolon';
        $next_state = 'before interface member';
      }
    } elsif ($state eq 'after raises') {
      if ($token->{type} eq '(') {
        $token = $get_next_token->();
        $state = 'before exception name';
      } else {
        $onerror->(type => 'raises lparen',
                   level => $self->{must_level});
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before semicolon') {
      if ($token->{type} eq ';') {
        $current[-2]->append_child ($current[-1]);
        pop @current;
        $token = $get_next_token->();
        if ($current[-1]->isa ('Whatpm::WebIDL::Definitions') or
            $current[-1]->isa ('Whatpm::WebIDL::Module')) {
          $state = 'before definitions';
        } elsif ($current[-1]->isa ('Whatpm::WebIDL::Interface')) {
          $state = 'before members';
          $next_state = 'before interface member';
        } else {
          $state = 'before members';
          $next_state = 'before exception member';
        }
      } else {
        $onerror->(type => 'before semicolon', level => 'm',
                   token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'before block semicolon') {
      if ($token->{type} eq ';') {
        $current[-2]->append_child ($current[-1]);
        pop @current;
        $token = $get_next_token->();
        if ($current[-1]->isa ('Whatpm::WebIDL::Definitions') or
            $current[-1]->isa ('Whatpm::WebIDL::Module')) {
          $state = 'before definitions';
        } elsif ($current[-1]->isa ('Whatpm::WebIDL::Interface')) {
          $state = 'before members';
          $next_state = 'before interface member';
        } else {
          $state = 'before members';
          $next_state = 'before exception member';
        }
      } else {
        $onerror->(type => 'before semicolon', level => 'm',
                   token => $token);
        pop @current; # avoid appended by 'ignore'
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
      }
    } elsif ($state eq 'ignore') {
      if ($nest_level == 0 and $token->{type} eq ';') {
        while (@current > 1) {
          if ($current[-1]->isa ('Whatpm::WebIDL::Interface') or
              $current[-1]->isa ('Whatpm::WebIDL::Exception') or
              $current[-1]->isa ('Whatpm::WebIDL::Module')) {
            last;
          }
          pop @current;
        }

        $token = $get_next_token->();
        if ($current[-1]->isa ('Whatpm::WebIDL::Definitions') or
            $current[-1]->isa ('Whatpm::WebIDL::Module')) {
          $state = 'before definitions';
        } elsif ($current[-1]->isa ('Whatpm::WebIDL::Interface')) {
          $state = 'before members';
          $next_state = 'before interface member';
        } else {
          $state = 'before members';
          $next_state = 'before exception member';
        }
      } elsif ($token->{type} eq '{') {
        $nest_level++;
        $token = $get_next_token->();
        # stay in the state
      } elsif ($nest_level and $token->{type} eq '}') {
        $nest_level--;
        $token = $get_next_token->();
        # stay in the state
      } elsif ($token->{type} eq 'eof') {
        while (@current > 1) {
          if ($current[-1]->isa ('Whatpm::WebIDL::Interface') or
              $current[-1]->isa ('Whatpm::WebIDL::Exception') or
              $current[-1]->isa ('Whatpm::WebIDL::Module')) {
            last;
          }
          pop @current;
        }

        last;
      } else {
        # ignore the token
        $token = $get_next_token->();
        # stay in the state
      }
    } else {
      die "parse_char_string: unkown state: $state";
    }
  }

  if (@current > 1) {
    $onerror->(type => 'premature end of file', level => $self->{must_level});
    while (@current > 1) {
      $current[-2]->append_child ($current[-1]);
      pop @current;
    }
  }

  $get_type = undef; # unlink loop

  return $defs;
} # parse_char_string

package Whatpm::WebIDL::Node;

require Scalar::Util;

sub new ($) {
  return bless {child_nodes => []}, $_[0];
} # new

sub append_child ($$) {
  my $self = shift;
  my $child = shift;
  
  ## TODO: child type
  ## TODO: parent check

  push @{$self->{child_nodes}}, $child;

  $child->{parent_node} = $self;
  Scalar::Util::weaken ($child->{parent_node});

  return $child;
} # append_child

sub child_nodes ($) {
  return [@{$_[0]->{child_nodes}}]; # dead list
} # child_nodes

sub idl_text ($) {
  return '[[ERROR: ' . (ref $_[0]) . '->idl_text]]';
} # idl_text

sub node_name ($) {
  return $_[0]->{node_name}; # may be undef
} # node_name

sub parent_node ($) {
  return $_[0]->{parent_node};
} # parent_node

sub get_user_data ($$) {
  return $_[0]->{user_data}->{$_[1]};
} # get_user_data

sub set_user_data ($$$) {
  if (defined $_[2]) {
    $_[0]->{user_data}->{$_[1]} = ''.$_[2];
  } else {
    delete $_[0]->{user_data}->{$_[1]};
  }
} # set_user_data

package Whatpm::WebIDL::Definitions;
push our @ISA, 'Whatpm::WebIDL::Node';

sub idl_text ($) {
  return join "\x0A", map {$_->idl_text} @{$_[0]->{child_nodes}};
} # idl_text

my $xattr_defs = {
  Constructor => {
    #allow_id => 0,
    allow_arglist => 1,
    allowed_type => {Interface => 1},
    allow_multiple => 1,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      ## NOTE: Arguments
      unshift @$items,
          map { {node => $_, scope => $item->{scope}} }
          @{$xattr->{child_nodes}};
    },
  },
  ExceptionConsts => {
    allow_id => 1,
    #allow_arglist => 0,
    allowed_type => {Module => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      my $id = $xattr->value;
      if (defined $id) {
        my $has_x;
        for my $x (@{$item->{node}->child_nodes}) {
          next unless $x->isa ('Whatpm::WebIDL::Exception');
          if ($x->node_name eq $id) {
            $has_x = 1;
            last;
          }
        }
        unless ($has_x) {
          $onerror->(type => 'exception not defined',
                     value => $id,
                     node => $xattr,
                     level => $levels->{must});
        }
      } else {
        $onerror->(type => 'xattr id missing',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{must});
      }
    },
  },
  IndexGetter => {
    #allow_id => 0,
    #allow_arglist => 0,
    allowed_type => {Operation => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      if (@{$item->{node}->{child_nodes}} != 1 or
          $item->{node}->{child_nodes}->[0]->type_text ne 'unsigned long') {
        $onerror->(type => 'wrong signature accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
      }
      if ($item->{defined_accessors}->{$xattr_name} and
          $item->{defined_accessors}->{$xattr_name} ne $item->{node}) {
        $onerror->(type => 'duplicate accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{undefined});
      }
      $item->{defined_accessors}->{$xattr_name} = $item->{node};
    },
  },
  IndexSetter => {
    #allow_id => 0,
    #allow_arglist => 0,
    allowed_type => {Operation => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      if (@{$item->{node}->{child_nodes}} != 2 or
          $item->{node}->{child_nodes}->[0]->type_text ne 'unsigned long') {
        $onerror->(type => 'wrong signature accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
      }
      if ($item->{defined_accessors}->{$xattr_name} and
          $item->{defined_accessors}->{$xattr_name} ne $item->{node}) {
        $onerror->(type => 'duplicate accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{undefined});
      }
      $item->{defined_accessors}->{$xattr_name} = $item->{node};
    },
  },
  NameGetter => {
    #allow_id => 0,
    #allow_arglist => 0,
    allowed_type => {Operation => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      if (@{$item->{node}->{child_nodes}} != 1 or
          $item->{node}->{child_nodes}->[0]->type_text ne 'DOMString') {
        $onerror->(type => 'wrong signature accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
      }
      if ($item->{defined_accessors}->{$xattr_name} and
          $item->{defined_accessors}->{$xattr_name} ne $item->{node}) {
        $onerror->(type => 'duplicate accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{undefined});
      }
      $item->{defined_accessors}->{$xattr_name} = $item->{node};
    },
  },
  NameSetter => {
    #allow_id => 0,
    #allow_arglist => 0,
    allowed_type => {Operation => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      if (@{$item->{node}->{child_nodes}} != 2 or
          $item->{node}->{child_nodes}->[0]->type ne '::DOMString::') {
        $onerror->(type => 'wrong signature accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
      }
      if ($item->{defined_accessors}->{$xattr_name} and
          $item->{defined_accessors}->{$xattr_name} ne $item->{node}) {
        $onerror->(type => 'duplicate accessor',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{undefined});
      }
      $item->{defined_accessors}->{$xattr_name} = $item->{node};
    },
  },
  Null => {
    allow_id => 1,
    #allow_arglist => 0,
    allowed_type => {Argument => 1, Attribute => 1},
        ## ISSUE: Is this allwoed for extended attribute's arguments?
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;
      
      ## ISSUE: [Null=Empty] readonly attribute is not disallowed

      if ($item->{node}->type ne '::DOMString::') {
        $onerror->(type => 'xattr for wrong type',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
      }

      my $id = $xattr->value;
      if (defined $id) {
        if ($id eq 'Null' or $id eq 'Empty') {
          #
        } else {
          $onerror->(type => 'xattr id value not allowed',
                     text => $xattr_name,
                     value => $id,
                     node => $xattr,
                     level => $levels->{must});
        }
      } else {
        $onerror->(type => 'xattr id missing',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{must});
      }
    },
  },
  PutForwards => {
    allow_id => 1,
    #allow_arglist => 0,
    allowed_type => {Attribute => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      ## NOTE: Direct or indirect cirlic reference is not an error.

      unless ($item->{node}->readonly) {
        $onerror->(type => 'attr not readonly',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
      }
      
      my $type_item = $resolve->($item->{node}->type, $item->{scope});
      if ($type_item and
          $type_item->{node}->isa ('Whatpm::WebIDL::Interface')) {
        my $id = $xattr->value;
        if (defined $id) {
          ## ISSUE: "attribute that exists on the interface and which
          ## has the same type as this attribute.": "same type"?
          ## ISSUE: must be read-write attribute?

          my $check = sub ($) {
            my $type_item = shift;
            
            A: {
              for my $attr (@{$type_item->{node}->{child_nodes}}) {
                next unless $attr->isa ('Whatpm::WebIDL::Attribute');
                if ($attr->node_name eq $id) {
                  last A;
                }
              }
              
              $onerror->(type => 'referenced attr not defined',
                         text => $xattr_name,
                         value => $id,
                         node => $xattr,
                         level => $levels->{must});
            } # A
          }; # $check

          if ($type_item->{node}->is_forward_declaration) {
            ## NOTE: Checked later.
            push @$items, {code => sub {
              $check->($resolve->($item->{node}->type, $item->{scope}));
            }};
          } else {
            $check->($type_item);
          }
        } else {
          $onerror->(type => 'xattr id missing',
                     text => $xattr_name,
                     node => $xattr,
                     level => $levels->{must});
        }
      } else {
        ## NOTE: Builtin types, or undefined interface
        $onerror->(type => 'attr type not interface',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
      }
    },
  },
  Stringifies => {
    allow_id => 1,
    #allow_arglist => 0,
    allowed_type => {Interface => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      my $id = $xattr->value;
      if (defined $id) {
        A: {
          for my $attr (@{$item->{node}->{child_nodes}}) {
            next unless $attr->isa ('Whatpm::WebIDL::Attribute');
            if ($attr->node_name eq $id) {
              last A;
            }
          }

          $onerror->(type => 'referenced attr not defined',
                     text => $xattr_name,
                     value => $id,
                     node => $xattr,
                     level => $levels->{must});
        } # A
      }
    },
  },
  Variadic => {
    #allow_id => 0,
    #allow_arglist => 0,
    allowed_type => {Argument => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;
      
      ## ISSUE: is this allowed on extended attribute arguuments?

      ## NOTE: If this is not the final argument, then an error will
      ## be raised later.
      $item->{has_arg_xattr}->{variadic} = 1;
    },
  },

  ## ECMAScript specific extended attributes
  NamedConstructor => {
    allow_id => 1,
    allow_arglist => 1,
    allowed_type => {Interface => 1, Exception => 1},
    allow_multiple => 1,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;
      
      ## NOTE: [NamedConstructor=a,NamedConstructor=a] is not disallowed.

      my $id = $xattr->value;
      if (defined $id) {
        if ($constructors->{$id} and
            $constructors->{$id}->{node} ne $item->{node}) {
          $onerror->(type => 'duplicate constructor name',
                     value => $id,
                     node => $xattr,
                     level => $levels->{must});
        } else {
          $constructors->{$id} = {node => $item->{node},
                                  is_named_constructor => $xattr};
        }
      } else {
        $onerror->(type => 'xattr id missing',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{must});
      }
    },
  },
  NativeObject => {
    allow_id => 1,
    #allow_arglist => 0,
    allowed_type => {Interface => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      my $id = $xattr->value;
      if (defined $id and $id ne 'FunctionOnly') {
        $onerror->(type => 'xattr id value not allowed',
                   text => $xattr_name,
                   value => $id,
                   node => $xattr,
                   level => $levels->{must});
      }

      ## TODO: We should warn if the condition in the section 4.5 is not met.
    },
  },
  NoInterfaceObject => {
    #allow_id => 0,
    #allow_arglist => 0,
    allowed_type => {Interface => 1, Exception => 1},
    #allow_multiple => 0,
    check => sub {
      my ($self, $onerror, $levels, $items, $item, $xattr, $xattr_name,
          $resolve, $constructors) = @_;

      ## ISSUE: [Constructor, NoInterfaceObject]
    },
  },
  Undefined => {
    allow_id => 1,
    #allow_arglist => 0,
    allowed_type => {Argument => 1, Attribute => 1},
        ## ISSUE: Is this allwoed for extended attribute's arguments?
    #allow_multiple => 0,
    #check : is set later
  },
}; # $xattr_defs
$xattr_defs->{Undefined}->{check} = $xattr_defs->{Null}->{check};

sub check ($$;$) {
  my ($self, $onerror, $levels) = @_;

  $levels ||= $default_levels;

  my $check_const_value = sub ($) {
    my $item = shift;
    
    my $type = $item->{node}->type;
    my $value = $item->{node}->value;
    
    ## NOTE: Although it is not explicitly spelled out in the spec,
    ## it can be assumed, imho, that "any" type accepts all of these
    ## constant values.
    ## ISSUE: Should I ask the editor to clarify the spec about this?

        if ($value->[0] eq 'TRUE' or $value->[0] eq 'FALSE') {
          if ($type eq '::boolean::') {
            #
          } elsif ($type eq '::any::') {
            #
          } else {
            $onerror->(type => 'const type mismatch',
                       level => 'm',
                       node => $item->{node},
                       text => $item->{node}->type_text,
                       value => $value->[0]);
          }
        } elsif ($value->[0] eq 'integer') {
          if ($type eq '::octet::') {
            if ($value->[1] < 0 or 255 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } elsif ($type eq '::short::') {
            if ($value->[1] < -32768 or 32767 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } elsif ($type eq '::unsigned short::') {
            if ($value->[1] < 0 or 65535 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } elsif ($type eq '::long::') {
            if ($value->[1] < -2147483648 or 2147483647 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } elsif ($type eq '::unsigned long::') {
            if ($value->[1] < 0 or 4294967295 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } elsif ($type eq '::long long::') {
            if ($value->[1] < -9223372036854775808 or
                9223372036854775807 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } elsif ($type eq '::unsigned long long::') {
            if ($value->[1] < 0 or 18446744073709551615 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } elsif ($type eq '::any::') {
            if ($value->[1] < -9223372036854775808 or
                18446744073709551615 < $value->[1]) {
              $onerror->(type => 'const value out of range',
                         level => 'm',
                         node => $item->{node},
                         value => $value->[1]);
            }
          } else {
            $onerror->(type => 'const type mismatch',
                       level => 'm',
                       node => $item->{node},
                       text => $item->{node}->type_text,
                       value => $value->[1]);
          }
        } elsif ($value->[0] eq 'float') {
          if ($type eq '::float::' or $type eq '::any::') {
            #
          } else {
            $onerror->(type => 'const type mismatch',
                       level => 'm',
                       node => $item->{node},
                       text => $item->{node}->type_text,
                       value => $value->[1]);
          }
        }
        ## NOTE: Otherwise, an error of the implementation or the application.
  }; # $check_const_value

  my $defined_qnames = {};
  my $resolve = sub ($$) {
    my $i_sn = shift;
    my $scope = shift;
    
    if ($i_sn =~ /\A::(?>[^:]+)::\z/ or
        $i_sn =~ /^::::sequence::::/) {
      return undef;
    } elsif ($i_sn =~ /::DOMString\z/ or
             $i_sn =~ /::DOMString::::\z/) {
      return undef;
    } elsif ($i_sn =~ /^::/) {
      if ($defined_qnames->{$i_sn}) {
        return $defined_qnames->{$i_sn};
      } else {
        return undef;
      }
    } else {
      if ($defined_qnames->{$scope . $i_sn}) {
        return $defined_qnames->{$scope . $i_sn};
      } elsif ($defined_qnames->{'::' . $i_sn}) {
        return $defined_qnames->{'::' . $i_sn};
      } else {
        return undef;
      }
    }
  }; # $resolve

  my $items = [map { {node => $_, scope => '::'} } @{$self->{child_nodes}}];

  my $constructors = {};
      ## NOTE: Items are: identifier => {node => $interface_or_exception,
      ## is_named_constructor => $named_constructor_xattr/undef}.

  while (@$items) {
    my $item = shift @$items;
    if (not $item->{node}) {
      $item->{code}->();
      next;
    } elsif ($item->{node}->isa ('Whatpm::WebIDL::Definition') and
             not $item->{defined_members}) {
                 ## NOTE: Const in Interface does not have this.
      if ($item->{node}->isa ('Whatpm::WebIDL::Module')) {
        unshift @$items,
            map {
              {node => $_, parent => $item->{node},
               scope => $item->{scope} . $item->{node}->node_name . '::'}
            }
            @{$item->{node}->{child_nodes}};
      } else {
        unless ($item->{parent}) {
          $onerror->(type => 'non-module definition',
                     level => 's',
                     node => $item->{node});
        }
      }

      if ($item->{node}->isa ('Whatpm::WebIDL::Interface')) {
        for my $i_sn (@{$item->{node}->{inheritances}}) {
          my $def = $resolve->($i_sn, $item->{scope});

          unless ($def and $def->{node}->isa ('Whatpm::WebIDL::Interface')) {
            $i_sn =~ s/::DOMString::::\z/::DOMString/;
            $onerror->(type => 'interface not defined',
                       level => 'm',
                       node => $item->{node},
                       text => $i_sn);
          }
        }

        my $defined_members = {};
        my $defined_accessors = {};
        unshift @$items,
            map { {node => $_, defined_members => $defined_members,
                   defined_accessors => $defined_accessors,
                   scope => $item->{scope}} }
            @{$item->{node}->{child_nodes}};
      } elsif ($item->{node}->isa ('Whatpm::WebIDL::Exception')) {
        my $defined_members = {};
        unshift @$items,
            map { {node => $_, defined_members => $defined_members,
                   scope => $item->{scope}} }
            @{$item->{node}->{child_nodes}};
      } elsif ($item->{node}->isa ('Whatpm::WebIDL::Const')) {
        $check_const_value->($item);
      } elsif ($item->{node}->isa ('Whatpm::WebIDL::Typedef')) {
        my $name = $item->{node}->node_name;
        my $type = $item->{node}->type;
        if ($name eq '::DOMString::' or
            $type eq '::DOMString::' or
            $type =~ /::DOMString::::\z/) {
          $onerror->(type => 'typedef ignored',
                     level => 'i',
                     node => $item->{node});
        }
        ## ISSUE: Refernece to a non-defined interface is not non-conforming.

        ## ISSUE: What does "ignored" mean?
        ## "typedef dom::DOMString a; typedef long a;" is conforming?
        ## "typedef dom::DOMString b; interface c { attribute b d; };" is?

        ## ISSUE: Is "sequence<undefinedtype>" conforming?

        if ($type =~ /\A::([^:]+)::\z/) {
          $item->{allow_null} = {
            boolean => 1, octet => 1, short => 1, 'unsigned short' => 1,
            long => 1, 'unsigned long' => 1, 'long long' => 1, 
            'unsigned long long' => 1, float => 1,
          }->{$1};
        } elsif ($type =~ /^::::sequence::::/) {
          $item->{allow_null} = 1;
        } else {
          my $def = $resolve->($type, $item->{scope});
          $item->{allow_null} = $def->{allow_null};
        }
      } elsif ($item->{node}->isa ('Whatpm::WebIDL::Valuetype')) {
        my $name = $item->{node}->node_name;
        if ($name eq '::DOMString::') {
          $onerror->(type => 'ignored valuetype',
                     level => 'i',
                     node => $item->{node});
        } else {
          my $type = $item->{node}->type;
          if ($type =~ /\A::[^:]+::\z/) {
            #
          } elsif ($type =~ /^::::sequence::::/) {
            ## ISSUE: Is "sequence<unknowntype>" conforming?
          } else {
            my $def = $resolve->($type, $item->{scope});
            if ($def and 
                $def->{allow_null}) {
              #
            } else {
              ## ISSUE: It is not explicitly specified that ScopedName
              ## must refer a defined type.
              $onerror->(type => 'not boxable type',
                         level => 'm',
                         node => $item->{node},
                         text => $item->{node}->type_text);
            }
          }
        }
      }

      my $qname = $item->{node}->qualified_name;
      if ($defined_qnames->{$qname}) {
        ## NOTE: "The identifier of a definition MUST  be locally unique":
        ## Redundant with another requirement below.

        ## ISSUE: |interface x; interface x {};| is non-conforming
        ## according to the current spec text.

        ## ISSUE: |interface x;| with no |interface x {};| is conforming
        ## according to the current spec text.

        $onerror->(type => 'duplicate qname',
                   level => 'm',
                   node => $item->{node});

        if ($item->{node}->isa ('Whatpm::WebIDL::Interface') and
            $defined_qnames->{$qname}->{node}->isa
                ('Whatpm::WebIDL::Interface') and
            $defined_qnames->{$qname}->{node}->is_forward_declaration) {
          $defined_qnames->{$qname} = $item;
        }
      } else {
        $defined_qnames->{$qname} = $item;
        ## NOTE: This flag must be turned on AFTER inheritance check is
        ## performed (c.f. |interface x : x {};|).
      }
    } elsif ($item->{node}->isa ('Whatpm::WebIDL::InterfaceMember')) {
      if ($item->{node}->isa ('Whatpm::WebIDL::Operation')) {
        ## NOTE: Arguments
        my $has_arg_xattr = {};
        unshift @$items,
            map { {node => $_, scope => $item->{scope},
                   has_arg_xattr => $has_arg_xattr} }
            @{$item->{node}->{child_nodes}};
      } else {
        my $name = $item->{node}->node_name;
        if ($item->{defined_members}->{$name}) {
          $onerror->(type => 'duplicate member',
                     level => 'm',
                     node => $item->{node});
          ## ISSUE: Whether the example below is conforming or not
          ## is ambigious:
          ## |interface a { attribute any b; any b (); };|
        } else {
          $item->{defined_members}->{$name} = 1;
        }
      }

      if ($item->{node}->isa ('Whatpm::WebIDL::Attribute') or
          $item->{node}->isa ('Whatpm::WebIDL::Operation')) {
        my $type = $item->{node}->type;
        if ($type =~ /\A::[^:]+::\z/) { # note that sequence<> not allowed
          #
        } else { # scoped name
          my $def = $resolve->($type, $item->{scope});
          
          unless ($def and
                  ($def->{node}->isa ('Whatpm::WebIDL::Interface') or
                   $def->{node}->isa ('Whatpm::WebIDL::Typedef') or
                   $def->{node}->isa ('Whatpm::WebIDL::Valuetype'))) {
            $onerror->(type => 'type not defined',
                       level => 'm',
                       node => $item->{node},
                       text => $item->{node}->type_text);
          }
        }
                
        for (@{$item->{node}->{raises} or []}, # for operations
             @{$item->{node}->{getraises} or []}, # for attributes
             @{$item->{node}->{setraises} or []}) { # for attributes
          my $def = $resolve->($_, $item->{scope});
          
          unless ($def and
                  $def->{node}->isa ('Whatpm::WebIDL::Exception')) {
            $onerror->(type => 'exception not defined',
                       level => 'm',
                       node => $item->{node},
                       text => $_);
          }
        }
        
        ## ISSUE: readonly setraises is not disallowed
        ## ISSUE: raises (x,x) and raises (x,::x) and etc. are not disallowed
      } elsif ($item->{node}->isa ('Whatpm::WebIDL::Const')) {
        $check_const_value->($item);
      }
    } elsif ($item->{node}->isa ('Whatpm::WebIDL::Argument') or
             $item->{node}->isa ('Whatpm::WebIDL::ExceptionMember')) {
      if ($item->{has_arg_xattr}->{variadic} and
          $item->{node}->isa ('Whatpm::WebIDL::Argument')) {
        $onerror->(type => 'argument after variadic',
                   node => $item->{node},
                   level => $levels->{fact});
      }

      ## ISSUE: No uniqueness constraints for arguments in an operation,
      ## so we don't check it for arguments.

      ## ISSUE: For extended attributes, semantics of the argument
      ## (e.g. the identifier is given by the |identifier| in the |Argument|)
      ## is not explicitly defined.  In addition, no uniqueness constraint
      ## is defined, so we don't check it for arguments.

      my $name = $item->{node}->node_name;
      if ($item->{defined_members}->{$name}) {
        $onerror->(type => 'duplicate member',
                   level => 'm',
                   node => $item->{node});
      } else {
        $item->{defined_members}->{$name} = 1;
      }

      my $type = $item->{node}->type;
      if ($type =~ /\A::[^:]+::\z/) { # note that sequence<> not allowed
        #
      } else { # scoped name
        my $def = $resolve->($type, $item->{scope});
        
        unless ($def and
                ($def->{node}->isa ('Whatpm::WebIDL::Interface') or
                 $def->{node}->isa ('Whatpm::WebIDL::Typedef') or
                 $def->{node}->isa ('Whatpm::WebIDL::Valuetype'))) {
          $onerror->(type => 'type not defined',
                     level => 'm',
                     node => $item->{node},
                     text => $item->{node}->type_text);
        }
      }
    }

    my $xattrs = $item->{node}->{xattrs} || [];
    my $has_xattr;
    X: for my $xattr (@$xattrs) {
      my $xattr_name = $xattr->node_name;
      my $xattr_def = $xattr_defs->{$xattr_name};

      unless ($xattr_def) {
        $onerror->(type => 'unknown xattr',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{uncertain});
        next X;
      }

      A: {
        for my $cls (keys %{$xattr_def->{allowed_type} or {}}) {
          if ($item->{node}->isa ('Whatpm::WebIDL::' . $cls)) {
            if ($cls eq 'Interface' and
                $item->{node}->is_forward_declaration) {
              #
            } else {
              last A;
            }
          }
        }

        $onerror->(type => 'xattr not applicable',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{fact});
        next X;
      } # A

      if ($has_xattr->{$xattr_name} and not $xattr_def->{allow_multiple}) {
        ## ISSUE: Whether multiple extended attributes with the same
        ## name are allowed is not explicitly specified in the spec.
        ## It is, however, specified that some extended attributes may
        ## be specified more than once.
        $onerror->(type => 'duplicate xattr',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{warn});
      }
      $has_xattr->{$xattr_name} = 1;

      if (not $xattr_def->{allow_id} and defined $xattr->value) {
        $onerror->(type => 'xattr id not allowed',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{must});
      }
      if (not $xattr_def->{allow_arglist} and $xattr->has_argument_list) {
        $onerror->(type => 'xattr arglist not allowed',
                   text => $xattr_name,
                   node => $xattr,
                   level => $levels->{must});
      }

      $xattr_def->{check}->($self, $onerror, $levels, $items, $item,
                            $xattr, $xattr_name, $resolve, $constructors);
    }

    if (not $has_xattr->{NoInterfaceObject} and
        (($item->{node}->isa ('Whatpm::WebIDL::Interface') and
          not $item->{node}->is_forward_declaration) or
         $item->{node}->isa ('Whatpm::WebIDL::Exception'))) {
      my $id = $item->{node}->node_name;
      if ($constructors->{$id} and
          $constructors->{$id}->{is_named_constructor}) {
        $onerror->(type => 'duplicate constructor name',
                   value => $id,
                   node => $constructors->{$id}->{is_named_constructor},
                   level => $levels->{must});
      } else {
        ## NOTE: Duplication is not checked in this case, since any
        ## duplication of interface/exception identifiers are detected
        ## by the parser.
        $constructors->{$id} = {node => $item->{node}};
      }
    }
  }
} # check

package Whatpm::WebIDL::Definition;
push our @ISA, 'Whatpm::WebIDL::Node';

sub new ($$) {
  return bless {child_nodes => [], node_name => ''.$_[1]}, $_[0];
} # new

sub set_extended_attribute_node ($$) {
  my $self = shift;
  ## TODO: check
  push @{$self->{xattrs} ||= []}, shift;
} # set_extended_attribute_node

sub _xattrs_text ($) {
  my $self = shift;

  unless ($self->{xattrs} and
          @{$self->{xattrs}}) {
    return '';
  }

  my $r = '[';
  $r .= join ', ', map {$_->idl_text} @{$self->{xattrs}};
  $r .= ']';
  return $r;
} # _xattrs_text

sub qualified_name ($) {
  my $self = shift;

  my $parent = $self->{parent_node};
  if ($parent and $parent->isa ('Whatpm::WebIDL::Definition')) {
    return $parent->qualified_name . '::' . $self->{node_name};
  } else {
    return '::' . $self->{node_name};
  }
} # qualified_name

sub type ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->{type} = $_[1];
    } else {
      $_[0]->{type} = '::any::';
    }
  }
  return $_[0]->{type};
} # type

  my $serialize_type;
  $serialize_type = sub ($) {
    my $type = shift;
    if ($type =~ s/^::::sequence:::://) {
      return 'sequence<' . $serialize_type->($type) . '>';
    } elsif ($type =~ /\A::([^:]+)::\z/) {
      return $1;
    } else {
      $type =~ s/::DOMString::::\z/::DOMString/;
      return $type; ## TODO: escape identifiers...
    }
  }; # $serialize_type

sub type_text ($) {
  my $type = $_[0]->{type};
  return undef unless defined $type;

  return $serialize_type->($type);
} # type_text

package Whatpm::WebIDL::Module;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= 'module ' . $self->node_name . " {\x0A\x0A"; ## TODO: escape
  for (@{$self->{child_nodes}}) {
    $r .= $_->idl_text;
  }
  $r .= "\x0A};\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Interface;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{inheritances} = [];
  return $self;
} # new

sub append_inheritance ($$) {
  my $self = shift;
  my $scoped_name = shift;
  push @{$self->{inheritances}}, $scoped_name;
} # append_inheritance

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= 'interface ' . $self->node_name;

  if ($self->{is_forward_declaration}) {
    $r .= ";\x0A";
    return $r;
  }

  if (@{$self->{inheritances}}) {
    $r .= ' : '; ## TODO: ...
    $r .= join ', ', map {$serialize_type->($_)} @{$self->{inheritances}};
  }
  $r .= " {\x0A"; ## TODO: escape
  for (@{$self->{child_nodes}}) {
    $r .= '  ' . $_->idl_text;
  }
  $r .= "};\x0A";
  return $r;
} # idl_text

sub is_forward_declaration ($;$) {
  if (@_ > 1) {
    if ($_[1]) {
      $_[0]->{is_forward_declaration} = 1;
    } else {
      delete $_[0]->{is_forward_declaration};
    }
  }

  return $_[0]->{is_forward_declaration};
} # is_forward_declaration

package Whatpm::WebIDL::Exception;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= 'exception ' . $self->node_name . " {\x0A"; ## TODO: escape
  for (@{$self->{child_nodes}}) {
    $r .= '  ' . $_->idl_text;
  }
  $r .= "};\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Typedef;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = '::any::';
  return $self;
} # new

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  my $node_name = $self->node_name;
  $node_name = 'DOMString' if $node_name eq '::DOMString::';
  ## TODO: escape
  $r .= 'typedef ' . $self->type_text . ' ' . $node_name . ";\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Valuetype;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = '::boolean::';
  return $self;
} # new

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  my $name = $self->node_name;
  $name = 'DOMString' if $name eq '::DOMString::';
  ## TODO: escape
  $r .= 'valuetype ' . $name . ' ' . $self->type_text . ";\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::InterfaceMember;
push our @ISA, 'Whatpm::WebIDL::Node';

sub new ($$) {
  return bless {node_name => ''.$_[1]}, $_[0];
} # new

sub child_nodes ($) { return [] }

*_xattrs_text = \&Whatpm::WebIDL::Definition::_xattrs_text;

*set_extended_attribute_node = \&Whatpm::WebIDL::Definition::set_extended_attribute_node;

*type = \&Whatpm::WebIDL::Definition::type;

*type_text = \&Whatpm::WebIDL::Definition::type_text;

package Whatpm::WebIDL::Const;
push our @ISA, 'Whatpm::WebIDL::Definition', 'Whatpm::WebIDL::InterfaceMember';

sub new ($$) {
  my $self = shift->SUPER::new (@_); # Definition->new should be called
  $self->{type} = '::boolean::';
  $self->{value} = ['FALSE'];
  return $self;
} # new

sub value ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->{value} = $_[1];
    } else {
      $_[0]->{value} = ['FALSE'];
    }
  }
  
  return $_[0]->{value};
} # value

sub value_text ($) {
  my $value = $_[0]->{value};

  if ($value->[0] eq 'TRUE' or $value->[0] eq 'FALSE') {
    return $value->[0];
  } elsif ($value->[0] eq 'integer' or $value->[0] eq 'float') {
    ## TODO: format
    return $value->[1];
  } else {
    return undef;
  }
} # value_text

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= 'const ' . $self->type_text . ' ' . $self->node_name . ' = ' . $self->value_text . ";\x0A"; ## TODO: escape
  return $r;
} # idl_text

package Whatpm::WebIDL::Attribute;
push our @ISA, 'Whatpm::WebIDL::InterfaceMember';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = '::any::';
  $self->{getraises} = [];
  $self->{setraises} = [];
  return $self;
} # new

sub append_getraises ($$) {
  ## TODO: error check, etc.
  push @{$_[0]->{getraises}}, $_[1];
} # append_getraises

sub append_setraises ($$) {
  ## TODO: error check, etc.
  push @{$_[0]->{setraises}}, $_[1];
} # append_setraises

sub readonly ($;$) {
  if (@_ > 1) {
    $_[0]->{readonly} = $_[1];
  }

  return $_[0]->{readonly};
} # readonly

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= ($self->readonly ? 'readonly ' : '') . 'attribute ' . $self->type_text . ' ' . $self->node_name;
  ## TODO: escape
  if (@{$self->{getraises}}) {
    $r .= ' getraises (';
    ## todo: ...
    $r .= join ', ', map {$serialize_type->($_)} @{$self->{getraises}};
    $r .= ')';
  }
  if (@{$self->{setraises}}) {
    $r .= ' setraises (';
    ## todo: ...
    $r .= join ', ', map {$serialize_type->($_)} @{$self->{setraises}};
    $r .= ')';
  }
  $r .= ";\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Operation;
push our @ISA, 'Whatpm::WebIDL::InterfaceMember';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = '::any::';
  $self->{child_nodes} = [];
  $self->{raises} = [];
  return $self;
} # new

sub append_raises ($$) {
  ## TODO: error check, etc.
  push @{$_[0]->{raises}}, $_[1];
} # append_raises

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= $self->type_text . ' ' . $self->node_name . ' ('; ## TODO: escape
  $r .= join ', ', map {$_->idl_text} @{$self->{child_nodes}};
  $r .= ')';
  if (@{$self->{raises}}) {
    $r .= ' raises (';
    ## todo: ...
    $r .= join ', ', map {$serialize_type->($_)} @{$self->{raises}};
    $r .= ')';
  }
  $r .= ";\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Argument;
push our @ISA, 'Whatpm::WebIDL::Node';

sub new ($$) {
  return bless {node_name => ''.$_[1], type => '::any::'}, $_[0];
} # new

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= 'in ' . $self->type_text . ' ' . $self->node_name; ## TODO: escape
  return $r;
} # idl_text

*_xattrs_text = \&Whatpm::WebIDL::Definition::_xattrs_text;

*set_extended_attribute_node = \&Whatpm::WebIDL::Definition::set_extended_attribute_node;

*type = \&Whatpm::WebIDL::Definition::type;

*type_text = \&Whatpm::WebIDL::Definition::type_text;

package Whatpm::WebIDL::ExceptionMember;
push our @ISA, 'Whatpm::WebIDL::Node';

sub new ($$) {
  return bless {node_name => ''.$_[1], type => '::any::'}, $_[0];
} # new

sub idl_text ($) {
  my $self = shift;
  my $r = $self->_xattrs_text;
  $r .= ' ' if length $r;
  $r .= $self->type_text . ' ' . $self->node_name . ";\x0A"; ## TODO: escape
  return $r;
} # idl_text

*_xattrs_text = \&Whatpm::WebIDL::Definition::_xattrs_text;

*set_extended_attribute_node = \&Whatpm::WebIDL::Definition::set_extended_attribute_node;

*type = \&Whatpm::WebIDL::Definition::type;

*type_text = \&Whatpm::WebIDL::Definition::type_text;
             
package Whatpm::WebIDL::ExtendedAttribute;
push our @ISA, 'Whatpm::WebIDL::Node';

sub new ($$) {
  return bless {child_nodes => [], node_name => ''.$_[1]};
} # new

sub has_argument_list ($;$) {
  if (@_ > 1) {
    if ($_[1]) {
      $_[0]->{has_argument_list} = 1;
    } else {
      delete $_[0]->{has_argument_list};
    }
  }
  
  return ($_[0]->{has_argument_list} or scalar @{$_[0]->{child_nodes}});
} # has_argument_list

sub idl_text ($) {
  my $self = shift;
  my $r = $self->node_name; ## TODO:] esceape
  if (defined $self->{value}) {
    $r .= '=' . $self->{value}; ## TODO: escape
  }
  if ($self->has_argument_list) {
    $r .= ' (';
    $r .= join ', ', map {$_->idl_text} @{$self->{child_nodes}};
    $r .= ')';
  }
  return $r;
} # idl_text

sub value ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->{value} = ''.$_[1];
    } else {
      delete $_[0]->{value};
    }
  }

  return $_[0]->{value};
} # value

1;
