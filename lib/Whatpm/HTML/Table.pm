package Whatpm::HTML::Table;
use strict;
use warnings;
our $VERSION = '1.2';

## An implementation of "Forming a table" algorithm in HTML5
sub form_table ($$;$$) {
  my (undef, $table_el, $onerror, $levels) = @_;
  $onerror ||= sub { };
  $levels ||= {must => 'm'};
  
  ## Step 1
  my $x_width = 0;

  ## Step 2
  my $y_height = 0;
  my $y_max_node;

  ## Step 3
  my $pending_tfoot = [];
  
  ## Step 4
  my $table = {
    #caption
    column => [],
    column_group => [],
    row => [], ## NOTE: HTML5 algorithm doesn't associate rows with <tr>s.
    row_group => [],
    cell => [],
    height => 0,
    width => 0,
    element => $table_el,
  };
  
  my @column_has_anchored_cell;
  my @row_has_anchored_cell;
  my @column_generated_by;
  my @row_generated_by;
  
  ## Step 5
  my @table_child = @{$table_el->child_nodes};
  return $table unless @table_child;

  ## Step 6
  for (0..$#table_child) {
    my $el = $table_child[$_];
    next unless $el->node_type == 1; # ELEMENT_NODE
    next unless $el->manakai_local_name eq 'caption';
    my $nsuri = $el->namespace_uri;
    next unless defined $nsuri;
    next unless $nsuri eq q<http://www.w3.org/1999/xhtml>;
    $table->{caption} = {element => $el};
    splice @table_child, $_, 1, ();
    last;
  }

  my $process_row_group;
  my $end = sub {
    ## Step 19 (End)
    for (@$pending_tfoot) {
      $process_row_group->($_);
    }
    
    ## Step 20
    for (0 .. $x_width - 1) {
      unless ($column_has_anchored_cell[$_]) {
        if ($table->{column}->[$_] and $table->{column}->[$_]->{element}) {
          $onerror->(type => 'column with no anchored cell',
                     node => $table->{column}->[$_]->{element},
                     level => $levels->{must});
        } else {
          $onerror->(type => 'colspan creates column with no anchored cell',
                     node => $column_generated_by[$_],
                     level => $levels->{must});
        }
        last; # only one error.
      }
    }
    for (0 .. $y_height - 1) {
      unless ($row_has_anchored_cell[$_]) {
        if ($table->{row}->[$_] and $table->{row}->[$_]->{element}) {
          $onerror->(type => 'row with no anchored cell',
                     node => $table->{row}->[$_]->{element},
                     level => $levels->{must});
        } else {
          $onerror->(type => 'rowspan creates row with no anchored cell',
                     node => $row_generated_by[$_],
                     level => $levels->{must});
        }
        last; # only one error.
      }
    }
    
    ## Step 21
    #return $table;
  }; # $end

  ## Step 7, 8
  my $current_element;
  my $current_ln;
  NEXT_CHILD: {
    $current_element = shift @table_child;
    if (defined $current_element) {
      redo NEXT_CHILD unless $current_element->node_type == 1;
      my $nsuri = $current_element->namespace_uri;
      redo NEXT_CHILD unless defined $nsuri and
        $nsuri eq q<http://www.w3.org/1999/xhtml>;
      $current_ln = $current_element->manakai_local_name;

      redo NEXT_CHILD unless {
        colgroup => 1,
        thead => 1,
        tbody => 1,
        tfoot => 1,
        tr => 1,
      }->{$current_ln};
    } else {
      ## Step 6 2nd paragraph
      $end->();
      $table->{width} = $x_width;
      $table->{height} = $y_height;
      return $table;
    }
  } # NEXT_CHILD

  ## Step 9
  while ($current_ln eq 'colgroup') { # Step 9, Step 9.4
    ## Step 9.1: column groups
    my @col = grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      $_->manakai_local_name eq 'col'
    } @{$current_element->child_nodes};
    if (@col) {
      ## Step 1
      my $x_start = $x_width;
      
      ## Step 2, 6
      while (@col) {
        my $current_column = shift @col;
        
        ## Step 3: columns
        my $span = 1;
        my $col_span = $current_column->get_attribute_ns (undef, 'span');
        ## Parse non-negative integer
        if (defined $col_span and
            $col_span =~ /^[\x09\x0A\x0C\x0D\x20]*([0-9]+)/) {
          $span = $1 || 1;
        }
        
        ## Step 4, 5
        $table->{column}->[$x_width++] = {element => $current_column}
            for 1..$span;
      }
      
      ## Step 7
      my $cg = {element => $current_element,
                x => $x_start, y => 0,
                width => $x_width - $x_start};
      $table->{column_group}->[$_] = $cg for $x_start .. $x_width - 1;
    } else { # no <col> children
      ## Step 1
      my $span = 1;
      my $col_span = $current_element->get_attribute_ns (undef, 'span');
      ## Parse non-negative integer
      if (defined $col_span and
          $col_span =~ /^[\x09\x0A\x0C\x0D\x20]*([0-9]+)/) {
        $span = $1 || 1;
      }
      
      ## Step 2
      $x_width += $span;
      
      ## Step 3
      my $cg = {element => $current_element,
                x => $x_width - $span, y => 0,
                width => $span};
      $table->{column_group}->[$_] = $cg for $cg->{x} .. $x_width - 1;
    }
    
    ## Step 9.2, 9.3
    NEXT_CHILD: {
      $current_element = shift @table_child;
      if (defined $current_element) {
        redo NEXT_CHILD unless $current_element->node_type == 1;
        my $nsuri = $current_element->namespace_uri;
        redo NEXT_CHILD unless defined $nsuri and
          $nsuri eq q<http://www.w3.org/1999/xhtml>;
        $current_ln = $current_element->manakai_local_name;
        
        redo NEXT_CHILD unless {
          colgroup => 1,
          thead => 1,
          tbody => 1,
          tfoot => 1,
          tr => 1,
        }->{$current_ln};
      } else {
        ## End of subsection
        
        ## Step 5 of overall steps 2nd paragraph
        $end->();
        $table->{width} = $x_width;
        $table->{height} = $y_height;
        return $table;
      }
    } # NEXT_CHILD
  }

  ## Step 10
  my $y_current = 0;

  ## Step 11
  my @downward_growing_cells;

  my $growing_downward_growing_cells = sub {
    for (@downward_growing_cells) {
      for my $x ($_->[1] .. ($_->[1] + $_->[2] - 1)) {
        $table->{cell}->[$x]->[$y_current] = [$_->[0]];
        $_->[0]->{height}++;
      }
    }
  }; # $growing_downward_growing_cells

  my $process_row = sub {
    ## Step 1
    $y_height++ if $y_height == $y_current;
    
    ## Step 2
    my $x_current = 0;

    ## Step 5
    my $tr = shift;
    $table->{row}->[$y_current]->{element} = $tr;
    my @tdth = grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      {td => 1, th => 1}->{$_->manakai_local_name}
    } @{$tr->child_nodes};
    my $current_cell = shift @tdth;

    ## Step 3
    $growing_downward_growing_cells->();

    ## Step 4
    return unless $current_cell;

    CELL: while (1) {
      ## Step 6: cells
      $x_current++
        while ($x_current < $x_width and
               $table->{cell}->[$x_current]->[$y_current]);

      ## Step 7
      $x_width++ if $x_current == $x_width;

      ## Step 8
      my $colspan = 1;
      my $attr_value = $current_cell->get_attribute_ns (undef, 'colspan');
      if (defined $attr_value
          and $attr_value =~ /^[\x09\x0A\x0C\x0D\x20]*([0-9]+)/) {
        $colspan = $1 || 1;
      }
      
      ## Step 9
      my $rowspan = 1;
      $attr_value = $current_cell->get_attribute_ns (undef, 'rowspan');
      if (defined $attr_value and
          $attr_value =~ /^[\x09\x0A\x0C\x0D\x20]*([0-9]+)/) {
        $rowspan = $1;
      }
      
      ## Step 10
      my $cell_grows_downward;
      if ($rowspan == 0) {
        $cell_grows_downward = 1;
        $rowspan = 1;
      }
      
      ## Step 11
      if ($x_width < $x_current + $colspan) { 
        $column_generated_by[$_] = $current_cell
          for $x_width .. $x_current + $colspan - 1;
        $x_width = $x_current + $colspan;
      }
      
      ## Step 12
      if ($y_height < $y_current + $rowspan) {
        $row_generated_by[$_] = $current_cell
            for $y_height .. $y_current + $rowspan - 1;
        $y_height = $y_current + $rowspan;
        $y_max_node = $current_cell;
      }
      
      ## Step 13
      my $cell = {
        element => $current_cell,
        x => $x_current, y => $y_current,
        width => $colspan, height => $rowspan,
      };
      $cell->{is_header} = 1 if $current_cell->manakai_local_name eq 'th';
      if ($cell->{is_header}) {
        $cell->{scope} = $current_cell->get_attribute_ns (undef, 'scope') || '';
        $cell->{scope} =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
        $cell->{scope} = '' unless {
          row => 1, col => 1, rowgroup => 1, colgroup => 1,
        }->{$cell->{scope}};
      }
      $column_has_anchored_cell[$x_current] = 1;
      $row_has_anchored_cell[$y_current] = 1;
      for my $x ($x_current .. ($x_current + $colspan - 1)) {
        for my $y ($y_current .. ($y_current + $rowspan - 1)) {
          unless ($table->{cell}->[$x]->[$y]) {
            $table->{cell}->[$x]->[$y] = [$cell];
          } else {
            $onerror->(type => 'cell overlapping',
                       text => "$x,$y",
                       node => $current_cell,
                       level => $levels->{must});
            push @{$table->{cell}->[$x]->[$y]}, $cell;
          }
        }
      }

      for my $x ($x_current .. ($x_current + $colspan - 1)) {
        $table->{column}->[$x]->{has_header} = 1 if $cell->{is_header};
        $table->{column}->[$x]->{has_data} = 1 unless $cell->{is_header};
      }
      for my $y ($y_current .. ($y_current + $rowspan - 1)) {
        $table->{row}->[$y]->{has_header} = 1 if $cell->{is_header};
        $table->{row}->[$y]->{has_data} = 1 unless $cell->{is_header};
      }

      ## Whether the cell is an empty data cell or not
      $cell->{is_empty} = 1;
      for my $node (@{$current_cell->child_nodes}) {
        my $nt = $node->node_type;
        if ($nt == 3 or $nt == 4) { # TEXT_NODE / CDATA_SECTION_NODE
          if ($node->data =~ /\P{WhiteSpace}/) {
            delete $cell->{is_empty};
            last;
          }
        } elsif ($nt == 1) { # ELEMENT_NODE
          delete $cell->{is_empty};
          last;
        }
      }
      ## NOTE: Entity references are not supported
      
      ## Step 14
      if ($cell_grows_downward) {
        push @downward_growing_cells, [$cell, $x_current, $colspan];
      }
      
      ## Step 15
      $x_current += $colspan;

      ## Step 16-18
      $current_cell = shift @tdth;
      if (defined $current_cell) {
        ## Step 17-18
        #
      } else {
        ## Step 16
        $y_current++;
        last CELL;
      }
    } # CELL
  }; # $process_row

  $process_row_group = sub ($) {
    my $element_being_processed = $_[0];

    ## Step 1
    my $y_start = $y_height;

    ## Step 2
    for (grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      $_->manakai_local_name eq 'tr'
    } @{$element_being_processed->child_nodes}) {
      $process_row->($_);
    }

    ## Step 3
    if ($y_height > $y_start) {
      my $rg = {element => $element_being_processed,
                x => 0, y => $y_start,
                height => $y_height - $y_start};
      $table->{row_group}->[$_] = $rg for $y_start .. $y_height - 1;
    }

    ## Step 4
    ## Ending a row group
      ## Step 1
      while ($y_current < $y_height) {
        ## Step 1
        $growing_downward_growing_cells->();

        ## Step 2
        $y_current++;
      }
      ## Step 2
      @downward_growing_cells = ();
  }; # $process_row_group

  ## Step 12: rows
  unshift @table_child, $current_element;
  ROWS: {
    NEXT_CHILD: {
      $current_element = shift @table_child;
      if (defined $current_element) {
        redo NEXT_CHILD unless $current_element->node_type == 1;
        my $nsuri = $current_element->namespace_uri;
        redo NEXT_CHILD unless defined $nsuri and
          $nsuri eq q<http://www.w3.org/1999/xhtml>;
        $current_ln = $current_element->manakai_local_name;
      
        redo NEXT_CHILD unless {
          thead => 1,
          tbody => 1,
          tfoot => 1,
          tr => 1,
        }->{$current_ln};
      } else {
        ## Step 6 2nd paragraph
        $end->();
        $table->{width} = $x_width;
        $table->{height} = $y_height;
        return $table;
      }
    } # NEXT_CHILD

    ## Step 13
    if ($current_ln eq 'tr') {
      $process_row->($current_element);
      # advance (done at the first of ROWS)
      redo ROWS;
    }

    ## Step 14
    ## Ending a row group
      ## Step 1
      while ($y_current < $y_height) {
        ## Step 1
        $growing_downward_growing_cells->();

        ## Step 2
        $y_current++;
      }
      ## Step 2
      @downward_growing_cells = ();

    ## Step 15
    if ($current_ln eq 'tfoot') {
      push @$pending_tfoot, $current_element;
      # advance (done at the top of ROWS)
      redo ROWS;
    }

    ## Step 16
    # thead or tbody
    $process_row_group->($current_element);

    ## Step 17
    # Advance (done at the top of ROWS).

    ## Step 18
    redo ROWS;
  } # ROWS

  $end->();
  $table->{width} = $x_width;
  $table->{height} = $y_height;
  return $table;
} # form_table

sub _is_column_header ($$) {
  my ($table, $cell) = @_;
  return 0 unless $cell->{is_header};
  
  return 1 if $cell->{scope} eq 'col';
  return 0 if $cell->{scope};

  for my $y ($cell->{y} .. ($cell->{y} + $cell->{height} - 1)) {
    return 0 if $table->{row}->[$y]->{has_data};
  }

  return 1;
} # _is_column_header

sub _is_row_header ($$) {
  my ($table, $cell) = @_;
  return 0 unless $cell->{is_header};
  
  return 1 if $cell->{scope} eq 'row';
  return 0 if $cell->{scope};

  return 0 if _is_column_header ($table, $cell);

  for my $x ($cell->{x} .. ($cell->{x} + $cell->{width} - 1)) {
    return 0 if $table->{column}->[$x]->{has_data};
  }

  return 1;
} # _is_row_header

sub _scan_and_assign ($$$$$$$) {
  my ($table, $p_cell, $header_list, $x, $y, $d_x, $d_y) = @_;

  ## 1.
  #my $x = $init_x;

  ## 2.
  #my $y = $init_y;

  ## 3.
  my $opaque_headers = [];

  ## 4.
  my $in_header_block;
  my $headers_from_current = [];;
  if ($p_cell->{is_header}) {
    $in_header_block = 1;
    push @$headers_from_current, $p_cell;
  }

  ## 5. Loop
  my $blocked;
  LOOP: {
    $x += $d_x;
    $y += $d_y;

    ## 6.
    return if $x < 0;
    return if $y < 0;

    ## 7.
    my $current_cells = $table->{cell}->[$x]->[$y];
    redo LOOP unless @$current_cells == 1;

    ## 8.
    my $current_cell = $current_cells->[0];

    ## 9.
    if ($current_cell->{is_header}) {
      ## 9.A.1.
      $in_header_block = 1;
      
      ## 9.A.2.
      push @$headers_from_current, $current_cell;
      
      ## 9.A.3.
      $blocked = 0;

      ## 9.A.4.
      if ($d_x == 0) {
        if (_is_column_header ($table, $current_cell)) {
          for my $cell (@$opaque_headers) {
            if ($cell->{x} == $current_cell->{x} and
                $cell->{width} == $current_cell->{width}) {
              $blocked = 1;
              last;
            }
          }
        } else {
          $blocked = 1;
        }
      } else {
        if (_is_row_header ($table, $current_cell)) {
          for my $cell (@$opaque_headers) {
            if ($cell->{y} == $current_cell->{y} and
                $cell->{height} == $current_cell->{height}) {
              $blocked = 1;
              last;
            }
          }
        } else {
          $blocked = 1;
        }
      }

      ## 9.A.5.
      push @$header_list, $current_cell unless $blocked;
    } elsif ($in_header_block) {
      $in_header_block = 0;
      push @$opaque_headers, @$headers_from_current;
      @$headers_from_current = ();
    }
    
    ## 10.
    redo LOOP;
  } # LOOP
} # _scan_and_assign

## XXX This is untested code.
## O(table_width * table_height)
sub get_assigned_headers ($$$$) {
  my (undef, $table, $p_x, $p_y) = @_;

  ## 1.
  my $header_list = [];

  ## 2.
  #my ($p_x, $p_y) = ($p_cell->{x}, $p_cell->{y});
  my $p_cell = $table->{cell}->[$p_x]->[$p_y]->[0] or return $header_list;

  ## 3.
  my $headers = $p_cell->{element}->get_attribute_ns (undef, 'headers');
  if (defined $headers) {
    ## 3.A.1.
    my $id_list = map { length $_ } split /[\x09\x0A\x0C\x0D\x20]+/, $headers;
    
    ## 3.A.2.

    ## XXX For each token in the id list, if the first element in the
    ## Document with an ID equal to the token is a cell in the same
    ## table, and that cell is not the principal cell, then add that
    ## cell to header list.
  } else {
    ## 3.B.1.
    my $p_w = $p_cell->{width};
    
    ## 3.B.2.
    my $p_h = $p_cell->{height};
    
    ## 3.B.3.
    for my $y ($p_y .. ($p_y + $p_h - 1)) {
      _scan_and_assign ($table, $p_cell, $header_list, $p_x, $y, -1, 0);
    }

    ## 3.B.4.
    for my $x ($p_x .. ($p_x + $p_w - 1)) {
      _scan_and_assign ($table, $p_cell, $header_list, $x, $p_y, 0, -1);
    }

    ## 3.B.5.
    my $p_rg = $table->{row_group}->[$p_y];
    if ($p_rg) {
      for my $x (0 .. ($p_x + $p_w - 1)) {
        for my $y (0 .. ($p_y + $p_h - 1)) {
          my $h_cell = $table->{cell}->[$x]->[$y]->[0] or next;
          $h_cell->{scope} eq 'rowgroup' or next;
          my $h_rg = $table->{row_group}->[$y]->[0] or next;
          $h_rg->{y} == $p_rg->{y} or next;
          push @$header_list, $h_cell;
        }
      }
    }

    ## 3.B.6.
    my $p_cg = $table->{column_group}->[$p_x];
    if ($p_cg) {
      for my $x (0 .. ($p_x + $p_w - 1)) {
        for my $y (0 .. ($p_y + $p_h - 1)) {
          my $h_cell = $table->{cell}->[$x]->[$y]->[0] or next;
          $h_cell->{scope} eq 'colgroup' or next;
          my $h_cg = $table->{column_group}->[$x]->[0] or next;
          $h_cg->{x} == $p_cg->{x} or next;
          push @$header_list, $h_cell;
        }
      }
    }
  }

  ## 4.
  @$header_list = grep { not $_->{is_empty} } @$header_list;

  ## 5.
  @$header_list = values %{{map { ($_->{x} . '-' . $_->{y} => $_) } @$header_list}};

  ## 6.
  return $header_list;
} # get_assigned_header

## XXX Obsolete (old HTML5 algorithm)
sub assign_header ($$;$$) {
  my (undef, $table, $onerror, $levels) = @_;
  $onerror ||= sub { };
  $levels ||= {must => 'm'};

  warn "Whatpm::HTML::Table::assign_header is OBSOLETE!\n";

  my $assign_header = sub ($$$) {
    my $_cell = shift;    my ($x, $y) = @_;

    for my $__cell (@{$_cell or []}) {
      if ($__cell and $__cell->{element} and
          not $__cell->{is_header} and
          not $__cell->{element}->has_attribute_ns (undef, 'headers')) {
        $__cell->{header}->{$x}->{$y} = 1;
      }
    }
  }; # $assign_header

  my @headers_cell;
  my $id_to_cell = {};
  ## ISSUE: ID duplication, non-TH reference

  for my $x (0 .. $table->{width} - 1) {
    for my $y (0 .. $table->{height} - 1) {
      my $cell = $table->{cell}->[$x]->[$y];
      $cell = $cell->[0] if $cell; # anchored cell is always ->{cell}[][][0].
      next if $cell->{x} != $x;
      next if $cell->{y} != $y;
      if ($cell) {
        if ($cell->{is_header}) {
          my $id = $cell->{element}->get_attribute_ns (undef, 'id');
          if (defined $id and not $id_to_cell->{$id}) {
            $id_to_cell->{$id} = $cell;
          }

          my $scope = $cell->{element}->get_attribute_ns (undef, 'scope');
          $scope = '' unless defined $scope;
          $scope =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
          if ($scope eq 'row') {
            for my $_x ($x + $cell->{width} .. $table->{width} - 1) {
              for my $_y ($y .. $y + $cell->{height} - 1) {
                $assign_header->($table->{cell}->[$_x]->[$_y] => $x, $y);
              }
            }
          } elsif ($scope eq 'col') {
            for my $_x ($x .. $x + $cell->{width} - 1) {
              for my $_y ($y .. $table->{height} - 1) {
                $assign_header->($table->{cell}->[$_x]->[$_y] => $x, $y);
              }
            }
          } elsif ($scope eq 'rowgroup') {
            ## NOTE: A cell cannot exceed across a row group boundary.
            if ($table->{row_group}->[$y] and
                $table->{row_group}->[$y]->{height}) {
              for my $_x ($x .. $table->{width} - 1) {
                for my $_y ($y ..
                            $table->{row_group}->[$y]->{y} +
                            $table->{row_group}->[$y]->{height} - 1) {
                  $assign_header->($table->{cell}->[$_x]->[$_y] => $x, $y);
                }
              }
            }
            ## TODO: Should we raise a warning?
          } elsif ($scope eq 'colgroup') {
            if ($table->{column_group}->[$x] and
                $table->{column_group}->{width} and
                $table->{column_group}->[$x]->{x} == $x) { # anchored
              for my $_x ($x .. 
                          $table->{column_group}->[$x]->{x} + 
                          $table->{column_group}->[$x]->{width} - 1) {
                for my $_y ($y .. $table->{height} - 1) {
                  $assign_header->($table->{cell}->[$_x]->[$_y] => $x, $y);
                }
              }
            }
            ## TODO: Warning?
          } else { # auto
            ## 1.
            my $header_width = $cell->{width};
            W: for ($x + $cell->{width} .. $table->{width} - 1) {
              my $_cell = $table->{cell}->[$_]->[$y];
              for (@{$_cell or []}) {
                if ($_->{element} and not $_->{is_empty}) {
                  last W; # not empty
                }
              }
              $header_width++;
            } # W

            ## 2.
            my $_x = $x + $header_width;

            ## 3.
            my $_y = $y + $cell->{height}; # $cell->{height} == header_{height}

            ## 4.
            HORIZONTAL: {
              last HORIZONTAL if $_x == $table->{width}; # goto Vertical

              ## 5. # goto Vertical
              last HORIZONTAL
                  if $table->{cell}->[$_x]->[$y] and
                      $table->{cell}->[$_x]->[$y]->[0] and # anchored
                      $table->{cell}->[$_x]->[$y]->[0]->{is_header};

              ## 6.
              for my $_y ($y .. $y + $cell->{height} - 1) {
                $assign_header->($table->{cell}->[$_x]->[$_y] => $x, $y);
              }

              ## 7.
              $_x++;

              ## 8.
              redo HORIZONTAL;
            } # HORIZONTAL

            ## 9. Vertical
            VERTICAL: {
              last VERTICAL if $_y == $table->{height}; # goto END

              ## 10.
              if ($table->{cell}->[$x]->[$_y]) {
                my $h_cell = $table->{cell}->[$x]->[$_y]->[0]; # anchored cell
                if ($h_cell and $h_cell->{is_header}) {
                  ## 10.1.
                  my $width = $h_cell->{width};
                  W: for ($h_cell->{x} + $width .. $table->{width} - 1) {
                    my $_cell = $table->{cell}->[$_]->[$y];
                    for (@{$_cell or []}) {
                      if ($_->{element} and not $_->{is_empty}) {
                        last W; # not empty
                      }
                    }
                    $width++;
                  } # W
                    
                  ## 10.2. # goto end
                  last VERTICAL if $width == $header_width;
                } # 10.
              }

              ## 11.
              for my $_x ($x .. $x + $header_width - 1) {
                $assign_header->($table->{cell}->[$_x]->[$_y] => $x, $y);
              }

              ## 12.
              $_y++;

              ## 13. # goto vertical (wrong)
              redo VERTICAL;
            } # VERTICAL

            ## 14. End
            # (we have already done)

            $scope = '';
          }
          $cell->{scope} = $scope;
        } else { # data cell
          if ($cell->{element} and
              $cell->{element}->has_attribute_ns (undef, 'headers')) {
            push @headers_cell, $cell;
          }
        }
      }
    }
  }

  for my $headers_cell (@headers_cell) {
    my @headers = split /[\x09\x0A\x0C\x0D\x20]+/,
        $headers_cell->{element}->get_attribute_ns (undef, 'headers');
    my %headers;
    for my $header_id (@headers) {
      next unless length $header_id;
      if ($headers{$header_id}) {
        $onerror->(type => 'duplicate token', value => $header_id,
                   node => $headers_cell->{element}->get_attribute_node_ns
                       (undef, 'headers'),
                   level => $levels->{must});
        next;
      }
      $headers{$header_id} = 1;

      if ($id_to_cell->{$header_id}) {
        my $header_cell = $id_to_cell->{$header_id};
        $headers_cell->{header}->{$header_cell->{x}}->{$header_cell->{y}} = 1;
      } else {
        $onerror->(type => 'no referenced header cell', value => $header_id,
                   node => $headers_cell->{element}->get_attribute_node_ns
                       (undef, 'headers'),
                   level => $levels->{must});
      }
    }
  }

  ## NOTE: The "tree order" constraints in the spec algorithm are irrelevant
  ## in fact.

  ## NOTE: We does not support ID attributes other than HTML "id" attribute.
} # assign_header

1;

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
