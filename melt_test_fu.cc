#include <iostream>
#include <cmath>
using namespace std;

int BoundaryFluxSaltTempW3(double dz0, double Tice, 
			   double press,
			   double salt, double temp,
			   double &Tb, double &Sb,
			   double &dHdt, double &FluxS,
			   double &FluxT);

int BoundaryFluxSaltTemp_flo(double dz0, double Tice, 
			   double press,
			   double salt, double temp,
			   double &Tb, double &Sb,
			   double &dHdt, double &FluxS,
			   double &FluxT);

int main (){

  double Tb, Sb, dHdt, FluxS, FluxT;

  double dz0, Tice, press, salt, temp;

  //  cerr<<"Tb << '\t' <<  Sb << '\t' <<  dHdt << '\t' <<  FluxS << '\t' <<  FluxT" << '\n' ; 

  while (cin >> dz0 >> Tice >> press >> salt >> temp){
    //    BoundaryFluxSaltTempW3(dz0, Tice, press, salt, temp, Tb, Sb, dHdt, FluxS, FluxT);
    //    cout<<"C "<<Tb << '\t' <<  Sb << '\t' <<  dHdt*365.25*86400 << '\t' <<  FluxS << '\t' <<  FluxT << '\n' ; 
    //    cerr<<"C "<< dHdt*365.25*86400 << '\n' ; 
    BoundaryFluxSaltTemp_flo(dz0, Tice, press, salt, temp, Tb, Sb, dHdt, FluxS, FluxT);
    //    cout<<Tb << '\t' <<  Sb << '\t' <<  dHdt*365.25*86400 << '\t' <<  FluxS << '\t' <<  FluxT << '\n'; 
    //    cout << temp - Tb  +  5.73e-2* (salt-Sb) << '\t' << dHdt*365.25*86400 << '\n'; 
    //cerr<<"F "<< dHdt*365.25*86400 << '\n' ; 
  }


}
int BoundaryFluxSaltTempW3(double dz0, double Tice, 
						   double press,
						   double salt, double temp,
						   double &Tb, double &Sb,
						   double &dHdt, double &FluxS,
						   double &FluxT)
{
  double L       = 3.34e5, 
    kappa   = 1.54e-6,
    rho_ice = 910.,
    rho_oce = 1028.,
    gammaT  = 1e-4,
    gammaS  = 5.05e-7,
    cp_ice  = 2009.,
    cp_oce  = 4170.,
    grav_const= 9.81,
    a = -5.73e-2,
    b = 9.39e-2, // IN CELSIUS! 
    c = -7.53e-8;
  

  double eta1, eta2, eta3, eta4, eta5 ,eta6, TmpVar;
  double Sb1, Sb2;

  // Initialization 
  eta1 = rho_oce * cp_oce * gammaT;
  eta2 = rho_oce * L      * gammaS;
  eta3 = rho_ice * cp_ice * kappa/dz0;

  eta4 = b - c*press;
  Tb   =   a * salt + b + c*press;
  //FreezeOceanTemp(salt,press); // !!! Degree Celsius

      
  // Tice: temperature of ice above the ice-ocean boundary, which
  //       is not the boundary temperature.
  eta5 = (eta1* temp-eta1*eta4 + eta2 + eta3*Tice - eta3*eta4)
    /( a*(eta1+eta3) );

  eta6 = eta2*salt /( a*(eta1+eta3) ) ;

  //Sb   = eta5*0.5 +- sqrt( eta5*eta5*0.25 - eta6 );
  TmpVar = eta5*eta5*0.25 - eta6;
  if ( TmpVar > 0.0 ) {
    TmpVar = sqrt(TmpVar);
    Sb1  = eta5*0.5 - TmpVar ;
    Sb2  = eta5*0.5 + TmpVar ;
    if ( Sb1 < 0 ) {
      Sb = Sb2;
    } else {
      Sb = max(Sb1, Sb2);
    }
  } else{
    Sb = 5.;
  }

#ifdef DEBUG_BoundaryFluxSaltTempW
  cout << "Tb = " << Tb  << "C =" << setw(8) << Tb+DegC2DegK  <<"K "
       << "   press = "  << setw(8)  << press
       << " Sb = " << setw(6) << Sb
       << "  TempOce=" << setw(6) << temp 
       << "  SaltOce=" << setw(6) << salt << "\n";
#endif

  dHdt  = ( Sb-salt ) *rho_oce/rho_ice* gammaS;
  FluxS = ( Sb-salt ) *rho_oce*         gammaS;
  FluxT = ( Tb-temp ) *rho_oce*cp_oce*  gammaT;

  return 0;
}



int BoundaryFluxSaltTemp_flo(double dz0, double Tice, 
						   double press,
						   double salt, double T_oce,
						   double &Tb, double &Sb,
						   double &dHdt, double &FluxS,
						   double &FluxT)
{
    const bool debug = false ;
  double L       = 3.34e5, 
    kappa   = 1.54e-6,
    rho_ice = 910.,
    rho_oce = 1028.,
    gammaT  = 1e-4,
    gammaS  = 5.05e-7,
    cp_ice  = 2009.,
    cp_oce  = 4170.,
    grav_const= 9.81,
    a = -5.75e-2,
    b = 9.01e-2, // IN CELSIUS! 
    c = -7.61e-8;
  const  double Qsi = 0. , Sice = 0 ;
  const double alpha = b + c * press;
  //    if (debug )  std::cerr << "alpha = " << alpha << "\n"; 
  const double Ks = - rho_oce * gammaS ;
    if (debug )  std::cerr << "Ks = " << Ks << "\n"; 
  const double k_oce = - rho_oce * cp_oce * gammaT; 
    if (debug )  std::cerr << "k_oce = " << k_oce << "\n"; 
    //    dz0 = max (dz0 , 10.) ;
  const double k_ice = - rho_ice * cp_ice * kappa / dz0 ; 
  
   if (debug )  std::cerr << "k_ice = " << k_ice << "\n"; 
  
  
  
  const double psi = ( a * (Qsi + Ks * salt  ) + alpha * Ks ) *  (k_oce + k_ice )  - (k_oce * T_oce + k_ice *  Tice ) * Ks ;
   if (debug )  std::cerr << "psi = " << psi << '\n'; 
  const double phi =  ( Sice * a + alpha ) *  ( k_oce + k_ice ) - k_oce * T_oce - k_ice * Tice + Ks *  L ;
    if (debug )  std::cerr << "phi / 2 L [ ... /a ]  = " << phi / 2 / L * 3e7 << '\n'; 
    if (debug )  std::cerr << "phi / 2 L  = " << phi / 2 / L << '\n'; 
  
  if (  - psi / L + phi*phi / 4 / L / L  < 0 )
    {  std:: cerr<< "NEGATIVE INPUT FOR SQRT";
      std::cerr <<   (  - psi / L + phi*phi / 4 / L / L  )<< '\n';}
  const double Mp = phi / 2 / L + sqrt( - psi / L + phi*phi / 4 / L / L ); 
  const double Mm = phi / 2 / L  - sqrt( - psi / L + phi*phi / 4 / L / L ); 
  
  const double  vp = Mp / rho_ice; 
  const double vm = Mm / rho_ice ; 
  if (debug) std::cerr << "T_oce << _vp_ << vm <<\n"; 
  if (debug) std::cerr <<T_oce <<'\t' << vp * 3e7 << '\t' << vm * 3e7 << '\n' ; 

  Sb = ( Qsi  - Mp * Sice + Ks * salt ) / ( Ks - Mp ) ; 
  if (debug) cerr<< "Salinity " << Sb << "\n";
  Tb = a * Sb + alpha ; 
  if (debug) cerr<< "Temp " << Tb  << "\n";
  dHdt = -vp ;
  FluxS = Qsi - Mp * (Sice - Sb) ;
  if (debug) cerr<< "FluxS " << FluxS  << "\n";
  FluxT = k_oce * ( a * Sb + alpha - T_oce) ;
  if (debug) cerr<< "FluxT " << FluxT << "\n";
  cout << Sb << '\t' << Tb << '\t' <<  vp * 86400 * 365.25 << "\n";
  return 0 ;
}
