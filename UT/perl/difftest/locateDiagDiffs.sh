#!/bin/bash
# This script compares binary output files by using IDL script
# ctm_locatediff, storing results in log files, and showing on screen
# (off by default). It is best to use summarizeDiff.sh before recording all
# differences to ensure the full differences file will not be too large.
#
# E. Lundgren, August 2015

# diagnostic files
DIAGFILE1="./Dev/trac_avg.MET_GRID_SIM.START_DATE.Dev"
DIAGFILE2="./Ref/trac_avg.MET_GRID_SIM.START_DATE.Ref"

# destination files for differences
DIAGDIFF="logs/diag_diffs_all.log"

# Get diagnostic file diffs 
# warning: may produce a large file! Use summarizeDiagDiffs.sh first.
idl << idlenv
ctm_diaginfo, file='./Dev/diaginfo.dat', /force
ctm_tracerinfo, file='./Dev/tracerinfo.dat', /force
ctm_locatediff, '$DIAGFILE1', '$DIAGFILE2', OutFileName='$DIAGDIFF'
idlenv
