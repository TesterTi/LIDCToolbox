function [new_path, new_filename] = LIDC_xml_2_pmap(xml_path, xml_filename, pixel_spacing)

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
% Runs MAX to convert the XML annotation to a probability map.
%
% The function LIDC_pmap_2_mat is then called to convert this
% probability map into GT images that are saved within a mat file.
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


% NOT USED UNDER WINDOWS: Path to the XML::Twig, XML::Parser, 
% Math::Polygon::Calc and Tie::IxHash in OSX these aren't installed in 
% Perl's default path.
perl_library_path = '/opt/local/lib/perl5/site_perl/5.12.4/';  


% Should be ok as it is (it's included with the toolbox)
MAX_path          = [fileparts(which('LIDC_mat_2_gt_image')) filesep 'support_software/max-V107b/']; 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




perl_library_path = correct_path(perl_library_path);
MAX_path          = correct_path(MAX_path);


path_str = '';
if strcmpi(computer, 'MACI64') || strcmpi(computer, 'GLNXA64')
    path_str = sprintf('export PERL5LIB=$PERL5LIB:%s ;', perl_library_path);
end

%
% Test that the Perl installation contains the correct packages
%
t = system([path_str 'perl -MXML::Twig -e 1']);
if t ~= 0
    error('The XML::Twig Perl package is required by MAX, please see ./support_software/max-V107/max.pl for more information');
end
t = system([path_str 'perl -MXML::Parser -e 1']);
if t ~= 0
    error('The XML::Parser Perl package is required by MAX, please see ./support_software/max-V107/max.pl for more information');
end
t = system([path_str 'perl -MMath::Polygon::Calc -e 1']);
if t ~= 0
    error('The Math::Polygon::Calc Perl package is required by MAX, please see ./support_software/max-V107/max.pl for more information');
end
t = system([path_str 'perl -MTie::IxHash -e 1']);
if t ~= 0
    error('The Tie::IxHash Perl package is required by MAX, please see ./support_software/max-V107/max.pl for more information');
end



xml_path  = correct_path(xml_path);
    
% Make Matlab GT output directory
if isdir([xml_path 'mat_GTs'])
    rmdir([xml_path 'mat_GTs'], 's');
end
mkdir(xml_path, 'mat_GTs');



fprintf('Processing file: %s\n', xml_filename);


% IGNORE THIS IF CALLING FROM LIDC_process_annotations....
% ONLY USE IF USING NEW UNZIPPED LIDCXML FILES, MAX COMPLAINS <- don't need
% this when splitting annotations as they are put in their own directory.
% IF EACH XML FILE IS WITHIN IN IT'S OWN DIRECTORY...
%[p,f] = fileparts(xml_files{i});
%mkdir([p filesep], f);
%movefile(xml_files{i},[p filesep f filesep f '.xml']);


% MAKE MAX DIR
mkdir(xml_path, 'max');

% EXECUTE MAX
cmd_str = ['perl "' MAX_path sprintf('max-V107b.pl" --skip-num-files-check --pixel-dim=%f --files=%s --dir-out=%s', pixel_spacing, [xml_path xml_filename], [xml_path 'max' filesep])];
fprintf('Executing: %s', cmd_str);
status = system([path_str cmd_str]);

if status > 0 && status ~= 120 % Some XML files are empty and we can ignore these (error code is 120)
    error('There was a problem executing Max (perhaps a space in the input/output path or something more serious -- see Max output above)');
end


% CONVERT OUTPUT INTO A MAT FILE
gt = LIDC_pmap_2_mat([xml_path, filesep, 'max', filesep], 'pmap.xml');

if ~isempty(gt)
    
    [~, patient_id] = fileparts(xml_filename);
    
    j = 1;
    while exist([xml_path filesep 'mat_GTs' filesep patient_id '_' num2str(j) '.mat'], 'file')
        j = j + 1;
    end
    
    new_path     = [xml_path filesep 'mat_GTs' filesep];
    new_filename = [patient_id '_' num2str(j) '.mat'];
    
    movefile([xml_path, filesep, 'max', filesep, 'pmap.mat'], [new_path new_filename]);
else
    new_path     = '';
    new_filename = '';
end
    
end