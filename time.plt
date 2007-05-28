set terminal png color
set output "time.png"

set xlabel "data length [characters]"
set logscale y
set ylabel "time [s]"

plot \
  ".decode.txt" title "bytes->char", \
  ".parse.txt" title "html5->dom5", \
  ".serialize.txt" title "dom5 serialize", \
  ".check.txt" title "dom5 check"
