function LIDC_mat_2_gt_image(image_path, output_path, studyID, ignore_matching_warnings)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% LIDC Toolbox
%
% If you use the software for research purposes I kindly ask you to cite
% the following paper:
%
%    T. Lampert, A. Stumpf, and P. Gancarski, 'An Empirical Study of Expert 
%       Agreement and Ground Truth Estimation', IEEE Transactions on Image
%       Processing 25 (6): 2557–2572, 2016.
%
%
% The LIDC_convert_xml_2_mat function produces a MAT file with all the
% annotation information contained. This function takes this file and
% creates from it the annotators GT images and puts them in order of where 
% they appear in the data slice. It then puts them in $output_path$/gts.
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



    image_path = correct_path(image_path);
    output_path = correct_path(output_path);
    

    mat_path   = image_path;  % will recursively search this path for mat files
    gt_path    = [output_path 'gts' filesep studyID filesep];

    if ~exist(gt_path, 'dir')
        mkdir(gt_path);
    end
    
    no_images = 0; % Used to keep track of whether all images were found
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Each annotator may have missed some slices so we union the set of 
    % each annotators slice identifiers to find the set of all slices that
    % have been annotated
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    annotator_file_list = find_files(mat_path, '.mat');
    overall_index = [];
    overall_z_pos = [];
    for i = 1:numel(annotator_file_list)

        load(annotator_file_list{i});
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
    % each of the slices that have been annotated and save it's position
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fprintf('Searching for correspondences (for GT images)...\n');
    LIDC_slice_index = zeros(1, numel(overall_index));
    image_file_list  = find_files(image_path, '.dcm');
    DICOM_filenames  = cell(1, numel(overall_index));
    match_found      = zeros(1, numel(overall_index));
    z_pos            = zeros(1, numel(overall_index));
    
    k = 0;
    for j = 1:numel(image_file_list)
        
        dicomInfo = dicominfo(image_file_list{j});

        % Find whether slice is in overall annotated slice index
        [intrsct, ind] = intersect(overall_index, dicomInfo.SOPInstanceUID);
        if ~isempty(intrsct) && strcmpi(strrep(dicomInfo.StudyInstanceUID, '1.3.6.1.4.1.14519.5.2.1.6279.6001.', ''), studyID)

            LIDC_slice_index(ind) = dicomInfo.InstanceNumber;
            
            [~, fname]            = fileparts(dicomInfo.Filename);
            DICOM_filenames{ind}  = [fname '.dcm'];
            match_found(ind)      = 1;

            k = k + 1;

        end
        
    end
    
    if all(match_found == 0)
        if numel(image_file_list) ~= 0
            warning(sprintf('No images were found that match the GT annotations (although it appears that there are DICOM images in the same directory as the XML file)\nPress any key to continue (output will not be in anatomical order)'));
            if ~ignore_matching_warnings
                 pause
            end
        else
            warning(['No image found (looking in ' image_path ') GTs will not be in slice order\n']);
        end
        no_images = 1;
    else
        if sum(match_found) < numel(overall_index)
            wrn1 = sprintf('Only %d correspondences were found between the readers'' annotations and the DICOM slice images\n', k);
            warning([wrn1 'Press any key to continue writing the GT images in partial order']);
            no_images = 2;
            if ~ignore_matching_warnings
                pause
            end
        end
        
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find the correct slice order
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [~, ind]              = sort(LIDC_slice_index);
    sorted_overall_index  = overall_index(ind);
    sorted_DICOM_filename = DICOM_filenames(ind);
    sorted_match_found    = match_found(ind);
    sorted_z_pos          = overall_z_pos(ind);
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Go through each annotator's annotations to find which slice they
    % correspond to
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    try
        fid = fopen([gt_path 'slice_correspondences.txt'], 'w');
    catch e
        error(['Could not create slice index file ' gt_path 'slice_correspondences.txt for writing.']);
    end
    switch no_images
        case 0
            fprintf(fid, 'DICOM images found (slices are in order).\n');
        case 1
            fprintf(fid, 'DICOM images not found (slices are not in order).\n');
        case 2
            fprintf(fid, sprintf('Only %d DICOM image matches were found (first %d slices are in order).\n', sum(match_found), sum(match_found)));
    end
    fprintf(fid, 'Original Data Path: %s\n', image_path);
    fprintf(fid, 'Study Instance UID: 1.3.6.1.4.1.14519.5.2.1.6279.6001.%s\n', studyID);

    gts_size = [];
    i = 1;
    missing = 0;
    max_missing = numel(annotator_file_list);
    while i <= numel(annotator_file_list)

        load(annotator_file_list{i}); % loads gts and slice_index
        
        if ~isempty(gts)
            % save the GT size in case MAX failed with some
            gts_size = size(gts);
        else
            missing = missing + 1;
            % if the GT is empty (MAX failed), create blank GT image
            if ~isempty(gts_size)
                gts = zeros(gts_size(1:2));
            else
                if missing < max_missing
                    % put it at the end, hopefully another will have the
                    % gt size
                    annotator_file_list{end+1} = annotator_file_list{i};
                    i = i + 1;
                    continue
                else
                    % return without creating gts as they are all empty
                    i = i + 1;
                    continue;
                end
            end
        end
        
        gts(gts > 0) = 1;
        current_ann_slice_index = slice_index;
        clear slice_index
        clear z_pos


        % Find the slices in which this annotator didn't mark anything
        if ~isempty(current_ann_slice_index)
            missing_gt_ind = ~ismember(sorted_overall_index, current_ann_slice_index);
        else
            missing_gt_ind = ones(1, numel(sorted_overall_index));
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Write the gts to file in order of slices
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        written_count = 1;

        for k = 1:-1:0 % First write the GTs that we found images for then the rest

            for j = 1:numel(sorted_overall_index)

                if sorted_match_found(j) == k

                    slice_dir = [gt_path 'slice' num2str(written_count) filesep];

                    % Create the output directory if it doesn't exist
                    if ~exist(slice_dir, 'dir')
                        mkdir(slice_dir);
                    end

                    if missing_gt_ind(j)

                        imwrite(zeros(size(gts(:,:,1))), [gt_path 'slice' num2str(written_count) filesep 'GT_id' num2str(i) '.tif']);

                    else

                        [~, ind] = intersect(current_ann_slice_index, sorted_overall_index(j));

                        imwrite(gts(:,:,ind), [gt_path 'slice' num2str(written_count) filesep 'GT_id' num2str(i) '.tif']);

                    end

                    if i - missing == 1
                        if k == 1
                            fprintf(fid, 'slice: %d - z pos: %f - SOPInstanceUID: %s - DICOM filename: %s\n', written_count, sorted_z_pos(j), sorted_overall_index{j}, sorted_DICOM_filename{j});
                        else
                            fprintf(fid, 'slice: %d - z pos: %f - SOPInstanceUID: %s\n', written_count, sorted_z_pos(j), sorted_overall_index{j});
                        end
                    end

                    written_count = written_count + 1;

                end
            end
        end
        
        i = i + 1;
        
    end
    
    fclose(fid);
    
end
