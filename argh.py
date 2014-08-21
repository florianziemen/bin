#!/usr/bin/python

from numpy import *
from pylab import *
import os
import time
import re
import glob
import subprocess as sp
import xml.dom.minidom as md
import tempfile
import shutil
import netCDF4 as nc

class report(object):
  def __init__(self,filename):
    self.starttime=0.
    self.endtime=0.
    self.duration=0.
    self.filename=filename
    self.solverlist=[]
    self.solvercount=[]
    self.thelist=[]
    self.iterations=0
    self.iterations_planned=0
    self.modeltime=0
    self.modeltime_offset=0
    self.timestep=0
    self.last_solver="--none--"
    self.xml_data={}
    self.images=[]
    infile=open(self.filename)
    line=infile.readline()
    starttime_string=re.findall('(2009/.*)\n',line)
    if (not len(starttime_string)):
      print "ILLEGAL FILE %s"%self.filename
      return -1
    
    self.get_times()
    self.get_iterations()
    self.get_timesteps()
    self.parse_xml()
    self.find_images()
    print self.solverlist
    print self.solvercount

    
  def get_times(self):
    if(not self.starttime):
      statinfo = os.stat(self.filename)
      infile=open(self.filename)
      line=infile.readline()
      print self.filename
      print line
      starttime_string=re.findall('(2009/.*)\n',line)[0]
      self.starttime=time.mktime(time.strptime(starttime_string,'%Y/%m/%d %H:%M:%S'))
      self.endtime=statinfo.st_mtime
      self.duration=statinfo.st_mtime-self.starttime
    return (self.starttime, self.endtime,self.duration)

  def get_timesteps(self):
#    if(self.iterations_planned!=0):
#      return (self.iterations,self.iterations_planned,self.modeltime)
    infile=open(self.filename)
    lines=infile.read()
    print self.filename
    timestepstr=re.findall("\nTimestep Sizes\s*=\s*([0-9.]*)",lines)
    if (not len(timestepstr)):
        return -1
    
    timestepstr=timestepstr[0]
    self.timestep=float(timestepstr)
    infile.close()
    alltimes=re.findall('Time: (.*)',lines)
    if(len(alltimes)):
      starttime_offset=alltimes[0]
      (iterations,planned,modeltime)=re.findall('\s*([0-9]*)/([0-9]*)\s*(.*)',starttime_offset)[0]
      self.modeltime_offset=float(modeltime)-self.timestep
      lasttime=alltimes[-1]
      (iterations,planned,modeltime)=re.findall('\s*([0-9]*)/([0-9]*)\s*(.*)',lasttime)[0]
      iterations=int(iterations)
      planned=int(planned)
      modeltime=float(modeltime)
      self.iterations=iterations
      self.iterations_planned=planned
      self.modeltime=modeltime
    print (self.iterations,self.iterations_planned,self.modeltime)
    return (self.iterations,self.iterations_planned,self.modeltime)
  
  def get_iterations(self):
    if(self.thelist):
      return [self.solverlist,self.thelist]
    text=open(self.filename).read()
    alllist=re.findall('(.*[0-9]) (.*)\nComputeChange.* \(\s*(\S*)\s*(\S*).* ::\s(.*)',text)
    #iteration_number, precision, norm, rel_change, name
    allsolverlist=[x[4]for x in alllist]
    numberedlist=[[number, int(value[0]),float(value[1]),float(value[2]),float(value[3]),value[4]] for (number,value) in enumerate (alllist)] 
    self.solverlist=unique(allsolverlist).tolist()
    self.solvercount=[allsolverlist.count(x) for x in self.solverlist]
    thelist=[]
    for (number,solver) in enumerate(self.solverlist):
      data=zeros([self.solvercount[number],5])
      i=0
      for x in numberedlist:
          if(x[5]==solver):
            data[i][0]=x[0]
            data[i][1]=x[1]
            data[i][2]=x[2]
            data[i][3]=x[3]
            data[i][4]=x[4]
            i=i+1
      thelist.append(data)
    self.allsolvers={}
    
#      print data
    self.thelist=thelist
    if (numberedlist):
      self.last_solver=numberedlist[-1][5]
    return [self.solverlist,self.thelist]

  def plot_iterations(self,force_replot=True):
    pdfname=re.sub('.log','_solvers.pdf',self.filename)
    if ( os.path.isfile( pdfname )):
      if ((not force_replot) and newer(pdfname,self.filename)):
        print "skipping plotting \n %s \n since pdf is newer and replot not forced"%(self.filename)
        return
    close(1)
    figure(1)
    # print self.thelist[:][0]
    for (number,solver) in enumerate(self.solverlist):
      data=self.thelist[number]
      semilogy(data[:,0],data[:,1],'.-',label=solver)
    legend(loc=2)
    title(self.filename)
    xlabel('solver call')
    ylabel('linear system iterations')
    savefig(re.sub('.log','_solvers.pdf',self.filename))
    close(1)
    figure(1)
    # print self.thelist[:][0]
    for (number,solver) in enumerate(self.solverlist):
      data=self.thelist[number]
      semilogy(data[:,0],data[:,3],'.-',label=solver)
    title(self.filename)
    xlabel('solver call')
    ylabel('linear system norm')
    savefig(re.sub('.log','_norms.pdf',self.filename))
    
  
  def print_report(self):
    outfilepath=re.sub('.log','.tex',self.filename)
    outfile=open(outfilepath,'w')
    print_head(outfile)
    self.print_body(outfile)
    print_closing(outfile)
    outfile.close()
    latex_file(outfilepath)
    
  def print_body(self,outfile):
    duration=self.duration
    start=self.starttime
    end=self.endtime
    outfilepath=re.sub('.log','.tex',self.filename)
    (outfiledir,outfilename)=os.path.split(outfilepath)
    
    outfile.write("\\begin{center} Documentation generated from %s \\end{center}\\\n"%(re.sub('_','\\_',self.filename)))
    outfile.write("\\begin{minipage}{.5\\textwidth}")
    outfile.write("\\begin{tabular}{l r}\n")
    durationstring=str(int(duration/3600)).zfill(2)+":"+str(mod(int(duration/60),60)).zfill(2)+":"+str(mod(int(duration),60)).zfill(2)
    outfile.write("run started & {\\tt %s} \\\\ \n run ended &   {\\tt %s}\\\\\n  duration&  {\\tt %s}\\\\\n"%(time.ctime(start),time.ctime(end),durationstring))
    outfile.write("Model time at start &{\\tt %s}\\\\\n"%(self.modeltime_offset))
    outfile.write("timestep &{\\tt %s}\\\\\n"%(self.timestep))
    outfile.write("iterations planned &{\\tt %s}\\\\\n"%(self.iterations_planned))
    outfile.write("last iteration started &{\\tt %s}\\\\\n"%(self.iterations))
    outfile.write("Time at last timestep &{\\tt %s}\\\\\n"%(self.modeltime))
    outfile.write("Last finished solver &{\\tt %s}\\\\\n"%(self.last_solver))
    outfile.write("config file  & {\\tt %s} \\\\ \n"%(re.sub('tex','sif',outfilename)))
    outfile.write("\\end{tabular}\n\\par\\vspace{.5cm}\n")
    
    
    outfile.write("\\begin{tabular}{lrr}\n")
    outfile.write("Solver &  called &tot. iterations\\\\ \n")
    for (number,solver) in enumerate(self.solverlist):
      outfile.write(solver+" & "+str(int(self.solvercount[number]))+ " & " + str(int(sum(self.thelist[number][:,1])))+'\\\\ \n')
    outfile.write("\\end{tabular}\n")
    keylist=self.xml_data.keys()
    keylist.sort()
    for key in keylist:
      outfile.write(re.sub('_',' ',"\n\\par {\\bf %s}\\par\n\n"%key))
      outfile.write(self.xml_data.get(key,' -- nothing found -- '))
      outfile.write("\n\\par\n\n")
    outfile.write("\\end{minipage}")
    solvers=re.sub('.log','_solvers.pdf',self.filename)
    norms=re.sub('.log','_norms.pdf',self.filename)
    outfile.write("\\begin{minipage}{.5\\textwidth}")
    if (os.path.isfile(solvers)):
        outfile.write("\\includegraphics[width=\\textwidth]{"+solvers+"}\n\par\n")
    if (os.path.isfile(norms)):
        outfile.write("\\includegraphics[width=\\textwidth]{"+norms+"}")
    outfile.write("\\end{minipage}")
    for image in self.images:
      if os.path.isfile(image):
        sv=os.path.split(image)[1]
        harmless=re.sub('_','\\_',sv)
        outfile.write("\n added figure \\ref{fig:%s}: %s\n\\par"%(sv,harmless))
        outfile.write("\n\\begin{figure}\n\\label{fig:%s}\n\n\\caption{%s}\\includegraphics[width=\\textwidth]{%s}\n\\end{figure}\n"%(sv,harmless,image))


  def parse_xml(self):
    filename=re.sub('log','xml',self.filename)
    xml_data={}    
    if(not os.path.isfile(filename)):
         return xml_data
    print filename
    dom=md.parse(filename)
    dc0=dom.childNodes[0]
    for node in dc0.childNodes:
      if (node.nodeName != '#text'):
        xml_data[node.nodeName]=node.childNodes[0].data
    self.xml_data=xml_data
#    print self.xml_data
    return xml_data
 
  def find_images(self):
    imageroot=re.sub('.log','',self.filename)
    extensions=['.jpg']
    images=[]
    for ext in extensions:
      images=images+glob.glob(imageroot+'_image*'+ext)
    images.sort()
    self.images=images
    return images

  def toxml(self):
    doc=md.Document()
    lr=doc.createElement('logreport')
    doc.appendChild(lr)
    data={}
    data['solverlist']=self.solverlist
    data['starttime']=self.starttime
    data['endtime']=self.endtime
    data['duration']=self.duration
    data['filename']=self.filename
##        self.iterations=0
    data['iterations_planned']=self.iterations_planned
    data['modeltime']=self.modeltime
    data['modeltime_offset']=self.modeltime_offset
    data['solverlist']='\n'.join(solverlist)
    data['solvercount']='\n'.join(solvercount)

    solvers=doc.createElement('solvers')
    lr.append(solvers)
      
##    lr=doc.createElement('logreport')
##    doc.appendChild(lr)
##    filename=doc.createElement('filename')
##    lr.append(filename)
##    tn=doc.createTextNode(self.filename)
##    filename.appendChild(tn)

    
def print_closing(outfile):
    outfile.write("\\end{document}\n")
    
  
def print_head(outfile):
    outfile.write('\\documentclass[10pt,a4paper]{article}\n'
                  +'\\usepackage{graphicx}\n'
                  +'\\usepackage[margin=2cm]{geometry}\n'
                  +'\\usepackage{listings}\n'
                  +'\\usepackage{hyperref}\n'
                  +'\\begin{document}\n'
                  +'\\lstset{language=Fortran,basicstyle=\\ttfamily}\n')

def difffiles(file1,file2):
  diff=sp.Popen(['/usr/bin/diff',file1,file2],stdout=sp.PIPE,stderr=sp.STDOUT)
  differences=diff.communicate()[0]
  return differences
    

def print_differences(file1,file2,outfile):
  diff=difffiles(file1,file2)
  outfile.write('\n\\par\n')
  outfile.write("\\begin{tabular}{lr}\n")
  outfile.write('differences between &{\\tt %s (<)}\\\\\n and & {\\tt  %s (>)}\n'%(re.sub('_','\\_',file1),re.sub('_','\\_',file2)))
  outfile.write("\\end{tabular}\n")
  outfile.write('\\begin{lstlisting}\n')
  outfile.write(diff)
  outfile.write('\\end{lstlisting}')
    
##def process_dir(directory,force_replot=False):
##    if (directory[-1]=='/'):
##        files=glob.glob(directory+"*.log")
##    else:
##        files=glob.glob(directory+"/*.log")
##    if (len(files)==0):
##      print "found no files in %s\n EXITING \n"%(directory)
##      return
##    files.sort()
##    siffiles=[re.sub('log','sif',fi) for fi in files]
##    outfilepath=directory+"/report.tex"
##    outfile=open(outfilepath,'w')
##    print_head(outfile)
##    for (num,x) in enumerate(files):
##      a=report(x)
##      a.plot_iterations(force_replot)
##      a.print_body(outfile)
##      if (num):
##        print_differences(siffiles[num-1],siffiles[num],outfile)
##      outfile.write('\n\\pagebreak\n')
##        
##    print_closing(outfile)
##    outfile.close()
##    latex_file(outfilepath)


def latex_file(outfilepath,debug=False):
  tempdir=tempfile.mkdtemp('_argh-tex')
  (outfiledir,outfilename)=os.path.split(outfilepath)
  sp.call(['/usr/bin/pdflatex', '-output-directory', tempdir, outfilepath])
  sp.call(['/usr/bin/pdflatex', '-output-directory', tempdir, outfilepath])
  pdfname=re.sub('.tex','.pdf',outfilename)
  shutil.move(tempdir+'/'+pdfname,outfiledir+'/'+pdfname)
  if(not debug):
    shutil.rmtree(tempdir)
  else:
    print "leaving directory %s in place for debugging"%(tempdir)
  
    

def newer(file1,file2):
  if (not os.path.isfile(file1)):
    return false
  statinfo = os.stat(file1)
  f1time=statinfo.st_mtime
  statinfo = os.stat(file2)
  f2time=statinfo.st_mtime
  return f1time>f2time

def gettext(dom,var):
  elem=dom.getElementsByTagName(var)
  if (len(elem)==1):
    text=elem[0].childNodes[0].data
  else:
    text=""
  return text


def process_dir(directory,force_replot=False):
    if (directory[-1]=='/'):
        files=glob.glob(directory+"*.log")
    else:
        files=glob.glob(directory+"/*.log")
    if (len(files)==0):
      print "found no files in %s\n EXITING \n"%(directory)
      return
    if (directory[-1]=='/'):
        files=glob.glob(directory+"*.log")
    else:
        files=glob.glob(directory+"/*.log")
    process_list(files,directory,force_replot)


def process_list(files,directory='/pf/m/m300019/PhD/Log_processing/',force_replot=False):
    files.sort()
    siffiles=[re.sub('log','sif',fi) for fi in files]
    outfilepath=directory+"/report.tex"
    outfile=open(outfilepath,'w')
    print_head(outfile)
    for (num,x) in enumerate(files):
      a=report(x)
      a.plot_iterations(force_replot)
      a.print_body(outfile)
      if (num):
        print_differences(siffiles[num-1],siffiles[num],outfile)
      outfile.write('\n\\pagebreak\n')
        
    print_closing(outfile)
    outfile.close()
    latex_file(outfilepath)

def process_listfile(listfile,directory='/pf/m/m300019/PhD/Log_processing/',force_replot=False):
  files=open(listfile).readlines()
  files=[ifile[:-1] for ifile in files]
  fd={}
  for ifile in files:
    if (os.path.isfile(ifile)):
      fd[os.path.split(ifile)[1]]=ifile
  keylist=fd.keys()
  keylist.sort()
  files=[fd[key] for key in keylist]
  process_list(files)

##def array2string(a):
##  return '\n'.join(['\t'.join(x) for x in [[str (x) for x in y] for y in a]])

##def string2array(text):
##  return array([[float(x) for x in line.split()] for line in text.split('\n')])


def array2string(a):
  return '\n'.join([str (x) for x in a])

def string2float_array(text):
  return array([float(x) for x in text.split('\n')])

def string2int_array(text):
  return array([int(x) for x in text.split('\n')],dtype=int32)



class solver(object):
  """Represents one solver in all the calls made to it."""
  def __init__(self,name,count):
    self.name=name
    self.count=count
    self.call_numbers=zeros(count,dtype=int32)
    self.iterations=zeros(count)
    self.precisions=zeros(count)
    self.rel_changes=zeros(count)
    self.norms=zeros(count)

  def to_xml(self,doc,hook):
      solv=doc.createElement('solver')
      hook.appendChild(solv)
      solv.setAttribute('name',self.name)
      solv.setAttribute('count',self.count)
      properties={'call_numbers':self.call_numbers,
                  'iterations':self.iterations,
                  'precisions':self.precisions,
                  'rel_changes':self.rel_changes,
                  'norms':self.norms}
      for prop in propertiese:
        prop=doc.createElement(prop)
        solv.appendChild(prop)
        tn=doc.createTextNode(array2str(properties[prop]))
        prop.appendChild(tn)


class model_run(object):
  def __init__(self):
    #simple properties go in a dictionary for easy xml im/export
    self.properties={}
    #times are wallclock times
    self.properties["start_time"] = 0.
    self.properties["end_time"] = 0.
    self.properties["duration"] = 0.
    #model times
    self.properties["model_time_start"] = 0
    self.properties["model_time_end"] = 0
    self.properties["timestep"] = 0
    self.properties["timesteps_planned"] = 0
    #always nice to no
    self.properties["last_finished_solver"] = "--none--"
    self.properties["last_started_solver"] = "--none--"
    self.properties["log_file"]=""
    #A list of all solvers used in the run.
    self.solverlist = []

  def read_log(self,filename):
    self.properties["log_file"]=filename
    #Check if we are reading a correct logfile.
    #(latex also generates .log for example)
    infile=open(filename)
    line=infile.readline()
    starttime_string=re.findall('(2009/.*)\n',line)
    if (not len(starttime_string)):
      #looks like this is not the case.
      print "ILLEGAL FILE %s"%self.filename
      return -1
    #if we get here, it's a logfile
    self.get_times()
    self.get_iterations()
    self.get_timesteps()
    
  
  def get_times(self):
    statinfo = os.stat(self.filename)
    infile=open(self.filename)
    line=infile.readline()
    print self.filename
    print line
    starttime_string=re.findall('(2009/.*)\n',line)[0]
    self.starttime=time.mktime(time.strptime(starttime_string,'%Y/%m/%d %H:%M:%S'))
    self.endtime=statinfo.st_mtime
    self.duration=statinfo.st_mtime-self.starttime
    return (self.starttime, self.endtime,self.duration)


  def read_xml(filename):
    return 0


##class solver_call(object):
##  """One solver call."""
##  def __init__(self, solver_name, call_number, iterations, precicsion, rel_change, norm):
##    self.solver_name=solver_name
##    self.call_number=call_number
##    self.iterations=iterations
##    self.precision=precision
##    self.rel_change=rel_change
##    self.norm=norm
