package Site_Max;

#------------------------------------------------------------------------------
#
#          Copyright 2010
#          THE REGENTS OF THE UNIVERSITY OF MICHIGAN
#          ALL RIGHTS RESERVED
#
#           The software and supporting documentation was developed by the
#
#                   Digital Image Processing Laboratory
#                   Department of Radiology
#                   University of Michigan
#                   1500 East Medical Center Dr.
#                   Ann Arbor, MI 48109
#
#           It is funded in part by DHHS/NIH/NCI 1 U01 CA91099-01 and
#           DHHS/NIH/NCI 1 P01 CA87634-01.
#
#           IT IS THE RESPONSIBILITY OF THE USER TO CONFIGURE AND/OR MODIFY
#           THE SOFTWARE TO PERFORM THE OPERATIONS THAT ARE REQUIRED BY THE
#           USER.
#
#           THIS SOFTWARE IS PROVIDED AS IS, WITHOUT REPRESENTATION FROM THE
#           UNIVERSITY OF MICHIGAN AS TO ITS FITNESS FOR ANY PURPOSE, AND
#           WITHOUT WARRANTY BY THE UNIVERSITY OF MICHIGAN OF ANY KIND,
#           EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
#           IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
#           PARTICULAR PURPOSE. THE REGENTS OF THE UNIVERSITY OF MICHIGAN
#           SHALL NOT BE LIABLE FOR ANY DAMAGES, INCLUDING SPECIAL, INDIRECT,
#           INCIDENTAL, OR CONSEQUENTIAL DAMAGES, WITH RESPECT TO ANY CLAIM
#           ARISING OUT OF OR IN CONNECTION WITH THE USE OF THE SOFTWARE,
#           EVEN IF IT HAS BEEN OR IS HEREAFTER ADVISED OF THE POSSIBILITY OF
#           SUCH DAMAGES.
#
#           PERMISSION IS GRANTED TO USE, COPY, CREATE DERIVATIVE WORKS AND
#           REDISTRIBUTE THIS SOFTWARE AND SUCH DERIVATIVE WORKS FOR ANY
#           PURPOSE, SO LONG AS THIS ENTIRE COPYRIGHT NOTICE, INCLUDING THE
#           GRANT OF PERMISSION, AND DISCLAIMERS, APPEAR IN ALL COPIES MADE;
#           AND SO LONG AS THE NAME OF THE UNIVERSITY OF MICHIGAN IS NOT USED
#           IN ANY ADVERTISING OR PUBLICITY PERTAINING TO THE USE OR
#           DISTRIBUTION OF THIS SOFTWARE WITHOUT SPECIFIC, WRITTEN PRIOR
#           AUTHORIZATION.
#
#------------------------------------------------------------------------------

# This package is specifically for use with the LIDC application known as MAX.  It attempts
# to localize all site-specific code and data structures into a single file, thus making it
# easier to port the application to other sites.  Ideally, max.pl would never have to be
# edited by the different sites; instead, edit Site_Max.pl (and even then, editing shouldn't
# be necessary in most cases).

# Porting issues
# --------------
#
# This module defines various constants.  In general, they don't need to be customized.
# However, the most likely candidates for modification are the string constants for the various
# filenames and the @TAB array which controls the indentation for the XML.  See the code below.

# Revision History
# ----------------
#
#=== October 17-18, 2005: V0.01
# Original version written.  Include %RETURN_CODE, get_seriesid, LIDCDEFDBNAMERD,
# and LIDCDEFDBNAMEWR.
#=== October 18, 2005: V0.02
# Re-code get_seriesid
# Rename to Site_Max & Site_Max.pm
#=== October 26, 2005:
# Add nonoduleswarning to %RETURN_CODE
#=== November 11, 2005: V1.00
# Make it V1.00 since this version works fine!
# Add PMAPXMLDEFFILENAME and pmapxmlfileerror .
#=== November 18-, 2005:
# Move get_zinfo from max and add internal data generation to it.
# Move get_pixeldim from max.pl .
# Move some more constants from max.pl .
# Add "use warnings".
#=== January 4, 2006:
# Add characteristicserror to %RETURN_CODE
#=== January 30, 2006:
# Add VERSIONPMAPXML & XMLINDENT
#=== February 14 - ?, 2006: V2.00 (major change)
# Eliminate subs get_pixeldim & get_seriesid as a part of the simplification where we stop
#   accessing the DB and remove as much site customizations as possible.
# Remove DB-related constants.
# Add NUMDIGRND & ZSPACINGTOLFILLIN.
# === March 6-8, 2006: 
# Add HISTORYXMLDEFFILENAME MATCHINGXMLDEFFILENAME VERSIONMATCHINGXML and VERSIONHISTORYXML .
# Eliminated lots of unused commented-out code (z info stuff and DB-related).
# === March 10, 2006: 
# Add comments tags to delineate the constants so that they can be picked-out by the --internals
#   option.
# === March 13, 2006:
# Add XMLLINE1 and @TAB
# === April 5-6, 2006:
# Add VIRTSPHEREDEFDIAM, DIRINDEF, and DIROUTDEF
# === April 12, 2006:
# Add MINNUMEMPTS
# === April 19, 2006:
# Add MSGDEFFILENAME.  Add outfileerror to %RETURN_CODE
# === May 16, 2006:
# Change ZSPACINGTOLFILLIN to 0.0001
# === June 2, 2006:
# Add LNIDEFFILENAME
# === June 12, 2006:
# Add CENTSEPFACTOR
# === June 13, 2006:
# Add MAJORITYTHR
# === August 31 & Sept 24, 2006:
# Add SMNONSEPTHR
# === Dec. 1, 2006:
# Set VERSIONMATCHINGXML to 1.01
# === March 6 - May 2, 2007:
# Added return code documentation to %RETURN_CODE (see the string '#""" Return code doc: ');
#   works with the (new) --internaldoc option in MAX.
# Re-do the return codes associated with the files used to pass info between runs: See
#   savefileouterror, savefileevalerror, and savefileinerror.
# Bump VERSIONMATCHINGXML to 1.02.
# Add FILEINDEFREX
# === May 11, 2007:
# Added NARROWNESSSEARCHOFFSET
# === June 5, 2007:
# Add %FILEOUTSUFFIXES
# === June 6, 2007:
# Added "interrupted" to %RETURN_CODE
# === June 8, 2007:
# Added GNUPLOTARGS
# === June 29, 2007:
# Moved VERSIONPMAPXML, VERSIONMATCHINGXML & VERSIONHISTORYXML to max.pl itself since these
#   aren't user-configurable.
# === Sept. 19-20, 2007:
# Added CXRREQXMLDEFFILENAME, IDRIREADMESSAGETAGOPEN, & IDRIREADMESSAGETAGCLOSE


# Various pragmas and declarations...
#
use strict;
use diagnostics;
use warnings;
#
# for general use...
use Data::Dumper;



# =======================================================================
# ===================== Do some setup & bookkeeping =====================
# =======================================================================

# Setup our exporting...
require Exporter;
our @ISA = qw(Exporter);
# Export all constants, variables, etc. that we want the outside world to be able to access:
our @EXPORT = qw(
    GNUPLOTARGS 
    XMLINDENT
    XMLLINE1
    DIRINDEF DIROUTDEF
    FILEINDEFREX
    PMAPDEFFILENAME AVSFIELDDEFFILENAME SAVEDATADEFFILENAME
    HISTORYXMLDEFFILENAME MATCHINGXMLDEFFILENAME PMAPXMLDEFFILENAME MSGDEFFILENAME 
    %FILEOUTSUFFIXES 
    CXRREQXMLDEFFILENAME 
    IDRIREADMESSAGETAGOPEN IDRIREADMESSAGETAGCLOSE 
    LNIDEFFILENAME LNI1DEFFILENAME 
    PIXSPACINGTOL CTIMAGESIZE DIAMTHR VIRTSPHEREDEFDIAM CENTSEPFACTOR SMNONSEPTHR 
    ZSPACINGTOL ZSPACINGTOLFILLIN
    MINNUMEMPTS
    NUMREADERS
    NUMDIGRND
    MAJORITYTHR
    NARROWNESSSEARCHOFFSET
    %RETURN_CODE
    @TAB
    );

our $VERSION = 2.00;



# =======================================================================
# ================== Site-specific constants/variables ==================
# =======================================================================

# N.B.: Keep the "begin constant section" tag and the corresponding "end" tag.  They allow this
#       section to be extracted and displayed; see the --internals option.  Be sure all constants
#       are placed in this section.
#
# ++++++++++ begin constant section ++++++++++

# The first line of XML...
use constant XMLLINE1 => q !<?xml version="1.0" encoding="UTF-8"?>!;
# XML lines used in the IDRI/CXR request
use constant IDRIREADMESSAGETAGOPEN  => q !<IdriReadMessage xmlns="http://www.nih.gov/idri">!;
use constant IDRIREADMESSAGETAGCLOSE => q !</IdriReadMessage>!;

# Some directory-related defaults...
use constant DIRINDEF  => '.';
use constant DIROUTDEF => 'max';

# Some filename-related defaults...
use constant FILEINDEFREX             => '\.xml$';  # "file in default regular expression" - input filenames end in ".xml"
use constant SAVEDATADEFFILENAME      => "savedata.dump";
use constant PMAPDEFFILENAME          => "file.pmap";
use constant AVSFIELDDEFFILENAME      => "file.fld";
use constant HISTORYXMLDEFFILENAME    => "history.xml";
use constant MATCHINGXMLDEFFILENAME   => "matching.xml";
use constant PMAPXMLDEFFILENAME       => "pmap.xml";
use constant MSGDEFFILENAME           => "messages.txt";
use constant CXRREQXMLDEFFILENAME     => "cxrrequest-partial.xml";
use constant LNIDEFFILENAME           => "largenodinfo.dump";
use constant LNI1DEFFILENAME          => "largenodinfo1.dump";
# Define a set of suffixes to add to filenames to differentiate among the different types of runs that MAX can do:
our %FILEOUTSUFFIXES;
# N.B.: Don't change the strings within the "{}" (the keys) that we use to "index" into the hash!!!
#       It's OK to change the values - the strings in single quotes.
$FILEOUTSUFFIXES{blinded}{request} = '';  # MAX doesn't analyze blinded request files
$FILEOUTSUFFIXES{blinded}{response} = '-bl_resp';
$FILEOUTSUFFIXES{unblinded}{request} = '-unbl_req';
$FILEOUTSUFFIXES{unblinded}{response} = '-unbl_resp';

# Related to edge map point counts...
use constant MINNUMEMPTS => 5;  # minimum number of edge map points that should be present in an inclusion ROI
                                #   >> Set this to 0 to effectively disable this check.
use constant NARROWNESSSEARCHOFFSET => 3;  # search for narrow contour pixels at this offset from the beginning of the segment; used in sub check_for_narrow_contour

# Various dimensional/geometrical constants:
use constant CTIMAGESIZE       => 512;    # we *should* read this from the DICOM file!
use constant PIXSPACINGTOL     => 0.05;   # fractional tolerance to use for pixel spacing comparisons
use constant ZSPACINGTOL       => 0.1;    # fractional tolerance to use for Z spacing comparisons
use constant ZSPACINGTOLFILLIN => 0.0001; # fractional tolerance to use for comparisons in filling-in Z slices
use constant DIAMTHR           => 3.0;    # diameter (in mm.) to discriminate between small and non-small nodules
use constant SMNONSEPTHR       => 5.0;    # centroid separation threshold (in mm.) for testing for overlap between small and non-nodules
use constant VIRTSPHEREDEFDIAM => 3.0;    # default diameter of the virtual sphere constructed around small nodules
use constant CENTSEPFACTOR     => 2.0;    # a multiplier on the centroid separation checking code

# Other constants:
use constant NUMREADERS => 4;  # the number of readers that we expect
use constant NUMDIGRND => 4;  # number of digits for rounding of floating point numbers (typically
                              #  for Z coords) for comparisons, storage, and use as hash keys
use constant MAJORITYTHR => 3;  # The threshold for determining whether the majority of readers
                                # marked a particular thing as being a large nodule; for QA #6.
use constant GNUPLOTARGS => '-geometry 1000x1000';  # add -persist to keep the plots

# ++++++++++ end constant section ++++++++++

# Indentation for the XML:
# As furnished, the code uses a tab for each indentation level for the XML.  If desired, you can
# activate the space code which would (as furnished) use 4 spaces per level.
use constant XMLINDENT => 4;
my $indentstr = sprintf ' ' x XMLINDENT;  # a single space repeated according to the value of XMLINDENT
our @TAB;
$TAB[0] = '';
foreach my $i ( 1 .. 20 ) {  # 20 is arbitrary: it's just the maximum number of levels that we anticipate -- could be made more or less
    # Fill with spaces per above:
    #$tab[$i] = $tab[$i-1] . $indentstr;
    # Or just fill with tabs instead:
    $TAB[$i] = "\t" x $i;
}

# Use a hash to define return codes...
# Porting notes: This probably doesn't need to be changed.  But if you do, you probably
# should keep the "normal", "reserved", "error", and "unanticipatederror" values as shown.
our %RETURN_CODE;
tie %RETURN_CODE, "Tie::IxHash";  # Preserve ordering
%RETURN_CODE = (
  normal               =>   0,  #""" Return code doc: 0:   The normal return code (no errors detected).
  error                =>   1,  #""" Return code doc: 1:   Generic error return (probably not used).
  reserved             =>   2,  # apparently used by pod2usage if we don't specify anything for -exitstatus
  othererror           => 101,  #""" Return code doc: 101: An option was specified that is not ready for use (secondary matching or "include small").
  cmnderror            => 102,  #""" Return code doc: 102: The form of an option on the command line is incorrect or the value given with an option is invalid or missing.
  validationerror      => 103,  #""" Return code doc: 103: Error in a tag value in the XML.
  inputerror           => 104,  #""" Return code doc: 104: Incorrect number of input files or error in opening or reading an input file or directory.
  configfileerror      => 105,  #""" Return code doc: 105: Error in opening, reading, or interpreting the configuration file.
  savefileerror        => 106,  # obsolete
  internalerror        => 107,  #""" Return code doc: 107: Internal error (matching, pmap construction, saving information between runs, unreachable code).
  pmapfileerror        => 108,  # obsolete
  dbconnectionerror    => 109,  # obsolete
  dbqueryerror         => 110,  # obsolete
  serieserror          => 111,  # obsolete
  pixelerror           => 112,  # obsolete
  matchingerror        => 113,  #""" Return code doc: 113: Matching error (inconsistency in assigning an SNID).
  othermatchingerror   => 114,  #""" Return code doc: 114: Other error during matching (incorrect Z information).
  dbautherror          => 115,  #obsolete
  nonoduleserror       => 116,  #""" Return code doc: 116: No nodules were found; matching cannot be done.
  pmapxmlfileerror     => 117,  # obsolete
  characteristicserror => 118,  # obsolete
  seriesinfoerror      => 119,  # obsolete
  zinfoerror           => 120,  #""" Return code doc: 120: Z information error (getting or inferring slice spacing, filling-in Z coordinates).
  xmloutfileerror      => 121,  #""" Return code doc: 121: Error in opening one of the various XML output files.
  outfileerror         => 122,  # obsolete
  xmlinputdataerror    => 123,  #""" Return code doc: 123: Inconsistent read type detected between/within the input XML data file(s).
  messagesfileerror    => 124,  #""" Return code doc: 124: Error in opening the messages file or its directory.
  savefileinerror      => 125,  # obsolete/changed (see below)
  savefileouterror     => 126,  #""" Return code doc: 126: Error in saving data to file for passing information between runs.
  savefileevalerror    => 127,  #""" Return code doc: 127: Error in evaluating a file for passing information between runs.
  savefileinerror      => 128,  #""" Return code doc: 128: Error in opening or accessing a file for passing information between runs.
  xmlinputparsingerror => 129,  #""" Return code doc: 129: Error in parsing the XML in an input file.
  interrupted          => 130,  #""" Return code doc: 130: An interrupt signal (control-C) was detected.
  
  unanticipatederror   => 255  # apparently used by Perl if it detects an error of its own, so we should never use this value    #""" Return code doc: 255: used by Perl if it detects an error during execution
);


# And speaking of return codes...
1;  # return code for the entire module when it is loaded (must be "true")
