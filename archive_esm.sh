#!/bin/bash 
#
##########################################################################
# File: archive_esm.sh
#
# This script is used to archive raw, restart, and logging data of mpiesm
# coupled models. Additionally climatologies are performed and archived.
#
# Usage:
# ------
# archive_esm.sh [OPTIONS]...
#
# Options are
#	--help, -h display built-in help text and exit.
#
#	for more use --help
#
###########################################################################

# ---- Error handling ----------------------------------------------------#
set -e

# Trap error and killer signals
# so that we can exit with a message incl. line no
trap 'err_exit ${LINENO}'                      ERR
trap 'err_exit "" "Received signal SIGHUP !"'  SIGHUP
trap 'err_exit "" "Received signal SIGINT !"'  SIGINT
trap 'err_exit "" "Received signal SIGTERM !"' SIGTERM
trap 'err_exit "" "Received signal SIGQUIT !"' SIGQUIT
#-------------------------------------------------------------------------#

# ---- Format specifier --------------------------------------------------#
# bold
b="\e[1m"
# underlined
u="\e[4m"
# normal
n="\e[0m"
#-------------------------------------------------------------------------#

# ---- Functions ---------------------------------------------------------#
# Error and exit for non existing raw data directories
function err_dat_dir() {
	# $1 line no
	# $2 component (Atmosphere/Land/Ocean/OBGC)
	# $3 data directory

	local code=1
	if [ ! -d $3 ]; then
		local msg="$2 dir is not there!"
       	 	err_exit $1 "${msg}" ${code} 
	fi
}
# Error and exit for non existing raw data file
function err_dat_file() {
	# $1 line no
	# $2 raw data file

	local msg="Raw data file $2 is not there or permissions denied!"
	local code=1
	err_exit $1 "${msg}" ${code}
}
# Exit with message
function err_exit {
	# $1 line no
	# $2 error message
	# $3 error code

	local parent_lineno="$1"
	local message="$2"
	local code="${3:-1}"
	local err_msg="ERROR $0 on or near line ${parent_lineno}"
	echo
	if [[ -n "$message" ]] ; then
	  echo "${err_msg}: ${message}" 
	else
	  echo "${err_msg}"
	fi
	on_exit ${code}
	exit ${code}
}
# Error and exit for empty mandatory options
function err_option() {
	# $1 line no
	# $2 name of option

	local msg="Empty mandatory $2 option!"
	local code=1
        err_exit $1 "${msg}" ${code}
}
# Error and exit for read-only raw data directories
function err_ro_dat_dir() {
	# $1 line no
	# $2 component (Atmosphere/Land/Ocean/OBGC)
	# $3 data directory

	if [ ! -w $3 ]; then 
		local msg="$2 dir is write-protected for user!" 
	local code=1
		err_exit $1 "${msg}" ${code}
	fi
}
# Error and exit for processing's first year > last year
function err_years() {
	# $1 line no
	# $2 first year
	# $3 last year

	local msg="Processing's first year $2 > last year $3!"
	local code=1
        err_exit $1 "${msg}" ${code}
}
# get multi-year monthly means climatology 
function get_lm_climatology() {
	# $1 name of data file with e.g. monthly means
	# $2 time period of data file
	# $3 type id of input data, e.g. monthly means
	# $4 type id of multi-year monthly means
	# $5 variable to store file name of multi-year monthly means
	# $6 path to code file for data file
	# $7 tidying up is desired on failure

	# cdo command to get climatology output file in netCDF format
        local cdo 
	set_cdo_cmd $1 $6 cdo $7
	# climatology file name
	local outfile=$(set_climatology_fname $1 $2 $3 $4)
	# Retrieve data file isn't in netCDF format
	if [[ $(get_str_short_suffix "$1" ".") != "nc" ]]; then
		# climatology file is in netCDF format
		outfile=$(get_str_short_prefix ${outfile} ".").nc
	fi
	# get multi-year monthly means
	${cdo} -lmean $1 ${outfile}
	# return climatology file name
	eval ${5}="'${outfile}'"
}
# get monthly means climatology 
function get_mm_climatology() {
	# $1 name of data file with e.g. daily means
	# $2 time period of data file
	# $3 type id of input data, e.g. daily means
	# $4 type id of monthly means
	# $5 variable to store file name of monthly means
	# $6 path to code file for data file
	# $7 tidying up is desired on failure

	# cdo command to get climatology output file in netCDF format
        local cdo 
	set_cdo_cmd $1 $6 cdo $7
	# climatology file name
	local outfile=$(set_climatology_fname $1 $2 $3 $4)
	# Retrieve data file isn't in netCDF format
	if [[ $(get_str_short_suffix "$1" ".") != "nc" ]]; then
		# climatology file is in netCDF format
		outfile=$(get_str_short_prefix ${outfile} ".").nc
	fi
	# get monthly means
	${cdo} -monmean $1 ${outfile}
	# return climatology file name
	eval ${5}="'${outfile}'"
}
# Get option argument and store it in function argument
function get_option_arg() {
	# $1   variable to store argument
	# $2:@ option followed by it's arguments

	# Variable to store arguments
	local _var=$1
	# Arguments
	local args=""
	# Retrieve option: non empty argument and argument starts with "-"
	if [[ -n ${2} && ( ${2:0:1} == "-" ) ]]; then
		shift
		# Retrieve args: non empty arguments and arguments doesn't start with "-"
		while [[ -n ${2} && ( ${2:0:1} != "-" ) ]]; do
			args="${args} ${2}"
			shift
		done
		# Remove 1st character of arguments string, is a blank space
		args=${args:1}
		eval ${_var}="'${args}'"
	fi
}
# get multi-year seasonal means climatology 
function get_sm_climatology() {
	# $1 name of data file with e.g. multi-year monthly means
	# $2 time period of data file
	# $3 type id of input data, e.g multi_year monthly means
	# $4 type id of multi-year seasonal means
	# $5 variable to store file name of multi-year seasonal means
	# $6 path to code file for data file
	# $7 tidying up is desired on failure

	# cdo command to get climatology output file in netCDF format
        local cdo 
	set_cdo_cmd $1 $6 cdo $7
	# climatology file name
	local outfile=$(set_climatology_fname $1 $2 $3 $4)
	# Retrieve data file isn't in netCDF format
	if [[ $(get_str_short_suffix "$1" ".") != "nc" ]]; then
		# climatology file is in netCDF format
		outfile=$(get_str_short_prefix ${outfile} ".").nc
	fi
	# get multi-year seasonal means
	### compare to yseasmean?
	${cdo}  -mergetime                  \
		-timmean -selmon,12,1,2  $1 \
		-timmean -selmon,3,4,5   $1 \
		-timmean -selmon,6,7,8   $1 \
		-timmean -selmon,9,10,11 $1 \
    	${outfile}
	# return climatology file name
	eval ${5}="'${outfile}'"
}
# get longest prefix of a string 
function get_str_long_prefix() {
	# $1 string, e.g. file name
	# $2 delimiter

	# get longest prefix of string up to delimiter
	local prefix=${1%$2*}
	# return prefix
	echo ${prefix}
}
# get longest suffix of a string 
function get_str_long_suffix() {
	# $1 string, e.g. file name
	# $2 delimiter

	# get longest suffix of string from delimiter backwards
	local suffix=${1#*${2}}
	# return prefix
	echo ${suffix}
}
# get shortest prefix of a string 
function get_str_short_prefix() {
	# $1 string, e.g. file name
	# $2 delimiter

	# get shortest prefix of string up to delimiter
	local prefix=${1%%$2*}
	# return prefix
	echo ${prefix}
}
# get shortest suffix of a string 
function get_str_short_suffix() {
	# $1 string, e.g. file name
	# $2 delimiter

	# get shortes suffix of string from delimiter backwards 
	local suffix=${1##*${2}}
	# return prefix
	echo ${suffix}
}
# get time means climatology 
function get_tm_climatology() {
	# $1 name of data file to get climatology from
	# $2 time period of data file
	# $3 type id of input data, e.g multi_year monthly means
	# $4 type id of time means
	# $5 variable to store file name of time means
	# $6 path to code file for data file
	# $7 tidying up is desired on failure

	# cdo command to get climatology output file in netCDF format
        local cdo 
	set_cdo_cmd $1 $6 cdo $7
	# climatology file name
	local outfile=$(set_climatology_fname $1 $2 $3 $4)
	# Retrieve data file isn't in netCDF format
	if [[ $(get_str_short_suffix "$1" ".") != "nc" ]]; then
		# climatology file is in netCDF format
		outfile=$(get_str_short_prefix ${outfile} ".").nc
	fi
	# get multi-year seasonal means
	${cdo} -timmean $1 ${outfile} 
	# return climatology file name
	eval ${5}="'${outfile}'"
}
# Some info on exit
function on_exit() {
	local exit_code=${1:-$?}
	echo 
	echo Exiting $0 with status $exit_code
	exit $exit_code
}
# Moving/copying data message within processing
function proc_mv_msg() {
	# $1    command
	# $2 $3 Source and destination directory

	if [ "$1" == "mv" ]; then
		printf "\tmove "
	elif [ "$1" == "cp" ]; then
		printf "\tcopy " 
	fi
	printf "data from $2 to $3 \n\n"
}
# archiving data message within processing
function proc_tar_msg() {
	# $1 command
	# $2 tar file name
	# $3 path to tar file

	if [ "$1" == "tar -cvf" ]; then
		printf "\tcreating "
	elif [ "$1" == "tar -rvf" ]; then
		printf "\tappending files to "
	fi
        printf "tar file $2 on $3 containing: \n" 
}
# check size of transferred files 
function put_check_size() {
	# $1 local file size
	# $2 remote file name incl. path
	# $3 log file of file transfer

	# remote file size
	tarball=$(get_str_short_suffix "${2}" "/")
	local rsz=$(grep "^-.*${tarball}$" $3 | awk '{print $5}')
	# error code
	local code=1
	# if empty abort
	if [ -z ${rsz} ] ; then
		local msg="Remote tarball $2 not there!"
       	 	err_exit $LINENO "${msg}" ${code}
	fi
	# if not equal to local abort
	if [ ${1} -ne ${rsz} ] ; then 
		local msg="Tarballs local size = ${1} /= remote size = ${rsz}!"
       	 	err_exit $LINENO "${msg}" ${code}
	fi
}
# select code file of raw data file 
function select_code_file() {
	# $1 data file name (wo path) 
	# $2 path to code file for data file
	# $3 variable to store code file name

	# delimiter to get substrings of prefix
	local delim="_"
	# get experiment id of file name
	local iden=$(get_str_short_prefix "$1" "${delim}")
	# get model component of file name
	#local comp=${1#*_}
	local comp=$(get_str_long_suffix "$1" "${delim}")
	#comp=${comp%%_*}
	comp=$(get_str_short_prefix "${comp}" "${delim}")
	# select code file of data file
	local file
	case $1 in
		*${comp}*_accw_*)
			file="${iden}_${comp}_accw.codes"
			;;
		*${comp}*_ATM_*)
			file="${iden}_${comp}_echam.codes"
			;;
		*${comp}*_BOT_*)
			file="${iden}_${comp}_echam.codes"
			;;
		*${comp}*_co2_*)
			file="${iden}_${comp}_co2.codes"
			;;
		*${comp}*_jsbach_*)
			file="${iden}_${comp}_jsbach.codes"
			;;
		*${comp}*_land_*)
			file="${iden}_${comp}_land.codes"
			;;
		*${comp}*_surf_*)
			file="${iden}_${comp}_surf.codes"
			;;
		*${comp}*_veg_*)
			file="${iden}_${comp}_veg.codes"
			;;
		*${comp}*_yasso_*)
			file="${iden}_${comp}_yasso.codes"
			;;
		*)
			local msg="No code file for data file $1 defined!"
	       	 	err_exit $LINENO "${msg}" 1 
	esac
	# return code file name incl. path
	file="$2/${file}"
	if [[ -f ${file} ]]; then
		eval $3="'${file}'"
	else
       	 	err_exit $LINENO "Code file ${file} not found!" 1
	fi
}
# set cdo commands with outfile in netCDF format 
function set_cdo_cmd() {
	# $1 name of input data file
	# $2 path to code file for data file
	# $3 variable to store cdo command
	# $4 tidying up is desired on failure

	# Retrieve data file isn't in netCDF format
	if [[ $(get_str_short_suffix "$1" ".") != "nc" ]]; then
		# get code file for data file
		local codefile
		select_code_file $1 $2 codefile $4
		# cdo command to convert climatology file to netCDF
		local cmd="cdo --silent -f nc -setpartab,${codefile}"
	else
		# cdo command for netCDF data files
		local cmd="cdo --silent"
	fi
	# return cdo command
	eval ${3}="'${cmd}'"
}
# set climatology file name 
function set_climatology_fname() {
	# $1 name of data file to get climatology from
	# $2 time period of data file
	# $3 type id of data to get climatology from, e.g. daily means
	# $4 type id of climatology data

	# prefix of data file name up to time period 
	local pref=$(get_str_short_prefix "$1" "$2")
	# suffix of data file incl. time period
	local suff=${2}$(get_str_short_suffix "$1" "$2")
	# climatology file name
	local outfile=${pref}${4}_${suff}
	# delete type id of monthly means substring
	outfile=${outfile/_${3}_/"_"}
	# return climatology file name
	echo "${outfile}"
}
# Tidying up: mv data files of temporary directory back
# to where they come from
function tidying_up() {
	# $file_pats 	global data file patterns
	# $mvcp		global move/copy of model data to temporary
	#		directory and vice versa
	# $sub_time	global placeholder for time period of data files
	# $tmp_path	global temporary directory
	# $years	global list of years of processing
	local msg     # local error message
	local code=1  # local error code

	printf "\nMove/Copy model data files from temporary directory"
	printf "${tmp_path} to where they come from"
	printf "\nfor ${first_year} to ${last_year} starts ...\n"
	
	# Retrieve temporary directory doesn't exist and exit
	err_dat_dir ${LINENO} "temporary" "${tmp_path}" false

	# Retrieve temporary directory doesn't contain any files
	# and exit
	if [ ! "$(find ${tmp_path} -type f 2>/dev/null)" ]; then
		printf "\n\tRETURN: temporary dir doesn't contain any files!\n\n"
		exit
	fi

	for (( i=0;i<${#file_pats[@]};i++ )); do
		# Pattern of temporary data file names
		local pat="$(get_str_short_suffix "${file_pats[i]}" "/")"
		# Path where the temporary data files comes from 
	        local in_path="$(get_str_long_prefix "${file_pats[i]}" "/")"
		# Retrieve path doesn't exist and exit
		#if [ ! -d ${in_path} ]; then
		#	msg="Path ${in_path} where the temporary "
		#	msg="${msg}" "data files comes from is not there!"
		#	err_exit ${LINENO} "${msg}" ${code}
		#fi
		# not needed: path inquired within global file patterns 
		
		# Loop through all years for processing
		for year in ${years}; do
			# Data file names
			fnames="${pat/${sub_time}/${year}*}"
			# Loop through temporay data files
			for file in ${tmp_path}/${fnames}; do
				# Set raw data file
				in_file=$(get_str_short_suffix "${file}" "/")
				in_file=${in_path}/${in_file}	 
				# Retrieve temporary data file exists
				if [[ -f "${file}" ]]; then
					# Retrieve raw data file doesn't exists
					if [[ ! -f "${in_file}" ]]; then
						# Move temporary data file 
						# back to where it comes from
						printf "\n\t${mvcp} "${file}" "${in_file}"\n"
						${mvcp} "${file}" "${in_file}"
					# Retrieve raw data file exists
					else
						printf "\n\tNo move/copy: raw data file ${in_file} exists !\n"
					fi
				# Retrieve temporary data file doesn't exist
				else
					printf "\n\tNo move/copy: temporary data files ${file} not found !\n"
				fi
			done
		done
	done

	printf "\nMove/Copy model data files done!\n"
}
# Built-in help text
function usage() {
  printf "${b}NAME${n}\n\t$(basename $0) - archiving mpiesm model data\n\n" 
  printf "${b}SYNOPSIS ${n}\n\t${b}$(basename $0)${n}  [${u}OPTION${n}]...\n\n"
 
  printf "${b}DESCRIPTION ${n}\n"
  printf "\tArchives mpiesm model raw, restart, and/or logging data for a\n"
  printf "\tuser specified time period and model components. Additionally\n"
  printf "\tclimatologies are performed.\n"
  printf "\tThe user can freely select which files should be processed.\n"
  printf "\tFurthermore the archiving and the processing of the\n"
  printf "\tclimatologies can be switched on/off.\n\n"

  printf "\tIn the experiment's root directory, see option experiment_path,\n"
  printf "\tthe raw and restart data are expected in the outdata and restart\n"
  printf "\tsubdirectory of the model component, and the logging data in\n"
  printf "\tthe log subdirectory.\n\n"

  printf "\tThe data are moved or copied to and processed in the temporary\n"
  printf "\tdirectory, see option tmp_path. That will be previously cleaned up.\n\n"

  printf "\tOptionally monthly (mm), multi-year monthly (lm) and seasonal (sm),\n"
  printf "\tand time mean (tm) climatologies of the model raw data being\n"
  printf "\tprocessed and copied into the local storage directory, see\n"
  printf "\toption climatologies_path. The files are named after the\n"
  printf "\tprocessed raw data file combined with the climatology type and\n"
  printf "\tthe time period replaced with the processing's first and last\n"
  printf "\tyear.\n\n"

  printf "\tFor archiving each data and climatology file get zipped and put\n"
  printf "\tinto a tarball. The raw data and climatologies of each model\n"
  printf "\tcomponent, the restart and logging data get each one tarball.\n"
  printf "\tThey are named after\n"
  printf "\t<experiment_id>_<model_component|restart|log>_<firstyear_lastyear>.tar\n\n"
  printf "\tThe minimum and maximum size of the tarballs are 1 GB (warning)\n"
  printf "\tand 500 GB (error).\n\n"

  printf "\tThe tarballs are transfered via pftp to the archive path on\n"
  printf "\tthe long term remote archiv and copied into the local storage\n"
  printf "\tdirectory, see options remote_archive_path and local_archive_path.\n"
  printf "\tThe transfer expects a valid netrc.\n\n"

  printf "\tAll directories incl. the remote directories are created as\n"
  printf "\trequired.\n\n"

  printf "\tEnabling tidying up, see option ltidying, moves or copies data\n"
  printf "\tfiles from the temporary directory to where they come from. By\n"
  printf "\tthe setup you set the temporary files and where they come from.\n"
  printf "\tNo more archiving and/or climatologies are performed.\n\n"

  printf "${b}OPTIONS${n}\n"

  printf "\t${b}--atmosphere_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select raw data of the\n"
  printf "\t\tatmosphere model component for processing, see options\n"
  printf "\t\tlatmosphere and larchive_data and/or lclimatologies:\n"
  printf "\t\t<experiment_path>/outdata/<atmosphere_model_component>/\n"
  printf "\t\t<experiment_id>_<atmosphere_model_component>_<atmosphere_data_pat><time period>.grb\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"accw_  ATM_mm_ BOT_mm_ co2_ co2_mm_ echam_\"\n"

  printf "\t${b}--atmosphere_data_type${n} ${u}TYPE${n}\n"
  printf "\t\ttype of raw data of atmosphere model component to control\n"
  printf "\t\tperforming climatologies (daily means = dm, monthly means = mm,\n"
  printf "\t\tyearly means = ym, no climatologies desired = none).\n"
  printf "\t\tdefault: \"mm mm mm none mm none\"\n"

  printf "\t${b}--atmosphere_model_component${n} ${u}COMPONENT${n}\n"
  printf "\t\tmodel component of file patterns to select raw and restart\n"
  printf "\t\tdata of the atmosphere model component for processing, see\n"
  printf "\t\toption atmosphere_data_pat and atmosphere_restart_data_pat.\n"
  printf "\t\tdefault: \"echam6\"\n"

  printf "\t${b}--atmosphere_restart_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select restart data of\n"
  printf "\t\tthe atmosphere model component for processing, see options\n"
  printf "\t\tlatmosphere and larchive_restart:\n"
  printf "\t\t<experiment_path>/restart/<atmosphere_model_component>/\n"
  printf "\t\trestart_<experiment_id>_<atmosphere_restart_data_pat><time period>.nc\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"accw_ co2_ echam_\"\n"

  printf "\t${b}--climatologies_path${n} ${u}PATH${n}\n"
  printf "\t\tpath to root directory, where to store performed climatologies.\n"
  printf "\t\tdefault: \"/work/<project_id>/\${USER}/<mpiesm_id>/experiments/"
  printf "means/<experiment_id>\"\n"
  
  printf "\t${b}--coupler_model_component${n} ${u}COMPONENT${n}\n"
  printf "\t\tmodel component of file patterns to select restart data of\n"
  printf "\t\tthe coupler for processing, see option coupler_restart_data_pat.\n"
  printf "\t\tdefault: \"oasis3mct\"\n"

  printf "\t${b}--coupler_restart_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select restart data of\n"
  printf "\t\tthe coupler model component for processing, see options\n"
  printf "\t\tlcoupler and larchive_restart:\n"
  printf "\t\t<experiment_path>/restart/<coupler_model_component>/\n"
  printf "\t\t<coupler_restart_data_pat>i<experiment_id>_<time period>.tar\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"flxatmos_ sstocean_\"\n"

  printf "\t${b}--experiment_id, -e${n} ${u}ID${n}\n"
  printf "\t\tmandatory experiment ID for default paths to temporary,\n"
  printf "\t\texperiment's, climatologies, local and remote archive\n"
  printf "\t\tdata (see options tmp_path, experiment_path,\n"
  printf "\t\tclimatologies_path, local_archive_path,and\n"
  printf "\t\tremote_archive_path). Additionally used for file patterns\n"
  printf "\t\tto select raw, restart, and/or logging data for processing.\n"

  printf "\t${b}--experiment_path${n} ${u}PATH${n}\n"
  printf "\t\tpath to directory with experiment's raw, restart, and\n"
  printf "\t\tlogging data.\n"
  printf "\t\tdefault: \"/work/<project_id>/\${USER}/<mpiesm_id>/experiments/"
  printf "<experiment_id>\"\n"

  printf "\t${b}--firstyear, -f${n} ${u}FIRSTYEAR${n}\n"
  printf "\t\tmandatory year to start data processing (in format YYYY).\n"
  printf "\t\tTogether with last year, see option lastyear, and the\n"
  printf "\t\tincrement, see option incrementyear, it sets the period and\n"
  printf "\t\tthe list of years for the file patterns to select raw,\n"
  printf "\t\trestart, and/or logging data for processing.\n"

  printf "\t${b}--help, -h${n}\n"
  printf "\t\tdisplay this built-in help text and exit.\n" 

  printf "\t${b}--incrementyear, -f${n} ${u}INCREMENT${n}\n"
  printf "\t\tincrement of processing's time period in years. Together\n"
  printf "\t\twith first and last year, see option firstyear and lastyear,\n"
  printf "\t\tit sets the list of years for the file patterns to select\n"
  printf "\t\traw, restart, and/or logging data for processing.\n"
  printf "\t\tdefault: 1\n"

  printf "\t${b}--land_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select raw data of the\n"
  printf "\t\tland model component for processing, see options lland and\n"
  printf "\t\tlarchive_data and/or lclimatologies:\n"
  printf "\t\t<experiment_path>/outdata/<land_model_component>/\n"
  printf "\t\t<experiment_id>_<land_model_component>_<land_data_pat><time period>.grb\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"jsbach_ jsbach_mm_ land_ land_mm_ surf_ surf_mm_\n"
  printf "\t\t\t\tveg_ veg_mm_ yasso_ yasso_mm_\"\n"

  printf "\t${b}--land_data_type${n} ${u}TYPE${n}\n"
  printf "\t\ttype of raw data of land model component to control\n"
  printf "\t\tperforming climatologies (daily means = dm, monthly means = mm,\n"
  printf "\t\tyearly means = ym, no climatologies desired = none).\n"
  printf "\t\tdefault: \"none mm none mm none mm none mm none mm\"\n"

  printf "\t${b}--land_model_component${n} ${u}COMPONENT${n}\n"
  printf "\t\tmodel component of file patterns to select raw and restart\n"
  printf "\t\tdata of the land model component for processing, see option\n"
  printf "\t\tland_data_pat and land_restart_data_pat.\n"
  printf "\t\tdefault: \"jsbach\"\n"

  printf "\t${b}--land_restart_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select restart data of\n"
  printf "\t\tthe land model component for processing, see options lland\n"
  printf "\t\tand larchive_restart:\n"
  printf "\t\t<experiment_path>/restart/<land_model_component>/\n"
  printf "\t\trestart_<experiment_id>_<land_restart_data_pat><time period>.nc\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"hd_ jsbach_ surf_ veg_ yasso_\"\n"

  printf "\t${b}--larchive_data${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable archiving raw data and climatologies of enabled model\n"
  printf "\t\tcomponents.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--larchive_log${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable archiving experiment's logging data.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--larchive_restart${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable archiving restart data of enabled model components.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--latmoshere${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable processing data of the atmosphere model component.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--lastyear, -l${n} ${u}LASTYEAR${n}\n"
  printf "\t\tmandatory year to end data processing (in format YYYY).\n"
  printf "\t\tTogether with first year, see option firstyear, and the\n"
  printf "\t\tincrement, see option incrementyear, it sets the period and\n"
  printf "\t\tthe list of years for the file patterns to select raw,\n"
  printf "\t\trestart, and/or logging data for processing.\n"

  printf "\t${b}--lclimatologies${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable processing climatologies of raw data of enabled model\n"
  printf "\t\tcomponents.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--lcoupler${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable processing data of coupler component.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--lland${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable processing data of land model component.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--llog${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable processing experiment's logging data.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--lobgc${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable processing data of ocean's biogeochemistry model\n"
  printf "\t\tcomponent.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--local_archive_path${n} ${u}PATH${n}\n"
  printf "\t\tpath to archive data on local machine.\n"
  printf "\t\tdefault: \"/work/<project_id>/\${USER}/<mpiesm_id>/experiments/"
  printf "tars/<experiment_id>\"\n"
  
  printf "\t${b}--locean${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable processing data of ocean model component.\n"
  printf "\t\tdefault: true\n"

  printf "\t${b}--log_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select logging data\n"
  printf "\t\tfor processing:\n"
  printf "\t\t<experiment_path>/log/"
  printf "<experiment_id>_<log_data_pat><time period>.log\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"run_ store_ \"\n"
  printf "\t\tif latmosphere	== true	: <log_data_pat> + echam6_atmout_\n"
  printf "\t\tif locean	== true	: <log_data_pat> + mpiom_oceout_\n"
  printf "\t\tif lobgc	== true	: <log_data_pat> + hamocc_bgcout_\n"

  printf "\t${b}--lprofiling${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable profiling.\n"
  printf "\t\tdefault: false\n"

  printf "\t${b}--ltidying${n} ${u}LOGICAL${n}\n"
  printf "\t\tenable tidying up: move/copy data files from temporary\n"
  printf "\t\tdirectory to where they come from. By the setup you set the\n"
  printf "\t\ttemporary files and where they come from. No more archiving\n"
  printf "\t\tand/or climatologies are performed.\n"
  printf "\t\tdefault: false\n"

  printf "\t${b}--mpiesm_id, -m${n} ${u}ID${n}\n"
  printf "\t\tmandatory mpiesm ID for default paths to experiment's,\n"
  printf "\t\tclimatologies, local and remote archive data (see options\n"
  printf "\t\texperiment_path, climatologies_path, local_archive_path,\n"
  printf "\t\tand remote_archive_path).\n"

  printf "\t${b}--obgc_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select raw data of the\n"
  printf "\t\tocean's biogeochemistry model component for processing, see\n"
  printf "\t\toptions lobgc and larchive_data and/or lclimatologies:\n"
  printf "\t\t<experiment_path>/outdata/<obgc_model_component>/\n"
  printf "\t\t<experiment_id>_<obgc_model_component>_<obgc_data_pat><time period>.grb\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"co2_ data_2d_mm_ data_3d_ym_ data_eu_mm_\n"
  printf "\t\t\t\tdata_sedi_ym_ monitoring_ym_\"\n"

  printf "\t${b}--obgc_data_type${n} ${u}TYPE${n}\n"
  printf "\t\ttype of raw data of ocean's biogeochemistry model component\n"
  printf "\t\tto control performing climatologies (daily means = dm,\n"
  printf "\t\tmonthly means = mm, yearly means = ym, \n"
  printf "\t\tno climatologies desired = none).\n"
  printf "\t\tdefault: \"dm mm ym mm ym ym\"\n"

  printf "\t${b}--obgc_model_component${n} ${u}COMPONENT${n}\n"
  printf "\t\tmodel component of file patterns to select raw and restart\n"
  printf "\t\tdata of the ocean's biogeochemistry model component for\n"
  printf "\t\tprocessing, see option obgc_data_pat and obgc_restart_data_pat.\n"
  printf "\t\tdefault: \"hamocc\"\n"

  printf "\t${b}--obgc_restart_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select restart data of\n"
  printf "\t\tthe ocean's biogeochemistry model component for processing,\n"
  printf "\t\tsee options lobgc and larchive_restart:\n"
  printf "\t\t<experiment_path>/restart/<obgc_model_component>/\n"
  printf "\t\trerun_<experiment_id>_<obgc_restart_data_pat><time period>.nc\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"hamocc_\"\n"

  printf "\t${b}--ocean_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select raw data of the\n"
  printf "\t\tocean model component for processing, see options locean and\n"
  printf "\t\tlarchive_data and/or lclimatologies:\n"
  printf "\t\t<experiment_path>/outdata/<ocean_model_component>/\n"
  printf "\t\t<experiment_id>_<ocean_model_component>_<ocean_data_pat><time period>.grb\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"data_2d_mm_ data_3d_mm_ data_moc_mm_ "
  printf "monitoring_ym_ timeser_mm_\"\n"

  printf "\t${b}--ocean_data_type${n} ${u}TYPE${n}\n"
  printf "\t\ttype of raw data of the ocean model component to control\n"
  printf "\t\tperforming climatologies (daily means = dm, monthly means = mm,\n"
  printf "\t\tyearly means = ym, no climatologies desired = none).\n"
  printf "\t\tdefault: \"mm mm mm ym mm\"\n"

  printf "\t${b}--ocean_model_component${n} ${u}COMPONENT${n}\n"
  printf "\t\tmodel component of file patterns to select raw and restart\n"
  printf "\t\tdata of the ocean model component for processing, see option\n"
  printf "\t\tocean_data_pat and obgc_restart_data_pat.\n"
  printf "\t\tdefault: \"mpiom\"\n"

  printf "\t${b}--ocean_restart_data_pat${n} ${u}PATTERN${n}\n"
  printf "\t\tdata indicators of file patterns to select restart data of\n"
  printf "\t\tthe ocean model component for processing, see options locean\n"
  printf "\t\tand larchive_restart:\n"
  printf "\t\t<experiment_path>/restart/<ocean_model_component>/\n"
  printf "\t\trerun_<experiment_id>_<ocean_restart_data_pat><time period>.nc\n"
  printf "\t\twith time period between first and last year.\n"
  printf "\t\tdefault: \"mpiom_\"\n"

  printf "\t${b}--project_id, -p ${n} ${u}ID${n}\n"
  printf "\t\tmandatory project ID for default paths to experiment's,\n"
  printf "\t\tclimatologies, local and remote archive data (see options\n"
  printf "\t\texperiment_path, climatologies_path, local_archive_path,\n"
  printf "\t\tand remote_archive_path).\n"

  printf "\t${b}--remote_archive_path${n} ${u}PATH${n}\n"
  printf "\t\tpath to archive data on remote archiving host.\n"
  printf "\t\tdefault: \"<project_id>/\${USER}/<mpiesm_id>/<experiment_id>\"\n"

  printf "\t${b}--tmp_path${n} ${u}PATH${n}\n"
  printf "\t\tpath to temporary data and processing.\n"
  printf "\t\tdefault: \"/scratch/m/\${USER}/tmp/<experiment_id>_<first_year>_<last_year>_\$\$\"\n"

  printf "\t${b}--verbose, -v${n} ${u}INT${n}\n"
  printf "\t\tenable verbose log.\n"
  printf "\t\tdefault: 0 (no log info) | >=2 print command info\n"

  printf "${b}\nEXAMPLES ${n}\n\n"
  printf "\t${b}./$(basename $0) --project_id xx0000 --mpiesm_id mpiesm_rev_0\n"
  printf "\t\t--experiment_id xxx0123 --firstyear 3800 --lastyear 3899${n}\n"
  printf "\t\tarchives experiment's xxx0123 default raw, restart, and\n"
  printf "\t\tlogging data of all model components and performs and\n"
  printf "\t\tarchives the default climatologies for the time period\n"
  printf "\t\t3800 - 3899. The data are expected in and the processed\n"
  printf "\t\tdata are put into the default directories.\n\n"

  printf "\t${b}./$(basename $0) --project_id xx0000 --mpiesm_id mpiesm_rev_0\n"
  printf "\t\t--experiment_id xxx0123 --firstyear 3800 --lastyear 3899\n"
  printf "\t\t--lobgc false${n}\n"
  printf "\t\tarchives experiment's xxx0123 default raw, restart, and\n"
  printf "\t\tlogging data of all model components except the ocean's\n"
  printf "\t\tbiogeochemical one and performs and archives the default\n"
  printf "\t\tclimatologies for the time period 3800 - 3899. The data are\n"
  printf "\t\texpected in and the processed data are put into the\n"
  printf "\t\tdefault directories.\n\n"

  printf "\t${b}./$(basename $0) --project_id xx0000 --mpiesm_id mpiesm_rev_0\n"
  printf "\t\t--experiment_id xxx0123 --firstyear 3800 --lastyear 3899\n"
  printf "\t\t--latmosphere false --lland false --lobgc false --locean false\n"
  printf "\t\t--lcoupler false ${n}\n"
  printf "\t\tarchives experiment's xxx0123 default logging data for the\n"
  printf "\t\ttime period 3800 - 3899. The data are expected in and the\n"
  printf "\t\tprocessed data are put into the default directories.\n\n"

  printf "\t${b}./$(basename $0) --project_id xx0000 --mpiesm_id mpiesm_rev_0\n"
  printf "\t\t--experiment_id xxx0123 --firstyear 3800 --lastyear 3899\n"
  printf "\t\t--larchive_restart false --larchive_log false ${n}\n"
  printf "\t\tarchives experiment's xxx0123 default raw data of all model\n"
  printf "\t\tcomponents and performs and archives the default climatologies\n"
  printf "\t\tfor the time period 3800 - 3899. The data are expected in and\n"
  printf "\t\tthe processed data are put into the default directories.\n\n"

  printf "\t${b}./$(basename $0) --project_id xx0000 --mpiesm_id mpiesm_rev_0\n"
  printf "\t\t--experiment_id xxx0123 --firstyear 3809 --lastyear 3899\n"
  printf "\t\t--incrementyear 10 --larchive_data false --larchive_log false\n"
  printf "\t\t--lclimatologies false${n}\n"
  printf "\t\tarchives experiment's xxx0123 default restart data of all model\n"
  printf "\t\tcomponents for the time period 3809 - 3899 with an increment of\n"
  printf "\t\t10 years. The data are expected in and the processed data are\n"
  printf "\t\tput into the default directories.\n\n"

  printf "\n"
}
#-------------------------------------------------------------------------#
#set -x
#dir="/work/mh0110/m211003/mpiesm-flo-dev/experiments/uwe0010/outdata/echam6"
## Get file pattern of model compoments experiment's raw data directory
## Twice delete up to the first "_" (incl.), 
## 3rd delete all after last "_", then sort and find uniques
#ls $dir | sed -n 's/_/&\n/;s/.*\n//p' | sed -n 's/_/&\n/;s/.*\n//p' | sed 's/\(.*\_\).*/\1/g' | sort | uniq 
#exit
#-------------------------------------------------------------------------#

# ---- Get options and setup ---------------------------------------------#
while [[ -n $1 ]]; do
	case $1 in
		# data indicators of file patterns for atmosphere raw data
		--atmosphere_data_pat 		)
			get_option_arg atmos_dat $@ ;;
		# type of atmosphere raw data to control performing climatologies
		--atmosphere_data_type 		)
			get_option_arg atmos_dat_type $@ ;;
		# model component for the atmosphere
		--atmosphere_model_component 	)
			get_option_arg atmos_mod_com $@ ;;
		# data indicators of file patterns for atmosphere restart data
		--atmosphere_restart_data_pat 	)
			get_option_arg atmos_rst $@ ;;
                # path to root directory, where to store performed climatologies
		--climatologies_path 	)
			get_option_arg cli_path $@ ;;
		# model component for the coupler
		--coupler_model_component 	)
			get_option_arg coupl_mod_com $@ ;;
                # data indicators of file patterns for coupler restart data
		--coupler_restart_data_pat	)
			get_option_arg coupl_rst $@ ;;
                # mandatory experiment ID for default root directories and
		# file patterns to select data for processing
		--experiment_id | -e 		)
			get_option_arg exp_id $@ ;;
                # path to experiment's root directory
		--experiment_path 		)
			get_option_arg exp_path $@ ;;
                # mandatory first model year to process (in format YYYY)
		--firstyear | -f		)
			get_option_arg first_year $@ ;;
		# print built-in help and exit
		--help | -h			)
			usage; exit ;;
                # increment of time period in years
		--incrementyear 		)
			get_option_arg increment_year $@ ;;
 		# data indicators of file patterns for land raw data
		--land_data_pat 		)
			get_option_arg land_dat $@ ;;
		# type of land raw data to control processing climatologies
		--land_data_type 		)
			get_option_arg land_dat_type $@ ;;
		# model component for the land
		--land_model_component		)
			get_option_arg land_mod_com $@ ;;
		# data indicators of file patterns for land restart data
		--land_restart_data_pat 	)
			get_option_arg land_rst $@ ;;
                # enable archiving raw data and climatologies
		--larchive_data			)
			get_option_arg larchive_data $@ ;;
                # enable archiving logging data
		--larchive_log			)
			get_option_arg larchive_log $@ ;;
                # enable archiving restart data
		--larchive_restart		)
			get_option_arg larchive_restart $@ ;;
                # enable processing atmosphere data
		--latmosphere			)
			get_option_arg latmos $@ ;;
                # mandatory last model year to process (in format YYYY)
		--lastyear | -l			)
			get_option_arg last_year $@ ;;
                # enable performing climatologies 
		--lclimatologies		)
			get_option_arg lclimat $@ ;;
                # enable processing coupler data 
		--lcoupler			)
			get_option_arg lcoup $@ ;;
                # enable processing land data 
		--lland				)
			get_option_arg lland $@ ;;
		# enable processing logging data 
		--llog				)
			get_option_arg llog $@ ;;
                # enable processing ocean biogeochemical data 
		--lobgc				)
			get_option_arg lobgc $@ ;;
		# path to archive data on local machine
		--local_archive_path  		)
			get_option_arg loc_arc_path $@ ;;
                # enable processing ocean data 
		--locean			)
			get_option_arg locean $@ ;;
                # data indicators of file patterns for logging data 
		--log_data_pat 			)
			get_option_arg log_dat $@ ;;
                # enable profiling 
		--lprofiling			)
			get_option_arg lprofiling $@ ;;
                # enable tidying up only 
		--ltidying			)
			get_option_arg ltidying $@ ;;
                # mandatory mpiesm ID for default root directories
		--mpiesm_id | -m 		)
			get_option_arg esm_id $@ ;;
		# data indicators of file patterns for ocean biogeochemical raw data
		--obgc_data_pat 		)
			get_option_arg obgc_dat $@ ;;
		# type of ocean biogeochemical raw data to control processing climatologies
		--obgc_data_type		)
			get_option_arg obgc_dat_type $@ ;;
		# model component for the ocean biogeochemistry
		--obgc_model_component 		)
			get_option_arg obgc_mod_com $@ ;;
		# data indicators of file patterns for ocean biogeochemical restart data
		--obgc_restart_data_pat 	)
			get_option_arg obgc_rst $@ ;;
		# data indicators of file patterns for ocean raw data
		--ocean_data_pat 		)
			get_option_arg ocean_dat $@ ;;
		# type of ocean raw data to control processing climatologies
		--ocean_data_type 		)
			get_option_arg ocean_dat_type $@ ;;
		# model component for the ocean
		--ocean_model_component 	)
			get_option_arg ocean_mod_com $@ ;;
		# data indicators of file patterns for ocean restart data
		--ocean_restart_data_pat 	)
			get_option_arg ocean_rst $@ ;;
                # mandatory project ID for default root directories
		--project_id | -p 		)
			get_option_arg prj_id $@ ;;
		# path to archive data on remote machine
		--remote_archive_path 		)
			get_option_arg rmt_arc_path $@ ;;
                # path to temporary data and processing
		--tmp_path			)
			get_option_arg tmp_path $@ ;;
                # enable verbose log 
		--verbose | -v			)
			get_option_arg verbose $@ ;;
		# error and exit if option isn't defined 
	 	-*               	)
			err_msg="Invalid option $1!"
			if [[ "$1" != $( echo "$1" | tr -d = ) ]]; then
			   err_msg=${err_msg}" Please use blank insted of '=' " 
			   err_msg=${err_msg}" to separate option's argument."
			fi
			err_exit $LINENO "${err_msg}" 1 
	esac
	shift
done

# Enable verbose log
verbose=${verbose:-0}
# Print command info
[[ ${verbose} -ge 2 ]] && set -x

# Enable profiling
lprofiling=${lprofiling:-false}
# Get time for profiling in nanoseconds
if ${lprofiling}; then t1="$(date +%s%N)"; fi
#-------------------------------------------------------------------------#

# ---- Processing setup --------------------------------------------------#
# Enable climatologies
lclimat=${lclimat:-true}
# Enable archiving raw data and climatologies
larchive_data=${larchive_data:-true}
# Enable archiving restart data
larchive_restart=${larchive_restart:-true}
# Enable archiving logging data/
larchive_log=${larchive_log:-true}

# Error handling of enable processing
if ! ${lclimat}          && ! ${larchive_data} && \
   ! ${larchive_restart} && ! ${larchive_log}     \
   ; then
	err_exit $LINENO "Processing's configuration is lacking!" 1 
fi

# Enable processing of atmosphere/ECHAM data 
latmos=${latmos:-true}
# Enable processing of land/JSBACH data
lland=${lland:-true}
# Enable processing of ocean/MPIOM data
locean=${locean:-true}
# Enabel processing ocean's biogeochemical/HAMOCC data
lobgc=${lobgc:-true}
# Enabel processing coupler data
lcoup=${lcoup:-true}
# Enabel processing logging data
llog=${llog:-true}

# Error handling of enable model components for processing
if ( (${lclimat} || ${larchive_data})                                        &&   \
    (! ${latmos} && ! ${lland} && ! ${locean} && ! ${lobgc}) )               ||   \
   ( ${larchive_restart}                                                     &&   \
    (! ${latmos} && ! ${lland} && ! ${locean} && ! ${lobgc} && ! ${lcoup}) ) ||   \
   ( ${larchive_log}                                                         &&   \
     ! ${llog} )                                               \
   ; then
	err_exit $LINENO "Processing's configuration is lacking!" 1 
fi

# Enable tidying up only: mv/cp data files from temporary directory 
# to where they come from
# needs processings's configuration
ltidying=${ltidying:-false}

# Retrieve empty mandatory options and exit:
# retrieve archiving raw, restart, and/or logging data are desired
if ((${latmos} || ${lland} || ${locean} || ${lobgc}) && (${larchive_data} || ${larchive_restart})) || \
   (					   ${lcoup}  &&  ${larchive_restart}	                 ) || \
   (                                       ${llog}   &&  ${larchive_log}                         )    \
   ; then
	# Retrieve mandatory experiment id to set data files prefixes
	# and default root directories is empty
	[[ -z ${exp_id} ]] && err_option ${LINENO} "experiment_id" 

	# Retrieve path to default root directory of experiment or
	# to archive data on local or remote machine are desired 
	if [[ -z ${exp_path} || -z ${loc_arc_path} || -z ${rmt_arc_path} ]]; then
		# Retrieve mandatory project id is empty and exit
		[[ -z ${prj_id} ]] && err_option ${LINENO} "project_id"
		# Retrieve mandatory MPIESM id is empty and exit
		[[ -z ${esm_id} ]] && err_option ${LINENO} "mpiesm_id"
	fi
fi
# retrieve climatologies are desired
if (${latmos} || ${lland} || ${locean} || ${lobgc}) && ${lclimat}; then
	# Retrieve mandatory experiment id to set data files prefixes
	# and default root directories are desired is empty
	[[ -z ${exp_id} ]] && err_option ${LINENO} "experiment_id"

	# Retrieve path to default root directory of experiment or
	# to store locally climatologies are desired 
	if [[ -z ${exp_path} || -z ${cli_path} ]]; then
		# Retrieve mandatory project id isn't set and exit
		[[ -z ${prj_id} ]] && err_option ${LINENO} "project_id"
		# Retrieve mandatory MPIESM id isn't set and exit
		[[ -z ${esm_id} ]] && err_option ${LINENO} "mpiesm_id" 
	fi
fi
# first and last year of raw data to process
[[ -z ${first_year} ]] && err_option ${LINENO} "firstyear" 
[[ -z ${last_year}  ]] && err_option ${LINENO} "lastyear"

# Increment of time period in years
increment_year=${increment_year:-1}

# Get list of years
years="$(seq -f "%04.0f" -s " " ${first_year} ${increment_year} ${last_year})"
# Retrieve empty list: first year > last year and exit
[[ -z ${years} ]] && err_years ${LINENO} ${first_year} ${last_year}

# Get time period
period=${first_year}_${last_year}
#-------------------------------------------------------------------------#

# ---- Set root directories ----------------------------------------------#
# Path to temporary data and processing
tmp_path=${tmp_path:-"/scratch/m/${USER}/tmp/${exp_id}_${first_year}_${last_year}_$$"}
# Path to root directory of experiment
exp_path=${exp_path:-"/work/${prj_id}/${USER}/${esm_id}/experiments/${exp_id}"}
# Path to root directory of experiment's raw data
dat_path="${exp_path}/outdata"
# Error handling for non existing experiment's data directory
if (${lclimat}||${larchive_data}); then
	err_dat_dir ${LINENO} "root data" "${dat_path}"
fi
# Path to root directory of experiment's restart data
rst_path="${exp_path}/restart"
# Error handling for non existing experiment's data directory
if ${larchive_restart}; then
	err_dat_dir ${LINENO} "root restart" "${rst_path}"
fi
# Path to root directory of experiment's log and code data
log_path="${exp_path}/log"
# Error handling for non existing experiment's data directory
if ${larchive_log}; then
	err_dat_dir ${LINENO} "root log" "${log_path}"
fi
# Path to root directory of local tarballs
loc_arc_path=${loc_arc_path:-"/work/${prj_id}/${USER}/${esm_id}/experiments/tars/${exp_id}"}
# Path to root directory of tarballs on remote archiving machine
rmt_arc_path=${rmt_arc_path:-"${prj_id}/${USER}/${esm_id}/${exp_id}"}
# Path to root directory of restart tarballs on remote archiving machine
rmt_arc_rst_path="${rmt_arc_path}/restarts"

# Path to root directory of climatologies
cli_path=${cli_path:-"/work/${prj_id}/${USER}/${esm_id}/experiments/means/${exp_id}"}
#-------------------------------------------------------------------------#

# ---- Print processing setup --------------------------------------------#
set +x
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                                                   "
echo "+	This is processing ${exp_id} for setup:		     	  	  "
echo "+	Project ID: 		${prj_id}				  "
echo "+	MPIESM ID: 		${esm_id}			 	  "
echo "+	Climatologies: 		${lclimat}				  "
echo "+	Archiving data: 	${larchive_data}			  "
echo "+	Archiving restarts:	${larchive_restart}			  "
echo "+	Archiving logs: 	${larchive_log}				  "
echo "+	Atmosphere: 		${latmos}				  "
echo "+	Land:	 		${lland}				  "
echo "+	Ocean:	 		${locean}				  "
echo "+	OBGC:	 		${lobgc}				  "
echo "+	Coupler: 		${lcoup}				  "
echo "+	Logs:	 		${llog}				  	  "
echo "+	Time period: 		${period}				  "
echo "+	TMP dir: 		${tmp_path}				  "
echo "+	Root data dir: 		${dat_path}				  "
echo "+	Root restart dir:	${rst_path}				  "
echo "+	Log data dir:		${log_path}				  "
echo "+	Local archive: 		${loc_arc_path}				  "
echo "+	Remote archive:		${rmt_arc_path}				  "
echo "+	Climatologies dir:	${cli_path}				  "
echo "+                                                                   "
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
[[ ${verbose} -ge 2 ]] && set -x
# ------------------------------------------------------------------------#

# ---- Defaults ----------------------------------------------------------#
# Enable move / copy of model data to temporary directory for processing
declare -r mvcp="cp"
#declare -r mvcp="mv"

# Concatenate data files for climatologies
# concatenate
declare -r cat=cat
# cdo cat 12 min slower than cat for 100 years all of Flo's exprm
#cat="cdo --silent -cat"

# Zip files
# gzip, keep original files
declare -r zip="gzip -c"
# szip, rejected bc of poorer results and
# unsupported file type for coupler restart files
#zip="cdo -s -z szip copy"
# zipped file suffix
case "${zip}" in
	gzip*)
		zip_suf="gz"
		;;
esac

# ftp
declare -r ftp="pftp"

# Create new tarball
declare -r ctar="tar -cvf"
# Append to tarball
declare -r atar="tar -rvf"
# Suffix of tarballs
declare -r tar_suf="tar"

# Maximum size of tarball in GB
declare -r max_sz_tarball=500
# Minimum size of tarball in MB
declare -r min_sz_tarball=1024

# netCDF file suffix
declare -r nc_suf="nc"
# grib file suffix
declare -r grb_suf="grb"

# Placeholder for time period of data files
declare -r sub_time="<YYYY>"

# Data is given by daily means
declare -r dm_data="dm"
# monthly means
declare -r mm_data="mm"
# yearly means
declare -r ym_data="ym"
# multi-year monthly means
declare -r lm_data="lm"
# multi-year seasonal means
declare -r sm_data="sm"
# time means
declare -r tm_data="tm"
# no result data, e.g. restart and log data
declare -r no_data="none"
#-------------------------------------------------------------------------#

# ---- Set directories and patterns for atmosphere data ------------------#
# Retrieve processing of atmosphere data is desired
if ${latmos}&&(${lclimat}||${larchive_data}||${larchive_restart}); then
	# Model component
	mod_com=${atmos_mod_com:-"echam6"}

	# Retrieve archiving raw data and/or climatologies are desired
        if (${lclimat}||${larchive_data}) then
		# Path to subdirectory of model component tarballs on archive
		arc_spath="${rmt_arc_path}/${mod_com}"
		# Path to subdirectory of model component raw data
		dat_spath="${dat_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Atmosphere data" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Atmosphere data" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of raw data files
		pref="${exp_id}_${mod_com}_"
        	data=${atmos_dat:-"accw_           ATM_${mm_data}_ \
				   BOT_${mm_data}_ co2_            \
				   co2_${mm_data}_ echam_         "}
        	declare -a data=(${data[0]})
		# Type of data, e.g. monthly means, etc.
		type=${atmos_dat_type:-"${mm_data} ${mm_data} ${mm_data} \
					${no_data} ${mm_data} ${no_data}"}
        	declare -a type=(${type[0]})
		if [[ ${#data[@]} -ne ${#type[@]} ]]; then
			msg="Size atmos data pattern ${#data[@]} /= size types ${#type[@]} !"
			err_exit $LINENO "${msg}" 1 
		fi
		suff="${grb_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Raw data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
			# Overall file patterns
        		file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${type[i]}")
				# Paths to local directory to store climatologies
	        		cli_spath=("${cli_spath[@]}" "${cli_path}/${mod_com}")
			fi
		        if ${larchive_data}; then
				# Tarball for each data pattern on archive
				tars[i]="${arc_spath}/${pref}${period}.${tar_suf}"
				# Overall raw data and climatologies tarballs
			        tar_balls=("${tar_balls[@]}" "${tars[i]}")
			fi
		done
	fi

	# Retrieve archiving restart data is desired 
        if ${larchive_restart}; then
		# Path to subdirectory of model component restart tarballs on archive
		arc_spath="${rmt_arc_rst_path}"
		# Subdirectory of model component restart data
		dat_spath="${rst_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Atmosphere restart" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Atmosphere restart" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of restart data files
		pref="restart_${exp_id}_"
		data=${atmos_rst:-"accw_ co2_ echam_"}
        	declare -a data=(${data[0]})
		suff="${nc_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Restart data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
       			# Overall restart file patterns
		 	file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${no_data}")
				# Paths to local directory to store climatologies
				# empty bc of no climatologies for restarts
	        		cli_spath=("${cli_spath[@]}" "")
			fi
			# Tarball for each restart pattern on archive
			tars[i]="${arc_spath}/${exp_id}_restart_${period}.${tar_suf}"
			# Overall restart data tarballs
		        tar_balls=("${tar_balls[@]}" "${tars[i]}")
		done
	fi
fi
#-------------------------------------------------------------------------#

# ---- Set directories and patterns for land data ------------------------#
# Retrieve processing of land data is desired
if ${lland}&&(${lclimat}||${larchive_data}||${larchive_restart}); then
	# Model component
	mod_com=${land_mod_com:-"jsbach"}

	# Retrieve archiving raw data and/or climatologies are desired
        if (${lclimat}||${larchive_data}) then
		# Path to subdirectory of model component tarballs on archive
		arc_spath="${rmt_arc_path}/${mod_com}"
		# Path to subdirectory of model component raw data
		dat_spath="${dat_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Land data" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Land data" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of raw data files
		pref="${exp_id}_${mod_com}_"
        	data=${land_dat:-"jsbach_ jsbach_${mm_data}_  \
				    land_   land_${mm_data}_  \
				    surf_   surf_${mm_data}_  \
                                     veg_    veg_${mm_data}_  \
				   yasso_  yasso_${mm_data}_ "}
        	declare -a data=(${data[0]})
		# Type of data, e.g. monthly means, etc.
		type=${land_dat_type:-"${no_data} ${mm_data}  \
				       ${no_data} ${mm_data}  \
				       ${no_data} ${mm_data}  \
				       ${no_data} ${mm_data}  \
				       ${no_data} ${mm_data} "}
        	declare -a type=(${type[0]})
		if [[ ${#data[@]} -ne ${#type[@]} ]]; then
			msg="Size land data pattern ${#data[@]} /= size types ${#type[@]} !"
			err_exit $LINENO "${msg}" 1
		fi
		suff="${grb_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Raw data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
			# Overall file patterns
        		file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${type[i]}")
				# Paths to local directory to store climatologies
	        		cli_spath=("${cli_spath[@]}" "${cli_path}/${mod_com}")
			fi
		        if ${larchive_data}; then
				# Tarball for each data pattern on archive
				tars[i]="${arc_spath}/${pref}${period}.${tar_suf}"
				# Overall raw data and climatologies tarballs
			        tar_balls=("${tar_balls[@]}" "${tars[i]}")
			fi
		done
	fi

	# Retrieve archiving restart data is desired 
        if ${larchive_restart}; then
		# Path to subdirectory of model component restart tarballs on archive
		arc_spath="${rmt_arc_rst_path}"
		# Subdirectory of model component restart data
		dat_spath="${rst_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Land restart" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Land restart" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of restart data files
		pref="restart_${exp_id}_"
		data=${land_rst:-"hd_ jsbach_ surf_ veg_ yasso_"}
        	declare -a data=(${data[0]})
		suff="${nc_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Restart data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
       			# Overall restart file patterns
		 	file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${no_data}")
				# Paths to local directory to store climatologies
				# empty bc of no climatologies for restarts
	        		cli_spath=("${cli_spath[@]}" "")
			fi
			# Tarball for each restart pattern on archive
			tars[i]="${arc_spath}/${exp_id}_restart_${period}.${tar_suf}"
			# Overall restart data tarballs
		        tar_balls=("${tar_balls[@]}" "${tars[i]}")
		done
	fi
fi
#-------------------------------------------------------------------------#

# ---- Set directories and patterns for ocean data -----------------------#
# Retrieve processing of ocean data is desired
if ${locean}&&(${lclimat}||${larchive_data}||${larchive_restart}); then
	# Model component
	mod_com=${ocean_mod_com:-"mpiom"}

	# Retrieve archiving raw data and/or climatologies are desired
        if (${lclimat}||${larchive_data}) then
		# Path to subdirectory of model component tarballs on archive
		arc_spath="${rmt_arc_path}/${mod_com}"
		# Path to subdirectory of model component raw data
		dat_spath="${dat_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Ocean data" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Ocean data" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of raw data files
		pref="${exp_id}_${mod_com}_"
	        data=${ocean_dat:-" data_2d_${mm_data}_ data_3d_${mm_data}_    \
				   data_moc_${mm_data}_ monitoring_${ym_data}_ \
				    timeser_${mm_data}_                       "}
        	declare -a data=(${data[0]})
		# Type of data, e.g. monthly means, etc.
		type=${ocean_dat_type:-"${mm_data} ${mm_data} ${mm_data} \
					${ym_data} ${mm_data}           "}
        	declare -a type=(${type[0]})
		if [[ ${#data[@]} -ne ${#type[@]} ]]; then
			msg="Size ocean data pattern ${#data[@]} /= size types ${#type[@]} !"
			err_exit $LINENO "${msg}" 1
		fi
		suff="${nc_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Raw data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
			# Overall file patterns
        		file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${type[i]}")
				# Paths to local directory to store climatologies
	        		cli_spath=("${cli_spath[@]}" "${cli_path}/${mod_com}")
			fi
		        if ${larchive_data}; then
				# Tarball for each data pattern on archive
				tars[i]="${arc_spath}/${pref}${period}.${tar_suf}"
				# Overall raw data and climatologies tarballs
			        tar_balls=("${tar_balls[@]}" "${tars[i]}")
			fi
		done
	fi

	# Retrieve archiving restart data is desired 
        if ${larchive_restart}; then
		# Path to subdirectory of model component restart tarballs on archive
		arc_spath="${rmt_arc_rst_path}"
		# Subdirectory of model component restart data
		dat_spath="${rst_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Ocean restart" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Ocean restart" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of restart data files
		pref="rerun_${exp_id}_"
		data=${ocean_rst:-"mpiom_"}
        	declare -a data=(${data[0]})
		suff="${nc_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Restart data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
       			# Overall restart file patterns
		 	file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${no_data}")
				# Paths to local directory to store climatologies
				# empty bc of no climatologies for restarts
	        		cli_spath=("${cli_spath[@]}" "")
			fi
			# Tarball for each restart pattern on archive
			tars[i]="${arc_spath}/${exp_id}_restart_${period}.${tar_suf}"
			# Overall restart data tarballs
		        tar_balls=("${tar_balls[@]}" "${tars[i]}")
		done
	fi
fi
#-------------------------------------------------------------------------#

# ---- Set directories and patterns for ocean biogeochemical data --------#
# Retrieve processing of ocean biogeochemical data is desired
if ${lobgc}&&(${lclimat}||${larchive_data}||${larchive_restart}); then
	# Model component
	mod_com=${obgc_mod_com:-"hamocc"}

	# Retrieve archiving raw data and/or climatologies are desired
        if (${lclimat}||${larchive_data}) then
		# Path to subdirectory of model component tarballs on archive
		arc_spath="${rmt_arc_path}/${mod_com}"
		# Path to subdirectory of model component raw data
		dat_spath="${dat_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Ocean biogeochemical data" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Ocean biogeochemical data" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of raw data files
		pref="${exp_id}_${mod_com}_"
	        data=${obgc_dat:-"      co2_            data_2d_${mm_data}_    \
				    data_3d_${ym_data}_ data_eu_${mm_data}_    \
				  data_sedi_${ym_data}_ monitoring_${ym_data}_"}
        	declare -a data=(${data[0]})
		# Type of data, e.g. monthly means, etc.
		type=${obgc_dat_type:-"${dm_data} ${mm_data} ${ym_data} \
				       ${mm_data} ${ym_data} ${ym_data}"}
        	declare -a type=(${type[0]})
		if [[ ${#data[@]} -ne ${#type[@]} ]]; then
			msg="Size obgc data pattern ${#data[@]} /= size types ${#type[@]} !"
			err_exit $LINENO "${msg}" 1
		fi
		suff="${nc_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Raw data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
			# Overall file patterns
        		file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${type[i]}")
				# Paths to local directory to store climatologies
	        		cli_spath=("${cli_spath[@]}" "${cli_path}/${mod_com}")
			fi
		        if ${larchive_data}; then
				# Tarball for each data pattern on archive
				tars[i]="${arc_spath}/${pref}${period}.${tar_suf}"
				# Overall raw data and climatologies tarballs
			        tar_balls=("${tar_balls[@]}" "${tars[i]}")
			fi
		done
	fi

	# Retrieve archiving restart data is desired 
        if ${larchive_restart}; then
		# Path to subdirectory of model component restart tarballs on archive
		arc_spath="${rmt_arc_rst_path}"
		# Subdirectory of model component restart data
		dat_spath="${rst_path}/${mod_com}"
		# Error handling for non existing data directory
		err_dat_dir ${LINENO} "Ocean biogeochemical restart" "${dat_spath}"
                # Error handling for read-only data directory
		# if model data moved from experiment to temporary dir 
		if [[ ${mvcp} == "mv" ]]; then
			err_ro_dat_dir ${LINENO} "Ocean biogeochemical restart" "${dat_spath}"
		fi
		# Prefix, data indicator and suffix of restart data files
		pref="rerun_${exp_id}_"
		data=${obgc_rst:-"hamocc_"}
        	declare -a data=(${data[0]})
		suff="${nc_suf}"
		# Loop through all data indicators
        	for (( i=0;i<${#data[@]};i++ )); do
			# Restart data file pattern
			pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}.${suff}"
       			# Overall restart file patterns
		 	file_pats=("${file_pats[@]}" "${pats[i]}")
			if ${lclimat}; then
				# Overall files data type
				data_type=("${data_type[@]}" "${no_data}")
				# Paths to local directory to store climatologies
				# empty bc of no climatologies for restarts
	        		cli_spath=("${cli_spath[@]}" "")
			fi
			# Tarball for each restart pattern on archive
			tars[i]="${arc_spath}/${exp_id}_restart_${period}.${tar_suf}"
			# Overall restart data tarballs
		        tar_balls=("${tar_balls[@]}" "${tars[i]}")
		done
	fi
fi
#-------------------------------------------------------------------------#

# ---- Set directories and patterns for coupler restart data -------------#
# Retrieve processing of coupler restart data is desired
if ${lcoup}&&${larchive_restart}; then
	# Coupler component
	mod_com=${coupl_mod_com:-"oasis3mct"}
	# Path to subdirectory of coupler restart tarballs on archive
	arc_spath="${rmt_arc_rst_path}"
	# Path to subdirectory of model component restart data
	dat_spath="${rst_path}/${mod_com}"
	# Error handling for non existing data directory
	err_dat_dir ${LINENO} "Coupler restart" "${dat_spath}"
        # Error handling for read-only data directory
	# if model data moved from experiment to temporary dir 
	if [[ ${mvcp} == "mv" ]]; then
		err_ro_dat_dir ${LINENO} "Coupler restart" "${dat_spath}"
	fi
	# Prefix, data indicator and suffix of restart data files
	pref="${exp_id}_"
	data=${coupl_rst:-"flxatmos_ sstocean_"}
	declare -a data=(${data[0]})
	suff="tar"
	# Loop through all data indicators
	for (( i=0;i<${#data[@]};i++ )); do
		# Restart data file pattern
		pats[i]="${dat_spath}/${data[i]}${pref}${sub_time}.${suff}"
       		# Overall restart file patterns
	 	file_pats=("${file_pats[@]}" "${pats[i]}")
		if ${lclimat}; then
			# Overall files data type
			data_type=("${data_type[@]}" "${no_data}")
			# Paths to local directory to store climatologies
			# empty bc of no climatologies for restarts
        		cli_spath=("${cli_spath[@]}" "")
		fi
		# Tarball for each restart pattern on archive
		tars[i]="${arc_spath}/${exp_id}_restart_${period}.${tar_suf}"
		# Overall restart data tarballs
	        tar_balls=("${tar_balls[@]}" "${tars[i]}")
	done
fi
#-------------------------------------------------------------------------#

# ---- Set directories and patterns for logging data ---------------------#
# Retrieve processing of logging data is desired
if ${llog}&&${larchive_log}; then
	# Path to subdirectory of logging tarball on archive
	arc_spath="${rmt_arc_path}/log"
	# Path to subdirectory of logging data
	dat_spath=${log_path}
	# Error handling for non existing data directory
	err_dat_dir ${LINENO} "Log data" "${dat_spath}"
        # Error handling for read-only data directory
	# if model data moved from experiment to temporary dir 
	if [[ ${mvcp} == "mv" ]]; then
		err_ro_dat_dir ${LINENO} "Log data" "${dat_spath}"
	fi
	# Prefix, data indicator and suffix of restart data files
	pref="${exp_id}_"
	dflt_dat="run_ store_"
        if ${latmos}; then dflt_dat=${dflt_dat}" "echam6_atmout_; fi
        if ${locean}; then dflt_dat=${dflt_dat}" "mpiom_oceout_ ; fi
        if ${lobgc} ; then dflt_dat=${dflt_dat}" "hamocc_bgcout_; fi
	data=${log_dat:-"${dflt_dat}"}
	declare -a data=(${data[0]})
	# Loop through all data indicators
	for (( i=0;i<${#data[@]};i++ )); do
		# Logging data file pattern
		pats[i]="${dat_spath}/${pref}${data[i]}${sub_time}" 
       		# Overall restart file patterns
	 	file_pats=("${file_pats[@]}" "${pats[i]}")
		if ${lclimat}; then
			# Overall files data type
			data_type=("${data_type[@]}" "${no_data}")
			# Paths to local directory to store climatologies
			# empty bc of no climatologies for restarts
        		cli_spath=("${cli_spath[@]}" "")
		fi
		# Tarball for each logging pattern on archive
		tars[i]="${arc_spath}/${pref}log_${period}.${tar_suf}"
	        tar_balls=("${tar_balls[@]}" "${tars[i]}")
	done
fi
#-------------------------------------------------------------------------#

# ---- Only tidying up ---------------------------------------------------#
# Tidying up: mv/cp data files from temporary directory 
# to where they come from
if ${ltidying}; then
	tidying_up
	exit
fi
#-------------------------------------------------------------------------#

# ---- Prepare processing data (archiving, climatologies) ----------------#
# Create temporary directory
mkdir -p ${tmp_path}
# Change to temporary directory for processing 
# and clean up, beside of a clean status this improves sth tar performance
cd ${tmp_path}
rm -rf *
printf "\nChanging to tmp/working directory: $(pwd)\n"

# Create directories to store locally climatologies
if ${lclimat}; then
	uniq_dirs=($(printf "%s\n" "${cli_spath[@]}" | sort -u))
	for (( i=0;i<${#uniq_dirs[@]};i++ )); do
		mkdir -p ${uniq_dirs[i]}
	done
fi

# Set unique tarballs
uniq_tar_balls=($(printf "%s\n" "${tar_balls[@]}" | sort -u))

# Retrieve profiling is desired
if ${lprofiling}; then 
	# Get time needed for setup in nanoseconds
	t2="$(date +%s%N)"; 
	t_setup="$((t2-t1))" 
	t1=${t2}

        # Initialize time needed for
	# getting lists of data files and putting data to tmp
	t_get_fnames=0; t_data_2_tmp=0
	# concatenate data files and climatologies 
	t_concatenat=0; t_climatolog=0
	# zipping and archiving 
	t_zipping=0; t_archiv=0
	# remote and local transfer of tarballs
	t_rmt_arc=0; t_loc_arc=0
fi
#-------------------------------------------------------------------------#

# ---- Processing raw data (archiving, climatologies) --------------------#
# Initialize list of raw data, temporary, and zipped files
in_files=""; tmp_files=""; zip_files=""
# Initialize climatologies files 
mm_file=""; lm_file=""; sm_file=""; tm_file=""

# Loop through all data file patterns
for (( i=0;i<${#file_pats[@]};i++ )); do
	printf "\nProcessing ${file_pats[i]}"
	printf "\nfrom ${first_year} to ${last_year} starts ...\n\n"

	# Loop through all years for processing
	for year in ${years}; do
		# Data files 
		files=${file_pats[i]/${sub_time}/${year}*}
		# Loop through all data files
		for file in ${files}; do
			# Retrieve data file exist
			if [ -f ${file} ]; then
				# Add to list of data files
				in_files=${in_files}" "${file}
				# Add to list of temporary data files
				tmp_files=${tmp_files}" \
					  "$(get_str_short_suffix "${file}" "/")
			else
				err_dat_file ${LINENO} "${file}"
			fi 
		done
	done
	# Time needed for getting lists of data files 
	if ${lprofiling}; then 
		t2="$(date +%s%N)"; 
		t_get_fnames="$((t2-t1+t_get_fnames))" 
		t1=${t2}
	fi

	# Print some info
	proc_mv_msg ${mvcp} $(get_str_long_prefix "${file_pats[i]}" "/") ${tmp_path}
	# Move/copy raw data files to temporary directory 
	${mvcp} ${in_files} ${tmp_path}

	# Time needed for move/copy raw data files 
	if ${lprofiling}; then 
		t2="$(date +%s%N)"; 
		t_data_2_tmp="$((t2-t1+t_data_2_tmp))" 
		t1=${t2}
	fi

        # Retrieve climatologies are desired
	if ${lclimat} && [[ "${data_type[i]}" != "${no_data}" ]]; then
		# File name for concatenated raw data files
		cat_file=$(get_str_short_suffix "${file_pats[i]}" "/")
		cat_file=${cat_file/${sub_time}/${period}}
		# Print some info
		printf "\tcombine raw data files into 1 file ${cat_file} on $(pwd)\n\n"
		# Concatenate raw data files to one file
		# overwrites old one
		# cat
		${cat} ${tmp_files} > ${cat_file}
		# cdo cat
		#${cat} ${tmp_files} ${cat_file}

		# Time needed for concatenate data files 
		if ${lprofiling}; then 
			t2="$(date +%s%N)"; 
			t_concatenat="$((t2-t1+t_concatenat))" 
			t1=${t2}
		fi

		# Print some info
		printf "\tclimatologies of file ${cat_file}\n\n"
		# Climatologies
		case "${data_type[i]}" in
			# of daily means
			*${dm_data}*)
				# Monthly means
				get_mm_climatology ${cat_file} ${period}  \
						   ${dm_data}  ${mm_data} \
						   mm_file     ${log_path}

				# Multi-year monthly means
				get_lm_climatology ${cat_file} ${period}  \
						   ${mm_data}  ${lm_data} \
						   lm_file     ${log_path}

				# Multi-year seasonal means
				get_sm_climatology ${lm_file} ${period}  \
						   ${lm_data} ${sm_data} \
						   sm_file    ${log_path}

				# Time means file
				get_tm_climatology ${lm_file} ${period}  \
						   ${lm_data} ${tm_data} \
						   tm_file    ${log_path}
	    			;;
			# of monthly means
			*${mm_data}*)
				# Multi-year monthly means
				get_lm_climatology ${cat_file} ${period}  \
						   ${mm_data}  ${lm_data} \
						   lm_file     ${log_path}

				# Multi-year seasonal means
				get_sm_climatology ${lm_file} ${period}  \
						   ${lm_data} ${sm_data} \
						   sm_file    ${log_path}

				# Time means file
				get_tm_climatology ${lm_file} ${period}  \
						   ${lm_data} ${tm_data} \
						   tm_file    ${log_path}
	    			;;
			# of yearly means	
			*${ym_data}*)
				# Time means file
				get_tm_climatology ${cat_file} ${period}  \
						   ${ym_data}  ${tm_data} \
						   tm_file     ${log_path}
				;;
			# of other data	
			*)
				# Time means file
				get_tm_climatology ${cat_file} ${period}  \
						   "XXXXXXXX"  ${tm_data} \
						   tm_file     ${log_path}
				;;
		esac
		# Copy climatologies to local storage directory
		cp ${mm_file} ${lm_file} ${sm_file} ${tm_file} ${cli_spath[i]}
                # Clean up concatenated raw data files
                rm -rf ${cat_file}

		# Time needed for climatologies 
		if ${lprofiling}; then 
			t2="$(date +%s%N)"; 
			t_climatolog="$((t2-t1+t_climatolog))" 
			t1=${t2}
		fi
	fi

	# Retrieve archiving is desired
	if ${larchive_data} || ${larchive_restart} || ${larchive_log} ; then
		# Print some info
                printf "\tzip files on $(pwd)\n\n"
		# Zip each raw data and climatologies file
		for file in ${tmp_files} ${mm_file} ${lm_file} \
			    ${sm_file} ${tm_file} 	       \
		; do
			${zip} "${file}" > "${file}.${zip_suf}"
			zip_files="${zip_files}"" ""${file}.${zip_suf}"
		done	

		# Time needed for zipping  
		if ${lprofiling}; then 
			t2="$(date +%s%N)"; 
			t_zipping="$((t2-t1+t_zipping))" 
			t1=${t2}
		fi

		# Retrieve creating new or appending to tarball is desired
		tarball=$(get_str_short_suffix "${tar_balls[i]}" "/")
		[[ -f ${tarball} ]] && tar=${atar} || tar=${ctar}
		# Archiving, local tarball
		proc_tar_msg "${tar}" "${tarball}" "$(pwd)" 
		${tar} ${tarball} ${zip_files}
		# Size of tarball in GB
		tsz=$(du --block-size=1073741824 --apparent-size ${tarball} | cut -f1)
		# Retrieve tarball is too big for archive and exit
		if [[ $tsz -gt ${max_sz_tarball} ]]; then
			msg="Size of tarball ${tarball} = ${tsz}GB is too big !"
			err_exit $LINENO "${msg}" 1 
		fi

		# Time needed for archiving  
		if ${lprofiling}; then 
			t2="$(date +%s%N)"; 
			t_archiv="$((t2-t1+t_archiv))" 
			t1=${t2}
		fi
	fi	
	# Some info
	printf "\nProcessing ${file_pats[i]} files done.\n\n"

	# Initialize list of raw data and temporary files for next pattern
        in_files=""; tmp_files=""; zip_files=""
	# Initialize climatologies files for next pattern
	mm_file=""; lm_file=""; sm_file=""; tm_file=""
done
#-------------------------------------------------------------------------#

# ---- Put tarballs to archive and local storage directory ---------------#
# Retrieve archiving is desired
if ${larchive_data} || ${larchive_restart} || ${larchive_log} ; then

# Get unique tarballs
uniq_tar_balls=($(printf "%s\n" "${tar_balls[@]}" | sort -u))
# and ftp log file
ftp_log="ftp.$$.log"

# Loop through all tarballs
for (( i=0;i<${#uniq_tar_balls[@]};i++ )); do
# Make and test tarballs directories on archive 
# get tarball name
tarball=$(get_str_short_suffix "${uniq_tar_balls[i]}" "/")
# get path to tarball on archive 
dir=$(get_str_long_prefix "${uniq_tar_balls[i]}" "/")
# print some info
printf "\nPutting tarball ${tarball} to remote dir ${dir} ...\n\n"
# size of tarball in MB
tsz=$(du --block-size=1048576 --apparent-size "${tarball}" | cut -f1)
# retrieve tarball is too small for archive
if [[ $tsz -lt ${min_sz_tarball} ]]; then
	printf "WARNING: Size of tarball ${tarball} = ${tsz}MB is too small.\n\n"
fi
# size of tarball in B
tsz=$(ls -l "${tarball}" | awk '{print $5}')
# print some info
printf "\tcreating directory ${dir} on remote machine\n\n"
# initialize subdirectories in path to tarball
sdir=""
# loop through non empty path
while [[ -n "${dir}" ]]; do
# increment subdirectories step by step
[[ -n "${sdir}" ]] && sdir="${sdir}/${dir%%/*}" || sdir=${dir%%/*}
# make last subdirectory on archive 
set +e
trap '' ERR
${ftp} << EOF
mkdir "${sdir}"
quit
EOF
set -e
trap 'err_exit ${LINENO}' ERR
# path to tarball up to last subdirectory
case "$dir" in
	*/*) 
		dir=$(get_str_long_suffix "${dir}" "/")
		;;
	*)
		dir=""
		;;
esac
done # end while loop through non empty path, end mkdir rmt dirs

# Put tarball to remote archive
# print some info
printf "\n\ttransfering tarball\n\n"
# get path to tarball on archive
dir=$(get_str_long_prefix "${uniq_tar_balls[i]}" "/")
# put tarball to archive
${ftp} << EOF >> ${ftp_log} 2>&1 
cd ${dir}
pput ${tarball}
ls -l 
quit
EOF
# print some info
printf "\tchecking transferred size\n\n"
# check transfer
if [ $? -ne 0 ] ; then exit 1 ; fi
put_check_size "${tsz}" "${uniq_tar_balls[i]}" "${ftp_log}"
# print some info
printf "Putting tarball ${tarball} done.\n\n"

# Get time needed for transfer tarballs to remote machine in nanoseconds
if ${lprofiling}; then 
	t2="$(date +%s%N)"; 
	t_rmt_arc="$((t2-t1+t_rmt_arc))" 
	t1=${t2}
fi

# Copy tarball to local storage directory
if [ "$(pwd)" != "${loc_arc_path}" ] ; then
	# create local subdirectory of tarball
	sdir=$(get_str_long_suffix ${tarball} "_")
	sdir=$(get_str_short_prefix ${sdir} "_")
	mkdir -p ${loc_arc_path}/${sdir}
	# print some info
	printf "\nCopying tarball ${tarball} to local dir ${loc_arc_path}/${sdir}\n\n"
	cp ${tarball} ${loc_arc_path}/${sdir}/.
	# print some info
	printf "Copying tarball ${tarball} done.\n\n"

	# get time needed for local copy of tarballs in nanoseconds
	if ${lprofiling}; then 
		t2="$(date +%s%N)"; 
		t_loc_arc="$((t2-t1+t_loc_arc))" 
		t1=${t2}
	fi
fi

done # end for loop through unique tarballs

fi
#-------------------------------------------------------------------------#

# ---- Print profiling ---------------------------------------------------#
if ${lprofiling}; then
	# time in ms 
	t_setup_ms=$((t_setup/1000000))
	t_get_fnames_ms=$((t_get_fnames/1000000))
	t_data_2_tmp_ms=$((t_data_2_tmp/1000000))
	t_concatenat_ms=$((t_concatenat/1000000))
	t_climatolog_ms=$((t_climatolog/1000000))
	t_zipping_ms=$((t_zipping/1000000))
	t_archiv_ms=$((t_archiv/1000000))
	t_rmt_arc_ms=$((t_rmt_arc/1000000))
	t_loc_arc_ms=$((t_loc_arc/1000000))
	# time in s
	t_setup_s=$((t_setup/1000000000))
	t_get_fnames_s=$((t_get_fnames/1000000000))
	t_data_2_tmp_s=$((t_data_2_tmp/1000000000))
	t_concatenat_s=$((t_concatenat/1000000000))
	t_climatolog_s=$((t_climatolog/1000000000))
	t_zipping_s=$((t_zipping/1000000000))
	t_archiv_s=$((t_archiv/1000000000))
	t_rmt_arc_s=$((t_rmt_arc/1000000000))
	t_loc_arc_s=$((t_loc_arc/1000000000))
	# sum of the times in ns
	t_sum=$((t_setup      + t_get_fnames + t_data_2_tmp + \
		 t_concatenat + t_climatolog + t_zipping    + \
		 t_archiv     + t_rmt_arc    + t_loc_arc))
	# sum of the times in ms
	t_sum_ms=$((t_setup_ms      + t_get_fnames_ms + t_data_2_tmp_ms + \
	  	    t_concatenat_ms + t_climatolog_ms + t_zipping_ms    + \
		    t_archiv_ms     + t_rmt_arc_ms    + t_loc_arc_ms))
	# sum of the times in s
	t_sum_s=$((t_setup_s      + t_get_fnames_s + t_data_2_tmp_s + \
		   t_concatenat_s + t_climatolog_s + t_zipping_s    + \
		   t_archiv_s     + t_rmt_arc_s    + t_loc_arc_s))

	printf "\t\ts\t\tms\t\tns\n"
	printf "t_setup      = "${t_setup_s}"\t\t"${t_setup_ms}"\t\t${t_setup}\t\n"      
	printf "t_get_fnames = "${t_get_fnames_s}"\t\t"${t_get_fnames_ms}"\t\t${t_get_fnames}\t\n" 
	printf "t_data_2_tmp = "${t_data_2_tmp_s}"\t\t"${t_data_2_tmp_ms}"\t\t${t_data_2_tmp}\t\n" 
	printf "t_concatenat = "${t_concatenat_s}"\t\t"${t_concatenat_ms}"\t\t${t_concatenat}\t\n" 
	printf "t_climatolog = "${t_climatolog_s}"\t\t"${t_climatolog_ms}"\t\t${t_climatolog}\t\n" 
	printf "t_zipping    = "${t_zipping_s}"\t\t"${t_zipping_ms}"\t\t${t_zipping}\t\n"    
	printf "t_archiv     = "${t_archiv_s}"\t\t"${t_archiv_ms}"\t\t${t_archiv}\t\n"    
	printf "t_rmt_arc    = "${t_rmt_arc_s}"\t\t"${t_rmt_arc_ms}"\t\t${t_rmt_arc}\t\n"    
	printf "t_loc_arc    = "${t_loc_arc_s}"\t\t"${t_loc_arc_ms}"\t\t${t_loc_arc}\t\n"    
	printf "sum          = "${t_sum_s}"\t\t"${t_sum_ms}"\t\t${t_sum}\t\n"    
fi
#-------------------------------------------------------------------------#

# ---- Exit --------------------------------------------------------------#
on_exit
#-------------------------------------------------------------------------#

