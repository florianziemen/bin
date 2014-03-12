#!/usr/bin/env python

import netCDF4 as nc
import datetime 

def sort_forcing_timing(pism_file_name, climate_file_name, years_to_run):
    plausible_time_names = ["time", "t"] 
    pism_file = nc.Dataset(pism_file_name)
    climate_file = nc.Dataset(climate_file_name)
    pism_dimensions = pism_file.dimensions
    climate_dimensions = climate_file.dimensions
    pism_time=False
    climate_time=False
    print pism_dimensions
    print climate_dimensions

    for dim in pism_dimensions.keys() :
        if pism_dimensions[t].is_unlimited():
            pism_time = dim
            print "using %s as pism time dimension"%dim
    for dim in climate_dimensions.keys() :
        if climate_dimensions[t].is_unlimited():
            climate_time = dim
            print "using %s as climate time dimension"%dim
    
    ptv=pism_file.variables[pism_time]
    ctv=climate_file.variables[climate_time]
    
    pism_date     = num2date(ptv[-1], units = ptv.units, calendar = ptv.calendar)
    climate_start = num2date(ctv[0],  units = ctv.units, calendar = ctv.calendar)
    climate_end   = num2date(ctv[-1], units = ctv.units, calendar = ctv.calendar)

    print pism_date
    print climate_start
    print climate_end
