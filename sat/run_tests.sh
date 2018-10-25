#!/bin/bash

TIMEFORMAT="%R"
NUM_TRIALS=10

# for benchmark in benchmarks/uf150-*
# do
#     total=0
#     for trial in {0..$NUM_TRIALS}
#     do
#         res=$(time (./bin/sat $benchmark $@ > /dev/null) 2>&1)
#         total=$(echo "scale = 5; $total + $res" | bc)
#     done
#     mean=$(echo "scale = 5; $total / $NUM_TRIALS" | bc)
#     echo "$benchmark, $mean"
# done

total=0
for trial in $(seq 0 $NUM_TRIALS)
do
    res=$(time (./bin/sat $@ > /dev/null) 2>&1)
    total=$(echo "scale = 5; $total + $res" | bc)
done
echo "scale = 5; $total / $NUM_TRIALS" | bc
