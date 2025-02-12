/******************************************************************************

	STATISTICS EQUATIONS
	--------------------

	Written by Marcelo C. Pereira, University of Campinas

	Copyright Marcelo C. Pereira
	Distributed under the GNU General Public License

	Equations that are not required for the model to run but may produce
	useful country- or sector-level statistics for analysis.

 ******************************************************************************/

/*========================= COUNTRY-LEVEL STATS ==============================*/

EQUATION( "Aee" )
/*
Overall energy efficiency
*/
v[1] = VS( GRANDPARENT, "En" );
RESULT( v[1] > 0 ? ( VS( SECSTAL2, "A1ee" ) * VS( CAPSECL2, "En1" ) +
					 VS( SECSTAL2, "A2ee" ) * VS( CONSECL2, "En2" ) ) / v[1] :
				   0 )


EQUATION( "Aef" )
/*
Overall environmental friendliness
*/
v[1] = VS( GRANDPARENT, "Em" );
RESULT( v[1] > 0 ? ( VS( SECSTAL2, "A1ef" ) * VS( CAPSECL2, "Em1" ) +
					 VS( SECSTAL2, "A2ef" ) * VS( CONSECL2, "Em2" ) ) / v[1] :
				   0 )


EQUATION( "CD" )
/*
Total credit demand
*/
RESULT( VS( SECSTAL2, "CD1" ) + VS( SECSTAL2, "CD2" ) )


EQUATION( "CDc" )
/*
Total credit demand constraint
*/
RESULT( VS( SECSTAL2, "CD1c" ) + VS( SECSTAL2, "CD2c" ) )


EQUATION( "CS" )
/*
Total credit supplied
*/
RESULT( VS( SECSTAL2, "CS1" ) + VS( SECSTAL2, "CS2" ) )


EQUATION( "DefGDP" )
/*
Government deficit on GDP ratio
*/
RESULT( VS( GRANDPARENT, "Def" ) / VS( GRANDPARENT, "GDPnom" ) )


EQUATION( "GDI" )
/*
Gross domestic income (nominal terms)
*/
RESULT( VS( LABSUPL2, "W" ) + VS( ENESECL2, "PiE" ) +
		VS( CAPSECL2, "Pi1" ) + VS( CONSECL2, "Pi2" ) +
		VS( FINSECL2, "PiB" ) + VS( GRANDPARENT, "Div" ) +
		VS( GRANDPARENT, "G" ) - VS( GRANDPARENT, "Tax" ) +
		VS( CAPSECL2, "PPI" ) * VS( CONSECL2, "SI" ) / VS( CONSECL2, "m2" ) )


EQUATION( "TaxCO2" )
/*
Government CO2 (carbon) tax income
*/
RESULT( ( VS( CAPSECL2, "Em1" ) + VS( CONSECL2, "Em2" ) ) *
		VS( GRANDPARENT, "trCO2" ) +
		VS( ENESECL2, "EmE" ) * VS( ENESECL2, "trCO2e" ) )


EQUATION( "dA" )
/*
Overall labor productivity growth rate
*/
v[1] = VLS( GRANDPARENT, "A", 1 );
RESULT( v[1] > 0 ? VS( GRANDPARENT, "A" ) / v[1] - 1 : 0 )


/*============================== CLIMATE STATS ===============================*/

EQUATION( "CO2a" )
/*
CO2 concentration in atmosphere in PPM
*/
RESULT( VS( CLIMATL2, "Ca" ) / PPMCO2GTC )


EQUATION( "EmGDP" )
/*
CO2 emissions to GDP ratio
*/
RESULT( VS( GRANDPARENT, "Em" ) / VS( GRANDPARENT, "GDPreal" ) )


EQUATION( "dEm" )
/*
Overall CO2 emissions growth rate
*/
v[1] = VLS( GRANDPARENT, "Em", 1 );
RESULT( v[1] > 0 ? VS( GRANDPARENT, "Em" ) / v[1] - 1 : 0 )


EQUATION( "shockAavg" )
/*
Expected disaster generating function shock size
*/
v[1] = VS( CLIMATL2, "a0" ) * ( 1 + log( VLS( CLIMATL2, "Tm", 1 ) /
										 VS( CLIMATL2, "Tm0" ) ) );
v[2] = VS( CLIMATL2, "b0" ) * VS( CLIMATL2, "sigma10y0" ) /
							  VLS( CLIMATL2, "sigma10y", 1 );
RESULT( VS( GRANDPARENT, "flagClimShocks" ) > 0 && T >= VS( CLIMATL2, "tA0" ) ?
		v[1] / ( v[1] + v[2] ) : 0 )


/*========================= FINANCIAL SECTOR STATS ===========================*/

EQUATION( "BadDebAcc" )
/*
Accumulated losses from bad debt in financial sector
*/
RESULT( CURRENT + VS( FINSECL2, "BadDeb" ) )


EQUATION( "Bda" )
/*
Firms financial fragility defined as the ratio between accumulated bad debt (loans
in default) and total bank assets (stock of loans)
*/
RESULT( SUMS( FINSECL2, "_Bda" ) )


EQUATION( "Bfail" )
/*
Rate of failing banks
*/
VS( FINSECL2, "NWb" );							// make sure it is updated
RESULT( COUNT_CNDS( FINSECL2, "Bank", "_Gbail", ">", 0 ) /
		COUNTS( FINSECL2, "Bank" ) )


EQUATION( "HHb" )
/*
Normalized Herfindahl-Hirschman index for financial sector
*/
i = COUNTS( FINSECL2, "Bank" );
RESULT( i > 1 ? max( 0, ( WHTAVES( FINSECL2, "_fB", "_fB" ) - 1.0 / i ) /
						( 1 - 1.0 / i ) ) : 1 )


EQUATION( "HPb" )
/*
Hymer-Pashigian index for financial sector
*/

v[0] = 0;										// index accumulator
CYCLES( FINSECL2, cur, "Bank" )
	v[0] += fabs( VLS( cur, "_fB", 1 ) - VS( cur, "_fB" ) );// sum share changes

RESULT( v[0] )


EQUATION( "TC" )
/*
Total credit supply provided by financial sector
Negative value (-1) means unlimited credit
*/

if ( VS( GRANDPARENT, "flagCreditRule" ) < 1 )
	END_EQUATION( -1 );

RESULT( SUMS( FINSECL2, "_TC" ) )


/*=========================== ENERGY SECTOR STATS ============================*/

EQUATION( "Ade" )
/*
Thermal efficiency of energy sector
*/
v[1] = SUMS( ENESECL2, "_Qde" );
RESULT( v[1] > 0 ? WHTAVES( ENESECL2, "_Ade", "_Qde" ) / v[1] : CURRENT )


EQUATION( "AtauDEavg" )
/*
Average thermal efficiency of a new dirty power plant in energy sector
*/
RESULT( AVES( ENESECL2, "_AtauDE" ) )


EQUATION( "CDe" )
/*
Total credit demand in energy sector
*/
RESULT( SUMS( ENESECL2, "_CDe" ) )


EQUATION( "CDeC" )
/*
Total credit demand constraint in energy sector
*/
RESULT( SUMS( ENESECL2, "_CDeC" ) )


EQUATION( "CSe" )
/*
Total credit supplied in energy sector
*/
RESULT( SUMS( ENESECL2, "_CSe" ) )


EQUATION( "DebEmax" )
/*
Total maximum prudential credit supplied in energy sector
*/
RESULT( SUMS( ENESECL2, "_DebEmax" ) )


EQUATION( "EnGDP" )
/*
Energy demand to GDP ratio
*/
RESULT( VS( GRANDPARENT, "En" ) / VS( GRANDPARENT, "GDPreal" ) )


EQUATION( "HHe" )
/*
Normalized Herfindahl-Hirschman index in energy sector
*/
i = COUNTS( ENESECL2, "FirmE" );
RESULT( i > 1 ? max( 0, ( WHTAVES( ENESECL2, "_fE", "_fE" ) - 1.0 / i ) /
						( 1 - 1.0 / i ) ) : 1 )


EQUATION( "HPe" )
/*
Hymer-Pashigian index in energy sector
*/

v[0] = 0;										// index accumulator
CYCLES( ENESECL2, cur, "FirmE" )
	v[0] += fabs( VLS( cur, "_fE", 1 ) - VS( cur, "_fE" ) );// sum share changes

RESULT( v[0] )


EQUATION( "ICtauGEavg" )
/*
Average unit installation cost of a new green power plant in energy sector
*/
RESULT( AVES( ENESECL2, "_ICtauGE" ) )


EQUATION( "RDe" )
/*
R&D expenditure of energy sector
*/
RESULT( SUMS( ENESECL2, "_RDe" )  )


EQUATION( "RSe" )
/*
Power plant (planned) scrapping rate of energy sector
*/
v[1] = SUMLS( ENESECL2, "_Ke", 1 );
RESULT( T > 1 && v[1] > 0 ? ( SUMS( ENESECL2, "_SIdeD" ) +
							  SUMS( ENESECL2, "_SIgeD" ) ) / v[1] : 0 )


EQUATION( "ageEavg" )
/*
Average age of firms in energy sector
*/
RESULT( T - AVES( ENESECL2, "_tEent" ) )


EQUATION( "dEmE" )
/*
CO2 emissions growth rate of energy sector
*/
v[1] = VLS( ENESECL2, "EmE", 1 );
RESULT( v[1] > 0 ? VS( ENESECL2, "EmE" ) / v[1] - 1 : 0 )


EQUATION( "dEn" )
/*
Overall energy demand growth rate
*/
v[1] = VLS( GRANDPARENT, "En", 1 );
RESULT( v[1] > 0 ? VS( GRANDPARENT, "En" ) / v[1] - 1 : 0 )


EQUATION( "emTauDEavg" )
/*
Average emissions of a new dirty energy power plant in energy sector
*/
RESULT( AVES( ENESECL2, "_emTauDE" ) )


EQUATION( "innDE" )
/*
Rate of firms successfully innovating in dirty energy
*/
RESULT( SUMS( ENESECL2, "_innDE" ) / VS( ENESECL2, "Fe" ) )


EQUATION( "innGE" )
/*
Rate of firms successfully innovating in green energy
*/
RESULT( SUMS( ENESECL2, "_innGE" ) / VS( ENESECL2, "Fe" ) )


EQUATION( "muEavg" )
/*
Weighted average markup in energy sector
*/
RESULT( WHTAVES( ENESECL2, "_muE", "_fE" ) )


EQUATION( "fGE" )
/*
Market share of green energy power plants in energy sector
*/
v[1] = VS( ENESECL2, "Qe" );
RESULT( v[1] > 0 ? SUMS( ENESECL2, "_Qge" ) / v[1] : 0 )


EQUATION( "fKge" )
/*
Share of green energy power plants in installed generation capacity
*/
v[1] = VS( ENESECL2, "Kge" );
RESULT( v[1] > 0 ? v[1] / ( v[1] + VS( ENESECL2, "Kde" ) ) : 0 )


/*======================= CAPITAL-GOOD SECTOR STATS ==========================*/

EQUATION( "A1ee" )
/*
Energy efficiency of capital-good sector
*/
RESULT( WHTAVES( CAPSECL2, "_BtauEE", "_f1" ) )


EQUATION( "A1ef" )
/*
Environmental friendliness of capital-good sector
*/
RESULT( WHTAVES( CAPSECL2, "_BtauEF", "_f1" ) )


EQUATION( "AtauAvg" )
/*
Average labor productivity of machines supplied by capital-good sector
*/
RESULT( AVES( CAPSECL2, "_AtauLP" ) )


EQUATION( "BtauAvg" )
/*
Average labor productivity of machines produced by capital-good sector
*/
RESULT( AVES( CAPSECL2, "_BtauLP" ) )


EQUATION( "CD1" )
/*
Total credit demand of firms in capital-good sector
*/
RESULT( SUMS( CAPSECL2, "_CD1" ) )


EQUATION( "CD1c" )
/*
Total credit demand constraint of firms in capital-good sector
*/
RESULT( SUMS( CAPSECL2, "_CD1c" ) )


EQUATION( "CS1" )
/*
Total credit supplied to firms in capital-good sector
*/
RESULT( SUMS( CAPSECL2, "_CS1" ) )


EQUATION( "Deb1max" )
/*
Total maximum prudential credit supplied to firms in capital-good sector
*/
RESULT( SUMS( CAPSECL2, "_Deb1max" ) )


EQUATION( "HCavg" )
/*
Number of historical clients of capital-good firms
*/
RESULT( AVES( CAPSECL2, "_HC" ) )


EQUATION( "HH1" )
/*
Normalized Herfindahl-Hirschman index for capital-good sector
*/
i = COUNTS( CAPSECL2, "Firm1" );
RESULT( i > 1 ? max( 0, ( WHTAVES( CAPSECL2, "_f1", "_f1" ) - 1.0 / i ) /
						( 1 - 1.0 / i ) ) : 1 )


EQUATION( "HP1" )
/*
Hymer-Pashigian index for capital-good sector
*/

v[0] = 0;										// index accumulator
CYCLES( CAPSECL2, cur, "Firm1" )
	v[0] += fabs( VLS( cur, "_f1", 1 ) - VS( cur, "_f1" ) );// sum share changes

RESULT( v[0] )


EQUATION( "NCavg" )
/*
Number of new clients of capital-good firms
*/
RESULT( AVES( CAPSECL2, "_NC" ) )


EQUATION( "RD" )
/*
R&D expenditure of capital-good sector
*/
RESULT( SUMS( CAPSECL2, "_RD" ) )


EQUATION( "age1avg" )
/*
Average age of firms in capital-good sector
*/
RESULT( T - AVES( CAPSECL2, "_t1ent" ) )


/*======================= CONSUMER-GOOD SECTOR STATS =========================*/

EQUATION( "A2ee" )
/*
Energy efficiency of consumption-good sector
*/
RESULT( WHTAVES( CONSECL2, "_A2ee", "_f2" ) )


EQUATION( "A2ef" )
/*
Environmental friendliness of consumption-good sector
*/
RESULT( WHTAVES( CONSECL2, "_A2ef", "_f2" ) )


EQUATION( "A2sd" )
/*
Standard deviation of machine-level log labor productivity of firms in
consumption-good sector
*/

v[1] = VS( CONSECL2, "A2" );					// average productivity
if ( v[1] <= 0 )
	END_EQUATION( 0 );							// probably no production yet

v[1] = log( v[1] + 1 );							// average log productivity

i = 0;											// valid cases count
v[0] = 0;										// square difference accumulator
CYCLES( CONSECL2, cur, "Firm2" )
{
	v[2] = VS( cur, "_A2" );
	if ( is_finite( v[2] ) && v[2] > 0 )
	{
		v[0] += pow( log( v[2] + 1 ) - v[1], 2 );
		++i;
	}
}

RESULT( i > 0 ? sqrt( v[0] / i ) : 0 )


EQUATION( "CD2" )
/*
Total credit demand of firms in consumption-good sector
*/
RESULT( SUMS( CONSECL2, "_CD2" ) )


EQUATION( "CD2c" )
/*
Total credit demand constraint of firms in consumption-good sector
*/
RESULT( SUMS( CONSECL2, "_CD2c" ) )


EQUATION( "CS2" )
/*
Total credit supplied to firms in consumption-good sector
*/
RESULT( SUMS( CONSECL2, "_CS2" ) )


EQUATION( "Deb2max" )
/*
Total maximum prudential credit supplied to firms in consumption-good sector
*/
RESULT( SUMS( CONSECL2, "_Deb2max" ) )


EQUATION( "EId" )
/*
Total desired expansion investment in consumption-good sector
*/
RESULT( SUMS( CONSECL2, "_EId" ) )


EQUATION( "HH2" )
/*
Normalized Herfindahl-Hirschman index for consumption-good sector
*/
i = COUNTS( CONSECL2, "Firm2" );
RESULT( i > 1 ? max( 0, ( WHTAVES( CONSECL2, "_f2", "_f2" ) - 1.0 / i ) /
						( 1 - 1.0 / i ) ) : 1 )


EQUATION( "HP2" )
/*
Hymer-Pashigian index for consumption-good sector
*/

v[0] = 0;										// index accumulator
CYCLES( CONSECL2, cur, "Firm2" )
	v[0] += fabs( VLS( cur, "_f2", 1 ) - VS( cur, "_f2" ) );// sum share changes

RESULT( v[0] )


EQUATION( "L2larg" )
/*
Number of workers of largest firm in consumption-good sector
*/
RESULT( MAXS( CONSECL2, "_L2" ) )


EQUATION( "RS2" )
/*
Machine (planned) scrapping rate in consumption-good sector
*/
v[1] = VLS( CONSECL2, "K", 1 );
RESULT( T > 1 && v[1] > 0 ? SUMS( CONSECL2, "_RS2" ) /
		( v[1] / VS( CONSECL2, "m2" ) ) : 0 )


EQUATION( "SId" )
/*
Total desired substitution investment in consumption-good sector
*/
RESULT( SUMS( CONSECL2, "_SId" ) )


EQUATION( "age2avg" )
/*
Average age of firms in consumption-good sector
*/
RESULT( T - AVES( CONSECL2, "_t2ent" ) )


EQUATION( "dN" )
/*
Change in total inventories (real terms)
*/
RESULT( VS( CONSECL2, "N" ) - VLS( CONSECL2, "N", 1 ) )


EQUATION( "mu2avg" )
/*
Weighted average mark-up of consumption-good sector
*/
RESULT( WHTAVES( CONSECL2, "_mu2", "_f2" ) )


EQUATION( "nBrochAvg" )
/*
Average number of machine brochures available to firms in consumer-good sector
*/

v[0] = 0;
CYCLES( CONSECL2, cur, "Firm2" )
	v[0] += COUNTS( cur, "Broch");

RESULT( v[0] / VS( CONSECL2, "F2" ) )


/*============================= LABOR STATS ==================================*/

EQUATION( "V" )
/*
Effective vacancy rate (unfilled positions over total labor supply)
*/
RESULT( T > 1 ? min( ( VS( CAPSECL2, "JO1" ) + VS( CONSECL2, "JO2" ) ) /
					   VS( LABSUPL2, "Ls" ), 1 ) : 0 )


EQUATION( "dw" )
/*
Nominal average wage growth rate
*/
RESULT( log( VS( LABSUPL2, "w" ) ) - log( VLS( LABSUPL2, "w", 1 ) ) )


/*============================ AGENT-LEVEL STATS =============================*/

EQUATION( "_Ade" )
/*
Thermal efficiency of energy producer
*/
v[1] = SUM( "__Qde" );
RESULT( v[1] > 0 ? WHTAVE( "__Ade", "__Qde" ) / v[1] : CURRENT )


EQUATION( "_A2e" )
/*
Machine-level effective productivity of firm in consumption-good sector
*/
i = V( "_L2" );
RESULT( i > 0 ? V( "_Q2e" ) / i : CURRENT )


EQUATION( "_RS2" )
/*
Number of machines to scrap of firm in consumption-good sector
*/

v[0] = 0;
CYCLE( cur, "Vint" )
	v[0] += abs( VS( cur, "__RSvint" ) );

RESULT( v[0] )


/*============================= DUMMY EQUATIONS ==============================*/

EQUATION_DUMMY( "exitEfail", "" )
/*
Rate of exiting bankrupt firms in energy sector
Updated in 'entryEexit'
*/

EQUATION_DUMMY( "exit1fail", "" )
/*
Rate of exiting bankrupt firms in capital-good sector
Updated in 'entry1exit'
*/

EQUATION_DUMMY( "exit2fail", "" )
/*
Rate of exiting bankrupt firms in consumption-good sector
Updated in 'entry2exit'
*/
