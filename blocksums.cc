#include<netcdf>
#include<iostream>
#include<vector>
#include<fstream>
#include<string>

using namespace std;
using namespace netCDF;

void reset_sum(vector<double>& sum);
inline bool fexists(const char *filename)
{
  ifstream ifile(filename);
  return (bool)  ifile;
}

int main(int argc, char** argv){
  vector<string> vars;
  vars.push_back("thk");
  vars.push_back("cumul_acab");
  vars.push_back("cumul_calving");
  //  vars.push_back("cumul_basal_flux");
  vars.push_back("cumul_shelf_basal_flux");


  //Input data, the name is read from the command line
  NcFile mask_file ("output_mask.nc", NcFile::read);
  if  (mask_file.isNull()){
    cerr<< "trouble opening file : output_mask.nc\n";
    return 1;
  }
  NcVar mask_var = mask_file.getVar("output_mask");

  int numsteps;
  mask_var.getAtt("num_vals").getValues(&numsteps);
  long int mask_size = mask_var.getDim(0).getSize() * mask_var.getDim(1).getSize();
  //  cerr << "mask size = " << mask_size;
  int mask[mask_size];
  mask_var.getVar(mask);


  vector <double> sum(numsteps);

  //cerr<<"creating output file\n";

  //output data. Always written to outfile.nc
  char outfilename[] = "outfile.nc";
  NcFile outfile (outfilename, NcFile::replace);
  if  (outfile.isNull()){
    cerr<< "trouble opening outfile : outfile.nc\n";
    return 1;
  }
  NcDim out_t = outfile.addDim("t");
  NcDim out_cell_no = outfile.addDim("cell_no",numsteps);
  vector <NcDim> out_dims;
  out_dims.push_back(out_t);
  out_dims.push_back(out_cell_no);
  NcVar out_time =  outfile.addVar("t", ncDouble, out_t);
  vector <NcVar> out_data;
  for (int v=0; v <vars.size() ;v++)
    {
      //      cerr<<"creating var " << vars[v] << '\n';
      out_data.push_back(outfile.addVar(vars[v], ncDouble, out_dims));
    }

  vector<size_t> out_timestep;
  out_timestep.push_back(0);

  for (int filenum = 1;  filenum < argc; filenum++ ){

    //Open input file (one after the other)
    NcFile infile (argv[filenum], NcFile::read);
    if  (infile.isNull()){
      cerr<< "trouble opening file :" << argv[filenum] << '\n';
      return 1;
    }

    vector <NcVar> data_vars;
    for (int v=0; v <vars.size() ;v++)
      data_vars.push_back( infile.getVar(vars[v]));

    int dims[data_vars[0].getDimCount()];
    //Print dimensions to stderr for debugging
    // cerr<< argv[filenum] << '\n' ;
    for (int x=0; x< data_vars[0].getDimCount(); x++ ){
      dims[x]=data_vars[0].getDim(x).getSize();
      //cerr<< data_vars[0].getDim(x).name()<< "\t" << dims[x]<< "\n";
    }
    //determine size of one timeslice.
    long size= dims[1]*dims[2];
    if (size != mask_size ) {
      cerr<< "ERROR size " << size << "does not match mask_size " << mask_size << "\n"
	  << "Mask has size " << mask_var.getDim(0).getSize() << " by " << mask_var.getDim(1).getSize() << "\n";
      cerr<< "While data_vars[0] has size " << dims[1]<< " by " << dims[2] << '\n';
      return(1);
    }

    //get time dimension
    const string timename = data_vars[0].getDim(0).getName();
    NcVar in_time = infile.getVar(timename);

    double t;
    double field[size];
    vector<size_t> in_timestep;
    in_timestep.push_back(0);
    vector<size_t> field_index;
    field_index.push_back(0);
    field_index.push_back(0);
    field_index.push_back(0);
    vector<size_t> field_size;
    field_size.push_back(1);
    field_size.push_back(dims[1]);
    field_size.push_back(dims[2]);
    vector<size_t> out_field_index;
    out_field_index.push_back(0);
    out_field_index.push_back(0);
    vector<size_t> out_field_size;
    out_field_size.push_back(1);
    out_field_size.push_back(numsteps);
    for ( ; in_timestep[0]<data_vars[0].getDim(0).getSize() ; in_timestep[0]++ ) {
      in_time.getVar(in_timestep, &t);
      out_time.putVar(out_timestep, &t);
      out_field_index[0]=out_timestep[0];
      for (int v=0; v <vars.size() ;v++){
	reset_sum(sum);
	field_index[0]=in_timestep[0];
	data_vars[v].getVar(field_index, field_size, field);
	for (int x=0 ; x < size; x++)
	  sum[mask[x]]+=field[x];
	out_data[v].putVar(out_field_index,out_field_size,&sum[0]);
      }
      out_timestep[0]++;
    }
  }
  return 0 ;
}
void reset_sum(vector<double> &  sum){

  for (int i=0 ; i< sum.size() ; i++)
    sum[i] = 0.;
}
