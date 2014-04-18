#!/usr/bin/env python
# -*- coding: utf-8 -*-

import netCDF4 as nc
import datetime
import copy
import flo_utils as fu
import sys

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
        print dir(pism_dimensions[dim])
        if pism_dimensions[dim].isunlimited():
            pism_time = dim
            print "using %s as pism time dimension"%dim
    for dim in climate_dimensions.keys() :
        if climate_dimensions[dim].isunlimited():
            climate_time = dim
            print "using %s as climate time dimension"%dim
    
    ptv=pism_file.variables[pism_time]
    ctv=climate_file.variables[climate_time]
    
    pism_date     = nc.num2date(ptv[ptv.size - 1], units = ptv.units, calendar = ptv.calendar)
    
    climate_start = nc.num2date(ctv[0],  units = ctv.units, calendar = ctv.calendar)
    climate_2nd =  nc.num2date(ctv[1],  units = ctv.units, calendar = ctv.calendar)
    climate_end   = nc.num2date(ctv[ctv.size - 1], units = ctv.units, calendar = ctv.calendar)
    run_end = copy.copy(pism_date)
    run_end.year = run_end.year + 10

    test = climate_end - climate_start
    
    print test
    print pism_date
    print climate_start
    print climate_end
    print run_end

    # so, und jetzt will ich Modulo-Rechnung auf den Jahren machen.
    # Wie oft muss ich das Klima hintereinander ketten, um an das Startjahr zu kommen,
    # bzw. wie bekomme ich das eine in das andere gepasst?
    
    # Den Offset vom Klima berücksichtige ich am Ende. Das interessante ist die Dauer?
    # Nee, wenn ich ein Klima habe, das 1800 bis 2000 ist, dann sollen Eis-Modell-Jahre 1800 bis 2000 das gefälligst auch benutzen.
    # Ok, ich gehe jezt einfach mal von ganzen Jahren im Klima aus, Alles andere wird unfassbarer Hirnfick.
    # auch das wird schon Spass, weil ich ja i.d.R. mit dem dezember-Zeitschritt ende.

    # wenn ich mehr als 1 Record habe, kann ich die Zeitschritt-Länge abfragen.
    print (dir(test))
    climate_timestep = (climate_2nd - climate_start)
    if climate_timestep == 0:
        fu.cerr("ERROR: CLIMATE TIMESTEP LENGTH = 0 -- THIS IS A FIXED CLIMATE")
        sys.exit(666)
    print climate_timestep
    print climate_start < pism_date
    print climate_end > run_end
    runs_per_climate = (climate_end - climate_start) # .total_seconds() # /((run_end - pism_date).total_seconds())
    print (climate_end , climate_end + climate_timestep)
    