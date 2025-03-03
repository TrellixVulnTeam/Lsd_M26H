/******************************************************************************

	BANK OBJECTS EQUATIONS
	----------------------

	Written by Marcelo C. Pereira, University of Campinas

	Copyright Marcelo C. Pereira
	Distributed under the GNU General Public License

	Equations that are specific to the bank objects in the K+S LSD model
	are coded below.

 ******************************************************************************/

/*============================== KEY EQUATIONS ===============================*/

EQUATION( "_Bda" )
/*
Customer firms financial fragility defined as the ratio between accumulated
bad debt (loans in default) and total bank assets
*/

// losses with bad debt, discarding negative losses (proceedings)
v[1] = VL( "_BadDebE", 1 ) + VL( "_BadDeb1", 1 ) + VL( "_BadDeb1", 1 );

v[2] = VL( "_Loans", 1 ) + VL( "_BondsB", 1 ) +	// bank assets
	   VL( "_Res", 1 ) + VL( "_ExRes", 1 );

RESULT( v[2] > 0 ? v[1] / v[2] : 0 )


EQUATION( "_DivB" )
/*
Dividends to pay by bank
*/
RESULT( max( VS( PARENT, "dB" ) * ( V( "_PiB" ) - V( "_TaxB" ) ), 0 ) )


EQUATION( "_ExRes" )
/*
Bank excess reserves (free cash)
Bank try to minimize excess reserves (not paying interest) trading bonds
Updates '_BondsB', '_BD'
*/

// compute initial free cash in period, before adjustments
v[0] = CURRENT + ( V( "_PiB" ) - V( "_TaxB" ) )	// + net profit
	   - VL( "_DivB", 1 )						// - distributed dividends
	   - ( V( "_Res" ) - VL( "_Res", 1 ) );		// - increased reserves

// account existing sovereign bonds maturing
v[1] = VS( PARENT, "thetaBonds" );				// maturing rate of bonds
v[2] = VL( "_BondsB" , 1 );						// bonds hold by bank
v[3] = v[2] / v[1];								// bonds maturing in period
v[2] -= v[3];									// remaining bonds
v[0] += v[3];									// add matured bonds income

// repay exiting loans from central bank (liquidity lines)
v[4] = VL( "_LoansCB", 1 );						// liquidity loans from c. bank
if ( v[0] > 0 && v[4] > 0 )						// repay loans if possible
{
	INCR( "_LoansCB", v[0] > v[4] ? - v[4] : - v[0] );// repay what is possible
	v[0] = max( v[0] - v[4], 0 );				// remaining free cash
}

// trade bonds: sell if free cash negative or try to buy otherwise
if ( v[0] <= 0 )								// need to top up total reserves?
{
	if ( - v[0] > v[2] )						// need larger than stock?
		v[5] = - v[2];							// sell all bonds
	else
		v[5] = v[0];							// sell just required amount
}
else											// try to buy bonds
{
	v[6] = V( "_fB" ) * ( VS( PARENT, "BS" ) +	// available bond share
						  VLS( PARENT, "BondsCB", 1 ) / v[1] );

	if ( v[0] > v[6] )							// bonds are rationed?
		v[5] = v[6];							// buy what is available
	else
		v[5] = v[0];							// buy using all excess reserves
}

WRITE( "_BD", v[5] );
INCR( "_BondsB", v[5] - v[3] );
v[0] -= v[5];									// update free cash after trade

// request loan from central bank if still illiquid (liquidity line)
if ( v[0] < 0 )									// negative free cash
{
	INCR( "_LoansCB", - v[0] );					// get loan from central bank
	v[0] = 0;									// no excess reserves
}

RESULT( v[0] )


EQUATION( "_NWb" )
/*
Bank net worth (book value)
Also updates '_Gbail', '_ExRes', '_LoansCB'
*/

// net worth as assets minus liabilities (deposits) ('_ExRes' before '_BondsB'!)
v[0] = V( "_Loans" ) + V( "_Res" ) + V( "_ExRes" ) + V( "_BondsB" ) -
	   V( "_Depo" ) - V( "_LoansCB" );

// government rescue bank when net worth is negative (Basel-like rule)
if ( v[0] < 0 && VS( GRANDPARENT, "flagCreditRule" ) == 2 )
{
	// use fraction of weighted average bank market to adjust net worth
	v[1] = max( VL( "_fB", 1 ), V( "_fD" ) );	// lower bounded market share

	// remove effect of this bank net worth in the bank total average
	if ( v[1] < 1 )
		v[2] = ( VLS( PARENT, "NWb", 1 ) - CURRENT ) / ( 1 - v[1] );
	else
		v[2] = 0;								// monopoly, use capital rule

	// desired bank new capital after bailout
	v[3] = VS( PARENT, "PhiB" ) * v[1] * v[2];

	// ensure respecting the capital adequacy rate
	v[4] = max( v[3], VS( PARENT, "tauB" ) * V( "_Loans" ) );

	v[5] = - v[0] + v[4];						// government bailout
	v[0] = v[4];								// assets after bailout

	INCR( "_ExRes", v[5] );						// bailout enter as free cash
	WRITE( "_Gbail", v[5] );					// register bailout
}
else
	WRITE( "_Gbail", 0 );						// no bailout

RESULT( v[0] )


EQUATION( "_TC" )
/*
Total credit supply provided by bank to firms.
Negative value (-1) means unlimited credit.
*/

k = VS( GRANDPARENT, "flagCreditRule" );		// credit limit & bail-out rule

if ( k == 1 )									// deposits multiplier rule?
	v[0] = VL( "_Depo", 1 ) / VS( PARENT, "tauB" );// 1/tauB = bank multiplier
else
	if ( k == 2 )								// Basel-like credit rule?
	{
		h = VS( PARENT, "mPerB" );
		for ( v[1] = i = 0; i < h; ++i )
			v[1] += VL( "_Bda", i ) / h;		// bank fragility moving average

		v[0] = VL( "_NWb", 1 ) / ( VS( PARENT, "tauB" ) *
								 ( 1 + VS( PARENT, "betaB" ) * v[1] ) );
	}
	else
		v[0] = -1;								// no-limit rule

RESULT( v[0] )


EQUATION( "_TCeFree" )
/*
Minimum bank total credit supply to firms in energy sector
Updated in 'update_debtE' support function
*/

if ( VS( GRANDPARENT, "flagCreditRule" ) > 0 )
{
	v[1] = VL( "_CD1b", 1 );					// credit demand from sector 1
	v[2] = VL( "_CD2b", 1 );					// credit demand from sector 2
	v[3] = VL( "_CDeB", 1 );					// credit demand from energy sec.

	if ( v[1] + v[2] + v[3] > 0 )
		v[4] = v[3] / ( v[1] + v[2] + v[3] );	// allocate according demand share
	else
		v[4] = 0.333;							// no demand, just do 33/33/33%

	v[0] = v[4] * max( 0, V( "_TC" ) - VL( "_Loans", 1 ) );// free cash to lend
}
else
	v[0] = -1;									// no limit

RESULT( v[0] )


EQUATION( "_TC1free" )
/*
Minimum bank total credit supply to firms in capital-good sector
Updated in 'update_debt1' support function
*/

if ( VS( GRANDPARENT, "flagCreditRule" ) > 0 )
{
	v[1] = VL( "_CD1b", 1 );					// credit demand from sector 1
	v[2] = VL( "_CD2b", 1 );					// credit demand from sector 2
	v[3] = VL( "_CDeB", 1 );					// credit demand from energy sec.

	if ( v[1] + v[2] + v[3] > 0 )
		v[4] = v[1] / ( v[1] + v[2] + v[3] );	// allocate according demand share
	else
		v[4] = 0.333;							// no demand, just do 33/33/33%

	v[0] = v[4] * max( 0, V( "_TC" ) - VL( "_Loans", 1 ) );// free cash to lend
}
else
	v[0] = -1;									// no limit

RESULT( v[0] )


EQUATION( "_TC2free" )
/*
Maximum bank total credit supply to firms in consumption-good sector
*/

if ( VS( GRANDPARENT, "flagCreditRule" ) > 0 )
{
	v[1] = VL( "_CD1b", 1 );					// credit demand from sector 1
	v[2] = VL( "_CD2b", 1 );					// credit demand from sector 2
	v[3] = VL( "_CDeB", 1 );					// credit demand from energy sec.

	if ( v[1] + v[2] + v[3] > 0 )
		v[4] = v[2] / ( v[1] + v[2] + v[3] );	// allocate according demand share
	else
		v[4] = 0.333;							// no demand, just do 33/33/33%

	v[0] = v[4] * max( 0, V( "_TC" ) - VL( "_Loans", 1 ) );// free cash to lend
}
else
	v[0] = -1;									// no limit

RESULT( v[0] )


EQUATION( "_iB" )
/*
Bank interest income from loans
*/

v[1] = VLS( PARENT, "rDeb", 1 );				// interest on debt
v[2] = VS( PARENT, "kConst" );					// interest scaling

// compute the firm-specific interest income
v[0] = 0;										// interest accumulator
CYCLE( cur, "CliE" )							// energy sector
{
	j = VLS( SHOOKS( cur ), "_qcE", 1 );		// firm credit class
	v[3] = VLS( SHOOKS( cur ), "_DebE", 1 );	// firm debt
	v[0] += v[3] * v[1] * ( 1 + ( j - 1 ) * v[2] );// interest received
}

CYCLE( cur, "Cli1" )							// sector 1
{
	j = VLS( SHOOKS( cur ), "_qc1", 1 );		// firm credit class
	v[3] = VLS( SHOOKS( cur ), "_Deb1", 1 );	// firm debt
	v[0] += v[3] * v[1] * ( 1 + ( j - 1 ) * v[2] );// interest received
}

CYCLE( cur, "Cli2" )							// sector 2
{
	j = VLS( SHOOKS( cur ), "_qc2", 1 );		// firm credit class
	v[3] = VLS( SHOOKS( cur ), "_Deb2", 1 );	// firm debt
	v[0] += v[3] * v[1] * ( 1 + ( j - 1 ) * v[2] );// interest received
}

RESULT( v[0] )


/*============================ SUPPORT EQUATIONS =============================*/

EQUATION( "_BadDebE" )
/*
Bank bad debt (defaults) from energy sector
Just reset once per period, updated in 'entryEexit'
*/
RESULT( 0 )


EQUATION( "_BadDeb1" )
/*
Bank bad debt (defaults) from capital-good sector
Just reset once per period, updated in 'entry1exit'
*/
RESULT( 0 )


EQUATION( "_BadDeb2" )
/*
Bank bad debt (defaults) from consumption-good sector
Just reset once per period, updated in 'entry2exit'
*/
RESULT( 0 )


EQUATION( "_CDeB" )
/*
Bank credit demand from energy sector
*/

VS( ENESECL2, "TaxE" );							// ensure all credit demanded

v[0] = 0;
CYCLE( cur, "CliE" )							// energy sector credit demand
	v[0] += VS( SHOOKS( cur ), "_CDe" );

RESULT( v[0] )


EQUATION( "_CD1b" )
/*
Bank credit demand from capital-good sector
*/

VS( CAPSECL2, "Tax1" );							// ensure all credit demanded

v[0] = 0;
CYCLE( cur, "Cli1" )							// sector 1 credit demand
	v[0] += VS( SHOOKS( cur ), "_CD1" );

RESULT( v[0] )


EQUATION( "_CD2b" )
/*
Bank credit demand from consumption-good sector
*/

VS( CONSECL2, "Tax2" );							// ensure all credit demanded

v[0] = 0;
CYCLE( cur, "Cli2" )							// sector 2 credit demand
	v[0] += VS( SHOOKS( cur ), "_CD2" );

RESULT( v[0] )


EQUATION( "_Cl" )
/*
Number of bank clients
*/
RESULT( COUNT( "CliE" ) + COUNT( "Cli1" ) + COUNT( "Cli2" ) )


EQUATION( "_Depo" )
/*
Bank deposits
Net deposits from exiting and entering firms in period not considered
*/

VS( GRANDPARENT, "Sav" );						// ensure savings are calculated
V( "_Loans" );									// ensure all transactions done

v[0] = V( "_fD" ) * VS( GRANDPARENT, "SavAcc" );// workers deposits

CYCLE( cur, "CliE" )							// energy sector deposits
	v[0] += max( VS( SHOOKS( cur ), "_NWe" ), 0 );

CYCLE( cur, "Cli1" )							// sector 1 deposits
	v[0] += max( VS( SHOOKS( cur ), "_NW1" ), 0 );

CYCLE( cur, "Cli2" )							// sector 2 deposits
	v[0] += max( VS( SHOOKS( cur ), "_NW2" ), 0 );

RESULT( max( v[0], 0 ) )


EQUATION( "_Loans" )
/*
Bank loans (non-defaulted)
Net loans to exiting and entering firms in period not considered
*/

VS( ENESECL2, "TaxE" );							// ensure transactions are done
VS( CAPSECL2, "Tax1" );
VS( CONSECL2, "Tax2" );

v[0] = 0;										// accumulator

CYCLE( cur, "CliE" )							// energy sector debt
	v[0] += VS( SHOOKS( cur ), "_DebE" );

CYCLE( cur, "Cli1" )							// sector 1 debt
	v[0] += VS( SHOOKS( cur ), "_Deb1" );

CYCLE( cur, "Cli2" )							// sector 2 debt
	v[0] += VS( SHOOKS( cur ), "_Deb2" );

RESULT( v[0] )


EQUATION( "_PiB" )
/*
Bank gross profits (losses) before dividends/taxes
*/
RESULT( V( "_iB" ) - V( "_iDb" ) +
		VLS( PARENT, "rRes", 1 ) * VL( "_Res", 1 ) +
		VLS( PARENT, "rBonds", 1 ) * VL( "_BondsB", 1 ) -
		VLS( PARENT, "r", 1 ) * VL( "_LoansCB", 1 ) -
		VL( "_BadDebE", 1 ) - VL( "_BadDeb1", 1 ) - VL( "_BadDeb2", 1 ) )


EQUATION( "_Res" )
/*
Bank required reserves hold at the central bank
*/
RESULT( VS( PARENT, "tauB" ) * V( "_Depo" ) )


EQUATION( "_TaxB" )
/*
Tax paid by bank in consumption-good sector
*/
RESULT( max( V( "_PiB" ) * VS( GRANDPARENT, "tr" ), 0 ) )


EQUATION( "_fB" )
/*
Bank effective market share (in number of customers)
*/
RESULT( V( "_Cl" ) / VS( PARENT, "Cl" ) )


EQUATION( "_iDb" )
/*
Bank interest payments from deposits
*/

v[0] = V( "_fD" ) * VLS( GRANDPARENT, "SavAcc", 1 );// workers deposits

CYCLE( cur, "CliE" )							// energy sector deposits
	v[0] += max( VLS( SHOOKS( cur ), "_NWe", 1 ), 0 );

CYCLE( cur, "Cli1" )							// sector 1 deposits
	v[0] += max( VLS( SHOOKS( cur ), "_NW1", 1 ), 0 );

CYCLE( cur, "Cli2" )							// sector 2 deposits
	v[0] += max( VLS( SHOOKS( cur ), "_NW2", 1 ), 0 );

RESULT( VLS( PARENT, "rD", 1 ) * v[0] )


/*========================== SUPPORT LSD FUNCTIONS ===========================*/

EQUATION( "_cScores" )
/*
Define the credit class for bank's clients
*/

firmRank firmData;
vector < firmRank > rankE, rank1, rank2;

CYCLE( cur, "CliE" )							// rank energy sector clients
{
	v[1] = VLS( SHOOKS( cur ), "_NWe", 1 );		// net worth
	v[2] = VLS( SHOOKS( cur ), "_Se", 1 );		// sales
	firmData.NWtoS = ( v[1] > 0 && v[2] > 0 ) ? v[1] / v[2] : 0;
	firmData.firm = SHOOKS( cur );
	rankE.push_back( firmData );
}

CYCLE( cur, "Cli1" )							// rank sector 1 clients
{
	v[1] = VLS( SHOOKS( cur ), "_NW1", 1 );		// net worth
	v[2] = VLS( SHOOKS( cur ), "_S1", 1 );		// sales
	firmData.NWtoS = ( v[1] > 0 && v[2] > 0 ) ? v[1] / v[2] : 0;
	firmData.firm = SHOOKS( cur );
	rank1.push_back( firmData );
}

CYCLE( cur, "Cli2" )							// rank sector 2 clients
{
	v[1] = VLS( SHOOKS( cur ), "_NW2", 1 );		// net worth
	v[2] = VLS( SHOOKS( cur ), "_S2", 1 );		// sales
	firmData.NWtoS = ( v[1] > 0 && v[2] > 0 ) ? v[1] / v[2] : 0;
	firmData.firm = SHOOKS( cur );
	rank2.push_back( firmData );
}

// order bank rankings in descending order (higher ratios first)
sort( rankE.begin( ), rankE.end( ), rank_desc_NWtoS );
sort( rank1.begin( ), rank1.end( ), rank_desc_NWtoS );
sort( rank2.begin( ), rank2.end( ), rank_desc_NWtoS );
k = rankE.size( );								// # clients in energy sector
i = rank1.size( );								// # clients in sector 1
j = rank2.size( );								// # clients in sector 2

// attribute the credit class of clients in both sectors
h = 0;
for ( auto cli : rankE )
{
	WRITES( cli.firm, "_qcE",
			h < k * 0.25 ? 1 : h < k * 0.5 ? 2 : h < k * 0.75 ? 3 : 4 );
	++h;
}

h = 0;
for ( auto cli : rank1 )
{
	WRITES( cli.firm, "_qc1",
			h < i * 0.25 ? 1 : h < i * 0.5 ? 2 : h < i * 0.75 ? 3 : 4 );
	++h;
}

h = 0;
for ( auto cli : rank2 )
{
	WRITES( cli.firm, "_qc2",
			h < j * 0.25 ? 1 : h < j * 0.5 ? 2 : h < j * 0.75 ? 3 : 4 );
	++h;
}

RESULT( k + i + j )


/*============================= DUMMY EQUATIONS ==============================*/

EQUATION_DUMMY( "_BD", "_ExRes" )
/*
Sovereign bonds demand by bank
Updated in '_ExRes'
*/

EQUATION_DUMMY( "_BondsB", "" )
/*
Sovereign bonds stock hold by bank
Updated in '_ExRes'
*/

EQUATION_DUMMY( "_Gbail", "_NWb" )
/*
Government bailout funds to bank
Updated in '_NWb'
*/

EQUATION_DUMMY( "_LoansCB", "_ExRes" )
/*
Liquidity loans from central bank to bank
Updated in '_ExRes', '_NWb'
*/
