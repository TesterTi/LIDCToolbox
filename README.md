# LIDC Matlab Toolbox

Thomas A. Lampert, ICube, University of Strasbourg

This work was carried out as part of the FOSTER project, which is funded by the French Research Agency (Contract 
ANR Cosinus, ANR-10-COSI-012-03-FOSTER, 2011—2014): http://foster.univ-nc.nc/

## Introduction

This toolbox accompanies the following paper:

	T. Lampert, A. Stumpf, and P. Gancarski, 'An Empirical Study of Expert Agreement and Ground Truth 
		Estimation', (submitted).

I kindly request you to cite the paper if you use this toolbox for research purposes.



The toolbox contains functions for converting the LIDC database XML annotation files into images. The main 
function is LIDC_process_annotations, this function extracts the readings for each individual marker in the 
database, and then creates a TIFF image related to each slice of the scan.

## Overview


The function works whether the images are present or not, the only caveat is that it uses the images to order
the slices and therefore if this information is not present the output's order is not in 'anatomical' order.
There are two paths to set in the LIDC_process_annotations.m file, the first to the LIDC dataset, this will be
searched recursively for all XML files and the processing will be performed on each. The second path is the 
output path, if the images are present in the dataset then three folders will be created: gts, images, masks.
Please note that neither of these paths can contain a space. Each of these folders will contain folders that 
are named after the StudyInstanceID of the relevant scan (minus the first '1.3.6.1.4.1.14519.5.2.1.6279.6001.',
which seems to be constant throughout the dataset), and within the gts folder several folders named slice1 ... 
sliceX, where X is the number of slices for which reader annotations were found. Each of these folders contains 
the files `GT_id1.tif ... GT_isY.tif` where Y is the number of readers found for that particular scan (each file 
is a binary image where ones denote the markers GT). The gts folder will also contain a text file that details 
the correspondence between the folder's name (slice number), the SOPInstanceUID (unique for each slice of the 
scan) and the DICOM filename that contains that slice (if the images are present). The masks folder contains 
binary images `slice1.tif ... sliceY.tif`, where one indicates that the area is out-of-bounds of the scan. The 
images folder contains images `slice1.tif ... sliceY.tif`, which contain the slice images. The masks and images 
folder are only created if the images are present in the folder in which the XML annotations exist (as is the 
structure when the LIDC dataset is downloaded). The toolbox will only extract the slices for which annotations 
are found, the remaining slices can be obtained from the DICOM images quite easily.


## Installation

To use the toolbox's functions, simply add the toolbox directory to Matlab's path. Within the header of each 
function may be found a short description of its purpose.

The function LIDC_xml_2_pmap uses the external Perl script max.pl 
(https://wiki.cancerimagingarchive.net/display/Public/Lung+Image+Database+Consortium) and therefore requires 
that Perl is installed, furthermore the following packages should be installed:

	XML::Twig
	XML::Parser
	Math::Polygon::Calc
	Tie::IxHash

More information can be found in the header of LIDC_process_annotations.m and the max.pl script located in
./support_software/max.pl. If you are using OSX (and perhaps Linux) you may also need to update the 
perl_library_path variable in LIDC_xml_2_pmap.m to point to the correct location of these libraries 
(particularly if you receive the error "Can't locate XML/Twig.pm" or it complains that XML::Twig is not 
installed, when it is). To install these packages the following command can be executed (use sudo if on OSX):

        perl -MCPAN -e "install XML::Twig"

NOTE: This toolbox was created under Matlab 2013a and OSX, I have also tested it under Windows 7 x64 using
Matlab 2012b.

NOTE: Many functions include assignments such as [~, var1] = someFunction(input), which is only supported in
versions of Matlab newer than 2009b. You can replace these assignments to [ignore, var1] = someFunction(input)
for versions earlier than 2010a, although I've not tested that no other incompatibilities exist.


## Quick Start - Windows

1. Download and Install Activestate (http://www.activestate.com/activeperl/downloads)
2. Install the following perl packages
 * `XML::Twig`
 * `XML::Parser`
 * `Math::Polygon::Calc`
 * `Tie::IxHash`

 To do that, start the Windows command prompt and execute the following commands:
<br>`perl -MCPAN -e "install XML::Twig"`
<br>`perl -MCPAN -e "install XML::Parser"`
<br> `perl -MCPAN -e "install Math::Polygon::Calc"`
<br>`perl -MCPAN -e "install Tie::IxHash"`
3. Restart your PC

Your computer is now ready to use the toolbox.

To begin using the toolbox

1. Open the file "LIDC_process_annotations.m"
2. Set the Paths for the LIDC-IDRI folder and to the Output folder
 * Note: Make sure your path does not include a space, For example:
<br>&nbsp;&nbsp;"c:\LIDCtoolbox v1.3" is an invalid path due to the space between "toolbox" and "v1.3"
<br>&nbsp;&nbsp;"c:\LIDCtoolbox_v1.3" is a valid path
3. Open the file 
4. Run "LIDC_process_annotations.m"


## Quick Start - OS X/Linux

1. Install the following perl packages
 * XML::Twig
 * XML::Parser
 * Math::Polygon::Calc
 * Tie::IxHash

 To do that, start the terminal and execute the following commands:
 <br>`sudo perl -MCPAN -e "install XML::Twig"`
 <br>`sudo perl -MCPAN -e "install XML::Parser"`
 <br>`sudo perl -MCPAN -e "install Math::Polygon::Calc"`
 <br>`sudo perl -MCPAN -e "install Tie::IxHash"`

Your computer is now ready to use the toolbox.

To begin using the toolbox

1. Open the file "LIDC_process_annotations.m"
2. Set the Paths for the LIDC-IDRI folder and to the Output folder
 * Note: Make sure your path does not include a space, For example:
<br>&nbsp;&nbsp;"/users/LIDCtoolbox v1.3" is an invalid path due to the space between "toolbox" and "v1.3"
<br>&nbsp;&nbsp;"/users/LIDCtoolbox_v1.3" is a valid path
3. Open the file "LIDC_xml_2_pmap.m"
4. Set the path stored in the variable "perl_library_path" to that which contains the above installed 
   perl packages.
5. Run "LIDC_process_annotations.m"

If you find any problems or would like to contribute some code to the toolbox then please contact me.

## Acknowledgements

Peyton Bland gave considerable advice with regards to the Max software upon which this toolbox is based.
Hamada Rasheed Hassan also contributed through extensive testing of the toolbox under Windows and in helping write this readme file.
