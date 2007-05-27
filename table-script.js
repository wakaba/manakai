function tableToCanvas (table) {
  var canvas = document.createElement ('canvas');
  document.body.appendChild (canvas);
  var c2d = canvas.getContext ('2d');

  var param = {
    columnLeft: 20,
    columnWidth: 20,
    columnSpacing: 5,
    columnGroupTop: 10,
    columnTop: 15,
    rowTop: 20,
    rowHeight: 20,
    rowSpacing: 5,
    rowGroupLeft: 10,
    rowLeft: 15,
    cellTop: 20,
    cellLeft: 20,
    cellBottom: 20,
    cellRight: 20,
    explicitColumnGroupStrokeStyle: 'black',
    explicitColumnStrokeStyle: 'black',
    impliedColumnStrokeStyle: '#C0C0C0',
    explicitHeaderRowGroupStrokeStyle: 'black',
    explicitHeaderRowGroupFillStyle: 'rgba(220, 220, 220, 0.3)',
    explicitBodyRowGroupStrokeStyle: 'black',
    explicitBodyRowGroupFillStyle: 'rgba(0, 0, 0, 0)',
    explicitFooterRowGroupStrokeStyle: 'black',
    explicitFooterRowGroupFillStyle: 'rgba(220, 220, 220, 0.3)',
    explicitRowStrokeStyle: 'black',
    impliedRowStrokeStyle: '#C0C0C0',
    headerCellFillStyle: 'rgba(192, 192, 192, 0.5)',
    headerCellStrokeStyle: 'black',
    dataCellFillStyle: 'rgba(0, 0, 0, 0)',
    dataCellStrokeStyle: 'black',
    overlappingCellFillStyle: 'red',
    overlappingCellStrokeStyle: 'rgba(0, 0, 0, 0)'
  };

var columnNumber = table.column.length;
if (columnNumber < table.cell.length) columnNumber = table.cell.length;
var rowNumber = 0;
for (var i = 1; i < table.cell.length; i++) {
  if (table.cell[i] && rowNumber < table.cell[i].length) {
    rowNumber = table.cell[i].length;
  }
}

canvas.width = param.cellLeft
    + (param.columnWidth + param.columnSpacing) * columnNumber
    + param.cellRight;
canvas.height = param.cellTop
    + (param.rowHeight + param.rowSpacing) * rowNumber
    + param.cellBottom;
canvas.style.width = 'auto'; // NOTE: Opera9 has default style=""
canvas.style.height = 'auto';

var y = param.rowTop;
for (var i = 1; i < table.row_group.length; i++) {
  var rg = table.row_group[i];
  c2d.beginPath ();
  if (rg.type == 'thead') {
    c2d.strokeStyle = param.explicitHeaderRowGroupStrokeStyle;
    c2d.fillStyle = param.explicitHeaderRowGroupFillStyle;
  } else if (rg.type == 'tfoot') {
    c2d.strokeStyle = param.explicitFooterRowGroupStrokeStyle;
    c2d.fillStyle = param.explicitFooterRowGroupFillStyle;
  } else {
    c2d.strokeStyle = param.explicitBodyRowGroupStrokeStyle;
    c2d.fillStyle = param.explicitBodyRowGroupFillStyle;
  }
  var dy = (param.rowHeight + param.rowSpacing) * rg.height;
  c2d.moveTo (param.rowGroupLeft, y);
  c2d.lineTo (param.rowGroupLeft, y + dy - param.rowSpacing);
  c2d.stroke ();
  c2d.closePath ();
  c2d.beginPath ();
  c2d.rect (param.rowGroupLeft,
            y,
            (param.columnWidth + param.columnSpacing) * columnNumber - param.columnSpacing,
            dy - param.rowSpacing);
  c2d.fill ();
  c2d.closePath ();
  y += dy;
  i += rg.height - 1;
}

c2d.beginPath ();
c2d.strokeStyle = param.explicitColumnGroupStrokeStyle;
var x = param.columnLeft;
for (var i = 1; i < table.column_group.length; i++) {
  var cg = table.column_group[i];
  c2d.moveTo (x, param.columnGroupTop);
  x += (param.columnWidth + param.columnSpacing) * cg.width;
  c2d.lineTo (x - param.columnSpacing, param.columnGroupTop);
  i += cg.width - 1;
}
c2d.stroke ();
c2d.closePath ();

var x = param.columnLeft;
for (var i = 1; i < columnNumber; i++) {
  var c = table.column[i];
  c2d.beginPath ();
  c2d.moveTo (x, param.columnTop);
  x += param.columnWidth + param.columnSpacing;
  c2d.lineTo (x - param.columnSpacing, param.columnTop);
  if (c) {
    c2d.strokeStyle = param.explicitColumnStrokeStyle;
  } else {
    c2d.strokeStyle = param.impliedColumnStrokeStyle;
  }
  c2d.stroke ();
  c2d.closePath ();
}

var x = param.cellLeft;
for (var i = 1; i < table.cell.length; i++) {
  var y = param.cellTop;
  if (!table.cell[i]) continue;
  for (var j = 1; j < table.cell[i].length; j++) {
    var c = table.cell[i][j];
    if (c && ((c[0].x == i && c[0].y == j) || c.length > 1)) {
      c2d.beginPath ();
      var width = (param.columnWidth + param.columnSpacing) * c[0].width
          - param.columnSpacing;
      var height = (param.rowHeight + param.rowSpacing) * c[0].height
          - param.rowSpacing;
      if (c.length == 1) {
        c2d.rect (x, y, width, height);
        c2d.fillStyle = c[0].is_header
            ? param.headerCellFillStyle : param.dataCellFillStyle;
        c2d.strokeStyle = c[0].is_header
            ? param.headerCellStrokeStyle : param.dataCellStrokeStyle;
      } else {
        c2d.rect (x, y, param.columnWidth, param.rowHeight);
        c2d.fillStyle = param.overlappingCellFillStyle;
        c2d.strokeStyle = param.overlappingCellStrokeStyle;
      }
      c2d.fill ();
      c2d.stroke ();
      c2d.closePath ();
    }
    y += param.rowHeight + param.rowSpacing;
  }
  x += param.columnWidth + param.columnSpacing;
}

var y = param.rowTop;
for (var i = 1; i < rowNumber; i++) {
  c2d.beginPath ();
  c2d.moveTo (param.rowLeft, y);
  y += param.rowHeight + param.rowSpacing;
  c2d.lineTo (param.rowLeft, y - param.rowSpacing);
  //if (true) {
    c2d.strokeStyle = param.explicitRowStrokeStyle;
  //} else {
  //  c2d.strokeStyle = param.impliedRowStrokeStyle;
  //}
  c2d.stroke ();
  c2d.closePath ();
}
} // tableToCanvas

/*

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

*/
/* $Date: 2007/05/27 06:37:05 $ */
