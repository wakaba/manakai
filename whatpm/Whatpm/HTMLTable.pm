package Whatpm::HTMLTable;
use strict;

## An implementation of "Forming a table" algorithm in HTML5
sub form_table ($$$;$) {
  my (undef, $table_el, $onerror, $must_level) = @_;
  $onerror ||= sub { };
  $must_level ||= 'm';
  
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
        if ($table->{column}->[$_]) {
          $onerror->(type => 'column with no anchored cell',
                     node => $table->{column}->[$_]->{element},
                     level => $must_level);
        } else {
          $onerror->(type => 'colspan creates column with no anchored cell',
                     node => $column_generated_by[$_],
                    level => $must_level);
        }
        last; # only one error.
      }
    }
    for (0 .. $y_height - 1) {
      unless ($row_has_anchored_cell[$_]) {
        if ($table->{row}->[$_]) {
          $onerror->(type => 'row with no anchored cell',
                     node => $table->{row}->[$_]->{element},
                     level => $must_level);
        } else {
          $onerror->(type => 'rowspan creates row with no anchored cell',
                     node => $row_generated_by[$_],
                     level => $must_level);
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
        if (defined $col_span and $col_span =~ /^[\x09-\x0D\x20]*([0-9]+)/) {
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
      if (defined $col_span and $col_span =~ /^[\x09-\x0D\x20]*([0-9]+)/) {
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

    ## Step 3
    my $tr = shift;
    $table->{row}->[$y_current] = {element => $tr};
    my @tdth = grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      {td => 1, th => 1}->{$_->manakai_local_name}
    } @{$tr->child_nodes};
    my $current_cell = shift @tdth;

    ## Step 4
    $growing_downward_growing_cells->();

return unless $current_cell;
## ISSUE: Support for empty <tr></tr> (removed at revision 1376).

    CELL: while (1) {
      ## Step 5: cells
      $x_current++
        while ($x_current < $x_width and
               $table->{cell}->[$x_current]->[$y_current]);

      ## Step 6
      $x_width++ if $x_current == $x_width;

      ## Step 7
      my $colspan = 1;
      my $attr_value = $current_cell->get_attribute_ns (undef, 'colspan');
      if (defined $attr_value and $attr_value =~ /^[\x09-\x0D\x20]*([0-9]+)/) {
        $colspan = $1 || 1;
      }
      
      ## Step 8
      my $rowspan = 1;
      my $attr_value = $current_cell->get_attribute_ns (undef, 'rowspan');
      if (defined $attr_value and $attr_value =~ /^[\x09-\x0D\x20]*([0-9]+)/) {
        $rowspan = $1;
      }
      
      ## Step 9
      my $cell_grows_downward;
      if ($rowspan == 0) {
        $cell_grows_downward = 1;
        $rowspan = 1;
      }
      
      ## Step 10
      if ($x_width < $x_current + $colspan) { 
        @column_generated_by[$_] = $current_cell
          for $x_width .. $x_current + $colspan - 1;
        $x_width = $x_current + $colspan;
      }
      
      ## Step 11
      if ($y_height < $y_current + $rowspan) {
        @row_generated_by[$_] = $current_cell
            for $y_height .. $y_current + $rowspan - 1;
        $y_height = $y_current + $rowspan;
        $y_max_node = $current_cell;
      }
      
      ## Step 12
      my $cell = {
                  is_header => ($current_cell->manakai_local_name eq 'th'),
                  element => $current_cell,
                  x => $x_current, y => $y_current,
                  width => $colspan, height => $rowspan,
                 };
      $column_has_anchored_cell[$x_current] = 1;
      $row_has_anchored_cell[$y_current] = 1;
      for my $x ($x_current .. ($x_current + $colspan - 1)) {
        for my $y ($y_current .. ($y_current + $rowspan - 1)) {
          unless ($table->{cell}->[$x]->[$y]) {
            $table->{cell}->[$x]->[$y] = [$cell];
          } else {
            $onerror->(type => "cell overlapping:$x:$y", node => $current_cell,
                       level => $must_level);
            push @{$table->{cell}->[$x]->[$y]}, $cell;
          }
        }
      }

      ## Whether the cell is an empty data cell or not
      if (not $cell->{is_header}) {
        $cell->{is_empty} = 1;
        for my $node (@{$current_cell->child_nodes}) {
          my $nt = $node->node_type;
          if ($nt == 3 or $nt == 4) { # TEXT_NODE / CDATA_SECTION_NODE
            if ($node->data =~ /\P{Zs}/) { ## TOOD: non-Zs class
              delete $cell->{is_empty};
              last;
            }
          } elsif ($nt == 1) { # ELEMENT_NODE
            delete $cell->{is_empty};
            last;
          }
        }
        ## NOTE: Entity references are not supported
      }
      
      ## Step 13
      if ($cell_grows_downward) {
        push @downward_growing_cells, [$cell, $x_current, $colspan];
      }
      
      ## Step 14
      $x_current += $colspan;

      ## Step 15-17
      $current_cell = shift @tdth;
      if (defined $current_cell) {
        ## Step 16-17
        #
      } else {
        ## Step 15
        $y_current++;
        last CELL;
      }
    } # CELL
  }; # $process_row

  $process_row_group = sub ($) {
    ## Step 1
    my $y_start = $y_height;

    ## Step 2
    for (grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      $_->manakai_local_name eq 'tr'
    } @{$_[0]->child_nodes}) {
      $process_row->($_);
    }

    ## Step 3
    if ($y_height > $y_start) {
      my $rg = {element => $current_element, ## ISSUE: "element being processed"?
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

sub assign_header ($$;$$) {
  my (undef, $table, $onerror, $must_level) = @_;
  $onerror ||= sub { };
  $must_level ||= 'm';

  my $assign_header = sub ($$$) {
    my $_cell = shift;
    my ($x, $y) = @_;

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
          $scope = $scope ? lc $scope : ''; ## TODO: case
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
            HORIZONTAL: {
              last HORIZONTAL if $_x == $table->{width}; # goto Vertical

              ## 4. # goto Vertical
              last HORIZONTAL
                  if $table->{cell}->[$_x]->[$y] and
                      $table->{cell}->[$_x]->[$y]->[0] and # anchored
                      $table->{cell}->[$_x]->[$y]->[0]->{is_header};

              ## 5.
              for my $_y ($y .. $y + $cell->{height} - 1) {
                $assign_header->($table->{cell}->[$_x]->[$_y] => $x, $y);
              }

              ## 6.
              $_x++;

              ## 7.
              redo HORIZONTAL;
            } # HORIZONTAL

            ## 8. Vertical
            my $_y = $y + $cell->{height};

            VERTICAL: {
              ## 9. # goto END
              last VERTICAL if $_y == $table->{height};

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
          }
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
    my @headers = split /[\x09-\x0D\x20]+/,
        $headers_cell->{element}->get_attribute_ns (undef, 'headers');
    my %headers;
    for my $header_id (@headers) {
      next unless length $header_id;
      if ($headers{$header_id}) {
        $onerror->(type => 'duplicate token', value => $header_id,
                   node => $headers_cell->{element}->get_attribute_node_ns
                       (undef, 'headers'),
                   level => $must_level);
        next;
      }
      $headers{$header_id} = 1;

      if ($id_to_cell->{$header_id}) {
        my $header_cell = $id_to_cell->{$header_id};
        $headers_cell->{header}->{$header_cell->{x}}->{$header_cell->{y}} = 1;
      } else {
        $onerror->(type => 'no header cell', value => $header_id,
                   node => $headers_cell->{element}->get_attribute_node_ns
                       (undef, 'headers'),
                   level => $must_level);
      }
    }
  }

  ## NOTE: The "tree order" constraints in the spec algorithm are irrelevant
  ## in fact.

  ## NOTE: We does not support ID attributes other than HTML "id" attribute.
} # assign_header

1;
## $Date: 2008/05/10 10:06:49 $
