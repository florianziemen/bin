#!/usr/bin/env python

import netCDF4 as nc
import matplotlib.pylab as mpl
import numpy.ma as ma
import math

infile = nc.Dataset("input_grid.nc","r")
vars=infile.variables


so = vars['so'][:]
tho = vars['thetao'][:]

s0 = so[0]
m0 = ~s0.mask
f0 = s0.filled(0)
mpl.figure()
mpl.imshow(s0, interpolation = "nearest")
mpl.colorbar()

i2=1/2.
s1 = s0 [:]
storage = s0[:]
reached = False
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
  s2=s1*(~m0)*ic1 + f0*m0
  if  not reached and  (abs(s2-f1).max() < 0.01) :
    print ("Limit reached after %d iterations"%x)
    mpl.figure()
    mpl.imshow(s2, interpolation = "nearest")
    mpl.colorbar()
    mpl.title("%d iterations"%x)
    reached = True
    storage = s2
  s1=s2




mpl.figure()
mpl.imshow(s1, interpolation = "nearest")
mpl.colorbar()


mpl.figure()
mpl.imshow(ma.masked_equal(storage - s1,0.0), interpolation = "nearest")
mpl.title ( "Error from criterion")
mpl.colorbar()



mpl.show()