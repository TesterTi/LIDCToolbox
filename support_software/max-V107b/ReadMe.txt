ReadMe.txt
==========


MAX V1.07 - max-V107.pl
29 July 2010


------------------------------------------------------------------------------------------------
Copyright 2006 - 2010
THE REGENTS OF THE UNIVERSITY OF MICHIGAN
ALL RIGHTS RESERVED

The software and supporting documentation was developed by the

         Digital Image Processing Laboratory
         Department of Radiology
         University of Michigan
         1500 East Medical Center Dr.
         Ann Arbor, MI 48109

It is funded in part by DHHS/NIH/NCI 1 U01 CA91099-01.

IT IS THE RESPONSIBILITY OF THE USER TO CONFIGURE AND/OR MODIFY THE SOFTWARE TO PERFORM THE 
OPERATIONS THAT ARE REQUIRED BY THE USER.

THIS SOFTWARE IS PROVIDED AS IS, WITHOUT REPRESENTATION FROM THE UNIVERSITY OF MICHIGAN AS 
TO ITS FITNESS FOR ANY PURPOSE, AND WITHOUT WARRANTY BY THE UNIVERSITY OF MICHIGAN OF ANY 
KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE REGENTS OF THE UNIVERSITY OF 
MICHIGAN SHALL NOT BE LIABLE FOR ANY DAMAGES, INCLUDING SPECIAL, INDIRECT, INCIDENTAL, 
OR CONSEQUENTIAL DAMAGES, WITH RESPECT TO ANY CLAIM ARISING OUT OF OR IN CONNECTION WITH 
THE USE OF THE SOFTWARE, EVEN IF IT HAS BEEN OR IS HEREAFTER ADVISED OF THE POSSIBILITY 
OF SUCH DAMAGES.

PERMISSION IS GRANTED TO USE, COPY, CREATE DERIVATIVE WORKS AND REDISTRIBUTE THIS SOFTWARE 
AND SUCH DERIVATIVE WORKS FOR ANY PURPOSE, SO LONG AS THIS ENTIRE COPYRIGHT NOTICE, 
INCLUDING THE GRANT OF PERMISSION, AND DISCLAIMERS, APPEAR IN ALL COPIES MADE; AND SO LONG 
AS THE NAME OF THE UNIVERSITY OF MICHIGAN IS NOT USED IN ANY ADVERTISING OR PUBLICITY 
PERTAINING TO THE USE OR DISTRIBUTION OF THIS SOFTWARE WITHOUT SPECIFIC, WRITTEN PRIOR 
AUTHORIZATION.
------------------------------------------------------------------------------------------------


General
-------

MAX -- Multipurpose Application for XML -- performs nodule matching, pmap generation, and other
XML-related and QA/QC-related tasks on the blinded and unblinded LIDC read responses.

This release of MAX continues its development, fixes some bugs, and adds a number of features &
enhancements. See the ReleaseNotes.txt file for details.

MAX is implemented with of a small number of Perl files. The files can be placed in any directory
that is accessible to your users.


Development
-----------

MAX was developed under RedHat Linux Enterprise. The Perl versions used were v5.8.0 and v5.8.8.
It is quite possible that MAX will run on older versions of Perl, but this hasn't been tested.

Although Perl can be run under Windows, we have little or no experience in doing this, so the use
of Linux is recommended. See, however, the comments in the file max.pl that are labeled "Porting
to other operation systems".


Environment
-----------

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
The Perl environment for MAX should be setup according to the comments in the file max.pl that
are labeled "Pre-requisites and environment". Setting up the Perl environment involves being sure
that your Perl installation contains the necessary extra modules that are in the public domain.


Installation
------------

The two main files that comprise MAX are max.pl and Site_Max.pm. These are actually symbolic
links to the "real" files in this distro: max-V107.pl and Site_Max-V200.pm, respectively.

The archive of this distro was produced using the following command:

    % tar -cvz -T filelist -f max-V107.tar.gz  (where "%" represents the shell prompt)

You need to be certain that the current installation of MAX is completely independent of any
previous installations.  Pay particular attention to the Site_Max*.pm file.  Unless instructed
otherwise, you must always replace it with the new version furnished in the distro.  If you
have installed them in a library directory that is included in @INC (perhaps by the use of an
environmental variable such as PERL5LIB), be sure to replace that version in the library
directory.  (The simplest way to install MAX is for max*.pl and Site_Max*.pm to reside in the
same directory rather than to use a separate directory for Site_Max*.pm.)

An installation procedure similar to the following is recommended. Our examples here assume that
the previous version of MAX was installed in a directory /usr/local/max.

    % cd /usr/local
    % mv max max-V106  # if applicable
    % mkdir max
    % cd max
    % cp /from/somewhere/max-V107.tar.gz .
    % tar -xvz -f max-V107.tar.gz

The resulting directory should look something like this:

    -rw-r--r--  1 bland dipl   4321 Feb 28 16:34 ReadMe.txt
    -rw-r--r--  1 bland dipl  15241 Feb 28 16:50 ReleaseNotes.txt
    -rwxr-xr-x  1 bland dipl  15330 Feb 28 14:29 Site_Max-V200.pm
    lrwxrwxrwx  1 bland dipl     16 Feb 28 14:56 Site_Max.pm -> Site_Max-V200.pm
    -rw-r--r--  1 bland dipl    191 Feb 28 16:50 filelist
    -rwxr-xr-x  1 bland dipl   5900 Feb 28 16:48 get_image_geom-V201.pl
    lrwxrwxrwx  1 bland dipl     22 Feb 28 16:40 get_image_geom.pl -> get_image_geom-V201.pl
    -rwxr-xr-x  1 bland dipl    504 Feb 28 16:38 getfiles.sh
    -rwxr-xr-x  1 bland dipl   2940 Feb 28 16:38 getpix-V100.sh
    lrwxrwxrwx  1 bland dipl     14 Feb 28 16:38 getpix.sh -> getpix-V100.sh
    -rwxr-xr-x  1 bland dipl 439983 Feb 28 15:00 max-V107.pl
    -rw-r--r--  1 bland dipl 176266 Feb 28 16:51 max-V107.tar.gz
    -rw-r--r--  1 bland dipl    207 Feb 28 14:56 max-faq.txt
    lrwxrwxrwx  1 bland dipl     11 Feb 28 14:57 max.pl -> max-V107.pl


Configuration
-------------

MAX can probably be run "as is". However, some customizations or adjustments can be made to the
"Site_Max" file; see the comments in the file max.pl that are labeled "Porting to other sites".


The first test of MAX
---------------------

As a first test, run MAX with its "--help" option to display its in-line documentation:

    % ./max.pl --help

Success in running MAX in this way validates your installation of MAX and shows that all necessary
Perl modules were loaded properly.

If you see an error message that looks something like the following, then the environment for MAX
is not properly setup.

--------
  Can't locate Math/Polygon/Calc.pm in @INC (@INC contains: /usr/lib/perl5/5.8.0/i386-linux-thread-multi
  /usr/lib/perl5/5.8.0 /usr/lib/perl5/site_perl/5.8.0/i386-linux-thread-multi ...
  BEGIN failed--compilation aborted at ./TestSetup.pl line 22 (#1)
      (F) You said to do (or require, or use) a file that couldn't be
      found. Perl looks for the file in all the locations mentioned in @INC,
      unless the file name included the full path to the file.  Perhaps you
      need to set the PERL5LIB or PERL5OPT environment variable to say where
      the extra library is, or maybe the script needs to add the library name
      to @INC.  Or maybe you just misspelled the name of the file.  See
      perlfunc/require and lib.
      
  Uncaught exception from user code:
          Can't locate Math/Polygon/Calc.pm in @INC (@INC contains:
  /usr/lib/perl5/5.8.0/i386-linux-thread-multi /usr/lib/perl5/5.8.0 ...
  BEGIN failed--compilation aborted at ./TestSetup.pl line 22.
--------

Read the error message carefully, and refer again to comments in the code of the file max.pl that
are labeled "Pre-requisites and environment".

In any case, use the "help" information thus displayed to learn how to run MAX.  The source code
to MAX also contains information that might be useful.

Alternatively, use the perldoc utility to show this help text without running MAX explicitly:

    % perldoc -t max.pl


MAX examples
------------

Let's consider a simple example of running MAX that might be useful for getting started with
analyzing unblinded read XML files.  Assume that we are in a directory containing one file of the
four unblinded read results XML merged together:

    % /usr/local/max/max.pl --pixel-size=0.82 --slice-spacing=2.5 \
                            --fname UM_nih.xml --skip-num-files-check --xml-ops=none

Running with --xmlops=none prevents the XML files from being created.

To run MAX and allow it to create the XML files, omit "--xml-ops=none".  By default, MAX writes
the XML files in a directory called max/ in the current directory. To specify another directory
other than max/, use "--dir-out" or edit the constant DIROUTDEF in Site_Max.pm.


Support scripts
---------------

The distro includes a number of small support scripts that we use in our lab to facilitate the use
of MAX. Two are used to get pixel size and slice spacing from the CT data associated with the
unblinded read data. (This is necessary since these parameters are not stored in the XML files.)
There is also a script that generates the names of the four unblinded read files which is useful
when analyzing the unblinded reads as separate files. These scripts are almost certainly not
usable "as is" but are instead furnished to serve as examples. See MAX's in-line help text (run
with "--help") for examples. However, using these scripts is not at all mandatory: Many users
may prefer to specify slice spacing and pixel size as shown above.


Questions, Troubleshooting
--------------------------

If you have trouble installing MAX, refer to the following:
  * this file: Readme.txt (mainly "Environment", "Installation", and "The first test of MAX")
  * the FAQ: max-faq.txt
  * comments in the file max.pl as notes in ReadMe.txt
  
If you have trouble analyzing data with MAX, refer to the following:
  * this file: Readme.txt ("MAX examples" and "Support scripts")
  * the FAQ: max-faq.txt
  * MAX's in-line help (run with "--help" as noted above)

Otherwise, contact Peyton Bland: bland@umich.edu

