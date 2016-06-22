#include<netcdf>
#include<iostream>
#include<vector>
using namespace std;
using namespace netCDF;
void reset_sum(vector<double>& sum);

void create_dims(NcFile& outfile, const NcVar & sample_var);
void diffuse( vector<vector<double> >  & vfield, const double missval) ;



int main(int argc, char** argv){
  if (argc < 3){
    std::cerr<<"Call " <<argv[0] << " INFILE VAR1 [VAR2 ... [VARN]]\n";
    return 64;
  }
  vector<char*> vars;
  for (int i = 2 ; i < argc ; i++)
    vars.push_back(argv[i]);


  //Input data, the name is read from the command line
  //Open input file (one after the other)
  char* infilename = argv[1];
  NcFile infile (infilename, NcFile::read);
    if  (infile.isNull()){
      cerr<< "trouble opening file :" << infilename << '\n';
      return 1;
    }
  vector <NcVar> input_vars; // read all the input variables.
  for (int v=0; v <vars.size() ;v++)
    input_vars.push_back( infile.getVar(vars[v]));

  //output data. Always written to infile[:-3]+"_filled.nc"
  std::string outfilename = infilename;
  {
    int ofns = outfilename.size();
    outfilename.resize(ofns+7);
    outfilename.replace(ofns-3,3,"_filled.nc");
  }

  NcFile outfile (outfilename, NcFile::replace);
  if  (outfile.isNull()){
    cerr<< "trouble opening outfile : "<< outfilename << "\n";
    return 1;
  }
  std::cerr<<"creating dims\n";
  create_dims(outfile, infile.getVar(vars[0]));
  std::cerr<<"created dims\n";

  vector <NcVar> output_vars;
  vector <std::string> dim_names; // Get a list of all dimension names
				  // for creating new variables.
  vector <size_t> dim_sizes;
  std::cerr<<"getting names and sizes\n";
  vector <NcDim> dims = input_vars.begin()->getDims();
  for (std::vector<NcDim>::iterator d = dims.begin() ; d != dims.end() ; d++){
    dim_names.push_back(d->getName());
    dim_sizes.push_back(d->getSize());
  }
  std::cerr<<"got names and sizes\n";
  for ( int ss = 0 ; ss < 3 ; ss++ )
    {std::cerr << "dim " << ss  << " size " << dim_sizes[ss] ; }

  vector <double> fill_values;
  for (std::vector<NcVar>::iterator v = input_vars.begin(); v != input_vars.end() ; v++){
    cerr<<"copying var " << v->getName() << '\n';
    NcVar ov = outfile.addVar( v->getName(), v->getType().getName(), dim_names );
    output_vars.push_back( ov );
    NcVarAtt ovf = v->getAtt("_FillValue");
    double fv ;
    ovf.getValues(&fv);
    fill_values.push_back(fv);
    ov.putAtt("_FillValue", ovf.getType(), fv);

  }

  //get the time dimension
  const string timename = input_vars[0].getDim(0).getName();
  NcVar in_time = infile.getVar(timename);
  NcVar out_time = outfile.addVar(timename, in_time.getType().getName(), timename);
  double t;
  double field[dim_sizes[1]][dim_sizes[2]];
  vector < vector <double> > vfield ( dim_sizes[1], vector<double>(dim_sizes[2],0)) ;
  vector<size_t> position(dim_sizes.size(), 0);
  vector<size_t> sizes(dim_sizes);
  sizes[0] =  1;
  vector<size_t> tpos(1,0);
  //loop over all timesteps in one file
  for (size_t in_timestep = 0 ; in_timestep < input_vars[0].getDim(0).getSize() ; in_timestep++ ) {
    //copy the time to the output file
    tpos[0]= in_timestep;
    in_time.getVar(tpos, &t);
    //    out_time.putVar(tpos, &t);
    position[0] = in_timestep;

    //for one timestep, process each variable
    for (int v=0; v <vars.size() ;v++){
      input_vars[v].getVar(position, sizes, field[0]);
      double fv = fill_values[v];
      for (size_t i = 0 ; i < dim_sizes[1] ; i++ )
	for (size_t j = 0 ; j < dim_sizes[2] ; j++ )
	  vfield[i][j] = field[i][j];
            diffuse(vfield, fv);
      for (size_t i = 0 ; i < dim_sizes[1] ; i++ )
	for (size_t j = 0 ; j < dim_sizes[2] ; j++ ){
	  field[i][j] = vfield[i][j];
	}
      output_vars[v].putVar(position, sizes, field[0]);
    }

  }
  return 0 ;
}

void reset_sum(vector<double> &  sum){

  for (int i=0 ; i< sum.size() ; i++)
    sum[i] = 0.;
}

void create_dims(NcFile& outfile, const NcVar & sample_var){
  std::vector<NcDim> dims = sample_var.getDims();
  for (std::vector<NcDim>::iterator d = dims.begin(); d != dims.end(); d++ ){
      if (d->isUnlimited())
	outfile.addDim(d->getName());
      else
	outfile.addDim(d->getName(), d->getSize());
    }
}

void copyvec( vector<vector<double> > in,  vector<vector<double> > & out){
  size_t ii = in.size(),
    jj = in[0].size();
  for (size_t i = 0 ; i < ii ; i++ )
    for (size_t j = 0 ; j < jj ; j++ )
      out[i][j] = in[i][j];
}
void copyvec( vector<vector<bool> > in,  vector<vector<bool> > & out){
  size_t ii = in.size(),
    jj = in[0].size();
  for (size_t i = 0 ; i < ii ; i++ )
    for (size_t j = 0 ; j < jj ; j++ )
      out[i][j] = in[i][j];
}

void diffuse( vector<vector<double> >  & vfield, const double missval) {
  size_t ii = vfield.size(),
    jj = vfield[0].size();
  vector < vector <double> > infield ( ii , vector<double>( jj ,0)) ;
  vector < vector <double> > inmask ( ii , vector<double>( jj , 0)) ;
  vector < vector <double> > currmask ( ii , vector<double>( jj , 0)) ;
  vector < vector <double> > weight ( ii , vector<double>( jj ,0)) ;
  vector < vector <double> > newfield ( ii , vector<double>( jj ,0)) ;

  copyvec(vfield, infield);
  for (size_t i = 0 ; i < ii ; i++ ){
    for (size_t j = 0 ; j < jj ; j++ ){
      inmask[i][j] = (infield[i][j] == missval) ? 0 : 1; // 0 is false
						       // (for
						       // multiplication)
    }
  }
  copyvec(inmask, currmask);
  for (int k = 0 ; k < 4000 ; k++){
    double count = 0 ;
    for (size_t i = 1 ; i < ii-1 ; i++ ){
      // low j margin
      newfield [i][0] =
      	currmask[i-1][0] * vfield[i-1][0] + currmask[i+1][0] * vfield[i+1][0]
      	+ currmask[i][1] * vfield[i][1]
      	+ .5 *(   currmask[i-1][1] * vfield[i-1][1]
      		  + currmask[i+1][1] * vfield[i+1][1] );
      weight[i][0] = currmask[i-1][0] + currmask[i+1][0]
      	+ currmask[i][1] + .5 * (currmask[i-1][1] + currmask[i+1][1]);
      // interior
      for (size_t j = 1 ; j < jj-1 ; j++ ){
	newfield [i][j] =
	  currmask[i-1][j] * vfield[i-1][j] + currmask[i+1][j] * vfield[i+1][j]
	  + currmask[i][j-1] * vfield[i][j-1] + currmask[i][j+1] * vfield[i][j+1]
	  + .5 *(   currmask[i-1][j-1] * vfield[i-1][j-1] + currmask[i-1][j+1] * vfield[i-1][j+1]
		    + currmask[i+1][j-1] * vfield[i+1][j-1] + currmask[i+1][j+1] * vfield[i+1][j+1] );
	weight[i][j] = currmask[i-1][j] + currmask[i+1][j]
	  + currmask[i][j-1] + currmask[i][j+1]
	  + .5 * (currmask[i-1][j-1] + currmask[i-1][j+1]
		  + currmask[i+1][j-1] + currmask[i+1][j+1]);
      }
      // high j margin
      newfield [i][jj-1] =
      	currmask[i-1][jj-1] * vfield[i-1][jj-1] + currmask[i+1][jj-1] * vfield[i+1][jj-1]
      	+ currmask[i][jj-2] * vfield[i][jj-2]
      	+ .5 *(   currmask[i-1][jj-2] * vfield[i-1][jj-2]
      		  + currmask[i+1][jj-2] * vfield[i+1][jj-2] );
      weight[i][jj-1] = currmask[i-1][jj-1] + currmask[i+1][jj-1]
      	+ currmask[i][jj-2] + .5 * (currmask[i-1][jj-2] + currmask[i+1][jj-2]);
    }
    // low i margin
    for (size_t j = 1 ; j < jj-1 ; j++ ){
    	newfield [0][j] =
    	  currmask[0+1][j] * vfield[0+1][j]
    	  + currmask[0][j-1] * vfield[0][j-1] + currmask[0][j+1] * vfield[0][j+1]
    	  + .5 *( currmask[0+1][j-1] * vfield[0+1][j-1] + currmask[0+1][j+1] * vfield[0+1][j+1] );

    	weight[0][j] = currmask[0+1][j]
    	  + currmask[0][j-1] + currmask[0][j+1]
    	  + .5 * (currmask[0+1][j-1] + currmask[0+1][j+1]);
      }
    // high i margin
      for (size_t j = 1 ; j < jj-1 ; j++ ){
    	newfield [ii-1][j] =
    	  currmask[ii-2][j] * vfield[ii-2][j]
    	  + currmask[ii-1][j-1] * vfield[ii-1][j-1] + currmask[ii-1][j+1] * vfield[ii-1][j+1]
    	  + .5 *( currmask[ii-2][j-1] * vfield[ii-2][j-1] + currmask[ii-2][j+1] * vfield[ii-2][j+1] );

    	weight[ii-1][j] = currmask[ii-2][j]
    	  + currmask[ii-1][j-1] + currmask[ii-1][j+1]
    	  + .5 * (currmask[ii-2][j-1] + currmask[ii-2][j+1]);
      }

    for (size_t i = 0 ; i < ii ; i++ )
      for (size_t j = 0 ; j < jj ; j++ ){
	if (weight[i][j] > 1.6 ){
	  newfield[i][j] = newfield[i][j] / weight[i][j];
	  weight[i][j] = 1;
	  newfield[i][j] = newfield[i][j] * (1 - currmask[i][j] ) + vfield[i][j] * currmask[i][j];
	  count = count + (1-currmask[i][j]);
	}else{
	  newfield[i][j] = missval;
	  weight[i][j] = 0 ;
	}
      }
    copyvec(weight, currmask);
    for (size_t i = 0 ; i < ii ; i++ )
      for (size_t j = 0 ; j < jj ; j++ ){
	vfield[i][j] = infield[i][j] * inmask[i][j] + newfield[i][j] * (1 - inmask[i][j]);
      }
    std::cerr<< count << " fields changed \n";
    if (count < 1 ){
      size_t i= 0 , j= 0 , io=1 , jo = 1 ;
      newfield [i][j] = (vfield[i+io][j] + vfield[i][j+jo] + .5 * vfield[i+io][j+jo]) / 2.5;
      vfield[i][j] = infield[i][j] * inmask[i][j] + newfield[i][j] * (1 - inmask[i][j]);
      i= ii-1 ; j= 0 ;  io=-1 , jo = 1 ;
      newfield [i][j] = (vfield[i+io][j] + vfield[i][j+jo] + .5 * vfield[i+io][j+jo]) / 2.5;
      vfield[i][j] = infield[i][j] * inmask[i][j] + newfield[i][j] * (1 - inmask[i][j]);
      i= 0 ; j= jj-1 ;  io=1 , jo = -1 ;
      newfield [i][j] = (vfield[i+io][j] + vfield[i][j+jo] + .5 * vfield[i+io][j+jo]) / 2.5;
      vfield[i][j] = infield[i][j] * inmask[i][j] + newfield[i][j] * (1 - inmask[i][j]);
      i= ii-1 ; j= jj-1 ;  io=-1 , jo = -1 ;
      newfield [i][j] = (vfield[i+io][j] + vfield[i][j+jo] + .5 * vfield[i+io][j+jo]) / 2.5;
      vfield[i][j] = infield[i][j] * inmask[i][j] + newfield[i][j] * (1 - inmask[i][j]);
      return ;
    }

  } // k loop

}
