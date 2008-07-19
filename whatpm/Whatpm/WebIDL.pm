package Whatpm::WebIDL;
use strict;

package Whatpm::WebIDL::Parser;

my $integer = qr/-?0([0-7]*|[Xx][0-9A-Fa-f]+)|[1-9][0-9]*/;
my $float = qr/-?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+-]?[0-9]+)?|[0-9]+[Ee][+-]?[0-9]+/;
my $identifier = qr/[A-Z_a-z][0-9A-Z_a-z]*/;
my $whitespace = qr<[\t\n\r ]+|[\t\n\r ]*((//.*|/\*.*?\*/)[\t\n\r ]*)+>;

sub new ($) {
  my $self = bless {
    must_level => 'm',
    should_level => 's',
    warn_level => 'w',
    info_level => 'i',
  }, $_[0];
  return $self;
} # new

sub parse_char_string ($$;$) {
  my $self = shift;
  my $s = ref $_[0] ? $_[0] : \($_[0]);

  my $defs = Whatpm::WebIDL::Definitions->new;

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
    my $name = [];

    ## NOTE: "DOMString" is not a scoped name, while "::DOMString"
    ## and "x::DOMString" are.

    if ($token->{type} eq 'identifier') {
      ## TODO: unescape
      push @$name, $token->{value};
      $token = $get_next_token->();
      while ($token->{type} eq '::') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          ## TODO: unescape
          push @$name, $token->{value};
          $token = $get_next_token->();
        } elsif ($token->{type} eq 'DOMString') {
          push @$name, '::DOMString::';
          $token = $get_next_token->();
          last;
        }
      }
    } elsif ($token->{type} eq '::') {
      push @$name, '';
      while ($token->{type} eq '::') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          ## TODO: unescape
          push @$name, $token->{value};
          $token = $get_next_token->();
        } elsif ($token->{type} eq 'DOMString') {
          push @$name, '::DOMString::';
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
    return $name;
  }; # $get_scoped_name

  my $get_type;
  $get_type = sub {
    my $r;
    if ({
      void => 1, any => 1, boolean => 1, octet => 1, float => 1,
      DOMString => 1, Object => 1, short => 1,
    }->{$token->{type}}) {
      $r = ['::'.$token->{type}.'::'];
      $token = $get_next_token->();
    } elsif ($token->{type} eq 'unsigned') {
      $token = $get_next_token->();
      if ($token->{type} eq 'short') {
        $r = ['::unsigned '.$token->{type}.'::'];
        $token = $get_next_token->();
      } elsif ($token->{type} eq 'long') {
        $token = $get_next_token->();
        if ($token->{type} eq 'long') {
          $r = ['::unsigned long long::'];
          $token = $get_next_token->();
        } else {
          $r = ['::unsigned long::'];
          # reconsume
        }
      } else {
        $onerror->(type => 'unsigned', level => $self->{must_level});
        return undef;
      }
    } elsif ($token->{type} eq 'long') {
      $token = $get_next_token->();
      if ($token->{type} eq 'long') {
        $r = ['::long long::'];
        $token = $get_next_token->();
      } else {
        $r = ['::long::'];
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
              $r = ['::sequence::', $type];
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
      if ($token->{type} eq '[') {
        $xattrs = {};
        $token = $get_next_token->();
        $state = 'before xattr';
        $next_state = 'before def';
      } elsif ({module => 1, interface => 1, exception => 1,
               typedef => 1, valuetype => 1, const => 1}->{$token->{type}}) {
        $xattrs = {};
        # reconsume
        $state = 'before def';
      } elsif ($token->{type} eq '}' and @current > 1) {
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before definitions';
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
      
      ## TODO: methodType methodName ([broken xattr] ...); is not well
      ## handled on forward-compatible parsing (i.e. pop @current).

      if ($token->{type} eq 'identifier') {
        ## TODO: _escape
        ## ISSUE: Duplicate attributes
        ## ISSUE: Unkown attributes
        $xattrs->{$token->{value}} = '';
        $last_xattr = $token->{value};
        $token = $get_next_token->();
        $state = 'after xattr';
      } elsif ($token->{type} eq 'eof') {
        $onerror->(type => 'before xattr:eof', level => 'm', token => $token);
        $token = $get_next_token->();
        $state = 'after xattrlist';
      } else {
        $onerror->(type => 'before xattr', level => 'm', token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'after xattr') {
      if ($token->{type} eq '=') {
        $token = $get_next_token->();
        $state = 'before xattrarg';
      } else {
        # reconsume
        $state = 'after xattrarg';
      }
    } elsif ($state eq 'before xattrarg') {
      if ($token->{type} eq 'identifier') {
        ## TODO: escape
        $xattrs->{$last_xattr} = $token->{value};
        $token = $get_next_token->();
        $state = 'after xattrarg';
      } elsif ($token->{type} eq 'eof') {
        # any extended attributes are ignored
        $onerror->(type => 'after xattrarg:eof', level => 'm',
                   token => $token);
        last;
      } else {
        $onerror->(type => 'after xattrarg', level => 'm', token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';        
      }
    } elsif ($state eq 'after xattrarg') {
      if ($token->{type} eq ',') {
        $token = $get_next_token->();
        $state = 'before xattr';
      } elsif ($token->{type} eq ']') {
        $token = $get_next_token->();
        $state = $next_state; # 'before def' or 'before interface member'
      } elsif ($token->{type} eq 'eof') {
        # any extended attributes are ignored
        $onerror->(type => 'after xattr:eof', level => 'm', token => $token);
        last;
      } else {
        $onerror->(type => 'after xattr', level => 'm', token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'before def') {
      if ($token->{type} eq 'module') {
        $token = $get_next_token->();
        if ($token->{type} eq 'identifier') {
          ## TODO: escape
          push @current, Whatpm::WebIDL::Module->new ($token->{value});
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
          ## TODO: escape
          push @current, Whatpm::WebIDL::Interface->new ($token->{value});
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
          ## TODO: escape
          push @current, Whatpm::WebIDL::Exception->new ($token->{value});
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
          ## TODO: escape
          push @current, Whatpm::WebIDL::Valuetype->new ($token->{value});
          $token = $get_next_token->();
          $state = 'before boxed type';
          next;
        } elsif ($token->{type} eq 'DOMString') {
          push @current, Whatpm::WebIDL::Valuetype->new ('::DOMString::');
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
                    $current[-1]->type
                        (['::sequence::', ['::unsigned short::']]);
                    $token = $get_next_token->();
                    $state = 'before semicolon';
                    $next_state = 'before definitions';
                    next;
                  } else {
                    $onerror->(type => 'valuetype DOMString sequence lt unsigned short gt',
                               level => $self->{must_level});
                    #                
                  }
                } else {
                  $onerror->(type => 'valuetype DOMString sequence lt unsigned short',
                             level => $self->{must_level});
                  #                
                }
              } else {
                $onerror->(type => 'valuetype DOMString sequence lt unsigned',
                           level => $self->{must_level});
                #
              }
            } else {
              $onerror->(type => 'valuetype DOMString sequence lt',
                         level => $self->{must_level});
              #
            }
          } else {
            $onerror->(type => 'valuetype DOMString sequence',
                       level => $self->{must_level});
            #
          }
          shift @current; # valuetype
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
      } elsif ($token->{type} eq 'eof') {
        ## NOTE: Any extended attributes are ignored.
        $onerror->(type => 'before def:eof', level => 'm', token => $token);
        last;
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
        pop @current; # interface
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
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
          pop @current; # operation/attribute
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before interface member';
        }
      } else {
        $onerror->(type => 'scoped name', level => $self->{must_level});
        pop @current; # operation/attribute
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before interface member';
      }
    } elsif ($state eq 'before interface block') {
      if ($token->{type} eq '{') {
        $token = $get_next_token->();
        $state = 'before members';
        $next_state = 'before interface member';
      } else {
        $onerror->(type => 'before interface block',
                   level => $self->{must_level});
        # reconsume
        pop @current; # interface
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
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
        pop @current; # exception
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'before members') {
      if ($token->{type} eq '[') {
        $token = $get_next_token->();
        $state = 'before xattr';
        #$next_state = $next_state; # 'before interface member' or ...
      } elsif ($token->{type} eq '}') {
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before definitions';
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
        $onerror->(type => 'before interface member:eof',
                   level => $self->{must_level});
        $current[-2]->append_child ($current[-1]);
        last;
      } else {
        $onerror->(type => 'before interface member',
                   level => $self->{must_level});
        # reconsume
        pop @current; # interface
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before interface member';
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
        $onerror->(type => 'before exception member:eof',
                   level => $self->{must_level});
        $current[-2]->append_child ($current[-1]);
        last;
      } else {
        $onerror->(type => 'before exception member',
                   level => $self->{must_level});
        # reconsume
        pop @current; # interface
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before exception member';
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
          shift @current; # valuetype
          # reconsume
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before definitions';
        }
      } else {
        $onerror->(type => 'before boxed type', level => $self->{must_level});
        shift @current; # valuetype
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
        $current[-1]->type ($current_type);
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before definitions';
      } elsif ($token->{type} eq 'DOMString') {
        push @current, Whatpm::WebIDL::Typedef->new ('::DOMString::');
        $current[-1]->type ($current_type);
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
        ## TODO: unescape
        push @current, Whatpm::WebIDL::Const->new ($token->{value});
        $current[-1]->type ($current_type);
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
      } elsif ($token->{type} eq 'integer' or $token->{type} eq 'float') {
        $current[-1]->value ([$token->{type}, $token->{value}]);
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
          pop @current; # operation
          $state = 'ignore';
          $nest_level = 0;
          $next_state = 'before interface member';
        }
      } else {
        $onerror->(type => 'before type', level => $self->{must_level});
        pop @current; # operation
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before interface member';
      }
    } elsif ($state eq 'before attribute identifier') {
      if ($token->{type} eq 'identifier') {
        ## TODO: unescape
        push @current, Whatpm::WebIDL::Attribute->new ($token->{value});
        $current[-1]->readonly ($read_only);
        $current[-1]->type ($current_type);
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
        ## TODO: unescape
        push @current, Whatpm::WebIDL::ExceptionMember->new ($token->{value});
        $current[-1]->type ($current_type);
        $token = $get_next_token->();
        $state = 'before semicolon';
        $next_state = 'before exception member';
      } else {
        $onerror->(type => 'exception member identifier',
                   level => $self->{must_level});
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before exception member';
      }
    } elsif ($state eq 'before operation identifier') {
      if ($token->{type} eq 'identifier') {
        ## TODO: unescape
        push @current, Whatpm::WebIDL::Operation->new ($token->{value});
        $current[-1]->type ($current_type);
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
          pop @current;
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
        ## TODO: unescape
        my $arg = Whatpm::WebIDL::Argument->new ($token->{value});
        $arg->type ($current_type);
        $current[-1]->append_child ($arg);
        $token = $get_next_token->();
        if ($token->{type} eq ')') {
          $token = $get_next_token->();
          $state = 'before raises';
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
      pop @current; # operation
      # reconsume
      $state = 'ignore';
      $nest_level = 0;
      $next_state = 'before interface member';
    } elsif ($state eq 'before argument') {
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
        pop @current; # operation
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before interface member';
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
        pop @current; # operation
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before interface member';
      }
    } elsif ($state eq 'before semicolon') {
      if ($token->{type} eq ';') {
        $current[-2]->append_child ($current[-1]);
        pop @current;
        $token = $get_next_token->();
        $state = {
          #'before definitions',
          'before interface member' => 'before members', # keep $next_state
          'before exception member' => 'before members', #   as is
        }->{$next_state} || $next_state;
      } else {
        pop @current;
        $onerror->(type => 'before semicolon', level => 'm',
                   token => $token);
        # reconsume
        $state = 'ignore';
        $nest_level = 0;
        $next_state = 'before definitions';
      }
    } elsif ($state eq 'ignore') {
      if (($nest_level == 0 and $token->{type} eq ';') or
          (@current > 1 and not $nest_level and $token->{type} eq '}')) {
        $token = $get_next_token->();
        $state = {
          #'before definitions',
          'before interface member' => 'before members', # keep $next_state
          'before exception member' => 'before members', #   as is
        }->{$next_state} || $next_state;
      } elsif ($token->{type} eq '{') {
        $nest_level++;
        $token = $get_next_token->();
        # stay in the state
      } elsif ($nest_level and $token->{type} eq '}') {
        $nest_level--;
        $token = $get_next_token->();
        # stay in the state
      } elsif ($token->{type} eq 'eof') {
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
    $onerror->(type => 'block not closed', level => $self->{must_level});    
  }

  $get_type = undef; # unlink loop

  return $defs;
} # parse_char_string

package Whatpm::WebIDL::Definitions;

sub new ($) {
  return bless {child_nodes => []}, $_[0];
} # new

*append_child = \&Whatpm::WebIDL::Definition::append_child;

sub idl_text ($) {
  return join "\x0A", map {$_->idl_text} @{$_[0]->{child_nodes}};
} # idl_text

package Whatpm::WebIDL::Definition;

sub new ($$) {
  return bless {child_nodes => [], node_name => ''.$_[1]}, $_[0];
} # new

sub append_child ($$) {
  my $self = shift;
  my $child = shift;
  
  ## TODO: child type
  ## TODO: parent check

  push @{$self->{child_nodes}}, $child;

  return $child;
} # append_child

sub node_name ($) {
  return $_[0]->{node_name};
} # node_name

sub idl_text ($) {
  return '[[ERROR: ' . (ref $_[0]) . '->idl_text]]';
} # idl_text

sub type ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->{type} = $_[1];
    } else {
      $_[0]->{type} = ['::any::'];
    }
  }
  return $_[0]->{type};
} # type

sub type_text ($) {
  my $type = $_[0]->{type};
  return undef unless defined $type;
  
  if ($type->[0] eq '::sequence::') {
    return 'sequence<' . (join '::', @{$type->[1]}) . '>'; ## TODO: escape, nested
  } else {
    return join '::', @$type; ## TODO: escape
  }
} # type_text

package Whatpm::WebIDL::Module;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub idl_text ($) {
  my $r = 'module ' . $_[0]->node_name . "{\x0A\x0A"; ## TODO: escape
  for (@{$_[0]->{child_nodes}}) {
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
  my $r = 'interface ' . $self->node_name;
  if (@{$self->{inheritances}}) {
    $r .= ' : '; ## TODO: ...
    $r .= join ', ', map {join '::', @{$_}} @{$self->{inheritances}};
  }
  $r .= " {\x0A"; ## TODO: escape
  for (@{$self->{child_nodes}}) {
    $r .= '  ' . $_->idl_text;
  }
  $r .= "};\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Exception;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub idl_text ($) {
  my $r = 'exception ' . $_[0]->node_name . "{\x0A"; ## TODO: escape
  for (@{$_[0]->{child_nodes}}) {
    $r .= '  ' . $_->idl_text;
  }
  $r .= "};\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Typedef;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = ['::any::'];
  return $self;
} # new

sub idl_text ($) {
  ## TODO: escape
  return 'typedef ' . $_[0]->type_text . ' ' . $_[0]->node_name . ";\x0A";
} # idl_text

package Whatpm::WebIDL::Valuetype;
push our @ISA, 'Whatpm::WebIDL::Definition';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = ['::boolean::'];
  return $self;
} # new

sub idl_text ($) {
  ## TODO: escape
  return 'valuetype ' . $_[0]->node_name . ' ' . $_[0]->type_text . ";\x0A";
} # idl_text

package Whatpm::WebIDL::InterfaceMember;

sub new ($$) {
  return bless {node_name => ''.$_[1]}, $_[0];
} # new

*idl_text = \&Whatpm::WebIDL::Definition::idl_text;

*node_name = \&Whatpm::WebIDL::Definition::node_name;

*type = \&Whatpm::WebIDL::Definition::type;

*type_text = \&Whatpm::WebIDL::Definition::type_text;

package Whatpm::WebIDL::Const;
push our @ISA, 'Whatpm::WebIDL::Definition', 'Whatpm::WebIDL::InterfaceMember';

sub new ($$) {
  my $self = shift->SUPER::new (@_); # Definition->new should be called
  $self->{type} = ['::boolean::'];
  $self->{value} = ['FALSE'];
  return $self;
} # new

sub value ($;$) {
  if (@_ > 1) {
    $_[0]->{value} = $_[1];
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
  return 'const ' . $_[0]->type_text . ' ' . $_[0]->node_name . ' = ' . $_[0]->value_text . ";\x0A"; ## TODO: escape
} # idl_text

package Whatpm::WebIDL::Attribute;
push our @ISA, 'Whatpm::WebIDL::InterfaceMember';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = ['::any::'];
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
  my $r = ($self->readonly ? 'readonly ' : '') . 'attribute ' . $self->type_text . ' ' . $self->node_name;
  ## TODO: escape
  if (@{$self->{getraises}}) {
    $r .= ' getraises (';
    ## todo: ...
    $r .= join ', ', map {join '::', @{$_}} @{$self->{getraises}};
    $r .= ')';
  }
  if (@{$self->{setraises}}) {
    $r .= ' setraises (';
    ## todo: ...
    $r .= join ', ', map {join '::', @{$_}} @{$self->{setraises}};
    $r .= ')';
  }
  $r .= ";\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Operation;
push our @ISA, 'Whatpm::WebIDL::InterfaceMember';

sub new ($$) {
  my $self = shift->SUPER::new (@_);
  $self->{type} = ['::any::'];
  $self->{child_nodes} = [];
  $self->{raises} = [];
  return $self;
} # new

*append_child = \&Whatpm::WebIDL::Definition::append_child;

sub append_raises ($$) {
  ## TODO: error check, etc.
  push @{$_[0]->{raises}}, $_[1];
} # append_raises

sub idl_text ($) {
  my $self = shift;
  my $r = $self->type_text . ' ' . $self->node_name . ' ('; ## TODO: escape
  $r .= join ', ', map {$_->idl_text} @{$self->{child_nodes}};
  $r .= ')';
  if (@{$self->{raises}}) {
    $r .= ' raises (';
    ## todo: ...
    $r .= join ', ', map {join '::', @{$_}} @{$self->{raises}};
    $r .= ')';
  }
  $r .= ";\x0A";
  return $r;
} # idl_text

package Whatpm::WebIDL::Argument;

sub new ($$) {
  return bless {node_name => ''.$_[1], type => ['::any::']}, $_[0];
} # new

sub idl_text ($) {
  return 'in ' . $_[0]->type_text . ' ' . $_[0]->node_name; ## TODO: escape
} # idl_text

*node_name = \&Whatpm::WebIDL::Definition::node_name;

*type = \&Whatpm::WebIDL::Definition::type;

*type_text = \&Whatpm::WebIDL::Definition::type_text;

package Whatpm::WebIDL::ExceptionMember;

sub new ($$) {
  return bless {node_name => ''.$_[1], type => ['::any::']}, $_[0];
} # new

sub idl_text ($) {
  return $_[0]->type_text . ' ' . $_[0]->node_name . ";\x0A"; ## TODO: escape
} # idl_text

*node_name = \&Whatpm::WebIDL::Definition::node_name;

*type = \&Whatpm::WebIDL::Definition::type;

*type_text = \&Whatpm::WebIDL::Definition::type_text;

1;
