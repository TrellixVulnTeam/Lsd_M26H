\name{read.doe.lsd}
\alias{read.doe.lsd}
\title{
Read a set of experimental data from a LSD model
}
\description{
This function reads the sampling data produced by a LSD model design of experiment (DoE), pre-process it and saves it as a R object that can be used by the other tools provided by the LSDsensitivity package. Optionally, it can be used with a second DoE, on the same simulation model, to allow the out-of-sample (external) validation of the fitted meta-models.
}
\usage{
read.doe.lsd( folder, baseName, outVar = "", does = 1, doeFile = NULL,
              respFile = NULL, validFile = NULL, valRespFile = NULL,
              confFile = NULL, limFile = NULL, iniDrop = 0, nKeep = -1,
              saveVars = NULL, addVars = NULL, eval.vars = NULL,
              eval.run = NULL, eval.stat = c( "mean", "median" ),
              pool = TRUE, na.rm = FALSE, rm.temp = TRUE, rm.outl = FALSE,
              lim.outl = 10, nnodes = 1, quietly = TRUE, instance = 1,
              posit = NULL, posit.match = c( "fixed", "glob", "regex" ) )
}
\arguments{
  \item{folder}{
the \emph{relative} folder path to the LSD DoE data files, using the R working directory as reference (see \code{\link[base]{getwd}()}).
}
  \item{baseName}{
the LSD data files base name, without numbering and extension suffixes (should be the same as the name of the baseline \code{.lsd} file, without the extension). If \code{.lsd} extension is included, it is automatically removed.
}
  \item{outVar}{
the name of an \emph{existing} variable to be used as the reference to perform the sensitivity analysis. If no name is supplied, the default is to use the first element of \code{saveVars} or \code{addVars}.
}
  \item{does}{
1 or 2: number of experiments to be processed, being 2 only when one additional external validation sample (independent from the main sample) is available (see the required files below). The default is 1.
}
  \item{doeFile}{
the DoE specification file to be used. For the default (NULL), the \code{baseName} is used to generate the default LSD generated name.
}
  \item{respFile}{
the DoE response file to be used/created. For the default (NULL), the \code{baseName} is used to generate the name.
}
  \item{validFile}{
the external validation DoE specification file to be used. For the default (NULL), the \code{baseName} is used to generate the default LSD generated name.
}
  \item{valRespFile}{
the external validation DoE response file to be used/created. For the default (NULL), the \code{baseName} is used to generate the name.
}
  \item{confFile}{
the LSD baseline \code{.lsd} configuration file. The default (NULL) is to use \code{baseName.lsd}.
}
  \item{limFile}{
the LSD factor limit ranges \code{.sa} file. The default (NULL) is to use \code{baseName.sa}.
}
  \item{iniDrop}{
integer: the number of initial time steps to drop from analysis (from \code{t = 1} till \code{t = iniDrop}). The default (0) is to remove no time step.
}
  \item{nKeep}{
integer: the total number of time steps to keep after \code{iniDrop}, if simulation length is longer than \code{nKeep} discard data from the end of the simulation. The default (-1) is to preserve all data.
}
  \item{saveVars}{
a vector of existing LSD variable names to be kept in the data set. The default (\code{NULL}) is to save just \code{outVar}, if supplied. At least one existing or new variable (defined by \code{addVars}) must exist. \code{saveVars} also defines the variables which are available for processing by the function defined by \code{eval.vars}, the default \code{saveVars = c()} representing all variables in the results files. For large datasets, this parameter allow reducing the memory required by not loading unnecessary data into memory.
}
  \item{addVars}{
a vector of new LSD variable names to be added to the data set. The default (\code{NULL}) is to add none. At least one existing or new variable must exist.
}
  \item{eval.vars}{
a function to recalculate any item of the imported data set, including added variables. The default (NULL) is to have no function (just use selected existing variables as is). If defined, function must take two arguments: the data set for a specific DoE point (time steps in the rows) and the list of variables (columns) in the data set. The function may change any value within the data set but \emph{should not} add or remove rows or columns.
}
  \item{eval.run}{
a function to evaluate the DoE response for each experimental sampling point, attributing an optional value to it. The default (NULL) is to have no function. In this case, the function uses the selected variable Monte Carlo mean and standard deviation, or the median and the median absolute deviation if \code{median = TRUE}, to value the point. If defined, function must take four arguments: (a) the data set (a 3-dimensional array of lists, the numbers of the DoE sampling points in the first dimension, variables in the second, and Monte Carlo runs in the in the third, being each list element a vector with all time-step values for that sample/variable/MC run), (b) the number of the DoE sampling point to evaluate, (c) the index to the analysis variable in the data set, and (d) the applicable confidence interval. The function must return a R list containing four values for the selected sampling point/variable pair: (a) the average value for the response, (b) the response standard deviation, (c) the the number of observations used, and (d) the number of observations discarded.
}
  \item{eval.stat}{
character: define the statistics to be used to evaluate the DoE response when \code{eval.run = NULL}. Options are \code{"mean"} to use the mean and the standard deviation (default), or \code{"median"}, to use the median and the median absolute deviation (MAD). Names can be abbreviated. If an evaluation function is provided in \code{eval.run}, this option is ignored.
}
  \item{na.rm}{
logical: if TRUE NA values are stripped before the computation proceeds.
}
  \item{rm.temp}{
logical: if \code{TRUE} (default), remove response and temporary speed up files. If \code{FALSE}, do not remove response and temporary speed up files, allowing fast execution of subsequent call to this function. Please note that when set to FALSE, the user \emph{must} temporary files (extension \code{.Rdata}) manually whenever LSD data files are updated, so they are re-read. This can be done by simply turning \code{rm.temp} to TRUE once.
}
  \item{rm.outl}{
logical: if \code{TRUE}, remove outliers from data set. Default is \code{FALSE}, no outliers removal.
}
  \item{lim.outl}{
numeric: if \code{rm.outl = TRUE}, defines the limit for non-outliers deviation in number of standard deviations.
}
  \item{nnodes}{
integer: the maximum number of parallel computing nodes (parallel threads) in the current computer to be used for reading the files. The default, \code{nnodes = 1}, means single thread processing (no parallel threads). If equal to zero, creates up to one node per CPU core. Only \code{PSOCK} clusters are used, to ensure compatibility with any platform. Please note that each node requires its own memory space, so memory usage increases linearly with the number of nodes.
}
  \item{quietly}{
logical: if \code{TRUE}, no message confirming file reading/information is printed. The default (\code{FALSE}) is to show details about each results file read.
}
  \item{pool}{
logical: if \code{TRUE} (default), create a simpler data array, pooling together only a single instance for each variable. The instance to be considered is provided by \code{instance}. If \code{FALSE}, use all variable instances, which are treated as a single one (indeed, pooling all values...). More control over which instances are used can be obtained by simultaneously using \code{posit}.
}
  \item{instance}{
integer: the instance of the variable to be read, for variables that exist in more than one object. This number is based on the relative position (column) of the variable in the results file. The default (1) is to read the first instance. Only a single existing instance at a time can be read for analysis.
}
  \item{posit}{
a string, a vector of strings or an integer vector describing the LSD object position of the variable(s) to select. If an integer vector, it should define the position of a SINGLE LSD object. If a string or vector of strings, each element should define one or more different LSD objects, so the returning matrix may contain variables from more than one object. By setting \code{posit.match}, globbing (wildcard), and regular expressions can be used to select multiple objects at once; in this case, all matching objects are selected, but only the instance defined by \code{instance} is used.
}
  \item{posit.match}{
a string defining how the \code{posit} argument, if provided, should be matched against the LSD object positions. If equal to \code{"fixed"}, the default, only exact matching is done. \code{"glob"} allows using simple wildcard characters ('*' and '?') in \code{posit} for matching. If \code{posit.match="regex"} interpret \code{posit} as POSIX 1003.2 extended regular expression(s). See \code{\link[=regex]{regular expressions}} for details of the different types of regular expressions. Options can be abbreviated.
}
}
\details{
The function reuses any existing response file(s) (for the main and the optional external validation DoEs) or try to create it (them) if not existing. The response files can be created in relation to any existing, modified or new variable from any simulated time step, including complex combinations of those. New and modified variables (w.r.t. the ones available from LSD) can be easily created by the definition of a \code{eval.vars(data, varList)} function, as shown in the example below. The response values for each sampling point in the DoE(s) can be evaluated using any math/statistical technique over the entire data for each sampled point in every Monte Carlo run by the definition of a \code{eval.run(data, mc.run, var.idx, ci)}, as in the example below.

Each call to the function can process a single variable. If sensitivity analysis is being performed on multiple variables, the function must be called several times. However, if \code{rm.tmp = FALSE} the processing time from the second variable is significantly shortened.

This function requires that the complete set of LSD DoE data files be stored in a single folder/directory. The list of required files is the following (\code{XX}, \code{YY} and \code{ZZ} are sequential control numbers produced by LSD, \code{i = 0, 1,...}):

\preformatted{
folder/baseName.lsd              : LSD baseline configuration (1 file)
folder/baseName.sa               : factor ranges (1 file)
folder/baseName_XX_YY.csv        : DoE specification (1 file)
folder/baseName_XX+i.res[.gz]]   : DoE data (YY-XX+1 files)
folder/baseName_YY+1_ZZ.csv      : validation specification (optional - 1 file)
folder/baseName_YY+1+i.res[.gz]  : validation data (optional - ZZ-YY+1 files)
}

The function generates the required response files for the selected variable of analysis and produces the following files in the same folder/directory (\code{WWW} is the name of the selected analysis variable):

\preformatted{
folder/baseName_XX_YY_WWW.csv    : DoE response for the selected variable (1 file)
folder/baseName_YY+1_ZZ_WWW.csv  : validation response for variable (optional - 1 file)
}

When \code{posit} is supplied together with \code{col.names} or \code{instance}, the variable selection process is done in two steps. Firstly, the column names set by \code{saveVars} and \code{instance} are selected. Secondly, the instances defined by \code{posit} are selected from the first selection set. See \code{\link{select.colnames.lsd}} and \code{\link{select.colattrs.lsd}} for examples on how to apply advanced selection options.
}
\value{
The function returns an object/list of class \code{lsd-doe} containing all the experimental data and the corresponding results regarding the selected reference variable \code{outVar}, including the data for the out-of-sample (external) validation of the produced meta-models, if available, as well the DoE(s) details required by the package meta-modelling tools (\code{\link{elementary.effects.lsd}}, \code{\link{kriging.model.lsd}}, and \code{\link{polynomial.model.lsd}}).

List components:
\item{doe}{the DoE data. Can be a tabular data frame if \code{pool = TRUE} or a four-dimensional array otherwise.}
\item{resp}{the DoE response data table.}
\item{valid}{the external validation DoE data. Can be a tabular data frame if \code{pool = TRUE} or a four-dimensional array otherwise.}
\item{valResp}{the external validation DoE response data table.}
\item{facLim}{the factors limit ranges table.}
\item{facLimLo}{the factors minimum values.}
\item{facLimUp}{the factors maximum values.}
\item{facDef}{the factors default/calibration values.}
\item{saVarName}{the sensitivity analysis reference variable name, as defined by \code{outVar}.}
}
\author{
\packageAuthor{LSDsensitivity}
}
\note{
See the note in \link[LSDsensitivity]{LSDsensitivity-package} for step-by-step instructions on how to perform the complete sensitivity analysis process using LSD and R.

Please refer to LSD documentation about the details on the files produced by its sensitivity analysis tools, in particular when using NOLH, Elementary Effects and MC Range Sensitivity Analysis sampling:

LSD documentation is available at \url{https://www.labsimdev.org/} and the latest binaries and source code can be downloaded at \url{https://github.com/marcov64/Lsd/}.
}
\seealso{
\code{\link{elementary.effects.lsd}()},
\code{\link{kriging.model.lsd}()},
\code{\link{polynomial.model.lsd}()}
\code{\link[LSDinterface]{list.files.lsd}()}
}
\examples{
# get the example directory name
path <- system.file( "extdata/sobol", package = "LSDsensitivity" )

# Steps to use this function:
# 1. define the variables you want to use in the analysis
# 2. optionally, define special handling functions (see examples below)
# 3. load data from a LSD simulation saved results using read.doe.lsd
# 4. perform the elementary effects analysis applying elementary.effects.lsd

# the definition of existing, to take log and to be added variables
lsdVars <- c( "var1", "var2", "var3" )
logVars <- c( "var1", "var3" )
newVars <- c( "var4" )

# load data from a LSD simulation baseline configuration named "Sim1.lsd" to
# perform sensitivity analysis on the variable named "var1"
# there are two groups of sampled data (DoEs) created by LSD being read
# just use no handling functions for now, see possible examples below
dataSet <- read.doe.lsd( path,                 # data files folder
                         "Sim3",               # data files base name (same as .lsd file)
                         "var3",               # variable name to perform the sens. analysis
                         does = 2,             # # of experiments (data + external validation)
                         iniDrop = 0,          # initial time steps to drop (0=none)
                         nKeep = -1,           # number of time steps to keep (-1=all)
                         saveVars = lsdVars,   # LSD variables to keep in dataset
                         addVars = newVars,    # new variables to add to the LSD dataset
                         eval.stat = "median", # use median to evaluate runs
                         rm.temp = FALSE,      # reuse temporary speedup files
                         rm.outl = FALSE,      # remove outliers from dataset
                         lim.outl = 10,        # limit non-outliers deviation (# of std. devs.)
                         quietly = FALSE )     # show information during processing
print( dataSet$doe )            # the design of the experiment sample done in LSD
print( dataSet$valid )          # the extenal validation sample
print( dataSet$saVarName )      # the variable for which the response was analyzed
print( dataSet$resp )           # analysis of the response of the selected variable

#### OPTIONAL HANDLING FUNCTION EXAMPLES ####

# eval.vars( ) EXAMPLE 1
# the definition of a function to take the log of the required variables () and
# compute the new ones (for use on pool = TRUE databases)

eval.vars <- function( dataSet, allVars ) {
  tsteps <- nrow( dataSet )        # number of time steps in simulated data set
  nvars <- ncol( dataSet )         # number of variables in data set (including new ones)

  # ---- Recompute values for existing variables ----
  for( var in allVars ) {
    if( var \%in\% logVars ) {     # take the log values of selected variables
      try( dataSet[ , var ] <- log( dataSet[ , var ] ), silent = TRUE )  # <= 0 as NaN
    }
  }

  # ---- Calculate values of new variables (added to LSD data set) ----
  dataSet[ , "var4" ] <- dataSet[ , "var1" ] + dataSet[ , "var2" ]   # example of new var

  return( dataSet )
}

# load data again, now using new variable v4 for analysis
dataSet <- read.doe.lsd( path,                 # data files folder
                         "Sim3",               # data files base name (same as .lsd file)
                         "var4",               # variable name to perform the sens. analysis
                         does = 2,             # # of experiments (data + external validation)
                         iniDrop = 0,          # initial time steps to drop (0=none)
                         nKeep = -1,           # number of time steps to keep (-1=all)
                         saveVars = lsdVars,   # LSD variables to keep in dataset
                         addVars = newVars,    # new variables to add to the LSD dataset
                         eval.vars = eval.vars,# function to evaluate/adjust/expand the dataset
                         rm.temp = TRUE,       # remove temporary speedup files
                         rm.outl = FALSE,      # remove outliers from dataset
                         lim.outl = 10 )       # limit non-outliers deviation (# of std. devs.)
print( dataSet$doe )            # the design of the experiment sample done in LSD
print( dataSet$valid )          # the external validation sample
print( dataSet$saVarName )      # the variable for which the response was analyzed
print( dataSet$resp )           # analysis of the response of the selected variable

# eval.vars( ) EXAMPLE 2
# the definition of a function to compute the new variables
# (for use on pool = FALSE databases)

# ---- 4D data frame version (when pool = FALSE) ----

eval.vars <- function( data, vars ) {
  tsteps <- length( data [ , 1, 1, 1 ] )
  nvars <- length( data [ 1, , 1, 1 ] )
  insts <- length( data [ 1, 1, , 1 ] )
  samples <- length( data [ 1, 1, 1, ] )

  # ---- Compute values for new variables, preventing infinite values ----
  for( m in 1 : samples )               # for all MC samples (files)
    for( j in 1 : insts )               # all instances
      for( i in 1 : tsteps )            # all time steps
        for( var in vars ) {            # and all variables

          if( var == "var4" ) {
            # Normalization of key variables using the period average size
            mean <- mean( data[ i, "var2", , m ], na.rm = TRUE )
            if( is.finite ( mean ) && mean != 0 )
              data[ i, var, j, m ] <- data[ i,"var2", j, m ] / mean
            else
              data[ i, var, j, m ] <- NA
          }
        }
  return( data )
}

# load data again, now using new variable var2 for analysis
dataSet <- read.doe.lsd( path,                 # data files folder
                         "Sim3",               # data files base name (same as .lsd file)
                         "var2",               # variable name to perform the sens. analysis
                         does = 2,             # # of experiments (data + external validation)
                         iniDrop = 0,          # initial time steps to drop (0=none)
                         nKeep = -1,           # number of time steps to keep (-1=all)
                         pool = FALSE,         # don't pool MC runs
                         saveVars = lsdVars,   # LSD variables to keep in dataset
                         addVars = newVars,    # new variables to add to the LSD dataset
                         eval.vars = eval.vars,# function to evaluate/adjust/expand the dataset
                         rm.temp = TRUE,       # remove temporary speedup files
                         rm.outl = FALSE,      # remove outliers from dataset
                         lim.outl = 10 )       # limit non-outliers deviation (# of std. devs.)
print( dataSet$doe )            # the design of the experiment sample done in LSD
print( dataSet$valid )          # the external validation sample
print( dataSet$saVarName )      # the variable for which the response was analyzed
print( dataSet$resp )           # analysis of the response of the selected variable

# eval.run( ) EXAMPLE
# the definition of a function to evaluate a point in the DoE, associating a result
# with it (in terms of average result and dispersion/S.D.)
# the example evaluates the fat-taildness of the distribution of the selected
# variable, using the Subbotin distribution b parameter as metric (response)

library( normalp )

eval.run <- function( data, run, varIdx, conf ) {

  obs <- discards <- 0

  # ------ Compute Subbotin fits for each run ------
  bSubbo <- rep( NA, dim( data )[ 3 ] )
  for( i in 1 : dim( data )[ 3 ] ) {
    x <- data[[ run, varIdx, i ]]
    sf <- paramp( x )
    sf$p <- estimatep( x, mu = sf$mean, p = sf$p, method = "inverse" )
    if( sf$p >= 1 ) {
      bSubbo[ i ] <- sf$p
      obs <- obs + 1
    } else {
      bSubbo[ i ] <- NA
      discards <- discards + 1
    }
  }

  return( list( mean( bSubbo, na.rm = TRUE ),
                var( bSubbo, na.rm = TRUE ), obs, discards ) )
}

# load data again, now using the defined evaluation function
dataSet <- read.doe.lsd( path,                 # data files folder
                         "Sim3",               # data files base name (same as .lsd file)
                         "var2",               # variable name to perform the sens. analysis
                         does = 2,             # # of experiments (data + external validation)
                         iniDrop = 0,          # initial time steps to drop (0=none)
                         nKeep = -1,           # number of time steps to keep (-1=all)
                         saveVars = lsdVars,   # LSD variables to keep in dataset
                         addVars = newVars,    # new variables to add to the LSD dataset
                         eval.run = eval.run,  # function to evaluate the DoE point response
                         rm.temp = TRUE,       # remove temporary speedup files
                         rm.outl = FALSE,      # remove outliers from dataset
                         lim.outl = 10 )       # limit non-outliers deviation (# of std. devs.)
print( dataSet$doe )            # the design of the experiment sample done in LSD
print( dataSet$valid )          # the external validation sample
print( dataSet$saVarName )      # the variable for which the response was analyzed
print( dataSet$resp )           # analysis of the response of the selected variable
}
\keyword{ interface }
\keyword{ file }
\keyword{ datasets }
\keyword{ datagen }
\keyword{ design }
