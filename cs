#!/bin/bash

start=$(echo $1|sed 's/,/ /g')
inc=$2
end=$3

echo $(seq $start $inc $end) |sed 's/ /,/g'
