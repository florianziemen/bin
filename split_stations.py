#!/usr/bin/env python

import sys

infile = open(sys.argv[1],"r")
data = infile.readlines()
stations = [
"USC00508672",
"USC00503198",
"USC00504103",
"USC00504107",
"USC00505851",
"US1AKJB0010",
"USR0000AJUN",
"USC00507451",
"US1AKJB0005",
"USC00508416",
"USC00501225",
"USC00500464",
"USC00504094",
"US1AKJB0002",
"USW00025309",
"USC00507221",
"USC00504117",
"USC00500363",
"USC00501226",
"USC00504092",
"US1AKJB0007",
"USC00508168",
"USC00504109",
"USC00504104",
"US1AKJB0009",
"USC00504110",
"US1AKJB0003"
]
outfiles = {}
for x in stations:
    outfiles[x]= open(x+".dat","w")

for x in outfiles.keys():
    outfiles[x].write(data[0])

for x in data[1:]:
    name=x[6:17]
    outfiles[name].write(x)

for x in outfiles.keys():
    outfiles[x].close()
