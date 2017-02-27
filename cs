#!/bin/bash

start=$1
inc=$2
end=$3

echo $(seq $start $inc $end) |sed 's/ /,/g'
