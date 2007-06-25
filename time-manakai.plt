set terminal png color
set output "time-manakai.png"

set xlabel "data length [characters]"
set ylabel "time [s]"

plot \
  ".manakai-decode.txt" title "bytes->chars", \
  ".manakai-parse.txt" title "html5(chars)->dom5", \
  ".manakai-parse_xml.txt" title "xml1(bytes)->dom5", \
  ".manakai-serialize_html.txt" title "dom5->html5(char)", \
  ".manakai-serialize_xml.txt" title "dom5->xml1(char)", \
  ".manakai-serialize_test.txt" title "dom5->test(char)", \
  ".manakai-check.txt" title "dom5 check"

set output "time-manakai-log.png"
set logscale x
set logscale y
replot

## License: Public Domain.
## $Date: 2007/06/25 00:15:12 $
