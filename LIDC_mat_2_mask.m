function LIDC_mat_2_mask(image_path, output_path, studyID)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% LIDC Toolbox
%
% If you use the software for research purposes I kindly ask you to cite
% the following paper:
%
%    T. Lampert, A. Stumpf, and P. Gancarski, 'An Empirical Study of Expert 
%       Agreement and Ground Truth Estimation', (submitted).
%
%
% The LIDC_convert_xml_2_mat function produces a MAT file with all the
% annotation information contained. This function takes this file and
% creates the images and masks corresponding each slice that the annotator 
% has marked. It then puts them in $output_path$/images and 
% $output_path$/masks.
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


    image_path  = correct_path(image_path);
    output_path = correct_path(output_path);
    
    mat_path       = image_path;  % will recursively search this path for mat files
    image_path_out = [output_path 'images' filesep studyID filesep];
    mask_path      = [output_path 'masks' filesep studyID filesep];

    
    if ~exist(mask_path, 'dir')
        mkdir(mask_path);
    end
    if ~exist(image_path_out, 'dir')
        mkdir(image_path_out);
    end
    
    no_images = 0; % Used to keep track of whether all images were found
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Each annotator may have missed some slices so we union the set of 
    % each annotators slices to find the set of all slices that have been 
    % annotated.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    file_list = find_files(mat_path, '.mat');
    overall_index = [];
    overall_z_pos = [];
    for i = 1:numel(file_list)

        load(file_list{i});
        for j = 1:numel(slice_index)
            slice_index{j} = char(slice_index{j});
        end
        
        %overall_index = union(overall_index, slice_index);
        
        [~,ia,ib] = union(overall_index, slice_index);
        
        [overall_index, ix] = sort([overall_index(ia); slice_index(ib)']);
        
        overall_z_pos = [overall_z_pos(ia), z_pos(ib)];
        overall_z_pos = overall_z_pos(ix);
        
    end
    
    clear slice_index
    clear z_pos
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Search through the image slices to find the one that corresponds to
    % the annotators slice, save it's position and create the mask.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    fprintf('Searching for correspondences (for masks and slice images)...\n');
    
    image_file_list  = find_files(image_path, '.dcm');
    if numel(image_file_list) ~= 0
        
        % check that the DICOM information matches that which we're looking
        % for
        no_image = 1;
        for i  = 1:numel(image_file_list)
            dicomInfo        = dicominfo(image_file_list{i}); 
            if strcmpi(strrep(dicomInfo.StudyInstanceUID, '1.3.6.1.4.1.14519.5.2.1.6279.6001.', ''), studyID)
                no_image = 0;
            end
        end
        
        % setup the mask and image variables using the information in the
        % DICOM header
        if no_image == 0
            masks            = zeros(dicomInfo.Height, dicomInfo.Width, numel(overall_index));
            images           = zeros(size(masks), 'uint16');
        else
            masks            = [];
            images           = [];
        end
    end
    LIDC_slice_index = zeros(1, numel(overall_index));
    DICOM_filenames  = cell(1, numel(overall_index));
    LIDC_SOP_UID     = cell(1, numel(overall_index));
    match_found      = zeros(1, numel(overall_index));
    z_pos            = zeros(1, numel(overall_index));
    
    % Find the image that corresponds to the slices that have GTs
    k = 1;
    for j = 1:numel(image_file_list)
        
        dicomInfo = dicominfo(image_file_list{j});

        if ~isempty(intersect(overall_index, dicomInfo.SOPInstanceUID)) && strcmpi(strrep(dicomInfo.StudyInstanceUID, '1.3.6.1.4.1.14519.5.2.1.6279.6001.', ''), studyID)

            img_bw = dicomread(image_file_list{j});

            if ~isfield(dicomInfo, 'PixelPaddingValue')
                warning('No padding value found. If negative values are found in the image then these will be used for the mask, if not, the mask will be empty');
            end
            
            temp_mask = zeros(dicomInfo.Height, dicomInfo.Width);
            % The pixel padding value is not consistent between the actual 
            % value in the image and that in the DICOM info so we set it to
            % the minimum value in the image if there is a value below 0
            actual_mask_value = min(min(img_bw));
            if actual_mask_value < 0
                if isfield(dicomInfo, 'PixelPaddingValue') && actual_mask_value ~= dicomInfo.PixelPaddingValue
                    warning(['The DICOM PixelPaddingValue used to create the mask has been corrected from ' ...
                                               num2str(dicomInfo.PixelPaddingValue) ' to ' num2str(actual_mask_value)]);
                end
                dicomInfo.PixelPaddingValue = actual_mask_value;
            end
            
            if isfield(dicomInfo, 'PixelPaddingValue')
                temp_mask(img_bw == dicomInfo.PixelPaddingValue) = 1;
            end
            masks(:,:,k)  = temp_mask;

            if isfield(dicomInfo, 'PixelPaddingValue')
                img_bw(img_bw == dicomInfo.PixelPaddingValue) = 0;
            end
            images(:,:,k) = img_bw;

            LIDC_slice_index(k) = dicomInfo.InstanceNumber;
            
            LIDC_SOP_UID{k}     = dicomInfo.SOPInstanceUID;
            
            z_pos(k)            = dicomInfo.SliceLocation;
            
            [~, fname]          = fileparts(dicomInfo.Filename);
            DICOM_filenames{k}  = [fname '.dcm'];
            
            match_found(k)      = 1;
            
            k = k + 1;

        end
    end
    
    if all(match_found == 0)
        if numel(image_file_list) ~= 0
            warning(sprintf('No images were found that match the GT annotations (although it appears that there are DICOM images in the same directory as the XML file)\nPress any key to continue writing only the GTs'));
            pause
        else
            warning(['No image found (looking in ' image_path ') masks and slice images will not be created\n']);
        end
        no_images = 1;
    else
        if sum(match_found) < numel(overall_index)
            wrn1 = sprintf('Only %d correspondences were found between the readers'' annotations and the DICOM slice images\n', k-1);
            warning([wrn1 'Press any key to continue writing the images and masks of only those correspondences found']);
            no_images = 2;
            pause
        end
        
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find the correct slice order and sort the masks accordingly
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [~, ind]               = sort(LIDC_slice_index);
    if any(match_found == 1)
        masks                  = masks(:,:,ind);
        images                 = images(:,:,ind);
    end
    sorted_LIDC_SOP_UID    = LIDC_SOP_UID(ind);
    sorted_DICOM_filenames = DICOM_filenames(ind);
    sorted_match_found     = match_found(ind);
    sorted_z_pos           = z_pos(ind);
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % Write the masks to file
    %%%%%%%%%%%%%%%%%%%%%%%%%
    try
        fid = fopen([image_path_out 'slice_correspondences.txt'], 'w');
    catch e
        error(['Could not create slice index file ' image_path_out 'slice_correspondences.txt for writing.']);
    end
    switch no_images
        case 0
            fprintf(fid, 'DICOM images found (slices are in order).\n');
        case 1
            fprintf(fid, 'DICOM images not found (masks not created).\n');
        case 2
            fprintf(fid, sprintf('Only %d DICOM image matches were found (masks and images of the matches have been written in order).\n', sum(match_found)));
    end
    fprintf(fid, 'Original Data Path: %s\n', image_path);
    fprintf(fid, 'Study Instance UID: 1.3.6.1.4.1.14519.5.2.1.6279.6001.%s\n', studyID);
    
    if any(match_found == 1)
        for i = 1:size(masks,3)

            if sorted_match_found(i)
                imwrite(masks(:,:,i),  [mask_path 'slice' num2str(i) '.tif']);

                t = Tiff([image_path_out 'slice' num2str(i) '.tif'], 'w');
                
                t.setTag('ImageLength',         size(images,1));
                t.setTag('ImageWidth',          size(images,2));
                t.setTag('Photometric',         Tiff.Photometric.MinIsBlack);
                t.setTag('BitsPerSample',       16);
                t.setTag('SamplesPerPixel',     1);
                t.setTag('Compression',         Tiff.Compression.LZW);
                t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
                
                t.write(images(:,:,i));
                t.close();

                fprintf(fid, 'slice: %d - z pos: %f - SOPInstanceUID: %s - DICOM filename: %s\n', i, sorted_z_pos(i), sorted_LIDC_SOP_UID{i}, sorted_DICOM_filenames{i});
            end

        end
    end
    clear gts
    
    fclose(fid);
    
    try
        copyfile([image_path_out 'slice_correspondences.txt'], [mask_path 'slice_correspondences.txt']);
    catch e
        warning(['Could not copy the slice index file ' image_path_out 'slice_correspondences.txt to ' mask_path 'slice_correspondences.txt.']);
    end
end
