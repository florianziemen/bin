
blocksums:blocksums.cc
	g++ -o blocksums blocksums.cc $(shell /sw/jessie-x64/netcdf_cxx-4.2.1-gccsys/bin/ncxx4-config --cflags --libs)  $(shell nc-config --cflags --libs)
