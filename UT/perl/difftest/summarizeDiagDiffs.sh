#!/bin/bash
# This script compares binary output files by using IDL script
# ctm_summarizediff, storing a summary of the results in log files
# and showing them on screen.
#
# E. Lundgren, August 2015

# diagnostic files
DIAGFILE1="./Dev/trac_avg.MET_GRID_SIM.START_DATE.Dev"
DIAGFILE2="./Ref/trac_avg.MET_GRID_SIM.START_DATE.Ref"

# destination files for differences
DIAGDIFF="logs/diag_diffs_summary.log"

# Get rst and diag file diffs
idl << idlenv
ctm_diaginfo, file='./Dev/diaginfo.dat', /force
ctm_tracerinfo, file='./Dev/tracerinfo.dat', /force
ctm_summarizediff, '$DIAGFILE1', '$DIAGFILE2', OutFileName='$DIAGDIFF'
idlenv

