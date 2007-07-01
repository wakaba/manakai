package Whatpm::HTMLTable;
use strict;

## An implementation of "Forming a table" algorithm in HTML5
sub form_table ($$$) {
  my (undef, $table_el, $onerror) = @_;
  $onerror ||= sub { };
  
  ## Step 1
  my $x_max = 0;

  ## Step 2
  my $y_max = 0;
  my $y_max_node;
  
  ## Step 3
  my $table = {
    #caption
    column => [],
    column_group => [],
    # no |row| since HTML5 algorithm doesn't associate rows with <tr>s
    row_group => [],
    cell => [],
  };
  
  my @has_anchored_cell;
  my @column_generated_by;
  my $check_empty_column = sub {
    for (1..$x_max) {
      unless ($has_anchored_cell[$_]) {
        if ($table->{column}->[$_]) {
          $onerror->(type => 'column with no anchored cell',
                     node => $table->{column}->[$_]->{element});
        } else {
          $onerror->(type => 'colspan creates column with no anchored cell',
                     node => $column_generated_by[$_]);
        }
      }
    }
  }; # $check_empty_column
  
  ## Step 4
  ## "If the table element has no table children, then return the table (which will be empty), and abort these steps."
  ## ISSUE: What is "table children"?
  my @table_child = @{$table_el->child_nodes};
  return unless @table_child; # don't call $check_empty_column

  ## Step 5, 6, 8
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

      if ($current_ln eq 'caption' and not defined $table->{caption}) {
        ## Step 7
        $table->{caption} = {element => $current_element};
        redo NEXT_CHILD; # Step 8
      }

      redo NEXT_CHILD unless {
        #caption => 1, ## Step 6
        colgroup => 1,
        thead => 1,
        tbody => 1,
        tfoot => 1,
        tr => 1,
      }->{$current_ln};
    } else {
      ## End of subsection
      $check_empty_column->();
      ## Step 5 2nd paragraph
      return $table;
    }
  } # NEXT_CHILD

  ## ISSUE: Step 9.1 /next column/ is not used.

  ## Step 9
  while ($current_ln eq 'colgroup') { # Step 9, Step 9.5
    ## Step 2: column groups
    my @col = grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      $_->manakai_local_name eq 'col'
    } @{$current_element->child_nodes};
    if (@col) {
      ## Step 1
      my $x_start = $x_max + 1;
      
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
        ## ISSUE: If span=0, what is /span/ value?
        
        ## Step 4, 5
        $table->{column}->[++$x_max] = {element => $current_column} for 1..$span;
      }
      
      ## Step 7
      my $cg = {element => $current_element,
                x => $x_start, y => 1,
                width => $x_max - $x_start - 1}; ## ISSUE: Spec incorrect
      $cg->{width} = $x_max - $x_start + 1;
      $table->{column_group}->[$_] = $cg for $x_start .. $x_max;
    } else { # no <col> children
      ## Step 1
      my $span = 1;
      my $col_span = $current_element->get_attribute_ns (undef, 'span');
      ## Parse non-negative integer
      if (defined $col_span and $col_span =~ /^[\x09-\x0D\x20]*([0-9]+)/) {
        $span = $1 || 1;
      }
      ## ISSUE: If span=0, what is /span/ value?
      
      ## Step 2
      $x_max += $span;
      
      ## Step 3
      my $cg = {element => $current_element,
                x => $x_max - $span + 1, y => 1,
                width => $span};
      $table->{column_group}->[$_] = $cg for (($x_max - $span + 1) .. $x_max);
    }
    
    ## Step 3, 4
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
        $check_empty_column->();
        ## Step 5 of overall steps 2nd paragraph
        return $table;
      }
    } # NEXT_CHILD
  }

  ## Step 10
  my $y_current = 0;

  ## Step 11
  my @downward_growing_cells;

  my $growing_downward_growing_cells = sub {
    ## Step 1
    return unless @downward_growing_cells;

    ## Step 2
    if ($y_max < $y_current) {
      $y_max++;
      undef $y_max_node;
    }

    ## Step 3
    for (@downward_growing_cells) {
      for my $x ($_->[1] .. ($_->[1] + $_->[2] - 1)) {
        $table->{cell}->[$x]->[$y_current] = [$_->[0]];
        $_->[0]->{height}++;
      }
    }
  }; # $growing_downward_growing_cells

  my $process_row = sub {
    ## Step 1
    $y_current++;
    
    ## Step 2
    $growing_downward_growing_cells->();
    
    ## Step 3
    my $x_current = 1;

    ## Step 4
    my $tr = shift;
    my @tdth = grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      {td => 1, th => 1}->{$_->manakai_local_name}
    } @{$tr->child_nodes};
    #return unless @tdth; # redundant with |while| below

    ## Step 5, 16, 17, 18
    ## ISSUE: Step 18 says "step 5 (cells)" while "cells" is step 6.
    while (@tdth) {
      my $current_cell = shift @tdth;
    
      ## Step 6: cells
      $x_current++
        while ($x_current <= $x_max and
               $table->{cell}->[$x_current]->[$y_current]);

      ## Step 7
      if ($x_current > $x_max) {
        $x_max++;
      }

      ## Step 8
      ## ISSUE: How to parse |colspan| is not explicitly specified
      ## (while |span| was).
      ## <http://lists.whatwg.org/pipermail/whatwg-whatwg.org/2006-November/007981.html>
      my $colspan = 1;
      my $attr_value = $current_cell->get_attribute_ns (undef, 'colspan');
      if (defined $attr_value and $attr_value =~ /^[\x09-\x0D\x20]*([0-9]+)/) {
        $colspan = $1 || 1;
      }
      
      ## Step 9
      my $rowspan = 1;
      ## ISSUE: How to parse
      ## <http://lists.whatwg.org/pipermail/whatwg-whatwg.org/2006-November/007981.html>
      my $attr_value = $current_cell->get_attribute_ns (undef, 'rowspan');
      if (defined $attr_value and $attr_value =~ /^[\x09-\x0D\x20]*([0-9]+)/) {
        $rowspan = $1;
      }
      
      ## Step 10
      my $cell_grows_downward;
      if ($rowspan == 0) {
        $cell_grows_downward = 1;
        $rowspan = 1;
      }
      
      ## Step 11
      if ($x_max < $x_current + $colspan - 1) { 
        @column_generated_by[$_] = $current_cell
          for $x_max + 1 .. $x_current + $colspan - 1;
        $x_max = $x_current + $colspan - 1;
      }
      
      ## Step 12
      if ($y_max < $y_current + $rowspan - 1) {
        $y_max = $y_current + $rowspan - 1;
        $y_max_node = $current_cell;
      }
      
      ## Step 13
      my $cell = {
                  is_header => ($current_cell->manakai_local_name eq 'th'),
                  element => $current_cell,
                  x => $x_current, y => $y_current,
                  width => $colspan, height => $rowspan,
                 };
      $has_anchored_cell[$x_current] = 1;
      for my $x ($x_current .. ($x_current + $colspan - 1)) {
        for my $y ($y_current .. ($y_current + $rowspan - 1)) {
          unless ($table->{cell}->[$x]->[$y]) {
            $table->{cell}->[$x]->[$y] = [$cell];
          } else {
            $onerror->(type => "cell overlapping:$x:$y", node => $current_cell);
            push @{$table->{cell}->[$x]->[$y]}, $cell;
          }
        }
      }
      
      ## Step 14
      if ($cell_grows_downward) {
        push @downward_growing_cells, [$cell, $x_current, $colspan];
      }
      
      ## Step 15
      $x_current += $colspan;
    }
  }; # $process_row

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
        ## Step 10 2nd sentense
        if ($y_current != $y_max) {
          $onerror->(type => 'no cell in last row', node => $table_el);
        }
        ## End of subsection
        $check_empty_column->();
        ## Step 5 2nd paragraph
        return $table;
      }
    } # NEXT_CHILD

    ## Step 13
    if ($current_ln eq 'tr') {
      $process_row->($current_element);
      redo ROWS;
    }

    ## Step 14
    ## Ending a row group
      ## Step 1
      if ($y_current < $y_max) {
        $onerror->(type => 'rowspan expands table', node => $y_max_node);
      }
      ## Step 2
      while ($y_current < $y_max) {
        ## Step 1
        $y_current++;
        $growing_downward_growing_cells->();
      }
      ## Step 3
      @downward_growing_cells = ();
      
    ## Step 15
    my $y_start = $y_max + 1;

    ## Step 16
    for (grep {
      $_->node_type == 1 and
      defined $_->namespace_uri and
      $_->namespace_uri eq q<http://www.w3.org/1999/xhtml> and
      $_->manakai_local_name eq 'tr'
    } @{$current_element->child_nodes}) {
      $process_row->($_);
    }

    ## Step 17
    if ($y_max >= $y_start) {
      my $rg = {element => $current_element,
                x => 1, y => $y_start,
                height => $y_max - $y_start + 1};
      $table->{row_group}->[$_] = $rg for $y_start .. $y_max;
    }

    ## Step 18
    ## Ending a row group
      ## Step 1
      if ($y_current < $y_max) {
        $onerror->(type => 'rowspan expands table', node => $y_max_node);
      }
      ## Step 2
      while ($y_current < $y_max) {
        ## Step 1
        $y_current++;
        $growing_downward_growing_cells->();
      }
      ## Step 3
      @downward_growing_cells = ();

    ## Step 19
    redo ROWS; # Step 12
  } # ROWS
} # form_table

## TODO: Implement scope="" algorithm

1;
## $Date: 2007/07/01 04:46:48 $
