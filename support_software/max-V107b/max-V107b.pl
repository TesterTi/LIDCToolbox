#!/usr/bin/perl

#------------------------------------------------------------------------------
#
#          Copyright 2006 - 2010
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
#           It is funded in part by DHHS/NIH/NCI 1 U01 CA91099-01.
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

# Filename: max-V107.pl (version 1.07)  (and edit the greeting line below)

# Note: Much important information is included in the comments of this code.  The most
# important info is placed early (in the first 250 to 300 lines of comments), with
# less important info (Revision History, etc.) appearing later.  The in-line help text
# (accessible via the --help command line switch) also contains lots of useful info.

# Topics in this comment block
# ----------------------------
#  * Purpose
#  * Usage
#  * Background, data organization, etc.
#  * Pre-requisites and environment
#  * Porting to other sites
#  * Porting to other operation systems
#  * Other utilities, programs, applications, modules, files
#  * Assumptions
#  * Matching algorithm description
#  * XML - history, matching, pmap, etc.
#  * QA actions
#  * Revision History
#  * Confirmed/verified actions/characteristics
#  * Known bugs, limitations
#  * To do, future ideas, limitations, "issues"
#  * Coding notes
#  * User message codes
#  * Picking out user messages from the code
#  * Command line options, read type & message type, XML tags, etc.
#  * Rough roadmap of execution of the code
#  * Execution speed

# Purpose
# -------
#
# "MAX" stands for "multi-purpose application for XML".  It is used by the LIDC to perform
# nodule matching, pmap generation, QA, and other XML-related tasks on the blinded and unblinded
# read responses.

# Usage
# -----
#
# See the in-line doc for options, etc.: run this app with --help .

# Background, data organization, etc.
# -----------------------------------
#
# The organization of our (Michigan's) initial review process and workflow (as a requesting
# site) is described here.  However, very little of this environment (except as
# noted below under "Pre-requisites and environment" and "Porting issues") appears in
# the code of this app.  Thus, our environment is described here for reference only.  
#
# As cases are being worked-up, files are placed in:
#
#   amazon:/galaxy/LIDC/req/<seriesinstuid>/
#
# Each <seriesinstuid>/ directory contains four directories:
#
#   bl_req/
#   bl_resp/
#   unbl_req/
#   unbl_resp/
#
# These, in turn, contain all XML files associated with being a requesting site: 
# request and response XML files for/from the blinded and unblinded reads.  The
# <seriesinstuid>/ directory also contains a
# directory (named as the re-assigned study ID) containing the DICOM images and
# also contains a tar file of this image directory.
#
# When a case is completed (responses have been received from each of the four
# institutions), it is moved to:
#
#   amazon:/galaxy/LIDC/req/completed/<seriesinstuid>/
#
# which contains everything listed above (the four directories, plus a directory containing
# the DICOM images and a tar file of this DICOM image directory).  Thus when a case appears in
# the completed/ directory, matching can be performed.
#
# The directory structure as described above is germane to running MAX on the unblinded reads
# for the primary purpose of generating matching and pmap data.  Using MAX for other purposes
# -- namely in the QA process -- require different directory/data environments.

# Pre-requisites and environment
# ------------------------------
#
# Operating system: RedHat Enterprise Linux was used to develop MAX, but MAX can also be run
# under a suitable Windows environment.  See the comments on the Unix utilities below, as well
# as the section on porting to other operating systems..
#
# Perl: perl v5.8.0 built for i386-linux-thread-multi (with 1 registered patch) (see "perl -v")
#
# Various Perl books from O'Reilly have been used in the development of this application.
# References in the comments to various "recipes" refer to chapters/sections in _Perl Cookbook_
# (2nd edition) by Tom Christiansen and Nathan Torkington.
#
# Perl modules:
#
# This script uses a number of additional Perl modules that are probably not installed on your
# system:
#   XML::Twig (depends internally on XML::Parser which you may need to download)
#   Math::Polygon::Calc
#   Tie:IxHash
# These can generally be obtained from CPAN (http://www.cpan.org) if not included in your Perl
# installation. See the "use" statements in this file and in other associated files (such as
# Site_Max.pm) for the names of any additional modules: But except for the modules listed above,
# other modules shown in the "use" statements should be part of the standard Perl installation
# and will not need to be loaded from CPAN.
# 
# To see what modules have been loaded into your environment, try this shell command:
#     perl -MFoo -e 1        # This shows whether the modules "Foo" and "Foo::Bar" are already
#     perl -MFoo::Bar -e 1   #  installed on your system.
#
# Try "man perlmodinstall" to see lots of helpful information on installing modules (especially
# the PREAMBLE section).  The following commands are taken from this man page.  They can be
# executed from the shell prompt.
#     perl -MFoo -e 1        # This shows whether the specified module is already installed 
#     perl -MFoo::Bar -e 1   #  on your system.
#     perl -e 'print qq(@INC), "\n"'  # This shows the directories that Perl searches 
#                                     #  when loading modules.
#     perl Makefile.PL PREFIX=/my/perl_dir  # This installs a module in a particular place rather
#                                           #  than in the default (usually a system directory)
#
# In addition, the distro of this app may include a Perl script called TestSetup.pl that can be
# run from the shell prompt.  Read its comments for more information. If TestSetup.pl is not
# included, just run MAX with the "--help" option as described in the distro's "ReadMe" file.

# Although it is usually preferable to install any additional modules in the standard Perl library
# directories (typically under /usr on a *nix system), you may use the environmental variable
# PERL5LIB (see "man perlrun") if needed to point to additional local modules in non-standard
# locations.  See also http://www.cpan.org/misc/cpan-faq.html -- notably the section titled "II.
# - The Quest for Perl source, modules and scripts".

# Porting to other sites
# ----------------------
#
# An attempt has been made to place all site-specific code and data in the Site_Max.pm module
# for ease in porting the code; users at other sites can edit this file if needed.
# See also these sections: "Background, data organization, etc." and "Assumptions".

# Porting to other operation systems
# ----------------------------------
#
# MAX should run "as is" on any Unix/Linux system containing a properly installed Perl
# environment.
#
# For Windows, you may want to consider ActiveState: To convert to a self-contained ".exe" file,
# see perl2exe (http://www.indigostar.com/perl2exe.htm) or PAR
# (http://search.cpan.org/~smueller/PAR-0.941/script/pp).

# Other utilities, programs, applications, modules, files
# -------------------------------------------------------
#
# Perl modules that need to be specifically loaded:
#   See the "use" statements in the code of this file and in other associated files.  Some
#   modules may need to be downloaded (typically from CPAN) and installed as described elsewhere.
#
# Locally developed Perl modules:
#   Site_Max.pm
#
# "Standard" Unix/Linux utilities:
#
#    less - for displaying input & config files
#    gnuplot - for producing test/debugging plots
#    file - for identifying XML files
#    grep, sed, cut, and tr - for picking out constants and populating various arrays used by
#      the --internals option
#
# Of these, only the "files" utility is mandatory; however, references to it will be bypassed if 
# the XML files are specified explicitly on the command line rather than letting MAX try to find 
# them in the current directory.  Other references to the Unix utilities are optional and do not
# perform vital functions. In other words, if you (1) explicitly name the XML files and (2) do
# not use any of the following options
#   --list
#   --plot
#   --internals
# then the code that accesses the above-named utilities will not be executed.
#
# Windows environments may not contain these Unix utilities, but this is not necessarily an 
# important issue as stated above.
#
# The comment string "#@@@ Code location: UnixUtil-" is used to mark locations in the code
# containing references to these utilities.

# Assumptions
# -----------
#
# See the specification document for MAX (included with the distro).  (Much of the documentation
# that formerly appeared embedded in the source code of MAX has been moved to the spec doc.)

# Matching algorithm description
# ------------------------------
#
# Refer to the specification document.

# XML - history, matching, pmap, etc.
# -----------------------------------
#
# Refer to the specification document and the various schema.

# QA actions
# ----------
# 
# The most up-to-date information may appear in the document titled: "MAX Addendum to LIDC QA"
# 
# The descriptions are based on Sam Armato's QA document.
# Error 1:
#   Description: Errant marks on non-pulmonary regions of the image.
#   MAX actions: Partial detection: MAX detects when there are too few points in an ROI but does
#                not base any of this on anatomical location.
# Error 2:
#   Description: Marks from multiple categories assigned to the same lesion by the same reader.
#   MAX actions: The following intra-reader overlaps are flagged by MAX: small/large nodule,
#                small nodule/non-nodule, large nodule/non-nodule, small/small nodule.  A
#                somewhat related situation is the re-use of IDs in some cases; limited checking
#                and adjustment is performed.
# Error 3:
#   Description: More than a single small nodule mark assigned to the same lesion by a single
#                reader.
#   MAX actions: This is at least roughly equivalent to intra-reader overlap detection between
#                the virtual spheres constructed around small nodule markings.
# Error 4:
#   Description: Large nodule contours for a single lesion that are recorded as separate lesions
#                in each section.
#   MAX actions: This is not currently done but could be added.
# Error 5:
#   Description: Large nodule contours for a single lesion that are not contiguous across sections.
#   MAX actions: This is essentially accomplished by the slice spacing uniformity check.
# Error 6:
#   Description: Large nodule marked by 3 readers during the unblinded read but not marked by the
#                4th reader.  (This is a new version of this error.)
#   MAX actions: This has been implemented.
# Error 7:
#   Description: A large nodule marked by a specific reader during the blinded read that then
#                received no mark at all by that same reader during the unblinded read.
#   MAX actions: This has been implemented.
#
# Processing MAX's QA-related messages:
# MAX is currently able to detect approx. 20 reader-related QA issues; each is presented to the
# user in the form of a user message.  (There are a number of other warnings and errors messages
# that relate to data problems not under reader control [for example, pixels that are neither 4-
# nor 8-connected in an XML file]; these are not considered here.  Also, command line errors and
# internal MAX errors and warnings are not considered here.)  Since
# messages from MAX can be saved into a file (by default, messages.txt in the max/ directory) if
# the --save-messages option is given, the occurrence of any of these QA issues can be detected
# by the following shell command:
#   grep -E \
#     '3401|4403|4405|4406|4407|4409|4410|4503|4504|4505|4506|4507|4509|4510|4511|4512|4513|5501|5502|5503|5504|6602' \
#       messages.txt
# The string of message IDs in this command may need to be updated as MAX is revised.  Use the
# following shell command to see a list of messages somewhat related to QA:
#   max.pl --internaldoc | grep -E '^ [3-6][4-7][0-9][0-9]'
# This is an overly inclusive list from which applicable messages can be chosen.  See MAX's
# in-line help text for more information on user messages.

# Revision History
# ----------------
#
#=== March 9-, 2006: new version release - V1.00, phb
# All major capabilities are included and tested, so we're ready to release (probably should be
#   called a beta release).
#=== March 10 to April 10, 2006: continuing development -- V1.01, phb
# Improve IO code: filehandles, opening (and closing?), etc.
# Add Site_Max to the constants display part of the --internals section.
# Changed some fatal error traps from using die to using print/exit.
# Add tags in the comments to make it easier to pull-out warning/error code:
#   Put this in as a comment:
#     %%!!str!!%% where str is INFO, WARNING, FATAL
#   Then filter these lines out using, for example,
#     grep '%%\!\!FATAL\!\!%%' max.pl
#   Or to generate a list of message strings...
#     grep '%%\!\!.*\!\!%%' max.pl | sed -e 's:\\":\`:g' | awk -F\" '{printf "%d: %s \n   %s \n\n", NR, $0, $(NF-1 ) }' | sed -e 's:\\n::g' -e 's/Stopped//'
#   Or use this regex: ;.*#.*%%!!
# Add code to sub show to deal with missing tags in the NIH (anonymized) version of the data.
# Move @tab to Site_max (and rename to @TAB).
# Add subs accum_xml_lines and write_xml_lines; re-do much of the XML generation code.
# Re-organize the headers of the XML files.
# Begin the marking history XML file.
# Add --skip-num-files-check option.
# Partial re-do of the --savedatastructures code (was called --savefile).  But this is not complete.
# Clarify some of the progress messages.
# Augment the in-line help text that describes how the XML input files are identified, etc.
# Add --dirin (--dirname is an alias with this) and --dirout.
# Convert @contours to %contours to get around memory problems with large datasets: Even the
#   operartion of simply interrogating an array element for whether it is defined
#   causes that element to be autovivified which makes memory usage huge for a big dataset
#   which can, in turn, cause a seg fault.
#   Implications of changing to a hash:
#     * Bounding box and offsets are irrelevant.
#     * 2nd pass is not needed.
#     * If we ever run out of memory using the hash (which seems VERY unlikely based on early
#       experience!), we can probably offer the command line
#       option of tieing it to a disk file.  N.B.: See "perldoc -q 'tied hashes'" (or
#       "man perlfaq4").
# Rename sub dump_contours_arr to dump_contours_hash and re-write it to find the "indices" into
#   the hash via successive use of the keys function on each "dimension".
# Following the model of sub dump_contours_arr, re-code other subs to access %contours:
#   centroid_calcs, simple_matching, and pmap_calcs.
# Convert @pmaparr to %pmap and re-code sub pmap_calcs.
# Add sub reorder_contours.
# Add "&" in front of all INCL, EXCL, etc. constants.
# Remove code for progress bars -- no longer needed!!  Execution is FAST!!
# Re-code the "@stack*" code in sub simple_matching.
# Add another check on the layer flags in sub simple_matching.
# Add $FILLER and use it on sub simple_matching.
# Change INCL, EXCL, SMLN, and NONN from integer constants to strings since when used as hash keys,
#   they get stringified.
# In the code that processes values for the "ops" options (for example, "--xmlops"), change the
#   match operator from "m/something/" to m/^something/".
# Added subs msg_mgr and cleanup.
# --xmlops & --pmapops options: Implement defaults and add some code to show results of the
#   processing these options.
# Removed the constant CENTROIDSEP.
# Get default for $sphere_diam from VIRTSPHEREDEFDIAM (in SiteMax).
# Begin re-coding warnings, errors, etc. to use sub msg_mgr.
# Add the --zanalyze option (only rudimentary "analysis" is done at this point).
# Demote some fatal errors to warnings or to non-fatal errors.
# Add defaults for --dirin & --dirout; see SiteMax.
# Add sub infer_spacing.  Called from the --zanalyze and other sections.
#=== April 10 - 27, 2006: continuing development -- V1.02, phb
# Remove all code related to AVS field creation.
# Update the in-line help.
# Add code in sub simple_matching th check whether a reader marks a small nodule whose sphere
#   overlaps with a non-nodule.
# Augment comments on user msg lines (warnings, errors, etc.) to make them easier to pull out
#   for documentation.
# Add the --comments option.
# Add comment tag sections to subs write_xml_app_header and write_xml_datainfo_header.
# Fix bad logic in setting the 4 "$found" flags in sub simple_matching.
# Remove the code that checked for $foundINCL + $foundEXCL + $foundSMLN + $foundNONN ) != 1 in
#   sub simple_matching.  Don't want it since the earlier checks for various "bad" overlaps no
#   longer result in fatal errors -- only warnings, so even if multiple flags are set, just continue.
# Add code to signal if too few edgemap points are found in an inclusion ROI.
# Fix the code in sub simple_matching that detects & warns about bad overlaps.
# Improve the warning message in sub construct_sphere.
# chomp $rundatetime before using it.
# In sub make_backup: make a backup of a file only if it has size > 0 (so that we don't needlessly
#   wipe-out an existing backup file with a zero-length one).
# Disable the writing of all XML files if we are validating.  (Formerly, matching.xml wasn't
#   written but pmap.xml was due to some missing logic.)
# Modify sub msg_mgr to accept and display a message ID (a unique identifier for each message);
#   add message ID to all messages.
# Begin adding code locator "tags" in the code to aid in coordinating with the spec doc.  For
#   example,
#       #@@@ Code location: A47
#   where the "#" must be in column 1, spaces are exactly as shown, and the label ("A47" in this
#   example) can be anything.
# Change behavior for blinded data: Don't explicitly force an exit at the end of pass 1; instead,
#   exit by default after centroid calculations (which is just before matching) (unless forced
#   to exit earlier by --action).
# Fix a bug in the code that wrote-out the ambiguity XML that was causing too many lines to be
#   written.
# In sub simple_matching, fix the nodule/nodule ambiguity code for a bug in the sizeclass for the
#   XML.
# In sub simple_matching, correct sizeclass mislabeling in the ambig msgs stored in @ambig_msgs.
# Add the --savemessages option: writes the contents of @main::msglog to a file whose name is
#   defined in Site_Max.
# Fix the code that dumped constants from Site_Max.pm.
# Add user message info to the "internals" section (--internals).
# Add additional command line option aliases for naming consistency.
# In the calls to gnuplot via system ("/usr/bin/gnuplot $ScrFile >plotmsgs.txt 2>&1"), change
#   plotmsgs.txt to /dev/null since this output doesn't appear to be important.
# Change "use warnings" to "use warnings FATAL => qw(all)" to be sure that we don't miss any
#   "small" problems.
# Update the POD.
# Remove the "longest diameter" code.  A special version of MAX has been split-off that retains
#   this functionality.
#=== April 28 - June 13, 2006: continuing development -- V1.03, phb
# Edits to the POD.
# The --study-instance-uid command line option was coded in V1.00 (but was not documented).  
#   Keep the code for this as a command line option and in the POD, but comment out the lines 
#   that add it to the XML since the Implementation Group decided that this isn't a mandatory tag.
# Add code to write pmap XML data only if the pmap is non-null; that is, skip the XML if a pmap
#   only contains small nodules.
# At the TooFewPnts code section: Expand the text for msg ID 3401 and rename it as TooFewPnts2;
#   this is informational since this is for a multi-slice nodule (the "too few points" ROI can 
#   be an end cap).  Add section TooFewPnts1 with msgID 4403 which warns about too few points
#   for a single-slice nodule since a mark of this type is probably an accident.
# Add "use FindBin;".
# Clarify the text for message 6201.
# Sub gen_slices: Clarify certain diagnostic messages (for verbose >= 6).  (In conjunction with
#   this, change ZSPACINGTOLFILLIN in Site_Max from 0.001 to 0.0001.)
# Add comments fo show where Unix/Linux utilities are used: "#@@@ Code location: UnixUtil-"
# Modify code that sets $rundatetime *not* to use the Unix date utility.
# Add sub save_large_nod_info for use in implementing QA checking between blinded and unblinded
#   runs.
# Re-do the code for read type.  Parse the <TaskDesription> tag.
# Clarify the text of some of the messages to stdout.
# Augment sub rename_nn_id to prepend NN for IDs consisting of small integers.  (Not robust, but
#   probably OK under the circumstances...)
# Change --save-data-structures to accept a list of values.
# Add sub doit to evaluate saved data (saved via Dumper).
# Convert %centroids to a 3-key hash; was a single-key hash where the keys were 3-element lists.
# Add the --quality-assurance option.
# Store small nodule x & y coords in %centroids w/o offsets.
# Add the --dir-save option.
# Implement the test for QA error #7.
# Add SOP instance UID to pmap.xml.
# N.B.: The Implementation Group "signed-off" on this version of MAX as being ready for
#       production, so we terminate development on this version and start the next...
#=== June 13 - 30, 2006: continuing development, bug fixes -- V1.04, phb
# > June 27: send a version (V1.04b1) to Roger for QA beta testing
# Edits to the in-line help text.
# Implement QA #6.  (N.B.: See below for the implementation of the new vesion of QA #6.
# Remove the code that forces an exit on blinded reads: We need to be able to do matching on 
#   blinded reads in order to implement QA #6.
# Add aliases for --action: --exit-early, --forced-exit
# Expand the code that extracts valid values for --action, --test, --xmlops, etc. for display
#   in the --internals section.
# Re-do the END block; add an informational termination message (ID=3101).
# Re-do user messages (mostly error messages) that didn't use msg_mgr but should have: IDs 6101,
#   6102, 6301, 6302, 6304, 6401, and 5302 (was 6310), as well as the 5 file open sections of
#   code at dummy sub section075__open_files.  Command
#   line errors continue *not* to use this facility; this code uses pod2usage in most (all?)
#   cases.  Now most (all?) messages go to the messages file so that they can be processed in 
#   the case where we run MAX in unattended mode.
# Adjust verbosity levels on many error messages.
# Add --message-type.
# Convert msg id 4404 (inconsistent read type) to 3402.
# Add the <Location...> tag in matching.xml: Gives x,y,z location of small nods & non-nodules
#   and is paired with the <Object...> tag in the <Matching> section.
# Minor reformatting of some stdout output.
# If we see --z-analyze, disable matching and pmap XML generation and skip the requirement for
#   --pixel-size.
# Add diagnostic dump for %z2siu.
# Fix error in filling %z2siu: add "round ( $zcoord, NUMDIGRND )" in non-nodule section (nodule
#   section was OK).
# Bug: Replace 0.001 (!!!) with ZSPACINGTOLFILLIN in call to sub approxeq from sub get_index.  
#   (Checked the code for other such constants, but didn't find any.)
#=== June 30 - Sept. ?, 2006: continuing development -- V1.05, phb
# Get hostname and add it to the greeting line and the XML output files.
# Add a number of informational/status messages (msg IDs = 310<n>).
#=== August 9-10, 2006: minor bug fix
# Add code to prepend the input directory name to filenames passed-in via the --files option
#    and add the --prepend-dir-in command option.
#=== August 30 - Sept. ??, 2006: minor edits, feature addition, phb
# Add --quality-assurance to help summary.
# Clarify the text for message ID 3402.
# Add calls to sub round in subs show_zlist and infer_spacing and in the "foreach ... (@ubRNlist)"
#   loop of sub rSpass1 in the calculation of $spacing.  Without rounding to a fixed number of
#   decimal places (NUMDIGRND in this case, we can have trouble in floating point comparisons.
# Add sub check_smnon_dist ("check small and non-nodule distance") which is called from the QA
#   section in the "post XML" and matching sections.  Does a better job than simple
#   voxel overlap since it computes the distance between the markings.  Used for QA, but can also
#   be used for matching to augment the overlap method.
# Augment the (comment) text in the "Pre-requisites and environment" section.
# Slight format change in sub show_zlist.  Re-do the user messages in the --z-analyze section.
# Add "none" to --quality-assurance.
# Add --data-type & --datatype aliases to --read-type.
# Add code to sub rSpass1 to parse QA tags.  (The Impl. Group decided to defer the addition of QA
#   tags in the XML until later [or never...].)
# Add code to surpress message 5401 id --skip-num-files-check is given.
#=== Dec. 1, 2006: minor edits & feature changes
# Eliminate <Location> tag and move location info into the <Object> tag in the matching XML file.
# Change XML version to 1.01 (VERSIONMATCHINGXML in Site_Max.pm).
# Probably added preliminary implementation of QA tag processing sometime after this date; see
#   sub rSpass1 (array @qAlist, etc.).  This is in the concept/testing stage as the Implementation
#   Group has not agreed to this.
#=== March 5 - May 2, 2007: bug fixes and feature additions; re-work parts of ambiguity processing;
#   re-work & augment QA code; many changes related to user messages
# Add logic to the END block to handle the case where a filehandle couldn't be opened on the 
#   file to save messages into.
# Fix logic for message #3401: In a multi-ROI marking, an ROI containing only 1 point deserves an
#   informational message.
# Minor edits to a few error exit message strings.
# Re-assign some error codes.
# Add the --internaldoc option.  Add comments of the form '#""" User message doc: ...' to document
#   the user messages.  This replaces the "%%!!str!!%%" idea (where str is INFO, WARNING, FATAL, etc.).
# Fix code to save SAVEDATADEFFILENAME in $dirsave (--save-data-structures & --dir-save).
# Rename PNID to SNID ("physical nodule ID" to "series nodule ID").
# Elevate message IDs 5301 & 5303 from non-fatal errors to fatal errors: 6316 & 6317, respectively.
# Re-do some error return messages associated with opening file for output for passing info
#   between runs.
# Added message ID 4512.
# Eliminate the message having ID = 4401 ("At the end of pass 1, small nodules were found,
#   but no large nodules were found; as a result, we may not be able to determine slice spacing").
# Demote message IDs 4501 & 4502 to info message IDs 3504 & 3505, respectively; these pertain
#   to slice spacing inference.
# Added these command option aliases: pixel-spacing & pixelspacing .
# Add %listnonnodseparately to keep track of which non-nodules need to be listed separately in
#   the XML.  (If a non-nodule appears in the ambiguity section, it should not be in the separate
#   list.)  Add <NonNodules><Unmatched> section to matching.xml file.
# Change the <AmbiguousPair> tag to <AmbiguousSet> .  Output ambiguity not pairwise as was done
#   previously, but in sets.  Improve ambiguity processing in general.
# Eliminate @ambig_msgs .  <<<<<< maybe not !!!
# Add --file-in-pattern .
# Add message ID = 6907 in sub secondary_matching.
# Re-organize/simplify sub simple_matching.
# Added message IDs 3107 & 3108.
# Add aliases for --files: --file-name and --fname .
# Add to sub simpleplot: force a 1:1 aspect ratio & add a title.
# Rename sub check_connectivity to check_pixel_connectivity .
# Add sub check_region_connectivity .  Call it from sub rSpass2.
# Add sub check_for_narrow_contour and the value of "narrowcontours" for --qa-ops.
# Add code to discern ambiguity type in sub simple_matching .  This needs more testing and
#   verification.
# Change the time and date attributes of the <RunInfo> tag to be consistent with time & date
#   tags in other XML files.
# Add the --show-slice-spacing-messages command line option.
# Implement new QA #6: Flag an error if not all readers mark a nodule as large on the unblinded
#   read response.  That is, if an SNID consists of exactly 3 large nodule markings, an error 
#   is flagged for the reader not represented.  Add allmarkedlarge as a legal value for
#   --quality-assurance-ops (but actually we don't use this since QA6new is cheap to perform so
#   we'll always do it).
# Copy the msg ID 6602 (no nodules found in the XML) code to just before the call to sub
#   simple_matching.  But keep it also at its earlier location but degrade it to informational
#   at this earlier point.
#=== May 2, 2007 - Feb. 28, 2008: continuing development -- V1.06, phb
# Update and edit the in-line help text.
# Minor re-writes of some text to stdout.
# Clarify the text in user messages 6303, 6306, 6307, 6308, 6311, 6312, and 6315.
# Changes to user messages: Added IDs 3110 & 3201; store these in the messages file.  Modified
#    ID 3109 slightly.
# Modified the code for handling --early-exit values: Shortened forms are acceptable.
# Disable non-nodule intra-reader proximity check by default since non-nodules being close is 
#    for a given reader is reality -- not an error.  Can enable this by giving
#    --qa-ops=nonnodprox on the command line.  (Non-nodule intra-reader proximity is message ID
#    4511.)
# Add code to sub simple_matching to check for intra-reader overlap of large nodules:
#    message ID = 5504.
# Raise verbosity level from 5 to 6 on certain actions: executing sub dump_contours_hash and
#    dumping x,y,z,rdr in sub simple_matching.
# Fix options value listings in the --internals section for XML & pmap options.
# Re-write the code that processes --xmlops & --pmapops.
# Minor re-write of some of the matching XML output code in sub simple_matching.
# Add code to check for consistency of read type and message type between command line options
#   (and/or defaults) and XML file content.  Elevate message ID 3402 from warning to fatal error
#   (ID=6408). (Note added 21 July 2010: There is some confusion here: 6408 is erroneously given 
#   as INFO level; change this as described in July 21-?, 2010 rev notes.) Add message ID 6407.
# Add code for --add-suffix.
# Re-work the code that checks and processes the characteristics data, including improved error
#   checking (messaeg IDs 5402, 5403, 5404 & 5405).
# Added an interrupt (control-C) handler: see sub interrupt_handler.
# Improve the plotting routines: sub simpleplot.
# Enhance sub check_for_narrow_contour: Re-wrote it to detect overlapping pixels as a separate
#   check and moved it from pass 2 to pass 1.  Add NARROWNESSSEARCHOFFSET to Site_Max for use
#   by this sub.  Break msg ID 4408 out into 4409 & 4410 for separate and detailed notification
#   of narrow and overlapping portions, respectively; the notification includes coordinate x & y
#   values in such a way that they can be easily parsed for automated handling of these warnings.
#   Add  "if (grep {/^narrow$/} @testlist)".
# Create alias --debug for --test.
# Regularize the way we report the reader: include both index and ID for message
#   IDs 4509, 4510 & 4511.
# Remove the conditional based on the --show-slice-spacing-messages option (via the
#   $show_sl_sp_msg variable) on user message 4503 (slice non-uniformity problems detected within
#   a nodule); re-word the message text.
# Add code to insert any comments specified via --comments into the message log.
# Add z coord (in mm.) to messages 4509, 4510, & 4511.
# Moved VERSIONPMAPXML, VERSIONMATCHINGXML & VERSIONHISTORYXML to here from Site_Max.pm since 
#   these constants aren't really user-configurable.
# Add a line to sub rSpass1 to add non-nodule info to the %nnninfo hash.
# Fix code at "#@@@ Code location: SlSpacChg" (msg ID 4503): Skip the warning if we just have 1
#   slice.
# Add code to filter the user messages:
#   * Eliminate repetitious, symmetrical messages for proximity between various combos of
#   small and non-nodules: If we say that A is too close to B, we don't need to say that B is 
#   too close to A.  See message IDs 4509, 4510 & 4511.
#   * Not fully implemented: Eliminate repetitious messages about exclusion pixels without
#   corresponding inclusion pixels (ID 4505).
# Add a new --xml-ops value: cxrrequest.  Triggers the writing of an XML file that is used to
#   form the CXR request.  This is done in and around pass1.  It consists mainly of the sections 
#   for all large nodules along with other tags according to the CXR request schema.
# Correct an apparent error in the use of %nnninfo.  Ordinarily used as:
#     $nnninfo{$reader}{$nodule}{"overlap"} = "yes"
#   but in one place as:
#     $nnninfo{$reader}{$nodule} = "non-nodule"
#   This is apparently as error, so changed it to:
#     $nnninfo{$reader}{$nodule}{'sizeclass'} = "non-nodule"
#   --> (Not too important as this hash isn't really used for anything...) <-- OH YES IT IS!!!
# Add code to prepend the contents of the environmental variable MAXOPTS to the command line
#   options.  Define a msg number to show the value of this when defined.
# Add code to handle the case where no markings of any kind are found.
# Make the outputting of msg 3106 ("Centroids have been calculated") conditional.
# Augment the %noduleremap hash with size info (small/large/non-nodule).
# Re-address usage of %nnninfo wrt setting %overlap.
# Fix for a bug apparently introduced in sub simple_matching in V1.05: Before processing 
#   %overlap and assigning SNIDs, we must explicitly adjust %overlap for "solitary" nodules that
#   do not overlap anything.  Base this on what is stored in %nnninfo.  (This 
#   code used to be in simple_matching but we accidentally moved it out in V1.05!)  See "Code
#   location: AdjForSolitary".
# Added "set yrange [] reverse" (gnuplot cmnd) to subs simpleplot & pointplot in order to match
#   the origin used by the drawing tools.
# === Feb. 28, 2008: continuing development -- V1.07, phb
# === June 4 - 13, 2008: minor debugging; new features -- phb
# Changed %e to %d in this stmt: my $rundate = strftime "%Y-%m-%e", localtime; .
# Remove extra spaces from around the "=": <SeriesNoduleID value = \"$nn\"/> .
# Check to be sure we have an even # of readers (for pmap median vol calcs). Add msg ID 5406.
# Compute various volume measures; write-out to the <VolumeMeasures> tag section in the pmap XML
#   file.
# Bump VERSIONPMAPXML to 2.01 b/c of the <VolumeMeasures> tag (haven't been doing this: have made
#   other changes in the pmap xml -- such as changing nomenclature from PNID to SNID -- but didn't
#   increase the version even though some of these changes have made pmap XML parsing incompatible
#   with earlier code!)
# Many edits to the in-line help (including removing some refs to marking history).
# === July 22, 2008: minor edit -- phb
# Add a conditional & a short message around "specific QA tests" for error #6.  (Code location:
#   QA6new)
# === July 25, 2008: minor addition -- phb
# Parse <StudyInstanceUID> from <ResponseHeader> for inclusion in <DataInfoHeader> according to
#   NCI's (MIRC's) needs.
# Correct logic error in adding the <VolumeMeasures> tag section within the <PmapData> tag section.
# === Oct. 28, 2008: minor -- phb
# Improve internal documentation (comment formatting, etc.)
# === Jan. 21, 2009: minor bug fix -- phb
# Modify sub approxeq to work-around divide-by-zero error.
# === Feb. 17, 2009: minor bug fix -- phb
# In sub msg_mgr: Added the exists function in 2 places when checking the hash.
# === March 25, 2009: minor feature addition -- phb
# In sub rSpass1, add code to check that the beginning and ending pixel coords are equal for each ROI.
# === May 13, 2009: minor change -- phb
# In several places, change distance precision in the "mm. apart" message for smalls & non-nods
#   that are close together.
# === July 16, 2009: feature addition, etc -- phb
# Add function modify_reader_id to make anonymized reader names distinctive. Requested by Qinyan
#   Pan for AIM conversion.
# Removed variable $filenum -- not really needed.
# === September 28-29, 2009: change in error response, phb
# Convert FATAL[6409] to ERROR[5407] ("Beginning and ending pixel coordinates not equal in an ROI").
#   Now that this is not a fatal error, we had to adjust the code in sub fill_poly: Function
#   polygon_contains_point that fill_poly calls requires that the 1st & last points be the same
#   in the polygon array; guarantee this by unconditionally appending the first point to it.
#   Also add a connectivity check between 1st & last points to detect a gap (ERROR 5408).
# Add "code => -1" to the call to msg_mgr for ERROR[5406].  (This is the default, but make it
#   explicit!)
# === July 21-9, 2010: minor mods to get ready for release to CIP wiki, phb
# (Will be made available via https://wiki.nci.nih.gov/display/CIP/LIDC.)
# Minor changes to comments & in-line doc.
# Straighten-out confusion concerning what message ID 6408: Change its label from "INFO" to
#   "FATAL", and set its return code properly. (It was formerly an INFO message having ID 3402 --
#   and maybe it should still be "INFO" from the standpoint of QA as noted in the comments in
#   the code!)
#=== March 27, 2013: minor edit by Tom Lampert to fix compilation errors on newer versions of
#   perl (and test execution under Windows - requires cygwin!). Search "Tom Lampert" to find
#   changes.

# Confirmed/verified actions/characteristics
# ------------------------------------------
#
# The following actions or characteristics of the algorithm have been confirmed/verified. (This
# is in addition to the normal debuggung and testing.)  The actions taken in some of these
# situations have been changed in more recent versions of MAX.  This is not an exhaustive list.
#
# * Matching between nodules marked by the same reader should not be allowed.  For example,
#   if a small nodule is marked "close" (less than 3mm separation) to a large nodule, they
#   would overlap according to the simple criterion.  This condition is detected and is treated
#   as a fatal error.
#
# * Interspersal of nodules and non-nodules: Cornell and UCLA/QIWS don't intersperse.  Didn't
#   hear from Iowa/PASS.  Ran a test: apparently this type of ordering doesn't matter to Twig --
#   MAX lists all nodule sections, followed by non-nodule sections regardless of ordering/
#   interspersal.
#
# * Using square nodules, confirmed that inclusions/exclusions are handled properly wrt inclusion
#   voxels "under" and exclusion are set to undefined.
#
# * If an imageSOP_UID value is found in the XML that is not in the series slice data, a fatal
#   error results.
#
# * Confirmed that a nodule lying entirely within the exclusion portion of another nodule
#   (marked by another reader) is not counted as an overlap.
#
# * Used a simple but comprehensive arrangement of nodules to confirm that the pmap generation
#   code works as designed.
#
# * Ran MAX against a number of our completed cases and compared with Sam's manual QA
#   spreadsheet: Looked at basic matching, pmap generation, ambiguity, exclusions.
#
# * Confirmed proper operation with data having solitary large & small nodules (nodules that
#   overlap with no other nodules and thus have their own SNID) both with & without overlapping
#   non-nodules.

# Known bugs, limitations
# -----------------------
#
# * Sub rename_nn_id is a kludge and is needed only to allow a small number of cases to process
#     normally; its algorithm for detecting the need to rename the IDs is not robust but
#     probably OK...
# * There seem to be problems in ambiguity detection in some circumstances -- especially
#     when there are a large number of nodules & non-nodules?
# * In sub simple_matching, there is the following note:
#     "Should inspect %ambig_list (or generate a separate structure above) to see if there
#     is more than 1 ambiguity (must adjust the algorithm accordingly).  Could add another
#     key to %ambig_list: store an index to the ambiguity sets in the added key."
# * Not all combos of overlap within the same reader are checked for:
#     We are currently checking all combos except non/non overlaps (these
#     are somewhat more complicated to check for -- maybe the dwg apps should do these!  Plus 
#     non-non overlap isn't really an issue).  (Non-nodule/small was added in V1.02.)
# * QA #6: We are using centroidal separation to detect "matching" between blinded & unblinded,
#     but this is not as good as voxel overlap as we do for "regular" matching.  N.B.: This is
#     the original/old/obsolete version of QA #6.
# * Check for the same small nodule being marked more that once ala Roger's email of 5/19/2006.
#     This is a variation on QA #3; MAX does this to a degree, but could be improved.
# * In sub get_index, may want to replace sub approxeq with a closest match operator to make this
#     more robust against floating point equality uncertainty and rounding.  Do this in other
#     places as well?
# * What happens with matching and ambiguity when IDs are reused (1) between nodules and 
#     non-nodules and (2) between non-nodules?  This practice was apparently discontinued after
#     of July 1, 2005 so it might not be worth dealing with.  Just affects the 1st 30 cases
#     for Cornell.  See the ReusedIDs.sh script.
# * We don't generally check the values given to cmnd line args: see below.  For example, illegal
#     values for --action are not detected; they are just ignored since they never match any
#     of the greps in the code.
# * In checking hashes for existence of elements, use the exists() function.  Check the Perl
#     man page for proper application of this.
# * Do a better job of closing files: see below.
# * The config file reading code is only partially implemented -- doesn't work too well.  But do
# *   we really need this???
# * The plotting routines are pretty bad, but they are generally used only during development
#     so they're probably OK.

# To do, future ideas, limitations, "issues"
# ------------------------------------------
#
#=== Error/warning/info message handling:
# * Eliminate/filter repetitious messages: 4505 (exclusion outside an inclusion) (this is
#     provisionally completed); 4509, 4510 & 4511 (various combos of small and non-nodules in
#     close proximity) (completed); 4409 & 4410 (narrow and overlapping sections); 4504 
#     (constructed sphere overlaps an existing voxel).
# * Elevate 3401 (too few points) to a warning???
# * There are still some messages in the old format (using die, etc).  (Search for "die" from
#     the end of the file.)
# * Do a better job of detecting if a required value is omitted from an option (test the return
#     code from GetOptions).  Also check to see if values are correct type: integer, float, etc.
#     Check the values given to cmnd line args: for example, should check for valid number
#     for --pixelsize, --slicespacing, --verbose, etc.  See the "validate input" article in my
#     Perl Usenet directory.
# * Extend user message output to write an XML file (is this really necessary?).
# * It would be nice to catch errors from the call to GetOptions with our own handler to make
#     them easier to see on the screen.  See "man GetOptions::Long".
#     For now, configure GetOptions with pass_through and deal with extra/bad things myself.
#     Look into "use Error ':try';" and the "try { } catch Exception with { } finally" construct.
#     > Other ideas: Allow files to be specified on the cmnd line.  Here are some hints for this:
#     >   Eliminate passthru, check error return from GetOptions, check @ARGV, etc.
# * Try Carp.
#=== QA:
# * Move all or most "small" QA tests to pass 1.
# * Add a check for max no. of nodules (according to acceptance criteria).  Put this number in
#     Site_Max (but allow override by cmnd line arg).  Check on blinded only?  Check on a per-
#     reader basis.  Issue a warning -- not an error.
# * Do more validation/checking in rSpass1.
# * ERROR 5501 is in the matching code, but it may also be appropriate to include it earlier as
#     a QA check (not sure which one of Sam's QA errors it corresponds to).
# * Finish implementing various QA measures as outlined in Sam's document.
#   - Defer implementation of Sam's QA #4 for now: A large nodule is marked on several slices but
#     not "tied" together properly into a single nodule.  This was seen only once so far.
# * Check for the same small nodule being marked more that once ala Roger's email of 5/19/2006.
#     This is a variation on #3; MAX does this to a degree, but could be improved.
# * Be sure that we can detect if slices are skipped in a regular pattern in a set of ROIs
#     (for example, what if alternating slices are marked?).  We can detect this in some cases
#     now via the uniformity checking code.
# * Add comments to QA XML to note, for example, that a QA suggestion was acknowledged but was
#     purposely ignored.  (This idea pertains to QA XML tags which aren't implemented yet.)
# * Add call to xmllint (with --noout) (if available) for a "properly formatted XML" check.
#=== Functionality/correct operation:
# * Create a test suite.  (For now see the directories under Peyton's testsuite/ dir tree for
#     very simple test setups.)
# * In constructing spheres around small nodules, we ignore problems of constructing a sphere on
#     an anisotropic grid.  For example, might need to handle round-off problems by rounding 
#     differently for in-plane & out-of-plane directions.
# * Sub approx_eq should include an option to operate in absolute differences rather than always
#     in relative.  (But maintain the use of tolerance.)
# * Ambiguity needs more testing/verification.
# * In "Code location: AmbigProc1a", see the "N.B." note about adding a consistency check
#     in reading the set info from %ambigsets1
# * Be sure that we're rounding where we need to -- all Z calcs & comparisons!
# * Add code to check for message type consistency as we do for read type (msg ID 6406).
# * Add better status/progress indicators while processing slow parts (such as parsing through
#     the XML -- needed with big files).
# * XML parsing...
#   - Automatic detection of data type (blinded/unblinded) and message type (request/response)
#     or make the parsing code so that it doesn't really care what it gets.  This would make
#     it easier to setup for certain QA operations since QA operates on almost all kinds of files.
# * XML writing...
#   - Write schema for the XML produced by MAX.  Consider writing a single schema that can be used
#     by both the pmap and matching (and history?) (and size metrics? -- see below) XML files.
#   - Finish the code to write history info out to XML files.  (Defer this pending decision by
#     Impl. Group.)  Write separate files for blinded and unblinded (which means that we wouldn't
#     combine history XML with pmap and matching if we decide to combine them).
#   - QA & history: Record changes made to the markings after the reading session is closed
#     according to Impl. Group decision.  (This isn't really a MAX issue...)
# * Sub rename_nn_id improvements:
#   - Move its constants to Site_Max.
#   - Extend to allow a list of site names to be handled.
#   - Extend to append an incremented string to the end to differentiate repeated non-nodule IDs.
# * Finish the help text -- including updating the XML info.
# * Size metrics: Sam, Chuck, and Tony are working on this.  This would include the "largest
#     diameter" code which has been removed from MAX!!!  When we restore it, will write out the
#     results in XML.  Other size metrics will be developed and coded.
# * Augment the --zanalyze option: list Z coords (and uniformity and spacing) for each feature 
#      found and overall spacing.  Accumulate this in an array and dump out at END.  Note what 
#      kind of objects are present at each slice.  Include info to help see non-uniform slice
#      spacing.
# * Add a --dirimageinfo option to point to dir where DICOM images are located; add code to get
#     pixel size and slice spacing from the images (or read them from files if available).  This
#     is quite site-specific, so this has a low priority.
# * File open and close calls:
#      Check all for...
#        error checks
#        consistent syntax
#        use of lexical filehandles
#        use of the 3-argument form of open
#      From Ben Morrow on clpm:
#         If you use lexical filehandles, there's no need to explicitly close
#         files opened for reading. Files opened for writing should be explicitly
#         closed, and the return value of close checked, to catch errors writing
#         (such as a full disk). close will return an error if any of the writes
#         failed, so there's no need to check each print (unless you are expecting
#         errors and want to abort early).
#             close $XML or die "can't write to $file.xml: $!"; 
#      Add open & close to the plotting routine scratch files.
#      Learn how to close all in END section or is this really necessary?  Yes -- from the
#      Cookbook...
#         These implicit closes are for convenience, not stability, because
#         they don't tell you whether the system call succeeded or failed.
#         Not all closes succeed. Even a close on a read-only file can fail.
#         For instance, you could lose access access to the device because
#         of a network outage. It's even more important to check the close
#         if the file was opened for writing. Otherwise you wouldn't notice
#         if the disk filled up.
#      Don't know how to check filehandles to see if they are in use.  May just close all of
#        them that could possibly be open and disregard the errors.  <-- not good to disregard
#        errors!!
#      From c.l.p.m Usenet group:
#         # Untested
#         use warnings;
#         use strict;
#         use FileHandle::Fmode qw(:all);
#         my $fh;
#         # (optionally) other code that does stuff
#         if is_arg_ok($fh) {print "\$fh is a file handle to an open file"}
#         else  {print "\$fh is NOT a file handle to an open file"} 
#      Perl function fileno would probably work: see perldoc -f fileno
#      Or keep a list of opened filehandles and process (close the FHs) the list on exit.
#      See perldata.
# * We probably need some way to manually specify which nodules overlap which would override
#     the decisions made by MAX.  This would follow some manual editing to arbitrate 
#     "difficult" cases.  Re-visit this only after an "official" decision by the Impl. Group.
# * Catch errors from GetOpts and display them better to the user.  (Tried the try/catch/finally
#     method but couldn't get it to work.)  Try Carp.  But our current method is pretty good.
#     > Check the status code returned by GetOpts (?).
# * The config file reading code probably doesn't work: Try the "eval `cat $file`" method as we
#     did in the old fake Z data section of get_zinfo().  But the file could be laced with evil 
#     code.  May want to re-visit this.  See Recipe 8.17.  Also, see CPAN for a config module.
# * Develop the --savedatastructures code further if needed.
#=== "User friendly":
# * Clarify the results of matching, etc. that are written to stdout.  Unclutter the output.
#      Be sure that important info is communicated to the user.
# * Translate layer number in %contours to a phrase according to %layer_list.
# * Add "common" names for the sites: Michigan, Cornell, UCLA, Iowa, Chicago.  Put this in a
#      hash in Site_Max.
#=== Code maintainability:
# * We are storing reader info in two places: @servicingRadiologist and %reader_info .  Can
#      probably replace
#          $servicingRadiologist[$r]
#      with
#          $reader_info{$r}{'id'}
#      And might want to simplify $servicingRadiologistIndex to $reader_index .
# * Remove/simplify code that was originally written as a result of @contours, bounding box/
#      offsets, pass1/pass2, etc.
# * There are places where we do this:
#      my $numrois = $ubRNindex->children_count('roi')
#   then later have this in an "if" test:
#      $ubRNindex->children_count('roi') == 1
#   rather than using
#      $numrois == 1
#   in the "if" test.  Same for $numem .
# * Re-code to use sub cleanup.  We need to do this in about 8 places.
# * Improve code readibility (especially comments).  See man perlstyle.
# * Eliminate calling external Unix/Linux utilities; re-code in Perl instead as much as possible.
#     For example, replace file with File::MMagic .  But all uses of *nix utils can be 
#     avoided as they are in optional sections of the code or in the case of the file utility, 
#     just specify the files explicitly using --file.
# * Break into more subs.
# * "Magic numbers" are used for initial values of $minx, $maxx, $miny, $maxy, $minzc, 
#    and $maxzc.  Do this better.  Similarly for pmapinfo in routine pmap_calcs().
#    Is there a Perl module that gives things like MININT & MAXINT?
#    Or localize this to two constants in SiteMax: MINPIXELCOORD & MAXPIXELCOORD
#    Other "magic numbers" in the code that should be turned into constants or handled better:
#      * see sub rename_nn_id
#      * keyword strings associated with the --xmlops option (and other options...)
#      * strings in grep and in the "m/.../" construct
#      * strings in the XML parser code (subs rSpass1 & rSpass2) -- will probably leave these alone
#      * ";;" is used in forming the keys for %ambigsets
# * Do a better job with constants: see Recipe 1.21 -- or eliminate them.  N.B.: Constants as
#      I have implemented them should be preceded by a "&"  or with () at end of the name (see
#      http://perldoc.perl.org/constant.html) when used as a hash key.
#=== Other/misc.:
# * Looks like we might not need "-output => \*STDERR" in the call to pod2usage to show the 
#     help text.  (The "|" looks OK???)  Another idea to allow "|" to display corrrectly is to 
#     set LANG to null ("") before running MAX.
# * --early-exit value doesn't need to be an array; scalar string would be fine.
# * Speed-up the algorithm in sub check_region_connectivity .
# * Speed-up file I/O (especially writing) by using File::Slurp ...
#     use lib "/user/bland/perl/lib/perl5/File-Slurp-9999.09/lib";
#     see http://cpan.uwinnipeg.ca/htdocs/File-Slurp/File/Slurp.pm.html
#     (but is this really a problem?  some large files process VERY slowly!)
# * Consider secondary overlap measures.
# * There is no namespace processing for the XML (but this is probably OK).

# Coding notes
# ------------
#
# Use these lines to delimit debugging/diagnostic code sections to cause them to be skipped.
=begin ++++++++++++++++ begin diagnostic code section +++++++++++++++++
=cut +++++++++++++++++++ end diagnostic code section ++++++++++++++++++
#
# Debugging help:
# print "We are at line ", __LINE__, " in file ", __FILE__, "\n";  # see "man perldata"
# We also use conditionals on print statements that look like this:
#   print " +++ here we are +++ \n" if ( $verbose > 5 || 0 );  # change the 0 to 1 to force execution of the print stmt.
# or sometimes, the above but with only the "if ( 0 )" part.
#
# Cross referencing:
#   perl -MO=Xref junk.pl > junk.plx  # look at options for Xref: -MO=Xref[,OPTIONS]
#
# For dumping structures:
#   print "dump of the \%x hash (at line " . __LINE__ . ")...\n", Dumper(%x), "\n" if ( $verbose >= 5 || 0 );  # 0: conditional dump; 1: always dump
#
# Instead of Dumper, try...
#     use Dumpvalue; 
#     Dumpvalue->new->dumpValue($somevar);
#   >> not sure if this is right -- see man page
#
# Other notes appear in the code.

# User message codes
# ------------------
# 
# See the spec doc.

# Picking out user messages from the code
# ---------------------------------------
#
# Use the --internaldoc option to display message IDs and corresponding descriptive text which
# is embedded in the code as specially formatted comments.
# (This replaces the obsolete method described below which is used sporadically in the code.)
# The --internaldoc option also displays info on the return codes which is embedded in Site_Max.pm .
#
# <obsolete>
# We have added tags in the comments to make it easier to pull-out warning/error code:
#   Put this in as a comment:
#     %%!!str!!%% where str is INFO, WARNING, FATAL
#   Then filter these lines out using, for example,
#       % grep '%%\!\!FATAL\!\!%%' max.pl
#   Or to generate a list of message strings...
#     * % grep -n '%%\!\!.*\!\!%%' max.pl | grep -v -E '^#' | sed -e 's:\\":\`:g' | awk -F\" '{printf "%s \n   %s \n\n", $0, $(NF-1 ) }' | sed -e 's:\\n::g' -e 's/Stopped//'
#   Or use this regex: ;.*#.*%%!!
# Other messages are handled via calls to sub msg_mgr:
#     * % grep -A 7 'msg_mgr (' max.pl | grep -E 'msg_mgr|severity|text|msgid' | sed 's/^[ \t]*//' | sed 's/msg_mgr/\nmsg_mgr/'
# * Use these two to make a list of message blocks in MAX.  Save them to a file.
#   To extract a list of message IDs that have been used (along with a count to show duplicates)...
#     % sed -n -e 's/^\(.*msgid => \)\(.*\)\(,.*$\)/\2/p' -e 's/^\(.*\[\)\([0-9][0-9][0-9][0-9]\)\(\].*$\)/\2/p' max.pl | sort | uniq -c
# </obsolete>

# Command line options, read type & message type, XML tags, etc.
# --------------------------------------------------------------
#
# MAX is designed to analyze three of the four types of XML message files used by the LIDC (all
# but blinded request messages).  This processing is controlled by a number of variables which
# are set via the read type and message type command line options (or their defaults).
#
# In all the tables below, the values of the variables are indicated in single quotes, 
# and the names of the Perl constants used to set them and test them are indicated in upper case
# below the variable values.
#
# The first two tables show how the read type and message type command line options are processed.
# (Minimum abbreviations are shown for the option values.)
#
#   --message-type  $messagetype_optval (1)   $messagetype_tag (2)
#        option           variable                  variable      
#   --------------  -----------------------   --------------------
#                                                                 
#       resp        'response' (default)        'ResponseHeader'  
#                     RESPMESSAGETYPEVALUE        RESPHDRTAGNAME  
#       req         'request'                   'RequestHeader'   
#                     REQMESSAGETYPEVALUE         REQHDRTAGNAME   
#
# (1) This is an expanded version of the value specified with the --message-type option.
# (2) This is set based on the $messagetype_optval variable.
#
#   --read-type     $readtype_optval (3)      $readtype_tag
#     option              variable               variable  
#   -----------     ------------------------  -------------
#                                                          
#      unbl         'unblinded' (default)       See        
#                     UNBLINDEDREADTYPEVALUE      table    
#       bl          'blinded'                       below  
#                     BLINDEDREADTYPEVALUE                 
#
# (3) This is an expanded version of the value specified with the --read-type option.
#
# This table shows the interactions among read type & message type, XML tags, and Perl variables.
#
#     file     <TaskDescription>  --message-type  --read-type  $messagetype_tag     <*Header>        $readtype_tag (4)         <*ReadNodule>    
#     type         tag value          option         option        variable         tag name             variable                 tag name      
#   ---------  -----------------  --------------  -----------  ----------------  ----------------  ----------------------  ---------------------
#                                                                                                                                               
#   blinded     First                 n/a             n/a          n/a           <RequestHeader>           n/a                     n/a          
#    request     blinded read                                                                                                                   
#                                                                                                                                               
#   blinded     First                 resp          blind      'ResponseHeader'  <ResponseHeader>  'blindedReadNodule'     <blindedReadNodule>  
#    response    blinded read       (default)                    RESPHDRTAGNAME                      BLINDEDREADTAGNAME                         
#                                                                                                                                               
#   unblinded   Second                req           unblind    'RequestHeader'   <RequestHeader>   'blindedReadNodule'     <blindedReadNodule>  
#    request     unblinded read                    (default)     REQHDRTAGNAME                       BLINDEDREADTAGNAME                         
#                                                                                                                                               
#   unblinded   Second                resp          unblind    'ResponseHeader'  <ResponseHeader>  'unblindedReadNodule'   <unblindedReadNodule>
#    response    unblinded read     (default)      (default)     RESPHDRTAGNAME                      UNBLINDEDREADTAGNAME                       
#
# (4) This is set based on the $messagetype_optval and $readtype_optval variables.

# Rough roadmap of execution of the code
# --------------------------------------
#
# This was constructed mainly to track access to the %contours hash.  May not be quite up-to-date.
#
# subroutines/main sections                             secondary operations
# -------------------------                             --------------------
#
# rSpass1
#  * gather info for bounding box
#
# intermediate_calcs
#  * generate @allz and related arrays & variables
#    (including @zmatch)
#
# rSpass2
#  * populate %contours
#  * construct spheres
#    (build %spherez)
#
#                                                       update @zmatch from %spherez
#
#                                                       optionally execute sub dump_contours_hash
#
# centroid_calcs
#  * loop over %contours
#
#                                                       optionally execute sub dump_contours_hash
#
# initial_matching
#  * loop over %contours
#
# pmap_calcs
#  * loop over %contours
#

# Execution speed
# ---------------
#
# On a Dell PE1750 (dual 3.06GHz hyperthreaded CPUs with 4GB memory), approx. 1 sec. of elapsed
# elapsed time is required for each 20KB of total XML file size (for 4 readers); matching and
# pmap XML files are produced.  (However, a case with 765KB total XML file size took approx. 70
# sec. -- about half the rate for smaller files)  Most of the time seems to be taken to process 
# the XML rather than to perform the matching, pmap generation, etc.

# ==========================================================================
# =                                                                        =
# =        B R I N G   I N   T H E   M O D U L E S   W E   N E E D         =
# =                                                                        =
# ==========================================================================
sub section010__use_stmts {}  # a dummy sub that lets us jump to this location via the function list in our editor

# Start with the usual stuff...
use strict;
use diagnostics;
use warnings FATAL => qw(all);  # This may seem severe, but we want to be sure that we see all warnings

# Here are some particular modules that we need:
use POSIX qw(strftime);  # add this for formatting localtime output
use Data::Dumper;  # useful for general diagnostic purposes
use Getopt::Long;  # this allows command line processing with long ("--") options
use Pod::Usage;    # error/usage message and in-line help processing
use XML::Twig;     # we use Twig methods for all XML parsing
use Cwd;  # this gets us getcwd()
use File::Basename;  # this gets us dirname()
use Sys::Hostname;  # this gets us hostname()
use File::Temp qw/ tempfile /;  # this is used by subs simpleplot & pointplot
use Tie::IxHash;   # contains routines that preserve order of XML tags in hashes
use Math::Polygon::Calc;  # we use this to fill the contours

use IPC::Open2;

# Add the directory that MAX lives in to the module/library search path:
use FindBin;
use lib "$FindBin::Bin";

# Site-specific:
use Site_Max;  # our own package that contains site-specific data; may need to be edited by each site.


# ======================================================
# =                                                    =
# =        S O M E   P R E L I M I N A R I E S         =
# =                                                    =
# ======================================================
sub section030__prelims {}  # a dummy sub that lets us jump to this location via the function list in our editor

# Get some info pertaining to the running of this script:
my $runcmnd = "$0 @ARGV";
my $rundatetime = strftime "%a %b %e %H:%M:%S %Z %Y", localtime;
my $runtime = strftime "%H:%M:%S", localtime;  # We'll use these two specially formatted
my $rundate = strftime "%Y-%m-%d", localtime;  # strings in the <RunInfo> XML tag.
my $curdir = getcwd();
my $hostname = hostname();
my $runenv = sprintf "Executing on host %s on %s from directory %s", $hostname, $rundatetime, $curdir;

# The greeting line:
my $version = "1.07b";  # edit this for correct version...
my $datetime = "2013-03-27 18:00:00 GMT";  # ...and date/time of this particular "build" (ideally the date/time of saving the file)
# ($verbose is not available to us at this point, so we print these lines unconditionally.)
print "\nMAX: Multipurpose Application for XML -- max.pl: version $version ($datetime)\n\n";
#print "Executing on host $hostname on $rundatetime from directory $curdir \n\n";
print "$runenv \n\n";

# Generate messages for insertion into @main::msglog
#""" User message doc: 3109: A display of the greeting line.
msg_mgr (
    severity => 'INFO',
    msgid => 3109,
    text => my $text = ( sprintf "Executing max.pl version %s (%s). ", $version, $datetime ),
    accum => 1,
    screen => 0,  # doesn't need to be displayed on the screen since we've already shown this info above
    code => -1
);
#""" User message doc: 3110: A display of the run environment.
msg_mgr (
    severity => 'INFO',
    msgid => 3110,
    text => $runenv,
    accum => 1,
    screen => 0,  # doesn't need to be displayed on the screen since we already did this above
    code => -1
);

# Some message/status lines are output (to stdout) with a trailing "\r"  rather than the usual "\n" 
# to allow overprinting.  Set a variable ($OUTPUT_AUTOFLUSH) to force flushing of these lines --
# or more accurately, to force flushing the buffer more often.
$| = 1;
# We also need to force flushing in order for the stderr redirect to work as desired.

# Re-direct stderr to stdout so that everything go to the same place...
open STDERR, ">&STDOUT";
# N.B.: This works together with setting $| = 1 as done above.

# Set-up a sub to jump to when the user hits control-C:
$SIG{INT} = \&interrupt_handler;

# We probably don't need this since we're using the "use warnings FATAL" pragma, but anyways...
print "Pause to allow us to see any initial diagnostics as we begin execution.\r";
sleep ( defined $ENV{"MAXSLEEP"} ? $ENV{"MAXSLEEP"} : 0 );
print "                                                                       \n";  # "erase" the "Pause" line above

# Tighten-up the indentation a bit for Dumper output (default: 2)...
$Data::Dumper::Indent = 1;


# ==================================================
# =                                                =
# =        G L O B A L   V A R I A B L E S         =
# =                                                =
# ==================================================
sub section040__global_vars {}  # a dummy sub that lets us jump to this location via the function list in our editor

# These data structures are defined below in the constants section (Keep it there so that it will be
# included in the report with other constants when the --internals option is given.):
my %layer_list;
tie %layer_list, "Tie::IxHash";  # preserve ordering
my @AMBIG_TYPE;  # see also the "constant section" below and sub get_ambig_type

# Even though it is discouraged by the Perl community in general, extensive use is made of global
# variables to simplify communication between various parts of this app.  This, of course, prevents
# many of the subroutines from being of general use, but it is unlikely that this is a real issue.

# Constants (for global use):
# Reference any constants defined with "use constant" as CONSTNAME (without a "$").
# For example...
#   print DIAMTHR / 2.0, "\n";
#   my $x = DIAMTHR; print "$x\n";
#   my $d = (6*10/PI)**(1./3.); print "for V=10, d=$d\n";
#   exit;
#
# N.B.: Keep the "begin constant section" tag and the corresponding "end" tag.  They allow this
#       section to be extracted and displayed; see the --internals option.  Be sure all constants
#       are placed in this section.
#
# ++++++++++ begin constant section ++++++++++
#
# This section contains constants that probably don't need to be changed.  For other constants
# that might need to be fine-tuned or customized by the sites, see Site_Max.pm.
#
use constant PI => 4 * atan2(1, 1);

use constant DEFVERBOSE => 3;  # default to a middle level of verbosity

# Various XML versions.  These *will* need to be changed if the XML is changed.
use constant VERSIONPMAPXML     => '2.01';
use constant VERSIONMATCHINGXML => '1.02';
use constant VERSIONHISTORYXML  => '1.00';
use constant VERSIONCXRREQXML   => '1.02';

# These are "magic strings" that appear in the XML.  (But not all such XML "magic strings" appear
# here: there are LOTS of other "magic strings" that appear in routines rSpass1 and rSpass2.)
use constant UNBLINDEDREADTAGNAME => 'unblindedReadNodule';  # These are the 
use constant   BLINDEDREADTAGNAME =>   'blindedReadNodule';  # names of XML tags
use constant       RESPHDRTAGNAME => 'ResponseHeader';       # defined
use constant        REQHDRTAGNAME =>  'RequestHeader';       # in the schema.

# Some more "magic strings" used to describe the read type...
use constant UNBLINDEDREADTYPEVALUE => 'unblinded';
use constant   BLINDEDREADTYPEVALUE =>   'blinded';
# ...and message type...
use constant  REQMESSAGETYPEVALUE => 'request';
use constant RESPMESSAGETYPEVALUE => 'response';

# Pertaining to the <characteristics> tag:
my @char_props = qw ( subtlety internalStructure calcification sphericity margin lobulation spiculation texture malignancy );  # list of properties
my $NUMCHARACTERISTICS = ( scalar @char_props );  # the following didn't work: use constant NUMCHARACTERISTICS => ( scalar @char_props )
use constant MAXCHARPROPVALUE => 6;  # from the schema

# Default values for some config variables:
use constant NCSthrDEF => 1000.0;  # Large values like this effectively disable any
use constant  VRthrDEF => 1000.0;  # "filtering" in secondary matching based on these measures.

# We wanted to setup some constants like this...
#      use constant OMITTHIS  => "OmitThis";
#      use constant NONODULE  => "NoNodule";
#      use constant NOREADER  => "NoReader";
#      use constant NOOVERLAP => "NoOverlap";
# ...but this didn't seem to work consistently with string comparisons (or maybe I wasn't using
# these correctly in the hash?).  So some constants are defined in the regular way (but in
# upper case to make them stand out)...
# These variables are used as markers for various purposes (and we assume that no nodules will ever
#   be labeled with any of these):
my $FILLER    = "Filler";     # a marker used to occupy an array position in some little arrays used in matching
my $OMITTHIS  = "OmitThis";   # a marker to signify that we should omit this nodule from the pmap
my $NONODULE  = "NoNodule";   # a marker to signify that there is no nodule to specify
my $NOREADER  = "NoReader";   # a marker to signify that there is no reader to specify
my $NOOVERLAP = "NoOverlap";  # a marker to signify that there is no overlap between nodules

# Define a layer phrase list to make nicer output reporting:
%layer_list = (
  EXCL => 'exclusion',     # access it via mnemonic keys...
  INCL => 'inclusion',
  SMLN => 'small nodule',
  NONN => 'non-nodule',
  0 => 'exclusion',        # or numeric keys
  1 => 'inclusion',
  2 => 'small nodule',
  3 => 'non-nodule'
);

# Define a 2D array that codes ambiguity type based on the number of nodules and non-nodules in an ambiguity set.
# Possible types (not all are present/implemented in the array nor in the table below):
#   nodule
#   non-nodule
#   mixed
#   probably/maybe * (a modifier to the above)
#   indeterminate/unknown/undefined/uncertain
# The make-up of the members of an ambiguous set and the resulting type:
#   no. of nods.  no. of non-nods.  nodule  non-nod.  mixed  indet/...  not poss.  comments
#   ------------  ----------------  ------  --------  -----  ---------  ---------  --------
#        0               0                                                  x              
#     1 or 2             0                                                  x              
#    3 or more           0             x                                                   
#        0          any number                                              x              
#     1 or 2        any number                  x                                          
#    3 or more      any number                                   x                         
# Encode this table as a 2D array where the 1st "index" is the no. of nodules and the 2nd is the no. of non-nodules.
$AMBIG_TYPE[0][0] = 'internal error';
$AMBIG_TYPE[1][0] = 'internal error';
$AMBIG_TYPE[2][0] = 'internal error';
$AMBIG_TYPE[3][0] = 'nodule';
$AMBIG_TYPE[0][1] = 'internal error';
$AMBIG_TYPE[1][1] = 'non-nodule';
$AMBIG_TYPE[2][1] = 'non-nodule';
$AMBIG_TYPE[3][1] = 'indeterminate';
# Set the maxima for later use according to the indices above; the minima are 0
my $maxATindex1 = 3;
my $maxATindex2 = 1;
# Index into the array to pick-up the value which is the ambiguity type descriptor.  Note that the
# 1st index is restricted to 0..$maxATindex1 and the 2nd to 0..$maxATindex2 and as such, the code 
# that accesses this array must abide by these limits; see sub get_ambig_type.

# Rounding term for use in constructing the sphere around small nodules:
# ! Currently unused !
use constant RO => 0.5;  # set to 0.0 to disable rounding

# ++++++++++ end constant section ++++++++++

# Related to the file that holds MAX and related script files:
my $MAXfname =           $0;
my $SMfname  = dirname ( $0 ) . '/Site_Max.pm';

# Variables related to filenames and IO handles:
my ( $historyxmlfile, $cxrreqxmlfile, $matchingxmlfile, $pmapxmlfile, $savefile, $messagesfile, $lnifile, $lni1file );  # filenames
my ( $historyxml_fh,  $cxrreqxml_fh,  $matchingxml_fh,  $pmapxml_fh,  $save_fh,  $messages_fh,  $lni_fh,  $lni1_fh  );  # file handles
# Variables for the messages file are declared and set in the command line processing section.

# Accumulate any comment tags from the incoming XML for storage in the XML files that MAX creates:
my %cmnt_tags;

# A flag to indicate whether the main header tag was found as expected.  (Reset before parsing each file,
# set in sub show, and checked in sub rSpass1.)
my $headertag_ok;

# Related to getting, parsing, and setting the read type...
#  $readtype_optval   # this is the value picked up from the --read-type cmnd line option (this is "declared" elsewhere)
my $readtype_tag;     # this is set to one of the constants UNBLINDEDREADTAGNAME or BLINDEDREADTAGNAME (see above)
my $readtype_parsed;  # this is parsed from the <TaskDescription> tag in the header
my %readtype_list;    # use this to keep track of whether we see more than one read type in the set of XML input files
#...and message type...
#  $messagetype_optval  # this is the value picked up from the --message-type cmnd line option (this is "declared" elsewhere)
my $messagetype_tag;    # this is set to one of the constants REQHDRTAGNAME or RESPHDRTAGNAME (see above)

# We use a global array @main::msglog to hold warnings and other messages that might fly by too 
# fast on the screen.  We will dump it to stdout at the end of the script (in the END block).
# Note that the manner in which it is referenced (prefaced with "@main::") makes it accessible
# from all modules and packages and that as a result, a "my" "declaration" is not only 
# unnecessary but illegal.
my $msgstr;  # holds text that will be added to @main::msglog and probably also output to stdout
# Example of use:
#   $msgstr = "Warning: We found an inconsistency at x = 1.2";
#   $msgstr = sprintf("We are at line %d", __LINE__);
#   push @main::msglog, $msgstr;  # this line is superceded by calling msg_mgr with "accum => 1"

# Use this to construct the message concerning duplicate non-nodule IDs that we find:
my @dupnnid_msg;  # filled in sub rSpass1 but also needs to be accessed globally

# For use with the --validate switch to allow testing the exit status.
my $validatestatus;

# A short phrase displayed upon exiting (in the END block) telling the reason for exiting.
my $exit_msg;

# Some config variables...
# These are for secondary matching which we are not doing now.
# "NCS" = "normalized centroidal separation" -- see secondary matching code
# "VR" = "volume ratio" -- see secondary matching code
my ($NCSthr,$VRthr);  # These will probably be set to defaults later.

# Accumulate XML lines in this -- use it with subs accum_xml_lines & write_xml_lines...
my %xml_lines;

# Get these from the XML "header" (parsed by sub show) for later use:
my $taskdescr;
my $reqsite;
my $svcsite;
my $ctimagefile;
my ( $seriu, $stuiu );  # Series & Study Instance UIDs

# Use this to classify the size of nodules: value = "small" or "large"
my $sizeclass;

# Counters for various features found in pass 1...
my $foundnodules = 0;  # total nodules (of any size)
my $foundsmall   = 0;  # total small nodules
my $foundlarge   = 0;  # total large
my $foundnonn    = 0;  # total non-nodules
my $nomarkings   = 0;  # a flag that will be set to 1 if no markings of any kind are found

#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
#  .                                                                                 .
#  .  A note about units, terminology, and variable names:                           .
#  .  This app deals with both physical units of measurement (in mm.) and            .
#  .  computational "units" (in terms of acessing various data structures).  In some .
#  .  -- but NOT ALL -- cases, the word "coordinates" (or "coords") signals a        .
#  .  physical measurement in mm.; corresponding variable names might contain "x",   .
#  .  "y", or "z".  By contrast, indices or counts are often denoted by variable     .
#  .  names involving "i", "j", and "k" or "number" (such as "slice number").        .
#  .  Notable exceptions include loops that access one of the main variables of this .
#  .  app (the %contours hash) that typically use variable names such as $x and      .
#  .  $offsetx both of which are indices and integer pixel/slice counts,             .
#  .  respectively.                                                                  .
#  .                                                                                 .
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

# These variables define the bounding box of the ROIs.  Initial values are chosen to be
# appropriate outer limits for medical images.  "Correct" values are set in rSpass1
# as the edge maps are parsed from the XML.
my ( $minx, $maxx, $miny, $maxy ) = ( 1000000, -1, 1000000, -1 );  # pixel counts
my ( $minzc, $maxzc ) = ( 3000.0, -3000.0 );  # "c" means "coordinates", so this is in mm.
my ( $minz, $maxz );  # initial values are not needed -- will be set later

# For storing the nodule outlines (and subsequently filled outlines), small nodule marks (and
# subsequently filled enclosing spheres), and non-nodule markings.  ("contours" is a somewhat
# misleading name ["marking" would be better], but we'll stick with it since it's so pervasive...)
my %contours;  # Consider this to be a 5D hash: $contours{reader}{x-index}{y-index}{z-index}{layer}
# We need another hash holding the same info but in a different order: See sub reorder_contours.
my %contours1; # $contours1{x-index}{y-index}{z-index}{reader}{layer} (reader is moved to the 4th dimension)
# The $*index and $offset* variables are used to indexing into the contour hashes (or other similar  
#   structures).  The spatial coordinates that index into this array are offset based on the size  
#   of the bounding box in order to keep %contours as small as possible.  See the code for 
#   examples of how this is done (search for "$contours").
# Indices for reader, x, y, and z...
my ($rindex,$xindex,$yindex,$zindex);
# (The 5th dimension is generally indexed by $layer, but this is "declared" later.)
# Offsets for indexing into %contours that takes into account the overall bounding box
# that encloses all nodules...
my ($offsetx,$offsety,$offsetz);  # (Actually, $offsetz is always 0 in this version of the code as explained later.)

# for plotting...
my (@xdata,@ydata);
my ( $plotinfo_noduleID, $plotinfo_zcoord, $plotinfo_roitype );  # for passing info into the plotting routines

# for filling the contour polygons...
my ( @poly, @filledpoly, @finalpoly );

# This will be set to the longest corner-to-corner diagonal of the voxels in the data.  We use this as a
# "typical" length for assessing separations and comparing distances.
my $voxeldim;

# This hash holds nodule centroid info and is set in subs rSpass2 and centroid_calcs.
# Currently, this hash is only used to store centroid info for writing XML output.
my %centroids;  # key = (reader, nodule number, quantity) -- that is, a list -- where quantity is "sumx", etc
tie %centroids, "Tie::IxHash";  # maintain order to make it easier to look at...

# === These hashes hold nodule & non-nodule status & info for use in various places in the process ===
#
# This one holds info about single nodules and non-nodules.  It is populated in sub rSpass1 and in all sections
# (all the small/large/non-nodule combo sections) of sub simple_matching.
my %nnninfo;  # for example: $nnninfo{$reader}{$nodule}{"overlap"} = "yes"  # overlaps with at least one other nodule
# N.B.: We got a runtime error when using this as: $nnninfo{$reader}{$nodule} = "non-nodule"
#       so changed this to: $nnninfo{$reader}{$nodule}{'sizeclass'} = "non-nodule"
#
# For storing info about large nodules marked by the majority of readers.  Used to implement QA test #6[original].
my %majority;  # typical use: $majority{$rdr}{$id} = $snid;
#
# For storing info about small nodules.  Populated in sub construct_sphere and used in a few places.
my %smnodinfo = ();
# Similar but for storing info about non-nodules.  Populated in rSpass2 with a list like [x,y,z].
my %nonnodinfo = ();
# Using these hashes:
#   $smnodinfo{$r}{$n} = [$x,$y,$z];
#   $ref = $smnodinfo{$r}{$n}; ( $x, $y, $z ) = ( @$ref[0], @$ref[1], @$ref[2] );
# Use this one to keep track of which non-nodules need to be listed separately in the XML.  (If a
# non-nodule appears in the ambiguity section, it should not be in the separate list.)
# $listnonnodseparately{reader}{id} = 'string'
my %listnonnodseparately = ();
# Use this one to find the sets ambiguous objects:
# Set flags in it symmetrically: $ambigsets{id1}{id2} = 1 and $ambigsets{id2}{id1} = 1
#   where the IDs are reader and label concatenated together.  The value of the flag denotes
#   the type of ambiguity for the pair that is represented.
my %ambigsets = ();
# This one is derived from %ambigsets and denotes which "set" each ambiguous object belongs to.
# It is set as: $ambigsets1{$rdr}{$nodlabel} = $set
my %ambigsets1 = ();
#
# This one records overlap between nodule pairs...
my %overlap;  # It is symmetrical with a flag value stored in each "direction": a overlaps b and b overlaps a.
              # See sub simple_matching.
# The right way to access %overlap (check for existence first -- but we should use the exists function!)...
#   if (  $overlap{2}{5}{3}{45} ) { print "  reader 2 / nodule 5 and reader 3 / nodule 45: overlap: yes \n"; }
#   if ( !$overlap{1}{1}{1}{10} ) { print "  reader 1 / nodule 1 and reader 1 / nodule 10: overlap: no \n"; }
# The wrong way ($overlap{1}{1}{1}{10} may not exist!)...
#   print "  reader 1 / nodule 1 and reader 1 / nodule 10: $overlap{1}{1}{1}{10} \n";
#
# This hash holds info pertaining to overlap between nodule pairs -- mainly for secondary overlap measures:
my %nodulepairinfo;
#
# Preserve ordering to make it easier to inspect the hash dumps:
tie %nnninfo,              "Tie::IxHash";
tie %smnodinfo,            "Tie::IxHash";
tie %nonnodinfo,           "Tie::IxHash";
tie %listnonnodseparately, "Tie::IxHash";
tie %overlap,              "Tie::IxHash";
tie %nodulepairinfo,       "Tie::IxHash";
tie %majority,             "Tie::IxHash";

# We need to get Z info on all slices so that (1) we can safely add the sphere around small
#   nodules with sub construct_sphere (we don't want to add voxels off the end of the stack of
#   images), (2) we can check for slice spacing uniformity within each nodule, and (3) get the
#   overall slice spacing.
my $overallspacing = -1.0;  # Spacing over all nodules that we find in the XML; give it an initial value to indicate that it hasn't been set.
                            # It will be set in rSpass1 (but is made global for use in other routines).
                            # But it can be overridden by --slicespacing .
# We will try to infer slice spacing from the slices in the XML.  If we have any kind of difficulty or question in doing this, 
# we will set this flag and try to recover by seeing if --slicespacing was given on the command line.
my $troubleWithInferringSpacing = '';
# Two arrays generated by gen_slices:
# The ("synthesized"/inferred) list of all z slice coords (in mm.) in the study:
my @allz;  # index into it to get the z coord for a given (local) slice number
# The list of indices in @allz where coord values match with where markings were found in the XML:
# We use this to index through %contours efficiently: We only need to access the slices
# in which we know that data is located.
my @zmatch;

# Keep track of the slices in which sub construct_sphere adds voxels:
# (Filled by sub construct_sphere and used to update @zmatch.)
my %spherez = ();

# Arrays of Z coords: populated and processed in sub rSpass1; processed further in sub intermediate_calcs
# for bounding box limits in the z direction.
my @zcoordsallnods    = ( );  # z coords (in mm.) of all slices containing nodules
my @zcoordsallnonnods = ( );  # z coords (in mm.) of all slices containing non-nodules
my @zcoordsallnnn     = ( );  # z coords (in mm.) of all slices containing nodules and non-nodules

# Keep track of Z coord and SOP instance UID of the image slices that are referenced in the XML...
# Populated in rSpass1 and used in pmap_calcs.
my %z2siu;  # key = Z coord (formatted to a fixed number of decimal places), value = SOP instance UID

# Pertaining to radiologist IDs and numbers:
my $servicingRadiologistIndex;  # a local array/hash index which will typically be 0..3 (assuming 4 readers)
my @servicingRadiologist;  # an array holding radiologists' IDs (indexed into by $servicingRadiologistIndex or a similar index variable)
my $numreaders;  # total number of readers found in all the XML files specified on the cmnd line (equal to the size of @servicingRadiologist)
# This expands on @servicingRadiologist by also storing institution:
my %reader_info;  # index into this as $reader_info{$r}{$info} where $r is typically 0..3 and $info is 'id' (from <servicingRadiologistID>), 'site' (from <ServicingSite>), etc
tie %reader_info, "Tie::IxHash";
# N.B.: When referring to readers outsise this app, use IDs instead of indices since indices have
#       meaning only within this app (plus, they also depend on the order in which the files are processed!).

# >>> These hashes are set in the sub simple_matching <<<
# A hash holding the mapping from original nodules to the new/matched nodule numbers (SNID)...
#   After it is populated, index into it with reader/nodule combo
#   and read-out new nodule number (SNID): $snid = $noduleremap{$reader}{$nodule}
my %noduleremap = ();
# A reversed version of %noduleremap...
#   Access it as $noduleremaprev{$newnum}{$reader}{$nodule} and check for a flag value.
my %noduleremaprev;
# A list of nodules rejected based on the secondary matching criteria.  Same indexing scheme as %noduleremap
my %rejectednodules;

my $maxnewnodnum;  # copied from the final value of $newnodnum (not used for anything yet...)

my $nnid_has_been_changed;  # a flag set by sub rename_nn_id to signal that at least one non-nodule ID has been changed.

# pmap structures:
my  %pmap;  # This holds the pmap; it is filled and used in sub pmap_calcs.  "Index" into it as {SNID}{z}{y}{x}, where the ordering of the "subscripts" is tailored to producing the pmap XML file.
my  %pmapinfo;  # ancillary info that goes with %pmap
tie %pmapinfo, "Tie::IxHash";  # preserve order to make it a _little_ easier to look at



# ========================================================================================================
# =                                                                                                      =
# =        C O M M A N D   L I N E   P R O C E S S I N G   A N D   R E L A T E D   M A T T E R S         =
# =                                                                                                      =
# ========================================================================================================

sub section050__cmnd_line_proc {}  # a dummy sub that lets us jump to this location via the function list in our editor

print "=============== Command line parameter processing ===============\n\n";

# Prepend the command line argument array with whatever (if anything) is defined in MAXOPTS:
# (We *prepend* so that we can override args in MAXOPTS with args given on the command line.)
print "+++ dump of the command line args:\n", Dumper(@ARGV), "\n" if (0);  # testing
my $optstr;
if ( defined $ENV{"MAXOPTS"} ) {
    $optstr = $ENV{"MAXOPTS"};
    print "Command line options set via MAXOPTS: \n";
    print "  $optstr \n";
    my @optarr = split ' ', $optstr;
    print "+++ dump of the MAXOPTS options:\n", Dumper(@optarr), "\n" if (0);  # testing
    @ARGV = ( @optarr, @ARGV );
    print "+++ dump of the new command line opts:\n", Dumper(@ARGV), "\n" if (0);  # testing
}

print "The command line:\n $runcmnd \n\n";

# Define variables and set (some) defaults...
my $skipnumfilescheck = '';
my $dirin   = DIRINDEF;
my $prependdirin = '';
my $dirout  = DIROUTDEF;
my $dirsave = DIROUTDEF;
my @savedatastrlist;
my @qalist;
my $help = '';
my $internals;
my $internaldoc;
my $list = '';
my $plot = '';
my $verbose = DEFVERBOSE;
my @testlist;
my $validate = '';
my @actionlist;
my $configfilename = '';
my $readtype_optval    = UNBLINDEDREADTYPEVALUE;
my $messagetype_optval =   RESPMESSAGETYPEVALUE;
my @pmapoplist;
my @xmloplist;
my $sec_matching = '';
my $fileinpattern = FILEINDEFREX;
my $addsuffix;
my @filelist;
my $pixeldim = '';  # a single number -- assume 1:1 aspect ratio
my $slicespacing = '';
my $zanalyze = '';
my $show_sl_sp_msg;
my $sphere_diam = VIRTSPHEREDEFDIAM;  # the diameter in mm. of the virtual sphere constructed around small nodule markings
my $studyinstanceuid = '';
my $comments = '';
my $savemessages;
# Get ready for processing...
Getopt::Long::Configure('pass_through');
# Note that we use aliases (the "|" notation) to allow us to specify options with dashes as word separators for clarity
# or without dashes for brevity:
my %GetOptionsHash = (
        'help'         => \$help,
        'internals'    => \$internals,
        'internaldoc'  => \$internaldoc,
        'list'         => \$list,
        'validate'     => \$validate,
        'plot'         => \$plot,
        'verbose=i'    => \$verbose,     # to see the choices: 0 (minimal verbosity) to N (max verbosity);
        'test|debug=s' => \@testlist,    # to see the choices: run with --internals
        'action|exit-early|exitearly|early-exit|earlyexit|forced-exit|forcedexit=s'
                      => \@actionlist,  # choices: run with --internals
        'pmap-ops|pmapops=s'                        => \@pmapoplist,  # to see the choices: run with --internals
        'xml-ops|xmlops=s'                          => \@xmloplist,   # to see the choices: run with --internals
        'config-file|configfile=s'                  => \$configfilename,
        'read-type|readtype|data-type|datatype=s'   => \$readtype_optval,
        'message-type|messagetype=s'                => \$messagetype_optval,
        'sec-matching|secmatching'                  => \$sec_matching,
        'save-data-structures|savedatastructures=s' => \@savedatastrlist,  # to see the choices: run with --internals
        'quality-assurance-ops|qualityassuranceops|qa-ops|qaops=s'
                                                    => \@qalist,  # to see the choices: run with --internals
        'file-in-pattern|fileinpattern=s'           => \$fileinpattern,
        'add-suffix|addsuffix'                      => \$addsuffix,
        'files|file-name|filename|fname=s'          => \@filelist,
        'skip-num-files-check|skipnumfilescheck'    => \$skipnumfilescheck,
        'dir-in|dirin|dir-name|dirname=s'           => \$dirin,
        'prepend-dir-in|prependdirin'               => \$prependdirin,
        'dir-out|dirout=s'                          => \$dirout,
        'dir-save|dirsave=s'                        => \$dirsave,
        'pixel-dim|pixeldim|pixel-size|pixelsize|pixel-spacing|pixelspacing=s'
                                                    => \$pixeldim,
        'slice-spacing|slicespacing=s'              => \$slicespacing,
        'z-analyze|zanalyze'                        => \$zanalyze,
        'show-slice-spacing-messages|showslicespacingmessages' 
                                                    => \$show_sl_sp_msg,
        'sphere-diam|spherediam=f'                  => \$sphere_diam,
        'study-instance-uid|studyinstanceuid=s'     => \$studyinstanceuid,
        'comments=s'                                => \$comments,
        'save-messages|savemessages'                => \$savemessages
        );
# Do the processing...
GetOptions ( %GetOptionsHash );

#""" User message doc: 3201: A display of the command line.
msg_mgr (
    severity => 'INFO',
    msgid => 3201,
    text => my $text1 = ( sprintf "The command line: %s ", $runcmnd ),
    accum => 1,
    screen => 0,  # don't show to screen since we did this above
    code => -1
);
#""" User message doc: 3202: A display of the command line.
msg_mgr (
    severity => 'INFO',
    msgid => 3202,
    text => my $text2 = ( sprintf "Command line options set via MAXOPTS: %s ", $optstr ),
    accum => 1,
    screen => 0,  # don't show to screen since we did this above
    code => -1
) if $optstr;

# All info from the command line is passed into this script via options rather than arguments.
#   So, if there are arguments (as opposed to options), we consider this to be an error.  Note
#   that any (erroneous) options are passed thru due to the 'pass_through" config above...
if ( $ARGV[0] ) {
    #""" User message doc: 6201: Command line error (invalid option, lone argument, omitted value, ambiguous option name, etc.).
    pod2usage ( -message    => "\nThere is an error [6201] on the command line: $ARGV[0] \n" .  # %%!!FATAL!!%% -- command line/file processing
                               "  You may have specified a lone argument (only options with dashes are allowed), \n" .
                               "  or you may have specified an invalid option, \n" .
                               "  or you may have omitted a required value from an option, \n" .
                               "  or you may have given a value where none is allowed, \n" .
                               "  or you may have specified an option ambiguously. \n" .
                               "Re-run with --help for more information.\n",
                -verbose    => 0,
                -output     => \*STDERR,  # use STDERR to prevent corruption of the "|" symbol in the POD help text (?!?!)
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
}
# Another way to handle this which catches only arguments:
#   print "Unprocessed (ignored) arguments:\n" if $ARGV[0];
#   foreach (@ARGV) { print "  $_ \n"; }

if ( $help ) { 
    print "\n\n", " " x 19, "-" x 41, "\n\n\n";
    pod2usage ( -verbose    => 2,
                -output     => \*STDERR,  # use STDERR to prevent corruption of the "|" symbol in the POD help text (?!?!)
                -exitstatus => $Site_Max::RETURN_CODE{normal} );
}

if ( $sec_matching ) {
    # Not ready for prime time yet -- needs more development and checking.  Plus the Implementation
    # Group has not decided to do this, so...
    #""" User message doc: 6101: Secondary matching is experimental/under development and thus cannot be performed.
    msg_mgr (
        severity => 'FATAL',
        msgid => 6101,
        appname => 'MAX',
        line => __LINE__ - 6,
        text => 'Secondary matching is experimental/under development and thus cannot be performed.',
        before => 1,
        after => 2,
        accum => 1,
        verbose => 1,
        code => $Site_Max::RETURN_CODE{othererror}
    );
}

#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
#  .                                                                                 .
#  .                             Using $verbose                                      .
#  .                                                                                 .
#  .  Now that the $verbose variable is available, we'll start using it.  Here is    .
#  .  an example of a typical use...                                                  .
#  .    print "some stuff\n" if $verbose >= 4;                                       .
#  .  To temporarily activate a section of "verbose-bounded" code selectively...     .
#  .    if ( $verbose >= 4 or 1 ) { some code }                                      .
#  .  Standardize the values of $verbose...                                          .
#  .   0: Almost nothing - except greeting and command line processing messages      .
#  .      which come before $verbose is defined                                      .
#  .   1: Basic/terse progress messages and most error messages                      .
#  .   2: More detailed progress messages and most warnings                          .
#  .   3: Detail about content of the XML, etc. (default value)                      .
#  .   4: More verbose and detail about content, etc.                                .
#  .   5..9: Dumps (often via Dumper) of increasingly obscure data structures        .
#  .                                                                                 .
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

# A number of command options can have a list as their values or have multiple values.
# In this section, we do 2 things for each option:
# (1) We concatenate all values given for an option into a single list (implemented as an array).
#   That is, "... --xmlops=match,pmap --pix=0.625 --xmlops=hist ..." is equivalent to
#   "... --xmlops=match,pmap,hist --pix=0.625 ..." with the result that @xmloplist contains
#   'match', 'pmap', and 'hist'.
# (2) We use some funky code to extract the valid
#   values from the source code itself so that we can display them in the --internals section.  We
#   are doing this by the use of Unix utilities -- should re-code this in Perl!  This get funky
#   b/c of extra slashes, etc in the code.
# Examples of how to use the lists/arrays:
#   if  (grep {/^spacing$/} @testlist) { print "something about spacing\n" }
# ...or as a stmt modifier...
#   print "something about spacing\n" if (grep {/^spacing$/} @testlist);
# ...or the negative...
#   if (!grep {/^spacing$/} @testlist) { print "something about not spacing\n" }
#@@@ Code location: UnixUtil-grep
#@@@ Code location: UnixUtil-cut
#@@@ Code location: UnixUtil-tr
# The action options...
@actionlist = split(/,/,join(',',@actionlist));
my @actionwords = `grep -E 'grep.*\@actionlist' $0 | grep -v '\#' | cut -d/ -f2 | tr -d '^\$' `;
# The testing options...
@testlist = split(/,/,join(',',@testlist));
my @testwords = `grep -E 'grep.*\@testlist' $0 | grep -v '\#' | cut -d/ -f2 | tr -d '^\$'`;
# The save data structure options...
@savedatastrlist = split(/,/,join(',',@savedatastrlist));
my @savedatastrlistwords = `grep -E 'grep.*\@savedatastrlist' $0 | grep -v '\#' | cut -d/ -f2 | tr -d '^\$'`;
# The QA options...
@qalist = split(/,/,join(',',@qalist));
my @qalistwords = `grep -E 'grep.*\@qalist' $0 | grep -v '\#' | cut -d/ -f2 | tr -d '^\$'`;
# The XML options...
@xmloplist = split(/,/,join(',',@xmloplist));
#my @xmloplist1 = split(/,/,join(',',@xmloplist));
my @xmllistwords = `grep -E 'grep { /.*\@xmloplist' $0 | grep -v '\#' | cut -d/ -f2 | tr -d '^\$'`;
# The pmap options...
#my @pmapoplist1 = split(/,/,join(',',@pmapoplist));
@pmapoplist = split(/,/,join(',',@pmapoplist));
my @pmaplistwords = `grep -E 'grep { /.*\@pmapoplist' $0 | grep -v '\#' | cut -d/ -f2 | tr -d '^\$'`;

# Dump selected internal data structures and other info, then exit
#         ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
#         !    WARNING: funky code ahead...   !
#         ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
if ( $internals ) {
  print "\n=============== Selected internal data structures ===============\n\n";
  # Show the path found by FindBin
  print "\$FindBin::Bin is $FindBin::Bin \n\n";
  # Dump the return codes hash
  dump_rc(); print "\n";
  # Show the args that can be used with various options...
  print "Valid arguments for --quality-assurance-ops based on a search through the source file: \n @qalistwords \n" if @qalistwords;
  print "Valid arguments for --save-data-structures based on a search through the source file: \n @savedatastrlistwords \n" if @savedatastrlistwords;
  print "Valid arguments for --xmlops based on a search through the source file: \n @xmllistwords \n" if @xmllistwords;
  print "Valid arguments for --pmapops based on a search through the source file: \n @pmaplistwords \n" if @pmaplistwords;
  print "Valid arguments for --test based on a search through the source file: \n @testwords \n" if @testwords;
  print "Valid arguments for --exit-early (alias: --action) based on a search through the source file: \n @actionwords \n" if @actionwords;
  # Show defined constants...
  #@@@ Code location: UnixUtil-sed
  print "Defined constants in $0:\n\n",
    `sed -n -e '/^# +*+ begin constant section +/,/^# +*+ end constant section +/ p' $0       | sed -e '/^#/d'`;  # couldn't get this to work: sed '/^$/d'
  print "Defined constants in $SMfname:\n",
    `sed -n -e '/^# +*+ begin constant section +/,/^# +*+ end constant section +/ p' $SMfname | sed -e '/^#/d'`;
  # Show current command line options...
  print "Current values of all possible command line options (with aliases separated by \"|\") \nshowing values specified on the command line as well as default values: \n";
  # This is MESSY b/c I couldn't figure-out how to de-reference $GetOptionsHash{$optkey},
  #   so I let Dumper do it, but its output had to be edited!...
  foreach my $optkey ( sort keys %GetOptionsHash ) {
    #print "+++\$optkey = $optkey \n";
    my $optvalue = $GetOptionsHash{$optkey};
    #print "+++\$optvalue = $optvalue \n";
    $optkey =~ s/=.//;  # for example, change "pixeldim=s" to "pixeldim" for nice formatting
    my $dumpopt = Data::Dumper->new([$optvalue],[$optkey]);
    my $dumpoptstr = $dumpopt->Dump;
    for ( $dumpoptstr ) {
      s/\$/--/;    # Variable names begin with "$"; change to "--" to make them look like options.
      s/\;//;      # Get rid of ";"s.
      s/\\//;      # We don't need the "\"s.
      s/\[\]/''/;  # This just makes it look a little nicer.
      s/\[\n//; s/\]\n//;     # We don't need the "\n"s around any "[...]".
      }
    print "  ", $dumpoptstr;
  }
  print "The above list may contain illegal options/values as not all error checking has been performed at this point.\n\n";
  print "User message information:\n";
  print "The best way to see this information is use the --internaldocs option.\n";
  print "Alternatively (the \"old\" way), enter these commands at the shell prompt:\n";
  # Because of all the special characters in the two commands below, this is the easiest way for now.
  # Should, of course, re-write in Perl!!!
#@@@ Code location: UnixUtil-grep
  print `grep -A 10 beginsomecommands $0 | grep -v beginsomecommands`;  # watch the "6" -- magic number!!! -- dependent on no. of lines before "=cut"
=beginsomecommands
    % cd /to/the/location/of/max.pl
  A list of message IDs that have been used (including counts to show any duplicate use):
    % sed -n -e 's/^\(.*msgid => \)\(.*\)\(,.*$\)/\2/p' -e 's/^\(.*\[\)\([0-9][0-9][0-9][0-9]\)\(\].*$\)/\2/p' max.pl | grep -E '[0-9]{4}' | sort | uniq -c
  Two listings of code excerpts showing mesage text and context:
    # This one looks for the "%%!!...!!%%" pattern:
    % grep -n '%%\!\!.*\!\!%%' max.pl | grep -v -E '^#' | sed -e 's:\\":\`:g' | awk -F\" '{printf "%s \n   %s \n\n", $0, $(NF-1 ) }' | sed -e 's:\\n::g' -e 's/Stopped//'
    # This one extracts invocations of the msg_mgr subroutine:
    % grep -A 12 'msg_mgr (' max.pl | grep -E 'msg_mgr|severity|text|msgid|code' | sed 's/^[ \t]*//' | sed 's/msg_mgr/\nmsg_mgr/'
    # This one finds lines containing things like "[6202]":
    % grep '\[[0-9][0-9][0-9][0-9]\]' max.pl
=cut
  print "These commands may display some extraneous code.\n";
  $exit_msg = sprintf "Exit on the display of internals.";
  exit $Site_Max::RETURN_CODE{normal};
}

# Dump selected internal documentation info (--internaldoc), then exit
# WARNING: more funky code ahead...
if ( $internaldoc ) {
  print "\n=============== Return code documentation ===============\n\n";
#@@@ Code location: UnixUtil-grep
#@@@ Code location: UnixUtil-cut
  print `grep ',  #""" Return code doc: ' $SMfname | cut -d: -f 2-`;
  print "\n\n=============== User message documentation ===============\n\n";
#@@@ Code location: UnixUtil-grep
#@@@ Code location: UnixUtil-cut
#@@@ Code location: UnixUtil-sort
  print `grep '#""" User message doc: [1-6][0-9][0-9][0-9]' $MAXfname | cut -d: -f 2- | sort`;
  exit $Site_Max::RETURN_CODE{normal};
}


if ( $comments ) {
    print "\nComments specified on the commandline:\n  $comments \n\n" if $verbose >= 3;
    # Generate a message for insertion into @main::msglog
    #""" User message doc: 3111: A display of comments for this run.
    msg_mgr (
        severity => 'INFO',
        msgid => 3111,
        text => my $text = ( sprintf "Comments for this run: %s. ", $comments ),
        accum => 1,
        screen => 0,  # doesn't need to be displayed on the screen
        code => -1
    );
}

# Based on the value obtained from the --read-type option, expand the read type option value:
if ( $readtype_optval =~ m/^unbl/ ) {
    $readtype_optval = UNBLINDEDREADTYPEVALUE;  # adjust the value to its full name
}
elsif ( $readtype_optval =~ m/^bl/ ) {
    $readtype_optval = BLINDEDREADTYPEVALUE;  # adjust the value to its full name
}
else {
    #""" User message doc: 6202: An illegal read type has been specified with the --read-type option.
    pod2usage ( -message    => "\nAn illegal read type has been specified with the --read-type option [6202]. \n".   # %%!!FATAL!!%% -- command line/file processing
                               "Re-run with --help for more information.\n\n",
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
}

# Based on the value obtained from the --message-type option, expand the message type option value and set the message type tag variable:
if ( $messagetype_optval =~ m/^req/ ) {
    #print "The files will be processed as requests.\n\n" if $verbose >= 5;
    $messagetype_optval = REQMESSAGETYPEVALUE;  # adjust the value to its full name
    $messagetype_tag    = REQHDRTAGNAME;
}
elsif ( $messagetype_optval =~ m/^resp/ ) {
    #print "The files will be processed as responses.\n\n" if $verbose >= 5;
    $messagetype_optval = RESPMESSAGETYPEVALUE;  # adjust the value to its full name
    $messagetype_tag    = RESPHDRTAGNAME;
}
else {
    #""" User message doc: 6210: An illegal message type has been specified with the --message-type option.
    pod2usage ( -message    => "\nAn illegal message type has been specified with the --message-type option [6210]. \n".   # %%!!FATAL!!%% -- command line/file processing
                               "Re-run with --help for more information.\n\n",
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
}

# Set the read type tag based on the read and message type command line options:
if ( $messagetype_optval eq RESPMESSAGETYPEVALUE && $readtype_optval eq BLINDEDREADTYPEVALUE ) {
    $readtype_tag = BLINDEDREADTAGNAME;
}
elsif ( $messagetype_optval eq REQMESSAGETYPEVALUE && $readtype_optval eq UNBLINDEDREADTYPEVALUE ) {
    $readtype_tag = BLINDEDREADTAGNAME;
}
elsif ( $messagetype_optval eq RESPMESSAGETYPEVALUE && $readtype_optval eq UNBLINDEDREADTYPEVALUE ) {
    $readtype_tag = UNBLINDEDREADTAGNAME;
}
else {
    #""" User message doc: 6211: An illegal combination of message type and read type has been specified (or an internal error was detected).
    msg_mgr (
        severity => 'FATAL',
        msgid => 6211,
        appname => 'MAX',
        line => __LINE__ - 6,
        text => 'An illegal combination of message type and read type has been specified (or an internal error was detected).',
        before => 1,
        after => 2,
        accum => 1,
        verbose => 1,
        code => $Site_Max::RETURN_CODE{cmnderror}
    );
}
print "The file(s) will be processed as $readtype_optval $messagetype_optval messages (with tags <$messagetype_tag> and <$readtype_tag>).\n\n" if ( $verbose >= 5 or 0 );

# QA option processing:
if ( @qalist && $verbose >= 5 ) {
  print "QA operations: ";
  foreach ( @qalist ) {
    print "$_ ";
  }
  print "\n";
}
# Do some checking:
# (Coordinate this list of matches with the code below that processes the option values.)
foreach ( @qalist ) {
  if ( ! m/^droppedlarge/ && ! m/^notmajority/ && ! m /^allmarkedlarge/ && ! m/^connect/ && ! m/^narrow/ && ! m/^nonnodprox/ && ! m/^none/ ) {
    #""" User message doc: 6209: An illegal value has been specified with the --quality-assurance-ops option.
    pod2usage ( -message    => "\nAn illegal value has been specified with the --quality-assurance-ops option [6209]. \n".   # %%!!FATAL!!%% -- command line/file processing
                               "Re-run with --help for more information.\n\n",
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
  }
}
# Set some flags:
my $qa_droplg         = grep { /^droppedlarge/   } @qalist;
my $qa_notmajority    = grep { /^notmajority/    } @qalist;
my $qa_allmarkedlarge = grep { /^allmarkedlarge/ } @qalist;
my $qa_conn           = grep { /^connect/        } @qalist;
my $qa_narrow         = grep { /^narrow/         } @qalist;
my $qa_nonnodprox     = grep { /^nonnodprox/     } @qalist;
my $qa_none           = grep { /^none/           } @qalist;

# Process the values from --save-data-structures:
if ( @savedatastrlist && $verbose >= 5 ) {
  print "Data save operations: ";
  foreach ( @savedatastrlist ) {
    print "$_ ";
  }
  print "\n";
}
# Do some checking:
foreach ( @savedatastrlist ) {
  if ( ! m/^largenod/ && ! m/^other/ ) {
    #""" User message doc: 6208: An illegal value has been specified with the --save-data-structures option.
    pod2usage ( -message    => "\nAn illegal value has been specified with the --save-data-structures option [6208]. \n".   # %%!!FATAL!!%% -- command line/file processing
                               "Re-run with --help for more information.\n\n",
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
  }
}
# Set some flags:
my $save_lni   = grep { /^largenod/ } @savedatastrlist;
my $save_other = grep { /^other/    } @savedatastrlist;

# Do some checking on the XML operations:
if ( @xmloplist && $verbose >= 5 ) {
  print "XML operations: ";
  foreach ( @xmloplist ) {
    print "$_ ";
  }
  print "\n";
}
# Check the XML options:
# (Coordinate this list of matches (m/^.../) with the code below that processes the option values.)
foreach ( @xmloplist ) {
  if ( ! m/^hist/ && ! m/^match/ && ! m/^pmap/ && ! m/^cxrreq/ && ! m/^none/ ) {
    #""" User message doc: 6203: An illegal value has been specified with the --xml-ops option.
    pod2usage ( -message    => "\nAn illegal value has been specified with the --xml-ops option [6203]. \n".   # %%!!FATAL!!%% -- command line/file processing
                               "Re-run with --help for more information.\n\n",
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
  }
}
# Fill-in the defaults if nothing else has been specified:
@xmloplist = ( 'match', 'pmap' ) unless @xmloplist;
# Do not allow any XML write operations if we are just validating or doing Z analysis
if ( ( $validate || $zanalyze ) && @xmloplist ) {
    print "XML write operations are disabled for validating or doing Z analysis.\n" if $verbose >= 3;
    # clear-out all XML write operations:
    @xmloplist = grep { ! /^hist/   } @xmloplist;
    @xmloplist = grep { ! /^match/  } @xmloplist;
    @xmloplist = grep { ! /^pmap/   } @xmloplist;
    @xmloplist = grep { ! /^cxrreq/ } @xmloplist;
}
# Set some XML flags:
my $xmlhistory = grep { /^hist/   } @xmloplist;
my $xmlmatch   = grep { /^match/  } @xmloplist;
my $xmlpmaps   = grep { /^pmap/   } @xmloplist;
my $xmlcxrreq  = grep { /^cxrreq/ } @xmloplist;
my $xmlnone    = grep { /^none/   } @xmloplist;
#print Dumper(@xmloplist, $xmlhistory, $xmlmatch, $xmlpmaps, $xmlcxrreq); exit;  # testing

# Do some checking on the pmap option values:
if ( @pmapoplist && $verbose >= 5 ) {
  print "pmap operations: ";
  foreach ( @pmapoplist ) {
    print "$_ ";
  }
  print "\n";
}
# (Coordinate this list of matches (m/^.../) with the code below that processes the option values.)
foreach ( @pmapoplist ) {
  if ( ! m/^createpmap/ && ! m/^createxml/ && ! m/^includesm/ && ! m/^includecons/ && ! m/^none/ ) {
    #""" User message doc: 6204: An illegal value has been specified with the --pmap-ops option.
    pod2usage ( -message    => "\nAn illegal value has been specified with the --pmap-ops option [6204]. \n".   # %%!!FATAL!!%% -- command line/file processing
                               "Re-run with --help for more information.\n\n",
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
  }
}
# Fill-in the defaults if nothing else has been specified:
@pmapoplist = ( 'createxml', 'createpmap' ) unless @pmapoplist;
# Make a special adjustment if we are validating:
if ( $validate || $zanalyze ) {
    @pmapoplist = grep { ! /^createxml/ } @pmapoplist;
}
# Set some pmap flags:
my $createpmap          = grep { /^createpmap/  } @pmapoplist;
my $createpmapxml       = grep { /^createxml/   } @pmapoplist;
my $includeconstituents = grep { /^includecons/ } @pmapoplist;
my $includesmall        = grep { /^includesm/   } @pmapoplist;
my $pmapnone            = grep { /^none/        } @pmapoplist;
# But actually, the "include small" code isn't ready yet -- and may not ever be needed -- so take a fatal exit...
if ( $includesmall ) {
    #""" User message doc: 6102: The "include small" code is not implemented; re-run without includesmall on --pmap-ops.
    msg_mgr (
        severity => 'FATAL',
        msgid => 6102,
        appname => 'MAX',
        line => __LINE__ - 5,
        text => 'The "include small" code is not implemented; re-run without includesmall on --pmap-ops.',
        before => 1,
        after => 2,
        accum => 1,
        verbose => 1,
        code => $Site_Max::RETURN_CODE{othererror}
    );
}

# Reconcile various flags:
# For example, "--pmap-ops=createxml" and "--xml-ops=pmaps" mean the same thing.
$createpmapxml = $xmlpmaps = ( $createpmapxml || $xmlpmaps );  # now we can use either $createpmapxml or $xmlpmaps as a flag
# Then adjust the overall pmap switch...
$createpmap = $createpmapxml || $includesmall || $includeconstituents unless $createpmap;
# If we've said --xml-ops=none, this overrides all XML flags:
$createpmapxml = $xmlpmaps = 0 if $xmlnone;
if ( $verbose >= 4 ) {
    print "A quick summary of the --pmap-ops and --xml-ops options at the completion of command line processing:\n";
    print "  The \@pmapoplist array: @pmapoplist \n";
    print "    pmap flags: \$createpmap=$createpmap \$createpmapxml=$createpmapxml \$includesmall=$includesmall \$includeconstituents=$includeconstituents \$pmapnone=$pmapnone \n";
    print "  The \@xmloplist array: @xmloplist \n";
    print "    XML flags: \$xmlhistory=$xmlhistory \$xmlmatch=$xmlmatch \$xmlpmaps=$xmlpmaps \$xmlcxrreq=$xmlcxrreq \$xmlnone=$xmlnone \n";
    print "\n";
}

# Prepend the input directory name to the filenames in @filelist (if it has been populated via --files):
if ( $prependdirin && @filelist ) {
    my @tmplist = split(/,/,join(',',@filelist));
    @filelist = ();
    push @filelist, File::Spec->catfile( $dirin , $_ ) foreach ( @tmplist );
}

# Get the XML files to process from the specified directory (unless @filelist to be populated already because of the presence of the --files option):
if ( ! @filelist ) {
    #""" User message doc: 6301: Error in opening the directory specified by --dir-in.
    opendir ( DIR, $dirin ) or msg_mgr (
                                severity => 'FATAL',
                                msgid => 6301,
                                appname => 'MAX',
                                line => __LINE__ - 4,
                                text => my $text = ( sprintf "Error in opening directory %s: %s", $dirin, $! ),
                                before => 1,
                                after => 2,
                                accum => 1,
                                verbose => 1,
                                code => $Site_Max::RETURN_CODE{inputerror}
                            );
    # Could recode the following using File::Spec->rel2abs($dirin)
    print "These XML files were found in ", $dirin eq '.' ? $curdir : $dirin, " ...\n" if $verbose >= 4;
    while (defined(my $direntry = readdir(DIR))) {
        my $complete = $dirin . "/" . $direntry;
#@@@ Code location: UnixUtil-file
        my $stdouttxt = `file $complete`;  # execute the *nix file command to identify the file type
        my @parts = split(/:/,$stdouttxt);
        if ( ( $parts[1] =~ m/XML/ ) && ( $direntry =~ m/$fileinpattern/ ) ) {
            push @filelist, $complete;
            print "  $direntry \n" if $verbose >= 4;
        }
    }
    print "\n" if $verbose >= 4;
    #""" User message doc: 6314: Error in closing the directory specified by --dir-in.
    closedir(DIR) or msg_mgr (
                        severity => 'FATAL',
                        msgid => 6314,
                        appname => 'MAX',
                        line => __LINE__ - 4,
                        text => my $text1 = ( sprintf "Error in closing directory %s: %s", $dirin, $! ),
                        before => 1,
                        after => 2,
                        accum => 1,
                        verbose => 1,
                        code => $Site_Max::RETURN_CODE{inputerror}
                    );
}

# Do some checking on the files:
@filelist = split(/,/,join(',',@filelist));  # prepare the filelist
# Do some checking of the number of XML input files for a couple of different cases...
my $numinfiles = scalar(@filelist);
# By the time we get to this point, we should have at least one file, so check for that:
if ( $numinfiles == 0 ) {
    #""" User message doc: 6207: No files have been specified on the command line using the --file option nor found via the --dir-in (or --dir-name) option or any of the default actions.
    pod2usage ( -message    => "\nNo files have been specified on the command line using the --file option \n  nor found via the --dir-in (or --dir-name) option or any of the default actions [6207]. \n" .   # %%!!FATAL!!%% -- command line/file processing
                               "Re-run with --help for more information.\n\n",
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
}
# We must have 2..NUMREADERS input files unless we are validating, processing blinded reads,
# or have explicitly asked to skip "number of files " checking, in which case we'll allow any number:
elsif ( $validate || ( $readtype_tag eq BLINDEDREADTAGNAME ) || $skipnumfilescheck ) {
    print "Skipping the \"number of files\" requirement since we are validating, processing blinded data,\n" .
          " or since we have explicitly requested that this requirement be skipped.\n\n" if $verbose >= 1;
}
# The final (and most stringent) check on the number of files:
elsif ( $numinfiles < 2 || $numinfiles > NUMREADERS ) {
    #""" User message doc: 6205: An improper number of files have been specified on the command line using the --files option or have been found in the default or specified directory.
    # Create a formatted string for the error message:
    my $str = ( $dirin eq '.' ? 'the current directory (the default)' : 'directory ' . $dirin . ' which you specified using --dir-in (or --dir-name)');
    pod2usage ( -message    => "\nAn improper number of files have been specified on the command line using the --files option \n  or have been found in $str.  Re-run with --help for more information [6205].\n\n",  # %%!!FATAL!!%% -- command line/file processing
                -verbose    => 0,
                -output     => \*STDERR,
                -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
}
# Check each file for read access (and implicitly for existence)...
foreach ( @filelist ) {
    if ( ! -r ) {
        #""" User message doc: 6302: There is a problem with access to and/or existence of one of the input files.
        msg_mgr (
            severity => 'FATAL',
            msgid => 6302,
            appname => 'MAX',
            line => __LINE__ - 5,
            text => '',
            text => my $text = ( sprintf "There is a problem with access to and/or existence of input file %s.", $_ ),
            before => 1,
            after => 2,
            accum => 1,
            verbose => 1,
            code => $Site_Max::RETURN_CODE{inputerror}
        );
    }
}

# Just show the files and exit:
if ( $list ) {
#@@@ Code location: UnixUtil-less
    if ( $configfilename ) {
        print "\n\n\n=================== configuration file $configfilename =====================\n\n";
        system("less", $configfilename);
    }
    foreach ( @filelist ) { 
        print "\n\n\n========================== XML file $_ ===========================\n\n";
        system("less", "-e", $_);
    }
    exit $Site_Max::RETURN_CODE{normal};
}

# Check for mandatory arguments:
if ( ! $validate && ! $zanalyze ) {
    if ( ! $pixeldim ) {
        #""" User message doc: 6206: Pixel size must be specified via --pixel-size or --pixel-dim .
        pod2usage ( -message    => "\nPixel size must be specified via --pixel-size or --pixel-dim [6206]. \n".   # %%!!FATAL!!%% -- command line/file processing
                                   "Re-run with --help for more information.\n\n",
                    -verbose    => 0,
                    -output     => \*STDERR,
                    -exitstatus => $Site_Max::RETURN_CODE{cmnderror} );
    }
}

print "\n\n";


# ================================================================
# =                                                              =
# =        P R O C E S S   T H E   C O N F I G   F I L E         =
# =                                                              =
# ================================================================
sub section060__config_file {}  # a dummy sub that lets us jump to this location via the function list in our editor

#@@@ Code location: ConfigFileProc
print "============== Configuration parameter processing ==============\n\n" if $verbose >= 1;

#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
#  .                                                                                           .
#  .  The config file contains Perl code that typically sets variables, but we                 .
#  .  can get fancy and have conditionals, for example.                                        .
#  .                                                                                           .
#  .  Config file processing is placed fairly early so that                                    .
#  .  it can be used to patch-in values that would otherwise have to be placed                 .
#  .  on the command line.  That is, instead of specifying "--pixel-dim 0.57", we              .
#  .  can put this line in the config file: $pixeldim = "0.57";                                .
#  .                                                                                           .
#  .  For other ideas, see Recipe 8.16 in the Cookbook -- different ways to parse,             .
#  .  checking for system-wide vs local config files, etc...                                   .
#  .  (but couldn't get the 'do' function method to work -- something about variable scope? -- .
#  .  need to turn warnings or strict off inside the do block?)                                .
#  .  >>> Or see CPAN: We shouldn't try to write our own config file processor! <<<            .
#  .                                                                                           .
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

# This really needs to be reworked!
if ( $configfilename ) {
    #""" User message doc: 6304: Error in opening the configuration file.
    open ( CONFIG, $configfilename ) or msg_mgr (
                                            severity => 'FATAL',
                                            msgid => 6304,
                                            appname => 'MAX',
                                            line => __LINE__ - 4,
                                            text => my $text = ( sprintf "Error in opening the configuration file %s: %s", $configfilename, $! ),
                                            before => 1,
                                            after => 2,
                                            accum => 1,
                                            verbose => 1,
                                            code => $Site_Max::RETURN_CODE{configfileerror}
                                        );
    print "Contents of $configfilename ...\n" if $verbose >= 3;
    while (<CONFIG>) {
        print "  ", $_;
        chomp;
        eval;
        if ( $@ ) {
            #""" User message doc: 6401: Error in parsing a line of the configuration file.
            msg_mgr (
                severity => 'FATAL',
                msgid => 6401,
                appname => 'MAX',
                line => __LINE__ - 5,
                text => my $text = ( sprintf "Error in parsing this line of the configuration file: \"%s\" -- %s", $_, $@ ),
                before => 1,
                after => 2,
                accum => 1,
                verbose => 1,
                code => $Site_Max::RETURN_CODE{configfileerror}
             );
        }
    }
    print "\n";
    #close ( CONFIG ) or do { print "Error [6305] in closing the config file $configfilename : $!. \n"; exit $Site_Max::RETURN_CODE{configfileerror} };  # %%!!FATAL!!%% -- file/directory access
}
else {
    print "There is no configuration information to process; defaults will be used.\n\n\n" if $verbose >= 3;
}


# ==================================================================
# =                                                                =
# =        S O M E   L A T E R   P R E L I M I N A R I E S         =
# =                                                                =
# ==================================================================
sub section070__later_prelims {}  # a dummy sub that lets us jump to this location via the function list in our editor

print "================== Preliminary processing ==================\n\n" if $verbose >= 1;

if ( $validate ) {
    print "Preliminary processing is skipped during validation.\n" if $verbose >= 2;
}
else {
    # Do preliminary processing
    print "There are no preliminary processing operations in the version.\n" if $verbose >= 2;
}

if  (grep {/^prelim/} @actionlist) { 
    $exit_msg = "Exiting on \"--exit-early=preliminary\"";
    exit $Site_Max::RETURN_CODE{normal};
}


# ================================================================================================
# =                                                                                              =
# =        O P E N   T H E   F I L E S   F O R   X M L   A N D   O T H E R   O U T P U T         =
# =                                                                                              =
# ================================================================================================
sub section075__open_files {}  # a dummy sub that lets us jump to this location via the function list in our editor

my $suffix = $FILEOUTSUFFIXES{$readtype_optval}{$messagetype_optval};
print "Adding the suffix \"$suffix\" to selected output filenames.\n" if $verbose >= 5;

# Open the files we'll need for outputting XML, etc.:
# * marking history:
if ( $xmlhistory ) {
    $historyxmlfile = File::Spec->catfile( $dirout, HISTORYXMLDEFFILENAME );
    # Use a regex that starts from the right and matches the first '.'; replace it with the suffix followed by a '.'
    $historyxmlfile =~ s/(\.)(?!.*\.)/$suffix\./ if $addsuffix;
    print "Opening $historyxmlfile \n" if $verbose >= 5;
    make_backup($historyxmlfile);
    #""" User message doc: 6306: Error in opening the marking history XML file (or its directory) for writing.
    open ($historyxml_fh, "> $historyxmlfile") or msg_mgr (
                                                    severity => 'FATAL',
                                                    msgid => 6306,
                                                    appname => 'MAX',
                                                    line => __LINE__ - 4,
                                                    text => my $text = ( sprintf "Error in opening the marking history XML file (or its directory) for writing %s: %s", $historyxmlfile, $! ),
                                                    accum => 1,
                                                    verbose => 1,
                                                    code => $Site_Max::RETURN_CODE{xmloutfileerror}
                                                 );
}
# * matching results:
if ( $xmlmatch ) {
    $matchingxmlfile = File::Spec->catfile( $dirout, MATCHINGXMLDEFFILENAME );
    $matchingxmlfile =~ s/(\.)(?!.*\.)/$suffix\./ if $addsuffix;
    print "Opening $matchingxmlfile \n" if $verbose >= 5;
    make_backup($matchingxmlfile);
    #""" User message doc: 6307: Error in opening the matching XML file (or its directory) for writing.
    open ($matchingxml_fh, "> $matchingxmlfile") or msg_mgr (
                                                        severity => 'FATAL',
                                                        msgid => 6307,
                                                        appname => 'MAX',
                                                        line => __LINE__ - 4,
                                                        text => my $text = ( sprintf "Error in opening the matching XML file (or its directory) for writing %s: %s", $matchingxmlfile, $! ),
                                                        accum => 1,
                                                        verbose => 1,
                                                        code => $Site_Max::RETURN_CODE{xmloutfileerror}
                                                    );
}
# * CXR request XML:
if ( $xmlcxrreq ) {
    $cxrreqxmlfile = File::Spec->catfile( $dirout, CXRREQXMLDEFFILENAME );
    print "Opening $cxrreqxmlfile \n" if $verbose >= 5;
    make_backup($cxrreqxmlfile);
    #""" User message doc: 6318: Error in opening the CXR request XML file (or its directory) for writing.
    open ($cxrreqxml_fh, "> $cxrreqxmlfile") or msg_mgr (
                                                        severity => 'FATAL',
                                                        msgid => 6318,
                                                        appname => 'MAX',
                                                        line => __LINE__ - 4,
                                                        text => my $text = ( sprintf "Error in opening the CXR request XML file (or its directory) for writing %s: %s", $cxrreqxmlfile, $! ),
                                                        accum => 1,
                                                        verbose => 1,
                                                        code => $Site_Max::RETURN_CODE{xmloutfileerror}
                                                    );
}
# * pmaps:
if ( $xmlpmaps ) {
    $pmapxmlfile = File::Spec->catfile( $dirout, PMAPXMLDEFFILENAME );
    print "Opening $pmapxmlfile \n" if $verbose >= 5;
    make_backup($pmapxmlfile);
    #""" User message doc: 6308: Error in opening the pmap XML file (or its directory) for writing.
    open ($pmapxml_fh, "> $pmapxmlfile") or msg_mgr (
                                                severity => 'FATAL',
                                                msgid => 6308,
                                                appname => 'MAX',
                                                line => __LINE__ - 4,
                                                text => my $text = ( sprintf "Error in opening the pmap XML file (or its directory) for writing %s: %s", $pmapxmlfile, $! ),
                                                accum => 1,
                                                verbose => 1,
                                                code => $Site_Max::RETURN_CODE{xmloutfileerror}
                                            );
}
# * selected data structure(s):
if ( $save_other ) {
    $savefile = File::Spec->catfile( $dirsave, SAVEDATADEFFILENAME );
    $savefile =~ s/(\.)(?!.*\.)/$suffix\./ if $addsuffix;
    print "Opening $savefile \n" if $verbose >= 5;
    make_backup($savefile);
    #""" User message doc: 6303: Error in opening the datasave file  (or its directory) for writing.
    open ( $save_fh, "> $savefile") or msg_mgr (
                                        severity => 'FATAL',
                                        msgid => 6303,
                                        appname => 'MAX',
                                        line => __LINE__ - 4,
                                        text => my $text = ( sprintf "Error in opening the data save file (or its directory) for writing %s: %s", $savefile, $! ),
                                        accum => 1,
                                        verbose => 1,
                                        code => $Site_Max::RETURN_CODE{savefileouterror}
                                    );
}
# * save the user messages
if ( $savemessages ) {
    $messagesfile = File::Spec->catfile( $dirout, MSGDEFFILENAME );
    $messagesfile =~ s/(\.)(?!.*\.)/$suffix\./ if $addsuffix;
    print "Opening $messagesfile \n" if $verbose >= 5;
    make_backup($messagesfile);
    #""" User message doc: 6311: Error in opening the messages file (or its directory) for writing.
    open ( $messages_fh, "> $messagesfile" ) or msg_mgr (
                                                    severity => 'FATAL',
                                                    msgid => 6311,
                                                    appname => 'MAX',
                                                    line => __LINE__ - 4,
                                                    text => my $text = ( sprintf "Error in opening the messages file (or its directory) for writing %s: %s", $messagesfile, $! ),
                                                    before => 1,
                                                    after => 2,
                                                    accum => 1,
                                                    verbose => 1,
                                                    code => $Site_Max::RETURN_CODE{messagesfileerror}
                                                );
}
# * saved info for use between sessions:
# -- large nodule info:
if ( $save_lni ) {
    $lnifile = File::Spec->catfile( $dirsave, LNIDEFFILENAME );
    $lnifile =~ s/(\.)(?!.*\.)/$suffix\./ if $addsuffix;
    print "Opening $lnifile \n" if $verbose >= 5;
    make_backup($lnifile);
    #""" User message doc: 6312: Error in opening the 1st large nodule info file  (or its directory) for writing.
    open ($lni_fh, "> $lnifile") or msg_mgr (
                                        severity => 'FATAL',
                                        msgid => 6312,
                                        appname => 'MAX',
                                        line => __LINE__ - 4,
                                        text => my $text = ( sprintf "Error in opening large nodule info file (or its directory) for writing %s: %s", $lnifile, $! ),
                                        accum => 1,
                                        verbose => 1,
                                        code => $Site_Max::RETURN_CODE{savefileouterror}
                                    );
    $lni1file = File::Spec->catfile( $dirsave, LNI1DEFFILENAME );
    $lni1file =~ s/(\.)(?!.*\.)/$suffix\./ if $addsuffix;
    print "Opening $lni1file \n" if $verbose >= 5;
    make_backup($lni1file);
    #""" User message doc: 6315: Error in opening the 2nd large nodule info file  (or its directory) for writing.
    open ($lni1_fh, "> $lni1file") or msg_mgr (
                                        severity => 'FATAL',
                                        msgid => 6315,
                                        appname => 'MAX',
                                        line => __LINE__ - 4,
                                        text => my $text1 = ( sprintf "Error in opening large nodule info file (or its directory) for writing %s: %s", $lni1file, $! ),
                                        accum => 1,
                                        verbose => 1,
                                        code => $Site_Max::RETURN_CODE{savefileouterror}
                                    );
}
# The file that is used to save user messages has been opened previously so that it would be available as early as possible
# to catch errors associated with getting things ready for the run.  See the variables $messages_fh and $messagesfile.

# ============================================================================================================
# =                                                                                                          =
# =        C R E A T E   T H E   T W I G S   F O R   T H E   P A S S E S   T H R U   T H E   D A T A         =
# =                                                                                                          =
# ============================================================================================================
sub section080__create_twigs {}  # a dummy sub that lets us jump to this location via the function list in our editor

# Set-up handlers using the new method.  The handlers are subroutines that do the actual work of parsing the XML.

# For pass 1...
my $twig1=XML::Twig->new ( 
    twig_handlers => { 
        # The following path allows access to the header:
        '/LidcReadMessage/' . $messagetype_tag => \&show,
        # The following path allows access to all readingSession 
        #   sections from a single element.  The rSpass1
        #   subroutine is where we gather info for the bounding box and much, much more...
        '/LidcReadMessage' => \&rSpass1
    },
    pretty_print => 'nice',  # do this to get nice output for the CXR request XML (see --xml-ops=cxrrequest)
  );

# For pass 2...
my $twig2=XML::Twig->new ( twig_handlers => { 
    # The rSpass2 subroutine is where the contours are copied into the bounding box
    # array as well as other preps for matching and much, much more...
    '/LidcReadMessage' => \&rSpass2
    }
  );


# ================================================================================================
# =                                                                                              =
# =        1 S T   P A S S   O V E R   A L L   T H E   X M L   M E S S A G E   F I L E S         =
# =                                                                                              =
# ================================================================================================
sub section090__pass1 {}  # a dummy sub that lets us jump to this location via the function list in our editor

# Begin accumulating the beginning of the history XML in the hash before going thru the readers during which
# time we will collect the marking history data which will be added to the hash also.
if ( $xmlhistory ) {
    accum_xml_lines ( 'history', \%xml_lines,  $Site_Max::TAB[1] . "<MarkingHistoryInfo>" );
    accum_xml_lines ( 'history', \%xml_lines,  $Site_Max::TAB[2] . "<MarkingHistoryComments/>" );
    accum_xml_lines ( 'history', \%xml_lines,  $Site_Max::TAB[1] . "</MarkingHistoryInfo>" );
}

$servicingRadiologistIndex = 0;  # an index (which for 4 readers will be 0..3); it is incremented within rSpass1

print "\n\n======== Pass 1 XML file processing ========\n" if $verbose >= 1;
my $keepfilename;  # a variable to preserve the filename for later use
# Get ready for outputting the CXR read request XML
if ( $xmlcxrreq ) {
    write_xml_line1 ($cxrreqxml_fh);
    print $cxrreqxml_fh IDRIREADMESSAGETAGOPEN . "\n";
}
foreach my $file (@filelist) {
    $keepfilename = $file;
    undef $headertag_ok;  # reset the flag before precessing the next file
    print "\n\n======== Processing file $file (pass 1) ========\n" if $verbose >= 1;
    # Parse the file (the processing defined by the handlers will be carried-out)
    $twig1->parsefile($file);  # twig1 was created above
    # finish-up...
    print "\n" if $verbose >= 1;
}
# Close-out the CXR XML file:
if ( $xmlcxrreq ) {
    print $cxrreqxml_fh "\n";
    print $cxrreqxml_fh IDRIREADMESSAGETAGCLOSE . "\n";
}

# Save some data
if ( $save_other ) {
    my $str = "TESTING: at the end of pass 1";
    print $save_fh "# --save-data-structures \n" . Data::Dumper->Dump([$str,$servicingRadiologistIndex], [qw(str servicingRadiologistIndex)]);
}

# Write the history XML file:
if ( $xmlhistory) {
    # We're doing these initial operations here (after parsing thru the data) so that we have
    # access to some values for the XML headers (for example, requesting site) that were
    # unknown until we have parsed the file(s).
    write_xml_line1 ( $historyxml_fh );
    print $historyxml_fh $Site_Max::TAB[0] . "<LidcMarkingHistory>\n";
    write_xml_app_header( VERSIONHISTORYXML, $historyxml_fh );
    write_xml_datainfo_header( $historyxml_fh );
    # Dump the lines from the hash to the file:
    write_xml_lines ( 'history', \%xml_lines, $historyxml_fh );
    # Add the last line to the hash:
    print $historyxml_fh $Site_Max::TAB[0] . "</LidcMarkingHistory>\n";
}

if  ($validate) { 
    print "\n\n================== All files have been validated ==================\n" if $verbose >= 1;
    print "\nExiting. \n\n";
    $validatestatus = $Site_Max::RETURN_CODE{normal} if ! $validatestatus;
    exit $validatestatus;
}

print "\n\n================== All files have been processed for pass 1 ==================\n\n\n" if $verbose >= 2;

print "\n\n================= A report of information gathered in pass 1 ================\n\n" if $verbose >= 2;

# Show the readers that we found:
print "dump of \@servicingRadiologist ... \n", Dumper(@servicingRadiologist), "\n" if $verbose >= 5;
$numreaders = scalar(@servicingRadiologist);
#@@@ Code location: RdrID
# Display reader ID info:
print "dump of \%reader_info... \n", Dumper(%reader_info), "\n" if $verbose >= 6;
if ( $verbose >= 3 ) {
    print "\nReader information:\n";
    for ( 0 .. ( $numreaders - 1 ) ) {
        # show info from parsed from <ServicingSite> & <servicingRadiologistID>:
        print "  $_:  $reader_info{$_}{'site'}  $reader_info{$_}{'id'} \n";
    }
}
#@@@ Code location: NumRdrs
if ( ( $numreaders != NUMREADERS ) && ( ! $skipnumfilescheck ) ) {
    print "(We were expecting ", NUMREADERS, " readers.) \n" if $verbose >= 3;
    #""" User message doc: 5401: An unexpected number of readers was found.
    msg_mgr (
        severity => 'ERROR',
        msgid => 5401,
        appname => 'MAX',
        text => "We were expecting " . NUMREADERS . " readers, but we found " . $numreaders . ".",
        accum => 1,
        screen => 0,
        code => -1
    );
}
print "\n" if $verbose >= 3;

print "dump of \%z2siu (hash that converts Z coord to SOP inst UID)... \n", Dumper(\%z2siu), "\n" if $verbose >= 5;

# Show a summary of the numbers found and do some checking:
print "The following counts were found during pass 1:   \n" .
      "  Total number of nodules:\t $foundnodules       \n" .
      "    Number of small nodules: $foundsmall         \n" .
      "    Number of large nodules: $foundlarge         \n" .
      "  Number of non-nodules:\t $foundnonn            \n" if $verbose >=3;
if ( $foundnodules == 0  &&  $foundnonn == 0 ) {
    $nomarkings = 1;
    #""" User message doc: 4512: No markings were found for either nodules or non-nodules.
    msg_mgr (
        severity => 'WARNING',
        msgid => 4512,
        appname => 'MAX',
        line => __LINE__ - 6,
        text => my $text = 'No markings were found for either nodules or non-nodules.',
        before => 1, after => 0,
        accum => 1,
        verbose => 2,
        code => -1
    );
}
if ( ( $foundsmall + $foundlarge ) != $foundnodules ) {
    #""" User message doc: 4901: At the end of pass 1, there was an inconsistency found in nodule counts.
    msg_mgr (
        severity => 'WARNING',
        msgid => 4901,
        appname => 'MAX',
        line => __LINE__ - 5,
        text => my $text = ( sprintf("At the end of pass 1, there was an inconsistency found in nodule counts: %d + %d != %d ", $foundsmall, $foundlarge, $foundnodules ) ),
        accum => 1,
        verbose => 2,
        code => -1
    );
}

#@@@ Code location: NonIDChanged
# Check the flag (set by sub rename_nn_id) that signals whether at least one non-nodule ID has been changed.
if ( $nnid_has_been_changed ) {
    #""" User message doc: 3503: At least one non-nodule ID has been changed.
    msg_mgr (
        severity => 'INFO',
        msgid => 3503,
        #appname => 'MAX',
        #line => __LINE__ - 5,
        text => my $text = "At least one non-nodule ID has been changed.",
        before => 1,
        after => 1,
        accum => 1,
        verbose => 3,
        code => -1
    );
}

#@@@ Code location: DupNonID
# Make a report of duplicate non-nodule IDs
if ( @dupnnid_msg ) {
    #""" User message doc: 4402: Duplicate non-nodule IDs have been detected.
    msg_mgr (
        severity => 'WARNING',
        msgid => 4402,
        appname => 'MAX',
        line => __LINE__ - 5,
        text => my $text = "Duplicate non-nodule IDs have been detected; see the report at the end of pass 1.",
        screen => 0,
        accum => 1,
        verbose => 2,
        code => -1
    );
     print "\n";
     print "Duplicate non-nodule IDs have been detected:\n";
     foreach ( @dupnnid_msg ) {
         print "  $_ \n";
     }
}

if ( $zanalyze ) {
    # N.B.: We will not assign message numbers in this section since the text output that it produces are part of a report as requested by the --z-analyze option.
    print "\n";
    show_zlist();
    my ( $smallest_delz, $num_occurs, $numslices ) = infer_spacing(@zcoordsallnods, @zcoordsallnonnods);  # the arrays get concatenated, but this is OK
    print "A delta-Z of $smallest_delz mm. appears $num_occurs times and is the smallest delta-Z calculated from the set of $numslices total available Z coords.\n";
    # N.B.: Not sure if the following block is really appropriate in terms of the messages it gives the user....
        # The following if/else tree is a shortened version of the similar one below in the "How did we do..." ("See how we did..."??) section.
        #     if ( $troubleWithInferringSpacing ) {
        #         if ( $slicespacing ) {
        #             printf "We had trouble inferring slice spacing from the XML, but a slice spacing of %.4f mm. was given on the command line.\n", $slicespacing;
        #         }
        #         else {
        #             printf "We had trouble inferring slice spacing from the XML, and slice spacing was not given on the command line.\n";
        #         }
        #     }
        #     else {
        #         if ( $slicespacing ) {
        #             if ( approxeq($slicespacing,$overallspacing,ZSPACINGTOLFILLIN) ) {
        #                 printf "The slice spacing of %.4f mm. that we inferred from the XML is equal (or approx. equal) to the slice spacing of %.4f mm. that was given on the command line.\n", $overallspacing, $slicespacing;
        #             }
        #             else {
        #                 printf "The slice spacing of %.4f mm. that we inferred from the XML is not equal to the slice spacing of %.4f mm. that was given on the command line.\n", $overallspacing, $slicespacing;
        #             }
        #         }
        #         else {
        #             printf "We inferred a slice spacing of %.4f mm. from the XML.\n", $overallspacing;
        #         }
        #     }
    $exit_msg = "Exiting on the \"--z-analyze\" option";
    exit;
}  # end of the --z-analyze block

# See how we did with slice spacing...
print "\n";
if ( $troubleWithInferringSpacing ) {
#@@@ Code location: SlSpacCmndLn
    if ( $slicespacing ) {
        # This is just a "little trouble" -- not fatal -- since we have the spacing from the command line...
        #""" User message doc: 3504: We had trouble inferring slice spacing from the XML, so we will use the slice spacing that was given on the command line.
        msg_mgr (
            severity => 'INFO',
            msgid => 3504,
            appname => 'MAX',
            line => __LINE__ - 7,
            text => my $text = ( sprintf 'We had trouble inferring slice spacing from the XML, so we will use the slice spacing that was given on the command line (%.4f mm.).', $slicespacing ),
            accum => 1,
            before => 1,
            code => -1
        ) if $show_sl_sp_msg;
    }
    else {
#@@@ Code location: SlSpacNoCmndLn
        if ( $verbose >= 1 ) {
            # This is fatal...
            # We can't recover from this, so give a little extra info to the user about the Z coords before we terminate:
            @zcoordsallnnn = ( @zcoordsallnods, @zcoordsallnonnods );
            # Use zuni to sort and cull the list of z coords that have been found.
            ( my $dummy, @zcoordsallnnn ) = zuni(@zcoordsallnnn);
            # We show this list so that the user can use it to make a guess at the slice spacing if desired.
            print "We found nodule and non-nodule markings at the following Z coordinates (in mm.):\n";
            foreach ( @zcoordsallnnn ) {
                print "  $_ \n";
            }
            my ( $smallest_delz, $num_occurs, $numslices ) = infer_spacing(@zcoordsallnods, @zcoordsallnonnods);
            print "A delta-Z of $smallest_delz mm. appears $num_occurs times and is the smallest delta-Z calculated from the set of $numslices total available Z coords.\n\n";
        }
        #""" User message doc: 6504: We had trouble inferring slice spacing from the XML, and slice spacing was not given on the command line.
        msg_mgr (
            severity => 'FATAL',
            msgid => 6504,
            appname => 'MAX',
            line => __LINE__ - 4,
            text => 'We had trouble inferring slice spacing from the XML, and slice spacing was not given on the command line.',
            accum => 1,
            before => 1,
            code => $Site_Max::RETURN_CODE{zinfoerror}
        );
    }
}
else {
    if ( $slicespacing ) {
        # If spacing is available from the command line, we will use it since we assume that it is more reliable.
        if ( approxeq($slicespacing,$overallspacing,ZSPACINGTOLFILLIN) ) {
            #""" User message doc: 3501: The slice spacing that we inferred from the XML is equal (or approx. equal) to the slice spacing that was given on the command line.
            msg_mgr (
                severity => 'INFO',
                msgid => 3501,
                appname => 'MAX',
                line => __LINE__ - 5,
                text => my $text = ( sprintf("The slice spacing of %.4f mm. that we inferred from the XML is equal (or approx. equal) to the slice spacing of %.4f mm. that was given on the command line.",
                                             $overallspacing, $slicespacing) ),
                verbose => 2,
                accum => 1,
                code => -1
            ) if $show_sl_sp_msg;
        }
#@@@ Code location: SlSpacNotEq
        else {
            #""" User message doc: 3505: The slice spacing that we inferred from the XML is not equal to the slice spacing that was given on the command line; we will use the command line value.
            msg_mgr (
                severity => 'INFO',
                msgid => 3505,
                appname => 'MAX',
                line => __LINE__ - 6,
                text => my $text = ( sprintf("The slice spacing of %.4f mm. that we inferred from the XML is not equal to the slice spacing of %.4f mm. that was given on the command line; we will use the command line value.",
                                             $overallspacing, $slicespacing) ),
                verbose => 2,
                accum => 1,
                code => -1
            ) if $show_sl_sp_msg;
        }
    }
    else {
            #""" User message doc: 3502: We will use the slice spacing that we inferred from the XML since slice spacing was not given on the command line.
            msg_mgr (
                severity => 'INFO',
                msgid => 3502,
                appname => 'MAX',
                line => __LINE__ - 5,
                text => my $text = ( sprintf("We will use the slice spacing of %.4f mm. that we inferred from the XML since slice spacing was not given on the command line.", $overallspacing) ),
                verbose => 2,
                accum => 1,
                code => -1
            ) if $show_sl_sp_msg;
        $slicespacing = $overallspacing;
    }
}
# As we leave this block, $slicespacing contains the spacing value that we will use for the rest of this run.

if  (grep {/^pass1/} @actionlist) {
    $exit_msg = "Exiting on \"--exit-early=pass1\"";
    exit $Site_Max::RETURN_CODE{normal};
}

# If we found no nodules, we'll just note it with an informational message here.  It's fatal later on
# if we continue and want to do matching.
#@@@ Code location: NoNodsFnd1
if ( ! $foundnodules ) {
    #""" User message doc: 3506: No nodules were found.
    msg_mgr (
        severity => 'INFO',
        msgid => 3506,
        appname => 'MAX',
        line => __LINE__ - 6,
        text => 'No nodules were found.',
        accum => 1,
        verbose => 2,
        code => -1
    );
}


# ======================================================
# =                                                    =
# =        I N T E R M E D I A T E   S T U F F         =
# =                                                    =
# ======================================================
sub section100__intermediate {}  # a dummy sub that lets us jump to this location via the function list in our editor

intermediate_calcs();

# Quit here?
if  (grep {/^intermediate/} @actionlist) { 
    $exit_msg = "Exiting on \"--exit-early=intermediate\"";
    exit $Site_Max::RETURN_CODE{normal};
}


# ================================================================================================
# =                                                                                              =
# =        2 N D   P A S S   O V E R   A L L   T H E   X M L   M E S S A G E   F I L E S         =
# =                                                                                              =
# ================================================================================================
sub section110__pass2 {}  # a dummy sub that lets us jump to this location via the function list in our editor

$servicingRadiologistIndex = 0;  # an index which (for 4 readers) will be 0..3; it is incremented within rSpass2

print "\n\n======== Pass 2 XML file processing ========\n" if $verbose >= 1;
foreach my $file (@filelist) {
    $keepfilename = $file;
    print "\n\n======== Processing file $file (pass 2) ========\n" if $verbose >= 1;
    # Parse the file (the processing defined by the handlers will be carried-out)
    $twig2->parsefile($file);  # twig2 was created above
    # finish-up...
    print "\n" if $verbose >= 1;
}  # end of the foreach loop over all the files for pass 2

print "\n\n================== All files have been processed for pass 2 ==================\n\n" if $verbose >= 2;
if  (grep {/^pass2/} @actionlist) { 
    $exit_msg = "Exiting on \"--exit-early=pass2\"";
    exit $Site_Max::RETURN_CODE{normal};
}

if ( $verbose >= 5 ) {
    print "\n";
    print "dump of \%nnninfo (as of completion of pass 2 -- more info will be added later as the script continues)...\n", 
          Dumper(%nnninfo), "\n";
}
# Update @zmatch with %spherez (@zmatch contains the slice numbers that tell us where %contours contains values)
if ( %spherez ) {
    foreach my $key (keys %spherez) {
        push @zmatch, $key;
    }
    my $unifstr;
    ($unifstr,@zmatch) = zuni(@zmatch);  # cull and sort
    @zmatch = map{ int($_) } @zmatch;  # convert to integers (zuni made floats!)
}
print "dump of \%spherez... \n", Dumper(%spherez), "\n" if $verbose >= 6;
print "dump of \@zmatch... \n", Dumper(@zmatch), "\n" if $verbose >= 6;

print "\n";
dump_contours_hash() if $verbose >= 6;

if  (grep {/^check/} @actionlist) { 
    $exit_msg = "Exiting on \"--exit-early=check\"";
    exit $Site_Max::RETURN_CODE{normal};
}


# ==================================================================================================
# =                                                                                                =
# =        P E R F O R M   S O M E   " P O S T   X M L "   P R O C E S S I N G   S T E P S         =
# =                                                                                                =
# ==================================================================================================
sub section120__postXML_steps {}  # a dummy sub that lets us jump to this location via the function list in our editor

centroid_calcs();

# Save the %centroids hash (used by QA error checks #6[original] & #7)
save_large_nod_info('centroids') if $save_lni;

# Display/dump/process some data structures:
if ( $verbose >= 3 ) {
    print "\n\n============== Display selected data structures ==============\n\n";
    print "dump of the \%smnodinfo hash...\n", Dumper(%smnodinfo), "\n" if $verbose >= 5;
    print "Index through the \%smnodinfo hash (x,y,z indices are shown)...\n";
    for my $r ( keys %smnodinfo ) {
        my $rid = $servicingRadiologist[$r];
        for my $n ( keys %{$smnodinfo{$r}} ) {
            my $ref = $smnodinfo{$r}{$n};  # do it this way b/c each hash value is a little array
            print "  reader $rid($r) / nodule $n: @$ref \n";
        }
    }
    print "\n";
    print "dump of the \%nonnodinfo hash...\n", Dumper(%nonnodinfo), "\n" if $verbose >= 5;
    print "Index through the \%nonnodinfo hash (x,y,z indices are shown)... \n";
    for my $r ( keys %nonnodinfo ) {
        my $rid = $servicingRadiologist[$r];
        for my $n ( keys %{$nonnodinfo{$r}} ) {
            my $ref = $nonnodinfo{$r}{$n};  # do it this way b/c each hash value is a little array
            print "  reader $rid($r) / ID $n: @$ref \n";
        }
    }
    print "\n";
    print "dump of the \%nnninfo hash (at line " . __LINE__ . ")...\n", Dumper(%nnninfo), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
    print "Index through the \%nnninfo hash (\"nodule and non-nodule info\") and display additional info based other hashes...\n" if $verbose >= 3;
    for my $r ( keys %nnninfo ) {
        my $rid = $servicingRadiologist[$r];
        print "  reader $rid ($r): \n" if $verbose >= 3;
        for my $n ( keys %{$nnninfo{$r}} ) {
            print "    ID $n:" if $verbose >= 3;
            # Add some more info to the line:
            my $descrstr;
            if ( exists($smnodinfo{$r}{$n}) ) {
                $descrstr = 'small nodule';
            }
            elsif ( exists($nonnodinfo{$r}{$n}) ) {
                $descrstr = 'non-nodule';
            }
            else {
                $descrstr = 'large nodule';
            }
            print "\t $descrstr" if $verbose >= 3;
            # The functionality of following section (sans the print functions) has been moved into sub simple_matching
            # just before processing of %overlap.  In V1.04, it was in the proper location but was moved out here for
            # V1.05.  V1.06 retores it to the proper location inside sub simple_matching: see "Code location: AdjForSolitary".
            # This adjustment to %overlap cannot be made until *after* we have gone over all the overlap combos in sub simple_matching.
#             print "\t overlap:"  if $verbose >= 3;
#             if ( exists ( $nnninfo{$r}{$n}{"overlap"} ) ) {
#                 print $nnninfo{$r}{$n}{"overlap"} if $verbose >= 3;
#             }
#             else {
#                 print "no" if $verbose >= 3;
#                 # Add non-overlapping nodules to %overlap but mark them as not overlapping with anything -- but do this only if they are small nodules
#                 # (don't want to do this for non-nodules).
#                 ##$overlap{$r}{$n}{$NOREADER}{$NONODULE} = $NOOVERLAP;
#             }
#             print "    +++ key #3 (and value): " if $verbose >= 3;
#             for my $k3 ( keys %{$nnninfo{$r}{$n}} ) {
#                 print "$k3 ($nnninfo{$r}{$n}{$k3})  " if $verbose >= 3;
#             }
            print "\n" if $verbose >= 3;  # terminate the line (the print fcts above do not end in \n)
        }
    }
    print "\n" if $verbose >= 3;
    
}


#print "\n\n================== Specific QA tests ==================\n" if ( $verbose >= 2 && ( $qa_notmajority || $qa_droplg ) );
print "\n\n================== Specific QA tests - I ==================\n" if $verbose >= 2;

if ( $qa_none ) {
    print "\nSkipping specific QA tests.\n" if $verbose >= 2;
}

else {
    
    print "\nCheck for QA technical errors #2 & #3 using a distance criterion:\n" if $verbose >= 2;
    check_smnon_dist( context  => 'QA',
                      features => 'both' );
    
#@@@ Code location: QA6orig
    if ( $qa_notmajority ) {
        print "\nCheck for QA technical error #6[original]:\n";
        # Index thru %majority and check that the reader has marked something (nodule, small nodule or non-nodule)
        # close to each member of %majority.
	my $lnifile = File::Spec->catfile( $dirsave, LNIDEFFILENAME );

	my $lni1file = File::Spec->catfile( $dirsave, LNI1DEFFILENAME );
        # Both files must be present to do this test...
        if ( ! -e $lnifile || ! -e $lni1file ) {
            #""" User message doc: 6317: One of the files containing large nodule information (used for QA) does not exist.
            msg_mgr (
                severity => 'FATAL',
                msgid => 6317,  # was 5303
                appname => 'MAX',
                line => __LINE__ - 6,
                text => my $text = ( sprintf "One of the files (%s and/or %s) containing large nodule information (used for QA) does not exist.", $lnifile, $lni1file ),
                before => 1,
                after => 2,
                accum => 1,
                verbose => 1,
                code => $Site_Max::RETURN_CODE{savefileinerror}
            );
        }
        my %majority     = %{ doit ( $lni1file ) };
        my %bl_centroids = %{ doit ( $lnifile  ) };
        print "dump of \%majority (restored)... \n",    Dumper(%majority)     if $verbose >= 4;
        print "dump of \%bl_centroids (current)... \n", Dumper(%bl_centroids) if $verbose >= 4;
        print "dump of \%centroids (current)... \n",    Dumper(%centroids)    if $verbose >= 5;
        my $sep_criterion = $voxeldim * CENTSEPFACTOR;
        printf "  Using a centroid separation criterion of %.2f mm. \n", $sep_criterion if $verbose >= 3;
        my %qa6_matches;
        for my $bl_rdr ( keys %majority ) {
            for my $bl_id ( keys %{$majority{$bl_rdr}} ) {
                my $bl_snid = $majority{$bl_rdr}{$bl_id};
                my $bl_centx = $bl_centroids{$bl_rdr}{$bl_id}{'centx'} * $pixeldim;
                my $bl_centy = $bl_centroids{$bl_rdr}{$bl_id}{'centy'} * $pixeldim;
                my $bl_centz = $bl_centroids{$bl_rdr}{$bl_id}{'centz'} * $slicespacing;
                printf "  Comparison against blinded \"majority\" info for reader %s and (large) nodule ID %s which maps to \"SNID\" %s and is located at (%.2f, %.2f, %.2f): \n",
                       $bl_rdr, $bl_id, $bl_snid, $bl_centx, $bl_centy, $bl_centz;
                $qa6_matches{$bl_snid} = 0;
                print "    Large nodules:\n";
                for my $rdr ( keys %centroids ) {
                    for my $id ( keys %{$centroids{$rdr}} ) {
                        my $centx = $centroids{$rdr}{$id}{'centx'} * $pixeldim;
                        my $centy = $centroids{$rdr}{$id}{'centy'} * $pixeldim;
                        my $centz = $centroids{$rdr}{$id}{'centz'} * $slicespacing;
                        my $sep = dist ( $bl_centx, $bl_centy, $bl_centz, $centx, $centy, $centz );
                        printf "      separation between (bl[lg] unbl[lg]):  x: %.3f %.3f  y: %.3f %.3f  z: %.3f %.3f    %.3f \n",
                               $bl_centx, $centx, $bl_centy, $centy, $bl_centz, $centz, $sep if $verbose >= 5;
                        if ( $sep < $sep_criterion ) {
                            $qa6_matches{$bl_snid} ++;
                            print "      Nodule ID $id matches with SNID $bl_snid.\n";
                        }
                    }
                }
                print "    Small nodules:\n";
                for my $rdr ( keys %smnodinfo ) {
                    for my $id ( keys %{$smnodinfo{$rdr}} ) {
                        my $smxyz_ref = $smnodinfo{$rdr}{$id};
                        my $smx = @$smxyz_ref[0] * $pixeldim;
                        my $smy = @$smxyz_ref[1] * $pixeldim;
                        my $smz = @$smxyz_ref[2] * $slicespacing;
                        my $sep = dist ( $bl_centx, $bl_centy, $bl_centz, $smx, $smy, $smz );
                        printf "      separation between (bl[lg] unbl[small]):  x: %.3f %.3f  y: %.3f %.3f  z: %.3f %.3f    %.3f \n",
                               $bl_centx, $smx, $bl_centy, $smy, $bl_centz, $smz, $sep if $verbose >= 5;
                        if ( $sep < $sep_criterion ) {
                            $qa6_matches{$bl_snid} ++;
                            print "      Nodule ID $id matches with SNID $bl_snid.\n";
                        }
                    }
                }
                print "    Non-nodules:\n";
                for my $rdr ( keys %nonnodinfo ) {
                    for my $id ( keys %{$nonnodinfo{$rdr}} ) {
                        my $nonxyz_ref = $nonnodinfo{$rdr}{$id};
                        my $nonx = @$nonxyz_ref[0] * $pixeldim;
                        my $nony = @$nonxyz_ref[1] * $pixeldim;
                        my $nonz = @$nonxyz_ref[2] * $slicespacing;
                        my $sep = dist ( $bl_centx, $bl_centy, $bl_centz, $nonx, $nony, $nonz );
                        printf "      separation between (bl[lg] unbl[non-nod]):  x: %.3f %.3f  y: %.3f %.3f  z: %.3f %.3f    %.3f \n",
                               $bl_centx, $nonx, $bl_centy, $nony, $bl_centz, $nonz, $sep if $verbose >= 5;
                        if ( $sep < $sep_criterion ) {
                            $qa6_matches{$bl_snid} ++;
                            print "      Non-nodule ID $id matches with SNID $bl_snid.\n";
                        }
                    }
                }
            }
        }  # end of indexing over readers in the majority hash
        for ( keys %qa6_matches ) {
            if ( $qa6_matches{$_} == 0 ) {
                #""" User message doc: 4508: Nothing has been found to match with an SNID which was marked by other readers in the blinded read (QA error #6[original]).
                msg_mgr (
                    severity => 'WARNING',
                    msgid =>4508,
                    appname => 'MAX',
                    line => __LINE__ - 5,
                    text => my $text = ( sprintf "QA error #6[original]: Nothing has been found to match with \"SNID\" %s which was marked by at least %s readers in the blinded read.", $_, MAJORITYTHR ),
                    accum => 1,
                    verbose => 2,
                    code => -1
                );
            }
        }
    }
    
#@@@ Code location: QA7
    if ( $qa_droplg ) {
        print "\nCheck for QA technical error #7:\n";
        # Compare large nodule IDs between the blinded and unblinded reads...
	my $lnifile = File::Spec->catfile( $dirsave, LNIDEFFILENAME );

        if ( -e $lnifile ) {
            my %bl_centroids = %{ doit ( $lnifile ) };
            print "dump of \%bl_centroids (restored)... \n", Dumper(%bl_centroids) if $verbose >= 4;
            print "dump of \%centroids (current)... \n", Dumper(%centroids) if $verbose >= 5;
            # Compare the two centroids hashes:
            # Index thru the blinded centroid data.  Check to see if each large nodule in the blinded
            # data has a corresponding entry in the unblinded centroid data.  We will base correspondence
            # on proximity of centroids.
            my $sep_criterion = $voxeldim * CENTSEPFACTOR;
            printf "  Using a centroid separation criterion of %.2f mm. \n", $sep_criterion if $verbose >= 3;
            for my $bl_rdr ( keys %bl_centroids ) {
                for my $bl_id ( keys %{$bl_centroids{$bl_rdr}} ) {
                    print "  blinded data: for reader $bl_rdr and ID $bl_id...\n" if $verbose >= 5;
                    my $bl_centx = $bl_centroids{$bl_rdr}{$bl_id}{'centx'} * $pixeldim;
                    my $bl_centy = $bl_centroids{$bl_rdr}{$bl_id}{'centy'} * $pixeldim;
                    my $bl_centz = $bl_centroids{$bl_rdr}{$bl_id}{'centz'} * $slicespacing;
                    my $bl_sizeclass = ( $bl_centroids{$bl_rdr}{$bl_id}{'count'} == 1 ? 'small' : 'large' );
                    next if $bl_sizeclass eq 'small';  # skip over small nodules on the blinded read
                    my $num_matched = 0;
                    for my $rdr ( keys %centroids ) {
                        for my $id ( keys %{$centroids{$rdr}} ) {
                            print "    unblinded data: for reader $rdr and ID $id...\n" if $verbose >= 5;
                            my $centx = $centroids{$rdr}{$id}{'centx'} * $pixeldim;
                            my $centy = $centroids{$rdr}{$id}{'centy'} * $pixeldim;
                            my $centz = $centroids{$rdr}{$id}{'centz'} * $slicespacing;
                            my $sizeclass = ( $centroids{$rdr}{$id}{'count'} == 1 ? 'small' : 'large' );
                            my $sep = dist ( $bl_centx, $bl_centy, $bl_centz, $centx, $centy, $centz );
                            printf "      separation between (bl unbl):  x: %.3f %.3f  y: %.3f %.3f  z: %.3f %.3f  %s %s    %.3f \n",
                                   $bl_centx, $centx, $bl_centy, $centy, $bl_centz, $centz, $sizeclass, $bl_sizeclass, $sep if $verbose >= 5;
                            if ( $sep < $sep_criterion ) {
                                $num_matched++;
                                print "  Blinded nodule ID $bl_id has been marked in the unblinded read as ID $id \n";
                            }
                        }
                    }
                    if ( $num_matched == 0 ) {
                        #""" User message doc: 4506: There is a blinded nodule that has no corresponding nodule in the unblinded read for this reader (QA error #7).
                        msg_mgr (
                            severity => 'WARNING',
                            msgid =>4506,
                            appname => 'MAX',
                            line => __LINE__ - 5,
                            text => my $text = ( sprintf "QA error #7: blinded nodule ID %s has no corresponding nodule in the unblinded read for this reader (QA error #7).", $bl_id ),
                            accum => 1,
                            verbose => 2,
                            code => -1
                        );
                    }
                    elsif ( $num_matched > 1 ) {
                        #""" User message doc: 4507: There is ambiguity in detecting whether a blinded nodule has a match in the unblinded read for this reader (QA error #7).
                        msg_mgr (
                            severity => 'WARNING',
                            msgid =>4507,
                            appname => 'MAX',
                            line => __LINE__ - 5,
                            text => my $text = ( sprintf "There is ambiguity in detecting whether blinded nodule ID %s has a match in the unblinded read (QA error #7).", $bl_id ),
                            accum => 1,
                            verbose => 2,
                            code => -1
                        );
                    }
                }
            }
        }
        else {
            #""" User message doc: 6316: The file containing large nodule information (used for QA) does not exist.
            msg_mgr (
                severity => 'FATAL',
                msgid => 6316,
                appname => 'MAX',
                line => __LINE__ - 6,
                text => my $text = ( sprintf "The file, %s, containing large nodule information (used for QA) does not exist.", $lnifile ),
                before => 1,
                after => 2,
                accum => 1,
                verbose => 1,
                code => $Site_Max::RETURN_CODE{saveinevalerror}
            );
        }  # end of if/else on checking the file
    }  # end of if on $qa_droplg flag
    
}  # end of the if/else on testing $qa_none

# Look at an early exit condition:
if  (grep {/^centroid/} @actionlist) { 
    $exit_msg = "Exiting on \"--exit-early=centroid\"";
    exit $Site_Max::RETURN_CODE{normal};
}

# dump %contours again now that it has been corrected for inclusions/exclusions in sub centroid_calcs:
print "\n";
dump_contours_hash() if $verbose >= 6;

# Create %contours1 -- a version of %contours in which the keys are re-ordered such that they are
# better suited for matching and pmap generation.
reorder_contours();


# ==================================================
# =                                                =
# =        P E R F O R M   M A T C H I N G         =
# =                                                =
# ==================================================
sub section130__matching {}  # a dummy sub that lets us jump to this location via the function list in our editor

print "\n\n==================== Perform matching =======================\n" if $verbose >= 1;
    
# If we found no nodules, this is a fatal error at this point; it was issued as informational earlier.
#@@@ Code location: NoNodsFnd2
if ( ! $foundnodules ) {
    #""" User message doc: 6602: No nodules were found; matching cannot be performed.
    msg_mgr (
        severity => 'FATAL',
        msgid => 6602,
        appname => 'MAX',
        line => __LINE__ - 5,
        text => 'No nodules were found; matching cannot be performed.',
        before => 1,
        after => 2,
        accum => 1,
        verbose => 1,
        code => $Site_Max::RETURN_CODE{nonoduleserror}
    );
}

#@@@ Code location: TooFewRdrs
# Because of the --skip-num-files-check option, it's possible that we get here with insufficient
# info (not enough readers) to preform matching, so we'll check for this:
if ( $numreaders < 2 ) {
    #""" User message doc: 6404: There must be responses from at least two readers before matching can be performed.
    msg_mgr (
        severity => 'FATAL',
        msgid => 6404,
        appname => 'MAX',
        line => __LINE__ - 5,
        text => 'There must be responses from at least two readers before matching can be performed.',
        before => 1,
        after => 2,
        accum => 1,
        verbose => 1,
        code => $Site_Max::RETURN_CODE{inputerror}
    );
}

# Initially, we just call this sub which uses simple overlap as the matching criterion...
simple_matching();

### Since this sub isn't ready -- or desirable! -- we crash out early in the app if we see the --sec-matching option. ###
# This sub implements other overlap measures that assume that simple overlap detection (above) has
# been done.
# Secondary matching is performed only if explicitly requested.
# (It can be effectively disabled by specifying large values for NCSthrDEF and VRthrDEF.)
secondary_matching() if $sec_matching;

# Save the %majority hash (QA #6[original])
save_large_nod_info('majority') if $save_lni;

if ( $readtype_optval eq UNBLINDEDREADTYPEVALUE ) {
    print "\n\n================== Specific QA tests - II ==================\n" if $verbose >= 2;
    if ( $qa_none ) {
        print "\nSkipping specific QA tests.\n" if $verbose >= 2;
    }
    else {
#@@@ Code location: QA6new
        # Perform QA #6 (new version):
        print "\nCheck for QA technical error #6 (new version):\n" if $verbose >= 2;
        # In the unblinded read response, if a SNID consists of exactly 3 constituents (or actually
        # NUMREADERS - 1) that are all large nodules,
        # then an error is flagged for the 4th reader who failed to mark anything for that SNID.
        my $foundone = 0;  # a flag to control printing of a message at the end
        my $numrdrthr = NUMREADERS - 1;  # a threshold of the number of readers
        # Loop over the SNIDs which are the keys in %noduleremaprev:
        for my $snid ( keys %noduleremaprev ) {
            print "  Checking SNID $snid\n" if ( $verbose >= 5 or 0 );
            my @rdrlist = ();  # initialize the list of readers
            my $numlarge = 0;  # initialize this counter (counts the number of large nodules in an SNID)
            my $nummembers = scalar keys %{$noduleremaprev{$snid}};  # number of members in the SNID
            print "    $nummembers members" if ( $verbose >= 5 or 0 );
            if ( $nummembers == $numrdrthr ) {
                # If we match the threshold, we have more work to do (continue with the code after this if stmt.)
                print " so we need to count the number of large nodules for this SNID:\n" if ( $verbose >= 5 or 0 );
            }
            else {
                # Otherwise, skip to the next SNID
                print " so we need check no further for this SNID.\n" if ( $verbose >= 5 or 0 );
                next;
            }
            # Count the number of large nodules in this SNID:
            for my $rdr ( keys %{$noduleremaprev{$snid}} ) {
                for my $nid ( keys %{$noduleremaprev{$snid}{$rdr}} ) {
                    $rdrlist[$rdr] = 1;  # set a flag to show that this reader marked a nodule in this SNID; for use below
                    # If it's neither a small nodule nor a non-nodule, it must be a large nodule:
                    $numlarge++ if ( ! exists($smnodinfo{$rdr}{$nid}) && ! exists($nonnodinfo{$rdr}{$nid}) );
                    print "      checking reader / ID    $rdr / $nid   (large nodule count: $numlarge) \n" if ( $verbose >= 5 or 0 );
                }
            }
            # Find which reader is *not* represented in this SNID:
            # The logic of this loop as a valid way of detecting this depends on the fact that
            # $numrdrthr = NUMREADERS - 1 (the "1" is key -- that is, it's an error only if exactly
            # 1 reader didn't make a mark for this SNID)
            my $rdrnum;
            print "    Check the reader list: " if ( $verbose >= 5 or 0 );
            for my $i ( 0 .. (NUMREADERS - 1) ) {
                print "$i " if ( $verbose >= 5 or 0 );
                $rdrnum = $i;  # transport the reader number index outside the loop for use below
                # Jump out when we find a reader (actually, *the* reader) that is not in the list:
                last if ! exists $rdrlist[$i];
            }
            print "\n" if ( $verbose >= 5 or 0 );
            # Finally! -- we check for the error:
            if ( $numlarge == $numrdrthr ) {
                $foundone = 1;  # set the flag
                #""" User message doc: 4513: A reader failed to mark a nodule for an SNID while the remaining readers did.
                msg_mgr (
                    severity => 'WARNING',
                    msgid => 4513,
                    appname => 'MAX',
                    line => __LINE__ - 7,
                    text => my $text = ( sprintf "Reader %s (%d) did not mark anything for SNID %s while the remaining readers did (QA error #6new).",
                                                 $servicingRadiologist[$rdrnum], $rdrnum, $snid ),
                    accum => 1,
                    verbose => 2,
                    code => -1
                );
            }
        }
        print "  No errors of this type were found.\n" if ( $foundone == 0 && $verbose >= 2 );
        print "\n" if $verbose >= 2;
    }  # end of else for $qa_none
}

# Look at an early exit condition:
if  (grep {/^match/} @actionlist) { 
    $exit_msg = "Exiting on \"--exit-early=match\"";
    exit $Site_Max::RETURN_CODE{normal};
}


# ================================================
# =                                              =
# =        C A L C U L A T E   P M A P S         =
# =                                              =
# ================================================
sub section160__pmap {}  # a dummy sub that lets us jump to this location via the function list in our editor

pmap_calcs() if $createpmap;


# ======================================
# =                                    =
# =        T H A T ' S   A L L         =
# =                                    =
# ======================================
sub section170__END_of_the_app {}  # a dummy sub that lets us jump to this location via the function list in our editor

# We define an END block to carry-out end-of-run actions, error processing, final message, etc.
END {
    
    exit 0 if $help;  # exit quietly with a "success" status if we're just showing the help text
    
    print "\n\n============== Processing MAX's termination code ==============\n\n";
    
    print "$exit_msg\n\n" if $exit_msg;
    
    # Close any open files -- or will they be closed OK "by the system" when we exit?:
    # >>> code to be added later? <<<
    
    # Extract the mnemonic of the error code:
    my ($mnemonic, $code);
    while( ($mnemonic, $code) = each %RETURN_CODE ) {
        last if $code eq $?;
    }
    
    # Generate the final message for insertion into @main::msglog
    #""" User message doc: 3101: Exiting from max.pl .
    my $exitdatetime = strftime "%a %b %e %H:%M:%S %Z %Y", localtime;
    msg_mgr (
        severity => 'INFO',
        msgid => 3101,
        text => my $text = ( sprintf "Exit from max.pl with return code %s (%s) at %s.", $?, $mnemonic, $exitdatetime ),
        accum => 1,
        screen => 0,  # doesn't need to be displayed on the screen
        code => -1
    );
    
    # Dump any text in the warnings log...
    $verbose = 3 if ! $verbose;  # be sure it has a value
    if ( @main::msglog && $verbose >= 1) {
        my $error_in_saving_messages = 0;
        print "Messages produced during the run:\n";
        foreach ( @main::msglog ) {
            print "  $_ \n";
            # Save to file only if the filename has been set.  Do this in an eval to catch the
            # error that results if the filehandle couldn't be opened.
            eval { print $messages_fh "$_ \n" if ( $savemessages && $messagesfile ) };
            $error_in_saving_messages = 1 if $@;
        }
        print "\n";
        print "Messages could not be saved to file as requested.\n\n" if $error_in_saving_messages;
    }

    print "Exiting\n\n";
    exit $code; #$?;
    
}  # end of the END block




# ==================================================
# =                                                =
# =        M A I N   S U B R O U T I N E S         =
# =                                                =
# ==================================================
sub section190__main_subs {}  # a dummy sub that lets us jump to this location via the function list in our editor

# These routines appear in the order in which they are executed.

# A few of these routines are called only once for a very specific purpose
# rather than being general purpose routines.  Thus globals are used for all
# "inputs" and "outputs".  These routines were broken-out in this way to make
# the main code easier to read.

# There are three twig handler subs: show, rSpass1, and rSpass2.
# In many cases, variable names in the twig handlers are chosen to mimic
# the names of the corresponding XML tag names.  For example, $rSindex is an
# index for going thru the readingSessions which are stored in @rSlist.


sub show
{
    # This sub displays those elements named in the lists below which contain header tag names
    my ( $twig, $element ) = @_;
    $headertag_ok = 1;  # If we're here, we found the expected main header tag.
    print "\n\nSelected header elements...\n" if $verbose >= 3;
    my ( @list1 )   = qw(Version TaskDescription CtImageFile);
    my ( @listreq ) = qw(DateRequest RequestingSite);
    my ( @listres ) = qw(DateService ServicingSite ResponseDescription ResponseComments);
    my ( @list ) = ( @list1, @listreq, @listres );
    foreach my $str ( @list ) {
        my $e = $element->first_child($str);
        if ( $e ) {
            print "  ", $str, ": ", $e->text , "\n" if $verbose >= 3;
        }
    }
    # Pull these out as special cases for use elsewhere (they are global variables):
    # (All these are required tags, but some are not present in the NIH versions of the files (and
    #   one is present only in the NIH files) so we'll include checks for existence.)
    $taskdescr   = $element->first_child('TaskDescription')->text    if $element->first_child('TaskDescription');
    $reqsite     = $element->first_child('RequestingSite')->text     if $element->first_child('RequestingSite');
    $svcsite     = $element->first_child('ServicingSite')->text      if $element->first_child('ServicingSite');
    print "+++ servicing site parsed from the header: $svcsite \n" if ( 0 );  # for testing
    $ctimagefile = $element->first_child('CtImageFile')->text        if $element->first_child('CtImageFile');
    $seriu       = $element->first_child('SeriesInstanceUid')->text  if $element->first_child('SeriesInstanceUid');
    $stuiu       = $element->first_child('StudyInstanceUID')->text   if $element->first_child('StudyInstanceUID');
    # Parse the read type:
    if ( $taskdescr =~ m/^First blinded read$/ ) {
        $readtype_parsed = BLINDEDREADTYPEVALUE;
    }
    elsif ( $taskdescr =~ m/^Second unblinded read$/ ) {
        $readtype_parsed = UNBLINDEDREADTYPEVALUE;
    }
#@@@ Code location: BadTskDescr
    else {
        #""" User message doc: 6405: Illegal content in tag <TaskDescription> in this XML file.
        msg_mgr (
            severity => 'FATAL',
            msgid => 6405,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 9,
            text => my $text = "Illegal content in tag <TaskDescription> in this XML file.",
            before => 1,
            after => 2,
            accum => 1,
            verbose => 1,
            code => $Site_Max::RETURN_CODE{validationerror}
        );
    }
    print "+++ Read type:    Command line option value: $readtype_optval    XML tag name: $readtype_tag    Parsed from <TaskDescription>: $readtype_parsed \n" if ( 0 );  # for testing
#@@@ Code location: IncnstRdTypeData
    # Keep track of the read types we see in the input XML file(s).  Should be exactly one entry!  If not, fatal error...
    # (We should similarly check message type!)
    $readtype_list{$readtype_parsed} = 1;  # just set to a flag value to mark the presence
    if ( scalar( keys %readtype_list ) != 1 ) {
        #""" User message doc: 6406: Inconsistent read type detected between/within the input XML data file(s).
        msg_mgr (
            severity => 'FATAL',
            msgid => 6406,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => my $text = "Inconsistent read or message type detected between/within the input XML data file(s).",
            before => 1,
            after => 2,
            accum => 1,
            verbose => 1,
            code => $Site_Max::RETURN_CODE{xmlinputdataerror}
        );
    }
#@@@ Code location: IncnstRdType
    # Be sure the read type is consistent between the XML and the command line:
    if ( $readtype_parsed ne $readtype_optval ) {
        # N.B.: We keep this as an info message (rather than elevating it to a warning) 
        #       since this inconsistency is unavoidable in processing unblinded request message files for QA: 
        #       The <TaskDescription> tag in this case is "Second unblinded read".
        #       But the data are contained within <blindedReadNodule> tags (since the data came from unblinded reads), 
        #       so "--data-type=blinded" must be given on the command line.
        #       Hence the unavoidable inconsistency within unblinded request files (from MAX's standpoint).
        # NO >>>> Reverse the above: promote 3402 to fatal 6408...
        #""" User message doc: 6408: Inconsistency found in the read type between the input XML data file and the command line (or as a default).
        msg_mgr (
            severity => 'FATAL',
            msgid => 6408,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => my $text = sprintf ( "Read type detected in the input XML data file is \"%s\", but \"%s\" was found on the command line (or as a default).",
                                         $readtype_parsed, $readtype_optval ),
            accum => 1,
            verbose => 2,
            code => $Site_Max::RETURN_CODE{inputerror}
        );
    }
    # Accumulate the comments:
    if ( $element->first_child('ResponseComments') ) {
        $cmnt_tags{$svcsite} = $element->first_child('ResponseComments')->text;
        print "\nComments have been stored for $svcsite: $cmnt_tags{$svcsite} \n" if $verbose >= 5;
    }
    print "  ............................................................processing XML reading session data \r";
}


sub rSpass1 {

    # "readingSession pass 1"
    # Travese the twig:
    #   Display info parsed from the twig
    #   Gather info to define the bounding box
    #   Generate XML commands to keep nodule and non-nodule history
    # This routine is also used for validation of the XML and its content.
    
    my ( $twig, $readingSession ) = @_;
    my $num;
    my $posn;
    
    # Check to be sure we encountered the header as we expected it to be.  (This seems to be an odd
    # place to check this, but b/c of the way we setup the twigs, we must do it this way.)
    if ( ! $headertag_ok ) {
        #""" User message doc: 6407: Error in parsing the header of an XML file.
        msg_mgr (
            severity => 'FATAL',
            msgid => 6407,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 7,
            text => my $text = "Error in parsing the header of an XML file.",
            before => 1,
            after => 2,
            accum => 1,
            verbose => 1,
            code => $Site_Max::RETURN_CODE{xmlinputparsingerror}
        );
    }

    # Use this structure to keep track of duplicate non-nodule IDs:
    my %seen_nnid;  # accumulate the count of each reader ID/non-nodule ID that has been seen
    
    print "                                                                                                   \n";
    
    # some diagnostic output...
    print "\nThe entire twig: \n", $twig->print, "\n" if $verbose >= 7;
    
    # Start the next history section for this reader:
    accum_xml_lines ( 'history', \%xml_lines, $Site_Max::TAB[1] . "<MarkingHistory>" ) if $xmlhistory;
    
    # Note: The entire $readingSession element is bracketed by <LidcReadMessage>...</LidcReadMessage>
    
    print "\n" if $verbose >= 2;
    my @rSlist = $readingSession->children('readingSession');
    
    foreach my $rSindex (@rSlist) {
        print "\nReading session number ", $rSindex->pos('readingSession'), "...\n" if $verbose >= 2;
        my $servicingRadiologistID = modify_reader_id ( $rSindex->first_child('servicingRadiologistID')->text );  # get and optionally modify the ID
        my $annotationVersion = $rSindex->first_child('annotationVersion')->text;
        print "  servicing radiologist ID: ", $servicingRadiologistID, " (reader index ",$servicingRadiologistIndex, ")\n" if $verbose >= 2;
        $servicingRadiologist[$servicingRadiologistIndex] = $servicingRadiologistID;
        # store some reader ID info for later use
        $reader_info{$servicingRadiologistIndex}{'id'}   = $servicingRadiologistID;
        $reader_info{$servicingRadiologistIndex}{'site'} = $svcsite;
        if ( $xmlcxrreq ) {
            print $cxrreqxml_fh "<CTreadingSession>\n";
            print $cxrreqxml_fh "<annotationVersion>$annotationVersion</annotationVersion>\n";
            print $cxrreqxml_fh "<servicingRadiologistID>$servicingRadiologistID</servicingRadiologistID>\n";
        }
        # >>> The following is included for development of concept only and is not used in practice. <<<
        # Parse the QA tags:
        my @qAlist = $rSindex->children('qualityAssurance');
        if ( @qAlist && $verbose >= 3 ) {
            print "  number of QA tag sections: " . scalar @qAlist . "\n";
            foreach my $qAindex ( @qAlist ) {
                print "    in QA section " . $qAindex->pos('qualityAssurance') . "...\n";
                my @elist = $qAindex->children('error');
                print "      number of errors: " . scalar @elist . "\n";
                foreach my $eindex ( @elist ) {
                    print "        error " . $eindex->pos('error') . ":\n";
                    my $ia_cmnt = $eindex->first_child('initialAssessment')->{'att'}->{'comment'};
                    print "          initial assessment: " . $eindex->first_child('initialAssessment')->text . ( $ia_cmnt ? " ($ia_cmnt)" : "" ) . "\n";
                    print "          action taken: "       . $eindex->first_child('actionTaken'      )->text . "\n";
                    print "          date action taken: "  . $eindex->first_child('dateActionTaken'  )->text . "\n";
                    my $xcoord = $eindex->first_child('location')->{'att'}->{'xCoord'};
                    my $ycoord = $eindex->first_child('location')->{'att'}->{'yCoord'};
                    my $slice  = $eindex->first_child('location')->{'att'}->{'slice' };
                    print "          location: "           . "xcoord " . ( $xcoord ? "= $xcoord, " : "is unknown, " )
                                                           . "ycoord " . ( $ycoord ? "= $ycoord, " : "is unknown, " )
                                                           . "slice "  . ( $slice  ? "= $slice"    : "is unknown"   ) . "\n";
                    print "          comments: "           . $eindex->first_child('comments'         )->text . "\n";
                }  # end of looping over QA error sections
            }  # end of looping over QA sections
        }
        print "  number of nodule sections: ", $rSindex->children_count($readtype_tag), "\n" if $verbose >= 2;
        my @ubRNlist = $rSindex->descendants($readtype_tag);
        # Parse through the <unblindedReadNodule> section for nodule info:
        my $prevspacing = -1.0;  # use this to keep a (very) short spacing history as we go thru the nodules
        foreach my $ubRNindex (@ubRNlist) {
            my $zcoord;  # "declare" this out here so its scope is large enough to use in error messages
            my @zcoordsnod = ();  # initialize the array to hold the z coords of this nodules' slices
            my $roitype;
            $sizeclass = "large";  # will be adjusted below as needed to the correct value
            print "    in nodule section ", $ubRNindex->pos($readtype_tag), "...\n" if $verbose >= 3;
            my $noduleid = $ubRNindex->first_child('noduleID')->text;
            print "      nodule ID: $noduleid \n" if $verbose >= 3;
            $plotinfo_noduleID = $noduleid;
            my $numrois = $ubRNindex->children_count('roi');
            print "      number of ROIs: $numrois \n" if $verbose >= 3;
            # Initialize the bounding box for the nodule:
            my ( $minx_nod, $maxx_nod, $miny_nod, $maxy_nod ) = ( CTIMAGESIZE, 0, CTIMAGESIZE, 0 );
            my @roilist = $ubRNindex->descendants('roi');
            foreach my $roiindex (@roilist) {
                # Initialize the bounding box for this slice:
                my ( $minx_sl, $maxx_sl, $miny_sl, $maxy_sl ) = ( CTIMAGESIZE, 0, CTIMAGESIZE, 0 );
                my $roinumber = $roiindex->pos('roi');
                print "      in ROI $roinumber...\n" if $verbose >= 3;
                $zcoord = $roiindex->first_child('imageZposition')->text;
                $zcoord =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
                $plotinfo_zcoord = $zcoord;
                @zcoordsnod = ( @zcoordsnod, $zcoord );  # accumulate the nodule's slices z coords in mm.
                print "        image Z position: $zcoord mm. \n" if $verbose >= 3;
                my $SOPinstUID = $roiindex->first_child('imageSOP_UID')->text;
                $SOPinstUID =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
                print "        image SOP instance UID: $SOPinstUID \n" if $verbose >= 3;
                $z2siu{ round ( $zcoord, NUMDIGRND ) } = $SOPinstUID;  # store this info for later use
#@@@ Code location: InExVal1
                if ( $roiindex->first_child('inclusion')->text eq 'TRUE' ) { 
                    $roitype = 'inclusion'; 
                }
                elsif ( $roiindex->first_child('inclusion')->text eq 'FALSE' ) { 
                    $roitype = 'exclusion'; 
                }
                else { 
                    #""" User message doc: 6402: Could not determine inclusion/exclusion status (in pass 1).
                    msg_mgr (
                        severity => 'FATAL',
                        msgid => 6402,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__ - 6,
                        text => 'Could not determine inclusion/exclusion status.',
                        accum => 1,
                        verbose => 1,
                        code => $Site_Max::RETURN_CODE{validationerror}
                    );
                }
                $plotinfo_roitype = $roitype;
                print "        ROI type: $roitype \n" if $verbose >= 3;
                my $numem = $roiindex->children_count('edgeMap');
                print "        number of edge maps: $numem \n" if $verbose >= 3;
                # Check the number of edge map points (for inclusions only):
                # > Note: The number of edge map points stored in the XML is one more that the apparent number 
                #           of points drawn on the image since the 1st & last points are the same to close the contour.
                # > Note: Assume that MINNUMEMPTS = 5 as typically set in Site_Max.
                #   1 point and  1 edgemap means it's a small nodule, so no message
                #   1 point and >1 edgemap means it's probbaly extraneous, so trigger the message
                #   0 & 2 may be impossible (depending on the drawing tool?), so trigger the message
                #   3 & 4 cannot enclose any pixels, so trigger the message
                #   But 5 (and greater) points can enclose at least 1 pixel, so no message
                # Break it down into two messages:
#@@@ Code location: TooFewPnts1
                # If it's a single-slice nodule, it's probably an extraneous mark, so we'll give a warning:
                if (
                     ( $roitype eq 'inclusion' )
                                  &&
                     ( $numem == 0 || ( $numem >= 2 && $numem <= (MINNUMEMPTS-1) ) )
                                  &&
                     ( $numrois == 1 ) 
                                       ) {
                    #""" User message doc: 4403: Too few points in the ROI of a single slice nodule.
                    msg_mgr (
                        severity => 'WARNING',
                        msgid => 4403,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__ - 12,
                        text => my $text = ( sprintf ( "At z = %.3f mm. for nodule %s (a single-slice inclusion) drawn by reader %s(%s) contains only %d points; we expected at least %d.",
                                                       $roinumber, $numrois, $zcoord, $noduleid, $servicingRadiologistID, $servicingRadiologistIndex, $numem, MINNUMEMPTS ) ),
                        accum => 1,
                        verbose => 2,
                        code => -1
                        );
                }
#@@@ Code location: TooFewPnts2
                # If it's a multi-slice nodule, the reader may have drawn a small "end cap" on either end.  We won't try to arbitrate this
                #   but will just give an informational message:
                if (
                     ( $roitype eq 'inclusion' )
                                  &&
                    #( $numem == 0 || ( $numem >= 2 && $numem <= (MINNUMEMPTS-1) ) )
                     ( $numem <= (MINNUMEMPTS-1) )
                                  &&
                     ( $numrois > 1 )
                                      ) {
                    #""" User message doc: 3401: Too few points in an ROI of a multi-slice nodule.
                    msg_mgr (
                        severity => 'INFO',
                        msgid => 3401,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__ - 12,
                        text => my $text = ( sprintf ( "At ROI %d of %d at z = %.3f mm. for nodule %s (an inclusion) drawn by reader %s(%s) contains only %d points; we expected at least %d.",
                                                       $roinumber, $numrois, $zcoord, $noduleid, $servicingRadiologistID, $servicingRadiologistIndex, $numem, MINNUMEMPTS ) ),
                        accum => 1,
                        code => -1
                        );
                }
                # The number of surface pixels referenced in the following "if" is one less than the
                #   number of edge maps since the 1st and last points are the same in the XML...
                if ( $nnninfo{$servicingRadiologistIndex}{$noduleid}{"surface-pix"} ) {
                     $nnninfo{$servicingRadiologistIndex}{$noduleid}{"surface-pix"} += ( $numem - 1 );
                }
                else {
                    $nnninfo{$servicingRadiologistIndex}{$noduleid}{"surface-pix"} = ( $numem - 1 );
                }
                # adjust the z size (in mm.) of the bounding box
                if ( $zcoord < $minzc ) { $minzc = $zcoord };
                if ( $zcoord > $maxzc ) { $maxzc = $zcoord };
                my @eMlist = $roiindex->descendants('edgeMap');
                if ( $ubRNindex->children_count('roi')    == 1 && 
                     $roiindex->children_count('edgeMap') == 1 ) { 
                    # one ROI, one edgemap & one point pair means a small nodule:
                    $sizeclass = "small"; 
                }
                $nnninfo{$servicingRadiologistIndex}{$noduleid}{"sizeclass"} = $sizeclass;
                @xdata = (); @ydata = ();  # initialize for plotting
                my ( $prev_xcoord, $prev_ycoord );  # for use in the loop below
                my ( $beg_xcoord, $beg_ycoord, $end_xcoord, $end_ycoord );  # to test whether begin & end pixels are identical
                foreach my $eMindex (@eMlist) {
                    my $xcoord = $eMindex->first_child('xCoord')->text;
                    my $ycoord = $eMindex->first_child('yCoord')->text;
                    $beg_xcoord = $xcoord unless $beg_xcoord;  # These are set only for
                    $beg_ycoord = $ycoord unless $beg_ycoord;  # the 1st pixel in the loop.
                    $end_xcoord = $xcoord;  # When we exit this loop, these will
                    $end_ycoord = $ycoord;  # hold the coords of the end pixel.
                    if ( $verbose >= 4 ) { 
                        print "          point location in edge map ",
                              $eMindex->pos('edgeMap'), " : (", $xcoord, ", ", $ycoord, ") \n"  # terminate with \r or \n depending on how you want to see the coords
                    }
                    if ( $qa_conn && $prev_xcoord && $prev_ycoord ) {
                        my $conn_code = check_pixel_connectivity ( $prev_xcoord, $prev_ycoord, $xcoord, $ycoord );
                        print "+++ returned from sub check_pixel_connectivity +++\n" if (0);  # testing
                        if ( $conn_code == 0 || $conn_code == -1 ) {
                            #""" User message doc: 4405: Improperly connected points (neither 4- nor 8-connected) in an ROI.
                            msg_mgr (
                                severity => 'WARNING',
                                msgid => 4405,
                                appname => 'MAX',
                                subname => (caller(0))[3],
                                line => __LINE__ - 6,
                                text => my $text = ( sprintf "Improperly connected points (neither 4- nor 8-connected) detected for reader %s(%s) in nodule %s around x,y = %d,%d",
                                                     $servicingRadiologistID, $servicingRadiologistIndex, $noduleid, $xcoord, $ycoord ),
                                before => 0,
                                after => 1,
                                accum => 1,
                                verbose => 2,
                                code => -1
                            );        
                        }
                    }
                    $prev_xcoord = $xcoord;  # get ready for the
                    $prev_ycoord = $ycoord;  # next connectivity check
                    # Adjust the global bounding box in x and y:
                    if ( $xcoord < $minx ) { print "BBOX: minx was $minx -- now $xcoord \n" if (grep {/^bbox$/} @testlist); $minx = $xcoord };
                    if ( $xcoord > $maxx ) { print "BBOX: maxx was $maxx -- now $xcoord \n" if (grep {/^bbox$/} @testlist); $maxx = $xcoord };
                    if ( $ycoord < $miny ) { print "BBOX: miny was $miny -- now $ycoord \n" if (grep {/^bbox$/} @testlist); $miny = $ycoord };
                    if ( $ycoord > $maxy ) { print "BBOX: maxy was $maxy -- now $ycoord \n" if (grep {/^bbox$/} @testlist); $maxy = $ycoord };
                    # Adjust the bounding box for this slice:
                    $minx_sl = $xcoord if $xcoord < $minx_sl;
                    $maxx_sl = $xcoord if $xcoord > $maxx_sl;
                    $miny_sl = $ycoord if $ycoord < $miny_sl;
                    $maxy_sl = $ycoord if $ycoord > $maxy_sl;
                    # Adjust the nodule bounding box:
                    $minx_nod = $xcoord if $xcoord < $minx_nod;
                    $maxx_nod = $xcoord if $xcoord > $maxx_nod;
                    $miny_nod = $ycoord if $ycoord < $miny_nod;
                    $maxy_nod = $ycoord if $ycoord > $maxy_nod;
                    # accumulate points for plotting
                    @xdata = (@xdata,$xcoord);
                    @ydata = (@ydata,$ycoord);
                }  # end of the foreach over @eMlist
                if ( $beg_xcoord != $end_xcoord  or  $beg_ycoord != $end_ycoord ) {
                    #""" User message doc: 5407: Beginning and ending pixel coordinates not equal in an ROI.
                    msg_mgr (
                        severity => 'ERROR',
                        msgid => 5407,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__,
                        text => my $text5407 = ( sprintf "The beginning and ending pixel coordinates are not equal in an ROI: reader %s(%s), nodule %s: (%d,%d) != (%d,%d) at z=%.2f mm.",
                                                 $servicingRadiologistID, $servicingRadiologistIndex, $noduleid, $beg_xcoord, $beg_ycoord, $end_xcoord, $end_ycoord, $zcoord ),
                        before => 0,
                        after => 1,
                        accum => 1,
                        verbose => 2,
                        code => -1
                    );
                    my $conn_code = check_pixel_connectivity ( $beg_xcoord, $beg_ycoord, $end_xcoord, $end_ycoord );
                    if ( $conn_code == 0 || $conn_code == -1 ) {
                        #""" User message doc: 5408: There may be a gap between the beginning and end points in an ROI (neither 4- nor 8-connected).
                        msg_mgr (
                            severity => 'ERROR',
                            msgid => 5408,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => my $text5408 = ( sprintf "There may be a gap between the beginning and end points in an ROI (neither 4- nor 8-connected): reader %s(%s) in nodule %s around x,y = %d,%d and %d,%d",
                                                 $servicingRadiologistID, $servicingRadiologistIndex, $noduleid, $beg_xcoord, $beg_ycoord, $end_xcoord, $end_ycoord ),
                            before => 0,
                            after => 1,
                            accum => 1,
                            verbose => 2,
                            code => -1
                        );        
                    }
                }
                # Show the results of the bounding box for this slice:
                print "        bounding box for this slice (in pixels): x = $minx_sl to $maxx_sl and y = $miny_sl to $maxy_sl \n" if $verbose >= 3;
                if ( $qa_narrow ) {
                    my ( $cfnc_ret, $narrow_coords, $overlapping_coords ) = check_for_narrow_contour ( \@xdata, \@ydata );
                    if ( $cfnc_ret == 0 && $narrow_coords ) {
                        #""" User message doc: 4409: The contour drawn around a nodule has a narrow portion.
                        msg_mgr (
                            severity => 'WARNING',
                            msgid => 4409,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 7,
                            text => my $text = ( sprintf("The contour drawn around nodule %s (%s) at z = %.3f mm. has narrow portions at x,y: %s", $noduleid, $servicingRadiologistID, $zcoord, $narrow_coords ) ),
                            accum => 1,
                            code => -1
                        );
                    }
                    if ( $cfnc_ret == 0 && $overlapping_coords ) {
                        #""" User message doc: 4410: The contour drawn around a nodule has an overlapping portion.
                        msg_mgr (
                            severity => 'WARNING',
                            msgid => 4410,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 7,
                            text => my $text = ( sprintf("The contour drawn around nodule %s (%s) at z = %.3f mm. has overlapping portions at x,y: %s", $noduleid, $servicingRadiologistID, $zcoord, $overlapping_coords ) ),
                            accum => 1,
                            code => -1
                        );
                    }
                }
                if ( $plot && @xdata > 1 ) {
                    simpleplot(\@xdata,\@ydata);
                }
            }  # end of the foreach over @roilist
            #print "      Z coords (unsorted) for this nodule's slices: @zcoordsnod \n" if $verbose >= 5;  # for testing
            my $unifstr; ( $unifstr, @zcoordsnod ) = zuni(@zcoordsnod);
            my $spacing = -1.0;  # -1.0 indicates that we don't have a valid spacing yet
            # Conditionally, set the spacing to a valid number: If the spacing is uniform, we can just calc the delta-z
            # from the 1st 2 array elements...
            $spacing = round ( abs ( $zcoordsnod[0] - $zcoordsnod[1] ), NUMDIGRND ) if ( $unifstr eq 'uniform' );
            if ( $verbose >= 3 ) {
                print "      slice spacing uniformity is \"$unifstr\"";
                printf " (%.3f mm.)", $spacing if scalar(@zcoordsnod) >= 2;
                print " over the ", scalar(@zcoordsnod), " slice(s) marked";
                print "\n";
            }
            # Check for spacing problems.  We have a problem if the nodule is large and either of these is true:
            #   * If zuni returned anything other than 'uniform' for 2 or more slices.
            #   * If the current spacing is not the same as the previous (as long as this isn't the first time
            #       through as indicated by the previous spacing being equal to -1.0).
            # (The following logic is complicated, but seems to work over the cases we tested.)
            # (May want to break it down into a series of if/elsif blocks.)
            #   OK if small -- just accumulate the z values
            #   OK if large & 1 slice -- just accumulate the z values
            #   OK if large & 2 slices -- accumulate the z values and calc spacing
            #   ...etc...
#@@@ Code location: SlSpacChg
            print "\n+++ dump of \@zcoordsnod ... \n", Dumper(@zcoordsnod) if (0);  # for testing
            print "+++ | $sizeclass | $unifstr | ", scalar(@zcoordsnod), " | $prevspacing | $spacing | +++ \n\n" if (0);  # for testing
            if ( $sizeclass eq 'large' &&
                 ( ( $unifstr ne 'uniform' && scalar @zcoordsnod >= 2 ) || ( $prevspacing != -1.0 && $spacing != $prevspacing ) ) &&
                 scalar @zcoordsnod != 1 ) {
                # We have a problem with inferring the slice spacing from the XML z coords.  Record a message in the log and set a flag.
                # This event will convert to a fatal error after pass 1 unless we find that --slice-spacing was given on the command line.
                $troubleWithInferringSpacing = 1;
                #""" User message doc: 4503: There is a problem with the slice spacing for the current nodule.
                msg_mgr (
                    severity => 'WARNING',
                    msgid => 4503,
                    appname => 'MAX',
                    subname => (caller(0))[3],
                    line => __LINE__ - 5,
                    text => my $text = ( sprintf ("The slice spacing for nodule ID %s (reader %s) is %s.", $noduleid, $servicingRadiologistID, $unifstr) ),
                    accum => 1,
                    verbose => 2,
                    code => -1
                );
                # probably don't want this conditional on this call to msg_mgr:
                #) if $show_sl_sp_msg;  # set via the --show-slice-spacing-messages option
            }
            $prevspacing    = $spacing if $spacing > -1.0;  # update our (very) short history
            $overallspacing = $spacing if $spacing > -1.0;  # We want to access this outside this sub: As long as we don't have any
                                                            #   z spacing problems, this variable will contain
                                                            #   the "true" z spacing value when we exit this sub.
            @zcoordsallnods = ( @zcoordsallnods, @zcoordsnod );  # accumulate what we have found
            #if ( @zcoordsallnods ) { print "      nodule z coords (unsorted) so far: @zcoordsallnods \n"; }  # testing
            print "      size classification: $sizeclass \n" if $verbose >= 3;
            # Update the nodule counters:
            $foundnodules++;  # counts all nodules found
            $foundsmall++ if  $sizeclass eq 'small';
            # Show the results of the bounding box for this nodule:
            print "      bounding box for this nodule (in pixels): x = $minx_nod to $maxx_nod and y = $miny_nod to $maxy_nod \n" if $verbose >= 3;
            $foundlarge++ if $sizeclass eq 'large';
#@@@ Code location: ProcChars
            # Process the characteristics section:
            my $charbase = ( $ubRNindex->descendants('characteristics') )[0];  # there's only 1 (or 0) characteristics section
            if ( $sizeclass eq 'large' && $messagetype_tag eq RESPHDRTAGNAME && $readtype_tag eq UNBLINDEDREADTAGNAME ) {
                # Since this is a large nodule and this is an unblinded response message,
                #   there should be a characteristics section with exactly $NUMCHARACTERISTICS properties...
                if ( $charbase ) {
                    # ok, we found a chars section
                    my $num_props = $charbase->children_count('*');
                    if ( $num_props != $NUMCHARACTERISTICS ) {
                        #""" User message doc: 5402: An improper number of characteristics properties was found.
                        msg_mgr (
                            severity => 'ERROR',
                            msgid => 5402,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 7,
                            text => my $text = ( sprintf "An improper number of characteristics properties was found for nodule ID %s, reader %s.", $noduleid, $servicingRadiologistID ),
                            accum => 1,
                            code => -1
                            );
                    }  # end of if that checks the number of properties
                    # List and check the characteristics properties values:
                    print "      characteristics:\n" if $verbose >= 3;
                    foreach my $prop_name ( @char_props ) {
                        # we can process this property name only if it exists in the XML
                        if ( $charbase->first_child( $prop_name ) ) {
                            my $prop_value = $charbase->first_child( $prop_name )->text;
                            if ( $prop_value < 1 || $prop_value > MAXCHARPROPVALUE ) {
                                #""" User message doc: 5404: A characteristics property value was out of range.
                                msg_mgr (
                                    severity => 'ERROR',
                                    msgid => 5404,
                                    appname => 'MAX',
                                    subname => (caller(0))[3],
                                    line => __LINE__ - 7,
                                    text => my $text = ( sprintf "A characteristics property value was out of range for nodule ID %s, reader %s.", $noduleid, $servicingRadiologistID ),
                                    accum => 1,
                                    code => -1
                                    );
                            }  # end of if that checks the property value
                            print "        $prop_name: $prop_value \n" if $verbose >= 3;
                        }  # end of if checking to see if the property name was found in the XML
                    }  # end of the foreach loop over all properties
                }  # end of if that checks for the presence of $charbase
                else {
                    #""" User message doc: 5405: The characteristics section is missing.
                    msg_mgr (
                        severity => 'ERROR',
                        msgid => 5405,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__ - 7,
                        text => my $text = ( sprintf "The characteristics section is missing for nodule ID %s, reader %s.", $noduleid, $servicingRadiologistID ),
                        accum => 1,
                        code => -1
                        );
                }
            }  # end of if for being in a nodule that should have a chars section
            else {
                # There should NOT be a characteristics section
                if ( $charbase ) {
                    #""" User message doc: 5403: Found a characteristics section where there should have been none.
                    msg_mgr (
                        severity => 'ERROR',
                        msgid => 5403,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__ - 7,
                        text => my $text = ( sprintf "Found a characteristics section where there should have been none in nodule ID %s for reader %s.", $noduleid, $servicingRadiologistID ),
                        accum => 1,
                        code => -1
                        );
                }
            }  # end of else for being in a nodule that should NOT have a chars section 
            if ( $xmlcxrreq and ( $sizeclass eq 'large' ) ) {
                $ubRNindex->print($cxrreqxml_fh);
            }
        }  # end of the foreach over @ubRNlist
        
        # Parse the <nonNodule> section:
        # Non-nodules will be matched in a limited way.  Plus we 
        # keep non-nodule info because it gets stored as a part of marking history.
        print "  number of non-nodule sections: ", $rSindex->children_count('nonNodule'), "\n" if $verbose >= 2;
        my @nNlist = $rSindex->descendants('nonNodule');
        foreach my $nNindex (@nNlist) {
            $foundnonn++;  # bump the counter
            print "    in non-nodules section ", $nNindex->pos('nonNodule'), "...\n" if $verbose >= 3;
#@@@ Code location: NonNodIdProc1
            # Get the non-nodule ID: Keep track of whether it's been duplicated and repair it if needed; details in sub rename_nn_id.
            my ($nonnodID, $nonnodIDrenamed, $renamestr);
            $nonnodID = $nNindex->first_child('nonNoduleID')->text;
            $seen_nnid{$servicingRadiologistIndex}{$nonnodID}++;
            print "+++ Dump of the \%reader_info hash ...\n", Dumper(%reader_info), "\n" if ( 0 );  # testing
            $nonnodIDrenamed = rename_nn_id($nonnodID,$reader_info{$servicingRadiologistIndex}{'site'});
            if ( $nonnodID eq $nonnodIDrenamed ) {
                $renamestr = '';
            }
            else {
                $renamestr = sprintf ( '(renamed to %s)', $nonnodIDrenamed );
            }
            print "      non-nodule ID: $nonnodID $renamestr \n" if $verbose >= 3;
            $nonnodID = $nonnodIDrenamed;  # preserve the modification for later use
            # This apparently caused a problem later: attempt to use a string as a hash reference.  (But this hash really isn't used for much...)
            #$nnninfo{$servicingRadiologistIndex}{$nonnodID} = 'non-nodule';
            $nnninfo{$servicingRadiologistIndex}{$nonnodID}{'sizeclass'} = 'non-nodule';  # not really a "sizeclass" but is consistent with what we do for small & large nods...
            # Initialize an entry in the hash to 'yes' for each non-nodule we find; will adjust later (set to 'no') as needed.
            # (This hash is only populated if matching XML file creation is enabled.)
            $listnonnodseparately{$servicingRadiologistIndex}{$nonnodID} = 'yes';
            my $zcoord = $nNindex->first_child('imageZposition')->text;  # in mm.
            $zcoord =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
            print "      image Z position: $zcoord mm. \n" if $verbose >= 3;
            @zcoordsallnonnods = ( @zcoordsallnonnods, $zcoord );  # accumulate all non-nodule's slices z coords
            # adjust the bounding box z size (in mm.) for non-nodules:
            if ( $zcoord < $minzc ) { $minzc = $zcoord };
            if ( $zcoord > $maxzc ) { $maxzc = $zcoord };
            my $SOPinstUID = $nNindex->first_child('imageSOP_UID')->text;
            $SOPinstUID =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
            print "      image SOP instance UID: $SOPinstUID \n" if $verbose >= 3;
            $z2siu{ round ( $zcoord, NUMDIGRND ) } = $SOPinstUID;  # store this info for later use
            my @locuslist = $nNindex->descendants('locus');
            foreach my $locusindex (@locuslist) {
                my $xcoord = $locusindex->first_child('xCoord')->text;
                my $ycoord = $locusindex->first_child('yCoord')->text;
                print "      point location: (", $xcoord, ", ", $ycoord, ") \n" if $verbose >= 4;
                # adjust the bounding box in x and y based on non-nodules as well:
                if ( $xcoord < $minx ) { print "BBOX: minx was $minx -- now $xcoord \n" if (grep {/^bbox$/} @testlist); $minx = $xcoord };
                if ( $xcoord > $maxx ) { print "BBOX: maxx was $maxx -- now $xcoord \n" if (grep {/^bbox$/} @testlist); $maxx = $xcoord };
                if ( $ycoord < $miny ) { print "BBOX: miny was $miny -- now $ycoord \n" if (grep {/^bbox$/} @testlist); $miny = $ycoord };
                if ( $ycoord > $maxy ) { print "BBOX: maxy was $maxy -- now $ycoord \n" if (grep {/^bbox$/} @testlist); $maxy = $ycoord };
            }  # end of the foreach loop over @locuslist
        }  # end of the foreach loop over @nNlist
        
        # close-out this reader's section
        if ( $xmlcxrreq ) {
            print $cxrreqxml_fh "\n</CTreadingSession>\n";  # we need the leading \n b/c Twig doesn't include one at the end of <unblindedReadNodule>
        }
        
        $servicingRadiologistIndex ++;  # get ready for the next reader
        
    }  # end of the foreach loop over @rSlist
    
    $twig->purge;  # free the memory
    
#@@@ Code location: RptDupNnIds
    # Process %seen_nnid for duplicates:
    for my $r ( keys %seen_nnid ) {
        for my $n ( keys %{$seen_nnid{$r}} ) {
            if ( $seen_nnid{$r}{$n} > 1 ) {
                # Accumulate the message; will report it after we exit from this sub
                push @dupnnid_msg, sprintf "Non-nodule ID $n appears $seen_nnid{$r}{$n} times in the file from $reader_info{$r}{'site'} ($r).";
            }
        }
    } 
    
    # A final adjustment of this flag...
    $troubleWithInferringSpacing = 1 if $overallspacing < 0.0;
    
    print "dump of the \%nnninfo hash...\n", Dumper(%nnninfo), "\n" if $verbose >= 5;
    
    # Close out this history section for this reader:
    accum_xml_lines ( 'history', \%xml_lines, $Site_Max::TAB[1] . "</MarkingHistory>" ) if $xmlhistory;
    
}  # end of sub rSpass1


sub intermediate_calcs {
    
    print "\n\n=================== Processing based on pass1 information ====================\n\n" if $verbose >= 1;
    
    # We do the following in this sub...
    #  * Show some pixel & voxel dimensions.
    #  * Show the virtual sphere voxels.
    #  * Construct a list of all Z coords in the series.
    #  * Bounding box & offsets.
    
    # local variables...
    my (@keys, @values);
    my $index;
    
    print "Pixel dimension for this series: $pixeldim mm. \n" if $verbose >= 3;
    
    print "Slice spacing that we will use for this run: $slicespacing mm. \n" if $verbose >= 3;
    
    # For use later in comparing distances and separations:
    $voxeldim = sqrt ( 2*$pixeldim*$pixeldim + $slicespacing*$slicespacing );
    printf "Typical voxel dimension for distance comparisons: %.3f mm. \n", $voxeldim if $verbose >= 3;
    
    # Compute a typical virtual sphere that would be constructed for this particular dataset.
    # (We're not going to do anything with the sphere -- just show its extents for informational purposes.)
    # The sub construct_sphere_list returns
    # the maximum deltas from the center of the sphere (similar to radii in each coord direction).
    # for use in bounding box construction; we will use them as "borders".
    # That is, especially in the z direction, we need to
    # allow room for virtual spheres to be constructed without array out-of-bounds indexing problems
    # for the case of a small nodule at the edge of the data.
    my ($xborder, $yborder, $zborder) = construct_sphere_list();  # this returns pixel/slice counts -- not coords
    print "Extent of the virtual spheres to be constructed around small nodule marks: x = +/-$xborder pixels, y = +/-$yborder pixels, z = +/-$zborder slices \n\n" if $verbose >= 3;
    
    # We can't do anything else here if there are no markings
    if ( $nomarkings ) {
        print "Exiting this section early because there are no markings.\n";
        return;
    }
    
    # Based on the slice spacing and the z coords in the XML, construct a list of ALL z coords in the series...
    # Begin by concatenating nodule and non-nod z coords and sort them numerically (small to large)
    @zcoordsallnnn = sort {$a <=> $b} ( @zcoordsallnods, @zcoordsallnonnods );
    # Add slice coords at each end to give us extra room to construct spheres in the z direction:
    my ($zcan_min,$zcan_max) = ($zcoordsallnnn[0],$zcoordsallnnn[-1]);  # min and max are at beginning & end, respectively
    # print "$zcan_min    $zcan_max    $slicespacing \n";  # testing
    foreach ( 1 .. $zborder ) {
        push @zcoordsallnnn, ( $zcan_min - $_ * $slicespacing);
        push @zcoordsallnnn, ( $zcan_max + $_ * $slicespacing);
    }
    # print Dumper(@zcoordsallnnn);  # testing
    my ($allz_ref, $zcoordsallnnn_ref, $zmatch_ref);  # references to the arrays
    ($zcoordsallnnn_ref,$allz_ref,$zmatch_ref) = gen_slices(@zcoordsallnnn);  # we use references to keep the arrays separate upon return from the sub
    @allz          = @$allz_ref;           # dereference
    @zcoordsallnnn = @$zcoordsallnnn_ref;  # the
    @zmatch        = @$zmatch_ref;         # arrays
    if ( $verbose >= 4 ) {
        print "Contents of the \@allz array (interpolated, contiguous Z coords in mm.)...\n";
        foreach ( 0 .. scalar(@allz)-1 ) {
            print "  $_:  $allz[$_] \n";
        }
        print "\n";
    }
    print "indices (\"slice numbers\") where matches were found: @zmatch \n" if $verbose >= 4;
    print "Z coordinates for ", scalar(@allz), " contiguous slices have been generated based on ", scalar(@zcoordsallnnn), " slices that contain markings.\n" if $verbose >= 3;
    
    # Now we can do the bounding box...
    printf "\nBounding box (before adjustment) (units: pixels)   x: %d to %d    y: %d to %d    (z is handled differently) \n", 
         $minx, $maxx, $miny, $maxy if $verbose >= 3;
    $minx = $minx - $xborder;
    if ( $minx < 0 ) {
        $minx = 0;
        #""" User message doc: 4101: Attempt to adjust bounding box too far.  Minimum x has been constrained.
        msg_mgr (
            severity => 'WARNING',
            msgid => 4101,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => "Attempt to adjust bounding box too far.  Minimum x has been constrained to $minx.",
            accum => 1,
            verbose => 2,
            code => -1
        );
    }
    $maxx = $maxx + $xborder;
    if ( $maxx > (CTIMAGESIZE-1) ) {
        $maxx = CTIMAGESIZE-1;
        #""" User message doc: 4102: Attempt to adjust bounding box too far.  Maximum x has been constrained.
        msg_mgr (
            severity => 'WARNING',
            msgid => 4102,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => "Attempt to adjust bounding box too far.  Maximum x has been constrained to $maxx.",
            accum => 1,
            verbose => 2,
            code => -1
        );
    }
    $miny = $miny - $yborder;
    if ( $miny < 0 ) {
        $miny = 0;
        #""" User message doc: 4103: Attempt to adjust bounding box too far.  Minimum y has been constrained.
        msg_mgr (
            severity => 'WARNING',
            msgid => 4103,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => "Attempt to adjust bounding box too far.  Minimum y has been constrained to $miny.",
            accum => 1,
            verbose => 2,
            code => -1
        );
    }
    $maxy = $maxy + $yborder;
    if ( $maxy > (CTIMAGESIZE-1) ) {
        $maxy = CTIMAGESIZE-1;
        #""" User message doc: 4104: Attempt to adjust bounding box too far.  Maximum y has been constrained.
        msg_mgr (
            severity => 'WARNING',
            msgid => 4104,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => "Attempt to adjust bounding box too far.  Maximum y has been constrained to $maxy.",
            accum => 1,
            verbose => 2,
            code => -1
        );
    }
    $minz = 0;
    $maxz = scalar(@allz) - 1;
    printf "Bounding box (adjusted outward) (units: pixels)   x: %d to %d    y: %d to %d    z: %d to %d \n", 
        $minx, $maxx, $miny, $maxy, $minz, $maxz if $verbose >= 3;
    
    # Apply the following offsets when indexing into the contours hash (whose effective size is defined by the bounding box):
    ( $offsetx, $offsety, $offsetz ) = ( $minx, $miny, $minz );  # note that $offsetz = 0 since $minz = 0 -- therefore, $offsetz does not need to be used
    # For example, an edgemap coord pair from the XML file of (184,123) would
    # map to (184-$offsetx,123-$offsety) in %contours (the "bounding box" array).
    ###( $offsetx, $offsety, $offsetz ) = ( 0, 0, 0 );  # for testing
    print "Offsets for use with the \%contours hash: ($offsetx,$offsety,$offsetz) \n" if $verbose >= 3;
    
    return;
    
}  # end of routine intermediate_calcs()


sub rSpass2 {
    
    # "readingSession pass 2"
    # Travese the twig (again) and apply certain info that we gathered in pass1:
    #   Populate the contours hash with edgemaps from small and large nodules
    #   Fill the outlines of large nodules
    #   Construct spheres around small nodules
    #   Deal with non-nodules
    
    # In this routine, we will generally print only on a high value of $verbose (usually 7) 
    # because we've seen all this info on pass 1 (except
    # for call to construct_sphere which contains some prints at a lower level).
    
    my ( $twig, $readingSession ) = @_;
    my $num;
    my $posn;
    
    # Note: The entire $readingSession element is bracketed by <LidcReadMessage>...</LidcReadMessage>
    
    print "\n" if $verbose >= 7;
    my @rSlist = $readingSession->children('readingSession');
    
    foreach my $rSindex (@rSlist) {
        
        # Index through the reading sessions...
        print "\nReading session number ", $rSindex->pos('readingSession'), "...\n" if $verbose >= 7;
        my $servicingRadiologistID = modify_reader_id ( $rSindex->first_child('servicingRadiologistID')->text );  # get and optionally modify the ID
        print "  servicing radiologist ID: ", $servicingRadiologistID, " (reader index ",$servicingRadiologistIndex, ")\n" if $verbose >= 7;
        print "  number of nodule sections: ", $rSindex->children_count($readtype_tag), "\n" if $verbose >= 2;
        my @ubRNlist = $rSindex->descendants($readtype_tag);
        foreach my $ubRNindex (@ubRNlist) {
            
            # Index through the nodule sections...
            $sizeclass = "large";
            print "    in nodule section ", $ubRNindex->pos($readtype_tag), "...\n" if $verbose >= 3;
            my $noduleid = $ubRNindex->first_child('noduleID')->text;
            print "      nodule ID: $noduleid \n" if $verbose >= 3;
            print "      number of ROIs: ", $ubRNindex->children_count('roi'), "\n" if $verbose >= 6;
            my @roilist = $ubRNindex->descendants('roi');
            
            foreach my $roiindex (@roilist) {
                
                # Index through the ROIs...
                print "      in ROI ", $roiindex->pos('roi'), "...\n" if $verbose >= 7;
                my ($roitype,$layer);
#@@@ Code location: InExVal2
                if ( $roiindex->first_child('inclusion')->text eq 'TRUE' ) { 
                    $roitype = 'inclusion'; 
                    $layer = 'INCL';
                }
                elsif ( $roiindex->first_child('inclusion')->text eq 'FALSE' ) { 
                    $roitype = 'exclusion'; 
                    $layer = 'EXCL';
                }
                else { 
                    #""" User message doc: 6403: Could not determine inclusion/exclusion status (in pass 2).
                    msg_mgr (
                        severity => 'FATAL',
                        msgid => 6403,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__ - 6,
                        text => 'Could not determine inclusion/exclusion status.',
                        accum => 1,
                        verbose => 1,
                        code => $Site_Max::RETURN_CODE{validationerror}
                    );
                }
                print "        ROI type: $roitype \n" if $verbose >= 7;
                my $zcoord = $roiindex->first_child('imageZposition')->text;
                $zcoord =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
                print "        image Z position: $zcoord mm. \n" if $verbose >= 7;
                my $SOPinstUID = $roiindex->first_child('imageSOP_UID')->text;
                $SOPinstUID =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
                print "        image SOP instance UID: $SOPinstUID \n" if $verbose >= 7;
                print "        number of edge maps: ", $roiindex->children_count('edgeMap'), "\n" if $verbose >= 7;
                # get a z index...
                my $zidx = get_index($zcoord, @allz);
                if ( $zidx == -1 ) {
                    #""" User message doc: 6501: Couldn't get a Z index corresponding to a Z coordinate in a nodule marking.
                    msg_mgr (
                        severity => 'FATAL',
                        msgid => 6501,
                        appname => 'MAX',
                        subname => (caller(0))[3],
                        line => __LINE__ - 6,
                        text => my $text = ( sprintf( "Couldn't get a Z index at Z coordinate %.3f mm.", $zcoord) ),
                        accum => 1,
                        verbose => 1,
                        code => $Site_Max::RETURN_CODE{othermatchingerror}
                    );
                }
                if ( $ubRNindex->children_count('roi') == 1 && $roiindex->children_count('edgeMap') == 1 ) { 
                    # one edgeMap point & one ROI mean this edge map is the centroid of a small nodule:
                    $sizeclass = "small"; 
                }
                my @eMlist = $roiindex->descendants('edgeMap');
                @xdata = (); @ydata = ();  # for plotting
                @poly = ();  # for filling
                
                foreach my $eMindex (@eMlist) {
                    
                    # Index through the edge maps (x,y pairs)...
                    # (Note that this loop picks-up edge coords for both large and small nodules.
                    # They are processed a bit differently, however.)
                    # Get the x,y pair from the XML -- these are "raw" indices -- will offset to the bounding box later:
                    my $xcoord = $eMindex->first_child('xCoord')->text;
                    my $ycoord = $eMindex->first_child('yCoord')->text;
                    # Accumulate the points for plotting:
                    @xdata = (@xdata,$xcoord);
                    @ydata = (@ydata,$ycoord);
                    # Accumulate the points in an array as point pairs for filling:
                    @poly = (@poly,[$xcoord,$ycoord]);
                    if ( $verbose >= 7 ) { 
                        print "          point location in edge map ",
                          $eMindex->pos('edgeMap'), " : (", $xcoord, ", ", $ycoord, ") \n"  # terminate with \r or \n
                    }
                    if ( $verbose >= 7 ) {
                        print "            >>> found ", $noduleid, " at: ", 
                            $servicingRadiologistIndex, " ", $xcoord-$offsetx, " ", $ycoord-$offsety, " ", $zidx, "\n";
                    }
                    # (Although at this point, we have the outline point pairs for this large nodule,
                    # we won't store them yet since we want to store the *filled* outlines in the %contours hash; see below.)
                    
                    if ( $sizeclass eq "small" ) {
                        # We only have a single point for "small" nodules.
                        # Around this single point, a sphere is constructed to give it some size for matching....
                        print "CONSPH: construct a sphere at $xcoord $ycoord (pre-offset indices) \n" if (grep {/^consph$/} @testlist);
                        # This adds voxels to the SMLN layer of %contours...
                        construct_sphere($servicingRadiologistIndex,$xcoord-$offsetx,$ycoord-$offsety,$zidx,'SMLN',$noduleid);
                        # ...and as long as we're here, we'll fill-in some centroid info for these small nodules even though
                        # we make most of the entries into %centroids from the centroid_calcs sub which is called right before matching...
                        $centroids{$servicingRadiologistIndex}{$noduleid}{"centx"} = $xcoord;  # formerly included: -$offsetx;
                        $centroids{$servicingRadiologistIndex}{$noduleid}{"centy"} = $ycoord;  # ... -$offsety;
                        $centroids{$servicingRadiologistIndex}{$noduleid}{"centz"} = $zidx;  # was $zcoord-$offsetz;  # in mm.
                        $centroids{$servicingRadiologistIndex}{$noduleid}{"sumx"}  = $xcoord;  # ... -$offsetx;
                        $centroids{$servicingRadiologistIndex}{$noduleid}{"sumy"}  = $ycoord;  # ... -$offsety;
                        $centroids{$servicingRadiologistIndex}{$noduleid}{"sumz"}  = $zidx;  # was $zcoord-$offsetz;  # in mm.
                        $centroids{$servicingRadiologistIndex}{$noduleid}{"count"} = 1;
                    }
                    
                }   # end of the foreach over @eMlist
                
                print "          the coordinates from all edgemaps have been parsed                  \n" if $verbose >= 6;
                
#@@@ Code location: PolyFill                
                # This section of code is designed based on a particular decision made by the Implementation Group: 
                # Contour lines drawn on images for both inclusions and exclusions must not obscure *nodule* tissue.  In 
                # practice, this means that contours are drawn (1) just outside nodule tissue to define an inclusion and 
                # (2) just inside nodule tissue when defining an exclusion.
                # Create a mask from the polygon.  Inclusions and exclusions are handled a bit differently in keeping with
                # the above description...
                @filledpoly = fill_poly(@poly);  # Start by filling both of them with an algorithm
                                                 #   that INCLUDES the outer boundary.
                if ( $roitype eq "inclusion" ) {
                    # But, the drawn boundary of an inclusion is NOT to be included in the mask...
                    @finalpoly = remove_poly();  # (this fct gets its args @filledpoly & @poly as global arrays)
                }
                else {
                    # For an exclusion:  Since this filled region will be excluded, the drawn boundary should be 
                    # left alone and NOT be removed since it is just inside the nodule tissue.  Exclusions
                    # will effectively be removed by handling exclusions differently from inclusions; see sub
                    # centroid_calcs and how it processes the "layer" code below (the 5th "dimension" of %contours).
                    # When this is done, the drawn boundary of an exclusion will NOT be included in the mask.
                    @finalpoly = @filledpoly;
                }
                
                if ( $qa_conn && $sizeclass eq 'large' && $roitype eq 'inclusion' ) {
                    print "+++ entering sub check_region_connectivity +++\n" if (0);  # testing
                    my $numreg = check_region_connectivity ( @finalpoly );
                    print "+++ returned from sub check_region_connectivity +++\n" if (1);  # testing
                    if ( $numreg == 0 ) {
                        #""" User message doc: 4406: The contour drawn around a nodule encloses no pixels.
                        msg_mgr (
                            severity => 'WARNING',
                            msgid => 4406,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 7,
                            text => my $text = ( sprintf("The contour drawn around nodule %s (%s) at z = %.3f mm. encloses no pixels.", $noduleid, $servicingRadiologistID, $zcoord ) ),
                            accum => 1,
                            code => -1
                        );
                    }
                    if ( $numreg > 1 ) {
                        #""" User message doc: 4407: The contour drawn around a nodule resulted multiple separate regions.
                        msg_mgr (
                            severity => 'WARNING',
                            msgid => 4407,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 7,
                            text => my $text = ( sprintf("The contour drawn around nodule %s (%s) at z = %.3f mm. resulted in %d separate regions.", $noduleid, $servicingRadiologistID, $zcoord, $numreg) ),
                            accum => 1,
                            code => -1
                        );
                    }
                }  # end of if that checks $qa_conn
                
                # Copy the filled poly into %contours...
                while (@finalpoly) {
                    # Get a pair of indices:
                    my ($xcoord,$ycoord) = @{shift(@finalpoly)};
                    # At this point, $layer indicates inclusion or exclusion for this large nodule.
                    print "indexing thru \@finalpoly: ($xcoord,$ycoord,$zidx): $layer and $noduleid \n" if $verbose >= 8;
                    # Offsets are included as the point is checked and loaded into %contours:
                    # First check to see if this reader has already made a large nodule mark at this location already:
                    if ( ( $layer eq 'INCL' ) && ( defined ( $contours{$servicingRadiologistIndex}{$xcoord-$offsetx}{$ycoord-$offsety}{$zidx}{$layer} ) ) ) {
                        print "+++ !!! intra-reader large nodule overlap at $xcoord, $ycoord !!! +++ \n" if ( 0 );  # testing
                        #""" User message doc: 5504: Overlap has been detected between two large nodules for this reader.
                        msg_mgr (
                            severity => 'ERROR',
                            msgid => 5504,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 8,
                            text => my $text = ( sprintf( "Overlap has been detected between two large nodules (IDs = %s and %s) at %d %d %d (%.3f mm) for reader %s (%d).",
                                                 $noduleid, $contours{$servicingRadiologistIndex}{$xcoord-$offsetx}{$ycoord-$offsety}{$zidx}{$layer},
                                                 $xcoord, $ycoord, $zidx, $allz[$zidx], $servicingRadiologist[$servicingRadiologistIndex], $servicingRadiologistIndex) ),
                            accum => 1,
                            code => -1
                        );
                    }
                    # Regardless of the above error, store the new nodule ID at this location.
                    $contours{$servicingRadiologistIndex}{$xcoord-$offsetx}{$ycoord-$offsety}{$zidx}{$layer} = $noduleid;
                    print "+++ writing to \%contours in rSpass2 at filled poly with z = $zidx \n" if ( 0 );  #testing
                }  # end of while thru @finalpoly
                
                pointplot(@filledpoly) if ( $plot && @xdata > 1 );
                
            }  # end of the foreach over @roilist
            
        }  # end of the foreach over @ubRNlist
        
        # This block is for non-nodules: Non-nodules will be matched in a limited way.
        print "  number of non-nodule sections: ", $rSindex->children_count('nonNodule'), "\n" if $verbose >= 2;
        my @nNlist = $rSindex->descendants('nonNodule');
        foreach my $nNindex (@nNlist) {
            print "    in non-nodules section ", $nNindex->pos('nonNodule'), "...\n" if $verbose >= 3;
            my $zcoord = $nNindex->first_child('imageZposition')->text;  # in mm.
            $zcoord =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
            print "      image Z position: $zcoord mm. \n" if $verbose >= 7;
            my $SOPinstUID = $nNindex->first_child('imageSOP_UID')->text;
            $SOPinstUID =~ s/^\s+|\s+$//g;  # remove leading & trailing spaces -- from PerlFAQ 4.32
            print "      image SOP instance UID: $SOPinstUID \n" if $verbose >= 7;
#@@@ Code location: NonNodIdProc2
            # Get and repair the non-nodule ID if needed; details in sub rename_nn_id.
            my ($nonnodID, $nonnodIDrenamed, $renamestr);
            $nonnodID = $nNindex->first_child('nonNoduleID')->text;
            $nonnodIDrenamed = rename_nn_id($nonnodID,$reader_info{$servicingRadiologistIndex}{'site'});
            if ( $nonnodID eq $nonnodIDrenamed ) {
                $renamestr = '';
            }
            else {
                $renamestr = sprintf ( '(renamed to %s)', $nonnodIDrenamed );
            }
            print "      non-nodule ID: $nonnodID $renamestr \n" if $verbose >= 3;
            $nonnodID = $nonnodIDrenamed;  # preserve the modification for later use
            my @locuslist = $nNindex->descendants('locus');
            foreach my $locusindex (@locuslist) {
            my $xcoord = $locusindex->first_child('xCoord')->text;
            my $ycoord = $locusindex->first_child('yCoord')->text;
            print "      point location: (", $xcoord, ", ", $ycoord, ") \n" if $verbose >= 4;
            # get a z index for use below...
            my $zidx = get_index($zcoord, @allz);
            if ( $zidx == -1 ) {
                #""" User message doc: 6502: Couldn't get a Z index corresponding to a Z coordinate for a non-nodule.
                msg_mgr (
                    severity => 'FATAL',
                    msgid => 6502,
                    appname => 'MAX',
                    subname => (caller(0))[3],
                    line => __LINE__ - 6,
                    text => my $text = ( sprintf( "Couldn't get a Z index at Z coordinate %.3f mm.", $zcoord) ),
                    accum => 1,
                    verbose => 1,
                    code => $Site_Max::RETURN_CODE{othermatchingerror}
                );
            }
            # Make an entry in %contours (with offsets applied)...
            #printf "! indices into \%contours: %d %d %d \n", $xcoord-$offsetx, $ycoord-$offsety, $zidx;  # testing
            $contours{$servicingRadiologistIndex}{$xcoord-$offsetx}{$ycoord-$offsety}{$zidx}{NONN} = $nonnodID;
            print "+++ writing to \%contours in rSpass2 at non-nod with z = $zidx \n" if ( 0 );  # testing
            # Store some info about this non-nodule in a hash...
            $nonnodinfo{$servicingRadiologistIndex}{$nonnodID} = [ $xcoord, $ycoord, $zidx ];
            }  # end of the foreach loop over @locuslist
        }  # end of the foreach loop over @nNlist
        
        $servicingRadiologistIndex ++;  # get ready for the next reader
        
    }  # end of the foreach loop over @rSlist
    
    $twig->purge;  # free the memory
    
}  # end of sub rSpass2


sub centroid_calcs {
    
    print "\n\n========== Process inclusions/exclusions and calculate centroids =============\n\n" if $verbose >= 1;
    
    # The main job here is to fill the (global) %centroids hash.  Entries for small nodules have
    # already been made in rSpass2 because this was an easy place to make these entries.
    # We also repair the inclusions layer for the presence of exclusions and do some related checking
    # since this needs to be done as a part of calc'ing centroids.
    
    my @rdndlist = ();  # reader/nodule list for use in this sub
    my %seen;  # use this (see below) to keep dupes out of @rdndlist and to control how %centroids is populated
    my %alreadyShownExOutInMsg = ();  # Use this to keep track of "exclusion outside of inclusion" messages so that they aren't repetitious
    # Loop thru %contours and extract the nodule info; accumulate certain measures in %centroids...
    for $rindex ( keys %contours ) {
        for $xindex ( keys %{$contours{$rindex}} ) {
            for $yindex ( keys %{$contours{$rindex}{$xindex}} ) {
                for $zindex ( keys %{$contours{$rindex}{$xindex}{$yindex}} ) {
                    # These are for use below: Adding the offset back in ($xno -> "x no offset") takes us back to the
                    #   image pixel space as it appears in the XML, so it's easier to interpret the coords in messages below.
                    my $xno = $xindex + $offsetx;
                    my $yno = $yindex + $offsety;
                    # Pickup the nodule IDs at this location for this reader...
                    my ($inodnum, $xnodnum);
                    if ( exists($contours{$rindex}{$xindex}{$yindex}{$zindex}{INCL}) ) { $inodnum = $contours{$rindex}{$xindex}{$yindex}{$zindex}{INCL} };
                    if ( exists($contours{$rindex}{$xindex}{$yindex}{$zindex}{EXCL}) ) { $xnodnum = $contours{$rindex}{$xindex}{$yindex}{$zindex}{EXCL} };
                    # We will perform 3 independent inclusion/exclusion actions based on these IDs.
                    # (By "independent", we mean that each is begun by a single "if" rather than 
                    # being a nested/cascaded "if-elsif-else" structure.)
#@@@ Code location: ExNoIn
                    # 1: Are we in a improperly defined exclusion -- an exclusion pixel without a corresponding inclusion pixel?
                    if ( !defined($inodnum) && defined($xnodnum) ) {
                        #""" User message doc: 4505: A pixel in an exclusion was found that appears to be outside its corresponding inclusion.
                        msg_mgr (
                            severity => 'WARNING',
                            msgid => 4505,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => my $text = ( sprintf( "For reader %s in nodule ID %s: a pixel in an exclusion was found that appears to be outside its corresponding inclusion at (reader x,y,z layer) = (%d %d,%d,%d [offsets included] EXCL, [z coord = %.3f mm.])", $servicingRadiologist[$rindex], $xnodnum, $rindex, $xno, $yno, $zindex, $allz[$zindex] ) ),
                            accum => 1,
                            code => -1
                        ) unless ( exists $alreadyShownExOutInMsg{ ($rindex, $xnodnum, $zindex) } && 0 );  # 0 => show all; 1=> cull the messages
                        $alreadyShownExOutInMsg{ ($rindex, $xnodnum, $zindex) } = 1;
                    }  # end of #1
                    # 2: Are we in a properly defined exclusion?  That is, it has a corresponding inclusion with it
                    # as evidenced by the presence of a defined entry in both the INCL and EXCL layers for this reader/location.
                    if ( defined($inodnum) && defined($xnodnum) ) {
                        # Yes, since something is defined at exactly the same reader and location in both INCL & EXCL.
                        # So, set the inclusion part to undefined since the purpose of an exclusion is to "erase" part
                        # of an inclusion.  But don't do anything to the exclusion entry.
                        # Further, note that exclusions do not enter into the centroid calcs (see the next test).
                        delete $contours{$rindex}{$xindex}{$yindex}{$zindex}{INCL};
                        undef $inodnum;
                        print "--- performing inclusion/exclusion adjustment at (x,y) = ($xno,$yno) at zindex = $zindex ($allz[$zindex] mm.) for reader $rindex (ID: $servicingRadiologist[$rindex]) \n" if $verbose >= 6;
                    }  # end of #2
                    # 3: Are we in an inclusion with no exclusion?
                    if ( defined($inodnum) && !defined($xnodnum) ) {
                        # Yes, so this voxel should be included in the centroid calcs:
                        printf " adding (x,y) = ($xno,$yno) at zindex = $zindex ($allz[$zindex] mm.) (reader: $rindex -- $servicingRadiologist[$rindex]) \n" if $verbose >= 6;
                        # Keep a list reader/nodule combos that we are processing, but don't allow any duplicates:
                        my $element = join(',', $rindex,$inodnum);
                        push ( @rdndlist, $element ) unless ($seen{$element}++);
                        # N.B.: We are adding-in the offsets when accumulating the the centroid sums (so don't do it again later!).
                        # Also use %seen to control how we populate %centroids:
                        if ($seen{$element} > 1) {  # continue accumulating the current coords since we have already initialized %centroids for this reader/nodule:
                            $centroids{$rindex}{$inodnum}{"sumx"} += $xno;
                            $centroids{$rindex}{$inodnum}{"sumy"} += $yno;
                            $centroids{$rindex}{$inodnum}{"sumz"} += $zindex;
                            $centroids{$rindex}{$inodnum}{"count"} ++;
                        }
                        else {  # first time for this reader/nodule combo, so initialize its storage locations:
                            $centroids{$rindex}{$inodnum}{"sumx"} = $xno;
                            $centroids{$rindex}{$inodnum}{"sumy"} = $yno;
                            $centroids{$rindex}{$inodnum}{"sumz"} = $zindex;
                            $centroids{$rindex}{$inodnum}{"count"} = 1;
                        }  # end of the "if" that keeps track of first time for a given reader/nodule combo
                    }  # end of #3
                    # 4: This isn't one of the 3 tests.  Instead, it's the condition where both $inodnum and $xnodnum
                    # are undefined, so we don't need to do anything at this reader/location.
                }  # loop over z
            }  # loop over y
        }  # loop over x
    }  # loop over reader
    
    if ( $verbose >= 5 ) {
        print "dump of the \%seen hash:\n",Dumper(\%seen);
        print "dump of the \%centroids hash:\n",Dumper(\%centroids);
        print "dump of the \@rdndlist array:\n",Dumper(\@rdndlist);
    }
    
    print "Centroid calculation results for all readers and nodules (for large nodules only): \n" if $verbose >= 3;
    print "  (units: x & y - pixels, z - slice index number and physical position, volume - voxels)\n" if $verbose >= 3;
    foreach (@rdndlist) {
        my ($rd,$nd) = split(/,/);
        my $count = $centroids{$rd}{$nd}{"count"};
        my $centx = $centroids{$rd}{$nd}{"sumx"}/$count; $centroids{$rd}{$nd}{"centx"} = $centx;
        my $centy = $centroids{$rd}{$nd}{"sumy"}/$count; $centroids{$rd}{$nd}{"centy"} = $centy;
        my $centz = $centroids{$rd}{$nd}{"sumz"}/$count; $centroids{$rd}{$nd}{"centz"} = $centz;
        print "  reader ", reader_id($rd), " and nodule $nd: \n" if $verbose >= 3;
        printf "    centroid location: x = %.2f  y = %.2f  z = %.2f (%.2f mm.) \n", $centx, $centy, $centz, $allz[int($centz+0.5)] if $verbose >= 3;
        printf "    volume = %d \n", $count if $verbose >= 3;
    }
    
    # Generate a status message for insertion into @main::msglog
    #""" User message doc: 3106: Centroids have been calculated.
    msg_mgr (
        severity => 'INFO',
        msgid => 3106,
        text => my $text = ( sprintf "Centroids have been calculated." ),
        accum => 1,
        screen => 0,  # doesn't need to be displayed on the screen
        code => -1
    ) unless ! $foundnodules;

    return;
    
}  # end of routine centroid_calcs()


sub check_smnon_dist {

    # "check small and non-nodule distance"
    # This sub can operate in one of two modes:
    #  * Checks for QA errors #2 & #3 (intra-reader mode)
    #  * Checks for matching between small and non-nodules (inter-reader mode) (not sure if
    #      we'll really use this mode)
    # In either case, it compares the distance between marks for all distinct combinations of 
    # small nodules and non-nodules with a threshold to assess whether they are the same object.
    # For some purposes, a distance threshold is better than simple voxel overlap since small 
    # nodule markings can be close together but not have any overlapping voxels depending on  
    # where the voxels of the virtual spheres are created which is influenced by rounding and
    # truncation.
    #
    # In this way, note that some of the checks done here are similar (but not identical) to 
    # checks done elsewhere:
    #         distance checks                                overlap checks
    #   -----------------------------     -----------------------------------------------------------
    #   sub check_smnon_dist              sub simple_matching           sub construct_spheres
    #   -----------------------------     ---------------------------   -----------------------------
    #   2 small nodules are close                                       2 constructed spheres overlap
    #     message ID 4509                                                 message ID 4504
    #   small nod & non-nod are close     small nod & non-nod overlap
    #     message ID 4510                   message ID 5502
    
    my %args = @_;
    my $doingQA       = $args{context} eq 'QA';
    my $doingmatching = $args{context} eq 'matching';
    my $processSMLN = $args{features} eq 'SMLN' || $args{features} eq 'both';
    my $processNONN = $args{features} eq 'NONN' || $args{features} eq 'both';
    #print "\$doingQA, \$doingmatching, \$processSMLN, \$processNONN: $doingQA, $doingmatching, $processSMLN, $processNONN \n";  # testing
    
    # Start by conditionally (depending on the 'features' key) merging the two hashes together 
    # since for our purposes here, small and non-nodules are treated alike:
    my %mergedinfo;
    my ( $r, $n );  # reader, nodule ID, type
    if ( $processSMLN ) {
        #print "+++ merging SMLN\n";
        for $r ( keys %smnodinfo ) {
            for $n ( keys %{$smnodinfo{$r}} ) {
                $mergedinfo{$r}{$n}{SMLN} = $smnodinfo{$r}{$n};
            }
        }
    }
    if ( $processNONN ) {
        #print "+++ merging NONN\n";
        for $r ( keys %nonnodinfo ) {
            for $n ( keys %{$nonnodinfo{$r}} ) {
                $mergedinfo{$r}{$n}{NONN} = $nonnodinfo{$r}{$n};
            }
        }
    }
    print "\nDump of \%mergedinfo (the merged hash of small and non-nodule info)\n", Dumper(%mergedinfo) if $verbose >= 5;
    
    # "Index" thru the merged hash and make all comparisons:
    my ( $r1, $n1, $t1, $r2, $n2, $t2 );  # reader, nodule ID, type
    my $foundone;  # a flag for use in conditionally printing a message at the end of these for loops
    my %alreadyShownProxMsg = ();  # Use this to keep track of proximity messages so that they aren't repetitious for symmetrical detected proximities.
    # Get the keys for one "side" of the comparison:
    for $r1 ( keys %mergedinfo ) {
        for $n1 ( keys %{$mergedinfo{$r1}} ) {
            for $t1 ( keys %{$mergedinfo{$r1}{$n1}} ) {
                # Get the keys for the other "side" of the comparison:
                for $r2 ( keys %mergedinfo ) {
                    for $n2 ( keys %{$mergedinfo{$r2}} ) {
                        for $t2 ( keys %{$mergedinfo{$r2}{$n2}} ) {
                            #print "--------\n"; print "same reader: $r1\n" if $r1 eq $r2; print "same id: $n1\n" if $n1 eq $n2; print "same type: $t1\n" if $t1 eq $t2;  # testing
                            # Do the comparison contingent on how ($r1,$n1,$t1) compares with ($r2,$n2,$t2)
                            my $criterion;
                            $criterion = ( $r1 ne $r2 || ( $n1 ne $n2 || $t1 ne $t2 ) ) if $doingmatching;
                            $criterion = ( $r1 eq $r2 && ( $n1 ne $n2 || $t1 ne $t2 ) ) if $doingQA;
                            if ( $criterion ) {
                                my $ref1 = $mergedinfo{$r1}{$n1}{$t1};
                                my $ref2 = $mergedinfo{$r2}{$n2}{$t2};
                                my $sep = dist ( @$ref1[0] * $pixeldim, @$ref1[1] * $pixeldim, @$ref1[2] * $slicespacing,
                                                 @$ref2[0] * $pixeldim, @$ref2[1] * $pixeldim, @$ref2[2] * $slicespacing );
                                # Setup some friendlier phrases for the messages:
                                my $t1phr = $t1 eq 'SMLN' ? 'small-nodule' : 'non-nodule';
                                my $t2phr = $t2 eq 'SMLN' ? 'small-nodule' : 'non-nodule';
                                my $rid1 = $reader_info{$r1}{'id'};
                                my $rid2 = $reader_info{$r2}{'id'};
#@@@ Code location: QaSmSmDist
                                # Separation checks between small nodules for QA purposes:
                                if ( $sep <= SMNONSEPTHR && ( $t1 eq 'SMLN' && $t2 eq 'SMLN' ) ) {
                                    if ( $doingQA ) {
                                        $foundone = 1;
                                        #""" User message doc: 4509: Two small nodules are closer together than the distance threshold for QA purposes.
                                        msg_mgr (
                                            severity => 'WARNING',
                                            msgid =>4509,
                                            appname => 'MAX',
                                            line => __LINE__ - 7,
                                            text => my $text = ( sprintf "(reader,ID,type) at (i,j,k,z): (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) and (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) are %.1f mm. apart (threshold = %.2f).", 
                                                                         $rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2], $allz[@$ref1[2]], $rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2], $allz[@$ref2[2]], $sep, SMNONSEPTHR ),
                                            accum => 1,
                                            screen => 1,
                                            verbose => 3,
                                            code => -1
                                        ) unless ( exists $alreadyShownProxMsg{($rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2])} );
                                        $alreadyShownProxMsg{($rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2])} = 1;
                                    }
                                    else {  # doing matching
                                        printf "  (reader,ID,type) at (i,j,k): (%s/%s,%s,%s) at (%s,%s,%s) and (%s/%s,%s,%s) at (%s,%s,%s) match since they are %.1f mm. apart (threshold = %.2f).",
                                               $rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2], $rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2], $sep, SMNONSEPTHR;
                                        print  "    >> But we're not storing this match at this time! \n";
                                    }
                                }
#@@@ Code location: QaSmNonDist
                                # Separation checks between small nodules and non-nodules for QA purposes:
                                if ( $sep <= SMNONSEPTHR && ( ( $t1 eq 'SMLN' && $t2 eq 'NONN' ) || ( $t1 eq 'NONN' && $t2 eq 'SMLN' ) ) ) {
                                    if ( $doingQA ) {
                                        $foundone = 1;
                                        #""" User message doc: 4510: A small nodule and a non-nodule are closer together than the distance threshold for QA purposes.
                                        msg_mgr (
                                            severity => 'WARNING',
                                            msgid =>4510,
                                            appname => 'MAX',
                                            line => __LINE__ - 7,
                                            text => my $text = ( sprintf "(reader,ID,type) at (i,j,k,z): (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) and (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) are %.1f mm. apart (threshold = %.2f).",
                                                                         $rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2], $allz[@$ref1[2]], $rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2], $allz[@$ref2[2]], $sep, SMNONSEPTHR ),
                                            accum => 1,
                                            screen => 1,
                                            verbose => 3,
                                            code => -1
                                        ) unless ( exists $alreadyShownProxMsg{($rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2])} );
                                        $alreadyShownProxMsg{($rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2])} = 1;
                                    }
                                    else {  # doing matching
                                        printf "  (reader,ID,type) at (i,j,k): (%s/%s,%s,%s) at (%s,%s,%s) and (%s/%s,%s,%s) at (%s,%s,%s) match since they are %.1f mm. apart (threshold = %.2f).",
                                               $rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2], $rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2], $sep, SMNONSEPTHR;
                                        print  "    >> But we're not storing this match at this time! \n";
                                    }
                                }
#@@@ Code location: QaNonNonDist
                                # Separation checks between non-nodules for QA purposes:
                                # >>> This may not be done the right way.  Depends on whether we ever use the "matching" "else" 
                                # >>> or the "additional separation" "elsif" sections below.
                                if ( $qa_nonnodprox ) {
                                    if ( $sep <= SMNONSEPTHR && ( $t1 eq 'NONN' && $t2 eq 'NONN' ) ) {
                                        if ( $doingQA) {
                                            $foundone = 1;
                                            #""" User message doc: 4511: Two non-nodules are closer together than the distance threshold for QA purposes.
                                            msg_mgr (
                                                severity => 'WARNING',
                                                msgid =>4511,
                                                appname => 'MAX',
                                                line => __LINE__ - 7,
                                                text => my $text = ( sprintf "(reader,ID,type) at (i,j,k,z): (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) and (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) are %.1f mm. apart (threshold = %.2f).",
                                                                             $rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2], $allz[@$ref1[2]], $rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2], $allz[@$ref2[2]], $sep, SMNONSEPTHR ),
                                                accum => 1,
                                                screen => 1,
                                                verbose => 3,
                                                code => -1
                                            ) unless ( exists $alreadyShownProxMsg{($rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2])} );
                                            $alreadyShownProxMsg{($rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2])} = 1;
                                        }
                                        else {  # doing matching
                                            printf "  (reader,ID,type) at (i,j,k): (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) and (%s/%s,%s,%s) at (%s,%s,%s,%.3f mm.) match since they are %.1f mm. apart (threshold = %.2f).",
                                                   $rid1, $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2], $allz[@$ref1[2]], $rid2, $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2], $allz[@$ref2[2]], $sep, SMNONSEPTHR;
                                            print  "    >> But we're not storing this match at this time! \n";
                                        }
                                    }
                                    # This is an additional separation check for debugging purposes ($verbose >= 5): Open-up the separation wider (the factor of 3 is arbitrary) to show more info:
                                    elsif ( $sep <= ( 3 * SMNONSEPTHR ) && $verbose >= 5 ) {
                                        printf "Separation of marks (diagnostic info): (%s,%s,%s) at (%s,%s,%s) and (%s,%s,%s) at (%s,%s,%s) are %.1f mm. apart. \n",
                                                $r1, $n1, $t1phr, @$ref1[0], @$ref1[1], @$ref1[2], $r2, $n2, $t2phr, @$ref2[0], @$ref2[1], @$ref2[2], $sep;
                                    }  # end of the separation tests (test on $sep)
                                }  # end of if for checking the $qa_nonnodprox flag
                            }  # end of the ($r1,$n1,$t1) / ($r2,$n2,$t2) comparison (test on $criterion)
                        }  # end of the $t2 loop
                    }  # end of the $n2 loop
                }  # end of the $r2 loop
            }  # end of the $t1 loop
        }  # end of the $n1 loop
    }  # end of the $r1 loop
    print "  No errors of these types were found.\n" if ( ! $foundone && $doingQA && $verbose >= 2 );
}


sub simple_matching {
    
    print "\n\n================ Simple check for matching ===================\n\n" if $verbose >= 1;
    
    # Initial matching criterion: simple overlap only
    # (In the process of doing this, accumulate some "secondary measures" of
    #   matching that *may* be used later for "second order" decisions if needed.)
    
    # Define flags to signal the detection of non-nodule and nodule/nodule ambiguity.
    my ( $foundnonnodambig, $foundnodnodambig ) = ( 0, 0 );
    
    # Index thru the %contours1 hash and do basic overlap/matching...
    # (Recall that %contours1 holds the nodule ID at each 5-tuple of {x,y,z,reader,type}.)
    my @ambig_msgs;  # Accumulate ambiguity messages in this array and print them out when we're finished with this section;
                     # we don't do any "real" processing on this array.
    for $xindex ( keys %contours1 ) {
        for $yindex ( keys %{$contours1{$xindex}} ) {
            for $zindex ( keys %{$contours1{$xindex}{$yindex}} ) {
                # These are "no offset" indices as explained above:
                my $xno = $xindex + $offsetx;
                my $yno = $yindex + $offsety;
                
                # At each x,y,z location, pick-out data for all readers and load into the various
                # stack arrays which are initialized here.  The stacks are for large nodules (inclusions only), 
                # small nodules (including their surrounding spheres), non-nodules, respectively.
                my ( @stack, @stack_sml, @stack_non );
                for ( 0 .. ($numreaders-1 ) ) {
                    $stack[$_] = $stack_sml[$_] = $stack_non[$_] = $FILLER;
                }
                for $rindex ( keys %{$contours1{$xindex}{$yindex}{$zindex}} ) {
                    # Set some flags based on the layers dimension at this x,y,z,r:
                    my ($foundINCL, $foundEXCL, $foundSMLN, $foundNONN) = ( 0, 0, 0, 0 );
                    # Loop over the layers:
                    for ( keys %{$contours1{$xindex}{$yindex}{$zindex}{$rindex}} ) {
                        $foundINCL = 1 if $_ eq 'INCL';
                        $foundEXCL = 1 if $_ eq 'EXCL';
                        $foundSMLN = 1 if $_ eq 'SMLN';
                        $foundNONN = 1 if $_ eq 'NONN';
                    }
                    # For testing...
                    # print "+++ this is a(n) ";
                    # print "inclusion \n" if $foundINCL;
                    # print "small nodule \n" if $foundSMLN;
                    # print "non-nodule \n" if $foundNONN;
                    printf ("+++ Values of the layer flags (INCL EXCL SMLN NONN) = %d %d %d %d \n", $foundINCL, $foundEXCL, $foundSMLN, $foundNONN ) if $verbose >= 7;
                    print "  at x,y,z,rdr = $xindex,$yindex,$zindex,$rindex: \$foundINCL: " . $foundINCL . "   \$foundSMLN: " . $foundSMLN . "   \$foundNONN: " . $foundNONN . "\n" if $verbose >= 6;
                    # === Do a series of "same reader" overlap tests ===
#@@@ Code location: RdrSmOvLrg
                    # This test catches the error where a reader marks a small nodule whose sphere overlaps with a large nodule:
                    if ( $foundINCL && $foundSMLN ) {
                        #""" User message doc: 5501: Overlap has been detected between a small nodule and a large nodule for this reader.
                        msg_mgr (
                            severity => 'ERROR',
                            msgid => 5501,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => my $text = ( sprintf( "Overlap has been detected between a small nodule (ID = %s) and a large nodule (ID = %s) at %d %d %d (%.3f mm) for reader %d (%s).",
                                                          $contours1{$xindex}{$yindex}{$zindex}{$rindex}{SMLN}, $contours1{$xindex}{$yindex}{$zindex}{$rindex}{INCL}, 
                                                          $xno, $yno, $zindex, $allz[$zindex], $rindex, $servicingRadiologist[$rindex]) ),
                            accum => 1,
                            code => -1
                        );
                    }
#@@@ Code location: RdrSmOvNon
                    # This test catches the error where a reader marks a small nodule whose sphere overlaps with a non-nodule:
                    if ( $foundSMLN && $foundNONN ) {
                        #""" User message doc: 5502: Overlap has been detected between a small nodule and a non-nodule for this reader.
                        msg_mgr (
                            severity => 'ERROR',
                            msgid => 5502,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => my $text = ( sprintf( "Overlap has been detected between a small nodule (ID = %s) and a non-nodule (ID = %s) at %d %d %d (%.3f mm) for reader %d (%s).",
                                                          $contours1{$xindex}{$yindex}{$zindex}{$rindex}{SMLN}, $contours1{$xindex}{$yindex}{$zindex}{$rindex}{NONN}, 
                                                          $xno, $yno, $zindex, $allz[$zindex], $rindex, $servicingRadiologist[$rindex]) ),
                            accum => 1,
                            code => -1
                        );
                    }
#@@@ Code location: RdrNonOvLrg
                    # This test catches the error where a reader marks a non-nodule within a large nodule:
                    if ( $foundINCL && $foundNONN ) {
                        #""" User message doc: 5503: Overlap has been detected between a non-nodule and a large nodule for this reader.
                        msg_mgr (
                            severity => 'ERROR',
                            msgid => 5503,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => my $text = ( sprintf( "Overlap has been detected between a non-nodule (ID = %s) and a large nodule (ID = %s) at %d %d %d (%.3f mm) for reader %d (%s).",
                                                          $contours1{$xindex}{$yindex}{$zindex}{$rindex}{NONN}, $contours1{$xindex}{$yindex}{$zindex}{$rindex}{INCL}, 
                                                          $xno, $yno, $zindex, $allz[$zindex], $rindex, $servicingRadiologist[$rindex] ) ),
                            accum => 1,
                            code => -1
                        );
                    }
                    # Fill the stack arrays with the nodule IDs that are read from %contours1; they are indexed into by (0-based) reader number.
                    # The original stack: inclusions from large nodules...
                    if ( $foundINCL ) {
                        $stack[$rindex] = $contours1{$xindex}{$yindex}{$zindex}{$rindex}{INCL};
                    }
                    # The stack for small nodules (including their surrounding spheres)...
                    if ( $foundSMLN ) {
                        $stack_sml[$rindex] = $contours1{$xindex}{$yindex}{$zindex}{$rindex}{SMLN};
                    }
                    # The stack for non-nodules...
                    if ( $foundNONN ) {
                        $stack_non[$rindex] = $contours1{$xindex}{$yindex}{$zindex}{$rindex}{NONN};
                    }
                    
                }  # end of the "foreach $rindex" loop
                
#@@@ Code location: OvCombos
                # Now that the stack arrays are filled, check them in various combinations according to the established matching criteria.
                # These are checking for "between reader" overlap.
                # There is a block below for each criterion.
                
                # print "+++ | " . $stack[0] . " | " . $stack[1] .  " | " . $stack[2] .  " | " . $stack[3] .  " | " . "\n";  # testing
                
                # Check @stack for overlap between large nodules:
                #   Are there multiple elements having nodule IDs in @stack?  If so, we've found an overlap.
                if ( scalar ( grep { $_ ne $FILLER} @stack ) > 1 ) {
                    print "+++++++++++ at $xno $yno $zindex \@stack is @stack \n" if $verbose >= 6;
                    # Index into @stack over the appropriate reader pairs:
                    # For 4 readers, we compare readers 0 & 1, 0 & 2, 0 & 3, 1 & 2, 1 & 3, 2 & 3,
                    # but we don't need to compare 1 & 0, 2 & 0, etc.
                    foreach my $ir (0..$numreaders-2) {
                        foreach my $jr ($ir+1..$numreaders-1){
                            # N.B.: As a result of the above reader pairs, this loop will never be able to flag any
                            #       of a reader's markings as overlapping with another marking made by the same reader --
                            #       and we don't want to do this unless we can catch it as an error or warning.
                            #       That's why we added the check above between small and large for the same reader.
                            # Translate reader indices to reader IDs for reporting results:
                            #print "+++ \@stack values: " . $stack[$ir] . " and " . $stack[$jr] . "\n";  # testing
                            #print "+++ \@stack_sml values: " . $stack_sml[$ir] . " and " . $stack_sml[$jr] . "\n";  # testing
                            my $irid = $servicingRadiologist[$ir];
                            my $jrid = $servicingRadiologist[$jr];
                            print "+++++++++++++ compare reader $ir:$irid and $jr:$jrid for layer INCL \n" if $verbose >= 6;
                            if ( $stack[$ir] ne $FILLER && $stack[$jr] ne $FILLER ) {
                                # Store something (symmetrically in 2 cells) to flag simple overlap...
                                # We use a floating point number that will eventually be used to indicate the degree of overlap
                                # (range: >0.0 &  =<1.0) where an undefined value indicates no overlap and 1.0 is (for now)
                                # unqualified overlap.
                                $overlap{$ir}{$stack[$ir]}{$jr}{$stack[$jr]} = 1.0;
                                $overlap{$jr}{$stack[$jr]}{$ir}{$stack[$ir]} = 1.0;
                                print "  reader $ir:$irid/nodule $stack[$ir] overlaps reader $jr:$jrid/nodule $stack[$jr] in layer INCL \n" if $verbose >= 5;
                                $nnninfo{$ir}{$stack[$ir]}{"overlap"} = "yes";  
                                $nnninfo{$jr}{$stack[$jr]}{"overlap"} = "yes";
                            }  # end of if checking @stack for valid nodule data
                        }  # end of the $jr loop
                    }  # end of the $ir loop
                }  # end of the if for testing @stack if there multiple elements containing valid labels
                
                # Check for overlap between small nodules (very similar to checking large nodule data as above):
                #   Are there multiple elements having nodule IDs in @stack_sml?  If so, we've found an overlap.
                if ( scalar ( grep { $_ ne $FILLER} @stack_sml ) > 1 ) {
                    print "+++++++++++ at $xno $yno $zindex \@stack_sml is @stack_sml \n" if $verbose >= 6;
                    # Index into @stack_sml over the appropriate reader pairs as with large nodules:
                    foreach my $ir (0..$numreaders-2) {
                        foreach my $jr ($ir+1..$numreaders-1){
                            # Translate indices to IDs for reporting results:
                            my $irid = $servicingRadiologist[$ir];
                            my $jrid = $servicingRadiologist[$jr];
                            print "+++++++++++++ compare reader $ir:$irid and $jr:$jrid for layer SMLN \n" if $verbose >= 6;
                            if ( $stack_sml[$ir] ne $FILLER && $stack_sml[$jr] ne $FILLER ) {
                                $overlap{$ir}{$stack_sml[$ir]}{$jr}{$stack_sml[$jr]} = 1.0;
                                $overlap{$jr}{$stack_sml[$jr]}{$ir}{$stack_sml[$ir]} = 1.0;
                                print "  reader $ir:$irid/nodule $stack_sml[$ir] overlaps reader $jr:$jrid/nodule $stack_sml[$jr] in layer SMLN \n" if $verbose >= 5;
                                $nnninfo{$ir}{$stack_sml[$ir]}{"overlap"} = "yes";  
                                $nnninfo{$jr}{$stack_sml[$jr]}{"overlap"} = "yes";
                            }  # end of if checking @stack_sml for valid nodule data
                        }  # end of the $jr loop
                    }  # end of the $ir loop
                }  # end of the if for testing @stack_sml if there multiple elements containing valid labels
                
                # Check for overlap between small (@stack_sml) and large (@stack) nodules:
                if ( ( scalar ( grep { $_ ne $FILLER} @stack_sml ) > 0 ) && ( scalar ( grep { $_ ne $FILLER} @stack ) > 0 ) ) {
                    print "+++++++++++ at ", $xno, " ", $yno, " ", $zindex, " \@stack_sml is @stack_sml and \@stack is @stack \n" if $verbose >= 6;
                    # Index over (almost) all reader pairs.  Since we're comparing between two different stack arrays,
                    # we need to look in both directions: for example, compare 1 & 2 and 2 & 1, but...
                    foreach my $ir (0..$numreaders-1) {  # $ir indexes thru @stack_sml
                        foreach my $jr (0..$numreaders-1) {  # $jr indexes thru @stack
                            # ...we don't need to compare 0 & 0, 1 & 1, 2 & 2, etc.
                            if ( $ir != $jr ) {
                                # Translate indices to IDs for reporting results:
                                my $irid = $servicingRadiologist[$ir];
                                my $jrid = $servicingRadiologist[$jr];
                                print "+++++++++++++ compare reader $ir:$irid in layer SMLN and $jr:$jrid in layer INCL \n" if $verbose >= 6;
                                if ( $stack_sml[$ir] ne $FILLER && $stack[$jr] ne $FILLER ) {
                                    # Store something (symmetrically in 2 cells) to flag simple overlap...
                                    $overlap{$ir}{$stack_sml[$ir]}{$jr}{$stack[$jr]} = 1.0;
                                    $overlap{$jr}{$stack[$jr]}{$ir}{$stack_sml[$ir]} = 1.0;
                                    print "  reader $ir:$irid/nodule $stack_sml[$ir] in layer SMLN overlaps reader $jr:$jrid/nodule $stack[$jr] in layer INCL \n" if $verbose >= 5;
                                    $nnninfo{$ir}{$stack_sml[$ir]}{"overlap"} = "yes";  
                                    $nnninfo{$jr}{$stack[$jr]}{"overlap"} = "yes";
                                    }  # end of if checking the stacks for valid nodule data
                            }  # end of if that allows only inter-reader comparisons
                        }  # end of the $jr loop
                    }  # end of the $ir loop
                }  # end of the if for testing if there multiple elements containing valid labels for small and large nodules
                
                # Check for overlap between non-nodules (@stack_non) and small (@stack_sml) nodules:
                if ( ( scalar ( grep { $_ ne $FILLER} @stack_non ) > 0 ) && ( scalar ( grep { $_ ne $FILLER} @stack_sml ) > 0 ) ) {
                    print "+++++++++++ at $xno $yno $zindex \@stack_non is @stack_non and \@stack_sml is @stack_sml\n" if $verbose >= 6;
                    # Index over reader pairs as above:
                    foreach my $ir (0..$numreaders-1) {  # $ir indexes thru @stack_non
                        foreach my $jr (0..$numreaders-1) {  # $jr indexes thru @stack_sml
                            if ( $ir != $jr ) {
                                # Translate indices to IDs for reporting results:
                                my $irid = $servicingRadiologist[$ir];
                                my $jrid = $servicingRadiologist[$jr];
                                print "+++++++++++++ compare reader $ir:$irid in layer NONN and $jr:$jrid in layer SMLN \n" if $verbose >= 6;
                                if ( $stack_non[$ir] ne $FILLER && $stack_sml[$jr] ne $FILLER ) {
                                    # Store something (symmetrically in 2 cells) to flag simple overlap...
                                    $overlap{$ir}{$stack_non[$ir]}{$jr}{$stack_sml[$jr]} = 1.0;
                                    $overlap{$jr}{$stack_sml[$jr]}{$ir}{$stack_non[$ir]} = 1.0;
                                    print "  reader $ir:$irid/nodule $stack_non[$ir] in layer NONN overlaps reader $jr:$jrid/nodule $stack_sml[$jr] in layer SMLN \n" if $verbose >= 5;
                                    #print "+++ getting ready to use these hash keys: ", $ir, "  &  ", $stack_non[$ir], "\n" if (1);  # testing
                                    $nnninfo{$ir}{$stack_non[$ir]}{"overlap"} = "yes";  
                                    $nnninfo{$jr}{$stack_sml[$jr]}{"overlap"} = "yes";
                                    push @ambig_msgs, sprintf "%s(%s)/%s/%s and %s(%s)/%s/%s ", $irid, $ir, $stack_non[$ir], $layer_list{NONN}, $jrid, $jr, $stack_sml[$jr], $layer_list{SMLN};
                                    # Store the ambiguity in a new hash which we will use discern the sets of ambiguous objects but not pairwise.  
                                    # Glue the reader and nodule ID strings together using the string ";;" which we assume to be unique (that is, not used elsewhere).
                                    # This will make it easy to pull the reader and nodule ID strings apart later.
                                    $ambigsets{"$ir" . ";;" . "$stack_non[$ir]"}{"$jr" . ";;" . "$stack_sml[$jr]"} = 'non-nodule';
                                    $ambigsets{"$jr" . ";;" . "$stack_sml[$jr]"}{"$ir" . ";;" . "$stack_non[$ir]"} = 'non-nodule';
                                    $listnonnodseparately{$ir}{$stack_non[$ir]} = 'no' if $xmlmatch;
                                }  # end of if checking the stacks for valid nodule data
                            }  # end of if that allows only inter-reader comparisons
                        }  # end of the $jr loop
                    }  # end of the $ir loop
                }  # end of the if for testing if there multiple elements containing valid labels for non-nodules and small nodules
                
                # Check for overlap between non-nodules (@stack_non) and large (@stack) nodules:
                if ( ( scalar ( grep { $_ ne $FILLER} @stack_non ) > 0 ) && ( scalar ( grep { $_ ne $FILLER} @stack ) > 0 ) ) {
                    print "+++++++++++ at $xno $yno $zindex \@stack_non is @stack_non and \@stack is @stack\n" if $verbose >= 6;
                    # Index over reader pairs as above:
                    foreach my $ir (0..$numreaders-1) {  # $ir indexes thru @stack_non
                        foreach my $jr (0..$numreaders-1) {  # $jr indexes thru @stack
                            if ( $ir != $jr ) {
                                # Translate indices to IDs for reporting results:
                                my $irid = $servicingRadiologist[$ir];
                                my $jrid = $servicingRadiologist[$jr];
                                print "+++++++++++++ compare reader $ir:$irid in layer NONN and $jr:$jrid in layer INCL \n" if $verbose >= 6;
                                if ( $stack_non[$ir] ne $FILLER && $stack[$jr] ne $FILLER ) {
                                    # Store something (symmetrically in 2 cells) to flag simple overlap...
                                    $overlap{$ir}{$stack_non[$ir]}{$jr}{$stack[$jr]} = 1.0;
                                    $overlap{$jr}{$stack[$jr]}{$ir}{$stack_non[$ir]} = 1.0;
                                    print "  reader $ir:$irid/nodule $stack_non[$ir] in layer NONN overlaps reader $jr:$jrid/nodule $stack[$jr] in layer INCL \n" if $verbose >= 5;
                                    $nnninfo{$ir}{$stack_non[$ir]}{"overlap"} = "yes";  
                                    $nnninfo{$jr}{$stack[$jr]}{"overlap"} = "yes";
                                    push @ambig_msgs, sprintf "%s(%s)/%s/%s and %s(%s)/%s/%s ", $irid, $ir, $stack_non[$ir], $layer_list{NONN}, $jrid, $jr, $stack[$jr], $layer_list{INCL};
                                    $ambigsets{"$ir" . ";;" . "$stack_non[$ir]"}{"$jr" . ";;" . "$stack[$jr]"} = 'non-nodule';
                                    $ambigsets{"$jr" . ";;" . "$stack[$jr]"}{"$ir" . ";;" . "$stack_non[$ir]"} = 'non-nodule';
                                    $listnonnodseparately{$ir}{$stack_non[$ir]} = 'no' if $xmlmatch;
                                }  # end of if checking the stacks for valid nodule data
                            }  # end of if that allows only inter-reader comparisons
                        }  # end of the $jr loop
                    }  # end of the $ir loop
                }  # end of the if for testing if there multiple elements containing valid labels for non-nodules and large nodules
                
                # Note that we do not consider overlap *between* non-nodules.
                
            }  # end of the $zindex loop going thru %contours1
        }  # end of the $yindex loop going thru %contours1
    }  # end of the $xindex loop going thru %contours1
    
    # This is mainly for diagnostic purposes to validate access to %nnninfo's keys/values:
    if ( $verbose > 6 or 0 ) {
        print "A display of \%nnninfo: key #3 and value for each reader/id entry ...\n";
        for my $r ( keys %nnninfo ) {
            for my $n ( keys %{$nnninfo{$r}} ) {
                print "  $r/$n: ";
                for my $k3 ( keys %{$nnninfo{$r}{$n}} ) {
                    print "$k3 ($nnninfo{$r}{$n}{$k3})  ";
                }
                print "\n";
            }
        }
        print "\n";
    }
    
    print "dump of the \%nnninfo hash...\n", Dumper(%nnninfo), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
    
#@@@: Code location: AdjForSolitary
    # Adjust %overlap for nodules that do not overlap anything based on how we just set %nnninfo in the loops above:
    for my $r ( keys %nnninfo ) {
        for my $n ( keys %{$nnninfo{$r}} ) {
            if ( ! $nnninfo{$r}{$n}{"overlap"} ) {
                # add non-overlapping nodules (but not non-nodules) to %overlap but mark them as not overlapping with anything
                if ( ! exists($nonnodinfo{$r}{$n}) ) {
                    $overlap{$r}{$n}{$NOREADER}{$NONODULE} = $NOOVERLAP;
                    my $type = ( exists($smnodinfo{$r}{$n}) ? 'small' : 'large' );
                    print "+++ \"no overlap\" has been marked in \%overlap for reader/nodule $r/$n ($type nodule) \n" if ( $verbose > 4 or 0 );
                }
            }
        }
    }
    
    # Now do some additional processing and display the overlap/matching & ambiguity results in several forms...
    
    # Process the %overlap hash; generate the %noduleremap hash from it...
    print "dump of the \%overlap hash...\n", Dumper(%overlap), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
    print "Process the \%overlap hash...\n" if $verbose >= 4;
    my $newnodnum = 0;  # a counter used to assign a global nodule number (SNID): consecutive integers starting with 1
    for my $r1 ( keys %overlap ) {
        my $r1id = reader_id($r1);
        print "-- reader $r1id\n" if $verbose >= 4;
        for my $n1 ( keys %{$overlap{$r1}} ) {
            print "--== nodule $n1 \n" if $verbose >= 4;
            for my $r2 ( keys %{$overlap{$r1}{$n1}} ) {
                my $r2id = reader_id($r2);
                print "--==-- reader $r2id\n" if $verbose >= 4;
                for my $n2 ( keys %{$overlap{$r1}{$n1}{$r2}} ) {
                    print "--==--== nodule $n2 \n" if $verbose >= 4;
                    if ( ($r2 eq $NOREADER) && ($n2 eq $NONODULE) ) {
                        $newnodnum++;
                        $noduleremap{$r1}{$n1} = $newnodnum;
                        print "           $r1id/$n1 does not overlap with anything -- assign an SNID: $newnodnum \n" if $verbose >= 4;
                    }  # end of if for "NO" check
                    else {
                        # we check for all (?) cases just to be sure...
                        if ( !$noduleremap{$r1}{$n1} && !$noduleremap{$r2}{$n2} ) {
                            $newnodnum++;
                            $noduleremap{$r1}{$n1} = $newnodnum;
                            $noduleremap{$r2}{$n2} = $newnodnum;
                            print "           assigning SNID $newnodnum to $r1id/$n1 and $r2id/$n2 \n" if $verbose >= 4;
                        }
                        elsif ( $noduleremap{$r1}{$n1} && !$noduleremap{$r2}{$n2} ) {
                            $noduleremap{$r2}{$n2} = $noduleremap{$r1}{$n1};
                            print "           copying SNID $noduleremap{$r1}{$n1} from $r1id/$n1 (1) to $r2id/$n2 (2) \n" if $verbose >= 4;
                        }
                        elsif ( $noduleremap{$r2}{$n2} && !$noduleremap{$r1}{$n1} ) {
                            $noduleremap{$r1}{$n1} = $noduleremap{$r2}{$n2};
                            print "           copying SNID $noduleremap{$r2}{$n2} from $r2id/$n2 (2) to $r1id/$n1 (1) \n" if $verbose >= 4;
                        }
                        elsif ( ( $noduleremap{$r1}{$n1} && $noduleremap{$r2}{$n2} ) && 
                                ( $noduleremap{$r1}{$n1} == $noduleremap{$r2}{$n2} ) ) {
                            print "           no need to do anything further with nodule pair $r1id/$n1 and $r2id/$n2 \n" if $verbose >= 4;
                        }
                        elsif ( ( $noduleremap{$r1}{$n1} && $noduleremap{$r2}{$n2} ) && 
                                ( $noduleremap{$r1}{$n1} != $noduleremap{$r2}{$n2} ) ) {
                            #""" User message doc: 6601: Inconsistency while attempting to assign an SNID.
                            msg_mgr (
                                severity => 'FATAL',
                                msgid => 6601,
                                appname => 'MAX',
                                subname => (caller(0))[3],
                                line => __LINE__ - 6,
                                text => my $text = ( sprintf( "Inconsistency while attempting to assign an SNID to %s/%s (SNID = %s) and %s/%s (SNID = %s).",
                                                              $r1id, $n1, $noduleremap{$r1}{$n1}, $r2id, $n2, $noduleremap{$r2}{$n2} ) ),
                                accum => 1,
                                verbose => 1,
                                code => $Site_Max::RETURN_CODE{matchingerror}
                            );
                        }
                        else {
                            #""" User message doc: 6902: Reached unreachable code while assigning an SNID.
                            msg_mgr (
                                severity => 'FATAL',
                                msgid => 6902,
                                appname => 'MAX',
                                subname => (caller(0))[3],
                                line => __LINE__ - 6,
                                text => my $text = ( sprintf( "Reached unreachable code while assigning an SNID at %s/%s and %s/%s.", $r1id, $n1, $r2id, $n2 ) ),
                                accum => 1,
                                verbose => 1,
                                code => $Site_Max::RETURN_CODE{internalerror}
                            );
                        }
                    }  # end of else for "NO" check
                }  # end of if for $n2
            }  # end of if for $r2
        }  # end of if for $n1
    }  # end of if for $r1
    print "\n" if $verbose >= 4;
    
    $maxnewnodnum = $newnodnum;
    print "Last SNID used: $maxnewnodnum \n\n" if $verbose >= 3;
    
    # Process the %noduleremap hash: generate the %noduleremaprev hash from it...
    print "dump of \%noduleremap...\n", Dumper(%noduleremap) if $verbose >= 5;
    print "Contents of the \%noduleremap hash (augmented by the \%nnninfo hash)...\n" if $verbose >= 3;
    for my $r ( keys %noduleremap ) {
        my $rid = $servicingRadiologist[$r];
        for my $n ( keys %{$noduleremap{$r}} ) {
            my $type = $nnninfo{$r}{$n}{'sizeclass'};
            $type = $type . ' nodule' unless $type eq 'non-nodule';
            my $newn = $noduleremap{$r}{$n};  # new/reassigned nodule number (SNID)
            print "  $rid($r)/$n ($type) remaps to SNID $newn \n" if $verbose >= 3;
            # populate a reversed version of %noduleremap for later use:
            $noduleremaprev{$newn}{$r}{$n} = 1;  # store an arbitrary value as a flag
            # populate an indexed reverse mapping hash for later use: <--- huh???
        }
    }
    print "\n";
    
    # This display of %noduleremap hash isn't really needed in most cases.
    # See the next section for pretty much the same info.
    if ( $verbose >= 5 ) {
        print "Contents of the \%noduleremap hash (reverse by explicit looping)...\n";
        print "     SNID       reader/orig. ID \n" . 
              "     ----       --------------- \n";  # a heading line
        my $foundone = 1;  # this will get us started
        $newnodnum = 0;
        while ( $foundone ) {
            $newnodnum++;  # get ready to search for the next nodule number
            $foundone = 0;  # will set this below if we find the nodule number
            for my $r ( keys %noduleremap ) {
                my $rid = $servicingRadiologist[$r];
                for my $n ( keys %{$noduleremap{$r}} ) {
                    if ( $noduleremap{$r}{$n} == $newnodnum ) {
                        print "       $noduleremap{$r}{$n} \t$rid($r)/$n \n";
                        $foundone = 1;
                    }
                }  # end of looping over nodule ID keys in %noduleremap
            }  # end of looping over reader keys in %noduleremap
        }  # end of while on $found
        # See also section 13.15.7 in the Cookbook (Tie::RevHash).  Also 13.15.5 -- Tie::AppendHash -- might also be useful
        # in designing a data structure to accumulate multiple values per key.
        print "\n";
    }
    
    print "dump of \%noduleremaprev... \n", Dumper(%noduleremaprev) if $verbose >= 6;
    print "Process the \%noduleremaprev hash (including nodule/nodule ambiguity processing)...\n" if $verbose >= 3;
    
    # This is a good place to grab the matching results for the XML file,
    # so we'll start by writing some XML lines.  Then in the loop below (looping over the keys of
    # %noduleremaprev), we accumulate the XML lines that pertain to matching...
    if ( $xmlmatch ) {
        write_xml_line1 ( $matchingxml_fh );
        print $matchingxml_fh $Site_Max::TAB[0] . "<LidcMatching> \n";
        write_xml_app_header( VERSIONMATCHINGXML, $matchingxml_fh );
        write_xml_datainfo_header( $matchingxml_fh );
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[1] . "<MatchingInfo>");
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[2] . "<SmallNoduleSphere diameter=\"$sphere_diam\" units=\"mm.\"/>");
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[2] . "<NumberOfReaders>$numreaders</NumberOfReaders>");
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[2] . "<MatchingComments/>");
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[1] . "</MatchingInfo>");
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[1] . "<Matching>");
    }
    
#@@@ Code location: AmbigProc1
    # This processing loop also prepares us to look for overlap ambiguity between nodules (below).
    my %ambig_list;  # this will accumulate those reader/nodule pairs that are involved in ambiguity.
    for my $newn ( keys %noduleremaprev ) {
        my @rarr = keys %{$noduleremaprev{$newn}};
        my $numreadersforthis = scalar(@rarr);
        print "  $numreadersforthis readers for SNID $newn:  " if $verbose >= 3;
        if ( $xmlmatch ) {
            # begin XML for the next SNID:
            accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[2] . "<MatchedNoduleInfo> " );
            accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[3] . "<SeriesNoduleID value=\"$newn\"/> " );
            accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[3] . "<Constituents> " );
        }
        # Initialize two little arrays that will hold reader numbers and nodule IDs that will be extracted in the loop below.
        # They will be used to detect ambiguity.
        my ( @rlist, @nlist ) = ();
        # Three similar arrays but these are only filled with reader, noduleid, and SNID for large nodules.  Used to keep track of "majority" info for QA #6[original].
        my ( @rlglist, @nlglist, @slglist ) = ();
        my $num_lg;
        for my $r ( @rarr ) {
            my $rid = $servicingRadiologist[$r];
            for my $n ( keys %{$noduleremaprev{$newn}{$r}} ) {
                print "$rid($r)/$n   " if $verbose >= 3;  # accumulate reader/nodule on the current line
                push @rlist, $r;
                push @nlist, $n;
                # Write a line of XML for each constituent:
                my ( $typestr, $sizeclassstr, $locationstr ) = ( '' ) x 3;
                # >>> This if/else tree could be simplified...
                if ( exists ( $nonnodinfo{$r}{$n} ) ) {
                    $typestr = 'non-nodule';
                    my $nonxyz_ref = $nonnodinfo{$r}{$n};
                    my $nonx = @$nonxyz_ref[0];
                    my $nony = @$nonxyz_ref[1];
                    my $nonz = @$nonxyz_ref[2];
                    my $nonzint = round( $nonz, 0 );
                    my $nonzcoord = $allz[ $nonzint ];
                    my $sopinstanceuid = $z2siu{ $nonzcoord };
                    $locationstr = sprintf "i=\"%d\" j=\"%d\" z=\"%.3f\" sopinstanceuid=\"%s\" locationtype=\"single mark\"", $nonx, $nony, $nonzcoord, $sopinstanceuid;
                }
                else {
                    $typestr = 'nodule';
                    if ( exists ( $smnodinfo{$r}{$n} ) ) {
                        $sizeclassstr = 'sizeclass="small"';
                        my $smxyz_ref = $smnodinfo{$r}{$n};
                        my $smx = @$smxyz_ref[0];
                        my $smy = @$smxyz_ref[1];
                        my $smz = @$smxyz_ref[2];
                        my $smzint = round( $smz, 0 );
                        my $smzcoord = $allz[ $smzint ];
                        my $sopinstanceuid = $z2siu{ $smzcoord };
                        # The following line was commented by Thomas Lampert as it caused an error when processing LIDC-IDRI-0576, only to remain commented for use in the LIDC Matlab toolbox
                        # $locationstr = sprintf "i=\"%d\" j=\"%d\" z=\"%.3f\" sopinstanceuid=\"%s\" locationtype=\"single mark\"", $smx, $smy, $smzcoord, $sopinstanceuid; 
                    }
                    else {
                        $sizeclassstr = 'sizeclass="large"';
                        push @rlglist, $r;
                        push @nlglist, $n;
                        my $lgx = $centroids{$r}{$n}{"centx"};
                        my $lgy = $centroids{$r}{$n}{"centy"};
                        my $lgz = $centroids{$r}{$n}{"centz"};
                        my $lgzint = round( $lgz, 0 );
                        my $lgzcoord = $allz[ $lgzint ];
                        my $sopinstanceuid = $z2siu{ $lgzcoord };
                        $locationstr = sprintf "i=\"%.1f\" j=\"%.1f\" z=\"%.3f\" sopinstanceuid=\"%s\" locationtype=\"computed centroid\"", $lgx, $lgy, $lgzcoord, $sopinstanceuid;
                    }
                }
                accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[4] . "<Object type=\"$typestr\" reader=\"$servicingRadiologist[$r]\" id=\"$n\" $sizeclassstr $locationstr/>" ) if $xmlmatch;
            }
        }
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[3] . "</Constituents>" ) if $xmlmatch;
        print "\n" if $verbose >= 3;  # a newline for the cumulative print stmt above
        #print "+++ dump of \@rarr for \$newn = $newn ... \n", Dumper(@rarr);  # testing
        #print "+++ dump of \@rlist ... \n", Dumper(@rlist);  # testing
        #print "+++ dump of \@nlist ... \n", Dumper(@nlist);  # testing
        # Load the majority info from the little "lglist" arrays into %majority:
        $num_lg = scalar ( @rlglist );
        if ( $num_lg >= MAJORITYTHR ) {
            while ( @rlglist ) {
                my $r = pop @rlglist;
                my $n = pop @nlglist;
                $majority{$r}{$n} = $newn;
            }
        }
        # Detect nodule overlap ambiguity: Look for overlap among all combinations of original nodules that
        # have been re-assigned to the same new nodule number (SNID).  (Only needs to be done for > 2
        # original nodules (which is the same as the number of readers) since for 1 or 2, no ambiguity is possible.)
        # The overlap checked for here is the case where nodules A & C overlap and B & C overlap,
        # but A & B do *not* overlap.
        my $nummarksforthis = scalar(@rlist);  # "number of marks made for this nodule" -- the one under current consideration
                                               # N.B.: This can be more than the size of @rarr if a reader makes more than one marking that matches.
        if ( $nummarksforthis != $numreadersforthis ) {
            print "    (These $numreadersforthis readers made $nummarksforthis markings.) \n" if $verbose >= 3;
        }
        if ( $nummarksforthis > 2 ) {
            # setup the loop indices so that we check all possible pairs (but in one "direction" only)...
            foreach my $ir ( 0 .. ( $nummarksforthis - 2 ) ) {
                foreach my $jr ( ( $ir + 1 ) .. ( $nummarksforthis - 1 ) ) {
                    # Translate indices to IDs for reporting results:
                    my $irid = $servicingRadiologist[$rlist[$ir]];
                    my $jrid = $servicingRadiologist[$rlist[$jr]];
                    # Do the following check only if it doesn't involve non-nodules (which are checked elsewhere):
                    if ( $nonnodinfo{$rlist[$ir]}{$nlist[$ir]} || $nonnodinfo{$rlist[$jr]}{$nlist[$jr]} ) {
                        print "  Will not compare for ambiguity: $irid($rlist[$ir])/$nlist[$ir] and $jrid($rlist[$jr])/$nlist[$jr] (one or both is a non-nodule)\n" if $verbose >=5;
                    }
                    else {
                        print "  Comparing for ambiguity: $irid($rlist[$ir])/$nlist[$ir] and $jrid($rlist[$jr])/$nlist[$jr] \n" if $verbose >=5;
                        # check for overlap (in both directions) for the current reader/nodule pair
                        #print "  +++ overlap between $rlist[$ir]:$irid/$nlist[$ir] and $rlist[$jr]:$jrid/$nlist[$jr] ?... " . exists ( $overlap{$rlist[$ir]}{$nlist[$ir]}{$rlist[$jr]}{$nlist[$jr]} ) . "\n";  # testing
                        #print "  +++ overlap between $rlist[$jr]:$jrid/$nlist[$jr] and $rlist[$ir]:$irid/$nlist[$ir] ?... " . exists ( $overlap{$rlist[$jr]}{$nlist[$jr]}{$rlist[$ir]}{$nlist[$ir]} ) . "\n";  # testing
                        if ( ( ! exists ( $overlap{$rlist[$ir]}{$nlist[$ir]}{$rlist[$jr]}{$nlist[$jr]} ) ) || 
                             ( ! exists ( $overlap{$rlist[$jr]}{$nlist[$jr]}{$rlist[$ir]}{$nlist[$ir]} ) ) ) {
                                $ambig_list{$rlist[$ir]}{$nlist[$ir]} = 1;  # just set a flag
                                $ambig_list{$rlist[$jr]}{$nlist[$jr]} = 1;  # to mark involvement
                                # (We will format the ambig msg later after further processing)
                        }
                    }  # end of the if that excludes non-nodules from this check
                }  # end of $jr loop
            }  # end of $ir loop
        }  # end of if checking $nummarksforthis
        # end the XML for this SNID:
        accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[2] . "</MatchedNoduleInfo>" ) if $xmlmatch;
    }  # end of looping over keys of %noduleremaprev
    
    print "dump of \%majority hash...\n", Dumper(\%majority) if $verbose >= 4;
    
    # close-out this level of the XML:
    accum_xml_lines ( 'matching', \%xml_lines, $Site_Max::TAB[1] . "</Matching>" ) if $xmlmatch;
    print "\n";
    
#@@@ Code location: AmbigProc2
    # Complete the processing for nodule/nodule ambiguity:
    # N.B.: Should inspect %ambig_list (or generate a separate structure above) to see if there
    #       is more than 1 ambiguity (must adjust the algorithm accordingly).  Could add another
    #       key to %ambig_list: store an index to the ambiguity sets in the added key.
    if ( scalar ( keys %ambig_list ) > 0 ) {
        # Accumulate a hash of counts of overlaps:
        print "dump of \%ambig_list ...\n ", Dumper(%ambig_list) if $verbose >=5;
        print "Process the nodule/nodule ambiguity list (the \%ambig_list hash)...\n";
        my $num_of_ambigs = 0;
        my %overlap_counts;  # this keeps track of what the contents of %ambig_list overlap with
        # Traverse into %ambig_list to get each of its $r/$n pairs...
        for my $r ( keys %ambig_list ) {
            for my $n ( keys %{$ambig_list{$r}} ) {
                $num_of_ambigs++;
                print "  checking to see what $r/$n overlaps with...\n" if $verbose >= 5;
                print "dump of \%overlap{$r}{$n} ...\n", Dumper (%{$overlap{$r}{$n}}) if $verbose >= 5;
                # Now traverse into %overlap staring at $r/$n and get each of its $ro/$no pairs...
                for my $ro ( keys %{$overlap{$r}{$n}} ) {
                    for my $no ( keys %{$overlap{$r}{$n}{$ro}} ) {
                        print "    augmenting \%overlap_counts{$ro}{$no} \n" if $verbose >=5;
                        $overlap_counts{$ro}{$no}++;
                    }
                }
            }
        }
        # Look at the counts to find the nodule that is the common overlap for the nodules involved in ambiguity:
        print "dump of \%overlap_counts...\n", Dumper(%overlap_counts), "\n" if $verbose >= 5;
        my ($rcommon, $ncommon);
        for my $r ( keys %overlap_counts ) {
            for my $n ( keys %{$overlap_counts{$r}} ) {
                if ( $overlap_counts{$r}{$n} == $num_of_ambigs ) {
                    print "  reader/nodule $r/$n has $num_of_ambigs overlap counts\n" if $verbose >=5;
                    # The above equality should only happen once and thus $rcommon & $ncommon
                    # should only be set once.  Check for this and issue a warning.
                    if ( $rcommon || $ncommon ) {
                        #""" User message doc: 4701: A possible problem has been detected in nodule/nodule ambiguity checking.
                        msg_mgr (
                            severity => 'WARNING',
                            msgid => 4701,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => my $text = ( sprintf("A possible problem has been detected in nodule/nodule ambiguity checking: \$rcommon and \$ncommon are already set to %s (%s) and %s; getting ready to set them to %s (%s) and %s.",
                                                         $rcommon, $servicingRadiologist[$rcommon], $ncommon, $r, $servicingRadiologist[$r], $n) ),
                            accum => 1,
                            code => -1
                        );
                    }
                    # Regardless, go ahead and set these 2 variables:
                    ($rcommon, $ncommon) = ($r,$n);
                }
            }
        }
        if ( $rcommon && $ncommon ) {
            # These two variables should have been set in the loop above
            print "  reader/nodule $servicingRadiologist[$rcommon]($rcommon)/$ncommon is in common overlap with these: \n";
            for my $r ( keys %ambig_list ) {
                for my $n ( keys %{$ambig_list{$r}} ) {
                    print "    $servicingRadiologist[$r]($r)/$n \n";
                    $ambigsets{$rcommon . ';;' . $ncommon}{$r . ';;' . $n} = 'nodule';
                    $ambigsets{$r . ';;' . $n}{$rcommon . ';;' . $ncommon} = 'nodule';
                    my ( $sizestr1, $sizestr2 );
                    $sizestr1 = ( exists ( $smnodinfo{$rcommon}{$ncommon} ) ? $layer_list{SMLN} : $layer_list{INCL} );
                    $sizestr2 = ( exists ( $smnodinfo{$r      }{$n      } ) ? $layer_list{SMLN} : $layer_list{INCL} );
                    push @ambig_msgs, sprintf "%s(%s)/%s/%s and %s(%s)/%s/%s ", $servicingRadiologist[$rcommon], $rcommon, $ncommon, $sizestr1, $servicingRadiologist[$r], $r, $n, $sizestr2;
                }
            }
        }
        else {
            #""" User message doc: 4702: There is a problem processing the nodule/nodule ambiguity data to find the common matching nodule.
            msg_mgr (
                severity => 'WARNING',
                msgid => 4702,
                appname => 'MAX',
                subname => (caller(0))[3],
                line => __LINE__ - 6,
                text => 'There is a problem processing the nodule/nodule ambiguity data to find the common matching nodule ($rcommon and $ncommon were not set).',
                accum => 1,
                code => -1
            );
        }
    }  # end of the if that checks whether there is any nodule/nodule ambiguity to process (if %ambig_list has any content)
    
    # This is the old way (pairwise) of looking at ambiguity: Show it only under elevated verbosity...
    if ( $verbose >= 6 ) {
        print "\n";
        # Show all ambiguity results that were accumulated from all sections above:
        if ( @ambig_msgs && $verbose >= 3 ) {
            print "Ambiguity has been detected for these reader/ID/type pairs: \n";
            print "  (Obsolete: Ambiguity is more properly displayed in \"sets\" rather than in pairs.)\n";
            foreach ( @ambig_msgs ) {
                print "  ", $_, "\n";
            }
            print "\n";
        }
    }
    print "\n";
    
    #@@@ Code location: AmbigProc1a
    print "dump of the \%ambigsets hash...\n", Dumper(%ambigsets), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
    print "Process the \%ambigsets hash (\"reader ID/nodule ID\" are indicated)...\n" if $verbose >= 3;
    # These loops do two things: Dump the %ambigsets hash in a readable form and create %ambigsets1 for later use.
    # Recall that %ambigsets is set symmetrically: $ambigsets{idA}{idB} = 1 and $ambigsets{idB}{idA} = 1 which
    #   indicates that the objects defined by IDs idA & idB are related through an ambiguity.
    # Ambiguity will be represented in a more succinct way in %ambigsets1 which is created from %ambigsets.
    my $ambig_sets_cntr = 0;  # This will be incremented to indicate the "discovery" of new ambiguity sets.
    my %ambig_type = ();  # a hash to keep track of the type of ambiguity (nodule, non-nodule, possibly mixed, mixed) of each ambiguity set
    for my $id1 ( keys %ambigsets ) {
        my %current_set = ();  # initialize this temporary hash that will accumulate the current ambiguity set
        # As we loop over the keys in the 1st position, we will develop info about the object (nodule or non-nodule) represented by this key.
        my @list = keys %{$ambigsets{$id1}};
        my $numassoc = scalar( @list );  # How many "associates" does this key ($id1) have?
        my @id1arr = split ( /;;/, $id1 );  # ";;" is what we used earlier to glue the reader and nodule ID strings together
        my ( $type, $sizeclass, $snid );
        my ( $r1, $n1, $r2, $n2 );  # reader and object (nodule/non-nodule) ID variables
        if ( exists($nonnodinfo{$id1arr[0]}{$id1arr[1]}) ) {
            $type = 'non-nodule';
            $sizeclass = '';
            $snid = '';
            $r1 = $id1arr[0];
            $n1 = $id1arr[1];
        }
        else {
            $type = 'nodule';
            $sizeclass = ( exists($smnodinfo{$id1arr[0]}{$id1arr[1]}) ? 'small' : 'large' );
            $snid = $noduleremap{$id1arr[0]}{$id1arr[1]} if exists $noduleremap{$id1arr[0]};  # check for existence at the 1st key to avoid effects of auto-vivification
            $r1 = 'SNID';
            $n1 = $snid;
        }
        # Build-up a descriptive string for this object:
        my $descr;
        $descr  = '(';
        $descr .= $sizeclass      . ' ' if $sizeclass;
        $descr .= $type           . ' ' if $type;
        $descr .= ' SNID=' . $snid      if $snid;
        $descr .= ')';
        print "  $servicingRadiologist[$id1arr[0]]/$id1arr[1] $descr has $numassoc associate(s):\n" if $verbose >= 3;
        $current_set{$id1arr[0]}{$id1arr[1]} = 1;  # set a flag to mark presence of the object represented by the key of the outer loop
        # Get ready for the inner loop (all the objects associated with the outer object):
        for my $id2 ( @list ) {
            # Each of these keys in the inner loop represents an associate of the key ($id1) in the outer for loop.
            my @id2arr = split ( /;;/, $id2 );
            # As we did above, set some variables that characterize the object represented by this key.
            if ( exists($nonnodinfo{$id2arr[0]}{$id2arr[1]}) ) {
                $type = 'non-nodule';
                $sizeclass = '';
                $snid = '';
                $r2 = $id2arr[0];
                $n2 = $id2arr[1];
            }
            else {
                $type = 'nodule';
                $sizeclass = ( exists($smnodinfo{$id2arr[0]}{$id2arr[1]}) ? 'small' : 'large' );
                $snid = $noduleremap{$id1arr[0]}{$id1arr[1]} if exists $noduleremap{$id1arr[0]};
                $r2 = 'SNID';
                $n2 = $snid;
            }
            # Build-up a descriptive string for this object:
            $descr  = '(';
            $descr .= $sizeclass      . ' ' if $sizeclass;
            $descr .= $type           . ' ' if $type;
            $descr .= ' SNID=' . $snid      if $snid;
            $descr .= ')';
            my $type_flag = $ambigsets{$id1}{$id2};
            print "    $servicingRadiologist[$id2arr[0]]/$id2arr[1] $descr (this pair was originally flagged as '$type_flag' ambiguity) \n" if $verbose >= 3;
            $current_set{$id2arr[0]}{$id2arr[1]} = 1;  # set a flag to mark presence of the object represented by this inner key
        }  # end of for loop over the 2nd key of %ambigsets
        # Use %current_set to populate %ambigsets1 which organizes the ambiguity into sets suitable for later use:
        print "dump of the \%current_set hash...\n", Dumper(%current_set), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
        # Go thru the current sets and see if any of these sets are in %ambigsets1 yet (*):
        #   If so, get the current set number from %ambigsets.
        #   If not, bump the counter $ambig_sets_cntr and use this value as the current set.
        # (*) This seems strange b/c %ambigsets1 gets set in a later loop (the one below where we loop again
        #     over the keys of %current_set).  So, the first time thru this loop, the "exists ( $ambigsets1{$r}{$n} )"
        #     code finds nothing.
        my $this_set_num = 0;  # reset this as preparation for going into this loop.
        foreach my $r ( keys %current_set ) {
            foreach my $n ( keys %{$current_set{$r}} ) {
                print "      +++ looking at $r $n from \%current_set ...\n" if ( $verbose >= 7 or 0 );
                # We check %ambigsets1 for existence; note that %ambigsets1 is set in a loop below.
                if ( exists ( $ambigsets1{$r}{$n} ) ) {
                    $this_set_num = $ambigsets1{$r}{$n};
                    print "        +++ $r $n is already in \%ambigsets1 and is already marked as being in set $this_set_num \n" if ( $verbose >= 7 or 0 );  # 0: conditional dump; 1: always dump
                }
            }  # end of $n loop thru %current_set
        }  # end of $r loop thru %current_set
        if ( $this_set_num == 0 ) {
            # This means that we didn't find a set number, so "create" a new one by bumping the counter:
            # ( Otherwise, $this_set_num is set as above from %ambigsets1, and we'll use its value.)
            $ambig_sets_cntr++;
            $this_set_num = $ambig_sets_cntr;
            print "        +++ create the next set: number $this_set_num \n" if ( $verbose >= 7 or 0 );  # 0: conditional dump; 1: always dump
        }
        # N.B.: We could add some code to the above to check for consistency: Each {$r}{$n} that exists in %current_set should have the same value (be in the same set).
        # Go thru the current sets again: copy them into %ambigsets1 and mark each with the set number that we just found.
        print "    --- go over \%currentsets (for set $this_set_num)... \n" if ( 0 );
        foreach my $r ( keys %current_set ) {
            foreach my $n ( keys %{$current_set{$r}} ) {
                $ambigsets1{$r}{$n} = $this_set_num;
                print "      --- $r $n is in \%ambigsets1 and is marked/re-marked as being in set $this_set_num \n" if ( $verbose >= 7 or 0 );  # 0: conditional dump; 1: always dump
            }
        }
    }  # end of for loop over the 1st key of %ambigsets (a concatenation of reader & nod ID)
    print "Number of ambiguous object sets identified: $ambig_sets_cntr \n\n" if $verbose >= 3;
    
    print "dump of the \@AMBIG_TYPE array...\n", Dumper(@AMBIG_TYPE), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
    
    #@@@ Code location: AmbigProc1b
    print "dump of the \%ambigsets1 hash...\n", Dumper(%ambigsets1), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
    print "Process the \%ambigsets1 hash (\"reader ID/nodule ID\" are indicated)...\n" if $verbose >= 3;
    # This section does two things: Dump the %ambigsets1 hash in a readable form and create ambiguity XML lines.
    # We loop thru %ambigsets1 to discern the type of the ambiguity for use in the <AmbiguousSet type=""> tag...
    # We know how many sets of ambiguity we found above, so use this number to drive the loop:
    my %ambig_sets_type = ();  # Use this as a counter for the number of nods & non-nods in each set.
    tie %ambig_sets_type, "Tie::IxHash";
    foreach my $set ( 1 .. $ambig_sets_cntr ) {
        print "  Members of ambiguity set $set: \n" if $verbose >= 3;
        # Initialize the counters for this set:
        $ambig_sets_type{$set}{'nodule'} = 0;
        $ambig_sets_type{$set}{'non-nodule'} = 0;
        for my $rdr ( keys %ambigsets1 ) {
            my $rdrid = $servicingRadiologist[$rdr];
            for my $nid ( keys %{$ambigsets1{$rdr}} ) {
                if ( $ambigsets1{$rdr}{$nid} == $set ) {
                    print "    $rdrid($rdr)/$nid \n" if $verbose >= 3;
                    if ( exists($nonnodinfo{$rdr}{$nid}) ) {
                        $ambig_sets_type{$set}{'non-nodule'}++;
                    }
                    else {
                        $ambig_sets_type{$set}{'nodule'}++;
                    }
                }
                # This double loop looks at %ambigsets1 again to find the type of ambiguity between each pair in this set:
                # !!! This has  not been thoroughly tested (not sure if we're indexing into the hashes correctly) -- defer completion until later !!!
                for my $rdri ( keys %ambigsets1 ) {
                    for my $nidi ( keys %{$ambigsets1{$rdri}} ) {
                        if ( $ambigsets1{$rdr}{$nid} == $set ) {
                            my $idstr  = $rdr  . ';;' . $nid;
                            my $idstri = $rdri . ';;' . $nidi;
                            my $type = ( exists ( $ambigsets{$idstr}{$idstri} ) ? $ambigsets{$idstr}{$idstri} : 'indet' );
                            print "      +++ detected $type ambiguity between $idstr & $idstri \n" if ( $type ne 'indet' && ( $verbose >= 5 or 0 ) );
                        }
                    }
                }
            }  # end of for loop over the 2nd key of %ambigsets1
        }  # end of for loop over the 1st key of %ambigsets1
        # Discern ambiguity type based on the number of nodules & non-nodules in the set:
        my $type = get_ambig_type ( $ambig_sets_type{$set}{'nodule'}, $ambig_sets_type{$set}{'non-nodule'} );
        # Set a couple of flags for later use:
        $foundnonnodambig = 1 if $type eq 'non-nodule';
        $foundnodnodambig = 1 if $type eq     'nodule';
        if ( $type eq 'indeterminate' ) {
            # Indeterminacy results with 3 or more nodules and 1 or more non-nodules in an ambiguity set.
            # This could represent either nodule or non-nodule ambiguity.  Additional processing is needed
            # to determine which: May be able resolve this by looking at the constituents of the SNID of this set.
        }
        print "  This set exhibits '$type' ambiguity.\n";
    }  # end of the for loop over all the sets
    print "dump of the \%ambig_sets_type hash...\n", Dumper(%ambig_sets_type), "\n" if ( $verbose >= 5 or 0 );  # 0: conditional dump; 1: always dump
    # Loop again as above to generate the ambiguity XML lines:
    foreach my $set ( 1 .. $ambig_sets_cntr ) {
        # Start a new <AmbiguousSet> section:
        my $type = get_ambig_type ( $ambig_sets_type{$set}{'nodule'}, $ambig_sets_type{$set}{'non-nodule'} );  # as above
        accum_xml_lines ( 'ambig', \%xml_lines, sprintf ( "%s<AmbiguousSet type=\"%s\">", $Site_Max::TAB[2], $type ) );
        for my $rdr ( keys %ambigsets1 ) {
            my $rdrid = $servicingRadiologist[$rdr];
            for my $nid ( keys %{$ambigsets1{$rdr}} ) {
                if ( $ambigsets1{$rdr}{$nid} == $set ) {
                    my ( $type, $sizeclass, $snid );
                    # Set some variables that characterize the object represented by this key.
                    $snid = $noduleremap{$rdr}{$nid};
                    if ( exists($nonnodinfo{$rdr}{$nid}) ) {
                        $type = 'non-nodule';
                        $sizeclass = '';
                    }
                    else {
                        $type = 'nodule';
                        $sizeclass = ( exists($smnodinfo{$rdr}{$nid}) ? 'small' : 'large' );
                    }
                    accum_xml_lines ( 'ambig', \%xml_lines, sprintf ( "%s<Object type=\"%s\" reader=\"%s\" id=\"%s\" sizeclass=\"%s\" snid=\"%s\"/>",
                                                                      $Site_Max::TAB[3], $type, $rdrid, $nid, $sizeclass, $snid ) );
                }
            }  # end of for loop over the 2nd key of %ambigsets1
        }  # end of for loop over the 1st key of %ambigsets1
        # Close-out this <AmbiguousSet> section
        accum_xml_lines ( 'ambig', \%xml_lines, sprintf ( "%s</AmbiguousSet>", $Site_Max::TAB[2] ) );
    }  # end of the for loop over all the sets
    print "\n" if $verbose >= 3;
    
    # Process the list that indicates which non-nodules are unmatched; this list is output in a separate XML section:
    if ( $xmlmatch ) {
        print "dump of the \%listnonnodseparately hash...\n", Dumper(%listnonnodseparately), "\n" if $verbose >= 5;
        print "Index through the \%listnonnodseparately hash... \n" if $verbose >= 4;
        for my $r ( keys %listnonnodseparately ) {
            my $rid = $servicingRadiologist[$r];
            for my $n ( keys %{$listnonnodseparately{$r}} ) {
                my $value = $listnonnodseparately{$r}{$n};
                print "  reader $rid($r) / ID $n: $value \n" if $verbose >= 4;
                accum_xml_lines ( 'nonnodunmat', \%xml_lines, sprintf( "%s<Object type=\"non-nodule\" reader=\"%s\" id=\"%s\"/>", $Site_Max::TAB[3], $rid, $n ) ) if $value eq 'yes';
                # N.B.: !!! The following "nonnodmat" lines are never written out to file !!!
                accum_xml_lines ( 'nonnodmat'  , \%xml_lines, sprintf( "%s<Object type=\"non-nodule\" reader=\"%s\" id=\"%s\"/>", $Site_Max::TAB[3], $rid, $n ) ) if $value eq 'no';
            }
        }
        print "\n" if $verbose >= 4;
    }
    
    print "dump of \%xml_lines...\n", Dumper(%xml_lines), "\n" if ( 0 );  # for testing: 0 to supress output; 1 to dump it
    # Write the matching XML file:
    if ( $xmlmatch ) {
        # Dump the lines from the hash to the file:
        write_xml_lines ( 'matching', \%xml_lines, $matchingxml_fh ); 
        # Add ambiguity lines (if any) to the matching XML:
        if ( $xml_lines{'ambig'} ) {   # changed from "if ( defined @{$xml_lines{'nonnodunmat'}} ) {"  by Tom Lampert (produced comile errors)
            print $matchingxml_fh $Site_Max::TAB[1] . "<Ambiguity>\n";
            write_xml_lines ( 'ambig', \%xml_lines, $matchingxml_fh );
            print $matchingxml_fh $Site_Max::TAB[1] . "</Ambiguity>\n";
        }
        # Add non-nodule lines (if any) to the matching XML:
#         # >>> This next for "loop"is preliminary: may not really want/need this in the XML.
#         #     Would be nice to eliminate the extra </NonNodules> (end of the matched section)
#         #     followed by <NonNodules> (beginning of the unmatched), but this requires some extra logic.
#         for ( @{$xml_lines{'nonnodmat'}} ) {
#             print $matchingxml_fh $Site_Max::TAB[1] . "<NonNodules>\n";
#             print $matchingxml_fh $Site_Max::TAB[2] . "<Matched>\n";
#             write_xml_lines ( 'nonnodmat', \%xml_lines, $matchingxml_fh );
#             print $matchingxml_fh $Site_Max::TAB[2] . "</Matched>\n";
#             print $matchingxml_fh $Site_Max::TAB[1] . "</NonNodules>\n";
#             last;
#         }
        if ( $xml_lines{'nonnodunmat'} ) {   # changed from "if ( defined @{$xml_lines{'nonnodunmat'}} ) {"  by Tom Lampert (produced comile errors)
            print $matchingxml_fh $Site_Max::TAB[1] . "<NonNodules>\n";
            print $matchingxml_fh $Site_Max::TAB[2] . "<Unmatched>\n";
            write_xml_lines ( 'nonnodunmat', \%xml_lines, $matchingxml_fh );
            print $matchingxml_fh $Site_Max::TAB[2] . "</Unmatched>\n";
            print $matchingxml_fh $Site_Max::TAB[1] . "</NonNodules>\n";
        }
        print $matchingxml_fh $Site_Max::TAB[0] . "</LidcMatching> \n";
        print "Matching results have been saved as an XML file: $matchingxmlfile \n";
    }
    
    if ( $foundnonnodambig ) {
        #""" User message doc: 3107: Ambiguity involving a non-nodule has been detected.
        msg_mgr (
            severity => 'INFO',
            msgid => 3107,
            text => 'Ambiguity involving a non-nodule has been detected.',
            accum => 1,
            before   => 1,
            screen => 1,
            code => -1
        );
    }
    
    if ( $foundnodnodambig ) {
        #""" User message doc: 3108: Nodule/nodule ambiguity has been detected.
        msg_mgr (
            severity => 'INFO',
            msgid => 3108,
            text => 'Nodule/nodule ambiguity has been detected.',
            accum => 1,
            before   => 1,
            screen => 1,
            code => -1
        );
    }
    
    #""" User message doc: 3103: Matching has been performed.
    # Generate a status message for insertion into @main::msglog
    msg_mgr (
        severity => 'INFO',
        msgid => 3103,
        text => 'Matching has been performed.',
        accum => 1,
        screen => 0,  # doesn't need to be displayed on the screen
        code => -1
    );
    
    return;
    
}  # end of sub simple_matching


sub secondary_matching {
    
    print "\n\n================ Secondary check for matching ===================\n\n" if $verbose >= 1;
    # This secondary check is done prior to (1) pmap generation, (2) saving results to a file,
    # and (3) writing final results to the XML file
    
    # Secondary matching criterion: consider the "additional" measures as stored in %nodulepairinfo
    for my $r1 ( keys %nodulepairinfo ) {
        print "-- reader $r1 \n" if $verbose >= 4;
        for my $n1 ( keys %{$nodulepairinfo{$r1}} ) {
            print "--== nodule $n1 \n" if $verbose >= 4;
            for my $r2 ( keys %{$nodulepairinfo{$r1}{$n1}} ) {
                print "--==-- reader $r2 \n" if $verbose >= 4;
                for my $n2 ( keys %{$nodulepairinfo{$r1}{$n1}{$r2}} ) {
                    print "--==--== nodule $n2 \n" if $verbose >= 4;
                    my $ncs = $nodulepairinfo{$r1}{$n1}{$r2}{$n2}{"NormCentSep"};
                    my $vr =  $nodulepairinfo{$r1}{$n1}{$r2}{$n2}{"VolRatio"};
                    $nodulepairinfo{$r1}{$n1}{$r2}{$n2}{"SecOverlap"} = "accept";  # default
                    printf "           normalized centroidal separation: %.3f \n", $ncs if $verbose >= 4;
                    if ( $ncs >= $NCSthr ) {
                        print "             * rejected based on the separation criterion \n" if $verbose >= 4;
                        $nodulepairinfo{$r1}{$n1}{$r2}{$n2}{"SecOverlap"} = "reject";
                    }
                    if ( $vr < 1.0 ) { $vr = 1.0 / $vr; }  # make $vr > 1.0 for the comparison below
                    printf "           (adjusted) volume ratio: %.3f \n", $vr if $verbose >= 4;
                    if ( $vr > $VRthr ) {
                        print "             * rejected based on the volume ratio criterion \n" if $verbose >= 4;
                        $nodulepairinfo{$r1}{$n1}{$r2}{$n2}{"SecOverlap"} = "reject";
                    }
                }  # end of for using $n2
            }  # end of for using $r2
        }  # end of if for $n1
    }  # end of if for $r1
    print "\n" if $verbose >= 4;
    
    print "\ndump of the \%nodulepairinfo hash...\n", Dumper(%nodulepairinfo), "\n" if $verbose >= 5;
    
    # Nodules that have been marked as "reject" should be removed from %noduleremap ...
    # But it's a bit more complicated than that. An example: Nodules A and B are rejected
    # based on the secondary matching criteria but B and C are accepted, so B should be retained
    # and A would be removed (unless it overlaps with another nodule).
    print "Coalesce the accept/reject status of all nodules that comprise each re-assigned (SNID) nodule...\n" if $verbose >= 4;
    my %acceptreject;
    for my $r1 ( keys %nodulepairinfo ) {
        for my $n1 ( keys %{$nodulepairinfo{$r1}} ) {
            for my $r2 ( keys %{$nodulepairinfo{$r1}{$n1}} ) {
                for my $n2 ( keys %{$nodulepairinfo{$r1}{$n1}{$r2}} ) {
                    # initialize each element to indicate 0 rejections:
                    if ( !$acceptreject{$r1}{$n1} ) { $acceptreject{$r1}{$n1} = 0 }
                    if ( !$acceptreject{$r2}{$n2} ) { $acceptreject{$r2}{$n2} = 0 }
                    if ( $nodulepairinfo{$r1}{$n1}{$r2}{$n2}{"SecOverlap"} eq "reject" ) {
                        print "  Nodule pair marked \"reject\" in the secondary matching test: $r1 / $n1 and $r2 / $n2 \n" if $verbose >= 4;
                        my $nn1 = $noduleremap{$r1}{$n1};
                        my $nn2 = $noduleremap{$r2}{$n2};
                        if ( $nn1 != $nn2 ) {
                            #""" User message doc: 6907: An internal error in remapping has been detected in secondary matching.
                            msg_mgr (
                                severity => 'FATAL',
                                msgid => 6907,
                                appname => 'MAX',
                                subname => (caller(0))[3],
                                line => __LINE__ - 6,
                                text => 'An internal error in remapping has been detected in secondary matching.',
                                accum => 1,
                                verbose => 1,
                                code => $Site_Max::RETURN_CODE{internalerror}
                            );
                        }
                        $acceptreject{$r1}{$n1} += 1;
                        $acceptreject{$r2}{$n2} += 1;
                        print "    These were remapped to nodule $nn1 which includes these original nodules: " if $verbose >= 4;
                        my @rarr = keys %{$noduleremaprev{$nn1}};
                        for my $r ( @rarr ) {
                            for my $n ( keys %{$noduleremaprev{$nn1}{$r}} ) {
                                print "$r / $n   " if $verbose >= 4;
                            }  # end of for using $r
                        }  # end of for using $r
                        print "\n" if $verbose >= 4;
                    }  # end of if testing for "reject"
                }  # end of for using $n2
            }  # end of for using $r2
        }  # end of for using $n1
    }  # end of for using $r1
    print "\ndump of the \%acceptreject hash (divide these counts by 2 before use)...\n", Dumper(%acceptreject), "\n" if $verbose >= 5;
    print "\"Rejection\" counts...\n" if $verbose >= 4;
    for my $nn ( keys %noduleremaprev ) {
        my $non = scalar ( keys %{$noduleremaprev{$nn}} );  # no. of orig. nodules that where matched to form the new nodule (SNID)
        print "  for SNID $nn (comprised of $non original nodules)...\n" if $verbose >= 4;
        my @rarr = keys %{$noduleremaprev{$nn}};
        for my $r ( @rarr ) {
            for my $n ( keys %{$noduleremaprev{$nn}{$r}} ) {
                if ( $acceptreject{$r}{$n} && ( $acceptreject{$r}{$n} > 0 ) ) {
                    my $count = $acceptreject{$r}{$n} / 2;
                    print "    original $r / $n has $count count(s) \n" if $verbose >= 4;
                    if ( $count == ($non - 1) ) {
                        # it has rejected against all other nodules in this group
                        print "      - remove this nodule \n" if $verbose >= 4;
                        delete($noduleremap{$r}{$n});
                        $noduleremaprev{$nn}{$r}{$n} = 0;  # unflag this one
                        # keep a list of rejected nodules for later use
                        $rejectednodules{$r}{$n} = $nn;
                    }  # end of if to check value of $count
                }  # end of checking %acceptreject{}{}
                else {
                print "    original $r / $n -- no rejections\n" if $verbose >= 4;
                }  # end of if to check contents of %acceptreject
            }  # end of loop over $n
        }  # end of loop over $r
    }  # end of loop over $nn
    # ? What should we do with the removed nodules ?...
    #   - Just forget about them.
    #       ...probably not
    #   - Give them new nodule numbers (SNIDs).
    #       ...probably not
    #   - See if they should be included with another group of nodules that have been re-assigned to a new nodule (SNID).
    #       ...most likely
    # ?  Or maybe we shouldn't even be "removing" them!...
    print "\ndump of the \"adjusted\" \%noduleremap hash...\n", Dumper(%noduleremap), "\n" if $verbose >= 5;
    print "\ndump of the \"adjusted\" \%noduleremaprev hash...\n", Dumper(%noduleremaprev), "\n" if $verbose >= 5;
    print "\ndump of the \%rejectednodules hash...\n", Dumper(%rejectednodules), "\n" if $verbose >= 5;
    # Since we've deleted in %noduleremap and unflagged in %noduleremaprev, we need
    # to re-assign new nodules in %noduleremap and re-generate %noduleremaprev 
    print "indexing thru \%noduleremap to find SNID assignments...\n" if $verbose >= 4;
    my $nnnn = 0;   # initialize the new SNID
    my %nnlist;
    for my $r ( keys %noduleremap ) {
        for my $n ( keys %{$noduleremap{$r}} ) {
            my $nnn = $noduleremap{$r}{$n};
            print "  looking at $r / $n which formerly remapped to $nnn \n" if $verbose >= 4;
            if ( !$nnlist{$nnn} ) {
                $nnnn++;
                $nnlist{$nnn} = $nnnn;
                print "    $nnn becomes $nnnn \n" if $verbose >= 4;
            }
        }
    }
    print "remap nodule numbers and generate the reversed hash...\n" if $verbose >= 4;
    my %tempremap = %noduleremap;
    %noduleremap = ();
    %noduleremaprev = ();
    for my $r ( keys %tempremap ) {
        for my $n ( keys %{$tempremap{$r}} ) {
            $noduleremap{$r}{$n} = $nnlist{$tempremap{$r}{$n}};
            print "  $r / $n remaps to $noduleremap{$r}{$n} \n" if $verbose >= 4;
            my $nn = $noduleremap{$r}{$n};
            # re-populate a reversed version of %noduleremap for later use:
            $noduleremaprev{$nn}{$r}{$n} = 1;  # store an arbitrary value as a flag
        }
    }
    print "\ndump of the cleaned-up \%noduleremap hash...\n", Dumper(%noduleremap), "\n" if $verbose >= 5;
    print "\ndump of the recomputed \%noduleremaprev hash...\n", Dumper(%noduleremaprev), "\n" if $verbose >= 5;
    
    # *MORE* additional measures to add: relative or percent overlapping volumes.  Might want to 
    # do this when we are indexing thru %contours (?) finding simple overlap in the initial check.
    
    #""" User message doc: 3105: Secondary matching has been performed.
    # Generate a status message for insertion into @main::msglog
    msg_mgr (
        severity => 'INFO',
        msgid => 3105,
        text => my $text = ( sprintf "Secondary matching has been performed." ),
        accum => 1,
        screen => 0,  # doesn't need to be displayed on the screen
        code => -1
    );

    return;
    
}  # end of sub secondary_matching


sub pmap_calcs {
    
    print "\n\n================= Perform pmap operations ================= \n\n" if $verbose >= 1; 
    
    #print "+++ flags: \$createpmapxml and \$xmlpmaps   $createpmapxml  $xmlpmaps\n";  # testing
    
    # Be sure that we have an even number of readers so that the median pmap volume calcs make sense:
    if ( NUMREADERS % 2 != 0 ) { 
        #""" User message doc: 5406: Odd number of readers.
        msg_mgr (
            severity => 'ERROR',
            msgid => 5406,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => 'We have detected an odd number of readers; need an even number for the pmap median volume measure.',
            screen => 1,
            accum => 1,
            code => -1
        );
    }
    my $pmapmedianvolthr = NUMREADERS / 2;  # but see the above check
    
    # Initialize the pmapinfo hash:
    # some "global" info...
    $pmapinfo{'numreaders'} = $numreaders;  # the number of participating readers
    $pmapinfo{'xoffset'} = $offsetx;  # bounding box offsets
    $pmapinfo{'yoffset'} = $offsety;  # found earlier while
    $pmapinfo{'zoffset'} = $offsetz;  # indexing thru %contours
    # for each nodule...
    foreach my $nn (keys %noduleremaprev) {
        # setup a bounding box for each nodule in the pmap...
        $pmapinfo{$nn}{'xmin'} = 1000000;  # these min/max
        $pmapinfo{$nn}{'xmax'} = -1;       # will be set
        $pmapinfo{$nn}{'ymin'} = 1000000;  # correctly
        $pmapinfo{$nn}{'ymax'} = -1;       # in the loop
        $pmapinfo{$nn}{'zmin'} = 1000000;  # below
        $pmapinfo{$nn}{'zmax'} = -1;
        # the number of readers that marked this nodule...
        $pmapinfo{$nn}{'nummarked'} = scalar(keys %{$noduleremaprev{$nn}});
    }
    
    # Index spatially thru %contours1.  At each x,y,z location, index thru all readers and collect the nodule IDs in the INCL layer (only!)...
    for $xindex ( keys %contours1 ) {
        for $yindex ( keys %{$contours1{$xindex}} ) {
            for $zindex ( keys %{$contours1{$xindex}{$yindex}} ) {
                my @stack = ($OMITTHIS, $OMITTHIS, $OMITTHIS, $OMITTHIS);  # initialize it
                for $rindex ( keys %{$contours1{$xindex}{$yindex}{$zindex}} ) {
                    # We only need to look in the INCL layer which has by this point been "corrected" for exclusions,
                    # plus it does *not* contain anything about small nodules which are in the SMLN layer and which
                    # are not to be included in the pmaps according to Impl. Group specs.
                    if ( defined $contours1{$xindex}{$yindex}{$zindex}{$rindex}{INCL} ) {
                        $stack[$rindex] = $contours1{$xindex}{$yindex}{$zindex}{$rindex}{INCL};
                    }
                }
                #print "elements in \@stack for readers 0..3: $stack[0] $stack[1] $stack[2] $stack[3] \n";
                # The contents of @stack drives the filling of %pmap...
                my $count = scalar( grep { $_ ne $OMITTHIS } @stack ); # get the count (the number of overlaps at this x,y,z) for the pmap
                if ( $count > 0 ) {
                    # Find the reader at the first "significant" element in the stack.  (We don't need 
                    #   to find all readers -- only the first because this is sufficient to find
                    #   the new nodule number -- the SNID.)
                    my $reader = 0;
                    until ( $stack[$reader] ne $OMITTHIS ) { ++$reader }
                    # Be sure $reader wasn't incremented too much...
                    if ( $reader > ($numreaders-1) ) {
                        #""" User message doc: 6904: Internal error in building the pmap.
                        msg_mgr (
                            severity => 'FATAL',
                            msgid => 6904,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => 'Internal error in building the pmap.',
                            accum => 1,
                            verbose => 1,
                            code => $Site_Max::RETURN_CODE{internalerror}
                        );
                    }
                    #print "+++ for orig and SNID: $reader/$stack[$reader] $noduleremap{$reader}{$stack[$reader]}  at: $xindex $yindex $zindex  count is $count \n";
                    if ( $noduleremap{$reader}{$stack[$reader]} ) {
                        my $nnn = $noduleremap{$reader}{$stack[$reader]};  # look-up the SNID based on this reader
                        $pmap{$nnn}{$zindex}{$yindex}{$xindex} = $count;  # store the count in the pmap hash
                        # update the pmap bounding box:
                        if ( $xindex < $pmapinfo{$nnn}{'xmin'} ) { $pmapinfo{$nnn}{'xmin'} = $xindex; }
                        if ( $xindex > $pmapinfo{$nnn}{'xmax'} ) { $pmapinfo{$nnn}{'xmax'} = $xindex; }
                        if ( $yindex < $pmapinfo{$nnn}{'ymin'} ) { $pmapinfo{$nnn}{'ymin'} = $yindex; }
                        if ( $yindex > $pmapinfo{$nnn}{'ymax'} ) { $pmapinfo{$nnn}{'ymax'} = $yindex; }
                        if ( $zindex < $pmapinfo{$nnn}{'zmin'} ) { $pmapinfo{$nnn}{'zmin'} = $zindex; }
                        if ( $zindex > $pmapinfo{$nnn}{'zmax'} ) { $pmapinfo{$nnn}{'zmax'} = $zindex; }
                    }  # end of if for checking %noduleremap
                }  # end of checking for $count > 0
            }  # end of the $zindex loop
        }  # end of the $yindex loop
    }  # end of the $xindex loop
    print "dump of \%pmapinfo...\n", Dumper(%pmapinfo) if $verbose >= 5;
    
    # Output %pmap to stdout and/or output it in XML form to a file...
    if ( $createpmapxml ) {
        write_xml_line1 ( $pmapxml_fh );
        print $pmapxml_fh $Site_Max::TAB[0] . "<LidcPmap> \n";
        write_xml_app_header( VERSIONPMAPXML, $pmapxml_fh );
        write_xml_datainfo_header( $pmapxml_fh );
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[1] . "<PmapInfoHeader> " );
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[2] . "<NumberOfReaders>$numreaders</NumberOfReaders>");
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[2] . "<OverallBoundingBox xoffset=\"$offsetx\" yoffset=\"$offsety\" zoffset=\"$offsetz\"/>" );
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[2] . "<PmapComments></PmapComments> " );
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[1] . "</PmapInfoHeader> " );
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[1] . "<Pmaps> " );
    }
    print "index through \%pmap:\n" if $verbose >= 5;
    # (This is potentially a BIG hash, so we'll index thru it ourselves rather than use Dumper so we can control the formatting better.)
    foreach my $nn (keys %noduleremaprev) {
        my $numpmapslices = scalar(keys%{$pmap{$nn}});  # Use this to control whether we write-out the <PmapData></PmapData> tag block.
        print "  The pmap for SNID $nn contains $numpmapslices slice(s). \n" if $verbose >= 5;
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[2] . "<PmapData> " ) if ( $createpmapxml && $numpmapslices > 0 );
        my @rarr = keys %{$noduleremaprev{$nn}};
        print "    ", scalar(@rarr), " reader(s) for SNID $nn (original reader/ID: " if $verbose >= 5;  # start a new line
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[3] . "<MatchedNoduleInfo> " ) if ( $createpmapxml && $numpmapslices > 0 );
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[4] . "<Constituents> " ) if ( $includeconstituents && $numpmapslices > 0 );
        for my $r ( @rarr ) {
            for my $n ( keys %{$noduleremaprev{$nn}{$r}} ) {
                print "$r/$n " if $verbose >= 5;  # add to the line
                accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[5] . "<Object type=\"nodule\" reader=\"$servicingRadiologist[$r]\" id=\"$n\" sizeclass=\"large\"/>" ) if ( $includeconstituents && $numpmapslices > 0 );
            }
        }
        if ( $createpmapxml && $numpmapslices > 0 ) {
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[4] . "</Constituents> " ) if $includeconstituents;
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[4] . "<SeriesNoduleID value=\"$nn\"/> " );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[3] . "</MatchedNoduleInfo> " );
            #print $pmapxml_fh $Site_Max::TAB[3] . "<NoduleBoundingBox xoffset=\"$pmapinfo{$nn}{'xmin'}\" yoffset=\"$pmapinfo{$nn}{'ymin'}\" zoffset=\"$pmapinfo{$nn}{'zmin'}\" xsize=\"\" ysize=\"\" zsize=\"\"/> \n";
        }
        print "):\n" if $verbose >= 5;  # finish the line
        # We will compute some volumes based on various voxel counts as we index thru the pmap:
        # Initialize the counters:
        my $pmapcount_raw = 0;  # raw volume count
        my $pmapcount_med = 0;  # median volume count
        # "index" thru %pmap{} in z, y, x order...
        foreach $zindex ( keys %{$pmap{$nn}} ) {
            my @xylines = ();  # initialize it to empty as we begin each slice
            foreach $yindex ( keys %{$pmap{$nn}{$zindex}} ) {
                foreach $xindex ( keys %{$pmap{$nn}{$zindex}{$yindex}} ) {
                    my $count = $pmap{$nn}{$zindex}{$yindex}{$xindex};
                    if ( $count ) {
                        print $count if $verbose >= 5;  # add to the line of pmap contents on stdout
                        # Accumulate count lines for this z slice; use non-offset x & y coords.  The resultant XML line looks something like this:
                        #     <Count x="123" y="321">3</Count>
                        my $line = sprintf ( "%s<Count i=\"%d\" j=\"%d\">%d</Count>", $Site_Max::TAB[4], ($xindex+$offsetx), ($yindex+$offsety), $count );
                        push @xylines, $line if $createpmapxml;
                        $pmapcount_raw++;
                        $pmapcount_med++ if $count >= $pmapmedianvolthr;
                    }  # end of if for $count
                }  # end of x
            }  # end of y
            ##print "\$zindex $zindex\n";  # testing
            ##print "\$allz[\$zindex] $allz[$zindex]\n";  # testing
            ##print "\$z2siu{\$allz[\$zindex]} $z2siu{$allz[$zindex]}\n";  # testing
            my $open = sprintf ( "%s<Slice k=\"%d\" z=\"%.3f\" sopinstanceuid=\"%s\">", $Site_Max::TAB[3], $zindex, $allz[$zindex], $z2siu{$allz[$zindex]} );
            my $close = sprintf ( $Site_Max::TAB[3] . "</Slice>" );
            @xylines = ( $open , @xylines, $close ) if ( @xylines && $createpmapxml );  # sandwich the count tags with <Slice> tags if there are any count tag lines
            foreach ( @xylines ) {
                accum_xml_lines ( 'pmap', \%xml_lines, $_ ) if ( @xylines && $createpmapxml );  # output ALL the lines for this z slice
            }
        }  # end of z
        # Add the volume measures lines to the XML file:
        if ( $createpmapxml && $numpmapslices > 0 ) {
            my $vol_line;
            my $vox_vol = $pixeldim * $pixeldim * $slicespacing;
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[3] . '<VolumeMeasures>' );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[4] . '<Measure description="gross volume">' );
            $vol_line = sprintf ( '<VoxelCount value="%d" units="voxels"/>', $pmapcount_raw );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[5] . $vol_line );
            $vol_line = sprintf ( '<PhysicalVolume value="%.1f" units="mm^3"/>', $pmapcount_raw * $vox_vol );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[5] . $vol_line );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[4] . '</Measure>' );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[4] . '<Measure description="median/threshold=2">' );
            $vol_line = sprintf ( '<VoxelCount value="%d" units="voxels"/>', $pmapcount_med );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[5] . $vol_line );
            $vol_line = sprintf ( '<PhysicalVolume value="%.1f" units="mm^3"/>', $pmapcount_med * $vox_vol );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[5] . $vol_line );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[4] . '</Measure>' );
            accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[3] . '</VolumeMeasures>' );
        }
        print "\n" if keys %{$pmap{$nn}} && $verbose >= 5;
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[2] . "</PmapData> " ) if ( $createpmapxml && $numpmapslices > 0 );
    }  # end of nn
    if ( $createpmapxml ) {
        # Finish-up the pmap XML:
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[1] . "</Pmaps> " );
        accum_xml_lines ( 'pmap', \%xml_lines, $Site_Max::TAB[0] . "</LidcPmap> " );  # the last line of XML
        write_xml_lines ( 'pmap', \%xml_lines, $pmapxml_fh );  # dump the hash to file
    }
    if ( $createpmapxml ) {
        # We are finished writing XML...
        #close $pmapxml_fh or do { $? = $Site_Max::RETURN_CODE{xmloutfileerror} << 8; die "Error [6309] in closing $pmapxmlfile: $!.  Stopped" };  # %%!!FATAL!!%% -- in sub pmap_calcs
        print "pmap data have been saved as an XML file: $pmapxmlfile \n" if $verbose >= 2;
    }
    print "\n\n" if $verbose >= 5;
    
    #""" User message doc: 3104: pmaps have been calculated.
    # Generate a status message for insertion into @main::msglog
    msg_mgr (
        severity => 'INFO',
        msgid => 3104,
        text => my $text = ( sprintf "pmaps have been calculated." ),
        accum => 1,
        screen => 0,  # doesn't need to be displayed on the screen
        code => -1
    );

    return;
    
}  # end of routine pmap_calcs()


# ====================================================================
# =                                                                  =
# =        M I N O R / U T I L I T Y   S U B R O U T I N E S         =
# =                                                                  =
# ====================================================================
sub section200__utility_subs {}  # a dummy sub that lets us jump to this location via the function list in our editor


sub msg_mgr {
# A sub that manages various messages to be sent to the user and saved in a global message array.
#
# Arguments are given as values to these hash keys:
#   KEYS         COMMENTS
#   severity     examples: DEBUG, INFO, WARNING, ERROR, FATAL
#   msgid        a unique 4-digit integer
#   appname      usually 'MAX' (optional)
#   subname      the name of the sub where the message is generated (optional)
#   line         usually set to the Perl variable __LINE__ (optional)
#   text         a (formatted) string containing the message
#   accum        add to the global messages array
#   screen       output to the screen
#   verbose      output to the screen if the global $verbose is >= this number  (In general, we
#                  use verbose level 1 for FATAL and ERROR, 2 for WARNING, and 3 everything else.)
#   before and after
#                no. of extra \n to insert before and after for screen output
#   code         status code (set to -1 for return to caller)
#   dontcleanup  don't cleanup leading, trailing and extra spaces in the location string
#
#   User messages are uniquely identified by 4-digit integers (the msgid key above).  These
#   supplement the descriptive phrases that are associated with messages and allow specific
#   action to be taken for each message.
#     
#     1st digit - severity or level of the message:
#     1000 - other
#     2000 - debug
#     3000 - information
#     4000 - warning
#     5000 - error (non-fatal)
#     6000 - fatal
#     
#     2nd digit - type of message:
#     100 - other
#     200 - command line
#     300 - file/directory access
#     400 - file content
#     500 - data parsing, interpretation, usage
#     600 - matching
#     700 - ambiguity
#     900 - internal error
#     
#     The 3rd and 4th digits enumerate specific messages beginning with 01 (00 represents
#     unspecified).
#     
#     0000 represents an unspecified message code.
#     
#     For example, "5407" represents an error ("5") related to file content ("4"); it is numbered
#     "07" within these categories.
#
# See also/instead Log::Dispatch (CPAN)
#
# Copy/paste from the following template -- but not all options are shown:
=begin template=
        #""" User message doc: idnum: Some text.
        msg_mgr (
            severity => 'DEBUG,INFO,WARNING,ERROR,FATAL',
            msgid => ,
            appname => 'MAX',
            subname => (caller(0))[3],  # MUST omit this when calling from main!
            line => __LINE__ - 6,
            text => '',
            text => my $text = ( sprintf... ),
            before => 1,
            after => 2,
            accum => 1,
            verbose => 3,
            code => $Site_Max::RETURN_CODE{error} OR -1
        );
=cut template=
    
    my %msg = @_;
    
    # Set the defaults:
    my ( $before, $after ) = ( 0, 1 );  # number of \n to be added before and after the message displayed to the screen
    my ( $severity, $appname, $subname, $line, $text ) = ( '', '', '', '', '', '' );
    my ( $msgid ) = '0000';
    my ( $location ) = ( '' );
    my ( $screen, $accum ) = ( 1, 0 );  # flags: the message goes to the screen and/or accumulated in @main::msglog
    my ( $verbthr ) = ( -1 );
    my ( $code ) = -1;
    
    # Get the values that exist:
    $before   = $msg{before}   if exists $msg{before};
    $after    = $msg{after}    if exists $msg{after};
    $screen   = $msg{screen}   if exists $msg{screen};  # && $msg{screen};
    $accum    = $msg{accum}    if exists $msg{accum};   # && $msg{accum};
    $verbthr  = $msg{verbose}  if exists $msg{verbose};
    $severity = $msg{severity} if exists $msg{severity};
    $msgid    = $msg{msgid}    if exists $msg{msgid};
    $text     = $msg{text}     if exists $msg{text};
    $code     = $msg{code}     if exists $msg{code};
    
    # Start formatting the output:    
    $appname = 'in '        . $msg{appname} if exists $msg{appname};
    $subname = 'in sub '    . $msg{subname} if exists $msg{subname};
    $subname =~ s/main:://                  if exists $msg{subname};  # clean it up a bit
    $line    = 'near line ' . $msg{line}    if exists $msg{line};
    $location = $appname . ' ' . $subname . ' ' . $line;
    $location = cleanup($location) unless exists $msg{dontcleanup};
    
    my $str = sprintf ( '%s[%s] (%s): %s', $severity, $msgid, $location, $text );   # Changed from "my $str = sprintf ( $severity . '[' . $msgid . ']' . ' (' . $location . '): ' . $text );" by Tom Lampert
    print "\n" x $before . $str . "\n" x $after if ( $screen && $verbose >= $verbthr );
    push @main::msglog, $str if $accum;
    
    return if $code == -1;
    exit $code;
}


sub cleanup {
    my ( $str ) = @_;
    $str =~ s/^\s+|\s+$//g;  # remove leading and trailing spaces
    $str =~ s/ +/ /g;  # change multiple spaces to singles
    return $str; 
}


sub show_zlist {

    my @allnnn = ( @zcoordsallnods, @zcoordsallnonnods );

    # Use zuni to sort and cull the list of z coords that have been found.
    ( my $dummy, @allnnn ) = zuni(@allnnn);

    # We show this list so that the user can use it to make a guess at the slice spacing if desired.
    print "We found the indicated number of nodule and non-nodule markings at the following Z coordinates:\n";
    print " Z coords (mm.) nods  non-nods   del-z = | z(i) - z(i-1) | \n";
    print " -------------- ----  --------   ------------------------- \n";
    my $prevz;
    my $delz;
    foreach my $z ( @allnnn ) {
        my $numnods = scalar ( grep { approxeq ( $_, $z, ZSPACINGTOLFILLIN) } @zcoordsallnods );
        my $numnons = scalar ( grep { approxeq ( $_, $z, ZSPACINGTOLFILLIN) } @zcoordsallnonnods );
        $delz = abs ( $z - $prevz ) if $prevz;
        $prevz = $z;
        printf "    %.3f \t %d \t %d \t\t %s \n", $z, $numnods, $numnons, ( $delz ? round ( $delz, NUMDIGRND ) : ' ' );
    }

}


sub infer_spacing {
# Looks at the deltas in the Z coords of the slices of the input
# array and reports the minimum delta-Z which may be used as an indicator of the slice
# spacing for the set of slices.  The confidence of this inference can be judged to a limited
# extent by the number of times that it appears compared with the total number of slices
# that were examined -- both of which are returned by this sub.
#
# Calling sequence:
#   infer_spacing( @arr_of_z_coords )
# Returns:
#   the smallest delta-Z (a positive number) (in mm.)
#   the number of times it occurred
#   the total number of distinct Z coords examined
# 
    
    my @allnnn = ( @zcoordsallnods, @zcoordsallnonnods );
    # Use zuni to sort and cull the list of z coords that have been found.
    ( my $dummy, @allnnn ) = zuni(@allnnn);
    
    my $prevz;
    my $delz;
    my @delz_arr;
    my ( $smallest_delz, $num_occurs ) = ( -1, -1 );
    my $numslices = scalar ( @allnnn );
    
    return ( $smallest_delz, $num_occurs, $numslices ) if $numslices < 2;
    
    foreach my $z ( @allnnn ) {
        if ( $prevz ) {
            $delz = abs ( $z - $prevz );
            push @delz_arr, round ( $delz, NUMDIGRND );
        }
        $prevz = $z;
    }
    
    @delz_arr = sort { $a <=> $b } @delz_arr;
    $smallest_delz = $delz_arr[0];
    $num_occurs = scalar ( grep { $_ == $smallest_delz } @delz_arr );
    print "In sub infer_spacing: The smallest delta-Z of $smallest_delz mm. appears $num_occurs times (out of $numslices total available Z coords.)\n" if $verbose >= 7;
    
    return ( $smallest_delz, $num_occurs, $numslices );
    
}


sub zuni {

# "Z uniformity"
# Operate on the a z coords array:
#  * cull repeated elements from the array
#  * sort the array
#  * calculate the Z uniformity of the slices from it
# Side-effects:
#  * The input array is culled and sorted and returned.
#  * A string describing the Z uniformity is returned:
#      "uniform", "nonuniform", or "indeterminate" (if there are fewer than 3 slices)
    
    my @zcoords = @_;  # pickup the argument (the coord array)
    my $index = 0;
    my $unifstr = "uniform";  # assume uniform but change it below depending on what we find
    my @retarr;
    
    # this uniqueness code is adapted from recipe 4.7.2.2 in the Cookbook
    my %seen = ( );
    my @uniq;
    foreach my $item (@zcoords) {
        # Try to eliminate unimportant differences that arise from differences in precision of
        # the z coords: "123.0" and "123.000" are the same for our purposes of comparison here
        # as are "122.999999" and "123.00".
        $item = round ( $item, NUMDIGRND );
        push(@uniq, $item) unless $seen{$item}++;
    }
    
    @zcoords = sort {$a <=> $b} @uniq;  # numeric sort back into @zcoords
    
    print "dump of \@zcoords (sorted and culled Z coords) (in routine zuni):\n", Dumper(@zcoords) if $verbose >= 6;
    
#     if ( scalar(@zcoords) < 3 ) {
#         $unifstr = "indeterminate";  # Uniformity of spacing can't be determined for 0, 1, or 2 slices.
#         # ...but slice spacing (in mm., for example) *can* be determined by the caller if desired if there
#         # are two slices: $spacing = $zcoords[1] - $zcoords[0];
#     }
    if ( scalar(@zcoords) <= 1 ) {
         $unifstr = "indeterminate";  # Uniformity of spacing can't be determined for 0 or 1 slices.
    }
    elsif ( scalar(@zcoords) == 2 ) {
         $unifstr = "uniform";  # We'll go ahead and say that slices are uniform for 2 slices.
    }
    else {  # we have 3 or more slices...
        foreach (@zcoords) {
            # we can only do the following when we're on the 3rd or greater coord...
            if ( $index > 1 ) {
                my $coord1 = $zcoords[$index-2];
                my $coord2 = $zcoords[$index-1];
                my $coord3 = $zcoords[$index];
                $unifstr = "nonuniform" if ( abs ( ($coord3-$coord2)/($coord2-$coord1) - 1 ) > ZSPACINGTOL );
            }
            $index ++;
        }
    }
    
    push @retarr, $unifstr; push @retarr, @zcoords; 
    return @retarr;
    
}


sub gen_slices {

# Generate an array @allz (which is passed back the the caller) of contiguous z coords of slices that 
# include the z coords in the input array @zarr (which are, in general, coords of non-contig slices).
# Also generate and pass back an array that contains indices of elements of @allz that match the coords
# of @zarr.  Schematically:
#
# @zarr:  10.0  12.0  14.0  16.0              22.0  24.0                    32.0        36.0  38.0  40.0
#           |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
# @allz:  10.0  12.0  14.0  16.0  18.0  20.0  22.0  24.0  26.0  28.0  30.0  32.0  34.0  36.0  38.0  40.0
#           |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
# indices
# of @allz: 0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15
#
# contents of @zmatch: 0 1 2 3 6 7 11 13 14 15

# Side-effect: The input array is sorted and culled (by sub zuni).
    
    my @zarr = @_;  # get the input array of z coords
    # another "input" parameter: $slicespacing (it's a global var)
    
    # returned to the caller along with @zarr
    my @allz = ();
    my @zmatch = ();
    
    # "local" vars:
    my $unifstr;  # this is returned by sub zuni but it's not otherwise used in this sub
    my $z;  # z coord (in mm.)
    my $i;  # an index that enumerates the generated slices in @allz
    my $matcherror = 0;  # this flags duplicate hits
    my $trouble = 0;  # an error detection flag
    my $totalmatches = 0;  # used only in a local print stmt.
    
    # Call zuni to sort and cull the z coords list:
    ($unifstr,@zarr) = zuni(@zarr);
    print "In sub gen_slices: dump of \@zarr ...\n", Dumper(@zarr) if $verbose >= 5;
    
    print "In sub gen_slices, we will go from z = $zarr[0] to $zarr[-1] \n" if $verbose >= 5;
    
    $trouble = 1 if $slicespacing < 0.0;  # this will ultimately cause us to take the error exit (msgid = 6503) 
    
    # Set these 2 vars to get us started:
    $z = $zarr[0];
    $i = 0;
    # Loop until we fall off the end of @zarr or until we detect a problem in the loop:
    until ( ( $z > ( $zarr[-1] + $slicespacing ) ) || $trouble ) {
        my $zrnd = round ( $z, NUMDIGRND );
        # Storing the rounded version of $z in @allz and generating the next $z (see below) are
        # the basic operations of this sub.  The remainder is error checking.
        push @allz, $zrnd;
        print "$i: \$z = ", $zrnd if $verbose >= 6;  # Start an output line.  Note: no \n at the end; we do this later.
        # See if we have a match between the currently generated z coord and a z coord in @zarr.
        # This is a sort of sanity check.  Finding 0 or 1 match is OK; finding multiple matches is an error.
        my $occurred = 0;  # a local counter to detect multiple matches
        # So for each $z, we loop through @zarr...
        foreach ( @zarr ) {
            if ( approxeq($z, $_, ZSPACINGTOLFILLIN) ) {
                print " // this \$z matches $_ which is an element in the z coords array \@zarr // " if $verbose >= 6;  # add to the line started above
                $occurred++;
                $totalmatches++;
                push @zmatch, $i;  # accumulate the indices of @allz where there are matches with @zarr
            }
        }  # end of the loop through @zarr
        # At the completion of looping thru @zarr, check the various values of occurrance...
        if ( $occurred == 0 ) {
            print " +++ a generated z coord with no corresponding z data " if $verbose >= 6;  # add to the line started above
        }
        elsif ( $occurred == 1 ) {
            print " +++ matches z data exactly once " if $verbose >= 6;  # add to the line started above
        }
        elsif ( $occurred > 1 ) {
            print " +++ a duplicate match with z data !!! " if $verbose >= 6;  # add to the line started above
            $matcherror = 1;  # this will trigger a fatal error below
        }
        print "\n" if $verbose >= 6;  # finish the line started above
        # get ready for the next iteration/test in the until loop
        $i++;
        $trouble = 1 if $i > 2000;  # trigger a fatal error if we try to generate too many slices (2000 is a "magic number" -- fairly arbitrary)
        $z = $i * $slicespacing + $zarr[0];
    }  # end of the until loop
    
    print "In sub gen_slices \@zarr contains ", scalar(@zarr)," members and we found $totalmatches matches to them.\n" if $verbose >= 5;
    
    print "In sub get_slices -- \$trouble & \$matcherror: $trouble & $matcherror \n" if $verbose >= 6;
    $trouble = $trouble || $matcherror;
    if ( $trouble ) {
        #""" User message doc: 6503: An error occurred in filling-in the Z coords.
        msg_mgr (
            severity => 'FATAL',
            msgid => 6503,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => 'An error occurred in filling-in the Z coords.',
            accum => 1,
            verbose => 3,
            code => $Site_Max::RETURN_CODE{zinfoerror}
        );
    }
    
    return (\@zarr, \@allz, \@zmatch);  # note the use of "\@" since we want the arrays to remain separate
    
}


sub get_index {
# Find the position in the array of the specified value.
    my ($val,@arr) = @_;
    my $i = 0;
    my $idx = -1;
    foreach ( @arr ) {
        # Check each array element for a match:
        # (may want to replace approxeq with a closest match operator to make this more robust against floating point equality uncertainty and rounding)
        if ( approxeq ( $_, $val, ZSPACINGTOLFILLIN ) ) {
            $idx = $i;
            last;
        }
        $i++;
    }
    return $idx;
}


sub simpleplot {
    
    # Calling protocol:
    #   simpleplot(\@xdata,\@ydata);
    # The data arrays are assumed to be the same length; no checking is done.
    
    my ($arr1,$arr2) = @_;  # note the use of $ even though they are arrays
    
    my ( $ScrFh, $ScrFile ) = tempfile( UNLINK => 1 );
    
    # The file attached to this filehandle will be used to accumulate the plot
    # commands and data to plot.
    open ($ScrFh, ">".$ScrFile);
    
    # some preliminaries...
    print $ScrFh "set style line 1 lt 1 lw 2 pt 7 ps 1.5 \n";  # for the lines & points
    print $ScrFh "set style line 2 lt 6 lw 1             \n";  # for the grid: lt 6 => brown & lt 3 ==> blue
    print $ScrFh "unset key \n";
    print $ScrFh "unset border \n";
    print $ScrFh "set bmargin 5 \n";
    print $ScrFh "set size ratio -1 \n";
    print $ScrFh "set grid linestyle 2 \n";
    print $ScrFh "set xtics 1 \n";
    print $ScrFh "set xtics nomirror rotate \n";
    print $ScrFh "set x2tics 1 \n";
    print $ScrFh "set x2tics nomirror rotate \n";
    print $ScrFh "set ytics 1 \n";
    print $ScrFh "set y2tics 1 \n";
    print $ScrFh "set yrange [] reverse \n";
    print $ScrFh "set tics out \n";
    print $ScrFh "set mouse format '%.0f' \n";
    print $ScrFh "set title \"MAX plot: nodule ID = $plotinfo_noduleID ($plotinfo_roitype) at z = $plotinfo_zcoord mm.\" \n";
    
    
    # output the plot command...
    print $ScrFh "plot \"-\" with linespoints linestyle 1 \n";
    
    # write a space-separated list of the data point pairs...
    my $i;
    foreach $i (0..@$arr1-1) {
    print $ScrFh @$arr1[$i], " ", @$arr2[$i], "\n";
    print        @$arr1[$i], " ", @$arr2[$i], "\n" if ( 0 ) ;  # for testing
    }
    # ...and terminate the list...
    print $ScrFh "e \n";
    
    # pause after the plot; press return to continue
    print ">>> Press enter to continue from the plot <<< \n";
    print $ScrFh "pause -1 \n";
    # (or omit the above and run gnuplot with "-persist" - see the GNUPLOTARGS constant in Site_Max.pl)
    
    close $ScrFh;  # most explicit closes have been eliminated (or will be executed "en masse") but leave this one
    
#@@@ Code location: UnixUtil-gnuplot
    my $gpstr = '/usr/bin/gnuplot ' . GNUPLOTARGS . ' ' . $ScrFile . ' /dev/null 2>&1';
    system ( $gpstr );
    
    return;
    
}


sub pointplot {
    
    # Calling protocol:
    #   pointplot(@data);
    # Conceptually *very* similar to sub simpleplot -- only different in plotting style (linespoints vs points).
    
    my ( @arr ) = @_;
    
    my ( $ScrFh, $ScrFile ) = tempfile( UNLINK => 1 );
    
    # The file attached to this filehandle will be used to accumulate the plot
    # commands and data to plot.
    open ($ScrFh, ">".$ScrFile);
    
    # some preliminaries...
    print $ScrFh "set nokey \n";
    print $ScrFh "set yrange [] reverse \n";
    print $ScrFh "set title \"MAX plot\" \n";
    
    # output the plot command...
    print $ScrFh "plot \"-\" with points \n";
    
    # write a space-separated list of the data point pairs...
    my $i;
    foreach $i (0..@arr-1) {
        print $ScrFh $arr[$i][0], " ", $arr[$i][1], "\n";
    }
    # ...and terminate the list...
    print $ScrFh "e \n";
    
    # pause after the plot; press return to continue
    print ">>> Press enter to continue from the plot <<< \n";
    print $ScrFh "pause -1 \n";
    
    close $ScrFh;  # most explicit closes have been eliminated (or will be executed "en masse") but leave this one
    
#@@@ Code location: UnixUtil-gnuplot
    system ("/usr/bin/gnuplot $ScrFile >/dev/null 2>&1");
    
    return;
    
}


sub fill_poly {
    
    # N.B.: This is not a perfect/consistent fill algorithm:
    #    1. It does not include all
    #       boundary points where the boundary is defined by a list of points
    #       that are not necessarily 4- or 8-connected.  But for LIDC data,
    #       the boundaries are 4- or 8-connected, so this is not a problem
    #       since we explicitly include the boundary (and explicitly remove
    #       it later as appropriate for inclusions).
    #    2. It duplicates some points but this is OK since we eventually
    #       copy from the array produced here into another array (%contours)
    #       which is indexed into as a multi-dimn array.
    
    my @poly = @_;
    my @filledpoly;
    
    my ($x,$y);
    my $in;
    my %seen;  # use this hash to keep out duplicate points
    
    my ($xmin, $ymin, $xmax, $ymax) = polygon_bbox(@poly);
    #print "in fill_poly: x: $xmin to $xmax  y: $ymin to $ymax \n";
    
    # Function polygon_contains_point (below) requires that the 1st & last points be the same in
    # the polygon array.  Guarantee this by unconditionally appending the first point to it.
    #         >>> We confirmed that this doesn't affect the pmap calcs. <<<
    my ( $first, $last ) = @poly[0,-1];
    @poly = ( @poly, [$first->[0],$first->[1]] );
    
    @filledpoly = @poly;  # include the given boundary in the fill
                          # >>> See the location in the code ("#@@@ Code location: PolyFill") that <<<
                          # >>> calls this fct for important info about handling the boundaries.   <<<
    pop(@filledpoly);  # pop off the last element since it duplicates the 1st one
    
    for $x ($xmin-1..$xmax+1) {
        for $y ($ymin-1..$ymax+1) {
            $in = polygon_contains_point([$x,$y],@poly);
            if ( $in ) {
                push(@filledpoly,[$x,$y]) unless ($seen{$x}{$y}++);
            }
        }
    }
    
    return @filledpoly;
    
}


sub remove_poly {

# There's gotta be a better way!... such as this?...
#    @other = qw(a b c);
#    @all = qw(d e f a c);
#    @test1{@all} = undef;
#    @x = grep{!exists $test1{$_}}@other;
#    print "in other but not in all: @x";
# Must adapt this to our situation of having 2 values per array element
#   by indexing into the has with something like this: $test1{$x}{$y}
# Or try something like this:
#   push(@final,[$x,$y]) unless ( grep {[$x,$y]} @filledexcl )
# where $x and $y come from @filledincl

    my @incl = @filledpoly;  # Do it this way since these are global arrays.
    my @excl = @poly;        # Pass them in this way as I had trouble doing it the right way...
    #print "dump of \@incl in remove_poly\n", Dumper(@incl);
    #print "dump of \@excl in remove_poly\n", Dumper(@excl);
    my @final;
    
    while (@incl) {
        my($xi,$yi) = @{shift(@incl)};
        #print "indexing thru \@incl: at  $xi  $yi \n";
        my @temp = @excl;  # re-initialize this array to get ready for the next while loop
        my $exclude = 0;
        while (@temp) {
            my($xe,$ye) = @{shift(@temp)};
            #print "  indexing thru (copy of) \@excl: at  $xe  $ye \n";
            if ( $xe == $xi && $ye == $yi ) { 
                $exclude = 1;
            }
        }
        if (!$exclude) { push(@final,[$xi,$yi]); }
    }
    #print "dump of \@final in remove_poly\n", Dumper(@final);
    
    return @final;
    
}


sub check_pixel_connectivity {
    # Check connectivity of the point pair
    my ( $prev_xcoord, $prev_ycoord, $xcoord, $ycoord ) = @_;
    my $del_x = abs ( $xcoord - $prev_xcoord );
    my $del_y = abs ( $ycoord - $prev_ycoord );
    return  0 if (   $del_x == 0 && $del_y == 0 );    # "0-connected" (the points coincide)
    return  4 if ( ( $del_x == 1 && $del_y == 0 ) ||
                   ( $del_x == 0 && $del_y == 1 ) );  # 4-connected
    return  8 if (   $del_x <= 1 && $del_y <= 1 );    # 8-connected
    return -1;  # anything else
}


sub check_region_connectivity {
    
    # Detect when an ROI contour (represented by the Xs) has been drawn such that is creates two
    # disconnnected regions (represented by the *s):
    #
    #    XXXXX      XXXXXXX
    #   X*****X    X*******X
    #   X******XXXX*********X      The narrowing effectively creates two separate regions.
    #    XXXXXXXXX***********X
    #             X*********X
    #              XXXXXXXXX
    
    # Create a 2D hash that is initially filled to show connectivity of the pixels.
    # Collapse it until it can be collapsed no more.  Then, the number of keys in the 1st dimension
    # is the number of separate regions.
    # This gets messy b/c this algorithm deletes single and double pixel regions from the connectivity
    # hash.  So we have added separate code to detect and count these.
    
    # N.B.: This algorithm is VEEEEEERY slow on large nodules -- to the extent that is it virtually
    #       unusable.  Consider separating the region connectivity check from the much faster
    #       pixel conn test -- or re-design the region conn test.
    
    my @arrin = @_;
    #print "dump the input array \@arrin ...\n", Dumper(@arrin), "\n";
    my @arrkeep = @arrin;
    my %conn;
    
    # Fill the initial connectivity hash:
    my $numsingles = 0;
    while ( @arrin ) {
        # get the xy that goes in the 1st key position
        my $xy1 = pop @arrin;
        # Pull x & y apart so that we can check pixel connectivity below
        my ( $x1, $y1 ) = @$xy1;
        #print "checking ($x1, $y1) \n";
        my @arr2 = @arrkeep;
        my $connected = 0;
        while ( @arr2 ) {
            # get the xy that goes in the 2nd key position
            my $xy2 = pop @arr2;
            my ( $x2, $y2 ) = @$xy2;
            #print "  comparing with ($x2, $y2) ";
            my $conn_flag = check_pixel_connectivity( $x1, $y1, $x2, $y2 );
            if ( $conn_flag == 4 || $conn_flag == 8 ) {
                #print "- connected";
                $conn{$x1.','.$y1}{$x2.','.$y2} = 1;  # set to 1 as a flag value
                $connected = 1;
            }
            #print "\n";
        }
        # Special count for lone pixels:
        if ( ! $connected ) {
            #print "  have detected a lone pixel: $x1,$y1 \n";
            $numsingles++;
        }
    }
    #print "\n";
    
    #print "index thru the connectivity hash \%conn (and do a slight amount of processing on it)...\n";
    my %doubles;
    foreach my $xy1 ( keys %conn ) {
        #print "$xy1 is connected to: \n";
        foreach my $xy2 ( keys %{$conn{$xy1}} ) {
            #print "  $xy2 \n";
            # Accumulate tentative list of pixels connected with only one other pixel:
            if ( scalar ( keys %{$conn{$xy1}} ) == 1 && $conn{$xy2}{$xy1} == 1 ) {
                #print "  have tentatively detected for a pair connected only to each other: $xy1 and $xy2 \n";
                $conn{$xy1}{$xy2} = 0;
                $doubles{$xy1}{$xy2} = 1;
            }
        }
    }
    #print "dump the connectivity hash \%conn ...\n", Dumper(%conn), "\n";
    #print "\n";
    
    # Initializations for the first time thru the loop:
    my $numregions = scalar ( keys %conn );
    my $prevnumregions = -1;  # something to get things started
    # Repeat the collapse loop until we see no more changes:
    my $numloops = 0;
    # This loop works on regions having 3 or more pixels; it deletes those with < 3 unfortunately,
    # but we've taken care of those above.
    while ( $numregions != $prevnumregions ) {
        # Use the hash's value (0 or 1) stored at each key as a flag:
        #   Set to 1 initially.
        #   Then set to 0 if an xy pair has been inserted into the other hash.
        # At the end of the loop, count the number of regions by seeing which keys contain non-zero flag vallues.
        # In any case, we don't want to delete from or add anything to the hash while iterating over it.
        #print "begin the collapse loop with $numregions regions (previously $prevnumregions) represented by the connectivity hash\n";
        $numloops++;
        foreach my $xy1 ( keys %conn ) {
            #print "see if anything needs to be collapsed under key $xy1\n";
            foreach my $xy2 ( keys %{$conn{$xy1}} ) {
                if ( exists ( $conn{$xy2} ) ) {
                    foreach my $xy3 ( keys %{$conn{$xy2}} ) {
                        #print "  populating {$xy1} from {$xy2}{$xy3}... \n";
                        if ( $xy1 ne $xy3 ) {
                            $conn{$xy1}{$xy3} = 1;  # marking it with a 1 means that $xy3 has been moved to be "under" $xy1
                            #print "    set {$xy1}{$xy3} \n"
                        }
                        if ( $xy2 ne $xy3 ) {
                            $conn{$xy2}{$xy3} = 0;  # mark $xy3 as having been moved and is no longer needed at its orig location
                            #print "    zero-out {$xy2}{$xy3} \n"
                        }
                    }
                }
            }
        }
        # Get ready for the next collapse loop:
        $prevnumregions = $numregions;
        # Count how many key pairs contain non-zero flag values
        $numregions = 0;
        foreach my $xy1 ( keys %conn ) {
            my $notcollapsed = 0;
            foreach my $xy2 ( keys %{$conn{$xy1}} ) {
                $notcollapsed = 1 if $conn{$xy1}{$xy2} != 0;
            }
            $numregions++ if $notcollapsed;
        }
        #print "at the end of the collapse loop (iteration $numloops): dump the \%conn hash ...\n", Dumper(%conn), "\n";
    }
    
    # Correct the tentative list of doubles:
    # First generate a flattened version of the connectivity hash:
    my %flat;
    foreach my $xy1 ( keys %conn ) {
        foreach my $xy2 ( keys %{$conn{$xy1}} ) {
            if ( $conn{$xy1}{$xy2} == 1 ) {
                $flat{$xy1} = 1;
                $flat{$xy2} = 1;
            }
        }
    }
    #print "dump the flattened hash \%flat ...\n", Dumper(%flat), "\n";
    #print "dump the doubles hash \%doubles ...\n", Dumper(%doubles), "\n";
    my $numdoubles = 0;
    foreach my $xy1 ( keys %doubles ) {
        foreach my $xy2 ( keys %{$doubles{$xy1}} ) {
            #print "checking $xy1 & $xy2 ...\n";
            if ( ! exists ( $flat{$xy1} ) && ! exists ( $flat{$xy2} ) ) {
                $numdoubles++;
            }
        }
    }
    
    print "There are $numregions + $numdoubles + $numsingles (large, double, single) regions represented in the connectivity hash ($numloops iterations).\n" if $verbose >= 5;
    my $grandtotal = $numregions + $numdoubles + $numsingles;
    return $grandtotal;
    
}


sub check_for_narrow_contour {
    # A simple routine to check to see if two "sides" of a contour were drawn too close to each
    # other.  That is, detect to see if there is narrowing.  This includes checking to see if
    # any 2 pixels overlap.
    #
    #      xxxx 
    #     x    x
    #     x     xxxxx  <---- This "tail" would be detected
    #      xxxxxxxxx   <---- by this routine
    #
    #    xxxxx      xxxxxxx
    #   x     x    x       x       The narrowing between the two parts of this contour would
    #   x      xxxx         x      be detected.  But this would also cause the creation of two
    #    xxxxxxxxx           x     disconnected regions which could also be detected by the
    #             x         x      check_region_connectivity routine.
    #              xxxxxxxxx
    #
    #    x x       But note that this section of a contour is *not* a narrowing because the  
    #     x x      "interior" diagonal pixels are 8-connected.  This is why the check on the  
    #      x x     deltas below at the end of the routine does *not* include 
    #       x x    ( $delx == 1 && $dely == 1 ).
    #
    #      xxxx 
    #     x    x
    #     x     xxx  <---- This spur would be detected as an overlap
    #      xxxxx
    #
    #    xxxxx        xxxxx
    #   x     x      x     x       The neck between the two parts of this contour would
    #   x      xxxxxx       x      be detected as overlap.
    #    xxxxxx    x         x
    #               x       x
    #                xxxxxxx
    #
    #
    # Returns a list:
    #   an integer:
    #     1 if no narrowness or overlapping was detected
    #     0 if narrowness or overlapping was detected
    #    -1 if there are insufficient points to make the determination
    #   a string containing coordinates of points involved in narrow sections of the contour
    #   a string containing coordinates of overlapping points
    my ( $x_arr, $y_arr ) = @_;
    # Index thru the input array of xy points.  We'll access the array with indices rather than Perl-style
    # b/c of the way we need to check the points.
    my $numpts = scalar ( @$x_arr );
    return -1 if $numpts < ( NARROWNESSSEARCHOFFSET + 3 );  # The loops below don't do anything unless there are sufficient pts
    print "        Performing narrowness check: \n" if (grep {/^narrow$/} @testlist);
    my $ret_val = 1;  # assume an "OK" return (no narrowness detected)
    my %overlapping = ();  # a 2D hash to detect overlapping points by counting how many points have the same x,y
    my %narrow = ();  # a 2D hash to keep track of points in narrow sections
    my $overlapping_coords = '';  # initialize these strings
    my $narrow_coords = '';       #  to accumulate coord lists
    # Index thru the points: normally 0 .. $numpts - 1 .  But include another -1 to skip the last one b/c it repeats the 1st
    foreach my $i ( 0 .. ( $numpts - 2 ) ) {
        # Get an xy pair and pull x & y apart
        my $x1 = @$x_arr[$i];
        my $y1 = @$y_arr[$i];
        $overlapping{$x1}{$y1} ++;
        print "  +++ looking at ($x1,$y1)...\n" if ( 0 );  # for testing
        if ( exists $overlapping{$x1}{$y1} && $overlapping{$x1}{$y1} > 1 ) {
            # We have found a pixel overlap:
            $overlapping_coords .= sprintf ( "(%s,%s) ", $x1, $y1 );  # accumulate a string to pass back to the caller
            print "          - Already found a pixel at $x1, $y1 \n" if (grep {/^narrow$/} @testlist);
            $ret_val = 0;
        }
        # In the following loop, start far enough away from the point being inspected (NARROWNESSSEARCHOFFSET points away)
        # so that we don't trigger narrowness when we get an acute angle.
        # At the end, skip the last pt b/c it repeats the 1st (as above) & skip one more to stay
        # far enough away from the 1st pt in computing the deltas.
        foreach my $j ( ( $i + NARROWNESSSEARCHOFFSET ) .. ( $numpts - 3 ) ) { 
            my $x2 = @$x_arr[$j];
            my $y2 = @$y_arr[$j];
            print "    --- compared with ($x2,$y2) \n" if ( 0 );  # for testing
            my $delx = abs ( $x1 - $x2 );
            my $dely = abs ( $y1 - $y2 );
            # See if the points are "close" to each other:
            if ( ( $delx == 1 && $dely == 0 ) || ( $delx == 0 && $dely == 1 ) ) {
                $narrow{$x2}{$y2} = 1;
                print "          - Detected narrowness at $x2, $y2 \n" if (grep {/^narrow$/} @testlist);
                $ret_val = 0;
            }
        }
    }
    print " +++ dump of \%narrow ...\n", Dumper(\%narrow), "\n\n +++ dump of \%overlapping ...\n", Dumper(\%overlapping), "\n" if ( 0 );  # for testing
    # The narrow coords require a little more processing: Don't include a coord pair in the narrow list if it
    #   is also in the overlapping list.
    for my $x ( keys %narrow ) {
        for my $y ( keys %{$narrow{$x}}) {
            #print " +++ processing ($x,$y) in \%narrow +++ \n";
            $narrow_coords .= sprintf ( "(%s,%s) ", $x, $y ) unless ( ( exists $overlapping{$x}{$y} ) && ( $overlapping{$x}{$y} > 1 ) );  # accumulate a string to pass back to the caller
        }
    }
    return ( $ret_val, $narrow_coords, $overlapping_coords );  
}


sub get_ambig_type {
    # Use @AMBIG_TYPE to discern the ambiguity type.  This is probably not an iron-clad solution;
    # thus this sub may need to be expanded to use other info to characterize ambiguity accurately.
    my ( $num_nods, $num_nons ) = @_;
    # Must clamp these before using as indices into the array due to the way that the array was set-up:
    print "in sub get_ambig_type before clamping: \$num_nods & \$num_nons = $num_nods & $num_nons\n" if ( 0 );  # for testing
    $num_nods = ( $num_nods > $maxATindex1 ? $maxATindex1 : $num_nods );
    $num_nons = ( $num_nons > $maxATindex2 ? $maxATindex2 : $num_nons );
    print "in sub get_ambig_type after clamping: \$num_nods & \$num_nons = $num_nods & $num_nons\n" if ( 0 );  # for testing
    my $type = $AMBIG_TYPE[ $num_nods ][ $num_nons ];
    if ( $type eq 'internal error' ) {
        #""" User message doc: 6908: An internal error in determining the ambiguity type has been detected.
        msg_mgr (
            severity => 'FATAL',
            msgid => 6908,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 7,
            text => 'An internal error in determining the ambiguity type has been detected.',
            accum => 1,
            verbose => 1,
            code => $Site_Max::RETURN_CODE{internalerror}
        );
    }
    return $type;
}


sub area_of_sphere {
    # surface area of a sphere given its diameter
    my ($diam) = @_;
    return PI * $diam**2.;
}


sub diam_of_sphere {
    # diameter of a sphere given its volume
    my ($vol) = @_;
    return (6.*$vol/PI)**(1.0/3.0);
}


sub dist {
    # 3D Euclidean distance
    my ($x1,$y1,$z1,$x2,$y2,$z2) = @_;
    return sqrt( ($x1-$x2)**2 + ($y1-$y2)**2 + ($z1-$z2)**2 ); 
}


sub construct_sphere {
# Construct a sphere around the specified point which is the location of a "small"
# nodule.  The voxels of the sphere are stored to be used later to allow small nodules to
# participate in matching.
    my ($r,$xc,$yc,$zc,$layer,$nn) = @_;  # 6 args: reader, (x,y,z) of point at the center of the object in the coords of the (global) %contours hash, layer number, nodule number
    print "CONSPH: in sub construct_sphere: args = @_ \n" if (grep {/^consph$/} @testlist);  # for debugging
    my $smallsphererad = $sphere_diam / 2.0;
    my $smallsphereradsq = $smallsphererad ** 2;
    # calc the deltas used to define the box within which the virtual sphere will be constructed
    my $idelta = int( $smallsphererad / $pixeldim ) + 1;  # in-plane delta in pixels
    my $kdelta = int( $smallsphererad / $slicespacing ) + 1;  # spacing between slices
    # These are for use below: Adding the offset back in ($xno -> "x no offset") takes us back to the
    #   image pixel space as it appears in the XML, so it's easier to interpret the coords in messages below.
    my $xno = $xc + $offsetx;
    my $yno = $yc + $offsety;
    print "        constructing a virtual sphere within a box of size +/- $idelta pixels in-plane and +/- $kdelta slices out-of-plane centered at $xno,$yno\n" if $verbose >= 3;
    # Store small nodule info in a hash:
    $smnodinfo{$r}{$nn} = [$xno,$yno,$zc] if $layer eq 'SMLN';
    # index thru the box
    foreach my $x ( ($xc-$idelta)..($xc+$idelta) ) {
        foreach my $y ( ($yc-$idelta)..($yc+$idelta) ) {
            foreach my $z ( ($zc-$kdelta)..($zc+$kdelta) ) {
                if ( in_the_sphere( ($x-$xc), ($y-$yc), ($z-$zc), $pixeldim, $slicespacing, $smallsphereradsq ) ) {
#@@@ Code location: ConstrSphOv
                    # Check to see if there is already a value stored at this location; if so, treat it as a warning
                    if ( defined ($contours{$r}{$x}{$y}{$z}{$layer}) ) {
                        #""" User message doc: 4504: A voxel of a constructed sphere has overwritten an existing marked voxel.
                        msg_mgr (
                            severity => 'WARNING',
                            msgid => 4504,
                            appname => 'MAX',
                            subname => (caller(0))[3],
                            line => __LINE__ - 6,
                            text => my $text = ( sprintf("For reader %s (%d) in layer %s, there is already a nodule ID of %s stored at (x,y,z) = (%d,%d[offset pixel coords],%.3f mm.); overwriting it with a nodule ID of %s", 
                            #     keep track of formats & variables: 1   2            3                                   4                       5  6                       7                                             8 ,  
                                                         $servicingRadiologist[$r], $r, $layer, $contours{$r}{$x}{$y}{$z}{$layer}, $x, $y, $allz[$z], $nn) ),
                            #                            1                          2   3       4                                  5   6   7          8
                            accum => 1,
                            verbose => 2,
                            code => -1
                        );
                    }
                    $contours{$r}{$x}{$y}{$z}{$layer} = $nn;  # store it in the desired layer of %contours (will probably always be the SMLN layer)
                    ###print "+++ writing to \%contours in construct_sphere with z = $z\n";
                    $spherez{$z} = 1 if $layer eq 'SMLN';  # we need to keep track of where we've added new points, so set a flag to mark this slice
                    print "          for reader $r and nodule $nn ... adding a point to \%contours at x,y,z = $x $y $z (offset pixel coords) in layer $layer \n" if $verbose >= 4;
                }  # end of the if that checks for being in or on the sphere
            }  # end of z
        }  # end of y
    }  # end of x
    return;
}  # end of construct_sphere


sub in_the_sphere {
# This is used by both sub construct_sphere & construct_sphere_list.  We localize the sphere calcs
# in a single sub to assure that both of these other subs implement the same decision criterion.
# N.B.: This doesn't include any round-off correction.  See the (unused) RO global variable.
    my ( $x, $y, $z, $pixel, $slice, $radsq ) = @_;
    # Compute the distance squared; to get physical distance, convert counts to distances.
    my $distsq = ( $x * $pixel ) ** 2 + ( $y * $pixel ) ** 2 + ( $z * $slice ) ** 2;
    # Is the point within or on the surface of the sphere?...
    return $distsq <= $radsq;  # Return the decision as a boolean
}


sub in_the_cylinder {
# ! NOT ACTUALLY USED ANYWHERE YET !
# ! May have been proposed to avoid the problems of constructing a sphere on an anisotropic grid (for example, round-off problems). !
# This is used by both sub construct_? & construct_?_list.  We localize the ? calcs
# in a single sub to assure that both of these other subs implement the same decision criterion.
    my ( $x, $y, $z, $pixel, $slice, $radsq ) = @_;
    return in_the_sphere ( $x, $y, 0.0, $pixel, $slice, $radsq ) && lt_approxeq (  );  # Return the decision as a boolean
}


sub construct_sphere_list {
# Like the real one above -- uses the same algorithm -- but just calcs (and optionally lists to stdout)
# a typical set of voxel coords that define the sphere for this case.  Also returns the maximum deltas
# in x,y,z from the center of the sphere.
# N.B.: Be sure to coordinate any changes in the algorithm between these two versions.

    my $smallsphererad = $sphere_diam / 2.0;
    my $smallsphereradsq = $smallsphererad ** 2;
    my $printedxy = 0;  # a flag for controlling newlines
    my ($xc,$yc,$zc) = (50,50,50);  # an arbitrary location (center of the sphere)
    # initialize some maxes and mins...
    my ($maxx_sph,$maxy_sph,$maxz_sph) = ($xc,$yc,$zc);
    my ($minx_sph,$miny_sph,$minz_sph) = ($xc,$yc,$zc);
    
    print "\nA set of voxel coordinates that define a virtual sphere centered at ($xc,$yc,$zc) for pixel size = $pixeldim mm., slice spacing = $slicespacing mm., and rounding term = ", RO, ":\n" if $verbose >= 4;
    
    # calc the deltas used to define the box within which the virtual sphere will be constructed
    my $idelta = int( $smallsphererad / $pixeldim ) + 1;  # in-plane delta in pixels
    my $kdelta = int( $smallsphererad / $slicespacing ) + 1;  # between-slice delta in slices
    
    # index thru the box
    foreach my $z ( ($zc-$kdelta)..($zc+$kdelta) ) {
        print "(i,j) pixel coords at k = $z:\n" if $verbose >= 4;
        $printedxy = 0;
        foreach my $y ( ($yc-$idelta)..($yc+$idelta) ) {
            foreach my $x ( ($xc-$idelta)..($xc+$idelta) ) {
                if ( in_the_sphere( ($x-$xc), ($y-$yc), ($z-$zc), $pixeldim, $slicespacing, $smallsphereradsq ) ) {
                    print "($x,$y) " if $verbose >= 4;
                    $printedxy = 1;
                    # Keep track of min/max for "delta" calcs below...
                    $minx_sph = $x if $x < $minx_sph;
                    $maxx_sph = $x if $x > $maxx_sph;
                    $miny_sph = $y if $y < $miny_sph;
                    $maxy_sph = $y if $y > $maxy_sph;
                    $minz_sph = $z if $z < $minz_sph;
                    $maxz_sph = $z if $z > $maxz_sph;
                }  # end of the if that checks for being in or on the sphere
            }  # end of x
            print "\n" if ( $printedxy && $verbose >= 4 );
            $printedxy = 0;
        }  # end of y
    }  # end of z
    
    #print Dumper($maxx_sph-$xc,$maxy_sph-$yc,$maxz_sph-$zc,$minx_sph-$xc,$miny_sph-$yc,$minz_sph-$zc);
    print "\n";
    
    my $maxx_del = ( abs($maxx_sph-$xc) > abs($minx_sph-$xc) ? abs($maxx_sph-$xc) : abs($minx_sph-$xc) );
    my $maxy_del = ( abs($maxy_sph-$yc) > abs($miny_sph-$yc) ? abs($maxy_sph-$yc) : abs($miny_sph-$yc) );
    my $maxz_del = ( abs($maxz_sph-$zc) > abs($minz_sph-$zc) ? abs($maxz_sph-$zc) : abs($minz_sph-$zc) );
    return $maxx_del, $maxy_del, $maxz_del;
}  # end of construct_sphere_list


sub dump_rc {
# Show the return codes...
    print "Return codes: \n";
    while ( my ($k,$v) = each %RETURN_CODE ) {
        print "  $v:\t$k\n";
    }
}


sub round {
# Very simple -- no error checking!...
    my ( $num, $numdigs ) = @_;
    return sprintf "%.". $numdigs . "f", $num;
}


sub approxeq {
# Check 2 numbers for equality to the specified tolerance
# See, however, http://www.cygnus-software.com/papers/comparingfloats/comparingfloats.htm
    my ( $x1, $x2, $tol ) = @_;
    my $flag;
    my $delta = abs ( $x1 - $x2 );
    my $ave = abs ( ( $x1 + $x2 ) / 2.0 );
    # A bad(?) attempt to guard against divide by zero
    if ( $ave > $tol ) {
        my $frac = $delta / $ave;
        $flag = ( $frac <= $tol );
    } else {
        $flag = ( $delta <= $tol );
    }
    #print "+++ x1, x2, delta, ave, frac, flag :: $x1  $x2  $delta  $ave  $frac  $flag \n";  # testing
    return $flag;
}


sub lt_approxeq {
# Checks if the 1st number is less than or approx equal to the 2nd
    my ( $x1, $x2, $tol ) = @_;
    return ( approxeq ( $x1, $x2, $tol ) || ( $x1 < $x2 ) );
}


sub rename_nn_id {

# Rename non-nodule IDs for selected conditions.

    my ( $id, $site ) = @_;
    
    # N.B.: $site will be undefined if $reader_info{$servicingRadiologistIndex}{'site'} has not been set
    #       which would happen if $svcsite was not set in sub show which would happen if sub show were not
    #       called which would happen if the header type (request vs. response) did not match what was specified
    #       on the command line which typically happens if a QA run is not setup right.  (whew!!)
    #       But if $site is undefined, we'll have lots of other problems, so just live with it!
    print "+++ in sub rename_nn_id: NNID is ", ( $id ? $id : 'unknown' ), " and site is ", ( $site ? $site : 'undefined' ), "\n" if ( 0 );  # testing
    
    # For Cornell: Prepend a string to the ID since early versions of their software
    #   re-used IDs between nodules and non-nodules.  This fix makes non-nodule IDs distinct
    #   from nodule IDs.
    # To identify Cornell, we consider two cases...
    # If the site name starts with "NY", we know it's Cornell for certain:
    if ( grep {/^NY/} $site ) {
        $nnid_has_been_changed = 1;  # set the flag (a global variable)
        return 'NN' . $id;
    }
    # But for data sent to NIH, the site designation is lost, so we are forced to identify
    # Cornell data by the fact that they seem to use small integers for IDs.
    # N.B.: The check for this is based on length of the string since doing a numeric equality
    #       check ( $id < 100) would fail for non-numeric IDs which some sites (such as Iowa) use.
    elsif ( length ( $id ) <= 2 ) {
        $nnid_has_been_changed = 1;  # set the flag (a global variable)
        return 'NN' . $id;
    }
    
    # If none of these above conditions are met, assume it's not Cornell and just return the ID unchanged.
    return $id;
    
}


sub reader_id {
# Return a string that identifies a reader as completely as possible.  Easily customizable
# by changing the lookup for index to string.
# Args:
#   in: an integer (reader index)
# Returns:
#   a string
    my ( $index ) = @_;
    my $idstr;
    if ( $index =~ /\D/ ) {
        # $index is NOT a number...
        $idstr = sprintf "Unknown(%s)", $index;
    }
    # else $index IS a number...
    elsif ( $index < 0 || $index > ($numreaders-1) ) {
        # ... but it's out of range, so...
        $idstr = sprintf "Unknown(%s)", $index;
    }
    else {
        # it's OK...
        $idstr = sprintf "%s(%d)", $servicingRadiologist[$index], $index;
    }
    return $idstr;
}


sub modify_reader_id {
# Modify the reader ID (passed-in) according to certain needs.
# For AIM: We need to differentiate between anonymized reader names (all names are set to "anon"
#          in the public data).  So, for example, change "anon" to "anon-2", where the final
#          digit is the current value of $servicingRadiologistIndex plus 1.
    
    my ( $id ) = @_;
    
    # AIM:
    my $index = $servicingRadiologistIndex + 1;
    return ( $id =~ /^anon$/ ? $id . '-' . $index : $id );
    
}


sub dump_contours_hash {
    print "Dump of defined values in the \%contours hash (using offset coords relative to bounding box)...\n";
    my $counter = 0;
    for my $r ( keys %contours ) {
        for my $x ( keys %{$contours{$r}} ) {
            for my $y ( keys %{$contours{$r}{$x}} ) {
                for my $z ( keys %{$contours{$r}{$x}{$y}} ) {
                    for my $l ( keys %{$contours{$r}{$x}{$y}{$z}} ) {
                        my $label = $contours{$r}{$x}{$y}{$z}{$l};
                        print "  \%contours{$r}{$x}{$y}{$z}{$l} = $label\n";
                        $counter ++;
                    }
                }
            }
        }
    }
    print "$counter marked voxels were found in \%contours \n";
    return;
}


sub reorder_contours {
    for my $r ( keys %contours ) {
        for my $x ( keys %{$contours{$r}} ) {
            for my $y ( keys %{$contours{$r}{$x}} ) {
                for my $z ( keys %{$contours{$r}{$x}{$y}} ) {
                    for my $l ( keys %{$contours{$r}{$x}{$y}{$z}} ) {
                        $contours1{$x}{$y}{$z}{$r}{$l} = $contours{$r}{$x}{$y}{$z}{$l};
                    }
                }
            }
        }
    }
}


sub make_backup {
    my ( $fname ) = @_;
    if ( -e $fname && -s $fname ) {  # make a backup only if the file exists and has size > 0
        if ( -w $fname ) {
            rename $fname, $fname . '~';
        }
        else {
            #""" User message doc: 5302: There was a problem making a backup copy of a file.
            msg_mgr (
                severity => 'ERROR',
                msgid => 5302,
                appname => 'MAX',
                subname => (caller(0))[3],
                line => __LINE__ - 6,
                text => my $text = ( sprintf "There was a problem making a backup copy of file %s.", $fname ),
                accum => 1,
                verbose => 3,
                code => -1  # consider this a non-fatal error so just return to the caller
            );
        }
    }
    return;
}


sub save_large_nod_info {
# This sub saves selected global data structures out to files as a way of implementing presistence
# between runs.  In particular, we do this for QA checks on large nodule data
# between the blinded and unblinded runs.

    my ( $choice ) = @_;
    
    print "In sub save_large_nod_info: dumping large nodule info. \n" if $verbose >= 5;
    
    if ( $choice eq 'centroids' ) {
        print $lni_fh  "# for servicing site: $svcsite \n" . Data::Dumper->Dump( [ \%centroids ], [ 'centroids' ] );
    }
    elsif ( $choice eq 'majority' ) {
        print $lni1_fh "# from blinded matching \n"        . Data::Dumper->Dump( [ \%majority  ], [ 'majority'  ] );
    }
    else {
        #""" User message doc: 6905: Internal error in saving large nodule data.
        msg_mgr (
            severity => 'FATAL',
            msgid => 6905,
            appname => 'MAX',
            subname => (caller(0))[3],
            line => __LINE__ - 6,
            text => 'Internal error in saving large nodule data.',
            accum => 1,
            verbose => 1,
            code => $Site_Max::RETURN_CODE{internalerror}
        );
    }
    
    return;

}


sub doit {
# This sub evaluates a file via the do function.  The file typically contains Perl code generated
# by Dumper; see, for example, sub save_large_nod_info.

    my ( $filename ) = @_;
    
    # This is the main event:
    my $ref = do $filename;
    
    if ( not $ref ) {
        if ( $! ) {
            #""" User message doc: 6313: Cannot evaluate a file.
            msg_mgr (
                severity => 'FATAL',
                msgid => 6313,
                appname => 'MAX',
                subname => (caller(0))[3],
                line => __LINE__ - 7,
                text => my $text = ( sprintf "Cannot evaluate filename %s: %s", $filename, $! ),
                accum => 1,
                verbose => 3,
                code => $Site_Max::RETURN_CODE{savefileevalerror}
            );
        }
        else {
            undef $ref;
        }
    }
    return $ref;
}


sub accum_xml_lines {
# Accumulate XML lines in a hash for later writing to a file (generally by sub write_xml_header below)
# Calling protocol:  accum_xml_lines ( $id, \%xml_lines, $line )
    my ( $id, $xml_lines, $line ) = @_;
    push @{$xml_lines{$id}}, $line;
    return;
}


sub write_xml_line1 {
    my ( $fh ) = @_;
    print $fh $Site_Max::TAB[0] . XMLLINE1 . "\n";
    return;
}


sub write_xml_lines {
# Write accumulated XML lines to a file
# Calling protocol: write_xml_lines ( $id, \%xml_lines, $fh )
    my ( $id, $xml_lines, $fh ) = @_;
    print $fh $_, "\n" foreach ( @{$xml_lines{$id}} );
    return;
}


sub write_xml_app_header {
    
    my ( $ver, $fh ) = @_;
    
    print $fh $Site_Max::TAB[1] . "<AppInfoHeader> \n";
    print $fh $Site_Max::TAB[2] . "<XmlVersion>", $ver, "</XmlVersion> \n";
    print $fh $Site_Max::TAB[2] . "<ProcessingInfo> \n";
    print $fh $Site_Max::TAB[3] . "<AppInfo name=\"MAX\" version=\"$version\" datetime=\"$datetime\"/> \n";
    print $fh $Site_Max::TAB[3] . "<AppConfig></AppConfig> \n";
    print $fh $Site_Max::TAB[3] . "<RunInfo cmnd=\"$runcmnd\" cwd=\"$curdir\" date=\"$rundate\" time=\"$runtime\" hostname=\"$hostname\"/> \n";
    print $fh $Site_Max::TAB[3] . "<AppComments>$comments</AppComments>\n" if $comments;
    print $fh $Site_Max::TAB[2] . "</ProcessingInfo> \n";
    print $fh $Site_Max::TAB[1] . "</AppInfoHeader> \n";
    
    return;
    
}


sub write_xml_datainfo_header {

    my ( $fh ) = @_;
    
    my @cmnt_arr;
    
    for ( keys %cmnt_tags ) {
        push @cmnt_arr, "<CommentText svcsite=\"$_\">$cmnt_tags{$_}</CommentText>\n" if $cmnt_tags{$_};
    }    
    
    # N.B.: The "( $var ? $var : 'unknown' )" code below is temporary
    print $fh $Site_Max::TAB[1] . "<DataInfoHeader>\n";
    print $fh $Site_Max::TAB[2] . "<RequestingSite>" . ( $reqsite ? $reqsite : 'unknown' ) . "</RequestingSite> \n";
    print $fh $Site_Max::TAB[2] . "<CtImageFile>" . ( $ctimagefile ? $ctimagefile : 'unknown' ) . "</CtImageFile> \n";
    print $fh $Site_Max::TAB[2] . "<StudyInstanceUID>"  . ( $stuiu ? $stuiu : 'unknown' ) . "</StudyInstanceUID> \n";
    print $fh $Site_Max::TAB[2] . "<SeriesInstanceUid>" . ( $seriu ? $seriu : 'unknown' ) . "</SeriesInstanceUid> \n";
    print $fh $Site_Max::TAB[2] . "<ImageGeometry pixelsize=\"$pixeldim\" slicespacing=\"" . ( $slicespacing ? $slicespacing : 'unknown' ) . "\" units=\"mm.\" xdim=\"" . CTIMAGESIZE . "\" ydim=\"" . CTIMAGESIZE . "\" numslices=\"" . ( @allz ? scalar(@allz) : 'unknown' ) . "\"/> \n";
    print $fh $Site_Max::TAB[2] . "<DataComments>\n"  if ( scalar ( @cmnt_arr ) > 0 );
    print $fh $Site_Max::TAB[3] . $_ for ( @cmnt_arr );
    print $fh $Site_Max::TAB[2] . "</DataComments>\n" if ( scalar ( @cmnt_arr ) > 0 );
    print $fh $Site_Max::TAB[1] . "</DataInfoHeader>\n";
}


sub interrupt_handler {
    # We come here on control-C.
    # This works along with the line of code at the beginning of MAX that sets-up the action 
    # (the sub to jump to) to take when control-C (the INT signal) is "trapped".
    # Log some info:
    #""" User message doc: 3102: An interrupt signal from the user (control-C) has been detected.
    msg_mgr (
        severity => 'INFO',
        msgid => 3102,
        text => 'An interrupt signal from the user (control-C) has been detected.',
        accum => 1,
        before => 4,
        after => 2,
        screen => 1,
        code => -1
    );
    # Set a return code and exit (the exit stmt causes the END block to be executed):
    exit $Site_Max::RETURN_CODE{interrupted};
}


# ====================================================================
# =                                                                  =
# =        P O D   T E X T   F O R   I N - L I N E   H E L P         =
# =                                                                  =
# ====================================================================
sub section900__PODtext {}  # a dummy sub that lets us jump to this location via the function list in our editor

=head1 NAME

max - "multipurpose app for XML" for LIDC data processing

=head1 SYNOPSIS

max.pl [options]

  Options:
    --help
    --internals
    --internaldoc
    --verbose
    --validate
    --list
    --plot
    --config-file
    --read-type or --data-type
    --message-type
    --dir-in or --dir-name
    --prepend-dir-in
    --dir-out
    --dir-save
    --files or --file-name or --fname
    --file-in-pattern
    --add-suffix
    --skip-num-files-check
    --pixel-dim or --pixel-size or --pixel-spacing
    --slice-spacing
    --z-analyze
    --show-slice-spacing-messages
    --pmap-ops
    --xml-ops
    --sphere-diam
    --save-data-structures
    --quality-assurance-ops or --qa-ops
    --sec-matching
    --exit-early or --early-exit or --forced-exit or --action
    --test or --debug
    --study-instance-uid
    --comments
    --save-messages

=head1 OPTIONS

Options can be specified in the long form as generally shown in this document
or in the more traditional short form
if that can be done unambiguously.  Thus, "-h" is allowed for "--help", but "-v" cannot be used
as this is ambiguous because of the presence of --validate and --verbose.
Further, minimum abbreviations may be used:
for example, "--verb" and "--pix" 
are equivalent to "--verbose" and "--pixel-dim", respectively.

Options whose names contain interior dashes can be abbreviated by omitting the dashes.
Thus, --file-in-pattern can be given as --fileinpattern
(which, as noted above, could be shortened to something such as --fileinpat).

Options requiring a value may be specified with a space or an "="
between the option and the value.
Further, multiple values may be specified as separate options or in a comma-separated list.
Thus the following are equivalent:

    --verbose 2
    --verbose=2

as are

    --files=reader1.xml --files=reader4.xml
    --files=reader1.xml,reader4.xml

The "internal" dashes that are part of the option names may be omitted.
Thus, "--pixel-dim" and "--pixeldim" are equivalent.

All information is passed into MAX via options
(that is, items of the form "-o" or "--option", optionally followed by a value)
rather than as arguments standing alone on the command line.

The complete list of valid options with a short description of each one
(see the DESCRIPTION section below for more details):

=over 8

=item --help

Print this help text and exit. Alternatively, use the perldoc utility
to show this help text without running MAX explicitly:

    % perldoc -t max.pl

(Note that "%" represents the shell prompt.)

=item --internals

Display selected internal data structures on stdout and exit.

=item --internaldoc

Display information that documents certain internal information
(such as return code and user message descriptions) and exit.

=item --verbose n

Show varying degrees of extra output: 0 for minimal, typically 9 for maximal.
(Default: 3 -- the recommended level)

=item --validate

Perform content-specific validation/display of the specified input files 
and exit without further processing.

=item --list

List the XML files and the configuration file (if present) to stdout and exit.

=item --skip-num-files-check

Do not perform the "number of files" check.

=item --plot

Show a simple plot of each contour for large nodules.

=item --config-file filename

Process the specified configuration file (in Perl statement format).
(Not fully implemented at this time.)

=item --read-type phrase (or --data-type)

Specify blinded or unblinded read input data.  (default: unblinded)

=item --message-type phrase

Specify request or response message type.  (default: response)

=item --dir-in dirspec (or --dir-name) (default: . - the current directory)

Look in this directory for the input files.

=item --prepend-dir-in

Prepend the directory given by --dir-in to each input file name given by --files.

=item --dir-out dirspec (default: max/)

Prepend this directory to output filenames.

=item --dir-save (default: max/)

Prepend this directory to filenames used to save data between runs.

=item --file-in-pattern (default: \.xml$)

Use this pattern (a regular expression used in the Perl m/.../ operator) to pick-out the input XML filenames.

=item --add-suffix

Add a suffix all output files to denote the type of read and the type of message.  The suffixes can be modified (see Site_Max.pm).

=item --files file1[,file2[,...]] (or --file-name or --fname)

Process this file (or a comma-separated list of filenames).

=item --pixel-dim n.nn (or --pixel-size or --pixel-spacing)

In-plane dimension of the pixels (in mm.) in the images comprising the series.

=item --slice-spacing n.nn

Center-to-center slice spacing (in mm.) of the images comprising the series.

=item --z-analyze

Show some results gathered from analyzing the data at each slice represented in the XML
and then exit.

=item --show-slice-spacing-messages

Show certain informational messages related to slice spacing.

=item --pmap-ops optype1[,optype2[,optype3]] 

Controls pmap operations.
If --pmap-ops is not given, the defaults actions are taken (see below).
If --pmap-ops is given with at least one value, the defaults are not executed unless explicitly specified.
Valid operations:

=over

=item createpmap

Execute the pmap generation section of this app (default).

=item createxml

Create an XML file holding the pmap information (default).

=item includeconstituents

Include XML tags listing the constituent nodules of the matched nodules.

=item includesmall

Represent small nodules in the pmap using a artificially constructed sphere around the
marked point of the small nodule.
This feature is not implemented as of V1.07.

=item none

No pmap operations are to be executed.
Specifying "none" has the effect of disabling the default pmap operations.

=back

For example,

=over

=over

=item --pmap-ops=createxml

=item --pmap-ops=none

=item --pmap-ops=createxml,includecons

=back

=back

Minimum abbreviations of the values are shown for illustration purposes.

"createpmap" is implicitly turned-on if any other pmap options are given.

Include --verbose=4 to display the values of various flags derived from --pmap-ops.

=item --xml-ops optype1[,optype2[,optype3]] 

Controls XML file output operations.
If --xml-ops is not given, the defaults actions are taken (see below).
If --xml-ops is given with at least one value, the defaults are not executed unless explicitly specified.
Valid operations:

=over

=item history

Write nodule and non-nodule marking history to a file in XML form.
(Not implemented in V1.07.)

=item matching

Write nodule matching results to a file in XML form (default).

=item pmaps

Write pmap results to a file in XML form (default).

=item cxrrequest

Write the XML sections for a CXR request (mostly the <unblindedReadNodule> sections for large nodules).

=item none

No XML operations are to be executed.
Specifying "none" has the effect of disabling the default XML operations.

=back

For example,

=over

=over

=item --xml-ops=hist

=item --xml-ops=none

=back

=back

Minimum abbreviations of the values are shown for illustration purposes.

Include --verbose=4 to display the values of various flags derived from --xml-ops.

=item --sphere-diam n.nn

The diameter of the virtual sphere (in mm.) constructed around small nodules for overlap detection.
(Default: 3.0 mm.)

=item --save-data-structures

Save selected internal data structures to a file for later processing.
Valid values include: other, largenodule.
This feature is mainly used for certain quality assurance tasks.

=item --quality-assurance-ops (or --qa-ops)

Perform certain quality assurance tasks.
Valid values are (short forms in parentheses):
droppedlargenodule (droppedlarge), allmarkedlarge, connectivity (connect), notmajority,
narrowcontour (narrow), nonnodproximity (nonnodprox), and none.
Connectivity checking includes both pixel and region connectivity.
(Checking region connectivity on large nodules is extremely slow and should be avoided.)

=item --sec-matching

Apply secondary matching criteria.
(This capability is not fully developed and tested and thus should not be selected.)

=item --exit-early string (or --early-exit or --forced-exit or --action)

Controls the execution/flow of the code by causing an early or forced exit.  
Valid values (in order of occurrence of these sections in the execution of the code;
minimum abbreviations shown in parentheses):
preliminary (prelim), pass1, intermediate, pass2, check, centroids (centroid), and matching (match).
Execution is terminated at the end of the named section.
If more than one value is given, the action that occurs first in the execution of the code is taken.

=item --test string (or --debug)

Controls how/whether certain sections of code are executed
for low-level testing and development purposes.
(Requires familiarity with certain "hooks" placed in the code.)

=item --study-instance-uid string

This is not used at the present time.

=item --comments string

User-entered comment text for inclusion in the XML.

=item --save-messages

Save selected user messages to a file (in addition to displaying them on the screen).

=back

=head1 DESCRIPTION

MAX was designed for use by the LIDC to perform nodule matching, pmap generation,
extraction of marking history,
limited content-based validation and quality assurance,
and other XML-related operations based
on the blinded and unblinded read responses from the servicing sites.
Results are displayed to the user,
and some are written to XML files.

=head1 USING MAX

This section covers MAX's various command line options in illustrative detail.
See also the EXAMPLES section for some "quick start" examples,
as well as examples for some specific situations.

The input XML files can be specified in a number of ways.
If MAX is run in its simplest form,

    % max.pl

it looks for XML files in the current directory.
(Note that "%" represents the shell prompt.
Depending on how you have installed MAX, you might need to add a directory specifier.)
(Actually, this way of running MAX is a bit too simple; more on that later in this section.)
The Unix/Linux file utility is used to identify XML input files in this case,
subject to any pattern specified by --file-in-pattern
(which defaults to the Perl regular expression, '\.xml$', 
meaning that only files ending in ".xml" are considered).
To force MAX to look in a particular directory, use the --dir-in option.
In either case, MAX uses the file utility to identify XML files.

If the directory contains any XML files that are not blinded or unblinded read responses,
one of the following methods for specifying the input files could be used.
To specify the files separately,
use the --file-name option (or, more compactly, --fname) as shown in these examples:

    % max.pl --fname=CA.xml --fname=IA.xml --fname=IL.xml --fname=NY.xml

    % max.pl --fname CA.xml,IA.xml,IL.xml,NY.xml

    % max.pl --fname CA.xml,IA.xml,IL.xml --fname QA/NY.xml

As noted above the use of the "=" is optional in associating a value with an option;
in general, a space may be used instead.
However, if a shell wildcard pattern is used on the command line to specify a file,
a space must be used to separate the option from the value as in

    % max.pl ... --file-name *unblinded_read*.xml ...

If a "=" were used, the shell would try to match the pattern
"--file-name=*unblinded_read*.xml".

The --file-in-pattern option can be used to fine-tune which files are picked-up by MAX.
For example, if a directory contains the following files:

=over

1.2.826.0.1.3680043.2.108.14.0.0.30472.11.Unblind.Res.xml
MI014_CA006_unblind_resp_1.2.826.0.1.2.108.14.0.0.30472.11.xml
MI014_IL057_unblind_resp_1.2.826.0.1.2.108.14.0.0.30472.11.xml
MI014_NY307_unbl_req_1.2.108.14.0.0.30472.11-response.xml
MI014_NY307_unbl_req_1.2.108.14.0.0.30472.11-response.xml.PRE_QA
UM30472_nih.xml

=back

use "--file-in-pattern='MI.*xml$|Res.xml$'" to pick-out the desired files
(skipping the "pre QA" and NIH files).
The four desired unblinded response files would be selected for analysis 
without having to use the "--file-name" option.

If a comma-separated list of filenames is stored in a single line of a file,
the Unix/Linux backtick syntax can be used to specify the file list:

    % max.pl --file `cat file.lis`

In either of these cases, a relative or absolute directory can be prepended to the filenames.

Under most circumstances, there must be responses from at least 2 readers
but no more than 4 (or whatever is specified by the NUMREADERS constant).
Four responses could be obtained from 4 separate files or from a single merged file
(the concatenation of separate responses into a single file,
the form in which the reponses typically appear on the NCIA site).
The requirement for multiple responses is skipped, however, 
if MAX is being run in validate mode
or if it is being run on blinded data.
This requirement is also skipped if the --skip-num-files-check option is specified.
This is useful in analyzing merged response files rather than separate files
or when performing on-site QA on a single file.
In any case, matching, of course, still requires at least 2 readers.

(In most of the examples that follow,
we will omit the "--file-name" and related options
and will assume that the user will specify the input files according to the examples above.)

Since pixel size is not stored in the XML, 
it must be passed into MAX via the command line 
as a floating point number in mm. using the --pixel-dim (or its synonym --pixel-size) option.
We convert the very first example of this section into a "legal" one by adding this option:

    % max.pl --pixel-dim=0.625

or alternatively, perhaps,

    % max.pl --pixel-dim=`getpix --series 30078`

where getpix is a small utility that would be written by and tailored to your site.
It could obtain the pixel dimension from the DICOM files or from a query of your local database;
then it simply emits the pixel dimension as a string.
(Note that our example shows that getpix takes a single argument, --series.)

The pixel size option may be omitted if you are validating the data.

Slice spacing must also be known before matching can be done.
Although it is preferred to specify it explicitly as follows...

    % max.pl --pixel-dim=`getpix --series 30078` \
             --slice-spacing=1.25

it may be permissible in some cases to omit --slice-spacing
to force MAX to attempt to infer it from the XML files.
However, even if the --slice-spacing switch is included,
MAX still reports some of the results of its slice spacing inference procedure
which may be useful in detecting slice spacing non-uniformity.
Include --show-slice-spacing-messages to force all of these messages to be displayed.

Alternatively, run MAX with the --z-analyze option:
In this case, MAX collects the Z coordinate/slice information from the XML file(s)
and reports (among other things) whether it was able to infer the slice spacing.
In addition, it displays a list of the Z coordinates where markings were found
which can be used to (manually) infer the slice spacing if necessary.
Following this, MAX exits without performing any further analysis of the data.

The inference algorithm may be summarized as follows:
As the XML is parsed in pass 1, Z coordinates are collected
from the <imageZposition> tags in XML files.
Slice spacing uniformity is determined within each large nodule.
Then the slice spacings of all large nodules are compared:
If equal, this value is used for the overall slice spacing.
Thus it is recommended that MAX first be run without --slice-spacing
to allow slice spacing uniformity to be checked.
If non-uniformity is detected, an error return is taken,
and MAX displays the Z coordinate information that has collected.
The user can then decide how to proceed:
Investigate the non-uniformity by careful inspection of MAX's output during pass 1.
Then either
(1) discard the case if the non-uniformity is legitimate and invalidates the data or
(2) determine that the data is uniform and override MAX's inference algorithm
by supplying a value for the slice spacing using the --slice-spacing option.

To summarize, perhaps the best (most reliable) method is the following...

    % max.pl --pixel-dim=`getpix --series 30078` \
             --slice-spacing=`getss --series 30078`

where getss is a small utility (similar to getpix as described above)
that obtains the slice spacing from local data structures
or by analyzing the series' DICOM files.
Note that even if --slice-spacing is present,
MAX still runs the inference procedure and reports what it finds,
but uses the spacing specified with --slice-spacing.

A number of output files are created for capturing
the results produced by MAX in XML form,
as well as for a file that stores user messages.
At the current time (V1.07), their names are constants
(rather than being specified on the command line):

    matching.xml
    history.xml
    pmap.xml
    messages.txt

They are modified by the presence of the --add-suffix option.
This option automatically adds a suffix to each of the four filenames listed above
depending on the type of file(s) being processed:

    -bl_resp
    -unbl_req
    -unbl_resp

This helps keep filenames distinct if a number of analyses are preformed on the same set of files.
Thus if you are processing blinded response data (typically for QA purposes)
and you specify --add-suffix, the filenames above become:

    matching-bl_resp.xml
    history-bl_resp.xml
    pmap-bl_resp.xml
    messages-bl_resp.txt

The filenames and the suffixes are displayed when you run MAX with the --internals option;
see the "use constants" section that defines various filename strings.
Theses names are specified in the Site_Max.pm file and can thus be changed by the user as desired.

To continue with the exampleabove, you could run MAX
and specify a directory named xmlout/ that is to hold the files that MAX produces:

    % max.pl --pixel-dim=`getpix --series 30078` \
             --slice-spacing=`getss --series 30078` --dir-out=xmlout

If --dir-out is not specified,
the default output directory for receiving the files that MAX produces is max/.
In any case, the directory that is to receive the files must be created by the user,
and the user must, of course, have write permission to it.
To run MAX and produce temporary versions of the XML files
without having to setup directory to receive them,
include, for example, --dir-out=/tmp where /tmp is a temporary directory for your system.
To suppress the creation of XML files, include --xmlops=none on the command line.

Additional options are described in the following paragraphs.

Simple content-based validation is implicitly performed on the XML files
during pass 1.
It can be explicitly selected by specifying --validate;
MAX exits at the end of pass 1 when this option is given.
Note, however, that validation against the schema is NOT performed,
so validation is limited to parsing the XML for the expected tags and values.
XML creation is disabled when --validate is given.

The --pmap-ops=createxml and --xml-ops=pmaps options both enable
creation of the pmap XML file.
Plus, the presence of any of the --pmap-ops values enables pmap creation even
if the "createpmap" value is not explicit.

Setting the verbosity to a low level (less than 2, for example)
will prevent many important warnings from being displayed.
Many of them will be displayed upon termination of MAX 
unless --verbose=0 is specified.

Use the --read-type option to specify blinded or unblinded read input data.
If not specified, this defaults to "unblinded" which is appropriate for 
performing matching, writing pmap data to XML, etc.
Specify "blinded" along with the appropriate --xml-ops value(s)
when running MAX to create marking history XML or some of the QA tests.
In addition, when "blinded" is specified, 
you may want to use --exit-early to force MAX to exit prematurely as described below.
If an early exit is not forced,
MAX will exit after the centroid calculations
(just before matching is performed since matching cannot be preformed on blinded data).

The --plot option may be specified to cause simple plots to be produced
that may aid in diagnosing and troubleshooting.
Two types of plots are produced.
In pass 1, a separate 2D plot of the nodule markings is produced from the edge maps of each ROI.
In pass 2, a separate 2D plot of the filled contours is produced.
The plots are not saved and exist on the screen only until the user presses the return key
(as prompted by MAX).
gnuplot is used to produce these plots.

The --exit-early option is used to control the execution of MAX.
It can be given the following values:

    preliminary
    pass1
    intermediate
    pass2
    check
    centroid
    match

These values cause MAX to exit after the named section of the code is executed.
This can be useful to cause early termination of the program
for testing and diagnostic purposes or for some QA checks.
There is no checking of the values for --exit-early.
Invalid values are effectively ignored and cause no specific exit action to be taken.

Using the --test option for diagnostic and development purposes:
Special (usually short-term) code may be present to allow
various aspects of this application to be monitored.
Run this application with --internals to indicate
whether any sections of code have been thus "instrumented".

=head1 PROCESSING STEPS

MAX carries out its processing in a number of successive steps:

1.
The command line is parsed, and the options are checked.

2.
The configuration file is processed.
(In version 1.07, this step is not implemented.)

3.
Preliminary processing is performed.
(In version 1.07, this step is empty.)

4.
A first pass is made over the XML files.
A number of tags under the <ResponseHeader> section are displayed.
Then the <readingSession> section is traversed and parsed.
Any gross errors in content will most likely be flagged
or will cause a more catastrophic/unanticipated error.
As the XML is parsed, a summary of the contents is displayed.
Information about the extent of the markings in x and y is gathered
for later use in constructing various bounding boxes,
and information about the Z coordinates is gathered.
Simple plots of the outlines are optionally produced.
Marking history is optionally output as an XML file.
Plots of each contour are optionally produced.

5.
A report is made at the completion of pass 1 in which
the number of nodules and  non-nodules that were found are shown.
If no nodules are found, MAX exits with an error code.
The results of MAX's attempt to infer slice spacing is shown;
MAX exits if it detects any fatal errors concerning slice spacing.
If blinded data are being processed
or if validation has been specified,
MAX exits at this point.
Information about the readers is also displayed.

6.
Intermediate computations include
bounding boxes construction and
Z coordinate processing.

7.
In pass 2, the <readingSession> sections of the XML files are re-parsed,
and the coordinates of the contours, small nodules, and non-nodules are stored in an array
using bounding box offsets computed above.
(Note: Due to a change in the data structure that is used to hold the marking information,
offset code is no longer necessary, but it remains in version V1.07.)
Contours surrounding large nodule are filled, and
virtual spheres are constructed around small nodule markings.
Information for centroid calculations is collected.
Plots of the filled contours are optionally produced.

8.
In preparation for matching, centroids are calculated and exclusions in large nodules are processed.

9.
Next, basic matching is performed, including error checking for illegal overlaps and ambiguity detection.
Matching between all applicable combinations of small and large nodules and non-nodules is considered.
The following list characterizes the marking process performed by the readers
and matching process performed by MAX:

=over

A nodule larger or equal to the threshold size (typically 3mm diameter) is outlined 
by the reader with a
continuous line in each applicable slice.

The continuous line drawn around the outside of a large nodule is referred to as an
inclusion.  An area to be excluded can also be drawn (completely within the inclusion).

A nodule smaller than the threshold size is marked by the reader with a single point.
Such nodules are
referred to as "small".

MAX surrounds each small nodule with a sphere (typically 3mm diameter) to define a spatial
extent for matching.

A non-nodule is marked by the reader with a single point but is not surrounded by a sphere.

Markings made for inclusions and exclusions must be made such that nodule tissue is not
covered by the markings themselves.

Matching is based on simple overlap of voxels between different readers.

A reader cannot match with him/herself.

Matching can occur between two large nodules, between two small nodules, between a small
and a large nodule, between a non-nodule and a large nodule,
and between a non-nodule and a small nodule.

Matching between two non-nodules is not allowed.

A matching that is for some reason considered to be questionable is tagged as "ambiguous".

A match involving a non-nodule is tagged as "ambiguous".

If two nodules do not overlap with each other but overlap separately with a third, all three
are tagged as "ambiguous".

=back

10.
Secondary matching would optionally be carried out next,
but it is bypassed at this time since the need or desirability for this has not been decided.

11.
Next, MAX optionally performs pmap calculations and produces pmap XML.

12.
When MAX terminates, it outputs any warning messages that it has accumulated.
It displays a termination message
and sets a return code that is available to the caller.

QA operations are carried out at various stages of this process.
This includes most of the "numbered" QA errors,
as well as various consisency and sanity checks.

=head1 RESULTS

As the XML is parsed, a summary of the XML is displayed
along with the results of various calculations.
For example, there are a number of internal data structures that hold the
information about the large and small nodules and the non-nodules,
centroid calculations, results of matching, etc.
Many of these are displayed in an easily readable form
so that you can inspect the input data
and see the results of intermediate calculations matching
and confirm correct operation of MAX.
Results are also output in XML form for later processing --
typically by another application.

When MAX shows these various results,
it must uniquely identify the nodules and non-nodules among the readers.
To do so, the reader must be specified along with the object (nodule or non-nodule) ID.
The reader, in turn, is identified by a zero-based index used internally by MAX
(which is, in general, specific to a particular invocation of MAX),
plus the reader ID which is read from the XML
(the <servicingRadiologistID> tag).
Thus, a complete reference to a nodule might look like "IL057-1(2)/3055",
where "IL057-1" is the reader ID, "2" is the internal local reader index, and the nodule ID is "3055"
(obtained from <noduleID> or <nonNoduleID>).

For data that is to be made public,
values of a number of XML tags are anonymized in the files that result from the reading process.
(These are the files used as input to MAX.)
For example, reader ID is changed to "anon".
However, certain uses of MAX's output require that readers be differentiated.
Thus, "anon" is changed to
"anon-1", "anon-2", "anon-3", and "anon-4", respectively for four readers.
These modified reader IDs are used in, for example, the matching XML file that MAX produces.
Other reader IDs (such as "IL057-2") are not modified.

After matching has been performed, however,
the use of the "reader/ID" notation for identification is replaced by
a single ID: the series nodule ID or SNID.
For example, if three nodules are found to match...

     IL057-1(2)/3055
     NY307-2(3)/7
     IA018-1(0)/Nodule 003

the aggregate would be represented by a pmap
and might be assigned an SNID of 2.
This SNID stays with the matched aggregate throughout all subsequent processing by MAX.
The concept of a physical nodule ID (PNID) is used to associate SNIDs across multiple exams
or when data from pathology is associated with a nodule.

Even though small nodules participate in the matching process,
they are not represented in the pmaps.
(See however, the "includesmall" value for the --pmap-ops option;
however, this is not currently implemented as of V1.07.)
Thus an aggregate of matched nodules consisting entirely of small nodules
would not have a pmap.

As described above, depending on command line options, a number of XML files may be produced 
to hold various results of running MAX.
If the --dir-out option is given,
the directory thus specified is prepended to the XML filenames.

=head1 USER MESSAGES

MAX passes messages to the user ranging in severity from informational to fatal.
The current version of MAX uses two formats and methods to present these messages.
In addition to descriptive, textual information,
messages may include subroutine name and/or line number
to help localize and diagnose the problem.
A number of warnings and non-fatal error conditions are defined
which do not cause program termination;
they are generally displayed on the screen and are accumulated for display when MAX terminates.
In addition, a number of fatal error conditions are defined which will cause MAX to terminate prematurely:
The termination sequence includes the dumping of selected messages generated 
during the course of execution.
In all cases, MAX will return to the caller with a status code 
that usually indicates the nature of the error.

If the --save-messages option is given,
selected messages that were displayed on the screen
are also written to a file, messages.txt by default.

Run MAX with --internaldoc (and also --internals)
to display information pertaining to user messages.
See also the specification document.

Note that in some cases, running MAX with a low level of verbosity
(lower than the default of 3 as with, for example, --verbose=1)
can result in the suppression of useful messages.

=head1 FILES

=over 4

=item Configuration file (not yet implemented)

=item XML files (see below)

=item User messages file

=back

=head1 XML FILES

=over 4

=item Schema files

=item Blinded read files

=item Unblinded read files

=item Marking history, matching, and pmap files

=back

=head1 ENVIRONMENT

See the comment sections in the code at the beginning of this script -- especially the
"Background, data organization, etc." and "Porting Issues" sections.

=head1 CONFIGURATION

Code that is potentially site-specific is localized in a file named Site_Max.pm 
which is included in the distribution of MAX.
It can be used to customize certain parts of MAX's operation,
but some of this should be done in consultation with the entire Implementation Group.
As such, it contains a number of constants whose values can be edited by the user.
Use caution in editing constants that change the behavior of MAX's algorithms;
refer any questions in this regard to the developers.
In most cases, few if any customizations are needed.

Configuration can also be controlled by a configuration file specified at run-time
via the --config-file command line option.
This option is not implemented in version V1.07, however.

=head1 PORTING TO OTHER SITES

See the "Porting issues" section in the comments in the code at the beginning of this script.

=head1 PERL MODULES

See the "use" statements near the beginning the code of this script
for non-standard Perl modules that must be available before MAX can be run.
These modules can be downloaded from http://cpan.org.

=head1 ENVIRONMENTAL VARIABLES

=over 4

=item MAXOPTS

Options to be prepended to the command line options specified on the command line.

=back

=over 4

=item MAXSLEEP

The number of seconds to wait at the beginning of the script (default: 0).
(Originally included for development purposes.)

=back

=over 4

=item PERL5LIB

Use this to specify additional places for Perl to look for modules; see man perlrun.

=back

=head1 RETURN CODES

Return codes are, in general, set for various situations that cause the script to exit.
These codes are displayed to stdout for a verbose level of 6 and higher 
or with the --internals option.

=head1 EXAMPLES

A number of examples appear in earlier sections of this help text.
In addition, refer to a separate document ("MAX Addendum to LIDC QA") 
for details -- including examples -- on running MAX for QA purposes.

Display this help text and exit:
    
    max.pl --help
    
The suggested simplest form for performing analysis with MAX:
    
    max.pl --pixel-dim=0.6445 --slice-spacing=2.0
    
This form looks for unblinded read XML files in the current directory and performs matching on these files.
Matching and pmap calculations are performed and results are stored as XML files
in the default output directory.
(Technically, this form of running MAX finds all files whose names end in ".xml"
and assumes that they are unblinded responses.
Thus, any "extraneous" files whose names end in ".xml" would cause unexpected or erroneous results.)
Add "--xml-ops=none" to prevent XML files from being written.

Analyze the unblinded request message:
    
    max.pl --pixel-dim=0.6445 --slice-spacing=2.0 \
      --fname *_unblinded_request_* --skip \
      --read-type=blinded --message-type=request --xml-ops=none
    
Note that matching can be done since markings from multiple readers are present.

Same as the first example above
except that (1) pmap calculations are not performed and (2) nothing is stored as XML:
    
    max.pl --pixel-dim=0.6445 --slice-spacing=2.0 \
      --pmap-ops=none --xml-ops=none
    
Matching is performed but results are only displayed on the screen.

A QA run on a blinded read:
    
    max.pl --pixel-dim=0.6445 --slice-spacing=2.0 \
      --fname   *_blind_resp_*.xml --skip --read=blind \
      --qaops=narrow --exit=centroids --xmlops=none
     
A QA run on an unblinded read:
    
    max.pl --pixel-dim=0.6445 --slice-spacing=2.0 \
      --fname *_unblind_resp_*.xml --skip \
      --qaops=narrow --exit=centroids --xmlops=none
    
These QA runs would typically be performed at a servicing site
prior to sending the response files to the requesting site.

Perform a simple analysis of the Z coordinates of the slices in the XML files and then exit:
    
    max.pl --pixel-dim=0.6445 --z-analyze
    
This can be useful in investigating issues with the slice spacing.

Look for unblinded read XML files in the current directory and perform simple validation
by virtue of parsing them:
    
    max.pl --validate
    
Display, respectively, selected internal data structures and information stored internally
that documents certain aspects of MAX and exit:
    
    max.pl --internals
    
    max.pl --internaldocs
    
=head1 BUGS, LIMITATIONS, ASSUMPTIONS

See the ENVIRONMENT section above.
Also see the comments at the beginning of this script -- especially the
"Assumptions", "Known bugs",
and "To do, future ideas, limitations, issues" sections.

=head1 SEE ALSO

Refer to selected items on the LIDC Wiki site <http://troll.rad.med.umich.edu/twiki/bin/view>
(authentication is required).

A specification document is included in the distro of MAX.

=head1 AUTHOR

This script was written by Peyton Bland <bland@umich.edu>
in consultation with Chuck Meyer <cmeyer@umich.edu>
and Gary Laderach <gladerac@umich.edu>
(Digital Image Processing Lab, University of Michigan)
and others in the LIDC Implementation Group.

=cut
