#!/usr/bin/env python

import netCDF4 as nc
import matplotlib.pylab as mpl
import numpy as np
import numpy.ma as ma
from argparse import ArgumentParser
import sys


def diffuse(variables, filename):
  infile = nc.Dataset(filename, "r+")
  fvars=infile.variables

  for var in variables:
    data = fvars[var]
    for (n,s0) in enumerate(data):
      print "processing slice %d of %s"%(n, var)
      print s0.shape
      m0 = ~s0.mask
      f0 = s0.filled(0)
      # mpl.figure()
      # mpl.imshow(s0, interpolation = "nearest")
      # mpl.colorbar()

      i2=1/2.
      s1 = s0 [:]
      storage = s0[:]
      for x in xrange(40000):

        m1 = ~s1.mask
        f1 = s1.filled(0)
        s1=f1*0

        s1[1:] = s1[1:] + f1[:-1]
        s1[:-1] = s1[:-1] + f1[1:]
        s1[:,1:] = s1[:,1:] + f1[:,:-1]
        s1[:,:-1] = s1[:,:-1] + f1[:,1:]

        # s1[1:,1:] = s1[1:,1:] + i2 * f1[:-1,:-1]
        # s1[1:,:-1] = s1[1:,:-1] + i2 * f1[:-1,1:]
        # s1[:-1,1:] = s1[:-1,1:] + i2 * f1[1:,:-1]
        # s1[:-1,:-1] = s1[:-1,:-1] + i2 * f1[1:,1:]

        c1=f1*0
        c1[1:] = c1[1:] + m1[:-1]
        c1[:-1] = c1[:-1] + m1[1:]
        c1[:,1:] = c1[:,1:] + m1[:,:-1]
        c1[:,:-1] = c1[:,:-1] + m1[:,1:]

        # c1[1:,1:] = c1[1:,1:] + i2 * m1[:-1,:-1]
        # c1[1:,:-1] = c1[1:,:-1] + i2 * m1[:-1,1:]
        # c1[:-1,1:] = c1[:-1,1:] + i2 * m1[1:,:-1]
        # c1[:-1,:-1] = c1[:-1,:-1] + i2 * m1[1:,1:]



        ic1 = ma.masked_less(c1, 0.2)
        ic1 = 1./ic1
        s1=s1*(~m0)*ic1 + f0*m0
        if   (abs(s1-f1).max() < 0.01) :
          print ("Limit reached after %d iterations"%x)
          break
      fvars[var][n] = s1



    # mpl.figure()
    # mpl.imshow(s1, interpolation = "nearest")
    # mpl.colorbar()


    # mpl.figure()
    # mpl.imshow(ma.masked_equal(storage - s1,0.0), interpolation = "nearest")
    # mpl.title ( "Error from criterion")
    # mpl.colorbar()



    # mpl.show()


def parse_args():
  parser = ArgumentParser()
  parser.description = "Diffuse out fields into missval land"
  parser.add_argument("-v", "--verbose",
                    help='''Be verbose''', action="store_true")
  parser.add_argument("VARS",
                      help='''comma separated list of variables''', nargs=1)
  parser.add_argument("FILE",
                      help='''File to read variables from''', nargs=1)

  options = parser.parse_args()
  return options
def main():
  options = parse_args()
  if options.verbose:
    print (dir(options))
  variables = options.VARS[0].split(",")
  diffuse(variables, options.FILE[0])




if __name__ == "__main__":
    main()
