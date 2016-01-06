from __future__ import print_function
import subprocess as sp
import shlex
import sys
import getopt
import os
import glob
import shutil
import re
import numpy as np
import netCDF4 as nc
import collections
from  local_conf import *
from os.path import expanduser
home = expanduser("~")

debug = False


def cerr(*objs):
  print( *objs, file=sys.stderr)

def debug_cerr(*objs):
  if debug:
    print( *objs, file=sys.stderr)

def gen_names(start, end):
  nums=[int(start)] + range(int(start)+ 50 - (int(start)%50),int(end)+2,50)
  names= ["%s-%s"%(nums[x],nums[x+1]-1) for x in range (len(nums)-1)]
  debug_cerr(names)
  return names


def save_cpt(p, name):
  of = open(home+"/.NCL/colormaps/%s.rgb"%name, 'w')
  of.write( "n_colors=%d\n"%len(p))
  of.write( "# r g b \n")
  of.write("\n".join([ " ".join([str (y) for y in x ])  for x in p ]))
  of.close()

def get_tornado_dir(floname):
  return my_tornado_run_dir + "/%s"%(floname)

def get_mpism_dir (floname):
  return work+"/mpism/" +floname

def set_debug(state):
  global debug
  debug = state


def get_my_bin():
  return my_bin


def query (question, stdin_string=False):
  if type(question) is str:
    question=shlex.split(question)


    debug_cerr("FU: trying " + " ".join(question))
  a = sp.Popen(question, stdin = sp.PIPE, stdout = sp.PIPE, stderr = sp.PIPE)

  if stdin_string:
    (so, se) = a.communicate(stdin_string)
  else:
    (so, se) = a.communicate()
  if debug:
    cerr( "returned " + str( a.returncode) )
  if a.returncode:
    cerr( "FU: attempting " + str(question) + " in  " + os.getcwd())
    cerr( "FU: returned " + str( a.returncode) )
    cerr( "FU: program stdout:")
    cerr( so)
    cerr( "FU: program stderr:")
    cerr( se)
    exit (a.returncode)
  return (so,se)

def qo(question, stdin_string=False):
  a = query(question, stdin_string)[0]
  return a


def check_call_ncl(arguments):
  if (debug):
    cerr( "trying ncl " " ".join(arguments))
  return sp.check_call(["/sw/lenny-x64/ncl-5.2.1-gccsys/bin/ncl"] + arguments, env= {"NCARG_ROOT" : "/sw/lenny-x64/ncl-5.2.1-gccsys", "PATH" : os.environ["PATH"]})

def rm_if_exist(files):
  if type (files) is str:
    files = [files]
  for filename in files:
    debug_cerr( "FU: removing %s if exists"%(filename))
    if ( os.access(filename,os.R_OK) ) :
      debug_cerr( "FU: %s exists. Removing it"%(filename))
      os.remove(filename)

def guess_name_from_dir():
  currdir=os.getcwd()
  if currdir[-8:-4] == '/flo':
    try:
      num=int(currdir[-4:])
    except:
      cerr( "FU: Could not guess run from directory name %s"%(currdir))
      exit(2)
    flo_name = currdir[-7:]
    debug_cerr( "using flo_name %s"%flo_name)
  if currdir[-4:-2] == '/F':
    try:
      num=int(currdir[-2:])
    except:
      cerr( "FU: Could not guess run from directory name %s"%(currdir))
      exit(2)
    flo_name = "flo00" + currdir[-2:]
    debug_cerr( "FU: using flo_name %s"%flo_name)
  return flo_name



def goto_dir(directory):
  if os.path.isdir(directory):
    debug_cerr( "FU: directory  %s  exists. Entering it."%(directory))
  else:
    sys.exit("FU: no data found\n" + directory + "\ndoes not exist")
  os.chdir(directory)



def check_files(filenames, fatal = True):
  ok = True
  if type(filenames) is str:
    filenames=filenames.split("\n")
  for filename in filenames:
    ok = ok and os.access(filename,os.R_OK)
    if  not ok:
      if fatal:
        sys.exit("FU: file '" + filename + "' does not exist! Exiting!")
      else:
        cerr("FU: file '" + filename + "' does not exist! Continuing anyway since not considered fatal.")

  return ok


def get_script_dir (floname):
  return my_script_dir + "/%s/scripts" % (floname)

def get_dir(floname):
  oke = "/work/mh0020/m300019/cosmos_work/experiments/"
  ke = work + "/cosmos_work/experiments/"
  se = scratch + "/cosmos_work/experiments/"
  for x in [ke, oke, se]:
    if os.path.isdir(x+floname):
      debug_cerr( "FU: directory %s exists. using it"%(x+floname))
      return x+floname
  sys.exit("FU: no directory found for " + floname + "! Exiting!")

def get_tmp_name(floname, param):
  return scratch + "/tmp/" + floname + "/" + param

def get_meanplot_dir(floname):
  return work + "/means/" + floname



def mkdir(target):
  if not os.path.isdir(target):
    debug_cerr( "FU: creating directory " + target)
    os.makedirs(target)

  return target

def mktmp(floname, param):
  target = get_tmp_name (floname, param)
  return  mkdir(target)


def make_p2e_dir(floname):
  target = get_dir(floname) + "/pism2echam"
  return mkdir(target)


def copy_files(files,target):
  debug_cerr( "copying \n%s\nto %s"%("\n".join(files), target))
  for x in files:
    shutil.copy2(x,target)

def get_uwe_name(flo_name):
  return flo_name[0].upper()+flo_name[-2:]

cache_dirs=[]
def pushd(directory = False):
  global cache_dirs
  if (not directory):
    directory = os.getcwd()
  debug_cerr( "FU: pushing directory %s"%directory)
  cache_dirs.append (directory)

def popd():
  global cache_dirs
  directory = (cache_dirs[-1])
  cache_dirs = cache_dirs[:-1]
  debug_cerr( "FU: popping directory %s"%directory)
  return directory


def parse_years (arg):
  years=[]
  single_year = re.compile('-?[0-9]*')
  year_range  = re.compile('(-?[0-9]*):(-?[0-9]*)')
  year_stride  = re.compile('(-?[0-9]*):(-?[0-9]*):(-?[0-9]*)')
  sy =  single_year.match(arg)
  my = year_range.match (arg)
  mys = year_stride.match (arg)
  if sy and sy.group() == arg :
    years.append(arg)
  elif my and my.group() == arg:
    (start,stop) = my.groups()
    start=int(start)
    stop=int(stop)
    if start <= stop:
      years = years + [str(x) for x in xrange (start,stop)]
    else:
      cerr( "trouble parsing year argument " + arg)
      cerr( "start year must be <= end year for ranges")
      exit(2)
  elif mys and mys.group() == arg:
    (start,stop,stride) = mys.groups()
    start=int(start)
    stop=int(stop)
    stride=int(stride)
    if (stop - start) * stride > 0 :
      years = years + [str(x) for x in xrange (start,stop,stride)]
    else:
      cerr( "trouble parsing year argument " + arg)
      cerr( "start year must be <= end year for ranges with positive stride and the other way around for neg strides")
      exit(2)

  else:
    cerr( "can't parse year argument " + arg)
    usage()
    sys.exit(2)
  return years




def spread_out(a, width=5):
  b=np.zeros(a.shape)
  for x in np.arange (width):
    if x:
      b[x:] =b[x:] +a[:-x]
      b[:-x]=b[:-x]+a[x:]
    else :
      b = b + a
    for y in np.arange(width-x):
      if y and x :
        b[x:  , y:  ] = b[x:  , y:  ] + a[ :-x,  :-y]
        b[x:  ,  :-y] = b[x:  ,  :-y] + a[ :-x, y:  ]
        b[ :-x,  :-y] = b[ :-x,  :-y] + a[x:  , y:  ]
        b[ :-x, y:  ] = b[ :-x, y:  ] + a[x:  ,  :-y]
      else :
        if y:
          b[:,y:] =b[:,y:] +a[:,:-y]
          b[:,:-y]=b[:,:-y]+a[:,y:]
  return b



def get_data(filename, variable):
  infile=nc.Dataset(filename, "r")
  data=infile.variables[variable][:]
  dimensions=collections.OrderedDict([ [x,infile.variables[x][:]] for x in infile.variables[variable].dimensions])
  infile.close()
  return (data, dimensions)


def corr(fields_file, fields_var, ts_file, ts_var, opts={}):
  if "cdo_opts" in opts.keys():
    cdo_opts = opts["cdo_opts"]
  else:
    cdo_opts = ""
  qo("cdo -f ext -b 64 copy %s -selvar,%s %s fort.50"%(cdo_opts, fields_var, fields_file))
  qo("cdo -f ext -b 64 copy %s -selvar,%s %s fort.51"%(cdo_opts, ts_var, ts_file))
  if ("max_lag" in opts.keys()) and ( "increment" in opts.keys() ):
    qo("%s/lagreg_uwe"%(my_bin), "%s %s"%(opts["max_lag"], opts["increment"]))
  else:
    qo("%s/lagreg_-200_1_200"%(my_bin))
  rm_if_exist("results.nc")
  command = "cdo -f nc  -merge -setgrid,%s -setname,regression fort.60 -setname,correlation -setgrid,%s fort.61 results.nc"%(fields_file, fields_file)
  qo(command)
  label= "%s from %s as function of %s from_%s, options = %s"%(fields_var, fields_file,ts_var,ts_file, str(opts))
  qo(["ncatted",  "-a" , "generated_by,global,o,c,"+label , "results.nc"])
