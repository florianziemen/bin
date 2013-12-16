#!/usr/bin/env python

import gdal
from gdalconst import *
import struct
from netCDF4 import Dataset
import matplotlib.pylab as mpl
import numpy as np

filename = "dem_12313.grid"
outfilename = "test.nc"

dataset = gdal.Open(filename, GA_ReadOnly)
driver = dataset.GetDriver().LongName
geotransform = dataset.GetGeoTransform()
band = dataset.GetRasterBand(1)
bandtype = gdal.GetDataTypeName(band.DataType)
scanline = band.ReadRaster( 0, 0, band.XSize, 1,band.XSize, 1, band.DataType)
cols = dataset.RasterXSize
rows = dataset.RasterYSize
bands = dataset.RasterCount
data = band.ReadAsArray(0, 0, cols, rows)
mpl.imshow(data)
xpos=np.arange(data.shape[0])*geotransform[-1]*-1+geotransform[0]
ypos=np.arange(data.shape[1])*geotransform[-1]+geotransform[3]


outfile = Dataset(outfilename, 'w', format='NETCDF4')
print outfile.file_format
lat = outfile.createDimension('lat', cols)
lon = outfile.createDimension('lon', rows)

latitudes = outfile.createVariable('lat','f4',('lat',))
longitudes = outfile.createVariable('lon','f4',('lon',))
height = outfile.createVariable('height','f4',('lon','lat'))

print xpos.shape
print ypos.shape
print data.shape

longitudes[:] = xpos
latitudes[:] = ypos
height[:] = data

