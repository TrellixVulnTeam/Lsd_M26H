#******************************************************************
#
# ----------------- K+S aggregates box-plots --------------------
#
#   Written by Marcelo C. Pereira, University of Campinas
#
#   Copyright Marcelo C. Pereira
#   Distributed under the GNU General Public License
#
#   Script used by KS-aggregates.R
#   This script should not be executed directly.
#
#******************************************************************

# remove warnings for support functions
# !diagnostics suppress = log0, colSds, na.remove, rec.stats, textplot


box_plots <- function( mcData, mcStat, nExp, nSize, TmaxStat, TmaskStat,
                       warmUpStat, nTstat, legends, legendList, sDigits,
                       bPlotCoef, bPlotNotc, folder, repName ) {

  # ======= COMPARISON OF EXPERIMENTS =======

  maxStats <- 99
  statsTb <- statsBp <- array( dim = c( maxStats, 5, nExp ) )
  n <- array( dim = c( maxStats, nExp ) )
  conf <- array( dim = c( maxStats, 2, nExp ) )
  data <- out <- array( list( ), dim = c( maxStats, nExp ) )
  temp <- matrix( nrow = TmaxStat, ncol = nSize )
  names <- units <- list( )

  # function to add whiskerplots to the list of comparisons
  addStat <- function( stat, exper, x, tit, ylab ) {

    if( stat > maxStats ) {
      warning( "Insufficient space for stats, discarding" )
      return( )
    }

    data[[ stat, exper ]] <<- x
    names[[ stat ]] <<- tit
    units[[ stat ]] <<- ylab
    statsTb[ stat, , exper ] <<- c( mean( x ), median( x ), sd( x ), min( x ), max( x ) )
    bPlotStats <- boxplot.stats( x, coef = bPlotCoef )
    statsBp[ stat, , exper ] <<- bPlotStats$stats
    n[ stat, exper ] <<- bPlotStats$n
    conf[ stat, , exper ] <<- bPlotStats$conf
    out[[ stat, exper ]] <<- bPlotStats$out

    return( stat + 1 )
  }

  # ---- Collect the data for each experiment ----

  for( k in 1 : nExp ) {
    stat <- 1

    # Calculates periodic GDP growth rates for each MC series
    for( j in 1 : nSize )
      for( i in TmaskStat )
        if( i == 1 ) {
          temp[ i - warmUpStat, j ] <- 0
        } else {
          temp[ i - warmUpStat, j ] <- ( log0( mcData[[ k ]][ i, "GDPreal", j ] ) -
                                         log0( mcData[[ k ]][ i - 1, "GDPreal", j ] ) )
        }

    # Remove +/-infinite values and replace by +/-1
    temp[ is.infinite( temp ) ] <- sign( temp[ is.infinite( temp ) ] )
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "GDP growth",
                     ylab = "Average real GDP growth rate" )

    stat <- addStat( stat, k, colSds( temp, na.rm = TRUE ),
                     tit = "Volatility of GDP growth",
                     ylab = "Standard deviation of real GDP growth rate" )

    # Mark crises periods (= 1) when GDP growth is less than -3%
    for( j in 1 : nSize ) {
      for( i in TmaskStat ) {
        if( i == 1 ){
          temp[ i - warmUpStat, j ] <- 0
        } else {
          if( log0( mcData[[ k ]][ i, "GDPreal", j ] ) -
              log0( mcData[[ k ]][ i - 1, "GDPreal", j ] ) < -0.03 ){
            temp[ i - warmUpStat, j ] <- 1
          } else {
            temp[ i - warmUpStat, j ] <- 0
          }
        }
      }
    }

    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Likelihood of GDP crises",
                     ylab = "Probability of GDP reductions over 3%" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "Q2u", ],
                                        na.rm = TRUE ),
                     tit = "Capacity utilization",
                     ylab = "Average capacity utilization rate in Consumption-good sector" )

    temp <- mcData[[ k ]][ TmaskStat, "dCPI", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Inflation",
                     ylab = "Consumer prices index average growth rate" )

    temp <- mcData[[ k ]][ TmaskStat, "Tax", ] / mcData[[ k ]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Government income",
                     ylab = "Government tax income over GDP" )

    temp <- mcData[[ k ]][ TmaskStat, "G", ] / mcData[[ k ]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Government expenditure",
                     ylab = "Total government expenditure over GDP" )

    temp <- mcData[[ k ]][ TmaskStat, "Gbail", ] / mcData[[k]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Government bank bail-out expenditure",
                     ylab = "Government costs to bail-out banks over GDP" )

    temp <- mcData[[ k ]][ TmaskStat, "Def", ] / mcData[[ k ]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Government deficit",
                     ylab = "Government deficit over GDP" )

    temp <- mcData[[ k ]][ TmaskStat, "Deb", ] / mcData[[ k ]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Government debt",
                     ylab = "Government debt over GDP" )

    temp <- mcData[[ k ]][ TmaskStat, "TC", ] / mcData[[ k ]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Bank credit supply",
                     ylab = "Total bank credit available over GDP" )

    temp <- mcData[[ k ]][ TmaskStat, "Loans", ] / mcData[[ k ]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Firm loans",
                     ylab = "Firm debt stock over GDP" )

    temp <- mcData[[ k ]][ TmaskStat, "BadDeb", ] / mcData[[ k ]][ TmaskStat, "GDPnom", ]
    temp[ ! is.finite( temp ) ] <- NA
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Bad debt",
                     ylab = "Total bank bad debt over GDP" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "U", ],
                                        na.rm = TRUE ),
                     tit = "Unemployment",
                     ylab = "Unemployment rate" )

    # Format full employment MC series (1 = full employment, 0 = otherwise)
    for( j in 1 : nSize )
      for( i in TmaskStat )
        if( mcData[[ k ]][ i, "U", j ] == 0 )
          temp[ i - warmUpStat, j ] <- 1
        else
          temp[ i - warmUpStat, j ] <- 0
    stat <- addStat( stat, k, colMeans( temp, na.rm = TRUE ),
                     tit = "Full employment frequency",
                     ylab = "Probability of zero unemployment rate" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "V", ],
                                        na.rm = TRUE ),
                     tit = "Vacancy",
                     ylab = "Vacancy rate" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "wReal", ],
                                        na.rm = TRUE ),
                     tit = "Real wage",
                     ylab = "Log real wage" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "inn", ],
                                        na.rm = TRUE ),
                     tit = "Innovation",
                     ylab = "Share of innovating firms in capital-good sector" )


    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "imi", ],
                                        na.rm = TRUE ),
                     tit = "Imitation",
                     ylab = "Share of imitating firms in capital-good sector" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "dA", ],
                                        na.rm = TRUE ),
                     tit = "Productivity growth",
                     ylab = "Labor productivity growth rate" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "HH2", ],
                                        na.rm = TRUE ),
                     tit = "Market concentration",
                     ylab = "Standardized Herfindahl-Hirschman index in Consumption-good sector" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "mu2avg", ],
                                        na.rm = TRUE ),
                     tit = "Mark-up",
                     ylab = "Weighted average mark-up rate in Consumption-good sector" )

    stat <- addStat( stat, k, colMeans( mcData[[ k ]][ TmaskStat, "entry1exit", ] +
                                          mcData[[ k ]][ TmaskStat, "entry2exit", ],
                                        na.rm = TRUE ),
                     tit = "Net entry of firms",
                     ylab = "Number of net entrant firms in all sectors" )
  }

  # remove unused stats space
  numStats <- stat - 1
  statsTb <- statsTb[ - ( stat : maxStats ), , , drop = FALSE ]
  statsBp <- statsBp[ - ( stat : maxStats ), , , drop = FALSE ]
  n <- n[ - ( stat : maxStats ), , drop = FALSE ]
  conf <- conf[ - ( stat : maxStats ), , , drop = FALSE ]
  out <- out[ - ( stat : maxStats ), , drop = FALSE ]
  rm( temp )


  # ---- Build experiments statistics table and performance comparison chart ----

  perf.comp <- statsTb[ , 1, 1 ]
  perf.names <- c( "Baseline[1]" )

  # Print whisker plots for each statistics

  for( stat in 1 : numStats ) {

    # find max/mins for all experiments
    lowLim <- Inf
    upLim <- -Inf
    for( k in 1 : nExp ) {
      if( conf[ stat, 1, k ] < lowLim )
        lowLim <- conf[ stat, 1, k ]
      if( conf[ stat, 2, k ] > upLim )
        upLim <- conf[ stat, 2, k ]
    }
    upLim <- upLim + ( upLim - lowLim )
    lowLim <- lowLim - ( upLim - lowLim )

    # build the outliers vectors
    outVal <- outGrp <- vector( "numeric" )
    for( k in 1 : nExp ) {
      if( length( out[[ stat, k ]] ) == 0 )
        next
      outliers <- vector( "numeric" )
      for( i in 1 : length( out[[ stat, k ]] ) ) {
        if( out[[ stat, k ]][ i ] < upLim &&
            out[[ stat, k ]][ i ] > lowLim )
          outliers <- append( outliers, out[[ stat, k ]][ i ] )
      }
      if( length( outliers ) > 0 ) {
        outVal <- append( outVal, outliers )
        outGrp <- append( outGrp, rep( k, length( outliers ) ) )
      }
    }

    if( nExp > 1 )
      listBp <- list( stats = statsBp[ stat, , ], n = n[ stat, ], conf = conf[ stat, , ],
                      out = outVal, group = outGrp, names = legends )
    else
      listBp <- list( stats = matrix( statsBp[ stat, , ] ),
                      n = matrix( n[ stat, ] ), conf = matrix( conf[ stat, , ] ),
                      out = outVal, group = outGrp, names = legends )

    title <- names[[ stat ]]
    subTitle <- as.expression(bquote(paste(
      "( bar: median / box: 2nd-3rd quartile / whiskers: max-min / points: outliers / MC runs = ",
      .( nSize ), " / period = ", .( warmUpStat + 1 ), " - ", .( nTstat ), " )" ) ) )
    tryCatch( bxp( listBp, range = bPlotCoef, notch = bPlotNotc, main = title,
                   sub = subTitle, ylab = units[[ stat ]] ),
              error = function( e ) {
                warning( "In boxplot (bxp): problem while plotting: ", title, "\n\n" )
                textplot( paste( "Plot for <", title, "> failed." ) )
              } )
  }

  if( mcStat == "mean" ) {
    scol <- 1
    slab <- "Avg"
    tlab <- "t-test"
  } else {
    scol <- 2
    slab <- "Med"
    tlab <- "U-test"
  }

  table.stats <- statsTb[ , c( scol, 3, 4, 5 ), 1 ]
  table.names <- c( paste0( slab, "[1]" ), "SD[1]", "Min[1]", "Max[1]" )
  perf.comp <- statsTb[ , 1, 1 ]
  perf.names <- c( "Baseline[1]" )

  if( nExp > 1 ){

    # Create 2D stats table and performance comparison table

    for( k in 2 : nExp ){

      # Stats table
      table.stats <- cbind( table.stats, statsTb[ , c( scol, 3, 4, 5 ), k ] )
      table.names <- cbind( table.names, c( paste0( slab, "[", k, "]" ),
                                            paste0( "SD[", k, "]" ),
                                            paste0( "Min[", k, "]" ),
                                            paste0( "Max[", k, "]" ) ) )

      # Performance comparison table
      if( mcStat == "mean" ) {
        perf.comp <- cbind( perf.comp, statsTb[ , 1, k ] / statsTb[ , 1, 1 ] )

        # t-test
        t <- ( statsTb[ , 1, k ] - statsTb[ , 1, 1 ] ) /
          sqrt( ( statsTb[ , 2, k ] ^ 2 + statsTb[ , 2, 1 ] ^ 2 ) / nSize )
        df <- floor( ( ( statsTb[ , 2, k ] ^ 2 + statsTb[ , 2, 1 ] ^ 2 ) / nSize ) ^ 2 /
                       ( ( 1 / ( nSize - 1 ) ) * ( ( statsTb[ , 2, k ] ^ 2 / nSize ) ^ 2 +
                                                     ( statsTb[ , 2, 1 ] ^ 2 / nSize ) ^ 2 ) ) )
        pval <- 2 * pt( - abs ( t ), df )

      } else {
        perf.comp <- cbind( perf.comp, statsTb[ , 2, k ] / statsTb[ , 2, 1 ] )

        # U-test (Mann-Whitney-Wilcoxon)
        pval <- rep( NA, numStats )
        for( stat in 1 : numStats ) {
          pval[ stat ] <- suppressWarnings( wilcox.test( data[[ stat, k ]],
                                                         data[[ stat, 1 ]],
                                                         digits.rank = 7 )$p.value )
        }
      }

      perf.comp <- cbind( perf.comp, pval )
      perf.names <- cbind( perf.names, t( c( paste0( "Ratio[", k, "]" ),
                                             paste0( "p-val[", k, "]" ) ) ) )
    }
  }

  # Print experiments table
  colnames( table.stats ) <- table.names
  rownames( table.stats ) <- names

  textplot( formatC( table.stats, digits = sDigits, format = "g" ), cmar = 1 )
  title <- paste( "Monte Carlo descriptive statistics ( all experiments )" )
  subTitle <- paste( "( numbers in brackets indicate the experiment number / MC runs =",
                     nSize, "/ period =", warmUpStat + 1, "-", nTstat, ")" )
  title( main = title, sub = subTitle )
  mtext( legendList, side = 1, line = -2, outer = TRUE )

  if( nExp > 1 ) {

    # Experiments performance comparison table

    colnames( perf.comp ) <- perf.names
    rownames( perf.comp ) <- names

    textplot( formatC( perf.comp, digits = sDigits, format = "g" ), cmar = 1 )
    title <- paste( "Performance comparison ( all experiments )" )
    subTitle <- paste(
      "( experiment number in brackets /", tlab,
      "H0: no difference with baseline / MC runs =",
      nSize, "/ period =", warmUpStat + 1, "-", nTstat, ")" )
    title( main = title, sub = subTitle )
    mtext( legendList, side = 1, line = -2, outer = TRUE )
  }
}
