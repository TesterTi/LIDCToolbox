function [fileList] = find_files(dirName, extension, ignore_dirs)

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
% Recursively finds files in a directory structure
%   dirName = starting directory (root)
%   extension = extension of files to look for
%   ignore_dirs = (optional) if there are any directory names to exclude
%   (cell array of strings)
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



if ~exist('ignore_dirs', 'var')
    ignore_dirs = {};
end

ignore_dirs_full = cat(2,{'.','..'},ignore_dirs);

  dirData  = dir(dirName);      %# Get the data for the current directory
  dirIndex = [dirData.isdir];   %# Find the index for directories
  fileList = {dirData(~dirIndex).name}';  %# Get a list of the files
  
  mat_ind = cellfun(@(x) strcmpi(x(end-3:end), extension), fileList, 'UniformOutput', true); % FIND XML FILES
  fileList = fileList(mat_ind); % keep only XML files
      
  if ~isempty(fileList)
      
      fileList = cellfun(@(x) fullfile(dirName,x), fileList, 'UniformOutput', false);  %# Prepend path to files
      
  end
  
  subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
  validIndex = ~ismember(subDirs, ignore_dirs_full);  %# Find index of subdirectories
                                               %#   that are not '.' or '..'
                                               
  for iDir = find(validIndex)                  %# Loop over valid subdirectories
      nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
      fileList = [fileList; find_files(nextDir, extension, ignore_dirs)];    %# Recursively call getAllFiles
  end

end