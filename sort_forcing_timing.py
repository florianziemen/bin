#!/usr/bin/env python

import netCDF4 as nc

def sort_forcing_timing(pism_file_name, climate_file_name, years_to_run):
    pism_file = nc.Dataset(pism_file_name)
    climate_file = nc.Dataset(climate_file_name)
    pism_dimensions = pism_file.dimensions
    climate_dimensions = climate_file.dimensions
    print pism_dimensions
    print climate_dimensions
