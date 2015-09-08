#!/usr/bin/perl
# Name:
# get_image_geom-V201.pl

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
# Get the pixel spacing and slice spacing from a set of DICOM files and create a string that
# can be used by MAX.

# Notes:
# * This is a very funky script that could be improved in many ways, but it's OK for now.
#   It is VERY specific to UofM's LIDC directory tree layout.

# Running the script:
# * Simply invoke the script; no arguments are needed.
#   % cd /to/an/lidc/dir
#   % /some/dir/max.pl `get_image_geom.pl` --some-more-opts
#  It emits a string like the following...
#     --pixel-dim 0.7031  --slice-spacing 0.625
#   If either part cannot be found, it is omitted in which case MAX deals with it.
# * Return status: Follows the usual Linux conventions: 0 if we can't determine which
#   directory tree we're in or 1 for success.
# * See below for directory tree considerations.

# Requirements and porting to other systems:
# * Software:
#   - Tie::IxHash -- from CPAN
#   - our locally developed Perl module Site_Max
#   - Bourne scripts getpix.sh and check_seq.sh
#   - /local/DIPLenv.csh (sourced by check_seq.sh)
#   - Mallinckrodt CTN suite: dcm_dump_file
# * Edit the code below that is specific to directory structure.

# Revision history:
# === ca. 2005:
# * Written.
# === March 8, 2007:
# * Generalized to run in either the request or servicing part of the tree.
# === March 12, 2007: V2.00 started (everything keys off finding a .flis file)
# === April 25, 2007:
# * Minor additions to the text output with the --interactive switch.
# === Sept. 19, 2007: V2.01 - new feature
# * Add capability of getting pixel & slice spacing args & values from the image_geom.args file
#   which should be located (1) in the same dir with the images and the .flis file or (2) in 
#   max/ or (3) under the directory named by $startdir.
# === Oct. 17, 2007:
# * Add "=" between the option name and value.


# Start with the usual stuff...
use strict;
use diagnostics;
use warnings;

# Here are some particular modules that we need:
use Getopt::Long;  # this allows command line processing with long ("--") options
use Data::Dumper;  # useful for general diagnostic purposes
use Tie::IxHash;   # contains routines that preserve order of XML tags in hashes (needed by Site_Max)
use Cwd;  # this gets us getcwd()
use File::Basename;  # this gets us dirname()

# Add the directory that MAX (and Site_Max) lives in to the module/library search path:
use FindBin;
use lib "$FindBin::Bin";

# Site-specific:
use Site_Max;  # our own package that contains site-specific constants, etc. (gives us ZSPACINGTOL)


# Simple command line processing:
my $interactive;
my %GetOptsHash = ( 'interactive' => \$interactive );
GetOptions ( %GetOptsHash );

# Define utilities that we'll use later:
my $ckseq = '/local/scripts/dicom/check_seq.sh';
my $ddf = '/usr/local/ctn/bin/dcm_dump_file';

# Find the directory in which we should start our search for a .flis file:
my $startdir;
my $curdir = getcwd;
if ( $curdir =~ m/\/galaxy\/LIDC\/req/ ) {
  # One level up, there is a 5-digit series directory which contains the .flis file.
  $startdir = '..';
}
elsif ( $curdir =~ m/\/galaxy\/LIDC\/serv/ ) {
  # In the current directory, there is a directory whose name is the same as the basename of our
  #  current location; there is an .flis file in this directory.
  $startdir = '.';
}
else {
  # Otherwise, we don't really know where we are, so error out:
  print "Can't identify where we are. \n" if $interactive;
  exit 1;
}

# See if there is an image_geom.args file.  If so, use it and exit.
my @argslist = split /\n/, `find $startdir -name image_geom.args`;
my $numargsfiles = scalar(@argslist);
# There should be exactly one:
if ( $numargsfiles == 1 ) {
    my $argsfname = $argslist[0];
    print `cat $argsfname`;
    print "\n" if $interactive;
    exit 0;
}
elsif ( $numargsfiles > 1 ) {
    # We don't really know what to do with multiples, so error out:
    print "Found $numargsfiles image_geom.args files under directory $startdir/.\n" if $interactive;
    exit 1;
}
else {
    #print "Found no image_geom.args files under directory $startdir/\n" if $interactive;
    # ... and just go on...
}

# Find the .flis file:
my @flislist = split /\n/, `find $startdir -name "*.flis"`;
my $flisfname;
my $numfiles = scalar(@flislist);
# There should be exactly one:
if ( $numfiles == 1 ) {
    $flisfname = $flislist[0];
}
else {
    # Otherwise, we don't really know what to do, so error out:
    print "Didn't find exactly 1 .flis file under directory $startdir/ -- found $numfiles instead.\n" if $interactive;
    exit 1;
}

# Get the slice spacing from the .flis file:
if ( $flisfname ) {
    my $minmaxslsp = `$ckseq -m $flisfname`;
    my ( $minslsp, $maxslsp ) = split ( / /, $minmaxslsp );
    printf " --slice-spacing=%.3f ", $minslsp if approxeq ( $minslsp, $maxslsp, ZSPACINGTOL );
}

# This code gets the pixel dimension from a DICOM image:
my $dicomfname = dirname($flisfname) . '/' . `head -n 1 $flisfname | cut -d ' ' -f3`;  # print "\n $dicomfname \n"; exit;
chomp $dicomfname;
push my @args, "-t", "$dicomfname";
open ( my $ddfh, "-|", "$ddf", "-t", "$dicomfname" ) or die "Can't run program: $!\n";
my $pixspacing;
while (<$ddfh>) {
    if ( /Pixel Spacing/ ) {
       my $line = $_;
       # The pixel spacing line typically looks like
       #    0028 0030       24 //              IMG Pixel Spacing//0.677734375\0.677734375
       $pixspacing = ( split /\\/, $line )[1];
    }
}
close $ddfh;
printf " --pixel-spacing=%.3f ", $pixspacing if $pixspacing;

print "\n" if $interactive;
exit 0;


# Borrowed from MAX...
sub approxeq {
# Check 2 numbers for equality to the specified tolerance
    my ( $x1, $x2, $tol ) = @_;
    return 0 if ( ! $x1 || ! $x2 );
    my $delta = $x1 - $x2;
    my $ave = ( $x1 + $x2 ) / 2.0;
    my $frac = abs ( $delta / $ave );
    my $flag = ( $frac <= $tol );
    return $flag;
}
