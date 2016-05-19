#!/bin/bash 
#
# archive_esm.sh
##########################################################################
# Setup for mistral (SLURM)
#
#SBATCH --job-name=archive_esm
#SBATCH --partition=shared
#SBATCH --ntasks=1             
#SBATCH --mem-per-cpu=1280     
##SBATCH --partition=compute
##SBATCH --exclusive
##SBATCH --nodes=1
##SBATCH --tasks-per-node=1
##SBATCH --cpus-per-task=1
##SBATCH --time=03:00:00
#SBATCH --output=archive_esm.o%j
#SBATCH --error=archive_esm.o%j
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=petra.nerge@mpimet.mpg.de
#SBATCH --account=bm0948
ulimit -s unlimited
###########################################################################
#prj_id="mh0110"
#esm_id="mpiesm-flo-dev"
#exp_id="uwe0010"
#firstyear=1900
#lastyear=1999
#firstyear=2800
#lastyear=2899

#exp_id="uwe0011"
#firstyear=2700
#lastyear=2799
#firstyear=2800
#lastyear=2899

#exp_id="uwe0012"
#firstyear=2700
#lastyear=2799
#firstyear=3300
#lastyear=3399

#esm_id="mpiesm_nohamocc"
#exp_id="uwe0013"
#firstyear=2700
#lastyear=2999

#exp_id="uwe0014"
#firstyear=2700
#lastyear=2999

# ---- Mandatory user spezified overall environment ----------------------#
# Experiment's project ID, MPIESM ID, and experiment ID 
# are used for default directories, see user spezified root  of
# experiment's data, local and remote tarballs, local climatologies, and
# temporary data
# if no defaults used, please set dummy data 
prj_id="mh0110"
esm_id="mpiesm_nohamocc"
exp_id="uwe0014"

# Start up and last year for processing (archiving, climatologies, ...)
firstyear=2900
lastyear=2999
#-------------------------------------------------------------------------#

# ---- User spezified root directories -----------------------------------#
# Directory of temporary data and processing
# default: "/scratch/m/${USER}/tmp/${exp_id}_${firstyear}_${lastyear}_$$"
tmp_dir="/scratch/m/${USER}/tmp/${exp_id}_${firstyear}_${lastyear}_$$"

# Root directory of experiment
# default: "/work/${prj_id}/${USER}/${esm_id}/experiments/${exp_id}"}
exp_dir="/work/${prj_id}/m211003/${esm_id}/experiments/${exp_id}"

# Root directory of local tarballs
# default: "/work/${prj_id}/${USER}/${esm_id}/experiments/tars/${exp_id}"}
tar_dir="/scratch/m/${USER}/tmp/${esm_id}/experiments/tars/${exp_id}"

# Root directory of tarballs on archive
# default: "${prj_id}/${USER}/${esm_id}/${exp_id}"
#arc_dir="bm0948/m211003/${esm_id}/${exp_id}"
arc_dir="bm0948/${USER}/${esm_id}/${exp_id}"

# Root directory to store climatologies
# default: "/work/${prj_id}/${USER}/${esm_id}/experiments/means/${exp_id}"}
cli_dir="/scratch/m/${USER}/tmp/${esm_id}/experiments/means/${exp_id}"
#-------------------------------------------------------------------------#

# ---- User spezified processing environment -----------------------------#
# Enable verbose log
# default: 0 (disabled)
#verbose=2

# Increment of time period
#incrementyear=10

# Enable climatologies
# default: true
lclimat=false
# Enable archiving raw data and climatologies
# default: true
larchiv_data=false
# Enable archiving restart data
# default: true
#larchiv_restart=false
# Enable archiving logging data
# default: true
larchiv_log=false

# Enable processing of atmosphere/ECHAM data 
# default: true
#latmos=false
# Enable processing of land/JSBACH data
# default: true
#lland=false
# Enable processing of ocean/MPIOM data
# default: true
#locean=false
# Enabel processing ocean's biogeochemical/HAMOCC data
# default: true
logbc=false
# Enabel processing coupler data
# default: true
#lcoup=false
# Enabel processing logging data
# default: true
llogg=false
#-------------------------------------------------------------------------#

# ---- Set data types for climatology processing -------------------------#
# Processing daily means
dm="dm"
# monthly means
mm="mm"
# yearly means
ym="ym"
# no processing desired
no="none"
#-------------------------------------------------------------------------#

# ---- User spezified data indicators of file patterns -------------------#
#      for atmosphere raw and restart data                                #
# default:
#atmos_dat="accw_  ATM_mm_ BOT_mm_ co2_ co2_mm_ echam_"
#atmos_dat_type="${mm} ${mm} ${mm} ${no} ${mm} ${no}"
#atmos_rst="accw_ co2_ echam_"
#-------------------------------------------------------------------------#

# ---- User spezified data indicators of file patterns -------------------#
#      for land raw and restart data                                      #
# default
#land_dat="jsbach_ jsbach_mm_ land_ land_mm_ surf_ surf_mm_ \
#	  veg_ veg_mm_ yasso_ yasso_mm_"
#land_dat_type="${no} ${mm} ${no} ${mm} ${no} ${mm} ${no} ${mm} ${no} ${mm}"
#land_rst="hd_ jsbach_ surf_ veg_ yasso_"
#-------------------------------------------------------------------------#

# ---- User spezified data indicators of file patterns -------------------#
#      for ocean raw and restart data                                     #
# default
#ocean_dat="data_2d_mm_ data_3d_mm_ data_moc_mm_ monitoring_ym_ \
#           timeser_mm_"
#ocean_dat_type="${mm} ${mm} ${mm} ${ym} ${mm}"
#ocean_rst="mpiom_"
#-------------------------------------------------------------------------#

# ---- User spezified data indicators of file patterns -------------------#
#      for ocean raw and restart data                                     #
# default
#obgs_dat="co2_ data_2d_mm_ data_3d_ym_ data_eu_mm_ data_sedi_ym_ \
#          monitoring_ym_"
#obgs_dat_type="${dm} ${mm} ${ym} ${mm} ${ym} ${ym}"
#obgc_rst="hamocc_"
#-------------------------------------------------------------------------#

# ---- User spezified data indicators of file patterns -------------------#
#      for coupler restart data                                           #
# default
#coupl_rst="flxatmos_ sstocean_"
#-------------------------------------------------------------------------#

# ---- User spezified data indicators of file patterns -------------------#
#      for logging data                                                   #
# default
#log_dat="store_"
#-------------------------------------------------------------------------#

# ---- Run processing ----------------------------------------------------#
/home/zmaw/m300465/bin/archive_esm.sh		\
--project_id ${prj_id} 				\
--mpiesm_id ${esm_id} 				\
--experiment_id ${exp_id} 			\
--firstyear ${firstyear} 			\
--lastyear ${lastyear}  			\
--incrementyear ${incrementyear}		\
--lclimatologies ${lclimat} 			\
--larchive_data ${larchiv_data}			\
--larchive_restart ${larchiv_restart}		\
--larchive_log ${larchiv_log}			\
--latmosphere ${latmos} 			\
--lland ${lland}  	  			\
--locean ${locean} 				\
--lobgc ${logbc}		  		\
--lcoupler ${lcoup} 				\
--llog ${llogg}		  			\
--atmosphere_data_pat ${atmos_dat} 		\
--atmosphere_data_type ${atmos_dat_type}	\
--atmosphere_restart_data_pat ${atmos_rst}	\
--land_data_pat ${land_dat}   			\
--land_data_type ${land_dat_type}		\
--land_restart_data_pat ${land_rst}		\
--ocean_data_pat ${ocean_dat} 			\
--ocean_data_type ${ocean_dat_type}		\
--ocean_restart_data_pat ${ocean_rst}		\
--obgc_data_pat ${obgs_dat}   			\
--obgc_data_type ${obgs_dat_type}		\
--obgc_restart_data_pat ${obgc_rst}		\
--coupler_restart_data_pat ${coupl_rst} 	\
--log_data_pat ${log_dat}			\
--tmp_path ${tmp_dir} 				\
--experiment_path ${exp_dir} 			\
--local_archive_path ${tar_dir} 		\
--remote_archive_path ${arc_dir}		\
--local_climatologies_path ${cli_dir}		\
--verbose ${verbose} 
#-------------------------------------------------------------------------#


