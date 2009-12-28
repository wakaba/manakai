set terminal png color
set output "time.png"

set xlabel "data length [characters]"
set ylabel "time [s]"

plot \
  ".decode.txt" title "bytes->char", \
  ".parse.txt" title "html5->dom5", \
  ".serialize.txt" title "dom5 serialize", \
  ".check.txt" title "dom5 check"

set output "time-log.png"
set logscale x
set logscale y
replot

## License: Public Domain.
## $Date: 2007/06/21 14:46:31 $
