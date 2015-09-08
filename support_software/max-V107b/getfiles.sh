#!/bin/sh

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

# A VERY simple script that works in our setup. Must be adapted for use in other environments!
# It makes a comma-separated list of the XML files found in the current dir preceeded by the
#   --files command line option.

# This little section is probably useful for testing only:
if [ $1 ]
then
  cd $1
fi

# for testing:
#/bin/ls -m *.xml | wc -l

# This is it...
echo -n "--files="
# Find all *.xml files, but filter-out some specific filenames, and delete spaces:
#/bin/ls -m *.xml | grep -v -E 'UM.*nih.xml|ORIG|ORG' | tr -d '[:space:]'
#/bin/ls -m *.xml | grep -v -E '*nih*.xml|ORIG|ORG' | tr -d '[:space:]'
/bin/ls -1 *.xml | grep -v -E '*nih*.xml|ORIG|ORG' | tr '[:space:]' ','
