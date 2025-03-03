#******************************************************************
#
# --------- K+S consumer-goods firm pooled analysis -------------
#
#   Written by Marcelo C. Pereira, University of Campinas
#
#   Copyright Marcelo C. Pereira
#   Distributed under the GNU General Public License
#
#   The default configuration assumes that the supplied LSD
#   simulation configurations (basename Sim):
#     R/data/Sim1.lsd
#     R/data/Sim2.lsd
#   are executed before this script is used.
#
#   To execute the simulations, (1) open LSD Model Manager (LMM),
#   (2) in LSD Model Browser, open the model which contains this
#   script (double click), (3) in LMM, compile and run the model
#   (menu Model>Compile and Run), (4) in LSD Model Browser, load
#   the desired configuration (menu File>Load), (5) execute the
#   configuration (menu Run>Run or Run> Parallel Run), accepting
#   the defaults (parallel run is optional but typically saves
#   significant execution time).
#
#   IMPORTANT: this script assumes the R working directory is set
#   to the R subfolder where this script file is stored. This can
#   be done automatically in RStudio if a project is created at
#   this subfolder, or using the command setwd(). The "folder"
#   variable below must always point to a (relative) subfolder
#   of the R working directory.
#
#******************************************************************

#******************************************************************
#
# ------------ Read Monte Carlo experiment files ----------------
#
#******************************************************************

folder    <- "data"                 # data files folder
baseName  <- "Sim"                  # data files base name (same as .lsd file)
nExp      <- 2                      # number of experiments
iniDrop   <- 0                      # initial time steps to drop (0=none)
nKeep     <- -1                     # number of time steps to keep (-1=all)

expVal <- c( "Baseline", "Monopolistic power" )   # case parameter values

# Firm-level variables to use
firmVar <- c( "_A2", "_Q2e" )
addFirmVar <- c( "normO2", "lnormO2", "lnormO2match", "lnormO2matchLag", "normA2",
                 "normO2grow", "lnormO2grow", "normA2grow", "growth2" )
sector <- "( Consumption-goods sector )"


# ==== Process LSD result files ====

# load support packages and functions
source( "KS-support-functions.R" )

# remove warnings for saved data
# !diagnostics suppress = pool, nSize, nTsteps, nFirms

# ---- Read data files ----

# Function to read one experiment data (to be parallelized)
readExp <- function( exper ) {
  if( nExp > 1 )
    myFiles <- list.files.lsd( folder, paste0( baseName, exper ) )
  else
    myFiles <- list.files.lsd( folder, baseName )

  cat( "Data files: ", myFiles, "\n" )

  # Read data from text files and format it as 4D array with labels
  mc <- read.4d.lsd( myFiles, col.names = firmVar, skip = iniDrop,
                     nrows= nKeep, nnodes = 1 )

  # Get dimensions information
  nTsteps <- dim( mc )[ 1 ]              # number of time steps
  nFirms <- dim( mc )[ 3 ]               # number of firms (instances)
  nSize  <- dim( mc )[ 4 ]               # Monte Carlo sample size

  # Add new variables names (not in LSD files)
  nFirmVarNew <- length( addFirmVar )   # number of new variables to add
  newFirmVar <- name.nice.lsd( c( dimnames( mc )[[ 2 ]], addFirmVar ) )
  nVar <- length( newFirmVar )          # number of variables (firm-level)

  # ------ Add new variables to data set ------

  # Increase array size to allow for new variables
  mc <- abind( mc, array( as.numeric( NA ),
                          dim = c( nTsteps, nFirmVarNew,
                                   nFirms, nSize ) ),
               along = 2, use.first.dimnames = TRUE )
  dimnames( mc )[[ 2 ]] <- newFirmVar

  # Compute values for new variables, preventing infinite values
  for( m in 1 : nSize )                 # for all MC samples (files)
    for( i in 1 : nTsteps ){            # all time steps
      # clean size vector
      Q2e <- as.vector( mc[ i, "Q2e", , m ] )
      Q2e <- Q2e[ is.finite( Q2e ) ]
      Q2e <- Q2e[ Q2e >= 1 ]
      mean.Q2e <- mean( Q2e, na.rm = TRUE )
      mean.lsize2 <- mean( log( Q2e ), na.rm = TRUE )

      A2 <- as.vector( mc[ i, "A2", , m ] )
      A2 <- A2[ is.finite( A2 ) ]
      A2 <- A2[ A2 >= 1 ]
      mean.A2 <- mean( A2, na.rm = TRUE )

      if( ! is.finite( mean.Q2e ) ) mean.Q2e <- 0
      if( ! is.finite( mean.lsize2 ) ) mean.lsize2 <- 0
      if( ! is.finite( mean.A2 ) ) mean.A2 <- 0

      for( j in 1 : nFirms ){            # and all firms (instances)

        # Take care of entrants' first period and other data problems to avoid artifacts
        if( is.na( mc[ i, "Q2e", j, m ] ) || mc[ i, "Q2e", j, m ] < 1 ||
            is.na( mc[ i, "A2", j, m ] ) || mc[ i, "A2", j, m ] < 1 ) {
          mc[ i, , j, m ] <- rep( NA, nVar )
          next
        }

        # Normalization of key variables using the period average size
        if( mean.Q2e != 0 )
          mc[ i, "normO2", j, m ] <- mc[ i, "Q2e", j, m ] / mean.Q2e
        if( mean.lsize2 != 0 )
          mc[ i, "lnormO2", j, m ] <- log( mc[ i, "Q2e", j, m ] ) - mean.lsize2
        if( mean.A2 != 0 )
          mc[ i, "normA2", j, m ] <- mc[ i, "A2", j, m ] / mean.A2

        # Growth rates and deltas are calculated only from 2nd period and for non-entrant firms
        if( i > 1 ) {
          if( is.finite( mc[ i - 1, "Q2e", j, m ] ) ) {

            # Size, normalized sales and productivity growth
            mc[ i, "growth2", j, m ] <- log( mc[ i, "Q2e", j, m ] ) -
                                                log( mc[ i - 1, "Q2e", j, m ] )
            mc[ i, "normO2grow", j, m ] <- log( mc[ i, "normO2", j, m ] ) -
                                                log( mc[ i - 1, "normO2", j, m ] )
            mc[ i, "normA2grow", j, m ] <- log( mc[ i, "normA2", j, m ] ) -
                                                log( mc[ i - 1, "normA2", j, m ] )

            if( ! is.finite( mc[ i, "normO2grow", j, m ] ) )
              mc[ i, "normO2grow", j, m ] <- NA
            if( ! is.finite( mc[ i, "normA2grow", j, m ] ) )
              mc[ i, "normA2grow", j, m ] <- NA
          }

          if( is.finite( mc[ i, "lnormO2", j, m ] ) &&
              is.finite( mc[ i - 1, "lnormO2", j, m ] ) ) {

            mc[ i, "lnormO2match", j, m ] <- mc[ i, "lnormO2", j, m ]
            mc[ i, "lnormO2matchLag", j, m ] <- mc[ i - 1, "lnormO2", j, m ]
            mc[ i, "lnormO2grow", j, m ] <- mc[ i, "lnormO2", j, m ] -
                                                 mc[ i - 1, "lnormO2", j, m ]

            if( ! is.finite( mc[ i, "lnormO2grow", j, m ] ) ) {
              mc[ i, "lnormO2grow", j, m ] <- NA
              mc[ i, "lnormO2match", j, m ] <- NA
              mc[ i, "lnormO2matchLag", j, m ] <- NA
            }
          }
        }
      }
    }

  # ---- Reorganize and save data ----

  # Create "flatter" 3D arrray, appending firms from different MC runs in sequence
  pool <- array( as.numeric( NA ), dim = c( nTsteps, nVar, nFirms * nSize ),
                 dimnames = list( c( ( iniDrop + 1 ) : ( iniDrop + nTsteps ) ),
                                  newFirmVar, c( 1 : ( nFirms * nSize ) ) ) )
  l <- rep( 1, nVar )                   # absolute variable instance (firm) counter

  for( m in 1 : nSize )                 # MC sample
    for( j in 1 : nVar )                # for all variables
      for( i in 1 : nFirms ){           # for all firms
        pool[ , j, l[ j ]] <- mc[ , j, i, m ]
        l[ j ] <- l[ j ] + 1
      }

  # Save temporary results to disk to save memory
  tmpFile <- paste0( folder, "/", baseName, exper, "_firm2_pool.Rdata" )
  save( pool, nTsteps, nVar, nSize, nFirms, file = tmpFile )

  return( tmpFile )
}

# load each experiment serially
tmpFiles <- lapply( 1 : nExp, readExp )

invisible( gc( verbose = FALSE ) )


#******************************************************************
#
# --------------------- Plot statistics -------------------------
#
#******************************************************************

# ====== User parameters ======

CI        <- 0.95   # desired confidence interval
nBins     <- 15     # number of bins to use in histograms
outLim    <- 0.10   # outlier percentile (0=don't remove outliers)
limOutl   <- 0.10   # quantile extreme limits (0=none)
warmUp    <- 200    # number of "warm-up" runs
nTstat    <- -1     # last period to consider for statistics (-1=all)

repName   <- ""     # report files base name (if "" same baseName)
sDigits   <- 4      # significant digits in tables
plotRows  <- 1      # number of plots per row in a page
plotCols  <- 1      # number of plots per column in a page
plotW     <- 10     # plot window width
plotH     <- 7      # plot window height

# Colors assigned to each experiment's lines in graphics
colors <- c( "black", "blue", "red", "orange", "green", "brown" )

# Line types assigned to each experiment
lTypes <- c( "solid", "solid", "solid", "solid", "solid", "solid" )

# Point types assigned to each experiment
pTypes <- c( 4, 4, 4, 4, 4, 4 )


# ====== External support functions & definitions ======

# remove warnings for support functions
# !diagnostics suppress = logNA, log0, t.test0, se, bkfilter, adf.test, colSds
# !diagnostics suppress = plot_lognorm, plot_norm, plot_laplace, plot_lin
# !diagnostics suppress = fit_subbotin, comp_stats, comp_MC_stats, size_bins
# !diagnostics suppress = remove_outliers_table, all.NA, textplot, nCores

# ====== Support stuff ======

if( repName == "" )
  repName <- baseName

# Generate fancy labels & build labels list legend
legends <- vector( )
legendList <- "Experiments: "
for( k in 1 : nExp ) {
  if( is.na( expVal[ k ]) || expVal[ k ] == "" )
    legends[ k ] <- paste( "Case", k )
  else
    legends[ k ] <- expVal[ k ]
  if( k != 1 )
    legendList <- paste0( legendList, ",  " )
  legendList <- paste0( legendList, "[", k, "] ", legends[ k ] )
}

# load data from first experiment
load( tmpFiles[[ 1 ]] )

# Number of periods to show in graphics and use in statistics
if( nTstat < 1 || nTstat > nTsteps || nTstat <= warmUp )
  nTstat <- nTsteps
TmaskStat <- ( warmUp + 1 ) : nTstat


#
# ====== Do pooled analysis ======
#

# Open PDF plot file for output
pdf( paste0( folder, "/", repName, "_firm2_pool.pdf" ),
     width = plotW, height = plotH )
par( mfrow = c ( plotRows, plotCols ) )             # define plots per page

szData <- oData <- Adata <- gData <- ngData <- ngAdata <- exData <- bins <- list( )

# run over all experiments individually
for( k in 1 : nExp ){

  # load pooled data from temporary files (first already loaded)
  if( k > 1 )
    load( tmpFiles[[ k ]] )

  file.remove( tmpFiles[[ k ]] )      # delete temporary file

  #
  # ------ Create data & statistics vectors ------
  #

  szData[[ k ]] <- as.vector( pool[ TmaskStat, "Q2e", ] )
  oData[[ k ]] <- as.vector( logNA( pool[ TmaskStat, "normO2", ] ) )
  Adata[[ k ]] <- as.vector( logNA( pool[ TmaskStat, "normA2", ] ) )
  gData[[ k ]] <- as.vector( pool[ TmaskStat, "growth2", ] )
  ngData[[ k ]] <- as.vector( pool[ TmaskStat, "normO2grow", ] )
  ngAdata[[ k ]] <- as.vector( pool[ TmaskStat, "normA2grow", ] )
  exData[[ k ]] <- as.vector( as.numeric( is.na( pool[ TmaskStat, "growth2", ] ) ) )

  # remove NAs
  szData[[ k ]] <- szData[[ k ]][ ! is.na( szData[[ k ]] ) ]
  oData[[ k ]] <- oData[[ k ]][ ! is.na( oData[[ k ]] ) ]
  Adata[[ k ]] <- Adata[[ k ]][ ! is.na( Adata[[ k ]] ) ]
  gData[[ k ]] <- gData[[ k ]][ ! is.na( gData[[ k ]] ) ]
  ngData[[ k ]] <- ngData[[ k ]][ ! is.na( ngData[[ k ]] ) ]
  ngAdata[[ k ]] <- ngAdata[[ k ]][ ! is.na( ngAdata[[ k ]] ) ]
  exData[[ k ]] <- exData[[ k ]][ ! is.na( exData[[ k ]] ) ]

  # compute each variable statistics
  stats <- lapply( list( oData[[ k ]], Adata[[ k ]], gData[[ k ]], ngData[[ k ]],
                         ngAdata[[ k ]], exData[[ k ]] ), comp_stats )

  o <- stats[[ 1 ]]
  A <- stats[[ 2 ]]
  g <- stats[[ 3 ]]
  ng <- stats[[ 4 ]]
  ngA <- stats[[ 5 ]]
  ex <- stats[[ 6 ]]

  # prepare data for Gibrat and scaling variance plots
  bins[[ k ]] <- size_bins( as.vector( pool[ TmaskStat, "lnormO2match", ] ),
                            as.vector( pool[ TmaskStat, "lnormO2matchLag", ] ),
                            as.vector( pool[ TmaskStat, "lnormO2grow", ] ),
                            bins = 2 * nBins, outLim = outLim )

  #
  # ------ Build statistics table ------
  #

  key.stats <- matrix( c( o$avg, A$avg,g$avg,
                          ng$avg, ngA$avg, ex$avg,

                          o$sd / sqrt( nSize ), A$sd / sqrt( nSize ),
                          g$sd / sqrt( nSize ), ng$sd / sqrt( nSize ),
                          ngA$sd / sqrt( nSize ), ex$sd / sqrt( nSize ),

                          o$sd, A$sd, g$sd,
                          ng$sd, ngA$sd, ex$sd,

                          o$subbo$b, A$subbo$b, g$subbo$b,
                          ng$subbo$b, ngA$subbo$b, ex$subbo$b,

                          o$subbo$a, A$subbo$a, g$subbo$a,
                          ng$subbo$a, ngA$subbo$a, ex$subbo$a,

                          o$subbo$m, A$subbo$m, g$subbo$m,
                          ng$subbo$m, ngA$subbo$m, ex$subbo$m,

                          o$jb$statistic, A$jb$statistic, g$jb$statistic,
                          ng$jb$statistic, ngA$jb$statistic, ex$jb$statistic,

                          o$jb$p.value, A$jb$p.value, g$jb$p.value,
                          ng$jb$p.value, ngA$jb$p.value, ex$jb$p.value,

                          o$ll$statistic, A$ll$statistic, g$ll$statistic,
                          ng$ll$statistic, ngA$ll$statistic, ex$ll$statistic,

                          o$ll$p.value, A$ll$p.value, g$ll$p.value,
                          ng$ll$p.value, ngA$ll$p.value, ex$ll$p.value,

                          o$ad$statistic, A$ad$statistic, g$ad$statistic,
                          ng$ad$statistic, ngA$ad$statistic, ex$ad$statistic,

                          o$ad$p.value, A$ad$p.value, g$ad$p.value,
                          ng$ad$p.value, ngA$ad$p.value, ex$ad$p.value,

                          o$ac$t1, A$ac$t1, g$ac$t1,
                          ng$ac$t1, ngA$ac$t1, ex$ac$t1,

                          o$ac$t2, A$ac$t2, g$ac$t2,
                          ng$ac$t2, ngA$ac$t2, ex$ac$t2 ),

                       ncol = 6, byrow = TRUE )
  colnames( key.stats ) <- c( "N.Output(log)", "N.Prod.(log)", "Output Gr.",
                              "N.Output Gr.", "N.Prod.Gr.", "Exit Rate" )
  rownames( key.stats ) <- c( "average", " (s.e.)", " (s.d.)", "Subbotin b", " a", " m", "Jarque-Bera X2",
                              " (p-val.)", "Lilliefors D", " (p-val.)", "Anderson-Darling A", " (p-val.)",
                              "autocorr. t-1", "autocorr. t-2" )

  textplot( formatC( key.stats, digits = sDigits, format = "g" ), cmar = 1.0 )
  title <- paste( "Pooled firm-level statistics (", legends[ k ], ")" )
  subTitle <- paste( eval( bquote( paste0( "( Sample size = ", sum( nFirms ),
                                           " firms / Period = ", warmUp + 1,
                                           "-", nTstat, " )" ) ) ),
                    sector, sep ="\n" )
  title( main = title, sub = subTitle )

  # ------ Gibrat law test plot ------

  plot_lin( bins[[ k ]]$sLagAvg, bins[[ k ]]$s1avg,
            "log(normalized size of firms in t-1)",
            "log(normalized size of firms in t)",
            tit = paste( "Gibrat law (", legends[ k ], ")" ),
            subtit = sector, invleg = TRUE )

  # ------ Scaling variance plot ------

  plot_lin( bins[[ k ]]$s2avg, bins[[ k ]]$gSD,
            "log(normalized size of firms)",
            "log(standard deviation of growth rate)",
            tit = paste( "Scaling of variance of firm size (", legends[ k ], ")" ),
            subtit = sector )
}

#
# ====== Plot distributions ( overplots )  ======
#

# ------ Size and productivity  distributions ( binned density x log variable in level )  ------

plot_norm( oData, "log(normalized size)", "Binned density",
           "Pooled size (output) distribution ( all experiments )",
           sector, outLim, nBins, legends, colors, lTypes, pTypes )

plot_norm( Adata, "log(normalized productivity)", "Binned density",
           "Pooled productivity distribution ( all experiments )",
           sector, outLim, nBins, legends, colors, lTypes, pTypes )

# ------ Size distributions ( log size x rank )  ------

plot_lognorm( szData, "Size", "Rank",
              "Pooled size (output) distribution ( all experiments )",
              sector, outLim, nBins, legends, colors, lTypes )

# ------ Growth rate distributions ( binned density x log growth rate )  ------

plot_laplace( gData, "Size growth rate", "Binned density",
              "Pooled size (output) growth rate distribution ( all experiments )",
              sector, outLim, nBins, legends, colors, lTypes, pTypes )

plot_laplace( ngData, "Normalized size growth rate", "Binned density",
              "Pooled size (output) growth rate distribution ( all experiments )",
              sector, outLim, nBins, legends, colors, lTypes, pTypes )

plot_laplace( ngAdata, "Normalized productivity growth rate", "Binned density",
              "Pooled productivity growth rate distribution ( all experiments )",
              sector, outLim, nBins, legends, colors, lTypes, pTypes )


# Close PDF plot file
dev.off( )
