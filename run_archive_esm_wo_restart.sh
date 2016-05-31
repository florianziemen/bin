#!/bin/bash 
#
###########################################################################
# File: run_archive_esm.sh
#
# This script is used to call the archive script for mpiesm coupled model
# data archive_esm.sh with a setup spezified by the user. 
#
# Interactive usage:
# ------------------
# ./run_archive_esm.sh
#
# Batch job usage on mistral:
# ---------------------------
# sbatch run_archive_esm.sh
#
###########################################################################
#
###########################################################################
# Batch job setup for mistral (SLURM)
# Please set required resources
#
#SBATCH --job-name=archive_esm
#SBATCH --partition=shared
#SBATCH --ntasks=1
#SBATCH --time=10:00:00
#SBATCH --output=archive_esm.o%j
#SBATCH --error=archive_esm.o%j
#SBATCH --mail-type=FAIL
#SBATCH --account=bm0948

##SBATCH --cpus-per-task=1
##SBATCH --mem-per-cpu=1280
##SBATCH --partition=compute
##SBATCH --exclusive
##SBATCH --nodes=1
##SBATCH --tasks-per-node=1

ulimit -s unlimited

module unload cdo
module load cdo/1.7.1-magicsxx-gcc48
###########################################################################

###########################################################################
# Setup for the archiving script
# Please set mandatory arguments and required options, if they differ from
# default 
#
# ---- Mandatory overall setup  ------------------------------------------#
# Please edit
#
# Path to archiving script
script=/home/zmaw/${USER}/Apps/ghb/archive_esm.sh
#
# Start up and last year to process (archiving, climatologies, ...)
firstyear=FIRST_YEAR
lastyear=LAST_YEAR
#
# ID of the experiment to process
# used for default paths to the temporary, experiment's, climatologies,
# local and remote archive data, and for the file patterns to select the
# data files for processing
experiment_id=EXPERIMENT_ID
echo $experiment_id $firstyear $lastyear
#-------------------------------------------------------------------------#
#
# ---- Mandatory setup for default directories ---------------------------#
# Project ID and MPIESM ID of the experiment to process 
# used for default paths to the experiment's, climatologies, local and
# remote archive data (see bullet point root directories). 
# Please edit, if directories differ from default
project_id="bm0948"
mpiesm_id="mpiesm-flo-dev"
#-------------------------------------------------------------------------#

# ---- Environment -------------------------------------------------------#
# Please edit, if environment differ from default
#
# Path to temporary data and processing
# default: "/scratch/m/${USER}/tmp/${experiment_id}_${firstyear}_${lastyear}_$$"
#tmp_path=""
#
# Path to experiment's root directory
# default: "/work/${project_id}/${USER}/${mpiesm_id}/experiments/${experiment_id}"}
experiment_path="/work/${project_id}/${USER}/${mpiesm_id}/experiments/${experiment_id}"
#
# Path to root directory of local tarballs
# default: "/work/${project_id}/${USER}/${mpiesm_id}/experiments/tars/${experiment_id}"}
local_archive_path="/scratch/m/${USER}/tmp/${mpiesm_id}/experiments/tars/${experiment_id}"
#
# Path to root directory of tarballs on archive
# default: "${project_id}/${USER}/${mpiesm_id}/${experiment_id}"
#remote_archive_path="bm0948/${USER}/${mpiesm_id}/${experiment_id}"
#
# Path to root directory to store climatologies
# default: "/work/${project_id}/${USER}/${mpiesm_id}/experiments/means/${experiment_id}"}
climatologies_path="/scratch/m/${USER}/tmp/${mpiesm_id}/experiments/means/${experiment_id}"
#-------------------------------------------------------------------------#

# ---- Processing setup --------------------------------------------------#
# Please edit, if setup differ from default
#
# Enable verbose log
# default: 0 (disabled) 2 is verbose
verbose=0
#
# Enable profiling 
# default: false
lprofiling=false
#
# Increment of time period
# default: 1
incrementyear=1
#
# Enable climatologies
# default: true
lclimatologies=true
# Enable archiving raw data and climatologies
# default: true
larchive_data=true
# Enable archiving restart data
# default: true
larchive_restart=false
# Enable archiving logging data
# default: true
larchive_log=true
#
# Enable processing of atmosphere/ECHAM data 
# default: true
latmosphere=true
# Enable processing of land/JSBACH data
# default: true
lland=true
# Enable processing of ocean/MPIOM data
# default: true
locean=true
# Enabel processing ocean's biogeochemical/HAMOCC data
# default: true
logbc=true
# Enabel processing coupler data
# default: true
lcoupler=true
# Enabel processing logging data
# default: true
llogg=true
#
# Enable tidying up: mv/cp data files from temporary directory 
# to where they come from
# needs processing's configuration
# default: false
ltidying=false
#-------------------------------------------------------------------------#

# ---- Experiment's raw data types for processing climatologies ----------#
# Please don't edit
#
# Data given by
# daily means
declare -r dm="dm"
# monthly means
declare -r mm="mm"
# yearly means
declare -r ym="ym"
# no processing desired
declare -r no="none"
#-------------------------------------------------------------------------#

# ---- Data indicators of file patterns to select raw and restart data ---#
#      and data types of raw data for processing climatologies            #
# Please edit, if different from default
#
# Atmosphere
# default:
#atmosphere_data_pat="accw_  ATM_mm_ BOT_mm_ co2_ co2_mm_ echam_"
#atmosphere_restart_data_pat="accw_ co2_ echam_"
#atmosphere_data_type="${mm} ${mm} ${mm} ${no} ${mm} ${no}"
#
# Land
# default:
#land_data_pat="jsbach_ jsbach_mm_ land_ land_mm_ surf_ surf_mm_ \
#	  	veg_ veg_mm_ yasso_ yasso_mm_"
#land_restart_data_pat="hd_ jsbach_ surf_ veg_ yasso_"
#land_dat_type="${no} ${mm} ${no} ${mm} ${no} ${mm} \
#	        ${no} ${mm} ${no} ${mm}"
#
# Ocean
# default:
#ocean_data_pat="data_2d_mm_ data_3d_mm_ data_moc_mm_ monitoring_ym_ \
#           	timeser_mm_"
#ocean_restart_data_pat="mpiom_"
#ocean_dat_type="${mm} ${mm} ${mm} ${ym} ${mm}"
#
# Ocean's biogeochemistry
# default:
#obgc_data_pat="co2_ data_2d_mm_ data_3d_ym_ data_eu_mm_ data_sedi_ym_ \
#          	monitoring_ym_"
#obgc_restart_data_pat="hamocc_"
#obgs_dat_type="${dm} ${mm} ${ym} ${mm} ${ym} ${ym}"
#-------------------------------------------------------------------------#

# ---- Data indicators of file patterns to select coupling restart data --#
# Please edit, if different from default
#
# default:
#coupler_restart_data_pat="flxatmos_ sstocean_"
#-------------------------------------------------------------------------#

# ---- Data indicators of file patterns to select logging data -----------#
# Please edit, if different from default
#
# default:
#log_data_pat="run_ store_"
#if latmosphere log_data_pat + " echam6_atmout_"
#if locean      log_data_pat + " mpiom_oceout_"
#if lobgc       log_data_pat + " hamocc_bgcout_"
#-------------------------------------------------------------------------#

# ---- Run processing ----------------------------------------------------#
# Please don't edit
#
${script}							\
--project_id ${project_id} 					\
--mpiesm_id ${mpiesm_id} 					\
--experiment_id ${experiment_id} 				\
--firstyear ${firstyear} 					\
--lastyear ${lastyear}  					\
--incrementyear ${incrementyear}				\
--lclimatologies ${lclimatologies} 				\
--larchive_data ${larchive_data}				\
--larchive_restart ${larchive_restart}				\
--larchive_log ${larchive_log}					\
--latmosphere ${latmosphere} 					\
--lland ${lland}  	  					\
--locean ${locean} 						\
--lobgc ${logbc}		  				\
--lcoupler ${lcoupler} 						\
--llog ${llogg}		  					\
--ltidying ${ltidying}		  				\
--atmosphere_data_pat ${atmosphere_data_pat} 			\
--atmosphere_data_type ${atmosphere_data_type}			\
--atmosphere_restart_data_pat ${atmosphere_restart_data_pat}	\
--land_data_pat ${land_data_pat}   				\
--land_data_type ${land_dat_type}				\
--land_restart_data_pat ${land_restart_data_pat}		\
--ocean_data_pat ${ocean_data_pat} 				\
--ocean_data_type ${ocean_dat_type}				\
--ocean_restart_data_pat ${ocean_restart_data_pat}		\
--obgc_data_pat ${obgc_data_pat}   				\
--obgc_data_type ${obgs_dat_type}				\
--obgc_restart_data_pat ${obgc_restart_data_pat}		\
--coupler_restart_data_pat ${coupler_restart_data_pat} 		\
--log_data_pat ${log_data_pat}					\
--tmp_path ${tmp_path} 						\
--experiment_path ${experiment_path} 				\
--local_archive_path ${local_archive_path} 			\
--remote_archive_path ${remote_archive_path}			\
--climatologies_path ${climatologies_path}			\
--lprofiling ${lprofiling}					\
--verbose ${verbose} 
#-------------------------------------------------------------------------#

