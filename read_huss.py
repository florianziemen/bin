#!/usr/bin/env python

import gdal
import math
from gdalconst import *
import struct
from netCDF4 import Dataset
import matplotlib.pylab as mpl
import numpy as np
import sys
import glob

increment = 30.

big_rows = big_cols = 10010
outfile = Dataset("big_file.nc", 'w', format='NETCDF4')
#print outfile.file_format
fdx = outfile.createDimension('x', big_cols)
fdy = outfile.createDimension('y', big_rows)

fvx = outfile.createVariable('x','f4',('x',))
fvy = outfile.createVariable('y','f4',('y',))
out_height = outfile.createVariable('height','f4',('y','x'), fill_value=-9.e9)
out_height.coordinates = "y x" ;
count = outfile.createVariable('count','i4',('y','x'), fill_value=-9.e9)
count.coordinates = "y x" ;
count[:] = 0 
# out_height[:]=0.
x_offset = 1000010.8
y_offset = 1000028.1
fvx[:] = np.arange (big_cols) * increment + (x_offset + increment/2.)
fvy[:] = np.arange (big_rows) * increment + (y_offset + increment/2.)


for     filename in  glob.glob("thick_*.agr"): # .grid

    dataset = gdal.Open(filename, GA_ReadOnly)
    driver = dataset.GetDriver().LongName
    geotransform = dataset.GetGeoTransform()

    band = dataset.GetRasterBand(1)
    bandtype = gdal.GetDataTypeName(band.DataType)
    scanline = band.ReadRaster( 0, 0, band.XSize, 1,band.XSize, 1, band.DataType)
    cols = dataset.RasterXSize
    rows = dataset.RasterYSize
    bands = dataset.RasterCount
    fincrement = - geotransform[-1]
    if fincrement != increment:
        print "GRID INCREMENTS DON'T MATCH! EXPECTING " + str(increment) + " GOT " + str(fincrement)
        print filename
        continue
#        sys.exit(666)
    xll = geotransform [0]
    xur = xll + cols * increment # remap to ur corner.
    yur = geotransform [3] 
    yll = yur - rows * increment # remap to ll corner.
    data = band.ReadAsArray(0, 0, cols, rows)
    #mpl.imshow(data, interpolation = "nearest")
    #mpl.colorbar()
    #mpl.show()
#    print geotransform
    xpos = np.arange(cols) * increment + xll + increment *.5
    ypos = np.arange(rows) * increment + yll + increment *.5

    writesingle = False
    if writesingle :
        single_outfilename = "test.nc"
        single_outfile = Dataset(single_outfilename, 'w', format='NETCDF4')
#        print single_outfile.file_format
        lon = single_outfile.createDimension('lon', cols)
        lat = single_outfile.createDimension('lat', rows)

        latitudes = single_outfile.createVariable('lat','f4',('lat',))
        longitudes = single_outfile.createVariable('lon','f4',('lon',))
        height = single_outfile.createVariable('height','f4',('lat','lon'))

        print xpos.shape
        print ypos.shape
        print data.shape

        longitudes[:] = xpos
        latitudes[:] = ypos
        height[:] = data[::-1,:]
        single_outfile.close()


    # print xpos.shape
    # print ypos.shape
    # print data.shape


    xmin = int(math.floor((xpos[0] - x_offset) / increment))
    xmax = int(xmin + cols)
    ymin = int(math.floor((ypos[0] - y_offset) / increment))
    ymax = int(ymin + rows)
    if xmin > 0 and xmax < big_cols and ymin > 0 and ymax < big_rows:
#        print (xmin, xmax, ymin, ymax)
        out_height[ymin:ymax,xmin:xmax] = np.where(data[::-1,:]> 0 , data[::-1,:], out_height[ymin:ymax,xmin:xmax] )
        count[ymin:ymax,xmin:xmax] += (data [::-1,:] >  0 )
# out_height[:] = np.where(count[:] > 0 , ( out_height[:] / count[:] ),  out_height[:])
out_height[:]=np.where(count[:],out_height[:],0)
outfile.close()

