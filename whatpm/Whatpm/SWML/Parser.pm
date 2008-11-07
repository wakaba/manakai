package Whatpm::SWML::Parser;
use strict;

sub AA_NS () { q<http://pc5.2ch.net/test/read.cgi/hp/1096723178/aavocab#> }
sub HTML_NS () { q<http://www.w3.org/1999/xhtml> }
sub SW09_NS () { q<urn:x-suika-fam-cx:markup:suikawiki:0:9:> }
sub SW10_NS () { q<urn:x-suika-fam-cx:markup:suikawiki:0:10:> }
sub XML_NS () { q<http://www.w3.org/XML/1998/namespace> }

sub IN_SECTION_IM () { 0 }
sub IN_TABLE_ROW_IM () { 1 }
sub IN_PARAGRAPH_IM () { 2 }

sub BLOCK_START_TAG_TOKEN () { 1 }
sub BLOCK_END_TAG_TOKEN () { 2 }
sub CHARACTER_TOKEN () { 3 }
sub COMMENT_PARAGRAPH_START_TOKEN () { 4 }
sub EDITORIAL_NOTE_START_TOKEN () { 5 }
sub ELEMENT_TOKEN () { 6 }
sub EMPHASIS_TOKEN () { 7 }
sub EMPTY_LINE_TOKEN () { 8 }
sub END_OF_FILE_TOKEN () { 9 }
sub FORM_TOKEN () { 10 }
sub HEADING_START_TOKEN () { 11 }
sub HEADING_END_TOKEN () { 12 }
sub INLINE_START_TAG_TOKEN () { 13 }
sub INLINE_MIDDLE_TAG_TOKEN () { 14 }
sub INLINE_END_TAG_TOKEN () { 15 }
sub LABELED_LIST_START_TOKEN () { 16 }
sub LABELED_LIST_MIDDLE_TOKEN () { 17 }
sub LIST_START_TOKEN () { 18 }
sub PREFORMATTED_START_TOKEN () { 19 }
sub PREFORMATTED_END_TOKEN () { 20 }
sub QUOTATION_START_TOKEN () { 21 }
sub STRONG_TOKEN () { 22 }
sub TABLE_ROW_START_TOKEN () { 23 }
sub TABLE_ROW_END_TOKEN () { 24 }
sub TABLE_CELL_START_TOKEN () { 25 }
sub TABLE_CELL_END_TOKEN () { 26 }
sub TABLE_COLSPAN_CELL_TOKEN () { 27 }

sub new ($) {
  my $self = bless {
  }, $_[0];
  return $self;
} # new

sub parse_char_string ($$$;$) {
  my $self = shift;
  my @s = split /\x0D\x0A?|\x0A/, ref $_[0] ? ${$_[0]} : $_[0], -1;

  my $doc = $_[1];
  @{$doc->child_nodes} = ();
  my $html_el = $doc->create_element_ns (HTML_NS, [undef, 'html']);
  $doc->append_child ($html_el);
  $html_el->set_attribute_ns
      ('http://www.w3.org/2000/xmlns/', [undef, 'xmlns'] => HTML_NS);
  my $head_el = $doc->create_element_ns (HTML_NS, [undef, 'head']);
  $html_el->append_child ($head_el);
  my $body_el = $doc->create_element_ns (HTML_NS, [undef, 'body']);
  $html_el->append_child ($body_el);
  for ($doc, $html_el, $head_el, $body_el) {
    $_->set_user_data (manakai_source_line => 1);
    $_->set_user_data (manakai_source_column => 1);
  }
  
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
                 local_name => 'anchor-end', namespace => SW09_NS,
                 anchor => $1, content => '[' . $1 . ']'};
      $column += $+[0] - $-[0];
    }
    
    while (length $$s) {
      if ($$s =~ s/^\[\[#([a-z-]+)//) {
        $column = $+[0] - $-[0];
        my $t = {type => FORM_TOKEN, name => $1,
                 line => $line, column => $column};
        if ($$s =~ s/^\(([^()\\]*)\)//) {
          $t->{id} = $1;
          $column += $+[0] - $-[0];
        }
        my @param;
        while ($$s =~ s/^://) {
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
          $t->{namespace} = SW09_NS;
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
                   local_name => 'anchor-internal', namespace => SW09_NS,
                   anchor => $1,
                   line => $line, column => $column};
        $column += $+[0] - $-[0];
      } elsif ($$s =~ s/^__&&//) {
        if ($$s =~ s/^(.+?)&&__//) {
          push @nt, {type => ELEMENT_TOKEN,
                     local_name => 'replace', namespace => SW09_NS,
                     by => $1,
                     line => $line, column => $column};
          $column += 4 + $+[0] - $-[0];
        } else {
          push @nt, {type => CHARACTER_TOKEN,
                     data => '__&&',
                     line => $line, column => $column};
          $column += 4;
        }
      } elsif ($$s =~ s/^([^<>\[\]'_]+)//) {
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
    } elsif ($s =~ s/^(\*+)[\x09\x20]*//) {
      push @nt, {type => HEADING_START_TOKEN, depth => length $1,
                 line => $line, column => $column};
      $column += $+[0] - $-[0];
      $tokenize_text->(\$s);
      push @nt, {type => HEADING_END_TOKEN,
                 line => $line, column => $column};
      undef $continuous_line;
      return shift @nt;
    } elsif ($s =~ s/^([-=]+)[\x09\x20]*//) {
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
        $tokenize_text->(\$name);
        $column = $real_column;
        push @nt, {type => LABELED_LIST_MIDDLE_TOKEN,
                   line => $line, column => $column};
        $column += $+[0] - $-[0] if $s =~ s/^:[\x09\x20]*//;
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
        $continuous_line = 1;
      } else {
        push @nt, {type => QUOTATION_START_TOKEN, depth => $depth,
                   line => $line, column => $column};
        $column += $depth;
        $column += $+[0] - $-[0] if $s =~ s/^[\x09\x20]+//;
        if ($s =~ s/^\@\@[\x09\x20]*//) {
          push @nt, {type => EDITORIAL_NOTE_START_TOKEN,
                     line => $line, column => $column};
          $column += $+[0] - $-[0];
          $continuous_line = 1;
        } elsif ($s =~ s/^;;[\x09\x20]*//) {
          push @nt, {type => COMMENT_PARAGRAPH_START_TOKEN,
                     line => $line, column => $column};
          $column += $+[0] - $-[0];
          $continuous_line = 1;
        } elsif (length $s) {
          $continuous_line = 1;
        } else {
          $continuous_line = 0;
        }
        $tokenize_text->(\$s);
      }
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
          last;
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
      $continuous_line = 1;
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
      my $image = $doc->create_element_ns (SW09_NS, [undef, 'image']);
      $image->set_user_data (manakai_source_line => $line);
      $image->set_user_data (manakai_source_column => 1);
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
  }; # $get_next_token

  ## NOTE: The "initial" mode.
  if (@s and $s[0] =~ s/^#\?//) {
    ## NOTE: "Parse a magic line".

    my $s = shift @s;
    if ($s =~ s/^([^\x09\x20]+)//) {
      $column += $+[0] - $-[0];
      my ($name, $version) = split m#/#, $1, 2;
      my $el = $doc->document_element;
      $el->set_attribute_ns (SW09_NS, ['sw', 'Name'] => $name);
      $el->set_attribute_ns (SW09_NS, ['sw', 'Version'] => $version)
          if defined $version;
    }

    while (length $s) {
      $column += $+[0] - $-[0] and next if $s =~ s/^[\x09\x20]+//;
      my $name = '';
      if ($s =~ s/^([^=]*)=//) {
        $name = $1;
        $column += length $name + 1;
      }
      my $param = $doc->create_element_ns (SW09_NS, [undef, 'parameter']);
      $param->set_attribute_ns (undef, [undef, 'name'] => $name);
      $param->set_user_data (manakai_source_line => $line);
      $param->set_user_data (manakai_source_column => $column);
      $head_el->append_child ($param);

      $column++ if $s =~ s/^"//;
      if ($s =~ s/^([^"]*)//) {
        my $values = $1;
        $column += length $values;
        $values =~ tr/\\//d;
        my @values = split /,/, $values, -1;
        push @values, '' unless length $values;
        for (@values) {
          my $value = $doc->create_element_ns (SW09_NS, [undef, 'value']);
          $value->text_content ($_);
          $value->set_user_data (manakai_source_line => $line);
          $value->set_user_data (manakai_source_column => $column);
          $param->append_child ($value);
        }
      }
      $column++ if $s =~ s/^"//;
    }

    $line = 2;
    $column = 1;
  }

  ## NOTE: Switched to the "body" mode.

  my $oe = [{node => $body_el,
             section_depth => 0,
             quotation_depth => 0,
             list_depth => 0}];
  my $structural_elements = {
    body => 1, section => 1, insert => 1, delete => 1, blockquote => 1,
    h1 => 1, ul => 1, ol => 1, dl => 1, li => 1, dt => 1, dd => 1,
    table => 1, tbody => 1, tr => 1, td => 1, p => 1, 'comment-p' => 1,
    ed => 1, pre => 1,
  };

  my $im = IN_SECTION_IM;
  $token = $get_next_token->();

  A: {
    if ($im == IN_PARAGRAPH_IM) {
      if ($token->{type} == CHARACTER_TOKEN) {
        $oe->[-1]->{node}->manakai_append_text ($token->{data});
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == INLINE_START_TAG_TOKEN) {
        if (not defined $token->{tag_name}) {
          my $el = $doc->create_element_ns (SW09_NS, [undef, 'anchor']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});
          
          $token = $get_next_token->();
          redo A;
        } else {
          my $type = {
                      AA => [AA_NS, 'aa'],
                      ABBR => [HTML_NS, 'abbr'],
                      CITE => [HTML_NS, 'cite'],
                      CODE => [HTML_NS, 'code'],
                      CSECTION => [SW10_NS, 'csection'],
                      DEL => [HTML_NS, 'del'],
                      DFN => [HTML_NS, 'dfn'],
                      INS => [HTML_NS, 'ins'],
                      KBD => [HTML_NS, 'kbd'],
                      KEY => [SW10_NS, 'key'],
                      Q => [HTML_NS, 'q'],
                      QN => [SW10_NS, 'qn'],
                      RUBY => [HTML_NS, 'ruby'],
                      RUBYB => [HTML_NS, 'rubyb'],
                      SAMP => [HTML_NS, 'samp'],
                      SPAN => [HTML_NS, 'span'],
                      SRC => [SW10_NS, 'src'],
                      SUB => [HTML_NS, 'sub'],
                      SUP => [HTML_NS, 'sup'],
                      TIME => [HTML_NS, 'time'],
                      VAR => [HTML_NS, 'var'],
                      WEAK => [SW09_NS, 'weak'],
                     }->{$token->{tag_name}} || [SW10_NS, $token->{tag_name}];
          my $el = $doc->create_element_ns ($type->[0], [undef, $type->[1]]);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});

          $el->set_attribute_ns (undef, [undef, 'class'] => $token->{classes})
              if defined $token->{classes};
          $el->set_attribute_ns (XML_NS, ['xml', 'lang'] => $token->{language})
              if defined $token->{language};
          
          $token = $get_next_token->();
          redo A;
        } 
      } elsif ($token->{type} == INLINE_MIDDLE_TAG_TOKEN) {
        my ($ns, $ln, $pop) = @{{
          rt => [HTML_NS, 'rt', 1],
          title => [SW10_NS, 'attrvalue', 1],
          nsuri => [SW10_NS, 'attrvalue', 1],
          qn => [SW10_NS, 'nsuri'],
          ruby => [HTML_NS, 'rt'],
          rubyb => [HTML_NS, 'rt'],
        }->{$oe->[-1]->{node}->manakai_local_name} || [SW10_NS, 'title']};
        pop @$oe if $pop;

        my $el = $doc->create_element_ns ($ns, [undef, $ln]);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $el->set_attribute_ns (XML_NS, ['xml', 'lang'] => $token->{language})
            if defined $token->{language};

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == INLINE_END_TAG_TOKEN) {
        pop @$oe if {
          rt => 1, title => 1, nsuri => 1, attrvalue => 1,
        }->{$oe->[-1]->{node}->manakai_local_name};
        
        if ({%$structural_elements,
             strong => 1, em => 1}->{$oe->[-1]->{node}->manakai_local_name}) {
          my $el = $doc->create_element_ns
              (SW09_NS,
               [undef, defined $token->{res_scheme}
                    ? 'anchor-external' : 'anchor-internal']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});
          $el->text_content (']]');
        }
        
        $oe->[-1]->{node}->set_attribute_ns (SW09_NS, ['sw', 'anchor'],
                                             $token->{anchor})
            if defined $token->{anchor};
        $oe->[-1]->{node}->set_attribute_ns (SW09_NS, ['sw', 'resScheme'],
                                             $token->{res_scheme})
            if defined $token->{res_scheme};
        $oe->[-1]->{node}->set_attribute_ns (SW09_NS, ['sw', 'resParameter'],
                                             $token->{res_parameter})
            if defined $token->{res_parameter};
        
        pop @$oe;
        
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == STRONG_TOKEN) {
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'strong']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == EMPHASIS_TOKEN) {
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'em']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == FORM_TOKEN) {
        ## There is an exact code clone.
        if ($token->{name} eq 'form') {
          my $el = $doc->create_element_ns (SW09_NS, [undef, 'form']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});

          $el->set_attribute_ns (undef, [undef, 'id']
                                     => $token->{id}) if defined $token->{id};
          $el->set_attribute_ns (undef, [undef, 'input']
                                     => shift @{$token->{parameters}})
              if @{$token->{parameter}};
          $el->set_attribute_ns (undef, [undef, 'template']
                                     => shift @{$token->{parameters}})
              if @{$token->{parameter}};
          $el->set_attribute_ns (undef, [undef, 'option']
                                     => shift @{$token->{parameters}})
              if @{$token->{parameter}};
          $el->set_attribute_ns (undef, [undef, 'parameter']
                                     => join ':', @{$token->{parameters}})
              if @{$token->{parameter}};
          
          $token = $get_next_token->();
          redo A;
        } else {
          my $el = $doc->create_element_ns (SW09_NS, [undef, 'form']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});

          $el->set_attribute_ns (undef, [undef, 'ref']
                                     => $token->{name});
          $el->set_attribute_ns (undef, [undef, 'id']
                                     => $token->{id}) if defined $token->{id};
          $el->set_attribute_ns (undef, [undef, 'parameter']
                                     => join ':', @{$token->{parameters}})
              if @{$token->{parameters}};
          
          $token = $get_next_token->();
          redo A;
        }
      } elsif ($token->{type} == ELEMENT_TOKEN) {
        ## NOTE: There is an exact code clone.
        my $el = $doc->create_element_ns
            ($token->{namespace}, [undef, $token->{local_name}]);
        $oe->[-1]->{node}->append_child ($el);
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $el->set_attribute_ns (SW09_NS, ['sw', 'anchor'], $token->{anchor})
            if defined $token->{anchor};
        $el->set_attribute_ns (undef, [undef, 'by']
                                   => $token->{by}) if defined $token->{by};
        $el->set_attribute_ns (SW09_NS, ['sw', 'resScheme'],
                                   $token->{res_scheme})
            if defined $token->{res_scheme};
        $el->set_attribute_ns (SW09_NS, ['sw', 'resParameter'],
                               $token->{res_parameter})
            if defined $token->{res_parameter};
        $el->text_content ($token->{content}) if defined $token->{content};

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == LABELED_LIST_MIDDLE_TOKEN) {
        pop @$oe while not $structural_elements
            ->{$oe->[-1]->{node}->manakai_local_name};
        pop @$oe if $oe->[-1]->{node}->manakai_local_name eq 'dt';
        
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'dd']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == HEADING_END_TOKEN) {
        pop @$oe while not $structural_elements
            ->{$oe->[-1]->{node}->manakai_local_name};
        pop @$oe if $oe->[-1]->{node}->manakai_local_name eq 'h1';
        
        $im = IN_SECTION_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == TABLE_CELL_END_TOKEN) {
        pop @$oe while not $structural_elements
            ->{$oe->[-1]->{node}->manakai_local_name};
        pop @$oe if $oe->[-1]->{node}->manakai_local_name eq 'td';
        
        $im = IN_TABLE_ROW_IM;
        $token = $get_next_token->();
        redo A;
      } elsif (($token->{type} == BLOCK_END_TAG_TOKEN and
                $token->{tag_name} eq 'PRE') or
               $token->{type} == PREFORMATTED_END_TOKEN) {
        pop @$oe while not $structural_elements
            ->{$oe->[-1]->{node}->manakai_local_name};
        pop @$oe if $oe->[-1]->{node}->manakai_local_name eq 'pre';

        $im = IN_SECTION_IM;
        $token = $get_next_token->();
        redo A;
      } else {
        pop @$oe while not $structural_elements
            ->{$oe->[-1]->{node}->manakai_local_name};
        
        $im = IN_SECTION_IM;
        ## Reconsume.
        redo A;
      }
    } elsif ($im == IN_SECTION_IM) {
      if ($token->{type} == HEADING_START_TOKEN) {
        B: {
          pop @$oe and redo B
              if not {body => 1, section => 1, insert => 1, delete => 1}
                  ->{$oe->[-1]->{node}->manakai_local_name} or
                 $token->{depth} <= $oe->[-1]->{section_depth};
          if ($token->{depth} > $oe->[-1]->{section_depth} + 1) {
            my $el = $doc->create_element_ns (HTML_NS, [undef, 'section']);
            $oe->[-1]->{node}->append_child ($el);
            push @$oe, {node => $el,
                        section_depth => $oe->[-1]->{section_depth} + 1,
                        quotation_depth => 0, list_depth => 0};
            redo B;
          }
        } # B

        my $el = $doc->create_element_ns (HTML_NS, [undef, 'section']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {node => $el,
                    section_depth => $oe->[-1]->{section_depth} + 1,
                    quotation_depth => 0, list_depth => 0};

        my $el2 = $doc->create_element_ns (HTML_NS, [undef, 'h1']);
        $oe->[-1]->{node}->append_child ($el2);
        push @$oe, {%{$oe->[-1]}, node => $el2};

        $im = IN_PARAGRAPH_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == BLOCK_START_TAG_TOKEN and
               ($token->{tag_name} eq 'INS' or
                $token->{tag_name} eq 'DEL')) {
        my $el = $doc->create_element_ns
            (SW09_NS,
             [undef, $token->{tag_name} eq 'INS' ? 'insert' : 'delete']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {node => $el, section_depth => 0,
                    quotation_depth => 0, list_depth => 0};
        $el->set_attribute_ns (undef, [undef, 'class'] => $token->{classes})
            if defined $token->{classes};
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == QUOTATION_START_TOKEN) {
        B: {
          pop @$oe and redo B
              if not {body => 1, section => 1, insert => 1, delete => 1,
                  blockquote => 1}
                  ->{$oe->[-1]->{node}->manakai_local_name} or
                 $token->{depth} < $oe->[-1]->{quotation_depth};
          if ($token->{depth} > $oe->[-1]->{quotation_depth}) {
            my $el = $doc->create_element_ns (HTML_NS, [undef, 'blockquote']);
            $oe->[-1]->{node}->append_child ($el);
            push @$oe, {node => $el, section_depth => 0,
                        quotation_depth => $oe->[-1]->{quotation_depth} + 1,
                        list_depth => 0};
            redo B;
          }
        } # B

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == LIST_START_TOKEN) {
        my $depth = length $token->{depth};
        my $list_type = substr ($token->{depth}, -1, 1) eq '-' ? 'ul' : 'ol';
        B: {
          pop @$oe and redo B if $oe->[-1]->{list_depth} > $depth;
          pop @$oe and redo B if $oe->[-1]->{list_depth} == $depth and
              $list_type ne $oe->[-1]->{node}->manakai_local_name;
          if ($oe->[-1]->{list_depth} < $depth) {
            my $type = substr $token->{depth}, $oe->[-1]->{list_depth}, 1;
            my $el = $doc->create_element_ns
                (HTML_NS, [undef, $type eq '-' ? 'ul' : 'ol']);
            $oe->[-1]->{node}->append_child ($el);
            push @$oe, {%{$oe->[-1]}, node => $el,
                        list_depth => $oe->[-1]->{list_depth} + 1};
            if ($oe->[-1]->{list_depth} < $depth) {
              my $el = $doc->create_element_ns (HTML_NS, [undef, 'li']);
              $oe->[-1]->{node}->append_child ($el);
              push @$oe, {%{$oe->[-1]}, node => $el};
            }
            redo B;
          }
        } # B
        
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'li']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};

        $im = IN_PARAGRAPH_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == LABELED_LIST_START_TOKEN) {
        pop @$oe if $oe->[-1]->{node}->manakai_local_name eq 'dd';
        if ($oe->[-1]->{node}->manakai_local_name ne 'dl') {
          my $el = $doc->create_element_ns (HTML_NS, [undef, 'dl']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
        }
        
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'dt']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        
        $im = IN_PARAGRAPH_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == TABLE_ROW_START_TOKEN) {
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'table']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};

        $el = $doc->create_element_ns (HTML_NS, [undef, 'tbody']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};

        $el = $doc->create_element_ns (HTML_NS, [undef, 'tr']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        
        $im = IN_TABLE_ROW_IM;
        $token = $get_next_token->();
        redo A;
      } elsif (($token->{type} == BLOCK_START_TAG_TOKEN and
                $token->{tag_name} eq 'PRE') or
               $token->{type} == PREFORMATTED_START_TOKEN) {
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'pre']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};

        $el->set_attribute_ns (undef, [undef, 'class'] => $token->{classes})
            if defined $token->{classes};

        $im = IN_PARAGRAPH_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == COMMENT_PARAGRAPH_START_TOKEN) {
        my $el = $doc->create_element_ns (SW10_NS, [undef, 'comment-p']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        
        $im = IN_PARAGRAPH_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == EDITORIAL_NOTE_START_TOKEN) {
        my $el = $doc->create_element_ns (SW10_NS, [undef, 'ed']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};

        $im = IN_PARAGRAPH_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == EMPTY_LINE_TOKEN) {
        pop @$oe while not {body => 1, section => 1, insert => 1, delete => 1}
            ->{$oe->[-1]->{node}->manakai_local_name};
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == BLOCK_END_TAG_TOKEN) {
        if ($token->{tag_name} eq 'INS') {
          for (reverse 1..$#$oe) {
            if ($oe->[$_]->{node}->manakai_local_name eq 'insert') {
              splice @$oe, $_;
              last;
            }
          }
        } elsif ($token->{tag_name} eq 'DEL') {
          for (reverse 1..$#$oe) {
            if ($oe->[$_]->{node}->manakai_local_name eq 'delete') {
              splice @$oe, $_;
              last;
            }
          }
        } else {
          ## NOTE: Ignore the token.
        }
        undef $continuous_line;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == FORM_TOKEN) {
        ## There is an exact code clone.
        if ($token->{name} eq 'form') {
          my $el = $doc->create_element_ns (SW09_NS, [undef, 'form']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});

          $el->set_attribute_ns (undef, [undef, 'id']
                                     => $token->{id}) if defined $token->{id};
          $el->set_attribute_ns (undef, [undef, 'input']
                                     => shift @{$token->{parameters}})
              if @{$token->{parameter}};
          $el->set_attribute_ns (undef, [undef, 'template']
                                     => shift @{$token->{parameters}})
              if @{$token->{parameter}};
          $el->set_attribute_ns (undef, [undef, 'option']
                                     => shift @{$token->{parameters}})
              if @{$token->{parameter}};
          $el->set_attribute_ns (undef, [undef, 'parameter']
                                     => join ':', @{$token->{parameters}})
              if @{$token->{parameter}};
          
          $token = $get_next_token->();
          redo A;
        } else {
          my $el = $doc->create_element_ns (SW09_NS, [undef, 'form']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});

          $el->set_attribute_ns (undef, [undef, 'ref'] => $token->{name});
          $el->set_attribute_ns (undef, [undef, 'id']
                                     => $token->{id}) if defined $token->{id};
          $el->set_attribute_ns (undef, [undef, 'parameter']
                                     => join ':', @{$token->{parameters}})
              if @{$token->{parameter}};
          
          $token = $get_next_token->();
          redo A;
        }
      } elsif ($token->{type} == ELEMENT_TOKEN and 
               $token->{local_name} eq 'replace') {
        ## NOTE: There is an exact code clone.
        my $el = $doc->create_element_ns
            ($token->{namespace}, [undef, $token->{local_name}]);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $el->set_attribute_ns (SW09_NS, ['sw', 'anchor'], $token->{anchor})
            if defined $token->{anchor};
        $el->set_attribute_ns (undef, [undef, 'by']
                                   => $token->{by}) if defined $token->{by};
        $el->set_attribute_ns (SW09_NS, ['sw', 'resScheme'],
                               $token->{res_scheme})
            if defined $token->{res_scheme};
        $el->set_attribute_ns (SW09_NS, ['sw', 'resParameter'],
                               $token->{res_parameter})
            if defined $token->{res_parameter};
        $el->text_content ($token->{content}) if defined $token->{content};

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        return;
      } elsif ({LABELED_LIST_MIDDLE_TOKEN => 1,
                HEADING_END_TOKEN => 1,
                PREFORMATTED_END_TOKEN => 1,
                TABLE_ROW_END_TOKEN => 1,
                TABLE_CELL_START_TOKEN => 1,
                TABLE_CELL_END_TOKEN => 1,
                TABLE_COLSPAN_CELL_TOKEN => 1}->{$token->{type}}) {
        ## NOTE: Ignore the token.
      } else {
        unless ({dd => 1,
                li => 1,
                 'comment-p' => 1,
                 ed => 1}->{$oe->[-1]->{node}->manakai_local_name}) {
          my $el = $doc->create_element_ns (HTML_NS, [undef, 'p']);
          $oe->[-1]->{node}->append_child ($el);
          push @$oe, {%{$oe->[-1]}, node => $el};
        }
        
        $im = IN_PARAGRAPH_IM;
        ## Reprocess.
        redo A;
      }
    } elsif ($im == IN_TABLE_ROW_IM) {
      if ($token->{type} == TABLE_CELL_START_TOKEN) {
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'td']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $im = IN_PARAGRAPH_IM;
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == TABLE_COLSPAN_CELL_TOKEN) {
        my $lc = $oe->[-1]->{node}->last_child;
        if ($lc and $lc->manakai_local_name eq 'td') {
          $lc->set_attribute_ns
              (undef, [undef, 'colspan'],
               ($lc->get_attribute_ns (undef, 'colspan') || 0) + 1);
        } else {
          my $el = $doc->create_element_ns (HTML_NS, [undef, 'td']);
          $oe->[-1]->{node}->append_child ($el);
          $el->set_user_data (manakai_source_line => $token->{line});
          $el->set_user_data (manakai_source_column => $token->{column});
        }

        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == TABLE_ROW_END_TOKEN) {
        pop @$oe if $oe->[-1]->{node}->manakai_local_name eq 'tr';
        $token = $get_next_token->();
        redo A;
      } elsif ($token->{type} == TABLE_ROW_START_TOKEN) {
        my $el = $doc->create_element_ns (HTML_NS, [undef, 'tr']);
        $oe->[-1]->{node}->append_child ($el);
        push @$oe, {%{$oe->[-1]}, node => $el};
        $el->set_user_data (manakai_source_line => $token->{line});
        $el->set_user_data (manakai_source_column => $token->{column});

        $token = $get_next_token->();
        redo A;
      } else {
        $im = IN_SECTION_IM;
        ## Reprocess.
        redo A;
      }
    } else {
      die "$0: Unknown insertion mode: $im";
    }
  } # A
} # parse_char_string

1;
