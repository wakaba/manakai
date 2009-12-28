set terminal png color
set output "time-cc.png"

set xlabel "data length [octets]"
set ylabel "time [s]"

plot \
  ".cc-decode.txt" title "bytes->chars", \
  ".cc-parse.txt" title "html5(chars)->dom5", \
  ".cc-parse_html.txt" title "html5(bytes)->dom5", \
  ".cc-parse_xml.txt" title "xml1(bytes)->dom5", \
  ".cc-parse_manifest.txt" title "manifest(bytes)->obj", \
  ".cc-check.txt" title "dom5 check", \
  x/1000 title 'y = x / 1000', \
  (x**0.5)/1000 title 'y = sqrt (x) / 1000'

set output "time-cc-log.png"
set logscale x
set logscale y
replot

## License: Public Domain.
## $Date: 2008/07/20 14:59:03 $
