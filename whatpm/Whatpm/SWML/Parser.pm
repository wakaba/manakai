package Whatpm::SWML::Parser;
use strict;


sub new ($) {
  my $self = bless {
  }, $_[0];
  return $self;
} # new

sub parse_char_string ($$$;$) {
  my $self = shift;
  my @s = split /\x0D\x0A?|\x0A/, ref $_[0] ? ${$_[0]} : $_[0], -1;

  my $doc = $_[1];
  $doc->inner_html
      ('<html xmlns="http://www.w3.org/1999/xhtml"><head/><body/></html>');
  for ($doc,
       $doc->document_element,
       $doc->document_element->first_child,
       $doc->document_element->last_child) {
    $_->set_user_data (manakai_source_line => 1);
    $_->set_user_data (manakai_source_column => 1);
  }
  $self->{oe} = {node => $doc->document_element->last_child,
                 section_depth => 0,
                 quotation_depth => 0,
                 list_depth => 0};
  
  my $_onerror = $_[2] || sub {
    my %opt = @_;
    my $r = 'Line ' . $opt{line} . ' column ' . $opt{column} . ': ';

    if ($opt{token}) {
      $r .= 'Token ' . (defined $opt{token}->{value}
                        ? $opt{token}->{value} : $opt{token}->{type}) . ': ';
    }

    $r .= $opt{type} . ';' . $opt{level};
    
    warn $r . "\n";
  }; # $_onerror

  my $line = 0;
  my $column = 0;
  my $token;
  my @nt;

  my $onerror = sub {
    $_onerror->(line => $line, column => $column, token => $token, @_);
  }; # $onerror

  my $continuous_line;

  my $tokenize_text = sub {
    my $s = shift; # ref

    if ($$s =~ s/^\[([0-9]+)\]//) {
      push @nt, {type => ELEMENT_TOKEN,
                 local_name => 'anchor-end', namespace => $SW09_NS,
                 anchor => $1, content => '[' . $1 . ']'};
      $column += $+[0] - $-[0];
    }
    
    while (length $$s) {
      if ($$s =~ s/^\[\[#([a-z-}+)//) {
        $column = $+[0] - $-[0];
        my $t = {type => FORM_TOKEN, name => $1,
                 line => $line, column => $column};
        if ($$s =~ s/^\(([^()\\]*)\)//) {
          $t->{id} = $1;
          $column += $+[0] - $-[0];
        }
        my @param;
        while ($$s =~ s/^:/) {
          if ($$s =~ s/^'((?>[^'\\]|\\.)*)//) {
            $column += 1 + $+[0] - $-[0];
            my $n = $1;
            $n =~ tr/\\//d;
            push @param, $n;
            $column++ if $$s =~ s/\A\\\z//;
            $column++ if $$s =~ s/^'//;
          } elsif ($$s =~ s/^([^':][^:]*)//) {
            $column += 1 + $+[0] - $-[0];
            push @param, $1;
          }
        }
        $t->{parameters} = \@param;
        $column += 2 if $$s =~ s/^\]\]//;
        push @nt, $t;
      } elsif ($$s =~ s/^\[\[//) {
        push @nt, {type => INLINE_START_TAG_TOKEN};
        $column += 2;
      } elsif ($$s =~ s/^\[([A-Z]+)(?>\(([^()\\]*)\))?(?>\@[0-9A-Za-z-]*)?\[//) {
        push @nt, {type => INLINE_START_TAG_TOKEN,
                   tag_name => $1, classes => $2, language => $3,
                   line => $line, column => $column};
        $column += $+[0] - $-[0];
      } elsif ($$s =~ s/^\]\]//) {
        push @nt, {type => INLINE_END_TAG_TOKEN,
                   line => $line, column => $column};
        $column += 2;
      } elsif ($$s =~ s/^(\]?)<([0-9A-Za-z%+._-]+)://) {
        my $t = {type => $1 ? INLINE_END_TAG_TOKEN : ELEMENT_TOKEN,
                 res_scheme => $2, res_parameter => '',
                 line => $line, column => $column};
        $column += $+[0] - $-[0];

        while (length $$s) {
          if ($$s =~ s/^([^>"]+)//) {
            $t->{res_parameter} .= $1;
            $column += $+[0] - $-[0];
          } elsif ($$s =~ s/^("(?>[^"\\]|\\.)*)//) {
            $t->{res_parameter} .= $1;
            $column += $+[0] - $-[0];
            $column++ if $$s =~ s/\A\\\z//;
            $column++ if $$s =~ s/^"//;
          } else {
            last;
          }
        }

        $column++ if $$s =~ s/^>//;

        $t->{content} = $t->{res_scheme} . ':' . $t->{res_parameter};
        if ($t->{res_scheme} !~ /[A-Z]/) {
          $t->{res_parameter} = $t->{content};
          $t->{res_scheme} = 'URI';
        }
        
        if ($t->{type} == INLINE_END_TAG_TOKEN) {
          $column++ if $$s =~ s/^\]//;
        } else {
          $t->{local_name} = 'anchor-external';
          $t->{namespace} = $SW09_NS;
        }
        push @nt, $t;
      } elsif ($$s =~ s/^\]>>([0-9]+)\]//) {
        push @nt, {type => INLINE_END_TAG_TOKEN,
                   anchor => $1,
                 line => $line, column => $column};
        $column += $+[0] - $-[0];
      } elsif ($$s =~ s/^\][\x09\x20]*(?>\@([0-9a-zA-Z-]*))?\[//) {
        push @nt, {type => INLINE_MIDDLE_TAG_TOKEN,
                   language => $1,
                   line => $line, column => $column};
        $column += $+[0] - $-[0];
      } elsif ($$s =~ s/\^''('?)//) {
        push @nt, {type => $1 ? STRONG_TOKEN : EMPHASIS_TOKEN,
                   line => $line, column => $column};
        $column += $+[0] - $-[0];
      } elsif ($$s =~ s/^>>([0-9]+)//) {
        push @nt, {type => ELEMENT_TOKEN,
                   local_name => 'anchor-internal', namespace => $SW09_NS,
                   anchor => $1,
                   line => $line, column => $column};
        $column += $+[0] - $-[0];
      } elsif ($$s =~ s/^__&&//) {
        if ($$s =~ s/^(.+?)&&__//) {
          push @nt, {type => ELEMENT_TOKEN,
                     local_name => 'replace', namespace => $SW09_NS,
                     by => $1,
                     line => $line, column => $column};
          $column += 4 + $+[0] - $-[0];
        } else {
          push @nt, {type => CHARACTER_TOKEN,
                     data => '__&&',
                     line => $line, column => $column};
          $column += 4;
        }
      } elsif ($$s =~ s/^([^<>\['_]+)//) {
        push @nt, {type => CHARACTER_TOKEN, data => $1,
                   line => $line, column => $column};
        $column += $+[0] - $-[0];
      } else {
        push @nt, {type => CHARACTER_TOKEN, data => substr ($$s, 0, 1),
                   line => $line, column => $column};
        substr ($$s, 0, 1) = '';
        $column++;
      }
    }
  }; # $tokenize_text

  my $get_next_token = sub {
    if (@nt) {
      return shift @nt;
    }
    
    if (not @s) {
      return {type => END_OF_FILE_TOKEN, line => $line, column => $column};
    }
    
    my $s = shift @s;
    ($line, $column) = ($line + 1, 1);
    if ($s eq '') {
      undef $continuous_line;
      return {type => EMPTY_LINE_TOKEN, line => $line, column => $column};
    } elsif ($s =~ /^[\x09\x20]/) {
      push @nt, {type => PREFORMATTED_START_TOKEN,
                 line => $line, column => $column};
      $tokenize_text->(\$s);
      while (@s) {
        my $s = shift @s;
        ($line, $column) = ($line + 1, 1);
        if ($s eq '') {
          push @nt, {type => PREFORMATTED_END_TOKEN,
                     line => $line, column => $column};
          unshift @s, $s;
          $line--;
          last;
        } elsif ($s =~ /\A\](INS|DEL)\][\x09\x20]*\z/) {
          push @nt, {type => PREFORMATTED_END_TOKEN,
                     line => $line, column => $column};
          push @nt, {type => BLOCK_END_TAG_TOKEN, tag_name => $1,
                     line => $line, column => $column};
          last;
        } else {
          push @nt, {type => CHARACTER_TOKEN, data => "\x0A",
                     line => $line, column => $column};
          $tokenize_text->(\$s);
        }
      }
      return shift @nt;
    } elsif ($s =~ s/^(\*+)\s*//) {
      push @nt, {type => HEADING_START_TOKEN, depth => length $1,
                 line => $line, column => $column};
      $column += $+[0] - $-[0];
      $tokenize_text->(\$s);
      push @nt, {type => HEADING_END_TOKEN,
                 line => $line, column => $column};
      undef $continuous_line;
      return shift @nt;
    } elsif ($s =~ s/^([-=]+)\s*//) {
      push @nt, {type => LIST_START_TOKEN, depth => $1,
                 line => $line, column => $column};
      $column += $+[0] - $-[0];
      $tokenize_text->(\$s);
      $continuous_line = 1;
      return shift @nt;
    } elsif ($s =~ s/^:([^:]*)//) {
      my $name = $1;
      if ($s eq '') {
        push @nt, {type => CHARACTER_TOKEN, data => ':',
                   line => $line, column => $column};
        $column++;
        $tokenize_text->(\$name);
      } else {
        my $real_column = $column + 1 + length $name;
        push @nt, {type => LABELED_LIST_START_TOKEN,
                   line => $line, column => $column};
        $name =~ s/\A[\x09\x20]*//;
        $column += 1 + $+[0] - $-[0];
        $name =~ s/[\x09\x20]+\z//;
        $tokenize_text->(\$s);
        $column = $real_column;
        push @nt, {type => LABELED_LIST_MIDDLE_TOKEN,
                   line => $line, column => $column};
        $column += $+[0] - $-[0] if $data =~ s/^:[\x09\x20]*//;
        $tokenize_text->(\$s);
      }
      $continuous_line = 1;
      return shift @nt;
    } elsif ($s =~ s/^(>+)//) {
      my $depth = length $1;
      if ($depth == 2 and $s =~ /^[0-9]/) {
        push @nt, {type => CHARACTER_TOKEN, data => "\x0A",
                   line => $line, column => $column}
            if $continuous_line;
        $s = '>>' . $s;
        $tokenize_text->(\$s);
      } else {
        push @nt, {type => QUOTATION_START_TOKEN, depth => $depth,
                   line => $line, column => $column};
        $column += $depth;
        $column += $+[0] - $-[0] if $s =~ s/^[\x09\x20]+//;
        if ($s =~ s/^\@\@[\x09\x20]*//) {
          push @nt, {type => EDITORIAL_NOTE_START_TOKEN,
                     line => $line, column => $column};
          $column += $+[0] - $-[0];
        } elsif ($s =~ s/^;;[\x09\x20]*//) {
          push @nt, {type => COMMENT_PARAGRAPH_START_TOKEN,
                     line => $line, column => $column};
          $column += $+[0] - $-[0];
        }
        $tokenize_text->(\$s);
      }
      $continuous_line = 1;
      return shift @nt;
    } elsif ($s =~ /\A\[(INS|DEL)(?>\(([^()\\]*)\))?\[[\x09\x20]*\z/) {
      undef $continuous_line;
      return {type => BLOCK_START_TAG_TOKEN, tag_name => $1,
              classes => $2,
              line => $line, column => $column};
    } elsif ($s =~ /\A\[PRE(?>\(([^()\\]*)\))?\[[\x09\x20]*\z/) {
      undef $continuous_line;
      push @nt, {type => BLOCK_START_TAG_TOKEN, tag_name => 'PRE',
                 classes => $1,
                 line => $line, column => $column};
      while (@s) {
        my $s = shift @s;
        ($line, $column) = ($line + 1, 1);
        if ($s =~ /\A\]PRE\][\x09\x20]*\z/) {
          push @nt, {type => BLOCK_END_TAG_TOKEN, tag_name => 'PRE',
                     line => $line, column => $column};
          undef $continuous_line;
          break;
        } else {
          push @nt, {type => CHARACTER_TOKEN, data => "\x0A",
                     line => $line, column => $column}
              if $continuous_line;
          $tokenize_text->(\$s);
          $continuous_line = 1;
        }
      }
      return shift @nt;
    } elsif ($s =~ s/^\@\@[\x09\x20]*//) {
      push @nt, {type => EDITORIAL_NOTE_START_TOKEN,
                 line => $line, column => $column};
      $column += $+[0] - $-[0];
      $tokenize_text->(\$s);
      $continuous_line = 1;
      return shift @nt;
    } elsif ($s =~ s/^;;[\x09\x20]*//) {
      push @nt, {type => COMMENT_PARAGRAPH_START_TOKEN,
                 line => $line, column => $column};
      $column += $+[0] - $-[0];
      $tokenize_text->(\$s);
      undef $continuous_line;
      return shift @nt;
    } elsif ($s =~ /\A\](INS|DEL)\][\x09\x20]*\z/) {
      $continuous_line = 1;
      return {type => BLOCK_END_TAG_TOKEN, tag_name => $1,
              line => $line, column => $column};
    } elsif ($s =~ /^,/) {
      push @nt, {type => TABLE_ROW_START_TOKEN,
                 line => $line, column => $column};
      while ($s =~ s/^,[\x09\x20]*//) {
        $column += $+[0] - $-[0];
        my $cell;
        my $cell_quoted;
        my $column_quoted = $column;
        my $column_cell = $column;
        if ($s =~ s/^"//) {
          $s =~ s/^((?>[^"\\]|\\.)*)//;
          $cell_quoted = $1;
          $column += 1 + length $cell_quoted;
          $cell_quoted =~ tr/\\//d;
          $column++ if $s =~ s/\A\\\z//;
          $column++ if $s =~ s/^"//;
        }
        if ($s =~ s/^([^,]+)//) {
          $cell = $1;
          $column += length $cell;
          $cell =~ s/[\x09\x20]+\z//;
        }
        if (not defined $cell_quoted and defined $cell and
            $cell eq '==') {
          push @nt, {type => TABLE_COLSPAN_CELL_TOKEN,
                     line => $line, column => $column_cell};
        } else {
          push @nt, {type => TABLE_CELL_START_TOKEN,
                     line => $line,
                     column => defined $column_quoted ? $column_quoted: $column_cell};
          my $real_column = $column;
          $column = $column_quoted + 1;
          $tokenize_text->(\$cell_quoted) if defined $cell_quoted;
              ## NOTE: When a quoted-pair is used, column numbers
              ## reported in this $tokenize_text call might be wrong.
          $column = $column_cell;
          $tokenize_text->(\$cell) if defined $cell;
          $column = $column_quoted;
          push @nt, {type => TABLE_CELL_END_TOKEN,
                     line => $line,
                     column => $column};
        }
      }
      push @nt, {type => TABLE_ROW_END_TOKEN,
                 line => $line, column => $column};
      undef $continuous_line;
      return shift @nt;
    } elsif ($s eq '__IMAGE__') {
      my $image = $doc->create_element_ns ($NS_SW09, 'image');
      $_->set_user_data (manakai_source_line => $line);
      $_->set_user_data (manakai_source_column => 1);
      $image->text_content (join "\x0A", $s, @s);
      ($line, $column) = ($line + @s, 1);
      @s = ();
      $doc->document_element->append_child ($image);
      return {type => END_OF_FILE_TOKEN,
              line => $line, column => $column};
    } else {
      push @nt, {type => CHARACTER_TOKEN, data => "\x0A",
                 line => $line, column => $column} if $continuous_line;
      $tokenize_text->(\$s);
      $continuous_line = 1;
      return shift @nt;
    }
  }; # $get_next_token_body

  ## NOTE: The "initial" mode.
  if (@s and $s[0] =~ /^#\?/) {
    ## NOTE: "Parse a magic line".

    my $s = shift @s;

    ## TODO:...

    $line = 2;
    $column = 0;
  }

  ## NOTE: Switched to the "body" mode.
  $get_next_token->();

} # parse_char_string

1;
