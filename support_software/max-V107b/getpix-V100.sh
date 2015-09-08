#!/bin/sh
# Name:
# getpix.sh

# ----------------------------------------------------------------------------------------------
# Copyright 2010
# THE REGENTS OF THE UNIVERSITY OF MICHIGAN
# ALL RIGHTS RESERVED
# 
# The software and supporting documentation was developed by the
# 
#          Digital Image Processing Laboratory
#          Department of Radiology
#          University of Michigan
#          1500 East Medical Center Dr.
#          Ann Arbor, MI 48109
# 
# It is funded in part by DHHS/NIH/NCI 1 U01 CA91099-01.
# 
# IT IS THE RESPONSIBILITY OF THE USER TO CONFIGURE AND/OR MODIFY THE SOFTWARE TO PERFORM THE 
# OPERATIONS THAT ARE REQUIRED BY THE USER.
# 
# THIS SOFTWARE IS PROVIDED AS IS, WITHOUT REPRESENTATION FROM THE UNIVERSITY OF MICHIGAN AS 
# TO ITS FITNESS FOR ANY PURPOSE, AND WITHOUT WARRANTY BY THE UNIVERSITY OF MICHIGAN OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE REGENTS OF THE UNIVERSITY OF 
# MICHIGAN SHALL NOT BE LIABLE FOR ANY DAMAGES, INCLUDING SPECIAL, INDIRECT, INCIDENTAL, 
# OR CONSEQUENTIAL DAMAGES, WITH RESPECT TO ANY CLAIM ARISING OUT OF OR IN CONNECTION WITH 
# THE USE OF THE SOFTWARE, EVEN IF IT HAS BEEN OR IS HEREAFTER ADVISED OF THE POSSIBILITY 
# OF SUCH DAMAGES.
# 
# PERMISSION IS GRANTED TO USE, COPY, CREATE DERIVATIVE WORKS AND REDISTRIBUTE THIS SOFTWARE 
# AND SUCH DERIVATIVE WORKS FOR ANY PURPOSE, SO LONG AS THIS ENTIRE COPYRIGHT NOTICE, 
# INCLUDING THE GRANT OF PERMISSION, AND DISCLAIMERS, APPEAR IN ALL COPIES MADE; AND SO LONG 
# AS THE NAME OF THE UNIVERSITY OF MICHIGAN IS NOT USED IN ANY ADVERTISING OR PUBLICITY 
# PERTAINING TO THE USE OR DISTRIBUTION OF THIS SOFTWARE WITHOUT SPECIFIC, WRITTEN PRIOR 
# AUTHORIZATION.
# ----------------------------------------------------------------------------------------------

# Purpose:
# Get the pixel spacing from a DICOM file.  Typically used by MAX.

# Notes:
# * This is a very funky script that could be improved in many ways, but it's OK for now.
#   It is VERY specific to UofM's LIDC directory tree layout.
# * Borrows code from our directory.sh and make_fld_file.sh scripts.

# Running the script:
# * Simply invoke the script; no arguments are needed.
# * See below for directory tree considerations.
# * Output: A floating point number (the pixel spacing).
# * Return status: Follows the usual Linux conventions: 1 if we can't determine which
#   directory tree we're in or 0 for success.

# Requirements and porting to other systems:
# * dcm_dump_file
# * Edit the code below that is specific to directory structure.

# Revision history:
# === ca. 2005:
# * Written.
# === March 8, 2007:
# * Generalized to run in either the request or servicing part of the tree.
# === March 3, 2008:
# * removed -t from dcm_dump_file


# Depending on where we are, we use different assumptions for finding the files:
if pwd | grep /galaxy/LIDC/req >/dev/null 2>&1
  # The request directory tree contains directories of this form:
  #   /galaxy/LIDC/req/completed/1.2.826.0.1.3680043.2.108.14.0.0.30070.11/unbl_resp
  # This script executes from within such a directory.
  # We know that one level up, there is a series directory named with a 5-digit string.
  # Get the 1st DICOM file in this series directory; we know that the filenames start with 
  #   1.2.826.0.1.3680043.2.108 since these are files that we created as requester.
  then
    #echo we are in the request tree
    if /bin/ls ../[0-9][0-9][0-9][0-9][0-9]/1.2.826.0.1.3680043.2.108.* >/dev/null 2>&1
      then
        dicomfname=../[0-9][0-9][0-9][0-9][0-9]/`/bin/ls ../[0-9][0-9][0-9][0-9][0-9]/1.2.826.0.1.3680043.2.108.* 2>/dev/null | head -n 1`
    fi
elif pwd | grep /galaxy/LIDC/serv >/dev/null 2>&1
  # The servicing directory tree contains directories of this form:
  #   /galaxy/LIDC/serv/BS/1.2.826.0.1.3680043.2.446.150.14.0.0.30070.11/
  # This script executes from within such a directory.
  # We know that there is a series directory whose name is the same as the last part of the current directory.
  # Get a DICOM file from this series directory.
  then
    #echo we are in the service tree
    cwd=`pwd`
    imagedir=`basename $cwd`
    dicomfname=`find $imagedir -type f 2>/dev/null | head -n 8 | tail -n 1`
else
    # we don't know where we are, so return nothing, but signal an error...
    exit 1
fi

# Get the value of the pixel spacing from the DICOM file:
if [ -n "$dicomfname" ]
  then
  psline=`/usr/local/ctn/bin/dcm_dump_file $dicomfname | grep "Pixel Spacing"`  # extract the line from the file
  psline=`echo $psline | tr -d '[:space:]' | tr -s '\\\' ','`  # clean it up
  psnum=`echo $psline | cut -d',' -f2`  # extract the spacing (a floating point number)
  psnum=`printf "%8.4f" $psnum`  # format it
  echo $psnum  # output it
fi

exit 0
