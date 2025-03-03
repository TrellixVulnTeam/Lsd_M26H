#******************************************************************
#
# ------ K+S consumer-goods firm Monte Carlo analysis -----------
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

expVal <- c( "Free entry", "Entry after exit" )   # case parameter values

# Firm-level variables to use
firmVar <- c( "_A2", "_Q2e" )
addFirmVar <- c( "growth2", "normO2", "normA2", "normO2grow", "normA2grow" )
sector <- "( Consumption-goods sector )"


# ==== Process LSD result files ====

# load support packages and functions
source( "KS-support-functions.R" )

# remove warnings for saved data
# !diagnostics suppress = mc, nSize, nTsteps, nFirms

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
                     nrows = nKeep, nnodes = 1 )

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

      A2 <- as.vector( mc[ i, "A2", , m ] )
      A2 <- A2[ is.finite( A2 ) ]
      A2 <- A2[ A2 >= 1 ]
      mean.A2 <- mean( A2, na.rm = TRUE )

      if( ! is.finite( mean.Q2e ) ) mean.Q2e <- 0
      if( ! is.finite( mean.A2 ) ) mean.A2 <- 0

      for( j in 1 : nFirms ){            # and all firms (instances)

        # Take care of entrants' first period and other data problems to avoid artifacts
        if( is.na( mc[ i, "Q2e", j, m ] ) || mc[ i, "Q2e", j, m ] < 1 ||
            is.na( mc[ i, "A2", j, m ] ) || mc[ i, "A2", j, m ] < 1 ||
            is.na( mc[ i, "Q2e", j, m ] ) ) {
          mc[ i, , j, m ] <- rep( NA, nVar )
          next
        }

        # Normalization of key variables using the period average size
        if( mean.Q2e != 0 )
          mc[ i, "normO2", j, m ] <- mc[ i, "Q2e", j, m ] / mean.Q2e
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
        }
      }
    }

  # Save temporary results to disk to save memory
  tmpFile <- paste0( folder, "/", baseName, exper, "_firm2_MC.Rdata" )
  save( mc, nTsteps, nVar, nSize, nFirms, file = tmpFile )

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
outLim    <- 0.10   # outlier percentile (0=don't remove outliers)
limOutl   <- 0.10   # quantile extreme limits (0=none)
warmUp    <- 200    # number of "warm-up" runs
nTstat    <- -1     # last period to consider for statistics (-1=all)
csBeg     <- 300    # beginning step for cross-section regressions
csEnd     <- 307    # last step for cross-section regressions

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
# !diagnostics suppress = remove_outliers_table, all.NA, textplot, npreg
# !diagnostics suppress = FHK_decomp, DN_decomp, plot_epanechnikov, nCores

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
if( csBeg < 1 || csBeg >= nTsteps || csBeg < warmUp )
  csBeg <- warmUp
if( csEnd < 1 || csEnd >= nTsteps || csEnd <= warmUp || csEnd <= csBeg )
  csEnd <- nTsteps - 1


# ====== Main code ======

# Open PDF plot file for output
pdf( paste0( folder, "/", repName, "_firm2_MC.pdf" ),
     width = plotW, height = plotH )
par( mfrow = c ( plotRows, plotCols ) )   # define plots per page

for( k in 1 : nExp ){             # do for each experiment

  # load pooled data from temporary files (first already loaded)
  if( k > 1 )
    load( tmpFiles[[ k ]] )

  file.remove( tmpFiles[[ k ]] )      # delete temporary file

  #
  # ------ Create MC statistics table ------
  #

  oMC <- AMC <- gMC <- ngMC <- ngAMC <- exMC <- list( )

  for( l in 1 : nSize ){          # for each MC run

    # ------ Update MC statistics lists ------

    oData <- logNA( mc[ TmaskStat, "Q2e", , l ] )
    Adata <- logNA( mc[ TmaskStat, "A2", , l ] )
    gData <- mc[ TmaskStat, "growth2", , l ]
    ngData <- mc[ TmaskStat, "normO2grow", , l ]
    ngAdata <- mc[ TmaskStat, "normA2grow", , l ]
    exData <- as.numeric( is.na( mc[ TmaskStat, "growth2", , l ] ) )

    # compute each variable statistics
    stats <- lapply( list( oData, Adata, gData, ngData, ngAdata, exData ),
                     comp_stats )

    oMC[[l]] <- stats[[ 1 ]]
    AMC[[l]] <- stats[[ 2 ]]
    gMC[[l]] <- stats[[ 3 ]]
    ngMC[[l]] <- stats[[ 4 ]]
    ngAMC[[l]] <- stats[[ 5 ]]
    exMC[[l]] <- stats[[ 6 ]]
  }

  # ------ Compute MC statistics vectors ------

  # compute each variable statistics
  stats <- lapply( list( oMC, AMC, gMC, ngMC, ngAMC, exMC ), comp_MC_stats )

  o <- stats[[ 1 ]]
  A <- stats[[ 2 ]]
  g <- stats[[ 3 ]]
  ng <- stats[[ 4 ]]
  ngA <- stats[[ 5 ]]
  ex <- stats[[ 6 ]]

  # ------ Build statistics table ------

  key.stats <- matrix( c( o$avg$avg, A$avg$avg, g$avg$avg,
                          ng$avg$avg, ngA$avg$avg, ex$avg$avg,

                          o$se$avg, A$se$avg, g$se$avg,
                          ng$se$avg, ngA$se$avg, ex$se$avg,

                          o$sd$avg, A$sd$avg, g$sd$avg,
                          ng$sd$avg, ngA$sd$avg, ex$sd$avg,

                          o$avg$subbo$b, A$avg$subbo$b, g$avg$subbo$b,
                          ng$avg$subbo$b, ngA$avg$subbo$b, ex$avg$subbo$b,

                          o$se$subbo$b, A$se$subbo$b, g$se$subbo$b,
                          ng$se$subbo$b, ngA$se$subbo$b, ex$se$subbo$b,

                          o$sd$subbo$b, A$sd$subbo$b, g$sd$subbo$b,
                          ng$sd$subbo$b, ngA$sd$subbo$b, ex$sd$subbo$b,

                          o$avg$subbo$a, A$avg$subbo$a, g$avg$subbo$a,
                          ng$avg$subbo$a, ngA$avg$subbo$a, ex$avg$subbo$a,

                          o$se$subbo$a, A$se$subbo$a, g$se$subbo$a,
                          ng$se$subbo$a, ngA$se$subbo$a, ex$se$subbo$a,

                          o$sd$subbo$a, A$sd$subbo$a, g$sd$subbo$a,
                          ng$sd$subbo$a, ngA$sd$subbo$a, ex$sd$subbo$a,

                          o$avg$subbo$m, A$avg$subbo$m, g$avg$subbo$m,
                          ng$avg$subbo$m, ngA$avg$subbo$m, ex$avg$subbo$m,

                          o$se$subbo$m, A$se$subbo$m, g$se$subbo$m,
                          ng$se$subbo$m, ngA$se$subbo$m, ex$se$subbo$m,

                          o$sd$subbo$m, A$sd$subbo$m, g$sd$subbo$m,
                          ng$sd$subbo$m, ngA$sd$subbo$m, ex$sd$subbo$m,

                          o$avg$ac$t1, A$avg$ac$t1, g$avg$ac$t1,
                          ng$avg$ac$t1, ngA$avg$ac$t1, ex$avg$ac$t1,

                          o$se$ac$t1, A$se$ac$t1, g$se$ac$t1,
                          ng$se$ac$t1, ngA$se$ac$t1, ex$se$ac$t1,

                          o$sd$ac$t1, A$sd$ac$t1, g$sd$ac$t1,
                          ng$sd$ac$t1, ngA$sd$ac$t1, ex$sd$ac$t1,

                          o$avg$ac$t2, A$avg$ac$t2, g$avg$ac$t2,
                          ng$avg$ac$t2, ngA$avg$ac$t2, ex$avg$ac$t2,

                          o$se$ac$t2, A$se$ac$t2, g$se$ac$t2,
                          ng$se$ac$t2, ngA$se$ac$t2, ex$se$ac$t2,

                          o$sd$ac$t2, A$sd$ac$t2, g$sd$ac$t2,
                          ng$sd$ac$t2, ngA$sd$ac$t2, ex$sd$ac$t2 ),

                       ncol = 6, byrow = TRUE )
  colnames( key.stats ) <- c( "Output(log)", "Prod.(log)", "Output Gr.", "N.Output Gr.",
                              "N.Prod.Gr.", "Exit Rate" )
  rownames( key.stats ) <- c( "average", " (s.e.)", " (s.d.)", "Subbotin b",
                              " (s.e.)", " (s.d.)", "Subbotin a", " (s.e.)",
                              " (s.d.)", "Subbotin m", " (s.e.)", " (s.d.)",
                              "autocorr. t-1", " (s.e.)",  " (s.d.)",
                              "autocorr. t-2", " (s.e.)",  " (s.d.)" )

  textplot( formatC( key.stats, digits = sDigits, format = "g" ), cmar = 1.0 )
  title <- paste( "Monte Carlo firm-level statistics (", legends[ k ], ")" )
  subTitle <- paste( eval( bquote( paste0( "( Sample size = ", nFirms,
                                           " firms / MC runs = ", nSize,
                                           " / Period = ", warmUp + 1, "-",
                                           nTstat, " )" ) ) ),
                    sector, sep ="\n" )
  title( main = title, sub = subTitle )
}


# Close PDF plot file
dev.off( )
