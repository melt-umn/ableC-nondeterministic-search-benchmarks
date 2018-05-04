#!/bin/bash

TIMEFORMAT="%R"
NUM_TRIALS=10

total=0
for trial in $(seq 0 $NUM_TRIALS)
do
    res=$(time (./bin/solitaire $@ > /dev/null) 2>&1)
    total=$(echo "scale = 5; $total + $res" | bc)
done
echo "scale = 5; $total / $NUM_TRIALS" | bc
