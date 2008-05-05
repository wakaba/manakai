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
        ## ISSUE: If span=0, what is /span/ value?
        
        ## Step 4, 5
        $table->{column}->[++$x_width] = {element => $current_column}
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
      ## ISSUE: If span=0, what is /span/ value?
      
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
  return $table;
} # form_table

## TODO: Implement scope="" algorithm

1;
## $Date: 2008/05/05 08:36:55 $
