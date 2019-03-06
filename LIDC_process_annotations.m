function LIDC_process_annotations


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% LIDC Toolbox
%
% If you use the software for research purposes I kindly ask you to cite
% the following paper:
%
%    T. Lampert, A. Stumpf, and P. Gancarski, 'An Empirical Study of Expert 
%       Agreement and Ground Truth Estimation', IEEE Transactions on Image
%       Processing 25 (6): 2557-2572, 2016.
%
%
% Runs through all of the LIDC scans within the directory specified by 
% LIDC_path and converts the XML annotations into GT images, along with the
% corresponding masks and slice images (if the images are present). The 
% results are put in the specified output_path under:
%
%   $output_path$/gts/$StudyInstanceID$/
%   $output_path$/images/$StudyInstanceID$/
%   $output_path$/masks/$StudyInstanceID$/
%
% Where $StudyInstanceID$ is the ID found within the DICOM minus the
% '1.3.6.1.4.1.14519.5.2.1.6279.6001.', which is constant within the
% dataset. An additional file names slice_info.txt is output within each of
% the above directories that contain the slice number, SOPInstanceUID and 
% DICOM filename correspondances.
%
% These functions only extract the slice images, GTs and masks for those 
% scan slices that have annotations associated with them.
%
% If you get an error similar to "Can't locate XML/Twig.pm" then you either 
% need to install the correct Perl packges required by MAX (see next 
% paragraph) or need to set the perl_library_path variable in 
% LIDC_convert_xml_2_mat.m to the location of the perl libraries (not 
% needed if using Windows).
%
% Requires PERL to be installed (MAX uses this) along with the following
% packages (see readme):
% 
%    XML::Twig
%    XML::Parser
%    Math::Polygon::Calc
%    Tie::IxHash
%
% NOTE TO USERS: I cannot guarantee that slicing distances and other
% anatomical data is preserved during this conversion (these functions rely
% on MAX to calculate all of this and I don't know whether I provide MAX 
% with enough information for this to be done reliably). I've tried my best
% to do things 'to-the-book' but I am not entirely familiar with the LIDC
% protocol.
%
% I've tested this on the first 100 LIDC files (LIDC-IDRI-0001 -
% LIDC-IDRI-0100) and all seems to be ok...
%
% The DCM and XML files corresponding to the same scan should be in the
% same directory, one directory for each scan (as is the structure of the
% original data). If the only the XML files are used then the masks and
% images will not be created and the GTs will not be in the order of the
% scan.
%
%
%   Thomas Lampert, http://sites.google.com/site/tomalampert
%  
%   Copyright 2013
%
%
%   This is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This software is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this software. If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            SET VARIABLES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set these paths correctly...
LIDC_path   = '';  % REPLACE WITH LIDC DATSET PATH
output_path = '';  % REPLACE WITH OUTPUT PATH

% Used if no images are found (i.e. you have only downloaded the XML files)
default_pixel_spacing = 0.787109;

% Turns off image missing warnings if using the XML only download
ignore_missing_file_warnings = false;

% Ignore matching warnings when matching GT to images (i.e. if images do 
% not exist, GTs will not be in anatomical order and not all images may be 
% written, this is a 'feature' of the dataset and not an error in the code)
ignore_matching_warnings = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




output_path = correct_path(output_path);
LIDC_path   = correct_path(LIDC_path);

if contains(LIDC_path, ' ')
    error('The LIDC path cannot contain spaces.');
end
if contains(output_path, ' ')
    error('The output path cannot contain spaces.');
end

xml_files = find_files(LIDC_path, '.xml', 'max');
new_xml_paths = cell(1, numel(xml_files)); % Keep a record of the paths that have been processed 
for i = 1:numel(xml_files)                 % so that they can be cleaned up if something goes wrong
    
    [xml_path, filename] = fileparts(xml_files{i});
    filename = [filename '.xml'];
    xml_path = correct_path(xml_path);
    
    % Extract the individual annotations from the xml files
    [new_xml_paths{i}, new_xml_filenames, studyID] = LIDC_split_annotations(xml_path, filename);
    
    if numel(new_xml_paths{i}) > 0
        try
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Get the dicom information from the first DICOM file found
            % in the XML directory so that we know what pixel spacing
            % to pass to MAX (if not found, use the default)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            missing_image = true;
            dcm_files = find_files(xml_path, '.dcm');
            for j = 1:numel(dcm_files)
                dicomInformation = dicominfo(dcm_files{1});
                
                % Make sure that the StudyInstanceUID matches that found in
                % the XML annotations
                if strcmpi(strrep(dicomInformation.StudyInstanceUID, '1.3.6.1.4.1.14519.5.2.1.6279.6001.', ''), studyID) && missing_image
                    missing_image = false;
                    break
                end
            end

            if ~missing_image
                pixel_spacing = dicomInformation.PixelSpacing(1);
                slice_thickness = dicomInformation.SliceThickness;
            else
                pixel_spacing = default_pixel_spacing;
                slice_thickness = -1;
                if ~ignore_missing_file_warnings
                    warning(['No image found (looking in ' xml_path ') continuing with the default pixel spacing of ' num2str(pixel_spacing) ...
                        '/nMasks and Images will not be created and the GTs will not be in slice order\n'...
                        '/nThis warning can be turned off by setting ignore_missing_file_warnings = true in LIDC_process_annotations']);
                end
            end
            
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create individual ground truths for each annotater and put them
            % in a temporary directory
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if missing_image % These are only used if the images do not exist because in these cases Max cannot automatically infer the slice spacing
                switch studyID
                    case '973595488903805096383507205745'
                        slice_thickness = 2.5;
                    case '769199091929930563098632346243'
                        slice_thickness = 2.5;
                    case '230628711415147360622019058241'
                        slice_thickness = 2.5;
                    case '184813778824165059499766817473'
                        slice_thickness = 1.25;
                    case '462307810912575525200563047628'
                        slice_thickness = 2.5;
                    case '290645258537791702736959842739'
                        slice_thickness = 2.5;
                    case '344370459068774891776634727699'
                        slice_thickness = 2.5;
                    case '373403474709639219417003839681'
                        slice_thickness = 1.25;
                    case '268602395458796193334776892547'
                        slice_thickness = 2.5;
                    case '814893999756843549134491977041'
                        slice_thickness = 1.25;
                    case '239106706584154405243531806759'
                        slice_thickness = 2.5;
                    case '177931410497444598503378575664'
                        slice_thickness = 3;
                    case '311744239959995611370181604400'
                        slice_thickness = 3;
                    case '385607958794725144174496012285'
                        slice_thickness = 2.5;
                    case '229359531540674087919898613528'
                        slice_thickness = 1.25;
                    case '998011886506191043815267149469'
                        slice_thickness = 2.5;
                    case '309197613983514716651302448908'
                        slice_thickness = 2.5;
                    case '233318337711699124969399854418'
                        slice_thickness = 2.5;
                    case '250876878281865060245064180921'
                        slice_thickness = 2.5;
                    case '101368220317159246676393493553'
                        slice_thickness = 2.5;
                    case '285544678683551057709080736846'
                        slice_thickness = 2.5;
                    case '306979641566588911923060002188'
                        slice_thickness = 2.5;
                    case '166927528009001339756280929911'
                        slice_thickness = 2.5;
                    case '854778727666988682245040938192'
                        slice_thickness = 2.5;
                end
            end
            
            switch studyID % Max always fails with these even with the image determined spacing
                case '208751380258614309420535124059'
                    slice_thickness = 0.3;
                case '282560440087299355954880509248'
                    continue % this annotation only contains small nodules and max always fails so we skip
            end
            
            for j = 1:numel(new_xml_filenames)
                LIDC_xml_2_pmap(new_xml_paths{i}{j}, new_xml_filenames{j}, pixel_spacing, slice_thickness, [xml_path, filename], studyID);
            end

            

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Extract the masks and ground truths from the dataset and put 
            % them in $output_path$/images
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            LIDC_mat_2_mask(xml_path, output_path, studyID, ignore_matching_warnings)
            
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Extract the images and GTs from the dataset and put them 
            % in $output_path$/images and $output_path$/gts
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            LIDC_mat_2_gt_image(xml_path, output_path, studyID, ignore_matching_warnings)
            
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Cleanup the temporary files for the current scans
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            for j = 1:numel(new_xml_filenames)
                if exist(new_xml_paths{i}{j}, 'dir')
                    rmdir(new_xml_paths{i}{j}, 's');
                end
            end
            
            
        catch e

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If something goes wrong cleanup the temporary files for all the 
            % scans that were successfully processed
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            for k = 1:i
                for j = 1:numel(new_xml_paths{k})
                    if exist(new_xml_paths{k}{j}, 'dir')
                        rmdir(new_xml_paths{k}{j}, 's');
                    end
                end
            end

            rethrow(e);
        end
    end
end